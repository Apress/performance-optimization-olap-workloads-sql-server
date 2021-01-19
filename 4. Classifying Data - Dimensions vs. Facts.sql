USE WideWorldImportersDW;
SET STATISTICS IO ON;
/*	Segment 4. Classifying Data - Dimensions vs. Facts

	A discussion of how to classify data in order to make for its most effective use.  Facts, dimensions, and more!
*/
GO

SELECT TOP 100
	*
FROM Fact.[Order];

SELECT TOP 100
	*
FROM Dimension.City;

SELECT
	*
FROM Dimension.City
WHERE [WWI City ID] = 5450;

SELECT
	*
FROM Dimension.City
WHERE [Valid From] <= '5/1/2013'
AND [Valid To] >= '5/1/2013';

SELECT TOP 10 *
FROM Dimension.Customer;
SELECT TOP 10 *
FROM Dimension.[Stock Item];
SELECT TOP 10 *
FROM Dimension.Date;
SELECT TOP 10 *
FROM Dimension.Employee;

SELECT
	THIS_MONTH.[Salesperson Key],
	ISNULL(SUM(LAST_MONTH.Quantity * LAST_MONTH.[Unit Price]), 0) AS SalesLastMonth,
	ISNULL(SUM(THIS_MONTH.Quantity * THIS_MONTH.[Unit Price]), 0) AS SalesThisMonth,
	ISNULL(SUM(THIS_MONTH.Quantity * THIS_MONTH.[Unit Price]), 0) - ISNULL(SUM(LAST_MONTH.Quantity * LAST_MONTH.[Unit Price]), 0) AS SalesDeltaMonthOverMonth,
	COUNT(*) AS TotalDataPoints
FROM Fact.[Order] THIS_MONTH
FULL JOIN Fact.[Order] LAST_MONTH
ON LAST_MONTH.[Salesperson Key] = THIS_MONTH.[Salesperson Key]
WHERE THIS_MONTH.[Order Date Key] >= '5/1/2013' AND THIS_MONTH.[Order Date Key] < '6/1/2013'
AND LAST_MONTH.[Order Date Key] >= '4/1/2013' AND LAST_MONTH.[Order Date Key] < '5/1/2013'
GROUP BY THIS_MONTH.[Salesperson Key];

SELECT
	[Employee],
	COUNT(*)
FROM Dimension.Employee
WHERE Employee.[Is Salesperson] = 1
AND Employee.[Valid From] >= '5/1/2016'
AND Employee.[Valid From] < '6/1/2016'
GROUP BY [Employee]
ORDER BY [Employee];

SELECT
	*
FROM fact.[Stock Holding]
INNER JOIN Dimension.[Stock Item]
ON [Stock Item].[Stock Item Key] = [Stock Holding].[Stock Item Key];

