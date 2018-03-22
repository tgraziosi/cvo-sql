SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec daily_order_log_ssrs_sp '03/14/2018'
-- tag 021414 - added qualifying order counts
-- tag 101617 - change so week goes from Sun - Sat instead of Mon - Sun
-- tag 031518 - performance - sniffing

CREATE PROCEDURE [dbo].[Daily_Order_Log_SSRS_sp] @OrderDate DATETIME
AS
BEGIN

    DECLARE @startdate DATETIME, @enddate DATETIME, @ord_date datetime;
    SELECT @ord_date = @OrderDate;

	SELECT @startdate = CONVERT(VARCHAR, DATEADD(dd, 1 - (DATEPART(dw, @ord_date)), @ord_date), 101);
	SELECT @enddate = CONVERT(VARCHAR, DATEADD(dd, (7 - DATEPART(dw, @ord_date)), @ord_date), 101);

    IF (OBJECT_ID('tempdb.dbo.#T1') IS NOT NULL)
        DROP TABLE dbo.#T1;

    /*
declare @orderdate datetime
select @orderdate = '02/05/2014'
*/

    SELECT ol.territory,
           ol.salesperson,
           ol.cust_code,
           ol.ship_to,
           ol.customer_name,
           ol.ORDER_NO,
           ol.date_entered,
           ol.tot_shp_qty,
           ol.status,
           ol.status_desc,
           ol.tot_ord_qty,
           promo_level,
           CASE WHEN promo_id = '' THEN '-' WHEN promo_id IS NULL THEN '-' ELSE promo_id END AS promo_id,
           REPLACE(tracking, ' ', '') AS tracking,
           tot_inv_sales,
           date_shipped,
           DATENAME(dw, ol.date_entered) AS Day_Name,
           DATEPART(WEEKDAY, ol.date_entered) AS Day,
           -- tag - 021414
           ROW_NUMBER() OVER (PARTITION BY ol.cust_code,
                                           DATENAME(dw, ol.date_entered)
                              ORDER BY ol.cust_code,
                                       DATENAME(dw, ol.date_entered)
                             ) AS UC,
           CASE WHEN ol.tot_ord_qty >= 5 THEN 1 ELSE 0 END AS qual_order
    INTO #t1
    FROM dbo.cvo_Daily_Order_Log_detail_vw ol (NOLOCK)
    WHERE date_entered between @startdate AND @enddate
		  AND LEFT(OrderType, 2) = 'ST'
          AND RIGHT(ol.OrderType, 2) NOT IN ( 'RB', 'TB', 'PM' )
          AND who_entered <> 'BACKORDR'




    UPDATE #t1
    SET UC = NULL
    WHERE UC <> 1;

    -- select #t1.uc*#t1.qual_order as qual_order,*  from #t1 order by cust_code, day


    SELECT ISNULL(c.territory_code, ol.territory) AS territory,
           ISNULL(c.salesperson, ol.salesperson) AS salesperson,
           ISNULL(c.Region, dbo.calculate_region_fn(ol.territory)) Region,
           ol.cust_code,
           ol.ship_to,
           ol.customer_name,
           ISNULL(ol.UC * ol.qual_order, 0) AS qual_order,
           ol.ORDER_NO,
           ol.date_entered,
           ol.tot_shp_qty,
           ol.status,
           ol.status_desc,
           ol.tot_ord_qty,
           promo_level,
           CASE WHEN promo_id IS NULL THEN '-' ELSE promo_id END AS promo_id,
           tracking,
           tot_inv_sales,
           date_shipped,
           Day_Name,
           Day
    FROM
    (
    SELECT DISTINCT
           r.territory_code,
           r.salesperson_code AS salesperson,
           dbo.calculate_region_fn(ar.territory_code) AS Region
    -- TAG - UPDATE TAKE TERRITORY/REP FROM ARSALESP INSTEAD - AVOID DUPLICATES
    FROM arsalesp r (NOLOCK)
        -- tg - 2/1/2013 commented out match on sc due to reps having more than 1 territory and don't report
        -- Marcella as a rep
        JOIN armaster ar (NOLOCK)
            ON --r.salesperson_code = ar.salesperson_code and 
            r.territory_code = ar.territory_code -- EL added territory_code match 1/7/2012
    WHERE r.territory_code IS NOT NULL
          AND salesperson_type = 0
          AND r.status_type = 1
          AND
          (
          r.salesperson_code <> 'smithma'
          AND ar.salesperson_code <> 'smithma'
          )
    -- order by r.territory_code
    ) c
        FULL OUTER JOIN #t1 ol
            ON c.territory_code = ol.territory;

-- order by Region,territory,ol.date_entered
END;




GO
