SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[explview_vw] as

select AppId,
	ViewName,
	ViewNumber
from CVO_Control..explview
                                              
GO
GRANT REFERENCES ON  [dbo].[explview_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[explview_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[explview_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[explview_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[explview_vw] TO [public]
GO
