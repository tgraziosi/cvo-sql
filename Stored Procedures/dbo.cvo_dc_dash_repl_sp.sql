SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[cvo_dc_dash_repl_sp] @asofdate DATETIME = NULL
AS
BEGIN

    IF @asofdate IS NULL
        SELECT @asofdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);

    SELECT 'PENDING' QSTATUS,
           rl.who_entered,
           COUNT(crq.tran_id) num_trans
    FROM dbo.cvo_cart_replenish_queue AS crq
        JOIN dbo.cvo_replenishment_log AS rl
            ON rl.part_no = crq.part_no
               AND rl.queue_id = crq.tran_id
    WHERE dateadd(hour,3,crq.queue_date) > GETDATE()
    AND EXISTS (SELECT 1 FROM tdc_pick_queue t WHERE t.tran_id = crq.tran_id)
    GROUP BY rl.who_entered
    UNION ALL
    
    SELECT 'LATE' QSTATUS,
           rl.who_entered,
           COUNT(crq.tran_id) num_trans
    FROM dbo.cvo_cart_replenish_queue AS crq
        JOIN dbo.cvo_replenishment_log AS rl
            ON rl.part_no = crq.part_no
               AND rl.queue_id = crq.tran_id
    WHERE dateadd(hour,3,crq.queue_date) <= GETDATE()
    AND EXISTS (SELECT 1 FROM tdc_pick_queue t WHERE t.tran_id = crq.tran_id)

    GROUP BY rl.who_entered
    UNION all
    
    SELECT 'COMPLETE' QSTATUS,
           rl.who_entered,
           COUNT(crp.tran_id) num_trans
    FROM dbo.cvo_cart_replenish_processed AS crp
        JOIN dbo.cvo_replenishment_log AS rl
            ON rl.part_no = crp.part_no
               AND rl.queue_id = crp.tran_id
    WHERE crp.queue_date >= @asofdate
    GROUP BY rl.who_entered;



END;

GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_repl_sp] TO [public]
GO
