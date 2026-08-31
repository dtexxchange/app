import React, { useEffect, useState, useRef } from "react";
import { format } from "date-fns";
import { Upload, Smartphone, Loader2, Plus, Trash2 } from "lucide-react";
import api from "../../lib/api";

interface AppRelease {
    id: string;
    version: string;
    changes: string | null;
    apkUrl: string | null;
    isActive: boolean;
    createdAt: string;
}

const AppReleases: React.FC = () => {
    const [releases, setReleases] = useState<AppRelease[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isUploading, setIsUploading] = useState(false);

    // Form state
    const [version, setVersion] = useState("");
    const [changes, setChanges] = useState("");
    const [file, setFile] = useState<File | null>(null);
    const [isDragging, setIsDragging] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const fetchReleases = async () => {
        setIsLoading(true);
        try {
            const res = await api.get('/app-releases');
            setReleases(res.data);
        } catch (error) {
            console.error("Failed to fetch releases", error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchReleases();
    }, []);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const selected = e.target.files[0];
            if (selected.name.toLowerCase().endsWith('.apk')) {
                setFile(selected);
            } else {
                alert("Please select an .apk file");
                if (fileInputRef.current) fileInputRef.current.value = '';
            }
        }
    };

    const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(true);
    };

    const handleDragLeave = (e: React.DragEvent<HTMLDivElement>) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(false);
    };

    const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
        e.preventDefault();
        e.stopPropagation();
        setIsDragging(false);
        if (e.dataTransfer.files && e.dataTransfer.files[0]) {
            const droppedFile = e.dataTransfer.files[0];
            if (droppedFile.name.toLowerCase().endsWith('.apk')) {
                setFile(droppedFile);
            } else {
                alert("Please drop a valid .apk file");
            }
        }
    };

    const handleUpload = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!file || !version) return;

        setIsUploading(true);
        const formData = new FormData();
        formData.append('file', file);
        formData.append('version', version);
        formData.append('changes', changes);

        try {
            await api.post('/app-releases', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            });

            setVersion("");
            setChanges("");
            setFile(null);
            if (fileInputRef.current) fileInputRef.current.value = '';
            await fetchReleases();
        } catch (error) {
            console.error("Upload error", error);
            alert("Error uploading release");
        } finally {
            setIsUploading(false);
        }
    };

    return (
        <div className="space-y-8">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-3xl font-outfit font-bold text-white mb-2">
                        Mobile App Releases
                    </h1>
                    <p className="text-text-dim">
                        Manage and publish new versions of the mobile application.
                    </p>
                </div>
                <div className="w-12 h-12 bg-primary/10 rounded-2xl flex items-center justify-center border border-primary/20 shadow-[0_0_20px_rgba(0,255,157,0.1)]">
                    <Smartphone className="text-primary" size={24} />
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Upload Form */}
                <div className="lg:col-span-1">
                    <div className="bg-white/5 border border-white/10 rounded-3xl p-6 sticky top-24">
                        <h2 className="text-xl font-bold font-outfit text-white mb-6 flex items-center gap-2">
                            <Plus size={20} className="text-primary" />
                            New Release
                        </h2>
                        <form onSubmit={handleUpload} className="space-y-5">
                            <div>
                                <label className="block text-sm font-medium text-text-dim mb-2">Version Number</label>
                                <input
                                    type="text"
                                    required
                                    placeholder="e.g. 1.0.5"
                                    value={version}
                                    onChange={(e) => setVersion(e.target.value)}
                                    className="w-full bg-bg-dark border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary/50 transition-colors"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-text-dim mb-2">APK File</label>
                                <div
                                    className={`border-2 border-dashed rounded-xl p-6 text-center cursor-pointer transition-all duration-200 ${isDragging
                                            ? 'border-primary bg-primary/15 scale-[1.01]'
                                            : file
                                                ? 'border-primary/50 bg-primary/5 hover:border-primary'
                                                : 'border-white/20 hover:border-white/40 hover:bg-white/2'
                                        }`}
                                    onClick={() => fileInputRef.current?.click()}
                                    onDragEnter={handleDragOver}
                                    onDragOver={handleDragOver}
                                    onDragLeave={handleDragLeave}
                                    onDrop={handleDrop}
                                >
                                    <input
                                        type="file"
                                        accept=".apk"
                                        ref={fileInputRef}
                                        onChange={handleFileChange}
                                        className="hidden"
                                    />
                                    {file ? (
                                        <div className="space-y-2">
                                            <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center mx-auto">
                                                <Upload size={20} className="text-primary" />
                                            </div>
                                            <p className="text-white font-medium text-sm truncate">{file.name}</p>
                                            <p className="text-xs text-text-dim">
                                                {(file.size / (1024 * 1024)).toFixed(2)} MB • Click or drag to replace
                                            </p>
                                        </div>
                                    ) : isDragging ? (
                                        <div className="space-y-2">
                                            <div className="w-10 h-10 bg-primary/20 rounded-full flex items-center justify-center mx-auto animate-bounce">
                                                <Upload size={20} className="text-primary" />
                                            </div>
                                            <p className="text-primary text-sm font-medium">Drop the APK file here</p>
                                        </div>
                                    ) : (
                                        <div className="space-y-2">
                                            <Upload size={24} className="text-text-dim mx-auto mb-2" />
                                            <p className="text-text-dim text-sm">Click to select or drag & drop APK</p>
                                        </div>
                                    )}
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-text-dim mb-2">Release Notes / Changes</label>
                                <textarea
                                    rows={4}
                                    placeholder="What's new in this version?"
                                    value={changes}
                                    onChange={(e) => setChanges(e.target.value)}
                                    className="w-full bg-bg-dark border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary/50 transition-colors resize-none"
                                />
                            </div>

                            <button
                                type="submit"
                                disabled={isUploading || !file || !version}
                                className="w-full py-4 bg-primary text-bg-dark font-bold rounded-xl hover:bg-white transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                            >
                                {isUploading ? (
                                    <>
                                        <Loader2 size={20} className="animate-spin" />
                                        Uploading...
                                    </>
                                ) : (
                                    <>
                                        <Upload size={20} />
                                        Publish Release
                                    </>
                                )}
                            </button>
                        </form>
                    </div>
                </div>

                {/* History List */}
                <div className="lg:col-span-2">
                    <div className="bg-white/5 border border-white/10 rounded-3xl p-6">
                        <h2 className="text-xl font-bold font-outfit text-white mb-6">Release History</h2>

                        {isLoading ? (
                            <div className="flex justify-center py-12">
                                <Loader2 size={32} className="text-primary animate-spin" />
                            </div>
                        ) : releases.length === 0 ? (
                            <div className="text-center py-12 border border-dashed border-white/10 rounded-2xl">
                                <p className="text-text-dim">No releases found. Upload your first APK.</p>
                            </div>
                        ) : (
                            <div className="space-y-4">
                                {releases.map((release) => (
                                    <div key={release.id} className="bg-bg-dark/50 border border-white/5 rounded-2xl p-5 hover:border-white/10 transition-colors">
                                        <div className="flex justify-between items-start">
                                            <div>
                                                <div className="flex items-center gap-3 mb-2">
                                                    <span className="text-lg font-bold text-white">v{release.version}</span>
                                                    {release.isActive ? (
                                                        <span className="px-2.5 py-1 bg-primary/20 text-primary text-[10px] font-bold rounded-full uppercase tracking-wider">
                                                            Active
                                                        </span>
                                                    ) : (
                                                        <span className="px-2.5 py-1 bg-white/10 text-text-dim text-[10px] font-bold rounded-full uppercase tracking-wider">
                                                            Archived
                                                        </span>
                                                    )}
                                                </div>
                                                <p className="text-xs text-text-dim mb-4">
                                                    Released {format(new Date(release.createdAt), "PPp")}
                                                </p>
                                                {release.changes && (
                                                    <div className="bg-white/5 p-3 rounded-lg">
                                                        <p className="text-xs text-white/70 whitespace-pre-wrap">{release.changes}</p>
                                                    </div>
                                                )}
                                            </div>
                                            {!release.isActive && !release.apkUrl && (
                                                <div className="text-xs text-red-400/80 bg-red-400/10 px-3 py-1 rounded-full flex items-center gap-1">
                                                    <Trash2 size={12} />
                                                    File Deleted
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AppReleases;
