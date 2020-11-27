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
-- The rowversion column is included on each table to incur provide overhead
-- similar to existing database design - likewise for its index.
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Company
-- --------------------------------------------------------------------------------
CREATE TABLE dbo.Company
(
    CompanyKey                  uniqueidentifier    NOT NULL,
    CompanyName                 nvarchar(40)        NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.Company
    ADD CONSTRAINT pk_Company
    PRIMARY KEY CLUSTERED (CompanyKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.Company
    ADD CONSTRAINT uk_Company_CompanyName
    UNIQUE (CompanyName)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Company_Rover
    ON dbo.Company (Rover)
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
    DisplayName                 nvarchar(100)       NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.UserAccount
    ADD CONSTRAINT pk_UserAccount
    PRIMARY KEY CLUSTERED (CompanyKey, UserAccountKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.UserAccount
    ADD CONSTRAINT uk_UserAccount_CompanyKeyEmail
    UNIQUE (CompanyKey, Email)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.UserAccount
    ADD CONSTRAINT fk_UserAccount_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey);
GO

CREATE NONCLUSTERED INDEX ix_UserAccount_Rover
    ON dbo.UserAccount (Rover)
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
    FacilityName                nvarchar(90)        NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.Facility
    ADD CONSTRAINT pk_Facility
    PRIMARY KEY CLUSTERED (CompanyKey, FacilityKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.Facility
    ADD CONSTRAINT uk_Facility_CompanyKeyFacilityName
    UNIQUE (CompanyKey, FacilityName)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.Facility
    ADD CONSTRAINT fk_Facility_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey);
GO

CREATE NONCLUSTERED INDEX ix_Facility_Rover
    ON dbo.Facility (Rover)
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
    DisplayName                 nvarchar(100)       NOT NULL,
    FacilityKey                 uniqueidentifier    NOT NULL,
    CreatedAt                   datetime2(7)        NOT NULL,
    Rover                       rowversion          NOT NULL
);
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT pk_Item
    PRIMARY KEY CLUSTERED (CompanyKey, ItemKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT uk_Item_FacilityKeyItemKey
    UNIQUE (FacilityKey, ItemKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT fk_Item_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey);
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT fk_Item_FacilityKey_Facility
    FOREIGN KEY (CompanyKey, FacilityKey)
    REFERENCES dbo.Facility (CompanyKey, FacilityKey);
GO

CREATE NONCLUSTERED INDEX ix_Item_FacilityKey
    ON dbo.Item (FacilityKey)
    WITH FILLFACTOR = 80
    ON CoreData;
GO

CREATE NONCLUSTERED INDEX ix_Item_Rover
    ON dbo.Item (Rover)
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


-- ================================================================================
-- DATABASE CONFIGURATION
-- ================================================================================

-- Change Data Capture Retention Period
EXECUTE sys.sp_cdc_change_job
    @job_type = N'cleanup',
    @retention = 1440;              -- 1 day.
GO
