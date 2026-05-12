-- ============================================================
-- Snowflake Scheduled Tasks (CRON Jobs) for RepoMetrics ETL
-- ============================================================

USE DATABASE GITSTAR_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- TASK 1: Daily Data Quality Check (Runs every day at 6 AM IST)
-- Logs row counts into a monitoring table for tracking
-- ============================================================

CREATE TABLE IF NOT EXISTS DATA_QUALITY_LOG (
    CHECK_TIME TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    TABLE_NAME STRING,
    ROW_COUNT INTEGER
);

CREATE OR REPLACE TASK DAILY_DATA_QUALITY_CHECK
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 0 6 * * * Asia/Kolkata'
    COMMENT = 'Daily data quality check - logs row counts for all tables'
AS
    INSERT INTO DATA_QUALITY_LOG (CHECK_TIME, TABLE_NAME, ROW_COUNT)
    SELECT CURRENT_TIMESTAMP(), 'COMMITS', COUNT(*) FROM COMMITS
    UNION ALL SELECT CURRENT_TIMESTAMP(), 'PULL_REQUESTS', COUNT(*) FROM PULL_REQUESTS
    UNION ALL SELECT CURRENT_TIMESTAMP(), 'REPOSITORIES', COUNT(*) FROM REPOSITORIES
    UNION ALL SELECT CURRENT_TIMESTAMP(), 'USERS', COUNT(*) FROM USERS
    UNION ALL SELECT CURRENT_TIMESTAMP(), 'AUTHORS', COUNT(*) FROM AUTHORS;

-- ============================================================
-- TASK 2: Refresh Materialized Analytics (Runs every 6 hours)
-- Pre-computes heavy aggregations so Power BI queries are fast
-- ============================================================

CREATE TABLE IF NOT EXISTS REPO_ANALYTICS_CACHE (
    REPO_ID INTEGER,
    REPO_NAME STRING,
    LANGUAGE STRING,
    OWNER_LOGIN STRING,
    STARGAZERS_COUNT INTEGER,
    FORKS_COUNT INTEGER,
    TOTAL_COMMITS INTEGER,
    TOTAL_PRS INTEGER,
    OPEN_PRS INTEGER,
    MERGED_PRS INTEGER,
    AVG_DAYS_TO_MERGE FLOAT,
    LAST_REFRESHED TIMESTAMP_NTZ
);

CREATE OR REPLACE TASK REFRESH_REPO_ANALYTICS
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 0 */6 * * * Asia/Kolkata'
    COMMENT = 'Refreshes pre-computed repo analytics every 6 hours'
AS
    BEGIN
        TRUNCATE TABLE REPO_ANALYTICS_CACHE;
        INSERT INTO REPO_ANALYTICS_CACHE
        SELECT
            r.ID AS REPO_ID,
            r.NAME AS REPO_NAME,
            l.NAME AS LANGUAGE,
            u.LOGIN AS OWNER_LOGIN,
            r.STARGAZERS_COUNT,
            r.FORKS_COUNT,
            (SELECT COUNT(*) FROM COMMITS c WHERE c.REPOSITORY_ID = r.ID) AS TOTAL_COMMITS,
            (SELECT COUNT(*) FROM PULL_REQUESTS p WHERE p.REPOSITORY_ID = r.ID) AS TOTAL_PRS,
            (SELECT COUNT(*) FROM PULL_REQUESTS p WHERE p.REPOSITORY_ID = r.ID AND p.STATE = 'open') AS OPEN_PRS,
            (SELECT COUNT(*) FROM PULL_REQUESTS p WHERE p.REPOSITORY_ID = r.ID AND p.MERGED_AT IS NOT NULL) AS MERGED_PRS,
            (SELECT AVG(DATEDIFF('day', p.CREATED_AT, p.MERGED_AT)) FROM PULL_REQUESTS p WHERE p.REPOSITORY_ID = r.ID AND p.MERGED_AT IS NOT NULL) AS AVG_DAYS_TO_MERGE,
            CURRENT_TIMESTAMP() AS LAST_REFRESHED
        FROM REPOSITORIES r
        LEFT JOIN LANGUAGES l ON r.LANGUAGE_ID = l.ID
        LEFT JOIN USERS u ON r.OWNER_ID = u.ID;
    END;

-- ============================================================
-- TASK 3: Weekly Commit Trend Summary (Runs every Monday 7 AM)
-- ============================================================

CREATE TABLE IF NOT EXISTS WEEKLY_COMMIT_SUMMARY (
    WEEK_START DATE,
    TOTAL_COMMITS INTEGER,
    UNIQUE_AUTHORS INTEGER,
    MOST_ACTIVE_REPO STRING,
    GENERATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TASK WEEKLY_COMMIT_TREND
    WAREHOUSE = COMPUTE_WH
    SCHEDULE = 'USING CRON 0 7 * * 1 Asia/Kolkata'
    COMMENT = 'Weekly commit trend summary - runs every Monday at 7 AM IST'
AS
    INSERT INTO WEEKLY_COMMIT_SUMMARY (WEEK_START, TOTAL_COMMITS, UNIQUE_AUTHORS, MOST_ACTIVE_REPO)
    SELECT
        DATE_TRUNC('week', CURRENT_DATE()) AS WEEK_START,
        (SELECT COUNT(*) FROM COMMITS) AS TOTAL_COMMITS,
        (SELECT COUNT(DISTINCT AUTHOR_ID) FROM COMMITS) AS UNIQUE_AUTHORS,
        (SELECT r.NAME FROM COMMITS c JOIN REPOSITORIES r ON c.REPOSITORY_ID = r.ID GROUP BY r.NAME ORDER BY COUNT(*) DESC LIMIT 1) AS MOST_ACTIVE_REPO;


-- ============================================================
-- ACTIVATE ALL TASKS (Tasks are created in SUSPENDED state)
-- ============================================================

ALTER TASK DAILY_DATA_QUALITY_CHECK RESUME;
ALTER TASK REFRESH_REPO_ANALYTICS RESUME;
ALTER TASK WEEKLY_COMMIT_TREND RESUME;


-- ============================================================
-- USEFUL MONITORING QUERIES
-- ============================================================

-- Check all task statuses:
-- SHOW TASKS;

-- View task execution history:
-- SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY()) ORDER BY SCHEDULED_TIME DESC LIMIT 20;

-- Check data quality logs:
-- SELECT * FROM DATA_QUALITY_LOG ORDER BY CHECK_TIME DESC;

-- Check weekly summaries:
-- SELECT * FROM WEEKLY_COMMIT_SUMMARY ORDER BY WEEK_START DESC;

-- View cached analytics:
-- SELECT * FROM REPO_ANALYTICS_CACHE ORDER BY TOTAL_COMMITS DESC LIMIT 20;

-- ============================================================
-- TO PAUSE/STOP TASKS:
-- ALTER TASK DAILY_DATA_QUALITY_CHECK SUSPEND;
-- ALTER TASK REFRESH_REPO_ANALYTICS SUSPEND;
-- ALTER TASK WEEKLY_COMMIT_TREND SUSPEND;
-- ============================================================
