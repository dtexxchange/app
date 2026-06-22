import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    Activity,
    ArrowDownLeft,
    ArrowUpRight,
    CheckCircle2,
    ChevronLeft,
    DollarSign,
    History,
    Search,
    ShieldAlert,
    ShieldCheck as ShieldIcon,
    XCircle,
} from "lucide-react";
import React, { useCallback, useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import api from "../../lib/api";
import { ENABLE_E2EE, decryptData, importPrivateKey } from "../../lib/crypto";
import { formatAmount } from "../../lib/formatters";

const UserTransactions: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [user, setUser] = useState<any>(null);
    const [transactions, setTransactions] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [filter, setFilter] = useState({ type: "", status: "", search: "" });
    const [selectedTx, setSelectedTx] = useState<any>(null);
    const [decryptedBankDetails, setDecryptedBankDetails] = useState<any>(null);

    const fetchUser = useCallback(async () => {
        try {
            const { data } = await api.get(`/users/${id}`);
            setUser(data);
        } catch (e) {
            console.error(e);
        }
    }, [id]);

    const fetchTransactions = useCallback(async () => {
        try {
            const params = new URLSearchParams();
            params.append("userId", id!);
            if (filter.status) params.append("status", filter.status);
            if (filter.type) params.append("type", filter.type);

            const { data } = await api.get(
                `/wallet/transactions?${params.toString()}`,
            );
            setTransactions(data);
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    }, [id, filter.status, filter.type]);

    useEffect(() => {
        fetchUser();
    }, [fetchUser]);

    useEffect(() => {
        fetchTransactions();
    }, [fetchTransactions]);

    const handleUpdateStatus = async (txId: string, status: string) => {
        let utr: string | null = null;
        if (status === "COMPLETED") {
            utr = prompt("Please enter the UTR / reference number to complete this transaction:");
            if (utr === null) return;
            if (!utr.trim()) {
                alert("UTR is required to complete the transaction.");
                return;
            }
        }
        try {
            await api.patch(`/wallet/transactions/${txId}/status`, { status, utr });
            fetchTransactions();
            if (selectedTx?.id === txId) {
                const { data } = await api.get(`/wallet/transactions/${txId}`);
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
            if (
                (data.type === "EXCHANGE" || data.type === "WITHDRAWAL") &&
                data.bankDetails
            ) {
                attemptDecryption(data.bankDetails);
            }
        } catch (e) {
            console.error(e);
        }
    };

    const filteredTransactions = transactions.filter((tx) => {
        if (!filter.search) return true;
        const searchLower = filter.search.toLowerCase();
        return (
            tx.id.toLowerCase().includes(searchLower) ||
            tx.amount.toString().includes(searchLower)
        );
    });

    return (
        <div className="space-y-8">
            <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
                <div>
                    <button
                        onClick={() => navigate("/users")}
                        className="flex items-center gap-2 text-text-dim hover:text-white transition-colors text-xs font-bold uppercase tracking-widest mb-6"
                    >
                        <ChevronLeft size={16} /> Back to Users
                    </button>
                    <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                        {user ? `${user.firstName || ""} ${user.lastName || ""}`.trim() || user.email : "User"}'s Ledger
                    </h1>
                    <p className="text-text-dim font-medium">
                        Complete transaction history and immutable audit trail.
                    </p>
                </div>
            </header>

            <section className="glass overflow-hidden">
                <div className="p-8 border-b border-white/5 bg-white/1 flex flex-col lg:flex-row items-center gap-6 justify-between">
                    <div className="flex items-center gap-4 w-full lg:w-auto overflow-x-auto scrollbar-hide pb-2 lg:pb-0">
                        {["", "DEPOSIT", "EXCHANGE", "WITHDRAWAL"].map((type) => (
                            <button
                                key={type}
                                onClick={() => setFilter({ ...filter, type })}
                                className={`px-5 py-2 rounded-full text-[10px] font-bold uppercase tracking-widest border transition-all shrink-0 ${
                                    filter.type === type
                                        ? "bg-primary border-primary text-bg-dark shadow-lg shadow-primary/10"
                                        : "border-white/10 text-text-dim hover:text-white hover:border-white/20"
                                }`}
                            >
                                {type || "All Types"}
                            </button>
                        ))}
                    </div>

                    <div className="flex flex-wrap items-center gap-4 w-full lg:w-auto justify-end">
                        <div className="relative w-full lg:w-64">
                            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-text-dim w-4 h-4" />
                            <input
                                type="text"
                                placeholder="Search by ID or amount..."
                                className="w-full bg-white/5 border border-white/10 rounded-xl pl-11 pr-4 py-2.5 text-xs focus:ring-2 focus:ring-primary/20 focus:outline-none focus:border-primary text-white transition-all"
                                value={filter.search}
                                onChange={(e) =>
                                    setFilter({
                                        ...filter,
                                        search: e.target.value,
                                    })
                                }
                            />
                        </div>
                        <select
                            className="bg-white/5 border border-white/10 rounded-xl px-5 py-2.5 text-xs font-bold text-white focus:outline-none focus:border-primary transition-all appearance-none cursor-pointer"
                            value={filter.status}
                            onChange={(e) =>
                                setFilter({ ...filter, status: e.target.value })
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
                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-[10px] font-black tracking-[0.2em] uppercase">
                                <th className="px-10 py-5">Instruction Hash</th>
                                <th className="px-10 py-5">Asset Value</th>
                                <th className="px-10 py-5">Network Status</th>
                                <th className="px-10 py-5 text-right">Synchronization</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {isLoading ? (
                                <tr>
                                    <td colSpan={4} className="py-20 text-center">
                                        <div className="w-8 h-8 border-4 border-primary/20 border-t-primary rounded-full animate-spin mx-auto" />
                                    </td>
                                </tr>
                            ) : filteredTransactions.map((tx) => (
                                <tr
                                    key={tx.id}
                                    className="hover:bg-white/2 cursor-pointer transition-colors group"
                                    onClick={() => openTxDetail(tx)}
                                >
                                    <td className="px-10 py-6">
                                        <div className="flex items-center gap-3">
                                            <div
                                                className={`w-10 h-10 rounded-xl flex items-center justify-center border transition-all ${
                                                    tx.type === "DEPOSIT"
                                                        ? "bg-primary/5 border-primary/20 text-primary"
                                                        : tx.type === "WITHDRAWAL"
                                                        ? "bg-orange-500/5 border-orange-500/20 text-orange-500"
                                                        : "bg-accent-blue/5 border-accent-blue/20 text-accent-blue"
                                                }`}
                                            >
                                                {tx.type === "DEPOSIT" ? (
                                                    <ArrowDownLeft size={18} />
                                                ) : (
                                                    <ArrowUpRight size={18} />
                                                )}
                                            </div>
                                            <div>
                                                <div className="font-bold text-white group-hover:text-primary transition-colors">
                                                    {tx.id.toUpperCase()}
                                                </div>
                                                <p className="text-[10px] font-bold text-text-dim uppercase tracking-tighter mt-0.5">
                                                    {tx.type} Request
                                                </p>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-10 py-6">
                                        <div className="text-lg font-outfit font-bold text-white">
                                            {formatAmount(tx.amount)}
                                            <span className="text-xs text-text-dim ml-1.5 font-medium">
                                                USDT
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-10 py-6">
                                        <div
                                            className={`inline-flex items-center gap-2 px-3 py-1 rounded-lg text-[9px] font-black uppercase tracking-widest border ${
                                                tx.status === "COMPLETED"
                                                    ? "border-primary/20 text-primary bg-primary/5"
                                                    : tx.status === "PENDING"
                                                      ? "border-accent-blue/20 text-accent-blue bg-accent-blue/5"
                                                      : "border-red-400/20 text-red-400"
                                            }`}
                                        >
                                            {tx.status === "COMPLETED" ? (
                                                <CheckCircle2 size={12} />
                                            ) : tx.status === "PENDING" ? (
                                                <Activity
                                                    size={12}
                                                    className="animate-pulse"
                                                />
                                            ) : (
                                                <XCircle size={12} />
                                            )}
                                            {tx.status}
                                        </div>
                                    </td>
                                    <td className="px-10 py-6 text-right">
                                        <div className="text-sm font-bold text-white">
                                            {format(
                                                new Date(tx.createdAt),
                                                "MMM dd, yyyy",
                                            )}
                                        </div>
                                        <div className="text-[10px] text-text-dim font-medium mt-1">
                                            {format(
                                                new Date(tx.createdAt),
                                                "HH:mm",
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                    {!isLoading && filteredTransactions.length === 0 && (
                        <div className="py-24 text-center">
                            <History
                                className="mx-auto text-white/5 mb-6"
                                size={64}
                            />
                            <p className="text-text-dim font-medium italic">
                                No matching lifecycle events found.
                            </p>
                        </div>
                    )}
                </div>
            </section>

            {/* Transaction Detail Modal (Same as Overview.tsx for consistency) */}
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
                                                {formatAmount(
                                                    selectedTx.amount,
                                                )}{" "}
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

                                    {(selectedTx.type === "EXCHANGE" || selectedTx.type === "WITHDRAWAL") && (
                                        <div className="glass p-8">
                                            <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-2">
                                                <ShieldIcon
                                                    size={16}
                                                    className="text-primary"
                                                />{" "}
                                                {selectedTx.type === "WITHDRAWAL" ? "Withdrawal Destination" : "Decrypted Bank PII"}
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

                                    {selectedTx.type === "WITHDRAWAL" && (
                                        <div className="glass p-8">
                                            <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-2">
                                                <DollarSign
                                                    size={16}
                                                    className="text-orange-500"
                                                />{" "}
                                                Withdrawal Fee Summary
                                            </h3>
                                            <div className="space-y-4">
                                                <div className="flex justify-between items-center py-3 border-b border-white/5">
                                                    <span className="text-[10px] font-bold text-text-dim uppercase">Gross Amount</span>
                                                    <span className="font-bold text-white">{formatAmount(selectedTx.amount)} USDT</span>
                                                </div>
                                                <div className="flex justify-between items-center py-3 border-b border-white/5">
                                                    <span className="text-[10px] font-bold text-text-dim uppercase">Platform Fee</span>
                                                    <span className="font-bold text-red-500">-{formatAmount(selectedTx.fee || 0)} USDT</span>
                                                </div>
                                                <div className="flex justify-between items-center py-3 last:border-0">
                                                    <span className="text-[10px] font-bold text-text-dim uppercase">Net Settlement</span>
                                                    <span className="font-bold text-primary text-lg">{formatAmount(selectedTx.amount - (selectedTx.fee || 0))} USDT</span>
                                                </div>
                                            </div>
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
                                                                        "MMM dd, hh:mm a",
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

export default UserTransactions;
