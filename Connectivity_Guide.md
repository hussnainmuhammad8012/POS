# Gravity POS - Companion App Connectivity Guide

This guide provides step-by-step instructions to ensure a seamless connection between the Desktop POS and the Companion App.

## 1. Initial Setup
1. **Desktop**: Open your POS Application and go to **Settings > Companion Server**.
2. **Enable Server**: Click "Enable Local API Server".
3. **QR Code**: A QR code will appear. This contains the connection details for your PC.

## 2. Network Preparation
For the app to "talk" to the PC, they must be on the same network.

### Option A: Shared Wi-Fi (Recommended)
- Connect your **PC** to the Wi-Fi.
- Connect your **Phone** to the **SAME Wi-Fi**.

### Option B: PC Mobile Hotspot
- Turn on **Mobile Hotspot** on your Windows PC.
- Connect your **Phone** to the PC's Hotspot Wi-Fi.
- **Tip**: On the phone, turn off "Mobile Data" (LTE/5G) to ensure it uses the PC Hotspot link.

---

## 3. Resolving Windows Firewall (Critical)
Windows often blocks mobile apps by default. To allow the connection, run this command on the PC:

1. Click **Start** and type **cmd**.
2. Right-click **Command Prompt** and select **Run as Administrator**.
3. Copy and paste the following command:
   ```
   netsh advfirewall firewall add rule name="POS_Companion_Link" dir=in action=allow protocol=TCP localport=8080 profile=any
   ```
4. Press Enter. It should say **"Ok."**

---

## 4. Troubleshooting
If the app says "Connection Failed" after scanning:

- **Network Profile**: Ensure your PC Wi-Fi is set to **"Private"** (Settings > Network > Wi-Fi > Properties).
- **Antivirus**: Third-party programs like Avast, McAfee, or Kaspersky may have their own firewall. You must add an "Exclusion" for Port **8080** in those programs.
- **IP Test**: Open the browser on the phone and type: `http://[PC_IP_ADDRESS]:8080/ping`. If you see `{"status":"ok"}`, the connection is working.

---
*Developed by Gravity POS Team*
