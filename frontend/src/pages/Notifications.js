import { useState, useEffect } from "react";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Bell, CheckCheck, Clock, AlertTriangle, Receipt, Info } from "lucide-react";
import { toast } from "sonner";

const typeIcons = {
  approval: AlertTriangle,
  billing: Receipt,
  system: Info,
};
const typeColors = {
  approval: "text-amber-400 bg-amber-500/10",
  billing: "text-blue-400 bg-blue-500/10",
  system: "text-emerald-400 bg-emerald-500/10",
};

export default function Notifications() {
  const { currentSociety } = useSociety();
  const [notifs, setNotifs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!currentSociety) return;
    fetchNotifs();
  }, [currentSociety]);

  const fetchNotifs = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/notifications/?society_id=${currentSociety.id}`);
      setNotifs(res.data);
    } catch (err) {
      console.error(err);
    }
    setLoading(false);
  };

  const markRead = async (id) => {
    try {
      await api.put(`/notifications/${id}/read`);
      setNotifs(notifs.map((n) => n.id === id ? { ...n, read: true } : n));
    } catch (err) {
      console.error(err);
    }
  };

  const markAllRead = async () => {
    try {
      await api.post(`/notifications/mark-all-read?society_id=${currentSociety.id}`);
      setNotifs(notifs.map((n) => ({ ...n, read: true })));
      toast.success("All notifications marked as read");
    } catch (err) {
      console.error(err);
    }
  };

  const unreadCount = notifs.filter((n) => !n.read).length;

  return (
    <div data-testid="notifications-page">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Notifications</h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {unreadCount} unread notification{unreadCount !== 1 ? "s" : ""}
          </p>
        </div>
        {unreadCount > 0 && (
          <Button variant="outline" size="sm" onClick={markAllRead} data-testid="mark-all-read">
            <CheckCheck className="w-4 h-4 mr-1.5" /> Mark All Read
          </Button>
        )}
      </div>

      {loading ? (
        <div className="text-center text-muted-foreground py-8">Loading...</div>
      ) : notifs.length === 0 ? (
        <Card className="bg-card border-white/[0.06]">
          <CardContent className="py-12 text-center">
            <Bell className="w-10 h-10 mx-auto mb-3 text-muted-foreground opacity-30" />
            <p className="text-muted-foreground">No notifications yet</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {notifs.map((notif) => {
            const Icon = typeIcons[notif.type] || Bell;
            const colorClass = typeColors[notif.type] || typeColors.system;
            return (
              <Card
                key={notif.id}
                className={`bg-card border-white/[0.06] transition-colors ${!notif.read ? "border-l-2 border-l-primary" : "opacity-70"}`}
                data-testid={`notif-${notif.id}`}
              >
                <CardContent className="p-4 flex items-start gap-3">
                  <div className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 ${colorClass}`}>
                    <Icon className="w-4 h-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <h3 className={`text-sm font-medium truncate ${!notif.read ? "text-foreground" : "text-muted-foreground"}`}>
                        {notif.title}
                      </h3>
                      {!notif.read && (
                        <div className="w-2 h-2 rounded-full bg-primary shrink-0" />
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground">{notif.message}</p>
                    <div className="flex items-center gap-2 mt-2">
                      <span className="text-[10px] text-muted-foreground flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {new Date(notif.created_at).toLocaleDateString()} {new Date(notif.created_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
                      </span>
                    </div>
                  </div>
                  {!notif.read && (
                    <Button
                      variant="ghost" size="sm" className="text-xs shrink-0"
                      onClick={() => markRead(notif.id)}
                      data-testid={`mark-read-${notif.id}`}
                    >
                      Mark Read
                    </Button>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
