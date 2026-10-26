import React, { useState, useRef, useEffect } from "react";
import { Link } from "react-router-dom";
import { toPng, toJpeg, toBlob } from "html-to-image";
import {
    Download,
    Copy,
    Check,
    RotateCw,
    Clock,
    Sparkles,
    Printer,
    FileText,
    ArrowLeft,
    Share2,
    ShieldCheck,
    Sliders,
    Eye,
    Plus,
} from "lucide-react";

const padZero = (n: number) => n.toString().padStart(2, "0");

const getFormattedNow = () => {
    const d = new Date();
    const yyyy = d.getFullYear();
    const mm = padZero(d.getMonth() + 1);
    const dd = padZero(d.getDate());
    const hh = padZero(d.getHours());
    const min = padZero(d.getMinutes());
    const ss = padZero(d.getSeconds());
    return `${yyyy}/${mm}/${dd} ${hh}:${min}:${ss}`;
};

const generateRandomDigits = (length: number): string => {
    let digits = "";
    for (let i = 0; i < length; i++) {
        digits += Math.floor(Math.random() * 10).toString();
    }
    return digits;
};

const generateRandomTRN = (): string => {
    // 'BOT' prefix + exactly 13 digits
    return `BOT${generateRandomDigits(13)}`;
};

const generateRandomUTR = (): string => {
    // Exactly 12 digits
    return generateRandomDigits(12);
};

const incrementValue = (val: string, fallbackPrefix = "", fixedDigits = 0): string => {
    if (!val) {
        return fallbackPrefix ? `${fallbackPrefix}${generateRandomDigits(fixedDigits || 13)}` : generateRandomDigits(fixedDigits || 12);
    }
    const match = val.match(/^(.*?)(\d+)$/);
    if (match) {
        const prefix = match[1] || fallbackPrefix;
        const numStr = match[2];
        try {
            const incremented = (BigInt(numStr) + 1n).toString();
            const minLength = fixedDigits > 0 ? fixedDigits : numStr.length;
            const padded =
                incremented.length < minLength
                    ? incremented.padStart(minLength, "0")
                    : incremented;
            return `${prefix}${padded}`;
        } catch {
            return val;
        }
    }
    return `${val}1`;
};

export const STATUS_OPTIONS = [
    { label: "SUCCESS", color: "text-emerald-400 border-emerald-500/40 bg-emerald-500/10" },
    { label: "PENDING", color: "text-amber-400 border-amber-500/40 bg-amber-500/10" },
    { label: "FAILED", color: "text-rose-400 border-rose-500/40 bg-rose-500/10" },
    { label: "PROCESSING", color: "text-blue-400 border-blue-500/40 bg-blue-500/10" },
    { label: "REVERSED", color: "text-purple-400 border-purple-500/40 bg-purple-500/10" },
];

export const TRANSACTION_TYPES = [
    "BANK_CARD",
    "IMPS",
    "NEFT",
    "RTGS",
    "UPI",
];

const ReceiptGenerator: React.FC = () => {
    // State matching all fields in the reference image
    const [title, setTitle] = useState("Transfer Funds Transaction Details");
    const [trn, setTrn] = useState<string>(() => generateRandomTRN());
    const [utr, setUtr] = useState<string>(() => generateRandomUTR());
    const [transactionType, setTransactionType] = useState("BANK_CARD");
    const [destinationAccount, setDestinationAccount] = useState("");
    const [bankIfsc, setBankIfsc] = useState("");
    const [payeeUpi, setPayeeUpi] = useState("None");
    const [upiId, setUpiId] = useState("");
    const [transactionDate, setTransactionDate] = useState(getFormattedNow());
    const [amount, setAmount] = useState("");
    const [currencySymbol, setCurrencySymbol] = useState("₹");
    const [status, setStatus] = useState("SUCCESS");

    // Display & export options
    const [fontFamily, setFontFamily] = useState<"Arial" | "Inter" | "Segoe UI" | "Courier">("Arial");
    const [cardWidth, setCardWidth] = useState<number>(500);
    const [labelWidth, setLabelWidth] = useState<number>(180);
    const [valueWeight, setValueWeight] = useState<"bold" | "normal" | "600">("bold");
    const [isDownloading, setIsDownloading] = useState(false);
    const [copiedLink, setCopiedLink] = useState(false);
    const [copiedImage, setCopiedImage] = useState(false);
    const [showOptions, setShowOptions] = useState(false);
    const [previewBg, setPreviewBg] = useState<"dark" | "grid" | "light">("dark");
    const [previewScale, setPreviewScale] = useState(1);
    const [autoFitMobile, setAutoFitMobile] = useState(true);
    const [cardHeight, setCardHeight] = useState<number>(340);

    const receiptRef = useRef<HTMLDivElement>(null);
    const previewStageRef = useRef<HTMLDivElement>(null);

    // Track receipt card height dynamically for wrapper sizing when scaled
    useEffect(() => {
        if (!receiptRef.current) return;
        const observer = new ResizeObserver((entries) => {
            for (let entry of entries) {
                if (entry.contentRect.height > 0) {
                    setCardHeight(Math.ceil(entry.contentRect.height));
                }
            }
        });
        observer.observe(receiptRef.current);
        return () => observer.disconnect();
    }, []);

    // Dynamically adjust scale on mobile screens to fit neatly without any line wrapping or horizontal overflow
    useEffect(() => {
        if (!previewStageRef.current) return;

        const handleResize = () => {
            if (!previewStageRef.current) return;
            const stageWidth = previewStageRef.current.clientWidth;
            // Accounting for container padding (p-3 = 12px each side = 24px)
            const availableWidth = Math.max(0, stageWidth - 28);
            if (autoFitMobile && availableWidth < cardWidth && availableWidth > 0) {
                const scale = Math.min(1, Math.max(0.3, availableWidth / cardWidth));
                setPreviewScale(scale);
            } else {
                setPreviewScale(1);
            }
        };

        handleResize();

        const stageObserver = new ResizeObserver(() => {
            handleResize();
        });
        stageObserver.observe(previewStageRef.current);

        window.addEventListener("resize", handleResize);
        return () => {
            stageObserver.disconnect();
            window.removeEventListener("resize", handleResize);
        };
    }, [cardWidth, autoFitMobile]);

    // Initial automatic generation for fresh values if needed
    useEffect(() => {
        // Set date to current time on mount if desired
        setTransactionDate(getFormattedNow());
    }, []);

    const handleRandomizeAll = () => {
        setTrn(generateRandomTRN());
        setUtr(generateRandomUTR());
        setTransactionDate(getFormattedNow());
        // Random amount between 500 and 100000
        const randAmount = (Math.random() * 95000 + 500).toFixed(2);
        setAmount(randAmount);
        // Random account
        setDestinationAccount(Math.floor(10000000000000 + Math.random() * 90000000000000).toString());
        setUpiId(`user${Math.floor(Math.random() * 90000 + 10000)}@okhdfcbank`);
    };

    const handleResetToSample = () => {
        setTitle("Transfer Funds Transaction Details");
        setTrn(generateRandomTRN());
        setUtr(generateRandomUTR());
        setTransactionType("BANK_CARD");
        setDestinationAccount("");
        setBankIfsc("");
        setPayeeUpi("None");
        setUpiId("");
        setTransactionDate(getFormattedNow());
        setAmount("");
        setCurrencySymbol("₹");
        setStatus("SUCCESS");
        setFontFamily("Arial");
        setCardWidth(500);
        setLabelWidth(180);
        setValueWeight("bold");
    };

    const handleDownload = async (formatType: "png" | "jpeg" = "png") => {
        if (!receiptRef.current) return;
        setIsDownloading(true);

        try {
            // High-resolution 3x Retina export without modifying preview UI scale
            const options = {
                quality: 1.0,
                pixelRatio: 3, // High-res 3x pixel ratio
                backgroundColor: "#ffffff",
                cacheBust: true,
                width: cardWidth,
                height: receiptRef.current.offsetHeight || undefined,
                style: {
                    width: `${cardWidth}px`,
                    minWidth: `${cardWidth}px`,
                    maxWidth: `${cardWidth}px`,
                    transform: "none",
                    margin: "0",
                    whiteSpace: "nowrap",
                },
            };

            const dataUrl =
                formatType === "png"
                    ? await toPng(receiptRef.current, options)
                    : await toJpeg(receiptRef.current, { ...options, quality: 0.95 });

            const link = document.createElement("a");
            link.download = `transaction_${trn || "receipt"}.${formatType}`;
            link.href = dataUrl;
            link.click();
        } catch (err) {
            console.error("Failed to generate receipt image:", err);
            alert("Could not generate image. Please try again.");
        } finally {
            setIsDownloading(false);
        }
    };

    const handleCopyImage = async () => {
        if (!receiptRef.current) return;

        try {
            const blob = await toBlob(receiptRef.current, {
                quality: 1.0,
                pixelRatio: 3,
                backgroundColor: "#ffffff",
                cacheBust: true,
                width: cardWidth,
                height: receiptRef.current.offsetHeight || undefined,
                style: {
                    width: `${cardWidth}px`,
                    minWidth: `${cardWidth}px`,
                    maxWidth: `${cardWidth}px`,
                    transform: "none",
                    margin: "0",
                    whiteSpace: "nowrap",
                },
            });
            if (blob && navigator.clipboard && window.ClipboardItem) {
                await navigator.clipboard.write([
                    new ClipboardItem({ "image/png": blob }),
                ]);
                setCopiedImage(true);
                setTimeout(() => setCopiedImage(false), 2200);
            } else {
                alert("Clipboard image copy not supported in this browser. Please use Download button.");
            }
        } catch (err) {
            console.error("Failed to copy image to clipboard", err);
            alert("Could not copy image directly. Please use Download button.");
        }
    };

    const handlePrint = () => {
        window.print();
    };

    const handleShareLink = () => {
        navigator.clipboard.writeText(window.location.href);
        setCopiedLink(true);
        setTimeout(() => setCopiedLink(false), 2000);
    };

    const formattedAmount = amount ? `${currencySymbol}${amount}` : "—";

    return (
        <div className="min-h-screen bg-[#07080a] text-slate-100 antialiased">
            {/* Top Navigation Bar */}
            <header className="border-b border-white/5 bg-[#0b0c10]/80 backdrop-blur-md sticky top-0 z-30 px-4 sm:px-8 py-3.5 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <Link
                        to="/"
                        className="p-2 rounded-xl bg-white/5 hover:bg-white/10 text-slate-400 hover:text-white transition-colors"
                        title="Back to App"
                    >
                        <ArrowLeft size={18} />
                    </Link>
                    <div>
                        <div className="flex items-center gap-2">
                            <h1 className="text-base sm:text-lg font-outfit font-bold tracking-tight text-white flex items-center gap-2">
                                <FileText size={18} className="text-primary" />
                                Transaction Slip Generator
                            </h1>
                            <span className="text-[11px] px-2 py-0.5 rounded-full bg-primary/10 text-primary border border-primary/30 font-medium hidden sm:inline-block">
                                Standalone / Client-side
                            </span>
                        </div>
                        <p className="text-xs text-slate-400 hidden sm:block">
                            Generate and download bank transaction slips as images. No database required.
                        </p>
                    </div>
                </div>

                <div className="flex items-center gap-2">
                    <button
                        onClick={handleShareLink}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-xs font-medium text-slate-300 transition-colors"
                        title="Copy page URL"
                    >
                        {copiedLink ? <Check size={14} className="text-primary" /> : <Share2 size={14} />}
                        <span>{copiedLink ? "Link Copied!" : "Share URL"}</span>
                    </button>
                    <button
                        onClick={handleResetToSample}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-xs font-medium text-slate-300 transition-colors"
                        title="Reset all fields to reference sample"
                    >
                        Reset Sample
                    </button>
                    <button
                        onClick={handleRandomizeAll}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-primary/10 hover:bg-primary/20 text-xs font-medium text-primary border border-primary/20 transition-colors"
                    >
                        <Sparkles size={14} />
                        <span className="hidden sm:inline">Randomize All</span>
                    </button>
                </div>
            </header>

            {/* Main Content Layout */}
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
                <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                    {/* Left Form Controls Column */}
                    <div className="lg:col-span-6 space-y-6">
                        {/* Section 1: Core Identifiers */}
                        <div className="bg-[#111318] border border-white/5 rounded-2xl p-5 shadow-xl space-y-4">
                            <div className="flex items-center justify-between pb-3 border-b border-white/5">
                                <h2 className="text-sm font-semibold uppercase tracking-wider text-slate-400 flex items-center gap-2">
                                    <ShieldCheck size={16} className="text-primary" />
                                    Transaction Identifiers
                                </h2>
                                <span className="text-xs text-slate-500">Auto-generated</span>
                            </div>

                            <div className="space-y-4">
                                {/* TRN */}
                                <div>
                                    <div className="flex items-center justify-between mb-1.5">
                                        <label className="text-xs font-medium text-slate-300">
                                            TRN (Transaction Reference Number)
                                        </label>
                                        <div className="flex items-center gap-2">
                                            <button
                                                type="button"
                                                onClick={() => setTrn(generateRandomTRN())}
                                                className="text-[11px] flex items-center gap-1 text-primary hover:underline cursor-pointer"
                                            >
                                                <RotateCw size={11} /> Auto-Generate
                                            </button>
                                        </div>
                                    </div>
                                    <div className="flex gap-2">
                                        <input
                                            type="text"
                                            value={trn}
                                            onChange={(e) => {
                                                let clean = e.target.value.toUpperCase();
                                                if (clean.length > 0 && !clean.startsWith("BOT") && /^\d+$/.test(clean)) {
                                                    clean = `BOT${clean}`;
                                                }
                                                setTrn(clean);
                                            }}
                                            placeholder="BOT1792914488468"
                                            className="flex-1 bg-white/5 border border-white/10 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-primary font-mono tracking-wide"
                                        />
                                        <button
                                            type="button"
                                            onClick={() => setTrn((prev) => incrementValue(prev, "BOT", 13))}
                                            className="px-3.5 py-2.5 bg-white/5 hover:bg-white/10 active:scale-95 border border-white/10 hover:border-primary/50 text-white rounded-xl text-xs font-mono font-bold flex items-center gap-1 transition-all shadow-sm cursor-pointer"
                                            title="Increment TRN (+1)"
                                        >
                                            <Plus size={14} className="text-primary" />
                                            <span>+1</span>
                                        </button>
                                    </div>
                                </div>

                                {/* UTR */}
                                <div>
                                    <div className="flex items-center justify-between mb-1.5">
                                        <label className="text-xs font-medium text-slate-300">
                                            UTR (Unique Transaction Reference)
                                        </label>
                                        <div className="flex items-center gap-2">
                                            <button
                                                type="button"
                                                onClick={() => setUtr(generateRandomUTR())}
                                                className="text-[11px] flex items-center gap-1 text-primary hover:underline cursor-pointer"
                                            >
                                                <RotateCw size={11} /> Auto-Generate
                                            </button>
                                        </div>
                                    </div>
                                    <div className="flex gap-2">
                                        <input
                                            type="text"
                                            value={utr}
                                            onChange={(e) => setUtr(e.target.value)}
                                            placeholder="629884398691"
                                            className="flex-1 bg-white/5 border border-white/10 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-primary font-mono tracking-wide"
                                        />
                                        <button
                                            type="button"
                                            onClick={() => setUtr((prev) => incrementValue(prev, "", 12))}
                                            className="px-3.5 py-2.5 bg-white/5 hover:bg-white/10 active:scale-95 border border-white/10 hover:border-primary/50 text-white rounded-xl text-xs font-mono font-bold flex items-center gap-1 transition-all shadow-sm cursor-pointer"
                                            title="Increment UTR (+1)"
                                        >
                                            <Plus size={14} className="text-primary" />
                                            <span>+1</span>
                                        </button>
                                    </div>
                                </div>

                                {/* Transaction Date */}
                                <div>
                                    <div className="flex items-center justify-between mb-1.5">
                                        <label className="text-xs font-medium text-slate-300">
                                            Transaction Date (YYYY/MM/DD HH:mm:ss)
                                        </label>
                                        <button
                                            type="button"
                                            onClick={() => setTransactionDate(getFormattedNow())}
                                            className="text-[11px] flex items-center gap-1 text-primary hover:underline"
                                        >
                                            <Clock size={11} /> Set to Now
                                        </button>
                                    </div>
                                    <div className="relative">
                                        <input
                                            type="text"
                                            value={transactionDate}
                                            onChange={(e) => setTransactionDate(e.target.value)}
                                            placeholder="2026/10/25 13:18:08"
                                            className="w-full bg-white/5 border border-white/10 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-primary font-mono tracking-wide"
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Section 2: Account & Transfer Details */}
                        <div className="bg-[#111318] border border-white/5 rounded-2xl p-5 shadow-xl space-y-4">
                            <h2 className="text-sm font-semibold uppercase tracking-wider text-slate-400 pb-3 border-b border-white/5">
                                Account & Banking Details
                            </h2>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                {/* Transaction Type */}
                                <div className="sm:col-span-2">
                                    <label className="block text-xs font-medium text-slate-300 mb-1.5">
                                        Transaction Type
                                    </label>
                                    <div className="flex flex-wrap gap-1.5 mb-2">
                                        {TRANSACTION_TYPES.map((type) => (
                                            <button
                                                key={type}
                                                type="button"
                                                onClick={() => setTransactionType(type)}
                                                className={`px-2.5 py-1 text-xs rounded-lg transition-colors ${transactionType === type
                                                    ? "bg-primary text-black font-semibold shadow-sm"
                                                    : "bg-white/5 text-slate-300 hover:bg-white/10"
                                                    }`}
                                            >
                                                {type}
                                            </button>
                                        ))}
                                    </div>
                                    <input
                                        type="text"
                                        value={transactionType}
                                        onChange={(e) => setTransactionType(e.target.value)}
                                        placeholder="BANK_CARD"
                                        className="w-full bg-white/5 border border-white/10 rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:border-primary"
                                    />
                                </div>

                                {transactionType === "UPI" ? (
                                    /* UPI ID input for UPI mode */
                                    <div className="sm:col-span-2 space-y-1.5">
                                        <div className="flex items-center justify-between">
                                            <label className="text-xs font-medium text-slate-300">
                                                UPI ID
                                            </label>
                                            <span className="text-[11px] text-primary font-medium">
                                                UPI Mode (Replaces A/C & IFSC)
                                            </span>
                                        </div>
                                        <input
                                            type="text"
                                            value={upiId}
                                            onChange={(e) => {
                                                setUpiId(e.target.value);
                                                setPayeeUpi(e.target.value);
                                            }}
                                            placeholder="Enter UPI ID (e.g. user@okhdfcbank)"
                                            className="w-full bg-white/5 border border-white/10 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-primary font-mono"
                                        />
                                    </div>
                                ) : (
                                    <>
                                        {/* Destination A/C */}
                                        <div>
                                            <label className="block text-xs font-medium text-slate-300 mb-1.5">
                                                Destination A/C
                                            </label>
                                            <input
                                                type="text"
                                                value={destinationAccount}
                                                onChange={(e) => setDestinationAccount(e.target.value)}
                                                placeholder="Enter A/C Number"
                                                className="w-full bg-white/5 border border-white/10 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-primary font-mono"
                                            />
                                        </div>

                                        {/* Bank IFSC */}
                                        <div>
                                            <label className="block text-xs font-medium text-slate-300 mb-1.5">
                                                Bank IFSC
                                            </label>
                                            <input
                                                type="text"
                                                value={bankIfsc}
                                                onChange={(e) => setBankIfsc(e.target.value.toUpperCase())}
                                                placeholder="Enter IFSC Code"
                                                className="w-full bg-white/5 border border-white/10 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-primary font-mono uppercase"
                                            />
                                        </div>

                                        {/* Payee UPI */}
                                        <div className="sm:col-span-2">
                                            <div className="flex items-center justify-between mb-1.5">
                                                <label className="text-xs font-medium text-slate-300">
                                                    Payee UPI
                                                </label>
                                                <div className="flex gap-2">
                                                    <button
                                                        type="button"
                                                        onClick={() => setPayeeUpi("None")}
                                                        className="text-[11px] text-slate-400 hover:text-white"
                                                    >
                                                        Set "None"
                                                    </button>
                                                </div>
                                            </div>
                                            <input
                                                type="text"
                                                value={payeeUpi}
                                                onChange={(e) => setPayeeUpi(e.target.value)}
                                                placeholder="None or handle@bank"
                                                className="w-full bg-white/5 border border-white/10 rounded-xl px-3.5 py-2.5 text-sm text-white focus:outline-none focus:border-primary"
                                            />
                                        </div>
                                    </>
                                )}
                            </div>
                        </div>

                        {/* Section 3: Amount & Status */}
                        <div className="bg-[#111318] border border-white/5 rounded-2xl p-5 shadow-xl space-y-4">
                            <h2 className="text-sm font-semibold uppercase tracking-wider text-slate-400 pb-3 border-b border-white/5">
                                Amount & Transaction Status
                            </h2>

                            <div className="space-y-4">
                                {/* Amount */}
                                <div>
                                    <label className="block text-xs font-medium text-slate-300 mb-1.5">
                                        Amount
                                    </label>
                                    <div className="flex rounded-xl overflow-hidden border border-white/10 focus-within:border-primary">
                                        <select
                                            value={currencySymbol}
                                            onChange={(e) => setCurrencySymbol(e.target.value)}
                                            className="bg-white/10 px-3 py-2.5 text-sm text-white font-medium border-r border-white/10 focus:outline-none"
                                        >
                                            <option value="₹" className="bg-[#111318]">₹ (INR)</option>
                                            <option value="$" className="bg-[#111318]">$ (USD)</option>
                                            <option value="€" className="bg-[#111318]">€ (EUR)</option>
                                            <option value="£" className="bg-[#111318]">£ (GBP)</option>
                                            <option value="" className="bg-[#111318]">None</option>
                                        </select>
                                        <input
                                            type="text"
                                            value={amount}
                                            onChange={(e) => setAmount(e.target.value)}
                                            placeholder="Enter Amount (e.g. 35000.00)"
                                            className="w-full bg-white/5 px-3.5 py-2.5 text-sm text-white focus:outline-none font-mono"
                                        />
                                    </div>
                                </div>

                                {/* Status */}
                                <div>
                                    <label className="block text-xs font-medium text-slate-300 mb-1.5">
                                        Status (Default: SUCCESS)
                                    </label>
                                    <div className="flex flex-wrap gap-2 mb-2">
                                        {STATUS_OPTIONS.map((opt) => (
                                            <button
                                                key={opt.label}
                                                type="button"
                                                onClick={() => setStatus(opt.label)}
                                                className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition-all ${status === opt.label
                                                    ? `${opt.color} ring-1 ring-white/20`
                                                    : "bg-white/5 border-white/10 text-slate-400 hover:text-white"
                                                    }`}
                                            >
                                                {opt.label}
                                            </button>
                                        ))}
                                    </div>
                                    <input
                                        type="text"
                                        value={status}
                                        onChange={(e) => setStatus(e.target.value)}
                                        placeholder="SUCCESS"
                                        className="w-full bg-white/5 border border-white/10 rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:border-primary font-semibold uppercase"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Section 4: Advanced Appearance Options */}
                        <div className="bg-[#111318] border border-white/5 rounded-2xl p-5 shadow-xl space-y-4">
                            <button
                                type="button"
                                onClick={() => setShowOptions(!showOptions)}
                                className="w-full flex items-center justify-between text-left text-sm font-semibold uppercase tracking-wider text-slate-400"
                            >
                                <span className="flex items-center gap-2">
                                    <Sliders size={16} className="text-primary" />
                                    Custom Styling & Alignment (Optional)
                                </span>
                                <span className="text-xs text-primary">
                                    {showOptions ? "Hide" : "Show"}
                                </span>
                            </button>

                            {showOptions && (
                                <div className="space-y-4 pt-3 border-t border-white/5">
                                    <div>
                                        <label className="block text-xs font-medium text-slate-300 mb-1">
                                            Slip Title Header
                                        </label>
                                        <input
                                            type="text"
                                            value={title}
                                            onChange={(e) => setTitle(e.target.value)}
                                            className="w-full bg-white/5 border border-white/10 rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:border-primary"
                                        />
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div>
                                            <label className="block text-xs font-medium text-slate-300 mb-1">
                                                Font Family
                                            </label>
                                            <select
                                                value={fontFamily}
                                                onChange={(e) => setFontFamily(e.target.value as any)}
                                                className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-sm text-white focus:outline-none"
                                            >
                                                <option value="Arial" className="bg-[#111318]">Arial / Helvetica (Default)</option>
                                                <option value="Inter" className="bg-[#111318]">Inter (Modern)</option>
                                                <option value="Segoe UI" className="bg-[#111318]">Segoe UI</option>
                                                <option value="Courier" className="bg-[#111318]">Monospace / Courier</option>
                                            </select>
                                        </div>

                                        <div>
                                            <label className="block text-xs font-medium text-slate-300 mb-1">
                                                Value Text Weight
                                            </label>
                                            <select
                                                value={valueWeight}
                                                onChange={(e) => setValueWeight(e.target.value as any)}
                                                className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-sm text-white focus:outline-none"
                                            >
                                                <option value="bold" className="bg-[#111318]">Bold (Matches Sample)</option>
                                                <option value="600" className="bg-[#111318]">Semi-Bold</option>
                                                <option value="normal" className="bg-[#111318]">Regular</option>
                                            </select>
                                        </div>
                                    </div>

                                    <div className="grid grid-cols-2 gap-4">
                                        <div>
                                            <label className="block text-xs font-medium text-slate-300 mb-1">
                                                Card Width: {cardWidth}px
                                            </label>
                                            <input
                                                type="range"
                                                min={380}
                                                max={650}
                                                step={10}
                                                value={cardWidth}
                                                onChange={(e) => setCardWidth(Number(e.target.value))}
                                                className="w-full accent-primary"
                                            />
                                        </div>

                                        <div>
                                            <label className="block text-xs font-medium text-slate-300 mb-1">
                                                Label Column: {labelWidth}px
                                            </label>
                                            <input
                                                type="range"
                                                min={140}
                                                max={240}
                                                step={5}
                                                value={labelWidth}
                                                onChange={(e) => setLabelWidth(Number(e.target.value))}
                                                className="w-full accent-primary"
                                            />
                                        </div>
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Right Sticky Preview & Actions Column */}
                    <div className="lg:col-span-6 lg:sticky lg:top-20 space-y-4">
                        {/* Action Buttons Bar */}
                        <div className="bg-[#111318] border border-white/5 rounded-2xl p-4 shadow-xl flex flex-wrap items-center justify-between gap-3">
                            <div className="flex items-center gap-2">
                                <Eye size={16} className="text-primary" />
                                <span className="text-sm font-semibold text-white">Live Screen Preview</span>
                            </div>

                            <div className="flex items-center gap-2">
                                {/* Mobile auto-fit zoom toggle */}
                                <button
                                    onClick={() => setAutoFitMobile(!autoFitMobile)}
                                    className="hidden sm:inline-flex md:hidden text-[11px] px-2.5 py-1 rounded-lg bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10 transition-colors"
                                    title="Toggle between auto-fitting mobile screen and actual 100% size"
                                >
                                    {autoFitMobile ? "Zoom: Fit" : "Zoom: 100%"}
                                </button>
                                <button
                                    onClick={() => setAutoFitMobile(!autoFitMobile)}
                                    className="sm:hidden text-[11px] px-2 py-1 rounded-lg bg-white/5 hover:bg-white/10 text-slate-300 border border-white/10 transition-colors"
                                    title="Toggle between auto-fitting mobile screen and actual 100% size"
                                >
                                    {autoFitMobile ? "100%" : "Fit"}
                                </button>

                                {/* Preview background switcher */}
                                <div className="flex items-center gap-1 bg-white/5 p-1 rounded-lg text-xs">
                                    <button
                                        onClick={() => setPreviewBg("dark")}
                                        className={`px-2 py-1 rounded transition-colors ${previewBg === "dark" ? "bg-white/10 text-white" : "text-slate-400 hover:text-white"
                                            }`}
                                    >
                                        Dark
                                    </button>
                                    <button
                                        onClick={() => setPreviewBg("grid")}
                                        className={`px-2 py-1 rounded transition-colors ${previewBg === "grid" ? "bg-white/10 text-white" : "text-slate-400 hover:text-white"
                                            }`}
                                    >
                                        Grid
                                    </button>
                                    <button
                                        onClick={() => setPreviewBg("light")}
                                        className={`px-2 py-1 rounded transition-colors ${previewBg === "light" ? "bg-white/10 text-white" : "text-slate-400 hover:text-white"
                                            }`}
                                    >
                                        Light
                                    </button>
                                </div>
                            </div>
                        </div>

                        {/* Receipt Container Preview Canvas */}
                        <div
                            ref={previewStageRef}
                            className={`rounded-2xl border border-white/10 p-3 sm:p-8 flex items-center justify-center overflow-x-auto min-h-[360px] sm:min-h-105 transition-colors ${previewBg === "dark"
                                ? "bg-[#0b0c10]"
                                : previewBg === "grid"
                                    ? "bg-[#14171f] bg-[radial-gradient(#334155_1px,transparent_1px)] bg-size-[16px_16px]"
                                    : "bg-slate-200"
                                }`}
                        >
                            {/* Scaled wrapper for responsive mobile viewing without distorting or wrapping the captured card */}
                            <div
                                style={{
                                    width: previewScale < 1 ? `${Math.round(cardWidth * previewScale)}px` : `${cardWidth}px`,
                                    height: previewScale < 1 && cardHeight > 0 ? `${Math.ceil(cardHeight * previewScale)}px` : "auto",
                                    position: "relative",
                                    overflow: "visible",
                                    flexShrink: 0,
                                    margin: "0 auto",
                                }}
                            >
                                <div
                                    style={{
                                        transform: previewScale < 1 ? `scale(${previewScale})` : "none",
                                        transformOrigin: "top left",
                                        width: `${cardWidth}px`,
                                        minWidth: `${cardWidth}px`,
                                        maxWidth: `${cardWidth}px`,
                                        position: previewScale < 1 ? "absolute" : "relative",
                                        top: 0,
                                        left: 0,
                                    }}
                                >
                                    {/* The Exact Printable / Exportable Screen Card (fixed dimensions, strictly no line-wrapping) */}
                                    <div
                                        ref={receiptRef}
                                        id="receipt-capture-area"
                                        style={{
                                            backgroundColor: "#ffffff",
                                            color: "#000000",
                                            fontFamily:
                                                fontFamily === "Inter"
                                                    ? "'Inter', sans-serif"
                                                    : fontFamily === "Segoe UI"
                                                        ? "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
                                                        : fontFamily === "Courier"
                                                            ? "'Courier New', Courier, monospace"
                                                            : "Arial, Helvetica, -apple-system, BlinkMacSystemFont, sans-serif",
                                            width: `${cardWidth}px`,
                                            minWidth: `${cardWidth}px`,
                                            maxWidth: `${cardWidth}px`,
                                            flexShrink: 0,
                                            padding: "24px 28px 24px 28px",
                                            boxSizing: "border-box",
                                            boxShadow: "0 10px 30px rgba(0,0,0,0.35)",
                                            borderRadius: "0px",
                                            whiteSpace: "nowrap",
                                            wordBreak: "keep-all",
                                            overflowWrap: "normal",
                                            WebkitTextSizeAdjust: "100%",
                                            textSizeAdjust: "100%",
                                        }}
                                    >
                                        {/* Title */}
                                        <div
                                            style={{
                                                fontSize: "17px",
                                                fontWeight: "700",
                                                color: "#000000",
                                                letterSpacing: "-0.1px",
                                                lineHeight: "1.25",
                                                marginBottom: "6px",
                                                whiteSpace: "nowrap",
                                                wordBreak: "keep-all",
                                                overflowWrap: "normal",
                                                flexShrink: 0,
                                            }}
                                        >
                                            {title}
                                        </div>

                                        {/* Divider line */}
                                        <div
                                            style={{
                                                borderBottom: "1.5px solid #000000",
                                                marginBottom: "12px",
                                                width: "100%",
                                            }}
                                        />

                                        {/* Transaction Details Table */}
                                        <div
                                            style={{
                                                display: "flex",
                                                flexDirection: "column",
                                                gap: "7px",
                                                lineHeight: "1.3",
                                                whiteSpace: "nowrap",
                                                width: "100%",
                                            }}
                                        >
                                            {/* Row 1: TRN */}
                                            <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                <div
                                                    style={{
                                                        width: `${labelWidth}px`,
                                                        minWidth: `${labelWidth}px`,
                                                        maxWidth: `${labelWidth}px`,
                                                        fontWeight: "700",
                                                        fontSize: "14.5px",
                                                        color: "#000000",
                                                        flexShrink: 0,
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                    }}
                                                >
                                                    TRN
                                                </div>
                                                <div
                                                    style={{
                                                        fontSize: "14.5px",
                                                        fontWeight: valueWeight,
                                                        color: "#000000",
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                        flexShrink: 0,
                                                        display: "inline-block",
                                                    }}
                                                >
                                                    {trn || "—"}
                                                </div>
                                            </div>

                                            {/* Row 2: UTR */}
                                            <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                <div
                                                    style={{
                                                        width: `${labelWidth}px`,
                                                        minWidth: `${labelWidth}px`,
                                                        maxWidth: `${labelWidth}px`,
                                                        fontWeight: "700",
                                                        fontSize: "14.5px",
                                                        color: "#000000",
                                                        flexShrink: 0,
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                    }}
                                                >
                                                    UTR
                                                </div>
                                                <div
                                                    style={{
                                                        fontSize: "14.5px",
                                                        fontWeight: valueWeight,
                                                        color: "#000000",
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                        flexShrink: 0,
                                                        display: "inline-block",
                                                    }}
                                                >
                                                    {utr || "—"}
                                                </div>
                                            </div>

                                            {/* Row 3: Transaction Type */}
                                            <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                <div
                                                    style={{
                                                        width: `${labelWidth}px`,
                                                        minWidth: `${labelWidth}px`,
                                                        maxWidth: `${labelWidth}px`,
                                                        fontWeight: "700",
                                                        fontSize: "14.5px",
                                                        color: "#000000",
                                                        flexShrink: 0,
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                    }}
                                                >
                                                    Transaction Type
                                                </div>
                                                <div
                                                    style={{
                                                        fontSize: "14.5px",
                                                        fontWeight: valueWeight,
                                                        color: "#000000",
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                        flexShrink: 0,
                                                        display: "inline-block",
                                                    }}
                                                >
                                                    {transactionType || "—"}
                                                </div>
                                            </div>

                                            {transactionType === "UPI" ? (
                                                /* Row for UPI: only UPI ID */
                                                <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                    <div
                                                        style={{
                                                            width: `${labelWidth}px`,
                                                            minWidth: `${labelWidth}px`,
                                                            maxWidth: `${labelWidth}px`,
                                                            fontWeight: "700",
                                                            fontSize: "14.5px",
                                                            color: "#000000",
                                                            flexShrink: 0,
                                                            whiteSpace: "nowrap",
                                                            wordBreak: "keep-all",
                                                            overflowWrap: "normal",
                                                        }}
                                                    >
                                                        UPI ID
                                                    </div>
                                                    <div
                                                        style={{
                                                            fontSize: "14.5px",
                                                            fontWeight: valueWeight,
                                                            color: "#000000",
                                                            whiteSpace: "nowrap",
                                                            wordBreak: "keep-all",
                                                            overflowWrap: "normal",
                                                            flexShrink: 0,
                                                            display: "inline-block",
                                                        }}
                                                    >
                                                        {upiId || (payeeUpi !== "None" ? payeeUpi : "") || "—"}
                                                    </div>
                                                </div>
                                            ) : (
                                                <>
                                                    {/* Row 4: Destination A/C */}
                                                    <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                        <div
                                                            style={{
                                                                width: `${labelWidth}px`,
                                                                minWidth: `${labelWidth}px`,
                                                                maxWidth: `${labelWidth}px`,
                                                                fontWeight: "700",
                                                                fontSize: "14.5px",
                                                                color: "#000000",
                                                                flexShrink: 0,
                                                                whiteSpace: "nowrap",
                                                                wordBreak: "keep-all",
                                                                overflowWrap: "normal",
                                                            }}
                                                        >
                                                            Destination A/C
                                                        </div>
                                                        <div
                                                            style={{
                                                                fontSize: "14.5px",
                                                                fontWeight: valueWeight,
                                                                color: "#000000",
                                                                whiteSpace: "nowrap",
                                                                wordBreak: "keep-all",
                                                                overflowWrap: "normal",
                                                                flexShrink: 0,
                                                                display: "inline-block",
                                                            }}
                                                        >
                                                            {destinationAccount || "—"}
                                                        </div>
                                                    </div>

                                                    {/* Row 5: Bank IFSC */}
                                                    <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                        <div
                                                            style={{
                                                                width: `${labelWidth}px`,
                                                                minWidth: `${labelWidth}px`,
                                                                maxWidth: `${labelWidth}px`,
                                                                fontWeight: "700",
                                                                fontSize: "14.5px",
                                                                color: "#000000",
                                                                flexShrink: 0,
                                                                whiteSpace: "nowrap",
                                                                wordBreak: "keep-all",
                                                                overflowWrap: "normal",
                                                            }}
                                                        >
                                                            Bank IFSC
                                                        </div>
                                                        <div
                                                            style={{
                                                                fontSize: "14.5px",
                                                                fontWeight: valueWeight,
                                                                color: "#000000",
                                                                whiteSpace: "nowrap",
                                                                wordBreak: "keep-all",
                                                                overflowWrap: "normal",
                                                                flexShrink: 0,
                                                                display: "inline-block",
                                                            }}
                                                        >
                                                            {bankIfsc || "—"}
                                                        </div>
                                                    </div>

                                                    {/* Row 6: Payee UPI */}
                                                    <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                        <div
                                                            style={{
                                                                width: `${labelWidth}px`,
                                                                minWidth: `${labelWidth}px`,
                                                                maxWidth: `${labelWidth}px`,
                                                                fontWeight: "700",
                                                                fontSize: "14.5px",
                                                                color: "#000000",
                                                                flexShrink: 0,
                                                                whiteSpace: "nowrap",
                                                                wordBreak: "keep-all",
                                                                overflowWrap: "normal",
                                                            }}
                                                        >
                                                            Payee UPI
                                                        </div>
                                                        <div
                                                            style={{
                                                                fontSize: "14.5px",
                                                                fontWeight: valueWeight,
                                                                color: "#000000",
                                                                whiteSpace: "nowrap",
                                                                wordBreak: "keep-all",
                                                                overflowWrap: "normal",
                                                                flexShrink: 0,
                                                                display: "inline-block",
                                                            }}
                                                        >
                                                            {payeeUpi || "None"}
                                                        </div>
                                                    </div>
                                                </>
                                            )}

                                            {/* Row 7: Transaction Date */}
                                            <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                <div
                                                    style={{
                                                        width: `${labelWidth}px`,
                                                        minWidth: `${labelWidth}px`,
                                                        maxWidth: `${labelWidth}px`,
                                                        fontWeight: "700",
                                                        fontSize: "14.5px",
                                                        color: "#000000",
                                                        flexShrink: 0,
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                    }}
                                                >
                                                    Transaction Date
                                                </div>
                                                <div
                                                    style={{
                                                        fontSize: "14.5px",
                                                        fontWeight: valueWeight,
                                                        color: "#000000",
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                        flexShrink: 0,
                                                        display: "inline-block",
                                                    }}
                                                >
                                                    {transactionDate || "—"}
                                                </div>
                                            </div>

                                            {/* Row 8: Amount */}
                                            <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                <div
                                                    style={{
                                                        width: `${labelWidth}px`,
                                                        minWidth: `${labelWidth}px`,
                                                        maxWidth: `${labelWidth}px`,
                                                        fontWeight: "700",
                                                        fontSize: "14.5px",
                                                        color: "#000000",
                                                        flexShrink: 0,
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                    }}
                                                >
                                                    Amount
                                                </div>
                                                <div
                                                    style={{
                                                        fontSize: "14.5px",
                                                        fontWeight: valueWeight,
                                                        color: "#000000",
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                        flexShrink: 0,
                                                        display: "inline-block",
                                                    }}
                                                >
                                                    {formattedAmount}
                                                </div>
                                            </div>

                                            {/* Row 9: Status */}
                                            <div style={{ display: "flex", alignItems: "center", whiteSpace: "nowrap", flexWrap: "nowrap", width: "100%" }}>
                                                <div
                                                    style={{
                                                        width: `${labelWidth}px`,
                                                        minWidth: `${labelWidth}px`,
                                                        maxWidth: `${labelWidth}px`,
                                                        fontWeight: "700",
                                                        fontSize: "14.5px",
                                                        color: "#000000",
                                                        flexShrink: 0,
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                    }}
                                                >
                                                    Status
                                                </div>
                                                <div
                                                    style={{
                                                        fontSize: "14.5px",
                                                        fontWeight: valueWeight,
                                                        color: "#000000",
                                                        whiteSpace: "nowrap",
                                                        wordBreak: "keep-all",
                                                        overflowWrap: "normal",
                                                        flexShrink: 0,
                                                        display: "inline-block",
                                                    }}
                                                >
                                                    {status || "SUCCESS"}
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Download & Export Action Buttons */}
                        <div className="bg-[#111318] border border-white/5 rounded-2xl p-5 shadow-xl space-y-3">
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                {/* Primary PNG Download */}
                                <button
                                    onClick={() => handleDownload("png")}
                                    disabled={isDownloading}
                                    className="w-full bg-primary hover:bg-primary/90 text-black font-bold py-3.5 px-5 rounded-xl flex items-center justify-center gap-2 shadow-[0_0_25px_rgba(0,255,157,0.25)] transition-all hover:scale-[1.01] active:scale-[0.99] disabled:opacity-50 cursor-pointer"
                                >
                                    <Download size={18} />
                                    <span>{isDownloading ? "Generating Image..." : "Download Image (PNG)"}</span>
                                </button>

                                {/* Copy to Clipboard */}
                                <button
                                    onClick={handleCopyImage}
                                    className="w-full bg-white/5 hover:bg-white/10 text-white font-medium py-3.5 px-5 rounded-xl border border-white/10 flex items-center justify-center gap-2 transition-all hover:border-white/20 active:scale-[0.99]"
                                >
                                    {copiedImage ? <Check size={18} className="text-primary" /> : <Copy size={18} />}
                                    <span>{copiedImage ? "Copied to Clipboard!" : "Copy Image"}</span>
                                </button>
                            </div>

                            <div className="flex items-center justify-between text-xs text-slate-400 pt-2 border-t border-white/5">
                                <span className="flex items-center gap-1.5">
                                    <span className="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
                                    High-res 3x Retina quality export
                                </span>
                                <div className="flex items-center gap-2">
                                    <button
                                        onClick={() => handleDownload("jpeg")}
                                        disabled={isDownloading}
                                        className="hover:text-white underline"
                                    >
                                        Download as JPEG
                                    </button>
                                    <span>•</span>
                                    <button
                                        onClick={handlePrint}
                                        className="hover:text-white flex items-center gap-1"
                                    >
                                        <Printer size={13} /> Print
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    );
};

export default ReceiptGenerator;
