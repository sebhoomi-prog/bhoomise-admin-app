# 🌱 Bhoomise – Smart Agri-Commerce & Inventory Platform

## 📌 Overview

**Bhoomise** is a scalable, real-time, multi-role Flutter application designed to streamline agricultural commerce and inventory management for mushrooms and organic products.

The platform connects **Customers, Stores (Retailers), and Admin (Suppliers)** into a unified ecosystem with:

- ⚡ Real-time inventory tracking  
- 🧠 Intelligent order routing  
- 🛒 Guest-first shopping experience  
- 🔗 Deep linking support  
- 🔐 Role-based access control  

---

## 🎯 Problem Statement

Traditional agri-commerce systems suffer from:

- ❌ No real-time stock visibility  
- ❌ Frequent stock-outs  
- ❌ Disconnected offline and online sales  
- ❌ Manual supply chain coordination  
- ❌ Poor customer experience  

---

## 💡 Solution

Bhoomise provides a **centralized product + distributed inventory system**:

- 📦 Real-time inventory sync  
- 🛒 Seamless guest browsing (no login required)  
- 🔄 Live order tracking with ETA  
- 🔗 Deep linking for campaigns and navigation  
- 🧠 Backend-driven order assignment  

---

## 👥 User Roles

### 🛒 Customer (Guest + Logged-in)

- Browse products without login  
- Add products/variants to cart  
- Apply coupons  
- Login only at checkout (OTP-based)  
- Track orders in real-time  

---

### 🏪 Store / Retailer (Vendor)

- Manage inventory (variant-wise)  
- Update stock after offline sales  
- Receive low-stock alerts  
- Handle assigned orders  
- ❌ Cannot create products  

---

### 👑 Admin (Supplier)

- Create and manage master products  
- Upload product images  
- Define product variants (200g, 500g, 1kg)  
- Approve vendor products  
- Monitor inventory & orders  
- Manage coupons  

---

## ⚙️ Key Features

### 📦 Inventory Management

- Real-time updates  
- Variant-based tracking  
- Low-stock alerts  

---

### 🛒 E-commerce System

- Admin-controlled product catalog  
- Multi-variant support  
- Dynamic pricing  
- Guest-first UX  

---

### 🧺 Cart System

- Multi-product + multi-variant support  
- Local storage (guest cart)  
- Sync after login  

**Example:**

- Mushroom 200g × 2  
- Mushroom 500g × 1  

---

### 🎟️ Coupon System

- Apply coupon at checkout  
- Real-time validation  
- Dynamic discount calculation  

---

### 🚚 Order & Delivery

- B2C (Customer delivery)  
- B2B (Store supply)  
- Smart backend order routing  

---

### 📍 Real-Time Order Tracking

Status Flow:

Placed → Preparing → Packed → Out for Delivery → Delivered  

- ETA countdown  
- Live updates  

---

### 🔔 Notifications

- Order updates  
- Low stock alerts  
- Promotional campaigns  

---

### 🔗 Deep Linking

- `myapp://product/{id}`  
- `myapp://order/{id}`  
- `myapp://coupon/{code}`  

Supports:
- Cold start  
- Background navigation  
- Login redirection  

---

## 🏪 Inventory & Product Model

### 🎯 Core Rule

Product = Admin  
Inventory = Store  
Purchase = Backend Controlled  

---

### 📦 Master Products (Admin)

- Name  
- Image  
- Category  
- Variants  

---

### 🏪 Store Inventory

- Linked to master product  
- Variant-wise stock  
- Price per variant  

---

### 🛒 Purchase Flow

1. User browses (Guest Mode)  
2. Adds to cart  
3. Checkout → Login required  
4. Backend validates stock  
5. Order assigned to store/admin  
6. Real-time tracking starts  

---

## 🧱 Tech Stack

### 📱 Frontend

- Flutter (Android, iOS)  
- GetX (State + Routing + Dependency Injection)  
- Clean Architecture  

---

### 🔥 Backend

- Firebase:
  - Authentication (OTP)  
  - Firestore (Real-time Database)  
  - Storage (Images)  

---

### ⚙️ Optional Backend (Scaling)

- Node.js + MongoDB  

---

## 🧠 Architecture Highlights

- Clean Architecture (Presentation + Domain + Data)  
- Feature-based modular structure  
- Real-time Firestore streams  
- Guest-first UX  
- Role-based navigation  

---

## 🎨 Design reference

- **Figma** (Customer Home and shells): [Bhoomise Storefront file](https://www.figma.com/design/kWtQ8RReUVoZ7BoABTOe3q/) — implement with shared tokens in `lib/core/theme/design_tokens.dart` and `.cursor/rules/code-converstion-rule.mdc`.

---

## 📦 Product Structure

Product: Mushroom  

Variants:  
- 200g → price, stock  
- 500g → price, stock  
- 1kg → price, stock  

---

## 🔄 Data Flow

Flutter App → GetX → Firebase / API → Database  

---

## 🔐 Security

- Role-based access control  
- Vendor restricted to own data  
- Admin full access  
- Firestore security rules  

---

## 🚀 Scalability Vision

- Multi-vendor marketplace  
- Hyperlocal delivery  
- AI-based demand prediction  
- Smart logistics system  

---

## 🔮 Future Enhancements

- AI stock prediction  
- Smart reorder suggestions  
- Live delivery tracking (maps)  
- Analytics dashboard  
- Multi-language support  

---

## 🌍 Vision

To build a scalable agri-tech ecosystem that digitizes supply chains and empowers farmers, retailers, and consumers.

---

## 👨‍💻 Author

**Aditya Pal**

---

## ⭐ Contribution

Feel free to fork, contribute, and improve Bhoomise 🚀# bhoomise-admin-app
