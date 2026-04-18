import { motion } from "framer-motion";
import {
    ArrowRightLeft,
    LayoutDashboard,
    LogOut,
    Settings,
    Users,
    Wallet,
} from "lucide-react";
import React from "react";
import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

const AdminLayout: React.FC = () => {
    const { logout } = useAuth();

    const navItems = [
        {
            path: "/admin",
            icon: <LayoutDashboard size={20} />,
            label: "Overview",
        },
        { path: "/users", icon: <Users size={20} />, label: "Users" },
        { path: "/wallets", icon: <Wallet size={20} />, label: "Wallets" },
        {
            path: "/exchange-rate",
            icon: <ArrowRightLeft size={20} />,
            label: "Exchange Rate",
        },
        { path: "/settings", icon: <Settings size={20} />, label: "Settings" },
    ];

    return (
        <div className="flex min-h-screen bg-bg-dark">
            {/* Sidebar */}
            <aside className="w-80 border-r border-white/5 bg-bg-dark/50 backdrop-blur-2xl sticky top-0 h-screen hidden lg:flex flex-col">
                <div className="p-10 border-b border-white/5">
                    <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center border border-primary/20 shadow-[0_0_20px_rgba(0,255,157,0.1)]">
                            <ArrowRightLeft className="text-primary" />
                        </div>
                        <div>
                            <h1 className="font-outfit font-bold text-xl text-white">
                                Admin Console
                            </h1>
                            <p className="text-[10px] font-bold text-primary uppercase tracking-widest mt-1">
                                Management Suite
                            </p>
                        </div>
                    </div>
                </div>

                <nav className="flex-1 p-6 space-y-2 overflow-y-auto">
                    {navItems.map((item) => (
                        <NavLink
                            key={item.path}
                            to={item.path}
                            className={({ isActive }) =>
                                `flex items-center gap-4 px-6 py-4 rounded-2xl transition-all duration-300 group ${
                                    isActive
                                        ? "bg-primary text-bg-dark font-bold shadow-lg shadow-primary/20 scale-[1.02]"
                                        : "text-text-dim hover:text-white hover:bg-white/5"
                                }`
                            }
                        >
                            <span className="transition-transform group-hover:scale-110">
                                {item.icon}
                            </span>
                            <span className="font-outfit tracking-wide">
                                {item.label}
                            </span>
                        </NavLink>
                    ))}
                </nav>

                <div className="p-6 border-t border-white/5">
                    <button
                        onClick={logout}
                        className="w-full flex items-center gap-4 px-6 py-4 rounded-2xl text-red-400 hover:bg-red-400/10 transition-all group font-bold"
                    >
                        <LogOut
                            size={20}
                            className="group-hover:-translate-x-1 transition-transform"
                        />
                        <span className="font-outfit">Logout</span>
                    </button>
                </div>
            </aside>

            {/* Mobile Navigation */}
            <div className="lg:hidden fixed bottom-6 left-6 right-6 z-50">
                <nav className="bg-bg-dark/80 backdrop-blur-2xl border border-white/10 p-3 rounded-full flex items-center justify-around shadow-2xl">
                    {navItems.map((item) => (
                        <NavLink
                            key={item.path}
                            to={item.path}
                            className={({ isActive }) =>
                                `p-4 rounded-full transition-all ${
                                    isActive
                                        ? "bg-primary text-bg-dark"
                                        : "text-text-dim"
                                }`
                            }
                        >
                            {item.icon}
                        </NavLink>
                    ))}
                </nav>
            </div>

            {/* Main Content */}
            <main className="flex-1 overflow-x-hidden">
                <div className="max-w-7xl mx-auto p-10 pb-32 lg:pb-10">
                    <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.4 }}
                    >
                        <Outlet />
                    </motion.div>
                </div>
            </main>
        </div>
    );
};

export default AdminLayout;
