USE WideWorldImporters;
SET STATISTICS IO ON;
GO
/*	Segment 2. OLAP vs. OLTP - How Do They Differ
	Illustrate transactional and analytic processes and how they differ from each other.
*/
GO

INSERT INTO sales.Orders
	(OrderID, CustomerID, SalespersonPersonID, PickedByPersonID, ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate, CustomerPurchaseOrderNumber,
     IsUndersupplyBackordered, Comments, DeliveryInstructions, InternalComments, PickingCompletedWhen, LastEditedBy, LastEditedWhen)
VALUES
(   420000,        -- OrderID - int
    150,           -- CustomerID - int
    20,            -- SalespersonPersonID - int
    3,             -- PickedByPersonID - int
    1299,          -- ContactPersonID - int
    NULL,          -- BackorderOrderID - int
    '10/21/2020',  -- OrderDate - date
    '10/24/2020',  -- ExpectedDeliveryDate - date
    '17000',       -- CustomerPurchaseOrderNumber - nvarchar(20)
    1,             -- IsUndersupplyBackordered - bit
    NULL,          -- Comments - nvarchar(max)
    NULL,          -- DeliveryInstructions - nvarchar(max)
    NULL,          -- InternalComments - nvarchar(max)
    NULL,          -- PickingCompletedWhen - datetime2(7)
    17,            -- LastEditedBy - int
    SYSDATETIME()  -- LastEditedWhen - datetime2(7)
    );
SELECT
	*
FROM Sales.Orders
WHERE Orders.OrderID = 420000;

UPDATE sales.Orders
	SET DeliveryInstructions = 'Leave at the back of the house by the door.',
		InternalComments = 'Delivery instructions added on 10/22/2020.',
		LastEditedBy = 3,
		LastEditedWhen = SYSDATETIME()
WHERE Orders.OrderID = 420000;
SELECT
	*
FROM Sales.Orders
WHERE Orders.OrderID = 420000;

DELETE
FROM Sales.Orders
WHERE Orders.OrderID = 420000;
SELECT
	*
FROM Sales.Orders
WHERE Orders.OrderID = 420000;

SELECT
	*
FROM Sales.Orders
WHERE Orders.OrderID = 17;

SELECT
	*
FROM Sales.Orders
WHERE Orders.CustomerID = 910
AND Orders.OrderDate >= '1/1/2016'
AND Orders.OrderDate < '1/1/2017';

USE WideWorldImportersDW;
GO

SELECT TOP 25
	*
FROM Fact.[Order];

SELECT
	SUM([Unit Price]) AS [Unit Price],
	SUM([Total Including Tax]) AS [Total Including Tax],
	COUNT(*) AS row_count
FROM Fact.[Order]
WHERE [Order].[Order Date Key] >= '1/1/2014'
AND [Order].[Order Date Key] < '2/1/2014';

