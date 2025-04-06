# Enterprise Wireless Security Assessment Platform

![Python](https://img.shields.io/badge/Python-3.9%2B-blue)
![Flask](https://img.shields.io/badge/Flask-2.0%2B-red)
![Aircrack-ng](https://img.shields.io/badge/Aircrack--ng-1.7%2B-orange)
![Docker](https://img.shields.io/badge/Docker-20.10%2B-2496ED)
![License](https://img.shields.io/badge/License-AGPL%203.0-green)

A comprehensive wireless network security evaluation system combining CLI penetration testing tools with a web-based management interface. Designed for enterprise security teams to conduct authorized wireless security audits with full audit trail capabilities.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Key Features](#key-features)
- [Technical Specifications](#technical-specifications)
- [Installation & Deployment](#installation--deployment)
- [Usage Guide](#usage-guide)
- [Security Considerations](#security-considerations)
- [Compliance](#compliance)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

## Architecture Overview

![System Architecture](https://i.imgur.com/ZsHjv7L.png)

The platform follows a modular microservices architecture:
1. **Web Interface**: Flask-based management console
2. **Task Engine**: Celery/RabbitMQ for asynchronous operations
3. **Wireless Toolkit**: aircrack-ng suite integration
4. **Data Layer**: PostgreSQL with Redis caching
5. **Reporting Engine**: PDF/HTML report generation
6. **Security Layer**: RBAC, MFA, and Audit Logging

## Key Features

### Core Functionality
- 802.11 a/b/g/n/ac Wireless Protocol Analysis
- WPA/WPA2 Enterprise & Personal Security Audits
- Simultaneous Multi-Interface Monitoring
- Automated Handshake Capture & Validation
- Rainbow Table & Dictionary Attack Integration
- Client Device Fingerprinting (OUI, Protocols, Behavior)

### Management Console
- Real-time Spectrum Analysis Dashboard
- Historical Scan Comparison Tools
- Vulnerability Knowledge Base Integration
- Collaborative Report Annotation
- Scheduled Scan Configuration
- Device Geolocation Mapping (Wi-Fi Triangulation)

### Security Features
- Role-Based Access Control (RBAC)
- JWT Authentication with Refresh Tokens
- Complete Audit Trail with Action Playback
- AES-256 Encrypted Session Storage
- HSM Integration for Credential Management
- Automated Evidence Chain-of-Custody

### Reporting System
- Executive Summary Generation
- Technical Findings Catalog
- Compliance Gap Analysis
- Remediation Workflow Tracking
- Multiple Export Formats (PDF, DOCX, JSON)
- Automated CVE Cross-Reference

### Deployment Options
- Docker Swarm/Kubernetes Ready
- Air-Gapped Environment Support
- Multi-User Team Collaboration
- SCAP Integration
- SIEM Integration (Splunk, ELK)
- Automated Backup & Recovery

## Technical Specifications

### Prerequisites
- Linux Kernel 5.4+ (Recommended: Kali Linux 2023.4)
- Wireless Adapter with Monitor Mode & Packet Injection
- Docker Engine 24.0+
- Minimum 4GB RAM (8GB Recommended)
- 20GB Disk Space (SSD Recommended)

### Dependencies
| Component       | Version   | Purpose                          |
|-----------------|-----------|----------------------------------|
| aircrack-ng     | 1.7       | Wireless packet capture/analysis|
| tshark          | 3.6.10    | Protocol dissection              |
| hashcat         | 6.2.5     | Password cracking                |
| Redis           | 7.0       | Task queue & caching             |
| PostgreSQL      | 15        | Relational data storage          |
| WeasyPrint      | 58        | PDF report generation            |

### Supported Hardware
| Chipset         | Monitor Mode | Packet Injection | Recommended Use       |
|-----------------|--------------|-------------------|-----------------------|
| Atheros AR9271  | Yes          | Yes               | General scanning      |
| RTL8812AU       | Yes          | Yes               | 5GHz band analysis    |
| Intel AX210     | Partial      | No                | Client emulation      |
| Ubertooth One   | N/A          | N/A               | Bluetooth coexistence|

## Installation & Deployment

### Docker Deployment (Recommended)
```bash
# Clone repository
git clone https://github.com/yourorg/wireless-audit-platform.git
cd wireless-audit-platform

# Configure environment
cp .env.example .env
nano .env  # Edit configuration values

# Build and launch
docker-compose up --build -d

# Initialize database
docker-compose exec web flask db upgrade
```
# Install system dependencies
sudo apt install -y build-essential libssl-dev zlib1g-dev \
libpcap-dev libpq-dev wireless-tools usbutils

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python requirements
pip install -r requirements.txt

# Configure runtime environment
export FLASK_APP=wsgi.py
export FLASK_ENV=production

# Database setup
flask db init
flask db migrate
flask db upgrade

# Start services
celery -A app.tasks worker --loglevel=info &
gunicorn --bind 0.0.0.0:5000 wsgi:app

```
```markdown
# Through web interface:
1. Navigate to Scans > New Assessment
2. Select wireless interface(s)
3. Configure scan parameters:
   - Channels: 1-14 (2.4GHz), 36-165 (5GHz)
   - Duration: 300-600 seconds
   - Packet buffer: 500MB-2GB
4. Confirm legal authorization
5. Start scan

# Through API:
POST /api/v1/scans
Headers: {"Authorization": "Bearer <JWT>"}
Body: {
  "interface": "wlan0",
  "channels": [1,6,11],
  "duration": 600,
  "output_prefix": "audit-2023Q4"
}
```

