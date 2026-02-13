import { useState, useEffect } from "react";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { TrendingUp, TrendingDown, Building2, CheckCircle2, Clock, AlertTriangle, IndianRupee, BarChart3 } from "lucide-react";

export default function CollectionDashboard() {
  const { currentSociety, role } = useSociety();
  const [loading, setLoading] = useState(true);
  const [dashboard, setDashboard] = useState(null);
  const [year, setYear] = useState(new Date().getFullYear());
  const [month, setMonth] = useState(new Date().getMonth() + 1);

  const months = [
    { value: 1, label: "January" }, { value: 2, label: "February" },
    { value: 3, label: "March" }, { value: 4, label: "April" },
    { value: 5, label: "May" }, { value: 6, label: "June" },
    { value: 7, label: "July" }, { value: 8, label: "August" },
    { value: 9, label: "September" }, { value: 10, label: "October" },
    { value: 11, label: "November" }, { value: 12, label: "December" },
  ];

  useEffect(() => {
    if (currentSociety?.id) fetchDashboard();
  }, [currentSociety?.id, year, month]);

  const fetchDashboard = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/societies/${currentSociety.id}/maintenance/collection-dashboard?year=${year}&month=${month}`);
      setDashboard(res.data);
    } catch (e) { console.error(e); } finally { setLoading(false); }
  };

  const formatCurrency = (amount) => {
    if (amount >= 100000) return `₹${(amount / 100000).toFixed(1)}L`;
    if (amount >= 1000) return `₹${(amount / 1000).toFixed(1)}K`;
    return `₹${amount.toLocaleString()}`;
  };

  if (loading) {
    return <div className="flex items-center justify-center h-64"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-cyan-400" /></div>;
  }

  return (
    <div className="space-y-6" data-testid="collection-dashboard-page">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">Collection Dashboard</h1>
          <p className="text-slate-400 text-sm mt-1">Maintenance collection overview</p>
        </div>
        <div className="flex items-center gap-3">
          <Select value={String(month)} onValueChange={(v) => setMonth(parseInt(v))}>
            <SelectTrigger className="w-[140px] bg-slate-800 border-slate-700 text-white"><SelectValue /></SelectTrigger>
            <SelectContent className="bg-slate-800 border-slate-700">
              {months.map((m) => <SelectItem key={m.value} value={String(m.value)}>{m.label}</SelectItem>)}
            </SelectContent>
          </Select>
          <Select value={String(year)} onValueChange={(v) => setYear(parseInt(v))}>
            <SelectTrigger className="w-[100px] bg-slate-800 border-slate-700 text-white"><SelectValue /></SelectTrigger>
            <SelectContent className="bg-slate-800 border-slate-700">
              <SelectItem value="2025">2025</SelectItem>
              <SelectItem value="2026">2026</SelectItem>
              <SelectItem value="2027">2027</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {dashboard && (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <Card className="bg-gradient-to-br from-emerald-500/20 to-emerald-600/10 border-emerald-500/30">
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-emerald-400 text-xs font-medium uppercase tracking-wider">Collected</p>
                    <p className="text-3xl font-bold text-white mt-1">{formatCurrency(dashboard.total_collected)}</p>
                    <p className="text-emerald-400 text-sm mt-1">{dashboard.collection_percentage}% of billed</p>
                  </div>
                  <TrendingUp className="w-10 h-10 text-emerald-400 opacity-50" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gradient-to-br from-amber-500/20 to-amber-600/10 border-amber-500/30">
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-amber-400 text-xs font-medium uppercase tracking-wider">Outstanding</p>
                    <p className="text-3xl font-bold text-white mt-1">{formatCurrency(dashboard.total_outstanding)}</p>
                    <p className="text-amber-400 text-sm mt-1">{dashboard.pending_flats} flats pending</p>
                  </div>
                  <Clock className="w-10 h-10 text-amber-400 opacity-50" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gradient-to-br from-red-500/20 to-red-600/10 border-red-500/30">
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-red-400 text-xs font-medium uppercase tracking-wider">Overdue</p>
                    <p className="text-3xl font-bold text-white mt-1">{dashboard.overdue_flats}</p>
                    <p className="text-red-400 text-sm mt-1">flats overdue</p>
                  </div>
                  <AlertTriangle className="w-10 h-10 text-red-400 opacity-50" />
                </div>
              </CardContent>
            </Card>
            <Card className="bg-gradient-to-br from-cyan-500/20 to-cyan-600/10 border-cyan-500/30">
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-cyan-400 text-xs font-medium uppercase tracking-wider">Total Billed</p>
                    <p className="text-3xl font-bold text-white mt-1">{formatCurrency(dashboard.total_billed)}</p>
                    <p className="text-cyan-400 text-sm mt-1">{dashboard.total_flats} flats</p>
                  </div>
                  <IndianRupee className="w-10 h-10 text-cyan-400 opacity-50" />
                </div>
              </CardContent>
            </Card>
          </div>

          <Card className="bg-slate-800/50 border-slate-700">
            <CardHeader>
              <CardTitle className="text-lg text-white flex items-center gap-2"><BarChart3 className="w-5 h-5 text-cyan-400" />Collection Progress</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-400">{dashboard.paid_flats} of {dashboard.paid_flats + dashboard.pending_flats} flats paid</span>
                  <span className="text-cyan-400 font-medium">{dashboard.collection_percentage}%</span>
                </div>
                <Progress value={dashboard.collection_percentage} className="h-3 bg-slate-700" />
                <div className="flex gap-4 mt-4">
                  <div className="flex items-center gap-2"><CheckCircle2 className="w-4 h-4 text-emerald-400" /><span className="text-sm text-slate-300">{dashboard.paid_flats} Paid</span></div>
                  <div className="flex items-center gap-2"><Clock className="w-4 h-4 text-amber-400" /><span className="text-sm text-slate-300">{dashboard.pending_flats} Pending</span></div>
                  <div className="flex items-center gap-2"><AlertTriangle className="w-4 h-4 text-red-400" /><span className="text-sm text-slate-300">{dashboard.overdue_flats} Overdue</span></div>
                </div>
              </div>
            </CardContent>
          </Card>

          <div className="grid gap-6 lg:grid-cols-2">
            <Card className="bg-slate-800/50 border-slate-700">
              <CardHeader><CardTitle className="text-lg text-white">Monthly Breakdown ({year})</CardTitle></CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {dashboard.month_wise_collection.map((m) => (
                    <div key={m.month} className="flex items-center gap-4">
                      <span className="text-slate-400 text-sm w-12">{months[m.month - 1]?.label.slice(0, 3)}</span>
                      <div className="flex-1">
                        <div className="flex h-6 rounded overflow-hidden bg-slate-700">
                          {m.billed > 0 && (
                            <>
                              <div className="bg-emerald-500 transition-all" style={{ width: `${(m.collected / m.billed) * 100}%` }} />
                              <div className="bg-amber-500/50" style={{ width: `${(m.pending / m.billed) * 100}%` }} />
                            </>
                          )}
                        </div>
                      </div>
                      <div className="text-right w-24">
                        <p className="text-sm text-white font-medium">{formatCurrency(m.collected)}</p>
                        <p className="text-xs text-slate-500">/ {formatCurrency(m.billed)}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card className="bg-slate-800/50 border-slate-700">
              <CardHeader><CardTitle className="text-lg text-white">Recent Payments</CardTitle></CardHeader>
              <CardContent>
                {dashboard.recent_payments.length === 0 ? (
                  <p className="text-slate-400 text-center py-8">No recent payments</p>
                ) : (
                  <div className="space-y-3">
                    {dashboard.recent_payments.map((payment, idx) => (
                      <div key={idx} className="flex items-center justify-between p-3 bg-slate-900/50 rounded-lg border border-slate-700">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-lg bg-emerald-500/20 flex items-center justify-center">
                            <Building2 className="w-5 h-5 text-emerald-400" />
                          </div>
                          <div>
                            <p className="text-white font-medium">{payment.flat_number}</p>
                            <p className="text-xs text-slate-400">{payment.date}</p>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className="text-emerald-400 font-bold">₹{payment.amount.toLocaleString()}</p>
                          <Badge variant="outline" className="text-xs mt-1 border-slate-600 text-slate-400">{payment.mode.toUpperCase()}</Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </>
      )}
    </div>
  );
}
