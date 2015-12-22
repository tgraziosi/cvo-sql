SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[imglxref_vw] 
AS select * from [CVO_Control]..imglxref
 where psql_acct_code not in (select is_acct_code from [CVO_Control]..imincsum)
 and psql_acct_code not in (select re_acct_code from [CVO_Control]..imincsum)  
GO
GRANT REFERENCES ON  [dbo].[imglxref_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imglxref_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imglxref_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imglxref_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imglxref_vw] TO [public]
GO
