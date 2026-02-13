import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  IndianRupee, TrendingUp, TrendingDown, Users, Home,
  AlertTriangle, ClipboardCheck, ArrowUpRight, ArrowDownLeft,
  PlusCircle, BarChart3, ArrowRight,
} from "lucide-react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, AreaChart, Area,
} from "recharts";

const formatCurrency = (n) => {
  if (n >= 10000000) return `${(n / 10000000).toFixed(1)}Cr`;
  if (n >= 100000) return `${(n / 100000).toFixed(1)}L`;
  if (n >= 1000) return `${(n / 1000).toFixed(1)}K`;
  return n?.toFixed(0) || "0";
};

export default function Dashboard() {
  const { currentSociety, role, isManager } = useSociety();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!currentSociety) return;
    setLoading(true);
    api.get(`/societies/${currentSociety.id}/dashboard`)
      .then((r) => setData(r.data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [currentSociety]);

  if (loading || !data) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-pulse text-muted-foreground">Loading dashboard...</div>
      </div>
    );
  }

  const statCards = [
    {
      label: "Society Balance",
      value: data.society_balance,
      icon: IndianRupee,
      color: data.society_balance >= 0 ? "text-emerald-400" : "text-red-400",
      bg: data.society_balance >= 0 ? "bg-emerald-500/10" : "bg-red-500/10",
    },
    {
      label: "Total Income",
      value: data.total_inward,
      icon: TrendingUp,
      color: "text-emerald-400",
      bg: "bg-emerald-500/10",
    },
    {
      label: "Total Expense",
      value: data.total_outward,
      icon: TrendingDown,
      color: "text-red-400",
      bg: "bg-red-500/10",
    },
    {
      label: "Pending Dues",
      value: data.pending_dues,
      icon: AlertTriangle,
      color: "text-amber-400",
      bg: "bg-amber-500/10",
      isCurrency: false,
    },
  ];

  return (
    <div data-testid="dashboard-page">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">{currentSociety?.name}</h1>
          <p className="text-sm text-muted-foreground mt-0.5">Financial Overview</p>
        </div>
        {isManager && (
          <div className="flex gap-2">
            <Button size="sm" onClick={() => navigate("/transactions/add")} data-testid="quick-add-txn">
              <PlusCircle className="w-4 h-4 mr-1.5" /> Add Transaction
            </Button>
            <Button size="sm" variant="outline" onClick={() => navigate("/reports")} data-testid="view-reports">
              <BarChart3 className="w-4 h-4 mr-1.5" /> Reports
            </Button>
          </div>
        )}
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-6">
        {statCards.map((card, i) => {
          const Icon = card.icon;
          return (
            <Card key={i} className={`bg-card border-white/[0.06] hover:border-primary/30 transition-colors stagger-${i + 1} animate-fade-in-up`} data-testid={`stat-${card.label.toLowerCase().replace(/\s/g, "-")}`}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between mb-3">
                  <span className="text-[11px] text-muted-foreground uppercase tracking-wider font-medium">{card.label}</span>
                  <div className={`w-8 h-8 rounded-lg ${card.bg} flex items-center justify-center`}>
                    <Icon className={`w-4 h-4 ${card.color}`} />
                  </div>
                </div>
                <p className={`text-2xl font-bold font-mono-financial tracking-tight ${card.color}`}>
                  {card.isCurrency === false ? card.value : `${formatCurrency(card.value)}`}
                </p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Charts + Info */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
        {/* Monthly Trend Chart */}
        <Card className="lg:col-span-2 bg-card border-white/[0.06]" data-testid="monthly-trend-chart">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Monthly Income vs Expense</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={240}>
              <BarChart data={data.monthly_trend} barGap={4}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey="month" tick={{ fill: "#94A3B8", fontSize: 11 }} tickLine={false} axisLine={false} />
                <YAxis tick={{ fill: "#94A3B8", fontSize: 11 }} tickLine={false} axisLine={false} tickFormatter={formatCurrency} />
                <Tooltip
                  contentStyle={{ background: "#15171E", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", fontSize: "12px" }}
                  labelStyle={{ color: "#F8FAFC" }}
                  formatter={(v) => [`Rs. ${v.toLocaleString()}`, undefined]}
                />
                <Bar dataKey="inward" fill="#10B981" radius={[4, 4, 0, 0]} name="Income" />
                <Bar dataKey="outward" fill="#EF4444" radius={[4, 4, 0, 0]} name="Expense" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Quick Stats */}
        <Card className="bg-card border-white/[0.06]" data-testid="quick-stats-card">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Quick Stats</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between p-3 rounded-lg bg-white/[0.02] border border-white/[0.04]">
              <div className="flex items-center gap-2">
                <Users className="w-4 h-4 text-primary" />
                <span className="text-sm">Members</span>
              </div>
              <span className="font-mono-financial font-semibold">{data.member_count}</span>
            </div>
            <div className="flex items-center justify-between p-3 rounded-lg bg-white/[0.02] border border-white/[0.04]">
              <div className="flex items-center gap-2">
                <Home className="w-4 h-4 text-primary" />
                <span className="text-sm">Flats</span>
              </div>
              <span className="font-mono-financial font-semibold">{data.flat_count}</span>
            </div>
            {(isManager || role === "committee") && (
              <div className="flex items-center justify-between p-3 rounded-lg bg-white/[0.02] border border-white/[0.04]">
                <div className="flex items-center gap-2">
                  <ClipboardCheck className="w-4 h-4 text-amber-400" />
                  <span className="text-sm">Pending Approvals</span>
                </div>
                <span className="font-mono-financial font-semibold text-amber-400">{data.pending_approvals}</span>
              </div>
            )}
            {isManager && (
              <Button variant="outline" className="w-full text-xs" onClick={() => navigate("/maintenance")} data-testid="manage-bills-btn">
                Manage Bills <ArrowRight className="w-3.5 h-3.5 ml-1" />
              </Button>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Recent Transactions */}
      <Card className="bg-card border-white/[0.06]" data-testid="recent-transactions">
        <CardHeader className="pb-2 flex flex-row items-center justify-between">
          <CardTitle className="text-sm font-medium">Recent Transactions</CardTitle>
          <Button variant="ghost" size="sm" className="text-xs" onClick={() => navigate("/transactions")} data-testid="view-all-txns">
            View All <ArrowRight className="w-3 h-3 ml-1" />
          </Button>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {data.recent_transactions.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">No transactions yet</p>
            ) : (
              data.recent_transactions.slice(0, 8).map((txn) => (
                <div key={txn.id} className="flex items-center gap-3 p-3 rounded-lg bg-white/[0.02] border border-white/[0.04] hover:border-white/[0.08] transition-colors" data-testid={`txn-${txn.id}`}>
                  <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${txn.type === "inward" ? "bg-emerald-500/10" : "bg-red-500/10"}`}>
                    {txn.type === "inward" ? (
                      <ArrowDownLeft className="w-4 h-4 text-emerald-400" />
                    ) : (
                      <ArrowUpRight className="w-4 h-4 text-red-400" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{txn.category}</p>
                    <p className="text-xs text-muted-foreground">{txn.date}</p>
                  </div>
                  <div className="text-right">
                    <p className={`font-mono-financial font-semibold text-sm ${txn.type === "inward" ? "text-emerald-400" : "text-red-400"}`}>
                      {txn.type === "inward" ? "+" : "-"}Rs.{txn.amount.toLocaleString()}
                    </p>
                    {txn.approval_status === "pending" && (
                      <Badge variant="outline" className="text-[9px] text-amber-400 border-amber-500/30">Pending</Badge>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
