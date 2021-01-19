USE WideWorldImportersDW;
SET STATISTICS IO ON;
SET NOCOUNT ON;
GO

/*	Segment 6. Indexing - B-Tree Versus Columnstore Indexes

	This segment discusses the difference between classic transactional indexes and columnstore indexes, explaining
	the use-cases and benefits of columnstore indexes in SQL Server for large fact tables.

	All of the creation and data population statements in this file are not run live, as they take a long time to execute,
	but are included here to assist the viewer in providing a full set of demo scripts that can model the creation
	of a speedy columnstore-indexed OLAP table.
*/

/********************************************************************************************************************
 ************************Setup & Compression*************************************************************************
 ********************************************************************************************************************
 ********************************************************************************************************************
 ************************Create OLAP Table with a Clustered  Rowstore Index******************************************
 *******************************************************************************************************************/

CREATE TABLE dbo.fact_order_BIG (
	[Order Key] [bigint] NOT NULL CONSTRAINT PK_fact_order_BIG PRIMARY KEY CLUSTERED,
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
	[Lineage Key] [int] NOT NULL);

--	Generate 231,412 * 100 rows of data in an OLTP table.  This takes a few minutes to execute, so we've already done it.
INSERT INTO dbo.fact_order_BIG
SELECT
	 [Order Key] + (250000 * ([Day Number] + ([Calendar Month Number] * 31))) AS [Order Key]
    ,[City Key]
    ,[Customer Key]
    ,[Stock Item Key]
    ,[Order Date Key]
    ,[Picked Date Key]
    ,[Salesperson Key]
    ,[Picker Key]
    ,[WWI Order ID]
    ,[WWI Backorder ID]
    ,[Description]
    ,[Package]
    ,[Quantity]
    ,[Unit Price]
    ,[Tax Rate]
    ,[Total Excluding Tax]
    ,[Tax Amount]
    ,[Total Including Tax]
    ,[Lineage Key]
FROM Fact.[Order]
CROSS JOIN
Dimension.Date
WHERE Date.Date <= '2013-04-10';

-- Add the typical NCI on the date column
CREATE NONCLUSTERED INDEX IX_fact_order_BIG ON dbo.fact_order_BIG ([order date key]);

-- How much data do we have?  23,141,200 Rows.  This took 49234 reads to execute and return data!
SELECT
	COUNT(*),
	MIN([order date key]),
	MAX([order date key])
FROM dbo.fact_order_BIG
WITH (INDEX=IX_fact_order_BIG);

/********************************************************************************************************************
 ************************Create OLAP Table with a Columnstore Index**************************************************
 *******************************************************************************************************************/

CREATE TABLE dbo.fact_order_BIG_CCI (
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
	[Lineage Key] [int] NOT NULL);

-- Generate 231,412 * 100 rows of data in an OLTP table.  This is a little faster than with the OLTP table.
INSERT INTO dbo.fact_order_BIG_CCI
SELECT
	 [Order Key] + (250000 * ([Day Number] + ([Calendar Month Number] * 31))) AS [Order Key]
    ,[City Key]
    ,[Customer Key]
    ,[Stock Item Key]
    ,[Order Date Key]
    ,[Picked Date Key]
    ,[Salesperson Key]
    ,[Picker Key]
    ,[WWI Order ID]
    ,[WWI Backorder ID]
    ,[Description]
    ,[Package]
    ,[Quantity]
    ,[Unit Price]
    ,[Tax Rate]
    ,[Total Excluding Tax]
    ,[Tax Amount]
    ,[Total Including Tax]
    ,[Lineage Key]
FROM Fact.[Order]
CROSS JOIN
Dimension.Date
WHERE Date.Date <= '2013-04-10';

-- Create a columnstore index on the table.
CREATE CLUSTERED COLUMNSTORE INDEX CCI_fact_order_BIG_CCI ON dbo.fact_order_BIG_CCI;
GO
--	How much data do we have?  23,141,200 Rows.
SELECT
	COUNT(*),
	MIN([order date key]),
	MAX([order date key])
FROM dbo.fact_order_BIG_CCI;

-- Compare table sizes
CREATE TABLE #storage_data
(	table_name VARCHAR(MAX),
	rows_used BIGINT,
	reserved VARCHAR(50),
	data VARCHAR(50),
	index_size VARCHAR(50),
	unused VARCHAR(50));

INSERT INTO #storage_data
	(table_name, rows_used, reserved, data, index_size, unused)
EXEC sp_MSforeachtable "EXEC sp_spaceused '?'";

UPDATE #storage_data
	SET reserved = LEFT(reserved, LEN(reserved) - 3),
		data = LEFT(data, LEN(data) - 3),
		index_size = LEFT(index_size, LEN(index_size) - 3),
		unused = LEFT(unused, LEN(unused) - 3);
SELECT
	table_name,
	rows_used,
	reserved / 1024 AS data_space_reserved_mb,
	data / 1024 AS data_space_used_mb,
	index_size / 1024 AS index_size_mb,
	unused AS free_space_kb,
	CAST(CAST(data AS DECIMAL(24,2)) / CAST(rows_used AS DECIMAL(24,2)) AS DECIMAL(24,4)) AS kb_per_row
FROM #storage_data
WHERE rows_used > 0
AND table_name IN ('fact_order_BIG', 'fact_order_BIG_CCI')
ORDER BY CAST(reserved AS INT) DESC;

DROP TABLE #storage_data;
GO

/********************************************************************************************************************
 **********************************Rowgroup and Segment Metadata*****************************************************
 *******************************************************************************************************************/

 -- Row Groups
SELECT
	tables.name AS table_name,
	indexes.name AS index_name,
	partitions.partition_number,
	column_store_row_groups.row_group_id,
	column_store_row_groups.state_description,
	column_store_row_groups.total_rows,
	column_store_row_groups.size_in_bytes
FROM sys.column_store_row_groups
INNER JOIN sys.indexes
ON indexes.index_id = column_store_row_groups.index_id
AND indexes.object_id = column_store_row_groups.object_id
INNER JOIN sys.tables
ON tables.object_id = indexes.object_id
INNER JOIN sys.partitions
ON partitions.partition_number = column_store_row_groups.partition_number
AND partitions.index_id = indexes.index_id
AND partitions.object_id = tables.object_id
WHERE tables.name = 'fact_order_BIG_CCI'
ORDER BY tables.object_id, indexes.index_id, column_store_row_groups.row_group_id;

-- Segments - This is the key metadata used to simplify execution plans and greatly speed up queries!
SELECT
	tables.name AS table_name,
	indexes.name AS index_name,
	columns.name AS column_name,
	partitions.partition_number,
	column_store_segments.*
FROM sys.column_store_segments
INNER JOIN sys.partitions
ON column_store_segments.hobt_id = partitions.hobt_id
INNER JOIN sys.indexes
ON indexes.index_id = partitions.index_id
AND indexes.object_id = partitions.object_id
INNER JOIN sys.tables
ON tables.object_id = indexes.object_id
INNER JOIN sys.columns
ON tables.object_id = columns.object_id
AND column_store_segments.column_id = columns.column_id
WHERE tables.name = 'fact_order_BIG_CCI'
ORDER BY columns.name, column_store_segments.segment_id;

/********************************************************************************************************************
 ***********************************Columnstore Data Order***********************************************************
 *******************************************************************************************************************/

SELECT
	tables.name AS table_name,
	indexes.name AS index_name,
	columns.name AS column_name,
	partitions.partition_number,
	column_store_segments.segment_id,
	column_store_segments.min_data_id,
	column_store_segments.max_data_id,
	column_store_segments.row_count
FROM sys.column_store_segments
INNER JOIN sys.partitions
ON column_store_segments.hobt_id = partitions.hobt_id
INNER JOIN sys.indexes
ON indexes.index_id = partitions.index_id
AND indexes.object_id = partitions.object_id
INNER JOIN sys.tables
ON tables.object_id = indexes.object_id
INNER JOIN sys.columns
ON tables.object_id = columns.object_id
AND column_store_segments.column_id = columns.column_id
WHERE tables.name = 'fact_order_BIG_CCI'
AND columns.name = 'Order Date Key'
ORDER BY tables.name, columns.name, column_store_segments.segment_id;

SELECT
	SUM([Quantity])
FROM dbo.fact_order_BIG_CCI
WHERE [Order Date Key] >= '1/1/2016'
AND [Order Date Key] < '2/1/2016';

CREATE TABLE dbo.fact_order_BIG_CCI_ORDERED (
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
	[Lineage Key] [int] NOT NULL);

CREATE CLUSTERED INDEX CCI_fact_order_BIG_CCI_ORDERED ON dbo.fact_order_BIG_CCI_ORDERED ([Order Date Key]);

INSERT INTO dbo.fact_order_BIG_CCI_ORDERED
SELECT
	 [Order Key] + (250000 * ([Day Number] + ([Calendar Month Number] * 31))) AS [Order Key]
    ,[City Key]
    ,[Customer Key]
    ,[Stock Item Key]
    ,[Order Date Key]
    ,[Picked Date Key]
    ,[Salesperson Key]
    ,[Picker Key]
    ,[WWI Order ID]
    ,[WWI Backorder ID]
    ,[Description]
    ,[Package]
    ,[Quantity]
    ,[Unit Price]
    ,[Tax Rate]
    ,[Total Excluding Tax]
    ,[Tax Amount]
    ,[Total Including Tax]
    ,[Lineage Key]
FROM Fact.[Order]
CROSS JOIN
Dimension.Date
WHERE Date.Date <= '2013-04-10';

-- Use MAPDOP = 1 to ensure that parallelism does not affect data order when the index is built.  We want it in a single ordered thread.
-- Since we do not build columnstore indexes from scratch often, the potential added time is 100% worth the wait.
CREATE CLUSTERED COLUMNSTORE INDEX CCI_fact_order_BIG_CCI_ORDERED ON dbo.fact_order_BIG_CCI_ORDERED WITH (MAXDOP = 1, DROP_EXISTING = ON);
GO

SELECT
	SUM([Quantity])
FROM dbo.fact_order_BIG_CCI_ORDERED
WHERE [Order Date Key] >= '1/1/2016'
AND [Order Date Key] < '2/1/2016';

SELECT
	tables.name AS table_name,
	indexes.name AS index_name,
	columns.name AS column_name,
	partitions.partition_number,
	column_store_segments.segment_id,
	column_store_segments.min_data_id,
	column_store_segments.max_data_id,
	column_store_segments.row_count
FROM sys.column_store_segments
INNER JOIN sys.partitions
ON column_store_segments.hobt_id = partitions.hobt_id
INNER JOIN sys.indexes
ON indexes.index_id = partitions.index_id
AND indexes.object_id = partitions.object_id
INNER JOIN sys.tables
ON tables.object_id = indexes.object_id
INNER JOIN sys.columns
ON tables.object_id = columns.object_id
AND column_store_segments.column_id = columns.column_id
WHERE tables.name = 'fact_order_BIG_CCI_ORDERED'
AND columns.name = 'Order Date Key'
ORDER BY tables.name, columns.name, column_store_segments.segment_id;

-- Compare table sizes
CREATE TABLE #storage_data
(	table_name VARCHAR(MAX),
	rows_used BIGINT,
	reserved VARCHAR(50),
	data VARCHAR(50),
	index_size VARCHAR(50),
	unused VARCHAR(50));

INSERT INTO #storage_data
	(table_name, rows_used, reserved, data, index_size, unused)
EXEC sp_MSforeachtable "EXEC sp_spaceused '?'";

UPDATE #storage_data
	SET reserved = LEFT(reserved, LEN(reserved) - 3),
		data = LEFT(data, LEN(data) - 3),
		index_size = LEFT(index_size, LEN(index_size) - 3),
		unused = LEFT(unused, LEN(unused) - 3);
SELECT
	table_name,
	rows_used,
	reserved / 1024 AS data_space_reserved_mb,
	data / 1024 AS data_space_used_mb,
	index_size / 1024 AS index_size_mb,
	unused AS free_space_kb,
	CAST(CAST(data AS DECIMAL(24,2)) / CAST(rows_used AS DECIMAL(24,2)) AS DECIMAL(24,4)) AS kb_per_row
FROM #storage_data
WHERE rows_used > 0
AND table_name IN ('fact_order_BIG', 'fact_order_BIG_CCI', 'fact_order_BIG_CCI_ORDERED')
ORDER BY CAST(reserved AS INT) DESC;

DROP TABLE #storage_data;
GO

