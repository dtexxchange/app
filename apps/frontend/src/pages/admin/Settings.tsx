import { AnimatePresence, motion } from "framer-motion";
import {
    AlertCircle,
    Download,
    History,
    RefreshCw,
    ShieldAlert,
    ShieldCheck,
    Upload,
    MessageCircle,
    Plus,
    Trash2,
    Edit2,
} from "lucide-react";
import React, { useEffect, useState } from "react";
import api from "../../lib/api";
import {
    exportPrivateKey,
    exportPublicKey,
    generateKeyPair,
} from "../../lib/crypto";

const Settings: React.FC = () => {
    const [contacts, setContacts] = useState<any[]>([]);
    const [newContact, setNewContact] = useState({ title: "", platform: "LINK", url: "" });
    const [editingContactId, setEditingContactId] = useState<string | null>(null);
    const [editingContactData, setEditingContactData] = useState({ title: "", platform: "LINK", url: "" });
    const [isLoading, setIsLoading] = useState(false);
    const [alert, setAlert] = useState<{
        title: string;
        message: string;
        type: "success" | "error";
    } | null>(null);
    const [hasKeys, setHasKeys] = useState(false);

    const fetchData = async () => {
        try {
            const privKey = localStorage.getItem("admin_private_key");
            setHasKeys(!!privKey);

            const res = await api.get("/settings/support-contacts");
            setContacts(Array.isArray(res.data) ? res.data : []);
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

    const createContact = async () => {
        if (!newContact.title.trim() || !newContact.url.trim()) return;
        setIsLoading(true);
        try {
            await api.post("/settings/admin/support-contacts", newContact);
            setNewContact({ title: "", platform: "LINK", url: "" });
            const res = await api.get("/settings/support-contacts");
            setContacts(Array.isArray(res.data) ? res.data : []);
            setAlert({
                title: "Created",
                message: "Support contact has been added.",
                type: "success",
            });
        } catch (e) {
            setAlert({
                title: "Error",
                message: "Failed to add support contact.",
                type: "error",
            });
        } finally {
            setIsLoading(false);
        }
    };

    const updateContact = async (id: string) => {
        if (!editingContactData.title.trim() || !editingContactData.url.trim()) return;
        setIsLoading(true);
        try {
            await api.patch(`/settings/admin/support-contacts/${id}`, editingContactData);
            setEditingContactId(null);
            const res = await api.get("/settings/support-contacts");
            setContacts(Array.isArray(res.data) ? res.data : []);
            setAlert({
                title: "Updated",
                message: "Support contact has been updated.",
                type: "success",
            });
        } catch (e) {
            setAlert({
                title: "Error",
                message: "Failed to update support contact.",
                type: "error",
            });
        } finally {
            setIsLoading(false);
        }
    };

    const deleteContact = async (id: string) => {
        if (!window.confirm("Are you sure you want to delete this contact?")) return;
        setIsLoading(true);
        try {
            await api.delete(`/settings/admin/support-contacts/${id}`);
            const res = await api.get("/settings/support-contacts");
            setContacts(Array.isArray(res.data) ? res.data : []);
            setAlert({
                title: "Deleted",
                message: "Support contact has been removed.",
                type: "success",
            });
        } catch (e) {
            setAlert({
                title: "Error",
                message: "Failed to delete support contact.",
                type: "error",
            });
        } finally {
            setIsLoading(false);
        }
    };

    const startEditing = (contact: any) => {
        setEditingContactId(contact.id);
        setEditingContactData({
            title: contact.title,
            platform: contact.platform,
            url: contact.url,
        });
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

                    {/* Help & Support */}
                    <section className="glass p-10 space-y-8">
                        <div className="flex items-center gap-5">
                            <div className="w-14 h-14 rounded-2xl flex items-center justify-center border-2 border-primary/20 bg-primary/10 shadow-2xl shadow-primary/10">
                                <MessageCircle className="text-primary" size={28} />
                            </div>
                            <div>
                                <h3 className="text-xl font-outfit font-bold text-white">
                                    Help & Support Channels
                                </h3>
                                <p className="text-[10px] font-bold uppercase tracking-[0.2em] mt-1 text-primary">
                                    Direct Contact CRUD
                                </p>
                            </div>
                        </div>

                        <div className="space-y-6">
                            <p className="text-sm text-text-dim leading-relaxed">
                                Manage the direct support channels (Telegram, WhatsApp, links) shown to users. You can add, edit, or delete as many custom contacts as needed.
                            </p>

                            {/* Active Channels List */}
                            <div className="space-y-4">
                                <h4 className="text-xs font-black uppercase tracking-widest text-text-dim">
                                    Active Contact Channels
                                </h4>
                                {contacts.length === 0 ? (
                                    <p className="text-xs text-text-dim italic">No support channels configured.</p>
                                ) : (
                                    <div className="grid grid-cols-1 gap-4">
                                        {contacts.map((c) => (
                                            <div key={c.id} className="glass p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 border-white/5">
                                                {editingContactId === c.id ? (
                                                    <div className="flex-1 grid grid-cols-1 md:grid-cols-3 gap-4">
                                                        <input
                                                            type="text"
                                                            value={editingContactData.title}
                                                            onChange={(e) => setEditingContactData({ ...editingContactData, title: e.target.value })}
                                                            placeholder="Button Title (e.g. Telegram Support)"
                                                            className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-white text-xs focus:outline-none focus:border-primary"
                                                        />
                                                        <select
                                                            value={editingContactData.platform}
                                                            onChange={(e) => setEditingContactData({ ...editingContactData, platform: e.target.value })}
                                                            className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-white text-xs focus:outline-none focus:border-primary cursor-pointer"
                                                        >
                                                            <option value="TELEGRAM">Telegram</option>
                                                            <option value="WHATSAPP">WhatsApp</option>
                                                            <option value="LINK">General Link</option>
                                                        </select>
                                                        <input
                                                            type="text"
                                                            value={editingContactData.url}
                                                            onChange={(e) => setEditingContactData({ ...editingContactData, url: e.target.value })}
                                                            placeholder="Username, Phone or URL Link"
                                                            className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-white text-xs focus:outline-none focus:border-primary"
                                                        />
                                                    </div>
                                                ) : (
                                                    <div className="flex items-center gap-4">
                                                        <div className={`px-3 py-1.5 rounded-lg text-[9px] font-black tracking-widest uppercase border ${
                                                            c.platform === "TELEGRAM" ? "bg-blue-500/10 border-blue-500/20 text-blue-400" :
                                                            c.platform === "WHATSAPP" ? "bg-green-500/10 border-green-500/20 text-green-400" :
                                                            "bg-primary/10 border-primary/20 text-primary"
                                                        }`}>
                                                            {c.platform}
                                                        </div>
                                                        <div>
                                                            <div className="font-bold text-white text-sm">{c.title}</div>
                                                            <div className="text-[10px] text-text-dim truncate max-w-md">{c.url}</div>
                                                        </div>
                                                    </div>
                                                )}

                                                <div className="flex items-center gap-2">
                                                    {editingContactId === c.id ? (
                                                        <>
                                                            <button
                                                                onClick={() => updateContact(c.id)}
                                                                className="px-4 py-2 rounded-lg bg-primary text-bg-dark font-bold text-[10px] uppercase tracking-widest hover:scale-105 transition-all"
                                                            >
                                                                Save
                                                            </button>
                                                            <button
                                                                onClick={() => setEditingContactId(null)}
                                                                className="px-4 py-2 rounded-lg border border-white/10 text-white font-bold text-[10px] uppercase tracking-widest hover:bg-white/5 transition-all"
                                                            >
                                                                Cancel
                                                            </button>
                                                        </>
                                                    ) : (
                                                        <>
                                                            <button
                                                                onClick={() => startEditing(c)}
                                                                className="p-2 hover:bg-white/5 rounded-lg text-text-dim hover:text-white transition-colors"
                                                            >
                                                                <Edit2 size={16} />
                                                            </button>
                                                            <button
                                                                onClick={() => deleteContact(c.id)}
                                                                className="p-2 hover:bg-white/5 rounded-lg text-red-400/80 hover:text-red-400 transition-colors"
                                                            >
                                                                <Trash2 size={16} />
                                                            </button>
                                                        </>
                                                    )}
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>

                            {/* Create New Channel */}
                            <div className="space-y-4 pt-4 border-t border-white/5">
                                <h4 className="text-xs font-black uppercase tracking-widest text-text-dim flex items-center gap-2">
                                    <Plus size={16} className="text-primary" /> Create Support Channel
                                </h4>

                                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black uppercase tracking-widest text-text-dim">Title</label>
                                        <input
                                            type="text"
                                            value={newContact.title}
                                            onChange={(e) => setNewContact({ ...newContact, title: e.target.value })}
                                            placeholder="e.g. Email Helpline"
                                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white text-xs focus:outline-none focus:border-primary"
                                        />
                                    </div>

                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black uppercase tracking-widest text-text-dim">Platform</label>
                                        <select
                                            value={newContact.platform}
                                            onChange={(e) => setNewContact({ ...newContact, platform: e.target.value })}
                                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white text-xs focus:outline-none focus:border-primary cursor-pointer"
                                        >
                                            <option value="TELEGRAM">Telegram</option>
                                            <option value="WHATSAPP">WhatsApp</option>
                                            <option value="LINK">General Link</option>
                                        </select>
                                    </div>

                                    <div className="space-y-2">
                                        <label className="text-[10px] font-black uppercase tracking-widest text-text-dim">Redirect Address / Handle</label>
                                        <input
                                            type="text"
                                            value={newContact.url}
                                            onChange={(e) => setNewContact({ ...newContact, url: e.target.value })}
                                            placeholder="e.g. @support or +123... or https://..."
                                            className="w-full bg-white/5 border border-white/10 rounded-xl px-4 py-3 text-white text-xs focus:outline-none focus:border-primary"
                                        />
                                    </div>
                                </div>

                                <button
                                    onClick={createContact}
                                    disabled={isLoading || !newContact.title.trim() || !newContact.url.trim()}
                                    className="px-6 py-4 rounded-xl bg-primary text-bg-dark font-black uppercase text-[10px] tracking-widest hover:scale-105 transition-all disabled:opacity-50"
                                >
                                    Add New Channel
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
