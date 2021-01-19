USE WideWorldImportersDW;
SET STATISTICS IO ON;
GO

/*	Segment 5. Optimizing Data Load Processes

	Loading data from a transactional environment into an analytic environment forms the first step in creating analytic data.
	This segment discusses common data load methods, as well as ways to improve performance.
*/

SELECT
	*
INTO #StagingData
FROM OPENQUERY([PRODSERVER01], '
	SELECT
       OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate,
       CustomerPurchaseOrderNumber, IsUndersupplyBackordered, PickingCompletedWhen, LastEditedBy, LastEditedWhen
	FROM Sales.Orders');
GO

SELECT
	*
INTO #StagingData
FROM OPENQUERY([PRODSERVER01], '
	SELECT
       OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate,
       CustomerPurchaseOrderNumber, IsUndersupplyBackordered, PickingCompletedWhen, LastEditedBy, LastEditedWhen
	FROM Sales.Orders')
WHERE OrderDate >= '11/17/2020';
GO

SELECT
	*
INTO #StagingData
FROM OPENQUERY([PRODSERVER01], '
	SELECT
       OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate,
       CustomerPurchaseOrderNumber, IsUndersupplyBackordered, PickingCompletedWhen, LastEditedBy, LastEditedWhen
	FROM Sales.Orders
	WHERE OrderDate >= ''11/17/2020'';');
GO

DECLARE @SqlCommand NVARCHAR(MAX);
DECLARE @OrderDate VARCHAR(MAX) = '11/17/2020';
SELECT
	@SqlCommand = '
		SELECT
			*
		INTO #StagingData
		FROM OPENQUERY([PRODSERVER01], ''
			SELECT
			   OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate,
			   CustomerPurchaseOrderNumber, IsUndersupplyBackordered, PickingCompletedWhen, LastEditedBy, LastEditedWhen
			FROM Sales.Orders
			WHERE OrderDate >= ''''' + @OrderDate + ''''';'');';
EXEC sp_executesql @SqlCommand;
GO

DECLARE @SqlCommand NVARCHAR(MAX);
DECLARE @LastModifiedDate VARCHAR(MAX) = '11/15/2020';
SELECT
	@SqlCommand = '
		SELECT
			*
		INTO #StagingData
		FROM OPENQUERY([PRODSERVER01], ''
			SELECT
			   OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate,
			   CustomerPurchaseOrderNumber, IsUndersupplyBackordered, PickingCompletedWhen, LastEditedBy, LastEditedWhen
			FROM Sales.Orders
			WHERE LastModifiedDate >= ''''' + @LastModifiedDate + ''''';'');';
EXEC sp_executesql @SqlCommand;
GO

CREATE TABLE dbo.TestCompression
(	TestID INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_TestCompression PRIMARY KEY CLUSTERED,
	EntityName VARCHAR(50) NOT NULL,
	CreateTime DATETIME2(3) NOT NULL,
	LastModifiedTime DATETIME2(3) NULL)
WITH (DATA_COMPRESSION = PAGE);

SELECT
	*
INTO dbo.Order_Uncompressed
FROM Fact.[Order]

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
AND table_name IN ('Order', 'Order_Uncompressed')
ORDER BY CAST(reserved AS INT) DESC;

DROP TABLE #storage_data;
GO

ALTER TABLE [dbo].[Order_Uncompressed] REBUILD WITH (DATA_COMPRESSION = PAGE, ONLINE = ON);
GO

DROP TABLE Order_Uncompressed;

INSERT INTO Fact.[Order_Audit]
SELECT
	*
FROM OPENQUERY([PRODSERVER01], '
	SELECT
       OrderID, City, Customer, SalespersonPerson, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate,
       CustomerPurchaseOrderNumber, IsUndersupplyBackordered, PickingCompletedWhen, LastEditedBy, LastEditedWhen
	FROM Sales.Orders
	WHERE OrderDate >= ''11/17/2020'';') REMOTE_DATA
LEFT JOIN Fact.[Order]
ON [Order].[Order Key] = REMOTE_DATA.OrderID
INNER JOIN Dimension.City
ON City.City = REMOTE_DATA.City
INNER JOIN Dimension.Customer
ON Customer.Customer = REMOTE_DATA.City
INNER JOIN Dimension.Employee
ON Employee.Employee = REMOTE_DATA.SalespersonPerson
WHERE [Order].[Order Key] IS NOT NULL
AND [Order].[Tax Rate] IS NOT NULL
AND [Order].[Tax Rate] >= 0.05;

INSERT INTO Fact.[Order_Audit]
SELECT
	*
FROM OPENQUERY([PRODSERVER01], '
	SELECT
       OrderID, City, Customer, SalespersonPerson, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate,
       CustomerPurchaseOrderNumber, IsUndersupplyBackordered, PickingCompletedWhen, LastEditedBy, LastEditedWhen
	FROM Sales.Orders_Audit_Staging
	WHERE OrderDate >= ''11/17/2020''
	AND [Order Key] IS NOT NULL
	AND [Tax Rate] IS NOT NULL
	AND [Tax Rate] >= 0.05;
	;') REMOTE_DATA;