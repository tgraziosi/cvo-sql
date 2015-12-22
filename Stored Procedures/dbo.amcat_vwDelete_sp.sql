SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcat_vwDelete_sp] 
( 
	@timestamp timestamp,
	@category_code smCategoryCode 
) as 

declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


delete from amcat where 
	category_code = @category_code and 
	timestamp = @timestamp 

select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amcat where 
		category_code = @category_code 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amcatdl.sp", 86, amcat, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		return 		20002 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/amcatdl.sp", 92, amcat, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		return 		20001 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcat_vwDelete_sp] TO [public]
GO
