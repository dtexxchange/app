import { AnimatePresence, motion } from "framer-motion";
import {
    ArrowRight,
    CheckCircle2,
    Loader2,
    ShieldAlert,
    UserPlus,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import api from "../lib/api";

const Signup: React.FC = () => {
    const [searchParams] = useSearchParams();
    const [firstName, setFirstName] = useState("");
    const [lastName, setLastName] = useState("");
    const [email, setEmail] = useState("");
    const [referralCode, setReferralCode] = useState("");
    const [loading, setLoading] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState<{
        title: string;
        message: string;
    } | null>(null);

    useEffect(() => {
        const ref = searchParams.get("ref");
        if (ref) {
            setReferralCode(ref.toUpperCase());
        }
    }, [searchParams]);

    const handleSignup = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError(null);
        try {
            await api.post("/auth/signup", {
                email,
                firstName,
                lastName,
                referralCode: referralCode || undefined,
            });
            setSuccess(true);
        } catch (err: any) {
            setError({
                title: "Signup Failed",
                message:
                    err.response?.data?.message ||
                    "Something went wrong. Please try again.",
            });
        }
        setLoading(false);
    };

    if (success) {
        return (
            <div className="min-h-screen flex items-center justify-center p-6 bg-bg-dark relative overflow-hidden">
                <motion.div
                    initial={{ opacity: 0, scale: 0.9 }}
                    animate={{ opacity: 1, scale: 1 }}
                    className="glass-panel p-10 w-full max-w-[420px] text-center relative z-10"
                >
                    <div className="w-20 h-20 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-8 border border-primary/20 shadow-[0_0_30px_rgba(0,255,157,0.15)]">
                        <CheckCircle2 className="text-primary w-10 h-10" />
                    </div>
                    <h1 className="text-3xl font-outfit font-bold text-white mb-4">
                        Request Sent
                    </h1>
                    <p className="text-text-dim mb-8">
                        Your registration request for{" "}
                        <span className="text-white font-bold">{email}</span>{" "}
                        has been submitted. Please wait for an administrator to
                        approve your account.
                    </p>
                    <Link
                        to="/login"
                        className="btn-primary w-full flex items-center justify-center gap-2 h-14 text-base"
                    >
                        Return to Login
                    </Link>
                </motion.div>
            </div>
        );
    }

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
                        <UserPlus className="text-primary w-10 h-10" />
                    </div>
                </div>

                <div className="text-center mb-8">
                    <h1 className="text-3xl font-outfit font-bold text-white tracking-tight mb-2">
                        Member Signup
                    </h1>
                    <p className="text-text-dim text-sm">
                        Create a secure account on our platform
                    </p>
                </div>

                <form onSubmit={handleSignup} className="space-y-6">
                    <div className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="relative group">
                                <label className="text-[10px] font-bold text-text-dim uppercase tracking-widest ml-1 mb-2 block">
                                    First Name
                                </label>
                                <input
                                    type="text"
                                    placeholder="John"
                                    className="input-field"
                                    value={firstName}
                                    onChange={(e) => setFirstName(e.target.value)}
                                    required
                                />
                            </div>
                            <div className="relative group">
                                <label className="text-[10px] font-bold text-text-dim uppercase tracking-widest ml-1 mb-2 block">
                                    Last Name
                                </label>
                                <input
                                    type="text"
                                    placeholder="Doe"
                                    className="input-field"
                                    value={lastName}
                                    onChange={(e) => setLastName(e.target.value)}
                                    required
                                />
                            </div>
                        </div>
                        <div className="relative group">
                            <label className="text-[10px] font-bold text-text-dim uppercase tracking-widest ml-1 mb-2 block">
                                Email Address
                            </label>
                            <input
                                type="email"
                                placeholder="name@network.app"
                                className="input-field"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                            />
                        </div>
                        <div className="relative group">
                            <label className="text-[10px] font-bold text-text-dim uppercase tracking-widest ml-1 mb-2 block">
                                Referral Code (Optional)
                            </label>
                            <input
                                type="text"
                                placeholder="8-CHARACTER-CODE"
                                className="input-field font-mono uppercase tracking-widest"
                                value={referralCode}
                                onChange={(e) =>
                                    setReferralCode(
                                        e.target.value.toUpperCase(),
                                    )
                                }
                            />
                        </div>
                    </div>

                    <button
                        disabled={loading || !email}
                        className="btn-primary w-full flex items-center justify-center gap-2 h-14 text-base"
                    >
                        {loading ? (
                            <Loader2 className="animate-spin w-5 h-5" />
                        ) : (
                            <>
                                Request Approval <ArrowRight size={18} />
                            </>
                        )}
                    </button>

                    <div className="text-center">
                        <Link
                            to="/login"
                            className="text-sm text-text-dim hover:text-white transition-colors"
                        >
                            Already registered?{" "}
                            <span className="text-primary font-bold">
                                Login here
                            </span>
                        </Link>
                    </div>
                </form>

                <div className="mt-8 pt-6 border-t border-white/5 flex items-start gap-3">
                    <ShieldAlert className="w-5 h-5 text-text-dim shrink-0" />
                    <p className="text-xs text-text-dim leading-relaxed">
                        Registration requests are manually reviewed by
                        administrators to ensure platform security.
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

export default Signup;
