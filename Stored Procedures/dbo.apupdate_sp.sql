SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[apupdate_sp]	@company_code	varchar(8),
				@currency_code	varchar(8),
				@old_company	varchar(8),
				@old_currency	varchar(8)
AS

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apupdate_sp] TO [public]
GO
