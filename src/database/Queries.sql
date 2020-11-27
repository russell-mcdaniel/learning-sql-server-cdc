USE MedicationTracker;
GO

-- ================================================================================
-- INSERT DATA
-- ================================================================================

-- Create company and facilities in separate transactions.
INSERT INTO
    dbo.Company (CompanyKey, CompanyName, CreatedAt)
VALUES
    ('6B8B67BF-E633-4005-9925-FCF983526A46', N'Becton, Dickinson and Company', SYSDATETIME());
GO

INSERT INTO
    dbo.UserAccount (CompanyKey, UserAccountKey, Email, DisplayName, CreatedAt)
VALUES
    ('6B8B67BF-E633-4005-9925-FCF983526A46', '57091C59-65BD-41C9-8DB1-0077CFCA24DE', N'maxwell.becton@bd.com', N'Maxwell Becton', SYSDATETIME());
GO

INSERT INTO
    dbo.Facility (CompanyKey, FacilityKey, FacilityName, CreatedAt)
VALUES
    ('6B8B67BF-E633-4005-9925-FCF983526A46', '373D6FB2-FCDE-4FF0-BFD6-F9EE236500AE', N'Franklin Lakes, NJ', SYSDATETIME());
GO

INSERT INTO
    dbo.Facility (FacilityKey, FacilityName, CompanyKey, CreatedAt)
VALUES
    ('6B8B67BF-E633-4005-9925-FCF983526A46', '12BF37EC-6E8A-4ABD-8A3A-AF8CD08AF99A', N'San Diago, CA', SYSDATETIME());
GO

-- Create company and facilities in a single transaction.
BEGIN TRANSACTION;
GO

INSERT INTO
    dbo.Company (CompanyKey, CompanyName, CreatedAt)
VALUES
    ('3A2FC681-A143-4A4E-BC47-09EDE8A7A8C1', N'Microsoft Corporation', SYSDATETIME());
GO

INSERT INTO
    dbo.UserAccount (CompanyKey, UserAccountKey, Email, DisplayName, CreatedAt)
VALUES
    ('3A2FC681-A143-4A4E-BC47-09EDE8A7A8C1', '80D79362-FCD4-4EE9-AD73-BF9C3F3D4735', N'bill.gates@microsoft.com', N'William Gates III', SYSDATETIME());
GO

INSERT INTO
    dbo.Facility (CompanyKey, FacilityKey, FacilityName, CreatedAt)
VALUES
    ('3A2FC681-A143-4A4E-BC47-09EDE8A7A8C1', '68461BD9-6CB2-402D-B3DE-3C56AFFF5229', N'Seattle, WA', SYSDATETIME()),
    ('3A2FC681-A143-4A4E-BC47-09EDE8A7A8C1', 'F6ED7478-9504-4B8B-AE6F-6AC2A4C355EC', N'Raleigh, NC', SYSDATETIME());
GO

COMMIT;
GO

-- Update facility in separate transaction.
UPDATE
    dbo.Facility
SET
    FacilityName = N'San Diego, CA'
WHERE
    CompanyKey = '6B8B67BF-E633-4005-9925-FCF983526A46'
AND
    FacilityKey = '12BF37EC-6E8A-4ABD-8A3A-AF8CD08AF99A';
GO

-- Update table schema.
ALTER TABLE dbo.Facility
    ADD FoundedOn DATE NULL;
GO


-- ================================================================================
-- CHANGE DATA CAPTURE
-- ================================================================================

-- Query records.
DECLARE
    @LsnFrom                        binary(10)          = (SELECT sys.fn_cdc_get_min_lsn(N'dbo_Company')),
    @LsnTo                          binary(10)          = (SELECT sys.fn_cdc_get_max_lsn());

SELECT
    *
FROM
    cdc.fn_cdc_get_all_changes_dbo_Company(@LsnFrom, @LsnTo, N'all update old');
GO

DECLARE
    @LsnFrom                        binary(10)          = (SELECT sys.fn_cdc_get_min_lsn(N'dbo_UserAccount')),
    @LsnTo                          binary(10)          = (SELECT sys.fn_cdc_get_max_lsn());

SELECT
    *
FROM
    cdc.fn_cdc_get_all_changes_dbo_UserAccount(@LsnFrom, @LsnTo, N'all update old');
GO

DECLARE
    @LsnFrom                        binary(10)          = (SELECT sys.fn_cdc_get_min_lsn(N'dbo_Facility')),
    @LsnTo                          binary(10)          = (SELECT sys.fn_cdc_get_max_lsn());

SELECT
    *
FROM
    cdc.fn_cdc_get_all_changes_dbo_Facility(@LsnFrom, @LsnTo, N'all update old');
GO

-- Query status.
EXECUTE sys.sp_cdc_help_change_data_capture;
EXECUTE sys.sp_cdc_help_jobs;
GO

SELECT * FROM sys.dm_cdc_log_scan_sessions;
SELECT * FROM sys.dm_cdc_errors;
GO

-- Get DDL history.
EXECUTE sys.sp_cdc_get_ddl_history @capture_instance = N'dbo_Company';
EXECUTE sys.sp_cdc_get_ddl_history @capture_instance = N'dbo_Facility';
GO


-- ================================================================================
-- MISCELLANEOUS
-- ================================================================================

-- Creation duration.
--
--   100 companies    host fs      forced flush on      1 thread       847 ms    Success.
--   100 companies    host fs      forced flush on      2 threads      n/a ms    Failure. SQL Server locks up after 2-4 inserts with PREEMPTIVE_OS_FLUSHFILEBUFFERS wait on INSERT and spinlocks soaking up CPU.
--   100 companies    docker fs    forced flush on      1 thread     1,102 ms    Success.
--   100 companies    docker fs    forced flush on      2 threads      n/a ms    Failure. Succeeded once, but then same freeze as above. More rows inserted before freezing (30+).
--   100 companies    docker fs    forced flush off     1 thread       699 ms    Success.
--   100 companies    docker fs    forced flush off     2 threads      366 ms    Success.
--   100 companies    docker fs    forced flush off    10 threads      166 ms    Success.
--   100 companies    host fs      forced flush off    10 threads      142 ms    Success.
--
-- https://www.sqlskills.com/blogs/paul/preemptive_os_flushfilebuffers-waits-on-linux/
-- https://support.microsoft.com/en-us/help/4131496/kb4131496-enable-forced-flush-mechanism-in-sql-server-2017-on-linux
--
-- To access SQL Server container as root to use mssql-conf:
-- docker exec -u root -it sql-server_sql-server_1 /bin/bash
--
select count(*) AS Companies, datediff(millisecond, min(c.CreatedAt), max(c.CreatedAt)) AS TimeToCreate from dbo.Company c;
select count(*) AS UserAccounts, datediff(millisecond, min(u.CreatedAt), max(u.CreatedAt)) AS TimeToCreate from dbo.UserAccount u;
select count(*) AS Facilities, datediff(millisecond, min(f.CreatedAt), max(f.CreatedAt)) AS TimeToCreate from dbo.Facility f;
GO

/*
alter index pk_Company on dbo.Company reorganize;
alter index pk_UserAccount on dbo.UserAccount reorganize;
alter index pk_Facility on dbo.Facility reorganize;
GO

delete from dbo.Facility;
delete from dbo.UserAccount;
delete from dbo.Company;
GO
*/

select * from dbo.Company (nolock);
select * from dbo.UserAccount (nolock);
select * from dbo.Facility (nolock);
GO

-- Company user accounts.
SELECT
    c.CompanyKey,
    c.CompanyName,
    u.UserAccountKey,
    u.Email,
    u.DisplayName
FROM
    dbo.Company c
INNER JOIN
    dbo.UserAccount u
ON
    u.CompanyKey = c.CompanyKey
ORDER BY
    c.CompanyKey,
    u.UserAccountKey;
GO

-- Company facilities.
SELECT
    c.CompanyKey,
    c.CompanyName,
    f.FacilityKey,
    f.FacilityName
FROM
    dbo.Company c
INNER JOIN
    dbo.Facility f
ON
    f.CompanyKey = c.CompanyKey
ORDER BY
    c.CompanyKey,
    f.FacilityKey;
GO

-- Index information.
SELECT
    OBJECT_SCHEMA_NAME(i.object_id)         AS schema_name,
    OBJECT_NAME(i.object_id)                AS table_name,
    i.name                                  AS index_name,
    i.type_desc                             AS index_type,
    i.index_id                              AS index_id,
    ps.index_level                          AS index_level,
    ps.partition_number                     AS partition_no,
    ps.record_count                         AS record_count,
    ps.page_count                           AS page_count,
    ps.avg_page_space_used_in_percent       AS page_space_pct,
    ps.avg_record_size_in_bytes             AS record_size,
    ps.fragment_count                       AS fragment_count,
    ps.avg_fragmentation_in_percent         AS fragment_pct,
    ps.avg_fragment_size_in_pages           AS fragment_size
FROM
    sys.indexes i
CROSS APPLY
    sys.dm_db_index_physical_stats(db_id(), i.object_id, i.index_id, NULL, N'DETAILED') ps
ORDER BY
    OBJECT_SCHEMA_NAME(i.object_id),
    OBJECT_NAME(i.object_id),
    i.index_id,
    ps.index_level;
GO
