import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// 🔑 Your Paymob API Key (keep this in Firebase config, not hardcoded)
const PAYMOB_API_KEY = process.env.PAYMOB_API_KEY || "";

// --------------------
// Generate and Save Paymob Card Token
// --------------------
export const generatePaymobToken = onCall(
  async (request: CallableRequest<any>): Promise<any> => {
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be logged in");
      }

      const userId = request.auth.uid;

      const { cardNumber, expiryMonth, expiryYear, cvv } = request.data;

      if (!cardNumber || !expiryMonth || !expiryYear || !cvv) {
        throw new HttpsError("invalid-argument", "Missing card details");
      }

      // 1️⃣ Authenticate with Paymob
      const authResponse = await fetch("https://accept.paymob.com/api/auth/tokens", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ api_key: PAYMOB_API_KEY }),
      });

      const authData = await authResponse.json();
      if (!authData.token) {
        throw new HttpsError("internal", "Failed to authenticate with Paymob");
      }

      // 2️⃣ Generate Card Token
      const tokenResponse = await fetch("https://accept.paymob.com/api/acceptance/tokenization", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          token: authData.token,
          card_number: cardNumber,
          card_expiry_mm: expiryMonth,
          card_expiry_yy: expiryYear,
          card_cvv: cvv,
        }),
      });

      const tokenData = await tokenResponse.json();
      if (!tokenData.token) {
        throw new HttpsError("internal", "Failed to generate Paymob token");
      }

      // 3️⃣ Prepare card info (only safe data)
      const paymentMethod = {
        cardBrand: tokenData.card_subtype || "Unknown",
        last4: tokenData.masked_pan ? tokenData.masked_pan.slice(-4) : "****",
        expiryMonth,
        expiryYear,
        isDefault: true, // first card added can be default
        addedAt: admin.firestore.Timestamp.now(),
      };

      // 4️⃣ Save to Firestore
      await db
        .collection("users")
        .doc(userId)
        .collection("payment_methods")
        .doc(tokenData.token) // use token as ID
        .set(paymentMethod);

      // 5️⃣ Return token & card info
      return {
        token: tokenData.token,
        ...paymentMethod,
      };
    } catch (err: any) {
      console.error("Error generating Paymob token:", err);
      throw new HttpsError("internal", err.message || "Something went wrong");
    }
  }
);
