# Utility Store POS (Desktop)

A modern, analytics-heavy desktop Point-of-Sale system for a single-counter utility store. Built with **Flutter** and **SQLite** for beautiful cross-platform UI and reliable local storage.

## Features

- **Dashboard**
  - Today’s sales, transactions, active customers, low stock items, and profit KPIs
  - 7-day sales trend chart and sales by category (donut chart)
  - Top 5 products and recent transactions
- **Point of Sale**
  - Fast cart UI with quantity controls and remove/void actions
  - Bulk quantity + barcode entry workflow
  - Customer selection and quick-add
  - Payment modal with cash/card/other methods
- **Inventory Management**
  - Categories with CRUD
  - Products with price, cost, stock, low stock thresholds, and image placeholder
  - Search and filter by category
  - Low-stock highlighting
- **Stock Movements**
  - Automatic stock deduction and logging for sales (schema + repository ready)
  - API for restock/adjustment operations
- **Customers**
  - Customer list with search and loyalty/total spent data fields
  - Customer profile view with stats and purchase history placeholder
- **Analytics & Reports**
  - Time range presets (Today, Week, Month, Custom placeholder)
  - Sales overview, best/worst sellers, profit analysis, and customer insights (wired with mock data; ready for DB integration)
  - Export button placeholder for PDF/Excel
- **Settings**
  - Store info, tax rate, and receipt footer
  - Backup/restore SQLite database file
  - Theme mode toggle and printer settings placeholder

## Tech Stack

- **Flutter** (desktop – Windows, macOS, Linux with the same codebase)
- **SQLite** via `sqflite_common_ffi`
- **Provider** for state management
- **fl_chart** for charts and analytics visuals
- **file_picker** for backup/restore

## Getting Started

### Prerequisites

- Flutter SDK (3.x or later) installed and configured
- For Windows desktop:
  - Enable desktop support with:

```bash
flutter config --enable-windows-desktop
```

### Install Dependencies

From the project root:

```bash
flutter pub get
```

### Run the Application (Windows)

```bash
flutter run -d windows
```

The app will create a local `data/utility_store_pos.db` SQLite file relative to the executable folder for all persistent data.

## Project Structure

- `lib/main.dart` – App entrypoint, theming, providers, navigation
- `lib/core/database/app_database.dart` – SQLite initialization and schema
- `lib/core/models/entities.dart` – Core entity models (products, customers, transactions, etc.)
- `lib/core/repositories/*_repository.dart` – Database access and business logic entry points
- `lib/core/theme/app_theme.dart` – Light/dark themes and color system
- `lib/core/widgets/*` – Shared widgets (navigation shell, KPI cards)
- `lib/features/*` – Feature modules by domain:
  - `dashboard`
  - `pos`
  - `inventory`
  - `customers`
  - `analytics`
  - `settings`

## Production-Readiness Notes

- **Data integrity**
  - SQLite schema enforces primary keys and relationships
  - Stock movements are logged on sales in a transaction to keep stock consistent
- **UX**
  - Consistent color-coded feedback and tooltips
  - Empty states and friendly error snackbars instead of blank screens
  - Dialog confirmations for destructive actions (delete, void sale)
- **Extensibility**
  - Repositories encapsulate all DB access, so you can evolve analytics or add suppliers/returns without touching the UI
  - Analytics screens are wired with mock data but structured for swapping in real aggregates from repositories

## Next Implementation Steps (Optional Enhancements)

- Wire POS barcode lookup to `ProductRepository.getByBarcode`
- Implement full transaction saving in POS using `TransactionRepository`
- Add real analytics queries to replace mock charts
- Implement CSV/XLSX import using `file_picker` + a parser
- Integrate with a receipt printer (over USB/network) and PDF export for receipts/reports

