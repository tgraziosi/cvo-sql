SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[impur_rel_vw]
AS SELECT
	po_key,
	type,
	part_no,
	lb_tracking,
	location,
	rel_date,
/* RDS
	confirm_date,
	confirmed,
END RDS */
	prev_qty,
	qty_ordered,
	qty_received,
	conv_factor,
	status,
        line,
	batch_no,
	dirty_flag,
	record_status_1,
	record_status_2,
	process_status,
	company_code,
	record_type,
	record_id_num,
        [User_ID]
FROM CVO_Control.dbo.impur
where (record_type & 0x100) > 0


GO
GRANT REFERENCES ON  [dbo].[impur_rel_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[impur_rel_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[impur_rel_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[impur_rel_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[impur_rel_vw] TO [public]
GO
