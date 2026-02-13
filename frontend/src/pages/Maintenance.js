import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from "@/components/ui/dialog";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { Receipt, PlusCircle, IndianRupee, Loader2, CheckCircle2, FileText } from "lucide-react";
import { toast } from "sonner";

const statusColors = {
  paid: "text-emerald-400 border-emerald-500/30 bg-emerald-500/10",
  pending: "text-amber-400 border-amber-500/30 bg-amber-500/10",
  overdue: "text-red-400 border-red-500/30 bg-red-500/10",
  partial: "text-blue-400 border-blue-500/30 bg-blue-500/10",
};

export default function Maintenance() {
  const { currentSociety, isManager } = useSociety();
  const [bills, setBills] = useState([]);
  const [loading, setLoading] = useState(true);
  const [genOpen, setGenOpen] = useState(false);
  const [payOpen, setPayOpen] = useState(false);
  const [selectedBill, setSelectedBill] = useState(null);
  const [genForm, setGenForm] = useState({
    month: new Date().getMonth() + 1,
    year: new Date().getFullYear(),
    amount_per_flat: "5000",
    due_date: "",
    late_fee: "500",
  });
  const [payForm, setPayForm] = useState({ amount_paid: "", payment_mode: "bank" });
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!currentSociety) return;
    fetchBills();
  }, [currentSociety]);

  const fetchBills = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/societies/${currentSociety.id}/maintenance/bills`);
      setBills(res.data);
    } catch (err) {
      console.error(err);
    }
    setLoading(false);
  };

  const handleGenerate = async () => {
    if (!genForm.amount_per_flat || !genForm.due_date) {
      toast.error("Please fill amount and due date");
      return;
    }
    setSubmitting(true);
    try {
      const res = await api.post(`/societies/${currentSociety.id}/maintenance/generate`, {
        month: parseInt(genForm.month),
        year: parseInt(genForm.year),
        amount_per_flat: parseFloat(genForm.amount_per_flat),
        due_date: genForm.due_date,
        late_fee: parseFloat(genForm.late_fee || 0),
      });
      toast.success(`${res.data.bills_created} bills generated successfully`);
      setGenOpen(false);
      fetchBills();
    } catch (err) {
      toast.error(err.response?.data?.detail || "Failed to generate bills");
    }
    setSubmitting(false);
  };

  const handlePay = async () => {
    if (!payForm.amount_paid) {
      toast.error("Please enter amount");
      return;
    }
    setSubmitting(true);
    try {
      await api.post(`/societies/${currentSociety.id}/maintenance/pay`, {
        bill_id: selectedBill.id,
        amount_paid: parseFloat(payForm.amount_paid),
        payment_mode: payForm.payment_mode,
      });
      toast.success("Payment recorded successfully");
      setPayOpen(false);
      setSelectedBill(null);
      fetchBills();
    } catch (err) {
      toast.error(err.response?.data?.detail || "Failed to record payment");
    }
    setSubmitting(false);
  };

  const summary = {
    total: bills.length,
    paid: bills.filter((b) => b.status === "paid").length,
    pending: bills.filter((b) => b.status === "pending" || b.status === "overdue").length,
    totalAmount: bills.reduce((s, b) => s + b.amount, 0),
    collected: bills.reduce((s, b) => s + (b.paid_amount || 0), 0),
  };

  return (
    <div data-testid="maintenance-page">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Maintenance Billing</h1>
          <p className="text-sm text-muted-foreground mt-0.5">{summary.total} bills generated</p>
        </div>
        {isManager && (
          <Button onClick={() => setGenOpen(true)} data-testid="generate-bills-btn">
            <PlusCircle className="w-4 h-4 mr-1.5" /> Generate Bills
          </Button>
        )}
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-6">
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="p-4">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Total Billed</p>
            <p className="text-xl font-bold font-mono-financial">Rs.{summary.totalAmount.toLocaleString()}</p>
          </CardContent>
        </Card>
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="p-4">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Collected</p>
            <p className="text-xl font-bold font-mono-financial text-emerald-400">Rs.{summary.collected.toLocaleString()}</p>
          </CardContent>
        </Card>
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="p-4">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Paid Bills</p>
            <p className="text-xl font-bold font-mono-financial text-emerald-400">{summary.paid}</p>
          </CardContent>
        </Card>
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="p-4">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Pending</p>
            <p className="text-xl font-bold font-mono-financial text-amber-400">{summary.pending}</p>
          </CardContent>
        </Card>
      </div>

      {/* Bills Table */}
      <Card className="bg-card border-white/[0.06]">
        <CardContent className="p-0">
          {loading ? (
            <div className="p-8 text-center text-muted-foreground">Loading...</div>
          ) : bills.length === 0 ? (
            <div className="p-8 text-center text-muted-foreground">
              <Receipt className="w-10 h-10 mx-auto mb-3 opacity-30" />
              <p>No maintenance bills generated yet</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/[0.06]">
                    <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Flat</th>
                    <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3 hidden sm:table-cell">Member</th>
                    <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Period</th>
                    <th className="text-right text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Amount</th>
                    <th className="text-right text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3 hidden md:table-cell">Paid</th>
                    <th className="text-center text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Status</th>
                    {isManager && <th className="text-center text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Action</th>}
                  </tr>
                </thead>
                <tbody>
                  {bills.map((bill) => (
                    <tr key={bill.id} className="border-b border-white/[0.04] hover:bg-white/[0.02]" data-testid={`bill-row-${bill.id}`}>
                      <td className="px-4 py-3 text-sm font-medium">{bill.flat_number}</td>
                      <td className="px-4 py-3 text-sm text-muted-foreground hidden sm:table-cell">{bill.member_name || "-"}</td>
                      <td className="px-4 py-3 text-sm font-mono-financial">{bill.month}/{bill.year}</td>
                      <td className="px-4 py-3 text-right font-mono-financial text-sm">Rs.{bill.amount.toLocaleString()}</td>
                      <td className="px-4 py-3 text-right font-mono-financial text-sm text-emerald-400 hidden md:table-cell">Rs.{(bill.paid_amount || 0).toLocaleString()}</td>
                      <td className="px-4 py-3 text-center">
                        <Badge variant="outline" className={`text-[10px] ${statusColors[bill.status] || statusColors.pending}`}>
                          {bill.status}
                        </Badge>
                      </td>
                      {isManager && (
                        <td className="px-4 py-3 text-center">
                          {bill.status !== "paid" && (
                            <Button
                              variant="ghost" size="sm" className="text-xs text-primary h-7"
                              onClick={() => { setSelectedBill(bill); setPayForm({ amount_paid: String(bill.amount - (bill.paid_amount || 0)), payment_mode: "bank" }); setPayOpen(true); }}
                              data-testid={`pay-btn-${bill.id}`}
                            >
                              <IndianRupee className="w-3 h-3 mr-1" /> Record Pay
                            </Button>
                          )}
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Generate Bills Dialog */}
      <Dialog open={genOpen} onOpenChange={setGenOpen}>
        <DialogContent className="bg-card border-white/[0.08]" data-testid="generate-bills-dialog">
          <DialogHeader>
            <DialogTitle>Generate Monthly Bills</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>Month</Label>
                <Select value={String(genForm.month)} onValueChange={(v) => setGenForm({ ...genForm, month: v })}>
                  <SelectTrigger className="bg-transparent" data-testid="gen-month">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {Array.from({ length: 12 }, (_, i) => (
                      <SelectItem key={i + 1} value={String(i + 1)}>
                        {new Date(2024, i).toLocaleString("default", { month: "long" })}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Year</Label>
                <Input type="number" value={genForm.year} onChange={(e) => setGenForm({ ...genForm, year: e.target.value })} data-testid="gen-year" className="bg-transparent" />
              </div>
            </div>
            <div className="space-y-1.5">
              <Label>Amount per Flat (Rs.)</Label>
              <Input type="number" value={genForm.amount_per_flat} onChange={(e) => setGenForm({ ...genForm, amount_per_flat: e.target.value })} data-testid="gen-amount" className="bg-transparent font-mono-financial" />
            </div>
            <div className="space-y-1.5">
              <Label>Due Date</Label>
              <Input type="date" value={genForm.due_date} onChange={(e) => setGenForm({ ...genForm, due_date: e.target.value })} data-testid="gen-due-date" className="bg-transparent" />
            </div>
            <div className="space-y-1.5">
              <Label>Late Fee (Rs.)</Label>
              <Input type="number" value={genForm.late_fee} onChange={(e) => setGenForm({ ...genForm, late_fee: e.target.value })} data-testid="gen-late-fee" className="bg-transparent font-mono-financial" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setGenOpen(false)}>Cancel</Button>
            <Button onClick={handleGenerate} disabled={submitting} data-testid="gen-submit">
              {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
              Generate Bills
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Record Payment Dialog */}
      <Dialog open={payOpen} onOpenChange={setPayOpen}>
        <DialogContent className="bg-card border-white/[0.08]" data-testid="record-payment-dialog">
          <DialogHeader>
            <DialogTitle>Record Payment - {selectedBill?.flat_number}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="p-3 rounded-lg bg-white/[0.03] border border-white/[0.06] text-sm">
              <div className="flex justify-between mb-1">
                <span className="text-muted-foreground">Bill Amount:</span>
                <span className="font-mono-financial">Rs.{selectedBill?.amount.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Outstanding:</span>
                <span className="font-mono-financial text-amber-400">
                  Rs.{((selectedBill?.amount || 0) - (selectedBill?.paid_amount || 0)).toLocaleString()}
                </span>
              </div>
            </div>
            <div className="space-y-1.5">
              <Label>Amount Received (Rs.)</Label>
              <Input type="number" value={payForm.amount_paid} onChange={(e) => setPayForm({ ...payForm, amount_paid: e.target.value })} data-testid="pay-amount" className="bg-transparent font-mono-financial" />
            </div>
            <div className="space-y-1.5">
              <Label>Payment Mode</Label>
              <Select value={payForm.payment_mode} onValueChange={(v) => setPayForm({ ...payForm, payment_mode: v })}>
                <SelectTrigger className="bg-transparent" data-testid="pay-mode">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="cash">Cash</SelectItem>
                  <SelectItem value="upi">UPI</SelectItem>
                  <SelectItem value="bank">Bank Transfer</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setPayOpen(false)}>Cancel</Button>
            <Button onClick={handlePay} disabled={submitting} data-testid="pay-submit">
              {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <CheckCircle2 className="w-4 h-4 mr-2" />}
              Record Payment
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
