import {
    Archive,
    CheckCircle,
    Edit2,
    ExternalLink,
    Newspaper,
    Trash2,
    X,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import api from "../../lib/api";

interface NewsItem {
    id: string;
    title: string;
    description: string;
    link?: string;
    status: "PUBLISHED" | "ARCHIVED";
    createdAt: string;
}

const AdminNews: React.FC = () => {
    const [news, setNews] = useState<NewsItem[]>([]);
    const [title, setTitle] = useState("");
    const [description, setDescription] = useState("");
    const [link, setLink] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const [editId, setEditId] = useState<string | null>(null);

    const fetchNews = async () => {
        try {
            const { data } = await api.get("/news/admin");
            setNews(data);
        } catch (e) {
            console.error(e);
        }
    };

    useEffect(() => {
        fetchNews();
    }, []);

    const handleAddOrEditNews = async () => {
        if (!title || !description) return;
        setIsLoading(true);
        try {
            if (editId) {
                await api.patch(`/news/${editId}`, {
                    title,
                    description,
                    link,
                });
                setEditId(null);
            } else {
                await api.post("/news", { title, description, link });
            }
            setTitle("");
            setDescription("");
            setLink("");
            fetchNews();
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    };

    const handleToggleStatus = async (
        id: string,
        currentStatus: "PUBLISHED" | "ARCHIVED",
    ) => {
        const status = currentStatus === "PUBLISHED" ? "ARCHIVED" : "PUBLISHED";
        try {
            await api.patch(`/news/${id}`, { status });
            fetchNews();
        } catch (e) {
            console.error(e);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm("Are you sure you want to delete this news item?")) return;
        try {
            await api.delete(`/news/${id}`);
            fetchNews();
        } catch (e) {
            console.error(e);
        }
    };

    const startEdit = (item: NewsItem) => {
        setEditId(item.id);
        setTitle(item.title);
        setDescription(item.description);
        setLink(item.link || "");
        window.scrollTo({ top: 0, behavior: "smooth" });
    };

    const cancelEdit = () => {
        setEditId(null);
        setTitle("");
        setDescription("");
        setLink("");
    };

    return (
        <div className="space-y-10 max-w-5xl">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    News & Broadcasts
                </h1>
                <p className="text-text-dim max-w-2xl font-medium">
                    Create and control informational messages displayed to end
                    users on their application dashboard.
                </p>
            </header>

            <section className="glass p-8 space-y-6">
                <h3 className="text-xl font-outfit font-bold text-white flex items-center justify-between">
                    <span className="flex items-center gap-3">
                        <Newspaper className="text-primary" />{" "}
                        {editId ? "Edit News Post" : "Compose New Post"}
                    </span>
                    {editId && (
                        <button
                            onClick={cancelEdit}
                            className="text-xs bg-white/10 hover:bg-white/20 text-text-dim hover:text-white px-3 py-2 rounded-xl flex items-center gap-2 transition-all font-bold"
                        >
                            <X size={14} /> Cancel Edit
                        </button>
                    )}
                </h3>
                <div className="flex flex-col gap-4">
                    <input
                        type="text"
                        placeholder="News Title"
                        className="w-full bg-white/5 border border-white/10 rounded-2xl py-4 px-6 text-sm font-bold text-white focus:outline-none focus:border-accent-blue transition-all"
                        value={title}
                        onChange={(e) => setTitle(e.target.value)}
                    />
                    <textarea
                        placeholder="Enter description..."
                        rows={4}
                        className="w-full bg-white/5 border border-white/10 rounded-2xl py-4 px-6 text-sm font-medium text-white focus:outline-none focus:border-accent-blue transition-all resize-none"
                        value={description}
                        onChange={(e) => setDescription(e.target.value)}
                    />
                    <input
                        type="url"
                        placeholder="Optional Link (e.g. https://example.com)"
                        className="w-full bg-white/5 border border-white/10 rounded-2xl py-4 px-6 text-sm font-medium text-white focus:outline-none focus:border-accent-blue transition-all"
                        value={link}
                        onChange={(e) => setLink(e.target.value)}
                    />
                    <div className="flex justify-end">
                        <button
                            onClick={handleAddOrEditNews}
                            disabled={isLoading || !title || !description}
                            className="px-8 py-4 rounded-2xl bg-primary text-bg-dark font-black uppercase tracking-widest text-xs shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
                        >
                            {isLoading
                                ? "Processing..."
                                : editId
                                  ? "Save News"
                                  : "Publish News"}
                        </button>
                    </div>
                </div>
            </section>

            <section className="space-y-4">
                <h3 className="text-lg font-outfit font-bold text-white mb-4">
                    Post History
                </h3>
                {news.length === 0 ? (
                    <div className="glass p-10 text-center text-text-dim">
                        No articles published yet. Draft one above.
                    </div>
                ) : (
                    <div className="grid grid-cols-1 gap-4">
                        {news.map((item) => {
                            const isPublished = item.status === "PUBLISHED";
                            return (
                                <div
                                    key={item.id}
                                    className={`glass p-6 flex flex-col md:flex-row items-start justify-between gap-6 transition-all ${!isPublished ? "opacity-60 grayscale" : ""}`}
                                >
                                    <div className="flex items-start gap-5 w-full md:w-auto flex-1">
                                        <div
                                            className={`w-12 h-12 rounded-xl flex items-center justify-center border-2 shadow-xl shrink-0 ${isPublished ? "bg-primary/10 border-primary/20 shadow-primary/10 text-primary" : "bg-text-dim/10 border-text-dim/20 text-text-dim"}`}
                                        >
                                            <Newspaper size={24} />
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center gap-3 flex-wrap">
                                                {isPublished ? (
                                                    <span className="text-[10px] bg-primary/20 text-primary px-2.5 py-1 rounded-lg font-bold uppercase tracking-wider flex items-center gap-1">
                                                        <CheckCircle
                                                            size={10}
                                                        />{" "}
                                                        Published
                                                    </span>
                                                ) : (
                                                    <span className="text-[10px] bg-red-500/20 text-red-400 px-2.5 py-1 rounded-lg font-bold uppercase tracking-wider flex items-center gap-1">
                                                        <Archive size={10} />{" "}
                                                        Archived
                                                    </span>
                                                )}
                                                <span className="text-text-dim text-[11px] font-bold">
                                                    {new Date(
                                                        item.createdAt,
                                                    ).toLocaleDateString(
                                                        undefined,
                                                        {
                                                            year: "numeric",
                                                            month: "short",
                                                            day: "numeric",
                                                        },
                                                    )}
                                                </span>
                                            </div>
                                            <h4 className="text-white font-outfit font-bold text-xl mt-3">
                                                {item.title}
                                            </h4>
                                            <p className="text-text-dim font-medium text-sm mt-2 whitespace-pre-wrap leading-relaxed">
                                                {item.description}
                                            </p>
                                            {item.link && (
                                                <a
                                                    href={item.link}
                                                    target="_blank"
                                                    rel="noreferrer"
                                                    className="inline-flex items-center gap-2 text-xs font-bold text-primary hover:underline mt-4 bg-primary/5 px-3 py-1.5 rounded-lg border border-primary/10"
                                                >
                                                    <ExternalLink size={12} />{" "}
                                                    {item.link}
                                                </a>
                                            )}
                                        </div>
                                    </div>
                                    <div className="flex items-center gap-3 w-full md:w-auto justify-end shrink-0 md:self-center">
                                        <button
                                            onClick={() => startEdit(item)}
                                            className="p-3 rounded-xl bg-white/5 hover:bg-white/10 transition-colors text-white"
                                            title="Edit Post"
                                        >
                                            <Edit2 size={18} />
                                        </button>
                                        <button
                                            onClick={() =>
                                                handleToggleStatus(
                                                    item.id,
                                                    item.status,
                                                )
                                            }
                                            className={`p-3 rounded-xl transition-colors ${isPublished ? "bg-red-500/10 text-red-500 hover:bg-red-500/20" : "bg-primary/10 text-primary hover:bg-primary/20"}`}
                                            title={
                                                isPublished
                                                    ? "Archive Post"
                                                    : "Publish Post"
                                            }
                                        >
                                            <Archive size={18} />
                                        </button>
                                        <button
                                            onClick={() =>
                                                handleDelete(item.id)
                                            }
                                            className="p-3 rounded-xl bg-white/5 hover:bg-red-500/20 hover:text-red-500 transition-colors text-text-dim"
                                            title="Delete Post"
                                        >
                                            <Trash2 size={18} />
                                        </button>
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

export default AdminNews;
