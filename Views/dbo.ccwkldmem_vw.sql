SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE VIEW [dbo].[ccwkldmem_vw]
AS
	SELECT 	h.workload_code, 
		workload_desc, 
		m.customer_code, 
		customer_name, 
		company_name
	FROM ccwrkhdr h, ccwrkmem m, arcust c, arco
	WHERE h.workload_code = m.workload_code
	AND m.customer_code = c.customer_code
GO
GRANT SELECT ON  [dbo].[ccwkldmem_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ccwkldmem_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ccwkldmem_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccwkldmem_vw] TO [public]
GO
