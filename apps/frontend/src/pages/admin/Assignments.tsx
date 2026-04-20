import React, { useEffect, useState } from "react";
import api from "../../lib/api";
import { QrCode, Clock } from "lucide-react";

interface Assignment {
    id?: string;
    user: {
        firstName?: string;
        lastName?: string;
        email: string;
    };
    wallet: {
        name?: string;
        network: string;
        address: string;
    };
    expiresAt: string;
}

const LiveTimer: React.FC<{ expiresAt: string }> = ({ expiresAt }) => {
    const [timeLeft, setTimeLeft] = useState<number>(0);

    useEffect(() => {
        const calculateTimeLeft = () => {
            const diffMs = new Date(expiresAt).getTime() - new Date().getTime();
            return Math.max(0, Math.floor(diffMs / 1000));
        };

        setTimeLeft(calculateTimeLeft());

        const timer = setInterval(() => {
            const left = calculateTimeLeft();
            setTimeLeft(left);
            if (left <= 0) clearInterval(timer);
        }, 1000);

        return () => clearInterval(timer);
    }, [expiresAt]);

    const formatTime = (totalSeconds: number) => {
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        return `${minutes.toString().padStart(2, "0")}:${seconds
            .toString()
            .padStart(2, "0")}`;
    };

    const getColorClass = () => {
        if (timeLeft <= 0) return "text-red-400";
        if (timeLeft < 60) return "text-red-400";
        if (timeLeft < 300) return "text-orange-400";
        return "text-accent-blue";
    };

    const getBgClass = () => {
        if (timeLeft <= 0) return "bg-red-400/10 border-red-400/20";
        if (timeLeft < 60) return "bg-red-400/10 border-red-400/20";
        if (timeLeft < 300) return "bg-orange-400/10 border-orange-400/20";
        return "bg-accent-blue/10 border-accent-blue/20";
    };

    return (
        <div
            className={`${getBgClass()} border px-3 py-1.5 rounded-xl flex items-center gap-2`}
        >
            <Clock size={14} className={getColorClass()} />
            <span
                className={`${getColorClass()} text-[11px] font-bold tracking-widest`}
            >
                {timeLeft <= 0 ? "EXPIRED" : `${formatTime(timeLeft)} LEFT`}
            </span>
        </div>
    );
};

const Assignments: React.FC = () => {
    const [assignments, setAssignments] = useState<Assignment[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const fetchAssignments = async () => {
            try {
                const { data } = await api.get("/settings/admin/assignments");
                setAssignments(data);
            } catch (e) {
                console.error(e);
            } finally {
                setIsLoading(false);
            }
        };
        fetchAssignments();
    }, []);

    return (
        <div className="space-y-10 max-w-5xl">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    Live QR Views
                </h1>
                <p className="text-text-dim max-w-2xl font-medium">
                    Monitor active wallet assignments temporarily assigned to users.
                </p>
            </header>

            <section className="space-y-4">
                {isLoading ? (
                    <div className="glass p-10 flex justify-center items-center">
                        <div className="w-8 h-8 border-4 border-primary/20 border-t-primary rounded-full animate-spin" />
                    </div>
                ) : assignments.length === 0 ? (
                    <div className="glass p-10 text-center text-text-dim flex flex-col items-center justify-center gap-4 py-20">
                        <QrCode size={48} className="text-white/10" />
                        <p>No active QR views matching users.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {assignments.map((a, i) => {
                            const nameStr =
                                a.user.firstName || a.user.lastName
                                    ? `${a.user.firstName || ""} ${a.user.lastName || ""}`.trim()
                                    : a.user.email;
                            const initial = nameStr.charAt(0).toUpperCase();

                            return (
                                <div
                                    key={a.id || i}
                                    className="glass p-6 space-y-4 hover:border-primary/30 transition-all group"
                                >
                                    <div className="flex items-start justify-between">
                                        <div className="flex items-center gap-4">
                                            <div className="w-12 h-12 rounded-xl bg-primary/10 text-primary flex items-center justify-center font-bold font-outfit text-xl border border-primary/20 shadow-lg shadow-primary/5">
                                                {initial}
                                            </div>
                                            <div>
                                                <h3 className="text-white font-bold font-outfit truncate max-w-[200px] text-lg">
                                                    {nameStr}
                                                </h3>
                                                <p className="text-text-dim text-xs truncate max-w-[200px]">
                                                    {a.user.email}
                                                </p>
                                            </div>
                                        </div>
                                        <LiveTimer expiresAt={a.expiresAt} />
                                    </div>

                                    <div className="pt-5 mt-2 border-t border-white/5 space-y-4">
                                        <div className="flex justify-between items-center">
                                            <span className="text-text-dim font-bold tracking-widest uppercase text-[10px]">
                                                Assigned Wallet
                                            </span>
                                            <span className="text-white font-bold font-outfit text-sm bg-white/5 px-2 py-1 rounded">
                                                {a.wallet.name?.toUpperCase() ||
                                                    a.wallet.network}
                                            </span>
                                        </div>
                                        <div className="flex justify-between items-center gap-4">
                                            <span className="text-text-dim font-bold tracking-widest uppercase text-[10px] shrink-0">
                                                Address
                                            </span>
                                            <span className="text-primary font-mono font-bold truncate text-sm">
                                                {a.wallet.address}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </section>
        </div>
    );
};

export default Assignments;
