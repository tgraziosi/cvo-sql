SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_ifp_config_update_sp] @brand VARCHAR(1024), @tier VARCHAR(10)
, @NewThresh INT = NULL
, @NewOrderA DATETIME = NULL, @NewOrderB DATETIME = NULL, @NewOrderC DATETIME = NULL

AS 
BEGIN

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

CREATE TABLE #brand ([brand] VARCHAR(20))
begin
	INSERT INTO #brand ([brand])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@brand)
	UNION ALL SELECT 'SUN'
END

CREATE TABLE #tier ([tier] VARCHAR(1))
begin
	INSERT INTO #tier ([tier])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@tier)
END

IF @NewThresh IS NOT null
UPDATE cic SET 
 threshold = isnull(@newthresh,threshold), 
 -- order_thru_date = ISNULL(@NewOrderThruDate,order_thru_date),
 asofdate = GETDATE()
FROM cvo_ifp_config cic
JOIN #brand b ON b.brand = cic.brand
JOIN #tier AS t ON t.tier = cic.tier
WHERE cic.threshold <> ISNULL(@NewThresh,cic.threshold) 
--   OR cic.order_thru_date <> ISNULL(@NewOrderThruDate,cic.order_thru_date)

IF @NewOrderA IS NOT NULL
UPDATE cic SET 
order_thru_date = ISNULL(@NewOrderA, order_thru_date),
asofdate = GETDATE()
FROM cvo_ifp_config cic
JOIN #brand b ON b.brand = cic.brand
WHERE cic.tier = 'A'
AND cic.order_thru_date <> ISNULL(@NewOrderA, cic.order_thru_date)

IF @NewOrderB IS NOT NULL
UPDATE cic SET 
order_thru_date = ISNULL(@neworderB, order_thru_date),
asofdate = GETDATE()
FROM cvo_ifp_config cic
JOIN #brand b ON b.brand = cic.brand
WHERE cic.tier = 'B'
AND cic.order_thru_date <> ISNULL(@NewOrderB, cic.order_thru_date)

IF @NewOrderC IS NOT NULL
UPDATE cic SET 
order_thru_date = ISNULL(@neworderC, order_thru_date),
asofdate = GETDATE()
FROM cvo_ifp_config cic
JOIN #brand b ON b.brand = cic.brand
WHERE cic.tier = 'C'
AND cic.order_thru_date <> ISNULL(@NewOrderC, cic.order_thru_date)

END 
	


GO
GRANT EXECUTE ON  [dbo].[cvo_ifp_config_update_sp] TO [public]
GO
