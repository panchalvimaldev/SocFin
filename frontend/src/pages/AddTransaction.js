import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ArrowDownLeft, ArrowUpRight, Loader2, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";

export default function AddTransaction() {
  const { currentSociety } = useSociety();
  const navigate = useNavigate();
  const [type, setType] = useState("inward");
  const [categories, setCategories] = useState({ inward: [], outward: [] });
  const [form, setForm] = useState({
    category: "", amount: "", description: "",
    vendor_name: "", payment_mode: "bank", date: new Date().toISOString().slice(0, 10),
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!currentSociety) return;
    api.get(`/societies/${currentSociety.id}/transactions/categories`)
      .then((r) => setCategories(r.data))
      .catch(() => {});
  }, [currentSociety]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.category || !form.amount) {
      toast.error("Please fill in category and amount");
      return;
    }
    setLoading(true);
    try {
      const res = await api.post(`/societies/${currentSociety.id}/transactions/`, {
        type,
        category: form.category,
        amount: parseFloat(form.amount),
        description: form.description,
        vendor_name: form.vendor_name,
        payment_mode: form.payment_mode,
        date: form.date,
      });
      if (res.data.approval_status === "pending") {
        toast.info("Transaction created and sent for committee approval");
      } else {
        toast.success("Transaction recorded successfully");
      }
      navigate("/transactions");
    } catch (err) {
      toast.error(err.response?.data?.detail || "Failed to create transaction");
    }
    setLoading(false);
  };

  const update = (field) => (e) => setForm({ ...form, [field]: e.target.value || e });

  const currentCategories = type === "inward" ? categories.inward : categories.outward;

  return (
    <div data-testid="add-transaction-page">
      <div className="mb-6">
        <h1 className="text-2xl font-bold tracking-tight">Add Transaction</h1>
        <p className="text-sm text-muted-foreground mt-0.5">Record a new financial transaction</p>
      </div>

      <Card className="bg-card border-white/[0.06] max-w-2xl">
        <CardContent className="p-6">
          <Tabs value={type} onValueChange={(v) => { setType(v); setForm({ ...form, category: "" }); }}>
            <TabsList className="w-full mb-6" data-testid="txn-type-tabs">
              <TabsTrigger value="inward" className="flex-1 gap-2" data-testid="tab-inward">
                <ArrowDownLeft className="w-4 h-4" /> Inward (Income)
              </TabsTrigger>
              <TabsTrigger value="outward" className="flex-1 gap-2" data-testid="tab-outward">
                <ArrowUpRight className="w-4 h-4" /> Outward (Expense)
              </TabsTrigger>
            </TabsList>
          </Tabs>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Category *</Label>
                <Select value={form.category} onValueChange={(v) => setForm({ ...form, category: v })}>
                  <SelectTrigger className="bg-transparent" data-testid="txn-category">
                    <SelectValue placeholder="Select category" />
                  </SelectTrigger>
                  <SelectContent>
                    {currentCategories.map((c) => (
                      <SelectItem key={c} value={c}>{c}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Amount (Rs.) *</Label>
                <Input
                  type="number" step="0.01" min="0" placeholder="0.00"
                  value={form.amount} onChange={update("amount")}
                  required data-testid="txn-amount"
                  className="bg-transparent font-mono-financial"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Date</Label>
                <Input
                  type="date" value={form.date} onChange={update("date")}
                  data-testid="txn-date" className="bg-transparent"
                />
              </div>
              <div className="space-y-2">
                <Label>Payment Mode</Label>
                <Select value={form.payment_mode} onValueChange={(v) => setForm({ ...form, payment_mode: v })}>
                  <SelectTrigger className="bg-transparent" data-testid="txn-payment-mode">
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

            {type === "outward" && (
              <div className="space-y-2">
                <Label>Vendor Name</Label>
                <Input
                  placeholder="Vendor / Payee name"
                  value={form.vendor_name} onChange={update("vendor_name")}
                  data-testid="txn-vendor" className="bg-transparent"
                />
              </div>
            )}

            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                placeholder="Add a note about this transaction..."
                value={form.description} onChange={update("description")}
                data-testid="txn-description" className="bg-transparent resize-none"
                rows={3}
              />
            </div>

            <div className="flex gap-3 pt-2">
              <Button type="submit" disabled={loading} data-testid="txn-submit" className="flex-1">
                {loading ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <CheckCircle2 className="w-4 h-4 mr-2" />}
                Record Transaction
              </Button>
              <Button type="button" variant="outline" onClick={() => navigate("/transactions")} data-testid="txn-cancel">
                Cancel
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
