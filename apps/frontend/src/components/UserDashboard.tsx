import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    Activity,
    ArrowDownLeft,
    ArrowUpRight,
    Banknote,
    CheckCircle2,
    Clock,
    History,
    ShieldCheck,
    Wallet,
    XCircle,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import api from "../lib/api";
import { ENABLE_E2EE, decryptData, encryptData } from "../lib/crypto";

type TransactionType = "DEPOSIT" | "WITHDRAW";
type TransactionStatus = "PENDING" | "COMPLETED" | "REJECTED";

interface TransactionLog {
    id: string;
    transactionId: string;
    status: TransactionStatus;
    actor: string;
    note?: string;
    createdAt: string;
}

interface Transaction {
    id: string;
    userId: string;
    type: TransactionType;
    amount: number;
    status: TransactionStatus;
    bankDetails?: string;
    createdAt: string;
    logs?: TransactionLog[];
}

interface BankDetails {
    name: string;
    account: string;
    bank: string;
    ifsc: string;
}

const UserDashboard: React.FC = () => {
    const [balance, setBalance] = useState<number>(0);
    const [transactions, setTransactions] = useState<Transaction[]>([]);
    const [isDepositOpen, setIsDepositOpen] = useState(false);
    const [isWithdrawOpen, setIsWithdrawOpen] = useState(false);
    const [amount, setAmount] = useState("");

    // Withdrawal fields
    const [bankDetails, setBankDetails] = useState<BankDetails>({
        name: "",
        account: "",
        bank: "",
        ifsc: "",
    });

    // Filters
    const [filter, setFilter] = useState({ query: "", type: "", status: "" });
    const [selectedTx, setSelectedTx] = useState<Transaction | null>(null);
    const [alert, setAlert] = useState<{
        title: string;
        message: string;
        type: "success" | "error";
    } | null>(null);
    const [decryptedBankDetails, setDecryptedBankDetails] =
        useState<BankDetails | null>(null);

    const fetchData = async () => {
        try {
            const { data: user } = await api.get("/users/me");
            setBalance(user.balance);

            const params = new URLSearchParams();
            if (filter.status) params.append("status", filter.status);
            if (filter.type) params.append("type", filter.type);

            const { data: txs } = await api.get(
                `/wallet/transactions?${params.toString()}`,
            );

            let filtered = txs;
            if (filter.query) {
                filtered = txs.filter((t: Transaction) =>
                    t.id.toLowerCase().includes(filter.query.toLowerCase()),
                );
            }

            setTransactions(filtered);
        } catch (e) {
            console.error(e);
        }
    };

    const openTxDetail = async (tx: Transaction) => {
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
            // For users, we don't handle RSA decryption in this demo
            // as they don't have the admin's private key.
            // But if E2EE is off, they can see it.
        } catch (err) {
            console.error("Decryption failed", err);
        }
    };

    useEffect(() => {
        fetchData();
    }, [filter.status, filter.type, filter.query]);

    const handleDeposit = async () => {
        try {
            await api.post("/wallet/deposit", { amount: parseFloat(amount) });
            setIsDepositOpen(false);
            setAmount("");
            fetchData();
            setAlert({
                title: "Request Cached",
                message:
                    "Your deposit request has been submitted to the vault. Pending admin verification.",
                type: "success",
            });
        } catch (err) {
            setAlert({
                title: "Submission Failed",
                message:
                    "Could not broadcast deposit request. Check your connection.",
                type: "error",
            });
        }
    };

    const handleWithdraw = async () => {
        try {
            let encrypted;
            if (ENABLE_E2EE) {
                const { data: keyData } = await api.get(
                    "/wallet/admin/public-key",
                );
                encrypted = await encryptData(keyData.publicKey, bankDetails);
            } else {
                encrypted = await encryptData("", bankDetails);
            }

            await api.post("/wallet/withdraw", {
                amount: parseFloat(amount),
                bankDetails: encrypted,
            });
            setIsWithdrawOpen(false);
            setAmount("");
            setBankDetails({ name: "", account: "", bank: "", ifsc: "" });
            fetchData();
            setAlert({
                title: "Funds Locked",
                message:
                    "Withdrawal request received. Your balance is reserved pending blockchain clearance.",
                type: "success",
            });
        } catch (err) {
            setAlert({
                title: "Withdraw Failed",
                message:
                    "Insufficient balance or invalid payment instructions.",
                type: "error",
            });
        }
    };

    return (
        <div className="space-y-8 animate-fade pb-20">
            {/* Balance Card Section */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <motion.div
                    whileHover={{ y: -5 }}
                    className="col-span-1 md:col-span-2 glass p-8 relative overflow-hidden group"
                >
                    <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/4 group-hover:bg-primary/10 transition-colors"></div>

                    <div className="relative z-10 flex flex-col justify-between h-full">
                        <div className="flex justify-between items-start">
                            <div>
                                <p className="text-text-dim mb-2 font-bold tracking-widest uppercase text-xs">
                                    Available Balance
                                </p>
                                <div className="flex items-baseline gap-3">
                                    <h2 className="text-6xl font-bold font-outfit text-white">
                                        {balance.toLocaleString()}
                                    </h2>
                                    <span className="text-primary text-2xl font-bold">
                                        USDT
                                    </span>
                                </div>
                            </div>
                            <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center border border-primary/20 backdrop-blur-md shadow-inner">
                                <Wallet className="text-primary w-8 h-8" />
                            </div>
                        </div>

                        <div className="mt-10 flex gap-4">
                            <button
                                onClick={() => setIsDepositOpen(true)}
                                className="flex-1 btn-primary flex items-center justify-center gap-2 hover:scale-[1.02]"
                            >
                                <ArrowDownLeft size={20} />{" "}
                                <span className="hidden sm:inline">
                                    Add Money
                                </span>
                            </button>
                            <button
                                onClick={() => setIsWithdrawOpen(true)}
                                className="flex-1 bg-white/5 hover:bg-white/10 text-white font-semibold py-3 rounded-xl transition-all flex items-center justify-center gap-2 border border-white/10 hover:scale-[1.02]"
                            >
                                <ArrowUpRight size={20} />{" "}
                                <span className="hidden sm:inline">
                                    Withdraw
                                </span>
                            </button>
                        </div>
                    </div>
                </motion.div>

                <motion.div className="col-span-1 glass p-8 relative overflow-hidden flex flex-col items-center justify-center text-center group">
                    <div className="absolute bottom-0 left-0 w-64 h-64 bg-accent-blue/5 rounded-full blur-3xl translate-y-1/2 -translate-x-1/4 group-hover:bg-accent-blue/10 transition-colors"></div>
                    <div className="relative z-10">
                        <div className="w-16 h-16 bg-accent-blue/10 rounded-full flex items-center justify-center mx-auto mb-4 border border-accent-blue/20">
                            <Banknote className="text-accent-blue w-8 h-8" />
                        </div>
                        <h3 className="text-xl font-outfit font-bold mb-2">
                            Advanced Banking
                        </h3>
                        <p className="text-sm text-text-dim leading-relaxed">
                            Experience seamless transactions with military-grade
                            E2EE security on withdrawals.
                        </p>
                    </div>
                </motion.div>
            </div>

            {/* Transactions Table */}
            <div className="glass overflow-hidden">
                <div className="p-8 border-b border-white/5 bg-white/1 flex flex-col md:flex-row items-center justify-between gap-4">
                    <div>
                        <h3 className="text-2xl font-bold font-outfit flex items-center gap-3">
                            <History size={24} className="text-primary" />{" "}
                            Transaction History
                        </h3>
                    </div>
                    <div className="flex items-center gap-3 w-full md:w-auto">
                        <input
                            type="text"
                            placeholder="Search by ID..."
                            className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-primary text-white w-full md:w-48"
                            value={filter.query}
                            onChange={(e) =>
                                setFilter({ ...filter, query: e.target.value })
                            }
                        />
                        <select
                            className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-sm focus:outline-none focus:border-primary text-white appearance-none"
                            value={filter.type}
                            onChange={(e) =>
                                setFilter({ ...filter, type: e.target.value })
                            }
                        >
                            <option value="" className="bg-bg-dark">
                                All Types
                            </option>
                            <option value="DEPOSIT" className="bg-bg-dark">
                                Deposit
                            </option>
                            <option value="WITHDRAW" className="bg-bg-dark">
                                Withdrawal
                            </option>
                        </select>
                    </div>
                </div>
                <div className="w-full overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                        <thead>
                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-xs font-semibold tracking-widest uppercase">
                                <th className="px-8 py-5">Type / ID</th>
                                <th className="px-8 py-5">Amount</th>
                                <th className="px-8 py-5">Status</th>
                                <th className="px-8 py-5 text-right">Date</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5">
                            <AnimatePresence>
                                {transactions.map((tx: Transaction) => (
                                    <motion.tr
                                        initial={{ opacity: 0 }}
                                        animate={{ opacity: 1 }}
                                        exit={{ opacity: 0 }}
                                        key={tx.id}
                                        className="table-row-hover transition-colors cursor-pointer"
                                        onClick={() => openTxDetail(tx)}
                                    >
                                        <td className="px-8 py-5">
                                            <div className="flex items-center gap-3">
                                                <div
                                                    className={`w-10 h-10 rounded-full flex shrink-0 items-center justify-center ${
                                                        tx.type === "DEPOSIT"
                                                            ? "bg-primary/10"
                                                            : "bg-white/5"
                                                    }`}
                                                >
                                                    {tx.type === "DEPOSIT" ? (
                                                        <ArrowDownLeft className="text-primary w-5 h-5" />
                                                    ) : (
                                                        <ArrowUpRight className="text-white w-5 h-5" />
                                                    )}
                                                </div>
                                                <div>
                                                    <div className="font-semibold text-white capitalize">
                                                        {tx.type.toLowerCase()}
                                                    </div>
                                                    <div className="text-xs text-text-dim mt-1 truncate max-w-[120px]">
                                                        TX-
                                                        {tx.id
                                                            .substring(0, 8)
                                                            .toUpperCase()}
                                                    </div>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-8 py-5">
                                            <div
                                                className={`text-lg font-outfit font-bold ${tx.type === "DEPOSIT" ? "text-primary" : "text-white"}`}
                                            >
                                                {tx.type === "DEPOSIT"
                                                    ? "+"
                                                    : "-"}
                                                {tx.amount.toLocaleString()}{" "}
                                                <span className="text-xs text-text-dim ml-1">
                                                    USDT
                                                </span>
                                            </div>
                                        </td>
                                        <td className="px-8 py-5">
                                            <span
                                                className={`inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-widest py-1.5 px-3 rounded-full border ${
                                                    tx.status === "COMPLETED"
                                                        ? "bg-primary/5 border-primary/20 text-primary"
                                                        : tx.status ===
                                                            "PENDING"
                                                          ? "bg-secondary/5 border-secondary/20 text-secondary"
                                                          : "bg-red-400/5 border-red-400/20 text-red-400"
                                                }`}
                                            >
                                                {tx.status === "PENDING" && (
                                                    <Clock size={12} />
                                                )}
                                                {tx.status === "COMPLETED" && (
                                                    <CheckCircle2 size={12} />
                                                )}
                                                {tx.status === "REJECTED" && (
                                                    <XCircle size={12} />
                                                )}
                                                {tx.status}
                                            </span>
                                        </td>
                                        <td className="px-8 py-5 text-text-dim text-sm font-medium text-right">
                                            {format(
                                                new Date(tx.createdAt),
                                                "MMM dd, HH:mm",
                                            )}
                                        </td>
                                    </motion.tr>
                                ))}
                            </AnimatePresence>
                            {transactions.length === 0 && (
                                <tr>
                                    <td
                                        colSpan={4}
                                        className="px-8 py-20 text-center"
                                    >
                                        <Activity className="w-12 h-12 mx-auto mb-4 text-white/10" />
                                        <p className="text-text-dim font-medium">
                                            No transactions found
                                        </p>
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Transaction Modals */}
            <AnimatePresence>
                {(isDepositOpen || isWithdrawOpen) && (
                    <div className="fixed inset-0 z-100 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ y: 20, opacity: 0 }}
                            animate={{ y: 0, opacity: 1 }}
                            exit={{ y: 20, opacity: 0 }}
                            className="glass p-8 w-full max-w-md shadow-2xl"
                        >
                            <h2 className="text-2xl font-outfit font-bold mb-6 flex items-center gap-3">
                                {isDepositOpen ? (
                                    <ArrowDownLeft className="text-primary" />
                                ) : (
                                    <ArrowUpRight className="text-white" />
                                )}
                                {isDepositOpen
                                    ? "Deposit Funds"
                                    : "Withdraw Funds"}
                            </h2>

                            <div className="space-y-5">
                                <div>
                                    <label className="text-xs text-text-dim block mb-2 uppercase font-bold tracking-wider">
                                        Amount (USDT)
                                    </label>
                                    <input
                                        type="number"
                                        className="input-field text-xl font-bold text-center tracking-wider"
                                        placeholder="0.00"
                                        value={amount}
                                        onChange={(e) =>
                                            setAmount(e.target.value)
                                        }
                                    />
                                </div>

                                {isWithdrawOpen && (
                                    <div className="space-y-4 pt-6 border-t border-white/5 relative">
                                        <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-bg-dark px-4 py-1 border border-white/10 rounded-full flex items-center gap-2 shadow-sm">
                                            <ShieldCheck
                                                size={14}
                                                className="text-primary"
                                            />
                                            <span className="text-[10px] text-primary font-bold uppercase tracking-widest">
                                                E2EE Encrypted Data
                                            </span>
                                        </div>

                                        <div className="pt-2 space-y-4">
                                            <div>
                                                <input
                                                    className="input-field text-sm"
                                                    placeholder="Beneficiary Account Name"
                                                    value={bankDetails.name}
                                                    onChange={(e) =>
                                                        setBankDetails({
                                                            ...bankDetails,
                                                            name: e.target
                                                                .value,
                                                        })
                                                    }
                                                />
                                            </div>
                                            <div>
                                                <input
                                                    className="input-field text-sm"
                                                    placeholder="Account Number"
                                                    value={bankDetails.account}
                                                    onChange={(e) =>
                                                        setBankDetails({
                                                            ...bankDetails,
                                                            account:
                                                                e.target.value,
                                                        })
                                                    }
                                                />
                                            </div>
                                            <div className="grid grid-cols-2 gap-4">
                                                <input
                                                    className="input-field text-sm"
                                                    placeholder="Bank Name"
                                                    value={bankDetails.bank}
                                                    onChange={(e) =>
                                                        setBankDetails({
                                                            ...bankDetails,
                                                            bank: e.target
                                                                .value,
                                                        })
                                                    }
                                                />
                                                <input
                                                    className="input-field text-sm"
                                                    placeholder="IFSC Code"
                                                    value={bankDetails.ifsc}
                                                    onChange={(e) =>
                                                        setBankDetails({
                                                            ...bankDetails,
                                                            ifsc: e.target
                                                                .value,
                                                        })
                                                    }
                                                />
                                            </div>
                                        </div>
                                    </div>
                                )}

                                <div className="flex gap-4 pt-6 mt-4 border-t border-white/5">
                                    <button
                                        onClick={() => {
                                            setIsDepositOpen(false);
                                            setIsWithdrawOpen(false);
                                            setAmount("");
                                        }}
                                        className="flex-1 px-6 py-3 rounded-xl border border-white/10 hover:bg-white/5 transition-colors font-semibold"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        onClick={() =>
                                            isDepositOpen
                                                ? handleDeposit()
                                                : handleWithdraw()
                                        }
                                        className="flex-1 btn-primary"
                                        disabled={!amount}
                                    >
                                        Confirm Request
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
                            initial={{ scale: 0.95, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.95, opacity: 0 }}
                            className="glass-panel p-0 w-full max-w-2xl shadow-2xl shadow-primary/10 overflow-hidden flex flex-col max-h-[90vh]"
                        >
                            <div className="p-8 border-b border-white/5 bg-white/5 flex items-center justify-between">
                                <div className="flex items-center gap-4">
                                    <div
                                        className={`w-12 h-12 rounded-xl flex items-center justify-center ${selectedTx.type === "DEPOSIT" ? "bg-primary/20 text-primary" : "bg-white/10 text-white"}`}
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
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-10">
                                    <div className="bg-white/5 p-6 rounded-2xl border border-white/5">
                                        <span className="text-[10px] font-bold text-text-dim uppercase tracking-widest block mb-1">
                                            Current Status
                                        </span>
                                        <div className="flex items-center gap-2">
                                            <span
                                                className={`text-lg font-bold font-outfit ${selectedTx.status === "COMPLETED" ? "text-primary" : selectedTx.status === "PENDING" ? "text-accent-blue" : "text-red-400"}`}
                                            >
                                                {selectedTx.status}
                                            </span>
                                        </div>
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
                                </div>

                                <div className="mb-6">
                                    <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-2">
                                        <History
                                            size={16}
                                            className="text-primary"
                                        />{" "}
                                        Activity Timeline
                                    </h3>
                                    <div className="space-y-0 pl-3 border-l-2 border-white/5">
                                        {selectedTx.logs?.map(
                                            (log: TransactionLog) => (
                                                <div
                                                    key={log.id}
                                                    className="relative pl-8 pb-8 last:pb-0"
                                                >
                                                    <div className="absolute left-[-11px] top-0 w-5 h-5 rounded-full bg-bg-dark border-2 border-primary shadow-lg flex items-center justify-center">
                                                        <div className="w-1.5 h-1.5 rounded-full bg-primary" />
                                                    </div>
                                                    <div className="flex justify-between items-start">
                                                        <div>
                                                            <div className="text-sm font-bold text-white">
                                                                {log.status}
                                                            </div>
                                                            <div className="text-xs text-text-dim mt-1">
                                                                {log.note ||
                                                                    "Status updated"}
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
                                                            <div className="text-[10px] text-primary/60 font-semibold mt-1">
                                                                by {log.actor}
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            ),
                                        )}
                                    </div>
                                </div>

                                {selectedTx.type === "WITHDRAW" &&
                                    decryptedBankDetails && (
                                        <div className="mb-10">
                                            <h3 className="text-sm font-bold text-white uppercase tracking-widest mb-6 flex items-center gap-2">
                                                <ShieldCheck
                                                    size={16}
                                                    className="text-primary"
                                                />{" "}
                                                Withdrawal Instructions
                                            </h3>
                                            <div className="bg-white/5 p-6 rounded-2xl border border-white/5 grid grid-cols-1 md:grid-cols-2 gap-y-4 gap-x-8">
                                                <div className="flex justify-between items-center border-b border-white/5 pb-3 md:border-b-0 md:pb-0">
                                                    <span className="text-[10px] font-bold text-text-dim text-left">
                                                        BENEFICIARY
                                                    </span>
                                                    <span className="font-bold text-white text-sm text-right">
                                                        {
                                                            decryptedBankDetails.name
                                                        }
                                                    </span>
                                                </div>
                                                <div className="flex justify-between items-center border-b border-white/5 pb-3 md:border-b-0 md:pb-0">
                                                    <span className="text-[10px] font-bold text-text-dim text-left">
                                                        ACCOUNT NO.
                                                    </span>
                                                    <span className="font-bold text-white text-sm text-right">
                                                        {
                                                            decryptedBankDetails.account
                                                        }
                                                    </span>
                                                </div>
                                                <div className="flex justify-between items-center border-b border-white/5 pb-3 md:border-b-0 md:pb-0">
                                                    <span className="text-[10px] font-bold text-text-dim text-left">
                                                        BANK NAME
                                                    </span>
                                                    <span className="font-bold text-white text-sm text-right">
                                                        {
                                                            decryptedBankDetails.bank
                                                        }
                                                    </span>
                                                </div>
                                                <div className="flex justify-between items-center">
                                                    <span className="text-[10px] font-bold text-text-dim text-left">
                                                        ROUTING / IFSC
                                                    </span>
                                                    <span className="font-bold text-accent-blue text-sm text-right">
                                                        {
                                                            decryptedBankDetails.ifsc
                                                        }
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                    )}
                                {(!selectedTx.logs ||
                                    selectedTx.logs.length === 0) && (
                                    <div className="text-sm text-text-dim italic">
                                        No activity logs found for this
                                        transaction.
                                    </div>
                                )}
                            </div>
                            <div className="p-8 border-t border-white/5 bg-white/2">
                                <button
                                    onClick={() => setSelectedTx(null)}
                                    className="w-full btn-primary"
                                >
                                    Close Details
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* Alert Modal */}
            <AnimatePresence>
                {alert && (
                    <div className="fixed inset-0 z-200 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
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
                                            : "bg-red-500/10 text-red-500"
                                    }`}
                                >
                                    {alert.type === "success" ? (
                                        <ShieldCheck size={32} />
                                    ) : (
                                        <XCircle size={32} />
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
                                            : "bg-red-500 text-white"
                                    }`}
                                >
                                    Acknowledge
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default UserDashboard;
