import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import {
  ArrowUpRight, ArrowDownLeft, PlusCircle, Search,
  ChevronLeft, ChevronRight, Filter, X,
} from "lucide-react";

export default function Transactions() {
  const { currentSociety, isManager } = useSociety();
  const navigate = useNavigate();
  const [txns, setTxns] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [filters, setFilters] = useState({ type: "", category: "" });
  const [categories, setCategories] = useState({ inward: [], outward: [] });
  const limit = 15;

  useEffect(() => {
    if (!currentSociety) return;
    api.get(`/societies/${currentSociety.id}/transactions/categories`)
      .then((r) => setCategories(r.data))
      .catch(() => {});
  }, [currentSociety]);

  useEffect(() => {
    if (!currentSociety) return;
    fetchData();
  }, [currentSociety, page, filters]);

  const fetchData = async () => {
    setLoading(true);
    const params = new URLSearchParams({ page, limit });
    if (filters.type) params.append("type", filters.type);
    if (filters.category) params.append("category", filters.category);
    try {
      const [txnRes, countRes] = await Promise.all([
        api.get(`/societies/${currentSociety.id}/transactions/?${params}`),
        api.get(`/societies/${currentSociety.id}/transactions/count?${params}`),
      ]);
      setTxns(txnRes.data);
      setTotal(countRes.data.count);
    } catch (err) {
      console.error(err);
    }
    setLoading(false);
  };

  const totalPages = Math.ceil(total / limit);
  const allCategories = filters.type === "inward" ? categories.inward : filters.type === "outward" ? categories.outward : [...categories.inward, ...categories.outward];

  const clearFilters = () => {
    setFilters({ type: "", category: "" });
    setPage(1);
  };

  return (
    <div data-testid="transactions-page">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Transactions</h1>
          <p className="text-sm text-muted-foreground mt-0.5">{total} total records</p>
        </div>
        {isManager && (
          <Button onClick={() => navigate("/transactions/add")} data-testid="add-transaction-btn">
            <PlusCircle className="w-4 h-4 mr-1.5" /> Add Transaction
          </Button>
        )}
      </div>

      {/* Filters */}
      <Card className="bg-card border-white/[0.06] mb-4">
        <CardContent className="p-3">
          <div className="flex flex-wrap items-center gap-3">
            <Filter className="w-4 h-4 text-muted-foreground" />
            <Select value={filters.type} onValueChange={(v) => { setFilters({ ...filters, type: v, category: "" }); setPage(1); }}>
              <SelectTrigger className="w-[140px] h-9 text-xs bg-transparent" data-testid="filter-type">
                <SelectValue placeholder="All Types" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="inward">Inward</SelectItem>
                <SelectItem value="outward">Outward</SelectItem>
              </SelectContent>
            </Select>
            <Select value={filters.category} onValueChange={(v) => { setFilters({ ...filters, category: v }); setPage(1); }}>
              <SelectTrigger className="w-[180px] h-9 text-xs bg-transparent" data-testid="filter-category">
                <SelectValue placeholder="All Categories" />
              </SelectTrigger>
              <SelectContent>
                {allCategories.map((c) => (
                  <SelectItem key={c} value={c}>{c}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            {(filters.type || filters.category) && (
              <Button variant="ghost" size="sm" onClick={clearFilters} className="text-xs" data-testid="clear-filters">
                <X className="w-3 h-3 mr-1" /> Clear
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Table */}
      <Card className="bg-card border-white/[0.06]">
        <CardContent className="p-0">
          {loading ? (
            <div className="p-8 text-center text-muted-foreground">Loading...</div>
          ) : txns.length === 0 ? (
            <div className="p-8 text-center text-muted-foreground">No transactions found</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/[0.06]">
                    <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Date</th>
                    <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Type</th>
                    <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Category</th>
                    <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3 hidden md:table-cell">Vendor</th>
                    <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3 hidden sm:table-cell">Mode</th>
                    <th className="text-right text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Amount</th>
                    <th className="text-center text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {txns.map((txn) => (
                    <tr
                      key={txn.id}
                      className="border-b border-white/[0.04] hover:bg-white/[0.02] transition-colors cursor-pointer"
                      data-testid={`txn-row-${txn.id}`}
                    >
                      <td className="px-4 py-3 text-sm font-mono-financial">{txn.date}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1.5">
                          {txn.type === "inward" ? (
                            <ArrowDownLeft className="w-3.5 h-3.5 text-emerald-400" />
                          ) : (
                            <ArrowUpRight className="w-3.5 h-3.5 text-red-400" />
                          )}
                          <span className="text-sm capitalize">{txn.type}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm">{txn.category}</td>
                      <td className="px-4 py-3 text-sm text-muted-foreground hidden md:table-cell">{txn.vendor_name || "-"}</td>
                      <td className="px-4 py-3 hidden sm:table-cell">
                        <Badge variant="outline" className="text-[10px] uppercase">{txn.payment_mode}</Badge>
                      </td>
                      <td className={`px-4 py-3 text-right font-mono-financial font-semibold text-sm ${txn.type === "inward" ? "text-emerald-400" : "text-red-400"}`}>
                        {txn.type === "inward" ? "+" : "-"}Rs.{txn.amount.toLocaleString()}
                      </td>
                      <td className="px-4 py-3 text-center">
                        <Badge variant="outline" className={`text-[10px] ${
                          txn.approval_status === "approved" ? "text-emerald-400 border-emerald-500/30" :
                          txn.approval_status === "pending" ? "text-amber-400 border-amber-500/30" :
                          "text-red-400 border-red-500/30"
                        }`}>
                          {txn.approval_status}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-white/[0.06]">
              <p className="text-xs text-muted-foreground">
                Page {page} of {totalPages}
              </p>
              <div className="flex gap-1">
                <Button variant="ghost" size="icon" className="h-8 w-8" disabled={page <= 1} onClick={() => setPage(page - 1)} data-testid="prev-page">
                  <ChevronLeft className="w-4 h-4" />
                </Button>
                <Button variant="ghost" size="icon" className="h-8 w-8" disabled={page >= totalPages} onClick={() => setPage(page + 1)} data-testid="next-page">
                  <ChevronRight className="w-4 h-4" />
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
