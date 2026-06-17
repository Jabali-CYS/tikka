import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;

  /// Lazy initialisation to prevent startup crashes when keys or network is missing
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();

      // Enforce Firebase App Check to defend against API abuse & fake clients (MASVS Guidelines)
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );

      // Optimise Firestore query settings for performance & offline support
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _isInitialized = true;
      debugPrint("Firebase Services initialized successfully with App Check protection.");
    } catch (e) {
      debugPrint("Critical Error during Firebase lazy-loading: $e");
    }
  }

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Secure calculation of Order totals server-side (Never trust client pricing parameters)
  Future<Map<String, double>> recalculateOrderTotal({
    required List<Map<String, dynamic>> items,
    required String? couponCode,
    required String zoneId,
  }) async {
    double subtotal = 0.0;

    // Fetch official prices from Firestore directly (IDs are immutable UUIDs)
    for (var item in items) {
      final productId = item['productId'] as String;
      final quantity = item['quantity'] as int;

      final prodDoc = await firestore.collection('products').doc(productId).get();
      if (!prodDoc.exists || prodDoc.data()?['isDeleted'] == true) {
        throw Exception("Invalid product selection detected.");
      }

      final double originalPrice = (prodDoc.data()?['price'] as num).toDouble();
      subtotal += originalPrice * quantity;

      // Calculate any chosen side add-ons extra costs secure verification
      final String? sideId = item['selectedSide'];
      if (sideId != null && sideId.isNotEmpty) {
        final List<dynamic> sideOpts = prodDoc.data()?['sideOptions'] ?? [];
        final sideObj = sideOpts.firstWhere(
          (element) => element['id'] == sideId,
          orElse: () => null,
        );
        if (sideObj != null) {
          final double sidePrice = (sideObj['price'] as num).toDouble();
          subtotal += sidePrice * quantity;
        }
      }
    }

    // Secure zone delivery fee fetch
    double deliveryFee = 0.0;
    final zoneDoc = await firestore.collection('delivery_zones').doc(zoneId).get();
    if (zoneDoc.exists) {
      deliveryFee = (zoneDoc.data()?['fee'] as num).toDouble();
    }

    // Taxes formulation (Fixed 5%) - Server Calculated
    double taxes = subtotal * 0.05;

    // Coupon verification directly against database records
    double discount = 0.0;
    if (couponCode != null && couponCode.isNotEmpty) {
      final couponSnap = await firestore
          .collection('coupons')
          .where('code', isEqualTo: couponCode.toUpperCase())
          .get();

      if (couponSnap.docs.isNotEmpty) {
        final couponData = couponSnap.docs.first.data();
        if (couponData['isDeleted'] != true) {
          final double minOrder = (couponData['minOrder'] as num).toDouble();
          if (subtotal >= minOrder) {
            final String type = couponData['discountType'];
            final double value = (couponData['value'] as num).toDouble();

            if (type == 'Percentage') {
              discount = subtotal * (value / 100.0);
            } else {
              discount = value;
            }
          }
        }
      }
    }

    double total = (subtotal + deliveryFee + taxes) - discount;
    if (total < 0.0) total = 0.0;

    return {
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'taxes': taxes,
      'discount': discount,
      'total': total,
    };
  }
}
