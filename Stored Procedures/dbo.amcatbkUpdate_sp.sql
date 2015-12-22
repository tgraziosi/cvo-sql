SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcatbkUpdate_sp] 
( 
	@timestamp 	timestamp,
	@category_code 	smCategoryCode, 
	@book_code 	smBookCode, 
	@effective_date 	varchar(30), 
	@depr_rule_code 	smDeprRuleCode, 
	@depr_rule_description 	smStdDescription, 
	@limit_rule_code 	smLimitRuleCode 
) as 
declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)

SELECT @effective_date = RTRIM(@effective_date) IF @effective_date = "" SELECT @effective_date = NULL


update amcatbk set 
	depr_rule_code 	= @depr_rule_code,
	limit_rule_code 	= @limit_rule_code 
where 
	category_code 	= @category_code and 
	book_code 	= @book_code and 
	effective_date 	= @effective_date and 
	timestamp 	= @timestamp 
select @error = @@error, @rowcount = @@rowcount 
if @error <> 0  
	return @error 
if @rowcount = 0  
begin 
	 
	select @ts = timestamp from amcatbk where 
	category_code = @category_code and 
	book_code = @book_code and 
	effective_date = @effective_date 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amctbkup.sp", 108, amcatbk, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		return 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amctbkup.sp", 114, amcatbk, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		return 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcatbkUpdate_sp] TO [public]
GO
