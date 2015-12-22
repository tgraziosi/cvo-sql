SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetNextActivityDate_sp] 
( 
 	@co_asset_book_id 	smSurrogateKey, 	
 	@from_date 			smApplyDate, 			
 	@method_id 			smDeprMethodID, 		
 	@to_date 			smApplyDate, 			
 	@basis_date 		smApplyDate 	OUTPUT,	
 	@boundary_type 		smBoundaryType 	OUTPUT,	
	@debug_level		smDebugLevel 	= 0		
)
AS 

DECLARE 
	@result		 		smErrorCode,	 		
	@act_date 			smApplyDate, 	 		
	@rul_date 			smApplyDate, 	 		
	@start_date			smApplyDate,	 		
	@prd_end_date		smApplyDate		 		 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amnxtact.sp" + ", line " + STR( 75, 5 ) + " -- ENTRY: "

IF @debug_level >= 4
	SELECT co_asset_book_id = @co_asset_book_id,
		 from_date 		= @from_date,
		 method_id 		= @method_id,
		 to_date 			= @to_date 


SELECT	@start_date = DATEADD(dd, 1, @from_date),
		@act_date	= NULL,
		@rul_date	= NULL

 
SELECT 	@boundary_type = 1 
EXEC 	@result = amGetFiscalYear_sp 
					 		@from_date,
		 			 		1,
							@basis_date OUTPUT 

IF ( @result <> 0 )
	RETURN @result 





	
	EXEC @result = amGetFiscalPeriod_sp 
							@from_date,
					 		1,
		 					@prd_end_date OUTPUT 

	IF ( @result <> 0 )
		RETURN 	@result 

	IF @debug_level >= 3
		SELECT prd_end_date = @prd_end_date

	 
	SELECT 	@act_date 			= MIN(apply_date)
	FROM 	amacthst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	apply_date 			> @prd_end_date 
	AND		apply_date			<= @basis_date 

	IF (@act_date IS NOT NULL)
	BEGIN
		EXEC @result = amGetFiscalPeriod_sp 
								@act_date,
						 		0,
			 					@act_date OUTPUT 

		IF ( @result <> 0 )
			RETURN 	@result 
	END

	IF (@act_date IS NOT NULL)
	AND (@act_date < @basis_date)
		SELECT 	@basis_date 	= DATEADD(dd, -1, @act_date),
				@boundary_type 	= 2 



 
SELECT 	@rul_date			= MIN(effective_date)
FROM 	amdprhst 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	effective_date 		>= @start_date 
AND		effective_date		< @basis_date

IF 	(@rul_date IS NOT NULL)
AND (@rul_date < @basis_date)
	SELECT 	@basis_date 	= DATEADD(dd, -1, @rul_date), 
			@boundary_type 	= 3 

IF @basis_date > @to_date 
	SELECT @basis_date = @to_date 

IF @debug_level >= 3
	SELECT basis_date 		= @basis_date,
		 boundary_type 	= @boundary_type 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amnxtact.sp" + ", line " + STR( 190, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetNextActivityDate_sp] TO [public]
GO
