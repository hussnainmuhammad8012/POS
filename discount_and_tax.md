# Discount and Tax System Guide

This document outlines the operational details of the Discount and Tax system integrated into the POS.

## 1. Discount System

The system supports two main types of discounts, controlled by settings in the **Store Information** section.

### 1.1. Discount Types
- **Fixed Amount (Absolute):** Discounts are entered and calculated in the local currency (e.g., Rs).
- **Percentage (%):** Discounts are entered as a percentage of the unit price or bill subtotal.
  - *Toggle:* `calculatePercentageDiscount` in Settings.

### 1.2. Item-Level Discounts
- Each item in the cart can have its own discount.
- If **Percentage Mode** is active, entering `10` will apply a 10% reduction to that item's unit price.
- Item discounts are stored individually in the `transaction_items` table.

### 1.3. Bill-Level (Global) Discounts
- Applied to the entire transaction after all item-level discounts and taxes have been summed.
- Stored as a total discount amount in the `transactions` table.

### 1.4. UOM Price Gap (Multi-Unit Management)
- When selling in bulk units (e.g., a cartoon instead of pieces), there is often a price difference.
- If `treatUomPriceGapAsDiscount` is enabled, this difference is automatically calculated as a discount.
- This discount is explicitly shown on receipts and recorded in reports to show "Savings" to the customer.

## 2. Tax System

The tax system is fully implemented and integrated into the POS.

### 2.1. Enabling Tax
- Go to **Settings → Store Information**.
- Toggle **"Enable Tax System"** ON.

### 2.2. Tax Modes

| Mode | Description |
|------|-------------|
| **Inclusive** | Prices already include tax. Tax is extracted from the price. Formula: `Tax = Price - Price / (1 + rate%)` |
| **Exclusive** | Tax is added on top of the price. Formula: `Tax = Price × rate%` |

### 2.3. Tax Rates
- **Default Global Rate:** Set in Settings under "Enable Tax System" (e.g., `5.0` for 5%).
- **Per-Unit Rate:** Each product unit (base or multiplier) can have its own `Tax Rate (%)` field in the Add/Edit Product dialog. This overrides the global rate for that unit.
- If a unit has `taxRate = 0`, no tax is applied to it regardless of global settings.

### 2.4. Display
- **Cart:** A "Tax (Incl.)" or "Tax (Excl.)" row appears in the cart summary only when the tax system is enabled and at least one item has a non-zero tax rate.
- **Receipt & PDF:** Each item shows its individual tax (e.g., `Tax (5.0%): +Rs. 5.00`). The receipt totals section shows the full tax breakdown with inclusive/exclusive label.
- **Invoice:** The `Transaction` record stores `tax` (total amount) and `isTaxInclusive` (true/false).

### 2.5. Data Stored
- `product_units.tax_rate` — per-unit tax percentage
- `product_variants.tax_rate` — per-variant tax percentage
- `transaction_items.tax_rate`, `transaction_items.tax_amount` — tax per line item
- `transactions.total_tax` (aliased as `tax`), `transactions.is_tax_inclusive`

## 3. Data Integrity
- All discounts and taxes are preserved in the database for accurate historical reporting.
- Recalculations happen in real-time within `PosProvider` using `_recalculateAllTaxes()`.

> [!TIP]
> Use the `allowDiscounts` and `enableTaxSystem` master toggles in Settings to quickly enable/disable these features.

> [!NOTE]
> Tax and discount are calculated independently. For **exclusive** tax, the order is: `Subtotal + Tax - Discount = Total`. For **inclusive** tax, the order is: `Subtotal - Discount = Total` (tax is already embedded).
