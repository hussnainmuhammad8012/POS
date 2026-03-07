# Production Support & Data Reliance Guide

This guide provides critical information for administrators regarding the reliability, maintenance, and backup procedures for the POS system.

## 1. Database Reliability (SQLite)
The system uses **SQLite**, an enterprise-grade database engine.
- **Longevity**: SQLite is designed to last for decades without maintenance.
- **Storage Capacity**: It can store up to **281 Terabytes**. For a typical store, the database will likely remain under **200 MB** even after 5 years of daily operation.
- **Hardware Requirement**: Any modern Windows PC with an SSD is sufficient. SSDs are highly recommended for the best performance and data safety.

## 2. Data Loss Risks & Prevention
While the database is robust, external factors can put data at risk:
1.  **Hardware Failure**: If the PC's hard drive fails, data is lost.
2.  **Sudden Power Loss**: Can occasionally lead to database corruption.
3.  **Human Error**: Accidental deletion of the database file.

**Prevention:**
- **UPS (Uninterruptible Power Supply)**: Always use a UPS with your desktop POS systems to prevent corruption during power cuts.
- **Regular Backups**: Maintain redundant copies of the database in separate physical locations.

## 3. Backup Strategy
We recommend following the **3-2-1 Backup Rule**:
- **3** copies of your data (Live system + 2 backups).
- **2** different storage media (PC Hard Drive + USB Drive).
- **1** copy off-site (Google Drive or physical USB kept outside the store).

### How to Backup Manually
1.  Navigate to the project root directory.
2.  Open the `data/` folder.
3.  Copy the `utility_store_pos.db` file.
4.  Paste it onto your USB drive or Google Drive folder.
5.  **Frequency**: It is recommended to do this at the end of every business day.

## 4. Disaster Recovery (Restoring Data)
If the app crashes or you move to a new PC:
1.  **Install the App**: Reinstall the software on the new computer.
2.  **Locate Backup**: Find your most recent `utility_store_pos.db` backup file.
3.  **Replace File**: Paste your backup into the `data/` folder of the new installation (overwrite the empty one).
4.  **Launch**: Open the app. All your historical transactions, customers, and products will be restored immediately.

## 5. Software Upgrades & Changes
If the software is updated with new modules (e.g., Warehouse Management) after 6 months:
- **Automatic Migration**: The system uses a versioned migration engine. It will automatically update the database structure to support new features when you run the new version.
- **No Data Loss**: Your existing transaction records, customer balances, and inventory levels will be perfectly preserved during these upgrades.
