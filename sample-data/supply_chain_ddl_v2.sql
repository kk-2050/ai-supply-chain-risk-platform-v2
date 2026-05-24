-- ============================================================
-- AI Supply Chain Risk Intelligence Platform
-- Database: SQL Server Express (T-SQL)
-- Created: 2026-05
-- Author : Kaori Kashiwagi
--
-- DISCLAIMER: All company names, supplier names, and organizations
-- in this dataset are entirely fictional and created for
-- portfolio demonstration purposes only.
-- Any resemblance to real companies is purely coincidental.
-- ============================================================

-- ============================================================
-- Business Risk Score Formula (Phase 1)
--
-- Overall Risk Score =
--   (Severity Score            x 0.40)
-- + (Operational Impact Score  x 0.35)
-- + (Urgency Score             x 0.25)
--
-- Design rationale:
--   Severity is weighted highest because the magnitude of a risk
--   event is the primary driver of business response priority.
--
--   Operational Impact reflects how significantly a supplier issue
--   affects production continuity. In manufacturing and supply chain
--   operations, business impact often becomes the key driver of
--   operational decision-making. Even a single supplier issue can
--   affect an entire production line.
--
--   Urgency is weighted lowest because time sensitivity alone does
--   not justify resource allocation. A high-urgency but low-severity
--   event should not displace a critical but slower-moving risk.
--
-- Phase 2 (future):
--   Overall Risk Score =
--     (Severity Score            x 0.35)
--   + (Operational Impact Score  x 0.30)
--   + (Urgency Score             x 0.20)
--   + (Likelihood Score          x 0.15)
--   Likelihood requires historical data and statistical patterns.
-- ============================================================

-- データベース作成（必要に応じて実行）
-- CREATE DATABASE SupplyChainRisk;
-- GO
-- USE SupplyChainRisk;
-- GO

-- ============================================================
-- 1. supplier_master
-- ============================================================
CREATE TABLE supplier_master (
    supplier_id     INT             IDENTITY(1,1)   PRIMARY KEY,
    supplier_name   NVARCHAR(200)   NOT NULL,
    country         NVARCHAR(100)   NOT NULL,
    region          NVARCHAR(100)   NULL,
    industry        NVARCHAR(100)   NULL,
    critical_level  NVARCHAR(10)    NOT NULL
                        CHECK (critical_level IN ('High', 'Medium', 'Low')),
    primary_parts   NVARCHAR(500)   NULL,
    active_flag     BIT             NOT NULL DEFAULT 1,
    created_at      DATETIME2       NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME2       NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- 2. risk_events
-- ============================================================
CREATE TABLE risk_events (
    event_id        INT             IDENTITY(1,1)   PRIMARY KEY,
    supplier_id     INT             NOT NULL,
    supplier_name   NVARCHAR(200)   NOT NULL,
    risk_title      NVARCHAR(500)   NOT NULL,
    risk_category   NVARCHAR(50)    NOT NULL
                        CHECK (risk_category IN (
                            'Logistics', 'Financial', 'Compliance',
                            'Quality', 'Geopolitical', 'Tariff', 'Other'
                        )),
    source_type     NVARCHAR(20)    NOT NULL
                        CHECK (source_type IN ('news', 'tariff', 'manual', 'rss')),
    source_url      NVARCHAR(1000)  NULL,
    event_date      DATE            NULL,
    created_at      DATETIME2       NOT NULL DEFAULT GETDATE(),
    processed_at    DATETIME2       NULL,
    status          NVARCHAR(20)    NOT NULL DEFAULT 'new'
                        CHECK (status IN ('new', 'reviewed', 'resolved')),

    CONSTRAINT FK_risk_events_supplier
        FOREIGN KEY (supplier_id) REFERENCES supplier_master(supplier_id)
);
GO

-- ============================================================
-- 3. risk_scores
-- ============================================================
CREATE TABLE risk_scores (
    score_id                 INT             IDENTITY(1,1)   PRIMARY KEY,
    event_id                 INT             NOT NULL,
    severity_score           TINYINT         NOT NULL
                                 CHECK (severity_score BETWEEN 1 AND 5),
    operational_impact_score TINYINT         NOT NULL
                                 CHECK (operational_impact_score BETWEEN 1 AND 5),
    urgency_score            TINYINT         NOT NULL
                                 CHECK (urgency_score BETWEEN 1 AND 5),
    overall_risk_score       AS (
                                 CAST(
                                     (severity_score            * 0.40)
                                   + (operational_impact_score  * 0.35)
                                   + (urgency_score             * 0.25)
                                 AS DECIMAL(4,2))
                             ) PERSISTED,
    confidence_score         TINYINT         NULL
                                 CHECK (confidence_score BETWEEN 0 AND 100),
    ai_summary               NVARCHAR(2000)  NULL,
    recommended_action       NVARCHAR(1000)  NULL,
    scored_at                DATETIME2       NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_risk_scores_event
        FOREIGN KEY (event_id) REFERENCES risk_events(event_id)
);
GO

-- ============================================================
-- 4. alert_logs
-- ============================================================
CREATE TABLE alert_logs (
    alert_id        INT             IDENTITY(1,1)   PRIMARY KEY,
    event_id        INT             NOT NULL,
    alert_level     NVARCHAR(10)    NOT NULL
                        CHECK (alert_level IN ('Low', 'Medium', 'High', 'Critical')),
    alert_sent_to   NVARCHAR(200)   NOT NULL,
    alert_channel   NVARCHAR(20)    NOT NULL
                        CHECK (alert_channel IN ('Email', 'Teams', 'Slack')),
    alert_sent_at   DATETIME2       NOT NULL DEFAULT GETDATE(),
    alert_status    NVARCHAR(10)    NOT NULL
                        CHECK (alert_status IN ('sent', 'failed', 'skipped')),

    CONSTRAINT FK_alert_logs_event
        FOREIGN KEY (event_id) REFERENCES risk_events(event_id)
);
GO

-- ============================================================
-- インデックス（クエリ高速化）
-- ============================================================
CREATE INDEX IX_risk_events_supplier_id  ON risk_events (supplier_id);
CREATE INDEX IX_risk_events_status       ON risk_events (status);
CREATE INDEX IX_risk_events_created_at   ON risk_events (created_at DESC);
CREATE INDEX IX_risk_scores_event_id     ON risk_scores (event_id);
CREATE INDEX IX_alert_logs_event_id      ON alert_logs  (event_id);
GO

-- ============================================================
-- サンプルデータ
-- DISCLAIMER: All company names are entirely fictional.
-- Any resemblance to real companies is purely coincidental.
-- ============================================================
INSERT INTO supplier_master (supplier_name, country, region, industry, critical_level, primary_parts)
VALUES
    (N'Apex Components Ltd',  N'Japan',  N'Asia Pacific', N'Industrial Components', 'High',   N'Capacitors, Inductors'),
    (N'Nova Auto Parts Co',   N'Japan',  N'Asia Pacific', N'Automotive',            'High',   N'Engine components'),
    (N'BioSource Materials',  N'USA',    N'North America',N'Pharma / Chemical',     'Medium', N'API ingredients'),
    (N'ChipTech Global',      N'Taiwan', N'Asia Pacific', N'Semiconductor',         'High',   N'Logic chips, GPUs'),
    (N'FastRoute Logistics',  N'China',  N'Asia Pacific', N'Logistics',             'Medium', N'Freight services');
GO

INSERT INTO risk_events (supplier_id, supplier_name, risk_title, risk_category, source_type, source_url, event_date, status)
VALUES
    (1, N'Apex Components Ltd', N'Factory shutdown risk due to earthquake warning',          'Geopolitical', 'news',   N'https://example.com/news/001',  '2026-05-10', 'new'),
    (4, N'ChipTech Global',     N'New import tariff on semiconductor components announced',   'Tariff',       'tariff', N'https://example.com/tariff/002', '2026-05-11', 'new'),
    (5, N'FastRoute Logistics', N'Port congestion causing 2-week delivery delays',            'Logistics',    'rss',    N'https://example.com/rss/003',   '2026-05-12', 'new');
GO

INSERT INTO risk_scores (event_id, severity_score, operational_impact_score, urgency_score, confidence_score, ai_summary, recommended_action)
VALUES
    (1, 5, 5, 4, 88, N'Major earthquake warning near primary production facility. Halt likely within 48 hours.',     N'Activate backup supplier immediately. Increase safety stock.'),
    (2, 3, 4, 3, 92, N'25% tariff increase on semiconductor imports effective next quarter. Significant cost impact.', N'Review contract terms. Evaluate alternative sourcing options.'),
    (3, 2, 3, 4, 85, N'Port congestion causing widespread delays. Estimated arrival extended by 14 days.',            N'Expedite air freight for critical parts. Notify production planning.');
GO

INSERT INTO alert_logs (event_id, alert_level, alert_sent_to, alert_channel, alert_status)
VALUES
    (1, 'Critical', N'supply.chain@company.com', 'Email', 'sent'),
    (1, 'Critical', N'Operations Team',          'Teams', 'sent'),
    (2, 'High',     N'procurement@company.com',  'Email', 'sent'),
    (3, 'Medium',   N'logistics@company.com',    'Email', 'sent');
GO

-- ============================================================
-- 動作確認クエリ
-- ============================================================

-- Business Risk Score 一覧（overall_risk_score 降順）
SELECT
    re.event_id,
    re.supplier_name,
    re.risk_title,
    re.risk_category,
    re.status,
    rs.severity_score,
    rs.operational_impact_score,
    rs.urgency_score,
    rs.overall_risk_score,
    rs.confidence_score,
    rs.ai_summary,
    rs.recommended_action
FROM risk_events re
JOIN risk_scores rs ON re.event_id = rs.event_id
ORDER BY rs.overall_risk_score DESC;
GO

-- アラート送信履歴
SELECT
    al.alert_id,
    re.supplier_name,
    re.risk_title,
    al.alert_level,
    al.alert_channel,
    al.alert_sent_to,
    al.alert_status,
    al.alert_sent_at
FROM alert_logs al
JOIN risk_events re ON al.event_id = re.event_id
ORDER BY al.alert_sent_at DESC;
GO
