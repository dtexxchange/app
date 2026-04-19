export const formatAmount = (amount: number | string | null | undefined): string => {
  if (amount === null || amount === undefined || amount === "") return "0.00";
  const num = typeof amount === "string" ? parseFloat(amount) : amount;
  if (isNaN(num)) return "0.00";
  return num.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
};

export const formatRaw = (amount: number | string | null | undefined): string => {
    if (amount === null || amount === undefined || amount === "") return "0.00";
    const num = typeof amount === "string" ? parseFloat(amount) : amount;
    if (isNaN(num)) return "0.00";
    return num.toFixed(2);
};
