SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[smmenus_vw]
AS SELECT * from CVO_Control..smmenus



                                              
GO
GRANT REFERENCES ON  [dbo].[smmenus_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smmenus_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smmenus_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smmenus_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smmenus_vw] TO [public]
GO
