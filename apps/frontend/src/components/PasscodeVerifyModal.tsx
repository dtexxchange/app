import { motion } from "framer-motion";
import { ShieldCheck, XCircle } from "lucide-react";
import React, { useEffect, useState } from "react";

interface PasscodeVerifyModalProps {
    isOpen: boolean;
    onClose: (passcode?: string) => void;
}

const PasscodeVerifyModal: React.FC<PasscodeVerifyModalProps> = ({
    isOpen,
    onClose,
}) => {
    const [input, setInput] = useState("");

    useEffect(() => {
        if (isOpen) setInput("");
    }, [isOpen]);

    const handleNumberClick = (num: string) => {
        if (input.length < 6) {
            setInput((prev) => prev + num);
        }
    };

    const handleBackspace = () => {
        setInput((prev) => prev.slice(0, -1));
    };

    const [activeKey, setActiveKey] = useState<string | null>(null);

    useEffect(() => {
        if (input.length === 6) {
            onClose(input);
        }
    }, [input]);

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (!isOpen) return;

            let key = "";
            if (e.key >= "0" && e.key <= "9") {
                key = e.key;
                handleNumberClick(key);
            } else if (e.key === "Backspace") {
                key = "DEL";
                handleBackspace();
            } else if (e.key === "Escape") {
                onClose();
                return;
            }

            if (key) {
                setActiveKey(key);
                setTimeout(() => setActiveKey(null), 150);
            }
        };

        window.addEventListener("keydown", handleKeyDown);
        return () => window.removeEventListener("keydown", handleKeyDown);
    }, [isOpen, input.length]);

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-black/80 backdrop-blur-2xl">
            <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                className="glass-panel p-10 w-full max-w-sm shadow-2xl relative"
                onClick={(e) => e.stopPropagation()}
            >
                <button
                    onClick={() => onClose()}
                    className="absolute top-6 right-6 text-text-dim hover:text-white transition-colors"
                >
                    <XCircle size={24} />
                </button>

                <div className="text-center space-y-4 mb-10">
                    <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center border border-primary/20 mx-auto text-primary mb-6">
                        <ShieldCheck size={32} />
                    </div>
                    <h2 className="text-3xl font-outfit font-bold text-white">
                        Authorize
                    </h2>
                    <p className="text-sm text-text-dim font-medium uppercase tracking-widest">
                        Enter your 6-digit passcode
                    </p>
                </div>

                <div className="flex justify-center gap-4 mb-10">
                    {[...Array(6)].map((_, i) => (
                        <div
                            key={i}
                            className={`w-4 h-4 rounded-full border-2 transition-all duration-300 ${
                                i < input.length
                                    ? "bg-primary border-primary scale-125 shadow-[0_0_15px_rgba(0,255,157,0.5)]"
                                    : "border-white/10"
                            }`}
                        />
                    ))}
                </div>

                <div className="grid grid-cols-3 gap-4">
                    {[
                        "1",
                        "2",
                        "3",
                        "4",
                        "5",
                        "6",
                        "7",
                        "8",
                        "9",
                        "",
                        "0",
                        "DEL",
                    ].map((key, i) => (
                        <button
                            key={i}
                            disabled={key === ""}
                            onClick={() =>
                                key === "DEL"
                                    ? handleBackspace()
                                    : handleNumberClick(key)
                            }
                            className={`h-16 rounded-2xl flex items-center justify-center text-xl font-bold transition-all active:scale-95 ${
                                key === ""
                                    ? "opacity-0 pointer-events-none"
                                    : key === "DEL"
                                      ? `bg-white/5 text-text-dim hover:bg-white/10 ${activeKey === "DEL" ? "bg-white/20 scale-110 shadow-[0_0_15px_rgba(255,255,255,0.2)]" : ""}`
                                      : `bg-white/5 text-white hover:bg-white/10 border border-white/5 ${activeKey === key ? "bg-primary/30 border-primary scale-110 shadow-[0_0_20px_rgba(0,255,157,0.4)]" : ""}`
                            }`}
                        >
                            {key === "DEL" ? "←" : key}
                        </button>
                    ))}
                </div>
            </motion.div>
        </div>
    );
};

export default PasscodeVerifyModal;
