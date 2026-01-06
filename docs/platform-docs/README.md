# 🏠 Campaign Lifecycle Platform - Documentation Hub

> **The definitive source of truth for platform architecture, design, and implementation.**

---

## 📊 Platform at a Glance

| Metric | Current | Target |
| -------- | --------- | -------- |
| Onboarding Time | 40-60 hours | **5 minutes** |
| Manual Steps | 97 steps | **0 steps** |
| Organizations | ~24 | **1,000+** |
| Cost per Org | $50/month | **$2-5/month** |

---

## 🗂️ Documentation Structure

### [📋 1. Platform Overview](./01-overview/README.md)

High-level introduction to the platform, vision, goals, and principles.

- [Executive Summary](./01-overview/executive-summary.md)
- [Vision & Goals](./01-overview/vision-and-goals.md)
- [Architectural Principles](./01-overview/principles.md)
- [Glossary](./01-overview/glossary.md)

### [🏗️ 2. System Architecture](./02-architecture/README.md)

Complete system design from high-level to component level.

- [High-Level Design (HLD)](./02-architecture/hld.md)
- [System Boundaries](./02-architecture/system-boundaries.md)
- [Data Flow](./02-architecture/data-flow.md)
- [Technology Stack](./02-architecture/tech-stack.md)

### [⚙️ 3. Service Catalog](./03-services/README.md)

Detailed specifications for all 12 microservices.

- [Auth Service](./03-services/auth/README.md)
- [Config Service](./03-services/config/README.md)
- [Connector Service](./03-services/connector/README.md)
- [ETL Orchestrator](./03-services/etl/README.md)
- [Data Services (Bronze/Silver/Gold)](./03-services/bronze/README.md)
- [Intelligence Services](./03-services/calculation/README.md)

### [💾 4. Data Architecture](./04-data/README.md)

Database schemas, API specifications, and data lake design.

- [Database Schemas](./04-data/schemas/README.md)
- [API Specifications](./04-data/apis/README.md)
- [Iceberg Lakehouse Design](./04-data/lakehouse/README.md)

### [📦 5. Module System](./05-modules/README.md)

Business modules and their configurations.

- [Module Framework](./05-modules/framework.md)
- [Pacing & Margin](./05-modules/pacing/README.md)
- [Alerts](./05-modules/alerts/README.md)
- [QA (Quality Assurance)](./05-modules/qa/README.md)
- [Taxonomy](./05-modules/taxonomy/README.md)

### [🔌 6. Integration Layer](./06-integrations/README.md)

DSP and external system integrations.

- [Connector Framework](./06-integrations/connector-framework.md)
- [DV360 Integration](./06-integrations/dv360/README.md)
- [TTD Integration](./06-integrations/ttd/README.md)
- [Meta Integration](./06-integrations/meta/README.md)
- [CRM Integration](./06-integrations/crm/README.md)

### [🔐 7. Security Architecture](./07-security/README.md)

Authentication, authorization, and security controls.

- [Authentication Flow](./07-security/authentication.md)
- [Permission Model](./07-security/permissions.md)
- [Encryption & Secrets](./07-security/encryption.md)
- [Network Security](./07-security/network.md)

### [☁️ 8. Infrastructure](./08-infrastructure/README.md)

Kubernetes, deployment, and operations.

- [Kubernetes Architecture](./08-infrastructure/kubernetes.md)
- [Deployment Strategy](./08-infrastructure/deployment.md)
- [Monitoring & Observability](./08-infrastructure/monitoring.md)
- [Disaster Recovery](./08-infrastructure/disaster-recovery.md)

### [🚀 9. Development](./09-development/README.md)

Roadmap, migration strategy, and development guides.

- [Development Roadmap](./09-development/roadmap.md)
- [Migration Strategy](./09-development/migration.md)
- [Development Guide](./09-development/dev-guide.md)

### [📚 10. Appendix](./10-appendix/README.md)

Reference materials and supporting documents.

- [Decision Log](./10-appendix/decision-log.md)
- [Risk Register](./10-appendix/risk-register.md)
- [Cost Analysis](./10-appendix/cost-analysis.md)

---

## 🔗 Quick Links

| Need | Go To |
| ------ | ------- |
| Understanding the system | [Executive Summary](./01-overview/executive-summary.md) |
| API reference | [API Specifications](./04-data/apis/README.md) |
| Database schemas | [Database Schemas](./04-data/schemas/README.md) |
| Service details | [Service Catalog](./03-services/README.md) |
| Deployment guide | [Kubernetes Architecture](./08-infrastructure/kubernetes.md) |

---

## 📅 Document Info

| Property | Value |
| ---------- | ------- |
| Version | 1.0 |
| Last Updated | December 24, 2025 |
| Status | Source of Truth |
| Owner | Platform Engineering |
