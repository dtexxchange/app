import {
    AlertCircle,
    Clock,
    DollarSign,
    History,
    Save,
    Shield,
    User,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import api from "../../lib/api";

interface FeeHistory {
    id: string;
    fee: number;
    adminEmail: string;
    createdAt: string;
}

const WithdrawalFee: React.FC = () => {
    const [currentFee, setCurrentFee] = useState<number | null>(null);
    const [feeInput, setFeeInput] = useState<string>("");
    const [history, setHistory] = useState<FeeHistory[]>([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState<{
        type: "success" | "error";
        text: string;
    } | null>(null);

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const [feeRes, historyRes] = await Promise.all([
                api.get("/settings/withdrawal-fee"),
                api.get("/settings/withdrawal-fee/history"),
            ]);

            const feeValue = feeRes.data.withdrawalFee;
            setCurrentFee(feeValue);
            setFeeInput(feeValue?.toString() || "0");
            setHistory(historyRes.data);
        } catch (error) {
            console.error("Error fetching fee data:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault();
        const fee = parseFloat(feeInput);
        if (isNaN(fee)) {
            setMessage({
                type: "error",
                text: "Please enter a valid numeric value",
            });
            return;
        }

        setSaving(true);
        setMessage(null);
        try {
            await api.patch("/settings/withdrawal-fee", { fee });
            setMessage({
                type: "success",
                text: "Withdrawal fee updated successfully",
            });
            fetchData();
        } catch (error: any) {
            setMessage({
                type: "error",
                text:
                    error.response?.data?.message ||
                    "Failed to update withdrawal fee",
            });
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-[400px]">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-500"></div>
            </div>
        );
    }

    return (
        <div className="p-8 max-w-6xl mx-auto space-y-8 animate-in fade-in duration-500">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold text-slate-900 tracking-tight">
                        Withdrawal Configuration
                    </h1>
                    <p className="text-slate-500 mt-1">
                        Manage global transaction fees and track historical
                        changes.
                    </p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Left Column: Current Status & Editor */}
                <div className="lg:col-span-1 space-y-6">
                    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                        <div className="p-6 border-b border-slate-100 bg-slate-50/50">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-emerald-100 rounded-lg">
                                    <Shield className="w-5 h-5 text-emerald-600" />
                                </div>
                                <h2 className="font-semibold text-slate-800">
                                    Global Fee Status
                                </h2>
                            </div>
                        </div>
                        <div className="p-8 text-center">
                            <span className="text-slate-400 text-sm font-medium uppercase tracking-wider">
                                Active Fee
                            </span>
                            <div className="mt-2 flex items-center justify-center gap-2">
                                <span className="text-4xl font-black text-slate-900">
                                    {currentFee !== null
                                        ? `${currentFee.toFixed(2)}`
                                        : "N/A"}
                                </span>
                                <span className="text-xl font-bold text-emerald-600">
                                    USDT
                                </span>
                            </div>
                        </div>
                    </div>

                    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6">
                        <h3 className="font-semibold text-slate-800 mb-4 flex items-center gap-2">
                            <DollarSign className="w-4 h-4 text-emerald-500" />
                            Update Fee
                        </h3>
                        <form onSubmit={handleSave} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1.5">
                                    New Withdrawal Fee (USDT)
                                </label>
                                <div className="relative">
                                    <input
                                        type="number"
                                        step="0.01"
                                        value={feeInput}
                                        onChange={(e) =>
                                            setFeeInput(e.target.value)
                                        }
                                        className="w-full pl-4 pr-16 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-all outline-none font-semibold text-slate-900"
                                        placeholder="0.00"
                                    />
                                    <div className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-xs uppercase">
                                        USDT
                                    </div>
                                </div>
                            </div>

                            {message && (
                                <div
                                    className={`p-4 rounded-xl flex items-start gap-3 ${
                                        message.type === "success"
                                            ? "bg-emerald-50 text-emerald-700 border border-emerald-100"
                                            : "bg-rose-50 text-rose-700 border border-rose-100"
                                    }`}
                                >
                                    <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
                                    <p className="text-sm font-medium">
                                        {message.text}
                                    </p>
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={saving}
                                className="w-full flex items-center justify-center gap-2 bg-slate-900 hover:bg-slate-800 text-white py-3.5 rounded-xl font-bold transition-all shadow-lg shadow-slate-200 disabled:opacity-50"
                            >
                                {saving ? (
                                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                ) : (
                                    <>
                                        <Save className="w-5 h-5" />
                                        Apply New Fee
                                    </>
                                )}
                            </button>
                        </form>
                    </div>
                </div>

                {/* Right Column: History Trail */}
                <div className="lg:col-span-2">
                    <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                        <div className="p-6 border-b border-slate-100 flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="p-2 bg-slate-100 rounded-lg">
                                    <History className="w-5 h-5 text-slate-600" />
                                </div>
                                <h2 className="font-semibold text-slate-800">
                                    Audit Trail
                                </h2>
                            </div>
                            <span className="text-xs font-bold text-slate-400 uppercase tracking-widest">
                                {history.length} Updates Recorded
                            </span>
                        </div>

                        <div className="overflow-x-auto">
                            <table className="w-full text-left">
                                <thead>
                                    <tr className="bg-slate-50/50 border-b border-slate-100">
                                        <th className="px-6 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">
                                            Fee Value
                                        </th>
                                        <th className="px-6 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider">
                                            Modified By
                                        </th>
                                        <th className="px-6 py-4 text-xs font-bold text-slate-500 uppercase tracking-wider text-right">
                                            Timestamp
                                        </th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-100">
                                    {history.map((item, idx) => (
                                        <tr
                                            key={item.id}
                                            className="hover:bg-slate-50/50 transition-colors"
                                        >
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-2">
                                                    <span className="font-bold text-slate-900">
                                                        {item.fee.toFixed(2)}
                                                    </span>
                                                    <span className="text-[10px] font-black text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded">
                                                        USDT
                                                    </span>
                                                    {idx === 0 && (
                                                        <span className="text-[10px] font-bold text-white bg-slate-900 px-2 py-0.5 rounded-full ml-2">
                                                            LATEST
                                                        </span>
                                                    )}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="flex items-center gap-2">
                                                    <div className="w-7 h-7 rounded-full bg-slate-100 flex items-center justify-center">
                                                        <User className="w-4 h-4 text-slate-500" />
                                                    </div>
                                                    <span className="text-sm font-medium text-slate-600">
                                                        {item.adminEmail}
                                                    </span>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 text-right">
                                                <div className="flex flex-col items-end">
                                                    <span className="text-sm font-semibold text-slate-800">
                                                        {new Date(
                                                            item.createdAt,
                                                        ).toLocaleDateString(
                                                            undefined,
                                                            {
                                                                month: "short",
                                                                day: "numeric",
                                                                year: "numeric",
                                                            },
                                                        )}
                                                    </span>
                                                    <div className="flex items-center gap-1 text-[10px] font-medium text-slate-400">
                                                        <Clock className="w-3 h-3" />
                                                        {new Date(
                                                            item.createdAt,
                                                        ).toLocaleTimeString(
                                                            undefined,
                                                            {
                                                                hour: "2-digit",
                                                                minute: "2-digit",
                                                            },
                                                        )}
                                                    </div>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                    {history.length === 0 && (
                                        <tr>
                                            <td
                                                colSpan={3}
                                                className="px-6 py-12 text-center text-slate-400 italic"
                                            >
                                                No historical changes recorded
                                                yet.
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default WithdrawalFee;
