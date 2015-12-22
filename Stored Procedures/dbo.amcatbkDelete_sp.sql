SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcatbkDelete_sp] 
( 
	@timestamp 	timestamp,
	@category_code 	smCategoryCode, 
	@book_code 	smBookCode, 
	@effective_date 	varchar(30)
) as 

declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)

SELECT @effective_date = RTRIM(@effective_date) IF @effective_date = "" SELECT @effective_date = NULL


delete from amcatbk where 
	category_code = @category_code and 
	book_code = @book_code and 
	effective_date = @effective_date and 
	timestamp = @timestamp 

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
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amctbkdl.sp", 101, amcatbk, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		RETURN 		20002 
	end 
	if @ts <> @timestamp 
	begin 

		EXEC 		amGetErrorMessage_sp 20001, "tmp/amctbkdl.sp", 108, amcatbk, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		RETURN 		20001 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcatbkDelete_sp] TO [public]
GO
