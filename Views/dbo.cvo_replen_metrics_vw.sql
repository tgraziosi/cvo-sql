SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_replen_metrics_vw]
AS 
SELECT rl.location ,
	   rl.who_entered  replen_group,
       rl.log_date requested_date,
       rl.queue_id ,
       rl.part_no ,
       rl.part_desc ,
       rl.from_bin ,
       rl.to_bin ,
       rl.qty ,
       tdc.tran_date Moved_date,
	   tdc.quantity,
	   tdc.UserID ,
	   DATEDIFF(MINUTE, log_date, tdc.tran_date) time_to_complete,
	   convert(varchar(10), tran_date, 101) tran_date,
	   convert(varchar(10), TRAN_date , 108) tran_time,
	   convert(varchar(10), rl.log_date , 101) req_date,
	   convert(varchar(10), rl.log_date , 108) req_time

FROM   dbo.cvo_replenishment_log AS rl
       LEFT OUTER JOIN tdc_log tdc ON tdc.tran_no = CAST(rl.queue_id AS VARCHAR(16))
                                      AND tdc.tran_ext = ''
WHERE  rl.log_date > ' 10/24/2017' -- start date of modification -- cant go back further than this
;

GO
GRANT SELECT ON  [dbo].[cvo_replen_metrics_vw] TO [public]
GO
