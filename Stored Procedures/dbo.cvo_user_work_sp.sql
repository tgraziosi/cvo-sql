SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_user_work_sp]
    @sdate DATETIME = NULL,
    @edate DATETIME = NULL
AS
BEGIN

    -- exec cvo_user_work_sp '11/30/2018', '12/1/2018'

    IF @sdate IS NULL
        SELECT @sdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), -1); -- yesterday
    IF @edate IS NULL
        SELECT @edate = GETDATE();

    SET @edate = DATEADD(ms, -3, DATEADD(dd, DATEDIFF(dd, 0, @edate), 1) ) -- end of today
    -- SELECT @sdate, @edate 


    ;
    WITH tdc
    AS (SELECT ISNULL(t.tran_date,'1/1/1900') tran_date,
               ISNULL(t.UserID,'') UserID,
               ISNULL(t.trans,'') trans,
               ISNULL(b.group_code,'') group_code,
               CAST(ISNULL(t.quantity, '0') AS NUMERIC) qty_tran
        FROM tdc_log t (NOLOCK)
            LEFT OUTER JOIN inv_master i (NOLOCK)
                ON i.part_no = t.part_no
            LEFT OUTER JOIN tdc_bin_master b (NOLOCK) ON b.location = t.location AND b.bin_no = t.bin_no
        WHERE t.tran_date
              BETWEEN @sdate AND @edate
              AND t.quantity <> ''
              AND 'case' <> ISNULL(i.type_code, '')
              AND t.UserID NOT IN ( '', 'upc upload', 'pick cart', 'autoprint', 'customframes', 'auto_alloc',
                                    'backorder'
                                  )
              AND t.trans NOT IN ( 'allocation', 'pick ticket', 'ORDER update', 'unallocation', 'xfer unalloc',
                                 'pack carton xfer', 'pack carton', 'unpack carton', 'cf mgtb2b created'
                               )
              AND t.trans_source NOT IN ( 'bo' )
              AND t.location = '001'
        UNION ALL
        SELECT crp.pick_time,
               crp.pick_user,
               'REPL PICK',
               ISNULL(b.group_code,'') group_code,
               CAST(ISNULL(crp.source_pick,0) AS NUMERIC) qty_tran
        FROM dbo.cvo_cart_replenish_processed AS crp
                LEFT OUTER JOIN tdc_bin_master b (NOLOCK) ON b.location = '001' AND b.bin_no = crp.source_bin
        WHERE CAST(ISNULL(crp.pick_time, DATEADD(DAY, 1, @edate)) AS DATETIME)
              BETWEEN @sdate AND @edate
              AND ISNULL(crp.isSkipped, 1) = 0
        UNION ALL
        SELECT crp.put_time,
               crp.put_user,
               'REPL PUT',
               ISNULL(b.group_code,'') group_code,
               CAST(ISNULL(crp.target_put,0) AS NUMERIC) qty_tran
        FROM dbo.cvo_cart_replenish_processed AS crp
            LEFT OUTER JOIN tdc_bin_master b (NOLOCK) ON b.location = '001' AND b.bin_no = crp.target_bin
        WHERE CAST(ISNULL(crp.put_time, DATEADD(DAY, 1, @edate)) AS DATETIME)
              BETWEEN @sdate AND @edate
              AND ISNULL(crp.isSkipped, 1) = 0
        UNION ALL
        SELECT tccl.count_date,
               tccl.userid,
               'CYCCNT',
               ISNULL(b.group_code,'') group_code,
               CAST(ISNULL(tccl.count_qty,0) AS numeric)
        FROM dbo.tdc_cyc_count_log AS tccl
            LEFT OUTER JOIN tdc_bin_master b (NOLOCK) ON b.location = tccl.location  AND b.bin_no = tccl.bin_no
        WHERE count_date
        BETWEEN @sdate AND @edate
        UNION ALL
        SELECT cpp.pick_complete_dt,
               cpp.user_login,
               'CARTPICK',
               ISNULL(cpp.bin_group_code,'') group_code,
               CAST(ISNULL(cpp.scanned,0) AS NUMERIC)
        FROM dbo.cvo_cart_parts_processed AS cpp
            
        WHERE cpp.pick_complete_dt
        BETWEEN @sdate AND @edate
        UNION ALL
        SELECT o.date_shipped,
               LTRIM(RTRIM(SUBSTRING(
                                        o.user_def_fld3,
                                        LEN(o.user_def_fld3) - CHARINDEX(' ', REVERSE(o.user_def_fld3)),
                                        LEN(o.user_def_fld3)
                                    )
                          )
                    ),
               'CREDIT RECEIVE',
               'BULK' group_code,
               CAST(1 AS NUMERIC) AS qty_tran
        FROM orders o (NOLOCK)
            JOIN ord_list ol (NOLOCK)
                ON ol.order_no = o.order_no
                   AND ol.order_ext = o.ext
        WHERE o.status = 't'
              AND o.type = 'c'
              AND o.date_shipped
              BETWEEN @sdate AND @edate
        UNION ALL
        SELECT xa.date_recvd,
               xa.who_recvd,
               'XFER RECEIVE',
               'BULK' GROUP_code,
               CAST(1 AS NUMERIC)  AS qty_tran
        FROM dbo.xfers_all AS xa (NOLOCK)
        WHERE xa.status = 's'
              AND xa.to_loc = '001'
              AND xa.date_recvd
              BETWEEN @sdate AND @edate
        ),
         jobs
    AS (SELECT ROW_NUMBER() OVER (ORDER BY UserID, tdc.tran_date) AS rowno,
               tran_date,
               UserID,
               trans,
               tdc.group_code,
               tdc.qty_tran
        FROM tdc),
         jobgroups
    AS (SELECT rowno - ROW_NUMBER() OVER (PARTITION BY UserID, group_code ORDER BY rowno) AS groupno,
               rowno,
               tran_date,
               UserID,
               trans,
               jobs.group_code,
               jobs.qty_tran
        FROM jobs)
    -- SELECT * FROM tdc 
    -- SELECT DISTINCT trans FROM jobs
    -- SELECT * FROM jobgroups ORDER BY groupno, rowno

    SELECT ISNULL(cu.fname + ' ' + cu.lname, g.UserID) UserID,
           g.trans,
           g.group_code,
           MIN(g.tran_date) starttime,
           MAX(g.tran_date) endtime,
           COUNT(g.trans) numtrans,
           SUM(g.qty_tran) qty_tran
    FROM jobgroups g
        LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
            ON cu.user_login = REPLACE(g.UserID, 'cvoptical\', '')
    GROUP BY groupno, 
             ISNULL(cu.fname + ' ' + cu.lname, g.UserID),
             g.userid,
             g.trans,
             g.group_code
    ORDER BY g.UserID,
             starttime;

END;




GO
GRANT EXECUTE ON  [dbo].[cvo_user_work_sp] TO [public]
GO
