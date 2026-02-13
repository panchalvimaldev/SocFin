import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Building2, ArrowLeft, Loader2, CheckCircle2 } from "lucide-react";
import { toast } from "sonner";

export default function CreateSociety() {
  const navigate = useNavigate();
  const { refreshSocieties, selectSociety } = useSociety();
  const [form, setForm] = useState({
    name: "", address: "", total_flats: "", description: "", approval_threshold: "50000",
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.name.trim() || !form.address.trim()) {
      toast.error("Name and address are required");
      return;
    }
    setLoading(true);
    try {
      const res = await api.post("/societies/", {
        name: form.name.trim(),
        address: form.address.trim(),
        total_flats: parseInt(form.total_flats) || 0,
        description: form.description.trim(),
        approval_threshold: parseFloat(form.approval_threshold) || 50000,
      });
      toast.success("Society created! You are now the Manager.");
      await refreshSocieties();
      selectSociety({
        id: res.data.id,
        name: res.data.name,
        address: res.data.address,
        total_flats: res.data.total_flats,
        description: res.data.description,
        role: "manager",
        membership_id: "",
      });
      navigate("/");
    } catch (err) {
      toast.error(err.response?.data?.detail || "Failed to create society");
    }
    setLoading(false);
  };

  const update = (field) => (e) => setForm({ ...form, [field]: e.target.value });

  return (
    <div className="min-h-screen flex items-center justify-center p-4 relative">
      <div className="absolute inset-0 bg-[#0B0C10]">
        <div className="absolute inset-0 opacity-10"
          style={{
            backgroundImage: `url(https://images.unsplash.com/photo-1758448501006-42ef007449ff?w=1920&q=60)`,
            backgroundSize: "cover", backgroundPosition: "center",
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0B0C10] via-[#0B0C10]/90 to-[#0B0C10]/70" />
      </div>

      <Card className="w-full max-w-lg relative z-10 bg-card/80 backdrop-blur-xl border-white/[0.08] shadow-2xl" data-testid="create-society-card">
        <CardHeader className="text-center pb-2">
          <div className="mx-auto w-14 h-14 rounded-xl bg-primary/20 flex items-center justify-center mb-4">
            <Building2 className="w-7 h-7 text-primary" />
          </div>
          <CardTitle className="text-2xl font-bold tracking-tight">Create New Society</CardTitle>
          <CardDescription>Set up a new housing society. You will be assigned as Manager.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label>Society Name *</Label>
              <Input
                placeholder="e.g., Sunrise Apartments" value={form.name}
                onChange={update("name")} required data-testid="cs-name" className="bg-transparent"
              />
            </div>
            <div className="space-y-2">
              <Label>Address *</Label>
              <Textarea
                placeholder="Full address with city and state" value={form.address}
                onChange={update("address")} required rows={2} data-testid="cs-address" className="bg-transparent resize-none"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Total Flats</Label>
                <Input
                  type="number" placeholder="e.g., 440" value={form.total_flats}
                  onChange={update("total_flats")} data-testid="cs-flats" className="bg-transparent font-mono-financial"
                />
              </div>
              <div className="space-y-2">
                <Label>Approval Threshold (Rs.)</Label>
                <Input
                  type="number" placeholder="50000" value={form.approval_threshold}
                  onChange={update("approval_threshold")} data-testid="cs-threshold" className="bg-transparent font-mono-financial"
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Description (optional)</Label>
              <Textarea
                placeholder="Brief description of your society" value={form.description}
                onChange={update("description")} rows={2} data-testid="cs-desc" className="bg-transparent resize-none"
              />
            </div>

            <div className="flex gap-3 pt-2">
              <Button type="submit" className="flex-1" disabled={loading} data-testid="cs-submit">
                {loading ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <CheckCircle2 className="w-4 h-4 mr-2" />}
                Create Society
              </Button>
              <Button type="button" variant="outline" onClick={() => navigate("/switch-society")} data-testid="cs-cancel">
                <ArrowLeft className="w-4 h-4 mr-1" /> Back
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
