# Business Logic & Report Calculations

This document details the core logic and calculation methodologies for the **Utility Store POS** reporting system.

## 1. Key Metrics & KPIs

| Metric | Calculation Logic | Data Source |
| :--- | :--- | :--- |
| **Total Revenue** | $\sum(\text{final\_amount})$ of all transactions. Includes retail/wholesale prices, taxes, and discounts. | `transactions` table |
| **Total Cost** | $\sum(\text{cost\_price} \times \text{quantity})$ for all items sold. Uses the `cost_at_time_of_sale`. | `transaction_items` table |
| **Net Profit** | `Total Revenue - Total Cost`. | Computed |
| **Total Credit** | $\sum(\text{current\_credit})$ across all customers. | `customers` table |

## 2. Wholesale Mode & Prices
When **Wholesale Mode** is enabled:
- **Price Switching**: The system automatically uses the defined `Wholesale Price`. If not set, it defaults to `Retail Price`.
- **Revenue Impact**: Total revenue will reflect the lower wholesale price.
- **Profit Tracking**: The system tracks profit by subtracting the original `Cost Price` from the `Wholesale Price`, ensuring margin accuracy for bulk sales.

## 3. Date Range and Filtering Logic
The analytics system uses a dual-mode logic for maximum business utility:

### Filtered by Date (Period-Specific)
The following metrics correspond **only** to the selected start and end dates:
- **Revenue**: Total sales made **during** the selected period.
- **Cost**: Total purchase cost of items sold **during** the selected period.
- **Profit**: Earnings generated **during** the selected period.
- **Performance Rankings**: Top Selling Products and Top Categories are ranked based **only** on sales within this period.

### Real-time Snapshots (Live System Status)
The following metrics show the **current state** of the business today, regardless of the report date range:
- **Total Credit to Collect**: The total outstanding debt currently owed by all customers across all time. This is intentional to remind the business owner of their total cash flow exposure.
- **Low Stock Count**: The number of items currently requiring restock today.

---
*Note: Using cost at the time of sale (`cost_at_time`) ensures that historical profit reports remain accurate even if you update your product purchase prices later.*
