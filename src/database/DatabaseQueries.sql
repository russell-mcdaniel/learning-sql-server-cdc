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
    dbo.Facility (CompanyKey, FacilityKey, FacilityName, CreatedAt)
VALUES
    ('6B8B67BF-E633-4005-9925-FCF983526A46', '12BF37EC-6E8A-4ABD-8A3A-AF8CD08AF99A', N'San Diego, CA', SYSDATETIME());
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
    ('3A2FC681-A143-4A4E-BC47-09EDE8A7A8C1', '68461BD9-6CB2-402D-B3DE-3C56AFFF5229', N'Saettle, WA', SYSDATETIME());

INSERT INTO
    dbo.Facility (CompanyKey, FacilityKey, FacilityName, CreatedAt)
VALUES
    ('3A2FC681-A143-4A4E-BC47-09EDE8A7A8C1', 'F6ED7478-9504-4B8B-AE6F-6AC2A4C355EC', N'Raleigh, NC', SYSDATETIME());
GO

COMMIT;
GO

-- Correct facility name in a separate transaction.
UPDATE
    dbo.Facility
SET
    FacilityName = N'Seattle, WA'
WHERE
    CompanyKey = '3A2FC681-A143-4A4E-BC47-09EDE8A7A8C1'
AND
    FacilityKey = '68461BD9-6CB2-402D-B3DE-3C56AFFF5229';
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

SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_Company(@LsnFrom, @LsnTo, N'all update old');
GO

DECLARE
    @LsnFrom                        binary(10)          = (SELECT sys.fn_cdc_get_min_lsn(N'dbo_UserAccount')),
    @LsnTo                          binary(10)          = (SELECT sys.fn_cdc_get_max_lsn());

SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_UserAccount(@LsnFrom, @LsnTo, N'all update old');
GO

DECLARE
    @LsnFrom                        binary(10)          = (SELECT sys.fn_cdc_get_min_lsn(N'dbo_Facility')),
    @LsnTo                          binary(10)          = (SELECT sys.fn_cdc_get_max_lsn());

SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_Facility(@LsnFrom, @LsnTo, N'all update old');
GO

DECLARE
    @LsnFrom                        binary(10)          = (SELECT sys.fn_cdc_get_min_lsn(N'dbo_Item')),
    @LsnTo                          binary(10)          = (SELECT sys.fn_cdc_get_max_lsn());

SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_Item(@LsnFrom, @LsnTo, N'all update old');
GO

DECLARE
    @LsnFrom                        binary(10)          = (SELECT sys.fn_cdc_get_min_lsn(N'dbo_Device')),
    @LsnTo                          binary(10)          = (SELECT sys.fn_cdc_get_max_lsn());

SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_Device(@LsnFrom, @LsnTo, N'all update old');
GO

DECLARE
    @LsnFrom                        binary(10)          = (SELECT sys.fn_cdc_get_min_lsn(N'dbo_Patient')),
    @LsnTo                          binary(10)          = (SELECT sys.fn_cdc_get_max_lsn());

SELECT * FROM cdc.fn_cdc_get_all_changes_dbo_Patient(@LsnFrom, @LsnTo, N'all update old');
GO

-- Query status.
EXECUTE sys.sp_cdc_help_change_data_capture;
EXECUTE sys.sp_cdc_help_jobs;
GO

SELECT latency, command_count / duration AS throughput FROM sys.dm_cdc_log_scan_sessions WHERE session_id = 0
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

-- Entity count and insertion time.
select N'Company'     as Entity, count(*) as Records, min(CreatedAt) as CreatedAtMin, max(CreatedAt) as CreatedAtMax, datediff(millisecond, min(CreatedAt), max(CreatedAt)) as TimeToCreate   from dbo.Company (nolock)         union all
select N'UserAccount' as Entity, count(*),            min(CreatedAt),                 max(CreatedAt),                 datediff(millisecond, min(CreatedAt), max(CreatedAt))                   from dbo.UserAccount (nolock)     union all
select N'Facility'    as Entity, count(*),            min(CreatedAt),                 max(CreatedAt),                 datediff(millisecond, min(CreatedAt), max(CreatedAt))                   from dbo.Facility (nolock)        union all
select N'Item'        as Entity, count(*),            min(CreatedAt),                 max(CreatedAt),                 datediff(millisecond, min(CreatedAt), max(CreatedAt))                   from dbo.Item (nolock)            union all
select N'Device'      as Entity, count(*),            min(CreatedAt),                 max(CreatedAt),                 datediff(millisecond, min(CreatedAt), max(CreatedAt))                   from dbo.Device (nolock)          union all
select N'Patient'     as Entity, count(*),            min(CreatedAt),                 max(CreatedAt),                 datediff(millisecond, min(CreatedAt), max(CreatedAt))                   from dbo.Patient (nolock)         union all
select N'Encounter'   as Entity, count(*),            min(CreatedAt),                 max(CreatedAt),                 datediff(millisecond, min(CreatedAt), max(CreatedAt))                   from dbo.Encounter (nolock)       union all
select N'Order'       as Entity, count(*),            min(CreatedAt),                 max(CreatedAt),                 datediff(millisecond, min(CreatedAt), max(CreatedAt))                   from dbo.PharmacyOrder (nolock);
GO

-- Entity name length.
select N'CompanyName'       as EntityCol,   max(len(CompanyName))    as MaxLen  from dbo.Company (nolock)        union all
select N'UserEmail',                        max(len(Email))                     from dbo.UserAccount (nolock)    union all
select N'UserDisplayName',                  max(len(DisplayName))               from dbo.UserAccount (nolock)    union all
select N'FacilityName',                     max(len(FacilityName))              from dbo.Facility (nolock)       union all
select N'ItemName',                         max(len(ItemName))                  from dbo.Item (nolock)           union all
select N'DeviceName',                       max(len(DeviceName))                from dbo.Device (nolock)         union all
select N'PatientName',                      max(len(PatientName))               from dbo.Patient (nolock)        union all
select N'EncounterId',                      max(len(EncounterId))               from dbo.Encounter (nolock)      union all
select N'OrderId',                          max(len(PharmacyOrderId))           from dbo.PharmacyOrder (nolock);
GO

/*
alter index all on dbo.Company rebuild;
alter index all on dbo.UserAccount rebuild;
alter index all on dbo.Facility rebuild;
alter index all on dbo.Item rebuild;
alter index all on dbo.Device rebuild;
alter index all on dbo.Patient reorganize;
alter index all on dbo.Encounter reorganize;
alter index all on dbo.PharmacyOrder reorganize;
GO

select * from dbo.Company (nolock);
select * from dbo.UserAccount (nolock);
select * from dbo.Facility (nolock);
select * from dbo.Item (nolock);
select * from dbo.Device (nolock);
select * from dbo.Patient (nolock);
select * from dbo.Encounter (nolock);
select * from dbo.PharmacyOrder (nolock);
GO

delete from dbo.PharmacyOrder;
delete from dbo.Encounter;
delete from dbo.Patient;
delete from dbo.Device;
delete from dbo.Item;
delete from dbo.Facility;
delete from dbo.UserAccount;
delete from dbo.Company;
GO
*/

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

-- Facility items.
SELECT
    f.FacilityKey,
    f.FacilityKey,
    i.ItemKey,
    i.ItemName
FROM
    dbo.Facility f
INNER JOIN
    dbo.Item i
ON
    i.CompanyKey = f.CompanyKey
AND
    i.FacilityKey = f.FacilityKey
ORDER BY
    f.CompanyKey,
    f.FacilityKey,
    i.ItemKey;
GO

-- Facility devices.
SELECT
    f.FacilityKey,
    f.FacilityName,
    d.DeviceKey,
    d.DeviceName
FROM
    dbo.Facility f
INNER JOIN
    dbo.Device d
ON
    d.CompanyKey = f.CompanyKey
AND
    d.FacilityKey = f.FacilityKey
ORDER BY
    f.CompanyKey,
    f.FacilityKey,
    d.DeviceKey;
GO

-- ================================================================================
-- Multi-tenant query performance query demonstration.
-- ================================================================================

-- Ordered items.
SELECT
	po.ItemKey						AS ItemKey,
	COUNT(*)						AS PharmacyOrderCount
FROM
	dbo.PharmacyOrder po
GROUP BY
	po.ItemKey
ORDER BY
	COUNT(*) DESC;
GO

-- Ordered items.
SELECT
	po.CompanyKey					AS CompanyKey,
	po.ItemKey						AS ItemKey,
	COUNT(*)						AS PharmacyOrderCount
FROM
	dbo.PharmacyOrder po
GROUP BY
	po.CompanyKey,
	po.ItemKey
ORDER BY
	COUNT(*) DESC;
GO

-- Ordered items.
WITH CompanyPharmacyOrder (CompanyKey, ItemKey, PharmacyOrderCount)
AS
(
	SELECT
		o.CompanyKey                AS CompanyKey,
		o.ItemKey                   AS ItemKey,
		COUNT(*)                    AS PharmacyOrderCount
	FROM
		dbo.PharmacyOrder o
	GROUP BY
		o.CompanyKey,
		o.ItemKey
)
SELECT
	cpo.ItemKey						AS ItemKey,
	SUM(cpo.PharmacyOrderCount)		AS PharmacyOrderCount
FROM
	CompanyPharmacyOrder cpo
GROUP BY
	cpo.ItemKey
ORDER BY
    SUM(cpo.PharmacyOrderCount) DESC;
GO
