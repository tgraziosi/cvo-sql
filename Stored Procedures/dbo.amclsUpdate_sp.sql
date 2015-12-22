SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclsUpdate_sp]
(
	@timestamp 	timestamp,
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@classification_code 	smClassificationCode,
	@classification_description 	smStdDescription,
	@gl_override 	smAccountOverride,
	@last_modified_date 	varchar(30),
	@modified_by 	smUserID
) as
declare @rowcount int
declare @error int
declare @ts timestamp
declare @message varchar(255)

SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL


update amcls set
	classification_description 	=	@classification_description,
	gl_override 	=	@gl_override,
	last_modified_date 	=	@last_modified_date,
	modified_by 	=	@modified_by
where
	company_id 	=	@company_id and
	classification_id 	=	@classification_id and
	classification_code 	=	@classification_code and
	timestamp 	=	@timestamp
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
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amclsup.sp", 109, "amcls", @error_message = @message out
		IF @message IS NOT NULL RAISERROR 	20004 @message
		return 		20004
	end
	if @ts <> @timestamp
	begin
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amclsup.sp", 115, "amcls", @error_message = @message out
		IF @message IS NOT NULL RAISERROR 	20003 @message
		return 		20003
	end
end
return @@error
GO
GRANT EXECUTE ON  [dbo].[amclsUpdate_sp] TO [public]
GO
