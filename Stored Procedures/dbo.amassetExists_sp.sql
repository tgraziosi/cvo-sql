SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amassetExists_sp] 
( 
	@company_id			smCompanyID, 
	@asset_ctrl_num		smControlNumber, 
	@valid				int output 
) as 


if exists (select 1 
			from amasset_org_vw 
			where 	company_id		= @company_id 
			and 	asset_ctrl_num	= @asset_ctrl_num 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amassetExists_sp] TO [public]
GO
