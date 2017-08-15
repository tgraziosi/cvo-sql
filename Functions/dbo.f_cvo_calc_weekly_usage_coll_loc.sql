SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM dbo.f_cvo_calc_weekly_usage_coll_loc('o','bcbg', null) AS fccwuc
-- SELECT * FROM dbo.f_cvo_calc_weekly_usage_coll('o','bcbg') AS fccwuc

CREATE FUNCTION [dbo].[f_cvo_calc_weekly_usage_coll_loc]
    (
      @usg_option CHAR(1) = 'o' ,
      @coll VARCHAR(20) = NULL, -- pass null to report all collections
	  @loc VARCHAR(12) = NULL -- pass null to report all locations
    )
RETURNS @usage TABLE
    (
      location VARCHAR(12) ,
      part_no VARCHAR(40) ,
      usg_option CHAR(1) ,
      asofdate DATETIME ,
      e4_wu INT ,
      e12_wu INT ,
      e26_wu INT ,
      e52_wu INT ,
      subs_exist INT ,
      subs_w4 INT ,
      subs_w12 INT ,
      promo_w4 INT ,
      promo_w12 INT ,

      rx_w4 INT ,
      rx_w12 INT -- 12/5/2016
      ,
      ret_w4 INT ,
      ret_w12 INT -- 12/28/2016 - for new SbS
      ,
      wty_w4 INT ,
      wty_w12 INT, -- 12/28/2016 - for new SbS

	-- 032017 - show gross rx% not net
	  gross_w4 INT,
	  gross_w12 INT
	)

-- 10/21/2015 - add substitute and promo qtys for material forecast
-- 12/5/2016 - add rx qty for inv forecast
-- 1/5/2017 - for credits use the date_entered only not the allocation date

-- select * From dbo.f_cvo_calc_weekly_usage_COLL ( 'O', 'bcbg' ) where part_no like 'CVCLI%'

AS
    BEGIN


/* 

Weekly Usage FOR Demand Planning
	Based on Shipments
	Based on Orders

select * from dbo.f_cvo_calc_weekly_usage_coll ('O', null)

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

        INSERT  @usage
                ( location ,
                  part_no ,
                  usg_option ,
                  asofdate ,
                  e4_wu ,
                  e12_wu ,
                  e26_wu ,
                  e52_wu ,
                  subs_w4 ,
                  subs_w12 ,
                  promo_w4 ,
                  promo_w12 ,
                  rx_w4 ,
                  rx_w12 ,
                  ret_w4 ,
                  ret_w12 ,
                  wty_w4 ,
                  wty_w12,
				  gross_w4,
				  gross_w12
                )
                SELECT  location ,
                        part_no ,
                        @usg_option usg_option ,
                        @asofdate ASofdate
--, usg_w4  = CEILING ( SUM(CASE WHEN bucket <= 4 THEN  qty_shipped ELSE 0 END) / 4 )
--, usg_w12 = ceiling ( SUM(CASE WHEN bucket <= 12 THEN qty_shipped ELSE 0 END) / 12 )
--, usg_w26 = ceiling ( SUM(CASE WHEN bucket <= 26 THEN qty_shipped ELSE 0 END) / 26 )
--, usg_w52 = CEILING ( SUM(CASE WHEN bucket <= 52 THEN qty_shipped ELSE 0 END) / 52 )
                        ,
                        usg_w4 = CAST (SUM(CASE WHEN bucket <= 4
                                                THEN qty_shipped
                                                ELSE 0
                                           END) / 4 AS INT) ,
                        usg_w12 = CAST (SUM(CASE WHEN bucket <= 12
                                                 THEN qty_shipped
                                                 ELSE 0
                                            END) / 12 AS INT) ,
                        usg_w26 = CAST (SUM(CASE WHEN bucket <= 26
                                                 THEN qty_shipped
                                                 ELSE 0
                                            END) / 26 AS INT) ,
                        usg_w52 = CAST (SUM(CASE WHEN bucket <= 52
                                                 THEN qty_shipped
                                                 ELSE 0
                                            END) / 52 AS INT) ,
                        subs_w4 = CAST (SUM(CASE WHEN bucket <= 4
                                                 THEN subs_qty
                                                 ELSE 0
                                            END) AS INT) ,
                        subs_w12 = CAST (SUM(CASE WHEN bucket <= 12
                                                  THEN subs_qty
                                                  ELSE 0
                                             END) AS INT) ,
                        promo_w4 = CAST (SUM(CASE WHEN bucket <= 4
                                                  THEN promo_qty
                                                  ELSE 0
                                             END) AS INT) ,
                        promo_w12 = CAST (SUM(CASE WHEN bucket <= 12
                                                   THEN promo_qty
                                                   ELSE 0
                                              END) AS INT) ,
                        rx_w4 = CAST (SUM(CASE WHEN bucket <= 4 THEN rx_qty
                                               ELSE 0
                                          END)  AS INT) ,
                        rx_w12 = CAST (SUM(CASE WHEN bucket <= 12 THEN rx_qty
                                                ELSE 0
                                           END) AS INT) ,
                        ret_w4 = CAST (SUM(CASE WHEN bucket <= 4 THEN ret_qty ELSE 0
                                           END)  AS INT) ,
                        ret_w12 = CAST (SUM(CASE WHEN bucket <= 12 THEN ret_qty ELSE 0
                                            END)  AS INT) ,
                        wty_w4 = CAST (SUM(CASE WHEN bucket <= 4 THEN wty_Qty ELSE 0
                                           END) AS INT) ,
                        wty_w12 = CAST (SUM(CASE WHEN bucket <= 12 THEN wty_Qty
                                                 ELSE 0
                                            END) AS INT),
						gross_w4 = CAST (SUM(CASE WHEN bucket <= 4 THEN gross_Qty ELSE 0
                                           END) AS INT) ,
                        gross_w12 = CAST (SUM(CASE WHEN bucket <= 12 THEN gross_Qty
                                                 ELSE 0
                                            END) AS INT)
                FROM    ( SELECT    ol.location ,
                                    part_no = ol.part_no ,
                                    subs_qty = 0 , -- ISNULL( subs.quantity, 0) ,
                                    promo_qty = CASE WHEN ISNULL(promo_id, '') > ''
                                                     THEN CASE
                                                              WHEN type = 'i'
                                                              THEN CASE
                                                              WHEN @usg_option = 's'
                                                              THEN ISNULL(shipped,
                                                              0)
                                                              ELSE ISNULL(ordered,
                                                              0)
                                                              END
                                                              ELSE CASE
                                                              WHEN @usg_option = 's'
                                                              THEN ISNULL(cr_shipped,
                                                              0)
                                                              ELSE ISNULL(cr_ordered,
                                                              0)
                                                              END * -1
                                                          END
                                                     ELSE 0
                                                END ,
												-- rx qty is based on sales only, no returns -- 032017
                                    rx_qty = CASE WHEN ISNULL(o.user_category,'ST') LIKE 'RX%' AND type = 'i'
                                                            THEN CASE
                                                              WHEN @usg_option = 'S'
                                                              THEN ISNULL(shipped,
                                                              0)
                                                              ELSE ISNULL(ordered,
                                                              0)
                                                              END
                                                        ELSE 0
                                             END ,
                                    ret_qty = 0 ,
                                    wty_Qty = 0 ,
                                    qty_shipped = CASE WHEN type = 'i'
                                                       THEN CASE
                                                              WHEN @usg_option = 's'
                                                              THEN ISNULL(shipped,
                                                              0)
                                                              ELSE ISNULL(ordered,
                                                              0)
                                                            END
                                                       ELSE CASE
                                                              WHEN @usg_option = 's'
                                                              THEN ISNULL(cr_shipped,
                                                              0)
                                                              ELSE ISNULL(cr_ordered,
                                                              0)
                                                            END * -1
                                                  END ,
				                     gross_qty =   CASE WHEN type = 'i'
                                                       THEN CASE
                                                              WHEN @usg_option = 's'
                                                              THEN ISNULL(shipped,
                                                              0)
                                                              ELSE ISNULL(ordered,
                                                              0)
                                                            END
                                                       ELSE 0 
													end,
									 -- 1/5/2017 - for credits use the date_entered not the allocation date
                                    bucket = CASE WHEN CASE WHEN @usg_option = 'S'
                                                            THEN o.date_shipped
                                                            ELSE CASE WHEN o.type = 'I' THEN
																ISNULL(co.allocation_date,o.date_entered)
																ELSE o.date_entered end
                                                       END >= @w4 THEN 4
                                                  WHEN CASE WHEN @usg_option = 'S'
                                                            THEN o.date_shipped
                                                            ELSE CASE WHEN o.type = 'I' THEN
																ISNULL(co.allocation_date,o.date_entered)
																ELSE o.date_entered end
                                                       END >= @w12 THEN 12
                                                  WHEN CASE WHEN @usg_option = 'S'
                                                            THEN o.date_shipped
                                                            ELSE CASE WHEN o.type = 'I' THEN
																ISNULL(co.allocation_date,o.date_entered)
																ELSE o.date_entered end
                                                       END >= @w26 THEN 26
                                                  WHEN CASE WHEN @usg_option = 'S'
                                                            THEN o.date_shipped
                                                            ELSE CASE WHEN o.type = 'I' THEN
																ISNULL(co.allocation_date,o.date_entered)
																ELSE o.date_entered end
                                                       END >= @w52 THEN 52
                                                  ELSE 99
                                             END
                          FROM      inv_master i ( NOLOCK )
                                    JOIN ord_list ol ( NOLOCK ) ON ol.part_no = i.part_no
                                    INNER JOIN orders o ( NOLOCK ) ON o.order_no = ol.order_no
                                                              AND o.ext = ol.order_ext
                                    INNER JOIN dbo.CVO_orders_all co ( NOLOCK ) ON co.ext = o.ext
                                                              AND co.order_no = o.order_no
                          WHERE     i.category = ISNULL(@coll, i.category)
									AND ol.location = ISNULL(@loc, ol.location) -- 07/31/2017
                                    AND o.status <> 'V'
                        -- AND o.date_entered >= @w52
                                    AND ( CASE WHEN @usg_option = 's'
                                               THEN o.date_shipped
                                               ELSE ISNULL(co.allocation_date,
                                                           o.date_entered)
                                          END ) BETWEEN @w52
                                                AND     @asofdate
                                    AND o.who_entered <> ( CASE
                                                              WHEN @usg_option = 's'
                                                              THEN ''
                                                              ELSE 'BACKORDR'
                                                           END )
                          UNION ALL
              -- old part number
                          SELECT    t.location ,
                                    part_no = LTRIM(RTRIM(SUBSTRING(data,
                                                              CHARINDEX(': ',
                                                              data, 1) + 2,
                                                              CHARINDEX('replaced',
                                                              data, 1)
                                                              - CHARINDEX(':',
                                                              data, 1) - 2))) ,
                                    subs_qty = -CAST(quantity AS DECIMAL(20, 8)) ,
                                    promo_qty = 0 ,
                                    rx_qty = 0 ,
                                    ret_Qty = 0 ,
                                    wty_qty = 0 ,
									qty_shipped = 0 ,
									gross_qty = 0,
                                    bucket = CASE WHEN t.tran_date >= @w4
                                                  THEN 4
                                                  WHEN t.tran_date >= @w12
                                                  THEN 12
                                                  WHEN t.tran_date >= @w26
                                                  THEN 26
                                                  WHEN t.tran_date >= @w52
                                                  THEN 52
                                                  ELSE 99
                                             END
                          FROM      inv_master i ( NOLOCK )
                                    JOIN tdc_log (NOLOCK) t ON t.part_no = i.part_no
								--INNER JOIN cvo_orders_all co ON co.order_no = t.tran_no AND co.ext = t.tran_ext
								--INNER JOIN orders o ON o.order_no = co.order_no AND o.ext = co.ext
                          WHERE     t.trans = 'SUBSTITUTE PROCESSING'
                                    AND t.tran_date >= @w52
                                    AND i.category = ISNULL(@coll, i.category)
									AND t.location = ISNULL(@loc, t.location)
                          UNION ALL
              -- new part number
                          SELECT    t.location ,
                                    i.part_no ,
                                    subs_qty = CAST(quantity AS DECIMAL(20, 8)) ,
                                    promo_qty = 0 ,
                                    rx_qty = 0 ,
                                    ret_qty = 0 ,
                                    wty_qty = 0 ,
								    qty_shipped = 0 ,
									gross_qty = 0,
                                    bucket = CASE WHEN t.tran_date >= @w4
                                                  THEN 4
                                                  WHEN t.tran_date >= @w12
                                                  THEN 12
                                                  WHEN t.tran_date >= @w26
                                                  THEN 26
                                                  WHEN t.tran_date >= @w52
                                                  THEN 52
                                                  ELSE 99
                                             END
                          FROM      inv_master i ( NOLOCK )
                                    JOIN tdc_log (NOLOCK) t ON t.part_no = i.part_no
								--INNER JOIN cvo_orders_all co ON co.order_no = t.tran_no AND co.ext = t.tran_ext
								--INNER JOIN orders o ON o.order_no = co.order_no AND o.ext = co.ext
                          WHERE     t.trans = 'SUBSTITUTE PROCESSING'
                                    AND t.tran_date >= @w52
                                    AND i.category = ISNULL(@coll, i.category)
									AND t.location = ISNULL(@loc, t.location)
                          UNION ALL
						-- 12/28/2016 FOR SbS
                          SELECT    s.location ,
                                    s.part_no ,
                                    subs_qty = 0 ,
                                    promo_qty = 0 ,
                                    rx_qty = 0 ,
                                    ret_qty = SUM(CASE WHEN s.return_code <> 'EXC'
                                                       THEN s.qreturns
                                                       ELSE 0
                                                  END) ,
                                    wty_qty = SUM(CASE WHEN s.return_code = 'WTY'
                                                       THEN s.qreturns
                                                       ELSE 0
                                                  END) ,
								    qty_shipped = 0 ,
									gross_qty = 0,
                                    bucket = CASE WHEN s.yyyymmdd >= @w4
                                                  THEN 4
                                                  WHEN s.yyyymmdd >= @w12
                                                  THEN 12
                                                  ELSE 99
                                             END
                          FROM      inv_master i
                                    JOIN cvo_sbm_details s ON s.part_no = i.part_no
                          WHERE     i.category = ISNULL(@coll, i.category)
									AND s.location = ISNULL(@loc, s.location)
                                    AND s.yyyymmdd >= @w12
                          GROUP BY  CASE WHEN s.yyyymmdd >= @w4 THEN 4
                                         WHEN s.yyyymmdd >= @w12 THEN 12
                                         ELSE 99
                                    END ,
                                    s.location ,
                                    s.part_no
                        ) usage
                WHERE   usage.location IS NOT NULL
                        AND usage.part_no IS NOT NULL
                GROUP BY usage.location ,
                        usage.part_no;
    --ORDER BY location ,
    --        part_no;

        RETURN;
    END;







GO
