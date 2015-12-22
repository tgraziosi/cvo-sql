SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[iminvmast_vw]
as
SELECT * FROM [CVO_Control].dbo.[iminvmast] vw



GO
GRANT REFERENCES ON  [dbo].[iminvmast_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iminvmast_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iminvmast_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iminvmast_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iminvmast_vw] TO [public]
GO
