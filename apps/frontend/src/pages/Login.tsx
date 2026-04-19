import { AnimatePresence, motion } from "framer-motion";
import {
    ArrowRight,
    Diamond,
    KeyRound,
    Loader2,
    ShieldAlert,
} from "lucide-react";
import React, { useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import api from "../lib/api";

const Login: React.FC = () => {
    const [email, setEmail] = useState("");
    const [otp, setOtp] = useState("");
    const [step, setStep] = useState<"email" | "otp">("email");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<{
        title: string;
        message: string;
    } | null>(null);
    const { login } = useAuth();

    const handleSendOtp = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        try {
            await api.post("/auth/send-otp", { email });
            setStep("otp");
        } catch (err: any) {
            setError({
                title: "Login Denied",
                message:
                    err.response?.data?.message ||
                    "Access Denied: You must be pre-registered by an Admin before accessing the platform.",
            });
        }
        setLoading(false);
    };

    const handleVerifyOtp = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        try {
            await login(email, otp);
            window.location.href = "/";
        } catch (err: any) {
            setError({
                title: "Auth Failure",
                message:
                    err.response?.data?.message ||
                    "The authorization code provided is invalid or has expired.",
            });
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center p-6 bg-bg-dark relative overflow-hidden">
            {/* Background ambient lighting */}
            <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none opacity-40">
                <div
                    className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] bg-primary rounded-full blur-[150px] opacity-20 animate-pulse"
                    style={{ animationDuration: "4s" }}
                />
                <div
                    className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[50%] bg-accent-blue rounded-full blur-[150px] opacity-20 animate-pulse"
                    style={{ animationDuration: "5s" }}
                />
            </div>

            <motion.div
                initial={{ opacity: 0, y: 30, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                transition={{ duration: 0.5, ease: "easeOut" }}
                className="glass-panel p-10 w-full max-w-[420px] relative z-10 shadow-2xl backdrop-blur-2xl"
            >
                <div className="flex justify-center mb-8">
                    <div className="w-20 h-20 bg-bg-dark rounded-3xl flex items-center justify-center border border-primary/20 shadow-[0_0_30px_rgba(0,255,157,0.15)]">
                        <Diamond className="text-primary w-10 h-10" />
                    </div>
                </div>

                <div className="text-center mb-8">
                    <h1 className="text-3xl font-outfit font-bold text-white tracking-tight mb-2">
                        Workspace Access
                    </h1>
                    <p className="text-text-dim text-sm">
                        {step === "email"
                            ? "Enter your whitelisted email address"
                            : "Check your inbox for the authorization code"}
                    </p>
                </div>

                <AnimatePresence mode="wait">
                    {step === "email" ? (
                        <motion.form
                            key="email-form"
                            initial={{ opacity: 0, x: -20 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: 20 }}
                            onSubmit={handleSendOtp}
                            className="space-y-6"
                        >
                            <div className="relative group">
                                <input
                                    type="email"
                                    placeholder="name@company.com"
                                    className="input-field pl-20 focus:pl-12 transition-all duration-300"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                />
                            </div>
                            <button
                                disabled={loading || !email}
                                className="btn-primary w-full flex items-center justify-center gap-2 h-14 text-base"
                            >
                                {loading ? (
                                    <Loader2 className="animate-spin w-5 h-5" />
                                ) : (
                                    <>
                                        Continue <ArrowRight size={18} />
                                    </>
                                )}
                            </button>
                            <div className="text-center pt-2">
                                <Link
                                    to="/signup"
                                    className="text-sm text-text-dim hover:text-white transition-colors"
                                >
                                    Don't have an account?{" "}
                                    <span className="text-primary font-bold">
                                        Signup here
                                    </span>
                                </Link>
                            </div>
                        </motion.form>
                    ) : (
                        <motion.form
                            key="otp-form"
                            initial={{ opacity: 0, x: 20 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -20 }}
                            onSubmit={handleVerifyOtp}
                            className="space-y-6"
                        >
                            <div className="relative group">
                                <input
                                    type="text"
                                    placeholder="0 0 0 0 0 0"
                                    className="input-field pl-12 text-center text-2xl font-outfit font-bold tracking-[0.2em] focus:pl-12 h-16"
                                    value={otp}
                                    maxLength={6}
                                    onChange={(e) =>
                                        setOtp(
                                            e.target.value.replace(/\D/g, ""),
                                        )
                                    }
                                    required
                                />
                                <KeyRound className="absolute left-4 top-1/2 -translate-y-1/2 text-text-dim w-5 h-5 group-focus-within:text-primary transition-colors" />
                            </div>

                            <div className="space-y-4">
                                <button
                                    disabled={loading || otp.length !== 6}
                                    className="btn-primary w-full flex items-center justify-center h-14 text-base"
                                >
                                    {loading ? (
                                        <Loader2 className="animate-spin w-5 h-5" />
                                    ) : (
                                        "Verify & Sign In"
                                    )}
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setStep("email")}
                                    className="w-full text-center text-text-dim text-sm hover:text-white transition-colors"
                                >
                                    Use a different email
                                </button>
                                <div className="text-center pt-4">
                                    <Link
                                        to="/signup"
                                        className="text-sm text-text-dim hover:text-white transition-colors"
                                    >
                                        Don't have an account?{" "}
                                        <span className="text-primary font-bold">
                                            Signup here
                                        </span>
                                    </Link>
                                </div>
                            </div>
                        </motion.form>
                    )}
                </AnimatePresence>

                <div className="mt-8 pt-6 border-t border-white/5 flex items-start gap-3">
                    <ShieldAlert className="w-5 h-5 text-text-dim shrink-0" />
                    <p className="text-xs text-text-dim leading-relaxed">
                        Protected by end-to-end encryption. Unregistered access
                        attempts are monitored and recorded.
                    </p>
                </div>
            </motion.div>

            {/* Error Modal */}
            <AnimatePresence>
                {error && (
                    <div className="fixed inset-0 z-200 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
                        <motion.div
                            initial={{ scale: 0.9, opacity: 0 }}
                            animate={{ scale: 1, opacity: 1 }}
                            exit={{ scale: 0.9, opacity: 0 }}
                            className="glass-panel p-8 w-full max-w-sm shadow-2xl border-white/10"
                        >
                            <div className="flex flex-col items-center text-center">
                                <div className="w-16 h-16 rounded-full bg-red-500/10 text-red-500 flex items-center justify-center mb-6">
                                    <ShieldAlert size={32} />
                                </div>
                                <h2 className="text-2xl font-outfit font-bold mb-2">
                                    {error.title}
                                </h2>
                                <p className="text-text-dim text-sm mb-8 leading-relaxed">
                                    {error.message}
                                </p>
                                <button
                                    onClick={() => setError(null)}
                                    className="w-full py-3 bg-red-500 text-white rounded-xl font-bold hover:bg-red-600 transition-colors"
                                >
                                    Try Again
                                </button>
                            </div>
                        </motion.div>
                    </div>
                )}
            </AnimatePresence>
        </div>
    );
};

export default Login;
