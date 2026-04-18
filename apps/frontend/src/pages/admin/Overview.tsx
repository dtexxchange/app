import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    Activity,
    ArrowDownLeft,
    ArrowUpRight,
    CheckCircle2,
    History,
    KeyIcon,
    Search,
    ShieldAlert,
    ShieldCheck,
    ShieldCheck as ShieldIcon,
    Users,
    XCircle,
} from "lucide-react";
import React, { useCallback, useEffect, useState } from "react";
import api from "../../lib/api";
import { ENABLE_E2EE, decryptData, importPrivateKey } from "../../lib/crypto";

const Overview: React.FC = () => {
    const [users, setUsers] = useState<any[]>([]);
    const [transactions, setTransactions] = useState<any[]>([]);
    const [hasKeys, setHasKeys] = useState(false);
    const [txFilter, setTxFilter] = useState({
        status: "",
        type: "",
        search: "",
    });
    const [selectedTx, setSelectedTx] = useState<any>(null);
    const [decryptedBankDetails, setDecryptedBankDetails] = useState<any>(null);

    const fetchTransactions = useCallback(async () => {
        try {
            const params = new URLSearchParams();
            if (txFilter.status) params.append("status", txFilter.status);
            if (txFilter.type) params.append("type", txFilter.type);

            const { data } = await api.get(
                `/wallet/transactions?${params.toString()}`,
            );
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

    const fetchUsers = async () => {
        try {
            const { data } = await api.get("/users");
            setUsers(data);
        } catch (e) {
            console.error(e);
        }
    };

    const checkKeys = () => {
        const privKey = localStorage.getItem("admin_private_key");
        setHasKeys(!!privKey);
    };

    useEffect(() => {
        fetchTransactions();
        fetchUsers();
        checkKeys();
    }, [fetchTransactions]);

    const handleUpdateStatus = async (id: string, status: string) => {
        try {
            await api.patch(`/wallet/transactions/${id}/status`, { status });
            fetchTransactions();
            if (selectedTx?.id === id) {
                const { data } = await api.get(`/wallet/transactions/${id}`);
                setSelectedTx(data);
            }
        } catch (err) {
            console.error(err);
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

    const openTxDetail = async (tx: any) => {
        setSelectedTx(tx);
        setDecryptedBankDetails(null);
        try {
            const { data } = await api.get(`/wallet/transactions/${tx.id}`);
            setSelectedTx(data);
            if (data.type === "EXCHANGE" && data.bankDetails) {
                attemptDecryption(data.bankDetails);
            }
        } catch (e) {
            console.error(e);
        }
    };

    return (
        <div className="space-y-8">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    Network Overview
                </h1>
                <p className="text-text-dim">
                    Real-time platform statistics and activity.
                </p>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <div className="glass p-8 relative overflow-hidden group">
                    <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:scale-110 group-hover:opacity-20 transition-all">
                        <Users size={80} />
                    </div>
                    <p className="text-text-dim text-xs font-bold uppercase tracking-widest mb-2">
                        Total Users
                    </p>
                    <h3 className="text-4xl font-outfit font-bold text-white">
                        {users.length}
                    </h3>
                    <div className="mt-4 flex items-center gap-2 text-primary text-xs font-bold">
                        <Activity size={14} /> Active Node
                    </div>
                </div>

                <div className="glass p-8 relative overflow-hidden group">
                    <div className="absolute top-0 right-0 p-4 opacity-10 group-hover:scale-110 group-hover:opacity-20 transition-all text-primary">
                        <ShieldCheck size={80} />
                    </div>
                    <p className="text-text-dim text-xs font-bold uppercase tracking-widest mb-2">
                        E2EE Security
                    </p>
                    <h3
                        className={`text-2xl font-outfit font-bold flex items-center gap-3 ${hasKeys ? "text-primary" : "text-red-400"}`}
                    >
                        {hasKeys ? (
                            <ShieldIcon size={24} />
                        ) : (
                            <ShieldAlert size={24} />
                        )}
                        {hasKeys ? "Operational" : "Keys Missing"}
                    </h3>
                    <p className="mt-4 text-text-dim text-xs">
                        Decryption terminal status
                    </p>
                </div>

                <div className="glass p-8 md:col-span-2 lg:col-span-1 border-primary/20 bg-primary/2">
                    <p className="text-text-dim text-xs font-bold uppercase tracking-widest mb-2">
                        Infrastructure
                    </p>
                    <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center border border-primary/20">
                            <KeyIcon className="text-primary" />
                        </div>
                        <div>
                            <p className="text-white font-bold text-lg">
                                Master Ledger
                            </p>
                            <p className="text-text-dim text-xs tracking-tight">
                                Mainnet Synchronization Active
                            </p>
                        </div>
                    </div>
                </div>
            </div>

            <section className="glass overflow-hidden">
                <div className="p-8 border-b border-white/5 flex flex-col lg:flex-row items-center gap-6 justify-between">
                    <h3 className="text-2xl font-outfit font-bold flex items-center gap-3 shrink-0">
                        <Activity className="text-primary" />
                        Transaction Stream
                    </h3>

                    <div className="flex flex-wrap items-center gap-4 w-full justify-end">
                        <div className="relative flex-1 max-w-sm">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-dim w-4 h-4" />
                            <input
                                type="text"
                                placeholder="Search by user email..."
                                className="w-full bg-white/5 border border-white/10 rounded-xl pl-11 pr-4 py-3 text-sm focus:ring-2 focus:ring-primary/20 focus:outline-none focus:border-primary text-white transition-all"
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
                            className="bg-white/5 border border-white/10 rounded-xl px-6 py-3 text-sm focus:outline-none focus:border-primary text-white transition-all appearance-none cursor-pointer hover:bg-white/10"
                            value={txFilter.status}
                            onChange={(e) =>
                                setTxFilter({
                                    ...txFilter,
                                    status: e.target.value,
                                })
                            }
                        >
                            <option value="">All Status</option>
                            <option value="PENDING">Pending</option>
                            <option value="COMPLETED">Completed</option>
                            <option value="REJECTED">Rejected</option>
                        </select>
                    </div>
                </div>

                <div className="w-full overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-xs font-semibold tracking-widest uppercase">
                                <th className="px-8 py-5">User Account</th>
                                <th className="px-8 py-5">Instruction</th>
                                <th className="px-8 py-5">Asset Value</th>
                                <th className="px-8 py-5 text-right">
                                    Network Status
                                </th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {transactions.map((tx) => (
                                <tr
                                    key={tx.id}
                                    className="hover:bg-white/2 cursor-pointer transition-colors"
                                    onClick={() => openTxDetail(tx)}
                                >
                                    <td className="px-8 py-6">
                                        <div className="font-bold text-white text-base mb-1">
                                            {tx.user?.email}
                                        </div>
                                        <div className="text-[10px] text-text-dim font-mono tracking-tighter">
                                            ID: {tx.id.toUpperCase()}
                                        </div>
                                    </td>
                                    <td className="px-8 py-6">
                                        <div
                                            className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest border ${tx.type === "DEPOSIT" ? "border-primary/20 text-primary bg-primary/5" : "border-accent-blue/20 text-accent-blue bg-accent-blue/5"}`}
                                        >
                                            {tx.type === "DEPOSIT" ? (
                                                <ArrowDownLeft size={12} />
                                            ) : (
                                                <ArrowUpRight size={12} />
                                            )}
                                            {tx.type}
                                        </div>
                                        <div className="text-[10px] text-text-dim mt-2 font-medium">
                                            {format(
                                                new Date(tx.createdAt),
                                                "MMM dd, HH:mm",
                                            )}
                                        </div>
                                    </td>
                                    <td className="px-8 py-6">
                                        <div className="text-lg font-outfit font-bold text-white">
                                            {tx.amount.toLocaleString()}
                                            <span className="text-xs text-primary ml-1.5 font-bold tracking-widest">
                                                USDT
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-8 py-6 text-right">
                                        {tx.status === "PENDING" ? (
                                            <div className="flex items-center gap-2 justify-end">
                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        handleUpdateStatus(
                                                            tx.id,
                                                            "COMPLETED",
                                                        );
                                                    }}
                                                    className="p-2.5 text-primary bg-primary/10 hover:bg-primary/20 border border-primary/20 rounded-xl transition-all"
                                                >
                                                    <CheckCircle2 size={18} />
                                                </button>
                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        handleUpdateStatus(
                                                            tx.id,
                                                            "REJECTED",
                                                        );
                                                    }}
                                                    className="p-2.5 text-red-500 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 rounded-xl transition-all"
                                                >
                                                    <XCircle size={18} />
                                                </button>
                                            </div>
                                        ) : (
                                            <span
                                                className={`text-xs font-bold tracking-widest uppercase py-1.5 px-3 rounded-lg ${tx.status === "COMPLETED" ? "text-primary bg-primary/5" : "text-red-500 bg-red-400/5"}`}
                                            >
                                                {tx.status}
                                            </span>
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    {transactions.length === 0 && (
                        <div className="py-20 text-center">
                            <Activity
                                className="mx-auto text-white/5 mb-4"
                                size={48}
                            />
                            <p className="text-text-dim text-sm font-medium tracking-wide italic">
                                No synchronized transaction data found.
                            </p>
                        </div>
                    )}
                </div>
            </section>

            {/* Transaction Detail Modal */}
            <AnimatePresence>
                {selectedTx && (
                    <div className="fixed inset-0 z-100 flex items-center justify-end bg-black/60 backdrop-blur-sm">
                        <motion.div
                            initial={{ x: "100%" }}
                            animate={{ x: 0 }}
                            exit={{ x: "100%" }}
                            transition={{
                                type: "spring",
                                damping: 25,
                                stiffness: 200,
                            }}
                            className="h-full w-full max-w-2xl bg-bg-dark border-l border-white/10 shadow-2xl overflow-y-auto"
                        >
                            <div className="p-10">
                                <button
                                    onClick={() => setSelectedTx(null)}
                                    className="p-2 hover:bg-white/5 rounded-lg text-text-dim mb-8 flex items-center gap-2 text-sm uppercase tracking-widest font-bold"
                                >
                                    <XCircle size={20} /> Close Detail
                                </button>

                                <div className="space-y-10">
                                    <header className="flex justify-between items-end">
                                        <div>
                                            <p className="text-primary text-[10px] font-bold uppercase tracking-[0.3em] mb-3">
                                                Transaction Manifest
                                            </p>
                                            <h2 className="text-4xl font-outfit font-bold text-white tracking-tight">
                                                {selectedTx.amount.toLocaleString()}{" "}
                                                <span className="text-text-dim font-normal">
                                                    USDT
                                                </span>
                                            </h2>
                                        </div>
                                        <div
                                            className={`px-4 py-2 rounded-xl border font-bold text-xs tracking-widest uppercase ${
                                                selectedTx.status ===
                                                "COMPLETED"
                                                    ? "border-primary/30 text-primary"
                                                    : selectedTx.status ===
                                                        "PENDING"
                                                      ? "border-accent-blue/30 text-accent-blue"
                                                      : "border-red-500/30 text-red-500"
                                            }`}
                                        >
                                            {selectedTx.status}
                                        </div>
                                    </header>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="glass p-6">
                                            <p className="text-[10px] font-bold text-text-dim uppercase mb-2">
                                                Network Type
                                            </p>
                                            <p className="text-white font-bold">
                                                {selectedTx.type}
                                            </p>
                                        </div>
                                        <div className="glass p-6">
                                            <p className="text-[10px] font-bold text-text-dim uppercase mb-2">
                                                Synchronized
                                            </p>
                                            <p className="text-white font-bold">
                                                {format(
                                                    new Date(
                                                        selectedTx.createdAt,
                                                    ),
                                                    "MMM dd, yyyy",
                                                )}
                                            </p>
                                        </div>
                                    </div>

                                    {selectedTx.type === "EXCHANGE" && (
                                        <div className="glass p-8">
                                            <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-2">
                                                <ShieldIcon
                                                    size={16}
                                                    className="text-primary"
                                                />{" "}
                                                Decrypted Bank PII
                                            </h3>
                                            {decryptedBankDetails ? (
                                                <div className="space-y-4">
                                                    {[
                                                        {
                                                            label: "Beneficiary",
                                                            val: decryptedBankDetails.name,
                                                        },
                                                        {
                                                            label: "Account No.",
                                                            val: decryptedBankDetails.account,
                                                        },
                                                        {
                                                            label: "Bank Name",
                                                            val: decryptedBankDetails.bank,
                                                        },
                                                        {
                                                            label: "Routing / IFSC",
                                                            val: decryptedBankDetails.ifsc,
                                                            color: "text-accent-blue",
                                                        },
                                                    ].map((item, i) => (
                                                        <div
                                                            key={i}
                                                            className="flex justify-between items-center py-3 border-b border-white/5 last:border-0"
                                                        >
                                                            <span className="text-[10px] font-bold text-text-dim uppercase">
                                                                {item.label}
                                                            </span>
                                                            <span
                                                                className={`font-bold text-sm ${item.color || "text-white"}`}
                                                            >
                                                                {item.val}
                                                            </span>
                                                        </div>
                                                    ))}
                                                </div>
                                            ) : (
                                                <div className="bg-red-400/5 p-6 rounded-2xl border border-red-400/10 flex items-center gap-4">
                                                    <ShieldAlert
                                                        className="text-red-400"
                                                        size={24}
                                                    />
                                                    <p className="text-xs text-text-dim font-medium leading-relaxed">
                                                        Identity protected.
                                                        Decryption required with
                                                        authenticated terminal
                                                        master key.
                                                    </p>
                                                </div>
                                            )}
                                        </div>
                                    )}

                                    <div>
                                        <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-2">
                                            <History
                                                size={16}
                                                className="text-primary"
                                            />{" "}
                                            Activity Timeline
                                        </h3>
                                        <div className="space-y-0 pl-3 border-l-2 border-white/5">
                                            {selectedTx.logs?.map(
                                                (log: any) => (
                                                    <div
                                                        key={log.id}
                                                        className="relative pl-8 pb-8 last:pb-0"
                                                    >
                                                        <div className="absolute left-[-11px] top-0 w-5 h-5 rounded-full bg-bg-dark border-2 border-primary shadow-lg flex items-center justify-center">
                                                            <div className="w-1.5 h-1.5 rounded-full bg-primary" />
                                                        </div>
                                                        <div className="flex justify-between gap-4">
                                                            <div>
                                                                <div className="text-sm font-bold text-white tracking-wide">
                                                                    {log.status}
                                                                </div>
                                                                <div className="text-xs text-text-dim mt-1 font-medium">
                                                                    {log.note ||
                                                                        "Status synchronized"}
                                                                </div>
                                                            </div>
                                                            <div className="text-right shrink-0">
                                                                <div className="text-[10px] font-bold text-white/40 uppercase mb-1">
                                                                    {format(
                                                                        new Date(
                                                                            log.createdAt,
                                                                        ),
                                                                        "MMM dd, HH:mm",
                                                                    )}
                                                                </div>
                                                                <div className="text-[10px] text-primary/60 font-bold uppercase tracking-tighter">
                                                                    by{" "}
                                                                    {log.actor}
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                ),
                                            )}
                                        </div>
                                    </div>

                                    {selectedTx.status === "PENDING" && (
                                        <div className="pt-10 flex gap-4">
                                            <button
                                                onClick={() =>
                                                    handleUpdateStatus(
                                                        selectedTx.id,
                                                        "COMPLETED",
                                                    )
                                                }
                                                className="flex-1 px-8 py-5 rounded-2xl bg-primary text-bg-dark font-black uppercase text-xs tracking-[0.2em] shadow-2xl shadow-primary/20 hover:scale-105 active:scale-95 transition-all"
                                            >
                                                Approve Transaction
                                            </button>
                                            <button
                                                onClick={() =>
                                                    handleUpdateStatus(
                                                        selectedTx.id,
                                                        "REJECTED",
                                                    )
                                                }
                                                className="flex-1 px-8 py-5 rounded-2xl border border-red-500/20 bg-red-500/5 text-red-500 font-extrabold uppercase text-xs tracking-[0.2em] hover:bg-red-500/10 transition-all"
                                            >
                                                Reject Instruction
                                            </button>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default Overview;
