SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW 
[dbo].[cvo_replenishment_vw]
AS 
SELECT rl.location ,
       cast (rl.queue_id AS VARCHAR(8)) queue_id ,
       rl.part_no ,
       rl.part_desc ,
       rl.from_bin ,
       rl.to_bin ,
       rl.qty ,
       rl.log_date ,
       rl.who_entered replen_group
	    FROM dbo.cvo_replenishment_log AS rl
GO
GRANT REFERENCES ON  [dbo].[cvo_replenishment_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_replenishment_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_replenishment_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_replenishment_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_replenishment_vw] TO [public]
GO
