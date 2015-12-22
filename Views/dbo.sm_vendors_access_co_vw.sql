SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[sm_vendors_access_co_vw] AS 
						SELECT DISTINCT a.customer_code 
							FROM armaster_all a 
GO
GRANT REFERENCES ON  [dbo].[sm_vendors_access_co_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_vendors_access_co_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_vendors_access_co_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_vendors_access_co_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_vendors_access_co_vw] TO [public]
GO
