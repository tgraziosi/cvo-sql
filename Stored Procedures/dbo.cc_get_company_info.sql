SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_company_info] 
	@companyDB varchar(30)
AS
select company_id, company_name from CVO_Control..smcomp where db_name = @companyDB

GO
GRANT EXECUTE ON  [dbo].[cc_get_company_info] TO [public]
GO
