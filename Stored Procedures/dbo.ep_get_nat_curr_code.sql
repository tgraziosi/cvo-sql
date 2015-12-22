SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE	[dbo].[ep_get_nat_curr_code] @companyID smallInt output,
	@sNatCurrCode varchar(8) output AS
Begin

	select @sNatCurrCode = currency_code, @companyID = company_id from apco
  	select company_id = @companyID, currency_code  = @sNatCurrCode
END 

GO
GRANT EXECUTE ON  [dbo].[ep_get_nat_curr_code] TO [public]
GO
