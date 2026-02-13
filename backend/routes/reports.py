from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import StreamingResponse
from database import db
from auth_utils import get_current_user
from models import MonthlySummary, CategorySpending
from datetime import datetime, timezone
import io

router = APIRouter(prefix="/api/societies/{society_id}/reports", tags=["Reports"])


async def _verify(user_id, society_id):
    q = {"user_id": user_id, "society_id": society_id, "status": "active"}
    m = await db.memberships.find_one(q, {"_id": 0})
    if not m:
        raise HTTPException(status_code=403, detail="Not a member")
    return m


@router.get("/monthly-summary")
async def monthly_summary(society_id: str, year: int = None,
                          current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id)
    if not year:
        year = datetime.now(timezone.utc).year

    txns = await db.transactions.find(
        {"society_id": society_id, "approval_status": "approved"}, {"_id": 0}
    ).to_list(50000)

    monthly = {}
    for t in txns:
        date_str = t.get("date", t.get("created_at", ""))[:7]
        if not date_str.startswith(str(year)):
            continue
        month = int(date_str[5:7])
        if month not in monthly:
            monthly[month] = {"inward": 0, "outward": 0, "count": 0}
        monthly[month][t["type"]] += t["amount"]
        monthly[month]["count"] += 1

    result = []
    for m in range(1, 13):
        data = monthly.get(m, {"inward": 0, "outward": 0, "count": 0})
        result.append(MonthlySummary(
            month=m, year=year,
            total_inward=data["inward"],
            total_outward=data["outward"],
            net=data["inward"] - data["outward"],
            transaction_count=data["count"],
        ))
    return result


@router.get("/category-spending")
async def category_spending(society_id: str, year: int = None, month: int = None,
                            current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id)
    query = {"society_id": society_id, "type": "outward", "approval_status": "approved"}

    txns = await db.transactions.find(query, {"_id": 0}).to_list(50000)

    # Filter by year/month if provided
    if year:
        txns = [t for t in txns if t.get("date", t.get("created_at", ""))[:4] == str(year)]
    if month:
        txns = [t for t in txns if t.get("date", t.get("created_at", ""))[5:7] == f"{month:02d}"]

    cats = {}
    total = 0
    for t in txns:
        cat = t["category"]
        if cat not in cats:
            cats[cat] = {"total": 0, "count": 0}
        cats[cat]["total"] += t["amount"]
        cats[cat]["count"] += 1
        total += t["amount"]

    result = []
    for cat, data in sorted(cats.items(), key=lambda x: -x[1]["total"]):
        result.append(CategorySpending(
            category=cat,
            total=data["total"],
            count=data["count"],
            percentage=round(data["total"] / total * 100, 1) if total > 0 else 0,
        ))
    return result


@router.get("/outstanding-dues")
async def outstanding_dues(society_id: str, current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id)
    bills = await db.maintenance_bills.find(
        {"society_id": society_id, "status": {"$in": ["pending", "overdue", "partial"]}},
        {"_id": 0},
    ).to_list(5000)

    result = []
    for b in bills:
        user = await db.users.find_one({"id": b.get("member_id", "")}, {"_id": 0})
        result.append({
            **b,
            "member_name": user["name"] if user else "Unassigned",
            "outstanding": b["amount"] - b.get("paid_amount", 0),
        })
    return result


@router.get("/annual-summary")
async def annual_summary(society_id: str, year: int = None,
                         current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id)
    if not year:
        year = datetime.now(timezone.utc).year

    txns = await db.transactions.find(
        {"society_id": society_id, "approval_status": "approved"}, {"_id": 0}
    ).to_list(50000)

    year_txns = [t for t in txns if t.get("date", t.get("created_at", ""))[:4] == str(year)]
    total_in = sum(t["amount"] for t in year_txns if t["type"] == "inward")
    total_out = sum(t["amount"] for t in year_txns if t["type"] == "outward")

    bills = await db.maintenance_bills.find(
        {"society_id": society_id, "year": year}, {"_id": 0}
    ).to_list(10000)
    total_billed = sum(b["amount"] for b in bills)
    total_collected = sum(b.get("paid_amount", 0) for b in bills)

    return {
        "year": year,
        "total_income": total_in,
        "total_expense": total_out,
        "net_balance": total_in - total_out,
        "total_billed": total_billed,
        "total_collected": total_collected,
        "collection_rate": round(total_collected / total_billed * 100, 1) if total_billed > 0 else 0,
        "transaction_count": len(year_txns),
    }


@router.get("/export/excel")
async def export_excel(society_id: str, year: int = None,
                       current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id)
    if not year:
        year = datetime.now(timezone.utc).year

    import openpyxl
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Transactions"
    ws.append(["Date", "Type", "Category", "Amount", "Vendor", "Payment Mode", "Description", "Status"])

    txns = await db.transactions.find({"society_id": society_id}, {"_id": 0}).sort("created_at", -1).to_list(50000)
    year_txns = [t for t in txns if t.get("date", t.get("created_at", ""))[:4] == str(year)]

    for t in year_txns:
        ws.append([
            t.get("date", ""), t["type"], t["category"], t["amount"],
            t.get("vendor_name", ""), t.get("payment_mode", ""),
            t.get("description", ""), t.get("approval_status", ""),
        ])

    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)

    soc = await db.societies.find_one({"id": society_id}, {"_id": 0})
    name = soc["name"].replace(" ", "_") if soc else "society"
    return StreamingResponse(
        buf,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={name}_transactions_{year}.xlsx"},
    )


@router.get("/export/pdf")
async def export_pdf(society_id: str, year: int = None,
                     current_user: dict = Depends(get_current_user)):
    await _verify(current_user["sub"], society_id)
    if not year:
        year = datetime.now(timezone.utc).year

    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
    from reportlab.lib.styles import getSampleStyleSheet

    soc = await db.societies.find_one({"id": society_id}, {"_id": 0})
    soc_name = soc["name"] if soc else "Society"

    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4)
    styles = getSampleStyleSheet()
    elements = []

    elements.append(Paragraph(f"{soc_name} - Financial Report {year}", styles["Title"]))
    elements.append(Spacer(1, 20))

    txns = await db.transactions.find({"society_id": society_id}, {"_id": 0}).sort("created_at", -1).to_list(50000)
    year_txns = [t for t in txns if t.get("date", t.get("created_at", ""))[:4] == str(year)]

    total_in = sum(t["amount"] for t in year_txns if t["type"] == "inward")
    total_out = sum(t["amount"] for t in year_txns if t["type"] == "outward")

    summary_data = [
        ["Total Income", f"Rs. {total_in:,.2f}"],
        ["Total Expense", f"Rs. {total_out:,.2f}"],
        ["Net Balance", f"Rs. {total_in - total_out:,.2f}"],
    ]
    st = Table(summary_data, colWidths=[200, 200])
    st.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.Color(0.1, 0.1, 0.15)),
        ("TEXTCOLOR", (0, 0), (-1, -1), colors.white),
        ("FONTSIZE", (0, 0), (-1, -1), 12),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
    ]))
    elements.append(st)
    elements.append(Spacer(1, 20))

    elements.append(Paragraph("Transaction Details", styles["Heading2"]))
    elements.append(Spacer(1, 10))

    table_data = [["Date", "Type", "Category", "Amount", "Status"]]
    for t in year_txns[:100]:
        table_data.append([
            t.get("date", "")[:10], t["type"].title(),
            t["category"], f"Rs. {t['amount']:,.0f}",
            t.get("approval_status", "approved").title(),
        ])

    if len(table_data) > 1:
        t2 = Table(table_data, colWidths=[80, 60, 120, 80, 70])
        t2.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.Color(0.2, 0.3, 0.6)),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTSIZE", (0, 0), (-1, -1), 8),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.Color(0.95, 0.95, 0.95), colors.white]),
        ]))
        elements.append(t2)

    doc.build(elements)
    buf.seek(0)

    name = soc_name.replace(" ", "_")
    return StreamingResponse(
        buf,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={name}_report_{year}.pdf"},
    )
