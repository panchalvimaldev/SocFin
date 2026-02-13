import { useState, useEffect } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { useSociety } from "@/contexts/SocietyContext";
import api from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem,
  DropdownMenuTrigger, DropdownMenuSeparator, DropdownMenuLabel,
} from "@/components/ui/dropdown-menu";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  LayoutDashboard, ArrowLeftRight, Receipt, FileText,
  Bell, Users, Settings, LogOut, Building2, ChevronDown,
  PlusCircle, ClipboardCheck, BarChart3, Menu, X, Shield,
} from "lucide-react";

const navItems = {
  manager: [
    { label: "Dashboard", icon: LayoutDashboard, path: "/" },
    { label: "Transactions", icon: ArrowLeftRight, path: "/transactions" },
    { label: "Add Transaction", icon: PlusCircle, path: "/transactions/add" },
    { label: "Maintenance", icon: Receipt, path: "/maintenance" },
    { label: "Approvals", icon: ClipboardCheck, path: "/approvals" },
    { label: "Reports", icon: BarChart3, path: "/reports" },
    { label: "Members", icon: Users, path: "/members" },
    { label: "Notifications", icon: Bell, path: "/notifications" },
  ],
  committee: [
    { label: "Dashboard", icon: LayoutDashboard, path: "/" },
    { label: "Transactions", icon: ArrowLeftRight, path: "/transactions" },
    { label: "Approvals", icon: ClipboardCheck, path: "/approvals" },
    { label: "Reports", icon: BarChart3, path: "/reports" },
    { label: "Notifications", icon: Bell, path: "/notifications" },
  ],
  auditor: [
    { label: "Dashboard", icon: LayoutDashboard, path: "/" },
    { label: "Transactions", icon: ArrowLeftRight, path: "/transactions" },
    { label: "Maintenance", icon: Receipt, path: "/maintenance" },
    { label: "Reports", icon: BarChart3, path: "/reports" },
    { label: "Notifications", icon: Bell, path: "/notifications" },
  ],
  member: [
    { label: "Dashboard", icon: LayoutDashboard, path: "/" },
    { label: "Transactions", icon: ArrowLeftRight, path: "/transactions" },
    { label: "My Bills", icon: Receipt, path: "/maintenance" },
    { label: "Reports", icon: BarChart3, path: "/reports" },
    { label: "Notifications", icon: Bell, path: "/notifications" },
  ],
};

const roleColors = {
  manager: "bg-blue-500/20 text-blue-400 border-blue-500/30",
  committee: "bg-amber-500/20 text-amber-400 border-amber-500/30",
  auditor: "bg-purple-500/20 text-purple-400 border-purple-500/30",
  member: "bg-emerald-500/20 text-emerald-400 border-emerald-500/30",
};

export default function Layout({ children }) {
  const { user, logout } = useAuth();
  const { currentSociety, societies, selectSociety, role } = useSociety();
  const location = useLocation();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);

  const items = navItems[role] || navItems.member;

  useEffect(() => {
    if (currentSociety) {
      api.get(`/notifications/unread-count?society_id=${currentSociety.id}`)
        .then((r) => setUnreadCount(r.data.count))
        .catch(() => {});
    }
  }, [currentSociety, location.pathname]);

  return (
    <div className="flex h-screen overflow-hidden noise-bg">
      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-40 w-64 border-r border-white/[0.06] bg-[#0B0C10]/95 backdrop-blur-xl transition-transform duration-300 lg:translate-x-0 lg:static ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        }`}
        data-testid="sidebar"
      >
        <div className="flex items-center gap-3 px-5 py-5 border-b border-white/[0.06]">
          <div className="w-9 h-9 rounded-lg bg-primary/20 flex items-center justify-center">
            <Building2 className="w-5 h-5 text-primary" />
          </div>
          <div className="min-w-0">
            <h1 className="text-sm font-bold text-foreground truncate tracking-tight">SocietyFin</h1>
            <p className="text-[10px] text-muted-foreground uppercase tracking-[0.15em]">Financial Manager</p>
          </div>
        </div>

        <ScrollArea className="flex-1 h-[calc(100vh-140px)]">
          <nav className="px-3 py-4 space-y-1">
            {items.map((item) => {
              const isActive = location.pathname === item.path || 
                (item.path !== "/" && location.pathname.startsWith(item.path));
              const Icon = item.icon;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  data-testid={`nav-${item.label.toLowerCase().replace(/\s/g, "-")}`}
                  onClick={() => setSidebarOpen(false)}
                  className={`flex items-center gap-3 px-3 py-2.5 rounded-md text-sm transition-all duration-200 ${
                    isActive
                      ? "bg-primary/10 text-primary border border-primary/20"
                      : "text-muted-foreground hover:text-foreground hover:bg-white/[0.04]"
                  }`}
                >
                  <Icon className="w-4 h-4 shrink-0" />
                  <span className="truncate">{item.label}</span>
                  {item.label === "Notifications" && unreadCount > 0 && (
                    <span className="ml-auto w-5 h-5 rounded-full bg-destructive text-[10px] font-bold flex items-center justify-center text-white">
                      {unreadCount > 9 ? "9+" : unreadCount}
                    </span>
                  )}
                </Link>
              );
            })}
          </nav>
        </ScrollArea>

        <div className="px-3 py-3 border-t border-white/[0.06]">
          <div className={`px-3 py-2 rounded-md border text-xs font-medium ${roleColors[role] || roleColors.member}`}>
            <Shield className="w-3 h-3 inline mr-1.5" />
            {role.charAt(0).toUpperCase() + role.slice(1)}
          </div>
        </div>
      </aside>

      {/* Overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-30 bg-black/60 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Main */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Topbar */}
        <header className="sticky top-0 z-20 glass border-b border-white/[0.06] px-4 lg:px-6 h-14 flex items-center justify-between" data-testid="topbar">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" className="lg:hidden" onClick={() => setSidebarOpen(!sidebarOpen)} data-testid="mobile-menu-btn">
              {sidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </Button>

            {/* Society Switcher */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" className="gap-2 text-sm font-medium max-w-[240px]" data-testid="society-switcher">
                  <Building2 className="w-4 h-4 text-primary shrink-0" />
                  <span className="truncate">{currentSociety?.name || "Select Society"}</span>
                  <ChevronDown className="w-3.5 h-3.5 shrink-0 text-muted-foreground" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start" className="w-64">
                <DropdownMenuLabel className="text-xs text-muted-foreground uppercase tracking-wider">Your Societies</DropdownMenuLabel>
                {societies.map((s) => (
                  <DropdownMenuItem
                    key={s.id}
                    data-testid={`society-option-${s.id}`}
                    onClick={() => { selectSociety(s); navigate("/"); }}
                    className="flex items-center justify-between"
                  >
                    <span className="truncate">{s.name}</span>
                    <Badge variant="outline" className={`text-[10px] ${roleColors[s.role]}`}>
                      {s.role}
                    </Badge>
                  </DropdownMenuItem>
                ))}
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => navigate("/switch-society")} data-testid="switch-society-link">
                  <Settings className="w-3.5 h-3.5 mr-2" /> Manage Societies
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          <div className="flex items-center gap-2">
            <Button variant="ghost" size="icon" className="relative" onClick={() => navigate("/notifications")} data-testid="notif-btn">
              <Bell className="w-4.5 h-4.5" />
              {unreadCount > 0 && (
                <span className="absolute -top-0.5 -right-0.5 w-4 h-4 rounded-full bg-destructive text-[9px] font-bold flex items-center justify-center text-white">
                  {unreadCount > 9 ? "9+" : unreadCount}
                </span>
              )}
            </Button>

            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" className="gap-2 text-sm" data-testid="user-menu">
                  <div className="w-7 h-7 rounded-full bg-primary/20 flex items-center justify-center text-primary text-xs font-bold">
                    {user?.name?.charAt(0) || "U"}
                  </div>
                  <span className="hidden sm:inline truncate max-w-[120px]">{user?.name}</span>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-48">
                <DropdownMenuLabel className="text-xs text-muted-foreground">{user?.email}</DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => navigate("/switch-society")} data-testid="switch-society-menu">
                  <Building2 className="w-3.5 h-3.5 mr-2" /> Switch Society
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => { logout(); navigate("/login"); }} data-testid="logout-btn" className="text-destructive">
                  <LogOut className="w-3.5 h-3.5 mr-2" /> Logout
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </header>

        {/* Content */}
        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          <div className="max-w-[1400px] mx-auto animate-fade-in-up">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
