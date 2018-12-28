SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_daily_whse_timeline_sp]
    @sdate DATETIME,
    @edate DATETIME
AS
BEGIN

    -- EXEC cvo_daily_whse_timeline_sp '11/30/2018', '11/30/2018'

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    SELECT @edate = DATEADD(ms, -1, DATEADD(DAY, 1, @edate));


    SELECT wms.module,
           trans,
           REPLACE(wms.UserID, 'cvoptical\', '') who_processed,
           ISNULL(cu.fname + ' ' + cu.lname, REPLACE(wms.UserID, 'cvoptical\', '')) Username,
           COUNT(wms.tran_no) num_activity,
           COUNT(DISTINCT wms.part_no) total_skus,
           MIN(ISNULL(wms.tran_date, 0)) start_tran_time,
           MAX(ISNULL(wms.tran_date,0)) end_tran_time
    FROM tdc_log wms (NOLOCK)
        LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
            ON cu.user_login = REPLACE(wms.UserID, 'cvoptical\', '')
        LEFT OUTER JOIN inv_master i
            ON i.part_no = wms.part_no
    WHERE wms.tran_date
          BETWEEN @sdate AND @edate
          AND 'case' <> ISNULL(i.type_code, '')
          AND trans NOT LIKE 'pack carton%'
          AND wms.userid <> 'auto_alloc'

    -- AND trans IN ( 'qcrelease', 'poptwy' )
    GROUP BY 
             wms.module,
             wms.trans,
             cu.fname,
             cu.lname,
             REPLACE(wms.UserID, 'cvoptical\', '')
      ORDER BY Username
    --UNION ALL
    --SELECT crp.pick_user,
    --       'REPL',
    --       'REPL PICK',
    --       crp.pick_user,
    --       COUNT(crp.source_pick) NUM_ACTIVITY,
    --       COUNT(DISTINCT crp.part_no) TOTAL_SKUS,
    --       DATEADD(dd, DATEDIFF(dd, 0, crp.pick_time), 0) tran_date
    --FROM dbo.cvo_cart_replenish_processed AS crp
    --WHERE CAST(ISNULL(crp.pick_time, DATEADD(DAY, 1, @edate)) AS DATETIME)
    --      BETWEEN @sdate AND @edate
    --      AND ISNULL(crp.isSkipped, 1) = 0
    --GROUP BY crp.pick_user,
    --         DATEADD(dd, DATEDIFF(dd, 0, crp.pick_time), 0)
    --UNION ALL
    --SELECT crp.put_user,
    --       'REPL',
    --       'REPL PUT',
    --       crp.put_user,
    --       COUNT(crp.target_put) NUM_ACTIVITY,
    --       COUNT(DISTINCT crp.part_no) TOTAL_SKUS,
    --       DATEADD(dd, DATEDIFF(dd, 0, crp.put_time), 0)
    --FROM dbo.cvo_cart_replenish_processed AS crp
    --WHERE CAST(ISNULL(crp.put_time, DATEADD(DAY, 1, @edate)) AS DATETIME)
    --      BETWEEN @sdate AND @edate
    --      AND ISNULL(crp.isSkipped, 1) = 0
    --GROUP BY crp.put_user,
    --         DATEADD(dd, DATEDIFF(dd, 0, crp.put_time), 0)
    --UNION ALL
    --SELECT tccl.userid,
    --       tccl.team_id,
    --       'CYCCNT',
    --       ISNULL(cu.fname + ' ' + cu.lname, REPLACE(tccl.userid, 'cvoptical\', '')) Username,
    --       COUNT(count_qty) num_activity,
    --       COUNT(DISTINCT part_no) num_skus,
    --       DATEADD(dd, DATEDIFF(dd, 0, tccl.count_date), 0)
    --FROM dbo.tdc_cyc_count_log AS tccl
    --    LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
    --        ON cu.user_login = REPLACE(tccl.userid, 'cvoptical\', '')
    --WHERE count_date
    --BETWEEN @sdate AND @edate
    --GROUP BY tccl.userid,
    --         tccl.team_id,
    --         cu.fname,
    --         cu.lname,
    --         DATEADD(dd, DATEDIFF(dd, 0, tccl.count_date), 0)
    --UNION ALL
    --SELECT cpp.user_login,
    --       'QTX',
    --       'CARTPICK',
    --       cpp.user_login,
    --       COUNT(cpp.scanned) num_activity,
    --       COUNT(DISTINCT cpp.part_no) num_skus,
    --       DATEADD(dd, DATEDIFF(dd, 0, cpp.pick_complete_dt), 0)
    --FROM dbo.cvo_cart_parts_processed AS cpp
    --WHERE cpp.pick_complete_dt
    --BETWEEN @sdate AND @edate
    --GROUP BY DATEADD(dd, DATEDIFF(dd, 0, cpp.pick_complete_dt), 0),
    --         cpp.user_login,
    --         cpp.cart_no
    --UNION ALL
    --SELECT LTRIM(RTRIM(SUBSTRING(
    --                                o.user_def_fld3,
    --                                LEN(o.user_def_fld3) - CHARINDEX(' ', REVERSE(o.user_def_fld3)),
    --                                LEN(o.user_def_fld3)
    --                            )
    --                  )
    --            ),
    --       'CREDIT RETURN',
    --       'CREDIT RECEIVE',
    --       ISNULL(
    --                 cu.fname + ' ' + cu.lname,
    --                 LTRIM(RTRIM(SUBSTRING(
    --                                          o.user_def_fld3,
    --                                          LEN(o.user_def_fld3) - CHARINDEX(' ', REVERSE(o.user_def_fld3)),
    --                                          LEN(o.user_def_fld3)
    --                                      )
    --                            )
    --                      )
    --             ) Username,
    --       COUNT(DISTINCT o.order_no) num_activity,
    --       COUNT(DISTINCT ol.part_no) num_skus,
    --       DATEADD(dd, DATEDIFF(dd, 0, o.date_shipped), 0)
    --FROM orders o (NOLOCK)
    --    JOIN ord_list ol (NOLOCK)
    --        ON ol.order_no = o.order_no
    --           AND ol.order_ext = o.ext
    --    LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
    --        ON cu.user_login = REPLACE(
    --                                      LTRIM(RTRIM(SUBSTRING(
    --                                                               o.user_def_fld3,
    --                                                               LEN(o.user_def_fld3)
    --                                                               - CHARINDEX(' ', REVERSE(o.user_def_fld3)),
    --                                                               LEN(o.user_def_fld3)
    --                                                           )
    --                                                 )
    --                                           ),
    --                                      'cvoptical\',
    --                                      ''
    --                                  )
    --WHERE o.status = 't'
    --      AND o.type = 'c'
    --      AND o.date_shipped
    --      BETWEEN @sdate AND @edate
    --GROUP BY LTRIM(RTRIM(SUBSTRING(
    --                                  o.user_def_fld3,
    --                                  LEN(o.user_def_fld3) - CHARINDEX(' ', REVERSE(o.user_def_fld3)),
    --                                  LEN(o.user_def_fld3)
    --                              )
    --                    )
    --              ),
    --         ISNULL(
    --                   cu.fname + ' ' + cu.lname,
    --                   LTRIM(RTRIM(SUBSTRING(
    --                                            o.user_def_fld3,
    --                                            LEN(o.user_def_fld3) - CHARINDEX(' ', REVERSE(o.user_def_fld3)),
    --                                            LEN(o.user_def_fld3)
    --                                        )
    --                              )
    --                        )
    --               ),
    --         DATEADD(dd, DATEDIFF(dd, 0, o.date_shipped), 0)
    --UNION ALL
    --SELECT REPLACE(xa.who_recvd, 'cvoptical\', ''),
    --       'ADM',
    --       'XFER RECEIVE',
    --       ISNULL(cu.fname + ' ' + cu.lname, REPLACE(xa.who_recvd, 'cvoptical\', '')) Username,
    --       COUNT(DISTINCT xa.xfer_no) num_activity,
    --       COUNT(DISTINCT xl.part_no) num_skus,
    --       DATEADD(dd, DATEDIFF(dd, 0, xa.date_recvd), 0)
    --FROM dbo.xfers_all AS xa (NOLOCK)
    --    JOIN dbo.xfer_list AS xl (NOLOCK)
    --        ON xl.xfer_no = xa.xfer_no
    --    LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
    --        ON cu.user_login = REPLACE(xa.who_recvd, 'cvoptical\', '')
    --WHERE xa.status = 's'
    --      AND xa.to_loc = '001'
    --      AND xa.date_recvd
    --      BETWEEN @sdate AND @edate
    --GROUP BY REPLACE(xa.who_recvd, 'cvoptical\', ''),
    --         ISNULL(cu.fname + ' ' + cu.lname, REPLACE(xa.who_recvd, 'cvoptical\', '')),
    --         DATEADD(dd, DATEDIFF(dd, 0, xa.date_recvd), 0);
END;




GO
