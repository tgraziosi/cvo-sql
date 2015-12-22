SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE VIEW [dbo].[mc_currency_group_member_vw]
AS
SELECT 	* 
FROM	CVO_Control..mc_currency_group_member
GO
GRANT REFERENCES ON  [dbo].[mc_currency_group_member_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[mc_currency_group_member_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[mc_currency_group_member_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[mc_currency_group_member_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[mc_currency_group_member_vw] TO [public]
GO
