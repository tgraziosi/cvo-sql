SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create FUNCTION [dbo].[f_cvo_calc_weekly_usage_part_no_loc] 
	(@usg_option CHAR(1)= 's', @location VARCHAR(10), @part_no VARCHAR(40))
	RETURNS @usage TABLE
	(location VARCHAR(12), part_no VARCHAR(40)
	, usg_option CHAR(1), asofdate datetime
	, e4_wu INT, e12_wu INT, e26_wu INT, e52_wu INT
	, subs_exist int
	, subs_w4 INT, subs_w12 INT, promo_w4 INT, promo_w12 int
	)

-- 10/21/2015 - add substitute and promo qtys for material forecast
-- select * From dbo.f_cvo_calc_weekly_usage ( 'S' ) where part_no like 'iz2801%'


AS 

BEGIN


/* 

Weekly Usage FOR Demand Planning
	Based on Shipments
	Based on Orders

select * from dbo.f_cvo_calc_weekly_usage ('O')

-- 10/1/2015 - credits don't have an allocation date.  use date entered instead


*/

-- Figure out week boundaries

-- 4wks
    DECLARE @asofdate DATETIME ,
        @w4 DATETIME ,
        @w12 DATETIME ,
        @w26 DATETIME ,
        @w52 DATETIME;

 --DECLARE @usg_option CHAR(1)
 --SELECT @usg_option = 'o' -- 'o'  s = shipped, o = ordered

    SELECT  @asofdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);
-- SELECT @asofdate

    SELECT  @w4 = DATEADD(WEEK, -4, @asofdate);
    SELECT  @w12 = DATEADD(WEEK, -12, @asofdate);
    SELECT  @w26 = DATEADD(WEEK, -26, @asofdate);
    SELECT  @w52 = DATEADD(WEEK, -52, @asofdate);

-- SELECT @w4, @w12, @w26, @w52

	INSERT @usage (location, part_no,usg_option, asofdate, e4_wu, e12_wu, e26_wu, e52_wu, subs_w4, subs_w12, promo_w4, promo_w12)
    SELECT  location ,
            part_no ,
            @usg_option usg_option ,
            @asofdate ASofdate
--, usg_w4  = CEILING ( SUM(CASE WHEN bucket <= 4 THEN  qty_shipped ELSE 0 END) / 4 )
--, usg_w12 = ceiling ( SUM(CASE WHEN bucket <= 12 THEN qty_shipped ELSE 0 END) / 12 )
--, usg_w26 = ceiling ( SUM(CASE WHEN bucket <= 26 THEN qty_shipped ELSE 0 END) / 26 )
--, usg_w52 = CEILING ( SUM(CASE WHEN bucket <= 52 THEN qty_shipped ELSE 0 END) / 52 )
            ,
            usg_w4 = CAST (SUM(CASE WHEN bucket <= 4 THEN qty_shipped ELSE 0 END) / 4 AS INT) ,
            usg_w12 = CAST (SUM(CASE WHEN bucket <= 12 THEN qty_shipped ELSE 0 END) / 12 AS INT) ,
            usg_w26 = CAST (SUM(CASE WHEN bucket <= 26 THEN qty_shipped ELSE 0 END) / 26 AS INT) ,
            usg_w52 = CAST (SUM(CASE WHEN bucket <= 52 THEN qty_shipped ELSE 0 END) / 52 AS INT),
			subs_w4 =  CAST (SUM(CASE WHEN bucket <= 4 THEN subs_qty ELSE 0 END)  AS INT) ,
			subs_w12 =  CAST (SUM(CASE WHEN bucket <= 12 THEN subs_qty ELSE 0 END)  AS INT) ,
			promo_w4 = CAST (SUM(CASE WHEN bucket <= 4 THEN promo_Qty ELSE 0 END)  AS INT) ,
			promo_w12 = CAST (SUM(CASE WHEN bucket <= 12 THEN promo_qty ELSE 0 END)  AS INT) 
    FROM    ( SELECT    ol.location ,
                        part_no = ol.part_no ,
						subs_qty = 0, -- ISNULL( subs.quantity, 0) ,
									
						promo_qty = CASE WHEN type = 'i' AND ISNULL(promo_id,'') > ''
                                           THEN CASE WHEN @usg_option = 's' THEN ISNULL(shipped, 0) ELSE ISNULL(ordered,0) end
                                           ELSE CASE WHEN @usg_option = 's' THEN ISNULL(cr_shipped, 0) ELSE ISNULL(cr_ordered,0) end * -1
                                      END ,
                        qty_shipped = CASE WHEN type = 'i'
                                           THEN CASE WHEN @usg_option = 's' THEN ISNULL(shipped, 0) ELSE ISNULL(ordered,0) end
                                           ELSE CASE WHEN @usg_option = 's' THEN ISNULL(cr_shipped, 0) ELSE ISNULL(cr_ordered,0) end * -1
                                      END ,
                        bucket = CASE WHEN CASE WHEN @usg_option = 'S'
                                                THEN o.date_shipped
                                                ELSE ISNULL(co.allocation_date,o.date_entered)
                                           END >= @w4 THEN 4
                                      WHEN CASE WHEN @usg_option = 'S'
                                                THEN o.date_shipped
                                                ELSE ISNULL(co.allocation_date,o.date_entered)
                                           END >= @w12 THEN 12
                                      WHEN CASE WHEN @usg_option = 'S'
                                                THEN o.date_shipped
                                                ELSE ISNULL(co.allocation_date,o.date_entered)
                                           END >= @w26 THEN 26
                                      WHEN CASE WHEN @usg_option = 'S'
                                                THEN o.date_shipped
                                                ELSE ISNULL(co.allocation_date,o.date_entered)
                                           END >= @w52 THEN 52
                                      ELSE 99
                                 END
              FROM      ord_list ol ( NOLOCK )
                        INNER JOIN orders o ( NOLOCK ) ON o.order_no = ol.order_no
                                                          AND o.ext = ol.order_ext
						INNER JOIN dbo.CVO_orders_all co (NOLOCK) ON co.ext = o.ext 
														  AND co.order_no = o.order_no
              WHERE     o.status <> 'V'
                        -- AND o.date_entered >= @w52
						AND (CASE WHEN @usg_option = 's' THEN o.date_shipped ELSE ISNULL(co.allocation_date,o.date_entered) END) BETWEEN @w52 AND @asofdate
						AND o.who_entered <> (CASE WHEN @usg_option = 's' THEN '' ELSE 'BACKORDR' END)
			  UNION ALL
              -- old part number
                        SELECT t.location,
							part_no = LTRIM(RTRIM(SUBSTRING(data,
                                            CHARINDEX(': ', data, 1) + 2,
                                            CHARINDEX('replaced', data, 1)
                                            - CHARINDEX(':', data, 1) - 2))) ,
                            subs_qty = -CAST(quantity AS DECIMAL(20,8)),
							promo_qty = 0,
							qty_shipped = 0,
							bucket = CASE WHEN t.tran_date >= @w4 THEN 4
                                      WHEN t.tran_date >= @w12 THEN 12
                                      WHEN t.tran_date >= @w26 THEN 26
                                      WHEN t.tran_date >= @w52 THEN 52
                                      ELSE 99
								     END
                                FROM      tdc_log (NOLOCK) t
								--INNER JOIN cvo_orders_all co ON co.order_no = t.tran_no AND co.ext = t.tran_ext
								--INNER JOIN orders o ON o.order_no = co.order_no AND o.ext = co.ext
                                WHERE     t.trans = 'SUBSTITUTE PROCESSING'
                                AND t.tran_date >= @w52
						UNION ALL
              -- new part number
                        SELECT t.location,
                            part_no ,
							subs_qty = CAST(quantity AS DECIMAL(20,8)),
							promo_qty = 0,
							qty_shipped = 0,
							bucket = CASE WHEN t.tran_date >= @w4 THEN 4
                                      WHEN t.tran_date >= @w12 THEN 12
                                      WHEN t.tran_date >= @w26 THEN 26
                                      WHEN t.tran_date >= @w52 THEN 52
                                      ELSE 99
								     END
                                FROM      tdc_log (NOLOCK) t
								--INNER JOIN cvo_orders_all co ON co.order_no = t.tran_no AND co.ext = t.tran_ext
								--INNER JOIN orders o ON o.order_no = co.order_no AND o.ext = co.ext
                                WHERE     t.trans = 'SUBSTITUTE PROCESSING'
                                AND t.tran_date >= @w52
            ) usage
	WHERE 1=1
	-- AND usage.location IS NOT NULL AND usage.part_no IS NOT null
	AND usage.location = @location AND usage.part_no = @part_no
    GROUP BY usage.location ,
            usage.part_no
    ORDER BY location ,
            part_no;

RETURN
END




GO
