import { AnimatePresence, motion } from "framer-motion";
import {
    AlertCircle,
    Download,
    History,
    RefreshCw,
    ShieldAlert,
    ShieldCheck,
    Upload,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import api from "../../lib/api";
import {
    exportPrivateKey,
    exportPublicKey,
    generateKeyPair,
} from "../../lib/crypto";

const Settings: React.FC = () => {
    const [hasKeys, setHasKeys] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [alert, setAlert] = useState<{
        title: string;
        message: string;
        type: "success" | "error";
    } | null>(null);

    const fetchData = async () => {
        try {
            const privKey = localStorage.getItem("admin_private_key");
            setHasKeys(!!privKey);
        } catch (e) {
            console.error(e);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const processKeyGen = async () => {
        setIsLoading(true);
        try {
            const keyPair = await generateKeyPair();
            const pub = await exportPublicKey(keyPair.publicKey);
            const priv = await exportPrivateKey(keyPair.privateKey);

            await api.post("/wallet/admin/public-key", { publicKey: pub });
            localStorage.setItem("admin_private_key", priv);
            setHasKeys(true);

            // Download PEM
            const element = document.createElement("a");
            const file = new Blob([priv], { type: "text/plain" });
            element.href = URL.createObjectURL(file);
            element.download = "admin_master_key.pem";
            document.body.appendChild(element);
            element.click();
            document.body.removeChild(element);

            setAlert({
                title: "Infrastructure Ready",
                message:
                    "Master Keys generated and deployed. PEM file downloaded.",
                type: "success",
            });
        } catch (e) {
            setAlert({
                title: "Failure",
                message: "Cryptographic reset failed.",
                type: "error",
            });
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="space-y-10 max-w-5xl">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    Platform Infrastructure
                </h1>
                <p className="text-text-dim max-w-2xl font-medium">
                    Core system configurations, cryptographic headers, and
                    secure settlement addresses.
                </p>
            </header>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Wallet Config */}
                <div className="lg:col-span-2 space-y-8">
                    <section className="glass p-10 space-y-8 border-red-500/10">
                        <div className="flex items-center gap-5">
                            <div
                                className={`w-14 h-14 rounded-2xl flex items-center justify-center border-2 shadow-2xl transition-all ${hasKeys ? "bg-primary/10 border-primary/20 shadow-primary/10" : "bg-red-500/10 border-red-500/20 shadow-red-500/10"}`}
                            >
                                {hasKeys ? (
                                    <ShieldCheck
                                        className="text-primary"
                                        size={28}
                                    />
                                ) : (
                                    <ShieldAlert
                                        className="text-red-500"
                                        size={28}
                                    />
                                )}
                            </div>
                            <div>
                                <h3 className="text-xl font-outfit font-bold text-white">
                                    E2EE Terminal
                                </h3>
                                <p
                                    className={`text-[10px] font-bold uppercase tracking-[0.2em] mt-1 ${hasKeys ? "text-primary" : "text-red-500"}`}
                                >
                                    {hasKeys
                                        ? "Active Infrastructure"
                                        : "Terminal Locked"}
                                </p>
                            </div>
                        </div>

                        <div className="space-y-6">
                            <p className="text-sm text-text-dim leading-relaxed max-w-xl">
                                End-to-End Encryption ensures all user bank
                                details are encrypted on the client and can only
                                be decrypted by an authorized admin terminal
                                with a valid Master Private Key.
                            </p>

                            <div className="flex flex-wrap gap-4">
                                <button
                                    onClick={processKeyGen}
                                    disabled={isLoading}
                                    className="px-8 py-5 rounded-2xl bg-white text-bg-dark font-black uppercase text-[10px] tracking-widest hover:scale-105 transition-all flex items-center gap-3 disabled:opacity-50"
                                >
                                    <RefreshCw
                                        size={16}
                                        className={
                                            isLoading ? "animate-spin" : ""
                                        }
                                    />
                                    {isLoading
                                        ? "Generating..."
                                        : "Reset Cryptography"}
                                </button>
                                <button className="px-8 py-5 rounded-2xl border border-white/10 text-white font-bold text-[10px] uppercase tracking-widest hover:bg-white/5 transition-all flex items-center gap-3">
                                    <Download size={16} /> Export PEM
                                </button>
                                <button className="px-8 py-5 rounded-2xl border border-white/10 text-white font-bold text-[10px] uppercase tracking-widest hover:bg-white/5 transition-all flex items-center gap-3">
                                    <Upload size={16} /> Import PEM
                                </button>
                            </div>
                        </div>
                    </section>
                </div>

                {/* Info blocks */}
                <div className="space-y-6">
                    <div className="glass p-8 bg-primary/5 border-primary/10">
                        <AlertCircle className="text-primary mb-4" size={24} />
                        <h4 className="text-white font-bold mb-2 font-outfit">
                            Security Protocol
                        </h4>
                        <p className="text-xs text-text-dim leading-relaxed">
                            System keys are stored locally in your browser's
                            secure context. Clearing site data will require a
                            PEM import to regain decryption capabilities.
                        </p>
                    </div>

                    <div className="glass p-8">
                        <History className="text-text-dim mb-4" size={24} />
                        <h4 className="text-white font-bold mb-2 font-outfit">
                            Audit Compliance
                        </h4>
                        <p className="text-xs text-text-dim leading-relaxed">
                            All infrastructure changes are logged with
                            administrative identity headers and timestamped on
                            the global settlement ledger.
                        </p>
                    </div>
                </div>
            </div>

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
                                className={`mx-auto w-16 h-16 rounded-full flex items-center justify-center mb-6 ${alert.type === "success" ? "bg-primary/10 text-primary" : "bg-red-500/10 text-red-500"}`}
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
                                        ? "bg-primary text-bg-dark"
                                        : "bg-red-500 text-white"
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

export default Settings;
