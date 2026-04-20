import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    AlertCircle,
    CheckCircle2,
    Edit2,
    History,
    Landmark,
    Plus,
    ShieldCheck,
    Trash2,
    X,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import api from "../../lib/api";

interface BankAccount {
    id: string;
    name: string;
    bankName: string;
    accountNo: string;
    ifsc: string;
    createdAt: string;
}

interface BankLog {
    id: string;
    action: string;
    changes: string;
    createdAt: string;
}

const BankAccounts: React.FC = () => {
    const [accounts, setAccounts] = useState<BankAccount[]>([]);
    const [isAddOpen, setIsAddOpen] = useState(false);
    const [editingAccount, setEditingAccount] = useState<BankAccount | null>(
        null,
    );
    const [formData, setFormData] = useState({
        name: "",
        bankName: "",
        accountNo: "",
        ifsc: "",
    });
    const [selectedAccount, setSelectedAccount] = useState<string | null>(null);
    const [logs, setLogs] = useState<BankLog[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [alert, setAlert] = useState<{
        title: string;
        message: string;
        type: "success" | "error";
    } | null>(null);

    const fetchAccounts = async () => {
        try {
            const { data } = await api.get("/bank-accounts");
            setAccounts(data);
        } catch (e) {
            console.error(e);
        }
    };

    useEffect(() => {
        fetchAccounts();
    }, []);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);
        try {
            if (editingAccount) {
                await api.patch(
                    `/bank-accounts/${editingAccount.id}`,
                    formData,
                );
                setAlert({
                    title: "Account Updated",
                    message: "Your bank account changes have been saved.",
                    type: "success",
                });
            } else {
                await api.post("/bank-accounts", formData);
                setAlert({
                    title: "Account Added",
                    message: "New bank account has been saved for future use.",
                    type: "success",
                });
            }
            setIsAddOpen(false);
            setEditingAccount(null);
            setFormData({ name: "", bankName: "", accountNo: "", ifsc: "" });
            fetchAccounts();
        } catch (err: any) {
            setAlert({
                title: "Error",
                message:
                    err.response?.data?.message || "Failed to save account.",
                type: "error",
            });
        } finally {
            setIsLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm("Are you sure you want to delete this account?"))
            return;
        try {
            await api.delete(`/bank-accounts/${id}`);
            fetchAccounts();
            if (selectedAccount === id) {
                setSelectedAccount(null);
                setLogs([]);
            }
        } catch (e) {
            console.error(e);
        }
    };

    const fetchLogs = async (id: string) => {
        try {
            const { data } = await api.get(`/bank-accounts/${id}/logs`);
            setLogs(data);
            setSelectedAccount(id);
        } catch (e) {
            console.error(e);
        }
    };

    return (
        <div className="space-y-10">
            <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                        Saved Accounts
                    </h1>
                    <p className="text-text-dim max-w-xl font-medium">
                        Manage your bank accounts for quick exchanges. All
                        information is stored securely.
                    </p>
                </div>
                <button
                    onClick={() => {
                        setIsAddOpen(true);
                        setEditingAccount(null);
                        setFormData({
                            name: "",
                            bankName: "",
                            accountNo: "",
                            ifsc: "",
                        });
                    }}
                    className="btn-primary px-8 py-4 flex items-center gap-3"
                >
                    <Plus size={20} /> Add New Account
                </button>
            </header>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Accounts List */}
                <div className="lg:col-span-2 space-y-4">
                    {accounts.length === 0 ? (
                        <div className="glass p-20 text-center space-y-4">
                            <Landmark
                                className="mx-auto text-white/5"
                                size={60}
                            />
                            <p className="text-text-dim text-sm italic">
                                You haven't added any bank accounts yet.
                            </p>
                        </div>
                    ) : (
                        accounts.map((acc) => (
                            <div
                                key={acc.id}
                                className={`glass transition-all duration-300 ${selectedAccount === acc.id ? "border-accent-blue/40 ring-1 ring-accent-blue/20" : "hover:border-white/10"}`}
                            >
                                <div className="p-8 flex items-start justify-between">
                                    <div className="flex items-start gap-5">
                                        <div className="w-14 h-14 bg-accent-blue/10 rounded-2xl flex items-center justify-center border border-accent-blue/20 text-accent-blue">
                                            <Landmark size={28} />
                                        </div>
                                        <div>
                                            <h3 className="text-xl font-outfit font-bold text-white mb-1 group-hover:text-accent-blue transition-colors">
                                                {acc.name}
                                            </h3>
                                            <p className="text-sm font-bold text-text-dim tracking-tight">
                                                Acc: {acc.accountNo}
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <button
                                            onClick={() => fetchLogs(acc.id)}
                                            className={`p-2.5 rounded-xl border transition-all ${selectedAccount === acc.id ? "bg-accent-blue text-white border-accent-blue" : "border-white/5 hover:bg-white/5 text-text-dim"}`}
                                            title="View Audit Logs"
                                        >
                                            <History size={18} />
                                        </button>
                                        <button
                                            onClick={() => {
                                                setEditingAccount(acc);
                                                setFormData({ ...acc });
                                                setIsAddOpen(true);
                                            }}
                                            className="p-2.5 rounded-xl border border-white/5 hover:bg-white/5 text-text-dim transition-all"
                                            title="Edit Account"
                                        >
                                            <Edit2 size={18} />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(acc.id)}
                                            className="p-2.5 rounded-xl border border-white/5 hover:bg-red-400/10 hover:text-red-400 transition-all"
                                            title="Delete Account"
                                        >
                                            <Trash2 size={18} />
                                        </button>
                                    </div>
                                </div>
                                <div className="px-8 py-4 grid grid-cols-2 md:grid-cols-4 gap-4 border-t border-white/5 bg-white/1">
                                    <div>
                                        <p className="text-[10px] font-black text-text-dim uppercase tracking-widest mb-1">
                                            Bank
                                        </p>
                                        <p className="text-xs font-bold text-white truncate">
                                            {acc.bankName}
                                        </p>
                                    </div>
                                    <div>
                                        <p className="text-[10px] font-black text-text-dim uppercase tracking-widest mb-1">
                                            IFSC Code
                                        </p>
                                        <p className="text-xs font-bold text-accent-blue font-mono">
                                            {acc.ifsc}
                                        </p>
                                    </div>
                                    <div className="md:col-span-2 text-right self-end">
                                        <p className="text-[10px] font-bold text-text-dim italic">
                                            Saved on{" "}
                                            {format(
                                                new Date(acc.createdAt),
                                                "MMM dd, yyyy",
                                            )}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        ))
                    )}
                </div>

                {/* Audit Logs Sidebar */}
                <div className="space-y-6">
                    <div className="glass flex flex-col h-full min-h-[500px]">
                        <div className="p-8 border-b border-white/5 flex items-center justify-between">
                            <h3 className="text-lg font-outfit font-bold flex items-center gap-3">
                                <History
                                    className="text-accent-blue"
                                    size={20}
                                />{" "}
                                Modification Logs
                            </h3>
                        </div>
                        <div className="flex-1 overflow-y-auto p-6 space-y-6">
                            {!selectedAccount ? (
                                <div className="h-full flex flex-col items-center justify-center text-center p-10 opacity-30">
                                    <AlertCircle size={40} className="mb-4" />
                                    <p className="text-xs font-bold uppercase tracking-widest">
                                        Select an account to view edit history
                                    </p>
                                </div>
                            ) : logs.length === 0 ? (
                                <p className="text-center text-text-dim text-sm italic py-10">
                                    No logs found for this account.
                                </p>
                            ) : (
                                logs.map((log) => (
                                    <div
                                        key={log.id}
                                        className="relative pl-6 border-l-2 border-white/5 pb-2"
                                    >
                                        <div className="absolute -left-[5px] top-0 w-2 h-2 rounded-full bg-accent-blue" />
                                        <div className="flex items-center justify-between mb-1">
                                            <span
                                                className={`text-[10px] font-black px-2 py-0.5 rounded uppercase tracking-tighter ${
                                                    log.action === "CREATE"
                                                        ? "bg-primary/20 text-primary"
                                                        : log.action ===
                                                            "UPDATE"
                                                          ? "bg-accent-blue/20 text-accent-blue"
                                                          : "bg-red-400/20 text-red-400"
                                                }`}
                                            >
                                                {log.action}
                                            </span>
                                            <span className="text-[10px] font-bold text-text-dim">
                                                {format(
                                                    new Date(log.createdAt),
                                                    "MMM dd, hh:mm a",
                                                )}
                                            </span>
                                        </div>
                                        {log.changes &&
                                            log.action === "UPDATE" && (
                                                <p className="text-[10px] text-text-dim font-medium leading-relaxed mt-2 italic">
                                                    Fields modified:{" "}
                                                    {Object.keys(
                                                        JSON.parse(log.changes),
                                                    )
                                                        .filter(
                                                            (k) =>
                                                                k !==
                                                                "_previous",
                                                        )
                                                        .join(", ")}
                                                </p>
                                            )}
                                    </div>
                                ))
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {/* Add/Edit Modal */}
            <AnimatePresence>
                {isAddOpen && (
                    <div className="fixed inset-0 z-100 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            className="glass-panel p-10 w-full max-w-lg shadow-2xl border-white/10"
                        >
                            <div className="flex items-center justify-between mb-8">
                                <h2 className="text-3xl font-outfit font-bold text-white flex items-center gap-3">
                                    {editingAccount ? (
                                        <Edit2 className="text-accent-blue" />
                                    ) : (
                                        <Plus className="text-primary" />
                                    )}
                                    {editingAccount
                                        ? "Edit Account"
                                        : "New Bank Account"}
                                </h2>
                                <button
                                    onClick={() => setIsAddOpen(false)}
                                    className="text-text-dim hover:text-white transition-colors"
                                >
                                    <X size={24} />
                                </button>
                            </div>

                            <form onSubmit={handleSubmit} className="space-y-6">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    <div className="md:col-span-2">
                                        <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em] mb-3 block">
                                            Beneficiary Name
                                        </label>
                                        <input
                                            required
                                            className="input-field"
                                            placeholder="Full Name as per bank records"
                                            value={formData.name}
                                            onChange={(e) =>
                                                setFormData({
                                                    ...formData,
                                                    name: e.target.value,
                                                })
                                            }
                                        />
                                    </div>
                                    <div>
                                        <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em] mb-3 block">
                                            Bank Name
                                        </label>
                                        <input
                                            required
                                            className="input-field"
                                            placeholder="e.g. HDFC Bank"
                                            value={formData.bankName}
                                            onChange={(e) =>
                                                setFormData({
                                                    ...formData,
                                                    bankName: e.target.value,
                                                })
                                            }
                                        />
                                    </div>
                                    <div>
                                        <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em] mb-3 block">
                                            IFSC Code
                                        </label>
                                        <input
                                            required
                                            className="input-field font-mono"
                                            placeholder="HDFC0001234"
                                            value={formData.ifsc}
                                            onChange={(e) =>
                                                setFormData({
                                                    ...formData,
                                                    ifsc: e.target.value.toUpperCase(),
                                                })
                                            }
                                        />
                                    </div>
                                    <div className="md:col-span-2">
                                        <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.2em] mb-3 block">
                                            Account Number
                                        </label>
                                        <input
                                            required
                                            className="input-field"
                                            placeholder="Enter 12-16 digit account number"
                                            value={formData.accountNo}
                                            onChange={(e) =>
                                                setFormData({
                                                    ...formData,
                                                    accountNo: e.target.value,
                                                })
                                            }
                                        />
                                    </div>
                                </div>

                                <div className="pt-6 flex gap-4">
                                    <button
                                        type="button"
                                        onClick={() => setIsAddOpen(false)}
                                        className="flex-1 px-8 py-4 rounded-2xl border border-white/10 text-white font-bold hover:bg-white/5 transition-all outline-none"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        disabled={isLoading}
                                        className="flex-1 btn-primary py-4 font-black shadow-xl shadow-primary/20 flex items-center justify-center gap-2 outline-none"
                                    >
                                        {isLoading ? (
                                            <RefreshCw
                                                className="animate-spin"
                                                size={20}
                                            />
                                        ) : (
                                            <ShieldCheck size={20} />
                                        )}
                                        {editingAccount
                                            ? "Sync Changes"
                                            : "Securely Save"}
                                    </button>
                                </div>
                            </form>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* Notification Modal */}
            <AnimatePresence>
                {alert && (
                    <div className="fixed inset-0 z-200 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            className="glass-panel p-10 w-full max-w-sm shadow-2xl border-white/10 text-center"
                        >
                            <div
                                className={`mx-auto w-16 h-16 rounded-full flex items-center justify-center mb-6 ${alert.type === "success" ? "bg-primary/10 text-primary" : "bg-red-400/10 text-red-400"}`}
                            >
                                {alert.type === "success" ? (
                                    <CheckCircle2 size={32} />
                                ) : (
                                    <AlertCircle size={32} />
                                )}
                            </div>
                            <h2 className="text-2xl font-outfit font-bold mb-2 tracking-tight uppercase">
                                {alert.title}
                            </h2>
                            <p className="text-text-dim text-sm mb-10 font-medium leading-relaxed">
                                {alert.message}
                            </p>
                            <button
                                onClick={() => setAlert(null)}
                                className={`w-full py-4 rounded-xl font-black uppercase text-xs tracking-widest transition-all ${
                                    alert.type === "success"
                                        ? "bg-primary text-bg-dark"
                                        : "border border-red-500/20 text-red-500 hover:bg-red-500/5"
                                }`}
                            >
                                Acknowledge
                            </button>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default BankAccounts;

const RefreshCw = ({
    className,
    size,
}: {
    className?: string;
    size?: number;
}) => (
    <svg
        className={className}
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
    >
        <path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />
        <path d="M3 3v5h5" />
        <path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16" />
        <path d="M16 16h5v5" />
    </svg>
);
