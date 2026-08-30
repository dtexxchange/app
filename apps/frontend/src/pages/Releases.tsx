import React, { useEffect, useState } from "react";
import { format } from "date-fns";
import { Download, Smartphone } from "lucide-react";
import api from "../lib/api";

interface AppRelease {
    id: string;
    version: string;
    changes: string | null;
    apkUrl: string | null;
    isActive: boolean;
    createdAt: string;
}

const Releases: React.FC = () => {
    const [releases, setReleases] = useState<AppRelease[]>([]);
    const [latest, setLatest] = useState<AppRelease | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const fetchReleases = async () => {
            try {
                const [latestRes, allRes] = await Promise.all([
                    api.get('/app-releases/latest'),
                    api.get('/app-releases')
                ]);

                if (latestRes.data) {
                    setLatest(latestRes.data);
                }

                if (allRes.data) {
                    setReleases(allRes.data);
                }
            } catch (error) {
                console.error("Failed to fetch releases", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchReleases();
    }, []);

    if (isLoading) {
        return (
            <div className="min-h-screen bg-bg-dark flex items-center justify-center">
                <div className="w-12 h-12 border-4 border-primary/20 border-t-primary rounded-full animate-spin" />
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-bg-dark text-white p-8">
            <div className="max-w-4xl mx-auto space-y-12">
                <div className="text-center space-y-6">
                    <div className="inline-flex items-center justify-center w-20 h-20 bg-primary/10 rounded-3xl border border-primary/20 shadow-[0_0_30px_rgba(0,255,157,0.15)] mb-4">
                        <Smartphone size={40} className="text-primary" />
                    </div>
                    <h1 className="text-5xl font-outfit font-bold">App Releases</h1>
                    <p className="text-text-dim max-w-2xl mx-auto text-lg">
                        Download the latest version of our mobile application to enjoy new features and improvements.
                    </p>
                </div>

                {latest && latest.apkUrl && (
                    <div className="bg-gradient-to-br from-primary/20 to-transparent border border-primary/30 p-8 rounded-3xl text-center shadow-[0_0_50px_rgba(0,255,157,0.05)] relative overflow-hidden group">
                        <div className="absolute inset-0 bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                        <h2 className="text-3xl font-bold font-outfit text-white mb-2 relative z-10">
                            Version {latest.version}
                        </h2>
                        <p className="text-primary font-medium mb-8 relative z-10">Latest Release</p>
                        <a
                            href={`/api${latest.apkUrl}`}
                            download
                            className="inline-flex items-center gap-3 px-8 py-4 bg-primary text-bg-dark font-bold rounded-2xl hover:bg-white transition-all transform hover:scale-105 active:scale-95 relative z-10"
                        >
                            <Download size={24} />
                            Download APK
                        </a>
                    </div>
                )}

                <div className="space-y-6">
                    <h3 className="text-2xl font-bold font-outfit mb-8">Version History</h3>
                    {releases.length === 0 ? (
                        <p className="text-text-dim text-center py-10">No releases found.</p>
                    ) : (
                        <div className="space-y-6">
                            {releases.map((release) => (
                                <div key={release.id} className="bg-white/5 border border-white/10 rounded-2xl p-6 transition-colors hover:bg-white/10">
                                    <div className="flex justify-between items-start mb-4">
                                        <div>
                                            <div className="flex items-center gap-3 mb-1">
                                                <h4 className="text-xl font-bold font-outfit">Version {release.version}</h4>
                                                {release.isActive && (
                                                    <span className="px-3 py-1 bg-primary/20 text-primary text-xs font-bold rounded-full uppercase tracking-wider">
                                                        Active
                                                    </span>
                                                )}
                                            </div>
                                            <p className="text-sm text-text-dim">
                                                Released on {format(new Date(release.createdAt), "PPP")}
                                            </p>
                                        </div>
                                    </div>
                                    {release.changes && (
                                        <div className="mt-4 pt-4 border-t border-white/5">
                                            <p className="text-text-dim font-medium mb-2 text-sm uppercase tracking-wider">What's New</p>
                                            <p className="whitespace-pre-wrap text-white/80">{release.changes}</p>
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default Releases;
