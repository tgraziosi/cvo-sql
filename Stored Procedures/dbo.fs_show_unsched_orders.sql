SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

--  Copyright (c) 2000 Epicor Software, Inc. All Right Reserved.
--  This procedure is designed to used in a batch job.  It reports whether any demand orders
--  are unscheduled.

CREATE PROCEDURE [dbo].[fs_show_unsched_orders]
	

AS
BEGIN


DECLARE	@sched_id INT,
        @tstcount INT

SELECT	@sched_id=MIN(SM.sched_id)
FROM	dbo.sched_model SM
WHERE	SM.batch_flag = 'B'

WHILE @sched_id IS NOT NULL
BEGIN
        SELECT	@tstcount = COUNT(*)
	   FROM sched_order 
          WHERE sched_id = @sched_id AND action_flag = 'U'

        IF @tstcount > 0
	   BEGIN
        	SELECT "Scenario: ", sched_name 
 			FROM sched_model 
			WHERE sched_id = @sched_id

        	SELECT "Unscheduled Orders"
        	SELECT "Order: ", order_no, "-", order_ext, " Order line: ", order_line, " Order Line Item: ",part_no  
          		FROM sched_order 
          	WHERE sched_id = @sched_id AND action_flag = 'U'
		ORDER BY order_no
	   END
	
	
	SELECT	@sched_id=MIN(SM.sched_id)
	   FROM	dbo.sched_model SM
	  WHERE	SM.batch_flag = 'B'
	  AND	SM.sched_id > @sched_id
END

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_show_unsched_orders] TO [public]
GO
