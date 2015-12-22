SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetLastActivityDate_sp] 
( 
	@co_asset_book_id 	smSurrogateKey, 		 
	@from_date 			smApplyDate, 			 
	@to_date 			smApplyDate, 			 
	@method_id 			smDeprMethodID, 		 
	@basis_date 		smApplyDate 	OUTPUT,  
	@boundary_type 		smBoundaryType 	OUTPUT,  
	@debug_level		smDebugLevel 	= 0		
)
AS 

DECLARE 
	@year_date 		smApplyDate, 
	@act_date 		smApplyDate, 
	@rul_date 		smApplyDate, 
	@message 		smErrorLongDesc, 
	@result		 	smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlstact.sp" + ", line " + STR( 107, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
		 	from_date 			= @from_date,
	 		to_date 			= @to_date 
	 		

SELECT 	@basis_date = @from_date 

 
EXEC @result = amGetFiscalYear_sp 
				@from_date,
		 		0,
				@year_date OUTPUT 

IF ( @result <> 0 )
	RETURN @result 

IF @year_date > @basis_date 
BEGIN 
	SELECT 	@basis_date 	= @year_date 
	SELECT 	@boundary_type 	= 1 
END 

IF @method_id != 7 
AND @method_id != 0
BEGIN 
	 
	SELECT 	@act_date 			= MAX(effective_date)
	FROM 	amacthst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	effective_date 		> @basis_date 
	AND 	effective_date 		<= @to_date 

	IF (@act_date IS NOT NULL)
	AND (@act_date > @basis_date)
		SELECT 	@basis_date 	= @act_date,
				@boundary_type 	= 2 
END 


SELECT 	@rul_date 			= MAX(effective_date)
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 		> @basis_date 
AND 	effective_date 		<= @to_date 

IF 	(@rul_date IS NOT NULL)
AND (@rul_date > @basis_date)
	SELECT 	@basis_date 	= @rul_date,
			@boundary_type 	= 3 

IF @debug_level >= 3
	SELECT basis_date 		= @basis_date,
		 boundary_type 	= @boundary_type 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlstact.sp" + ", line " + STR( 177, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetLastActivityDate_sp] TO [public]
GO
