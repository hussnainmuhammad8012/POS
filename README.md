# 🌌 Gravity POS (Hunain Mart)

Welcome to **Gravity POS**, a premium, high-performance desktop Point of Sale and Inventory Management system. Designed with a stunning, modern aesthetic (Star Admin) and powered by an offline-first architecture, Gravity POS offers everything a modern business needs to scale.

![Hunain Mart POS](flutter_01.png)

## 🚀 Key Features

### 🛒 Advanced Point of Sale
- **Robust Adaptive Cart**: A completely redesigned cart interface that scales beautifully across any window size. No more character wrapping or squeezed text.
- **Precision Scanner Integration**: High-speed barcode scanning with bulk quantity support.
- **Intelligent Search Overlay**: A global header search bar that allows you to find products and customers instantly from anywhere in the app.
- **Dynamic Pricing**: Toggle between Retail and Wholesale pricing on the fly with automatic margin recalculations.
- **Flexible Checkout**: Support for Cash, Card, and Credit sales. Integrated debt tracking for credit customers.

### 📊 Real-Time Analytics Dashboard
- **Instant KPIs**: Track Revenue, Transactions, Credit collected, and Low Stock counts at a glance.
- **Interactive Visualizations**: Deep-dive into sales trends with elegant line charts and category distribution donut charts.
- **Top Performers**: Auto-generated lists of top-selling products and highest-performing categories.
- **Report Export**: Generate detailed PDF reports with custom date ranges, ready for printing or digital sharing.

### 📦 Inventory & Stock Control
- **Multilevel Management**: Manage categories, products, and variants (Size, Color, Unit) with a powerful repository-based system.
- **Low Stock Alerts**: Automatic notifications for items falling below safety thresholds.
- **Stock Movements**: Every gram or milliliter is tracked through a comprehensive movement ledger (IN, OUT, ADJUSTMENT).

### 👥 Customer & Credit Management
- **Full Ledger Tracking**: View a complete history of credits and payments for every customer.
- **WhatsApp Integration**: Quickly transition from POS to communication with integrated phone and contact fields.
- **Debt Collection**: Specialized "Credits" screen to manage outstanding balances and collection due dates.

### ⚙️ Premium Settings & Branding
- **Dynamic Store Branding**: Change your store name and watch the entire app (titles, sidebars, receipts) sync instantly.
- **Triple Theme Support**: Toggle between **Light**, **Dark**, and the signature **Star Admin (Navy/Orange)** theme.
- **Auto-Backups**: Peace of mind with automated SQLite database backups to your local storage.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Desktop)
- **Database**: [SQLite](https://www.sqlite.org/index.html) (Offline-First, FFI)
- **State Mgmt**: [Provider](https://pub.dev/packages/provider) (Clean Architecture)
- **Visuals**: [Lucide Icons](https://lucide.dev/), [fl_chart](https://pub.dev/packages/fl_chart)
- **Windows Integration**: [bitsdojo_window](https://pub.dev/packages/bitsdojo_window)
- **PDF Engine**: [pdf](https://pub.dev/packages/pdf), [intl](https://pub.dev/packages/intl)

## 🏗️ Architecture

Gravity POS follows a strict **Layered Clean Architecture**:
1.  **Presentation Layer**: Custom-built widgets and UI controllers (Providers) using our premium design system.
2.  **Application Layer**: Business logic providers that orchestrate data flow between UI and Repositories.
3.  **Data Layer**: Encapsulated Repositories and SQLite DAOs to ensure data integrity and high performance.

## 📈 Business Logic & Metrics

For detailed information on how we calculate Revenue, Net Profit, and Costs, please refer to our internal logic documentation:
👉 [**Business Logic & Reports Guide**](business_logic_reports.md)

## 🚦 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Windows Development Environment (C++ tools)

### Installation
1.  Enable Windows support: `flutter config --enable-windows-desktop`
2.  Install dependencies: `flutter pub get`
3.  Launch: `flutter run -d windows`

---
*Built with ❤️ for Hunain Mart.*
