import { createContext, useContext, useState, useEffect, useCallback } from "react";
import api from "@/lib/api";
import { useAuth } from "./AuthContext";

const SocietyContext = createContext(null);

export function SocietyProvider({ children }) {
  const { isAuthenticated } = useAuth();
  const [societies, setSocieties] = useState([]);
  const [currentSociety, setCurrentSociety] = useState(() => {
    const stored = localStorage.getItem("sfm_society");
    return stored ? JSON.parse(stored) : null;
  });
  const [loading, setLoading] = useState(false);

  const fetchSocieties = useCallback(async () => {
    if (!isAuthenticated) return;
    setLoading(true);
    try {
      const res = await api.get("/societies/");
      setSocieties(res.data);
      // Auto-select if only one or restore stored
      if (res.data.length === 1 && !currentSociety) {
        selectSociety(res.data[0]);
      } else if (currentSociety) {
        const found = res.data.find((s) => s.id === currentSociety.id);
        if (found) selectSociety(found);
        else if (res.data.length > 0) selectSociety(res.data[0]);
      }
    } catch (err) {
      console.error("Failed to fetch societies:", err);
    } finally {
      setLoading(false);
    }
  }, [isAuthenticated]);

  useEffect(() => {
    fetchSocieties();
  }, [fetchSocieties]);

  const selectSociety = (society) => {
    setCurrentSociety(society);
    localStorage.setItem("sfm_society", JSON.stringify(society));
  };

  return (
    <SocietyContext.Provider
      value={{
        societies,
        currentSociety,
        selectSociety,
        loading,
        refreshSocieties: fetchSocieties,
        role: currentSociety?.role || "member",
        isManager: currentSociety?.role === "manager",
        isCommittee: currentSociety?.role === "committee",
        isAuditor: currentSociety?.role === "auditor",
      }}
    >
      {children}
    </SocietyContext.Provider>
  );
}

export const useSociety = () => useContext(SocietyContext);
