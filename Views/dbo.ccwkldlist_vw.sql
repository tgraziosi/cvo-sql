SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE VIEW [dbo].[ccwkldlist_vw]
AS
	SELECT 	h.workload_code, 
		workload_desc, 
		update_date, 
		workload_clause, 
		sequence_id, 
		company_name
	FROM ccwrkhdr h, ccwrkdet d, arco
	WHERE h.workload_code = d.workload_code
GO
GRANT SELECT ON  [dbo].[ccwkldlist_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ccwkldlist_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ccwkldlist_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccwkldlist_vw] TO [public]
GO
