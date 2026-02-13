import { useState, useEffect } from "react";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from "@/components/ui/dialog";
import {
  ClipboardCheck, CheckCircle2, XCircle, Loader2,
  IndianRupee, User, Calendar,
} from "lucide-react";
import { toast } from "sonner";

const statusStyles = {
  pending: "text-amber-400 border-amber-500/30 bg-amber-500/10",
  approved: "text-emerald-400 border-emerald-500/30 bg-emerald-500/10",
  rejected: "text-red-400 border-red-500/30 bg-red-500/10",
};

export default function Approvals() {
  const { currentSociety, role } = useSociety();
  const [approvals, setApprovals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionDialog, setActionDialog] = useState(null);
  const [comments, setComments] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const canApprove = role === "committee" || role === "manager";

  useEffect(() => {
    if (!currentSociety) return;
    fetchApprovals();
  }, [currentSociety]);

  const fetchApprovals = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/societies/${currentSociety.id}/approvals/`);
      setApprovals(res.data);
    } catch (err) {
      console.error(err);
    }
    setLoading(false);
  };

  const handleAction = async (action) => {
    setSubmitting(true);
    try {
      await api.post(`/societies/${currentSociety.id}/approvals/${actionDialog.id}/${action}`, {
        comments,
      });
      toast.success(`Expense ${action}d successfully`);
      setActionDialog(null);
      setComments("");
      fetchApprovals();
    } catch (err) {
      toast.error(err.response?.data?.detail || `Failed to ${action}`);
    }
    setSubmitting(false);
  };

  const pending = approvals.filter((a) => a.status === "pending");
  const processed = approvals.filter((a) => a.status !== "pending");

  return (
    <div data-testid="approvals-page">
      <div className="mb-6">
        <h1 className="text-2xl font-bold tracking-tight">Expense Approvals</h1>
        <p className="text-sm text-muted-foreground mt-0.5">
          {pending.length} pending approval{pending.length !== 1 ? "s" : ""}
        </p>
      </div>

      {/* Pending */}
      {pending.length > 0 && (
        <div className="mb-6">
          <h2 className="text-sm font-medium text-muted-foreground uppercase tracking-wider mb-3">Pending Approval</h2>
          <div className="space-y-3">
            {pending.map((appr) => (
              <Card key={appr.id} className="bg-card border-amber-500/20 hover:border-amber-500/40 transition-colors" data-testid={`approval-${appr.id}`}>
                <CardContent className="p-4">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-2">
                        <Badge variant="outline" className={statusStyles.pending}>Pending</Badge>
                        <span className="text-sm font-medium">{appr.transaction?.category || "Expense"}</span>
                      </div>
                      <p className="text-2xl font-bold font-mono-financial text-amber-400 mb-2">
                        Rs.{(appr.transaction?.amount || 0).toLocaleString()}
                      </p>
                      <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <User className="w-3 h-3" /> {appr.requested_by_name}
                        </span>
                        <span className="flex items-center gap-1">
                          <Calendar className="w-3 h-3" /> {appr.created_at?.slice(0, 10)}
                        </span>
                        {appr.transaction?.vendor_name && (
                          <span>Vendor: {appr.transaction.vendor_name}</span>
                        )}
                      </div>
                      {appr.transaction?.description && (
                        <p className="text-sm text-muted-foreground mt-2">{appr.transaction.description}</p>
                      )}
                    </div>
                    {canApprove && (
                      <div className="flex gap-2 shrink-0">
                        <Button
                          size="sm" onClick={() => setActionDialog({ ...appr, action: "approve" })}
                          className="bg-emerald-600 hover:bg-emerald-700" data-testid={`approve-btn-${appr.id}`}
                        >
                          <CheckCircle2 className="w-4 h-4 mr-1" /> Approve
                        </Button>
                        <Button
                          size="sm" variant="destructive" onClick={() => setActionDialog({ ...appr, action: "reject" })}
                          data-testid={`reject-btn-${appr.id}`}
                        >
                          <XCircle className="w-4 h-4 mr-1" /> Reject
                        </Button>
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* Processed */}
      {processed.length > 0 && (
        <div>
          <h2 className="text-sm font-medium text-muted-foreground uppercase tracking-wider mb-3">History</h2>
          <Card className="bg-card border-white/[0.06]">
            <CardContent className="p-0">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-white/[0.06]">
                      <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Category</th>
                      <th className="text-right text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Amount</th>
                      <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3 hidden sm:table-cell">Requested By</th>
                      <th className="text-left text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3 hidden md:table-cell">Approved By</th>
                      <th className="text-center text-[11px] uppercase tracking-wider text-muted-foreground font-medium px-4 py-3">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {processed.map((a) => (
                      <tr key={a.id} className="border-b border-white/[0.04]" data-testid={`history-${a.id}`}>
                        <td className="px-4 py-3 text-sm">{a.transaction?.category || "-"}</td>
                        <td className="px-4 py-3 text-right font-mono-financial text-sm">Rs.{(a.transaction?.amount || 0).toLocaleString()}</td>
                        <td className="px-4 py-3 text-sm text-muted-foreground hidden sm:table-cell">{a.requested_by_name}</td>
                        <td className="px-4 py-3 text-sm text-muted-foreground hidden md:table-cell">{a.approved_by_name || "-"}</td>
                        <td className="px-4 py-3 text-center">
                          <Badge variant="outline" className={`text-[10px] ${statusStyles[a.status]}`}>{a.status}</Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {pending.length === 0 && processed.length === 0 && !loading && (
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="py-12 text-center">
            <ClipboardCheck className="w-10 h-10 mx-auto mb-3 text-muted-foreground opacity-30" />
            <p className="text-muted-foreground">No approval requests</p>
          </CardContent>
        </Card>
      )}

      {/* Action Dialog */}
      <Dialog open={!!actionDialog} onOpenChange={() => { setActionDialog(null); setComments(""); }}>
        <DialogContent className="bg-card border-white/[0.08]" data-testid="approval-action-dialog">
          <DialogHeader>
            <DialogTitle>
              {actionDialog?.action === "approve" ? "Approve" : "Reject"} Expense
            </DialogTitle>
          </DialogHeader>
          <div className="py-2">
            <div className="p-3 rounded-lg bg-white/[0.03] border border-white/[0.06] mb-4">
              <p className="text-sm text-muted-foreground mb-1">{actionDialog?.transaction?.category}</p>
              <p className="text-xl font-bold font-mono-financial">
                Rs.{(actionDialog?.transaction?.amount || 0).toLocaleString()}
              </p>
            </div>
            <div className="space-y-1.5">
              <label className="text-sm font-medium">Comments (optional)</label>
              <Textarea
                value={comments} onChange={(e) => setComments(e.target.value)}
                placeholder="Add a comment..." className="bg-transparent resize-none"
                data-testid="approval-comments"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => { setActionDialog(null); setComments(""); }}>Cancel</Button>
            <Button
              onClick={() => handleAction(actionDialog?.action)}
              disabled={submitting}
              className={actionDialog?.action === "approve" ? "bg-emerald-600 hover:bg-emerald-700" : ""}
              variant={actionDialog?.action === "reject" ? "destructive" : "default"}
              data-testid="confirm-action-btn"
            >
              {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
              {actionDialog?.action === "approve" ? "Approve" : "Reject"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
