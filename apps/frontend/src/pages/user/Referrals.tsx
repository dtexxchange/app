import { format } from "date-fns";
import {
    Copy,
    Check,
    Users,
    Gift,
    Share2,
    Activity,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import { useAuth } from "../../context/AuthContext";
import api from "../../lib/api";

const Referrals: React.FC = () => {
    const { user } = useAuth();
    const [referrals, setReferrals] = useState<any[]>([]);
    const [copied, setCopied] = useState(false);
    const [isLoading, setIsLoading] = useState(true);

    const fetchReferrals = async () => {
        try {
            const { data } = await api.get("/users/me/referrals");
            setReferrals(data);
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchReferrals();
    }, []);

    const handleCopy = () => {
        if (!user?.referralCode) return;
        navigator.clipboard.writeText(user.referralCode);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    const referralLink = `${window.location.origin}/signup?ref=${user?.referralCode}`;

    const handleCopyLink = () => {
        navigator.clipboard.writeText(referralLink);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    return (
        <div className="space-y-10">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    Referral Network
                </h1>
                <p className="text-text-dim max-w-2xl font-medium">
                    Invite your friends to the platform and build your network. 
                    Manage your unique referral code and track your successful invites.
                </p>
            </header>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Referral Code Card */}
                <div className="lg:col-span-1 space-y-6">
                    <div className="glass p-8 space-y-8 border-primary/20 bg-primary/2">
                        <div className="flex items-center gap-4">
                            <div className="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center border border-primary/20 shadow-lg shadow-primary/5">
                                <Gift className="text-primary" size={24} />
                            </div>
                            <div>
                                <h3 className="text-lg font-outfit font-bold text-white">Your Reward ID</h3>
                                <p className="text-[10px] font-bold text-primary uppercase tracking-widest">Global Referral Code</p>
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div className="relative group">
                                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                                    <Share2 className="text-white/20 group-focus-within:text-primary transition-colors" size={16} />
                                </div>
                                <div className="w-full bg-black/40 border border-white/10 rounded-2xl py-6 pl-12 pr-4 text-center">
                                    <span className="text-2xl font-mono font-black text-white tracking-[0.2em]">
                                        {user?.referralCode || "--------"}
                                    </span>
                                </div>
                            </div>
                            
                            <button
                                onClick={handleCopy}
                                className="w-full py-4 rounded-2xl bg-white text-bg-dark font-black uppercase text-[10px] tracking-widest hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-3"
                            >
                                {copied ? <Check size={16} /> : <Copy size={16} />}
                                {copied ? "Copied ID" : "Copy Reward ID"}
                            </button>
                        </div>

                        <div className="pt-6 border-t border-white/5">
                            <p className="text-[10px] font-bold text-text-dim uppercase tracking-widest mb-3 block">Quick Share Link</p>
                            <div className="flex items-center gap-2 bg-white/5 rounded-xl p-2 border border-white/10">
                                <span className="flex-1 text-[10px] font-mono text-text-dim truncate pl-2">
                                    {referralLink}
                                </span>
                                <button 
                                    onClick={handleCopyLink}
                                    className="p-2 bg-white/10 rounded-lg hover:bg-white/20 transition-all"
                                >
                                    <Copy size={14} className="text-white" />
                                </button>
                            </div>
                        </div>
                    </div>

                    <div className="glass p-8">
                        <h4 className="text-white font-bold mb-4 font-outfit flex items-center gap-2">
                            <Activity size={18} className="text-primary" />
                            Network Stats
                        </h4>
                        <div className="space-y-4">
                            <div className="flex justify-between items-center py-3 border-b border-white/5">
                                <span className="text-xs text-text-dim font-medium">Total Referrals</span>
                                <span className="text-lg font-outfit font-bold text-white">{referrals.length}</span>
                            </div>
                            <div className="flex justify-between items-center py-3 border-b border-white/5">
                                <span className="text-xs text-text-dim font-medium">Active Members</span>
                                <span className="text-lg font-outfit font-bold text-primary">
                                    {referrals.filter(r => r.status === 'APPROVED').length}
                                </span>
                            </div>
                            <div className="flex justify-between items-center py-3">
                                <span className="text-xs text-text-dim font-medium">Pending Review</span>
                                <span className="text-lg font-outfit font-bold text-accent-blue">
                                    {referrals.filter(r => r.status === 'PENDING_APPROVAL').length}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Referrals List Card */}
                <div className="lg:col-span-2">
                    <div className="glass h-full flex flex-col">
                        <div className="p-8 border-b border-white/5 flex items-center justify-between">
                            <h3 className="text-xl font-outfit font-bold text-white flex items-center gap-3">
                                <Users className="text-text-dim" size={24} /> 
                                Referred Friends
                            </h3>
                            <span className="text-[10px] font-bold text-text-dim uppercase tracking-widest bg-white/5 px-4 py-2 rounded-full border border-white/5">
                                Live Connection
                            </span>
                        </div>

                        <div className="flex-1">
                            {isLoading ? (
                                <div className="flex flex-col items-center justify-center py-32 space-y-4">
                                    <div className="w-10 h-10 border-2 border-primary/20 border-t-primary rounded-full animate-spin" />
                                    <p className="text-xs text-text-dim font-medium animate-pulse">Synchronizing network data...</p>
                                </div>
                            ) : referrals.length === 0 ? (
                                <div className="flex flex-col items-center justify-center py-32 text-center px-10">
                                    <div className="w-20 h-20 bg-white/2 rounded-3xl flex items-center justify-center mb-6 border border-white/5">
                                        <Users className="text-white/10" size={40} />
                                    </div>
                                    <h4 className="text-white font-bold mb-2 font-outfit text-lg">No Referrals Yet</h4>
                                    <p className="text-text-dim text-sm max-w-xs leading-relaxed">
                                        Share your referral code with friends to start building your network and earning rewards.
                                    </p>
                                </div>
                            ) : (
                                <div className="overflow-x-auto">
                                    <table className="w-full text-left">
                                        <thead>
                                            <tr className="bg-white/2 text-[10px] font-black text-text-dim uppercase tracking-widest border-b border-white/5">
                                                <th className="px-8 py-5">Network Identity</th>
                                                <th className="px-8 py-5">Status</th>
                                                <th className="px-8 py-5 text-right">Join Date</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-white/5">
                                            {referrals.map((r) => (
                                                <tr key={r.id} className="group hover:bg-white/2 transition-colors">
                                                    <td className="px-8 py-6">
                                                        <div className="flex items-center gap-4">
                                                            <div className="w-10 h-10 rounded-xl bg-accent-blue/10 flex items-center justify-center text-accent-blue font-bold text-sm border border-accent-blue/20">
                                                                {(r.firstName?.[0] || r.email[0]).toUpperCase()}
                                                            </div>
                                                            <div>
                                                                <div className="text-sm font-bold text-white mb-0.5">
                                                                    {r.firstName || r.lastName ? `${r.firstName || ''} ${r.lastName || ''}`.trim() : r.email}
                                                                </div>
                                                                <div className="text-[10px] text-text-dim font-mono uppercase tracking-tighter">
                                                                    ID: {r.id.substring(0, 8).toUpperCase()}
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </td>
                                                    <td className="px-8 py-6">
                                                        <span className={`px-3 py-1 rounded-lg text-[9px] font-black uppercase tracking-widest border ${
                                                            r.status === 'APPROVED' 
                                                                ? 'bg-primary/5 text-primary border-primary/20' 
                                                                : r.status === 'PENDING_APPROVAL' 
                                                                    ? 'bg-accent-blue/5 text-accent-blue border-accent-blue/20'
                                                                    : 'bg-red-500/5 text-red-500 border-red-500/20'
                                                        }`}>
                                                            {r.status.replace('_', ' ')}
                                                        </span>
                                                    </td>
                                                    <td className="px-8 py-6 text-right">
                                                        <div className="text-xs text-text-dim font-medium">
                                                            {format(new Date(r.createdAt), "MMM dd, yyyy")}
                                                        </div>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Referrals;
