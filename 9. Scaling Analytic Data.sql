USE WideWorldImportersDW;
SET STATISTICS IO ON;
GO

/*	Segment 9. Scaling Analytic Data

	How to scale data in SQL Server so that as it gets larger, it can still be accessed efficiently.
*/

SELECT
	*
FROM Dimension.Employee;

CREATE TABLE Dimension.EmployeeHistory
(	[Employee Key] INT NOT NULL,
	[WWI Employee ID] INT NOT NULL,
	[Employee] NVARCHAR(50) NOT NULL,
	[Preferred Name] NVARCHAR(50) NOT NULL,
	[Is Salesperson] BIT NOT NULL,
	[Photo] VARBINARY(MAX) NULL,
	[Valid From] DATETIME2(7) NOT NULL,
	[Valid To] DATETIME2(7) NOT NULL,
	[Lineage Key] INT NOT NULL);
GO
CREATE CLUSTERED COLUMNSTORE INDEX CCI_EmployeeHistory ON Dimension.EmployeeHistory;
GO

INSERT INTO Dimension.EmployeeHistory
SELECT * FROM Dimension.Employee
WHERE [Valid To] <> '9999-12-31 23:59:59.9999999'

SELECT
	*
FROM Dimension.EmployeeHistory;
GO

CREATE VIEW v_Employee
AS
SELECT
	*
FROM Dimension.Employee
UNION ALL
SELECT
	*
FROM Dimension.EmployeeHistory
GO

SELECT * FROM dbo.v_Employee;
GO

SELECT
	DATEPART(YEAR, [Order Date Key]),
	COUNT(*) AS OrderCount
FROM Fact.[Order]
GROUP BY DATEPART(YEAR, [Order Date Key])
ORDER BY DATEPART(YEAR, [Order Date Key]);
GO

ALTER DATABASE WideWorldImportersDW ADD FILEGROUP WideWorldImportersDW_2013_fg;
ALTER DATABASE WideWorldImportersDW ADD FILEGROUP WideWorldImportersDW_2014_fg;
ALTER DATABASE WideWorldImportersDW ADD FILEGROUP WideWorldImportersDW_2015_fg;
ALTER DATABASE WideWorldImportersDW ADD FILEGROUP WideWorldImportersDW_2016_fg;
GO
ALTER DATABASE WideWorldImportersDW ADD FILE
	(NAME = WideWorldImportersDW_2013_data, FILENAME = 'C:\SQLData\WideWorldImportersDW_2013_data.ndf',
	 SIZE = 2GB, MAXSIZE = UNLIMITED, FILEGROWTH = 2GB)
TO FILEGROUP WideWorldImportersDW_2013_fg;
ALTER DATABASE WideWorldImportersDW ADD FILE
	(NAME = WideWorldImportersDW_2014_data, FILENAME = 'C:\SQLData\WideWorldImportersDW_2014_data.ndf',
	 SIZE = 2GB, MAXSIZE = UNLIMITED, FILEGROWTH = 2GB)
TO FILEGROUP WideWorldImportersDW_2014_fg;
ALTER DATABASE WideWorldImportersDW ADD FILE
	(NAME = WideWorldImportersDW_2015_data, FILENAME = 'C:\SQLData\WideWorldImportersDW_2015_data.ndf',
	 SIZE = 2GB, MAXSIZE = UNLIMITED, FILEGROWTH = 2GB)
TO FILEGROUP WideWorldImportersDW_2015_fg;
ALTER DATABASE WideWorldImportersDW ADD FILE
	(NAME = WideWorldImportersDW_2016_data, FILENAME = 'C:\SQLData\WideWorldImportersDW_2016_data.ndf',
	 SIZE = 2GB, MAXSIZE = UNLIMITED, FILEGROWTH = 2GB)
TO FILEGROUP WideWorldImportersDW_2016_fg;
GO

CREATE PARTITION FUNCTION WideWorldImportersDW_date_function (DATE)
AS RANGE RIGHT FOR VALUES
	( '1/1/2014', '1/1/2015', '1/1/2016');
GO

CREATE PARTITION SCHEME WideWorldImportersDW_date_scheme
AS PARTITION WideWorldImportersDW_date_function
TO (WideWorldImportersDW_2013_fg, WideWorldImportersDW_2014_fg, WideWorldImportersDW_2015_fg, WideWorldImportersDW_2016_fg);
GO

CREATE TABLE [Fact].[Order](
	[Order Key] [BIGINT] IDENTITY(1,1) NOT NULL,
	[City Key] [int] NOT NULL,
	[Customer Key] [int] NOT NULL,
	[Stock Item Key] [int] NOT NULL,
	[Order Date Key] [date] NOT NULL,
	[Picked Date Key] [date] NULL,
	[Salesperson Key] [int] NOT NULL,
	[Picker Key] [int] NULL,
	[WWI Order ID] [int] NOT NULL,
	[WWI Backorder ID] [int] NULL,
	[Description] [nvarchar](100) NOT NULL,
	[Package] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Unit Price] [decimal](18, 2) NOT NULL,
	[Tax Rate] [decimal](18, 3) NOT NULL,
	[Total Excluding Tax] [decimal](18, 2) NOT NULL,
	[Tax Amount] [decimal](18, 2) NOT NULL,
	[Total Including Tax] [decimal](18, 2) NOT NULL,
	[Lineage Key] [int] NOT NULL) ON WideWorldImportersDW_date_scheme;

	CREATE CLUSTERED COLUMNSTORE INDEX [CCI_Fact_Order] ON [Fact].[Order];
GO

CREATE TABLE [Fact].[Order_2013](
	[Order Key] [bigint] NOT NULL,
	[City Key] [int] NOT NULL,
	[Customer Key] [int] NOT NULL,
	[Stock Item Key] [int] NOT NULL,
	[Order Date Key] [date] NOT NULL,
	[Picked Date Key] [date] NULL,
	[Salesperson Key] [int] NOT NULL,
	[Picker Key] [int] NULL,
	[WWI Order ID] [int] NOT NULL,
	[WWI Backorder ID] [int] NULL,
	[Description] [nvarchar](100) NOT NULL,
	[Package] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Unit Price] [decimal](18, 2) NOT NULL,
	[Tax Rate] [decimal](18, 3) NOT NULL,
	[Total Excluding Tax] [decimal](18, 2) NOT NULL,
	[Tax Amount] [decimal](18, 2) NOT NULL,
	[Total Including Tax] [decimal](18, 2) NOT NULL,
	[Lineage Key] [int] NOT NULL,
	CONSTRAINT PK_Order_2013 PRIMARY KEY CLUSTERED ([Order Date Key], [Order Key]));

CREATE TABLE [Fact].[Order_2014](
	[Order Key] [bigint] NOT NULL,
	[City Key] [int] NOT NULL,
	[Customer Key] [int] NOT NULL,
	[Stock Item Key] [int] NOT NULL,
	[Order Date Key] [date] NOT NULL,
	[Picked Date Key] [date] NULL,
	[Salesperson Key] [int] NOT NULL,
	[Picker Key] [int] NULL,
	[WWI Order ID] [int] NOT NULL,
	[WWI Backorder ID] [int] NULL,
	[Description] [nvarchar](100) NOT NULL,
	[Package] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Unit Price] [decimal](18, 2) NOT NULL,
	[Tax Rate] [decimal](18, 3) NOT NULL,
	[Total Excluding Tax] [decimal](18, 2) NOT NULL,
	[Tax Amount] [decimal](18, 2) NOT NULL,
	[Total Including Tax] [decimal](18, 2) NOT NULL,
	[Lineage Key] [int] NOT NULL,
	CONSTRAINT PK_Order_2014 PRIMARY KEY CLUSTERED ([Order Date Key], [Order Key]));

CREATE TABLE [Fact].[Order_2015](
	[Order Key] [bigint] NOT NULL,
	[City Key] [int] NOT NULL,
	[Customer Key] [int] NOT NULL,
	[Stock Item Key] [int] NOT NULL,
	[Order Date Key] [date] NOT NULL,
	[Picked Date Key] [date] NULL,
	[Salesperson Key] [int] NOT NULL,
	[Picker Key] [int] NULL,
	[WWI Order ID] [int] NOT NULL,
	[WWI Backorder ID] [int] NULL,
	[Description] [nvarchar](100) NOT NULL,
	[Package] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Unit Price] [decimal](18, 2) NOT NULL,
	[Tax Rate] [decimal](18, 3) NOT NULL,
	[Total Excluding Tax] [decimal](18, 2) NOT NULL,
	[Tax Amount] [decimal](18, 2) NOT NULL,
	[Total Including Tax] [decimal](18, 2) NOT NULL,
	[Lineage Key] [int] NOT NULL,
	CONSTRAINT PK_Order_2015 PRIMARY KEY CLUSTERED ([Order Date Key], [Order Key]));

CREATE TABLE [Fact].[Order_2016](
	[Order Key] [bigint] NOT NULL,
	[City Key] [int] NOT NULL,
	[Customer Key] [int] NOT NULL,
	[Stock Item Key] [int] NOT NULL,
	[Order Date Key] [date] NOT NULL,
	[Picked Date Key] [date] NULL,
	[Salesperson Key] [int] NOT NULL,
	[Picker Key] [int] NULL,
	[WWI Order ID] [int] NOT NULL,
	[WWI Backorder ID] [int] NULL,
	[Description] [nvarchar](100) NOT NULL,
	[Package] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Unit Price] [decimal](18, 2) NOT NULL,
	[Tax Rate] [decimal](18, 3) NOT NULL,
	[Total Excluding Tax] [decimal](18, 2) NOT NULL,
	[Tax Amount] [decimal](18, 2) NOT NULL,
	[Total Including Tax] [decimal](18, 2) NOT NULL,
	[Lineage Key] [int] NOT NULL,
	CONSTRAINT PK_Order_2016 PRIMARY KEY CLUSTERED ([Order Date Key], [Order Key]));
GO

INSERT INTO fact.Order_2013
	([Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID],
     Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT
	[Order Key],
	[City Key],
	[Customer Key],
	[Stock Item Key],
	[Order Date Key],
	[Picked Date Key],
	[Salesperson Key],
	[Picker Key],
	[WWI Order ID],
	[WWI Backorder ID],
    Description,
	Package,
	Quantity,
	[Unit Price],
	[Tax Rate],
	[Total Excluding Tax],
	[Tax Amount],
	[Total Including Tax],
	[Lineage Key]
FROM Fact.[Order]
WHERE [Order].[Order Date Key] >= '1/1/2013'
AND [Order].[Order Date Key] < '1/1/2014';

INSERT INTO fact.Order_2014
	([Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID],
     Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT
	[Order Key],
	[City Key],
	[Customer Key],
	[Stock Item Key],
	[Order Date Key],
	[Picked Date Key],
	[Salesperson Key],
	[Picker Key],
	[WWI Order ID],
	[WWI Backorder ID],
    Description,
	Package,
	Quantity,
	[Unit Price],
	[Tax Rate],
	[Total Excluding Tax],
	[Tax Amount],
	[Total Including Tax],
	[Lineage Key]
FROM Fact.[Order]
WHERE [Order].[Order Date Key] >= '1/1/2014'
AND [Order].[Order Date Key] < '1/1/2015';

INSERT INTO fact.Order_2015
	([Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID],
     Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT
	[Order Key],
	[City Key],
	[Customer Key],
	[Stock Item Key],
	[Order Date Key],
	[Picked Date Key],
	[Salesperson Key],
	[Picker Key],
	[WWI Order ID],
	[WWI Backorder ID],
    Description,
	Package,
	Quantity,
	[Unit Price],
	[Tax Rate],
	[Total Excluding Tax],
	[Tax Amount],
	[Total Including Tax],
	[Lineage Key]
FROM Fact.[Order]
WHERE [Order].[Order Date Key] >= '1/1/2015'
AND [Order].[Order Date Key] < '1/1/2016';

INSERT INTO fact.Order_2016
	([Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID],
     Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT
	[Order Key],
	[City Key],
	[Customer Key],
	[Stock Item Key],
	[Order Date Key],
	[Picked Date Key],
	[Salesperson Key],
	[Picker Key],
	[WWI Order ID],
	[WWI Backorder ID],
    Description,
	Package,
	Quantity,
	[Unit Price],
	[Tax Rate],
	[Total Excluding Tax],
	[Tax Amount],
	[Total Including Tax],
	[Lineage Key]
FROM Fact.[Order]
WHERE [Order].[Order Date Key] >= '1/1/2016'
AND [Order].[Order Date Key] < '1/1/2017';
GO

ALTER TABLE Fact.Order_2013 ADD CONSTRAINT CK_Order_2013 CHECK ([Order Date Key] >= '1/1/2013' AND [Order Date Key] < '1/1/2014');
GO
ALTER TABLE Fact.Order_2014 ADD CONSTRAINT CK_Order_2014 CHECK ([Order Date Key] >= '1/1/2014' AND [Order Date Key] < '1/1/2015');
GO
ALTER TABLE Fact.Order_2015 ADD CONSTRAINT CK_Order_2015 CHECK ([Order Date Key] >= '1/1/2015' AND [Order Date Key] < '1/1/2016');
GO
ALTER TABLE Fact.Order_2016 ADD CONSTRAINT CK_Order_2016 CHECK ([Order Date Key] >= '1/1/2016' AND [Order Date Key] < '1/1/2017');
GO

CREATE VIEW dbo.v_Order
AS
	SELECT * FROM Fact.Order_2013
	UNION ALL
	SELECT * FROM Fact.Order_2014
	UNION ALL
	SELECT * FROM Fact.Order_2015
	UNION ALL
	SELECT * FROM Fact.Order_2016
GO

SELECT
	*
FROM dbo.v_Order
WHERE [Order Date Key] >= '7/17/2015'
AND [Order Date Key] < '8/1/2015';

INSERT INTO dbo.v_Order
	([Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID],
     Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT
	17 AS [Order Key],
	[City Key],
	[Customer Key],
	[Stock Item Key],
	[Order Date Key],
	[Picked Date Key],
	[Salesperson Key],
	[Picker Key],
	[WWI Order ID],
	[WWI Backorder ID],
    Description,
	Package,
	Quantity,
	[Unit Price],
	[Tax Rate],
	[Total Excluding Tax],
	[Tax Amount],
	[Total Including Tax],
	[Lineage Key]
FROM fact.[Order]
WHERE [Order].[Order Key] = 1292;

INSERT INTO dbo.v_Order
	([Order Key], [City Key], [Customer Key], [Stock Item Key], [Order Date Key], [Picked Date Key], [Salesperson Key], [Picker Key], [WWI Order ID], [WWI Backorder ID],
     Description, Package, Quantity, [Unit Price], [Tax Rate], [Total Excluding Tax], [Tax Amount], [Total Including Tax], [Lineage Key])
SELECT
	[Order Key],
	[City Key],
	[Customer Key],
	[Stock Item Key],
	'1/17/2035',
	[Picked Date Key],
	[Salesperson Key],
	[Picker Key],
	[WWI Order ID],
	[WWI Backorder ID],
    Description,
	Package,
	Quantity,
	[Unit Price],
	[Tax Rate],
	[Total Excluding Tax],
	[Tax Amount],
	[Total Including Tax],
	[Lineage Key]
FROM Fact.[Order]
WHERE [Order].[Order Key] = 201525;



/*	Cleanup
	
	DROP TABLE Dimension.EmployeeHistory;
	DROP VIEW dbo.v_Employee;
	DROP TABLE [Fact].[Order_2013];
	DROP TABLE [Fact].[Order_2014];
	DROP TABLE [Fact].[Order_2015];
	DROP TABLE [Fact].[Order_2016];
	DROP VIEW dbo.v_Order;
*/