# Ronin Application Documentation

## 📚 Documentation Structure

This documentation is organized by skill level to help you find the right information for your needs.

### 🟢 [Beginner Guide](./01_BEGINNER_GUIDE.md)
**For**: New team members, junior developers, business analysts

- What is Ronin?
- Basic concepts and terminology
- Simple data flow diagrams
- Common tasks and how to perform them
- Where to find things

### 🟡 [Mid-Level Guide](./02_MID_LEVEL_GUIDE.md)
**For**: Developers, data engineers, system analysts

- Detailed system architecture
- ETL processes and patterns
- Business logic and stored procedures
- Integration patterns
- Troubleshooting guide

### 🔴 [Senior Engineer Guide](./03_SENIOR_GUIDE.md)
**For**: Architects, senior engineers, technical leads

- Complete system architecture
- Advanced patterns and best practices
- Performance optimization
- Security model deep dive
- System dependencies and integration points

---

## 🎯 Quick Start

### I'm new to Ronin
→ Start with [Beginner Guide](./01_BEGINNER_GUIDE.md)

### I need to understand how data flows
→ See [Mid-Level Guide - Data Flow](./02_MID_LEVEL_GUIDE.md#data-flow-patterns)

### I'm designing a new feature
→ See [Senior Guide - Architecture](./03_SENIOR_GUIDE.md#system-architecture)

---

## 📊 System Overview

**Ronin** is an enterprise financial planning, budgeting, and forecasting system for **Dentsu** (global advertising agency network).

### Key Capabilities
- 💰 Budget and OPEX management
- 📊 Financial forecasting
- 📺 Media planning (MyFC)
- 👥 Client relationship management
- 🔄 Multi-system data integration

### Technology Stack
- **Database**: SQL Server
- **Source Systems**: SAP, D365, Workday, Navision, Paprika, NetSuite
- **Reporting**: Power BI
- **Architecture**: Data Warehouse with ETL staging

---

## 🔍 Navigation

| Topic | Beginner | Mid-Level | Senior |
|-------|----------|-----------|--------|
| What is Ronin? | ✅ | ✅ | ✅ |
| Database Structure | ✅ | ✅ | ✅ |
| Data Flow | ✅ | ✅ | ✅ |
| ETL Processes | ❌ | ✅ | ✅ |
| Stored Procedures | ❌ | ✅ | ✅ |
| Security Model | ❌ | ✅ | ✅ |
| Performance | ❌ | ❌ | ✅ |
| Architecture Patterns | ❌ | ❌ | ✅ |

---

## 📝 Document Version

- **Version**: 2.0
- **Last Updated**: Based on latest database metadata
- **Structure**: Multi-level documentation with Mermaid diagrams

---

## 🤝 Contributing

When updating documentation:
1. Update the appropriate level guide
2. Update diagrams if architecture changes
3. Keep examples current
4. Test all code snippets
