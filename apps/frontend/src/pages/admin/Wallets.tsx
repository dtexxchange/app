import React, { useEffect, useState } from "react";
import api from "../../lib/api";
import { Wallet, Plus, Trash2, Power, Copy, Check } from "lucide-react";

interface GlobalWallet {
    id: string;
    name?: string;
    address: string;
    network: string;
    isActive: boolean;
}

const Wallets: React.FC = () => {
    const [wallets, setWallets] = useState<GlobalWallet[]>([]);
    const [address, setAddress] = useState("");
    const [name, setName] = useState("");
    const [network, setNetwork] = useState("TRC20");
    const [isLoading, setIsLoading] = useState(false);
    const [copiedId, setCopiedId] = useState<string | null>(null);

    const fetchWallets = async () => {
        try {
            const { data } = await api.get("/settings/admin/wallets");
            setWallets(data);
        } catch (e) {
            console.error(e);
        }
    };

    useEffect(() => {
        fetchWallets();
    }, []);

    const handleAddWallet = async () => {
        if (!address) return;
        setIsLoading(true);
        try {
            await api.post("/settings/admin/wallets", { address, network, name });
            setAddress("");
            setName("");
            fetchWallets();
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    };

    const handleToggleStatus = async (id: string, currentStatus: boolean) => {
        try {
            await api.patch(`/settings/admin/wallets/${id}`, { isActive: !currentStatus });
            fetchWallets();
        } catch (e) {
            console.error(e);
        }
    };

    const handleDelete = async (id: string) => {
        try {
            await api.delete(`/settings/admin/wallets/${id}`);
            fetchWallets();
        } catch (e) {
            console.error(e);
        }
    };

    const handleCopy = (address: string, id: string) => {
        navigator.clipboard.writeText(address);
        setCopiedId(id);
        setTimeout(() => setCopiedId(null), 2000);
    };

    return (
        <div className="space-y-10 max-w-5xl">
            <header>
                <h1 className="text-4xl font-outfit font-bold text-white mb-2">
                    Settlement Wallets
                </h1>
                <p className="text-text-dim max-w-2xl font-medium">
                    Manage global treasury addresses for user deposits. Active wallets will be displayed to users.
                </p>
            </header>

            <section className="glass p-8 space-y-6">
                <h3 className="text-xl font-outfit font-bold text-white flex items-center gap-3">
                    <Plus className="text-primary" /> Add New Wallet
                </h3>
                <div className="flex gap-4 items-center flex-wrap">
                    <input
                        type="text"
                        placeholder="Wallet Label (e.g. Binance Main)"
                        className="flex-1 min-w-[200px] bg-white/5 border border-white/10 rounded-2xl py-4 px-6 text-sm font-bold text-white focus:outline-none focus:border-accent-blue transition-all"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                    />
                    <input
                        type="text"
                        placeholder="Wallet Address"
                        className="flex-[2] min-w-[300px] bg-white/5 border border-white/10 rounded-2xl py-4 px-6 text-sm font-bold text-white focus:outline-none focus:border-accent-blue transition-all"
                        value={address}
                        onChange={(e) => setAddress(e.target.value)}
                    />
                    <select
                        className="bg-white/5 border border-white/10 rounded-2xl py-4 px-6 text-sm font-bold text-white focus:outline-none focus:border-accent-blue transition-all"
                        value={network}
                        onChange={(e) => setNetwork(e.target.value)}
                    >
                        <option value="TRC20" className="text-black">TRC20</option>
                        <option value="ERC20" className="text-black">ERC20</option>
                        <option value="BEP20" className="text-black">BEP20</option>
                        <option value="POLYGON" className="text-black">POLYGON</option>
                    </select>
                    <button
                        onClick={handleAddWallet}
                        disabled={isLoading || !address}
                        className="px-8 py-4 rounded-2xl bg-primary text-bg-dark font-black uppercase tracking-widest text-xs shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
                    >
                        {isLoading ? "Adding..." : "Add Wallet"}
                    </button>
                </div>
            </section>

            <section className="space-y-4">
                <h3 className="text-lg font-outfit font-bold text-white mb-4">
                    Managed Addresses
                </h3>
                {wallets.length === 0 ? (
                    <div className="glass p-10 text-center text-text-dim">
                        No wallets configured yet. Add one above.
                    </div>
                ) : (
                    <div className="grid grid-cols-1 gap-4">
                        {wallets.map((wallet) => (
                            <div key={wallet.id} className={`glass p-6 flex flex-col md:flex-row items-center justify-between gap-6 transition-all ${!wallet.isActive ? 'opacity-60 grayscale' : ''}`}>
                                <div className="flex items-center gap-5 w-full md:w-auto">
                                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center border-2 shadow-xl ${wallet.isActive ? 'bg-primary/10 border-primary/20 shadow-primary/10 text-primary' : 'bg-text-dim/10 border-text-dim/20 text-text-dim'}`}>
                                        <Wallet size={24} />
                                    </div>
                                    <div>
                                        <div className="flex items-center gap-3">
                                            <span className="px-2 py-1 rounded bg-white/10 text-[10px] font-bold text-white tracking-widest uppercase">
                                                {wallet.network}
                                            </span>
                                            {wallet.isActive ? (
                                                <span className="text-[10px] bg-primary/20 text-primary px-2 py-1 rounded font-bold uppercase tracking-widest">Active</span>
                                            ) : (
                                                <span className="text-[10px] bg-red-500/20 text-red-500 px-2 py-1 rounded font-bold uppercase tracking-widest">Disabled</span>
                                            )}
                                        </div>
                                        {wallet.name && (
                                            <p className="text-primary text-xs font-bold uppercase tracking-widest mt-2">{wallet.name}</p>
                                        )}
                                        <p className="text-white font-mono text-sm sm:text-base mt-1 break-all">{wallet.address}</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-3 w-full md:w-auto justify-end">
                                    <button
                                        onClick={() => handleCopy(wallet.address, wallet.id)}
                                        className="p-3 rounded-xl bg-white/5 hover:bg-white/10 transition-colors text-white"
                                        title="Copy Address"
                                    >
                                        {copiedId === wallet.id ? <Check size={18} className="text-primary"/> : <Copy size={18} />}
                                    </button>
                                    <button
                                        onClick={() => handleToggleStatus(wallet.id, wallet.isActive)}
                                        className={`p-3 rounded-xl transition-colors ${wallet.isActive ? 'bg-red-500/10 text-red-500 hover:bg-red-500/20' : 'bg-primary/10 text-primary hover:bg-primary/20'}`}
                                        title={wallet.isActive ? "Disable Wallet" : "Enable Wallet"}
                                    >
                                        <Power size={18} />
                                    </button>
                                    <button
                                        onClick={() => handleDelete(wallet.id)}
                                        className="p-3 rounded-xl bg-white/5 hover:bg-red-500/20 hover:text-red-500 transition-colors text-text-dim"
                                        title="Delete Wallet"
                                    >
                                        <Trash2 size={18} />
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </section>
        </div>
    );
};

export default Wallets;
