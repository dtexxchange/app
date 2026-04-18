import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    Activity,
    Mail,
    Plus,
    Search,
    ShieldCheck,
    Users as UsersIcon,
    XCircle,
} from "lucide-react";
import React, { useCallback, useEffect, useState } from "react";
import api from "../../lib/api";

const Users: React.FC = () => {
    const [users, setUsers] = useState<any[]>([]);
    const [isAddUserOpen, setIsAddUserOpen] = useState(false);
    const [newUser, setNewUser] = useState({ email: "", role: "USER" });
    const [userFilter, setUserFilter] = useState({ search: "", role: "" });
    const [selectedUser, setSelectedUser] = useState<any>(null);
    const [isDepositModalOpen, setIsDepositModalOpen] = useState(false);
    const [depositAmount, setDepositAmount] = useState("");

    const fetchUsers = useCallback(async () => {
        try {
            const params = new URLSearchParams();
            if (userFilter.search) params.append("search", userFilter.search);
            if (userFilter.role) params.append("role", userFilter.role);

            const { data } = await api.get(`/users?${params.toString()}`);
            setUsers(data);
        } catch (e) {
            console.error(e);
        }
    }, [userFilter]);

    useEffect(() => {
        fetchUsers();
    }, [fetchUsers]);

    const handleAddUser = async () => {
        try {
            await api.post("/users", newUser);
            setIsAddUserOpen(false);
            setNewUser({ email: "", role: "USER" });
            fetchUsers();
        } catch (err: any) {
            console.error(err);
        }
    };

    const loadUserDetails = async (id: string) => {
        try {
            const { data } = await api.get(`/users/${id}`);
            setSelectedUser(data);
        } catch (e) {
            console.error(e);
        }
    };

    const handleAdminDeposit = async () => {
        if (!selectedUser || !depositAmount || isNaN(parseFloat(depositAmount)))
            return;
        try {
            await api.post("/wallet/admin/deposit", {
                userId: selectedUser.id,
                amount: parseFloat(depositAmount),
            });
            setIsDepositModalOpen(false);
            setDepositAmount("");
            loadUserDetails(selectedUser.id);
            fetchUsers();
        } catch (err: any) {
            console.error(err);
        }
    };

    return (
        <div className="space-y-8">
            <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                        User Directory
                    </h1>
                    <p className="text-text-dim font-medium">
                        Manage platform access and whitelisted accounts.
                    </p>
                </div>
                <button
                    onClick={() => setIsAddUserOpen(true)}
                    className="btn-primary px-8 py-4 flex items-center gap-3 active:scale-95 transition-transform"
                >
                    <Plus size={20} className="stroke-3" /> Add to Whitelist
                </button>
            </header>

            <div className="glass overflow-hidden">
                <div className="p-8 border-b border-white/5 flex flex-col md:flex-row items-center gap-6 justify-between bg-white/1">
                    <div className="flex items-center gap-4 w-full md:w-auto overflow-x-auto pb-4 md:pb-0 scrollbar-hide">
                        {["", "USER", "ADMIN"].map((role) => (
                            <button
                                key={role}
                                onClick={() =>
                                    setUserFilter({ ...userFilter, role })
                                }
                                className={`px-5 py-2 rounded-full text-[10px] font-bold uppercase tracking-widest border transition-all shrink-0 ${
                                    userFilter.role === role
                                        ? "bg-primary border-primary text-bg-dark"
                                        : "border-white/10 text-text-dim hover:border-white/20 hover:text-white"
                                }`}
                            >
                                {role || "All Roles"}
                            </button>
                        ))}
                    </div>

                    <div className="relative w-full md:w-80">
                        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-dim w-4 h-4" />
                        <input
                            type="text"
                            placeholder="Find whitelisted users..."
                            className="w-full bg-white/5 border border-white/10 rounded-xl pl-11 pr-4 py-3 text-sm focus:ring-2 focus:ring-primary/20 focus:outline-none focus:border-primary text-white transition-all"
                            value={userFilter.search}
                            onChange={(e) =>
                                setUserFilter({
                                    ...userFilter,
                                    search: e.target.value,
                                })
                            }
                        />
                    </div>
                </div>

                <div className="w-full overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-xs font-semibold tracking-widest uppercase">
                                <th className="px-8 py-5">Verified Identity</th>
                                <th className="px-8 py-5">Platform Role</th>
                                <th className="px-8 py-5">Available Balance</th>
                                <th className="px-8 py-5 text-right">
                                    Join Date
                                </th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {users.map((u) => (
                                <tr
                                    key={u.id}
                                    className="hover:bg-white/2 cursor-pointer transition-colors"
                                    onClick={() => loadUserDetails(u.id)}
                                >
                                    <td className="px-8 py-6">
                                        <div className="flex items-center gap-4">
                                            <div className="w-10 h-10 rounded-xl bg-accent-blue/10 flex items-center justify-center border border-accent-blue/20 text-accent-blue text-sm font-bold">
                                                {u.email[0].toUpperCase()}
                                            </div>
                                            <div>
                                                <div className="font-bold text-white mb-0.5">
                                                    {u.email}
                                                </div>
                                                <div className="text-[10px] text-text-dim font-mono tracking-tighter">
                                                    UID:{" "}
                                                    {u.id
                                                        .substring(0, 8)
                                                        .toUpperCase()}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-8 py-6">
                                        <span
                                            className={`px-3 py-1 rounded-lg text-[10px] font-bold uppercase tracking-widest border ${u.role === "ADMIN" ? "border-primary/40 text-primary bg-primary/5" : "border-white/10 text-white bg-white/5"}`}
                                        >
                                            {u.role}
                                        </span>
                                    </td>
                                    <td className="px-8 py-6">
                                        <div className="text-base font-outfit font-bold text-white">
                                            {u.balance.toLocaleString()}{" "}
                                            <span className="text-[10px] text-primary/60 font-bold tracking-widest ml-1">
                                                USDT
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-8 py-6 text-right">
                                        <div className="text-xs text-text-dim font-medium">
                                            {format(
                                                new Date(u.createdAt),
                                                "MMM dd, yyyy",
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    {users.length === 0 && (
                        <div className="py-20 text-center">
                            <UsersIcon
                                className="mx-auto text-white/5 mb-4"
                                size={48}
                            />
                            <p className="text-text-dim text-sm font-medium italic">
                                No users found in the system registry.
                            </p>
                        </div>
                    )}
                </div>
            </div>

            {/* Add User Modal */}
            <AnimatePresence>
                {isAddUserOpen && (
                    <div className="fixed inset-0 z-100 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            className="glass-panel p-10 w-full max-w-md shadow-2xl border-white/10"
                        >
                            <h2 className="text-3xl font-outfit font-bold mb-3 flex items-center gap-3 uppercase tracking-tight">
                                <Plus className="text-primary" /> Whitelist
                                Account
                            </h2>
                            <p className="text-text-dim text-sm mb-10 leading-relaxed font-medium">
                                Grant decentralized ledger access to a new
                                identity by verifying their email address.
                            </p>

                            <div className="space-y-6">
                                <div>
                                    <label className="text-[10px] font-bold text-text-dim uppercase tracking-widest mb-3 block">
                                        Email Connection
                                    </label>
                                    <div className="relative">
                                        <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-text-dim w-4 h-4" />
                                        <input
                                            type="email"
                                            className="input-field pl-12"
                                            placeholder="identity@network.app"
                                            value={newUser.email}
                                            onChange={(e) =>
                                                setNewUser({
                                                    ...newUser,
                                                    email: e.target.value,
                                                })
                                            }
                                        />
                                    </div>
                                </div>

                                <div>
                                    <label className="text-[10px] font-bold text-text-dim uppercase tracking-widest mb-3 block">
                                        Authorized Role
                                    </label>
                                    <div className="flex gap-4">
                                        {["USER", "ADMIN"].map((r) => (
                                            <button
                                                key={r}
                                                onClick={() =>
                                                    setNewUser({
                                                        ...newUser,
                                                        role: r,
                                                    })
                                                }
                                                className={`flex-1 py-4 rounded-xl text-xs font-bold transition-all border ${
                                                    newUser.role === r
                                                        ? "bg-primary border-primary text-bg-dark shadow-[0_4px_15px_rgba(0,255,157,0.2)]"
                                                        : "border-white/10 text-text-dim hover:border-white/20"
                                                }`}
                                            >
                                                {r}
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            </div>

                            <div className="flex gap-4 mt-10">
                                <button
                                    onClick={() => setIsAddUserOpen(false)}
                                    className="flex-1 px-6 py-4 rounded-xl border border-white/10 text-white font-bold text-xs uppercase tracking-widest hover:bg-white/5 transition-colors"
                                >
                                    Abort
                                </button>
                                <button
                                    onClick={handleAddUser}
                                    className="flex-1 btn-primary py-4 font-black text-xs uppercase tracking-widest"
                                >
                                    Whitelist
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* User Detail Sidebar */}
            <AnimatePresence>
                {selectedUser && (
                    <div className="fixed inset-0 z-100 flex items-center justify-end bg-black/60 backdrop-blur-sm">
                        <motion.div
                            initial={{ x: "100%" }}
                            animate={{ x: 0 }}
                            exit={{ x: "100%" }}
                            className="h-full w-full max-w-2xl bg-bg-dark border-l border-white/10 shadow-2xl overflow-y-auto"
                        >
                            <div className="p-10">
                                <button
                                    onClick={() => setSelectedUser(null)}
                                    className="p-2 hover:bg-white/5 rounded-lg text-text-dim mb-10 flex items-center gap-2 text-xs font-bold uppercase tracking-widest"
                                >
                                    <XCircle size={20} /> Close Profile
                                </button>

                                <div className="space-y-12">
                                    <header className="flex items-center gap-6">
                                        <div className="w-24 h-24 rounded-3xl bg-primary/10 border-2 border-primary/20 flex items-center justify-center text-primary text-4xl font-bold font-outfit shadow-2xl shadow-primary/10">
                                            {selectedUser.email[0].toUpperCase()}
                                        </div>
                                        <div>
                                            <div className="flex items-center gap-3 mb-2">
                                                <h2 className="text-3xl font-outfit font-bold text-white">
                                                    {selectedUser.email}
                                                </h2>
                                                <span className="px-3 py-1 rounded-lg text-[9px] font-black uppercase tracking-widest bg-primary text-bg-dark">
                                                    {selectedUser.role}
                                                </span>
                                            </div>
                                            <p className="text-text-dim font-medium flex items-center gap-2 mb-4">
                                                <Activity
                                                    size={14}
                                                    className="text-primary"
                                                />{" "}
                                                Whitelisted on{" "}
                                                {format(
                                                    new Date(
                                                        selectedUser.createdAt,
                                                    ),
                                                    "MMMM dd, yyyy",
                                                )}
                                            </p>
                                            {selectedUser.role === "USER" && (
                                                <button
                                                    onClick={() =>
                                                        setIsDepositModalOpen(
                                                            true,
                                                        )
                                                    }
                                                    className="px-6 py-2 bg-primary/10 text-primary border border-primary/20 hover:bg-primary/20 rounded-xl text-xs font-bold uppercase tracking-widest transition-all shadow-[0_0_15px_rgba(0,255,157,0.1)]"
                                                >
                                                    + Manual Deposit USDT
                                                </button>
                                            )}
                                        </div>
                                    </header>

                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                        <div className="glass p-8">
                                            <p className="text-[10px] font-bold text-text-dim uppercase tracking-[0.2em] mb-3">
                                                On-Chain Asset Balance
                                            </p>
                                            <div className="text-4xl font-outfit font-bold text-white">
                                                {selectedUser.balance.toLocaleString()}
                                                <span className="text-sm font-normal text-text-dim ml-2 uppercase">
                                                    USDT
                                                </span>
                                            </div>
                                        </div>
                                        <div className="glass p-8 flex flex-col justify-center">
                                            <p className="text-[10px] font-bold text-text-dim uppercase tracking-[0.2em] mb-3">
                                                Registration Status
                                            </p>
                                            <div className="flex items-center gap-2 text-primary font-bold">
                                                <ShieldCheck size={20} />{" "}
                                                Verified Identity
                                            </div>
                                        </div>
                                    </div>

                                    <div>
                                        <div className="flex items-center justify-between mb-8">
                                            <h3 className="text-xl font-outfit font-bold text-white flex items-center gap-3">
                                                <Activity
                                                    size={20}
                                                    className="text-primary"
                                                />{" "}
                                                Execution Ledger (Syncing...)
                                            </h3>
                                        </div>

                                        <div className="glass overflow-hidden border-white/5">
                                            <table className="w-full text-left">
                                                <thead>
                                                    <tr className="bg-white/2 text-[10px] font-bold text-text-dim uppercase tracking-widest border-b border-white/5">
                                                        <th className="px-6 py-4">
                                                            Type
                                                        </th>
                                                        <th className="px-6 py-4">
                                                            Asset Value
                                                        </th>
                                                        <th className="px-6 py-4">
                                                            Status
                                                        </th>
                                                        <th className="px-6 py-4 text-right">
                                                            Date
                                                        </th>
                                                    </tr>
                                                </thead>
                                                <tbody className="divide-y divide-white/5">
                                                    {selectedUser.transactions?.map(
                                                        (tx: any) => (
                                                            <tr
                                                                key={tx.id}
                                                                className="text-xs hover:bg-white/1 transition-colors"
                                                            >
                                                                <td className="px-6 py-4">
                                                                    <span
                                                                        className={`font-black uppercase tracking-tighter ${tx.type === "DEPOSIT" ? "text-primary" : "text-accent-blue"}`}
                                                                    >
                                                                        {
                                                                            tx.type
                                                                        }
                                                                    </span>
                                                                </td>
                                                                <td className="px-6 py-4 font-bold text-white">
                                                                    {tx.amount.toLocaleString()}{" "}
                                                                    <span className="text-[9px] text-text-dim">
                                                                        USDT
                                                                    </span>
                                                                </td>
                                                                <td className="px-6 py-4 font-bold">
                                                                    <span
                                                                        className={
                                                                            tx.status ===
                                                                            "COMPLETED"
                                                                                ? "text-primary"
                                                                                : tx.status ===
                                                                                    "PENDING"
                                                                                  ? "text-secondary"
                                                                                  : "text-red-400"
                                                                        }
                                                                    >
                                                                        {
                                                                            tx.status
                                                                        }
                                                                    </span>
                                                                </td>
                                                                <td className="px-6 py-4 text-right text-text-dim">
                                                                    {format(
                                                                        new Date(
                                                                            tx.createdAt,
                                                                        ),
                                                                        "MMM dd",
                                                                    )}
                                                                </td>
                                                            </tr>
                                                        ),
                                                    )}
                                                    {!selectedUser.transactions
                                                        ?.length && (
                                                        <tr>
                                                            <td
                                                                colSpan={4}
                                                                className="px-6 py-10 text-center text-text-dim font-medium italic"
                                                            >
                                                                No recorded
                                                                ledger activity.
                                                            </td>
                                                        </tr>
                                                    )}
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* Deposit Modal */}
            <AnimatePresence>
                {isDepositModalOpen && (
                    <div className="fixed inset-0 z-200 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            className="glass-panel p-10 w-full max-w-sm shadow-2xl border-white/10"
                        >
                            <h2 className="text-2xl font-outfit font-bold mb-2 flex items-center gap-3 uppercase tracking-tight">
                                <Plus className="text-primary" /> Credit Account
                            </h2>
                            <p className="text-text-dim text-xs mb-8 leading-relaxed font-medium">
                                Manually credit USDT to this user's balance.
                                This will create a COMPLETED deposit record.
                            </p>

                            <div className="space-y-6">
                                <div>
                                    <label className="text-[10px] font-bold text-text-dim uppercase tracking-widest mb-3 block">
                                        Deposit Amount (USDT)
                                    </label>
                                    <input
                                        type="number"
                                        className="w-full bg-white/5 border border-white/10 rounded-xl p-4 text-xl font-bold text-white focus:outline-none focus:border-primary transition-all text-center"
                                        placeholder="0.00"
                                        value={depositAmount}
                                        onChange={(e) =>
                                            setDepositAmount(e.target.value)
                                        }
                                    />
                                </div>
                            </div>

                            <div className="flex gap-4 mt-8">
                                <button
                                    onClick={() => {
                                        setIsDepositModalOpen(false);
                                        setDepositAmount("");
                                    }}
                                    className="flex-1 px-6 py-4 rounded-xl border border-white/10 text-white font-bold text-xs uppercase tracking-widest hover:bg-white/5 transition-colors"
                                >
                                    Cancel
                                </button>
                                <button
                                    onClick={handleAdminDeposit}
                                    disabled={
                                        !depositAmount ||
                                        isNaN(parseFloat(depositAmount)) ||
                                        parseFloat(depositAmount) <= 0
                                    }
                                    className="flex-1 btn-primary py-4 font-black text-xs uppercase tracking-widest disabled:opacity-50"
                                >
                                    Confirm
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default Users;
