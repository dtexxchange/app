import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    Activity,
    CheckCircle2,
    History,
    KeyIcon,
    LayoutDashboard,
    Plus,
    Search,
    Settings,
    ShieldAlert,
    ShieldCheck,
    Users,
    XCircle,
} from "lucide-react";
import React, { useCallback, useEffect, useState } from "react";
import api from "../lib/api";
import {
    ENABLE_E2EE,
    decryptData,
    exportPrivateKey,
    exportPublicKey,
    generateKeyPair,
    importPrivateKey,
} from "../lib/crypto";

const AdminDashboard: React.FC = () => {
    const [activeTab, setActiveTab] = useState<
        "overview" | "users" | "settings"
    >("overview");

    // Data states
    const [users, setUsers] = useState<any[]>([]);
    const [transactions, setTransactions] = useState<any[]>([]);
    const [hasKeys, setHasKeys] = useState(false);

    // Modals & UI states
    const [isAddUserOpen, setIsAddUserOpen] = useState(false);
    const [newUser, setNewUser] = useState({ email: "", role: "USER" });
    const [decryptedBankDetails, setDecryptedBankDetails] = useState<any>(null);
    const [tempPrivKey, setTempPrivKey] = useState<string | null>(null);
    const [selectedTx, setSelectedTx] = useState<any>(null);

    // Filters
    const [txFilter, setTxFilter] = useState({
        status: "",
        type: "",
        search: "",
    });
    const [userFilter, setUserFilter] = useState({ search: "", role: "" });
    const [selectedUser, setSelectedUser] = useState<any>(null);
    const [walletId, setWalletId] = useState<string>("");
    const [alert, setAlert] = useState<{
        title: string;
        message: string;
        type: "success" | "error" | "info";
    } | null>(null);
    const [confirmAction, setConfirmAction] = useState<{
        title: string;
        message: string;
        onConfirm: () => void;
    } | null>(null);

    const fetchTransactions = useCallback(async () => {
        try {
            // For transactions, our API supports status and type. We can filter the rest locally or optimally add search to the backend later.
            // We added status, type, userId to backend
            const params = new URLSearchParams();
            if (txFilter.status) params.append("status", txFilter.status);
            if (txFilter.type) params.append("type", txFilter.type);

            const { data } = await api.get(
                `/wallet/transactions?${params.toString()}`,
            );

            // Local email search since we didn't add deep relational search in backend getTransactions
            let filtered = data;
            if (txFilter.search) {
                filtered = data.filter((t: any) =>
                    t.user?.email
                        .toLowerCase()
                        .includes(txFilter.search.toLowerCase()),
                );
            }
            setTransactions(filtered);
        } catch (e) {
            console.error(e);
        }
    }, [txFilter]);

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

    const checkKeys = async () => {
        const privKey = localStorage.getItem("admin_private_key");
        setHasKeys(!!privKey);
    };

    const fetchWalletId = async () => {
        try {
            const { data } = await api.get("/settings/wallet-id");
            setWalletId(data.walletId || "");
        } catch (e) {
            console.error(e);
        }
    };

    useEffect(() => {
        fetchTransactions();
        fetchUsers();
        checkKeys();
        fetchWalletId();
    }, [fetchTransactions, fetchUsers]);

    const handleSaveWalletId = async () => {
        try {
            await api.patch("/settings/wallet-id", { walletId });
            setAlert({
                title: "Settings Updated",
                message: "Global Wallet ID has been successfully updated.",
                type: "success",
            });
        } catch (err: any) {
            setAlert({
                title: "Update Failed",
                message: err.response?.data?.message || "Failed to update wallet ID",
                type: "error",
            });
        }
    };

    const downloadFile = (filename: string, content: string) => {
        const element = document.createElement("a");
        const file = new Blob([content], { type: "text/plain" });
        element.href = URL.createObjectURL(file);
        element.download = filename;
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    };

    const handleSetupKeys = async () => {
        setConfirmAction({
            title: "Infrastructure Reset",
            message:
                "Generating new keys will invalidate existing pending withdrawals. You will receive a .pem file which MUST be saved securely. This is a ONE-TIME download. Proceed?",
            onConfirm: async () => {
                const keyPair = await generateKeyPair();
                const pub = await exportPublicKey(keyPair.publicKey);
                const priv = await exportPrivateKey(keyPair.privateKey);

                await api.post("/wallet/admin/public-key", { publicKey: pub });
                localStorage.setItem("admin_private_key", priv);
                setHasKeys(true);

                // Trigger one-time download
                downloadFile("admin_private_key.pem", priv);
                setTempPrivKey(priv);
            },
        });
    };

    const handleAddUser = async () => {
        try {
            await api.post("/users", newUser);
            setIsAddUserOpen(false);
            setNewUser({ email: "", role: "USER" });
            fetchUsers();
            setAlert({
                title: "Whitelist Success",
                message: "User has been added to the platform whitelist.",
                type: "success",
            });
        } catch (err: any) {
            setAlert({
                title: "Access Error",
                message:
                    err.response?.data?.message ||
                    "Error adding user to whitelist",
                type: "error",
            });
        }
    };

    const handleUpdateStatus = async (id: string, status: string) => {
        setConfirmAction({
            title: `${status === "COMPLETED" ? "Approve" : "Reject"} Transaction`,
            message: `Are you sure you want to change this transaction status to ${status}?`,
            onConfirm: async () => {
                try {
                    await api.patch(`/wallet/transactions/${id}/status`, {
                        status,
                    });
                    fetchTransactions();
                    if (selectedTx?.id === id) {
                        const { data } = await api.get(
                            `/wallet/transactions/${id}`,
                        );
                        setSelectedTx(data);
                    }
                    setAlert({
                        title: "Network Updated",
                        message: `Transaction status has been set to ${status}.`,
                        type: "success",
                    });
                } catch (err) {
                    setAlert({
                        title: "Update Failed",
                        message:
                            "Could not sync status with blockchain/database.",
                        type: "error",
                    });
                }
            },
        });
    };

    const openTxDetail = async (tx: any) => {
        setSelectedTx(tx);
        setDecryptedBankDetails(null);
        try {
            const { data } = await api.get(`/wallet/transactions/${tx.id}`);
            setSelectedTx(data);
            if (data.type === "WITHDRAW" && data.bankDetails) {
                await attemptDecryption(data.bankDetails);
            }
        } catch (e) {
            console.error(e);
        }
    };

    const attemptDecryption = async (encrypted: string) => {
        try {
            if (!ENABLE_E2EE) {
                const decrypted = await decryptData(null, encrypted);
                setDecryptedBankDetails(decrypted);
                return;
            }
            const privPem = localStorage.getItem("admin_private_key");
            if (!privPem) return;
            const privKey = await importPrivateKey(privPem);
            const decrypted = await decryptData(privKey, encrypted);
            setDecryptedBankDetails(decrypted);
        } catch (err) {
            console.error("Decryption failed", err);
        }
    };

    const loadUserDetails = async (id: string) => {
        try {
            const { data } = await api.get(`/users/${id}`);
            setSelectedUser(data);
        } catch (e) {
            setAlert({
                title: "Identity Error",
                message: "Failed to load detailed user profile from registry.",
                type: "error",
            });
        }
    };

    return (
        <div className="flex flex-col md:flex-row gap-8 pb-20 animate-fade">
            {/* Sidebar Navigation */}
            <div className="w-full md:w-64 shrink-0 space-y-2">
                <button
                    onClick={() => {
                        setActiveTab("overview");
                        setSelectedUser(null);
                    }}
                    className={`w-full flex items-center gap-3 px-6 py-4 rounded-xl transition-all font-semibold ${activeTab === "overview" ? "bg-primary text-black shadow-[0_4px_20px_rgba(0,255,157,0.2)]" : "text-text-dim hover:bg-white/5 hover:text-white"}`}
                >
                    <LayoutDashboard size={20} /> Dashboard
                </button>
                <button
                    onClick={() => {
                        setActiveTab("users");
                        setSelectedUser(null);
                    }}
                    className={`w-full flex items-center gap-3 px-6 py-4 rounded-xl transition-all font-semibold ${activeTab === "users" ? "bg-primary text-black shadow-[0_4px_20px_rgba(0,255,157,0.2)]" : "text-text-dim hover:bg-white/5 hover:text-white"}`}
                >
                    <Users size={20} /> User Directory
                </button>
                <button
                    onClick={() => {
                        setActiveTab("settings");
                        setSelectedUser(null);
                    }}
                    className={`w-full flex items-center gap-3 px-6 py-4 rounded-xl transition-all font-semibold ${activeTab === "settings" ? "bg-primary text-black shadow-[0_4px_20px_rgba(0,255,157,0.2)]" : "text-text-dim hover:bg-white/5 hover:text-white"}`}
                >
                    <Settings size={20} /> Global Settings
                </button>
            </div>

            {/* Main Content Area */}
            <div className="flex-1 w-full min-w-0">
                <AnimatePresence mode="wait">
                    {/* OVERVIEW TAB */}
                    {activeTab === "overview" && !selectedUser && (
                        <motion.div
                            key="overview"
                            initial={{ opacity: 0, x: 10 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -10 }}
                            className="space-y-8"
                        >
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div className="glass flex items-center justify-between p-6">
                                    <div>
                                        <p className="text-text-dim text-sm uppercase font-bold tracking-wider mb-1">
                                            Total Network Users
                                        </p>
                                        <h3 className="text-3xl font-outfit font-bold">
                                            {users.length}
                                        </h3>
                                    </div>
                                    <div className="w-12 h-12 rounded-xl bg-accent-blue/10 border border-accent-blue/20 flex items-center justify-center">
                                        <Users className="text-accent-blue" />
                                    </div>
                                </div>
                                <div className="glass flex items-center justify-between p-6">
                                    <div>
                                        <p className="text-text-dim text-sm uppercase font-bold tracking-wider mb-1">
                                            E2EE Cryptography
                                        </p>
                                        <h3 className="text-xl font-outfit font-bold text-primary mt-2 flex items-center gap-2">
                                            {hasKeys ? (
                                                <ShieldCheck size={24} />
                                            ) : (
                                                <ShieldAlert
                                                    className="text-red-400"
                                                    size={24}
                                                />
                                            )}
                                            {hasKeys
                                                ? "Operational"
                                                : "Keys Missing"}
                                        </h3>
                                    </div>
                                    <div className="w-12 h-12 rounded-xl bg-primary/10 border border-primary/20 flex items-center justify-center">
                                        <KeyIcon className="text-primary" />
                                    </div>
                                </div>
                            </div>

                            <div className="glass overflow-hidden">
                                <div className="p-6 border-b border-white/5 bg-white/1 flex flex-col md:flex-row items-center gap-4 justify-between">
                                    <div>
                                        <h3 className="text-2xl font-outfit font-bold flex items-center gap-3">
                                            <Activity className="text-primary" />{" "}
                                            Global Transactions
                                        </h3>
                                    </div>
                                    <div className="flex items-center gap-3 w-full md:w-auto">
                                        <div className="relative flex-1 md:w-64">
                                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-text-dim w-4 h-4" />
                                            <input
                                                type="text"
                                                placeholder="Search email..."
                                                className="w-full bg-white/5 border border-white/10 rounded-lg pl-9 pr-4 py-2 text-sm focus:outline-none focus:border-primary text-white transition-colors"
                                                value={txFilter.search}
                                                onChange={(e) =>
                                                    setTxFilter({
                                                        ...txFilter,
                                                        search: e.target.value,
                                                    })
                                                }
                                            />
                                        </div>
                                        <select
                                            className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-primary text-white transition-colors appearance-none"
                                            value={txFilter.status}
                                            onChange={(e) =>
                                                setTxFilter({
                                                    ...txFilter,
                                                    status: e.target.value,
                                                })
                                            }
                                        >
                                            <option
                                                value=""
                                                className="bg-bg-dark"
                                            >
                                                All Status
                                            </option>
                                            <option
                                                value="PENDING"
                                                className="bg-bg-dark"
                                            >
                                                Pending
                                            </option>
                                            <option
                                                value="COMPLETED"
                                                className="bg-bg-dark"
                                            >
                                                Completed
                                            </option>
                                            <option
                                                value="REJECTED"
                                                className="bg-bg-dark"
                                            >
                                                Rejected
                                            </option>
                                        </select>
                                    </div>
                                </div>

                                <div className="w-full overflow-x-auto">
                                    <table className="w-full text-left border-collapse">
                                        <thead>
                                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-xs font-semibold tracking-widest uppercase">
                                                <th className="px-6 py-4">
                                                    User
                                                </th>
                                                <th className="px-6 py-4">
                                                    Type / Date
                                                </th>
                                                <th className="px-6 py-4">
                                                    Amount
                                                </th>
                                                <th className="px-6 py-4">
                                                    Status / Action
                                                </th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-white/5">
                                            <AnimatePresence>
                                                {transactions.map((tx: any) => (
                                                    <motion.tr
                                                        initial={{ opacity: 0 }}
                                                        animate={{ opacity: 1 }}
                                                        exit={{ opacity: 0 }}
                                                        key={tx.id}
                                                        className="table-row-hover cursor-pointer"
                                                        onClick={() =>
                                                            openTxDetail(tx)
                                                        }
                                                    >
                                                        <td className="px-6 py-4">
                                                            <div className="font-semibold text-white truncate max-w-[150px]">
                                                                {tx.user?.email}
                                                            </div>
                                                            <div className="text-[10px] text-text-dim mt-0.5 truncate max-w-[150px]">
                                                                TX-
                                                                {tx.id
                                                                    .substring(
                                                                        0,
                                                                        8,
                                                                    )
                                                                    .toUpperCase()}
                                                            </div>
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <span
                                                                className={`inline-block px-2 py-0.5 rounded-full text-[10px] font-bold tracking-wider border ${tx.type === "DEPOSIT" ? "border-primary/20 text-primary bg-primary/5" : "border-accent-blue/20 text-accent-blue bg-accent-blue/5"}`}
                                                            >
                                                                {tx.type}
                                                            </span>
                                                            <div className="text-[10px] text-text-dim mt-1.5">
                                                                {format(
                                                                    new Date(
                                                                        tx.createdAt,
                                                                    ),
                                                                    "MMM dd, yyyy HH:mm",
                                                                )}
                                                            </div>
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <div className="text-base font-outfit font-bold text-white">
                                                                {tx.amount.toLocaleString()}{" "}
                                                                <span className="text-[10px] text-primary ml-0.5">
                                                                    USDT
                                                                </span>
                                                            </div>
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            {tx.status ===
                                                            "PENDING" ? (
                                                                <div className="flex items-center gap-2">
                                                                    {/* Eye icon removed as decryption is now integrated into detail modal */}
                                                                    <button
                                                                        onClick={(
                                                                            e,
                                                                        ) => {
                                                                            e.stopPropagation();
                                                                            handleUpdateStatus(
                                                                                tx.id,
                                                                                "COMPLETED",
                                                                            );
                                                                        }}
                                                                        className="p-2 text-primary bg-primary/5 hover:bg-primary/20 border border-primary/20 rounded-lg"
                                                                        title="Approve"
                                                                    >
                                                                        <CheckCircle2
                                                                            size={
                                                                                16
                                                                            }
                                                                        />
                                                                    </button>
                                                                    <button
                                                                        onClick={(
                                                                            e,
                                                                        ) => {
                                                                            e.stopPropagation();
                                                                            handleUpdateStatus(
                                                                                tx.id,
                                                                                "REJECTED",
                                                                            );
                                                                        }}
                                                                        className="p-2 text-red-400 bg-red-400/5 hover:bg-red-400/20 border border-red-400/20 rounded-lg"
                                                                        title="Reject"
                                                                    >
                                                                        <XCircle
                                                                            size={
                                                                                16
                                                                            }
                                                                        />
                                                                    </button>
                                                                </div>
                                                            ) : (
                                                                <span
                                                                    className={`text-xs font-bold tracking-wide ${tx.status === "COMPLETED" ? "text-primary" : "text-red-400"}`}
                                                                >
                                                                    {tx.status}
                                                                </span>
                                                            )}
                                                        </td>
                                                    </motion.tr>
                                                ))}
                                            </AnimatePresence>
                                        </tbody>
                                    </table>
                                    {transactions.length === 0 && (
                                        <div className="py-12 text-center text-text-dim text-sm">
                                            No transactions match your criteria.
                                        </div>
                                    )}
                                </div>
                            </div>
                        </motion.div>
                    )}

                    {/* USERS DIRECTORY TAB */}
                    {activeTab === "users" && !selectedUser && (
                        <motion.div
                            key="users"
                            initial={{ opacity: 0, x: 10 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -10 }}
                            className="space-y-8"
                        >
                            <div className="flex justify-between items-center mb-6">
                                <h3 className="text-3xl font-outfit font-bold">
                                    User Directory
                                </h3>
                                <button
                                    onClick={() => setIsAddUserOpen(true)}
                                    className="btn-primary flex items-center gap-2 text-sm px-4 py-2"
                                >
                                    <Plus size={18} /> Whitelist User
                                </button>
                            </div>

                            <div className="glass overflow-hidden">
                                <div className="p-6 border-b border-white/5 bg-white/1 flex items-center gap-4">
                                    <div className="relative flex-1 md:max-w-md">
                                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-text-dim w-4 h-4" />
                                        <input
                                            type="text"
                                            placeholder="Search users by email..."
                                            className="w-full bg-white/5 border border-white/10 rounded-lg pl-9 pr-4 py-2 text-sm focus:outline-none focus:border-primary text-white"
                                            value={userFilter.search}
                                            onChange={(e) =>
                                                setUserFilter({
                                                    ...userFilter,
                                                    search: e.target.value,
                                                })
                                            }
                                        />
                                    </div>
                                    <select
                                        className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-primary text-white appearance-none"
                                        value={userFilter.role}
                                        onChange={(e) =>
                                            setUserFilter({
                                                ...userFilter,
                                                role: e.target.value,
                                            })
                                        }
                                    >
                                        <option value="" className="bg-bg-dark">
                                            All Roles
                                        </option>
                                        <option
                                            value="USER"
                                            className="bg-bg-dark"
                                        >
                                            Standard Users
                                        </option>
                                        <option
                                            value="ADMIN"
                                            className="bg-bg-dark"
                                        >
                                            Admins
                                        </option>
                                    </select>
                                </div>

                                <div className="w-full overflow-x-auto">
                                    <table className="w-full text-left border-collapse">
                                        <thead>
                                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-xs font-semibold tracking-widest uppercase">
                                                <th className="px-6 py-4">
                                                    Account
                                                </th>
                                                <th className="px-6 py-4">
                                                    Role
                                                </th>
                                                <th className="px-6 py-4">
                                                    Joined Date
                                                </th>
                                                <th className="px-6 py-4">
                                                    Balance
                                                </th>
                                                <th className="px-6 py-4">
                                                    Actions
                                                </th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-white/5">
                                            {users.map((user: any) => (
                                                <tr
                                                    key={user.id}
                                                    className="table-row-hover"
                                                >
                                                    <td className="px-6 py-5 font-semibold text-white">
                                                        {user.email}
                                                    </td>
                                                    <td className="px-6 py-5">
                                                        <span
                                                            className={`text-[10px] uppercase font-bold tracking-widest px-2 py-1 rounded bg-white/5 ${user.role === "ADMIN" ? "text-primary" : "text-white"}`}
                                                        >
                                                            {user.role}
                                                        </span>
                                                    </td>
                                                    <td className="px-6 py-5 text-sm text-text-dim">
                                                        {format(
                                                            new Date(
                                                                user.createdAt,
                                                            ),
                                                            "MMM dd, yyyy",
                                                        )}
                                                    </td>
                                                    <td className="px-6 py-5 font-bold font-outfit text-white">
                                                        {user.balance?.toLocaleString()}{" "}
                                                        <span className="text-[10px] text-primary">
                                                            USDT
                                                        </span>
                                                    </td>
                                                    <td className="px-6 py-5">
                                                        <button
                                                            onClick={() =>
                                                                loadUserDetails(
                                                                    user.id,
                                                                )
                                                            }
                                                            className="text-xs bg-white/10 hover:bg-white/20 text-white px-3 py-1.5 rounded transition-colors font-semibold"
                                                        >
                                                            View Details
                                                        </button>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                    {users.length === 0 && (
                                        <div className="py-12 text-center text-text-dim text-sm">
                                            No users found.
                                        </div>
                                    )}
                                </div>
                            </div>
                        </motion.div>
                    )}

                    {/* SINGLE USER DETAILS VIEW */}
                    {selectedUser && (
                        <motion.div
                            key="user-detail"
                            initial={{ opacity: 0, x: 10 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -10 }}
                            className="space-y-6"
                        >
                            <button
                                onClick={() => setSelectedUser(null)}
                                className="text-text-dim hover:text-white inline-flex items-center gap-2 mb-2 text-sm transition-colors"
                            >
                                &larr; Back to Directory
                            </button>

                            <div className="glass p-8 flex justify-between items-center bg-linear-to-r from-bg-card to-white/2">
                                <div>
                                    <h2 className="text-3xl font-outfit font-bold">
                                        {selectedUser.email}
                                    </h2>
                                    <div className="flex gap-4 items-center mt-3">
                                        <span
                                            className={`text-xs uppercase font-bold tracking-widest px-2 py-1 rounded bg-black/40 ${selectedUser.role === "ADMIN" ? "text-primary border border-primary/20" : "text-white border border-white/10"}`}
                                        >
                                            {selectedUser.role}
                                        </span>
                                        <span className="text-xs text-text-dim">
                                            User ID: USR-
                                            {selectedUser.id
                                                .substring(0, 8)
                                                .toUpperCase()}
                                        </span>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <p className="text-xs text-text-dim font-bold tracking-widest uppercase mb-1">
                                        Current Balance
                                    </p>
                                    <div className="text-4xl font-outfit font-bold text-white">
                                        {selectedUser.balance?.toLocaleString()}{" "}
                                        <span className="text-primary text-lg">
                                            USDT
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div className="glass overflow-hidden">
                                <div className="p-6 border-b border-white/5 bg-white/1">
                                    <h3 className="font-outfit font-bold text-lg">
                                        Recent Transactions (
                                        {selectedUser.transactions?.length || 0}
                                        )
                                    </h3>
                                </div>
                                <div className="w-full overflow-x-auto">
                                    <table className="w-full text-left border-collapse">
                                        <thead>
                                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-xs font-semibold tracking-widest uppercase">
                                                <th className="px-6 py-3">
                                                    Type
                                                </th>
                                                <th className="px-6 py-3">
                                                    Amount
                                                </th>
                                                <th className="px-6 py-3">
                                                    Status
                                                </th>
                                                <th className="px-6 py-3">
                                                    Date
                                                </th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-white/5">
                                            {selectedUser.transactions?.map(
                                                (tx: any) => (
                                                    <tr
                                                        key={tx.id}
                                                        className="hover:bg-white/2"
                                                    >
                                                        <td className="px-6 py-4">
                                                            <span
                                                                className={`text-[10px] font-bold px-2 py-0.5 rounded border ${tx.type === "DEPOSIT" ? "border-primary/30 text-primary" : "border-accent-blue/30 text-accent-blue"}`}
                                                            >
                                                                {tx.type}
                                                            </span>
                                                        </td>
                                                        <td className="px-6 py-4 font-bold">
                                                            {tx.amount} USDT
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <span
                                                                className={`text-xs font-bold ${tx.status === "COMPLETED" ? "text-primary" : tx.status === "PENDING" ? "text-secondary" : "text-red-400"}`}
                                                            >
                                                                {tx.status}
                                                            </span>
                                                        </td>
                                                        <td className="px-6 py-4 text-xs text-text-dim">
                                                            {format(
                                                                new Date(
                                                                    tx.createdAt,
                                                                ),
                                                                "MMM dd, HH:mm",
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
                                                        className="px-6 py-8 text-center text-sm text-text-dim"
                                                    >
                                                        No transactions yet.
                                                    </td>
                                                </tr>
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </motion.div>
                    )}

                    {/* SETTINGS TAB */}
                    {activeTab === "settings" && !selectedUser && (
                        <motion.div
                            key="settings"
                            initial={{ opacity: 0, x: 10 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -10 }}
                            className="space-y-6 max-w-2xl"
                        >
                            <h3 className="text-3xl font-outfit font-bold mb-6">
                                Global Settings
                            </h3>

                            <div className="glass p-8">
                                <div className="flex items-center gap-4 mb-4">
                                    <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center border border-primary/20">
                                        <Activity className="text-primary" />
                                    </div>
                                    <div>
                                        <h4 className="text-lg font-outfit font-bold">
                                            Platform Wallet ID
                                        </h4>
                                        <p className="text-sm text-text-dim">
                                            The destination address for all user deposits.
                                        </p>
                                    </div>
                                </div>
                                
                                <div className="space-y-4 mt-6">
                                    <div>
                                        <label className="text-[10px] font-bold text-text-dim uppercase tracking-widest mb-2 block">
                                            Current Wallet Address
                                        </label>
                                        <input
                                            className="input-field"
                                            placeholder="Enter USDT TRC20/ERC20 Address"
                                            value={walletId}
                                            onChange={(e) => setWalletId(e.target.value)}
                                        />
                                    </div>
                                    <button
                                        onClick={handleSaveWalletId}
                                        className="btn-primary w-full md:w-auto px-10"
                                    >
                                        Update Wallet ID
                                    </button>
                                </div>
                            </div>

                            <div className="glass p-8">
                                <div className="flex items-center gap-4 mb-4">
                                    <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center border border-primary/20">
                                        <ShieldCheck className="text-primary" />
                                    </div>
                                    <div>
                                        <h4 className="text-lg font-outfit font-bold">
                                            End-to-End Encryption
                                        </h4>
                                        <p className="text-sm text-text-dim">
                                            Manage the RSA Cryptographic keys
                                            for the platform.
                                        </p>
                                    </div>
                                </div>

                                <div className="bg-black/30 border border-white/5 rounded-xl p-5 mt-6 mb-6">
                                    <p className="text-sm leading-relaxed text-white/80">
                                        When you generate keys, the{" "}
                                        <strong className="text-primary">
                                            Public Key
                                        </strong>{" "}
                                        is saved to the server and used by
                                        clients to encrypt bank details. The{" "}
                                        <strong className="text-accent-blue">
                                            Private Key
                                        </strong>{" "}
                                        never leaves your browser and is saved
                                        to `localStorage`.
                                    </p>
                                    <p className="text-sm leading-relaxed text-red-400 mt-3 font-semibold">
                                        Warning: Generating new keys will render
                                        existing pending withdrawals unreadable.
                                    </p>
                                </div>

                                {!ENABLE_E2EE ? (
                                    <div className="bg-accent-blue/10 border border-accent-blue/20 p-4 rounded-xl text-accent-blue text-sm font-semibold">
                                        E2EE is currently disabled by a global feature flag. All withdrawal data is stored in plain text.
                                    </div>
                                ) : (
                                    <button
                                        onClick={handleSetupKeys}
                                        className="btn-primary"
                                    >
                                        {hasKeys
                                            ? "Regenerate E2EE Keys"
                                            : "Initialize E2EE Infrastructure"}
                                    </button>
                                )}
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>
            </div>

            {/* Add User Modal */}
            <AnimatePresence>
                {isAddUserOpen && (
                    <div className="fixed inset-0 z-100 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ y: 20, opacity: 0 }}
                            animate={{ y: 0, opacity: 1 }}
                            exit={{ y: 20, opacity: 0 }}
                            className="glass-panel p-8 w-full max-w-md shadow-2xl"
                        >
                            <h2 className="text-2xl font-outfit font-bold mb-2">
                                Register User
                            </h2>
                            <p className="text-text-dim text-sm mb-6">
                                Add a new email to the access whitelist.
                            </p>

                            <div className="space-y-5">
                                <div>
                                    <label className="text-xs font-bold text-text-dim uppercase tracking-wider mb-2 block">
                                        Email Address
                                    </label>
                                    <input
                                        className="input-field"
                                        placeholder="user@company.com"
                                        value={newUser.email}
                                        onChange={(e) =>
                                            setNewUser({
                                                ...newUser,
                                                email: e.target.value,
                                            })
                                        }
                                    />
                                </div>
                                <div>
                                    <label className="text-xs font-bold text-text-dim uppercase tracking-wider mb-2 block">
                                        Access Role
                                    </label>
                                    <select
                                        className="input-field appearance-none"
                                        value={newUser.role}
                                        onChange={(e) =>
                                            setNewUser({
                                                ...newUser,
                                                role: e.target.value,
                                            })
                                        }
                                    >
                                        <option
                                            value="USER"
                                            className="bg-bg-dark"
                                        >
                                            Standard User
                                        </option>
                                        <option
                                            value="ADMIN"
                                            className="bg-bg-dark"
                                        >
                                            Administrator
                                        </option>
                                    </select>
                                </div>
                                <div className="flex gap-4 pt-4 mt-6 border-t border-white/5">
                                    <button
                                        onClick={() => setIsAddUserOpen(false)}
                                        className="flex-1 px-6 py-3 rounded-xl border border-white/10 hover:bg-white/5 transition-colors font-semibold"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        onClick={handleAddUser}
                                        className="flex-1 btn-primary"
                                    >
                                        Save User
                                    </button>
                                </div>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* Transaction Detail & Log Modal */}
            <AnimatePresence>
                {selectedTx && (
                    <div className="fixed inset-0 z-120 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ x: 200, opacity: 0 }}
                            animate={{ x: 0, opacity: 1 }}
                            exit={{ x: 200, opacity: 0 }}
                            className="glass-panel p-0 w-full max-w-2xl shadow-2xl shadow-primary/10 overflow-hidden flex flex-col max-h-[90vh]"
                        >
                            <div className="p-8 border-b border-white/5 bg-white/5 flex items-center justify-between">
                                <div className="flex items-center gap-4">
                                    <div
                                        className={`w-12 h-12 rounded-xl flex items-center justify-center ${selectedTx.type === "DEPOSIT" ? "bg-primary/20 text-primary" : "bg-accent-blue/20 text-accent-blue"}`}
                                    >
                                        <Activity size={24} />
                                    </div>
                                    <div>
                                        <h2 className="text-2xl font-outfit font-bold text-white leading-tight">
                                            Transaction Details
                                        </h2>
                                        <p className="text-xs text-text-dim font-mono tracking-widest mt-1">
                                            TX-{selectedTx.id.toUpperCase()}
                                        </p>
                                    </div>
                                </div>
                                <button
                                    onClick={() => setSelectedTx(null)}
                                    className="p-2 hover:bg-white/10 rounded-full text-text-dim hover:text-white transition-colors"
                                >
                                    <XCircle size={28} />
                                </button>
                            </div>

                            <div className="flex-1 overflow-y-auto p-8 custom-scrollbar">
                                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
                                    <div className="bg-white/5 p-6 rounded-2xl border border-white/5">
                                        <span className="text-[10px] font-bold text-text-dim uppercase tracking-widest block mb-1">
                                            Status
                                        </span>
                                        <span
                                            className={`text-lg font-bold font-outfit ${selectedTx.status === "COMPLETED" ? "text-primary" : selectedTx.status === "PENDING" ? "text-accent-blue" : "text-red-400"}`}
                                        >
                                            {selectedTx.status}
                                        </span>
                                    </div>
                                    <div className="bg-white/5 p-6 rounded-2xl border border-white/5">
                                        <span className="text-[10px] font-bold text-text-dim uppercase tracking-widest block mb-1">
                                            Amount
                                        </span>
                                        <div className="text-lg font-bold font-outfit text-white">
                                            {selectedTx.amount.toLocaleString()}{" "}
                                            <span className="text-[10px] text-primary">
                                                USDT
                                            </span>
                                        </div>
                                    </div>
                                    <div className="bg-white/5 p-6 rounded-2xl border border-white/5">
                                        <span className="text-[10px] font-bold text-text-dim uppercase tracking-widest block mb-1">
                                            User
                                        </span>
                                        <div className="text-lg font-bold font-outfit text-white truncate">
                                            {selectedTx.user?.email}
                                        </div>
                                    </div>
                                </div>

                                <div className="mb-10">
                                    <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-2">
                                        <History
                                            size={16}
                                            className="text-primary"
                                        />{" "}
                                        Activity Timeline
                                    </h3>
                                    <div className="space-y-0 pl-3 border-l-2 border-white/5">
                                        {selectedTx.logs?.map((log: any) => (
                                            <div
                                                key={log.id}
                                                className="relative pl-8 pb-8 last:pb-0"
                                            >
                                                <div className="absolute left-[-11px] top-0 w-5 h-5 rounded-full bg-bg-dark border-2 border-primary shadow-lg flex items-center justify-center">
                                                    <div className="w-1.5 h-1.5 rounded-full bg-primary" />
                                                </div>
                                                <div className="flex flex-col md:flex-row md:items-center justify-between gap-2">
                                                    <div>
                                                        <div className="text-sm font-bold text-white">
                                                            {log.status}
                                                        </div>
                                                        <div className="text-xs text-text-dim mt-1">
                                                            {log.note ||
                                                                "No details provided"}
                                                        </div>
                                                    </div>
                                                    <div className="text-right">
                                                        <div className="text-[10px] font-bold text-white/40 uppercase">
                                                            {format(
                                                                new Date(
                                                                    log.createdAt,
                                                                ),
                                                                "MMM dd, HH:mm",
                                                            )}
                                                        </div>
                                                        <div className="text-[10px] text-primary/60 font-semibold truncate max-w-[150px]">
                                                            by {log.actor}
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        ))}
                                        {(!selectedTx.logs ||
                                            selectedTx.logs.length === 0) && (
                                            <div className="text-sm text-text-dim italic">
                                                No activity logs found for this
                                                transaction.
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {selectedTx.type === "WITHDRAW" && (
                                    <div className="mb-10">
                                        <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-2">
                                            <ShieldCheck
                                                size={16}
                                                className="text-primary"
                                            />{" "}
                                            Decrypted Bank PII
                                        </h3>
                                        {decryptedBankDetails ? (
                                            <div className="bg-black/40 p-6 rounded-2xl border border-white/5 grid grid-cols-1 md:grid-cols-2 gap-y-4 gap-x-8">
                                                <div className="flex justify-between items-center border-b border-white/5 pb-3 md:border-b-0 md:pb-0">
                                                    <span className="text-[10px] font-bold text-text-dim">
                                                        BENEFICIARY
                                                    </span>
                                                    <span className="font-bold text-white text-sm">
                                                        {
                                                            decryptedBankDetails.name
                                                        }
                                                    </span>
                                                </div>
                                                <div className="flex justify-between items-center border-b border-white/5 pb-3 md:border-b-0 md:pb-0">
                                                    <span className="text-[10px] font-bold text-text-dim">
                                                        ACCOUNT NO.
                                                    </span>
                                                    <span className="font-bold text-white text-sm">
                                                        {
                                                            decryptedBankDetails.account
                                                        }
                                                    </span>
                                                </div>
                                                <div className="flex justify-between items-center border-b border-white/5 pb-3 md:border-b-0 md:pb-0">
                                                    <span className="text-[10px] font-bold text-text-dim">
                                                        BANK NAME
                                                    </span>
                                                    <span className="font-bold text-white text-sm">
                                                        {
                                                            decryptedBankDetails.bank
                                                        }
                                                    </span>
                                                </div>
                                                <div className="flex justify-between items-center">
                                                    <span className="text-[10px] font-bold text-text-dim">
                                                        ROUTING / IFSC
                                                    </span>
                                                    <span className="font-bold text-accent-blue text-sm">
                                                        {
                                                            decryptedBankDetails.ifsc
                                                        }
                                                    </span>
                                                </div>
                                            </div>
                                        ) : (
                                            <div className="bg-red-400/5 p-6 rounded-2xl border border-red-400/10 flex items-center gap-4">
                                                <ShieldAlert
                                                    className="text-red-400"
                                                    size={24}
                                                />
                                                <div>
                                                    <p className="text-sm font-bold text-white">
                                                        PII Decryption Failed
                                                    </p>
                                                    <p className="text-xs text-text-dim">
                                                        Private key missing or
                                                        invalid on this device.
                                                    </p>
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                )}

                                {selectedTx.status === "PENDING" && (
                                    <div className="pt-8 border-t border-white/5 flex flex-wrap gap-4">
                                        <button
                                            onClick={() =>
                                                handleUpdateStatus(
                                                    selectedTx.id,
                                                    "COMPLETED",
                                                )
                                            }
                                            className="flex-1 min-w-[140px] px-6 py-4 rounded-2xl bg-primary text-bg-dark font-bold hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-2 shadow-xl shadow-primary/20"
                                        >
                                            <CheckCircle2 size={18} /> Approve
                                        </button>
                                        <button
                                            onClick={() =>
                                                handleUpdateStatus(
                                                    selectedTx.id,
                                                    "REJECTED",
                                                )
                                            }
                                            className="flex-1 min-w-[140px] px-6 py-4 rounded-2xl border border-red-500/30 bg-red-500/5 text-red-500 font-bold hover:bg-red-500/10 transition-all flex items-center justify-center gap-2"
                                        >
                                            <XCircle size={18} /> Reject
                                        </button>
                                    </div>
                                )}
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* Confirm Modal */}
            <AnimatePresence>
                {confirmAction && (
                    <div className="fixed inset-0 z-200 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            className="glass-panel p-8 w-full max-w-sm shadow-2xl border-white/10"
                        >
                            <h2 className="text-xl font-outfit font-bold mb-3">
                                {confirmAction.title}
                            </h2>
                            <p className="text-text-dim text-sm mb-8 leading-relaxed">
                                {confirmAction.message}
                            </p>
                            <div className="flex gap-4">
                                <button
                                    onClick={() => setConfirmAction(null)}
                                    className="flex-1 px-6 py-3 rounded-xl border border-white/10 hover:bg-white/5 transition-colors font-semibold"
                                >
                                    Cancel
                                </button>
                                <button
                                    onClick={() => {
                                        confirmAction.onConfirm();
                                        setConfirmAction(null);
                                    }}
                                    className="flex-1 btn-primary"
                                >
                                    Proceed
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* Alert Modal */}
            <AnimatePresence>
                {alert && (
                    <div className="fixed inset-0 z-210 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            className="glass-panel p-8 w-full max-w-sm shadow-2xl border-white/10"
                        >
                            <div className="flex flex-col items-center text-center">
                                <div
                                    className={`w-16 h-16 rounded-full flex items-center justify-center mb-6 ${
                                        alert.type === "success"
                                            ? "bg-primary/10 text-primary"
                                            : alert.type === "error"
                                              ? "bg-red-500/10 text-red-500"
                                              : "bg-accent-blue/10 text-accent-blue"
                                    }`}
                                >
                                    {alert.type === "success" ? (
                                        <ShieldCheck size={32} />
                                    ) : alert.type === "error" ? (
                                        <ShieldAlert size={32} />
                                    ) : (
                                        <Activity size={32} />
                                    )}
                                </div>
                                <h2 className="text-2xl font-outfit font-bold mb-2">
                                    {alert.title}
                                </h2>
                                <p className="text-text-dim text-sm mb-8 leading-relaxed">
                                    {alert.message}
                                </p>
                                <button
                                    onClick={() => setAlert(null)}
                                    className={`w-full py-3 rounded-xl font-bold transition-all ${
                                        alert.type === "success"
                                            ? "bg-primary text-black"
                                            : alert.type === "error"
                                              ? "bg-red-500 text-white"
                                              : "bg-accent-blue text-white"
                                    }`}
                                >
                                    Acknowledge
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* Key Generation Success Modal (ONE TIME) */}
            <AnimatePresence>
                {tempPrivKey && (
                    <div className="fixed inset-0 z-250 flex items-center justify-center p-6 bg-black/80 backdrop-blur-2xl">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            className="glass-panel p-10 w-full max-w-lg shadow-2xl border-primary/30"
                        >
                            <div className="flex flex-col items-center text-center">
                                <div className="w-20 h-20 rounded-full bg-primary/10 text-primary flex items-center justify-center mb-8 border border-primary/20">
                                    <ShieldCheck size={40} />
                                </div>
                                <h2 className="text-3xl font-outfit font-bold mb-4">
                                    Master Key Generated
                                </h2>
                                <div className="bg-red-500/10 border border-red-500/20 p-4 rounded-xl mb-6 text-red-400 text-sm font-semibold flex items-start gap-3 text-left">
                                    <ShieldAlert
                                        className="shrink-0 mt-0.5"
                                        size={18}
                                    />
                                    <span>
                                        WARNING: Your Private Key has been
                                        downloaded as 'admin_private_key.pem'.
                                        Keep this file extremely safe. If lost,
                                        you will NEVER be able to recover
                                        withdrawal details. This file will NOT
                                        be available for download again.
                                    </span>
                                </div>
                                <p className="text-text-dim text-sm mb-8 leading-relaxed">
                                    The keys have been synchronized with the
                                    vault. You can now use this device to
                                    process withdrawals. To use other devices
                                    (like the Mobile Admin), you must import the
                                    .pem file manually.
                                </p>
                                <button
                                    onClick={() => setTempPrivKey(null)}
                                    className="w-full py-4 bg-primary text-black rounded-2xl font-bold hover:scale-[1.02] transition-all shadow-xl shadow-primary/20"
                                >
                                    I Have Saved the Key Safely
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default AdminDashboard;
