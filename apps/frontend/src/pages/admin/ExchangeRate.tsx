import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    AlertCircle,
    ArrowRightLeft,
    History,
    RefreshCw,
    ShieldCheck,
    TrendingDown,
    TrendingUp,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import api from "../../lib/api";
import { formatAmount } from "../../lib/formatters";

const ExchangeRate: React.FC = () => {
    const [rate, setRate] = useState<string>("");
    const [rateHistory, setRateHistory] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [alert, setAlert] = useState<{
        title: string;
        message: string;
        type: "success" | "error";
    } | null>(null);

    const fetchData = async () => {
        setIsLoading(true);
        try {
            const { data: current } = await api.get(
                "/settings/conversion-rate",
            );
            setRate(current.usdtToInrRate?.toString() || "");

            const { data: history } = await api.get(
                "/settings/conversion-rate/history",
            );
            setRateHistory(history);
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const handleSaveRate = async () => {
        if (!rate || isNaN(parseFloat(rate))) {
            setAlert({
                title: "Invalid Value",
                message: "Please specify a proper numeric exchange rate.",
                type: "error",
            });
            return;
        }
        setIsLoading(true);
        try {
            await api.patch("/settings/conversion-rate", {
                rate: parseFloat(rate),
            });
            await fetchData();
            setAlert({
                title: "Rate Synchronized",
                message: "Exchange rate successfully updated across all nodes.",
                type: "success",
            });
        } catch (err: any) {
            setAlert({
                title: "Update Failed",
                message:
                    err.response?.data?.message ||
                    "Failed to sync exchange rate with the database.",
                type: "error",
            });
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="space-y-10 max-w-4xl">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    Exchange Rate Control
                </h1>
                <p className="text-text-dim max-w-2xl font-medium">
                    Configure the global USDT to INR conversion rate. This value
                    directly impacts all automated exchange calculations and
                    settlements.
                </p>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Control Card */}
                <div className="glass p-10 space-y-8 border-primary/10">
                    <div className="flex items-center gap-5">
                        <div className="w-14 h-14 bg-primary/10 rounded-2xl flex items-center justify-center border-2 border-primary/20 shadow-2xl shadow-primary/10">
                            <ArrowRightLeft
                                className="text-primary"
                                size={28}
                            />
                        </div>
                        <div>
                            <h3 className="text-xl font-outfit font-bold text-white">
                                Live Rate Config
                            </h3>
                            <p className="text-[10px] font-bold text-primary uppercase tracking-[0.2em] mt-1">
                                Network-Wide Settlement
                            </p>
                        </div>
                    </div>

                    <div className="space-y-6">
                        <div>
                            <label className="text-[10px] font-black text-white/40 uppercase tracking-[0.3em] mb-4 block">
                                Current Conversion Standard
                            </label>
                            <div className="relative group">
                                <span className="absolute left-6 top-1/2 -translate-y-1/2 text-2xl font-bold text-primary/40 group-focus-within:text-primary transition-colors">
                                    ₹
                                </span>
                                <input
                                    type="number"
                                    step="0.01"
                                    placeholder="00.00"
                                    className="w-full bg-white/5 border border-white/10 rounded-2xl py-6 pl-14 pr-6 text-3xl font-outfit font-bold text-white focus:outline-none focus:border-primary focus:ring-4 focus:ring-primary/10 transition-all placeholder:text-white/5"
                                    value={rate}
                                    onChange={(e) => setRate(e.target.value)}
                                />
                            </div>
                        </div>

                        <button
                            onClick={handleSaveRate}
                            disabled={isLoading}
                            className="w-full btn-primary py-6 font-black uppercase tracking-[0.3em] text-xs shadow-2xl shadow-primary/20 active:scale-95 transition-all flex items-center justify-center gap-3 disabled:opacity-50"
                        >
                            {isLoading ? (
                                <RefreshCw className="animate-spin" size={20} />
                            ) : (
                                <ShieldCheck size={20} />
                            )}
                            Synchronize Rate
                        </button>
                    </div>

                    <div className="bg-primary/5 border border-primary/10 rounded-2xl p-6 flex items-start gap-4">
                        <AlertCircle
                            className="text-primary shrink-0"
                            size={20}
                        />
                        <p className="text-xs text-primary/80 font-medium leading-relaxed">
                            Adjusting this rate will immediately update the INR
                            equivalent for all pending and future exchange
                            requests on the network.
                        </p>
                    </div>
                </div>

                {/* Audit Trail Card */}
                <div className="glass flex flex-col pt-10">
                    <div className="px-10 mb-8 border-b border-white/5 pb-8 flex items-center justify-between">
                        <h3 className="text-xl font-outfit font-bold text-white flex items-center gap-3 uppercase tracking-tight">
                            <History className="text-text-dim" size={20} />{" "}
                            Audit Trail
                        </h3>
                        <span className="text-[10px] font-bold text-text-dim uppercase tracking-widest bg-white/5 px-3 py-1 rounded-full">
                            Historical Log
                        </span>
                    </div>

                    <div className="flex-1 overflow-y-auto px-6 space-y-4 pb-10 custom-scrollbar">
                        {rateHistory.map((h, i) => {
                            const prevRate = rateHistory[i + 1]?.rate;
                            const isUp = prevRate ? h.rate > prevRate : true;

                            return (
                                <motion.div
                                    initial={{ opacity: 0, x: 20 }}
                                    animate={{ opacity: 1, x: 0 }}
                                    key={h.id}
                                    className="p-5 rounded-2xl border border-white/5 bg-white/1 flex items-center justify-between group hover:bg-white/2 transition-colors"
                                >
                                    <div className="flex items-center gap-4">
                                        <div
                                            className={`p-2 rounded-lg ${isUp ? "text-primary" : "text-red-400"}`}
                                        >
                                            {isUp ? (
                                                <TrendingUp size={16} />
                                            ) : (
                                                <TrendingDown size={16} />
                                            )}
                                        </div>
                                        <div>
                                            <div className="text-xl font-outfit font-bold text-white">
                                                ₹{formatAmount(h.rate)}
                                            </div>
                                            <div className="text-[10px] text-text-dim mt-1 font-bold uppercase tracking-tighter">
                                                by {h.adminEmail}
                                            </div>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <div className="text-[10px] font-bold text-white/30 uppercase tracking-widest">
                                            {format(
                                                new Date(h.createdAt),
                                                "MMM dd",
                                            )}
                                        </div>
                                        <div className="text-xs font-medium text-text-dim mt-1">
                                            {format(
                                                new Date(h.createdAt),
                                                "HH:mm",
                                            )}
                                        </div>
                                    </div>
                                </motion.div>
                            );
                        })}
                        {rateHistory.length === 0 && (
                            <div className="py-20 text-center space-y-4">
                                <History
                                    className="mx-auto text-white/5"
                                    size={48}
                                />
                                <p className="text-text-dim text-sm italic font-medium">
                                    No conversion events logged yet.
                                </p>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Notification Modal */}
            <AnimatePresence>
                {alert && (
                    <div className="fixed inset-0 z-100 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
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
                                    <ShieldCheck size={32} />
                                ) : (
                                    <AlertCircle size={32} />
                                )}
                            </div>
                            <h2 className="text-2xl font-outfit font-bold mb-2 uppercase tracking-tight">
                                {alert.title}
                            </h2>
                            <p className="text-text-dim text-sm mb-10 font-medium leading-relaxed">
                                {alert.message}
                            </p>
                            <button
                                onClick={() => setAlert(null)}
                                className={`w-full py-4 rounded-xl font-black uppercase text-xs tracking-widest transition-all ${
                                    alert.type === "success"
                                        ? "bg-primary text-bg-dark shadow-xl shadow-primary/10"
                                        : "border border-red-500/20 text-red-500"
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

export default ExchangeRate;
