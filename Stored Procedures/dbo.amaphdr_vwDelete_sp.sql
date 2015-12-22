SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amaphdr_vwDelete_sp] 
( 
	@timestamp timestamp,
	@company_id		smCompanyID,
	@trx_ctrl_num	smControlNumber

) as 

declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


delete from amaphdr 
where company_id 	= @company_id 
and trx_ctrl_num 	= @trx_ctrl_num 
and timestamp 	= @timestamp 

select @error = @@error, @rowcount = @@rowcount 

if @error <> 0  
	return @error 

if @rowcount = 0  
begin 
	 
	select @ts = timestamp
	from amaphdr_vw 
	where 	company_id 	= @company_id 
	and 	trx_ctrl_num= @trx_ctrl_num 

	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amaphddl.sp", 90, amaphdr_vw, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		return 		20002 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amaphddl.sp", 96, amaphdr_vw, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		return 		20001 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amaphdr_vwDelete_sp] TO [public]
GO
