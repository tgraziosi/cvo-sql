SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amname_vwUpdate_sp]
(
	@timestamp				timestamp,
	@company_id				smCompanyID,
	@addr1					varchar(40 ),	 
	@addr2					varchar(40 ),	 
	@addr3					varchar(40 ),	 
	@addr4					varchar(40 ),	 
	@addr5					varchar(40 ),	 
	@addr6					varchar(40 ),	 
	@ap_interface			smLogicalFalse,
	@post_depreciation		smLogical,
	@post_additions			smLogical,
	@post_disposals			smLogical,
	@post_other_activities	smLogical,
	@last_modified_date		varchar(30),
	@modified_by			smUserID
) 
AS

DECLARE 
	@rowcount 	smCounter,
	@error 		smErrorCode,
	@ts 		timestamp,
	@message 	smErrorLongDesc
 
UPDATE 	amco 
SET	 	ap_interface			= @ap_interface,
		post_depreciation		= @post_depreciation,
		post_additions			= @post_additions,
		post_disposals			= @post_disposals,
		post_other_activities	= @post_other_activities,
		last_modified_date		= @last_modified_date,
		modified_by				= @modified_by
WHERE	company_id				= @company_id 
AND		timestamp				= @timestamp

SELECT @error = @@error, @rowcount = @@rowcount
IF @error <> 0 
	RETURN @error

IF @rowcount = 0 
BEGIN
	
	SELECT 	@ts 		= timestamp 
	FROM 	amname_vw 
	WHERE	company_id 	= @company_id
 
	SELECT @error = @@error, @rowcount = @@rowcount
	IF @error <> 0 
		RETURN @error
 
	IF @rowcount = 0 
	BEGIN
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amnameup.sp", 125, "amco", @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20004 @message
		RETURN 		20004
	END

	IF @ts <> @timestamp
	BEGIN
		EXEC	 	amGetErrorMessage_sp 20003, "tmp/amnameup.sp", 132, "amco", @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20003 @message
		RETURN 		20003
	END
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amname_vwUpdate_sp] TO [public]
GO
