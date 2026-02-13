import { useState, useEffect } from "react";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Settings as SettingsIcon, Save, Loader2, Building2, IndianRupee } from "lucide-react";
import { toast } from "sonner";

export default function SocietySettings() {
  const { currentSociety, refreshSocieties, isManager } = useSociety();
  const [form, setForm] = useState({ name: "", address: "", total_flats: "", description: "", approval_threshold: "" });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!currentSociety) return;
    api.get(`/societies/${currentSociety.id}`)
      .then((r) => {
        const s = r.data;
        setForm({
          name: s.name || "",
          address: s.address || "",
          total_flats: String(s.total_flats || 0),
          description: s.description || "",
          approval_threshold: String(s.approval_threshold || 50000),
        });
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [currentSociety]);

  const handleSave = async () => {
    if (!form.name.trim()) {
      toast.error("Society name is required");
      return;
    }
    setSaving(true);
    try {
      await api.put(`/societies/${currentSociety.id}`, {
        name: form.name,
        address: form.address,
        total_flats: parseInt(form.total_flats) || 0,
        description: form.description,
        approval_threshold: parseFloat(form.approval_threshold) || 50000,
      });
      toast.success("Society settings updated");
      refreshSocieties();
    } catch (err) {
      toast.error(err.response?.data?.detail || "Failed to update");
    }
    setSaving(false);
  };

  const update = (field) => (e) => setForm({ ...form, [field]: e.target.value });

  if (loading) {
    return <div className="flex items-center justify-center h-64 text-muted-foreground">Loading settings...</div>;
  }

  return (
    <div data-testid="settings-page">
      <div className="mb-6">
        <h1 className="text-2xl font-bold tracking-tight">Society Settings</h1>
        <p className="text-sm text-muted-foreground mt-0.5">Manage your society configuration</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Settings */}
        <Card className="lg:col-span-2 bg-card border-white/[0.06]" data-testid="settings-card">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Building2 className="w-4 h-4 text-primary" /> Society Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Society Name *</Label>
              <Input
                value={form.name} onChange={update("name")}
                disabled={!isManager} data-testid="setting-name"
                className="bg-transparent"
              />
            </div>
            <div className="space-y-2">
              <Label>Address</Label>
              <Textarea
                value={form.address} onChange={update("address")}
                disabled={!isManager} rows={2} data-testid="setting-address"
                className="bg-transparent resize-none"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Total Flats</Label>
                <Input
                  type="number" value={form.total_flats} onChange={update("total_flats")}
                  disabled={!isManager} data-testid="setting-flats"
                  className="bg-transparent font-mono-financial"
                />
              </div>
              <div className="space-y-2">
                <Label>Approval Threshold (Rs.)</Label>
                <Input
                  type="number" value={form.approval_threshold} onChange={update("approval_threshold")}
                  disabled={!isManager} data-testid="setting-threshold"
                  className="bg-transparent font-mono-financial"
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                value={form.description} onChange={update("description")}
                disabled={!isManager} rows={3} data-testid="setting-desc"
                className="bg-transparent resize-none"
              />
            </div>
            {isManager && (
              <Button onClick={handleSave} disabled={saving} data-testid="save-settings-btn" className="mt-2">
                {saving ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <Save className="w-4 h-4 mr-2" />}
                Save Changes
              </Button>
            )}
          </CardContent>
        </Card>

        {/* Info Panel */}
        <Card className="bg-card border-white/[0.06]">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <IndianRupee className="w-4 h-4 text-primary" /> Approval Policy
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4 text-sm">
              <div className="p-3 rounded-lg bg-white/[0.03] border border-white/[0.06]">
                <p className="text-muted-foreground mb-1">Current Threshold</p>
                <p className="text-xl font-bold font-mono-financial text-primary">
                  Rs.{parseFloat(form.approval_threshold || 0).toLocaleString()}
                </p>
              </div>
              <p className="text-muted-foreground text-xs leading-relaxed">
                Any outward transaction exceeding this amount will automatically require committee approval before being recorded as an approved expense.
              </p>
              <div className="p-3 rounded-lg bg-amber-500/5 border border-amber-500/20">
                <p className="text-amber-400 text-xs font-medium">Note</p>
                <p className="text-muted-foreground text-xs mt-1">
                  Only managers can modify society settings. Changes to the threshold affect future transactions only.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
