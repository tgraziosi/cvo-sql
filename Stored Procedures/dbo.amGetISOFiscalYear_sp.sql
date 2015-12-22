SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetISOFiscalYear_sp] 
(	
	@given_date smISODate, 		 	
	@period_start smLogical, 		
	@iso_date smISODate OUTPUT, 	
	@debug_level	smDebugLevel = 0	
)
AS 

DECLARE 
	@apply_date smApplyDate, 
	@new_date smApplyDate, 
	@ret_status smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfisiso.sp" + ", line " + STR( 67, 5 ) + " -- ENTRY: "

SELECT @new_date = CONVERT( datetime, @given_date)
EXEC @ret_status = amGetFiscalYear_sp 
					@new_date, 
					@period_start, 
					@apply_date OUTPUT 

IF @ret_status != 0 
 RETURN @ret_status 
 
SELECT @iso_date = CONVERT( char(8), @apply_date, 112 )

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfisiso.sp" + ", line " + STR( 80, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetISOFiscalYear_sp] TO [public]
GO
