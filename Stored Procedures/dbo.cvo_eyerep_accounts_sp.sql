SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		TG
-- Create date: 2/22/2016
-- Description:	EyeRep Main Customer Data
-- EXEC [cvo_eyerep_accounts_sp]
-- SELECT * From cvo_eyerep_actshp_tbl
-- SELECT * From cvo_eyerep_repEXT_tbl
-- SELECT * From cvo_eyerep_actsls_tbl
-- SELECT * FROM dbo.cvo_eyerep_promocodes_tbl AS ept
-- SELECT * FROM dbo.cvo_eyerep_inv_tbl AS eit where style = 'bluestone park'
-- tag - 071213 - create a regular table instead of temp table
-- tag - 8/21/2015 - add sales rep customer accounts
-- tag - 6/30/2016 - add ordtyp.txt table for promotions
-- tag - 7/28/2016 - add actext.txt, actsls.txt, repext.txt
-- =============================================

CREATE PROCEDURE [dbo].[cvo_eyerep_accounts_sp]    @datatype VARCHAR(10) = NULL
AS
    BEGIN

        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;

        DECLARE @today DATETIME ,
            @LOCATION VARCHAR(10);
        SET @today = GETDATE();
        SET @LOCATION = '001';

		IF @datatype = 'ALL' SELECT @datatype = NULL
	
        IF ( OBJECT_ID('tempdb.dbo.#AllTerr') IS NOT NULL )
            DROP TABLE dbo.#AllTerr;
            WITH    C AS ( SELECT DISTINCT
                                    ar.territory_code ,
                                    ar.customer_code
                           FROM     ( SELECT DISTINCT
                                                territory_code
                                      FROM      arterr (NOLOCK)
                                      WHERE     dbo.calculate_region_fn(territory_code) < '800'
                                                AND territory_code IN (
                                                '20206', '70778', '50503',
                                                '40440', '40456' ) -- phil, Elyse, dave s, kerry c, bob s
                                    ) Terr -- for testing 03/2016
                                    JOIN ( SELECT DISTINCT
                                                    customer_code ,
                                                    territory_code
                                           FROM     armaster (NOLOCK)
                                         ) ar ON Terr.territory_code = ar.territory_code
                         )
            SELECT DISTINCT
                    customer_code ,
                    STUFF(( SELECT DISTINCT
                                    ',' + territory_code
                            FROM    armaster (NOLOCK)
                            WHERE   customer_code = C.customer_code
                          FOR
                            XML PATH('')
                          ), 1, 1, '') AS AllTerr
            INTO    #AllTerr
            FROM    C;

	  -- add sales rep customers too - 8/19/2015
        INSERT  INTO #AllTerr
                ( customer_code ,
                  AllTerr
                )
                SELECT DISTINCT
                        ISNULL(employee_code, '') customer_code ,
                        territory_code
                FROM    arsalesp (NOLOCK)
                WHERE   ISNULL(employee_code, '') > ''
                        AND status_type = 1
                        AND territory_code IN ( '20206', '70778', '50503',
                                                '40440', '40456' ) -- phil, Elyse, dave s, kerry c
                        AND NOT EXISTS ( SELECT 1
                                         FROM   #AllTerr
                                         WHERE  #AllTerr.customer_code = ISNULL(employee_code,
                                                              '') );
	  

	  -- SELECT * FROM #allterr where customer_code = '010021'


IF 'MASTER' = ISNULL(@datatype, 'MASTER')
    BEGIN
	-- PULL LIST FOR CUSTOMERS - 3.2
                IF ( OBJECT_ID('dbo.cvo_eyerep_acts_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_acts_Tbl
                            (
                              acct_id VARCHAR(20) NOT NULL ,
                              billing_name VARCHAR(50) NULL ,
                              billing_addr1 VARCHAR(50) NULL ,
                              billing_addr2 VARCHAR(50) NULL ,
                              billing_city VARCHAR(30) NULL ,
                              billing_state VARCHAR(30) NULL ,
                              billing_postal_code VARCHAR(15) NULL ,
                              billing_phone VARCHAR(15) NULL ,
                              billing_email VARCHAR(100) NULL ,
                              current_balance DECIMAL(9, 2) NULL ,
                              detail_note VARCHAR(250) NULL ,
                              account_status VARCHAR(50) NULL ,
                              account_sort VARCHAR(50) NULL ,
                              prospect CHAR(1) NULL ,
                              billing_fax VARCHAR(15) NULL
                            )
                        ON  [PRIMARY];

                        GRANT ALL ON dbo.cvo_eyerep_acts_Tbl TO PUBLIC;
                    END;


                TRUNCATE TABLE cvo_eyerep_acts_Tbl;

                INSERT  INTO dbo.cvo_eyerep_acts_Tbl
                        ( acct_id ,
                          billing_name ,
                          billing_addr1 ,
                          billing_addr2 ,
                          billing_city ,
                          billing_state ,
                          billing_postal_code ,
                          billing_phone ,
                          billing_email ,
                          current_balance ,
                          detail_note ,
                          account_status ,
                          account_sort ,
                          prospect ,
                          billing_fax
                        )
                        SELECT  ar.customer_code ,
                                LEFT(addr1, 50) AS bill_name ,
                                LEFT(addr2, 50) AS bill_street ,
                                LEFT(CASE WHEN addr3 LIKE '%, __ %' THEN ''
                                          ELSE addr3
                                     END, 50) AS bill_street2 ,
                                LEFT(city, 30) AS bill_city ,
                                LEFT(state, 30) AS bill_state ,
                                LEFT(postal_code, 15) AS bill_postcode ,
                                LEFT(contact_phone, 15) AS bill_phone ,
                                LEFT(CASE WHEN ( contact_email LIKE '%refused%' )
                                          THEN ''
                                          --WHEN #AllTerr.customer_code = '010021'
                                          --THEN 'tgraziosi@cvoptical.com'
                                          ELSE REPLACE(LOWER(ISNULL(contact_email,
                                                              '')), ';', ',')
                                     END, 100) ,
                                0 AS current_balance ,
                                '' AS detail_note ,
                                LEFT(ar.status_type, 50) ,
                                LEFT(ar.short_name, 50) ,
                                'N' AS prospect ,
                                LEFT(tlx_twx, 15) AS bill_fax

-- INTO cvo_eyerep_acts_tbl
                        FROM    armaster ar ( NOLOCK )
                                INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                        WHERE   1 = 1
                                AND status_type = 1
                                AND address_type = 0;


-- Process Ship-to Customers - 3.2

                IF ( OBJECT_ID('dbo.cvo_eyerep_actshp_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_actshp_tbl
                            (
                              ship_id VARCHAR(20) NOT NULL ,
                              acct_id VARCHAR(20) NOT NULL ,
                              ship_name VARCHAR(50) NULL ,
                              ship_addr1 VARCHAR(50) NULL ,
                              ship_addr2 VARCHAR(50) NULL ,
                              ship_city VARCHAR(30) NULL ,
                              ship_state VARCHAR(30) NULL ,
                              ship_postal VARCHAR(15) NULL ,
                              default_shpmth VARCHAR(20) NULL
                            )
                        ON  [PRIMARY];
                        GRANT ALL ON dbo.cvo_eyerep_actshp_tbl TO PUBLIC;
                    END;


                TRUNCATE TABLE cvo_eyerep_actshp_tbl;

                INSERT  INTO dbo.cvo_eyerep_actshp_tbl
                        ( ship_id ,
                          acct_id ,
                          ship_name ,
                          ship_addr1 ,
                          ship_addr2 ,
                          ship_city ,
                          ship_state ,
                          ship_postal ,
                          default_shpmth
                        )
                        SELECT  ar.customer_code
                                + CASE WHEN ar.ship_to_code > ''
                                       THEN '-' + ar.ship_to_code
                                       ELSE ''
                                  END ,
                                ar.customer_code ,
                                LEFT(addr1, 50) AS ship_name ,
                                LEFT(addr2, 50) AS ship_street ,
                                LEFT(CASE WHEN addr3 LIKE '%, __ %' THEN ''
                                          ELSE addr3
                                     END, 50) AS ship_street2 ,
                                LEFT(city, 30) AS ship_city ,
                                LEFT(state, 30) AS ship_state ,
                                LEFT(postal_code, 15) AS ship_postcode ,
                                LEFT(ar.ship_via_code, 15)

-- INTO cvo_eyerep_acts_tbl
                        FROM    armaster ar ( NOLOCK )
                                INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                        WHERE   1 = 1
                                AND status_type = 1
                                AND address_type IN ( 0, 1 );

-- account extension data - 3.2
-- 7/26/2016

                IF ( OBJECT_ID('dbo.cvo_eyerep_actext_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_actext_tbl
                            (
                              acct_id VARCHAR(20) NOT NULL ,
                              field_name VARCHAR(50) NULL ,
                              field_value VARCHAR(200) NULL ,
                              display_order INT NULL ,
                              rep_id VARCHAR(20) NULL,
	                        )
                        ON  [PRIMARY];
                        GRANT ALL ON dbo.cvo_eyerep_actext_tbl TO PUBLIC;
                    END;


                TRUNCATE TABLE cvo_eyerep_actext_tbl;

                INSERT  INTO dbo.cvo_eyerep_actext_tbl
                        ( acct_id ,
                          field_name ,
                          field_value ,
                          display_order ,
                          rep_id
                        )
                        SELECT  ar.customer_code ,
                                'DISCOUNT CODE' field_name ,
                                ISNULL(ar.price_code, 'Unknown') field_value ,
                                1 display_order ,
                                '' rep_id
                        FROM    armaster ar ( NOLOCK )
                                INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                        WHERE   ar.address_type = 0
                                AND ar.status_type = 1
                        UNION ALL
                        SELECT  ar.customer_code ,
                                'PRIMARY DESIGNATION' field_name ,
                                dc.description field_value ,
                                2 display_order ,
                                '' rep_id
                        FROM    armaster ar ( NOLOCK )
                                INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                                INNER JOIN dbo.cvo_cust_designation_codes AS cdc ON cdc.customer_code = ar.customer_code
                                                              AND cdc.primary_flag = 1
                                INNER JOIN dbo.cvo_designation_codes AS dc ON dc.code = cdc.code
                        WHERE   ar.address_type = 0
                                AND ar.status_type = 1
                        UNION ALL
                        SELECT  ar.customer_code ,
                                'BUYING GROUP' field_name ,
                                bg.address_name field_value ,
                                3 display_order ,
                                '' rep_id
                        FROM    armaster ar ( NOLOCK )
                                INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                                INNER JOIN arnarel AS NA ON NA.child = ar.customer_code
                                                            AND NA.child <> NA.parent
                                INNER JOIN armaster bg ON bg.customer_code = NA.parent
                        WHERE   ar.address_type = 0
                                AND ar.status_type = 1
                        UNION ALL
                        SELECT  ar.customer_code ,
                                'STATUS' field_name ,
                                CASE WHEN ar.status_type = 1 THEN 'Active'
                                     WHEN ar.status_type = 2 THEN 'Inactive'
                                     WHEN ar.status_type = 3
                                     THEN 'No New Business'
                                     ELSE 'Unknown'
                                END AS field_value ,
                                4 display_order ,
                                '' rep_id
                        FROM    armaster ar ( NOLOCK )
                                INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                        WHERE   ar.address_type = 0
                        UNION ALL
                        SELECT  ar.customer_code ,
                                'OPEN DATE' field_name ,
                                CONVERT(VARCHAR(10), dbo.adm_format_pltdate_f(ar.date_opened), 101) field_value ,
                                5 display_order ,
                                '' rep_id
                        FROM    armaster ar ( NOLOCK )
                                INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                        WHERE   ar.address_type = 0
                                AND ar.status_type = 1;

-- get LIST FOR invoice terms - 3.2

                IF ( OBJECT_ID('dbo.cvo_eyerep_biltrm_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_biltrm_tbl
                            (
                              biltrm_id VARCHAR(20) NOT NULL ,
                              biltrm_description VARCHAR(30) NULL ,
                              biltrm_amount DECIMAL(9, 2)
                            )
                        ON  [PRIMARY];
                        GRANT ALL ON dbo.cvo_eyerep_biltrm_tbl TO PUBLIC;
                    END;

                TRUNCATE TABLE cvo_eyerep_biltrm_tbl;

                INSERT  INTO dbo.cvo_eyerep_biltrm_tbl
                        ( biltrm_id ,
                          biltrm_description
                        )
                        SELECT  a.terms_code ,
                                a.terms_desc
                        FROM    dbo.arterms AS a ( NOLOCK )
                        WHERE   1 = 1
                                AND a.terms_code IN ('NET30','NET60','NET90','INS2','INS3','INS4','INS5','INS7','PP');


-- Order types

                IF ( OBJECT_ID('dbo.cvo_eyerep_ordtyp_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_ordtyp_tbl
                            (
                              ordtyp_id VARCHAR(20) NOT NULL ,
                              ordtyp_description VARCHAR(30) NULL
                            )
                        ON  [PRIMARY];
                    END;

                TRUNCATE TABLE dbo.cvo_eyerep_ordtyp_tbl;

                INSERT  dbo.cvo_eyerep_ordtyp_tbl
                        ( ordtyp_id ,
                          ordtyp_description
                        )
                        SELECT DISTINCT
                                su.category_code ,
                                su.category_code + ' = ' + su.category_desc
                        FROM    dbo.so_usrcateg AS su
                        WHERE   void = 'N'
                                AND su.category_code LIKE 'ST%' AND RIGHT(su.category_code,2) <>'RB';

-- promotion codes

                IF ( OBJECT_ID('dbo.cvo_eyerep_promocodes_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_promocodes_tbl
                            (
                              promo_id VARCHAR(20) NOT NULL ,
                              promo_description VARCHAR(50) NULL
                            )
                        ON  [PRIMARY];
                    END;

                TRUNCATE TABLE dbo.cvo_eyerep_promocodes_tbl;

                INSERT  dbo.cvo_eyerep_promocodes_tbl
                        ( promo_id ,
                          promo_description
                        )
                        SELECT DISTINCT
                                promo_id + ',' + promo_level ,
                                promo_id + ',' + promo_level + ' = '
                                + c.promo_name
                        FROM    CVO_promotions AS c
                        WHERE   ISNULL(c.void, 'N') = 'N'
                                AND c.promo_start_date <= @today
                                AND c.promo_end_date >= @today;

-- Sales Reps


                IF ( OBJECT_ID('dbo.cvo_eyerep_rp_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_rp_tbl
                            (
                              rep_id VARCHAR(20) NOT NULL ,
                              rep_type VARCHAR(10) NULL ,
                              user_name VARCHAR(100) NULL ,
                              user_password VARCHAR(20) NULL ,
                              first_name VARCHAR(20) NULL ,
                              last_name VARCHAR(20) NULL ,
                              email_address VARCHAR(100) NULL
                            )
                        ON  [PRIMARY];
                    END;

                TRUNCATE TABLE dbo.cvo_eyerep_rp_tbl;

                INSERT  dbo.cvo_eyerep_rp_tbl
                        ( rep_id ,
                          rep_type ,
                          user_name ,
                          user_password ,
                          first_name ,
                          last_name ,
                          email_address
                        )
                        SELECT DISTINCT
                                a.territory_code ,
                                a.territory_code ,
                                a.salesperson_code ,
                                'eyerepcvo' ,
                                LEFT(LEFT(salesperson_name,
                                          CHARINDEX(' ', salesperson_name) - 1),
                                     20) ,
                                LEFT(SUBSTRING(salesperson_name,
                                               CHARINDEX(' ', salesperson_name)
                                               + 1, LEN(salesperson_name)), 20) ,
                                LEFT(a.slp_email, 100)
                        FROM    dbo.cvo_sc_addr_vw AS a 
-- testing
                        WHERE   a.territory_code IN ( '20206', '70778',
                                                      '50503', '40440',
                                                      '40456' );

            END;

-- rep accounts

        IF ( OBJECT_ID('dbo.cvo_eyerep_rpact_tbl') IS NULL )
            BEGIN
                CREATE TABLE dbo.cvo_eyerep_rpact_tbl
                    (
                      rep_id VARCHAR(20) NULL ,
                      acct_id VARCHAR(20) NULL
                    )
                ON  [PRIMARY];
            END;

        TRUNCATE TABLE dbo.cvo_eyerep_rpact_tbl;

        INSERT  dbo.cvo_eyerep_rpact_tbl
                ( rep_id ,
                  acct_id
                )
                SELECT DISTINCT
                        ISNULL(slp.territory_code, ar.territory_code) territory ,
                        ar.customer_code
                FROM    armaster ar ( NOLOCK )
                        INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                        LEFT OUTER JOIN arsalesp slp ON slp.employee_code = #AllTerr.customer_code
                WHERE   1 = 1
                        AND ar.status_type = 1
                        AND ar.address_type = 0
                        AND EXISTS ( SELECT 1
                                     FROM   dbo.cvo_eyerep_rp_tbl AS cert
                                     WHERE  cert.rep_id = ISNULL(slp.territory_code,
                                                              ar.territory_code) );

-- rep account ship addresses

        IF ( OBJECT_ID('dbo.cvo_eyerep_rpashp_tbl') IS NULL )
            BEGIN
                CREATE TABLE dbo.cvo_eyerep_rpashp_tbl
                    (
                      rep_id VARCHAR(20) NOT NULL ,
                      ship_id VARCHAR(20) NOT NULL ,
                      acct_id VARCHAR(20) NOT NULL
                    )
                ON  [PRIMARY];
            END;

        TRUNCATE TABLE dbo.cvo_eyerep_rpashp_tbl;

        INSERT  dbo.cvo_eyerep_rpashp_tbl
                ( rep_id ,
                  ship_id ,
                  acct_id
                )
                SELECT DISTINCT
                        ar.territory_code ,
                        ar.customer_code
                        + CASE WHEN ar.ship_to_code > ''
                               THEN '-' + ar.ship_to_code
                               ELSE ''
                          END ,
                        ar.customer_code
                FROM    armaster ar ( NOLOCK )
                        INNER JOIN #AllTerr (NOLOCK) ON ar.customer_code = #AllTerr.customer_code
                WHERE   1 = 1
                        AND ar.status_type = 1
                        AND address_type IN ( 0, 1 );


        IF ( OBJECT_ID('dbo.cvo_eyerep_repext_tbl') IS NULL )
            BEGIN
                CREATE TABLE dbo.cvo_eyerep_repext_tbl
                    (
                      rep_id VARCHAR(20) NOT NULL ,
                      field_name VARCHAR(50) NULL ,
                      field_value VARCHAR(200) NULL ,
                      display_order INT NULL,
	                )
                ON  [PRIMARY];
                GRANT ALL ON dbo.cvo_eyerep_repext_tbl TO PUBLIC;
            END;


        TRUNCATE TABLE cvo_eyerep_repext_tbl;
        DECLARE @stat_year VARCHAR(5);
        SELECT  @stat_year = CAST(YEAR(@today) AS VARCHAR(4)) + 'A';

        INSERT  INTO dbo.cvo_eyerep_repext_tbl
                ( rep_id ,
                  field_name ,
                  field_value ,
                  display_order
                )
                SELECT  ts.Territory_Code ,
                        '% over/under LY' field_name ,
                        ISNULL(CAST(ts.LY_TY_Sales_Incr_Pct * 100 AS VARCHAR(20)),
                               'Unknown') field_value ,
                        1 display_order
                FROM    dbo.cvo_terr_scorecard AS ts ( NOLOCK )
                WHERE   EXISTS ( SELECT 1
                                 FROM   #AllTerr
                                 WHERE  ts.Territory_Code = #AllTerr.AllTerr )
                        AND ts.Stat_Year = @stat_year
                UNION ALL
                SELECT  ts.Territory_Code ,
                        'RX %' field_name ,
                        ISNULL(CAST(ts.TY_RX_Pct * 100 AS VARCHAR(20)),
                               'Unknown') field_value ,
                        2 display_order
                FROM    dbo.cvo_terr_scorecard AS ts ( NOLOCK )
                WHERE   EXISTS ( SELECT 1
                                 FROM   #AllTerr
                                 WHERE  ts.Territory_Code = #AllTerr.AllTerr )
                        AND ts.Stat_Year = @stat_year
                UNION ALL
                SELECT  ts.Territory_Code ,
                        'Doors >500' field_name ,
                        ISNULL(CAST(ts.Doors_500 AS VARCHAR(20)), 'Unknown') field_value ,
                        3 display_order
                FROM    dbo.cvo_terr_scorecard AS ts ( NOLOCK )
                WHERE   EXISTS ( SELECT 1
                                 FROM   #AllTerr
                                 WHERE  ts.Territory_Code = #AllTerr.AllTerr )
                        AND ts.Stat_Year = @stat_year
                UNION ALL
                SELECT  ts.Territory_Code ,
                        'Doors >2400' field_name ,
                        ISNULL(CAST(ts.ActiveDoors_2400 AS VARCHAR(20)),
                               'Unknown') field_value ,
                        4 display_order
                FROM    dbo.cvo_terr_scorecard AS ts ( NOLOCK )
                WHERE   EXISTS ( SELECT 1
                                 FROM   #AllTerr
                                 WHERE  ts.Territory_Code = #AllTerr.AllTerr )
                        AND ts.Stat_Year = @stat_year;


-- ship methods

        IF ( OBJECT_ID('dbo.cvo_eyerep_shpmth_tbl') IS NULL )
            BEGIN

                CREATE TABLE dbo.cvo_eyerep_shpmth_tbl
                    (
                      shpmth_id VARCHAR(20) NOT NULL ,
                      shpmth_name VARCHAR(30) NOT NULL
                    )
                ON  [PRIMARY];
            END;

        TRUNCATE TABLE dbo.cvo_eyerep_shpmth_tbl;

        INSERT  dbo.cvo_eyerep_shpmth_tbl
                ( shpmth_id ,
                  shpmth_name
                )
                SELECT DISTINCT
                        ar.ship_via_code ,
                        ar.ship_via_code
                FROM    dbo.armaster AS ar
                WHERE   ISNULL(ar.ship_via_code, '') > ''
                        AND ar.address_type <> 9;


        IF ( OBJECT_ID('dbo.cvo_eyerep_promocodes_tbl') IS NULL )
            BEGIN
                CREATE TABLE dbo.cvo_eyerep_promocodes_tbl
                    (
                      promo_id VARCHAR(20) NOT NULL ,
                      promo_description VARCHAR(50) NULL
                    )
                ON  [PRIMARY];
            END;

        TRUNCATE TABLE dbo.cvo_eyerep_promocodes_tbl;

        INSERT  dbo.cvo_eyerep_promocodes_tbl
                ( promo_id ,
                  promo_description
                )
                SELECT  promo_id + ',' + promo_level ,
                        promo_name
                FROM    CVO_promotions
                WHERE   GETDATE() BETWEEN ISNULL(promo_start_date, @today)
                                  AND     ISNULL(promo_end_date, @today);

            END; -- MASTER DATA

-- rx % and st %
IF 'ACTIVITY' = ISNULL(@datatype, 'ACTIVITY')
    BEGIN

                IF ( OBJECT_ID('dbo.cvo_eyerep_actsls_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_actsls_tbl
                            (
                              acct_id VARCHAR(20) NOT NULL ,
                              TY_ytd_sales NUMERIC NULL ,
                              LY_ytd_sales NUMERIC NULL ,
                              ty_r12_sales NUMERIC NULL ,
                              LY_r12_sales NUMERIC NULL ,
                              aging30 NUMERIC NULL ,
                              aging60 NUMERIC NULL ,
                              aging90 NUMERIC NULL
                            )
                        ON  [PRIMARY];
                        GRANT ALL ON dbo.cvo_eyerep_actsls_tbl TO PUBLIC;
                    END;

                TRUNCATE TABLE cvo_eyerep_actsls_tbl;

                DECLARE @tystart DATETIME ,
                    @tyend DATETIME ,
                    @lystart DATETIME ,
                    @lyend DATETIME ,
                    @tyr12start DATETIME ,
                    @lyr12start DATETIME;
		
                SELECT  @tystart = drv.BeginDate ,
                        @tyend = drv.EndDate
                FROM    dbo.cvo_date_range_vw AS drv
                WHERE   Period = 'Year to Date';
                SELECT  @lystart = drv.BeginDate ,
                        @lyend = drv.EndDate
                FROM    dbo.cvo_date_range_vw AS drv
                WHERE   Period = 'Last Year to Date';
                SELECT  @tyr12start = drv.BeginDate
                FROM    dbo.cvo_date_range_vw AS drv
                WHERE   Period = 'Rolling 12 TY';
                SELECT  @lyr12start = drv.BeginDate
                FROM    dbo.cvo_date_range_vw AS drv
                WHERE   Period = 'Rolling 12 LY';


                INSERT  INTO dbo.cvo_eyerep_actsls_tbl
                        ( acct_id ,
                          TY_ytd_sales ,
                          LY_ytd_sales ,
                          ty_r12_sales ,
                          LY_r12_sales ,
                          aging30 ,
                          aging60 ,
                          aging90
                        )
                        SELECT  eat.acct_id ,
                                SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @tystart AND @tyend
                                                THEN anet
                                                ELSE 0
                                           END, 0)) ty_ytd_sales ,
                                SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @lystart AND @lyend
                                                THEN anet
                                                ELSE 0
                                           END, 0)) ly_ytd_sales ,
                                SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @tyr12start AND @tyend
                                                THEN anet
                                                ELSE 0
                                           END, 0)) ty_r12_sales ,
                                SUM(ISNULL(CASE WHEN yyyymmdd BETWEEN @lyr12start AND @lyend
                                                THEN anet
                                                ELSE 0
                                           END, 0)) ly_r12_sales ,
                                0 aging30 ,
                                0 aging60 ,
                                0 aging90
                        FROM    dbo.cvo_eyerep_acts_Tbl AS eat
                                LEFT OUTER JOIN cvo_sbm_details sbm ON sbm.customer = eat.acct_id
                        WHERE   sbm.yyyymmdd BETWEEN @lyr12start AND @tyend
                        GROUP BY eat.acct_id;



-- Get Inventory master info - 3.2

                IF ( OBJECT_ID('dbo.cvo_eyerep_inv_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_inv_tbl
                            (
                              sku VARCHAR(50) NOT NULL ,
                              upc VARCHAR(50) NULL ,
                              collection_id VARCHAR(50) NULL ,
                              style VARCHAR(100) NULL ,
                              color VARCHAR(100) NULL ,
                              eye_size VARCHAR(10) NULL ,
                              temple VARCHAR(10) NULL ,
                              bridge VARCHAR(10) NULL ,
                              product_rank INT NULL ,
                              collection_rank INT NULL ,
                              product_type VARCHAR(20) NULL ,
                              avail_status VARCHAR(30) NULL ,
                              avail_date VARCHAR(8) NULL ,
                              base_price DECIMAL(9, 2) NULL ,
                              new_release CHAR(1) NULL
                            )
                        ON  [PRIMARY];
                        GRANT ALL ON dbo.cvo_eyerep_inv_tbl TO PUBLIC;
                    END;

                TRUNCATE TABLE dbo.cvo_eyerep_inv_tbl;

				IF ( OBJECT_ID('tempdb.dbo.#usage') IS NOT NULL ) DROP TABLE #usage;

				SELECT location ,
                       part_no ,
                       usg_option ,
                       asofdate ,
                       e4_wu ,
                       e12_wu ,
                       e26_wu ,
                       e52_wu ,
                       subs_exist ,
                       subs_w4 ,
                       subs_w12 ,
                       promo_w4 ,
                       promo_w12 
					   INTO #usage FROM dbo.f_cvo_calc_weekly_usage('O')

                INSERT  INTO dbo.cvo_eyerep_inv_tbl
                        ( sku ,
                          upc ,
                          collection_id ,
                          style ,
                          color ,
                          eye_size ,
                          temple ,
                          bridge ,
                          product_rank ,
                          collection_rank ,
                          product_type ,
                          avail_status ,
                          avail_date ,
                          base_price ,
                          new_release
	                    )
                        SELECT  i.part_no ,
                                i.upc_code ,
								
								CASE WHEN hi.[category:1] IN ( 'frame', 'sun',
                                                              'pop' )
                                     THEN CASE WHEN i.collection IN ('izod','izx') THEN 'IZOD' ELSE i.collection END
                                     ELSE hi.[category:1]
                                END AS Collection ,
          --                      CASE WHEN hi.[category:1] IN ('frame','sun','pop') THEN LEFT(i.model, 100)
										--ELSE LEFT(i.model+ '-'+hi.[category:1],100) END  ,
								LEFT(i.model, 100),
								-- hi.VariantDescription,
                                CASE WHEN i.Collection = 'revo'
                                     THEN LEFT(ISNULL(i.ColorName, '') + '-'
                                               + ISNULL(i.sun_lens_color, ''),
                                               100)
                                     ELSE LEFT(i.ColorName, 100)
                                END ,
                                CAST (CAST(i.eye_size AS INT) AS VARCHAR(10)) ,
                                CAST (i.temple_size AS VARCHAR(10)) ,
                                CAST (i.dbl_size AS VARCHAR(10)) ,
                                99999 ,
                                9999 ,
                                LEFT(i.RES_type, 20) ,
                                CASE WHEN ISNULL(iav.qty_avl, 0) <= 0
                                          AND ISNULL(iav.SOF, 0) > 0
                                     THEN 'BACK-ORDERED'
                                     WHEN ISNULL(iav.qty_avl, 0) <= 0
                                     THEN 'OUT-OF-STOCK'
                                     WHEN ISNULL(iav.qty_avl, 0) <= ISNULL(fccwu.e12_wu,
                                                              0)
                                     THEN 'LIMITED-QUANTITIES'
                                     ELSE 'AVAILABLE'
                                END ,
                                CASE WHEN ISNULL(iav.qty_avl, 0) <= 0
                                     THEN ISNULL(CONVERT(VARCHAR(8), CASE
                                                              WHEN ISNULL(iav.NextPODueDate,
                                                              @today) < @today
                                                              THEN DATEADD(D,
                                                              1, @today)
                                                              ELSE ISNULL(iav.NextPODueDate,
                                                              '')
                                                              END, 112), '')
                                     ELSE ''
                                END ,
                                i.Wholesale_price ,
                                CASE WHEN i.release_date >= DATEADD(M, -6,
                                                              @today) THEN 'Y'
                                     ELSE 'N'
                                END
                        FROM    dbo.cvo_hs_inventory_8 AS hi
                                JOIN cvo_inv_master_r2_vw i ON i.part_no = hi.sku
                                LEFT OUTER JOIN cvo_apr_tbl #apr ON #apr.sku = i.part_no
                                                              AND @today BETWEEN #apr.eff_date
                                                              AND
                                                              ISNULL(#apr.obs_date,
                                                              @today)
                                LEFT OUTER JOIN dbo.cvo_item_avail_vw AS iav ON iav.part_no = i.part_no
                                                              AND location = @LOCATION
                                LEFT OUTER JOIN #usage
                                AS fccwu ON fccwu.location = @LOCATION
                                            AND fccwu.part_no = i.part_no
                        WHERE   1 = 1
						;

				
						INSERT into dbo.cvo_eyerep_inv_tbl
						(
							sku,
							upc,
							collection_id,
							style,
							color,
							eye_size,
							temple,
							bridge,
							product_rank,
							collection_rank,
							product_type,
							avail_status,
							avail_date,
							base_price,
							new_release
						)
						SELECT
							sku,
							hi.barcode,
							'POP',
							hi.VariantDescription,
							'' AS color,
							'' AS eye_size,
							'' AS temple,
							'' AS bridge,
							99999 AS product_rank,
							9999 AS collection_rank,
							LEFT(iav.REStype, 20),
							CASE
								WHEN ISNULL(iav.qty_avl, 0) <= 0
									 AND ISNULL(iav.SOF, 0) > 0 THEN
									'BACK-ORDERED'
								WHEN ISNULL(iav.qty_avl, 0) <= 0 THEN
									'OUT-OF-STOCK'
								WHEN ISNULL(iav.qty_avl, 0) <= ISNULL(fccwu.e12_wu,
																		 0
																	 ) THEN
									'LIMITED-QUANTITIES'
								ELSE
									'AVAILABLE'
							END,
							CASE
								WHEN ISNULL(iav.qty_avl, 0) <= 0 THEN
									ISNULL(CONVERT(   VARCHAR(8), CASE WHEN ISNULL(iav.NextPODueDate, @today) < @today THEN
															  DATEADD(D, 1, @today )
														  ELSE
															  ISNULL(iav.NextPODueDate, '') END, 112 ), '' )
								ELSE '' END,
							pp.price_a,
							CASE
								WHEN iav.ReleaseDate >= DATEADD(M,-6, @today) THEN 'Y' ELSE 'N' END
						FROM
							dbo.cvo_hs_inventory_8 AS hi
							LEFT OUTER JOIN part_price pp ON pp.part_no = hi.sku
							LEFT OUTER JOIN dbo.cvo_item_avail_vw AS iav
								ON iav.part_no = hi.sku
								   AND location = @location
							LEFT OUTER JOIN #usage AS fccwu
								ON fccwu.location = @location
								   AND fccwu.part_no = hi.sku
						WHERE hi.Manufacturer = 'POP'
						;

						INSERT dbo.cvo_eyerep_inv_tbl
						(
						    sku,
						    upc,
						    collection_id,
						    style,
						    color,
						    eye_size,
						    temple,
						    bridge,
						    product_rank,
						    collection_rank,
						    product_type,
						    avail_status,
						    avail_date,
						    base_price,
						    new_release
						)
						SELECT
							sku,
							hi.barcode,
							hi.coll,
							hi.VariantDescription,
							hi.Color AS color,
							hi.size AS eye_size,
							'' AS temple,
							'' AS bridge,
							99999 AS product_rank,
							9999 AS collection_rank,
							LEFT(iav.REStype, 20),
							CASE
								WHEN ISNULL(iav.qty_avl, 0) <= 0
									 AND ISNULL(iav.SOF, 0) > 0 THEN
									'BACK-ORDERED'
								WHEN ISNULL(iav.qty_avl, 0) <= 0 THEN
									'OUT-OF-STOCK'
								WHEN ISNULL(iav.qty_avl, 0) <= ISNULL(fccwu.e12_wu,
																		 0
																	 ) THEN
									'LIMITED-QUANTITIES'
								ELSE
									'AVAILABLE'
							END,
							CASE
								WHEN ISNULL(iav.qty_avl, 0) <= 0 THEN
									ISNULL(CONVERT(   VARCHAR(8), CASE WHEN ISNULL(iav.NextPODueDate, @today) < @today THEN
															  DATEADD(D, 1, @today )
														  ELSE
															  ISNULL(iav.NextPODueDate, '') END, 112 ), '' )
								ELSE '' END,
							pp.price_a,
							CASE
								WHEN iav.ReleaseDate >= DATEADD(M,-6, @today) THEN 'Y' ELSE 'N' END
						FROM
							dbo.cvo_hs_inventory_8 AS hi
							LEFT OUTER JOIN part_price pp ON pp.part_no = hi.sku
							LEFT OUTER JOIN dbo.cvo_item_avail_vw AS iav
								ON iav.part_no = hi.sku
								   AND location = @location
							LEFT OUTER JOIN #usage AS fccwu
								ON fccwu.location = @location
								   AND fccwu.part_no = hi.sku
						WHERE NOT EXISTS (SELECT 1 FROM cvo_eyerep_inv_tbl eit WHERE eit.sku = hi.sku)
						;


                UPDATE  dbo.cvo_eyerep_inv_tbl
                SET     avail_date = ''
                WHERE   avail_date = '19000101';

-- set product and collection rank for each item based on last 3 months sales

                DECLARE @lm_start DATETIME ,
                    @lm_end DATETIME;
                SELECT  @lm_start = DATEADD(M, -3, drv.BeginDate) ,
                        @lm_end = DATEADD(M, -3, drv.EndDate)
                FROM    dbo.cvo_date_range_vw AS drv
                WHERE   Period = 'Last Month';

                WITH    rr
                          AS ( SELECT   r.category ,
                                        r.style ,
                                        r.m_net ,
                                        RANK() OVER ( PARTITION BY r.category ORDER BY m_net DESC ) AS c_rank ,
                                        RANK() OVER ( ORDER BY m_net DESC ) AS p_rank
                               FROM     ( SELECT    i.category ,
                                                    ia.field_2 style ,
                                                    SUM(sbm.qnet) m_net
                                          FROM      inv_master i
                                                    JOIN inv_master_add ia ON ia.part_no = i.part_no
                                                    JOIN cvo_sbm_details sbm ON i.part_no = sbm.part_no
                                          WHERE     yyyymmdd BETWEEN @lm_start AND @lm_end
                                                    AND i.type_code IN (
                                                    'frame', 'sun' )
                                                    AND RIGHT(sbm.user_category,
                                                              2) NOT IN ( 'CL',
                                                              'RB' )
                                          GROUP BY  i.category ,
                                                    ia.field_2
                                        ) AS r
                             )
                    UPDATE  inv
                    SET     inv.product_rank = rr.p_rank ,
                            inv.collection_rank = rr.c_rank
                    FROM    rr
                            JOIN dbo.cvo_eyerep_inv_tbl AS inv ON inv.collection_id = rr.category
                                                              AND inv.style = rr.style;

-- Collections - 3.2

                IF ( OBJECT_ID('dbo.cvo_eyerep_invcol_tbl') IS NULL )
                    BEGIN
                        CREATE TABLE dbo.cvo_eyerep_invcol_tbl
                            (
                              collection_id VARCHAR(50) NOT NULL ,
                              collection_name VARCHAR(30) NULL
                            )
                        ON  [PRIMARY];
                    END;

                TRUNCATE TABLE dbo.cvo_eyerep_invcol_tbl;

                INSERT  dbo.cvo_eyerep_invcol_tbl
                        ( collection_id ,
                          collection_name
                        )
                        SELECT  kys ,
                                description
                        FROM    dbo.category AS c
                        WHERE   ISNULL(c.void, 'N') = 'N'
                                AND EXISTS ( SELECT 1
                                             FROM   dbo.cvo_eyerep_inv_tbl AS eit
                                             WHERE  eit.collection_id = c.kys );

-- add in qop,eor, etc.
                INSERT  dbo.cvo_eyerep_invcol_tbl
                        ( collection_id ,
                          collection_name
                        )
                        SELECT DISTINCT
                                eit.collection_id ,
                                eit.collection_id
                        FROM    dbo.cvo_eyerep_inv_tbl AS eit
                                LEFT OUTER JOIN cvo_eyerep_invcol_tbl c ON c.collection_id = eit.collection_id
                        WHERE   eit.collection_id NOT IN ( 'frame', 'sun' )
                                AND c.collection_id IS NULL;


-- SELECT * FROM dbo.cvo_eyerep_invcol_tbl AS eit


        IF ( OBJECT_ID('dbo.cvo_eyerep_acthis_tbl') IS NULL )
            BEGIN
                CREATE TABLE dbo.cvo_eyerep_acthis_tbl
                    (
                      account_id VARCHAR(20) NOT NULL ,
                      ship_id VARCHAR(20) NULL ,
                      ORDER_no VARCHAR(20) NOT NULL ,
                      tax_amt DECIMAL(9, 2) NOT NULL ,
                      ship_amt DECIMAL(9, 2) NOT NULL ,
                      WebOrderNumber VARCHAR(13) NULL ,
                      Invoice_no VARCHAR(30) NULL ,
                      upc VARCHAR(50) NULL ,
                      quantity DECIMAL(9, 2) NOT NULL ,
                      price DECIMAL(9, 2) NOT NULL , -- extended price
                      ship_date VARCHAR(8) NULL ,
                      ORDER_status VARCHAR(30) NULL ,
                      order_date VARCHAR(8) NULL ,
                      tracking_no VARCHAR(50) NULL ,
                      tracking_type VARCHAR(50) NULL ,
                      order_type VARCHAR(20) NULL ,
                      line_no VARCHAR(30) NULL
                    )
                ON  [PRIMARY];
            END;


        TRUNCATE TABLE cvo_eyerep_acthis_tbl;

        DECLARE @date INTEGER;
        SET @date = dbo.adm_get_pltdate_f(DATEADD(YEAR, -1, @today));
-- SELECT @date

-- regular invoices

        INSERT  INTO cvo_eyerep_acthis_tbl
                SELECT  customer = ISNULL(xx.customer_code, '') ,
                        ship_to = CASE WHEN xx.ship_to_code <> ''
                                       THEN xx.customer_code + '-'
                                            + xx.ship_to_code
                                       ELSE ''
                                  END ,
                        xx.order_ctrl_num ,
                        xx.amt_tax ,
                        xx.amt_net ,
                        '' AS WebOrderNumber ,
                        xx.doc_ctrl_num ,
                        ISNULL(i.upc_code, '0000000000000') AS upc_code ,
                        ol.shipped - ol.cr_shipped ,
                        CASE o.type
                          WHEN 'i'
                          THEN CASE ISNULL(cl.is_amt_disc, 'n')
                                 WHEN 'y'
                                 THEN ROUND(ol.shipped * ( ol.curr_price
                                                           - ROUND(ISNULL(cl.amt_disc,
                                                              0), 2) ), 2, 1)
                                 ELSE ROUND(ol.shipped * ( ol.curr_price
                                                           - ROUND(ol.curr_price
                                                              * ( ol.discount
                                                              / 100.00 ), 2) ),
                                            2)
                               END
                          ELSE 0
                        END AS asales ,
                        CONVERT(VARCHAR(8), dbo.adm_format_pltdate_f(xx.date_applied), 112) , -- yyyymmdd
                        'Shipped/Transferred' AS order_status ,
                        CONVERT(VARCHAR(8), oo.date_entered, 112) ,
                        ISNULL(ctn.tracking, '') tracking ,
                        ISNULL(ctn.tracking_type, '') tracking_type ,
                        o.user_category ,
                        ol.display_line
                FROM    #AllTerr
                        JOIN orders o ( NOLOCK ) ON o.cust_code = #AllTerr.customer_code
                        INNER JOIN CVO_orders_all co ( NOLOCK ) ON co.order_no = o.order_no
                                                              AND co.ext = o.ext
                        INNER JOIN ord_list ol ( NOLOCK ) ON ol.order_no = o.order_no
                                                             AND ol.order_ext = o.ext
                        LEFT OUTER JOIN CVO_ord_list cl ( NOLOCK ) ON cl.order_no = ol.order_no
                                                              AND cl.order_ext = ol.order_ext
                                                              AND cl.line_no = ol.line_no
                        LEFT OUTER JOIN orders_invoice oi ( NOLOCK ) ON oi.order_no = o.order_no
                                                              AND oi.order_ext = o.ext
                        LEFT OUTER JOIN artrx xx ( NOLOCK ) ON xx.trx_ctrl_num = oi.trx_ctrl_num
                        LEFT OUTER JOIN ( SELECT    order_no ,
                                                    MIN(ooo.date_entered)
                                          FROM      orders ooo ( NOLOCK )
                                          WHERE     ooo.status <> 'v'
                                          GROUP BY  ooo.order_no
                                        ) AS oo ( order_no, date_entered ) ON oo.order_no = o.order_no
-- tag 013114
                        LEFT OUTER JOIN inv_master i ON i.part_no = ol.part_no
                        LEFT OUTER JOIN ( SELECT    order_no ,
                                                    order_ext ,
                                                    MIN(ISNULL(c.cs_tracking_no,
                                                              c.carton_no)) tracking ,
                                                    MIN(c.carrier_code) tracking_type
                                          FROM      tdc_carton_tx c
                                          GROUP BY  c.order_no ,
                                                    c.order_ext
                                        ) ctn ON ctn.order_ext = o.ext
                                                 AND ctn.ORDER_no = o.order_no
                WHERE   1 = 1
                        AND EXISTS ( SELECT 1
                                     FROM   cvo_eyerep_acts_Tbl a
                                     WHERE  a.acct_id = #AllTerr.customer_code )
                        AND xx.date_applied >= @date
                        AND xx.trx_type IN ( 2031, 2032 )
                        AND xx.doc_desc NOT LIKE 'converted%'
                        AND xx.doc_desc NOT LIKE '%nonsales%'
                        AND xx.doc_ctrl_num NOT LIKE 'cb%'
                        AND xx.doc_ctrl_num NOT LIKE 'fin%'
                        AND xx.void_flag = 0
                        AND xx.posted_flag = 1
                        AND o.user_category NOT LIKE ( '%-RB' )
                        AND i.type_code IN ( 'frame', 'sun' )
                        AND 0 <> ( ol.shipped - ol.cr_shipped ); 


-- backorders
-- backord.txt

        IF ( OBJECT_ID('dbo.cvo_eyerep_backord_tbl') IS NULL )
            BEGIN
                CREATE TABLE dbo.cvo_eyerep_backord_tbl
                    (
                      account_id VARCHAR(20) NOT NULL ,
                      ship_id VARCHAR(20) NULL ,
                      ORDER_no VARCHAR(20) NOT NULL ,
                      tax_amt DECIMAL(9, 2) NOT NULL ,
                      ship_amt DECIMAL(9, 2) NOT NULL ,
                      WebOrderNumber VARCHAR(13) NULL ,
                      Invoice_no VARCHAR(30) NULL ,
                      upc VARCHAR(50) NULL ,
                      quantity DECIMAL(9, 2) NOT NULL ,
                      price DECIMAL(9, 2) NOT NULL , -- extended price
                      ship_date VARCHAR(8) NULL ,
                      ORDER_status VARCHAR(30) NULL ,
                      order_date VARCHAR(8) NULL ,
                      tracking_no VARCHAR(50) NULL ,
                      tracking_type VARCHAR(50) NULL ,
                      order_type VARCHAR(20) NULL ,
                      line_no VARCHAR(30) NULL
                    )
                ON  [PRIMARY];
            END;


        TRUNCATE TABLE dbo.cvo_eyerep_backord_tbl;
        INSERT  INTO dbo.cvo_eyerep_backord_tbl
                ( account_id ,
                  ship_id ,
                  ORDER_no ,
                  tax_amt ,
                  ship_amt ,
                  WebOrderNumber ,
                  Invoice_no ,
                  upc ,
                  quantity ,
                  price ,
                  ship_date ,
                  ORDER_status ,
                  order_date ,
                  tracking_no ,
                  tracking_type ,
                  order_type ,
                  line_no
                )
                SELECT  o.cust_code account_id ,
                        CASE WHEN o.ship_to > ''
                             THEN o.cust_code + '-' + o.ship_to
                             ELSE ''
                        END ship_address_id ,
                        o.order_no ,
                        0 AS tax_amount ,
                        0 AS ship_amount ,
                        o.user_def_fld4 webordernumber ,
                        '' AS invoicenumber ,
                        inv.upc_code upc ,
                        ol.ordered - ol.shipped quantity ,
                        ol.curr_price ,
                        CONVERT(VARCHAR(8), o.sch_ship_date, 112) shipdate ,
                        'BACKORDERED' orderstatus ,
                        CONVERT(VARCHAR(8), o.date_entered, 112) orderdate ,
                        '' trackingnumber ,
                        '' trackingtype ,
                        o.user_category ordertype ,
                        ol.line_no lineuniqueid
                FROM    inv_master inv ( NOLOCK )
                        INNER JOIN ord_list ol ( NOLOCK ) ON inv.part_no = ol.part_no
                        INNER JOIN orders o ( NOLOCK ) ON o.order_no = ol.order_no
                                                          AND o.ext = ol.order_ext
                        LEFT OUTER JOIN CVO_orders_all co ( NOLOCK ) ON co.order_no = o.order_no
                                                              AND co.ext = o.ext
                        LEFT OUTER JOIN CVO_promotions p ( NOLOCK ) ON p.promo_id = co.promo_id
                                                              AND p.promo_level = co.promo_level
-- 3/4/15
                        LEFT OUTER JOIN cvo_hard_allocated_vw e ( NOLOCK ) ON e.order_no = o.order_no
                                                              AND e.order_ext = o.ext
                                                              AND e.line_no = ol.line_no
                                                              AND e.order_type = 's'
                WHERE   1 = 1
                        AND o.cust_code IN ( SELECT DISTINCT
                                                    customer_code
                                             FROM   #AllTerr )
                        AND o.type = 'i'
                        AND inv.type_code IN ( 'frame', 'sun' )
                        AND ol.status < 'P'
                        AND o.status < 'p'
                        AND ol.ordered > ( ol.shipped + ISNULL(e.qty, 0) )
-- and o.sch_ship_date < @today
                        AND ol.part_type = 'p'
                        AND o.who_entered = 'backordr';

    END; -- ACTIVITY






GO
