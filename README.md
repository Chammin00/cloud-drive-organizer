# 🚀 DriveFlow | Cloud & PC AutoOrganizer

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg)](https://microsoft.com)
[![Zero-Dependencies](https://img.shields.io/badge/Dependencies-Zero%20(Pure%20PowerShell%20%2B%20HTML5)-success.svg)]()
[![Mobile-Ready](https://img.shields.io/badge/Mobile-Responsive%20PWA-indigo.svg)]()

> **1-Click storage organization, intelligent categorization, and automated cron/Task Scheduler setups for Google Drive, OneDrive, and PC Downloads.**

---

## 🌟 Key Features

- **⚡ 1-Click Multi-Drive Sweep**: Organize Google Drive, OneDrive, and PC Downloads simultaneously with a single button.
- **📱 Mobile-Friendly & Web Dashboard**: Sleek, glassmorphic UI built with Tailwind CSS. Accessible on desktop at `http://localhost:8080` or on your smartphone over local Wi-Fi.
- **⏰ Scheduled Cron & Task Scheduler Setup**: Visual cron expression builder with presets (Daily at 9:00 AM, Midnight, 6 Hours, Weekly). Instantly registers background jobs in Windows Task Scheduler.
- **🧠 Smart Taxonomy Classifier**: Automatically sorts files by content, type, and keyword into 7 standardized core categories:
  - `📁 Financial & Taxes` (1099s, W2s, bank statements, receipts)
  - `📁 Career & Professional` (resumes, employment verifications)
  - `📁 Real Estate & Properties` (deeds, surveys, contracts, closing disclosures)
  - `📁 Tech & Certifications` (packet tracer labs, certifications, ISOs, virtual appliances)
  - `📁 Gaming & Development` (ROMs, emulators, clips, projects)
  - `📁 Vehicles` (maintenance records, carfax, auto insurance)
  - `📁 Personal & Family` (childcare records, travel media, government IDs)
- **🔒 Protected System Directories**: Strictly safeguards application sync folders (`Google Photos`, `Antigravity`, `Colab Notebooks`, `Desktop`, `Documents`, `Pictures`) and OS registry hives.
- **📦 Zero External Dependencies**: Powered natively by Windows PowerShell `.NET HttpListener`. No Node.js or Python installation required.

---

## 🚀 Quick Start (1-Click)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Chammin00/cloud-drive-organizer.git
   cd cloud-drive-organizer
   ```

2. **Launch the app:**
   Double-click `launch.bat` or run:
   ```powershell
   .\launch.bat
   ```

3. **Enjoy!** The dashboard opens automatically in your browser at `http://localhost:8080`.

---

## 📱 Mobile Access (Local Network)

To control and monitor your storage organization from your phone:
1. Ensure your PC and mobile device are connected to the same Wi-Fi network.
2. Find your PC's local IP address (`ipconfig` in terminal, e.g. `192.168.1.150`).
3. Open `http://<YOUR-PC-IP>:8080` in your mobile browser.
4. (Optional) Tap **Add to Home Screen** to install as a standalone mobile app.

---

## 🛠️ Architecture

```
cloud-drive-organizer/
├── launch.bat                     # 1-Click Windows desktop launcher
├── server.ps1                     # Lightweight native REST API server (port 8080)
├── public/
│   └── index.html                 # Mobile-first responsive web dashboard
├── scripts/
│   ├── organize_all.ps1           # Unified multi-drive organization engine
│   ├── setup_task.ps1             # Windows Task Scheduler automation
│   └── push_to_github.ps1         # GitHub sync utility
├── .gitignore                     # Git ignore rules
├── LICENSE                        # MIT License
└── README.md                      # Documentation
```

---

## ⚙️ Cron & Task Scheduling Options

| Schedule | Cron Expression | Windows Task Trigger |
| :--- | :--- | :--- |
| **Daily (Morning)** | `0 9 * * *` | Every day at 9:00 AM |
| **Daily (Midnight)** | `0 0 * * *` | Every day at 12:00 AM |
| **Every 6 Hours** | `0 */6 * * *` | Hourly interval |
| **Weekly** | `0 0 * * 0` | Every Sunday at midnight |

---

## 📜 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
