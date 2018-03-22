SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi
-- Create date: 10/27/2014
-- Description:	New & Reactivated Account Incentive ScoreCard  (by SHIPPED ) <>*<>*<>*<>*<>*<>*<>*<>*<>*<>
-- EXEC CVO_NewReaIncentiv43_SP '01/01/2017','09/29/2017'

--insert into cvo_new_reactive_temp1 
--EXEC  CVO_NewReaIncentive4_SP
--12/2/2014 - ADDED PARAMETER FOR DESIGNATION CODE WILCARD SEARCH
-- 3/9/2018 - add parent code
-- =============================================
CREATE PROCEDURE [dbo].[CVO_NewReaIncentive3_SP]
    @DateFrom DATETIME = NULL ,
    @DateTo DATETIME = NULL ,
    @desig VARCHAR(10) = NULL
AS
    BEGIN
        SET NOCOUNT ON;

  --      Declare @DateFrom datetime
  --      Declare @DateTo DATETIME
  --      DECLARE @desig VARCHAR(10)
  --      Set @DateFrom = '01/1/2017' 
  --      Set @DateTo = '09/29/2017'
		--SET @desig = NULL

        IF @DateFrom IS NULL
            SELECT @DateFrom = DATEADD(
                                   dd ,
                                   -1,
                                   DATEADD(
                                       YEAR ,-1, DATEDIFF(dd, 0, GETDATE()))); -- year - 1
        IF @DateTo IS NULL
            SELECT @DateTo = DATEADD(dd, -1, DATEDIFF(dd, 0, GETDATE())); -- today

        SET @DateTo = DATEADD(SECOND, -1, DATEADD(D, 1, @DateTo));
        --  select @DateFrom, @DateTo, (dateadd(day,-1,dateadd(year,1,@DateFrom))), dateadd(year,-1,@DateFrom) , dateadd(day,-1,@DateFrom)

        -- select @datefrom, @dateto
        -- BUILD REP DATA
        IF ( OBJECT_ID('tempdb.dbo.#SlpInfo') IS NOT NULL )
            DROP TABLE dbo.#SlpInfo;
        SELECT   dbo.calculate_region_fn(territory_code) Region ,
                 territory_code AS Terr ,
                 salesperson_name AS Salesperson ,
                 ISNULL(date_of_hire, '1/1/1950') date_of_hire ,
                 CASE WHEN date_of_hire
                           BETWEEN @DateFrom AND DATEADD(
                                                     DAY ,
                                                     -1,
                                                     DATEADD(YEAR, 1, @DateFrom)) THEN
                          DATEPART(
                              YEAR ,
                              DATEADD(DAY, -1, DATEADD(YEAR, 1, @DateFrom)))
                      WHEN date_of_hire
                           BETWEEN DATEADD(YEAR, -1, @DateFrom) AND DATEADD(
                                                                        DAY ,
                                                                        -1,
                                                                        @DateFrom) THEN
                          DATEPART(YEAR, DATEADD(DAY, -1, @DateFrom))
                      ELSE
                          ISNULL(
                              DATEPART(YEAR, date_of_hire) ,
                              DATEPART(YEAR, DATEADD(DAY, -1, @DateFrom)))
                 END AS ClassOf ,
                 CASE WHEN date_of_hire
                           BETWEEN @DateFrom AND ( DATEADD(
                                                       DAY ,
                                                       -1,
                                                       DATEADD(
                                                           YEAR ,1, @DateFrom))) THEN
                          'Newbie'
                      WHEN date_of_hire
                           BETWEEN DATEADD(YEAR, -1, @DateFrom) AND DATEADD(
                                                                        DAY ,
                                                                        -1,
                                                                        @DateFrom) THEN
                          'Rookie'
                      WHEN salesperson_name LIKE '%DEFAULT%'
                           OR salesperson_name LIKE '%COMPANY%' THEN 'Empty'
                      WHEN date_of_hire > @DateFrom THEN 'Newbie'
                      ELSE 'VETERAN'
                 END AS Status
        INTO     #SlpInfo
        FROM     arsalesp
        WHERE    status_type = 1
                 AND territory_code NOT LIKE '%00'
                 AND salesperson_name <> 'Alanna Martin'
        ORDER BY territory_code;
        --  select * from #SlpInfo


        -- -- # STOCK ORDERS PER MONTH  
        -- PULL DATA FOR ST SHIPPED ORDERS / CREDITS OVER 5PCS
        IF ( OBJECT_ID('tempdb.dbo.#Invoices') IS NOT NULL )
            DROP TABLE #Invoices;


        SELECT   o.type ,
                 o.status ,
                 car.door ,
                 ar.territory_code ,
                 o.cust_code ,
                 CASE WHEN car.door = 1 THEN o.ship_to ELSE '' END ship_to , -- 10/6/2017
                 co.promo_id ,
                 o.user_category ,
                 o.order_no ,
                 o.ext ,
                 CASE WHEN o.type = 'I' THEN SUM(ordered)
                      ELSE SUM(cr_shipped) * -1
                 END AS QTY ,
                 CASE WHEN o.type = 'I' THEN 1
                      ELSE -1
                 END AS cnt ,
                 added_by_date ,
                 DATEADD(DAY, DATEDIFF(DAY, 0, o.date_shipped), 0) date_shipped ,
                 DATEADD(mm, DATEDIFF(MONTH, 0, o.date_shipped), 0) period ,
                 MONTH(date_shipped) AS X_MONTH
        INTO     #invoices
        FROM     orders_all ( NOLOCK ) o
                 JOIN ord_list ( NOLOCK ) ol ON o.order_no = ol.order_no
                                                AND o.ext = ol.order_ext
                 JOIN inv_master ( NOLOCK ) i ON ol.part_no = i.part_no
                 JOIN armaster ( NOLOCK ) ar ON o.cust_code = ar.customer_code
                                                AND o.ship_to = ar.ship_to_code
                 JOIN CVO_armaster_all ( NOLOCK ) car ON o.cust_code = car.customer_code
                                                         AND o.ship_to = car.ship_to
                 JOIN CVO_orders_all ( NOLOCK ) co ON o.order_no = co.order_no
                                                      AND o.ext = co.ext
        WHERE    o.status = 't'
                 AND date_shipped <= @DateTo
                 AND type = 'I'
                 AND o.who_entered <> 'backordr'
                 -- and (order_ext=0 OR o.who_entered = 'outofstock')
                 AND type_code IN ( 'sun', 'frame' )
                 AND user_category NOT LIKE 'rx%'
                 AND user_category NOT IN ( 'ST-RB', 'DO' )
        GROUP BY ar.territory_code ,
                 door ,
                 cust_code ,
                 CASE WHEN car.door = 1 THEN o.ship_to ELSE '' END ,
                 co.promo_id ,
                 user_category ,
                 o.order_no ,
                 o.ext ,
                 o.status ,
                 o.type ,
                 added_by_date ,
                 date_shipped;

        -- select * from #Invoices   where cust_code = '012845' and type='i' and 
        --
        -- REACTIVATED -- -- PULL Last & 2nd Last ST Order
        IF ( OBJECT_ID('tempdb.dbo.#DATA') IS NOT NULL )
            DROP TABLE #DATA;

        SELECT   ar.territory_code AS Territory ,
                 ar.customer_code ,
                 ship_to_code ,
                 car.door ,
                 added_by_date ,
                 -- SUM(S.NETSALES) YTDNET,

                 -- tag  -- Find the first ST qualified in the reporting period, and the previous one.  
                 -- Then find the difference between the two to see if it's going to be a new or reactivated customer.

                 --[FirstST_new] = 	(SELECT TOP 1 DATE_SHIPPED FROM #INVOICES t11 
                 --		WHERE Type='i' and QTY >=5 AND T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE 
                 --		and date_shipped >= @datefrom ORDER BY DATE_SHIPPED asc) ,

                 -- match to scorecard calculations

                 FirstST_new = (   SELECT MIN(date_shipped)
                                   FROM   #invoices inv
                                   WHERE  type = 'i'
                                          AND QTY >= 5
                                          -- AND date_shipped >= @DateFrom
										  AND date_shipped BETWEEN @datefrom AND @dateto
                                          AND inv.cust_code = ar.customer_code
                                          AND inv.ship_to = ar.ship_to_code ) ,

                 --[LastST] = 
                 --	(SELECT TOP 1 DATE_SHIPPED FROM #INVOICES t11 
                 --		WHERE Type='i' and QTY >=5 AND T11.CUST_CODE=ar.customer_code AND T11.SHIP_TO=ar.SHIP_TO_CODE 
                 --		ORDER BY DATE_SHIPPED DESC) ,

                 PrevST_new = (   SELECT MAX(date_shipped)
                                  FROM   #invoices t11
                                  WHERE  type = 'i'
                                         AND t11.date_shipped < (   SELECT MIN(inv.date_shipped)
                                                                    FROM   #invoices inv
                                                                    WHERE  type = 'i'
                                                                           AND QTY >= 5
                                                                           -- AND date_shipped >= @DateFrom
																		   AND date_shipped BETWEEN @datefrom AND @dateto
                                                                           AND inv.cust_code = ar.customer_code
                                                                           AND inv.ship_to = ar.ship_to_code )
                                         AND QTY >= 5
                                         AND t11.cust_code = ar.customer_code
                                         AND t11.ship_to = ar.ship_to_code )
        INTO     #DATA
        FROM     armaster ar ( NOLOCK )
                 JOIN CVO_armaster_all car ( NOLOCK ) ON ar.customer_code = car.customer_code
                                                         AND ar.ship_to_code = car.ship_to
        -- join cvo_rad_shipto s (nolock)  on right(s.customer,5)=right(ar.customer_code,5) and s.ship_to=ar.ship_to_code
        WHERE    ar.address_type <> 9
                 AND car.door = 1
        -- AND yyyymmdd BETWEEN @DateFrom AND @DateTo
        GROUP BY ar.territory_code ,
                 ar.customer_code ,
                 ar.ship_to_code ,
                 car.door ,
                 ar.added_by_date;
        --  select * from #Data where customer_code = '047859' order by territory, customer_code 

        IF ( OBJECT_ID('tempdb.dbo.#DATA2') IS NOT NULL )
            DROP TABLE #DATA2;
        SELECT T1.Territory ,
               T1.customer_code ,
               T1.ship_to_code ,
               T1.door ,
               T1.added_by_date ,
               T1.FirstST_new ,
               T1.PrevST_new ,
               CASE WHEN DATEDIFF(D, PrevST_new, FirstST_new) > 365
                         AND FirstST_new > @DateFrom
                         AND added_by_date < @DateFrom
                         AND ISNULL(PrevST_new, 0) <> 0 THEN 'REA'
                    ELSE ''
               END AS STAT_new ,
               CASE WHEN DATEDIFF(D, PrevST_new, FirstST_new) > 365
                         AND FirstST_new > @DateFrom
                         AND added_by_date < @DateFrom THEN
                        ISNULL(MONTH(PrevST_new), 1)
                    ELSE ''
               END AS X_MONTH_new
        INTO   #DATA2
        FROM   #DATA T1;
        --  select * from #Data2 where customer_code like '047859'
        -- select * from #Data2 where STAT='REA'

        IF ( OBJECT_ID('tempdb.dbo.#DATA3') IS NOT NULL )
            DROP TABLE #DATA3;
        SELECT t2.Region ,
               t2.Terr ,
               t2.Salesperson ,
               t2.date_of_hire ,
               t2.ClassOf ,
               t2.Status ,
               t1.Territory ,
               t1.customer_code ,
               t1.ship_to_code ,
               t1.Door ,
               t1.added_by_date ,
               t1.FirstST_new ,
               t1.PrevST_new ,
               t1.StatusType
        INTO   #DATA3
        FROM   (   SELECT Territory ,
                          customer_code ,
                          ship_to_code ,
                          CASE WHEN door = 1 THEN 'Y'
                               ELSE ''
                          END AS Door ,
                          added_by_date ,
                          FirstST_new ,
                          PrevST_new ,
                          STAT_new AS StatusType
                   FROM   #DATA2 T5
                   WHERE  Door = '1'
                          AND STAT_new = 'REA'
                   UNION ALL
                   SELECT Territory ,
                          customer_code ,
                          ship_to_code ,
                          CASE WHEN door = 1 THEN 'Y'
                               ELSE ''
                          END AS Door ,
                          added_by_date ,
                          FirstST_new ,
                          PrevST_new ,
                          'NEW' AS StatusType
                   FROM   #DATA2 t5
                   WHERE  (   added_by_date >= @DateFrom
                              AND FirstST_new >= @DateFrom )
                          OR (   FirstST_new >= @DateFrom
                                 AND ISNULL(PrevST_new, 0) = 0 )) t1
               FULL OUTER JOIN #SlpInfo t2 ON t1.Territory = t2.Terr;

        -- Get Designation Codes, into one field  (Where Designations date range is in report date range
        IF ( OBJECT_ID('tempdb.dbo.#desig') IS NOT NULL )
            DROP TABLE dbo.#desig;
        WITH C
        AS ( SELECT customer_code ,
                    code
             FROM   cvo_cust_designation_codes ( NOLOCK ))
        SELECT DISTINCT customer_code ,
               STUFF((   SELECT '; ' + code
                         FROM   cvo_cust_designation_codes ( NOLOCK )
                         WHERE  customer_code = C.customer_code
                                AND ISNULL(start_date, @DateTo) <= @DateTo
                                AND ISNULL(end_date, @DateTo) >= @DateTo
                         FOR XML PATH('')) ,
                     1 ,
                     1 ,
                     '') AS designations
        INTO   #desig
        FROM   C;

        -- Get Primary for each Customer
        IF ( OBJECT_ID('tempdb.dbo.#Primary') IS NOT NULL )
            DROP TABLE dbo.#Primary;
        SELECT customer_code ,
               code ,
               start_date ,
               end_date
        INTO   #Primary
        FROM   cvo_cust_designation_codes ( NOLOCK )
        WHERE  primary_flag = 1
               AND start_date <= @DateTo
               AND ISNULL(end_date, @DateTo) >= @DateTo;

        -- select * from #Primary

          SELECT   DISTINCT d.Region,
                            d.Terr,
                            d.Salesperson,
                            d.date_of_hire,
                            d.ClassOf,
                            d.Status,
                            d.Territory,
                            d.customer_code,
                            d.ship_to_code,
                            d.Door,
                            d.added_by_date,
                            d.FirstST_new,
                            d.PrevST_new,
                            d.StatusType ,
                         ISNULL(LTRIM(RTRIM(de.designations)), '') AS Designations ,
                         ISNULL(p.code, '') AS PriDesig,
						 ISNULL(NA.PARENT,'') AS Parent -- 3/9/2018
                FROM     #DATA3 d
                         LEFT OUTER JOIN #desig de ON de.customer_code = d.customer_code
                         LEFT OUTER JOIN #Primary p ON p.customer_code = d.customer_code
						 LEFT OUTER JOIN dbo.ARNAREL NA (NOLOCK) ON NA.CHILD = DE.customer_code
                WHERE    1 = 1
                         AND ISNULL(Terr, '') <> ''
						 AND DE.designations LIKE 
							CASE WHEN ISNULL(@desig,'*ALL*') = '*ALL*' 
								THEN DE.designations 
								ELSE '%' + ISNULL(@desig, '') + '%'
								END

                ORDER BY Terr;


    -- EXEC CVO_NewReaIncentive3_SP '1/1/2014','11/1/2014'
    -- tempdb..sp_help #data3


    END;



GO
GRANT EXECUTE ON  [dbo].[CVO_NewReaIncentive3_SP] TO [public]
GO
