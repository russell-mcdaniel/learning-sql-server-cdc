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
ON
(
    NAME        = $(DatabaseName),
    FILENAME    = '/var/opt/mssql/data/$(DatabaseName).mdf',
	SIZE		= 64 MB,
	MAXSIZE		= UNLIMITED,
	FILEGROWTH	= 64 MB
)
LOG ON
(
    NAME        = $(DatabaseName)Log,
    FILENAME    = '/var/opt/mssql/data/$(DatabaseName).ldf',
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
    ON [PRIMARY];
GO

ALTER TABLE dbo.Company
    ADD CONSTRAINT uk_Company_CompanyName
    UNIQUE (CompanyName)
    WITH FILLFACTOR = 80
    ON [PRIMARY];
GO

CREATE NONCLUSTERED INDEX ix_Company_1
    ON dbo.Company (Rover)
    WITH FILLFACTOR = 80
    ON [PRIMARY];
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Company',
--  @capture_instance = N'',        -- Use default name for demo.
    @supports_net_changes = 0,      -- No functions for net changes.
    @role_name = NULL,              -- No gating role.
    @index_name = NULL,
    @captured_column_list = NULL,
    @filegroup_name = N'PRIMARY',
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
    ON [PRIMARY];
GO

ALTER TABLE dbo.Facility
    ADD CONSTRAINT fk_Facility_CompanyKey_Company
    FOREIGN KEY (CompanyKey)
    REFERENCES dbo.Company (CompanyKey);
GO

CREATE NONCLUSTERED INDEX ix_Facility_1
    ON dbo.Facility (Rover)
    WITH FILLFACTOR = 80
    ON [PRIMARY];
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name = N'Facility',
--  @capture_instance = N'',        -- Use default name for demo.
    @supports_net_changes = 0,      -- No functions for net changes.
    @role_name = NULL,              -- No gating role.
    @index_name = NULL,
    @captured_column_list = NULL,
    @filegroup_name = N'PRIMARY',
    @allow_partition_switch = 1;
GO

-- --------------------------------------------------------------------------------
-- Item
-- --------------------------------------------------------------------------------
CREATE TABLE dbo.Item
(
);
GO

ALTER TABLE dbo.Item
    ADD CONSTRAINT pk_Item
    PRIMARY KEY CLUSTERED (CompanyKey, ItemKey)
    WITH FILLFACTOR = 80
    ON [PRIMARY];
GO
