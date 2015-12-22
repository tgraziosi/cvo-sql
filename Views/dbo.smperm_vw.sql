SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[smperm_vw]
AS SELECT * from CVO_Control..smperm

 

                                              
GO
GRANT REFERENCES ON  [dbo].[smperm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smperm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smperm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smperm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smperm_vw] TO [public]
GO
