USE WideWorldImportersDW;
SET STATISTICS IO ON;
GO

/*	Segment 8. Caching Challenging Metrics for Quick Retrieval

	Introduce the caching of important data as an optimization to time-sensitive processes.
*/

SELECT
	Date.[Calendar Year],
	Date.[Calendar Month Number],
	COUNT(*) AS OrderCount,
	COUNT(DISTINCT [Customer Key]) AS DistinctCustomerCount,
	AVG(CAST(DATEDIFF(DAY, [Order Date Key], [Picked Date Key]) AS DECIMAL(18,2))) AS AverageDaysFromOrderToPicked,
	SUM(Quantity) AS TotalQuantity,
	AVG([Unit Price]) AS AverageUnitPrice,
	AVG(LEN(Description)) AS AverageDescriptionLength
FROM Fact.[Order]
INNER JOIN Dimension.Date
ON Date.Date = [Order].[Order Date Key]
WHERE [Order].[Order Date Key] >= '5/1/2015'
AND [Order].[Order Date Key] < '6/1/2016'
GROUP BY Date.[Calendar Year], Date.[Calendar Month Number]
ORDER BY Date.[Calendar Year], Date.[Calendar Month Number];

CREATE TABLE Fact.MonthlyOrderMetrics
(	[Calendar Year] INT NOT NULL,
	[Calendar Month Number] INT NOT NULL,
	OrderCount INT NOT NULL,
	DistinctCustomerCount INT NOT NULL,
	AverageDaysFromOrderToPicked DECIMAL(18,2) NOT NULL,
	TotalQuantity INT NOT NULL,
	AverageUnitPrice DECIMAL(18,2) NOT NULL,
	AverageDescriptionLength INT NOT NULL,
	CONSTRAINT PK_MonthlyOrderMetrics PRIMARY KEY CLUSTERED ([Calendar Year], [Calendar Month Number]));

INSERT INTO Fact.MonthlyOrderMetrics
	([Calendar Year], [Calendar Month Number], OrderCount, DistinctCustomerCount, AverageDaysFromOrderToPicked, TotalQuantity,
	 AverageUnitPrice, AverageDescriptionLength)
SELECT
	Date.[Calendar Year],
	Date.[Calendar Month Number],
	COUNT(*) AS OrderCount,
	COUNT(DISTINCT [Customer Key]) AS DistinctCustomerCount,
	AVG(CAST(DATEDIFF(DAY, [Order Date Key], [Picked Date Key]) AS DECIMAL(18,2))) AS AverageDaysFromOrderToPicked,
	SUM(Quantity) AS TotalQuantity,
	AVG([Unit Price]) AS AverageUnitPrice,
	AVG(LEN(Description)) AS AverageDescriptionLength
FROM Fact.[Order]
INNER JOIN Dimension.Date
ON Date.Date = [Order].[Order Date Key]
GROUP BY Date.[Calendar Year], Date.[Calendar Month Number]
ORDER BY Date.[Calendar Year], Date.[Calendar Month Number];

SELECT
	*
FROM Fact.MonthlyOrderMetrics;

ALTER TABLE Fact.MonthlyOrderMetrics ADD DistinctPickerCount INT;
ALTER TABLE Fact.MonthlyOrderMetrics ADD DistinctStockItemCount INT;

WITH CTE_NEW_METRICS AS (
	SELECT
		Date.[Calendar Year],
		Date.[Calendar Month Number],
		COUNT(DISTINCT [Picker Key]) AS DistinctPickerCount,
		COUNT(DISTINCT [Stock Item Key]) AS DistinctStockItemCount
	FROM Fact.[Order]
	INNER JOIN Dimension.Date
	ON Date.Date = [Order].[Order Date Key]
	GROUP BY Date.[Calendar Year], Date.[Calendar Month Number])
UPDATE MonthlyOrderMetrics
	SET DistinctPickerCount = CTE_NEW_METRICS.DistinctPickerCount,
		DistinctStockItemCount = CTE_NEW_METRICS.DistinctStockItemCount
FROM Fact.MonthlyOrderMetrics
INNER JOIN CTE_NEW_METRICS
ON CTE_NEW_METRICS.[Calendar Year] = MonthlyOrderMetrics.[Calendar Year]
AND CTE_NEW_METRICS.[Calendar Month Number] = MonthlyOrderMetrics.[Calendar Month Number];

SELECT
	*
FROM Fact.MonthlyOrderMetrics;
GO

CREATE SCHEMA ReportData;
GO

CREATE TABLE ReportData.WeeklySalesRecapReport
(	ReportDate DATE NOT NULL CONSTRAINT PK_WeeklySalesRecapReport PRIMARY KEY CLUSTERED,
	OrderCount INT NOT NULL,
	DistinctCityCount INT NOT NULL,
	TotalQuantity INT NOT NULL,
	BackorderedQuantity INT NOT NULL,
	AverageDaysFromOrderToPicked DECIMAL(18,2) NOT NULL)

INSERT INTO ReportData.WeeklySalesRecapReport
	(ReportDate, OrderCount, DistinctCityCount, TotalQuantity, BackorderedQuantity, AverageDaysFromOrderToPicked)
SELECT
	MAX([Order].[Order Date Key]) AS ReportDate,
	COUNT(*) AS OrderCount,
	COUNT(DISTINCT [Order].[City Key]) AS DistinctCityCount,
	SUM([Order].Quantity) AS TotalQuantity,
	SUM(CASE WHEN [Order].[WWI Backorder ID] IS NOT NULL THEN 1 ELSE 0 END) AS BackorderedQuantity,
	AVG(CAST(DATEDIFF(DAY, [Order Date Key], [Picked Date Key]) AS DECIMAL(18,2))) AS AverageDaysFromOrderToPicked
FROM [Fact].[Order]
INNER JOIN Dimension.Date
ON Date.Date = [Order].[Order Date Key]
GROUP BY Date.[Calendar Year], Date.[Calendar Month Number], Date.[ISO Week Number]
ORDER BY Date.[Calendar Year], Date.[Calendar Month Number], Date.[ISO Week Number]

SELECT
	*
FROM ReportData.WeeklySalesRecapReport;

-- Cleanup
DROP TABLE Fact.MonthlyOrderMetrics;
DROP TABLE ReportData.WeeklySalesRecapReport;
DROP SCHEMA ReportData;
