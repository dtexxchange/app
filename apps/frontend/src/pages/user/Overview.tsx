import { format } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
    Activity,
    AlertCircle,
    ArrowDownLeft,
    ArrowUpRight,
    CheckCircle2,
    ChevronDown,
    Clock,
    Copy,
    Search,
    ShieldCheck,
    Wallet,
    XCircle,
    ShieldAlert,
} from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import React, { useCallback, useEffect, useState } from "react";
import api from "../../lib/api";
import { ENABLE_E2EE, encryptData } from "../../lib/crypto";
import { useAuth } from "../../context/AuthContext";
import PasscodeVerifyModal from "../../components/PasscodeVerifyModal";
import { formatAmount } from "../../lib/formatters";

interface Transaction {
    id: string;
    type: string;
    amount: number;
    status: string;
    createdAt: string;
}

interface SavedAccount {
    id: string;
    name: string;
    bankName: string;
    accountNo: string;
    ifsc: string;
}

const Overview: React.FC = () => {
    const [balance, setBalance] = useState(0);
    const [transactions, setTransactions] = useState<Transaction[]>([]);
    const [conversionRate, setConversionRate] = useState<number | null>(null);
    const [wallets, setWallets] = useState<
        { id: string; address: string; network: string; expiresAt?: string }[]
    >([]);
    const [timeLeft, setTimeLeft] = useState(1800);
    const [savedAccounts, setSavedAccounts] = useState<SavedAccount[]>([]);

    // UI States
    const [isDepositOpen, setIsDepositOpen] = useState(false);
    const [isExchangeOpen, setIsExchangeOpen] = useState(false);
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);
    const [searchQuery, setSearchQuery] = useState("");
    const [amount, setAmount] = useState("");
    const [inrAmount, setInrAmount] = useState("");
    const [selectedAccountId, setSelectedAccountId] =
        useState<string>("manual");
    const [bankDetails, setBankDetails] = useState({
        name: "",
        account: "",
        bank: "",
        ifsc: "",
    });
    const [saveNewAccount, setSaveNewAccount] = useState(true);
    const [hasPasscode, setHasPasscode] = useState(true);
    const [isVerifyModalOpen, setIsVerifyModalOpen] = useState(false);
    const [alert, setAlert] = useState<{
        title: string;
        message: string;
        type: "success" | "error" | "info";
    } | null>(null);

    const fetchData = useCallback(async () => {
        try {
            const { data: user } = await api.get("/users/me");
            setBalance(user.balance);
            setHasPasscode(user.passcode !== null);

            const { data: settings } = await api.get(
                "/settings/conversion-rate",
            );
            setConversionRate(settings.usdtToInrRate);

            const { data: wIdData } = await api.get("/settings/wallets");
            setWallets(wIdData);
            if (wIdData.length > 0 && wIdData[0].expiresAt) {
                const expiresAt = new Date(wIdData[0].expiresAt);
                const diff = Math.floor(
                    (expiresAt.getTime() - Date.now()) / 1000,
                );
                setTimeLeft(diff > 0 ? diff : 0);
            }

            const { data: txs } = await api.get("/wallet/transactions?limit=5");
            setTransactions(txs);

            const { data: accounts } = await api.get("/bank-accounts");
            setSavedAccounts(accounts);
        } catch (e) {
            console.error(e);
        }
    }, []);

    useEffect(() => {
        fetchData();
    }, [fetchData]);

    useEffect(() => {
        if (!isDepositOpen) return;

        const timer = setInterval(() => {
            setTimeLeft((prev) => {
                if (prev <= 1) {
                    fetchData();
                    return 0;
                }
                return prev - 1;
            });
        }, 1000);

        return () => clearInterval(timer);
    }, [isDepositOpen, fetchData]);

    const formatTime = (seconds: number) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
    };

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === "Escape") {
                setIsDepositOpen(false);
                setIsExchangeOpen(false);
                setAlert(null);
            }
        };
        window.addEventListener("keydown", handleKeyDown);
        return () => window.removeEventListener("keydown", handleKeyDown);
    }, []);

    const handleUsdtChange = (val: string) => {
        setAmount(val);
        if (conversionRate && val && !isNaN(parseFloat(val))) {
            setInrAmount((parseFloat(val) * conversionRate).toFixed(2));
        } else {
            setInrAmount("");
        }
    };

    const handleInrChange = (val: string) => {
        setInrAmount(val);
        if (conversionRate && val && !isNaN(parseFloat(val))) {
            setAmount((parseFloat(val) / conversionRate).toFixed(2));
        } else {
            setAmount("");
        }
    };

    const handleExchange = async () => {
        if (!amount || isNaN(parseFloat(amount))) return;
        if (parseFloat(amount) > balance) {
            setAlert({
                title: "Insufficient Funds",
                message: "You do not have enough USDT.",
                type: "error",
            });
            return;
        }

        let finalDetails = bankDetails;
        if (selectedAccountId !== "manual") {
            const saved = savedAccounts.find((a) => a.id === selectedAccountId);
            if (saved) {
                finalDetails = {
                    name: saved.name,
                    account: saved.accountNo,
                    bank: saved.bankName,
                    ifsc: saved.ifsc,
                };
            }
        }

        if (
            !finalDetails.name ||
            !finalDetails.account ||
            !finalDetails.bank ||
            !finalDetails.ifsc
        ) {
            setAlert({
                title: "Invalid Details",
                message: "Please provide complete bank account information.",
                type: "error",
            });
            return;
        }

        if (selectedAccountId === "manual" && saveNewAccount) {
            try {
                await api.post("/bank-accounts", {
                    name: finalDetails.name,
                    bankName: finalDetails.bank,
                    accountNo: finalDetails.account,
                    ifsc: finalDetails.ifsc,
                });
            } catch (err) {
                console.error("Failed to save new account", err);
            }
        }

        setIsVerifyModalOpen(true);
    };

    const confirmExchange = async (passcode: string) => {
        setIsVerifyModalOpen(false);
        let finalDetails = bankDetails;
        if (selectedAccountId !== "manual") {
            const saved = savedAccounts.find((a) => a.id === selectedAccountId);
            if (saved) {
                finalDetails = {
                    name: saved.name,
                    account: saved.accountNo,
                    bank: saved.bankName,
                    ifsc: saved.ifsc,
                };
            }
        }

        try {
            let encrypted;
            if (ENABLE_E2EE) {
                const { data: keyData } = await api.get(
                    "/wallet/admin/public-key",
                );
                encrypted = await encryptData(keyData.publicKey, finalDetails);
            } else {
                encrypted = await encryptData("", finalDetails);
            }

            await api.post("/wallet/exchange", {
                amount: parseFloat(amount),
                bankDetails: encrypted,
                passcode: passcode,
            });

            setIsExchangeOpen(false);
            setAmount("");
            setInrAmount("");
            setBankDetails({ name: "", account: "", bank: "", ifsc: "" });
            fetchData();
            setAlert({
                title: "Confirmed",
                message: "Exchange request has been queued.",
                type: "success",
            });
        } catch (err: any) {
            setAlert({
                title: "Error",
                message: err.response?.data?.message || "Failed to exchange.",
                type: "error",
            });
        }
    };

    const { user } = useAuth();
    return (
        <div className="space-y-10">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    {user?.firstName
                        ? `Welcome back, ${user.firstName}`
                        : "Welcome back"}
                </h1>
                <p className="text-text-dim font-medium">
                    Monitor your assets and manage your liquidity.
                </p>
            </header>
            {!hasPasscode && (
                <div className="glass p-6 border-red-500/20 bg-red-500/5 flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-xl bg-red-500/10 flex items-center justify-center text-red-500 border border-red-500/20">
                            <ShieldAlert />
                        </div>
                        <div>
                            <h4 className="text-white font-bold text-sm">
                                Passcode Required
                            </h4>
                            <p className="text-text-dim text-xs">
                                Authorize your settlements and secure your
                                assets.
                            </p>
                        </div>
                    </div>
                    <a
                        href="/profile"
                        className="px-6 py-3 rounded-xl bg-primary text-bg-dark font-black text-[10px] uppercase tracking-widest hover:scale-105 transition-all"
                    >
                        Setup Security
                    </a>
                </div>
            )}

            <PasscodeVerifyModal
                isOpen={isVerifyModalOpen}
                onClose={(p) =>
                    p ? confirmExchange(p) : setIsVerifyModalOpen(false)
                }
            />

            {/* Upper Section */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 space-y-8">
                    {/* Hero Card */}
                    <div className="glass p-10 relative overflow-hidden group">
                        <div className="absolute top-0 right-0 w-80 h-80 bg-accent-blue/5 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 group-hover:bg-accent-blue/10 transition-all duration-700" />

                        <div className="relative z-10 space-y-10">
                            <div className="flex justify-between items-start">
                                <div>
                                    <p className="text-text-dim text-[10px] font-black uppercase tracking-[0.3em] mb-4">
                                        Total Liquidity Pool
                                    </p>
                                    <div className="flex items-baseline gap-4">
                                        <h2 className="text-7xl font-outfit font-bold text-white tracking-tighter">
                                            {formatAmount(balance)}
                                        </h2>
                                        <span className="text-accent-blue text-2xl font-black">
                                            USDT
                                        </span>
                                    </div>
                                </div>
                                <div className="w-16 h-16 bg-white/5 rounded-2xl flex items-center justify-center border border-white/10 shadow-inner">
                                    <Wallet
                                        className="text-accent-blue"
                                        size={32}
                                    />
                                </div>
                            </div>

                            <div className="flex flex-wrap gap-4">
                                <button
                                    onClick={() => setIsDepositOpen(true)}
                                    className="px-10 py-5 rounded-2xl bg-white text-bg-dark font-black uppercase text-xs tracking-widest hover:scale-105 active:scale-95 transition-all flex items-center gap-3 shadow-xl"
                                >
                                    <ArrowDownLeft size={20} /> Deposit Funds
                                </button>
                                <button
                                    onClick={() => setIsExchangeOpen(true)}
                                    className="px-10 py-5 rounded-2xl border border-white/10 bg-white/5 text-white font-black uppercase text-xs tracking-widest hover:bg-white/10 active:scale-95 transition-all flex items-center gap-3"
                                >
                                    <ArrowUpRight size={20} /> Exchange USDT
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Stats */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="glass p-8 flex items-center gap-6">
                            <div className="w-14 h-14 bg-primary/10 rounded-2xl flex items-center justify-center border border-primary/20 text-primary">
                                <Activity size={24} />
                            </div>
                            <div>
                                <p className="text-text-dim text-[10px] font-bold uppercase tracking-widest mb-1">
                                    Exchange Status
                                </p>
                                <h4 className="text-white font-bold">
                                    {conversionRate
                                        ? `₹${conversionRate.toFixed(2)} / USDT`
                                        : "Syncing Rate..."}
                                </h4>
                            </div>
                        </div>
                        <div className="glass p-8 flex items-center gap-6">
                            <div className="w-14 h-14 bg-accent-blue/10 rounded-2xl flex items-center justify-center border border-accent-blue/20 text-accent-blue">
                                <CheckCircle2 size={24} />
                            </div>
                            <div>
                                <p className="text-text-dim text-[10px] font-bold uppercase tracking-widest mb-1">
                                    Verified Gateway
                                </p>
                                <h4 className="text-white font-bold">
                                    Standard Node Active
                                </h4>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Sidebar Side info */}
                <div className="space-y-6">
                    <div className="glass p-8 border-primary/10">
                        <h4 className="text-white font-bold mb-4 font-outfit uppercase tracking-widest text-xs flex items-center gap-2">
                            <Clock size={16} className="text-primary" /> Active
                            Deposits
                        </h4>
                        <div className="space-y-4">
                            {transactions
                                .filter((t) => t.status === "PENDING")
                                .slice(0, 3)
                                .map((tx) => (
                                    <div
                                        key={tx.id}
                                        className="flex justify-between items-center py-3 border-b border-white/5 last:border-0"
                                    >
                                        <div className="text-sm font-bold text-white">
                                            {formatAmount(tx.amount)} USDT
                                        </div>
                                        <div className="text-[10px] font-bold text-primary uppercase">
                                            Validating
                                        </div>
                                    </div>
                                ))}
                            {transactions.filter((t) => t.status === "PENDING")
                                .length === 0 && (
                                <p className="text-xs text-text-dim italic">
                                    No pending settlements.
                                </p>
                            )}
                        </div>
                    </div>

                    <div className="glass p-8 space-y-4">
                        <AlertCircle size={24} className="text-accent-blue" />
                        <h4 className="text-white font-bold text-sm">
                            Security Policy
                        </h4>
                        <p className="text-[10px] text-text-dim leading-relaxed uppercase tracking-tighter">
                            Identity-based E2EE active for all bank
                            instructions. Settlements are irreversible once
                            processed on the ledger.
                        </p>
                    </div>
                </div>
            </div>

            {/* Recent Activity */}
            <div className="glass overflow-hidden">
                <div className="p-8 border-b border-white/5 flex items-center justify-between bg-white/1">
                    <h3 className="text-xl font-outfit font-bold flex items-center gap-3">
                        <Activity className="text-accent-blue" /> Recent
                        Activity
                    </h3>
                    <a
                        href="/history"
                        className="text-xs font-bold text-accent-blue hover:underline"
                    >
                        View Full Ledger
                    </a>
                </div>
                <div className="w-full overflow-x-auto">
                    <table className="w-full text-left">
                        <thead>
                            <tr className="bg-white/2 border-b border-white/5 text-text-dim text-[10px] font-black tracking-[0.2em] uppercase">
                                <th className="px-10 py-5">Record</th>
                                <th className="px-10 py-5">Amount</th>
                                <th className="px-10 py-5">State</th>
                                <th className="px-10 py-5 text-right">
                                    Synchronization
                                </th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-white/5 text-sm">
                            {transactions.map((tx) => (
                                <tr
                                    key={tx.id}
                                    className="hover:bg-white/2 transition-colors group"
                                >
                                    <td className="px-10 py-5">
                                        <div className="flex items-center gap-4">
                                            <div
                                                className={`p-2 rounded-lg ${tx.type === "DEPOSIT" || tx.type === "REFERRAL_COMMISSION" ? "text-primary bg-primary/5" : "text-white bg-white/5"}`}
                                            >
                                                {tx.type === "DEPOSIT" ||
                                                tx.type ===
                                                    "REFERRAL_COMMISSION" ? (
                                                    <ArrowDownLeft size={16} />
                                                ) : (
                                                    <ArrowUpRight size={16} />
                                                )}
                                            </div>
                                            <span className="font-bold text-white group-hover:text-accent-blue transition-colors">
                                                TX-{tx.id.substring(0, 6)}
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-10 py-5 font-bold text-white">
                                        {formatAmount(tx.amount)} USDT
                                    </td>
                                    <td className="px-10 py-5">
                                        <span
                                            className={`text-[10px] font-black uppercase tracking-widest ${tx.status === "COMPLETED" ? "text-primary" : tx.status === "PENDING" ? "text-accent-blue" : "text-red-400"}`}
                                        >
                                            {tx.status}
                                        </span>
                                    </td>
                                    <td className="px-10 py-5 text-right text-text-dim text-xs font-medium">
                                        {format(
                                            new Date(tx.createdAt),
                                            "MMM dd, HH:mm",
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>

            {/* Modals */}
            <AnimatePresence>
                {isDepositOpen && (
                    <div
                        className="fixed inset-0 z-200 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl"
                        onClick={() => setIsDepositOpen(false)}
                    >
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            className="glass-panel p-10 w-full max-w-md shadow-2xl"
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div className="flex justify-between items-center mb-10">
                                <h2 className="text-3xl font-outfit font-bold flex items-center gap-4">
                                    <div className="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center border border-primary/20">
                                        <ArrowDownLeft className="text-primary" />
                                    </div>
                                    Deposit
                                </h2>
                                <button
                                    onClick={() => setIsDepositOpen(false)}
                                    className="text-text-dim hover:text-white"
                                >
                                    <XCircle size={24} />
                                </button>
                            </div>

                            <div className="space-y-6 max-h-[60vh] overflow-y-auto custom-scrollbar pr-2">
                                {wallets.map((wallet) => (
                                    <div
                                        key={wallet.id}
                                        className="bg-bg-dark border border-white/5 p-6 rounded-3xl flex flex-col items-center"
                                    >
                                        <div className="bg-white p-3 rounded-2xl mb-4 shadow-2xl shadow-white/10">
                                            <QRCodeSVG
                                                value={wallet.address}
                                                size={140}
                                            />
                                        </div>
                                        <p className="text-[10px] font-black text-text-dim uppercase tracking-widest mb-2">
                                            {wallet.network} Gateway
                                        </p>
                                        <div className="bg-white/5 p-3 rounded-xl w-full flex items-center gap-3 border border-white/5 group">
                                            <code className="text-xs text-primary truncate flex-1 font-mono text-center">
                                                {wallet.address}
                                            </code>
                                            <button
                                                onClick={() => {
                                                    navigator.clipboard.writeText(
                                                        wallet.address,
                                                    );
                                                    setAlert({
                                                        title: "Success",
                                                        message:
                                                            "Address copied.",
                                                        type: "info",
                                                    });
                                                }}
                                                className="p-2 bg-white/5 rounded-lg text-text-dim hover:text-white transition-colors"
                                            >
                                                <Copy size={16} />
                                            </button>
                                        </div>
                                        <div className="mt-6 flex flex-col items-center gap-2">
                                            <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-primary/5 border border-primary/10">
                                                <Clock
                                                    size={14}
                                                    className="text-primary"
                                                />
                                                <span className="text-[10px] font-black text-primary uppercase tracking-widest">
                                                    Refreshing in:{" "}
                                                    {formatTime(timeLeft)}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                                {wallets.length === 0 && (
                                    <div className="text-center text-text-dim p-4">
                                        No deposit gateways available.
                                    </div>
                                )}
                            </div>
                        </motion.div>
                    </div>
                )}

                {isExchangeOpen && (
                    <div
                        className="fixed inset-0 z-200 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl"
                        onClick={() => setIsExchangeOpen(false)}
                    >
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            className="glass-panel p-10 w-full max-w-xl shadow-2xl"
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div className="flex justify-between items-center mb-8">
                                <h2 className="text-3xl font-outfit font-bold flex items-center gap-4">
                                    <div className="w-12 h-12 bg-white/5 rounded-2xl flex items-center justify-center border border-white/10">
                                        <ArrowUpRight className="text-white" />
                                    </div>
                                    Exchange
                                </h2>
                                <button
                                    onClick={() => setIsExchangeOpen(false)}
                                    className="text-text-dim hover:text-white"
                                >
                                    <XCircle size={24} />
                                </button>
                            </div>

                            <div className="bg-bg-dark border border-white/5 rounded-2xl p-6 mb-8 flex items-center justify-between shadow-inner">
                                <div>
                                    <p className="text-[10px] text-text-dim font-black uppercase tracking-widest mb-1">
                                        Available Balance
                                    </p>
                                    <div className="flex items-baseline gap-2">
                                        <span className="text-3xl font-outfit font-bold text-white">
                                            {formatAmount(balance)}
                                        </span>
                                        <span className="text-sm font-bold text-primary">
                                            USDT
                                        </span>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <p className="text-[10px] text-text-dim font-black uppercase tracking-widest mb-1">
                                        Exchange Value (₹
                                        {conversionRate?.toFixed(2) || "0.00"})
                                    </p>
                                    <div className="flex items-baseline gap-2 justify-end">
                                        <span className="text-xl font-outfit font-bold text-white">
                                            ₹
                                            {conversionRate
                                                ? formatAmount(
                                                      balance * conversionRate,
                                                  )
                                                : "0.00"}
                                        </span>
                                        <span className="text-xs font-bold text-white/40">
                                            INR
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div className="space-y-8 max-h-[55vh] overflow-y-auto custom-scrollbar pr-2">
                                <div className="grid grid-cols-2 gap-6">
                                    <div className="relative">
                                        <label className="text-[10px] font-black text-text-dim uppercase tracking-widest mb-3 block">
                                            USDT to Deduct
                                        </label>
                                        <input
                                            type="number"
                                            className="w-full bg-white/5 border border-white/10 rounded-xl p-4 text-xl font-bold text-white pr-14"
                                            value={amount}
                                            onChange={(e) =>
                                                handleUsdtChange(e.target.value)
                                            }
                                        />
                                        <span className="absolute right-4 top-11 text-[10px] font-bold text-primary">
                                            USDT
                                        </span>
                                    </div>
                                    <div className="relative">
                                        <label className="text-[10px] font-black text-text-dim uppercase tracking-widest mb-3 block">
                                            INR to Receive
                                        </label>
                                        <input
                                            type="number"
                                            className="w-full bg-white/5 border border-white/10 rounded-xl p-4 text-xl font-bold text-white pr-14"
                                            value={inrAmount}
                                            onChange={(e) =>
                                                handleInrChange(e.target.value)
                                            }
                                        />
                                        <span className="absolute right-4 top-11 text-[10px] font-bold text-white/40">
                                            INR
                                        </span>
                                    </div>
                                </div>

                                <div className="space-y-4">
                                    <label className="text-[10px] font-black text-text-dim uppercase tracking-widest flex justify-between">
                                        Settlement Destination
                                        <a
                                            href="/bank-accounts"
                                            className="text-accent-blue hover:underline"
                                        >
                                            Manage Accounts
                                        </a>
                                    </label>

                                    {savedAccounts.length === 0 ? (
                                        <div className="bg-accent-blue/10 border border-accent-blue/20 p-4 rounded-xl flex items-center justify-between text-sm mb-2">
                                            <div className="flex items-center gap-3">
                                                <AlertCircle
                                                    size={18}
                                                    className="text-accent-blue shrink-0"
                                                />
                                                <span className="text-white font-medium text-xs leading-relaxed">
                                                    No saved accounts found.
                                                    Please enter destination
                                                    details below.
                                                </span>
                                            </div>
                                        </div>
                                    ) : (
                                        <div className="relative z-50">
                                            <button
                                                onClick={() =>
                                                    setIsDropdownOpen(
                                                        !isDropdownOpen,
                                                    )
                                                }
                                                className="w-full bg-white/5 border border-white/10 rounded-xl p-4 text-sm font-bold text-white flex justify-between items-center hover:bg-white/10 transition-colors"
                                            >
                                                <span>
                                                    {selectedAccountId ===
                                                    "manual"
                                                        ? "+ Enter Account Manually"
                                                        : (() => {
                                                              const acc =
                                                                  savedAccounts.find(
                                                                      (a) =>
                                                                          a.id ===
                                                                          selectedAccountId,
                                                                  );
                                                              return acc
                                                                  ? `${acc.name} - ${acc.accountNo}`
                                                                  : "+ Enter Account Manually";
                                                          })()}
                                                </span>
                                                <ChevronDown
                                                    size={18}
                                                    className={`text-text-dim transition-transform ${isDropdownOpen ? "rotate-180" : ""}`}
                                                />
                                            </button>

                                            <AnimatePresence>
                                                {isDropdownOpen && (
                                                    <motion.div
                                                        initial={{
                                                            opacity: 0,
                                                            y: -10,
                                                        }}
                                                        animate={{
                                                            opacity: 1,
                                                            y: 0,
                                                        }}
                                                        exit={{
                                                            opacity: 0,
                                                            y: -10,
                                                        }}
                                                        className="absolute top-full left-0 right-0 mt-2 bg-bg-card border border-white/10 rounded-xl shadow-2xl overflow-hidden"
                                                    >
                                                        <div className="p-3 border-b border-white/5 bg-white/5 flex items-center gap-2">
                                                            <Search
                                                                size={16}
                                                                className="text-text-dim shrink-0"
                                                            />
                                                            <input
                                                                type="text"
                                                                placeholder="Search accounts..."
                                                                className="bg-transparent border-none outline-none text-sm text-white w-full placeholder:text-text-dim/50"
                                                                value={
                                                                    searchQuery
                                                                }
                                                                onChange={(e) =>
                                                                    setSearchQuery(
                                                                        e.target
                                                                            .value,
                                                                    )
                                                                }
                                                                onClick={(e) =>
                                                                    e.stopPropagation()
                                                                }
                                                            />
                                                        </div>
                                                        <div className="max-h-48 overflow-y-auto custom-scrollbar">
                                                            {savedAccounts
                                                                .filter(
                                                                    (acc) =>
                                                                        acc.bankName
                                                                            .toLowerCase()
                                                                            .includes(
                                                                                searchQuery.toLowerCase(),
                                                                            ) ||
                                                                        acc.accountNo.includes(
                                                                            searchQuery,
                                                                        ),
                                                                )
                                                                .map((acc) => (
                                                                    <button
                                                                        key={
                                                                            acc.id
                                                                        }
                                                                        className="w-full text-left px-4 py-3 hover:bg-white/5 text-sm transition-colors border-b border-white/5 last:border-0 flex justify-between items-center"
                                                                        onClick={() => {
                                                                            setSelectedAccountId(
                                                                                acc.id,
                                                                            );
                                                                            setIsDropdownOpen(
                                                                                false,
                                                                            );
                                                                            setSearchQuery(
                                                                                "",
                                                                            );
                                                                        }}
                                                                    >
                                                                        <span className="font-bold text-white truncate max-w-[50%] pr-2">
                                                                            {
                                                                                acc.name
                                                                            }
                                                                        </span>
                                                                        <span className="text-text-dim shrink-0 text-xs">
                                                                            {
                                                                                acc.accountNo
                                                                            }{" "}
                                                                            -{" "}
                                                                            {
                                                                                acc.bankName
                                                                            }
                                                                        </span>
                                                                    </button>
                                                                ))}

                                                            <button
                                                                className="w-full text-left px-4 py-4 hover:bg-white/5 text-sm transition-colors flex items-center justify-center gap-2 text-primary font-bold tracking-widest uppercase text-[10px]"
                                                                onClick={() => {
                                                                    setSelectedAccountId(
                                                                        "manual",
                                                                    );
                                                                    setIsDropdownOpen(
                                                                        false,
                                                                    );
                                                                    setSearchQuery(
                                                                        "",
                                                                    );
                                                                }}
                                                            >
                                                                + Add New
                                                                Destination
                                                                Manually
                                                            </button>
                                                        </div>
                                                    </motion.div>
                                                )}
                                            </AnimatePresence>
                                        </div>
                                    )}

                                    {(selectedAccountId === "manual" ||
                                        savedAccounts.length === 0) && (
                                        <motion.div
                                            initial={{ height: 0, opacity: 0 }}
                                            animate={{
                                                height: "auto",
                                                opacity: 1,
                                            }}
                                            className="grid grid-cols-2 gap-4 pt-2"
                                        >
                                            <input
                                                required
                                                className="col-span-2 input-field text-xs py-3"
                                                placeholder="Beneficiary Name"
                                                value={bankDetails.name}
                                                onChange={(e) =>
                                                    setBankDetails({
                                                        ...bankDetails,
                                                        name: e.target.value,
                                                    })
                                                }
                                            />
                                            <input
                                                required
                                                className="input-field text-xs py-3"
                                                placeholder="Bank Name"
                                                value={bankDetails.bank}
                                                onChange={(e) =>
                                                    setBankDetails({
                                                        ...bankDetails,
                                                        bank: e.target.value,
                                                    })
                                                }
                                            />
                                            <input
                                                required
                                                className="input-field text-xs py-3"
                                                placeholder="IFSC Code"
                                                value={bankDetails.ifsc}
                                                onChange={(e) =>
                                                    setBankDetails({
                                                        ...bankDetails,
                                                        ifsc: e.target.value,
                                                    })
                                                }
                                            />
                                            <input
                                                required
                                                className="col-span-2 input-field text-xs py-3"
                                                placeholder="Account Number"
                                                value={bankDetails.account}
                                                onChange={(e) =>
                                                    setBankDetails({
                                                        ...bankDetails,
                                                        account: e.target.value,
                                                    })
                                                }
                                            />
                                            <div className="col-span-2 pt-2 flex items-center gap-3">
                                                <input
                                                    type="checkbox"
                                                    id="saveNewAccount"
                                                    checked={saveNewAccount}
                                                    onChange={(e) =>
                                                        setSaveNewAccount(
                                                            e.target.checked,
                                                        )
                                                    }
                                                    className="w-4 h-4 rounded border-white/20 bg-bg-dark text-primary focus:ring-primary focus:ring-offset-bg-dark cursor-pointer accent-primary"
                                                />
                                                <label
                                                    htmlFor="saveNewAccount"
                                                    className="text-xs font-bold text-white/70 tracking-wide cursor-pointer"
                                                >
                                                    Save this account for future
                                                    exchanges
                                                </label>
                                            </div>
                                        </motion.div>
                                    )}

                                    {selectedAccountId !== "manual" &&
                                        savedAccounts.length > 0 && (
                                            <motion.div
                                                initial={{
                                                    height: 0,
                                                    opacity: 0,
                                                }}
                                                animate={{
                                                    height: "auto",
                                                    opacity: 1,
                                                }}
                                                className="grid grid-cols-2 gap-4 pt-2"
                                            >
                                                {(() => {
                                                    const acc =
                                                        savedAccounts.find(
                                                            (a) =>
                                                                a.id ===
                                                                selectedAccountId,
                                                        );
                                                    if (!acc) return null;
                                                    return (
                                                        <>
                                                            <div className="col-span-2 bg-white/5 p-3 rounded-xl border border-white/5">
                                                                <p className="text-[10px] text-text-dim font-black uppercase tracking-widest mb-1">
                                                                    Beneficiary
                                                                    Name
                                                                </p>
                                                                <p className="text-xs font-bold text-white">
                                                                    {acc.name}
                                                                </p>
                                                            </div>
                                                            <div className="bg-white/5 p-3 rounded-xl border border-white/5">
                                                                <p className="text-[10px] text-text-dim font-black uppercase tracking-widest mb-1">
                                                                    Bank Name
                                                                </p>
                                                                <p className="text-xs font-bold text-white">
                                                                    {
                                                                        acc.bankName
                                                                    }
                                                                </p>
                                                            </div>
                                                            <div className="bg-white/5 p-3 rounded-xl border border-white/5">
                                                                <p className="text-[10px] text-text-dim font-black uppercase tracking-widest mb-1">
                                                                    IFSC Code
                                                                </p>
                                                                <p className="text-xs font-bold text-accent-blue font-mono">
                                                                    {acc.ifsc}
                                                                </p>
                                                            </div>
                                                            <div className="col-span-2 bg-white/5 p-3 rounded-xl border border-white/5">
                                                                <p className="text-[10px] text-text-dim font-black uppercase tracking-widest mb-1">
                                                                    Account
                                                                    Number
                                                                </p>
                                                                <p className="text-xs font-bold text-white">
                                                                    {
                                                                        acc.accountNo
                                                                    }
                                                                </p>
                                                            </div>
                                                        </>
                                                    );
                                                })()}
                                            </motion.div>
                                        )}
                                </div>

                                <div className="bg-primary/5 p-5 rounded-2xl flex items-start gap-4 border border-primary/10">
                                    <ShieldCheck
                                        className="text-primary shrink-0"
                                        size={18}
                                    />
                                    <p className="text-[10px] text-primary font-bold uppercase leading-relaxed">
                                        Identity Check: All bank instructions
                                        are cryptographically signed before
                                        transmission to the settlement node.
                                    </p>
                                </div>

                                <button
                                    onClick={handleExchange}
                                    className="w-full py-6 rounded-2xl bg-white text-bg-dark font-black uppercase text-xs tracking-widest shadow-2xl shadow-white/10 active:scale-95 transition-all"
                                >
                                    Execute Settlement
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>

            {/* Notification */}
            <AnimatePresence>
                {alert && (
                    <div
                        className="fixed inset-0 z-210 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl"
                        onClick={() => setAlert(null)}
                    >
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            className="glass-panel p-10 w-full max-w-sm shadow-2xl border-white/10 text-center"
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div
                                className={`mx-auto w-16 h-16 rounded-full flex items-center justify-center mb-6 ${alert.type === "success" ? "bg-primary/10 text-primary" : alert.type === "info" ? "bg-accent-blue/10 text-accent-blue" : "bg-red-400/10 text-red-400"}`}
                            >
                                {alert.type === "success" ? (
                                    <CheckCircle2 size={32} />
                                ) : alert.type === "info" ? (
                                    <Copy size={32} />
                                ) : (
                                    <XCircle size={32} />
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
                                className={`w-full py-4 rounded-xl font-black uppercase text-xs tracking-widest transition-all ${alert.type === "success" ? "bg-primary text-bg-dark" : "border border-white/10 text-white"}`}
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

export default Overview;
