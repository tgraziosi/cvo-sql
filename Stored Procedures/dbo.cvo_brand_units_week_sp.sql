SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_brand_units_week_sp] 
AS -- exec cvo_brand_units_week_sp 

    SET NOCOUNT ON;
	SET ANSI_WARNINGS OFF;

--  SELECT * FROM dbo.cvo_brand_units_week_tbl AS buwt WHERE REC_TYPE = 'S' and model = 'camilla'
-- drop table cvo_brand_units_week_tbl
	

    IF ( OBJECT_ID('dbo.cvo_brand_units_week_tbl') IS NULL )
        BEGIN
            CREATE TABLE dbo.cvo_brand_units_week_tbl
                (
                  brand VARCHAR(10) ,
                  MODEL VARCHAR(40) ,
                  rel_date DATETIME ,
                  type_code VARCHAR(10) ,
                  rel_date_wk INT ,
                  first_wk INT ,
		          wkno BIGINT ,
                  num_cust INT ,
				  -- num_cust_Ret INT,
                  sales_qty FLOAT(8) ,
                  st_qty FLOAT(8) null,
                  rx_qty FLOAT(8) null ,
                  ret_qty FLOAT(8) null ,
                  cl_qty FLOAT(8) NULL ,
				  rec_type VARCHAR(1),
                  asofdate DATETIME
                );
            CREATE INDEX idx_brand_units_week 
            ON dbo.cvo_brand_units_week_tbl
            (brand ASC, MODEL ASC, wkno ASC);
        END;

    TRUNCATE TABLE cvo_brand_units_week_tbl;



    IF ( OBJECT_ID('tempdb.dbo.#cte') IS NOT NULL ) DROP TABLE dbo.#cte;

	-- collect sales
	SELECT   i.category brand ,
        ia.field_2 MODEL ,
        MIN(ia.field_26) rel_date ,
        i.type_code ,
        MIN(CASE WHEN qsales <> 0 THEN yyyymmdd ELSE null END) first_sale ,
		MIN(CASE WHEN sbm.return_code NOT IN ('exc') AND qreturns <> 0 THEN yyyymmdd ELSE NULL end) first_return,
        AR.customer_code + CASE WHEN car.door = 1
                                THEN '-' + AR.ship_to_code
                                ELSE ''
                            END AS customer ,
        SUM(qsales) sales_qty ,
        SUM(CASE WHEN sbm.user_category NOT LIKE 'rx%'
                    THEN qsales
                    ELSE 0
            END) st_qty ,
        SUM(CASE WHEN sbm.user_category LIKE 'rx%'
                    THEN qsales
                    ELSE 0
            END) rx_qty ,
		SUM(CASE WHEN sbm.return_code not in ('exc') and qreturns <> 0
                    THEN qreturns
                    ELSE 0
            END) ret_qty ,
        SUM(CASE WHEN sbm.isCL = 1 THEN qsales
                    ELSE 0
        END) cl_qty
		INTO #cte
		FROM     cvo_sbm_details sbm
				JOIN dbo.CVO_armaster_all AS car ON car.ship_to = sbm.ship_to
													AND car.customer_code = sbm.customer
				JOIN armaster AR ON AR.customer_code = car.customer_code
									AND AR.ship_to_code = car.ship_to
				JOIN inv_master i ON i.part_no = sbm.part_no
				JOIN dbo.inv_master_add AS ia ON ia.part_no = i.part_no
		WHERE    yyyymmdd >= DATEADD(YEAR, -2, GETDATE())
				AND ia.field_26 >= DATEADD(YEAR, -2, GETDATE())
				--AND i.category = CASE WHEN @coll IS NULL
				--						THEN i.category
				--						ELSE @coll
				--					END
				AND i.type_code IN ( 'frame', 'sun' )
				AND ISNULL(ia.field_32, '') NOT IN ( 'hvc',
													'retail',
													'specialord' )
		GROUP BY AR.customer_code + CASE WHEN car.door = 1
										THEN '-' + AR.ship_to_code
										ELSE ''
									END ,
				i.category ,
				ia.field_2 ,
				i.type_code
				;
        
		-- sales
        INSERT  INTO dbo.cvo_brand_units_week_tbl
                ( brand ,
                  MODEL ,
                  rel_date ,
                  type_code ,
                  rel_date_wk ,
                  first_wk ,
			      wkno ,
                  num_cust ,
				  sales_qty ,
                  st_qty ,
                  rx_qty ,
                  -- ret_qty ,
                  cl_qty ,
				  rec_type,
                  asofdate
                )
                SELECT  cte.brand ,
                        cte.MODEL ,
                        CONVERT(DATETIME, cte.rel_date, 110) rel_date ,
                        cte.type_code ,
                        CAST(CAST (DATEPART(YEAR, cte.rel_date) AS VARCHAR(4))
                        + RIGHT('00'
                                + CAST(DATEPART(WEEK, cte.rel_date) AS VARCHAR(2)),
                                2) AS INT) AS rel_date_wk ,
                        CAST(CAST (DATEPART(YEAR, cte.first_sale) AS VARCHAR(4))
                        + RIGHT('00'
                                + CAST(DATEPART(WEEK, cte.first_sale) AS VARCHAR(2)),
                                2) AS INT) AS first_wk ,
								
						DATEDIFF(WEEK, rel_date, MIN(first_sale)) + 1 AS wkno,

                        COUNT(DISTINCT cte.customer) num_cust ,
						-- SUM(CASE WHEN ret_qty <> 0 THEN 1 else 0 end) AS num_cust_ret,
                        SUM(cte.sales_qty) sales_qty ,
                        SUM(cte.st_qty) st_qty ,
                        SUM(cte.rx_qty) rx_qty ,
                        -- SUM(cte.ret_qty) ret_qty ,
                        SUM(cte.cl_qty) cl_qty ,
						'S' AS rec_type,
                        GETDATE()
                FROM    #cte cte
				WHERE cte.sales_qty <> 0 AND cte.first_sale IS NOT null
                GROUP BY cte.brand ,
                        cte.MODEL ,
                        cte.rel_date ,
                        cte.type_code ,
                        CAST(CAST (DATEPART(YEAR, cte.first_sale) AS VARCHAR(4))
                        + RIGHT('00'
                                + CAST(DATEPART(WEEK, cte.first_sale) AS VARCHAR(2)),
                                2) AS INT)
		                ORDER BY cte.brand ,
                        cte.MODEL ,
                        wkno;

		-- returns
		        INSERT  INTO dbo.cvo_brand_units_week_tbl
                ( brand ,
                  MODEL ,
                  rel_date ,
                  type_code ,
                  rel_date_wk ,
                  first_wk ,
		          wkno ,
                  num_cust ,
		          --sales_qty ,
            --      st_qty ,
            --      rx_qty ,
                  ret_qty ,
            --      cl_qty ,
				  rec_type,
                  asofdate
                )
                SELECT  cte.brand ,
                        cte.MODEL ,
                        CONVERT(DATETIME, cte.rel_date, 110) rel_date ,
                        cte.type_code ,
                        CAST(CAST (DATEPART(YEAR, cte.rel_date) AS VARCHAR(4))
                        + RIGHT('00'
                                + CAST(DATEPART(WEEK, cte.rel_date) AS VARCHAR(2)),
                                2) AS INT) AS rel_date_wk ,
                		CAST(CAST (DATEPART(YEAR, cte.first_return) as VARCHAR(4))
                        + RIGHT('00'
                                + CAST(DATEPART(WEEK, cte.first_Return) AS VARCHAR(2)),
                                2) AS INT) AS first_wk ,

						DATEDIFF(WEEK, rel_date, MIN(first_Return)) + 1 AS wkno,
						SUM(CASE WHEN ret_qty <> 0 THEN 1 else 0 end) AS NUM_CUST,
                        SUM(cte.ret_qty) ret_qty ,
        				'R' AS rec_type,
                        GETDATE()
                FROM    #cte cte
				WHERE cte.ret_qty <> 0 AND cte.first_return IS NOT NULL
                GROUP BY cte.brand ,
                        cte.MODEL ,
                        cte.rel_date ,
                        cte.type_code ,
   					    CAST(CAST (DATEPART(YEAR, cte.first_return) AS VARCHAR(4))
                        + RIGHT('00'
                                + CAST(DATEPART(WEEK, cte.first_return) AS VARCHAR(2)),
                                2) AS INT)
                ORDER BY cte.brand ,
                        cte.MODEL ,
                        wkno;

			
		-- select * From #cte where model = 'acclaimed' order by first_brand_sale

		-- SELECT * FROM dbo.cvo_brand_units_week_tbl AS buwt WHERE REC_TYPE = 'R'

		--SELECT                         CAST(CAST (DATEPART(YEAR, yyyymmdd) AS VARCHAR(4))
  --                      + RIGHT('00'
  --                              + CAST(DATEPART(WEEK, yyyymmdd) AS VARCHAR(2)),
  --                              2) AS INT), * FROM cvo_sbm_details WHERE part_no LIKE 'asacc%' ORDER BY yyyymmdd

GO
