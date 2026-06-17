import { Category, Product, DeliveryZone, Coupon, SystemSettings } from "./types";

export const INITIAL_CATEGORIES: Category[] = [
  { id: "grill", name: "Grill", nameAr: "مشاوي", icon: "Flame" },
  { id: "sides", name: "Sides", nameAr: "مقبلات", icon: "Utensils" },
  { id: "drinks", name: "Drinks", nameAr: "مشروبات", icon: "CupSoda" },
  { id: "salads", name: "Salads", nameAr: "سلطات", icon: "Leaf" },
  { id: "desserts", name: "Desserts", nameAr: "حلويات", icon: "Cake" }
];

export const INITIAL_PRODUCTS: Product[] = [
  {
    id: "g1",
    title: "Classic Chicken Tikka",
    titleAr: "شيش طاووق كلاسيك",
    description: "Succulent boneless chicken chunks marinated in Greek yogurt and secret tandoori spices, slow-grilled over tandoori charcoal. Served with fresh mint chutney.",
    descriptionAr: "شيش طاووق دجاج مخلي من العظم متبل بالزبادي اليوناني وتوابل التندوري السرية، مشوي على الفحم الهادئ. يقدم مع صلصة النعناع الطازجة.",
    price: 8.50, // Jordanian Dinars (JOD)
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
  // Sides
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
  // Salads
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
  // Drinks
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

export const INITIAL_ZONES: DeliveryZone[] = [
  { id: "z1", name: "Shmeisani & Abdali", nameAr: "الشميساني والعبدلي", fee: 1.50, minOrder: 5.00 },
  { id: "z2", name: "Khalda & Tla' Al-Ali", nameAr: "خلدا وتلاع العلي", fee: 2.00, minOrder: 5.00 },
  { id: "z3", name: "Dabouq & Al-Madinah", nameAr: "دابوق وشارع المدينة", fee: 2.50, minOrder: 7.00 },
  { id: "z4", name: "Al-Barsha style Delivery, Amman Outskirts", nameAr: "ضواحي عمان الشرقية والجنوبية", fee: 3.50, minOrder: 10.00 }
];

export const INITIAL_COUPONS: Coupon[] = [
  { id: "c1", code: "TIKKAFIRST20", discountType: "Percentage", value: 20, minOrder: 5.00, description: "Get 20% off your first ever order!", descriptionAr: "خصم 20% على طلبك الأول من شيف طاووق!", isDeleted: false },
  { id: "c2", code: "AMMANLOVE", discountType: "Percentage", value: 10, minOrder: 10.00, description: "Receive 10% off as an Amman client.", descriptionAr: "خصم 10% لبلد النشامى عمان الحبيبة.", isDeleted: false },
  { id: "c3", code: "FREEDEL", discountType: "Fixed", value: 2.50, minOrder: 15.00, description: "Get JOD 2.50 off delivery fee on orders over 15 JOD.", descriptionAr: "توصيل مجاني لقيمة التوصيل 2.50 دينار للطلبات فوق 15 دينار.", isDeleted: false }
];

export const DEFAULT_SYSTEM_SETTINGS: SystemSettings = {
  workingHoursStart: "12:00",
  workingHoursEnd: "01:00",
  pointsPerJOD: 1000,
  pointsPerFreeMeal: 20000,
  isEmergencyClosed: false
};
