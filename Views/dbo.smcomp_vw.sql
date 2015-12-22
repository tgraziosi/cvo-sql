SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


 

 
CREATE VIEW [dbo].[smcomp_vw]
AS SELECT ddid, extended_security_flag from CVO_Control..smcomp sm where sm.db_name=db_name()


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[smcomp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smcomp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smcomp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smcomp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smcomp_vw] TO [public]
GO
