import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

// Initialize Firebase Admin SDK for infinite/backend privilege
initializeApp();
const db = getFirestore();

async function sendPushNotification(uid: string, title: string, body: string) {
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
      const message = {
        notification: { title, body },
        token: fcmToken,
      };
      await getMessaging().send(message);
      console.log(`FCM Notification successfully sent to user ${uid}`);
    }
  } catch (err) {
    console.warn("FCM messaging skipped or failed: ", err);
  }
}

/**
 * Custom Rate Limiter using Firestore
 * Allows up to `maxRequests` per `windowSeconds` (default 60 seconds)
 */
async function enforceRateLimit(uid: string, maxRequests: number = 5, windowSeconds: number = 60) {
  const rateLimitRef = db.collection("rate_limits").doc(uid);
  const now = Date.now();
  const cutoff = now - windowSeconds * 1000;

  await db.runTransaction(async (transaction) => {
    const docSnap = await transaction.get(rateLimitRef);
    let timestamps: number[] = [];

    if (docSnap.exists) {
      const data = docSnap.data();
      if (data && Array.isArray(data.timestamps)) {
        // filter out old timestamps
        timestamps = data.timestamps.filter((ts: number) => ts > cutoff);
      }
    }

    if (timestamps.length >= maxRequests) {
      throw new HttpsError(
        "resource-exhausted",
        "Rate limit exceeded. Too many requests. Please slow down and try again later."
      );
    }

    timestamps.push(now);
    transaction.set(rateLimitRef, { timestamps }, { merge: true });
  });
}

/**
 * 1. validateAndPlaceOrder (HTTPS Callable)
 *
 * Accepts raw cart inputs, performs strict server-authoritative recalculation against
 * verified DB prices/zones/coupons, and commits the finalized order securely.
 */
export const validateAndPlaceOrder = onCall(async (request) => {
  // Authentication Guard
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required to place an order."
    );
  }

  const uid = request.auth.uid;
  await enforceRateLimit(uid, 5, 60);
  const data = request.data || {};

  // 1. Working Hours check (Enforce 12:00 PM - 01:00 AM Amman Time, UTC+3)
  const nowUtc = new Date();
  const ammanHour = (nowUtc.getUTCHours() + 3) % 24;
  const isOpen = (ammanHour >= 12 || ammanHour === 0);

  if (!isOpen) {
    throw new HttpsError(
      "failed-precondition",
      "The restaurant is currently closed. Working hours: 12:00 PM to 1:00 AM Amman Time."
    );
  }

  // Input Structure Validation
  const items = data.items;
  const zoneId = data.zoneId;
  const couponCode = data.couponCode ? String(data.couponCode).toUpperCase().trim() : null;
  const fulfillmentType = data.fulfillmentType || "delivery";
  const address = data.address || null;
  const paymentMethod = data.paymentMethod || "Cash on Delivery";
  const customerName = data.customerName || "Customer";
  const customerPhone = data.customerPhone || "";

  if (!Array.isArray(items) || items.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "Order must contain at least one valid menu item."
    );
  }

  if (fulfillmentType === "delivery" && (!zoneId || !address)) {
    throw new HttpsError(
      "invalid-argument",
      "Delivery zone and detailed physical address are required for shipping."
    );
  }

  // 2. Geofencing Coordinates Check (Amman bounding box verification)
  if (fulfillmentType === "delivery" && address && address.coordinates) {
    const lat = parseFloat(address.coordinates.lat);
    const lng = parseFloat(address.coordinates.lng);
    if (isNaN(lat) || isNaN(lng) || lat < 31.8000 || lat > 32.1200 || lng < 35.7500 || lng > 36.0500) {
      throw new HttpsError(
        "failed-precondition",
        "لا يمكن تنفيذ الطلب لأن موقعك خارج مناطق التوصيل المدعومة في عمان."
      );
    }
  }

  try {
    return await db.runTransaction(async (transaction) => {
      let subtotal = 0.0;

      // 1. Recalculate prices directly from the authoritative Firestore catalog
      for (const item of items) {
        if (!item.productId || typeof item.quantity !== "number" || item.quantity <= 0) {
          throw new HttpsError(
            "invalid-argument",
            "Invalid format for standard item parameters."
          );
        }

        const productRef = db.collection("products").doc(item.productId);
        const productDoc = await transaction.get(productRef);

        if (!productDoc.exists || productDoc.data()?.isDeleted === true) {
          throw new HttpsError(
            "failed-precondition",
            `No active menu record was found for product: ${item.productId}`
          );
        }

        const prodData = productDoc.data()!;
        const basePrice = parseFloat(prodData.price || "0");
        let itemSum = basePrice;

        // Verify side option costs Authoritatively
        const sideId = item.selectedSide;
        if (sideId && typeof sideId === "string" && sideId.trim() !== "") {
          const sideOptions: any[] = prodData.sideOptions || [];
          const sideMatch = sideOptions.find((o) => o.id === sideId);
          if (sideMatch) {
            itemSum += parseFloat(sideMatch.price || "0");
          } else {
            throw new HttpsError(
              "failed-precondition",
              `Chosen side add-on '${sideId}' does not belong to product '${item.productId}'.`
            );
          }
        }

        subtotal += itemSum * item.quantity;
      }

      // 2. Authoritative Delivery Zone Fee Lookup
      let deliveryFee = 0.0;
      if (fulfillmentType === "delivery" && zoneId) {
        const zoneRef = db.collection("delivery_zones").doc(zoneId);
        const zoneDoc = await transaction.get(zoneRef);

        if (!zoneDoc.exists) {
          throw new HttpsError(
            "failed-precondition",
            "Specified delivery zone is unrecognized."
          );
        }

        const zoneData = zoneDoc.data()!;
        deliveryFee = parseFloat(zoneData.fee || "0");
        const minOrder = parseFloat(zoneData.minOrder || "0");

        if (subtotal < minOrder) {
          throw new HttpsError(
            "failed-precondition",
            `Subtotal (${subtotal} JOD) is below the minimum order floor (${minOrder} JOD) for ${zoneData.name}.`
          );
        }
      }

      // 3. Dynamic Tax Formulation (checking client override and settings fallback)
      const settingsRef = db.collection("settings").doc("system_settings");
      const settingsDoc = await transaction.get(settingsRef);

      let taxRate = 0.16; // Authoritative Jordanian Sales Tax 16%
      let taxEnabled = data.taxEnabled === true; // Enforce client checkbox selection

      if (settingsDoc.exists) {
        const sData = settingsDoc.data()!;
        if (typeof sData.taxRate === "number") {
          taxRate = sData.taxRate / 100.0;
        }
      }

      const taxes = taxEnabled ? parseFloat((subtotal * taxRate).toFixed(3)) : 0.0;

      // 4. Coupon Verification and Discounts Calculations
      let discount = 0.0;
      let appliedCouponId: string | null = null;

      if (couponCode) {
        const couponQuery = db.collection("coupons")
          .where("code", "==", couponCode)
          .where("isDeleted", "==", false)
          .limit(1);

        const couponSnap = await transaction.get(couponQuery);

        if (couponSnap.empty) {
          throw new HttpsError("not-found", "Invalid or deleted coupon code.");
        }

        const couponDoc = couponSnap.docs[0];
        const couponData = couponDoc.data();

        // Expired Verification
        const expiry = new Date(couponData.expiryDate);
        if (expiry.getTime() < Date.now()) {
          throw new HttpsError("failed-precondition", "The entered coupon has expired.");
        }

        // Global Usage Limits Check
        const maxLimit = parseInt(couponData.usageLimit || "0");
        const currentCount = parseInt(couponData.usedCount || "0");
        if (maxLimit > 0 && currentCount >= maxLimit) {
          throw new HttpsError("failed-precondition", "Coupon campaign limit reached.");
        }

        // Per-user restriction (Preventing coupon duplication fraud)
        const usageCheck = await db.collection("coupon_redemptions")
          .where("customerUid", "==", uid)
          .where("couponCode", "==", couponCode)
          .limit(1)
          .get();

        if (!usageCheck.empty) {
          throw new HttpsError("already-exists", "You have already used this coupon.");
        }

        // Check product subtotal floor
        const minCouponOrder = parseFloat(couponData.minOrder || "0");
        if (subtotal < minCouponOrder) {
          throw new HttpsError(
            "failed-precondition",
            `Coupon require minimum active purchase of: ${minCouponOrder} JOD.`
          );
        }

        // Calculate absolute discount
        const type = couponData.discountType;
        const value = parseFloat(couponData.value || "0");

        if (type === "Percentage") {
          discount = subtotal * (value / 100.0);
        } else {
          discount = value;
        }

        discount = parseFloat(Math.min(discount, subtotal).toFixed(3));
        appliedCouponId = couponDoc.id;
      }

      // Final Payable total calculation
      let total = (subtotal + deliveryFee + taxes) - discount;
      if (total < 0.0) total = 0.0;
      total = parseFloat(total.toFixed(3));

      // 5. Build official, tamper-free Order document
      const randomId = db.collection("orders").doc().id;
      const orderNumber = `T-${new Date().getFullYear().toString().substring(2)}-${Math.floor(1000 + Math.random() * 9000)}`;

      const finalizedOrder = {
        id: randomId,
        orderNumber: orderNumber,
        customerUid: uid,
        customerName: customerName,
        customerPhone: customerPhone,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        taxes: taxes,
        discount: discount,
        total: total,
        paymentMethod: paymentMethod,
        status: "pending", // Initial state MUST enforce 'pending'
        fulfillmentType: fulfillmentType,
        address: address,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        isDeleted: false,
        pointsAwarded: false,
        couponCode: couponCode || null,
        branchId: data.branchId || "main_jibeeha",
      };

      // Set order document
      transaction.set(db.collection("orders").doc(randomId), finalizedOrder);

      // Save coupon redemption audit details and update count in transaction
      if (appliedCouponId && couponCode) {
        transaction.update(db.collection("coupons").doc(appliedCouponId), {
          usedCount: FieldValue.increment(1),
        });

        const redemptionId = db.collection("coupon_redemptions").doc().id;
        transaction.set(db.collection("coupon_redemptions").doc(redemptionId), {
          id: redemptionId,
          customerUid: uid,
          couponCode: couponCode,
          redeemedAt: FieldValue.serverTimestamp(),
        });
      }

      // Create Order Audit Log Tracker
      const logId = db.collection("order_audit_logs").doc().id;
      transaction.set(db.collection("order_audit_logs").doc(logId), {
        id: logId,
        orderId: randomId,
        action: "ORDER_CREATED",
        details: `Calculated Total: ${total} JOD. Client pricing calculations ignored in favor of core backend rules.`,
        timestamp: FieldValue.serverTimestamp(),
      });

      return {
        orderId: randomId,
        orderNumber: orderNumber,
        total: total,
      };
    });
  } catch (error: any) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message || "An error occurred compiling order ticket.");
  }
});

/**
 * 2. awardLoyaltyPoints (Firestore Trigger)
 *
 * Runs automatically when order status transitions to "arrived" (delivered),
 * calculating and adding currency value loyalty points atomically via backend Admin.
 */
export const awardLoyaltyPoints = onDocumentUpdated("orders/{orderId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const orderBefore = snap.before.data();
  const orderAfter = snap.after.data();

  if (!orderAfter || !orderBefore) return;

  const orderId = event.params.orderId;
  const statusBefore = orderBefore.status;
  const statusAfter = orderAfter.status;

  if (statusAfter !== statusBefore) {
    let title = "Grill Chicken Tikka";
    let body = `حالة طلبك #${orderAfter.orderNumber} أصبحت الآن: ${statusAfter}`;
    
    const lowerStatus = statusAfter.toLowerCase();
    if (lowerStatus === "preparing") {
      title = "طلبك قيد التحضير 👨‍🍳";
      body = "يقوم الطاهي الآن بشواء وجبتك الشهية على الفحم الطبيعي!";
    } else if (lowerStatus === "onway" || lowerStatus === "out_for_delivery") {
      title = "خرج للتوصيل 🚴";
      body = "طلبك الساخن في طريقه إليك الآن مع سائق التوصيل!";
    } else if (lowerStatus === "arrived" || lowerStatus === "delivered") {
      title = "تم التوصيل بالسلامة 🎉";
      body = "وصل طلبك، بالهناء والشفاء! صحتين وعافية.";
    } else if (lowerStatus === "accepted") {
      title = "تم قبول الطلب ✅";
      body = "تم قبول طلبك من قبل المطعم وجاري توجيهه للمطبخ.";
    }

    await sendPushNotification(orderAfter.customerUid, title, body);
  }

  // Trigger Action strictly on 'delivered' state change && check pointsAwarded to guard against double award
  if (statusAfter === "delivered" && statusBefore !== "delivered" && orderAfter.pointsAwarded !== true) {
    const total = parseFloat(orderAfter.total || "0");
    const uid = orderAfter.customerUid;

    if (!uid) return;

    // Standard Business rule conversion: 1.00 JOD spent rewards 1000 points
    const earnedPoints = Math.floor(total * 1000);

    if (earnedPoints <= 0) return;

    const userRef = db.collection("users").doc(uid);

    try {
      await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          const currentPoints = parseInt(userDoc.data()?.points || "0");
          transaction.update(userRef, {
            points: currentPoints + earnedPoints,
            updatedAt: FieldValue.serverTimestamp(),
          });

          // Write immutable loyalty transactions ledger entry
          const txId = db.collection("loyalty_transactions").doc().id;
          transaction.set(db.collection("loyalty_transactions").doc(txId), {
            id: txId,
            customerUid: uid,
            pointsChanged: earnedPoints,
            transactionType: "earn",
            description: `Earned points from Ticket #${orderAfter.orderNumber}`,
            createdAt: FieldValue.serverTimestamp(),
          });

          // Flag order as points processed
          transaction.update(db.collection("orders").doc(orderId), {
            pointsAwarded: true,
            pointsEarnedCount: earnedPoints,
            updatedAt: FieldValue.serverTimestamp(),
          });

          // Append audit log
          const auditId = db.collection("order_audit_logs").doc().id;
          transaction.set(db.collection("order_audit_logs").doc(auditId), {
            id: auditId,
            orderId: orderId,
            action: "LOYALTY_POINTS_DISPATCHED",
            details: `Successfully completed. Dispatched +${earnedPoints} points to buyer UID: ${uid}.`,
            timestamp: FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (err: any) {
      console.error(`Transaction failure during loyalty assignment on ticket '${orderId}': ${err.message}`);
    }
  }
});

/**
 * 3. redeemLoyaltyReward (HTTPS Callable)
 *
 * Atomically verifies and deducts points to exchange for predefined rewards,
 * generating a discount coupon for checkout and recording immutable audits.
 */
export const redeemLoyaltyReward = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication is required to redeem reward loyalty options."
    );
  }

  const uid = request.auth.uid;
  await enforceRateLimit(uid, 5, 60);
  const rewardId = String(request.data?.rewardId || "").trim();

  // Unified rewards structure pricing points cost (1 JOD spent awards 1000 points; 20000 points = 5.5 JOD free meal)
  const rewardsCatalog: { [key: string]: { name: string; cost: number; discountValue: number; discountType: string } } = {
    "free_meal": { name: "Free Meal Coupon (5.5 JOD Value)", cost: 20000, discountValue: 5.50, discountType: "Flat" },
    "drink_reward": { name: "Free Soft Drink Coupon", cost: 1500, discountValue: 1.50, discountType: "Flat" },
    "side_reward": { name: "Free Hummus Accent", cost: 2500, discountValue: 2.50, discountType: "Flat" },
    "cash_5": { name: "5 JOD Off Coupon", cost: 5000, discountValue: 5.00, discountType: "Flat" },
  };

  const selectedReward = rewardsCatalog[rewardId];
  if (!selectedReward) {
    throw new HttpsError(
      "invalid-argument",
      "The selected reward program code was not found inside catalogs."
    );
  }

  const userRef = db.collection("users").doc(uid);

  try {
    return await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Loyalty customer user account record was not found.");
      }

      const currentPoints = parseInt(userDoc.data()?.points || "0");
      if (currentPoints < selectedReward.cost) {
        throw new HttpsError(
          "failed-precondition",
          `Insufficient points. Required: ${selectedReward.cost}, Your balance: ${currentPoints}.`
        );
      }

      const newBalance = currentPoints - selectedReward.cost;

      // 1. Deduct points atomically
      transaction.update(userRef, {
        points: newBalance,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 2. Generate a highly unique discount coupon in our coupons database
      const randomCouponCode = `REWARD-${Math.floor(100000 + Math.random() * 900000)}`;
      const couponId = db.collection("coupons").doc().id;

      // Coupons active expiration (valid for 30 days)
      const expiryDate = new Date();
      expiryDate.setDate(expiryDate.getDate() + 30);

      const couponObj = {
        id: couponId,
        code: randomCouponCode,
        discountType: selectedReward.discountType,
        value: selectedReward.discountValue,
        minOrder: 1.00, // Minimal boundary to bypass edge calculations
        expiryDate: expiryDate.toISOString(),
        usageLimit: 1, // Single redemption limit
        usedCount: 0,
        isDeleted: false,
        createdForUid: uid, // Restrict this coupon to this client only
      };

      transaction.set(db.collection("coupons").doc(couponId), couponObj);

      // 3. Write negative entry into loyalty transactions ledgers
      const txId = db.collection("loyalty_transactions").doc().id;
      transaction.set(db.collection("loyalty_transactions").doc(txId), {
        id: txId,
        customerUid: uid,
        pointsChanged: -selectedReward.cost,
        transactionType: "redeem",
        description: `Redeemed ${selectedReward.name}. Generated Coupon: ${randomCouponCode}`,
        createdAt: FieldValue.serverTimestamp(),
      });

      // 4. Create coupon redemptions history block record
      const redemptionId = db.collection("coupon_redemptions").doc().id;
      transaction.set(db.collection("coupon_redemptions").doc(redemptionId), {
        id: redemptionId,
        customerUid: uid,
        couponCode: randomCouponCode,
        redeemedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        couponCode: randomCouponCode,
        pointsDeducted: selectedReward.cost,
        newPointsBalance: newBalance,
      };
    });
  } catch (error: any) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message || "Failed to redeem loyalty points reward.");
  }
});

/**
 * 4. validateCoupon (HTTPS Callable)
 *
 * Clean internal coupon verifications, checking limits, expiration,
 * minimum order requirements, and user restrictions.
 */
export const validateCoupon = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const uid = request.auth.uid;
  await enforceRateLimit(uid, 10, 60);
  const couponCode = String(request.data?.couponCode || "").toUpperCase().trim();
  const subtotal = parseFloat(request.data?.subtotal || "0");

  if (!couponCode) {
    throw new HttpsError("invalid-argument", "Coupon code parameter is required.");
  }

  const couponQuery = db.collection("coupons")
    .where("code", "==", couponCode)
    .where("isDeleted", "==", false)
    .limit(1);

  const couponSnap = await couponQuery.get();

  if (couponSnap.empty) {
    throw new HttpsError("not-found", "The entered coupon code was not recognized.");
  }

  const couponDoc = couponSnap.docs[0];
  const couponData = couponDoc.data();

  // Expired Verification
  const expiry = new Date(couponData.expiryDate);
  if (expiry.getTime() < Date.now()) {
    throw new HttpsError("failed-precondition", "This discount coupon has expired.");
  }

  // Global Usage Limits Check
  const maxLimit = parseInt(couponData.usageLimit || "0");
  const currentCount = parseInt(couponData.usedCount || "0");
  if (maxLimit > 0 && currentCount >= maxLimit) {
    throw new HttpsError("failed-precondition", "This coupon has reached its maximum global usage limit.");
  }

  // Specific User Restrict Verify (E.g. generated coupon from points reward or single-use)
  if (couponData.createdForUid && couponData.createdForUid !== uid) {
    throw new HttpsError("permission-denied", "This promotional voucher is restricted to another customer account.");
  }

  // Check personal redemption history
  const usageCheck = await db.collection("coupon_redemptions")
    .where("customerUid", "==", uid)
    .where("couponCode", "==", couponCode)
    .limit(1)
    .get();

  if (!usageCheck.empty) {
    throw new HttpsError("already-exists", "This coupon has already been redeemed on your account.");
  }

  // Verify subtotal
  const minOrder = parseFloat(couponData.minOrder || "0");
  if (subtotal < minOrder) {
    throw new HttpsError(
      "failed-precondition",
      `Minimum order of ${minOrder} JOD is required for this code. Current subtotal: ${subtotal} JOD.`
    );
  }

  return {
    code: couponCode,
    discountType: couponData.discountType,
    value: parseFloat(couponData.value || "0"),
    minOrder: minOrder,
  };
});

/**
 * 5. seedDatabase (HTTPS Callable)
 * Populates Firestore with categories, products, delivery zones, coupons, and system settings.
 */
export const seedDatabase = onCall(async (request) => {
  const data = request.data || {};
  if (data.key !== "grill_tikka_seed_2026") {
    throw new HttpsError("permission-denied", "Unauthorized seed request.");
  }

  const batch = db.batch();

  // Categories
  const categories = [
    { id: "grill", name: "Grill", nameAr: "مشاوي", icon: "Flame", isDeleted: false },
    { id: "sides", name: "Sides", nameAr: "مقبلات", icon: "Utensils", isDeleted: false },
    { id: "drinks", name: "Drinks", nameAr: "مشروبات", icon: "CupSoda", isDeleted: false },
    { id: "salads", name: "Salads", nameAr: "سلطات", icon: "Leaf", isDeleted: false },
    { id: "desserts", name: "Desserts", nameAr: "حلويات", icon: "Cake", isDeleted: false }
  ];

  for (const cat of categories) {
    const ref = db.collection("categories").doc(cat.id);
    batch.set(ref, cat);
  }

  // Products
  const products = [
    {
      id: "g1",
      title: "Classic Chicken Tikka",
      titleAr: "شيش طاووق كلاسيك",
      description: "Succulent boneless chicken chunks marinated in Greek yogurt and secret tandoori spices, slow-grilled over tandoori charcoal. Served with fresh mint chutney.",
      descriptionAr: "شيش طاووق دجاج مخلي من العظم متبل بالزبادي اليوناني وتوابل التندوري السرية، مشوي على الفحم الهادئ. يقدم مع صلصة النعناع الطازجة.",
      price: 8.50,
      categoryId: "grill",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuAn1sCpgho6ewShTIi3ZNkAjWKlgDt29qFRFUi9FyPczl9zFcSOuGaooIzBIdH8lYBd2enaejW3EC5GDEtIW3VHjJwbFR-uG3N94wS2mxdUiIdG-yg69QMAYiQ5m1kk0rD_NVT1l9C7bfJ-q-wVWXWga53tLQxm5nfv17ZAiR5loYFZPtIxr_GdV0egWeAtdk2InHSmjpZrNr1CX3PXtLeCiFZliSirMcO0jI6PcfYMM8Wy5vE84cLpvSiFJCR-YNj2SU0c5J2WKOM",
      isPopular: true,
      rating: 4.9,
      spicyOptions: ["Mild", "Medium", "Hot"],
      sideOptions: [
        { id: "naan", name: "Butter Naan", nameAr: "خبز نان بالزبدة", image: "https://lh3.googleusercontent.com/aida-public/AB6AXu8W7qTvktr1E-Wj0AW-6a89Qyb5lt9i2BCczihk75IG4PKXvnyPgxSR18DjeMkffeqAFLeniEHjOnuOnFme95nFajfLwaLKd1sGgvthFUlnjgRCycaSZCDJc6c4ROSvfz0-lASsH1ZPYfELdEP9clfcdPCcFU3DxgUcJ4JGhs74BAEDp05SfFKZraPHrMchkN-dqcRzLwgHKWBtyHFQPO4FODG4EfMzWs_9HEgjvPn1BrLoq_LDNU6TknOWIsk1NL-4NhKJOLfeB0", price: 0.0 },
        { id: "fries", name: "French Fries", nameAr: "بطاطا مقلية", image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBDEuXbtXRUbd-DYeSdIDbjUZTWn7C37eRHKtafAPfSC_5GvmjGFN6Ziau_dATPg40ydoHFZZ4QqXLHsPaKc8AM0VIFLD_Gu19aKzb0bKbTQCFRSzjeev3gogbfhdx99cJtiI8D8Ap-oHcDfdkoT9kncyQRm2dyFuCQMCHUGo7EuLCGnuNmUHkz0LUSBLV_5Hlwk7PUM9hmq6AifQIRaNQJ1CQnhQidH0dDbK1O4YloqhLLo4NKFh-MAD5aFatD_MKnDzygKlydnds", price: 0.50 },
        { id: "rice", name: "Basmati Rice", nameAr: "أرز بسمتي فاخر", image: "https://lh3.googleusercontent.com/aida-public/AB6AXuA-E9-pkqVP8r26v8NuDTOPjOv5ljaqFAv7tNxxpzB2Aio6bdGXfCuCPdfiee8JYhuos0dL7Gt9o8R__4bALB0vIQwHx1ziu7iTylcV2AtO-mjYJdJP4iemUv7B_bH2-Sj9_juXLe66Xt_bIklM0wg3xjx3mHYfPNirghuttg3AkBwz4EVGdGb44bZNbNVIEqXkRx1NMEPaRDN71J0RaYox9IduyuHYXnUCMRAVYPWHItWvDh6PKiQo9EcbNXkbBeSc_p7qObGbe5w", price: 0.80 }
      ],
      isDeleted: false
    },
    {
      id: "g2",
      title: "Malai Boti Special",
      titleAr: "شيش طاووق كريمي (مالاي)",
      description: "Mildly spiced chicken cubes prepared in a rich cashew nut and heavy cream marinade for a buttery melt-in-the-mouth heritage taste.",
      descriptionAr: "مكعبات شيش طاووق منكهة ببهارات خفيفة متبلة بصلصة الكاجو الفاخرة والقشطة الطازجة لتذوب في الفم بطعم غني وشهي.",
      price: 9.20,
      categoryId: "grill",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuAK4NtGvmGbx63g3UJHL7AzDpD5ZYFQIWOuH6WtVSS6rN194vfNgRIhd8s3MWt7n57yuiuqWqmh-y_MU2I-myuyTUdoDgxJzu8_ZbFeWCSdbSmBFPj2RnYniL_vToOwTG-UtXbt8i5gcJwc4QPvGU3TUr8kVe67tfPmHv81HMlH7b7QzthKjoTAB2Us6vPzl-lefAuTWBW8cWL1C5GNJWO-7-d2kUZijBVKsYVwGJazTVU7Khm88WFm-FuvHPaqxnNsRbavvRJ9CtU",
      rating: 4.8,
      spicyOptions: ["Mild", "Medium"],
      sideOptions: [
        { id: "naan", name: "Butter Naan", nameAr: "خبز نان بالزبدة", image: "https://lh3.googleusercontent.com/aida-public/AB6AXu8W7qTvktr1E-Wj0AW-6a89Qyb5lt9i2BCczihk75IG4PKXvnyPgxSR18DjeMkffeqAFLeniEHjOnuOnFme95nFajfLwaLKd1sGgvthFUlnjgRCycaSZCDJc6c4ROSvfz0-lASsH1ZPYfELdEP9clfcdPCcFU3DxgUcJ4JGhs74BAEDp05SfFKZraPHrMchkN-dqcRzLwgHKWBtyHFQPO4FODG4EfMzWs_9HEgjvPn1BrLoq_LDNU6TknOWIsk1NL-4NhKJOLfeB0", price: 0.0 },
        { id: "fries", name: "French Fries", nameAr: "بطاطا مقلية", image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBDEuXbtXRUbd-DYeSdIDbjUZTWn7C37eRHKtafAPfSC_5GvmjGFN6Ziau_dATPg40ydoHFZZ4QqXLHsPaKc8AM0VIFLD_Gu19aKzb0bKbTQCFRSzjeev3gogbfhdx99cJtiI8D8Ap-oHcDfdkoT9kncyQRm2dyFuCQMCHUGo7EuLCGnuNmUHkz0LUSBLV_5Hlwk7PUM9hmq6AifQIRaNQJ1CQnhQidH0dDbK1O4YloqhLLo4NKFh-MAD5aFatD_MKnDzygKlydnds", price: 0.50 }
      ],
      isDeleted: false
    },
    {
      id: "g3",
      title: "Hariyali Green Grill",
      titleAr: "شيش طاووق هاريالي الأخضر",
      description: "Chicken breast pieces coated with a vibrant aromatic paste of fresh mint, cilantro, spinach, and fiery green chilies, charcoal-roasted.",
      descriptionAr: "قطع صدور الدجاج الشهية المغلفة بتتبيلة الأعشاب الخضراء الفواحة والنعناع والكزبرة والسبانخ مع لمسة من الفلفل الحار، مشوية على الفحم.",
      price: 8.75,
      categoryId: "grill",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuB8DnIJhRDZnirZg74h_zB2YUplD5VWIzfDry5BfxyMCiTHAw3IJszMylzmzxNEPasT4A9PTgHNo_3_Omt_NoFxF3oG1uXqvL64v22ZgIlhBDa6U8mw2RBvp8V81N8yNVDD2DDccY7U5sTBWeX35HJjx58z-n4t5B6rnaxpyTZWyMLgl3jojYQVmI4-eQQ0eLWm5cVCbOzjawf4jPsjDsJeAt-aPNgu6lcPMvvyuqlk3VFXzlwIHn_qaRiKrKXG3bNCeaMXpiF7z6I",
      isHerbal: true,
      rating: 4.7,
      spicyOptions: ["Medium", "Hot"],
      sideOptions: [
        { id: "naan", name: "Butter Naan", nameAr: "خبز نان بالزبدة", image: "https://lh3.googleusercontent.com/aida-public/AB6AXu8W7qTvktr1E-Wj0AW-6a89Qyb5lt9i2BCczihk75IG4PKXvnyPgxSR18DjeMkffeqAFLeniEHjOnuOnFme95nFajfLwaLKd1sGgvthFUlnjgRCycaSZCDJc6c4ROSvfz0-lASsH1ZPYfELdEP9clfcdPCcFU3DxgUcJ4JGhs74BAEDp05SfFKZraPHrMchkN-dqcRzLwgHKWBtyHFQPO4FODG4EfMzWs_9HEgjvPn1BrLoq_LDNU6TknOWIsk1NL-4NhKJOLfeB0", price: 0.0 },
        { id: "rice", name: "Basmati Rice", nameAr: "أرز بسمتي فاخر", image: "https://lh3.googleusercontent.com/aida-public/AB6AXuA-E9-pkqVP8r26v8NuDTOPjOv5ljaqFAv7tNxxpzB2Aio6bdGXfCuCPdfiee8JYhuos0dL7Gt9o8R__4bALB0vIQwHx1ziu7iTylcV2AtO-mjYJdJP4iemUv7B_bH2-Sj9_juXLe66Xt_bIklM0wg3xjx3mHYfPNirghuttg3AkBwz4EVGdGb44bZNbNVIEqXkRx1NMEPaRDN71J0RaYox9IduyuHYXnUCMRAVYPWHItWvDh6PKiQo9EcbNXkbBeSc_p7qObGbe5w", price: 0.80 }
      ],
      isDeleted: false
    },
    {
      id: "g4",
      title: "Authentic Afghani Tikka",
      titleAr: "شيش طاووق أفغاني أصيل",
      description: "A rich, non-spicy aromatic tandoor preparation featuring thick yogurt, black pepper, cardamom notes, and a dusting of tandoori herbs.",
      descriptionAr: "تحضير عطري غني غير حار متبل بالزبادي الكثيف، الفلفل الأسود، وحبات الهيل مع مزيج من الأعشاب الأفغانية المطبوخة بالتنور الأصيل.",
      price: 8.90,
      categoryId: "grill",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBc6QlKYTqTH-eyEeh5K7uIx_V1WPrpy0W5cFtwmxCXNrFLbHeln-mxmAWbcduinRBsYYKCj-SvibFnXrgc81O5D0TNZ1nlY8utn0HZ1ycZKiR0rDROjBXuhthSjyNSMCjcfTtYIfPf8LBnKAoeNaaXlIp9f67_99cpBx8tx2VrD85VKBlXKOuYAvyJji-Y0h2Fh5PL4F2ZZJBBhXNzG5_8VE5wrKIupR2HxbT0JBFmxc-FZMGCjYK1YEM4MdwKjlwX5vII-AEYHV0",
      rating: 4.6,
      spicyOptions: ["Mild"],
      sideOptions: [
        { id: "naan", name: "Butter Naan", nameAr: "خبز نان بالزبدة", image: "https://lh3.googleusercontent.com/aida-public/AB6AXu8W7qTvktr1E-Wj0AW-6a89Qyb5lt9i2BCczihk75IG4PKXvnyPgxSR18DjeMkffeqAFLeniEHjOnuOnFme95nFajfLwaLKd1sGgvthFUlnjgRCycaSZCDJc6c4ROSvfz0-lASsH1ZPYfELdEP9clfcdPCcFU3DxgUcJ4JGhs74BAEDp05SfFKZraPHrMchkN-dqcRzLwgHKWBtyHFQPO4FODG4EfMzWs_9HEgjvPn1BrLoq_LDNU6TknOWIsk1NL-4NhKJOLfeB0", price: 0.0 }
      ],
      isDeleted: false
    },
    {
      id: "g5",
      title: "Grill Kebabs Platter",
      titleAr: "طبق عائلي مشاوي مشكلة",
      description: "An ultimate royal dish combining skewers of Classic Tikka, Creamy Malai Boti, Kebab, and Garlic Wings. Served with garlic dip and butter naan.",
      descriptionAr: "طبق المشاوي الملكي الفاخر يجمع بين أسياخ شيش طاووق الكلاسيكي، مالاي كريمي بوتي، كباب دجاج وأجنحة متبلة، يقدم مع صلصة الثوم ونان الزبدة.",
      price: 15.50,
      categoryId: "grill",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuACQm4m5zIuq05Y89DYU2kVeLVBPihsk5pO2ifIZ8Uke6YG180wLT-uwADAVa0Lp_fwKzxXYN76vaEWe0LXSyPffTdV5VivmXrcBfjnW42AWyKsj-6Bq5zZcVAE6C6YEp4dVt0XeGpNTYQmWPc-TOuV45rOGxs4Vijb9sGMtMSct4X3SMMMA6Xgk3n17CN2m4dHzEnLwpjqQOFX0lzvOaZdWvncJgeTT1vDGVesEeBDQWhlWLZwghmcBEPqAlNiqWpxg7Z_A2KNTsY",
      isPopular: true,
      rating: 5.0,
      spicyOptions: ["Mild", "Medium", "Hot"],
      sideOptions: [
        { id: "naan", name: "Butter Naan", nameAr: "خبز نان بالزبدة", image: "https://lh3.googleusercontent.com/aida-public/AB6AXu8W7qTvktr1E-Wj0AW-6a89Qyb5lt9i2BCczihk75IG4PKXvnyPgxSR18DjeMkffeqAFLeniEHjOnuOnFme95nFajfLwaLKd1sGgvthFUlnjgRCycaSZCDJc6c4ROSvfz0-lASsH1ZPYfELdEP9clfcdPCcFU3DxgUcJ4JGhs74BAEDp05SfFKZraPHrMchkN-dqcRzLwgHKWBtyHFQPO4FODG4EfMzWs_9HEgjvPn1BrLoq_LDNU6TknOWIsk1NL-4NhKJOLfeB0", price: 0.0 },
        { id: "fries", name: "French Fries", nameAr: "بطاطا مقلية", image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBDEuXbtXRUbd-DYeSdIDbjUZTWn7C37eRHKtafAPfSC_5GvmjGFN6Ziau_dATPg40ydoHFZZ4QqXLHsPaKc8AM0VIFLD_Gu19aKzb0bKbTQCFRSzjeev3gogbfhdx99cJtiI8D8Ap-oHcDfdkoT9kncyQRm2dyFuCQMCHUGo7EuLCGnuNmUHkz0LUSBLV_5Hlwk7PUM9hmq6AifQIRaNQJ1CQnhQidH0dDbK1O4YloqhLLo4NKFh-MAD5aFatD_MKnDzygKlydnds", price: 0.50 }
      ],
      isDeleted: false
    },
    {
      id: "s1",
      title: "Crinkle Cut Fries",
      titleAr: "بطاطا مقلية متموجة كرانشي",
      description: "Perfectly golden crispy crinkle cut fries seasoned with our signature tandoori spice salt blend.",
      descriptionAr: "بطاطا مقلية ذهبية متموجة ومقرمشة متبلة بملح بهارات التندوري الكلاسيكية الخاصة بنا.",
      price: 1.80,
      categoryId: "sides",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBDEuXbtXRUbd-DYeSdIDbjUZTWn7C37eRHKtafAPfSC_5GvmjGFN6Ziau_dATPg40ydoHFZZ4QqXLHsPaKc8AM0VIFLD_Gu19aKzb0bKbTQCFRSzjeev3gogbfhdx99cJtiI8D8Ap-oHcDfdkoT9kncyQRm2dyFuCQMCHUGo7EuLCGnuNmUHkz0LUSBLV_5Hlwk7PUM9hmq6AifQIRaNQJ1CQnhQidH0dDbK1O4YloqhLLo4NKFh-MAD5aFatD_MKnDzygKlydnds",
      rating: 4.5,
      spicyOptions: ["Standard"],
      sideOptions: [],
      isDeleted: false
    },
    {
      id: "s2",
      title: "Artisanal Hummus Dip",
      titleAr: "حمص بلدي بالطحينة وزيت الزيتون",
      description: "Creamy traditional chickpea puree blended with fine sesame tahini, local virgin olive oil, and lemon.",
      descriptionAr: "مهروس الحمص التقليدي الناعم الممزوج بالطحينة السمسمية الفاخرة وعصير الليمون والزيت البلدي البكر.",
      price: 2.20,
      categoryId: "sides",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuAK4NtGvmGbx63g3UJHL7AzDpD5ZYFQIWOuH6WtVSS6rN194vfNgRIhd8s3MWt7n57yuiuqWqmh-y_MU2I-myuyTUdoDgxJzu8_ZbFeWCSdbSmBFPj2RnYniL_vToOwTG-UtXbt8i5gcJwc4QPvGU3TUr8kVe67tfPmHv81HMlH7b7QzthKjoTAB2Us6vPzl-lefAuTWBW8cWL1C5GNJWO-7-d2kUZijBVKsYVwGJazTVU7Khm88WFm-FuvHPaqxnNsRbavvRJ9CtU",
      rating: 4.7,
      spicyOptions: ["Standard"],
      sideOptions: [],
      isDeleted: false
    },
    {
      id: "l1",
      title: "Fresh Fattoush Salad",
      titleAr: "سلطة فتوش لبنانية بدبس الرمان",
      description: "A crisp traditional blend of garden-fresh vegetables, radishes, purslane, tossed in a sour sumac vinaigrette, and topped with crunchy fried pita bread.",
      descriptionAr: "مزيج منعش من الخضروات البلدية كالخيار والطماطم والجرجير بصلصة السماق الحامضة ودبس الرمان مع قطع الخبز المقرمشة.",
      price: 2.50,
      categoryId: "salads",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuAZNpJx-5V445o-FP-AgceF_VuK126rj1HB5E0iDY2vz17VqqflrY2f0s96vBR2gNsx51f6rfLa9zOaVQcbwCjT9SzKMjyKSjJuGah3nOy7yrexLig-aWz-DqNxFhEJbqPgSqSrssy3cDNaDzaEyEi0PLrZ4uroYGVVzF2Q75TLsASbhu_uTnuYRntYcxyXSrLRe3ESAOx84ZO25rwG10ds1ZQpj9k1O2Otb-LMtL9qHZYqW2LMDRKbCNathWr1d08Pp_4jjkzFC0Q",
      rating: 4.6,
      spicyOptions: ["Standard"],
      sideOptions: [],
      isDeleted: false
    },
    {
      id: "d1",
      title: "Fresh Mint Lemonade",
      titleAr: "ليمون بالنعناع فريش بارد",
      description: "Chilled zesty lemonade blended with fresh local hand-picked mint leaves for maximum revitalizing energy.",
      descriptionAr: "عصير الليمون المنعش الغني والنعناع البلدي الطازج مع قطع الثلج المفتت، رائع مع المشاوي.",
      price: 1.50,
      categoryId: "drinks",
      image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBc6QlKYTqTH-eyEeh5K7uIx_V1WPrpy0W5cFtwmxCXNrFLbHeln-mxmAWbcduinRBsYYKCj-SvibFnXrgc81O5D0TNZ1nlY8utn0HZ1ycZKiR0rDROjBXuhthSjyNSMCjcfTtYIfPf8LBnKAoeNaaXlIp9f67_99cpBx8tx2VrD85VKBlXKOuYAvyJji-Y0h2Fh5PL4F2ZZJBBhXNzG5_8VE5wrKIupR2HxbT0JBFmxc-FZMGCjYK1YEM4MdwKjlwX5vII-AEYHV0",
      rating: 4.9,
      spicyOptions: ["Cold"],
      sideOptions: [],
      isDeleted: false
    }
  ];

  for (const prod of products) {
    const ref = db.collection("products").doc(prod.id);
    batch.set(ref, prod);
  }

  // Delivery Zones
  const zones = [
    { id: "z1", name: "Shmeisani & Abdali", nameAr: "الشميساني والعبدلي", fee: 1.50, minOrder: 5.00 },
    { id: "z2", name: "Khalda & Tla' Al-Ali", nameAr: "خلدا وتلاع العلي", fee: 2.00, minOrder: 5.00 },
    { id: "z3", name: "Dabouq & Al-Madinah", nameAr: "دابوق وشارع المدينة", fee: 2.50, minOrder: 7.00 },
    { id: "z4", name: "Al-Barsha style Delivery, Amman Outskirts", nameAr: "ضواحي عمان الشرقية والجنوبية", fee: 3.50, minOrder: 10.00 }
  ];

  for (const zone of zones) {
    const ref = db.collection("delivery_zones").doc(zone.id);
    batch.set(ref, zone);
  }

  // Coupons
  const coupons = [
    { id: "c1", code: "TIKKAFIRST20", discountType: "Percentage", value: 20, minOrder: 5.00, description: "Get 20% off your first ever order!", descriptionAr: "خصم 20% على طلبك الأول من شيش طاووق!", expiryDate: "2030-12-31T23:59:59.000Z", usageLimit: 1000, usedCount: 0, isDeleted: false },
    { id: "c2", code: "AMMANLOVE", discountType: "Percentage", value: 10, minOrder: 10.00, description: "Receive 10% off as an Amman client.", descriptionAr: "خصم 10% لبلد النشامى عمان الحبيبة.", expiryDate: "2030-12-31T23:59:59.000Z", usageLimit: 1000, usedCount: 0, isDeleted: false },
    { id: "c3", code: "FREEDEL", discountType: "Fixed", value: 2.50, minOrder: 15.00, description: "Get JOD 2.50 off delivery fee on orders over 15 JOD.", descriptionAr: "توصيل مجاني لقيمة التوصيل 2.50 دينار للطلبات فوق 15 دينار.", expiryDate: "2030-12-31T23:59:59.000Z", usageLimit: 1000, usedCount: 0, isDeleted: false }
  ];

  for (const coup of coupons) {
    const ref = db.collection("coupons").doc(coup.id);
    batch.set(ref, coup);
  }

  // System Settings
  const settings = {
    workingHoursStart: "12:00",
    workingHoursEnd: "01:00",
    pointsPerJOD: 1000,
    pointsPerFreeMeal: 20000,
    isEmergencyClosed: false,
    taxEnabled: true,
    taxRate: 5
  };

  const settingsRef = db.collection("settings").doc("system_settings");
  batch.set(settingsRef, settings);

  await batch.commit();

  return { success: true, seededItems: { categories: categories.length, products: products.length, zones: zones.length, coupons: coupons.length } };
});

export const sendBroadcastNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  const uid = request.auth.uid;
  const adminSnap = await db.collection("admins").doc(uid).get();
  if (!adminSnap.exists) {
    throw new HttpsError("permission-denied", "Access Denied: Only administrators can broadcast marketing messages.");
  }

  const title = String(request.data?.title || "").trim();
  const body = String(request.data?.body || "").trim();

  if (!title || !body) {
    throw new HttpsError("invalid-argument", "Title and Body arguments are required.");
  }

  const message = {
    notification: { title, body },
    topic: "all",
  };

  await getMessaging().send(message);
  return { success: true };
});

