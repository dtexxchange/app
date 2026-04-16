// lib/crypto.ts

export const generateKeyPair = async () => {
  return window.crypto.subtle.generateKey(
    {
      name: "RSA-OAEP",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["encrypt", "decrypt"]
  );
};

export const exportPublicKey = async (key: CryptoKey) => {
  const exported = await window.crypto.subtle.exportKey("spki", key);
  return btoa(String.fromCharCode(...new Uint8Array(exported)));
};

export const exportPrivateKey = async (key: CryptoKey) => {
  const exported = await window.crypto.subtle.exportKey("pkcs8", key);
  return btoa(String.fromCharCode(...new Uint8Array(exported)));
};

export const importPrivateKey = async (pem: string) => {
  const binaryDerString = atob(pem);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }
  return window.crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSA-OAEP", hash: "SHA-256" },
    true,
    ["decrypt"]
  );
};

export const ENABLE_E2EE = false;

export const encryptData = async (publicKeyStr: string, data: any) => {
  if (!ENABLE_E2EE) {
    return btoa(JSON.stringify(data));
  }
  const binaryDerString = atob(publicKeyStr);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  const publicKey = await window.crypto.subtle.importKey(
    "spki",
    binaryDer,
    { name: "RSA-OAEP", hash: "SHA-256" },
    true,
    ["encrypt"]
  );

  const encoder = new TextEncoder();
  const encodedData = encoder.encode(JSON.stringify(data));
  const encrypted = await window.crypto.subtle.encrypt(
    { name: "RSA-OAEP" },
    publicKey,
    encodedData
  );

  return btoa(String.fromCharCode(...new Uint8Array(encrypted)));
};

export const decryptData = async (privateKey: CryptoKey | null, encryptedB64: string) => {
  if (!ENABLE_E2EE) {
    try {
      return JSON.parse(atob(encryptedB64));
    } catch (e) {
      return { error: "Parse failed", raw: encryptedB64 };
    }
  }
  if (!privateKey) throw new Error("Private key required");
  
  const binaryString = atob(encryptedB64);
  const binaryDer = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    binaryDer[i] = binaryString.charCodeAt(i);
  }

  const decrypted = await window.crypto.subtle.decrypt(
    { name: "RSA-OAEP" },
    privateKey,
    binaryDer
  );

  const decoder = new TextDecoder();
  return JSON.parse(decoder.decode(decrypted));
};
