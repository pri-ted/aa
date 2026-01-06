# Glossary

> Terms and definitions used throughout this documentation.

---

## Platform Terms

| Term | Definition |
| ------ | ------------ |
| **Platform** | The Campaign Lifecycle Management system being built |
| **Module** | A discrete functional capability (Pacing, Alerts, QA, Taxonomy) |
| **Organization (Org)** | A tenant/customer using the platform |
| **Pipeline** | A configured data flow from source to destination |
| **Connector** | An adapter for external systems (DSPs, CRMs) |

---

## Advertising Terms

| Term | Definition |
| ------ | ------------ |
| **DSP** | Demand-Side Platform - used to buy ad inventory (DV360, TTD, Meta) |
| **SSP** | Supply-Side Platform - used to sell ad inventory (GAM, Index) |
| **Campaign** | Top-level advertising initiative with budget and dates |
| **IO** | Insertion Order - a commitment to run advertising under a campaign |
| **Line Item** | Targeting and bidding settings within an IO |
| **Creative** | The actual ad content (image, video, etc.) |
| **Impression** | One display of an ad to a user |
| **Pacing** | Rate at which budget/impressions are being delivered |
| **SDF** | Structured Data Files - standardized campaign data format |

---

## DSP-Specific Terms

### DV360 (Display & Video 360)

| Term | Definition |
| ------ | ------------ |
| **Partner** | Top-level account in DV360 hierarchy |
| **Advertiser** | Brand or client within a partner |
| **Insertion Order** | Container for line items with shared budget |
| **Line Item** | Targeting and bidding configuration |

### TTD (The Trade Desk)

| Term | Definition |
| ------ | ------------ |
| **Partner** | Agency or parent account |
| **Advertiser** | Brand or client |
| **Campaign** | Top-level container |
| **Ad Group** | Targeting and bidding settings |

### Meta (Facebook/Instagram)

| Term | Definition |
| ------ | ------------ |
| **Business Account** | Top-level organization |
| **Ad Account** | Billing and campaign container |
| **Campaign** | Top-level objective |
| **Ad Set** | Targeting and budget settings |
| **Ad** | Creative and placement |

---

## Data Terms

| Term | Definition |
| ------ | ------------ |
| **Bronze Layer** | Raw, unprocessed data as received from source |
| **Silver Layer** | Cleaned, validated, normalized data |
| **Gold Layer** | Business-ready aggregations and metrics |
| **Iceberg** | Open table format for data lake storage |
| **ClickHouse** | Columnar database for analytics queries |
| **Lakehouse** | Architecture combining data lake and warehouse |

---

## Architecture Terms

| Term | Definition |
| ------- | ------------ |
| **Control Plane** | Services managing configuration, users, permissions |
| **Execution Plane** | Services processing data and running pipelines |
| **Temporal** | Durable workflow orchestration engine |
| **Circuit Breaker** | Pattern to prevent cascading failures |
| **Event Sourcing** | Storing state changes as sequence of events |
| **CQRS** | Command Query Responsibility Segregation |

---

## API Terms

| Term | Definition |
| ------- | ------------ |
| **REST** | Representational State Transfer API style |
| **GraphQL** | Query language for APIs |
| **gRPC** | High-performance RPC framework |
| **JWT** | JSON Web Token for authentication |
| **OAuth 2.0** | Authorization framework |

---

## Kubernetes Terms

| Term | Definition |
| ------- | ------------ |
| **Pod** | Smallest deployable unit in K8s |
| **Service** | Network abstraction for pods |
| **Deployment** | Declarative pod management |
| **Namespace** | Virtual cluster within K8s |
| **Helm** | Package manager for K8s |
| **ArgoCD** | GitOps continuous delivery tool |

---

## Abbreviations

| Abbr | Full Form |
| ------- | ----------- |
| API | Application Programming Interface |
| CRUD | Create, Read, Update, Delete |
| ETL | Extract, Transform, Load |
| HLD | High-Level Design |
| LLD | Low-Level Design |
| OLAP | Online Analytical Processing |
| OLTP | Online Transaction Processing |
| QA | Quality Assurance |
| RBAC | Role-Based Access Control |
| SLA | Service Level Agreement |

---

## Navigation

- **Previous:** [Architectural Principles](principles.md)
- **Up:** [Overview](README.md)
