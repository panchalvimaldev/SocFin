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
import { Users, UserPlus, Home, Shield, Loader2, Mail, Phone } from "lucide-react";
import { toast } from "sonner";

const roleColors = {
  manager: "text-blue-400 border-blue-500/30 bg-blue-500/10",
  committee: "text-amber-400 border-amber-500/30 bg-amber-500/10",
  auditor: "text-purple-400 border-purple-500/30 bg-purple-500/10",
  member: "text-emerald-400 border-emerald-500/30 bg-emerald-500/10",
};

export default function Members() {
  const { currentSociety, isManager } = useSociety();
  const [members, setMembers] = useState([]);
  const [flats, setFlats] = useState([]);
  const [loading, setLoading] = useState(true);
  const [addOpen, setAddOpen] = useState(false);
  const [addForm, setAddForm] = useState({ email: "", role: "member" });
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!currentSociety) return;
    Promise.all([
      api.get(`/societies/${currentSociety.id}/members`),
      api.get(`/societies/${currentSociety.id}/flats`),
    ])
      .then(([mRes, fRes]) => {
        setMembers(mRes.data);
        setFlats(fRes.data);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [currentSociety]);

  const handleAddMember = async () => {
    if (!addForm.email) {
      toast.error("Please enter an email");
      return;
    }
    setSubmitting(true);
    try {
      await api.post(`/societies/${currentSociety.id}/members`, {
        email: addForm.email,
        role: addForm.role,
      });
      toast.success("Member added successfully");
      setAddOpen(false);
      setAddForm({ email: "", role: "member" });
      const res = await api.get(`/societies/${currentSociety.id}/members`);
      setMembers(res.data);
    } catch (err) {
      toast.error(err.response?.data?.detail || "Failed to add member");
    }
    setSubmitting(false);
  };

  const handleRoleChange = async (membershipId, newRole) => {
    try {
      await api.put(`/societies/${currentSociety.id}/members/${membershipId}?role=${newRole}`);
      toast.success("Role updated");
      setMembers(members.map((m) => m.id === membershipId ? { ...m, role: newRole } : m));
    } catch (err) {
      toast.error("Failed to update role");
    }
  };

  return (
    <div data-testid="members-page">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Members & Flats</h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {members.length} members | {flats.length} flats
          </p>
        </div>
        {isManager && (
          <Button onClick={() => setAddOpen(true)} data-testid="add-member-btn">
            <UserPlus className="w-4 h-4 mr-1.5" /> Add Member
          </Button>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Members List */}
        <div className="lg:col-span-2">
          <Card className="bg-card border-white/[0.06]">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <Users className="w-4 h-4 text-primary" /> Society Members
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {loading ? (
                <div className="p-8 text-center text-muted-foreground">Loading...</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="border-b border-white/[0.06]">
                        <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Name</th>
                        <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3 hidden sm:table-cell">Email</th>
                        <th className="text-center text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Role</th>
                        <th className="text-center text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {members.map((m) => (
                        <tr key={m.id} className="border-b border-white/[0.04] hover:bg-white/[0.02]" data-testid={`member-row-${m.id}`}>
                          <td className="px-4 py-3">
                            <div className="flex items-center gap-2">
                              <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-primary text-xs font-bold">
                                {m.user_name?.charAt(0) || "?"}
                              </div>
                              <span className="text-sm font-medium">{m.user_name}</span>
                            </div>
                          </td>
                          <td className="px-4 py-3 text-sm text-muted-foreground hidden sm:table-cell">{m.user_email}</td>
                          <td className="px-4 py-3 text-center">
                            {isManager ? (
                              <Select value={m.role} onValueChange={(v) => handleRoleChange(m.id, v)}>
                                <SelectTrigger className="w-[120px] h-7 text-xs bg-transparent mx-auto" data-testid={`role-select-${m.id}`}>
                                  <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                  <SelectItem value="member">Member</SelectItem>
                                  <SelectItem value="manager">Manager</SelectItem>
                                  <SelectItem value="committee">Committee</SelectItem>
                                  <SelectItem value="auditor">Auditor</SelectItem>
                                </SelectContent>
                              </Select>
                            ) : (
                              <Badge variant="outline" className={`text-[10px] ${roleColors[m.role]}`}>
                                {m.role}
                              </Badge>
                            )}
                          </td>
                          <td className="px-4 py-3 text-center">
                            <Badge variant="outline" className={`text-[10px] ${m.status === "active" ? "text-emerald-400 border-emerald-500/30" : "text-red-400 border-red-500/30"}`}>
                              {m.status}
                            </Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Flats Summary */}
        <Card className="bg-card border-white/[0.06]">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium flex items-center gap-2">
              <Home className="w-4 h-4 text-primary" /> Flats ({flats.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 max-h-[400px] overflow-y-auto">
              {flats.slice(0, 20).map((flat) => (
                <div key={flat.id} className="flex items-center justify-between p-2.5 rounded-lg bg-white/[0.02] border border-white/[0.04]" data-testid={`flat-${flat.id}`}>
                  <div>
                    <p className="text-sm font-medium">{flat.flat_number}</p>
                    <p className="text-[10px] text-muted-foreground">{flat.flat_type} | {flat.wing} Wing | Floor {flat.floor}</p>
                  </div>
                  <span className="text-[10px] text-muted-foreground font-mono-financial">{flat.area_sqft} sqft</span>
                </div>
              ))}
              {flats.length > 20 && (
                <p className="text-xs text-muted-foreground text-center py-2">
                  +{flats.length - 20} more flats
                </p>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Add Member Dialog */}
      <Dialog open={addOpen} onOpenChange={setAddOpen}>
        <DialogContent className="bg-card border-white/[0.08]" data-testid="add-member-dialog">
          <DialogHeader>
            <DialogTitle>Add Member to Society</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="space-y-1.5">
              <Label>User Email</Label>
              <Input
                placeholder="Enter registered email"
                value={addForm.email}
                onChange={(e) => setAddForm({ ...addForm, email: e.target.value })}
                data-testid="add-member-email"
                className="bg-transparent"
              />
              <p className="text-[10px] text-muted-foreground">User must already be registered</p>
            </div>
            <div className="space-y-1.5">
              <Label>Role</Label>
              <Select value={addForm.role} onValueChange={(v) => setAddForm({ ...addForm, role: v })}>
                <SelectTrigger className="bg-transparent" data-testid="add-member-role">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="member">Member</SelectItem>
                  <SelectItem value="committee">Committee</SelectItem>
                  <SelectItem value="auditor">Auditor</SelectItem>
                  <SelectItem value="manager">Manager</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAddOpen(false)}>Cancel</Button>
            <Button onClick={handleAddMember} disabled={submitting} data-testid="add-member-submit">
              {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <UserPlus className="w-4 h-4 mr-2" />}
              Add Member
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
