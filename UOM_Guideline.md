# Multi-Unit of Measure (UOM) Implementation Guideline

This document provides a comprehensive overview of the Multi-Unit of Measure (UOM) system implemented in the Utility Store POS. It covers the architecture, business logic, pricing strategies, and cross-screen integration.

---

## 1. Core Architecture & Data Models

The UOM system is built on a "Base Unit" principle. Every product has a primary unit (e.g., Piece) and can have multiple higher-level units (e.g., Pet, Carton).

### `ProductUnit` Model
Located in `lib/features/inventory/data/models/product_unit_model.dart`.
- `id`: Unique identifier (starts with `unit_`).
- `productId`: Links to the base `Product`.
- `unitName`: Human-readable name (e.g., "Pet", "Box").
- `conversionRate`: How many base units make up this unit (e.g., 1 Pet = 6 Pieces).
- `retailPrice`: Price when selling this specific unit.
- `wholesalePrice`: Bulk price for this unit.
- `costPrice`: Cost for this unit (usually `baseCost * conversionRate`).
- `barcode`/`qr_code`: Unique codes for scanning this specific unit.

### `CartItem` Model (UOM Enhanced)
Located in `lib/features/pos/data/models/cart_item.dart`.
- `variantId`: For UOM items, this is a synthetic key: `${productId}__${unitId}`. For classic items, it's the `variant.id`.
- `baseVariantId`: The ID of the actual base variant in the database (used for stock deduction).
- `productSku`: The base SKU of the product.
- `conversionRate`: Used to calculate "Base Unit Equivalents" for stock checks.
- `productUnits`: A list of all available units for the product, enabling fluid switching in the cart.

---

## 2. Desktop "Command Center" Logic

The Desktop application acts as the control unit. If the `isUomEnabled` toggle is **OFF**, the system falls back to the classic single-unit variant flow.

### Barcode Scanning (`handleBarcode`)
1. Search for code in `product_units` first.
2. If found, add the specific unit to the cart using `_addUomToCart`.
3. If not found, search in `product_variants` (Classic Mode).

### Fluid Unit Selector (`AppUomSelector`)
A premium UI component that allows users to instantly switch between different units (e.g., changing a "Piece" to a "Pet") directly in the cart. 
- Automatically updates `unitPrice`, `profitMargin`, and `conversionRate`.
- Triggers `_autoUpscale` if the change creates a merge opportunity.

---

## 3. Dynamic Quantity Logic (Upscaling & Downscaling)

The system handles "broken" or mixed quantities fluidly to ensure the best price for the customer and accurate stock for the store.

### Auto-Upscaling (`_autoUpscale`)
When a base unit's quantity reaches a threshold (e.g., 6 pieces), the system automatically converts it into the higher unit (e.g., 1 Pet).
- **Exact Match**: If you have 6 pieces and 1 Pet = 6, the row transforms into 1 Pet.
- **Mixed Quantity**: If you have 8 pieces, they become **1 Pet** (at bulk price) and **2 Pieces** (at retail price). This is handled by creating two distinct rows in the cart.

### Fluid Downscaling (`decrementQuantity`)
If a user decrements a bulk unit (e.g., 1 Pet) and it's the last one, the system "breaks" it back into its constituent pieces (e.g., 5 pieces remaining) rather than just removing it.
- Ensures the user can sell exactly 5 pieces if they change their mind about a full Pet.

---

## 4. Pricing Calculation Strategy

The system follows a **"Best Unit + Remainder"** pricing strategy.

| Scenario | Logic | Result |
| :--- | :--- | :--- |
| **Full Units** | Customer buys 1 Pet (6 pieces). | Charged `pet.retailPrice`. |
| **Mixed Units** | Customer buys 8 bottles (Pieces). | System converts to **1 Pet** + **2 Pieces**. |
| **Calculation** | `(1 * PetPrice) + (2 * PiecePrice)`. | Total = Rs 600 + Rs 240 = Rs 840 (v.s. Rs 960 if all were retail). |

This logic ensures that customers automatically get bulk discounts when they reach the unit threshold, while also accurately accounting for remainders.

---

## 5. Stock Management

Stock is **always** managed at the base unit level in the database (`stock_levels.available_pieces`).
- **Insertion**: `quantity * conversionRate` is deducted.
- **Example**: 1 Pet (rate 6) deducts **6 pieces** from the database.
- **Refunds/Deletions**: The inverse logic applies.

---

## 6. Receipt & History System

### Detailed Breakdown
The Receipt Modal and PDF show an explicit breakdown for every item:
- **Bold Title**: `Product Name`
- **Identity**: `SKU: #SKU123`
- **Breakdown**: `  1 Pet x Rs 600.00` (indented for clarity).

### Transaction History (`TransactionRepository`)
Uses a **Poly-Join SQL Query** to ensure that human-readable names and SKUs are fetched correctly even if the `variant_id` saved is a UOM-specific `unit_` ID.
- Checks `product_variants` table first.
- Checks `product_units` table second.
- Returns `COALESCE` names and SKUs to the UI.

---

## 7. Companion App Integration (Mobile)

The Companion App mirrors the Desktop logic while adapting it for a mobile-first experience.

### 4-Step Product Creation
Located in `AddProductDialog`:
1. **Identity**: Basic product info (Category, Name, SKU).
2. **Pricing**: Defines the **Base Unit** (e.g., Piece) with its barcode, cost, and retail price.
3. **Multi-Units**: Dynamic UI to add multiplier units (e.g., Pet, Box) with custom conversion rates and prices.
4. **Stock**: Sets initial stock levels.

### UOM-Aware Stock Updates
Located in `InventoryScreen`:
- Users select the specific unit they are "adding" (e.g., adding 5 Boxes).
- **Client-Side Calculation**: Mobile multiplies `qty * conversionRate` to get `totalBasePieces`.
- **Sync**: Sends the `totalBasePieces` to the Desktop API, ensuring stock remains accurate at the base unit level in the shared database.

---

## 8. Cross-Platform Synchronization

1. **Desktop -> Mobile**: The `LocalApiServer` includes the full `units` list for every product summary.
2. **Mobile -> Desktop**: The `InventoryProvider` sends the `units` list during product creation, which the desktop `createProductWithUoms` repository method handles.
3. **Control**: Desktop remains the source of truth for all UOM definitions and toggle states.

---
> [!IMPORTANT]
> Any change to UOM logic must be first validated in the Desktop "Command Center" to ensure the database schema and business rules remain synchronized.
