SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[smspiduser_vw] 
AS 
SELECT 	spid, 
	user_name, 
	org_id, 
	db_name,
	global_user
FROM CVO_Control..smspiduser (NOLOCK)


GO
GRANT REFERENCES ON  [dbo].[smspiduser_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smspiduser_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smspiduser_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smspiduser_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smspiduser_vw] TO [public]
GO
