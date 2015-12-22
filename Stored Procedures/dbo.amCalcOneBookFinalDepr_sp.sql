SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCalcOneBookFinalDepr_sp] 
( 
	@co_asset_id 			smSurrogateKey, 	
	@co_asset_book_id 		smSurrogateKey, 	
	@disp_co_trx_id			smSurrogateKey,
	@depr_co_trx_id			smSurrogateKey,
	@trx_ctrl_num			smControlNumber,	
	@disposition_date		smApplyDate,		
	@full_disposition		smLogical	= 1,	
	@cur_precision 			smallint,			
	@round_factor 			float,				
	@depr_expense 			smMoneyZero	OUTPUT, 
	@cost 					smMoneyZero OUTPUT, 
	@accum_depr 			smMoneyZero OUTPUT, 
	@depr_ytd				smMoneyZero OUTPUT,
	@debug_level			smDebugLevel = 0 	
)
AS 

DECLARE 
	@result		 			smErrorCode, 		
	@disp_yr_start_date		smApplyDate,		
	@acquisition_date		smApplyDate

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amobfldp.sp" + ", line " + STR( 95, 5 ) + " -- ENTRY: "

SELECT	@acquisition_date	= acquisition_date
FROM	amasset
WHERE 	co_asset_id 		= @co_asset_id

 
UPDATE 	amacthst 
SET 	posting_flag 			= 100,
		journal_ctrl_num		= @trx_ctrl_num
FROM 	amacthst ah
WHERE 	ah.apply_date 			< @disposition_date 
AND 	ah.co_asset_book_id 	= @co_asset_book_id 
AND		ah.posting_flag 		= 0

SELECT @result = @@error 
IF @result <> 0 
	RETURN @result 

UPDATE 	amacthst 
SET 	posting_flag 			= 100,
		journal_ctrl_num		= @trx_ctrl_num
FROM 	amacthst ah
WHERE 	ah.apply_date 			= @disposition_date 
AND 	ah.co_asset_book_id 	= @co_asset_book_id 
AND		ah.posting_flag 		= 0
AND		ah.co_trx_id			< @depr_co_trx_id

SELECT @result = @@error 
IF @result <> 0 
	RETURN @result 


 
UPDATE 	amdprhst 
SET 	posting_flag 		= 1 
FROM 	amdprhst dh 
WHERE 	dh.effective_date 		<= @disposition_date 
AND 	dh.co_asset_book_id 	= @co_asset_book_id 
AND		dh.posting_flag 		= 0

SELECT @result = @@error 
IF @result <> 0 
	RETURN @result 

 
UPDATE 	ammandpr 
SET 	posting_flag 			= 1 
FROM 	ammandpr md
WHERE 	md.fiscal_period_end 	<= @disposition_date 
AND 	md.co_asset_book_id 	= @co_asset_book_id 
AND		md.posting_flag 		= 0

SELECT @result = @@error 
IF @result <> 0 
	RETURN @result 

EXEC @result = amGetFiscalYear_sp
					@disposition_date,
					0,
					@disp_yr_start_date OUTPUT
IF @result <> 0 
	RETURN @result 

 



CREATE TABLE #amastprf
(
	co_asset_book_id	int			NOT NULL,
	fiscal_period_end	datetime	NOT NULL,
	current_cost		float		NOT NULL,
	accum_depr			float		NOT NULL,
	effective_date		datetime	NOT NULL,
	posting_flag		tinyint		NOT NULL
)

CREATE UNIQUE INDEX #amastprf_ind_0 ON #amastprf (co_asset_book_id, fiscal_period_end)



CREATE TABLE #amvalues
(
	co_asset_book_id	int,
	co_asset_id			int,
	account_type_id		smallint,
	apply_date			datetime,
	trx_type			tinyint,
	cost				float,		
	accum_depr			float,		
	amount				float,	 	
	account_id			int
)



CREATE TABLE #amfstdpr
(
	co_asset_id			int,		
	co_asset_book_id	int,		
	original_cost		float,		
	post_to_gl			tinyint		
)



CREATE TABLE #amcalval
(
	co_asset_book_id	int,			
	apply_date			datetime,		
	beg_cost			float,			
	beg_accum_depr		float,			
	end_cost			float,			
	end_accum_depr		float,			
	ytd_depr			float,	 		
	year_end_date		datetime NULL	
)


EXEC	@result = amCalcBookFinalDepr_sp	
					@co_asset_id,
					@co_asset_book_id,
					@disposition_date,
					@disp_yr_start_date,
					@acquisition_date,
					@full_disposition,
					@disp_co_trx_id,
					@cur_precision,
					@round_factor,
					@cost 			OUTPUT,
					@accum_depr 	OUTPUT,
					@depr_ytd		OUTPUT,
					@depr_expense 	OUTPUT,
					@debug_level

IF @result <> 0
BEGIN 
	DROP TABLE 	#amvalues 
 	DROP TABLE 	#amfstdpr 
	DROP TABLE 	#amcalval 
	DROP TABLE 	#amastprf 
	RETURN @result 
END 

 
DROP TABLE 	#amvalues 
DROP TABLE 	#amfstdpr 
DROP TABLE 	#amcalval 
DROP TABLE 	#amastprf 


SELECT @accum_depr = (SIGN(@accum_depr - @depr_expense) * ROUND(ABS(@accum_depr - @depr_expense) + 0.0000001, @cur_precision))
	 
IF @debug_level >= 5
	SELECT 	depr_expense	= @depr_expense,
			accum_depr 		= @accum_depr

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amobfldp.sp" + ", line " + STR( 226, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCalcOneBookFinalDepr_sp] TO [public]
GO
