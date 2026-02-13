import { useState, useEffect } from "react";
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
import { Home, Users, UserPlus, Trash2, Loader2, ChevronRight, Shield } from "lucide-react";
import { toast } from "sonner";

const relationColors = {
  Owner: "text-blue-400 border-blue-500/30 bg-blue-500/10",
  Family: "text-emerald-400 border-emerald-500/30 bg-emerald-500/10",
  Tenant: "text-amber-400 border-amber-500/30 bg-amber-500/10",
  Partner: "text-purple-400 border-purple-500/30 bg-purple-500/10",
};

export default function FlatMembers() {
  const { currentSociety, isManager } = useSociety();
  const [flats, setFlats] = useState([]);
  const [selectedFlat, setSelectedFlat] = useState(null);
  const [flatMembers, setFlatMembers] = useState([]);
  const [societyMembers, setSocietyMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [membersLoading, setMembersLoading] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const [addForm, setAddForm] = useState({ user_id: "", relation_type: "Owner", is_primary: false });
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!currentSociety) return;
    Promise.all([
      api.get(`/societies/${currentSociety.id}/flats`),
      api.get(`/societies/${currentSociety.id}/members`),
    ])
      .then(([fRes, mRes]) => {
        setFlats(fRes.data);
        setSocietyMembers(mRes.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [currentSociety]);

  const loadFlatMembers = async (flat) => {
    setSelectedFlat(flat);
    setMembersLoading(true);
    try {
      const res = await api.get(`/societies/${currentSociety.id}/flats/${flat.id}/members`);
      setFlatMembers(res.data);
    } catch (err) {
      console.error(err);
    }
    setMembersLoading(false);
  };

  const handleAddMember = async () => {
    if (!addForm.user_id) {
      toast.error("Please select a member");
      return;
    }
    setSubmitting(true);
    try {
      await api.post(`/societies/${currentSociety.id}/flats/${selectedFlat.id}/members`, {
        user_id: addForm.user_id,
        relation_type: addForm.relation_type,
        is_primary: addForm.is_primary,
      });
      toast.success("Member linked to flat");
      setAddOpen(false);
      setAddForm({ user_id: "", relation_type: "Owner", is_primary: false });
      loadFlatMembers(selectedFlat);
    } catch (err) {
      toast.error(err.response?.data?.detail || "Failed to link member");
    }
    setSubmitting(false);
  };

  const handleRemoveMember = async (fmId) => {
    try {
      await api.delete(`/societies/${currentSociety.id}/flats/${selectedFlat.id}/members/${fmId}`);
      toast.success("Member unlinked from flat");
      loadFlatMembers(selectedFlat);
    } catch (err) {
      toast.error("Failed to remove member");
    }
  };

  if (loading) {
    return <div className="flex items-center justify-center h-64 text-muted-foreground">Loading...</div>;
  }

  return (
    <div data-testid="flat-members-page">
      <div className="mb-6">
        <h1 className="text-2xl font-bold tracking-tight">Flat-Member Assignment</h1>
        <p className="text-sm text-muted-foreground mt-0.5">Link members to flats with relationship types</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Flat List */}
        <Card className="bg-card border-white/[0.06]">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Home className="w-4 h-4 text-primary" /> Select Flat ({flats.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-2">
            <div className="space-y-1 max-h-[500px] overflow-y-auto">
              {flats.map((flat) => (
                <button
                  key={flat.id}
                  onClick={() => loadFlatMembers(flat)}
                  data-testid={`flat-select-${flat.id}`}
                  className={`w-full flex items-center justify-between p-3 rounded-md text-left transition-colors ${
                    selectedFlat?.id === flat.id
                      ? "bg-primary/10 border border-primary/20"
                      : "hover:bg-white/[0.03]"
                  }`}
                >
                  <div>
                    <p className="text-sm font-medium">{flat.flat_number}</p>
                    <p className="text-[10px] text-muted-foreground">{flat.flat_type} | {flat.wing} Wing</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-muted-foreground" />
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Flat Members Detail */}
        <Card className="lg:col-span-2 bg-card border-white/[0.06]">
          <CardHeader className="pb-2 flex flex-row items-center justify-between">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Users className="w-4 h-4 text-primary" />
              {selectedFlat ? `Members of ${selectedFlat.flat_number}` : "Select a flat"}
            </CardTitle>
            {isManager && selectedFlat && (
              <Button size="sm" onClick={() => setAddOpen(true)} data-testid="add-flat-member-btn">
                <UserPlus className="w-4 h-4 mr-1.5" /> Link Member
              </Button>
            )}
          </CardHeader>
          <CardContent>
            {!selectedFlat ? (
              <div className="text-center py-12 text-muted-foreground">
                <Home className="w-10 h-10 mx-auto mb-3 opacity-30" />
                <p>Select a flat from the left panel to view linked members</p>
              </div>
            ) : membersLoading ? (
              <div className="text-center py-8 text-muted-foreground">Loading...</div>
            ) : flatMembers.length === 0 ? (
              <div className="text-center py-12 text-muted-foreground">
                <Users className="w-10 h-10 mx-auto mb-3 opacity-30" />
                <p>No members linked to this flat</p>
                {isManager && (
                  <Button variant="outline" size="sm" className="mt-3" onClick={() => setAddOpen(true)}>
                    <UserPlus className="w-4 h-4 mr-1.5" /> Link First Member
                  </Button>
                )}
              </div>
            ) : (
              <div className="space-y-2">
                {flatMembers.map((fm) => (
                  <div
                    key={fm.id}
                    className="flex items-center gap-3 p-3 rounded-lg bg-white/[0.02] border border-white/[0.04]"
                    data-testid={`flat-member-${fm.id}`}
                  >
                    <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center text-primary text-xs font-bold">
                      {fm.user_name?.charAt(0) || "?"}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className="text-sm font-medium">{fm.user_name}</span>
                        {fm.is_primary && (
                          <Badge variant="outline" className="text-[9px] text-primary border-primary/30 bg-primary/10">
                            <Shield className="w-2.5 h-2.5 mr-0.5" /> PRIMARY
                          </Badge>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant="outline" className={`text-[10px] ${relationColors[fm.relation_type] || relationColors.Owner}`}>
                          {fm.relation_type}
                        </Badge>
                        <span className="text-[10px] text-muted-foreground">{fm.user_email}</span>
                      </div>
                    </div>
                    {isManager && (
                      <Button
                        variant="ghost" size="icon" className="h-8 w-8 text-destructive hover:text-destructive"
                        onClick={() => handleRemoveMember(fm.id)}
                        data-testid={`remove-fm-${fm.id}`}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    )}
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Add Flat Member Dialog */}
      <Dialog open={addOpen} onOpenChange={setAddOpen}>
        <DialogContent className="bg-card border-white/[0.08]" data-testid="add-flat-member-dialog">
          <DialogHeader>
            <DialogTitle>Link Member to {selectedFlat?.flat_number}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="space-y-1.5">
              <Label>Select Member</Label>
              <Select value={addForm.user_id} onValueChange={(v) => setAddForm({ ...addForm, user_id: v })}>
                <SelectTrigger className="bg-transparent" data-testid="fm-user-select">
                  <SelectValue placeholder="Choose society member" />
                </SelectTrigger>
                <SelectContent>
                  {societyMembers.map((m) => (
                    <SelectItem key={m.user_id} value={m.user_id}>
                      {m.user_name} ({m.user_email})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Relationship Type</Label>
              <Select value={addForm.relation_type} onValueChange={(v) => setAddForm({ ...addForm, relation_type: v })}>
                <SelectTrigger className="bg-transparent" data-testid="fm-relation-select">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Owner">Owner</SelectItem>
                  <SelectItem value="Family">Family</SelectItem>
                  <SelectItem value="Tenant">Tenant</SelectItem>
                  <SelectItem value="Partner">Partner</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex items-center gap-2">
              <input
                type="checkbox" id="is-primary"
                checked={addForm.is_primary}
                onChange={(e) => setAddForm({ ...addForm, is_primary: e.target.checked })}
                className="rounded border-white/20"
                data-testid="fm-is-primary"
              />
              <Label htmlFor="is-primary" className="text-sm cursor-pointer">
                Primary member (receives maintenance bill responsibility)
              </Label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAddOpen(false)}>Cancel</Button>
            <Button onClick={handleAddMember} disabled={submitting} data-testid="fm-submit">
              {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <UserPlus className="w-4 h-4 mr-2" />}
              Link Member
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
