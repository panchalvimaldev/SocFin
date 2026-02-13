import { useNavigate } from "react-router-dom";
import { useSociety } from "@/contexts/SocietyContext";
import { useAuth } from "@/contexts/AuthContext";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Building2, MapPin, Home, ArrowRight, Plus } from "lucide-react";

const roleColors = {
  manager: "bg-blue-500/20 text-blue-400 border-blue-500/30",
  committee: "bg-amber-500/20 text-amber-400 border-amber-500/30",
  auditor: "bg-purple-500/20 text-purple-400 border-purple-500/30",
  member: "bg-emerald-500/20 text-emerald-400 border-emerald-500/30",
};

export default function SocietySwitch() {
  const { societies, selectSociety, loading } = useSociety();
  const { user } = useAuth();
  const navigate = useNavigate();

  const handleSelect = (society) => {
    selectSociety(society);
    navigate("/");
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-4 relative">
      <div className="absolute inset-0 bg-[#0B0C10]">
        <div className="absolute inset-0 opacity-10"
          style={{
            backgroundImage: `url(https://images.unsplash.com/photo-1758448501006-42ef007449ff?w=1920&q=60)`,
            backgroundSize: "cover", backgroundPosition: "center",
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0B0C10] via-[#0B0C10]/90 to-[#0B0C10]/70" />
      </div>

      <div className="relative z-10 w-full max-w-2xl">
        <div className="text-center mb-8">
          <div className="mx-auto w-16 h-16 rounded-2xl bg-primary/20 flex items-center justify-center mb-4">
            <Building2 className="w-8 h-8 text-primary" />
          </div>
          <h1 className="text-3xl font-bold tracking-tight mb-2" data-testid="society-switch-title">
            Welcome, {user?.name?.split(" ")[0]}
          </h1>
          <p className="text-muted-foreground">Choose a society to continue</p>
        </div>

        {loading ? (
          <div className="text-center text-muted-foreground py-8">Loading societies...</div>
        ) : societies.length === 0 ? (
          <Card className="bg-card/60 backdrop-blur border-white/[0.08]">
            <CardContent className="py-12 text-center">
              <Building2 className="w-12 h-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-semibold mb-2">No Societies Yet</h3>
              <p className="text-muted-foreground text-sm mb-4">
                Create a new society or ask a manager to add you.
              </p>
              <Button onClick={() => navigate("/create-society")} data-testid="create-society-btn">
                <Plus className="w-4 h-4 mr-2" /> Create Society
              </Button>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-3">
            {societies.map((society, i) => (
              <Card
                key={society.id}
                className={`bg-card/60 backdrop-blur border-white/[0.08] cursor-pointer hover:border-primary/40 transition-all duration-300 hover:-translate-y-0.5 stagger-${i + 1} animate-fade-in-up`}
                data-testid={`society-card-${society.id}`}
                onClick={() => handleSelect(society)}
              >
                <CardContent className="p-5 flex items-center gap-4">
                  <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center shrink-0">
                    <Building2 className="w-6 h-6 text-primary" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold truncate">{society.name}</h3>
                      <Badge variant="outline" className={`text-[10px] shrink-0 ${roleColors[society.role]}`}>
                        {society.role}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-3 text-xs text-muted-foreground">
                      <span className="flex items-center gap-1">
                        <MapPin className="w-3 h-3" /> {society.address}
                      </span>
                      <span className="flex items-center gap-1">
                        <Home className="w-3 h-3" /> {society.total_flats} flats
                      </span>
                    </div>
                  </div>
                  <ArrowRight className="w-5 h-5 text-muted-foreground shrink-0" />
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
