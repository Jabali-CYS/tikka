export type Language = "en" | "ar";

export interface User {
  uid: string;
  phone: string;
  name: string;
  memberStatus: "Gold" | "Silver" | "Bronze";
  points: number;
}

export interface Category {
  id: string;
  name: string;
  nameAr: string;
  icon: string;
}

export interface Product {
  id: string;
  title: string;
  titleAr: string;
  description: string;
  descriptionAr: string;
  price: number; // in JOD
  categoryId: string;
  image: string;
  isPopular?: boolean;
  isHerbal?: boolean;
  rating: number;
  spicyOptions: string[];
  sideOptions: Array<{
    id: string;
    name: string;
    nameAr: string;
    image: string;
    price: number;
  }>;
  isDeleted: boolean;
}

export interface CartItem {
  id: string;
  productId: string;
  product: Product;
  quantity: number;
  selectedSpiciness: string;
  selectedSide: string; // side ID
  sidePrice: number;
  extras: Array<{
    name: string;
    nameAr: string;
    price: number;
  }>;
  totalPrice: number;
}

export type OrderStatus = "Pending" | "Preparing" | "OnWay" | "Arrived" | "Canceled";

export interface Order {
  id: string;
  orderNumber: string; // e.g. GCT-831
  customerUid: string;
  customerName: string;
  customerPhone: string;
  items: CartItem[];
  subtotal: number;
  deliveryFee: number;
  taxes: number;
  discount: number;
  total: number;
  paymentMethod: "Card" | "Cash" | "Points";
  status: OrderStatus;
  fulfillmentType: "Delivery" | "Pickup";
  address?: {
    street: string;
    buildingName: string;
    floor: string;
    apartment: string;
    instructions?: string;
    label: "Home" | "Office" | "Other";
    coordinates: { lat: number; lng: number };
  };
  driverName?: string;
  driverPhone?: string;
  driverRating?: number;
  createdAt: string;
  updatedAt: string;
  isDeleted: boolean;
}

export interface Coupon {
  id: string;
  code: string;
  discountType: "Percentage" | "Fixed";
  value: number;
  minOrder: number;
  description: string;
  descriptionAr: string;
  isDeleted: boolean;
}

export interface DeliveryZone {
  id: string;
  name: string;
  nameAr: string;
  fee: number;
  minOrder: number;
}

export interface SystemSettings {
  workingHoursStart: string; // e.g. "12:00"
  workingHoursEnd: string;   // e.g. "01:00"
  pointsPerJOD: number;      // e.g. 1000
  pointsPerFreeMeal: number; // e.g. 20000
  isEmergencyClosed: boolean;
}
