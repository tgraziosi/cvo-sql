SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclshdrInsert_sp] 
( 
	@company_id smCompanyID, @classification_id smSurrogateKey, @classification_name smClassificationName, @acct_level smAcctLevel, @start_col smSmallCounter, @length smSmallCounter, @override_default smAccountOverride, @updated_by smUserID 	 
	 
) as 

declare @error int
declare @todays smApplyDate

SELECT @todays = GETDATE() 

insert into amclshdr 
( 
	company_id,	
	classification_id, 
 classification_name, 
 acct_level , 
 start_col, 
 length , 
 override_default,
 last_updated,
	date_created,
	created_by,
	updated_by
	 
)
values 
( 
	@company_id,	
	@classification_id, 
 @classification_name, 
 @acct_level , 
 @start_col, 
 @length , 
 @override_default,
	@todays,
	@todays,
	@updated_by,
	@updated_by
		
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amclshdrInsert_sp] TO [public]
GO
