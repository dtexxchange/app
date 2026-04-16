# USDT Exchange & Banking Simulation

A high-performance, secure banking simulation platform allowing users to manage a virtual USDT wallet with simulated deposits and withdrawals, managed by an administrator.

## 🛡️ Key Features

- **End-to-End Encryption (E2EE)**: Sensitive bank details are encrypted on the client-side using the Admin's RSA public key. Only the Admin's physical device can decrypt this data.
- **Role-Based Access Control**:
  - **Admin**: Whitelist users, approve/reject transactions, view decrypted bank details for fulfillment.
  - **User**: View balance, request deposits, request withdrawals with encrypted bank details.
- **OTP Authentication**: Secure login via Resend Email OTP.
- **Simulated Wallet**: Transactional integrity (deduction on request, refund on rejection).
- **Premium Aesthetics**: Sleek dark-mode interface with toxic green and gold accents.

## 🏗️ Technology Stack

- **Backend**: NestJS, Prisma ORM, PostgreSQL.
- **Web Frontend**: React, Vite, Framer Motion, Tailwind/Glassmorphism.
- **Mobile**: Flutter/Dart (User & Admin apps).
- **E2EE**: Web Crypto API (SubtleCrypto) & PointyCastle (Dart).

---

## 🚀 Getting Started

### 1. Prerequisites
- **Node.js** (v18+)
- **PostgreSQL** (Running locally or hosted)
- **Flutter SDK** (For mobile development)
- **Resend API Key** (Get it at [resend.com](https://resend.com))

### 2. Backend Setup
```bash
cd apps/backend
npm install
# Update .env with your DATABASE_URL and RESEND_API_KEY
npx prisma db push
npm run start:dev
```

### 3. Setup Initial Admin
Since the app only allows whitelisted users to log in, you must create the first administrator manually:
```bash
curl -X POST http://localhost:3000/auth/setup-admin \
     -H "Content-Type: application/json" \
     -d '{"email": "your-email@example.com"}'
```

### 4. Web Frontend Setup
```bash
cd apps/frontend
npm install
npm run dev
```

### 5. Mobile Apps Setup
Ensure the backend is running and accessible from your emulator/device (usually `http://10.0.2.2:3000` for Android).
```bash
cd apps/mobile_app # or apps/mobile_app_admin
flutter pub get
flutter run
```

---

## 🔐 Security Architecture (E2EE)

1.  **Key Generation**: The Admin logs into the Web app and generates an RSA Key Pair.
2.  **Public Key**: The Public Key is stored on the server.
3.  **Encryption**: When a User requests a withdrawal, the app fetches the Admin's Public Key and encrypts their Bank Name, Acc No, etc.
4.  **Storage**: The server only holds the encrypted ciphertext. Even a database breach does not leak user details.
5.  **Decryption**: The Admin fetches the ciphertext and uses their **locally stored private key** to reveal the details.

## 📄 License
UNLICENSED
