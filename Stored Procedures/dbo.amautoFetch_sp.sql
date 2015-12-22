SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amautoFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smCompanyID 
) as 

declare @rowsfound smallint 
declare @period_timestamp timestamp 
declare @period_mask smControlNumber 
declare @period_next smCounter 
DECLARE @asset_timestamp timestamp 
DECLARE @asset_mask smControlNumber 
DECLARE @asset_next smCounter 

select @rowsfound = 0 

SELECT @asset_timestamp = 0,
		@asset_mask = "",
		@asset_next = 0,
		@period_timestamp = 0,
		@period_mask = "",
		@period_next = 0 

IF EXISTS (select * from amauto where 
	company_id = @company_id)
BEGIN 

	SELECT @asset_mask = num_mask,
		@asset_next = automatic_next,
		@asset_timestamp = timestamp 
	FROM amauto 
	WHERE company_id = @company_id 
	AND automatic_id = 1 


 SELECT @period_timestamp = timestamp,
	 @period_mask = num_mask,
		 @period_next = automatic_next 
 FROM amauto 
 WHERE company_id = @company_id 
 AND automatic_id = 2 

END 


SELECT company_id = @company_id,
	asset_timestamp = @asset_timestamp,
	asset_mask = @asset_mask,
	asset_next = @asset_next,
	period_timestamp = @period_timestamp,
	period_mask = @period_mask,
	period_next = @period_next 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amautoFetch_sp] TO [public]
GO
