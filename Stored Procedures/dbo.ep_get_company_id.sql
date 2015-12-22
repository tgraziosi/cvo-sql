SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE	[dbo].[ep_get_company_id] @validCompanyID smallInt output,
	@validCompName varchar(40), @companyName varchar(40), @companyID smallInt = 0 AS
Begin

	select @companyName = '%' + @companyName + '%'

	If (@companyID = 0)
	Begin
		select @validCompanyID = company_id,
			@validCompName = company_name
		from CVO_Control.dbo.smcomp (nolock) 
		where company_name like @companyName 
	End
	Else
	Begin
		select @validCompanyID = company_id,
			@validCompName = company_name
		from CVO_Control.dbo.smcomp (nolock) 
		where company_id =  @companyID 
	End

		
	IF (@validCompanyID is NULL)
	begin	--Case of invalid companyID, get the companyID from apco
		select @validCompanyID = company_id,
			@validCompName = company_name
		from apco
	End

  	select company_id = @validCompanyID, company_name = @validCompName 

END 

GO
GRANT EXECUTE ON  [dbo].[ep_get_company_id] TO [public]
GO
