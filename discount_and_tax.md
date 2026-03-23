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

## 2. Tax System (Upcoming)

The tax system will follow a similar logic to the discount system:
- **Global Tax Rate:** A base tax percentage applied to the bill.
- **Item-Specific Tax:** (Planned) Ability to set different tax categories per product.
- **Tax Inclusion/Exclusion:** (Planned) Settings to determine if prices are inclusive or exclusive of tax.

## 3. Data Integrity
- All discounts (both percentage and absolute) are preserved in the database to ensure accurate historical reporting.
- Recalculations happen in real-time within the `PosProvider` to provide immediate feedback in the UI.

> [!TIP]
> Use the `allowDiscounts` master toggle in Settings to quickly enable or disable all discount features across the POS.
