import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Receipt, IndianRupee, Calendar, CheckCircle2, Clock, AlertTriangle } from "lucide-react";

const statusColors = {
  paid: "text-emerald-400 border-emerald-500/30 bg-emerald-500/10",
  pending: "text-amber-400 border-amber-500/30 bg-amber-500/10",
  overdue: "text-red-400 border-red-500/30 bg-red-500/10",
  partial: "text-blue-400 border-blue-500/30 bg-blue-500/10",
};

export default function FlatLedger() {
  const { flatId } = useParams();
  const { currentSociety } = useSociety();
  const navigate = useNavigate();
  const [ledger, setLedger] = useState([]);
  const [flatInfo, setFlatInfo] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!currentSociety || !flatId) return;
    Promise.all([
      api.get(`/societies/${currentSociety.id}/maintenance/ledger/${flatId}`),
      api.get(`/societies/${currentSociety.id}/flats`),
    ])
      .then(([ledgerRes, flatsRes]) => {
        setLedger(ledgerRes.data);
        const flat = flatsRes.data.find((f) => f.id === flatId);
        setFlatInfo(flat);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [currentSociety, flatId]);

  if (loading) {
    return <div className="flex items-center justify-center h-64 text-muted-foreground">Loading ledger...</div>;
  }

  const totalBilled = ledger.reduce((s, b) => s + (b.amount || 0), 0);
  const totalPaid = ledger.reduce((s, b) => s + (b.paid_amount || 0), 0);
  const outstanding = totalBilled - totalPaid;

  return (
    <div data-testid="flat-ledger-page">
      <div className="flex items-center gap-3 mb-6">
        <Button variant="ghost" size="icon" onClick={() => navigate("/maintenance")} data-testid="ledger-back">
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">
            Flat {flatInfo?.flat_number || flatId} - Ledger
          </h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {flatInfo ? `${flatInfo.flat_type} | ${flatInfo.wing} Wing | Floor ${flatInfo.floor}` : "Payment history"}
          </p>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="p-4">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Total Billed</p>
            <p className="text-xl font-bold font-mono-financial">Rs.{totalBilled.toLocaleString()}</p>
          </CardContent>
        </Card>
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="p-4">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Total Paid</p>
            <p className="text-xl font-bold font-mono-financial text-emerald-400">Rs.{totalPaid.toLocaleString()}</p>
          </CardContent>
        </Card>
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="p-4">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Outstanding</p>
            <p className={`text-xl font-bold font-mono-financial ${outstanding > 0 ? "text-amber-400" : "text-emerald-400"}`}>
              Rs.{outstanding.toLocaleString()}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Ledger Timeline */}
      <Card className="bg-card border-white/[0.06]">
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium flex items-center gap-2">
            <Receipt className="w-4 h-4 text-primary" /> Payment History
          </CardTitle>
        </CardHeader>
        <CardContent>
          {ledger.length === 0 ? (
            <p className="text-muted-foreground text-center py-8">No billing records for this flat</p>
          ) : (
            <div className="space-y-3">
              {ledger.map((bill) => {
                const billOutstanding = (bill.amount || 0) - (bill.paid_amount || 0);
                return (
                  <div
                    key={bill.id}
                    className="flex items-center gap-4 p-4 rounded-lg bg-white/[0.02] border border-white/[0.04] hover:border-white/[0.08] transition-colors"
                    data-testid={`ledger-entry-${bill.id}`}
                  >
                    {/* Status Icon */}
                    <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                      bill.status === "paid" ? "bg-emerald-500/10" :
                      bill.status === "partial" ? "bg-blue-500/10" : "bg-amber-500/10"
                    }`}>
                      {bill.status === "paid" ? (
                        <CheckCircle2 className="w-5 h-5 text-emerald-400" />
                      ) : bill.status === "partial" ? (
                        <Clock className="w-5 h-5 text-blue-400" />
                      ) : (
                        <AlertTriangle className="w-5 h-5 text-amber-400" />
                      )}
                    </div>

                    {/* Details */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-semibold">
                          {new Date(2024, bill.month - 1).toLocaleString("default", { month: "long" })} {bill.year}
                        </span>
                        <Badge variant="outline" className={`text-[10px] ${statusColors[bill.status] || statusColors.pending}`}>
                          {bill.status}
                        </Badge>
                      </div>
                      <div className="flex items-center gap-4 text-xs text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <Calendar className="w-3 h-3" /> Due: {bill.due_date}
                        </span>
                        {bill.late_fee > 0 && (
                          <span className="text-amber-400">Late Fee: Rs.{bill.late_fee}</span>
                        )}
                      </div>
                    </div>

                    {/* Amounts */}
                    <div className="text-right shrink-0">
                      <p className="text-sm font-mono-financial">
                        <span className="text-muted-foreground text-xs mr-1">Bill:</span>
                        Rs.{(bill.amount || 0).toLocaleString()}
                      </p>
                      <p className="text-sm font-mono-financial text-emerald-400">
                        <span className="text-muted-foreground text-xs mr-1">Paid:</span>
                        Rs.{(bill.paid_amount || 0).toLocaleString()}
                      </p>
                      {billOutstanding > 0 && (
                        <p className="text-xs font-mono-financial text-amber-400 mt-0.5">
                          Due: Rs.{billOutstanding.toLocaleString()}
                        </p>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
