USE WideWorldImporters;
SET STATISTICS IO ON;
GO
/*	Segment 3. Assigning Business Goals and Meaning to Data

	How to model data by involving stakeholders and answer organizational questions using it.

	To effectively design, use, and optimize any data store, understanding the underlying meaning of that data is critical.  Who is this data
	for and what are the goals and objectives of collecting it?  What questions will need to be answered now and what will be expected
	in the future?  An extended discussion with organizational leaders is necessary to answer these questions and build the analytic data store that
	answers their questions effectively.
*/
GO

SELECT TOP 25
	*
FROM Sales.Orders;

SELECT TOP 25
	OrderID,
	Customers.CustomerName,
	People.FullName,
	OrderDate,
	ExpectedDeliveryDate,
	CustomerPurchaseOrderNumber
FROM Sales.Orders
INNER JOIN Application.People
ON People.PersonID = Orders.SalespersonPersonID
INNER JOIN Sales.Customers
ON Customers.CustomerID = Orders.CustomerID;

SELECT TOP 25
	OrderLines.OrderLineID,
	OrderLines.OrderID,
	OrderLines.Description,
	OrderLines.Quantity,
	OrderLines.UnitPrice
FROM Sales.OrderLines;

CREATE TABLE dbo.OrdersBySalesPerson
(	OrderDate DATE NOT NULL,
	SalespersonPersonID INT NOT NULL,
	LineItemCount INT NOT NULL,
	OrderCount INT NOT NULL,
	SalesTotal DECIMAL(18,2) NOT NULL,
	AverageDeliveryTimeDays DECIMAL(10,2) NOT NULL,
	CONSTRAINT PK_OrdersBySalesPerson PRIMARY KEY CLUSTERED (OrderDate, SalespersonPersonID));

SELECT
	Orders.OrderDate AS OrderDate,
	Orders.SalespersonPersonID,
	COUNT(*) AS LineItemCount,
	COUNT(DISTINCT Orders.OrderID) AS OrderCount,
	SUM(OrderLines.UnitPrice) AS SalesTotal,	
	AVG(DATEDIFF(DAY, Orders.OrderDate, Orders.ExpectedDeliveryDate)) AS AverageDeliveryTimeDays
FROM Sales.Orders
INNER JOIN Sales.OrderLines
ON OrderLines.OrderID = Orders.OrderID
WHERE Orders.OrderDate = '5/31/2016'
GROUP BY Orders.OrderDate, Orders.SalespersonPersonID;

SELECT
	Orders.OrderDate AS OrderDate,
	Orders.SalespersonPersonID,
	COUNT(*) AS LineItemCount,
	COUNT(DISTINCT Orders.OrderID) AS OrderCount,
	SUM(OrderLines.UnitPrice) AS SalesTotal,	
	AVG(DATEDIFF(DAY, Orders.OrderDate, Orders.ExpectedDeliveryDate)) AS AverageDeliveryTimeDays
FROM Sales.Orders
INNER JOIN Sales.OrderLines
ON OrderLines.OrderID = Orders.OrderID
WHERE Orders.OrderDate >= '5/1/2016' AND Orders.OrderDate <= '5/31/2016'
GROUP BY Orders.OrderDate, Orders.SalespersonPersonID
ORDER BY Orders.OrderDate, Orders.SalespersonPersonID;

SELECT
	DATEPART(YEAR, Orders.OrderDate) AS Order_Year,
	DATEPART(MONTH, Orders.OrderDate) AS Order_Month,
	Orders.SalespersonPersonID,
	COUNT(*) AS LineItemCount,
	COUNT(DISTINCT Orders.OrderID) AS OrderCount,
	SUM(OrderLines.UnitPrice) AS SalesTotal,	
	AVG(DATEDIFF(DAY, Orders.OrderDate, Orders.ExpectedDeliveryDate)) AS AverageDeliveryTimeDays
FROM Sales.Orders
INNER JOIN Sales.OrderLines
ON OrderLines.OrderID = Orders.OrderID
WHERE Orders.OrderDate >= '1/1/2016' AND Orders.OrderDate <= '12/31/2016'
GROUP BY DATEPART(YEAR, Orders.OrderDate), DATEPART(MONTH, Orders.OrderDate), Orders.SalespersonPersonID
ORDER BY DATEPART(YEAR, Orders.OrderDate), DATEPART(MONTH, Orders.OrderDate), Orders.SalespersonPersonID;

SELECT
	Orders.OrderDate AS OrderDate,
	Orders.SalespersonPersonID,
	COUNT(*) AS LineItemCount,
	COUNT(DISTINCT Orders.OrderID) AS OrderCount,
	SUM(OrderLines.UnitPrice) AS SalesTotal,	
	AVG(DATEDIFF(DAY, Orders.OrderDate, Orders.ExpectedDeliveryDate)) AS AverageDeliveryTimeDays,
	SUM(CASE WHEN Orders.BackorderOrderID IS NULL THEN 0 ELSE 1 END) AS BackorderCount,
	COUNT(DISTINCT Orders.ContactPersonID) AS DistinctContacts,
	SUM(CASE WHEN Orders.LastEditedWhen > Orders.ExpectedDeliveryDate THEN 1 ELSE 0 END) AS EditsAfterDelivery,
	COUNT(DISTINCT OrderLines.StockItemID) AS DistinctItemCount,
	AVG(OrderLines.TaxRate) AS AverageTaxRate,
	SUM(OrderLines.PickedQuantity) AS TotalQuantity,
	MAX(OrderLines.LastEditedWhen) AS MostRecentLineItemEdit
FROM Sales.Orders
INNER JOIN Sales.OrderLines
ON OrderLines.OrderID = Orders.OrderID
WHERE Orders.OrderDate >= '5/1/2016' AND Orders.OrderDate <= '5/31/2016'
GROUP BY Orders.OrderDate, Orders.SalespersonPersonID
ORDER BY Orders.OrderDate, Orders.SalespersonPersonID;
