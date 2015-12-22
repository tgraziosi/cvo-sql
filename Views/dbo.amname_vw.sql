SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amname_vw] 
AS 

SELECT 
		a.timestamp,
		a.company_id,
 	s.addr1,
 	s.addr2,
 	s.addr3,
 	s.addr4,
 	s.addr5,
 	s.addr6,
	 	a.ap_interface,
	 	a.post_depreciation,
		a.post_additions,
		a.post_disposals,
		a.post_other_activities,
		a.last_modified_date,
		a.modified_by
FROM 	amco a, 
 	CVO_Control..smcomp s 
WHERE 	a.company_id 	= s.company_id 

GO
GRANT REFERENCES ON  [dbo].[amname_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amname_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amname_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amname_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amname_vw] TO [public]
GO
