SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclsDelete_sp]
(
	@timestamp 	timestamp,
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@classification_code 	smClassificationCode
) as

declare @rowcount int
declare @error int
declare @ts timestamp
declare @message varchar(255)


delete from amcls where
	company_id = @company_id and
	classification_id = @classification_id and
	classification_code = @classification_code and
	timestamp = @timestamp

select @error = @@error, @rowcount = @@rowcount
if @error <> 0 
	return @error
if @rowcount = 0 
begin
	
	select @ts = timestamp from amcls where
		company_id = @company_id and
		classification_id = @classification_id and
		classification_code = @classification_code
	select @error = @@error, @rowcount = @@rowcount
	if @error <> 0 
		return @error
	if @rowcount = 0 
	begin
		EXEC 		amGetErrorMessage_sp 20002, "tmp/amclsdl.sp", 93, "amcls", @error_message = @message out
		IF @message IS NOT NULL RAISERROR 	20002 @message
		return 		20002
	end
	if @ts <> @timestamp
	begin
		EXEC	 	amGetErrorMessage_sp 20001, "tmp/amclsdl.sp", 99, "amcls", @error_message = @message out
		IF @message IS NOT NULL RAISERROR 	20001 @message
		return 		20001
	end
end
return @@error
GO
GRANT EXECUTE ON  [dbo].[amclsDelete_sp] TO [public]
GO
