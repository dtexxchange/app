import {
    AlertCircle,
    CheckCircle2,
    Key,
    Mail,
    ShieldAlert,
    ShieldCheck,
} from "lucide-react";
import React, { useState, useEffect } from "react";
import { useAuth } from "../../context/AuthContext";
import PasscodeModal from "../../components/PasscodeModal";
import api from "../../lib/api";

const Profile: React.FC = () => {
    const { user } = useAuth();
    const [isPasscodeModalOpen, setIsPasscodeModalOpen] = useState(false);
    const [hasPasscode, setHasPasscode] = useState(false);

    useEffect(() => {
        const checkStatus = async () => {
            const { data } = await api.get("/users/me");
            setHasPasscode(data.passcode !== null);
        };
        checkStatus();
    }, []);

    return (
        <div className="space-y-10 max-w-4xl">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    Security & Identity
                </h1>
                <p className="text-text-dim max-w-xl font-medium">
                    Manage your verified platform identity and security
                    parameters.
                </p>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                {/* Profile Card */}
                <div className="md:col-span-2 space-y-8">
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
                                        Authorize your settlements and secure
                                        your assets.
                                    </p>
                                </div>
                            </div>
                            <button
                                onClick={() => setIsPasscodeModalOpen(true)}
                                className="px-6 py-3 rounded-xl bg-primary text-bg-dark font-black text-[10px] uppercase tracking-widest hover:scale-105 transition-all"
                            >
                                Setup Security
                            </button>
                        </div>
                    )}

                    <section className="glass p-10 space-y-8">
                        <div className="flex items-center gap-6">
                            <div className="w-20 h-20 rounded-3xl bg-accent-blue/10 border-2 border-accent-blue/20 flex items-center justify-center text-3xl font-bold text-accent-blue shadow-2xl shadow-accent-blue/10">
                                {user?.email[0].toUpperCase()}
                            </div>
                            <div>
                                <h3 className="text-2xl font-outfit font-bold text-white mb-1">
                                    {user?.email}
                                </h3>
                                <div className="flex items-center gap-2">
                                    <span className="px-2 py-0.5 rounded bg-primary/20 text-primary text-[10px] font-black uppercase tracking-widest">
                                        Verified Member
                                    </span>
                                    <span className="px-2 py-0.5 rounded bg-white/5 text-text-dim text-[10px] font-black uppercase tracking-widest">
                                        {user?.role} Access
                                    </span>
                                </div>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-white/5">
                            <div>
                                <label className="text-[10px] font-black text-white/40 uppercase tracking-widest mb-3 block">
                                    Primary Email
                                </label>
                                <div className="flex items-center gap-3 text-white font-bold">
                                    <Mail
                                        size={16}
                                        className="text-accent-blue"
                                    />
                                    {user?.email}
                                </div>
                            </div>
                            <div>
                                <label className="text-[10px] font-black text-white/40 uppercase tracking-widest mb-3 block">
                                    Identity UID
                                </label>
                                <div className="flex items-center gap-3 text-white font-mono text-xs font-bold">
                                    <Key
                                        size={16}
                                        className="text-accent-blue"
                                    />
                                    {user?.id.toUpperCase()}
                                </div>
                            </div>
                        </div>
                    </section>

                    <section className="glass p-10 space-y-6">
                        <h4 className="text-lg font-outfit font-bold text-white flex items-center gap-3">
                            <ShieldCheck className="text-primary" />{" "}
                            Multi-Factor Authentication
                        </h4>
                        <p className="text-sm text-text-dim leading-relaxed font-medium capitalize">
                            Platform security is managed via OTP-based verified
                            email access. Physical security keys support coming
                            soon in v2.0.
                        </p>
                        <div className="flex items-center gap-3 text-primary text-xs font-black uppercase tracking-widest bg-primary/5 p-4 rounded-xl border border-primary/10">
                            <CheckCircle2 size={16} /> Identity Protection
                            Active
                        </div>
                    </section>

                    <section className="glass p-10 space-y-6">
                        <div className="flex items-center justify-between">
                            <div className="space-y-1">
                                <h4 className="text-lg font-outfit font-bold text-white flex items-center gap-3">
                                    <Key className="text-accent-blue" />{" "}
                                    Authorization Passcode
                                </h4>
                                <p className="text-sm text-text-dim">
                                    Secures your exchange transactions with a
                                    6-digit PIN.
                                </p>
                            </div>
                            <button
                                onClick={() => setIsPasscodeModalOpen(true)}
                                className="px-6 py-3 rounded-xl border border-white/10 bg-white/5 text-white font-black text-[10px] uppercase tracking-widest hover:bg-white/10 transition-all"
                            >
                                {hasPasscode
                                    ? "Change Passcode"
                                    : "Setup Passcode"}
                            </button>
                        </div>
                    </section>
                </div>

                <PasscodeModal
                    isOpen={isPasscodeModalOpen}
                    onClose={(success) => {
                        setIsPasscodeModalOpen(false);
                        if (success) {
                            window.location.reload(); // Refresh to update hasPasscode status
                        }
                    }}
                    userHasPasscode={hasPasscode}
                />

                {/* Info Sidebar */}
                <div className="space-y-6">
                    <div className="glass p-8 space-y-4">
                        <ShieldAlert className="text-accent-blue" size={24} />
                        <h4 className="text-white font-bold font-outfit">
                            Exchange Security
                        </h4>
                        <p className="text-xs text-text-dim leading-relaxed">
                            Large USDT settlements may require secondary manual
                            verification from the compliance terminal for
                            security reasons.
                        </p>
                    </div>

                    <div className="glass p-8 space-y-4">
                        <AlertCircle className="text-text-dim" size={24} />
                        <h4 className="text-white font-bold font-outfit">
                            E2EE Protocol
                        </h4>
                        <p className="text-xs text-text-dim leading-relaxed">
                            Your bank details are encrypted using RSA-4096
                            before leaving your browser. Even platform
                            administrators cannot view your details without a
                            secure key sync.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Profile;
