
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author: elabarbera
-- Create date: 7/1/2013
-- Description:, NEW Ranking Customer BILL TO
-- EXEC RankCust_all_sp 'Year To Date','TRUE', null, null, '*all*', 'b'
-- EXEC RankCustBillTo_sp '1/1/2014','12/31/2014','TRUE'
-- EXEC RankCustshipTo_sp '1/1/2014','12/31/2014','TRUE'
-- 12/5/2014 - tag - update RA figures to be only ra returns.  was including wty too
-- 12/19/14 - tag - update ra amounts to exclude RBs
-- 3/2016 - update coop info so there is only one record/per customer
-- -- SF STANDS FOR SUN FRAME ONLY DEFAULT IS ALL
-- =============================================

CREATE PROCEDURE [dbo].[RankCust_all_sp]
	-- @Period VARCHAR(100),
    @DateFrom DATETIME = NULL ,
    @DateTo DATETIME = NULL ,
    @sf VARCHAR(5) = 'TRUE' ,
    @collection VARCHAR(1000) = NULL ,
    @Territory VARCHAR(8000) = NULL ,
	@BuyingGroup VARCHAR(8000) = NULL ,
	@CustOpt CHAR(1) = 'B'  -- B or S

AS
    BEGIN
        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;


-- --  DECLARES
        DECLARE @DateFromTY DATETIME;                                    
        DECLARE @DateToTY DATETIME;
        DECLARE @DateFromLY DATETIME;                    -- don't comment                
        DECLARE @DateToLY DATETIME;                        -- don't comment
--DECLARE @sf  varchar(100)


 ----  SETS
        SET @DateFromTY = ISNULL(@DateFrom, '1/1/2015');
        SET @DateToTY = ISNULL(@DateTo, GETDATE());

		--SELECT @datefromty = begindate , @datetoty = enddate 
		--	FROM dbo.cvo_date_range_vw WHERE period = @Period

        SET @DateToTY = DATEADD(DAY, 1, ( DATEADD(SECOND, -1, @DateToTY) ));  
        SET @DateFromLY = DATEADD(YEAR, -1, @DateFromTY);
        SET @DateToLY = DATEADD(YEAR, -1, @DateToTY); 
--SET @SF = 'TRUE' -- 'SF'


 --  select @dateFrom, @dateto, @datefromly, @datetoly, @collection


-- tag 090914 - use comma list for collections instead of multiple vars
        CREATE TABLE #collection
            (
              [collection] VARCHAR(5)
            );
        IF ( @collection IS NULL )
            BEGIN
                INSERT  INTO #collection
                        ( [collection]
                        )
                        SELECT DISTINCT
                                kys
                        FROM    category
                        WHERE   void = 'n';
            END;
        ELSE
            BEGIN
                INSERT  INTO #collection
                        ( [collection]
                        )
                        SELECT  ListItem
                        FROM    dbo.f_comma_list_to_table(@collection);
            END;

		CREATE TABLE #terr
            (
              terr VARCHAR(8)
            );
        IF ( @territory IS NULL )
            BEGIN
                INSERT  INTO #terr
                        ( terr
                        )
                        SELECT DISTINCT territory_code 
							FROM    dbo.armaster
                        WHERE   1=1;
            END;
        ELSE
            BEGIN
                INSERT  INTO #terr
                        ( terr
                        )
                        SELECT  ListItem
                        FROM    dbo.f_comma_list_to_table(@territory);
            END;

		CREATE TABLE #bg
            (
              bg VARCHAR(8)
            );
        IF ( @BuyingGroup IS NULL OR @BuyingGroup like '%*ALL*%')
            BEGIN
                INSERT  INTO #BG
                        ( bg
                        )
                        SELECT DISTINCT parent 	FROM    arnarel
                INSERT INTO #bg (bg) VALUES ('');
            END;
        ELSE
            BEGIN
                INSERT  INTO #bg
                        ( bg
                        )
                        SELECT  ListItem
                        FROM    dbo.f_comma_list_to_table(@BuyingGroup);
            END;


-- Lookup 0 & 9 affiliated Accounts
        IF ( OBJECT_ID('tempdb.dbo.#Rank_Aff') IS NOT NULL )
            DROP TABLE #Rank_Aff; 
 
        SELECT  a.customer_code AS from_cust ,
                a.affiliated_cust_code AS to_cust
        INTO    #Rank_Aff
        FROM    armaster a ( NOLOCK )
                INNER JOIN armaster b ( NOLOCK ) ON a.affiliated_cust_code = b.customer_code 
        WHERE   a.address_type <> 9
                AND ISNULL(a.affiliated_cust_code, '') <> ''
                AND b.address_type <> 9;
 -- Select * from #Rank_Aff  


-- CLEAN OUT EXTRA DUPLICATE 0 & 9

        IF ( OBJECT_ID('tempdb.dbo.#RankCusts_S3') IS NOT NULL )
            DROP TABLE dbo.#RankCusts_S3;

        SELECT  MIN(ISNULL(Status, '')) Status ,
                MergeCust ,
                -- MIN(ISNULL(customer_code, '')) customer_code ,
                MIN(ISNULL(ship_to, '')) ship_to ,
                MIN(ISNULL(Terr, '')) terr ,
                MAX(ISNULL(Door, '')) Door ,
                MIN(ISNULL(address_name, '')) Address_name ,
                MIN(ISNULL(addr2, '')) addr2 ,
                MIN(ISNULL(addr3, '')) addr3 ,
                MIN(ISNULL(addr4, '')) addr4 ,
                MIN(ISNULL(City, '')) City ,
                MIN(ISNULL(State, '')) State ,
                MIN(ISNULL(Postal_code, '')) Postal_code ,
                MIN(ISNULL(country_code, '')) Country ,
                MIN(ISNULL(contact_name, '')) contact_name ,
                MIN(ISNULL(contact_phone, '')) contact_phone ,
                MIN(ISNULL(tlx_twx, '')) tlx_twx ,
                MIN(ISNULL(contact_email, '')) contact_email ,
                MIN(ISNULL(Designations, '')) Designations ,
                MIN(ISNULL(PriDesig, '')) PriDesig ,
                MIN(start_date) Start_date ,
                MIN(end_date) End_date ,
                MIN(ISNULL(Parent, '')) Parent ,
                MIN(ISNULL(CustType, '')) CustType ,
                MIN(ISNULL(coop_eligible, '')) coop_eligible ,
                MIN(ISNULL(PastDueAmt, 0)) pastdueamt ,
                MIN(ISNULL(price_code, '')) price_code
        INTO    #RankCusts_S3
        FROM   
		(      SELECT  -- t1.customer_code ,
                RIGHT(t1.customer_code, 5) MergeCust ,
                ship_to = CASE WHEN @CustOpt = 'B' THEN ''
                               ELSE t1.ship_to_code
                          END ,
                territory_code AS Terr ,
                Door = CASE WHEN T2.door = 1 THEN 'Y'
                            ELSE ''
                       END ,
                address_name ,
                ISNULL(addr2, '') addr2 ,
                CASE WHEN addr3 LIKE '%, __ %' THEN ''
                     ELSE addr3
                END AS addr3 ,
                CASE WHEN addr4 LIKE '%, __ %' THEN ''
                     ELSE addr4
                END AS addr4 ,
                ISNULL(city, '') City ,
                ISNULL(state, '') State ,
                ISNULL(postal_code, '') Postal_code ,
                ISNULL(country_code, '') country_code ,
                ISNULL(contact_name, '') contact_name ,
                ISNULL(contact_phone, '') contact_phone ,
                ISNULL(tlx_twx, '') tlx_twx ,
                CASE WHEN contact_email IS NULL THEN ''
                     WHEN contact_email LIKE '%@cvoptical%' THEN ''
                     ELSE contact_email
                END AS contact_email ,
                ISNULL(addr_sort1, '') AS CustType ,
                CASE WHEN coop_eligible = '' THEN 'N'
                     ELSE ISNULL(coop_eligible, 'N')
                END AS coop_eligible ,
                ISNULL(AR30 + AR60 + AR90 + AR120 + AR150, 0) PastDueAmt ,
                designations.desig Designations ,
                p.code PriDesig ,
                p.start_date ,
                p.end_date ,
                CASE WHEN t1.customer_code = art.parent THEN ''
                     ELSE art.parent
                END AS Parent ,
                CASE WHEN t1.status_type = 1 THEN 'A'
                     ELSE 'I'
                END AS Status ,
                t1.price_code
              FROM    #terr t
				INNER JOIN armaster t1 ( NOLOCK ) ON t.terr = t1.territory_code
				INNER JOIN artierrl (NOLOCK) art ON art.rel_cust = t1.customer_code
				INNER JOIN #bg ON #bg.bg = CASE WHEN art.rel_cust = art.parent THEN '' ELSE art.parent END
				 
                LEFT OUTER JOIN CVO_armaster_all T2 ON t1.customer_code = T2.customer_code
                                                       AND t1.ship_to_code = T2.ship_to
				LEFT OUTER JOIN SSRS_ARAging_Temp ar ON ar.CUST_CODE = t1.customer_code
                LEFT OUTER JOIN ( SELECT    c.customer_code ,
                                            RIGHT(c.customer_code, 5) MergeCust ,
                                            STUFF(( SELECT  '; ' + code
                                                    FROM    cvo_cust_designation_codes (NOLOCK)
                                                    WHERE   customer_code = c.customer_code
                                                            AND ISNULL(start_date, @DateToTY) <= @DateToTY
                                                            AND ISNULL(end_date, @DateToty) >= @DateToty
                                                  FOR
                                                    XML PATH('')
                                                  ), 1, 1, '') desig
                                  FROM      dbo.cvo_cust_designation_codes (NOLOCK) c
                                ) AS designations ON designations.MergeCust = RIGHT(t1.customer_code,5)
                LEFT OUTER JOIN ( SELECT    customer_code ,
                                            RIGHT(customer_code, 5) MergeCust ,
                                            code ,
                                            start_date ,
                                            end_date
                                  FROM      cvo_cust_designation_codes (NOLOCK)
                                  WHERE     primary_flag = 1
                                            AND ISNULL(start_date, @DateToty) <= @DateToty
                                            AND ( ISNULL(end_date, @DateToty) >= @DateToty )
                                ) AS p ON p.MergeCust = RIGHT(t1.customer_code, 5)    
        WHERE   ( t1.address_type = 0 AND @CustOpt = 'B') or ( t1.address_type IN ( 0, 1 ) AND @CustOpt = 'S' ) 
		) custinfo
        GROUP BY MergeCust ,
                ship_to;

      CREATE CLUSTERED INDEX [idx_rankcust3] ON #RankCusts_S3 (MergeCust, ship_to);

-- SOURCE SALES
        IF ( OBJECT_ID('tempdb.dbo.#sales') IS NOT NULL )
            DROP TABLE dbo.#sales;
        SELECT  RIGHT(customer, 5) MergeCust ,
                t2.customer ,
                ship_to = CASE WHEN @CustOpt = 'B' THEN ''
                               ELSE t2.ship_to
                          END ,
                t2.promo_id ,
                t2.return_code ,
                t2.user_category ,
                t2.yyyymmdd ,
                SUM(ISNULL(t2.asales, 0)) asales ,
                SUM(ISNULL(t2.areturns, 0)) areturns ,
                SUM(ISNULL(t2.anet, 0)) anet ,
                SUM(ISNULL(t2.qsales, 0)) qsales ,
                SUM(ISNULL(t2.qreturns, 0)) qreturns ,
                SUM(ISNULL(t2.qnet, 0)) qnet ,
                SUM(ISNULL(t2.lsales, 0)) lsales ,
                CASE WHEN t2.yyyymmdd BETWEEN @DateFromTY AND @DateToTY
                     THEN 'TY'
                     ELSE 'LY'
                END AS TYLY
        INTO    #sales
        FROM    #collection
                INNER JOIN inv_master (NOLOCK) INV ON INV.category = #collection.[collection]
                INNER JOIN cvo_sbm_details (NOLOCK) t2 ON t2.part_no = INV.part_no
				INNER JOIN armaster ar (NOLOCK) ON t2.customer = ar.customer_code AND t2.ship_to = ar.ship_to_code
				INNER JOIN #terr t ON t.terr = ar.territory_code

        WHERE   ( t2.yyyymmdd BETWEEN @DateFromTY AND @DateToTY
                  OR t2.yyyymmdd BETWEEN @DateFromLY AND @DateToLY
                )
                AND ( ( @sf = 'TRUE'
                        AND type_code LIKE ( '%' )
                      )
                      OR ( @sf = 'SUN'
                           AND type_code = ( 'SUN' )
                         )
                      OR ( @sf = 'FRAME'
                           AND type_code = ( 'FRAME' )
                         )
                      OR ( @sf = 'SF'
                           AND type_code IN ( 'SUN', 'FRAME' )
                         )
                    )
        GROUP BY RIGHT(t2.customer, 5) ,
                CASE WHEN @CustOpt = 'B' THEN ''
                     ELSE t2.ship_to
                END ,
                CASE WHEN t2.yyyymmdd BETWEEN @DateFromTY AND @DateToTY
                     THEN 'TY'
                     ELSE 'LY'
                END ,
                t2.customer ,
                t2.promo_id ,
                t2.return_code ,
                t2.user_category ,
                t2.yyyymmdd;

		CREATE INDEX idx_sales ON #sales (MergeCust, ship_to)

        SET ANSI_WARNINGS OFF;

        DECLARE @PrYr1From DATETIME;
        DECLARE @PrYr1To DATETIME;
        SET @PrYr1From = DATEADD(YEAR,
                                 DATEDIFF(YEAR, 0,
                                          DATEADD(YEAR, -1, @DateFromTY)), 0);
        SET @PrYr1To = DATEADD(MILLISECOND, -3,
                               DATEADD(YEAR,
                                       DATEDIFF(YEAR, 0,
                                                DATEADD(YEAR, -1, @DateToty))
                                       + 1, 0));

        IF ( OBJECT_ID('tempdb.dbo.#P3YRDATA') IS NOT NULL )
            DROP TABLE dbo.#P3YRDATA;
        CREATE TABLE #p3yrdata
            (
              year INT ,
              customer VARCHAR(8) ,
              ship_to VARCHAR(8) ,
              net DECIMAL(20, 8)
            );

        IF @CustOpt = 'B'
            BEGIN
                INSERT  #p3yrdata
                        ( year ,
                          customer ,
                          ship_to ,
                          net
                        )
                        SELECT  c_year AS YEAR ,
                                RIGHT(customer, 5) Customer ,
                                ship_to = '' ,
                                SUM(anet) NET
                        FROM    cvo_sbm_details sbm ( NOLOCK )
                                JOIN inv_master inv ( NOLOCK ) ON sbm.part_no = inv.part_no
                                JOIN #collection ON inv.category = #collection.[collection]
                        WHERE   yyyymmdd BETWEEN DATEADD(yy, -2, @PrYr1From)
                                         AND     @PrYr1To
                        GROUP BY RIGHT(Customer, 5) ,
                                sbm.c_year;
            END;
        IF @CustOpt = 'S'
            BEGIN
                INSERT  #p3yrdata
                        ( year ,
                          customer ,
                          ship_to ,
                          net
                        )
                        SELECT  c_year AS YEAR ,
                                RIGHT(customer, 5) Customer ,
                                sbm.ship_to ,
                                SUM(anet) NET
                        FROM    cvo_sbm_details sbm ( NOLOCK )
                                JOIN inv_master inv ( NOLOCK ) ON sbm.part_no = inv.part_no
                                JOIN #collection ON inv.category = #collection.[collection]
                        WHERE   yyyymmdd BETWEEN DATEADD(yy, -2, @PrYr1From) AND     @PrYr1To
                        GROUP BY RIGHT(Customer, 5) ,
                                sbm.ship_to ,
                                sbm.c_year;
            END;

			CREATE INDEX idx_py3 ON #p3yrdata (customer, ship_to) INCLUDE (year, NET)

        IF ( OBJECT_ID('tempdb.dbo.#R12') IS NOT NULL )
            DROP TABLE dbo.#R12;
        SELECT  Customer ,
                ship_to ,
                SUM(RetSRaTY_R12) RetSRaTY_R12 ,
                SUM(GrossNoBepSTY_R12) GrossNoBepSTY_R12 ,
                SUM(RetURaTY_R12) RetURaTY_R12 ,
                SUM(GrossNoBepUTY_R12) GrossNoBepUTY_R12 ,
                Years
        INTO    #R12
        FROM    
		(SELECT  RIGHT(customer, 5) Customer ,
                ship_to = CASE WHEN @CustOpt = 'B' THEN ''
                               ELSE t1.ship_to
                          END ,
                CASE WHEN promo_id <> 'BEP' THEN ISNULL(SUM(asales), 0)
                     ELSE 0
                END AS GrossNoBepSTY_R12 ,
                CASE WHEN return_code /*<> 'EXC'*/ = ''
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSRaTY_R12 ,
                CASE WHEN promo_id <> 'BEP'
                          AND type_code IN ( 'SUN', 'FRAME' )
                     THEN ISNULL(SUM(qsales), 0)
                     ELSE 0
                END AS GrossNoBepUTY_R12 ,
                CASE WHEN return_code /*<> 'EXC'*/ = ''
                          AND type_code IN ( 'SUN', 'FRAME' )
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetURaTY_R12 ,
                CASE WHEN yyyymmdd BETWEEN DATEADD(YEAR, -2,
                                                   DATEADD(dd, 1,
                                                           DATEDIFF(dd, 0,
                                                              @DateToty)))
                                   AND     DATEADD(YEAR, -1, @DateToty)
                     THEN 'LY'
                     ELSE 'TY'
                END AS Years
        from    cvo_sbm_details t1 ( NOLOCK )
                INNER JOIN inv_master t2 ( NOLOCK ) ON t1.part_no = t2.part_no
        WHERE   yyyymmdd BETWEEN DATEADD(YEAR, -2,
                                         DATEADD(dd, 1,
                                                 DATEDIFF(dd, 0, @DateToTY)))
                         AND     @DateToTY
        GROUP BY Customer ,
                CASE WHEN @CustOpt = 'B' THEN ''
                     ELSE t1.ship_to
                END ,
                promo_id ,
                return_code ,
                type_code ,
                yyyymmdd

		) r12data
		GROUP BY Customer ,
                ship_to ,
                Years;

        CREATE INDEX [idx_r12] ON #R12 (Customer, ship_to) INCLUDE  (Years);

-- select * from #R12


        IF ( OBJECT_ID('tempdb.dbo.#coopdata') IS NOT NULL )
            DROP TABLE dbo.#coopdata;
        CREATE TABLE [dbo].[#coopdata]
            (
              [territory_code] [VARCHAR](8) NULL ,
              [salesperson_code] [VARCHAR](8) NULL ,
              [customer_code] [VARCHAR](5) NULL ,
              [customer_name] [VARCHAR](40) NULL ,
              [coop_threshold_amount] [DECIMAL](20, 8) NULL ,
              [coop_cust_rate] [DECIMAL](20, 8) NULL ,
              [desig_code] [VARCHAR](10) NULL ,
              [yyear] [INT] NOT NULL ,
              [coop_sales] [DECIMAL](38, 8) NOT NULL ,
              [coop_earned] [DECIMAL](38, 6) NULL ,
              [coop_redeemed] [FLOAT] NOT NULL
            )
        ON  [PRIMARY];

        INSERT  INTO #coopdata
                EXEC cvo_coop_status_sp;
-- SELECT * FROM #COOPDATA where customer_code = '18422'
        CREATE INDEX [idx_COOP] ON #coopdata (customer_code) INCLUDE (yyear);


        IF ( OBJECT_ID('tempdb.dbo.#RXEFREIGHT') IS NOT NULL ) DROP TABLE #RXEFREIGHT;

-- Free Freight Invoices
        SELECT  t1.order_no ,
                RIGHT(t1.cust_code, 5) Cust_code ,
                ship_to = CASE WHEN @CustOpt = 'B' THEN ''
                               ELSE t1.ship_to
                          END ,
                 ( SELECT TOP 1
                            code
                  FROM      cvo_cust_designation_codes CD
                  WHERE     code IN ( 'RXE', 'RX3', 'RX5' )
                            AND ( ISNULL(end_date, @DateToTY) >= @DateToty )
                            AND RIGHT(t1.cust_code, 5) = RIGHT(CD.customer_code,5)
                  ORDER BY  start_date DESC
                ) RxDesig ,
                dbo.f_cvo_FreightRateLookup(T1.routing, LEFT(t1.ship_to_zip, 5),
                                            T4.cs_dim_weight) AS UnchargedRates
        INTO    #RXEFREIGHT
        FROM    orders_all t1 ( NOLOCK )
                INNER JOIN CVO_armaster_all T2 ( NOLOCK ) ON t1.cust_code = T2.customer_code
                                                             AND t1.ship_to = T2.ship_to
                INNER JOIN CVO_orders_all t3 ( NOLOCK ) ON t1.order_no = t3.order_no
                                                           AND t1.ext = t3.ext
                INNER JOIN tdc_carton_tx t4 ( NOLOCK ) ON t1.order_no = t4.order_no
                                                          AND t1.ext = t4.order_ext

        WHERE   ISNULL(t3.promo_id, '') IN ( 'RXE', 'RX3', 'RX5' )
                AND t1.status = 't'
                AND t1.tot_ord_freight = 0
                AND t1.routing NOT IN ( 'hold', 'slp' )
                AND ISNULL(t1.freight_allow_type, '') NOT IN ( 'collect', 'thrdprty' )
                AND t1.date_shipped BETWEEN @DateFromTY AND @DateToTY
                AND type = 'I'
				AND t1.who_entered <> 'backordr'
		GROUP BY T1.order_no,
				 RIGHT(t1.cust_code, 5) ,
                 CASE WHEN @CustOpt = 'B' THEN ''
                 ELSE t1.ship_to
                 END  ,
				  dbo.f_cvo_FreightRateLookup(T1.routing, LEFT(t1.ship_to_zip, 5),
                                            T4.cs_dim_weight)  

		CREATE INDEX idx_rxe ON #RXEFREIGHT (Cust_code, ship_to, RxDesig)  


        IF ( OBJECT_ID('tempdb.dbo.#FinalData1') IS NOT NULL )
            DROP TABLE dbo.#FinalData1;

		WITH salesdata AS 
		(
        SELECT  t1.MergeCust AS customer ,
                t1.ship_to ,
				-- SALES
                CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(anet), 0)
                     ELSE 0
                END AS NetSTY ,
                CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(anet), 0)
                     ELSE 0
                END AS NetSLY ,
                CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(lsales), 0)
                     ELSE 0
                END AS ListSTY ,
                CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(lsales), 0)
                     ELSE 0
                END AS ListSLY ,
                CASE WHEN TYLY = 'TY'
                          AND user_category LIKE 'RX%'
                     THEN ISNULL(SUM(anet), 0)
                     ELSE 0
                END AS NetSRXTY ,
                CASE WHEN TYLY <> 'TY'
                          AND user_category LIKE 'RX%'
                     THEN ISNULL(SUM(anet), 0)
                     ELSE 0
                END AS NetSRXLY ,
                CASE WHEN TYLY = 'TY'
                          AND user_category NOT LIKE 'RX%'
                     THEN ISNULL(SUM(anet), 0)
                     ELSE 0
                END AS NetSSTTY ,
                CASE WHEN TYLY <> 'TY'
                          AND user_category NOT LIKE 'RX%'
                     THEN ISNULL(SUM(anet), 0)
                     ELSE 0
                END AS NetSSTLY ,
                CASE WHEN TYLY = 'TY'
                          AND return_code <> 'EXC'
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSTY ,
                CASE WHEN TYLY <> 'TY'
                          AND return_code <> 'EXC'
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSLY ,
                CASE WHEN TYLY = 'TY'
                          AND return_code /*<> 'EXC'*/ = ''
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSRaTY ,
                CASE WHEN TYLY <> 'TY'
                          AND return_code /*<> 'EXC'*/ = ''
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSRaLY ,
                CASE WHEN TYLY = 'TY'
                          AND user_category LIKE 'RX%'
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSRXTY ,
                CASE WHEN TYLY <> 'TY'
                          AND user_category LIKE 'RX%'
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSRXLY ,
                CASE WHEN TYLY = 'TY'
                          AND user_category NOT LIKE 'RX%'
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSSTTY ,
                CASE WHEN TYLY <> 'TY'
                          AND user_category NOT LIKE 'RX%'
                     THEN -1 * ISNULL(SUM(areturns), 0)
                     ELSE 0
                END AS RetSSTLY ,
                CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(asales), 0)
                     ELSE 0
                END AS GrossSTY ,
                CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(asales), 0)
                     ELSE 0
                END AS GrossSLY ,
                CASE WHEN TYLY = 'TY'
                          AND promo_id <> 'BEP' THEN ISNULL(SUM(asales), 0)
                     ELSE 0
                END AS GrossNoBepSTY ,
                CASE WHEN TYLY <> 'TY'
                          AND promo_id <> 'BEP' THEN ISNULL(SUM(asales), 0)
                     ELSE 0
                END AS GrossNoBepSLY ,
-- UNITS
                CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qnet), 0)
                     ELSE 0
                END AS NetUTY ,
                CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(qnet), 0)
                     ELSE 0
                END AS NetULY ,
                CASE WHEN TYLY = 'TY'
                          AND user_category LIKE 'RX%'
                     THEN ISNULL(SUM(qnet), 0)
                     ELSE 0
                END AS NetURXTY ,
                CASE WHEN TYLY <> 'TY'
                          AND user_category LIKE 'RX%'
                     THEN ISNULL(SUM(qnet), 0)
                     ELSE 0
                END AS NetURXLY ,
                CASE WHEN TYLY = 'TY'
                          AND user_category NOT LIKE 'RX%'
                     THEN ISNULL(SUM(qnet), 0)
                     ELSE 0
                END AS NetUSTTY ,
                CASE WHEN TYLY <> 'TY'
                          AND user_category NOT LIKE 'RX%'
                     THEN ISNULL(SUM(qnet), 0)
                     ELSE 0
                END AS NetUSTLY ,
                CASE WHEN TYLY = 'TY'
                          AND return_code <> 'EXC'
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetUTY ,
                CASE WHEN TYLY <> 'TY'
                          AND return_code <> 'EXC'
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetULY ,
                CASE WHEN TYLY = 'TY'
                          AND return_code /*<> 'EXC'*/ = ''
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetURaTY ,
                CASE WHEN TYLY <> 'TY'
                          AND return_code /*<> 'EXC'*/ = ''
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetURaLY ,
                CASE WHEN TYLY = 'TY'
                          AND user_category LIKE 'RX%'
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetURXTY ,
                CASE WHEN TYLY <> 'TY'
                          AND user_category LIKE 'RX%'
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetURXLY ,
                CASE WHEN TYLY = 'TY'
                          AND user_category NOT LIKE 'RX%'
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetUSTTY ,
                CASE WHEN TYLY <> 'TY'
                          AND user_category NOT LIKE 'RX%'
                     THEN -1 * ISNULL(SUM(qreturns), 0)
                     ELSE 0
                END AS RetUSTLY ,
                CASE WHEN TYLY = 'TY' THEN ISNULL(SUM(qsales), 0)
                     ELSE 0
                END AS GrossUTY ,
                CASE WHEN TYLY <> 'TY' THEN ISNULL(SUM(qsales), 0)
                     ELSE 0
                END AS GrossULY ,
                CASE WHEN TYLY = 'TY'
                          AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales), 0)
                     ELSE 0
                END AS GrossNoBepUTY ,
                CASE WHEN TYLY <> 'TY'
                          AND promo_id <> 'BEP' THEN ISNULL(SUM(qsales), 0)
                     ELSE 0
                END AS GrossNoBepULY ,
                CASE WHEN TYLY = 'TY'
                          AND yyyymmdd BETWEEN t1.Start_date
                                       AND     ( CASE WHEN t1.End_date = '1/1/1900'
                                                      THEN GETDATE()
                                                      ELSE t1.End_date
                                                 END )
                     THEN ISNULL(SUM(anet), 0)
                     ELSE 0
                END AS DesigNetSTY
        FROM    #RankCusts_S3 t1
                LEFT OUTER JOIN #sales t2 ON t1.MergeCust = t2.MergeCust
                                             AND t1.ship_to = t2.ship_to
        GROUP BY t1.MergeCust ,
                t1.ship_to ,
                TYLY ,
                user_category ,
                promo_id ,
                return_code ,
                t1.Start_date ,
                t1.End_date ,
                yyyymmdd
		)
        SELECT  T1.customer ,
                T1.ship_to ,
-- SALES
                ROUND(SUM(NetSTY), 2) NetSTY ,
                ROUND(SUM(NetSLY), 2) NetSLY ,
                SUM(ListSTY) ListSTY ,
                SUM(ListSLY) ListSLY ,
                SUM(DesigNetSTY) DesigNetSTY ,
                SUM(NetSRXTY) NetSRXTY ,
                SUM(NetSRXLY) NetSRXLY ,
                SUM(NetSSTTY) NetSSTTY ,
                SUM(NetSSTLY) NetSSTLY ,
                SUM(RetSTY) RetSTY ,
                SUM(RetSLY) RetSLY ,
                SUM(RetSRaTY) RetSRaTY ,
                SUM(RetSRaLY) RetSRaLY ,
                SUM(RetSRXTY) RetSRXTY ,
                SUM(RetSRXLY) RetSRXLY ,
                SUM(RetSSTTY) RetSSTTY ,
                SUM(RetSSTLY) RetSSTLY ,
                SUM(GrossSTY) GrossSTY ,
                SUM(GrossSLY) GrossSLY ,
                SUM(GrossNoBepSTY) GrossNoBepSTY ,
                SUM(GrossNoBepSLY) GrossNoBepSLY , 
-- UNITS
                SUM(NetUTY) NetUTY ,
                SUM(NetULY) NetULY ,
                SUM(NetURXTY) NetURXTY ,
                SUM(NetURXLY) NetURXLY ,
                SUM(NetUSTTY) NetUSTTY ,
                SUM(NetUSTLY) NetUSTLY ,
                SUM(RetUTY) RetUTY ,
                SUM(RetULY) RetULY ,
                SUM(RetURaTY) RetURaTY ,
                SUM(RetURaLY) RetURaLY ,
                SUM(RetURXTY) RetURXTY ,
                SUM(RetURXLY) RetURXLY ,
                SUM(RetUSTTY) RetUSTTY ,
                SUM(RetUSTLY) RetUSTLY ,
                SUM(GrossUTY) GrossUTY ,
                SUM(GrossULY) GrossULY ,
                SUM(GrossNoBepUTY) GrossNoBepUTY ,
                SUM(GrossNoBepULY) GrossNoBepULY
        INTO    #FinalData1
        FROM    salesdata T1
		GROUP BY T1.customer ,
                T1.ship_to;
		
        IF ( OBJECT_ID('tempdb.dbo.#LastST2') IS NOT NULL )
            DROP TABLE #LastST2;
        SELECT DISTINCT
                RIGHT(cust_code, 5) Cust ,
                ship_to = CASE WHEN @CustOpt = 'B' THEN ''
                               ELSE A.ship_to
                          END ,
                ( SELECT TOP 1
                            last_st_ord_date
                  FROM      cvo_carbi B
                  WHERE     A.cust_code = B.cust_code
                            AND A.ship_to = CASE WHEN @CustOpt = 'B' THEN ''
                                                 ELSE B.ship_to
                                            END
                  ORDER BY  last_st_ord_date
                ) last_st_ord_date
        INTO    #LastST2
        FROM    cvo_carbi A; 
-- 13,165
		CREATE INDEX IDX_LASTST ON #LastST2 (Cust, ship_to) INCLUDE (last_st_ord_date)

        IF ( OBJECT_ID('tempdb.dbo.#LastST') IS NOT NULL )
            DROP TABLE #LastST;
        SELECT DISTINCT
                Cust ,
                ship_to = CASE WHEN @CustOpt = 'B' THEN ''
                               ELSE A.ship_to
                          END ,
                ( SELECT TOP 1
                            last_st_ord_date
                  FROM      #LastST2 B
                  WHERE     A.Cust = B.Cust
                            AND A.ship_to = CASE WHEN @CustOpt = 'B' THEN ''
                                                 ELSE B.ship_to
                                            END
                  ORDER BY  last_st_ord_date
                ) last_st_ord_date
        INTO    #LastST
        FROM    #LastST2 A; 
-- select * from #LastST
-- 13,121

        CREATE INDEX [idx_cust_ship] ON #FinalData1 (customer, ship_to);
        CREATE INDEX [idx_lastst] ON #LastST (Cust, ship_to);

        SELECT  status Stat ,
                T1.customer ,
                T1.ship_to ShipTo ,
                S3.terr ,
                S3.Door ,
                ISNULL(( SELECT TOP 1
                                salesperson_name
                         FROM   arsalesp AR
                         WHERE  S3.terr = AR.territory_code
                                AND AR.status_type = 1
                       ), ( S3.terr + ' Default' )) AS SLP ,
                Address_name ,
                addr2 ,
                addr3 ,
                addr4 ,
                City ,
                State ,
                Postal_code ,
                Country ,
                contact_name ,
                contact_phone ,
                tlx_twx ,
                contact_email ,
                NetSTY ,
                NetSLY ,
                ListSTY ,
                ListSLY ,
                DesigNetSTY ,
                NetSRXTY ,
                NetSRXLY ,
                NetSSTTY ,
                NetSSTLY ,
                RetSTY ,
                RetSLY ,
                RetSRaTY ,
                RetSRaLY ,
                RetSRXTY ,
                RetSRXLY ,
                RetSSTTY ,
                RetSSTLY ,
                GrossSTY ,
                GrossSLY ,
                GrossNoBepSTY ,
                GrossNoBepSLY ,
                NetUTY ,
                NetULY ,
                NetURXTY ,
                NetURXLY ,
                NetUSTTY ,
                NetUSTLY ,
                RetUTY ,
                RetULY ,
                RetURaTY ,
                RetURaLY ,
                RetURXTY ,
                RetURXLY ,
                RetUSTTY ,
                RetUSTLY ,
                GrossUTY ,
                GrossULY ,
                GrossNoBepUTY ,
                GrossNoBepULY ,
				ISNULL((r12_ty.RetSRaTY_R12), 0) RetSRaTY_R12 ,
                ISNULL((r12_ty.GrossNoBepSTY_R12), 0) GrossNoBepSTY_R12 ,
                ISNULL((r12_ty.RetURaTY_R12), 0) RetURaTY_R12 ,
                ISNULL((r12_ty.GrossNoBepUTY_R12), 0) GrossNoBepUTY_R12 ,
                ISNULL((r12_LY.RetSRaTY_R12), 0) RetSRaLY_R12 ,
                ISNULL((r12_ly.GrossNoBepSTY_R12), 0) GrossNoBepSLY_R12, 
                ISNULL(Designations, '') ActiveDesignation ,
                ISNULL(PriDesig, '') CurrentPrimary ,
                Start_date AS PriStart ,
                End_date AS PriEnd ,
                ISNULL(Parent, '') PARENT ,
                ISNULL(CustType, '') CustType ,
                ISNULL(s3.coop_eligible, 'N') Coop_Eligible ,
               	--ISNULL((coop_earned), 0) COOP_Earned ,
                --ISNULL((coop_redeemed), 0) COOP_ReDeemed ,
				coop.coop_earned COOP_Earned,
				coop.coop_redeemed COOP_ReDeemed,
                pastdueamt ,
                interval ,
                ISNULL(T2.goal1, 0) Goal1 ,
                ISNULL(T2.rebatepct1, 0) RebatePct1 ,
                ISNULL(goal2, 0) goal2 ,
                ISNULL(rebatepct2, 0) rebatepct2 ,
                ISNULL(goal3, 0) goal3 ,
                ISNULL(rebatepct3, 0) rebatepct3 ,
                ISNULL(PrimaryOnly, '') PrimaryOnly ,
                ISNULL(CurrentlyOnly, '') CurrentlyOnly ,
                ISNULL(RRLess, 0.25) RRLess ,
                COOPOvr ,
                S3.price_code PriceCode , 
                CASE WHEN EXISTS ( SELECT   1
                                   FROM     c_quote cq
                                   WHERE    RIGHT(cq.customer_key, 5) = T1.customer )
                     THEN 'Y'
                     ELSE 'N'
                END AS ContrPrcing ,
                CASE WHEN goal1 > DesigNetSTY THEN goal1 - DesigNetSTY
                     WHEN goal2 > DesigNetSTY THEN goal2 - DesigNetSTY
                     ELSE 0
                END AS DolToNextRebate ,
                CASE WHEN DesigNetSTY >= goal2 THEN DesigNetSTY * rebatepct2
                     WHEN DesigNetSTY >= goal1 THEN DesigNetSTY * rebatepct1
                     ELSE 0
                END AS RebateEarned ,
             	ISNULL((rx.rx3numords), 0) RX3NumOrds ,
                ISNULL((rx.rx3saved), 0) RX3Saved ,
                ISNULL((rx.rx5numords), 0) RX5NumOrds ,
                ISNULL((rx.rx5saved), 0) RX5Saved ,
                ISNULL((pryr1), 0) PrYr1 ,
                ISNULL((pryr2), 0) PrYr2 ,
                ISNULL((pryr3), 0) PrYr3 ,
				DATEPART(YEAR, @PrYr1To) AS PrYr1Name ,
				DATEPART(YEAR, DATEADD(YEAR, -1, @PrYr1To)) AS PrYr2Name ,
				DATEPART(YEAR, DATEADD(YEAR, -2, @PrYr1To)) AS PrYr3Name  ,
                t3.last_st_ord_date ,
-- shipto ranking only fields
                ar.m_Address_name ,
                ar.m_City ,
                ar.m_State ,
                ar.m_Postal_code
        FROM    #FinalData1 T1
                LEFT OUTER JOIN #RankCusts_S3 S3 ON S3.MergeCust = T1.customer
                                                    AND S3.ship_to = T1.ship_to
                LEFT OUTER JOIN cvo_designation_rebates T2 ON T2.code = ISNULL(S3.PriDesig,'') AND progyear = DATEPART(YEAR,@DateToty)
				LEFT OUTER JOIN
                (SELECT customer_code, SUM(COOP_earned) coop_earned, SUM(coop_redeemed) coop_redeemed
				FROM #coopdata
				WHERE yyear = DATEPART(YEAR, @datetoTY)
				GROUP BY customer_code) coop ON coop.customer_code = t1.customer
				-- LEFT OUTER JOIN #coopdata ON t1.customer = #coopdata.customer_code AND yyear = DATEPART(YEAR, @DateToTY)
                LEFT OUTER JOIN #LastST t3 ON T1.customer = t3.Cust
                                              AND T1.ship_to = t3.ship_to
				LEFT OUTER JOIN #R12 r12_ty on     T1.customer = R12_TY.Customer AND T1.ship_to = R12_TY.ship_to AND R12_TY.years = 'TY'
				LEFT OUTER JOIN #R12 r12_ly on     T1.customer = R12_LY.Customer AND T1.ship_to = R12_LY.ship_to AND R12_LY.years = 'LY'
				LEFT OUTER JOIN 
				(SELECT cust_code, ship_to
					, sum(CASE WHEN RxDesig = 'rx3' THEN 1 ELSE 0 end)  RX3NumOrds
					, SUM(CASE WHEN RxDesig = 'rx3' THEN UnchargedRates ELSE 0 END) RX3Saved
					, sum(CASE WHEN RxDesig = 'rx5' THEN 1 ELSE 0 end)  RX5NumOrds
					, SUM(CASE WHEN RxDesig = 'rx5' THEN UnchargedRates ELSE 0 END) RX5Saved
				FROM #RXEFREIGHT GROUP BY Cust_code ,
										  ship_to) RX ON T1.customer = RX.Cust_code AND T1.ship_to = RX.ship_to
				LEFT OUTER JOIN 
				( SELECT customer, ship_to, 
					ISNULL(SUM(CASE WHEN [year] = DATEPART(YEAR, @PrYr1To) THEN net ELSE 0 END ), 0) PrYr1 ,
					ISNULL(SUM(CASE WHEN [YEAR] = DATEPART(YEAR, DATEADD(YEAR, -1, @PrYr1To)) THEN net ELSE 0 END), 0) PrYr2 ,
					ISNULL(SUM(CASE WHEN [YEAR] = DATEPART(YEAR, DATEADD(YEAR, -2, @PrYr1To)) THEN NET ELSE 0 END), 0) PrYr3

					FROM #p3yrdata
					GROUP BY CUSTOMER, SHIP_TO)  PY on T1.customer = PY.customer AND T1.ship_to = PY.ship_to
				LEFT OUTER JOIN ( SELECT DISTINCT
                                            RIGHT(customer_code, 5) customer ,
                                            customer_name m_Address_name ,
                                            city m_City ,
                                            state m_State ,
                                            postal_code m_Postal_code
                                  FROM      arcust  (NOLOCK) WHERE status_type = 1
                                ) ar ON T1.customer = ar.customer; 

    END;

GO

GRANT EXECUTE ON  [dbo].[RankCust_all_sp] TO [public]
GO
