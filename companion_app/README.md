# 📱 Utility Mart - Android Companion App

The Utility Mart Companion App is a powerful extension of the Windows Desktop POS system, designed to give shop owners and staff mobile control over inventory and real-time business insights.

## 🚀 Dual-Path Architecture

The app is split into two distinct modes to serve different roles within the business:

1.  **📦 Inventory Manager (Local Sync)**: Designed for staff to add products and adjust stock levels on the shop floor using Wi-Fi or USB connectivity.
2.  **📊 Admin Dashboard (Internet Reporting)**: Designed for owners to monitor sales performance and receive automated closing reports from anywhere in the world.

---

## 📦 Inventory Manager (Local Sync)

### Features
*   **Quick Pairing**: Connect to the Desktop POS instantly via QR code scanning.
*   **Mobile Stock Adjustment**: Update product stock levels on the fly with a dedicated "Reason for Adjustment" field for better tracking.
*   **Premium Product Management**: A tabbed "Add Product" interface that supports:
    *   Barcode Scanning (continuous mode for high-speed entry).
    *   Pricing (Cost, MRP, Wholesale, Retail).
    *   Category selection synced from the desktop.
*   **Real-time UI Sync**: Changes made on the mobile app reflect **instantly** on the Windows Desktop dashboard and inventory lists.

### Connectivity
*   **Wi-Fi Bridge**: Works on any local network (Port 8080).
*   **USB Bridge (Ultra-Stable)**: Supports high-speed syncing via a USB cable using ADB reverse port forwarding—ideal for shops with unstable Wi-Fi.

---

## 📊 Admin Dashboard (Internet Reporting)

### Features
*   **Live KPIs**: View Today's Sales, Active Credits, and Transaction Counts at a glance.
*   **Pull-to-Refresh**: Force a live update from the PC via the local network or internet.
*   **Recent Alerts**: Integrated notifications for low stock and overdue customer credits.
*   **Star Admin Theme**: Premium dark-mode aesthetics for clear visibility and a professional feel.

### 🌐 Global Internet Reporting (FCM)
*   **Anywhere Access**: Receive data regardless of your location using Google Firebase Cloud Messaging.
*   **Closing Time Scheduler**: Configure a custom "Closing Time" (e.g., 8:00 PM) on the Desktop app. The PC will automatically send a full daily summary to your phone at that time.
*   **Real Sales Data**: Payload includes Total Sales, Cash vs. Credit breakdown, Item Counts, and Profit reports.

---

## ⚙️ Configuration & Setup

### Desktop Settings (Windows)
To manage the companion app connectivity, go to the **Settings > Companion App** tab on your Desktop POS:

1.  **Enable Local Server**: Toggles the Wi-Fi/USB bridge.
2.  **QR Pairing**: Shows the pairing code for new devices.
3.  **Session Duration**: Control how long mobile devices stay "paired" (8 hours to 1 week).
4.  **Daily 9PM Summary**: Toggle automated FCM reporting.
5.  **Closing Time (Report)**: Set your preferred time for the daily push notification.
6.  **FCM Server Key**: Required for internet reporting (configured in `lib/core/services/fcm_service.dart`).

### Mobile Setup
1.  Open the app and select your mode (**Inventory** or **Admin**).
2.  If **Inventory**, scan the QR code displayed on the Windows Desktop settings.
3.  Ensure the Android device and PC are on the same network (unless using FCM only).

---

## ✨ Visual Branding
*   **Unified Icons**: Uses the same premium "Utility Mart" brand logo as the Windows app.
*   **Consistent Experience**: Themes and color palettes are synchronized between platforms for a professional, cohesive business identity.

---

*Developed for Hunain Mart - Powered by Gravity POS Infrastructure.*
