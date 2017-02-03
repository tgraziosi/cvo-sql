SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_commission_statement_sp]
    @FiscalPeriod VARCHAR(10)
AS -- exec cvo_commission_statement_sp '10/2016'

    SET NOCOUNT ON;

    BEGIN

        DECLARE @start_date DATETIME ,
            @end_date DATETIME ,
            @fp VARCHAR(10) ,
            @drawweeks INT ,
            @year INT ,
            @prior_year INT ,
            @month INT;

--DECLARE @fiscalperiod VARCHAR(10)
-- SELECT @fiscalperiod = '01/2016'
        SELECT  @fp = @FiscalPeriod;

        SELECT  @start_date = CAST(LEFT(@fp, 2) AS VARCHAR(2)) + '/1/'
                + CAST(RIGHT(@fp, 4) AS VARCHAR(4));

        SELECT  @end_date = DATEADD(d, -1, DATEADD(m, 1, @start_date));

        SELECT  @year = CAST(RIGHT(@fp, 4) AS INT) ,
                @month = CAST(LEFT(@fp, 2) AS INT);

        SELECT  @prior_year = @year - 1;

-- SELECT @fp, @start_date, @end_date, @year, @prior_year

        IF ( OBJECT_ID('tempdb.dbo.#mm') IS NOT NULL )
            DROP TABLE #mm;

        CREATE TABLE #mm
            (
              salesperson VARCHAR(20) ,
              salesperson_name VARCHAR(50) ,
              territory VARCHAR(5) ,
              region VARCHAR(5) ,
              mm VARCHAR(2)
            );

        DECLARE @i INT;
        SELECT  @i = 1;

        WHILE @i < 13
            BEGIN
                INSERT  #mm
                        ( salesperson ,
                          salesperson_name ,
                          territory ,
                          region ,
                          mm
                        )
                        SELECT DISTINCT
                                salesperson ,
                                salesperson_name ,
                                ccswt.territory ,
                                dbo.calculate_region_fn(ccswt.territory) region ,
                                RIGHT('00' + CAST(@i AS VARCHAR(2)), 2) mm
                        FROM    dbo.cvo_commission_summary_work_tbl AS ccswt;
                SELECT  @i = @i + 1;
            END;

        SELECT  ty.id ,
                #mm.salesperson ,
                #mm.salesperson_name ,
                ty.hiredate ,
                ISNULL(ty.amount, 0) amount ,
                ISNULL(ty.comm_amt, 0) comm_amt ,
                ISNULL(ty.draw_amount, 0) draw_amount ,
                ty.draw_weeks ,
                ISNULL(ty.commission, 0) commission ,
                ISNULL(ty.incentivePC, 0) incentivePC ,
                ISNULL(ty.incentive, 0) incentive ,
                addition1 = addition1.addition1,
				addition2 = addition2.addition2,
                addition3 = addition3.addition3,

                additionrsn1 = addition1.additionrsn1,
				additionrsn2 = CASE WHEN #mm.mm = additionalrsn2.month_num
                                    THEN ISNULL(additionalrsn2.promo_details,
                                                '')
                                    ELSE ''
                               END ,
                additionrsn3 = addition3.additionrsn3,

                reduction1 = reductionrsn1.reduction1 ,
                reductionrsn1 = reductionrsn1.reductionrsn1 ,
                ISNULL(ty.rep_type, 0) rep_type ,
                ISNULL(ty.status_type, 0) status_type ,
                #mm.territory territory ,
                #mm.region region ,
                ISNULL(ty.total_earnings, 0) total_earnings ,
                ISNULL(ty.total_draw, 0) total_draw ,
                ISNULL(ty.prior_month_bal, 0) prior_month_bal ,
                ISNULL(ty.net_pay, 0) net_pay ,
                ty.report_month ,
                ty.current_flag ,
                ISNULL(ty.promo_detail, '') promo_detail ,
                ISNULL(ty.promo_sum, 0) promo_sum ,
                #mm.mm month_num ,
                @prior_year year_ly ,
                CASE WHEN ISNULL(lyhist.total_earnings, 0) <> 0
                     THEN lyhist.total_earnings
                     ELSE ISNULL(ly.total_earnings, 0)
                END AS total_earnings_ly ,
                general_note = general.comments ,
                spec_pay.spec_pay
        FROM    #mm
                LEFT OUTER JOIN ( SELECT    id ,
                                            salesperson ,
                                            hiredate ,
                                            amount ,
                                            comm_amt ,
                                            draw_amount ,
                                            draw_weeks ,
                                            commission ,
                                            incentivePC ,
                                            incentive ,
                                            other_additions ,
                                            reduction ,
                                            addition_rsn ,
                                            reduction_rsn ,
                                            rep_type ,
                                            status_type ,
                                            territory ,
                                            region ,
                                            total_earnings ,
                                            total_draw ,
                                            prior_month_bal ,
                                            net_pay ,
                                            report_month ,
                                            current_flag ,
                                            promo_detail ,
                                            promo_sum
                                  FROM      cvo_commission_summary_work_tbl
                                  WHERE     @year = CAST(RIGHT(report_month, 4) AS INT)
                                            AND @month > = CAST(LEFT(report_month,
                                                              2) AS INT)
                                ) ty ON ty.salesperson = #mm.salesperson
                                        AND #mm.mm = LEFT(ty.report_month, 2)
                LEFT OUTER JOIN ( SELECT    c.salesperson ,
                                            LEFT(c.report_month, 2) month_num ,
                                            c.total_earnings
                                  FROM      cvo_commission_history_tbl c
                                  WHERE     CAST(RIGHT(c.report_month, 4) AS INT) = @year
                                            AND @month > = CAST(LEFT(report_month,
                                                              2) AS INT)
                                ) tyhist ON #mm.salesperson = tyhist.salesperson
                                            AND #mm.mm = tyhist.month_num
                LEFT OUTER JOIN ( SELECT    c.salesperson ,
                                            LEFT(c.report_month, 2) month_num ,
                                            ISNULL(total_earnings, 0.00) total_earnings
                                  FROM      cvo_commission_summary_work_tbl c
                                  WHERE     CAST(RIGHT(c.report_month, 4) AS INT) = @prior_year
                                ) ly ON #mm.salesperson = ly.salesperson
                                        AND #mm.mm = ly.month_num
                LEFT OUTER JOIN ( SELECT    c.salesperson ,
                                            LEFT(c.report_month, 2) month_num ,
                                            c.total_earnings
                                  FROM      cvo_commission_history_tbl c
                                  WHERE     CAST(RIGHT(c.report_month, 4) AS INT) = @prior_year
                                ) lyhist ON #mm.salesperson = lyhist.salesperson
                                            AND lyhist.month_num = #mm.mm
				LEFT OUTER JOIN ( SELECT	cpv.rep_code, 
											LEFT(cpv.recorded_month,2) month_num,
											SUM(ISNULL(incentive_amount, 0)) addition1,
											MAX(ISNULL(cpv.comments,'')) additionrsn1
											 -- closeouts
                              FROM      dbo.cvo_commission_promo_values AS cpv

                              WHERE     RIGHT(cpv.recorded_month, 4) = @year
                                        AND cpv.line_type = 'Close Out Adj'
							  GROUP BY cpv.rep_code ,
									   LEFT(cpv.recorded_month,2)
                              HAVING    SUM(ISNULL(incentive_amount, 0)) > 0
                            ) addition1 ON #mm.salesperson = addition1.rep_code
										AND  #mm.mm = addition1.month_num 
				LEFT OUTER JOIN ( SELECT	cpv.rep_code, 
											LEFT(cpv.recorded_month,2) month_num,
											SUM(ISNULL(incentive_amount, 0)) addition2
											 -- closeouts
                              FROM      dbo.cvo_commission_promo_values AS cpv

                              WHERE     RIGHT(cpv.recorded_month, 4) = @year
                                        AND LTRIM(RTRIM(cpv.line_type)) IN (
                                        'Adj/Additional Adj 1',
                                        'Adj/Additional Adj 2' )
							  GROUP BY cpv.rep_code ,
									   LEFT(cpv.recorded_month,2)
                              HAVING    SUM(ISNULL(incentive_amount, 0)) > 0
                            ) addition2 ON #mm.salesperson = addition2.rep_code
										AND  #mm.mm = addition2.month_num 
				 LEFT OUTER JOIN ( SELECT	cpv.rep_code, 
											LEFT(cpv.recorded_month,2) month_num,
											SUM(ISNULL(incentive_amount, 0)) addition3,
											MAX(ISNULL(cpv.comments, '')) additionrsn3
											 -- closeouts
                              FROM      dbo.cvo_commission_promo_values AS cpv

                              WHERE     RIGHT(cpv.recorded_month, 4) = @year
                                        AND LTRIM(RTRIM(cpv.line_type)) IN ('Adj/Additional Adj 3' )
							  GROUP BY cpv.rep_code ,
									   LEFT(cpv.recorded_month,2)
                              HAVING    SUM(ISNULL(incentive_amount, 0)) > 0
                            ) addition3 ON #mm.salesperson = addition3.rep_code
										AND  #mm.mm = addition3.month_num 
                LEFT OUTER JOIN ( SELECT DISTINCT
                                            c.rep_code ,
                                            LEFT(c.recorded_month, 2) month_num ,
                                            REPLACE(STUFF(( SELECT DISTINCT
                                                              '; '
                                                              + ISNULL(ccpv2.comments,
                                                              '')
                                                            FROM
                                                              dbo.cvo_commission_promo_values
                                                              AS ccpv2
                                                            WHERE
                                                              c.rep_code = ccpv2.rep_code
                                                              AND ISNULL(ccpv2.line_type,
                                                              '') IN (
                                                              'Adj/Additional Adj 1',
                                                              'Adj/Additional Adj 2' )
                                                              AND ISNULL(ccpv2.incentive_amount,
                                                              0) > 0
                                                              AND LEFT(ccpv2.recorded_month,
                                                              2) = LEFT(c.recorded_month,
                                                              2)
                                                          FOR
                                                            XML
                                                              PATH('')
                                                          ), 1, 1, ''),
                                                    '&amp;', '&') promo_details
                                  FROM      dbo.cvo_commission_promo_values AS c
                                  WHERE     CAST(RIGHT(c.recorded_month, 4) AS INT) = @year
                                            AND c.recorded_month <= @FiscalPeriod
                                ) additionalrsn2 ON #mm.salesperson = additionalrsn2.rep_code
                                                    AND #mm.mm = additionalrsn2.month_num
                LEFT OUTER JOIN ( SELECT DISTINCT
                                            c.rep_code ,
                                            LEFT(c.recorded_month, 2) month_num ,
                                            ISNULL(c.incentive_amount, 0) reduction1 ,
                                            REPLACE(STUFF(( SELECT DISTINCT
                                                              '; '
                                                              + ISNULL(ccpv2.comments,
                                                              '')
                                                            FROM
                                                              dbo.cvo_commission_promo_values
                                                              AS ccpv2
                                                            WHERE
                                                              c.rep_code = ccpv2.rep_code
                                                              AND ccpv2.recorded_month = @FiscalPeriod
                                                              AND ISNULL(ccpv2.line_type,
                                                              '') IN (
                                                              'Manual Reduction' )
                                                              AND ISNULL(ccpv2.incentive_amount,
                                                              0) <= 0
                                                          FOR
                                                            XML
                                                              PATH('')
                                                          ), 1, 1, ''),
                                                    '&amp;', '&') reductionrsn1
                                  FROM      dbo.cvo_commission_promo_values AS c
                                  WHERE     CAST(RIGHT(c.recorded_month, 4) AS INT) = @year
                                            AND LEFT(c.recorded_month, 2) <= LEFT(@FiscalPeriod,
                                                              2)
                                            AND ISNULL(c.incentive_amount, 0) < 0
                                            AND c.line_type IN (
                                            'manual reduction' )
                                ) reductionrsn1 ON #mm.salesperson = reductionrsn1.rep_code
                                                   AND #mm.mm = reductionrsn1.month_num
                LEFT OUTER JOIN ( SELECT DISTINCT
                                            rep_code ,
                                            comments
                                  FROM      dbo.cvo_commission_promo_values
                                  WHERE     line_type = 'General'
                                            AND recorded_month = 'Note'
                                ) general ON #mm.salesperson = general.rep_code
                LEFT OUTER JOIN ( SELECT    rep_code ,
                                            LEFT(recorded_month, 2) month_num ,
                                            SUM(ISNULL(incentive_amount, 0)) spec_pay
                                  FROM      dbo.cvo_commission_promo_values
                                  WHERE     line_type = 'special payment'
                                            AND @year = CAST(RIGHT(recorded_month,
                                                              4) AS INT)
                                  GROUP BY  LEFT(recorded_month, 2) ,
                                            rep_code
                                ) spec_pay ON #mm.salesperson = spec_pay.rep_code
                                              AND #mm.mm = spec_pay.month_num
        ORDER BY salesperson;


    END;





GO
GRANT EXECUTE ON  [dbo].[cvo_commission_statement_sp] TO [public]
GO
