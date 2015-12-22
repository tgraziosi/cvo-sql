SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ampstInsert_sp] 
( 
	@company_id smCompanyID, @posting_code smPostingCode, @posting_code_description smStdDescription, @updated_by smUserID 	 
	 
) as 

declare @error int
declare @todays smApplyDate

SELECT @todays = GETDATE() 

insert into ampsthdr 
( 
	company_id,
	posting_code,
	posting_code_description,
	last_updated,
	date_created,
	created_by,
	updated_by
	 
)
values 
( 
	@company_id,
	@posting_code,
	@posting_code_description,
	@todays,
	@todays,
	@updated_by,
	@updated_by
		
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[ampstInsert_sp] TO [public]
GO
