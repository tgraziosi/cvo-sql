SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_daily_whse_activity_sp]
    @sdate DATETIME,
    @edate DATETIME
AS
BEGIN

    -- EXEC cvo_daily_whse_activity_sp '10/1/2018', '10/1/2018'

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    SELECT @edate = DATEADD(ms, -1, DATEADD(DAY, 1, @edate));


    SELECT REPLACE(wms.UserID, 'cvoptical\', '') who_processed,
           wms.module,
           trans,
           ISNULL(cu.fname + ' ' + cu.lname, REPLACE(wms.UserID, 'cvoptical\', '')) Username,
           COUNT(wms.tran_no) num_activity,
           COUNT(DISTINCT wms.part_no) total_skus,
           DATEADD(dd, DATEDIFF(dd, 0, wms.tran_date), 0) tran_date
    FROM tdc_log wms (NOLOCK)
        LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
            ON cu.user_login = REPLACE(wms.UserID, 'cvoptical\', '')
        LEFT OUTER JOIN inv_master i
            ON i.part_no = wms.part_no
    WHERE wms.tran_date
          BETWEEN @sdate AND @edate
          AND 'case' <> ISNULL(i.type_code, '')
          AND trans NOT LIKE 'pack carton%'

    -- AND trans IN ( 'qcrelease', 'poptwy' )
    GROUP BY REPLACE(wms.UserID, 'cvoptical\', ''),
             wms.module,
             wms.trans,
             cu.fname,
             cu.lname,
             DATEADD(dd, DATEDIFF(dd, 0, wms.tran_date), 0)
    UNION ALL
    SELECT crp.pick_user,
           'REPL',
           'REPL PICK',
           crp.pick_user,
           COUNT(crp.source_pick) NUM_ACTIVITY,
           COUNT(DISTINCT crp.part_no) TOTAL_SKUS,
           DATEADD(dd, DATEDIFF(dd, 0, crp.pick_time), 0) tran_date
    FROM dbo.cvo_cart_replenish_processed AS crp
    WHERE CAST(ISNULL(crp.pick_time, DATEADD(DAY, 1, @edate)) AS DATETIME)
          BETWEEN @sdate AND @edate
          AND ISNULL(crp.isSkipped, 1) = 0
    GROUP BY crp.pick_user,
             DATEADD(dd, DATEDIFF(dd, 0, crp.pick_time), 0)
    UNION ALL
    SELECT crp.put_user,
           'REPL',
           'REPL PUT',
           crp.put_user,
           COUNT(crp.target_put) NUM_ACTIVITY,
           COUNT(DISTINCT crp.part_no) TOTAL_SKUS,
           DATEADD(dd, DATEDIFF(dd, 0, crp.put_time), 0)
    FROM dbo.cvo_cart_replenish_processed AS crp
    WHERE CAST(ISNULL(crp.put_time, DATEADD(DAY, 1, @edate)) AS DATETIME)
          BETWEEN @sdate AND @edate
          AND ISNULL(crp.isSkipped, 1) = 0
    GROUP BY crp.put_user,
             DATEADD(dd, DATEDIFF(dd, 0, crp.put_time), 0)
    UNION ALL
    SELECT tccl.userid,
           tccl.team_id,
           'CYCCNT',
           ISNULL(cu.fname + ' ' + cu.lname, REPLACE(tccl.userid, 'cvoptical\', '')) Username,
           COUNT(count_qty) num_activity,
           COUNT(DISTINCT part_no) num_skus,
           DATEADD(dd, DATEDIFF(dd, 0, tccl.count_date), 0)
    FROM dbo.tdc_cyc_count_log AS tccl
        LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
            ON cu.user_login = REPLACE(tccl.userid, 'cvoptical\', '')
    WHERE count_date
    BETWEEN @sdate AND @edate
    GROUP BY tccl.userid,
             tccl.team_id,
             cu.fname,
             cu.lname,
             DATEADD(dd, DATEDIFF(dd, 0, tccl.count_date), 0)
    UNION ALL
    SELECT cpp.user_login,
           'QTX',
           'CARTPICK',
           cpp.user_login,
           COUNT(cpp.scanned) num_activity,
           COUNT(DISTINCT cpp.part_no) num_skus,
           DATEADD(dd, DATEDIFF(dd, 0, cpp.pick_complete_dt), 0)
    FROM dbo.cvo_cart_parts_processed AS cpp
    WHERE cpp.pick_complete_dt
    BETWEEN @sdate AND @edate
    GROUP BY DATEADD(dd, DATEDIFF(dd, 0, cpp.pick_complete_dt), 0),
             cpp.user_login,
             cpp.cart_no;



END;

GO
GRANT EXECUTE ON  [dbo].[cvo_daily_whse_activity_sp] TO [public]
GO
