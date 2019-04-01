SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_repl_sp] @asofdate DATETIME = NULL
AS
BEGIN

    IF @asofdate IS NULL
        SELECT @asofdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);

WITH repl AS 
(    SELECT 'PENDING' QSTATUS, -- repl done on ipods
           rl.who_entered who_entered,
           null username,
           COUNT(rl.queue_id) num_trans
    FROM dbo.cvo_replenishment_log AS rl (NOLOCK)
    WHERE DATEADD(HOUR, 3, rl.log_date) > GETDATE()
          AND EXISTS
    (
        SELECT 1 FROM tdc_pick_queue t WHERE t.tran_id = rl.queue_id
    )
    GROUP BY rl.who_entered
    UNION ALL
    -- manual replenishments (WH -> xx )
    SELECT CASE WHEN DATEPART(DAY,rl.log_date) = DATEPART(DAY,@asofdate) THEN 'LATE'
    ELSE 'INCOMPLETE' END  QSTATUS,
           rl.who_entered,
           null username,
           COUNT(rl.queue_id) num_trans
    FROM dbo.cvo_replenishment_log AS rl (NOLOCK)
    WHERE DATEADD(HOUR, 4, rl.log_date) <= GETDATE()
          AND EXISTS
    (
        SELECT 1 FROM tdc_pick_queue t WHERE t.tran_id = rl.queue_id
    )
    GROUP BY rl.who_entered, DATEPART(DAY,rl.log_date)
    UNION ALL
    SELECT 'COMPLETE' QSTATUS,
           rl.who_entered,
           T.USERID USERNAME,
           COUNT(rl.queue_id) num_trans
    FROM dbo.cvo_replenishment_log AS rl (NOLOCK)
        JOIN dbo.tdc_log t (NOLOCK)
            ON rl.part_no = t.part_no
               AND rl.queue_id = t.tran_no
    WHERE t.tran_date >= @asofdate
    GROUP BY rl.who_entered, t.UserID
),
final as
(SELECT repl.qstatus,
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER(repl.who_entered),'OPTICAL','FRAMES'),'H-H','H --> H'),'---','--'),'>F','> F'),' ->',' -->') who_entered,
       ISNULL(ccu.fname + ' ' + ccu.lname, REPLACE(repl.username, 'cvoptical\', '')) username,
       repl.num_trans FROM repl
       LEFT OUTER JOIN cvo_cmi_users ccu ON ccu.user_login = REPLACE(repl.username,'cvoptical\','')
)
SELECT final.QSTATUS,
       final.who_entered,
       final.username,
       SUM(final.num_trans) num_trans
        FROM final
        GROUP BY final.QSTATUS,
                 final.who_entered,
                 final.username

END;





GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_repl_sp] TO [public]
GO
