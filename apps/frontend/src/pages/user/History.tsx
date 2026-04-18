import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    Activity,
    ArrowDownLeft,
    ArrowUpRight,
    CheckCircle2,
    ExternalLink,
    History as HistoryIcon,
    XCircle,
} from "lucide-react";
import React, { useCallback, useEffect, useState } from "react";
import api from "../../lib/api";

const History: React.FC = () => {
    const [transactions, setTransactions] = useState<any[]>([]);
    const [filter, setFilter] = useState({ type: "", status: "" });
    const [selectedTx, setSelectedTx] = useState<any>(null);

    const fetchHistory = useCallback(async () => {
        try {
            const params = new URLSearchParams();
            if (filter.status) params.append("status", filter.status);
            if (filter.type) params.append("type", filter.type);

            const { data } = await api.get(
                `/wallet/transactions?${params.toString()}`,
            );
            setTransactions(data);
        } catch (e) {
            console.error(e);
        }
    }, [filter]);

    useEffect(() => {
        fetchHistory();
    }, [fetchHistory]);

    return (
        <div className="space-y-10">
            <header className="flex flex-col md:flex-row md:items-end justify-between gap-6">
                <div>
                    <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                        Ledger Activity
                    </h1>
                    <p className="text-text-dim max-w-xl font-medium">
                        A complete immutable record of your platform
                        interactions and settlements.
                    </p>
                </div>
            </header>

            <section className="glass overflow-hidden">
                <div className="p-8 border-b border-white/5 bg-white/1 flex flex-col md:flex-row items-center gap-6 justify-between">
                    <div className="flex items-center gap-4 w-full md:w-auto overflow-x-auto scrollbar-hide pb-2 md:pb-0">
                        {["", "DEPOSIT", "EXCHANGE"].map((type) => (
                            <button
                                key={type}
                                onClick={() => setFilter({ ...filter, type })}
                                className={`px-5 py-2 rounded-full text-[10px] font-bold uppercase tracking-widest border transition-all shrink-0 ${
                                    filter.type === type
                                        ? "bg-accent-blue border-accent-blue text-white shadow-lg shadow-accent-blue/10"
                                        : "border-white/10 text-text-dim hover:text-white hover:border-white/20"
                                }`}
                            >
                                {type || "All Instructions"}
                            </button>
                        ))}
                    </div>

                    <div className="flex items-center gap-4 w-full md:w-auto">
                        <select
                            className="flex-1 md:w-48 bg-white/5 border border-white/10 rounded-xl px-5 py-2.5 text-xs font-bold text-white focus:outline-none focus:border-accent-blue transition-all appearance-none cursor-pointer"
                            value={filter.status}
                            onChange={(e) =>
                                setFilter({ ...filter, status: e.target.value })
                            }
                        >
                            <option value="">Status: All States</option>
                            <option value="PENDING">Pending Approval</option>
                            <option value="COMPLETED">Settled / Closed</option>
                            <option value="REJECTED">Failed / Rejected</option>
                        </select>
                    </div>
                </div>

                <div className="w-full overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-[10px] font-black tracking-[0.2em] uppercase">
                                <th className="px-10 py-5">Instruction Hash</th>
                                <th className="px-10 py-5">Value (USDT)</th>
                                <th className="px-10 py-5">Network Status</th>
                                <th className="px-10 py-5 text-right">
                                    Synchronization
                                </th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            {transactions.map((tx) => (
                                <tr
                                    key={tx.id}
                                    className="hover:bg-white/2 cursor-pointer transition-colors group"
                                    onClick={() => setSelectedTx(tx)}
                                >
                                    <td className="px-10 py-6">
                                        <div className="flex items-center gap-3">
                                            <div
                                                className={`w-10 h-10 rounded-xl flex items-center justify-center border transition-all ${
                                                    tx.type === "DEPOSIT"
                                                        ? "bg-primary/5 border-primary/20 text-primary"
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
                                                <div className="font-bold text-white group-hover:text-accent-blue transition-colors">
                                                    TX-
                                                    {tx.id
                                                        .substring(0, 8)
                                                        .toUpperCase()}
                                                </div>
                                                <p className="text-[10px] font-bold text-text-dim uppercase tracking-tighter mt-0.5">
                                                    {tx.type} Request
                                                </p>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-10 py-6">
                                        <div className="text-lg font-outfit font-bold text-white">
                                            {tx.amount.toLocaleString()}
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
                    {transactions.length === 0 && (
                        <div className="py-24 text-center">
                            <HistoryIcon
                                className="mx-auto text-white/5 mb-6"
                                size={64}
                            />
                            <p className="text-text-dim font-medium">
                                No recorded lifecycle events found.
                            </p>
                        </div>
                    )}
                </div>
            </section>

            {/* Tx Detail Sidebar */}
            <AnimatePresence>
                {selectedTx && (
                    <div className="fixed inset-0 z-100 flex items-center justify-end bg-black/60 backdrop-blur-sm">
                        <motion.div
                            initial={{ x: "100%" }}
                            animate={{ x: 0 }}
                            exit={{ x: "100%" }}
                            className="h-full w-full max-w-2xl bg-bg-dark border-l border-white/10 shadow-2xl overflow-y-auto"
                        >
                            <div className="p-10">
                                <button
                                    onClick={() => setSelectedTx(null)}
                                    className="p-2 hover:bg-white/5 rounded-lg text-text-dim mb-10 flex items-center gap-2 text-xs font-bold uppercase tracking-widest"
                                >
                                    <XCircle size={20} /> Close Detail
                                </button>

                                <div className="space-y-12">
                                    <header>
                                        <p className="text-accent-blue text-[10px] font-black uppercase tracking-[0.3em] mb-3">
                                            Immutable Ledger Record
                                        </p>
                                        <h2 className="text-4xl font-outfit font-bold text-white">
                                            {selectedTx.amount.toLocaleString()}{" "}
                                            <span className="text-text-dim font-normal">
                                                USDT
                                            </span>
                                        </h2>
                                    </header>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="glass p-6">
                                            <p className="text-[10px] font-black text-text-dim uppercase tracking-widest mb-2">
                                                Instruction Type
                                            </p>
                                            <p className="text-white font-bold">
                                                {selectedTx.type}
                                            </p>
                                        </div>
                                        <div className="glass p-6">
                                            <p className="text-[10px] font-black text-text-dim uppercase tracking-widest mb-2">
                                                Network Status
                                            </p>
                                            <p
                                                className={`font-bold ${selectedTx.status === "COMPLETED" ? "text-primary" : "text-accent-blue"}`}
                                            >
                                                {selectedTx.status}
                                            </p>
                                        </div>
                                    </div>

                                    {selectedTx.conversionRate && (
                                        <div className="glass p-8 border-accent-blue/10 bg-accent-blue/2">
                                            <div className="flex justify-between items-center">
                                                <div>
                                                    <p className="text-[10px] font-bold text-text-dim uppercase tracking-widest mb-1">
                                                        Exchange Rate Applied
                                                    </p>
                                                    <p className="text-2xl font-outfit font-bold text-white">
                                                        ₹
                                                        {selectedTx.conversionRate.toFixed(
                                                            2,
                                                        )}
                                                    </p>
                                                </div>
                                                <div className="text-right">
                                                    <p className="text-[10px] font-bold text-text-dim uppercase tracking-widest mb-1">
                                                        Estimated Credit
                                                    </p>
                                                    <p className="text-2xl font-outfit font-bold text-primary">
                                                        ₹
                                                        {(
                                                            selectedTx.amount *
                                                            selectedTx.conversionRate
                                                        ).toLocaleString()}
                                                    </p>
                                                </div>
                                            </div>
                                        </div>
                                    )}

                                    <div>
                                        <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-3">
                                            <HistoryIcon
                                                size={16}
                                                className="text-accent-blue"
                                            />{" "}
                                            Processing Timeline
                                        </h3>
                                        <div className="space-y-0 pl-3 border-l-2 border-white/5">
                                            {selectedTx.logs?.map(
                                                (log: any) => (
                                                    <div
                                                        key={log.id}
                                                        className="relative pl-8 pb-8 last:pb-0"
                                                    >
                                                        <div className="absolute left-[-11px] top-0 w-4 h-4 rounded-full bg-bg-dark border-2 border-accent-blue flex items-center justify-center">
                                                            <div className="w-1 h-1 rounded-full bg-accent-blue" />
                                                        </div>
                                                        <div className="flex justify-between gap-4">
                                                            <div>
                                                                <div className="text-sm font-bold text-white">
                                                                    {log.status}
                                                                </div>
                                                                <div className="text-xs text-text-dim mt-1 font-medium">
                                                                    {log.note ||
                                                                        "System synchronization successful."}
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
                                                                <div className="text-[10px] text-accent-blue/60 font-black uppercase tracking-tighter">
                                                                    by{" "}
                                                                    {log.actor ===
                                                                    "system"
                                                                        ? "Platform"
                                                                        : "Network Admin"}
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                ),
                                            )}
                                            {(!selectedTx.logs ||
                                                selectedTx.logs.length ===
                                                    0) && (
                                                <p className="text-xs text-text-dim italic">
                                                    No lifecycle logs recorded
                                                    for this instruction.
                                                </p>
                                            )}
                                        </div>
                                    </div>

                                    <div className="pt-6 border-t border-white/5">
                                        <div className="flex items-center gap-4 text-text-dim hover:text-white transition-colors cursor-pointer group">
                                            <ExternalLink
                                                size={16}
                                                className="group-hover:scale-110 transition-transform"
                                            />
                                            <span className="text-xs font-bold uppercase tracking-widest">
                                                Verify on Ledger Explorer
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default History;
