import { useState, useEffect } from "react";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import {
  BarChart3, Download, FileSpreadsheet, FileText,
  TrendingUp, TrendingDown, PieChart as PieChartIcon,
} from "lucide-react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, PieChart, Pie, Cell, Legend,
} from "recharts";
import { toast } from "sonner";

const COLORS = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#0EA5E9", "#EC4899", "#F97316"];
const API_BASE = process.env.REACT_APP_BACKEND_URL;

const formatCurrency = (n) => `Rs.${Number(n).toLocaleString()}`;

export default function Reports() {
  const { currentSociety } = useSociety();
  const [year, setYear] = useState(new Date().getFullYear());
  const [monthly, setMonthly] = useState([]);
  const [categories, setCategories] = useState([]);
  const [annual, setAnnual] = useState(null);
  const [dues, setDues] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!currentSociety) return;
    fetchAll();
  }, [currentSociety, year]);

  const fetchAll = async () => {
    setLoading(true);
    try {
      const [mRes, cRes, aRes, dRes] = await Promise.all([
        api.get(`/societies/${currentSociety.id}/reports/monthly-summary?year=${year}`),
        api.get(`/societies/${currentSociety.id}/reports/category-spending?year=${year}`),
        api.get(`/societies/${currentSociety.id}/reports/annual-summary?year=${year}`),
        api.get(`/societies/${currentSociety.id}/reports/outstanding-dues`),
      ]);
      setMonthly(mRes.data);
      setCategories(cRes.data);
      setAnnual(aRes.data);
      setDues(dRes.data);
    } catch (err) {
      console.error(err);
    }
    setLoading(false);
  };

  const handleExport = (type) => {
    const token = localStorage.getItem("sfm_token");
    const url = `${API_BASE}/api/societies/${currentSociety.id}/reports/export/${type}?year=${year}`;
    window.open(url + `&token=${token}`, "_blank");
    toast.success(`${type.toUpperCase()} export started`);
  };

  const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const chartData = monthly.map((m, i) => ({
    month: monthNames[i],
    income: m.total_inward,
    expense: m.total_outward,
    net: m.net,
  }));

  if (loading) {
    return <div className="flex items-center justify-center h-64 text-muted-foreground">Loading reports...</div>;
  }

  return (
    <div data-testid="reports-page">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Financial Reports</h1>
          <p className="text-sm text-muted-foreground mt-0.5">Comprehensive financial overview</p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={String(year)} onValueChange={(v) => setYear(parseInt(v))}>
            <SelectTrigger className="w-[100px] bg-transparent" data-testid="year-select">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[2024, 2025, 2026].map((y) => (
                <SelectItem key={y} value={String(y)}>{y}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Button variant="outline" size="sm" onClick={() => handleExport("excel")} data-testid="export-excel">
            <FileSpreadsheet className="w-4 h-4 mr-1.5" /> Excel
          </Button>
          <Button variant="outline" size="sm" onClick={() => handleExport("pdf")} data-testid="export-pdf">
            <FileText className="w-4 h-4 mr-1.5" /> PDF
          </Button>
        </div>
      </div>

      {/* Annual Summary */}
      {annual && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-6">
          <Card className="bg-card border-white/[0.06]">
            <CardContent className="p-4">
              <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Total Income</p>
              <p className="text-xl font-bold font-mono-financial text-emerald-400">{formatCurrency(annual.total_income)}</p>
            </CardContent>
          </Card>
          <Card className="bg-card border-white/[0.06]">
            <CardContent className="p-4">
              <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Total Expense</p>
              <p className="text-xl font-bold font-mono-financial text-red-400">{formatCurrency(annual.total_expense)}</p>
            </CardContent>
          </Card>
          <Card className="bg-card border-white/[0.06]">
            <CardContent className="p-4">
              <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Net Balance</p>
              <p className={`text-xl font-bold font-mono-financial ${annual.net_balance >= 0 ? "text-emerald-400" : "text-red-400"}`}>
                {formatCurrency(annual.net_balance)}
              </p>
            </CardContent>
          </Card>
          <Card className="bg-card border-white/[0.06]">
            <CardContent className="p-4">
              <p className="text-[11px] text-muted-foreground uppercase tracking-wider mb-2">Collection Rate</p>
              <p className="text-xl font-bold font-mono-financial text-primary">{annual.collection_rate}%</p>
            </CardContent>
          </Card>
        </div>
      )}

      <Tabs defaultValue="monthly" className="space-y-4">
        <TabsList data-testid="report-tabs">
          <TabsTrigger value="monthly" data-testid="tab-monthly">Monthly Trend</TabsTrigger>
          <TabsTrigger value="categories" data-testid="tab-categories">Category Breakdown</TabsTrigger>
          <TabsTrigger value="dues" data-testid="tab-dues">Outstanding Dues</TabsTrigger>
        </TabsList>

        <TabsContent value="monthly">
          <Card className="bg-card border-white/[0.06]">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Monthly Income vs Expense - {year}</CardTitle>
            </CardHeader>
            <CardContent>
              <ResponsiveContainer width="100%" height={350}>
                <BarChart data={chartData} barGap={4}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis dataKey="month" tick={{ fill: "#94A3B8", fontSize: 11 }} tickLine={false} axisLine={false} />
                  <YAxis tick={{ fill: "#94A3B8", fontSize: 11 }} tickLine={false} axisLine={false} tickFormatter={(v) => `${(v / 1000).toFixed(0)}K`} />
                  <Tooltip
                    contentStyle={{ background: "#15171E", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", fontSize: "12px" }}
                    formatter={(v) => [formatCurrency(v), undefined]}
                  />
                  <Bar dataKey="income" fill="#10B981" radius={[4, 4, 0, 0]} name="Income" />
                  <Bar dataKey="expense" fill="#EF4444" radius={[4, 4, 0, 0]} name="Expense" />
                </BarChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="categories">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card className="bg-card border-white/[0.06]">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Expense by Category</CardTitle>
              </CardHeader>
              <CardContent>
                {categories.length > 0 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <PieChart>
                      <Pie data={categories} dataKey="total" nameKey="category" cx="50%" cy="50%" outerRadius={100} label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}>
                        {categories.map((_, i) => (
                          <Cell key={i} fill={COLORS[i % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(v) => [formatCurrency(v), undefined]} contentStyle={{ background: "#15171E", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", fontSize: "12px" }} />
                    </PieChart>
                  </ResponsiveContainer>
                ) : (
                  <p className="text-muted-foreground text-center py-8">No expense data for this year</p>
                )}
              </CardContent>
            </Card>
            <Card className="bg-card border-white/[0.06]">
              <CardHeader className="pb-2">
                <CardTitle className="text-sm font-medium">Category Details</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {categories.map((cat, i) => (
                    <div key={cat.category} className="flex items-center justify-between p-3 rounded-lg bg-white/[0.02] border border-white/[0.04]">
                      <div className="flex items-center gap-2">
                        <div className="w-3 h-3 rounded-sm" style={{ background: COLORS[i % COLORS.length] }} />
                        <span className="text-sm">{cat.category}</span>
                      </div>
                      <div className="text-right">
                        <p className="font-mono-financial text-sm font-medium">{formatCurrency(cat.total)}</p>
                        <p className="text-[10px] text-muted-foreground">{cat.percentage}% | {cat.count} txns</p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="dues">
          <Card className="bg-card border-white/[0.06]">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium">Outstanding Maintenance Dues</CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {dues.length === 0 ? (
                <p className="text-muted-foreground text-center py-8">No outstanding dues</p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-white/[0.06]">
                        <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Flat</th>
                        <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Member</th>
                        <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Period</th>
                        <th className="text-right text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Outstanding</th>
                        <th className="text-center text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {dues.map((d) => (
                        <tr key={d.id} className="border-b border-white/[0.04]" data-testid={`due-${d.id}`}>
                          <td className="px-4 py-3 text-sm font-medium">{d.flat_number}</td>
                          <td className="px-4 py-3 text-sm text-muted-foreground">{d.member_name}</td>
                          <td className="px-4 py-3 text-sm font-mono-financial">{d.month}/{d.year}</td>
                          <td className="px-4 py-3 text-right font-mono-financial text-sm text-amber-400">Rs.{d.outstanding?.toLocaleString()}</td>
                          <td className="px-4 py-3 text-center">
                            <span className="text-[10px] text-amber-400">{d.status}</span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
