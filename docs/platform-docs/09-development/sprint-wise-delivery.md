# Development Roadmap (Phase 1 + Phase 2)

> **0 → Production-ready self-serve platform in 3 months**
> 2-week sprints, explicit outcomes per sprint

---

## High-Level Timeline

| Phase       | Duration                      | Goal                                 |
| ----------- | ----------------------------- | ------------------------------------ |
| **Phase 1** | **Weeks 1–6 (1–1.5 months)**  | Platform foundation + first pilots   |
| **Phase 2** | **Weeks 7–12 (1.5–3 months)** | Self-serve onboarding + core modules |

---

# Phase 1 — Foundation & Current Capabilities

**Duration:** Weeks 1–6
**Outcome:** Platform can ingest data, isolate orgs, and onboard pilots with minimal manual steps.

---

## Sprint 1 (Weeks 1–2): Infrastructure & Control Plane

### Deliverables

* Kubernetes cluster (ARM-first)
* GitOps via ArgoCD
* Secrets management (Vault / External Secrets)
* Base observability (metrics, logs, alerts)
* Environments: dev + staging (if req)

### Outcome

* Infra ready for continuous delivery
* No manual deployments
* Cost visibility from day 1

---

## Sprint 2 (Weeks 3–4): Core Platform Services

### Deliverables

* Auth service (user → org → role)
* Org isolation model (hard multi-tenancy)
* Config / Metadata service (DB-backed)
* PostgreSQL & Redis production setup
* Minimal UI shell (login + org context)

### Outcome

* Multi-org platform foundation
* No org-specific code paths
* Platform primitives in place

---

## Sprint 3 (Weeks 5–6): Data Ingestion (Read-Only)

### Deliverables

* Connector service (DV360 read)
* Unified raw ingestion schema
* Bronze + Silver layers
* Data validation & retries
* Backfill + replay support

### Outcome

* Reliable data flow for pilots
* Deterministic pipelines (no Celery-style fire-and-forget)
* Ready for real org data

### Phase 1 Exit Criteria

* ✅ 5–10 pilot orgs onboarded
* ✅ DV360 data flowing end-to-end
* ✅ < **30 min** manual onboarding
* ✅ Clear gaps identified for self-serve

---

# Phase 2 — Self-Serve Platform & Core Modules

**Duration:** Weeks 7–12
**Outcome:** Zero-code onboarding + usable product for 50+ orgs.

---

## Sprint 4 (Weeks 7–8): Metadata-Driven Platform

### Deliverables

* Unified logical data model
* Metadata-driven pipeline configs
* Org-level dataset provisioning
* Cost-aware ingestion controls
* Schema evolution support

### Outcome

* Pipelines defined as **data, not code**
* New org ≠ new engineering work
* Foundation for scale economics

---

## Sprint 5 (Weeks 9–10): Core Modules (Read-Only)

### Deliverables

* Pacing calculations (read)
* QA rule engine (basic)
* Taxonomy validation
* Alerts framework (conditions + triggers)
* Module enablement per org

### Outcome

* Core value visible to users
* Feature parity with current system (read-only)
* No write-back risk yet

---

## Sprint 6 (Weeks 11–12): Self-Serve Onboarding & Hardening

### Deliverables

* UI onboarding wizard
* DSP connection flow
* Module selection & defaults
* Automated org provisioning
* Performance & cost tuning
* Migration tooling for legacy orgs

### Outcome

* **< 5 min self-serve onboarding**
* Platform usable without engineering
* Infra trending toward **$5–7/org**

---

## Phase 2 Exit Criteria (Critical)

* ✅ 50–100 orgs active
* ✅ Zero code changes per new org
* ✅ Data accuracy ≥ 99%
* ✅ Clear path to $2–5/org at scale
* ✅ Ready for write-back expansion (Phase 3)

---

# Visual Timeline Summary

```text
Month 1
│ Sprint 1 │ Infra & GitOps
│ Sprint 2 │ Auth, Orgs, Config

Month 2
│ Sprint 3 │ DV360 Ingestion
│ Sprint 4 │ Metadata Platform

Month 3
│ Sprint 5 │ Pacing, QA, Alerts
│ Sprint 6 │ Self-Serve Onboarding
```