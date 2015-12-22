SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ambookDelete_sp] 
( 
	@timestamp 	timestamp,
	@book_code 	smBookCode 
) as 

declare @rowcount int 
declare @error int 
declare @ts timestamp 
declare @message varchar(255)


delete from ambook where 
	book_code = @book_code and 
	timestamp = @timestamp 
select @error = @@error, @rowcount = @@rowcount 

if @error <> 0  
	return @error 

if @rowcount = 0  
begin 
	 
	select @ts = timestamp from ambook where 
		book_code = @book_code 
	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0  
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20002, "tmp/ambookdl.sp", 87, ambook, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20002 @message 
		return 		20002 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20001, "tmp/ambookdl.sp", 93, ambook, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20001 @message 
		return 		20001 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[ambookDelete_sp] TO [public]
GO
