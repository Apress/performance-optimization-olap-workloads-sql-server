USE WideWorldImportersDW;
SET STATISTICS IO ON;
GO
/*	Segment 7. ETL, Validation, and Analyzing Data Sources

	How to maintain the flow of data from a data source to its OLAP destination.  Tips and tricks
	for managing data validation and understanding data sources.  As a bonus, thorough validation
	can uncover problems within the source OLTP application that otherwise might not be detected as
	quickly.
*/

DECLARE @validation_date DATE = '5/7/2016';

SELECT
	COUNT(*) AS order_count,
	SUM(CASE WHEN [Picked Date Key] IS NOT NULL THEN 1 ELSE 0 END) AS order_picked_count,
	COUNT(DISTINCT [Salesperson Key]) AS distinct_salesperson_count,
	SUM(Quantity) AS quantity_total,
	SUM([Total Excluding Tax]) AS total_excluding_tax,
	SUM(CASE WHEN [Order Date Key] <> ISNULL([Picked Date Key], '1/1/1900') THEN 1 ELSE 0 END) AS orders_not_picked_same_day
FROM Fact.[Order]
WHERE [Order Date Key] = @validation_date;
GO

DECLARE @validation_date DATE = '5/7/2016';
DECLARE @compare_to_date DATE = '4/30/2016';
WITH CTE_CURRENT AS (
	SELECT
		COUNT(*) AS order_count_current,
		SUM(CASE WHEN [Picked Date Key] IS NOT NULL THEN 1 ELSE 0 END) AS order_picked_count_current,
		COUNT(DISTINCT [Salesperson Key]) AS distinct_salesperson_count_current,
		SUM(Quantity) AS quantity_total_current,
		SUM([Total Excluding Tax]) AS total_excluding_tax_current,
		SUM(CASE WHEN [Order Date Key] <> ISNULL([Picked Date Key], '1/1/1900') THEN 1 ELSE 0 END) AS orders_not_picked_same_day_current
	FROM Fact.[Order]
	WHERE [Order Date Key] = @validation_date),
CTE_PREVIOUS AS (
	SELECT
		COUNT(*) AS order_count_previous,
		SUM(CASE WHEN [Picked Date Key] IS NOT NULL THEN 1 ELSE 0 END) AS order_picked_count_previous,
		COUNT(DISTINCT [Salesperson Key]) AS distinct_salesperson_count_previous,
		SUM(Quantity) AS quantity_total_previous,
		SUM([Total Excluding Tax]) AS total_excluding_tax_previous,
		SUM(CASE WHEN [Order Date Key] <> ISNULL([Picked Date Key], '1/1/1900') THEN 1 ELSE 0 END) AS orders_not_picked_same_day_previous
	FROM Fact.[Order]
	WHERE [Order Date Key] = @compare_to_date)
SELECT
	CTE_CURRENT.order_count_current - CTE_PREVIOUS.order_count_previous AS order_count_delta,
	100 * CAST(CTE_CURRENT.order_count_current - CTE_PREVIOUS.order_count_previous AS DECIMAL) / CAST(CTE_PREVIOUS.order_count_previous AS DECIMAL) AS order_count_percent_delta,
	CTE_CURRENT.order_picked_count_current - CTE_PREVIOUS.order_picked_count_previous AS order_picked_count_delta,
	100 * CAST(CTE_CURRENT.order_picked_count_current - CTE_PREVIOUS.order_picked_count_previous AS DECIMAL) / CAST(CTE_PREVIOUS.order_picked_count_previous AS DECIMAL) AS order_picked_count_percent_delta,
	CTE_CURRENT.distinct_salesperson_count_current - CTE_PREVIOUS.distinct_salesperson_count_previous AS distinct_salesperson_count_delta,
	100 * CAST(CTE_CURRENT.distinct_salesperson_count_current - CTE_PREVIOUS.distinct_salesperson_count_previous AS DECIMAL) / CAST(CTE_PREVIOUS.distinct_salesperson_count_previous AS DECIMAL) AS distinct_salesperson_count_percent_delta,
	CTE_CURRENT.quantity_total_current - CTE_PREVIOUS.quantity_total_previous AS quantity_total_delta,
	100 * CAST(CTE_CURRENT.quantity_total_current - CTE_PREVIOUS.quantity_total_previous AS DECIMAL) / CAST(CTE_PREVIOUS.quantity_total_previous AS DECIMAL) AS quantity_total_percent_delta,
	CTE_CURRENT.total_excluding_tax_current - CTE_PREVIOUS.total_excluding_tax_previous AS total_excluding_tax_delta,
	100 * CAST(CTE_CURRENT.total_excluding_tax_current - CTE_PREVIOUS.total_excluding_tax_previous AS DECIMAL) / CAST(CTE_PREVIOUS.total_excluding_tax_previous AS DECIMAL) AS total_excluding_tax_percent_delta,
	CTE_CURRENT.orders_not_picked_same_day_current - CTE_PREVIOUS.orders_not_picked_same_day_previous AS orders_not_picked_same_day_delta,
	100 * CAST(CTE_CURRENT.orders_not_picked_same_day_current - CTE_PREVIOUS.orders_not_picked_same_day_previous AS DECIMAL) / CAST(CTE_PREVIOUS.orders_not_picked_same_day_previous AS DECIMAL) AS orders_not_picked_same_day_percent_delta
FROM CTE_CURRENT
CROSS JOIN CTE_PREVIOUS;

SELECT
	*
FROM OPENQUERY([ED_POSTGRES],
'	SELECT
		*
	FROM public.customer_list LIMIT 25;');

SELECT
	MAX(LEN(id)) AS id_length,
	MAX(LEN(name)) AS name_length,
	MAX(LEN(address)) AS address_length,
	MAX(LEN([zip code])) AS zip_code_length,
	MAX(LEN(phone)) AS phone_length,
	MAX(LEN(city)) AS city_length,
	MAX(LEN(country)) AS country_length,
	MAX(LEN(notes)) AS notes_length,
	MAX(LEN(sid)) AS sid_length,
	COUNT(*) AS row_count
FROM OPENQUERY([ED_POSTGRES],
'	SELECT
		*
	FROM public.customer_list;');

CREATE TABLE dbo.customer_list_candidate
(	id INT NOT NULL CONSTRAINT PK_customer_list_candidate PRIMARY KEY CLUSTERED,
	name VARCHAR(50) NOT NULL,
	address VARCHAR(100) NOT NULL,
	zip_code VARCHAR(5) NOT NULL,
	phone VARCHAR(12) NOT NULL,
	city VARCHAR(40) NOT NULL,
	country VARCHAR(60) NOT NULL,
	notes VARCHAR(10) NOT NULL,
	sid SMALLINT NOT NULL);

INSERT INTO dbo.customer_list_candidate
	(id, name, address, zip_code, phone, city, country, notes, sid)
SELECT
	id,
	name,
	address,
	[zip code],
	phone,
	city,
	country,
	notes,
	sid
FROM OPENQUERY([ED_POSTGRES],
'	SELECT
		id,
		name,
		address,
		"zip code",
		phone,
		city,
		country,
		notes,
		sid
	FROM public.customer_list;');

SELECT
	*
FROM dbo.customer_list_candidate;

SELECT
	SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS does_id_have_nulls,
	SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS does_name_have_nulls,
	SUM(CASE WHEN address IS NULL THEN 1 ELSE 0 END) AS does_address_have_nulls,
	SUM(CASE WHEN [zip code] IS NULL THEN 1 ELSE 0 END) AS does_zip_code_have_nulls,
	SUM(CASE WHEN phone IS NULL THEN 1 ELSE 0 END) AS does_phone_have_nulls,
	SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS does_city_have_nulls,
	SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS does_country_have_nulls,
	SUM(CASE WHEN notes IS NULL THEN 1 ELSE 0 END) AS does_notes_have_nulls,
	SUM(CASE WHEN sid IS NULL THEN 1 ELSE 0 END) AS does_sid_have_nulls	
FROM OPENQUERY([ED_POSTGRES],
'	SELECT
		id,
		name,
		address,
		"zip code",
		phone,
		city,
		country,
		notes,
		sid
	FROM public.customer_list;');

-- Cleanup
DROP TABLE dbo.customer_list_candidate;