import React from "react";
import {
    Navigate,
    Route,
    BrowserRouter as Router,
    Routes,
} from "react-router-dom";
import AdminLayout from "./components/AdminLayout";
import UserLayout from "./components/UserLayout";
import { AuthProvider, useAuth } from "./context/AuthContext";
import ExchangeRate from "./pages/admin/ExchangeRate";
import AdminOverview from "./pages/admin/Overview";
import Settings from "./pages/admin/Settings";
import Users from "./pages/admin/Users";
import UserOverview from "./pages/user/Overview";
import History from "./pages/user/History";
import BankAccounts from "./pages/user/BankAccounts";
import Profile from "./pages/user/Profile";
import Home from "./pages/Home";
import Login from "./pages/Login";
import Wallets from "./pages/admin/Wallets";

const ProtectedRoute: React.FC<{
    children: React.ReactNode;
    allowedRole?: "ADMIN" | "USER";
}> = ({ children, allowedRole }) => {
    const { user, isLoading } = useAuth();

    if (isLoading)
        return (
            <div className="min-h-screen bg-[#050505] flex items-center justify-center">
                <div className="w-12 h-12 border-4 border-primary/20 border-t-primary rounded-full animate-spin" />
            </div>
        );

    if (!user) return <Navigate to="/login" />;
    if (allowedRole && user.role !== allowedRole) return <Navigate to="/" />;
    return <>{children}</>;
};

const App: React.FC = () => {
    return (
        <Router>
            <AuthProvider>
                <Routes>
                    <Route path="/login" element={<Login />} />

                    <Route
                        path="/"
                        element={
                            <ProtectedRoute>
                                <Home />
                            </ProtectedRoute>
                        }
                    />

                    {/* Admin Routes */}
                    <Route
                        element={
                            <ProtectedRoute allowedRole="ADMIN">
                                <AdminLayout />
                            </ProtectedRoute>
                        }
                    >
                        <Route path="/admin" element={<AdminOverview />} />
                        <Route path="/users" element={<Users />} />
                        <Route
                            path="/exchange-rate"
                            element={<ExchangeRate />}
                        />
                        <Route path="/settings" element={<Settings />} />
                        <Route path="/wallets" element={<Wallets />} />
                    </Route>

                    {/* User Routes */}
                    <Route
                        element={
                            <ProtectedRoute allowedRole="USER">
                                <UserLayout />
                            </ProtectedRoute>
                        }
                    >
                        <Route path="/dashboard" element={<UserOverview />} />
                        <Route path="/history" element={<History />} />
                        <Route
                            path="/bank-accounts"
                            element={<BankAccounts />}
                        />
                        <Route path="/profile" element={<Profile />} />
                    </Route>

                    <Route path="*" element={<Navigate to="/" />} />
                </Routes>
            </AuthProvider>
        </Router>
    );
};

export default App;
