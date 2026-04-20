-- ─────────────────────────────────────────────────────────────────────────────
-- Enterprise Salary Management System — MySQL 8.0 Init
-- Runs once on first container start.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS hr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS hr_test       CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Read-replica simulation user (same host in dev, different DSN in prod)
CREATE USER IF NOT EXISTS 'salary_reader'@'%' IDENTIFIED BY 'reader_pass';
GRANT SELECT ON hr.* TO 'salary_reader'@'%';
GRANT SELECT ON hr_test.*        TO 'salary_reader'@'%';

FLUSH PRIVILEGES;
