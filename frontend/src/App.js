import "@/App.css";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Toaster } from "@/components/ui/sonner";
import { AuthProvider, useAuth } from "@/contexts/AuthContext";
import { SocietyProvider, useSociety } from "@/contexts/SocietyContext";

import Login from "@/pages/Login";
import Register from "@/pages/Register";
import SocietySwitch from "@/pages/SocietySwitch";
import CreateSociety from "@/pages/CreateSociety";
import Dashboard from "@/pages/Dashboard";
import Transactions from "@/pages/Transactions";
import AddTransaction from "@/pages/AddTransaction";
import Maintenance from "@/pages/Maintenance";
import FlatLedger from "@/pages/FlatLedger";
import Approvals from "@/pages/Approvals";
import Reports from "@/pages/Reports";
import Notifications from "@/pages/Notifications";
import Members from "@/pages/Members";
import FlatMembers from "@/pages/FlatMembers";
import SocietySettings from "@/pages/SocietySettings";
import Layout from "@/components/Layout";

function ProtectedRoute({ children }) {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return children;
}

function SocietyRoute({ children }) {
  const { isAuthenticated } = useAuth();
  const { currentSociety } = useSociety();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (!currentSociety) return <Navigate to="/switch-society" replace />;
  return <Layout>{children}</Layout>;
}

function AppRoutes() {
  const { isAuthenticated } = useAuth();

  return (
    <Routes>
      <Route path="/login" element={isAuthenticated ? <Navigate to="/switch-society" /> : <Login />} />
      <Route path="/register" element={isAuthenticated ? <Navigate to="/switch-society" /> : <Register />} />
      <Route path="/switch-society" element={
        <ProtectedRoute><SocietySwitch /></ProtectedRoute>
      } />
      <Route path="/" element={<SocietyRoute><Dashboard /></SocietyRoute>} />
      <Route path="/transactions" element={<SocietyRoute><Transactions /></SocietyRoute>} />
      <Route path="/transactions/add" element={<SocietyRoute><AddTransaction /></SocietyRoute>} />
      <Route path="/maintenance" element={<SocietyRoute><Maintenance /></SocietyRoute>} />
      <Route path="/approvals" element={<SocietyRoute><Approvals /></SocietyRoute>} />
      <Route path="/reports" element={<SocietyRoute><Reports /></SocietyRoute>} />
      <Route path="/notifications" element={<SocietyRoute><Notifications /></SocietyRoute>} />
      <Route path="/members" element={<SocietyRoute><Members /></SocietyRoute>} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <SocietyProvider>
          <AppRoutes />
          <Toaster position="top-right" richColors />
        </SocietyProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
