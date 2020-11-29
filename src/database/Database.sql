:on error exit

:setvar DatabaseName "MedicationTracker"

-- ================================================================================
-- DATABASE
-- ================================================================================
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = N'$(DatabaseName)')
BEGIN
    ALTER DATABASE [$(DatabaseName)]
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE [$(DatabaseName)];
END;
GO

CREATE DATABASE [$(DatabaseName)]
ON PRIMARY
(
    NAME        = $(DatabaseName),
--  FILENAME    = '/var/opt/mssql/data/$(DatabaseName).mdf',
    FILENAME    = '/home/mssql/data/$(DatabaseName).mdf',
	SIZE		= 64 MB,
	MAXSIZE		= UNLIMITED,
	FILEGROWTH	= 64 MB
),
FILEGROUP CoreData
(
    NAME        = $(DatabaseName)CoreData,
--  FILENAME    = '/var/opt/mssql/data/$(DatabaseName)CoreData.mdf',
    FILENAME    = '/home/mssql/data/$(DatabaseName)CoreData.ndf',
	SIZE		= 64 MB,
	MAXSIZE		= UNLIMITED,
	FILEGROWTH	= 64 MB
),
FILEGROUP CoreCdc
(
    NAME        = $(DatabaseName)CoreCdc,
--  FILENAME    = '/var/opt/mssql/data/$(DatabaseName)CoreCdc.ndf',
    FILENAME    = '/home/mssql/data/$(DatabaseName)CoreCdc.ndf',
	SIZE		= 64 MB,
	MAXSIZE		= UNLIMITED,
	FILEGROWTH	= 64 MB
),
FILEGROUP TransactionData
(
    NAME        = $(DatabaseName)TransactionData,
--  FILENAME    = '/var/opt/mssql/data/$(DatabaseName)TransactionData.ndf',
    FILENAME    = '/home/mssql/data/$(DatabaseName)TransactionData.ndf',
	SIZE		= 64 MB,
	MAXSIZE		= UNLIMITED,
	FILEGROWTH	= 64 MB
),
FILEGROUP TransactionCdc
(
    NAME        = $(DatabaseName)TransactionCdc,
--  FILENAME    = '/var/opt/mssql/data/$(DatabaseName)TransactionCdc.ndf',
    FILENAME    = '/home/mssql/data/$(DatabaseName)TransactionCdc.ndf',
	SIZE		= 64 MB,
	MAXSIZE		= UNLIMITED,
	FILEGROWTH	= 64 MB
)
LOG ON
(
    NAME        = $(DatabaseName)Log,
--  FILENAME    = '/var/opt/mssql/data/$(DatabaseName).ldf',
    FILENAME    = '/home/mssql/data/$(DatabaseName).ldf',
	SIZE		= 64 MB,
	MAXSIZE		= UNLIMITED,
	FILEGROWTH	= 64 MB
);
GO

ALTER DATABASE [$(DatabaseName)]
    SET RECOVERY SIMPLE;
GO

-- ================================================================================
-- DATABASE CONFIGURATION
-- ================================================================================
USE [$(DatabaseName)]
GO

-- Change Data Capture
EXECUTE sys.sp_cdc_enable_db;
GO


-- ================================================================================
-- SCHEMA
--
-- The rowversion column is included on each table to incur overhead similar
-- to existing database design - likewise for its index.
--
-- Indexes generally include the company key because it is the partition key
-- and is thus expected to be used in almost all queries.
--
-- Fillfactors are 100% for static table indexes because once they are populated
-- and rebuilt, there will be no additional traffic to cause fragmentation.
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Company
-- --------------------------------------------------------------------------------
CREATE TABLE dbo.Company
(
    CompanyKey                  uniqueidentifier    NOT NULL,
    CompanyName                 nvarchar(50)        NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.Company
    ADD CONSTRAINT pk_Company
    PRIMARY KEY CLUSTERED (CompanyKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Company
    ADD CONSTRAINT uk_Company_CompanyName
    UNIQUE (CompanyName)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Company_CompanyKeyRover
    ON dbo.Company (CompanyKey, Rover)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Company',
--  @capture_instance = N'',        -- Use default name for demo.
    @supports_net_changes = 0,      -- No functions for net changes.
    @role_name = NULL,              -- No gating role.
    @index_name = NULL,
    @captured_column_list = NULL,
    @filegroup_name = N'CoreCdc',
    @allow_partition_switch = 1;
GO

-- --------------------------------------------------------------------------------
-- UserAccount
-- --------------------------------------------------------------------------------
CREATE TABLE dbo.UserAccount
(
    CompanyKey                  uniqueidentifier    NOT NULL,
    UserAccountKey              uniqueidentifier    NOT NULL,
    Email                       nvarchar(100)       NOT NULL,
    DisplayName                 nvarchar(50)        NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.UserAccount
    ADD CONSTRAINT pk_UserAccount
    PRIMARY KEY CLUSTERED (CompanyKey, UserAccountKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.UserAccount
    ADD CONSTRAINT uk_UserAccount_CompanyKeyEmail
    UNIQUE (CompanyKey, Email)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.UserAccount
    ADD CONSTRAINT uk_UserAccount_CompanyKeyDisplayName
    UNIQUE (CompanyKey, DisplayName)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.UserAccount
    ADD CONSTRAINT fk_UserAccount_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey);
GO

CREATE NONCLUSTERED INDEX ix_UserAccount_CompanyKey
    ON dbo.UserAccount (CompanyKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_UserAccount_CompanyKeyRover
    ON dbo.UserAccount (CompanyKey, Rover)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'UserAccount',
--  @capture_instance = N'',        -- Use default name for demo.
    @supports_net_changes = 0,      -- No functions for net changes.
    @role_name = NULL,              -- No gating role.
    @index_name = NULL,
    @captured_column_list = NULL,
    @filegroup_name = N'CoreCdc',
    @allow_partition_switch = 1;
GO

-- --------------------------------------------------------------------------------
-- Facility
-- --------------------------------------------------------------------------------
CREATE TABLE dbo.Facility
(
    CompanyKey                  uniqueidentifier    NOT NULL,
    FacilityKey                 uniqueidentifier    NOT NULL,
    FacilityName                nvarchar(50)        NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.Facility
    ADD CONSTRAINT pk_Facility
    PRIMARY KEY CLUSTERED (CompanyKey, FacilityKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Facility
    ADD CONSTRAINT uk_Facility_CompanyKeyFacilityName
    UNIQUE (CompanyKey, FacilityName)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Facility
    ADD CONSTRAINT fk_Facility_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey);
GO

CREATE NONCLUSTERED INDEX ix_Facility_CompanyKey
    ON dbo.Facility (CompanyKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Facility_CompanyKeyRover
    ON dbo.Facility (CompanyKey, Rover)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Facility',
--  @capture_instance = N'',        -- Use default name for demo.
    @supports_net_changes = 0,      -- No functions for net changes.
    @role_name = NULL,              -- No gating role.
    @index_name = NULL,
    @captured_column_list = NULL,
    @filegroup_name = N'CoreCdc',
    @allow_partition_switch = 1;
GO

-- --------------------------------------------------------------------------------
-- Item
-- --------------------------------------------------------------------------------
CREATE TABLE dbo.Item
(
    CompanyKey                  uniqueidentifier    NOT NULL,
    ItemKey                     uniqueidentifier    NOT NULL,
    ItemName                    nvarchar(100)       NOT NULL,
    FacilityKey                 uniqueidentifier    NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT pk_Item
    PRIMARY KEY CLUSTERED (CompanyKey, ItemKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT uk_Item_FacilityKeyItemKey
    UNIQUE (FacilityKey, ItemKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT uk_Item_FacilityKeyItemName
    UNIQUE (FacilityKey, ItemName)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT fk_Item_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey);
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT fk_Item_CompanyKeyFacilityKey_Facility
    FOREIGN KEY (CompanyKey, FacilityKey)
    REFERENCES dbo.Facility (CompanyKey, FacilityKey);
GO

CREATE NONCLUSTERED INDEX ix_Item_CompanyKey
    ON dbo.Item (CompanyKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Item_CompanyKeyFacilityKey
    ON dbo.Item (CompanyKey, FacilityKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Item_CompanyKeyRover
    ON dbo.Item (CompanyKey, Rover)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Item',
--  @capture_instance = N'',        -- Use default name for demo.
    @supports_net_changes = 0,      -- No functions for net changes.
    @role_name = NULL,              -- No gating role.
    @index_name = NULL,
    @captured_column_list = NULL,
    @filegroup_name = N'CoreCdc',
    @allow_partition_switch = 1;
GO

--------------------------------------------------------------------------------
-- Device
--------------------------------------------------------------------------------
CREATE TABLE dbo.Device
(
    CompanyKey                  uniqueidentifier    NOT NULL,
    DeviceKey                   uniqueidentifier    NOT NULL,
    DeviceName                  nvarchar(50)        NOT NULL,
    FacilityKey                 uniqueidentifier    NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.Device
    ADD CONSTRAINT pk_Device
    PRIMARY KEY CLUSTERED (CompanyKey, DeviceKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Device
    ADD CONSTRAINT uk_Device_FacilityKeyDeviceKey
    UNIQUE (FacilityKey, DeviceKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Device
    ADD CONSTRAINT uk_Device_FacilityKeyDeviceName
    UNIQUE (FacilityKey, DeviceName)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

ALTER TABLE dbo.Device
    ADD CONSTRAINT fk_Device_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey);
GO

ALTER TABLE dbo.Device
    ADD CONSTRAINT fk_Device_CompanyKeyFacilityKey_Facility
    FOREIGN KEY (CompanyKey, FacilityKey)
    REFERENCES dbo.Facility (CompanyKey, FacilityKey);
GO

CREATE NONCLUSTERED INDEX ix_Device_CompanyKey
    ON dbo.Device (CompanyKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Device_CompanyKeyFacilityKey
    ON dbo.Device (CompanyKey, FacilityKey)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Device_CompanyKeyRover
    ON dbo.Device (CompanyKey, Rover)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Device',
--  @capture_instance = N'',        -- Use default name for demo.
    @supports_net_changes = 0,      -- No functions for net changes.
    @role_name = NULL,              -- No gating role.
    @index_name = NULL,
    @captured_column_list = NULL,
    @filegroup_name = N'CoreCdc',
    @allow_partition_switch = 1;
GO

-- --------------------------------------------------------------------------------
-- Patient
-- --------------------------------------------------------------------------------
CREATE TABLE dbo.Patient
(
    CompanyKey                  uniqueidentifier    NOT NULL,
    PatientKey                  uniqueidentifier    NOT NULL,
    PatientName                 nvarchar(50)        NOT NULL,
    Birthdate                   datetime2(7)        NOT NULL,
    FacilityKey                 uniqueidentifier    NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.Patient
    ADD CONSTRAINT pk_Patient
    PRIMARY KEY CLUSTERED (CompanyKey, PatientKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.Patient
    ADD CONSTRAINT uk_Patient_FacilityKeyPatientKey
    UNIQUE (FacilityKey, PatientKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

-- Patients can have the same name in the real world, but not here.
ALTER TABLE dbo.Patient
    ADD CONSTRAINT uk_Patient_FacilityKeyPatientName
    UNIQUE (FacilityKey, PatientName)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.Patient
    ADD CONSTRAINT fk_Patient_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey)
GO

ALTER TABLE dbo.Patient
    ADD CONSTRAINT fk_Patient_CompanyKeyFacilityKey_Facility
    FOREIGN KEY (CompanyKey, FacilityKey)
    REFERENCES dbo.Facility (CompanyKey, FacilityKey)
GO

CREATE NONCLUSTERED INDEX ix_Patient_CompanyKey
    ON dbo.Patient (CompanyKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Patient_CompanyKeyFacilityKey
    ON dbo.Patient (CompanyKey, FacilityKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

-- Use full pages with stable company key and sequential rowversions. Review
-- fragmentation behavior during tests to see if this is optimal.
CREATE NONCLUSTERED INDEX ix_Patient_CompanyKeyRover
    ON dbo.Patient (CompanyKey, Rover)
    WITH FILLFACTOR = 100
    ON CoreData;
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Patient',
--  @capture_instance = N'',        -- Use default name for demo.
    @supports_net_changes = 0,      -- No functions for net changes.
    @role_name = NULL,              -- No gating role.
    @index_name = NULL,
    @captured_column_list = NULL,
    @filegroup_name = N'CoreCdc',
    @allow_partition_switch = 1;
GO

-- --------------------------------------------------------------------------------
-- Encounter
-- --------------------------------------------------------------------------------
-- CREATE TABLE dbo.Encounter
-- (
-- );
-- GO

-- --------------------------------------------------------------------------------
-- PharmacyOrder
-- --------------------------------------------------------------------------------
-- CREATE TABLE dbo.PharmacyOrder
-- (
-- );
-- GO

-- --------------------------------------------------------------------------------
-- Transaction
-- --------------------------------------------------------------------------------
-- CREATE TABLE dbo.Transaction
-- (
-- );
-- GO


-- ================================================================================
-- DATABASE CONFIGURATION
-- ================================================================================

-- Change Data Capture Retention Period
EXECUTE sys.sp_cdc_change_job
    @job_type = N'cleanup',
    @retention = 1440;              -- 1 day.
GO
