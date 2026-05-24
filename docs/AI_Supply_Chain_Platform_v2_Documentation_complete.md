# AI Supply Chain Risk Intelligence Platform v2
## Complete Documentation Package

*Portfolio Project | All supplier data is fictional | For demonstration purposes only*

---

# 0. Platform Overview — Operational & Business Context

## What This Platform Is

The platform was designed not only as a technical automation workflow, but as an **operational decision-support system** intended to:

- Reduce manual monitoring effort for supply chain risk
- Improve escalation visibility across operations and procurement teams
- Support business prioritization during supply chain disruptions
- Provide evidence-based alerting with source article traceability

This is not a pure developer project. It is an **enterprise operational automation project** that combines AI analysis, workflow orchestration, business governance, and operational process design.

---

## Why AI Was Used

Traditional keyword-based alerting cannot easily:

- Estimate operational severity in business context
- Prioritize urgency across multiple concurrent risk events
- Summarize executive-level impact in plain language
- Generate mitigation recommendations at scale

AI (GPT-4o-mini) was used to provide:

- Contextual risk interpretation beyond keyword matching
- Business-oriented summarization for executive consumption
- Operational prioritization via weighted scoring
- Scalable analysis automation across continuous news feeds

---

## Why Not Fully Autonomous

The platform intentionally uses **AI-assisted recommendations** rather than fully autonomous decision-making.

Human operational review remains important for high-impact supply chain decisions. The system routes intelligence to humans — it does not replace human judgment.

This design reflects enterprise governance maturity:
- AI provides speed and scale
- Humans provide context and accountability
- The system creates the bridge between them

---

## Why n8n Was Selected

n8n was intentionally selected for this platform because it provides:

- Low-code workflow orchestration with full visibility
- Rapid prototyping without infrastructure overhead
- Flexible API integration (OpenAI, Google Sheets, Gmail)
- Operational transparency — every node is inspectable
- Scalable automation architecture that mirrors enterprise patterns

Production alternatives may include Azure Logic Apps, Power Automate, or enterprise orchestration platforms. The concepts demonstrated here are directly transferable.

---

## Future AI Capability Roadmap

| Future Capability | Purpose |
|-------------------|---------|
| Trend Detection | Identify repeated supplier risk patterns over time |
| Predictive Forecasting | Early disruption prediction based on historical signals |
| Supplier Risk Memory | Long-term risk pattern analysis per supplier |
| AI Copilot | Procurement analyst decision assistance |
| Anomaly Detection | Flag unusual risk score spikes automatically |
| Multi-source Intelligence | Combine RSS, API, and manual inputs |

---

## Intended Users

| User | Purpose |
|------|---------|
| Procurement Teams | Supplier disruption awareness and sourcing response |
| Operations Managers | Production impact visibility and continuity planning |
| Executive Leadership | Risk trend visibility and strategic decision support |
| Supply Chain Analysts | Operational monitoring and event investigation |
| Risk Management Teams | Escalation support and audit trail access |

---

# 1. Data Dictionary — risk_events Field Reference

## Overview

`risk_events` is the central data store for all supply chain risk events detected, analyzed, and tracked by the platform. Every row represents one risk event identified from an RSS news source, processed by AI, scored, and stored for alerting and analytics.

## Field Definitions

### Core Event Fields (Columns A–E)

| Column | Field | Type | Business Purpose |
|--------|-------|------|-----------------|
| A | `event_date` | Date | Publication date of the source article. Used for age filtering: Critical = 24h, Summary = 48h. Prevents stale news from triggering alerts. |
| B | `supplier_id` | Integer | Unique identifier linking to the supplier master. Enables supplier-level filtering in Power BI and SQL queries. |
| C | `supplier_name` | Text | Matched fictional supplier name. One of five predefined companies. Enables supplier-level risk aggregation. |
| D | `risk_title` | Text | RSS news headline. Preserved verbatim for traceability and audit. |
| E | `risk_category` | Text | Standardized category assigned post-AI analysis. Enables Power BI category aggregation and trend analysis. |

### AI Risk Scoring Fields (Columns F–J)

| Column | Field | Type | Range | Weight | Business Purpose |
|--------|-------|------|-------|--------|-----------------|
| F | `severity_score` | Decimal | 1–5 | 40% | How severe the impact would be if the risk materializes. Highest weight because impact severity drives business decisions. |
| G | `operational_impact_score` | Decimal | 1–5 | 35% | How much this disrupts production, logistics, and procurement. Second highest weight — operational continuity is critical. |
| H | `urgency_score` | Decimal | 1–5 | 25% | How quickly a response is required. Lower weight — urgency alone doesn't justify alert fatigue. |
| I | `overall_risk_score` | Decimal | 1–5 | — | Composite Business Risk Score. Drives all alert routing decisions. |
| J | `confidence_score` | Integer | 0–100 | — | AI's self-assessed confidence. Helps analysts prioritize manual review. Low confidence = human review recommended. |

### AI Analysis Fields (Columns K–L)

| Column | Field | Type | Business Purpose |
|--------|-------|------|-----------------|
| K | `ai_summary` | Text | Executive-ready 1–2 sentence risk summary. Used directly in Critical Alert and Daily Summary emails. |
| L | `recommended_action` | Text | AI-generated mitigation recommendation. Sourced from the actual risk data — never invented. Used in all email notifications. |

### Source Tracking Fields (Columns M–N)

| Column | Field | Type | Business Purpose |
|--------|-------|------|-----------------|
| M | `source_type` | Text | Data origin: currently `rss`. Future: `api`, `manual`. Supports multi-source expansion. |
| N | `source_url` | Text | Direct link to source article. Serves as evidence in emails, deduplication key, and Power BI drill-through source. |

### Operational Status Fields (Columns O–W)

| Column | Field | Type | Business Purpose |
|--------|-------|------|-----------------|
| O | `processed_at` | DateTime CST | Processing timestamp. Used for audit trails, Power BI time-series analysis, and SLA tracking. |
| P | `alert_level` | Text | Alert routing tier: `critical`, `summary`, or `low`. Determines which workflow handles the event. |
| Q | `summary_status` | Text | Daily Summary tracking: `pending` or `sent`. Prevents events from being summarized multiple times. |
| R | `summary_sent_at` | DateTime | When the Daily Summary email was sent. Empty until sent. Supports audit and compliance tracking. |
| S | `critical_alert_status` | Text | Critical Alert tracking: `pending`, `sent`, or `not_required`. Prevents duplicate critical emails. |
| T | `critical_alert_sent_at` | DateTime | When the Critical Alert email was sent. Supports SLA measurement and audit. |
| U | `processing_status` | Text | Workflow result: `success` or `error`. Enables operational monitoring and debugging. |
| V | `error_message` | Text | Error detail when `processing_status = error`. Supports troubleshooting without opening n8n. |
| W | `dedupe_key` | Text | `source_url` value used for deduplication. Prevents the same article from being re-processed across workflow runs. |

---

# 2. Risk Scoring Methodology

## Business Risk Score Formula

```
Overall Risk Score = (Severity × 0.40) + (Operational Impact × 0.35) + (Urgency × 0.25)
```

## Why These Weights?

| Dimension | Weight | Rationale |
|-----------|--------|-----------|
| Severity | 40% | The potential magnitude of harm drives the most critical business decisions. A low-severity event rarely justifies escalation regardless of urgency. |
| Operational Impact | 35% | Direct disruption to production, logistics, and procurement is the most measurable and actionable risk dimension for supply chain operations. |
| Urgency | 25% | Time sensitivity matters but should not override severity. Urgent low-severity events create alert fatigue without business value. |

## Score Interpretation

| Score Range | Alert Level | Action |
|-------------|-------------|--------|
| >= 4.5 | **CRITICAL** | Immediate email alert sent per event. Requires same-day operational response. |
| 3.5 – 4.49 | **SUMMARY** | Included in next Daily Summary email (5AM or 2PM CST). Requires monitoring and planning response. |
| < 3.5 | **LOW** | Logged only. No email notification. Available in Power BI for trend analysis. |

## Scoring Examples

| Scenario | Severity | Op. Impact | Urgency | Score | Level |
|----------|----------|------------|---------|-------|-------|
| Port closure — key supplier | 5 | 5 | 4 | 4.75 | CRITICAL |
| Tariff increase announced | 4 | 4 | 4 | 4.00 | SUMMARY |
| Minor logistics delay | 3 | 3 | 3 | 3.00 | LOW |
| Helium shortage warning | 4 | 5 | 4 | 4.35 | SUMMARY |

## Confidence Score

The `confidence_score` (0–100) reflects the AI model's self-assessed certainty in its analysis.

| Range | Interpretation | Recommended Action |
|-------|---------------|-------------------|
| 80–100 | High confidence | Proceed with standard routing |
| 60–79 | Moderate confidence | Monitor; consider secondary review |
| < 60 | Low confidence | Manual review recommended before action |

---

# 3. Master Data Design

## Supplier Master (Currently Hardcoded — Future: Google Sheets Tab)

| supplier_id | supplier_name | Industry | Keywords | Tier | Region | Criticality |
|------------|--------------|----------|---------|------|--------|-------------|
| 1 | Apex Components Ltd | Electronic Components | apex components, capacitor, inductor | 1 | Japan | High |
| 2 | Nova Auto Parts Co | Automotive | nova auto, automotive, auto parts, vehicle | 2 | Mexico | Medium |
| 3 | BioSource Materials | Pharmaceutical/Chemical | biosource, pharmaceutical, api ingredient, chemical | 1 | India | High |
| 4 | ChipTech Global | Semiconductor | chiptech, semiconductor, gpu, chip, microchip | 1 | Taiwan | Critical |
| 5 | FastRoute Logistics | Logistics/Freight | fastroute, logistics, freight, port, shipping | 2 | USA | Medium |

> **Disclaimer:** All supplier names are fictional and created for portfolio demonstration purposes only.

## Risk Category Master

| Category | Description | Example Events |
|----------|-------------|---------------|
| Geopolitical | Political conflicts, sanctions, war, trade tensions | Iran conflict, US-China trade war |
| Logistics | Shipping delays, port congestion, freight disruption | Port strike, Suez Canal blockage |
| Supply Shortage | Material shortages, inventory gaps, resource scarcity | Helium shortage, rare earth crisis |
| Financial | Cost increases, currency risk, price volatility | Fuel price hike, currency devaluation |
| Tariff | Trade tariffs, import/export duties | New semiconductor tariffs |
| Cybersecurity | Cyberattacks, data breaches, system vulnerabilities | Supplier system hack |
| Natural Disaster | Earthquakes, floods, typhoons, climate events | Taiwan earthquake |
| Operational Disruption | Factory shutdowns, labor disputes, production halts | Strike, facility fire |
| Other | Events not matching standard categories | — |

## Alert Status Master Values

| Field | Value | Meaning |
|-------|-------|---------|
| `alert_level` | `critical` | Score >= 4.5. Immediate email. |
| `alert_level` | `summary` | Score 3.5–4.49. Next daily summary. |
| `alert_level` | `low` | Score < 3.5. Log only. |
| `summary_status` | `pending` | Not yet included in Daily Summary. |
| `summary_status` | `sent` | Included in Daily Summary email. |
| `critical_alert_status` | `pending` | Critical alert not yet sent. |
| `critical_alert_status` | `sent` | Critical alert email sent. |
| `critical_alert_status` | `not_required` | Score below 4.5. |
| `processing_status` | `success` | Processed normally. |
| `processing_status` | `error` | Processing failed. See `error_message`. |

---

# 4. README — Platform Description

## AI Supply Chain Risk Intelligence Platform v2

An end-to-end AI-powered supply chain risk monitoring and alerting platform built with n8n, OpenAI GPT-4o-mini, and Google Sheets. Automatically detects, analyzes, scores, and routes supply chain risk events from live RSS news feeds.

### What It Does

- Fetches live supply chain news every 6 hours from Google News RSS
- Matches news articles to fictional supplier profiles using keyword matching
- Filters out articles older than 24 hours (age filter)
- Deduplicates articles using URL-based deduplication to prevent reprocessing
- Analyzes each event with AI (GPT-4o-mini) to extract risk category, severity, operational impact, urgency, and recommended action
- Calculates a composite Business Risk Score using a weighted formula
- Routes events by score: Critical Alert (immediate) or Daily Summary (twice daily)
- Sends professional HTML emails with source article evidence links
- Tracks alert status back to Google Sheets for audit and Power BI analytics

### Architecture

```
RSS Feed (Google News)
    ↓
Age Filter (24 hours)
    ↓
URL Deduplication (source_url check)
    ↓
AI Risk Analysis (GPT-4o-mini)
    ↓
Category Standardization
    ↓
Google Sheets Storage (all events)
    ↓
Score >= 4.5  →  Critical Alert Email (immediate, per event)
Score 3.5–4.49 → Daily Summary Email (5AM / 2PM CST)
Score < 3.5   →  Log Only
```

### Tech Stack

| Component | Technology |
|-----------|-----------|
| Workflow Automation | n8n Cloud |
| AI Analysis | OpenAI GPT-4o-mini |
| Data Storage | Google Sheets |
| Email Notifications | Gmail (via n8n) |
| Dashboard | GitHub Pages (HTML/CSS/JS) |
| Analytics (planned) | Power BI |
| SQL Logging (planned) | SQL Server Express |

### Scheduling

| Workflow | Schedule | Purpose |
|----------|----------|---------|
| Critical Alert Workflow | Every 6 hours | Detect and alert on high-risk events |
| Operational Summary Workflow | 5:00 AM and 2:00 PM CST | Daily digest covering all US time zones |

> **Note:** Current demo configuration: every 6 hours. Production recommended: every 30 minutes.

### Demo vs Production

| Aspect | Demo (Current) | Production (Recommended) |
|--------|---------------|--------------------------|
| Scheduler | Every 6 hours | Every 30 minutes |
| Storage | Google Sheets | SQL Server / Azure SQL |
| Suppliers | Fictional (hardcoded) | ERP-integrated supplier master |
| Notifications | Gmail | Teams / Slack / Enterprise email |
| Analytics | GitHub Pages dashboard | Live Power BI dashboards |
| Governance | None | Approval workflows, audit logging |

### AI Governance and Limitations

This platform is designed as an AI-assisted operational decision support system.

- AI analysis may occasionally produce imprecise category assignments
- RSS source data may contain duplicates or incomplete information
- Confidence scores indicate AI certainty but do not guarantee correctness
- Human review is recommended for high-impact operational decisions
- Production systems should include approval workflows and audit controls

### Why Google Sheets?

Google Sheets was intentionally selected for the portfolio version because it provides fast implementation, lightweight cloud persistence, easy debugging, transparent operational visibility, and zero infrastructure setup. Future production architecture would migrate to SQL Server, PostgreSQL, or Azure SQL.

### Future Roadmap

- SQL Server integration (in progress)
- Power BI real-time dashboards
- Supplier master management UI
- Teams / Slack notifications
- Predictive risk forecasting
- Human approval workflows
- Role-based alert routing
- Cloud deployment

---

# 5. Gamma Presentation Guide

## Slide Structure Recommendation

### Slide 1 — Problem Statement
**Title:** Supply chain risk moves faster than email threads.

*Key message:* By the time a procurement team hears about a geopolitical event, it's already disrupting their suppliers.

### Slide 2 — Solution Overview
**Title:** From news to action in minutes, not days.

*Visual:* Simple flow diagram
```
News → AI Analysis → Risk Score → Alert → Action
```

### Slide 3 — Live Demo Screenshot
**Title:** Automated detection. Zero manual monitoring.

*Content:* n8n workflow screenshot showing all green nodes

### Slide 4 — Risk Scoring
**Title:** Not all risks are equal.

*Content:* Score formula table with examples
- Score >= 4.5 → Immediate alert
- Score 3.5–4.49 → Daily summary
- Score < 3.5 → Log only

### Slide 5 — Alert Email Sample
**Title:** Executive-ready intelligence. Evidence included.

*Content:* Critical Alert email screenshot with Source Article link highlighted

### Slide 6 — Daily Summary Sample
**Title:** One email. Full operational picture.

*Content:* Daily Summary email screenshot showing AI Executive Summary + Source Events table

### Slide 7 — Architecture
**Title:** Enterprise design. Lightweight deployment.

*Content:* Tech stack diagram

### Slide 8 — Design Philosophy (CLOSING SLIDE)

> *"The system separates event persistence, dashboard visibility, and human notification.*
> *All events are logged. Dashboards remain available for self-service monitoring.*
> *Only critical or summarized risks are pushed to users."*
>
> **Designed for enterprise-grade reliability — not just automation.**

---

# 6. SQL Table Design

## risk_events Table

```sql
CREATE TABLE risk_events (
    id                      INT IDENTITY(1,1) PRIMARY KEY,
    event_date              DATE NOT NULL,
    supplier_id             INT NOT NULL,
    supplier_name           NVARCHAR(100) NOT NULL,
    risk_title              NVARCHAR(500) NOT NULL,
    risk_category           NVARCHAR(100) NOT NULL,
    severity_score          DECIMAL(3,2) NOT NULL CHECK (severity_score BETWEEN 1 AND 5),
    operational_impact_score DECIMAL(3,2) NOT NULL CHECK (operational_impact_score BETWEEN 1 AND 5),
    urgency_score           DECIMAL(3,2) NOT NULL CHECK (urgency_score BETWEEN 1 AND 5),
    overall_risk_score      DECIMAL(3,2) NOT NULL CHECK (overall_risk_score BETWEEN 1 AND 5),
    confidence_score        INT CHECK (confidence_score BETWEEN 0 AND 100),
    ai_summary              NVARCHAR(MAX),
    recommended_action      NVARCHAR(MAX),
    source_type             NVARCHAR(50) DEFAULT 'rss',
    source_url              NVARCHAR(2000),
    processed_at            DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    alert_level             NVARCHAR(20) NOT NULL CHECK (alert_level IN ('critical', 'summary', 'low')),
    summary_status          NVARCHAR(20) DEFAULT 'pending' CHECK (summary_status IN ('pending', 'sent')),
    summary_sent_at         DATETIME2 NULL,
    critical_alert_status   NVARCHAR(20) DEFAULT 'not_required' CHECK (critical_alert_status IN ('pending', 'sent', 'not_required')),
    critical_alert_sent_at  DATETIME2 NULL,
    processing_status       NVARCHAR(20) DEFAULT 'success' CHECK (processing_status IN ('success', 'error')),
    error_message           NVARCHAR(MAX) NULL,
    dedupe_key              NVARCHAR(2000) UNIQUE
);
```

## Recommended Indexes

```sql
-- For alert routing queries
CREATE INDEX idx_alert_level ON risk_events (alert_level);
CREATE INDEX idx_summary_status ON risk_events (summary_status, alert_level);
CREATE INDEX idx_critical_status ON risk_events (critical_alert_status);

-- For deduplication lookup
CREATE UNIQUE INDEX idx_dedupe_key ON risk_events (dedupe_key);

-- For time-based queries and Power BI
CREATE INDEX idx_processed_at ON risk_events (processed_at DESC);
CREATE INDEX idx_event_date ON risk_events (event_date DESC);

-- For supplier analysis
CREATE INDEX idx_supplier ON risk_events (supplier_id, overall_risk_score DESC);
```

## Useful Queries

```sql
-- Pending critical alerts (not yet sent)
SELECT * FROM risk_events
WHERE critical_alert_status = 'pending'
  AND alert_level = 'critical'
ORDER BY overall_risk_score DESC;

-- Daily Summary candidates
SELECT * FROM risk_events
WHERE summary_status = 'pending'
  AND alert_level = 'summary'
  AND event_date >= DATEADD(HOUR, -48, GETUTCDATE())
ORDER BY overall_risk_score DESC;

-- Supplier risk summary
SELECT
    supplier_name,
    COUNT(*) AS total_events,
    AVG(overall_risk_score) AS avg_score,
    MAX(overall_risk_score) AS max_score,
    SUM(CASE WHEN alert_level = 'critical' THEN 1 ELSE 0 END) AS critical_count
FROM risk_events
GROUP BY supplier_name
ORDER BY avg_score DESC;

-- Risk category distribution (last 30 days)
SELECT
    risk_category,
    COUNT(*) AS event_count,
    AVG(overall_risk_score) AS avg_score
FROM risk_events
WHERE processed_at >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY risk_category
ORDER BY event_count DESC;
```

---

# 7. Power BI Implementation Guide

## Operational KPIs

| KPI | Purpose | Data Source |
|-----|---------|-------------|
| Critical Alerts Sent | High-risk escalation volume | `critical_alert_status = 'sent'` count |
| Average Risk Score | Overall operational severity | `AVG(overall_risk_score)` |
| Supplier Risk Frequency | Supplier concentration risk | `COUNT` grouped by `supplier_name` |
| Duplicate Prevention Rate | Alert governance quality | Deduplicated events / total RSS fetched |
| Pending Summary Events | Unprocessed summary backlog | `summary_status = 'pending'` count |
| Category Trend (30 days) | Risk pattern visibility | `risk_category` distribution over time |

## Recommended Data Connection

Connect Power BI to Google Sheets via Web connector (current), or SQL Server (future production).

**Google Sheets URL format:**
```
https://docs.google.com/spreadsheets/d/[SHEET_ID]/export?format=csv&gid=0
```

## Recommended Report Pages

### Page 1 — Executive Dashboard
**KPIs (Card visuals):**
- Total Events (last 30 days)
- Critical Alerts Sent
- Average Risk Score
- Pending Summary Events

**Visuals:**
- Risk Score Over Time (Line chart: processed_at vs overall_risk_score)
- Alert Level Distribution (Donut chart: alert_level count)
- Top 5 Highest Risk Events (Table: supplier_name, risk_title, overall_risk_score)

### Page 2 — Supplier Risk Analysis
**Visuals:**
- Supplier Risk Heatmap (Matrix: supplier_name × risk_category, values = count)
- Average Risk Score by Supplier (Bar chart)
- Supplier Risk Trend (Line chart: supplier_name, processed_at, overall_risk_score)

### Page 3 — Category Trends
**Visuals:**
- Risk Category Distribution (Bar chart: risk_category, count)
- Category Risk Over Time (Line chart: risk_category, processed_at, avg score)
- Monthly Risk Distribution (Clustered bar: month, risk_category, count)

### Page 4 — Source Intelligence
**Visuals:**
- Source Events Table (Table: event_date, supplier_name, risk_title, overall_risk_score, source_url)
- Source URL as clickable link (enables drill-through to original article)

## Key DAX Measures

```dax
-- Total Events
Total Events = COUNTROWS(risk_events)

-- Critical Alert Rate
Critical Rate =
DIVIDE(
    COUNTROWS(FILTER(risk_events, risk_events[alert_level] = "critical")),
    COUNTROWS(risk_events),
    0
)

-- Average Risk Score
Avg Risk Score = AVERAGE(risk_events[overall_risk_score])

-- Events Last 7 Days
Events Last 7 Days =
CALCULATE(
    COUNTROWS(risk_events),
    risk_events[processed_at] >= TODAY() - 7
)

-- High Risk Suppliers (score >= 4.0)
High Risk Supplier Count =
CALCULATE(
    DISTINCTCOUNT(risk_events[supplier_name]),
    risk_events[overall_risk_score] >= 4.0
)
```

## Data Refresh Recommendation
- Demo: Manual refresh or scheduled daily
- Production: Every 30–60 minutes via Power BI Gateway

---

# 8. GitHub Documentation Structure

## Recommended Repository Structure

```
ai-supply-chain-risk-platform/
│
├── README.md                          ← Main project overview
├── CHANGELOG.md                       ← Version history
├── LICENSE                            ← License file
│
├── workflow-json/
│   ├── Critical_Alert_Workflow.json   ← n8n workflow export
│   └── Operational_Summary_Workflow.json
│
├── docs/
│   ├── data-dictionary.md             ← This document
│   ├── risk-scoring-methodology.md    ← Scoring formula explanation
│   ├── architecture.md                ← System design overview
│   └── demo-vs-production.md          ← Configuration comparison
│
├── sql/
│   ├── create_tables.sql              ← Table DDL
│   ├── indexes.sql                    ← Index definitions
│   └── sample_queries.sql             ← Useful analytical queries
│
├── dashboard/
│   ├── index.html                     ← GitHub Pages dashboard
│   ├── styles.css
│   └── data/
│       └── sample_events.json
│
├── screenshots/
│   ├── critical-alert-workflow.png
│   ├── operational-summary-workflow.png
│   ├── critical-alert-email.png
│   ├── daily-summary-email.png
│   └── google-sheets-data.png
│
├── sample-data/
│   └── risk_events_sample.csv         ← Sample data for demo
│
└── architecture/
    └── system-architecture-diagram.png
```

## CHANGELOG.md Template

```markdown
# Changelog

## v2.0 — 2026-05-24 — Production Ready

### Added
- Critical Alert threshold set to score >= 4.5
- URL-based Deduplication (source_url)
- 24-hour Age Filter for Critical Workflow
- 48-hour Age Filter for Summary Workflow
- Category Standardization (9 standard categories)
- Source Article link in Critical Alert email
- Daily Summary Workflow (5AM / 2PM CST)
- AI Executive Summary in Daily Summary email
- HTML Source Events table in Daily Summary email
- Update Critical Alert Status node (tracks sent status)
- Update Summary Status node (tracks sent status)
- processed_at, alert_level, dedupe_key fields added

### Changed
- Critical Alert email now includes Source Article URL as evidence
- Both workflows published to production

## v1.0 — 2026-05-14 — Initial Release

### Added
- RSS news ingestion from Google News
- Supplier keyword matching (5 fictional suppliers)
- AI risk analysis with GPT-4o-mini
- Business Risk Score calculation
- Google Sheets storage
- Critical Alert email notifications
- GitHub Pages dashboard
```

## README Badge Suggestions

```markdown
![n8n](https://img.shields.io/badge/n8n-Cloud-orange)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o--mini-green)
![Google Sheets](https://img.shields.io/badge/Storage-Google%20Sheets-blue)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
```

---

# Design Philosophy

> *"The system separates event persistence, dashboard visibility, and human notification.*
> *All events are logged. Dashboards remain available for self-service monitoring.*
> *Only critical or summarized risks are pushed to users."*
>
> **Designed for enterprise-grade reliability — not just automation.**

---

# Portfolio Positioning

This project demonstrates practical enterprise workflow automation concepts, AI-assisted operational intelligence, business process orchestration, and scalable operational monitoring design.

It is intended to showcase:

| Capability | Demonstration |
|-----------|---------------|
| AI Workflow Automation | n8n + OpenAI end-to-end pipeline |
| Business Operations Thinking | Risk scoring, alert routing, escalation design |
| Enterprise Architecture | Separation of concerns, audit trails, status tracking |
| AI Governance | Human-in-the-loop design, confidence scoring, non-autonomous decisions |
| Data Engineering | Deduplication, age filtering, schema design, SQL readiness |
| Operational Analytics | Power BI KPIs, category standardization, trend visibility |
| Documentation Maturity | Data dictionary, methodology, README, changelog |

This project reflects the intersection of **AI, automation, and enterprise operational process** — directly aligned with roles in AI Automation Architecture, Systems Analysis, Business Process Automation, and Enterprise AI Operations.

---

# Career Materials

## One-Line Resume Version

Designed and implemented an AI-assisted supply chain risk intelligence platform using n8n, OpenAI GPT-4o-mini, Google Sheets, and automated workflow orchestration to monitor operational disruptions, route executive alerts, and support business risk visibility.

---

## LinkedIn Portfolio Description

**AI Supply Chain Risk Intelligence Platform v2**

An end-to-end AI-powered operational monitoring platform that automatically detects, analyzes, and routes supply chain risk events from live news feeds.

Built with n8n Cloud, OpenAI GPT-4o-mini, and Google Sheets. The platform processes RSS news, matches events to supplier profiles, scores business risk using a weighted formula, and routes intelligence through two automated alert workflows — Critical Alerts (immediate) and Daily Executive Summaries (twice daily, covering all US time zones).

Key design decisions include URL-based deduplication, age filtering, category standardization, source article evidence in emails, and AI-assisted recommendations with human-in-the-loop governance.

Demonstrates: AI workflow automation · operational process design · enterprise alert architecture · business risk scoring · supply chain intelligence

`#n8n` `#OpenAI` `#SupplyChain` `#AIAutomation` `#WorkflowOrchestration` `#EnterpriseAI`

---

## Interview Talking Points

### Q: Why did you use AI for this?

Traditional keyword-based alerting can detect that a word like "shortage" appears in a headline. But it cannot estimate how severe the operational impact would be, how urgently a response is needed, or what a procurement manager should actually do about it. I used AI to provide contextual interpretation, executive-ready summarization, and scalable prioritization — things that rule-based systems cannot do well at volume.

---

### Q: Why did you separate the workflows?

The Critical Alert Workflow and the Daily Summary Workflow serve completely different operational purposes. Critical alerts require immediate individual response. Daily summaries support morning planning and broader visibility. Combining them would create either alert fatigue or missed escalations. The separation also mirrors how enterprise monitoring systems are actually designed — operational alerts versus management reporting are never the same pipeline.

---

### Q: Why a weighted scoring formula instead of just using the AI score directly?

I wanted the scoring logic to be transparent, explainable, and auditable. If a procurement manager asks "why did this event trigger a critical alert," I can show them exactly: severity was 5, operational impact was 5, urgency was 4, and the formula produced 4.75. A black-box AI score cannot be explained that way. The weights — 40% severity, 35% operational impact, 25% urgency — reflect the business priority that potential harm matters more than response speed alone.

---

### Q: Why did you design it to not be fully autonomous?

Supply chain decisions — changing a supplier, adjusting inventory, escalating to leadership — have real business and financial consequences. AI can provide speed, scale, and summarization, but it cannot provide accountability or contextual business judgment. The platform is designed to route intelligence to humans, not to replace human decisions. This is intentional governance design, not a limitation.

---

### Q: Why Google Sheets instead of a database?

Google Sheets was the right choice for a portfolio proof-of-concept because it provides zero infrastructure setup, immediate visibility into every record, easy debugging during development, and cloud persistence without a server. The schema was designed from the beginning to be SQL-ready — the field names, data types, constraints, and indexes are all defined and ready to migrate. Google Sheets is the current storage layer, not the final one.

---

### Q: How would you productionize this?

Four changes for production. First, migrate storage from Google Sheets to SQL Server or Azure SQL using the schema already designed. Second, change the scheduler from every 6 hours to every 30 minutes for near-real-time detection. Third, replace Gmail with enterprise notifications — Microsoft Teams, Slack, or an SMTP relay — and add role-based routing so the right alert goes to the right person. Fourth, add approval workflows for high-impact responses and structured audit logging for compliance. The architecture and separation of concerns are already production-ready. It is primarily an infrastructure and governance upgrade.

---

# Design Philosophy

> *"The system separates event persistence, dashboard visibility, and human notification.*
> *All events are logged. Dashboards remain available for self-service monitoring.*
> *Only critical or summarized risks are pushed to users."*
>
> **Designed for enterprise-grade reliability — not just automation.**

---

*AI Supply Chain Risk Intelligence Platform v2 | Portfolio Project*
*Built with n8n Cloud, OpenAI GPT-4o-mini, Google Sheets*
*All supplier data is fictional. Created for portfolio demonstration purposes only.*
