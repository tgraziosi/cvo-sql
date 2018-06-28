SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_commission_statement_sp] @FiscalPeriod VARCHAR(10)
AS

-- exec cvo_commission_statement_sp '05/2018'

SET NOCOUNT ON;

BEGIN

    DECLARE @start_date DATETIME,
            @end_date DATETIME,
            @fp VARCHAR(10),
            @drawweeks INT,
            @year INT,
            @prior_year INT,
            @month INT,
            @i INT;

    --DECLARE @fiscalperiod VARCHAR(10);
    --SELECT @FiscalPeriod = '04/2018';

    SELECT @fp = @FiscalPeriod;

    SELECT @start_date = CAST(LEFT(@fp, 2) AS VARCHAR(2)) + '/1/' + CAST(RIGHT(@fp, 4) AS VARCHAR(4));

    SELECT @end_date = DATEADD(d, -1, DATEADD(m, 1, @start_date));

    SELECT @year = CAST(RIGHT(@fp, 4) AS INT),
           @month = CAST(LEFT(@fp, 2) AS INT);

    SELECT @prior_year = @year - 1;

    -- SELECT @fp, @start_date, @end_date, @year, @prior_year

    IF (OBJECT_ID('tempdb.dbo.#mm') IS NOT NULL)
        DROP TABLE #mm;

    CREATE TABLE #mm
    (
        salesperson VARCHAR(20),
        salesperson_name VARCHAR(50),
        territory VARCHAR(8),
        region VARCHAR(5),
        hiredate DATETIME,
        termdate DATETIME,
        status_Type INT,
        rep_type INT,
        commission DECIMAL(5, 2),
        mm VARCHAR(2)
    );

    -- rebuild the summary too - 8/28/2017

    -- exec cvo_commiss_bldr_create_summary_sp @fp

    ;
    WITH months
    AS
    (
    SELECT 1 AS mm
    UNION ALL
    SELECT mm + 1
    FROM months
    WHERE mm + 1 <= 12
    )
    INSERT INTO #mm
    SELECT sp.salesperson_code salesperson,
           sp.salesperson_name,
           sp.territory_code territory,
           dbo.calculate_region_fn(sp.territory_code) region,
           ISNULL(dbo.adm_format_pltdate_f(sp.date_hired), '1/1/1900') hiredate,
           ISNULL(dbo.adm_format_pltdate_f(sp.date_terminated), '12/31/2099') termdate,
           sp.status_type,
           sp.salesperson_type,
           comm.commission,
           RIGHT('00' + CAST(months.mm AS VARCHAR(2)), 2) mm
    FROM dbo.arsalesp sp
        CROSS JOIN months
        LEFT OUTER JOIN
        (
        SELECT salesperson,
               commission,
               ccswt.report_month
        FROM dbo.cvo_commission_summary_work_tbl AS ccswt
        WHERE ccswt.id =
        (
        SELECT MAX(id)
        FROM dbo.cvo_commission_summary_work_tbl AS cswt
        WHERE cswt.salesperson = ccswt.salesperson
        )
        ) comm
            ON comm.salesperson = sp.salesperson_code
    WHERE sp.status_type = 1 OR (ISNULL(sp.status_type,0) <> 1 AND YEAR(ISNULL(dbo.adm_format_pltdate_f(sp.date_terminated), '12/31/2099'))
    										 >= YEAR(DATEADD(month,1,LEFT(@FiscalPeriod,2)+'/1/'+RIGHT(@FiscalPeriod,4))));

    --;
    --WITH months
    --AS
    --(
    --SELECT 1 AS mm
    --UNION ALL
    --SELECT mm + 1
    --FROM months
    --WHERE mm + 1 <= 12
    --)
    --INSERT INTO #mm
    --SELECT sp.salesperson_code salesperson,
    --       sp.salesperson_name,
    --       t.territory_code territory,
    --       dbo.calculate_region_fn(t.territory_code) region,
    --       ISNULL(dbo.adm_format_pltdate_f(sp.date_hired), '1/1/1900') hiredate,
    --       ISNULL(dbo.adm_format_pltdate_f(sp.date_terminated), '12/31/2099') termdate,
    --       sp.status_type,
    --       sp.salesperson_type,
    --       comm.commission,
    --       RIGHT('00' + CAST(months.mm AS VARCHAR(2)), 2) mm
    --FROM dbo.arterr AS t
    --    LEFT OUTER JOIN dbo.arsalesp sp
    --        ON sp.territory_code = t.territory_code
    --    LEFT OUTER JOIN
    --    (
    --    SELECT salesperson,
    --           commission,
    --           ccswt.report_month
    --    FROM dbo.cvo_commission_summary_work_tbl AS ccswt
    --    WHERE ccswt.id =
    --    (
    --    SELECT MAX(id)
    --    FROM dbo.cvo_commission_summary_work_tbl AS cswt
    --    WHERE cswt.salesperson = ccswt.salesperson
    --    )
    --    ) comm
    --        ON comm.salesperson = sp.salesperson_code
    --    CROSS JOIN months
    --WHERE sp.status_type = 1
    --      OR
    --      (
    --      ISNULL(sp.status_type, 0) <> 1
    --      AND EXISTS
    --(
    --SELECT 1
    --FROM dbo.cvo_commission_bldr_work_tbl AS cbwt
    --WHERE cbwt.Territory = t.territory_code
    --      AND RIGHT(cbwt.fiscal_period, 4) >= @prior_year
    --)
    --      );



    SELECT ty.id,
           #mm.salesperson,
           #mm.salesperson_name,
           #mm.hiredate,
           #mm.termdate,
           ISNULL(ty.amount, 0) amount,
           ISNULL(ty.acc_amount, 0) acc_amount,
           ISNULL(ty.comm_amt, 0) comm_amt,
           ISNULL(ty.draw_amount, 0.00) draw_amount,
           ty.draw_weeks,
           ISNULL(ty.commission, #mm.commission) commission,
           ISNULL(ty.incentivePC, 0) incentivePC,
           ISNULL(ty.incentive, 0) incentive,
           addition1.addition1 addition1,
           addition2.addition2 addition2,
           addition3.addition3 addition3,
           addition1.additionrsn1 additionrsn1,
           CASE WHEN #mm.mm = additionalrsn2.month_num THEN ISNULL(additionalrsn2.promo_details, '') ELSE '' END additionrsn2,
           CASE WHEN #mm.mm = additionalrsn3.month_num THEN ISNULL(additionalrsn3.additionalrsn3, '') ELSE '' END additionrsn3,
           reductionrsn1.reduction1 reduction1,
           reductionrsn1.reductionrsn1 reductionrsn1,
           -- iSNULL(ty.rep_type, 0) rep_type ,
           -- ISNULL(ty.status_type, 0) status_type ,
           #mm.rep_type,
           #mm.status_Type,
           #mm.territory territory,
           #mm.region region,
           ISNULL(ty.total_earnings, 0) total_earnings,
           ISNULL(ty.total_draw, 0) total_draw,
           ISNULL(ty.prior_month_bal, 0) prior_month_bal,
           ISNULL(ty.net_pay, 0) net_pay,
           ty.report_month,
           ty.current_flag,
           ISNULL(ty.promo_detail, '') promo_detail,
           ISNULL(ty.promo_sum, 0) promo_sum,
           #mm.mm month_num,
           @prior_year year_ly,
           CASE WHEN ISNULL(lyhist.total_earnings, 0) <> 0 THEN lyhist.total_earnings ELSE ISNULL(ly.total_earnings, 0) END AS total_earnings_ly,
           general.comments general_note,
           spec_pay.spec_pay
    INTO #final
    FROM #mm
        LEFT OUTER JOIN
        (
        SELECT cswt.id,
               cswt.salesperson,
               cswt.amount,
               ISNULL(acc.acc_amount, 0) acc_amount,
               cswt.comm_amt,
               cswt.draw_amount,
               cswt.draw_weeks,
               cswt.commission,
               cswt.incentivePC,
               cswt.incentive,
               cswt.other_additions,
               cswt.reduction,
               cswt.addition_rsn,
               cswt.reduction_rsn,
               cswt.territory,
               cswt.region,
               cswt.total_earnings,
               cswt.total_draw,
               cswt.prior_month_bal,
               cswt.net_pay,
               cswt.report_month,
               cswt.current_flag,
               cswt.promo_detail,
               cswt.promo_sum
        FROM dbo.cvo_commission_summary_work_tbl cswt
            LEFT OUTER JOIN
            (
            SELECT cbwt.fiscal_period,
                   Salesperson,
                   Territory,
                   SUM(Amount) acc_amount
            FROM dbo.cvo_commission_bldr_work_tbl AS cbwt
            WHERE Brand = 'ACC'
            GROUP BY cbwt.fiscal_period,
                     cbwt.Salesperson,
                     cbwt.Territory
            ) acc
                ON acc.Salesperson = cswt.salesperson
                   AND acc.Territory = cswt.territory
                   AND acc.fiscal_period = cswt.report_month
        WHERE @year = CAST(RIGHT(cswt.report_month, 4) AS INT)
              AND @month >= CAST(LEFT(cswt.report_month, 2) AS INT)
        ) ty
            ON ty.salesperson = #mm.salesperson
               AND #mm.mm = LEFT(ty.report_month, 2)
               AND #mm.territory = ty.territory -- 7/17
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               c.salesperson,
               c.territory,
               LEFT(c.report_month, 2) month_num,
               c.total_earnings
        FROM dbo.cvo_commission_history_tbl c
        WHERE CAST(RIGHT(c.report_month, 4) AS INT) = @year
              AND @month >= CAST(LEFT(report_month, 2) AS INT)
        ) tyhist
            ON #mm.salesperson = tyhist.salesperson
               AND #mm.mm = tyhist.month_num
               AND #mm.territory = tyhist.territory
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               c.salesperson,
               c.territory,
               LEFT(c.report_month, 2) month_num,
               ISNULL(total_earnings, 0.00) total_earnings
        FROM dbo.cvo_commission_summary_work_tbl c
        WHERE CAST(RIGHT(c.report_month, 4) AS INT) = @prior_year
        ) ly
            ON #mm.salesperson = ly.salesperson
               AND #mm.mm = ly.month_num
               AND #mm.territory = ly.territory -- 7/17
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               c.salesperson,
               c.territory,
               LEFT(c.report_month, 2) month_num,
               c.total_earnings
        FROM dbo.cvo_commission_history_tbl c
        WHERE CAST(RIGHT(c.report_month, 4) AS INT) = @prior_year
        ) lyhist
            ON #mm.salesperson = lyhist.salesperson
               AND lyhist.month_num = #mm.mm
               AND lyhist.territory = #mm.territory
        LEFT OUTER JOIN
        (
        SELECT cpv.rep_code,
               cpv.territory,
               LEFT(cpv.recorded_month, 2) month_num,
               SUM(ISNULL(incentive_amount, 0)) addition1,
               MAX(ISNULL(cpv.comments, '')) additionrsn1
        -- closeouts
        FROM dbo.cvo_commission_promo_values AS cpv
        WHERE cpv.line_type = 'Close Out Adj'
              AND RIGHT(cpv.recorded_month, 4) = @year
        GROUP BY cpv.rep_code,
                 cpv.territory,
                 LEFT(cpv.recorded_month, 2)
        HAVING SUM(ISNULL(incentive_amount, 0)) > 0
        ) addition1
            ON #mm.salesperson = addition1.rep_code
               AND #mm.mm = addition1.month_num
               AND #mm.territory = addition1.territory
        LEFT OUTER JOIN
        (
        SELECT cpv.rep_code,
               cpv.territory,
               LEFT(cpv.recorded_month, 2) month_num,
               SUM(ISNULL(incentive_amount, 0)) addition2
        -- closeouts
        FROM dbo.cvo_commission_promo_values AS cpv
        WHERE RIGHT(cpv.recorded_month, 4) = @year
              AND LTRIM(RTRIM(cpv.line_type)) IN ( 'Adj/Additional Adj 1', 'Adj/Additional Adj 2' )
        GROUP BY cpv.rep_code,
                 cpv.territory,
                 LEFT(cpv.recorded_month, 2)
        HAVING SUM(ISNULL(incentive_amount, 0)) > 0
        ) addition2
            ON #mm.salesperson = addition2.rep_code
               AND #mm.mm = addition2.month_num
               AND #mm.territory = addition2.territory
        LEFT OUTER JOIN
        (
        SELECT cpv.rep_code,
               cpv.territory,
               LEFT(cpv.recorded_month, 2) month_num,
               SUM(ISNULL(incentive_amount, 0)) addition3
        -- closeouts
        FROM dbo.cvo_commission_promo_values AS cpv
        WHERE RIGHT(cpv.recorded_month, 4) = @year
              AND LTRIM(RTRIM(cpv.line_type)) IN ( 'Adj/Additional Adj 3' )
        GROUP BY cpv.rep_code,
                 cpv.territory,
                 LEFT(cpv.recorded_month, 2)
        HAVING SUM(ISNULL(incentive_amount, 0)) > 0
        ) addition3
            ON #mm.salesperson = addition3.rep_code
               AND #mm.mm = addition3.month_num
               AND #mm.territory = addition3.territory
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               c.rep_code,
               c.territory,
               LEFT(c.recorded_month, 2) month_num,
               REPLACE(STUFF(
                       (
                       SELECT DISTINCT
                              '; ' + ISNULL(ccpv2.comments, '')
                       FROM dbo.cvo_commission_promo_values AS ccpv2
                       WHERE c.rep_code = ccpv2.rep_code
                             AND c.territory = ccpv2.territory
                             AND ISNULL(ccpv2.line_type, '') IN ( 'Adj/Additional Adj 1', 'Adj/Additional Adj 2' )
                             AND ISNULL(ccpv2.incentive_amount, 0) > 0
                             AND LEFT(ccpv2.recorded_month, 2) = LEFT(c.recorded_month, 2)
                             AND @year = RIGHT(ccpv2.recorded_month, 4) -- 2/10
                       FOR XML PATH('')
                       ),
                       1,
                       1,
                       ''
                            ),
                       '&amp;',
                       '&'
                      ) promo_details
        FROM dbo.cvo_commission_promo_values AS c
        WHERE CAST(RIGHT(c.recorded_month, 4) AS INT) = @year
              AND c.recorded_month <= @FiscalPeriod
        ) additionalrsn2
            ON #mm.salesperson = additionalrsn2.rep_code
               AND #mm.mm = additionalrsn2.month_num
               AND #mm.territory = additionalrsn2.territory
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               c.rep_code,
               c.territory,
               LEFT(c.recorded_month, 2) month_num,
               REPLACE(STUFF(
                       (
                       SELECT DISTINCT
                              '; ' + ISNULL(ccpv2.comments, '')
                       FROM dbo.cvo_commission_promo_values AS ccpv2
                       WHERE c.rep_code = ccpv2.rep_code
                             AND c.territory = ccpv2.territory
                             AND ISNULL(ccpv2.line_type, '') IN ( 'Adj/Additional Adj 3' )
                             AND ISNULL(ccpv2.incentive_amount, 0) > 0
                             AND LEFT(ccpv2.recorded_month, 2) = LEFT(c.recorded_month, 2)
                             AND @year = RIGHT(ccpv2.recorded_month, 4) -- 2/10
                       FOR XML PATH('')
                       ),
                       1,
                       1,
                       ''
                            ),
                       '&amp;',
                       '&'
                      ) additionalrsn3
        FROM dbo.cvo_commission_promo_values AS c
        WHERE CAST(RIGHT(c.recorded_month, 4) AS INT) = @year
              AND c.recorded_month <= @FiscalPeriod
        ) additionalrsn3
            ON #mm.salesperson = additionalrsn3.rep_code
               AND #mm.mm = additionalrsn3.month_num
               AND #mm.territory = additionalrsn3.territory
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               c.rep_code,
               c.territory,
               LEFT(c.recorded_month, 2) month_num,
               SUM(ISNULL(c.incentive_amount, 0)) reduction1,
               REPLACE(STUFF(
                       (
                       SELECT DISTINCT
                              '; ' + ISNULL(ccpv2.comments, '')
                       FROM dbo.cvo_commission_promo_values AS ccpv2
                       WHERE c.rep_code = ccpv2.rep_code
                             AND c.territory = ccpv2.territory
                             AND ISNULL(ccpv2.line_type, '') IN ( 'manual reduction' )
                             AND ISNULL(ccpv2.incentive_amount, 0) < 0
                             AND LEFT(ccpv2.recorded_month, 2) = LEFT(c.recorded_month, 2)
                             AND @year = RIGHT(ccpv2.recorded_month, 4) -- 2/10
                       FOR XML PATH('')
                       ),
                       1,
                       1,
                       ''
                            ),
                       '&amp;',
                       '&'
                      ) reductionrsn1
        FROM dbo.cvo_commission_promo_values AS c
        WHERE CAST(RIGHT(c.recorded_month, 4) AS INT) = @year
              AND c.recorded_month <= @FiscalPeriod
              AND ISNULL(c.line_type, '') IN ( 'manual reduction' )
        GROUP BY LEFT(c.recorded_month, 2),
                 c.rep_code,
                 c.territory
        ) reductionrsn1
            ON #mm.salesperson = reductionrsn1.rep_code
               AND #mm.mm = reductionrsn1.month_num
               AND #mm.territory = reductionrsn1.territory
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               g.rep_code,
               g.territory,
               g.comments
        FROM dbo.cvo_commission_promo_values g
            JOIN
            (
            SELECT rep_code,
                   cpv.territory,
                   MAX(date) max_date
            FROM dbo.cvo_commission_promo_values AS cpv
            WHERE cpv.line_type = 'General'
            GROUP BY rep_code,
                     cpv.territory
            ) gg
                ON gg.rep_code = g.rep_code
                   AND gg.territory = g.territory
                   AND gg.max_date = g.date
        WHERE g.line_type = 'General'
        ) general
            ON #mm.salesperson = general.rep_code
               AND #mm.territory = general.territory
        LEFT OUTER JOIN
        (
        SELECT rep_code,
               territory,
               LEFT(recorded_month, 2) month_num,
               SUM(ISNULL(incentive_amount, 0)) spec_pay
        FROM dbo.cvo_commission_promo_values
        WHERE line_type = 'special payment'
              AND @year = CAST(RIGHT(recorded_month, 4) AS INT)
        GROUP BY LEFT(recorded_month, 2),
                 rep_code,
                 territory
        ) spec_pay
            ON #mm.salesperson = spec_pay.rep_code
               AND #mm.mm = spec_pay.month_num
               AND #mm.territory = spec_pay.territory;

    DELETE FROM #final
    WHERE #final.salesperson + #final.territory IN
          (
          SELECT salesperson + territory
          FROM #final
          GROUP BY salesperson,
                   territory
          HAVING SUM(amount) = 0
          );

    SELECT DISTINCT
           f.id,
           f.salesperson,
           f.salesperson_name,
           f.hiredate,
           f.termdate,
           f.amount,
           f.acc_amount,
           f.comm_amt,
           f.draw_amount,
           f.draw_weeks,
           f.commission,
           f.incentivePC,
           f.incentive,
           f.addition1,
           f.addition2,
           f.addition3,
           f.additionrsn1,
           f.additionrsn2,
           f.additionrsn3,
           f.reduction1,
           f.reductionrsn1,
           f.rep_type,
           f.status_Type,
           f.territory,
           f.region,
           f.total_earnings,
           f.total_draw,
           f.prior_month_bal,
           f.net_pay,
           f.report_month,
           f.current_flag,
           f.promo_detail,
           f.promo_sum,
           f.month_num,
           f.year_ly,
           f.total_earnings_ly,
           f.general_note,
           f.spec_pay
    FROM #final f
        LEFT OUTER JOIN
        (
        SELECT MAX(fin.id) id,
               fin.salesperson,
               fin.territory,
               fin.report_month
        FROM #final fin
        GROUP BY fin.salesperson,
                 fin.territory,
                 fin.report_month
        ) ff
            ON ff.id = f.id
               AND ff.salesperson = f.salesperson
               AND ff.territory = f.territory
               AND ff.report_month = f.report_month;

END;
















GO
GRANT EXECUTE ON  [dbo].[cvo_commission_statement_sp] TO [public]
GO
