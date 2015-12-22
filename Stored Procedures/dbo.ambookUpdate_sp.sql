SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ambookUpdate_sp] 
( 
	@timestamp 	timestamp,
	@book_code 	smBookCode, 
	@book_description 	smStdDescription, 
	@capitalization_threshold 	smMoneyZero, 
	@currency_code 	smCurrencyCode, 
	@allow_revaluations 	smLogicalFalse, 
	@allow_writedowns 	smLogicalFalse, 
	@allow_adjustments 	smLogicalFalse, 
	@suspend_depr 	smLogicalFalse, 
	@post_to_gl 	smLogicalFalse, 
	@gl_book_code 	smBookCode,
	@depr_if_less_than_yr			smLogicalTrue 
) 
AS 
DECLARE @rowcount 	smCounter 
DECLARE @error 		smErrorCode 
DECLARE @ts 		timestamp 
DECLARE @message 	smErrorLongDesc


UPDATE ambook 
SET 
	book_description 	= @book_description,
	capitalization_threshold 	= @capitalization_threshold,
	currency_code 	= @currency_code,
	allow_revaluations 	= @allow_revaluations,
	allow_writedowns 	= @allow_writedowns,
	allow_adjustments 	= @allow_adjustments,
	suspend_depr 	= @suspend_depr,
	post_to_gl 	= @post_to_gl,
	gl_book_code 	= @gl_book_code,
	depr_if_less_than_yr			= @depr_if_less_than_yr
WHERE	book_code 	= @book_code 
AND 	timestamp 	= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 
IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 		= timestamp 
	FROM 	ambook 
	WHERE 	book_code 	= @book_code 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 
	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/ambookup.sp", 115, ambook, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC	 	amGetErrorMessage_sp 20003, "tmp/ambookup.sp", 121, ambook, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	END 
END 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[ambookUpdate_sp] TO [public]
GO
