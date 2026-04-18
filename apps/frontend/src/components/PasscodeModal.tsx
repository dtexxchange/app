import { motion } from "framer-motion";
import { Lock, XCircle } from "lucide-react";
import React, { useEffect, useState } from "react";
import api from "../lib/api";

interface PasscodeModalProps {
    isOpen: boolean;
    onClose: (success?: boolean) => void;
    userHasPasscode: boolean;
}

type Step = "VERIFY_OLD" | "ENTER_NEW" | "CONFIRM_NEW";

const PasscodeModal: React.FC<PasscodeModalProps> = ({
    isOpen,
    onClose,
    userHasPasscode,
}) => {
    const [step, setStep] = useState<Step>("ENTER_NEW");
    const [oldPasscode, setOldPasscode] = useState("");
    const [newPasscode, setNewPasscode] = useState("");
    const [confirmPasscode, setConfirmPasscode] = useState("");
    const [input, setInput] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (isOpen) {
            setStep(userHasPasscode ? "VERIFY_OLD" : "ENTER_NEW");
            resetState();
        }
    }, [isOpen, userHasPasscode]);

    const resetState = () => {
        setInput("");
        setOldPasscode("");
        setNewPasscode("");
        setConfirmPasscode("");
        setError(null);
    };

    const handleNumberClick = (num: string) => {
        if (input.length < 6) {
            setInput((prev) => prev + num);
        }
    };

    const handleBackspace = () => {
        setInput((prev) => prev.slice(0, -1));
    };

    useEffect(() => {
        if (input.length === 6) {
            handleComplete(input);
        }
    }, [input]);

    const [activeKey, setActiveKey] = useState<string | null>(null);

    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (!isOpen || isLoading) return;

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
    }, [isOpen, isLoading, input.length]); // input.length to ensure we don't exceed 6 via keyboard quickly

    const handleComplete = async (val: string) => {
        if (step === "VERIFY_OLD") {
            setIsLoading(true);
            try {
                const { data } = await api.post("/users/me/passcode/verify", {
                    passcode: val,
                });
                if (data.isValid) {
                    setOldPasscode(val);
                    setStep("ENTER_NEW");
                    setInput("");
                } else {
                    setError("Incorrect current passcode");
                    setInput("");
                }
            } catch (err) {
                setError("Verification failed");
                setInput("");
            } finally {
                setIsLoading(false);
            }
        } else if (step === "ENTER_NEW") {
            if (userHasPasscode && val === oldPasscode) {
                setError("New passcode cannot be the same as current");
                setInput("");
                return;
            }
            setNewPasscode(val);
            setStep("CONFIRM_NEW");
            setInput("");
        } else if (step === "CONFIRM_NEW") {
            if (val === newPasscode) {
                submitPasscode(val);
            } else {
                setError("Passcodes do not match. Try again.");
                setStep("ENTER_NEW");
                setInput("");
            }
        }
    };

    const submitPasscode = async (val: string) => {
        setIsLoading(true);
        try {
            await api.patch("/users/me/passcode", {
                passcode: val,
                oldPasscode: oldPasscode || undefined,
            });
            onClose(true);
        } catch (err: any) {
            setError(
                err.response?.data?.message || "Failed to update passcode",
            );
            setInput("");
            setStep("ENTER_NEW");
        } finally {
            setIsLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl">
            <motion.div
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                className="glass-panel p-10 w-full max-w-md shadow-2xl relative overflow-hidden"
            >
                <button
                    onClick={() => onClose()}
                    className="absolute top-6 right-6 text-text-dim hover:text-white transition-colors"
                >
                    <XCircle size={24} />
                </button>

                <div className="text-center space-y-4 mb-10">
                    <div className="w-16 h-16 bg-accent-blue/10 rounded-2xl flex items-center justify-center border border-accent-blue/20 mx-auto text-accent-blue mb-6">
                        <Lock size={32} />
                    </div>
                    <h2 className="text-3xl font-outfit font-bold text-white">
                        {step === "VERIFY_OLD"
                            ? "Verify Identity"
                            : step === "ENTER_NEW"
                              ? userHasPasscode
                                  ? "Enter New Passcode"
                                  : "Set Passcode"
                              : "Confirm New Passcode"}
                    </h2>
                    <p className="text-sm text-text-dim font-medium uppercase tracking-widest">
                        {step === "VERIFY_OLD"
                            ? "Enter your current 6-digit passcode"
                            : step === "ENTER_NEW"
                              ? "Choose a strong 6-digit pin"
                              : "Repeat the new passcode"}
                    </p>
                </div>

                <div className="flex justify-center gap-4 mb-10">
                    {[...Array(6)].map((_, i) => (
                        <div
                            key={i}
                            className={`w-4 h-4 rounded-full border-2 transition-all duration-300 ${
                                i < input.length
                                    ? "bg-accent-blue border-accent-blue scale-125 shadow-[0_0_15px_rgba(59,130,246,0.5)]"
                                    : "border-white/10"
                            }`}
                        />
                    ))}
                </div>

                {error && (
                    <motion.div
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="text-xs text-red-400 font-bold uppercase tracking-widest text-center mb-6"
                    >
                        {error}
                    </motion.div>
                )}

                <div className="grid grid-cols-3 gap-4 mb-8">
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
                            disabled={isLoading || key === ""}
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
                                      : `bg-white/5 text-white hover:bg-white/10 border border-white/5 ${activeKey === key ? "bg-accent-blue/30 border-accent-blue scale-110 shadow-[0_0_20px_rgba(59,130,246,0.4)]" : ""}`
                            }`}
                        >
                            {key === "DEL" ? "←" : key}
                        </button>
                    ))}
                </div>

                {isLoading && (
                    <div className="flex justify-center">
                        <div className="w-8 h-8 border-2 border-accent-blue border-t-transparent rounded-full animate-spin" />
                    </div>
                )}
            </motion.div>
        </div>
    );
};

export default PasscodeModal;
