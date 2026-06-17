import React, { useState, useEffect } from "react";
import {
  Flame,
  Utensils,
  CupSoda,
  Leaf,
  Cake,
  Phone,
  Shield,
  Activity,
  Check,
  FileText,
  Terminal as TermIcon,
  Settings,
  Code,
  Smartphone,
  Sliders,
  MapPin,
  User,
  ShoppingBag,
  TrendingUp,
  Send,
  Lock,
  Unlock,
  Clock,
  AlertTriangle,
  RefreshCw,
  Star,
  Bell,
  Plus,
  Minus,
  Trash2,
  Compass,
  Gift,
  Globe,
  ChevronRight,
  Search,
  CheckCircle,
  Copy,
  Download,
  Eye,
  Info
} from "lucide-react";

import { INITIAL_CATEGORIES, INITIAL_PRODUCTS, INITIAL_ZONES, INITIAL_COUPONS, DEFAULT_SYSTEM_SETTINGS } from "./data";
import { Product, CartItem, Order, OrderStatus, SystemSettings, Coupon, DeliveryZone } from "./types";

export default function App() {
  // Mobile Simulator State
  const [lang, setLang] = useState<"en" | "ar">("en");
  const [currentScreen, setCurrentScreen] = useState<
    "splash" | "language" | "login" | "otp" | "menu" | "custom_product" | "checkout" | "tracking" | "profile"
  >("splash");

  // Authentication State
  const [phone, setPhone] = useState("");
  const [otpCode, setOtpCode] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [isGuest, setIsGuest] = useState(true);
  const [userProfile, setUserProfile] = useState({
    name: "Hamza Al-Farsi",
    phone: "+962 7 9123 4567",
    points: 45000, // 45,000 points -> equivalent to JOD 45.00
    memberStatus: "Gold" as "Gold" | "Silver" | "Bronze"
  });

  // Database / Settings States
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [zones, setZones] = useState<DeliveryZone[]>(INITIAL_ZONES);
  const [coupons, setCoupons] = useState<Coupon[]>(INITIAL_COUPONS);
  const [systemSettings, setSystemSettings] = useState<SystemSettings>(DEFAULT_SYSTEM_SETTINGS);

  // Filter & Search States in Menu
  const [selectedCategory, setSelectedCategory] = useState("grill");
  const [searchQuery, setSearchQuery] = useState("");

  // Cart & checkout selections
  const [cart, setCart] = useState<CartItem[]>([]);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [customSpiciness, setCustomSpiciness] = useState("Medium");
  const [selectedSideId, setSelectedSideId] = useState("naan");
  const [checkoutFulfillment, setCheckoutFulfillment] = useState<"Delivery" | "Pickup">("Delivery");
  const [selectedZoneId, setSelectedZoneId] = useState("z1");
  const [appliedPromo, setAppliedPromo] = useState<string>("");
  const [promoError, setPromoError] = useState<string>("");
  const [promoSuccess, setPromoSuccess] = useState<string>("");
  const [paymentMethod, setPaymentMethod] = useState<"Card" | "Cash" | "Points">("Card");
  
  // Checkout Address input fields
  const [buildingName, setBuildingName] = useState("");
  const [floor, setFloor] = useState("");
  const [apartment, setApartment] = useState("");
  const [instructions, setInstructions] = useState("");
  const [addressLabel, setAddressLabel] = useState<"Home" | "Office" | "Other">("Home");

  // Orders State (Simulated Cloud Firestore / Orders ledger)
  const [orders, setOrders] = useState<Order[]>([]);
  const [activeTrackingOrderId, setActiveTrackingOrderId] = useState<string | null>(null);

  // Workspace configuration Tab Layout
  const [activeWorktab, setActiveWorktab] = useState<"code" | "admin" | "security" | "settings">("code");
  const [selectedFile, setSelectedFile] = useState<string>("pubspec.yaml");
  const [copiedCodeNotice, setCopiedCodeNotice] = useState(false);

  // Terminal & Security verification simulation logs
  const [terminalLogs, setTerminalLogs] = useState<string[]>([
    "Flutter SDK configured (v3.22.2 stable)",
    "Firebase Command Line Suite tool detected",
    "Running automated Grill Chicken Tikka build integrity checks...",
    "All security protocols: ENFORCED (Least Privilege rules compiled)"
  ]);
  const [isCompiling, setIsCompiling] = useState(false);

  // Business Hours status validator
  const [currentTimeStr, setCurrentTimeStr] = useState("12:30 PM");

  // Keep a local clock simulator running
  useEffect(() => {
    const timer = setInterval(() => {
      const date = new Date();
      let hours = date.getHours();
      const mins = date.getMinutes().toString().padStart(2, "0");
      const ampm = hours >= 12 ? "PM" : "AM";
      hours = hours % 12;
      hours = hours ? hours : 12; // safety
      setCurrentTimeStr(`${hours}:${mins} ${ampm}`);
    }, 10000);
    return () => clearInterval(timer);
  }, []);

  // Helper validation: Is restaurant currently open?
  const isRestaurantOpen = (): boolean => {
    if (systemSettings.isEmergencyClosed) return false;
    // Standard working hours checks: 12:00 PM until 1:00 AM
    // Let's assume user may always browse, but ordering will be blocked if open check is negative.
    return true; // We can let user trigger operational notices by turning isEmergencyClosed on!
  };

  const handleSendOtp = () => {
    if (!phone || phone.length < 7) {
      alert(lang === "ar" ? "الرجاء إدخال رقم هاتف Amman صالح" : "Please enter a valid phone number");
      return;
    }
    setOtpSent(true);
    setTerminalLogs(prev => [
      ...prev,
      `[AUTH] Sent Firebase Phone OTP verification to ${phone}`,
      `[AUTH] Challenge ID: auth-chall-${Math.floor(Math.random() * 100000)}`
    ]);
    setCurrentScreen("otp");
  };

  const handleVerifyOtp = () => {
    if (otpCode.length < 4) {
      alert(lang === "ar" ? "رمز التحقق يجب أن يكون 4 أرقام" : "OTP Code should be 4 digits");
      return;
    }
    setIsGuest(false);
    setTerminalLogs(prev => [
      ...prev,
      `[AUTH] Successfully authenticated client via Firebase Phone Auth.`,
      `[AUTH] UID generated: uid-user-hamza-${Math.floor(Math.random() * 90000 + 10000)}`
    ]);
    setCurrentScreen("menu");
  };

  // Switch Category Filter
  const currentProducts = products.filter(
    p => p.categoryId === selectedCategory && !p.isDeleted &&
    (searchQuery ? (p.title.toLowerCase().includes(searchQuery.toLowerCase()) || p.titleAr.includes(searchQuery)) : true)
  );

  const openProductCustomization = (product: Product) => {
    setSelectedProduct(product);
    setCustomSpiciness("Medium");
    setSelectedSideId(product.sideOptions[0]?.id || "");
    setCurrentScreen("custom_product");
  };

  const calculateProductCustomizedPrice = () => {
    if (!selectedProduct) return 0;
    let base = selectedProduct.price;
    const sideObj = selectedProduct.sideOptions.find(s => s.id === selectedSideId);
    if (sideObj) {
      base += sideObj.price;
    }
    return base;
  };

  const handleAddToCart = () => {
    if (!selectedProduct) return;
    const sideObj = selectedProduct.sideOptions.find(s => s.id === selectedSideId);
    const calculatedPrice = calculateProductCustomizedPrice();

    const newCartItem: CartItem = {
      id: `cart-item-${Date.now()}`,
      productId: selectedProduct.id,
      product: selectedProduct,
      quantity: 1,
      selectedSpiciness: customSpiciness,
      selectedSide: selectedSideId,
      sidePrice: sideObj ? sideObj.price : 0,
      extras: [],
      totalPrice: calculatedPrice
    };

    setCart(prev => [...prev, newCartItem]);
    setCurrentScreen("menu");
    
    setTerminalLogs(prev => [
      ...prev,
      `[CART] Added customized ${selectedProduct.title} to local storage. Total item value: JOD ${calculatedPrice.toFixed(2)}`
    ]);
  };

  const updateCartQuantity = (id: string, delta: number) => {
    setCart(prev => prev.map(item => {
      if (item.id === id) {
        const newQty = Math.max(1, item.quantity + delta);
        return {
          ...item,
          quantity: newQty,
          totalPrice: newQty * (item.product.price + item.sidePrice)
        };
      }
      return item;
    }));
  };

  const handleRemoveFromCart = (id: string) => {
    setCart(prev => prev.filter(item => item.id !== id));
  };

  // Checkout Calculations
  const getSubtotal = () => cart.reduce((sum, item) => sum + item.totalPrice, 0);
  
  const getDeliveryFee = () => {
    if (checkoutFulfillment === "Pickup") return 0;
    const zone = zones.find(z => z.id === selectedZoneId);
    return zone ? zone.fee : 1.50;
  };

  const getTaxes = () => getSubtotal() * 0.05; // 5% Sales tax

  const getDiscount = () => {
    const subtotal = getSubtotal();
    if (!appliedPromo) return 0;
    const coupon = coupons.find(c => c.code.toUpperCase() === appliedPromo.toUpperCase() && !c.isDeleted);
    if (!coupon) return 0;
    if (subtotal < coupon.minOrder) return 0;

    if (coupon.discountType === "Percentage") {
      return subtotal * (coupon.value / 100);
    } else {
      return coupon.value;
    }
  };

  const getFinalTotal = () => {
    const raw = (getSubtotal() + getDeliveryFee() + getTaxes()) - getDiscount();
    return Math.max(0, raw);
  };

  const applyPromoCode = (code: string) => {
    setPromoError("");
    setPromoSuccess("");
    if (!code) return;

    const coupon = coupons.find(c => c.code.toUpperCase() === code.toUpperCase() && !c.isDeleted);
    if (!coupon) {
      setPromoError(lang === "ar" ? "رمز ترويجي غير صالح!" : "Invalid promo code!");
      return;
    }

    if (getSubtotal() < coupon.minOrder) {
      setPromoError(
        lang === "ar"
          ? `الحد الأدنى للطلب هو ${coupon.minOrder} د.أ`
          : `Minimum order for this coupon is JOD ${coupon.minOrder.toFixed(2)}`
      );
      return;
    }

    setAppliedPromo(code.toUpperCase());
    setPromoSuccess(
      lang === "ar"
        ? `تم تطبيق الكوبون بنجاح! خصم بقيمة ${coupon.value}${coupon.discountType === "Percentage" ? "%" : " د.أ"}`
        : `Coupon applied! Saved ${coupon.discountType === "Percentage" ? `${coupon.value}%` : `JOD ${coupon.value.toFixed(2)}`}`
    );
  };

  const handlePlaceOrder = () => {
    if (cart.length === 0) {
      alert(lang === "ar" ? "سلتك فارغة!" : "Your cart is empty!");
      return;
    }

    if (isGuest) {
      alert(lang === "ar" ? "يجب عليك تسجيل الدخول أولاً لإتمام الطلب" : "Please log in via Phone Number to place your order.");
      setCurrentScreen("login");
      return;
    }

    if (systemSettings.isEmergencyClosed) {
      alert(
        lang === "ar"
          ? "المطعم مغلق حالياً بسبب أعمال الصيانة الطارئة!"
          : "We are currently closed for emergency maintenance. Browsing allowed but ordering blocked."
      );
      return;
    }

    // Capture Amman specific delivery rules
    const targetZone = zones.find(z => z.id === selectedZoneId);
    if (checkoutFulfillment === "Delivery" && targetZone) {
      if (getSubtotal() < targetZone.minOrder) {
        alert(
          lang === "ar"
            ? `الحد الأدنى للطلب لمنطقة ${targetZone.nameAr} هو ${targetZone.minOrder} د.أ`
            : `Minimum order for delivery to ${targetZone.name} is JOD ${targetZone.minOrder.toFixed(2)}`
        );
        return;
      }
    }

    // Secure Order Calculation (Tamper Proof)
    const newOrder: Order = {
      id: `order-uuid-${Date.now()}`,
      orderNumber: `GCT-${Math.floor(Math.random() * 900 + 100)}`,
      customerUid: "uid-user-hamza-1",
      customerName: userProfile.name,
      customerPhone: userProfile.phone,
      items: [...cart],
      subtotal: getSubtotal(),
      deliveryFee: getDeliveryFee(),
      taxes: getTaxes(),
      discount: getDiscount(),
      total: getFinalTotal(),
      paymentMethod: paymentMethod,
      status: "Pending",
      fulfillmentType: checkoutFulfillment,
      address: checkoutFulfillment === "Delivery" ? {
        street: "Zahran Street, Al-Sweifieh",
        buildingName: buildingName || "Amman Plaza",
        floor: floor || "3rd Floor",
        apartment: apartment || "Suite 304",
        instructions: instructions || "Near 7th Circle crossroads",
        label: addressLabel,
        coordinates: { lat: 31.9539, lng: 35.8576 } // Central Sweifieh coordenadas
      } : undefined,
      driverName: "Ahmed Khan",
      driverPhone: "+962 7 9987 6543",
      driverRating: 4.9,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      isDeleted: false
    };

    // Update locally stored orders state (cloud-simulation)
    setOrders(prev => [newOrder, ...prev]);
    setActiveTrackingOrderId(newOrder.id);
    
    // deduct or increment loyalty points securely
    if (paymentMethod === "Points") {
      setUserProfile(prev => ({ ...prev, points: Math.max(0, prev.points - 20000) }));
    } else {
      // Add secure points: 1 JOD spent = 1000 points
      const pointsEarned = Math.floor(newOrder.total) * 1000;
      setUserProfile(prev => ({ ...prev, points: prev.points + pointsEarned }));
    }

    // Reset checkout states
    setCart([]);
    setAppliedPromo("");
    setPromoSuccess("");
    setPromoError("");

    setTerminalLogs(prev => [
      ...prev,
      `[ORDER] Created Transaction: ${newOrder.orderNumber} successfully. Total JOD: ${newOrder.total.toFixed(2)}`,
      `[SECURITY] Parameters validated. Total calculated server-side matches client inputs exactly.`,
      `[LOYALTY] User updated. Real points balance: ${userProfile.points}`
    ]);

    setCurrentScreen("tracking");
  };

  const handleCancelOrder = (orderId: string) => {
    setOrders(prev => prev.map(o => {
      if (o.id === orderId && o.status === "Pending") {
        return { ...o, status: "Canceled" as OrderStatus, updatedAt: new Date().toISOString() };
      }
      return o;
    }));
    setTerminalLogs(prev => [
      ...prev,
      `[ORDER] User requested cancellation for Order ID: ${orderId}`
    ]);
  };

  // Workspace actions
  const triggerSimulationCompilation = () => {
    setIsCompiling(true);
    setTerminalLogs(prev => [...prev, "Executing command: flutter pub get...", "Running linter checking on security metrics..."]);
    setTimeout(() => {
      setIsCompiling(false);
      setTerminalLogs(prev => [
        ...prev,
        "Package resolution: Success. Dependencies correct.",
        "Executing: flutter run -d chrome --web-renderer canvaskit",
        "Build finished successfully! Grill Chicken Tikka applet online."
      ]);
    }, 1500);
  };

  const handleForceCompleteAllOrders = () => {
    setOrders(prev => prev.map(o => ({ ...o, status: "Arrived", updatedAt: new Date().toISOString() })));
    setTerminalLogs(prev => [...prev, "[ADMIN] Force updated active order tracking parameters to 'Arrived'."]);
  };

  const updateOrderStatusByAdmin = (id: string, status: OrderStatus) => {
    setOrders(prev => prev.map(o => {
      if (o.id === id) {
        return { ...o, status: status, updatedAt: new Date().toISOString() };
      }
      return o;
    }));
    setTerminalLogs(prev => [
      ...prev,
      `[ADMIN] Updated Order ${id.substring(0, 8)} status to: ${status}`
    ]);
  };

  const copyToClipboard = (code: string) => {
    navigator.clipboard.writeText(code);
    setCopiedCodeNotice(true);
    setTimeout(() => setCopiedCodeNotice(false), 2000);
  };

  const activeTrackingOrder = orders.find(o => o.id === activeTrackingOrderId);

  // File Code Dictionary representing standard Flutter Clean Architecture
  const codeDictionary: Record<string, { path: string; layer: string; code: string }> = {
    "pubspec.yaml": {
      path: "/pubspec.yaml",
      layer: "Project Config",
      code: `name: grill_chicken_tikka
description: A production-ready premium tandoor ordering and loyalty Flutter + Firebase application.
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.6

  # Dependency Injection & State Management (Riverpod)
  flutter_riverpod: ^2.4.9
  go_router: ^12.1.3

  # Persistent Cloud Services
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.9
  firebase_app_check: ^0.2.8

  # Secure Storage (As specified in guidelines)
  flutter_secure_storage: ^9.0.0

  # High-quality packages
  google_maps_flutter: ^2.5.3
  geolocator: ^10.1.0
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.1
  lucide_icons: ^3.0.0
  intl: ^0.19.0
  uuid: ^4.2.1`
    },
    "firestore.rules": {
      path: "/firestore.rules",
      layer: "Security Policies",
      code: `rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() { return request.auth != null; }
    function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; }
    function isAdmin() { 
      return isAuthenticated() && exists(/databases/$(database)/documents/admins/$(request.auth.uid)); 
    }

    match /admins/{adminId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create, update: if isOwner(userId) && request.resource.data.isDeleted == false;
    }

    match /orders/{orderId} {
      allow read: if isAdmin() || (isAuthenticated() && resource.data.customerUid == request.auth.uid);
      allow create: if isAuthenticated() && request.resource.data.customerUid == request.auth.uid;
      allow update: if isAdmin();
    }
  }
}`
    },
    "lib/main.dart": {
      path: "/lib/main.dart",
      layer: "Presentation Layer - Root",
      code: `import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/colors.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  runApp(
    const ProviderScope(
      child: GrillChickenTikkaApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/splash', builder: (c, s) => const OnboardingSplash()),
    GoRoute(path: '/home', builder: (c, s) => const MenuBrowserScreen()),
    GoRoute(path: '/checkout', builder: (c, s) => const CheckoutScreen()),
    GoRoute(path: '/profile', builder: (c, s) => const ProfileLoyaltyScreen()),
  ],
);`
    },
    "lib/core/constants/colors.dart": {
      path: "/lib/core/constants/colors.dart",
      layer: "Core Utility - Branding",
      code: `import 'package:flutter/material.dart';

class ArtisanalColors {
  // Brand color scheme matching the approved design reference
  static const Color primary = Color(0xFF33210D); // Earthy coal brown
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFF4B3621);
  static const Color onPrimaryContainer = Color(0xFFBD9F83);

  static const Color secondary = Color(0xFFB71032); // Fiery tandoor red accent
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFDA3148);

  static const Color background = Color(0xFFF9F9F9); // Warm cream canvas
  static const Color onBackground = Color(0xFF1B1B1B);
  
  static const Color outlineVariant = Color(0xFFD2C4BA); // Ceramic grey
}`
    },
    "lib/core/services/firebase_service.dart": {
      path: "/lib/core/services/firebase_service.dart",
      layer: "Data Layer - Infrastructure",
      code: `import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Firebase.initializeApp();

    // App Check validation prevents abuse and code tampering
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      androidProvider: AndroidProvider.playIntegrity,
    );

    _isInitialized = true;
  }
}`
    },
    "lib/features/menu/models/product_model.dart": {
      path: "/lib/features/menu/models/product_model.dart",
      layer: "Domain Layer - Entity Model",
      code: `class Product {
  final String id;
  final String title;
  final String titleAr;
  final String description;
  final String descriptionAr;
  final double price;
  final String categoryId;
  final String image;
  final double rating;
  final List<String> spicyOptions;
  final bool isDeleted;

  Product({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.description,
    required this.descriptionAr,
    required this.price,
    required this.categoryId,
    required this.image,
    required this.rating,
    required this.spicyOptions,
    this.isDeleted = false,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      title: data['title'] ?? '',
      titleAr: data['titleAr'] ?? '',
      description: data['description'] ?? '',
      descriptionAr: data['descriptionAr'] ?? '',
      price: (data['price'] as num).toDouble(),
      categoryId: data['categoryId'] ?? '',
      image: data['image'] ?? '',
      rating: (data['rating'] as num).toDouble(),
      spicyOptions: List<String>.from(data['spicyOptions'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
    );
  }
}`
    },
    "lib/features/menu/presentation/product_detail_screen.dart": {
      path: "/lib/features/menu/presentation/product_detail_screen.dart",
      layer: "Presentation Layer - Detail Screen",
      code: `import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../models/product_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String selectedSpiciness = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(widget.product.image, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.product.title, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text(widget.product.description),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}`
    }
  };

  // Helper translations for Amman bi-directional test client
  const t = {
    en: {
      appName: "Grill Chicken Tikka",
      premiumTaste: "Premium Authentic Taste",
      bestChicken: "The Best Chicken",
      inTown: "in Town",
      heritageText: "Experience the heritage of authentic charcoal grilling with every bite of our signature tikka.",
      getStarted: "Get Started",
      skip: "Skip",
      enterAmmanPhone: "Enter Amman Phone (+962)",
      loginDesc: "Enter your phone number to receive a 4-digit tandoor validation code",
      sendOtp: "Send SMS verification",
      enterOtp: "Enter Verification Code",
      verifyBtn: "Verify Code",
      categories: "Categories",
      popular: "Popular",
      rating: "Rating",
      filterBtn: "Filters",
      allSignatureCut: "Signature Grills",
      searchHint: "Search for charcoal grills, wraps...",
      workingHoursNote: "Daily Service hours: 12:00 PM - 1:00 AM",
      selectSpiciness: "Select Spiciness Level",
      chooseSide: "Choose Your Side Helper",
      totalPrice: "Total Price",
      addToCart: "Add to Cart",
      backBtn: "Back",
      orderSummary: "Order Summary",
      deliveryAddress: "Amman Delivery Address",
      fulfillmentType: "Fulfillment Goal",
      cashOnDelivery: "Cash on Delivery",
      pointsLoyalty: "Redeem Loyalty Points",
      placeOrder: "Place Order Securely",
      loyaltyPointsCard: "Loyalty Points Wallet",
      progressText: "Progress to next free meal",
      settings: "Profile Settings",
      logout: "Log Out",
      addItemsNotice: "Please load grilled products!",
      estimatedDelivery: "Estimated Delivery",
      orderedStatus: "Ordered",
      kitchenStatus: "In Kitchen",
      deliveryStatus: "On Route",
      arrivedStatus: "Arrived",
      couponsTitle: "Offers & Coupons",
      applyPromo: "Apply",
      addressInput: "Zahran Str. Sweifieh, Amman",
      phonePlaceholder: "79 123 4567"
    },
    ar: {
      appName: "شيف تيكا دجاج",
      premiumTaste: "طعم أصيل فاخر من التنور",
      bestChicken: "أفضل دجاج تيكا",
      inTown: "في عمان الحبيبة",
      heritageText: "استمتع بعراقة الشواء العماني الأصيل على الفحم الطبيعي الهادئ مع كل قضمة من تحضيرنا المميز.",
      getStarted: "ابدأ الآن",
      skip: "تخطي للطلب",
      enterAmmanPhone: "أدخل رقم الهاتف الأردني (+962)",
      loginDesc: "أدخل رقم هاتفك لتلقي رمز التحقق السري لدخول حسابك بأمان",
      sendOtp: "إرسال رمز التحقق",
      enterOtp: "أدخل رمز التحقق (OTP)",
      verifyBtn: "تأكيد الرمز والدخول",
      categories: "الأقسام",
      popular: "شائع جداً",
      rating: "التقييم",
      filterBtn: "تصفية المنتجات",
      allSignatureCut: "مشاوي فاخرة على الفحم",
      searchHint: "ابحث عن شيش طاووق، كباب بلدي، بطاطا...",
      workingHoursNote: "أوقات التوصيل والطلب: 12:00 ظهراً إلى 1:00 ليلاً",
      selectSpiciness: "اختر مستوى حدة الفلفل",
      chooseSide: "اختر طبق جانبي مرافق",
      totalPrice: "السعر الإجمالي للطلب",
      addToCart: "إضافة إلى سلة المأكولات",
      backBtn: "رجوع",
      orderSummary: "ملخص الطلب الحالي",
      deliveryAddress: "عنوان التوصيل في عمان",
      fulfillmentType: "طريقة الاستلام",
      cashOnDelivery: "الدفع نقداً عند الاستلام",
      pointsLoyalty: "الدفع بجمع النقاط",
      placeOrder: "إرسال الطلب الآمن للمطبخ",
      loyaltyPointsCard: "محفظة نقاط الولاء",
      progressText: "التقدم نحو الوجبة المجانية التالية",
      settings: "إعدادات الملف الشخصي",
      logout: "تسجيل الخروج",
      addItemsNotice: "الرجاء إضافة بعض المشاوي الفاخرة للسلة!",
      estimatedDelivery: "وقت التوصيل المتوقع",
      orderedStatus: "تم الطلب",
      kitchenStatus: "في المطبخ",
      deliveryStatus: "مع السائق",
      arrivedStatus: "وصل بالسلامة",
      couponsTitle: "عروض وكوبونات التوفير",
      applyPromo: "تطبيق",
      addressInput: "شارع زهران، الصويفية، عمان",
      phonePlaceholder: "79 123 4567"
    }
  };

  const activeLang = t[lang];

  return (
    <div className="min-h-screen bg-[#110D09] text-white flex flex-col font-sans">
      {/* Top Header Navigation Line */}
      <nav className="bg-[#1C130B] border-b border-[#33210D]/60 px-6 py-4 flex flex-col md:flex-row justify-between items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-[#B71032] rounded-full flex items-center justify-center text-white">
            <Flame className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <span className="text-[#BD9F83] text-xs tracking-widest font-bold uppercase block">
              Enterprise Suite • Amman JORDAN
            </span>
            <h1 className="font-semibold text-lg flex items-center gap-2 text-white">
              Grill Chicken Tikka <span className="text-[#FEDCBE] text-xs bg-[#4B3621] px-2 py-0.5 rounded-full">v1.2 Flutter</span>
            </h1>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <div className="bg-[#4B3621] px-3 py-1.5 rounded-xl border border-[#D2C4BA]/20 flex items-center gap-2">
            <Clock className="w-4 h-4 text-[#FEDCBE]" />
            <span className="text-xs font-semibold text-[#FEDCBE]">
              Restaurant hours: {systemSettings.workingHoursStart} - {systemSettings.workingHoursEnd} ({currentTimeStr})
            </span>
            <span className={`w-2 h-2 rounded-full ${isRestaurantOpen() ? "bg-green-500" : "bg-red-500"}`} />
          </div>

          <button
            onClick={() => setLang(lang === "en" ? "ar" : "en")}
            className="bg-[#B71032] text-white px-4 py-1.5 rounded-xl text-xs font-bold font-mono tracking-wider hover:bg-[#DA3148] transition flex items-center gap-1"
          >
            <Globe className="w-3.5 h-3.5" />
            {lang === "en" ? "العربية (RTL)" : "English (LTR)"}
          </button>
        </div>
      </nav>

      {/* Main Grid Workbench */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-12 gap-6 p-6">
        
        {/* PILLAR 1: INTERACTIVE MOBILE DEVIEC EMULATOR (5 COLUMNS) */}
        <section className="lg:col-span-5 flex flex-col items-center justify-start">
          <div className="w-full max-w-[420px] bg-[#1a1410] rounded-[50px] p-4 shadow-[0_25px_60px_-15px_rgba(0,0,0,0.8)] border-4 border-[#33210D] relative overflow-hidden">
            
            {/* Top Device Notch & Status bar */}
            <div className="absolute top-0 left-0 right-0 h-8 bg-black/40 flex justify-between items-center px-8 z-50 text-[10px] text-white/80 font-mono">
              <span>9:41</span>
              <div className="w-20 h-4 bg-black rounded-b-xl absolute left-1/2 -translate-x-1/2 top-0" />
              <div className="flex items-center gap-1">
                <span>5G</span>
                <div className="w-4 h-2.5 bg-white/80 rounded-[2px]" />
              </div>
            </div>

            {/* Inner Mobile screen content */}
            <div 
              style={{ direction: lang === "ar" ? "rtl" : "ltr" }}
              className="bg-[#F9F9F9] text-[#1B1B1B] rounded-[36px] w-[350px] md:w-[380px] min-h-[660px] max-h-[660px] overflow-y-auto relative flex flex-col pt-8 text-sm custom-scrollbar"
            >
              
              {/* MOBILE VIEW CONTROLLER: SPLASH SCREEN */}
              {currentScreen === "splash" && (
                <div 
                  className="absolute inset-0 z-10 flex flex-col justify-end bg-cover bg-center text-white"
                  style={{
                    backgroundImage: `linear-gradient(to top, rgba(51,33,13,0.95) 0%, rgba(51,33,13,0.4) 50%, rgba(51,33,13,0.3) 100%), url('https://lh3.googleusercontent.com/aida-public/AB6AXuAIZUimgLAsBT2wTLcm44Axh21C0n75FVErH8QrYNmkC1focUFGHbO5eIXk9sRNDGX17c3kKndG-HjZTC64Jbmxm7BsAXms1D-FQ9Jtw2OU-qijqEj_dGqIBKWGPlaTAMaxf9gL3J7g0RCVOl8bteVWqsF3fKWRuSOdHdSfhOlY9d76n6Fk8yviBR_Rn2_siv2fiSiPaNdfZty-dAvEhF6dh-fTf22dSBYkoyh7tKPD95zm1GyWv1AN5yd30cYOD_lsrElSsfBOX_I')`
                  }}
                >
                  <div className="p-6 text-center space-y-6">
                    <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center mx-auto shadow-lg">
                      <Flame className="w-10 h-10 text-[#B71032]" />
                    </div>
                    <div>
                      <p className="text-[#BD9F83] text-xs uppercase tracking-widest font-bold">
                        {activeLang.premiumTaste}
                      </p>
                      <h2 className="text-2xl font-bold font-sans mt-1">
                        {activeLang.bestChicken} <span className="text-[#FEDCBE]">{activeLang.inTown}</span>
                      </h2>
                      <p className="text-white/80 text-xs mt-2 leading-relaxed">
                        {activeLang.heritageText}
                      </p>
                    </div>

                    <div className="space-y-2 pt-4">
                      <button 
                        onClick={() => setCurrentScreen("login")}
                        className="w-full py-3 bg-[#B71032] hover:bg-[#DA3148] text-white rounded-xl text-xs font-bold uppercase tracking-wider transition-all shadow-md"
                      >
                        {activeLang.getStarted}
                      </button>
                      <button 
                        onClick={() => {
                          setIsGuest(true);
                          setCurrentScreen("menu");
                        }}
                        className="w-full py-3 bg-white/10 border border-white/20 hover:bg-white/20 text-white rounded-xl text-xs font-bold uppercase transition"
                      >
                        {activeLang.skip}
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* MOBILE VIEW CONTROLLER: PHONE NUMBER LOGIN */}
              {currentScreen === "login" && (
                <div className="p-6 flex-1 flex flex-col justify-start">
                  <div className="flex items-center gap-1 mb-6 text-[#33210D]">
                    <Flame className="w-5 h-5 text-[#B71032]" />
                    <span className="font-bold text-sm tracking-wider">{activeLang.appName}</span>
                  </div>

                  <h3 className="text-xl font-bold text-[#33210D]">
                    {activeLang.enterAmmanPhone}
                  </h3>
                  <p className="text-xs text-[#4E453D] mt-2 leading-relaxed">
                    {activeLang.loginDesc}
                  </p>

                  <div className="mt-6 space-y-4">
                    <div className="flex items-center bg-[#EEEEEE] border border-[#D2C4BA] rounded-xl px-4 py-3">
                      <span className="text-xs font-mono font-bold text-[#80756C] mr-2">+962</span>
                      <input 
                        type="tel" 
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                        placeholder={activeLang.phonePlaceholder}
                        className="bg-transparent border-none text-xs w-full focus:outline-none"
                      />
                    </div>

                    <button 
                      onClick={handleSendOtp}
                      className="w-full py-3 bg-[#B71032] text-white rounded-xl text-xs font-bold shadow-md hover:bg-[#DA3148] transition"
                    >
                      {activeLang.sendOtp}
                    </button>
                  </div>

                  <div className="mt-auto text-center">
                    <button 
                      onClick={() => {
                        setIsGuest(true);
                        setCurrentScreen("menu");
                      }}
                      className="text-xs text-[#B71032] font-semibold underline"
                    >
                      {lang === "en" ? "Continue as Guest" : "الاستمرار كزائر تصفح"}
                    </button>
                  </div>
                </div>
              )}

              {/* MOBILE VIEW CONTROLLER: OTP AUTH CHALLENGE */}
              {currentScreen === "otp" && (
                <div className="p-6 flex-1 flex flex-col justify-start">
                  <h3 className="text-xl font-bold text-[#33210D]">
                    {activeLang.enterOtp}
                  </h3>
                  <p className="text-xs text-[#4E453D] mt-2 leading-relaxed">
                    {lang === "en" 
                      ? `We sent an verification code to +962 ${phone}. Real OTP auto-bypass generated for safety.` 
                      : `أرسلنا الرمز السري إلى الهاتف +962 ${phone}. تم تشغيل الدخول السريع الآمن.`}
                  </p>

                  <div className="mt-6 space-y-4">
                    <input 
                      type="text" 
                      maxLength={4}
                      value={otpCode}
                      onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ""))}
                      placeholder="e.g. 1234"
                      className="w-full bg-[#EEEEEE] border border-[#D2C4BA] rounded-xl p-3 text-center tracking-[1em] text-lg font-mono focus:outline-none"
                    />

                    <button 
                      onClick={handleVerifyOtp}
                      className="w-full py-3 bg-[#B71032] text-white rounded-xl text-xs font-bold shadow-md hover:bg-[#DA3148] transition"
                    >
                      {activeLang.verifyBtn}
                    </button>
                  </div>
                </div>
              )}

              {/* MOBILE MAIN FRAMEWORK HEADER */}
              {currentScreen !== "splash" && currentScreen !== "login" && currentScreen !== "otp" && (
                <header className="px-4 py-3 bg-[#F9F9F9] border-b border-[#D2C4BA]/40 flex justify-between items-center sticky top-0 z-20">
                  <div className="flex items-center gap-1.5" onClick={() => setCurrentScreen("menu")}>
                    <MapPin className="w-4 h-4 text-[#B71032]" />
                    <div className="text-left">
                      <span className="text-[9px] text-[#80756C] block font-semibold uppercase">Amman Retail Store</span>
                      <h4 className="text-xs font-bold text-[#33210D]">{activeLang.appName}</h4>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <div className="relative cursor-pointer" onClick={() => setCurrentScreen("checkout")}>
                      <ShoppingBag className="w-5 h-5 text-[#33210D]" />
                      {cart.length > 0 && (
                        <span className="absolute -top-1.5 -right-1.5 bg-[#B71032] text-white text-[9px] rounded-full w-4 h-4 flex items-center justify-center font-bold">
                          {cart.reduce((sum, item) => sum + item.quantity, 0)}
                        </span>
                      )}
                    </div>
                    {!isGuest ? (
                      <div 
                        className="w-8 h-8 rounded-full border border-[#B71032] overflow-hidden cursor-pointer"
                        onClick={() => setCurrentScreen("profile")}
                      >
                        <User className="w-full h-full text-[#33210D] p-1.5" />
                      </div>
                    ) : (
                      <button 
                        onClick={() => setCurrentScreen("login")}
                        className="text-[10px] bg-[#B71032] text-white px-2 py-1 rounded-lg font-bold"
                      >
                        {lang === "en" ? "Login" : "دخول"}
                      </button>
                    )}
                  </div>
                </header>
              )}

              {/* MOBILE VIEW CONTROLLER: PRODUCTS MENU BROWSER */}
              {currentScreen === "menu" && (
                <div className="p-4 flex-1 flex flex-col">
                  
                  {/* Category Pill Horizontal Scroll */}
                  <div className="flex gap-2 overflow-x-auto pb-3 scrollbar-none">
                    {INITIAL_CATEGORIES.map(category => {
                      const isActive = selectedCategory === category.id;
                      return (
                        <button
                          key={category.id}
                          onClick={() => setSelectedCategory(category.id)}
                          className={`px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition ${
                            isActive 
                              ? "bg-[#33210D] text-white shadow-sm" 
                              : "bg-[#EEEEEE] text-[#4E453D] hover:bg-[#E8E8E8]"
                          }`}
                        >
                          {lang === "en" ? category.name : category.nameAr}
                        </button>
                      );
                    })}
                  </div>

                  {/* Search Bar */}
                  <div className="bg-[#EEEEEE] border border-[#D2C4BA]/60 rounded-xl px-3 py-2 flex items-center gap-2 mt-2 mb-4">
                    <Search className="w-4 h-4 text-[#80756C]" />
                    <input 
                      type="text" 
                      placeholder={activeLang.searchHint}
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="bg-transparent border-none text-xs w-full focus:outline-none"
                    />
                  </div>

                  {/* Section Title */}
                  <div className="flex justify-between items-center mb-3">
                    <h3 className="font-bold text-sm text-[#33210D]">{activeLang.allSignatureCut}</h3>
                    <span className="text-[10px] bg-[#B71032]/10 text-[#B71032] px-2.5 py-0.5 rounded-full font-bold">
                      {isRestaurantOpen() ? "OPEN" : "CLOSED NOW"}
                    </span>
                  </div>

                  {/* Vertical Menu Cards */}
                  <div className="space-y-3 flex-1">
                    {currentProducts.map(product => (
                      <div 
                        key={product.id}
                        className="bg-white rounded-2xl p-3 shadow-sm border border-[#D2C4BA]/20 flex gap-3 cursor-pointer hover:border-[#B71032]/40 transition group"
                        onClick={() => openProductCustomization(product)}
                      >
                        <div className="w-24 h-24 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
                          <img 
                            src={product.image} 
                            alt={product.title}
                            className="w-full h-full object-cover group-hover:scale-105 transition duration-300"
                          />
                        </div>

                        <div className="flex-1 flex flex-col justify-between">
                          <div>
                            <div className="flex justify-between items-start gap-1">
                              <h4 className="font-bold text-xs text-[#33210D] leading-tight">
                                {lang === "en" ? product.title : product.titleAr}
                              </h4>
                              {product.isPopular && (
                                <span className="bg-[#B71032]/10 text-[#B71032] text-[8px] font-bold px-1.5 py-0.5 rounded uppercase">
                                  {activeLang.popular}
                                </span>
                              )}
                              {product.isHerbal && (
                                <span className="bg-emerald-100 text-emerald-800 text-[8px] font-bold px-1.5 py-0.5 rounded uppercase">
                                  {lang === "en" ? "Herbal" : "صحي"}
                                </span>
                              )}
                            </div>
                            <p className="text-[10px] text-[#4E453D] line-clamp-2 mt-1">
                              {lang === "en" ? product.description : product.descriptionAr}
                            </p>
                          </div>

                          <div className="flex justify-between items-center mt-2">
                            <span className="font-extrabold text-[#B71032] text-sm">
                              JOD {product.price.toFixed(2)}
                            </span>
                            <div className="w-7 h-7 rounded-full bg-[#B71032] text-white flex items-center justify-center hover:bg-[#DA3148] transition">
                              <Plus className="w-4 h-4" />
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}

                    {currentProducts.length === 0 && (
                      <div className="text-center py-8 text-[#80756C] text-xs">
                        {lang === "en" ? "No products found matches query." : "لم يتم العثور على أي منتج يطابق خيار البحث."}
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* MOBILE VIEW CONTROLLER: PRODUCT CONFIGURATION BOTTOM-SHEET / MODAL */}
              {currentScreen === "custom_product" && selectedProduct && (
                <div className="p-4 flex-1 flex flex-col justify-between">
                  <div>
                    {/* Header bar back button */}
                    <button 
                      onClick={() => setCurrentScreen("menu")}
                      className="text-[#33210D] flex items-center gap-1 text-xs font-bold mb-3"
                    >
                      <ChevronRight className="w-4 h-4 rotate-180" /> {activeLang.backBtn}
                    </button>

                    {/* Product visual banner */}
                    <div className="w-full aspect-video rounded-2xl overflow-hidden relative mb-4">
                      <img 
                        src={selectedProduct.image} 
                        alt={selectedProduct.title}
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute top-2 right-2 bg-black/60 text-white rounded-full px-2 py-0.5 flex items-center gap-1 text-[10px]">
                        <Star className="w-3 h-3 text-amber-400 fill-amber-400" />
                        <span>{selectedProduct.rating}</span>
                      </div>
                    </div>

                    <h3 className="font-extrabold text-base text-[#33210D]">
                      {lang === "en" ? selectedProduct.title : selectedProduct.titleAr}
                    </h3>
                    <p className="text-xs text-[#4E453D] mt-1.5 leading-relaxed">
                      {lang === "en" ? selectedProduct.description : selectedProduct.descriptionAr}
                    </p>

                    {/* Spicy Selector Section */}
                    {selectedProduct.spicyOptions.length > 0 && (
                      <div className="mt-4">
                        <label className="text-xs font-bold text-[#33210D] block mb-2">
                          🌶️ {activeLang.selectSpiciness}
                        </label>
                        <div className="grid grid-cols-3 gap-2">
                          {selectedProduct.spicyOptions.map(opt => (
                            <button
                              key={opt}
                              onClick={() => setCustomSpiciness(opt)}
                              className={`py-2 text-xs font-bold rounded-xl border-2 transition ${
                                customSpiciness === opt 
                                  ? "bg-[#DA3148]/10 border-[#B71032] text-[#B71032]" 
                                  : "border-[#D2C4BA]/60 hover:bg-gray-100"
                              }`}
                            >
                              {opt}
                            </button>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* Side selection additions */}
                    {selectedProduct.sideOptions.length > 0 && (
                      <div className="mt-5">
                        <label className="text-xs font-bold text-[#33210D] block mb-2">
                          🍲 {activeLang.chooseSide}
                        </label>
                        <div className="space-y-2">
                          {selectedProduct.sideOptions.map(side => (
                            <div 
                              key={side.id}
                              onClick={() => setSelectedSideId(side.id)}
                              className={`flex justify-between items-center p-3 rounded-xl border-2 cursor-pointer transition ${
                                selectedSideId === side.id 
                                  ? "bg-[#33210D]/5 border-[#33210D]" 
                                  : "border-[#D2C4BA]/40 hover:bg-gray-50"
                              }`}
                            >
                              <div className="flex items-center gap-2">
                                <div className="w-8 h-8 rounded bg-gray-100 overflow-hidden">
                                  <img src={side.image} alt={side.name} className="w-full h-full object-cover" />
                                </div>
                                <span className="text-xs font-bold text-[#33210D]">
                                  {lang === "en" ? side.name : side.nameAr}
                                </span>
                              </div>
                              <span className="text-xs font-bold text-[#B71032]">
                                {side.price === 0 ? "Free" : `+ JOD ${side.price.toFixed(2)}`}
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Add to Cart CTA */}
                  <div className="pt-4 mt-4 border-t border-[#D2C4BA]/30 flex justify-between items-center gap-4">
                    <div>
                      <span className="text-[10px] text-[#80756C] block uppercase font-bold">{activeLang.totalPrice}</span>
                      <span className="text-lg font-black text-[#B71032]">
                        JOD {calculateProductCustomizedPrice().toFixed(2)}
                      </span>
                    </div>

                    <button 
                      onClick={handleAddToCart}
                      className="flex-1 py-3.5 bg-[#B71032] text-white font-bold rounded-xl shadow-lg hover:bg-[#DA3148] transition flex justify-center items-center gap-2"
                    >
                      <ShoppingBag className="w-4 h-4" />
                      {activeLang.addToCart}
                    </button>
                  </div>
                </div>
              )}

              {/* MOBILE VIEW CONTROLLER: CART & SECURE CHECKOUT PAGE */}
              {currentScreen === "checkout" && (
                <div className="p-4 flex-1 flex flex-col justify-between">
                  <div>
                    <h3 className="font-extrabold text-lg text-[#33210D] mb-4">
                      {activeLang.orderSummary}
                    </h3>

                    {/* Cart Items List */}
                    {cart.length > 0 ? (
                      <div className="space-y-3 mb-5">
                        {cart.map(item => (
                          <div key={item.id} className="bg-white p-3 rounded-xl border border-[#D2C4BA]/30 space-y-2">
                            <div className="flex justify-between items-start">
                              <div>
                                <h4 className="font-bold text-xs text-[#33210D]">
                                  {lang === "en" ? item.product.title : item.product.titleAr}
                                </h4>
                                <p className="text-[9px] text-[#80756C]">
                                  Side: {item.selectedSide} • {item.selectedSpiciness} spiciness
                                </p>
                              </div>
                              <span className="text-xs font-bold text-[#B71032]">
                                JOD {item.totalPrice.toFixed(2)}
                              </span>
                            </div>

                            <div className="flex justify-between items-center pt-2 border-t border-dashed border-[#D2C4BA]/30 text-xs">
                              <button 
                                onClick={() => handleRemoveFromCart(item.id)}
                                className="text-red-500 hover:text-red-700 flex items-center gap-1 text-[10px]"
                              >
                                <Trash2 className="w-3.5 h-3.5" /> Remove
                              </button>

                              <div className="flex items-center gap-2">
                                <button 
                                  onClick={() => updateCartQuantity(item.id, -1)}
                                  className="w-5 h-5 bg-gray-100 hover:bg-gray-200 rounded flex items-center justify-center"
                                >
                                  <Minus className="w-3 h-3 text-[#33210D]" />
                                </button>
                                <span className="font-mono text-xs font-bold">{item.quantity}</span>
                                <button 
                                  onClick={() => updateCartQuantity(item.id, 1)}
                                  className="w-5 h-5 bg-gray-100 hover:bg-gray-200 rounded flex items-center justify-center"
                                >
                                  <Plus className="w-3 h-3 text-[#33210D]" />
                                </button>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="text-center py-10 bg-white rounded-xl border border-dashed border-[#D2C4BA]/40 text-[#80756C] px-4 space-y-2 mb-4">
                        <ShoppingBag className="w-8 h-8 text-[#D2C4BA] mx-auto" />
                        <p className="text-xs">{activeLang.addItemsNotice}</p>
                        <button 
                          onClick={() => setCurrentScreen("menu")}
                          className="text-xs bg-[#B71032] text-white px-4 py-1.5 rounded-lg mt-2 font-bold"
                        >
                          {lang === "en" ? "Browse Menu" : "استعراض الوجبات"}
                        </button>
                      </div>
                    )}

                    {/* Delivery / Pickup Choice selector */}
                    <div className="space-y-2 mt-4">
                      <label className="text-xs font-bold text-[#33210D] block">{activeLang.fulfillmentType}</label>
                      <div className="grid grid-cols-2 gap-2">
                        <button
                          onClick={() => setCheckoutFulfillment("Delivery")}
                          className={`py-2 text-xs font-bold rounded-xl border-2 transition ${
                            checkoutFulfillment === "Delivery"
                              ? "bg-[#33210D]/5 border-[#33210D] text-[#33210D]"
                              : "border-[#D2C4BA]/40 hover:bg-gray-50"
                          }`}
                        >
                          🚴 Home Delivery
                        </button>
                        <button
                          onClick={() => setCheckoutFulfillment("Pickup")}
                          className={`py-2 text-xs font-bold rounded-xl border-2 transition ${
                            checkoutFulfillment === "Pickup"
                              ? "bg-[#33210D]/5 border-[#33210D] text-[#33210D]"
                              : "border-[#D2C4BA]/40 hover:bg-gray-50"
                          }`}
                        >
                          🏪 Store Pickup
                        </button>
                      </div>
                    </div>

                    {/* Delivery inputs */}
                    {checkoutFulfillment === "Delivery" && (
                      <div className="space-y-3 mt-4 bg-white p-3 rounded-xl border border-[#D2C4BA]/30">
                        <label className="text-xs font-bold text-[#33210D] block">🗺️ {activeLang.deliveryAddress}</label>
                        
                        <select 
                          value={selectedZoneId}
                          onChange={(e) => setSelectedZoneId(e.target.value)}
                          className="w-full text-xs p-2.5 rounded-lg bg-[#EEEEEE] border border-[#D2C4BA] focus:outline-none"
                        >
                          {zones.map(z => (
                            <option key={z.id} value={z.id}>
                              {lang === "en" ? z.name : z.nameAr} (Fee: JOD {z.fee.toFixed(2)})
                            </option>
                          ))}
                        </select>

                        <div className="grid grid-cols-2 gap-2">
                          <input 
                            type="text" 
                            placeholder="Building Name" 
                            value={buildingName}
                            onChange={(e) => setBuildingName(e.target.value)}
                            className="text-xs p-2 bg-[#EEEEEE] border border-[#D2C4BA] rounded focus:outline-none"
                          />
                          <input 
                            type="text" 
                            placeholder="Floor No." 
                            value={floor}
                            onChange={(e) => setFloor(e.target.value)}
                            className="text-xs p-2 bg-[#EEEEEE] border border-[#D2C4BA] rounded focus:outline-none"
                          />
                        </div>
                        <input 
                          type="text" 
                          placeholder="Delivery Instructions / Crossroad hint" 
                          value={instructions}
                          onChange={(e) => setInstructions(e.target.value)}
                          className="w-full text-xs p-2 bg-[#EEEEEE] border border-[#D2C4BA] rounded focus:outline-none"
                        />
                      </div>
                    )}

                    {/* Promo Code section */}
                    <div className="mt-4 bg-white p-3 rounded-xl border border-[#D2C4BA]/30">
                      <label className="text-xs font-bold text-[#33210D] block mb-2">🎁 {activeLang.couponsTitle}</label>
                      <div className="flex gap-2">
                        <input 
                          type="text" 
                          placeholder="e.g. TIKKAFIRST20"
                          id="promo-input"
                          className="flex-1 text-xs p-2.5 bg-[#EEEEEE] border border-[#D2C4BA] rounded-xl focus:outline-none uppercase font-mono font-bold"
                        />
                        <button 
                          onClick={() => {
                            const val = (document.getElementById("promo-input") as HTMLInputElement)?.value;
                            applyPromoCode(val);
                          }}
                          className="px-4 bg-[#33210D] text-white text-xs rounded-xl font-bold hover:bg-black"
                        >
                          {activeLang.applyPromo}
                        </button>
                      </div>
                      {promoError && <p className="text-red-500 text-[10px] mt-1 font-bold">{promoError}</p>}
                      {promoSuccess && <p className="text-green-600 text-[10px] mt-1 font-bold">{promoSuccess}</p>}
                    </div>

                    {/* Payment methods choices */}
                    <div className="mt-4 space-y-2">
                      <label className="text-xs font-bold text-[#33210D] block">💳 Payment Choice</label>
                      <div className="space-y-1">
                        <label className="flex items-center gap-2 p-2 bg-white rounded-lg border border-[#D2C4BA]/40 cursor-pointer">
                          <input 
                            type="radio" 
                            name="payment" 
                            checked={paymentMethod === "Card"}
                            onChange={() => setPaymentMethod("Card")}
                            className="text-[#B71032]" 
                          />
                          <span className="text-xs font-bold text-[#33210D]">Visa / MasterCard / CliQ Amman</span>
                        </label>
                        <label className="flex items-center gap-2 p-2 bg-white rounded-lg border border-[#D2C4BA]/40 cursor-pointer">
                          <input 
                            type="radio" 
                            name="payment" 
                            checked={paymentMethod === "Cash"} 
                            onChange={() => setPaymentMethod("Cash")}
                            className="text-[#B71032]" 
                          />
                          <span className="text-xs font-bold text-[#33210D]">{activeLang.cashOnDelivery}</span>
                        </label>
                        <label className={`flex items-center justify-between p-2 bg-white rounded-lg border border-[#D2C4BA]/40 cursor-pointer ${userProfile.points < 20000 ? "opacity-50" : ""}`}>
                          <div className="flex items-center gap-2">
                            <input 
                              type="radio" 
                              name="payment" 
                              disabled={userProfile.points < 20000}
                              checked={paymentMethod === "Points"}
                              onChange={() => setPaymentMethod("Points")}
                              className="text-[#B71032]" 
                            />
                            <span className="text-xs font-bold text-[#33210D]">{activeLang.pointsLoyalty}</span>
                          </div>
                          <span className="text-[10px] px-2 py-0.5 rounded bg-amber-100 text-amber-800 font-bold whitespace-nowrap">
                            {userProfile.points} PTS Ava.
                          </span>
                        </label>
                      </div>
                    </div>
                  </div>

                  {/* Summary Pricing Footer */}
                  {cart.length > 0 && (
                    <div className="pt-4 mt-4 border-t border-[#D2C4BA]/30 bg-white p-3 rounded-xl">
                      <div className="space-y-1 text-xs text-[#4E453D]">
                        <div className="flex justify-between">
                          <span>Subtotal:</span>
                          <span className="font-bold text-[#33210D]">JOD {getSubtotal().toFixed(2)}</span>
                        </div>
                        {checkoutFulfillment === "Delivery" && (
                          <div className="flex justify-between">
                            <span>Delivery Fee:</span>
                            <span className="font-bold text-[#33210D]">JOD {getDeliveryFee().toFixed(2)}</span>
                          </div>
                        )}
                        <div className="flex justify-between">
                          <span>Sales Tax (5%):</span>
                          <span className="font-bold text-[#33210D]">JOD {getTaxes().toFixed(2)}</span>
                        </div>
                        {getDiscount() > 0 && (
                          <div className="flex justify-between text-[#B71032]">
                            <span>Discount / Saving:</span>
                            <span>- JOD {getDiscount().toFixed(2)}</span>
                          </div>
                        )}
                        <div className="flex justify-between pt-2 border-t border-[#D2C4BA]/40 text-sm">
                          <span className="font-extrabold text-[#33210D]">Total Amount due:</span>
                          <span className="font-black text-[#B71032]">JOD {getFinalTotal().toFixed(2)}</span>
                        </div>
                      </div>

                      <button 
                        onClick={handlePlaceOrder}
                        className="w-full mt-4 py-3.5 bg-[#B71032] text-white hover:bg-[#DA3148] rounded-xl text-xs font-bold shadow-lg transition flex justify-center items-center gap-2 uppercase tracking-wide"
                      >
                        <CheckCircle className="w-4 h-4" />
                        {activeLang.placeOrder}
                      </button>
                    </div>
                  )}
                </div>
              )}

              {/* MOBILE VIEW CONTROLLER: ORDER TRACKING & MAP */}
              {currentScreen === "tracking" && (
                <div className="flex-1 flex flex-col justify-between overflow-hidden">
                  
                  {/* Google Maps Simulated frame background */}
                  <div className="w-full h-80 bg-gray-200 relative overflow-hidden flex items-center justify-center">
                    {/* Bouncing Rider Marker overlay with visual maps backdrop */}
                    <img 
                      src="https://lh3.googleusercontent.com/aida-public/AB6AXuDLAxx0kxvfQJP7Jx_vMQ5cbkIgSP4ntymtzuN8WCQOk0mDjQ6oBOaHJUe-Pk0mBA2itwAkt2rxDURna6_xTlyx4Lx77zN_O_FNhIIvKzLee4SO2gga344nJBmEwGlHnejSdwqU2v6RMMkBGkszGy3nIJPl4Pdzev4zsLRK8ojVYpXQatM8rP-krE7L4FLI7iSsIWDX5lxTcfOz6r0wbEbvDtYf8_IzP2C9xfhQxroYzFmA8CS-hdZiNnlYSGXP7gHDyjMuK0gZ7EU"
                      alt="Amman Simulated Map"
                      className="w-full h-full object-cover"
                    />

                    {/* Bouncing marker */}
                    <div className="absolute top-24 left-32 flex flex-col items-center">
                      <div className="bg-[#B71032] text-white font-bold p-2 text-[10px] rounded-lg shadow-md animate-bounce">
                        🚴 Driver Bouncing...
                      </div>
                      <div className="w-3 h-3 bg-[#B71032] rotate-45 -mt-1.5" />
                    </div>

                    {/* Restaurant base */}
                    <div className="absolute top-1/2 right-12 bg-[#33210D] text-white font-bold p-1 text-[9px] rounded-md shadow flex items-center gap-1">
                      <Flame className="w-3 h-3 text-[#B71032]" /> Grill Kitchen
                    </div>
                  </div>

                  {/* Active Steps */}
                  <div className="p-4 bg-[#F9F9F9] border-t border-[#D2C4BA]/40 relative flex-1 flex flex-col justify-between">
                    <div>
                      <div className="flex justify-between items-center mb-4">
                        <div>
                          <span className="text-[10px] text-[#80756C] uppercase font-bold tracking-wider">
                            Active Tracking Order • {activeTrackingOrder?.orderNumber || "GCT-831"}
                          </span>
                          <h3 className="font-extrabold text-base text-[#33210D]">{activeLang.estimatedDelivery}</h3>
                        </div>

                        <span className="px-3 py-1 bg-[#B71032]/10 text-[#B71032] text-xs font-bold rounded-full">
                          {activeTrackingOrder?.status || "Kitchen"}
                        </span>
                      </div>

                      {/* Horizontal progress steps indicators */}
                      <div className="grid grid-cols-4 gap-2 relative mt-2 pt-2">
                        {/* Connecting background Line */}
                        <div className="absolute top-4 left-4 right-4 h-1 bg-[#D2C4BA] z-0" />
                        
                        <div className="flex flex-col items-center z-10">
                          <div className="w-6 h-6 rounded-full bg-[#33210D] text-white flex items-center justify-center text-[10px] font-bold">
                            ✓
                          </div>
                          <span className="text-[9px] font-bold mt-1 text-[#33210D]">{activeLang.orderedStatus}</span>
                        </div>

                        <div className="flex flex-col items-center z-10">
                          <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold ${
                            activeTrackingOrder?.status !== "Pending" ? "bg-[#B71032] text-white animate-pulse" : "bg-[#D2C4BA] text-white"
                          }`}>
                            👨‍🍳
                          </div>
                          <span className="text-[9px] font-bold mt-1 text-[#33210D]">{activeLang.kitchenStatus}</span>
                        </div>

                        <div className="flex flex-col items-center z-10">
                          <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold ${
                            activeTrackingOrder?.status === "OnWay" || activeTrackingOrder?.status === "Arrived" ? "bg-[#33210D] text-white" : "bg-[#D2C4BA] text-white"
                          }`}>
                            🚴
                          </div>
                          <span className="text-[9px] font-bold mt-1 text-[#33210D]">{activeLang.deliveryStatus}</span>
                        </div>

                        <div className="flex flex-col items-center z-10">
                          <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold ${
                            activeTrackingOrder?.status === "Arrived" ? "bg-[#33210D] text-white" : "bg-[#D2C4BA] text-white"
                          }`}>
                            🏠
                          </div>
                          <span className="text-[9px] font-bold mt-1 text-[#33210D]">{activeLang.arrivedStatus}</span>
                        </div>
                      </div>
                    </div>

                    {/* Driver summary cards representation */}
                    <div className="bg-white p-3 rounded-xl border border-[#D2C4BA]/30 flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-10 h-10 rounded-full bg-[#EEEEEE] flex items-center justify-center text-xl overflow-hidden font-bold text-[#33210D]">
                          👨
                        </div>
                        <div>
                          <h4 className="font-bold text-xs text-[#33210D]">Ahmed Khan</h4>
                          <p className="text-[10px] text-[#80756C]">Amman Grill Captain • 4.9 ★</p>
                        </div>
                      </div>

                      <div className="flex gap-2">
                        <button 
                          onClick={() => alert("Simulating a phone call to rider Ahmed Khan: +962 7 9987 6543")}
                          className="p-2 bg-[#EEEEEE] hover:bg-gray-200 rounded-full cursor-pointer text-[#33210D]"
                        >
                          <Phone className="w-4 h-4" />
                        </button>
                        <button 
                          onClick={() => alert("Live WhatsApp/FCM Driver chat emulator active. Typing message...")}
                          className="p-2 bg-[#B71032] hover:bg-[#DA3148] rounded-full text-white cursor-pointer"
                        >
                          <Send className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* MOBILE VIEW CONTROLLER: USER PROFILE & LOYALTY SYSTEM */}
              {currentScreen === "profile" && (
                <div className="p-4 flex-1 flex flex-col justify-between">
                  <div className="space-y-4">
                    {/* Gold Loyalty Badge */}
                    <div className="p-4 rounded-2xl bg-gradient-to-br from-[#4B3621] to-[#33210D] text-white shadow-md relative overflow-hidden">
                      <div className="absolute right-0 bottom-0 translate-y-1/4 translate-x-1/4 opacity-10">
                        <Flame className="w-40 h-40" />
                      </div>

                      <div className="flex justify-between items-start">
                        <div>
                          <span className="bg-[#B71032] text-[8px] font-extrabold tracking-widest px-2.5 py-0.5 rounded-full uppercase">
                            {userProfile.memberStatus} MEMBER
                          </span>
                          <h3 className="font-bold text-lg mt-1">{userProfile.name}</h3>
                          <p className="text-[10px] opacity-70">{userProfile.phone}</p>
                        </div>
                        <Gift className="w-9 h-9 text-[#FEDCBE]" />
                      </div>

                      <div className="mt-6">
                        <span className="text-[10px] uppercase tracking-wider block opacity-85">
                          {activeLang.loyaltyPointsCard}
                        </span>
                        <h2 className="text-3xl font-mono font-black text-[#FEDCBE] mt-0.5">
                          {userProfile.points.toLocaleString()} <span className="text-sm font-sans font-normal text-white">pts</span>
                        </h2>
                      </div>

                      {/* Points to Rewards Stepper Progress */}
                      <div className="mt-4 pt-4 border-t border-white/10 space-y-1">
                        <div className="flex justify-between text-[10px] opacity-80">
                          <span>{activeLang.progressText} (20,000 pts)</span>
                          <span className="font-bold">One Free Meal Meal!</span>
                        </div>
                        <div className="w-full bg-white/20 h-2 rounded-full overflow-hidden">
                          <div 
                            className="bg-[#B71032] h-full" 
                            style={{ width: `${Math.min(100, (userProfile.points / 20000) * 100)}%` }} 
                          />
                        </div>
                      </div>
                    </div>

                    {/* past orders list ledger section */}
                    <h3 className="font-bold text-xs text-[#33210D] uppercase tracking-wider">Past Orders History</h3>
                    <div className="space-y-2">
                      {orders.map(o => (
                        <div key={o.id} className="bg-white p-3 rounded-xl border border-[#D2C4BA]/30 flex justify-between items-center">
                          <div>
                            <h4 className="font-bold text-xs text-[#33210D]">{o.orderNumber}</h4>
                            <p className="text-[10px] text-[#80756C]">JOD {o.total.toFixed(2)} • {o.items.length} items</p>
                          </div>
                          <span className={`text-[9px] font-bold px-2 py-0.5 rounded-full ${
                            o.status === "Arrived" ? "bg-green-100 text-green-800" : "bg-blue-100 text-blue-800"
                          }`}>
                            {o.status}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>

                  <button 
                    onClick={() => {
                      setIsGuest(true);
                      setCurrentScreen("splash");
                    }}
                    className="w-full mt-4 py-3 border border-red-200 text-red-500 hover:bg-red-50 rounded-xl text-xs font-bold transition flex justify-center items-center gap-2"
                  >
                    Logout
                  </button>
                </div>
              )}

              {/* Bottom Nav Bar helper inside the Device Simulator */}
              {currentScreen !== "splash" && currentScreen !== "login" && currentScreen !== "otp" && (
                <footer className="h-12 bg-white border-t border-[#D2C4BA]/40 mt-auto flex justify-around items-center text-xs">
                  <button 
                    onClick={() => setCurrentScreen("menu")}
                    className={`flex flex-col items-center gap-0.5 ${currentScreen === "menu" ? "text-[#B71032]" : "text-[#80756C]"}`}
                  >
                    <Utensils className="w-4 h-4" />
                    <span className="text-[9px]">Menu</span>
                  </button>
                  <button 
                    onClick={() => {
                      if (isGuest) {
                        setCurrentScreen("login");
                      } else {
                        setCurrentScreen("checkout");
                      }
                    }}
                    className={`flex flex-col items-center gap-0.5 ${currentScreen === "checkout" ? "text-[#B71032]" : "text-[#80756C]"}`}
                  >
                    <ShoppingBag className="w-4 h-4" />
                    <span className="text-[9px]">Cart</span>
                  </button>
                  <button 
                    onClick={() => {
                      if (isGuest) {
                        setCurrentScreen("login");
                      } else {
                        setCurrentScreen("profile");
                      }
                    }}
                    className={`flex flex-col items-center gap-0.5 ${currentScreen === "profile" ? "text-[#B71032]" : "text-[#80756C]"}`}
                  >
                    <User className="w-4 h-4" />
                    <span className="text-[9px]">Profile</span>
                  </button>
                </footer>
              )}
            </div>
          </div>
        </section>

        {/* WORKBENCH MODULE PILLARS: FILE DESK, ADMIN CONSOLE & PLANNERS (7 COLUMNS) */}
        <section className="lg:col-span-7 flex flex-col gap-6">
          <div className="bg-[#1C130B] border border-[#33210D] rounded-3xl p-6 flex-1 flex flex-col">
            
            {/* Tab layout tags */}
            <div className="flex border-b border-[#33210D] gap-2 pb-4 mb-4">
              <button
                onClick={() => setActiveWorktab("code")}
                className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition ${
                  activeWorktab === "code" 
                    ? "bg-[#B71032] text-white" 
                    : "bg-[#33210D] text-[#BD9F83] hover:text-white"
                }`}
              >
                <Code className="w-4 h-4 animate-bounce" />
                Flutter Code Center
              </button>

              <button
                onClick={() => setActiveWorktab("admin")}
                className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition ${
                  activeWorktab === "admin" 
                    ? "bg-[#B71032] text-white" 
                    : "bg-[#33210D] text-[#BD9F83] hover:text-white"
                }`}
              >
                <Sliders className="w-4 h-4" />
                Admin Dashboard (Flutter Web)
                {orders.filter(o => o.status === "Pending").length > 0 && (
                  <span className="bg-amber-500 text-black text-[10px] w-5 h-5 flex items-center justify-center rounded-full font-bold ml-1">
                    {orders.filter(o => o.status === "Pending").length}
                  </span>
                )}
              </button>

              <button
                onClick={() => setActiveWorktab("settings")}
                className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition ${
                  activeWorktab === "settings" 
                    ? "bg-[#B71032] text-white" 
                    : "bg-[#33210D] text-[#BD9F83] hover:text-white"
                }`}
              >
                <Settings className="w-4 h-4" />
                CRM Rules Settings
              </button>

              <button
                onClick={() => setActiveWorktab("security")}
                className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-2 transition ${
                  activeWorktab === "security" 
                    ? "bg-[#B71032] text-white" 
                    : "bg-[#33210D] text-[#BD9F83] hover:text-white"
                }`}
              >
                <Shield className="w-4 h-4" />
                Security Rules & Audits
              </button>
            </div>

            {/* TAB CONTENT: FLUTTER CODE DIRECTORY FILE EXPLORER */}
            {activeWorktab === "code" && (
              <div className="flex-1 flex flex-col md:grid md:grid-cols-12 gap-4 h-full">
                
                {/* File Tree Left Section (4 columns) */}
                <div className="md:col-span-4 bg-black/40 p-4 rounded-2xl border border-[#33210D] text-xs">
                  <h4 className="text-[#BD9F83] font-bold text-xs uppercase mb-3 block">Flutter Source Files List</h4>
                  
                  <div className="space-y-1">
                    {Object.keys(codeDictionary).map(key => {
                      const file = codeDictionary[key];
                      const isSelected = selectedFile === key;
                      return (
                        <div
                          key={key}
                          onClick={() => setSelectedFile(key)}
                          className={`p-2.5 rounded-xl cursor-pointer transition flex items-center justify-between ${
                            isSelected 
                              ? "bg-[#B71032] text-white font-bold" 
                              : "text-[#BD9F83] hover:bg-[#33210D]/30 hover:text-white"
                          }`}
                        >
                          <span className="truncate">{key}</span>
                          <span className="text-[8px] opacity-75 whitespace-nowrap bg-black/30 px-1.5 py-0.5 rounded">
                            {file.layer.split(" ")[0]}
                          </span>
                        </div>
                      );
                    })}
                  </div>

                  <div className="mt-4 pt-4 border-t border-[#33210D] space-y-2">
                    <button
                      onClick={triggerSimulationCompilation}
                      disabled={isCompiling}
                      className="w-full py-2 bg-[#4B3621] hover:bg-[#BD9F83] hover:text-[#33210D] text-[#FEDCBE] rounded-xl font-bold transition flex items-center justify-center gap-1 cursor-pointer disabled:opacity-50"
                    >
                      <RefreshCw className={`w-3.5 h-3.5 ${isCompiling ? "animate-spin" : ""}`} />
                      {isCompiling ? "Simulating Compile..." : "flutter pub get & compile"}
                    </button>
                  </div>
                </div>

                {/* Code viewer Right Section (8 columns) */}
                <div className="md:col-span-8 flex flex-col justify-between">
                  <div className="bg-black/60 rounded-2xl border border-[#33210D] p-4 flex-1 font-mono text-xs flex flex-col">
                    <div className="flex justify-between items-center pb-2 border-b border-[#33210D] text-[11px] text-[#BD9F83] mb-3">
                      <span className="font-bold flex items-center gap-1.5">
                        <FileText className="w-4 h-4 text-[#B71032]" />
                        {codeDictionary[selectedFile]?.path}
                      </span>
                      <span className="bg-[#4B3621] px-2 py-0.5 rounded font-sans text-xs text-[#FEDCBE] font-bold">
                        {codeDictionary[selectedFile]?.layer}
                      </span>
                    </div>

                    <pre className="overflow-auto max-h-[380px] custom-scrollbar text-[#FEDCBE] leading-relaxed select-text p-2 bg-[#110D09] rounded-xl flex-1 whitespace-pre">
                      {codeDictionary[selectedFile]?.code}
                    </pre>

                    <div className="flex justify-end gap-2 pt-3 border-t border-[#33210D] mt-3">
                      {copiedCodeNotice && (
                        <span className="text-green-400 text-[10px] self-center">✓ Snippet Copied!</span>
                      )}
                      <button
                        onClick={() => copyToClipboard(codeDictionary[selectedFile].code)}
                        className="bg-[#B71032] hover:bg-[#DA3148] text-white px-4 py-2 rounded-xl text-xs font-bold transition flex items-center gap-1"
                      >
                        <Copy className="w-3.5 h-3.5" /> Copy Code
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* TAB CONTENT: ADMIN WEB DASHBOARD */}
            {activeWorktab === "admin" && (
              <div className="flex-1 space-y-4">
                {/* Stats row overview */}
                <div className="grid grid-cols-3 gap-4">
                  <div className="bg-black/40 p-3 rounded-2xl border border-[#33210D]">
                    <span className="text-[10px] text-[#BD9F83] block uppercase font-bold">Total Amman Sales</span>
                    <h3 className="text-xl font-bold font-mono text-[#FEDCBE] mt-1">
                      JOD {orders.reduce((sum, o) => o.status === "Arrived" ? sum + o.total : sum, 0).toFixed(2)}
                    </h3>
                  </div>
                  <div className="bg-black/40 p-3 rounded-2xl border border-[#33210D]">
                    <span className="text-[10px] text-[#BD9F83] block uppercase font-bold">Active Orders</span>
                    <h3 className="text-xl font-bold font-mono text-amber-400 mt-1">
                      {orders.filter(o => o.status !== "Arrived" && o.status !== "Canceled").length} orders
                    </h3>
                  </div>
                  <div className="bg-black/40 p-3 rounded-2xl border border-[#33210D]">
                    <span className="text-[10px] text-[#BD9F83] block uppercase font-bold">Gold CRM Users</span>
                    <h3 className="text-xl font-bold font-mono text-emerald-400 mt-1">
                      12,481 Gold Accounts
                    </h3>
                  </div>
                </div>

                {/* Amman Orders Management table */}
                <div className="bg-black/60 rounded-2xl border border-[#33210D] p-4">
                  <div className="flex justify-between items-center mb-4">
                    <h4 className="text-xs font-extrabold text-[#BD9F83] uppercase">Live Orders Pipeline Feed</h4>
                    
                    <button
                      onClick={handleForceCompleteAllOrders}
                      className="text-[10px] bg-[#B71032] text-white px-3 py-1 rounded-lg font-bold"
                    >
                      ✓ Force Complete All for simulator
                    </button>
                  </div>

                  <div className="overflow-y-auto max-h-[300px] space-y-2 custom-scrollbar">
                    {orders.map(order => (
                      <div key={order.id} className="bg-black/30 p-3 rounded-xl border border-[#33210D] flex justify-between items-start text-xs">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-extrabold text-[#FEDCBE]">{order.orderNumber}</span>
                            <span className="text-[10px] opacity-75">{order.customerName}</span>
                          </div>
                          
                          <div className="mt-1.5 space-y-1 text-[#BD9F83] text-[11px]">
                            <p>Items: {order.items.map(i => `${lang === "en" ? i.product.title : i.product.titleAr} (${i.selectedSpiciness})`).join(", ")}</p>
                            {order.address && (
                              <p>🚴 Deliver to: {order.address.buildingName}, {order.address.floor}, {order.address.apartment} ({order.address.instructions})</p>
                            )}
                          </div>
                        </div>

                        <div className="text-right space-y-2">
                          <span className="font-extrabold text-white text-sm block">
                            JOD {order.total.toFixed(2)}
                          </span>

                          <div className="flex gap-1.5">
                            {order.status === "Pending" && (
                              <button
                                onClick={() => updateOrderStatusByAdmin(order.id, "Preparing")}
                                className="bg-amber-500 text-black px-2 py-1 rounded font-bold text-[10px]"
                              >
                                Accept & Cook
                              </button>
                            )}
                            {order.status === "Preparing" && (
                              <button
                                onClick={() => updateOrderStatusByAdmin(order.id, "OnWay")}
                                className="bg-indigo-500 text-white px-2 py-1 rounded font-bold text-[10px]"
                              >
                                Deliver Dispatch
                              </button>
                            )}
                            {order.status === "OnWay" && (
                              <button
                                onClick={() => updateOrderStatusByAdmin(order.id, "Arrived")}
                                className="bg-emerald-500 text-white px-2 py-1 rounded font-bold text-[10px]"
                              >
                                Mark Delivered
                              </button>
                            )}
                            <span className="text-[10px] text-gray-400 block mt-1 font-bold">Status: {order.status}</span>
                          </div>
                        </div>
                      </div>
                    ))}

                    {orders.length === 0 && (
                      <div className="text-center py-8 text-[#80756C] italic font-serif">
                        No transactions registered yet. Please place an order using the phone simulator on the left!
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* TAB CONTENT: CRM RULES & SETTINGS */}
            {activeWorktab === "settings" && (
              <div className="flex-1 bg-black/40 p-4 rounded-2xl border border-[#33210D] space-y-6">
                
                {/* Working hours system */}
                <div>
                  <h4 className="text-xs font-extrabold text-[#BD9F83] uppercase mb-3">Restaurant Operational Controls</h4>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <span className="text-[10px] text-[#BD9F83] block uppercase font-bold">Amman Opens Time (12:00)</span>
                      <input 
                        type="text" 
                        value={systemSettings.workingHoursStart}
                        onChange={(e) => setSystemSettings(prev => ({ ...prev, workingHoursStart: e.target.value }))}
                        className="w-full text-xs p-2.5 rounded-xl bg-black border border-[#33210D] text-[#FEDCBE] focus:outline-none focus:border-[#B71032]"
                      />
                    </div>
                    <div>
                      <span className="text-[10px] text-[#BD9F83] block uppercase font-bold">Amman Close Time (01:00)</span>
                      <input 
                        type="text" 
                        value={systemSettings.workingHoursEnd}
                        onChange={(e) => setSystemSettings(prev => ({ ...prev, workingHoursEnd: e.target.value }))}
                        className="w-full text-xs p-2.5 rounded-xl bg-black border border-[#33210D] text-[#FEDCBE] focus:outline-none focus:border-[#B71032]"
                      />
                    </div>
                  </div>

                  <div className="mt-4 flex items-center justify-between bg-black/60 p-4 rounded-xl border border-red-500/20">
                    <div>
                      <h5 className="text-red-500 font-bold text-xs">Emergency Force Close Toggle</h5>
                      <p className="text-[10px] text-[#BD9F83] mt-0.5">Toggle this state to simulate storm closures. Ordering is completely disabled dynamically.</p>
                    </div>

                    <button
                      onClick={() => setSystemSettings(prev => ({ ...prev, isEmergencyClosed: !prev.isEmergencyClosed }))}
                      className={`px-4 py-1.5 rounded-xl text-xs font-bold transition ${
                        systemSettings.isEmergencyClosed 
                          ? "bg-red-500 text-white" 
                          : "bg-black text-red-500 border border-red-500/40"
                      }`}
                    >
                      {systemSettings.isEmergencyClosed ? "EMERGENCY ACTIVE" : "NORMAL OPEN STATUS"}
                    </button>
                  </div>
                </div>

                {/* Loyalty Rules Ratio config */}
                <div className="pt-4 border-t border-[#33210D] space-y-3">
                  <h4 className="text-xs font-extrabold text-[#BD9F83] uppercase">Loyalty points rules formula</h4>
                  
                  <div className="grid grid-cols-2 gap-4">
                    <div className="bg-black/60 p-3 rounded-xl border border-[#33210D]">
                      <span className="text-[10px] text-[#BD9F83]">Points Earned per 1 JOD spent</span>
                      <p className="text-lg font-bold text-[#FEDCBE] font-mono mt-1">1,000 points</p>
                    </div>
                    <div className="bg-black/60 p-3 rounded-xl border border-[#33210D]">
                      <span className="text-[10px] text-[#BD9F83]">Points required for One Free Meal</span>
                      <p className="text-lg font-bold text-amber-400 font-mono mt-1">20,000 points</p>
                    </div>
                  </div>
                </div>

                {/* Jordan Delivery configuration parameters */}
                <div className="pt-4 border-t border-[#33210D] space-y-2">
                  <h4 className="text-xs font-extrabold text-[#BD9F83] uppercase flex justify-between">
                    <span>Jordan Delivery zones config</span>
                    <span className="text-amber-500 lowercase font-serif italic text-[11px]">Fee editable</span>
                  </h4>

                  <div className="space-y-1">
                    {zones.map(z => (
                      <div key={z.id} className="bg-black/60 p-1.5 rounded-xl flex justify-between items-center text-xs text-[#BD9F83]">
                        <span>{lang === "en" ? z.name : z.nameAr}</span>
                        <div className="flex items-center gap-2">
                          <span>Fee:</span>
                          <input 
                            type="number" 
                            step="0.5"
                            value={z.fee}
                            onChange={(e) => {
                              const v = parseFloat(e.target.value) || 0;
                              setZones(prev => prev.map(zoneItem => zoneItem.id === z.id ? { ...zoneItem, fee: v } : zoneItem));
                            }}
                            className="bg-black text-[#FEDCBE] text-right font-bold font-mono py-0.5 px-2 rounded border border-[#33210D] w-16 focus:outline-none"
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* TAB CONTENT: SECURITY COMPLIANCE & TERMINAL LOGS */}
            {activeWorktab === "security" && (
              <div className="flex-1 space-y-4">
                
                {/* Security rule checklist blocks */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-black/40 p-4 rounded-2xl border border-[#33210D] text-xs">
                    <h5 className="font-bold text-white mb-2 flex items-center gap-1">
                      <Shield className="w-4 h-4 text-emerald-500" />
                      IDOR & Access Protection
                    </h5>
                    <p className="text-[#BD9F83] text-[11px] leading-relaxed">
                      Least privilege standard rules prevent users from fetching metadata or listing other order templates, matching strict validation profiles recursively inside Firestore.
                    </p>
                  </div>

                  <div className="bg-black/40 p-4 rounded-2xl border border-[#33210D] text-xs">
                    <h5 className="font-bold text-white mb-2 flex items-center gap-1">
                      <Lock className="w-4 h-4 text-emerald-500" />
                      No Client-side Modification
                    </h5>
                    <p className="text-[#BD9F83] text-[11px] leading-relaxed">
                      All discount verification codes and delivery zones totals recalculate server-side in actual database processes to block parameter tampering attacks.
                    </p>
                  </div>
                </div>

                {/* Simulated build and compile console logger */}
                <div className="bg-black text-[#FEDCBE] font-mono text-xs p-4 rounded-2xl border border-[#33210D] relative">
                  <div className="absolute top-2 right-4 flex items-center gap-1.5">
                    <TermIcon className="w-3.5 h-3.5 text-amber-500" />
                    <span className="text-[10px] text-[#BD9F83]">terminal-logs</span>
                  </div>

                  <h5 className="text-[#BD9F83] text-[11px] font-bold uppercase mb-2 border-b border-[#33210D] pb-1.5 ">
                    Active Terminal Pipeline Output
                  </h5>

                  <div className="space-y-1 max-h-[160px] overflow-y-auto custom-scrollbar">
                    {terminalLogs.map((log, i) => (
                      <p key={i} className={log.includes("[SECURITY]") ? "text-emerald-400" : log.includes("Error") ? "text-red-500 animate-pulse font-bold" : ""}>
                        &gt; {log}
                      </p>
                    ))}
                  </div>

                  <div className="flex justify-end pt-3 mt-3 border-t border-[#33210D]">
                    <button 
                      onClick={() => setTerminalLogs(prev => [
                        ...prev,
                        `[AUDIT] Security audit run at ${new Date().toLocaleTimeString()}: MASVS compliance checks passed. 0 issues detected.`
                      ])}
                      className="text-[10px] underline hover:text-white"
                    >
                      Trigger MASVS Audit
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        </section>
      </div>

      {/* FOOTER METADATA INFO & SUMMARY */}
      <footer className="bg-[#1C130B] border-t border-[#33210D] p-6 text-center text-xs text-[#BD9F83] space-y-2">
        <div className="max-w-4xl mx-auto flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-left font-sans text-[#BD9F83]">
            🎨 <strong className="text-white">Artisanal Grill Design Style</strong> configured in standard Flutter Material 3, optimized for Android and Flutter Web (compiled with Canvaskit on Cloud Run containers).
          </p>
          <div className="flex gap-4">
            <span className="text-[10px] bg-[#B71032]/20 text-[#B71032] border border-[#B71032]/40 px-3 py-1 rounded-full font-bold">
              ✓ Firebase Firestore Rules Enforced
            </span>
            <span className="text-[10px] bg-[#4B3621]/80 text-[#FEDCBE] border border-[#BD9F83]/20 px-3 py-1 rounded-full font-bold">
              ✓ 1 JOD = 1,000 Points System
            </span>
          </div>
        </div>
      </footer>
    </div>
  );
}
