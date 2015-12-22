SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amSummariseTrx_sp] 
(
	@trx_type			smTrxType,			
	@rounding_factor	float,				
	@curr_precision		smallint,			
	@debug_level		smDebugLevel 	= 0	
)
AS 

DECLARE 
	@result 				smErrorCode,
	@message				smErrorLongDesc,
	@rowcount				smCounter,
	@co_trx_id				smSurrogateKey,
	@trx_ctrl_num			smControlNumber,
	@book_code				smBookCode,
	@post_depreciation		smLogical,
	@post_additions			smLogical,
	@post_dispositions		smLogical,
	@post_other_activities	smLogical

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amsumtrx.cpp" + ", line " + STR( 96, 5 ) + " -- ENTRY: "




SELECT	@book_code 	= book_code
FROM	ambook
WHERE	post_to_gl	= 1

SELECT	@rowcount = @@rowcount




IF @rowcount = 0
BEGIN
	EXEC 		amGetErrorMessage_sp 20605, "amsumtrx.cpp", 112, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20605 @message
	RETURN 		20605
END
ELSE IF @rowcount > 1
BEGIN
	EXEC 		amGetErrorMessage_sp 20606, "amsumtrx.cpp", 118, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20606 @message
	RETURN 		20606
END





SET ROWCOUNT 1
SELECT	@post_depreciation		= post_depreciation,
		@post_additions			= post_additions,
		@post_dispositions		= post_disposals,
		@post_other_activities	= post_other_activities
FROM	amco
SET ROWCOUNT 0




SELECT	@trx_ctrl_num	= trx_ctrl_num,
		@co_trx_id		= co_trx_id	 
FROM	#amtrxhdr

IF 	@trx_type = 50
AND	@post_depreciation = 1
BEGIN
	



	INSERT INTO #amsumval
	(
			account_id,
			account_code,
			account_reference_code,
			amount,
			asset_org_id	
	)
	SELECT
			a.account_id,
			a.account_code,
			a.account_reference_code,
			(SIGN(ISNULL(SUM(v.amount), 0.0)) * ROUND(ABS(ISNULL(SUM(v.amount), 0.0)) + 0.0000001, @curr_precision)),
			s.org_id	
	FROM	amastbk		ab,
			amvalues	v,
			amacct		a, amasset s	
	WHERE	v.co_trx_id			= @co_trx_id
	AND		v.co_asset_book_id	= ab.co_asset_book_id
	AND		ab.book_code		= @book_code
	AND		v.account_id		= a.account_id
	AND		s.co_asset_id		= ab.co_asset_id	
	GROUP BY	
			a.account_id,
			a.account_code, 
			a.account_reference_code,
			s.org_id		

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
END

	














INSERT INTO #amacthdr
(
	trx_co_trx_id,
	co_trx_id, 
	co_asset_id,
	co_asset_book_id,
	journal_ctrl_num,
	apply_date, 
	trx_type, 
	trx_description,
	doc_reference,
	change_in_quantity,
	last_modified_date,
	post_to_gl,
	sum_val,
	asset_org_id		
)
SELECT 				
	@co_trx_id,				
	ah.co_trx_id,			
	trx.co_asset_id,
	ah.co_asset_book_id,
	"",				  		
	ah.apply_date,			
	ah.trx_type,
   	trx.trx_description,
	trx.doc_reference,
	trx.change_in_quantity,
   	ah.last_modified_date,
	b.post_to_gl,
	trd.summmarize_activity,
	s.org_id		
FROM	amtrxhdr	trx,
		amacthst 	ah,
		amastbk 	ab,
		ambook 		b,
		amtrxdef    trd, amasset s	
WHERE	ah.journal_ctrl_num	= @trx_ctrl_num
AND		ah.co_asset_book_id	= ab.co_asset_book_id
AND		ab.book_code		= b.book_code
AND		ah.co_trx_id		= trx.co_trx_id
AND		ah.trx_type			= trd.trx_type
AND		s.co_asset_id			= ab.co_asset_id	

SELECT @result = @@error
IF @result <> 0
	RETURN @result









INSERT INTO #amacthdr
(
	trx_co_trx_id,
	co_trx_id, 
	co_asset_id,
	co_asset_book_id,
	journal_ctrl_num,
	apply_date, 
	trx_type, 
	trx_description,
	doc_reference,
	change_in_quantity,
	last_modified_date,
	post_to_gl,
	sum_val,
	asset_org_id		
)
SELECT DISTINCT				
	@co_trx_id,				
	ah.co_trx_id,			
	trx.co_asset_id,
	ah.co_asset_book_id,
	"",				  		
	ah.apply_date,			
	ah.trx_type,
   	trx.trx_description,
	trx.doc_reference,
	trx.change_in_quantity,
   	ah.last_modified_date,
	b.post_to_gl,
	trd.summmarize_activity,
	s.org_id		
FROM	#amacthdr	tmp,
		amtrxhdr	trx,
		amacthst 	ah,
		amastbk 	ab,
		ambook 		b,
		amtrxdef    trd, amasset s  		
WHERE	ah.journal_ctrl_num	!= @trx_ctrl_num		
AND		ah.co_asset_book_id	= ab.co_asset_book_id
AND		ab.book_code		= b.book_code
AND		ah.co_trx_id		= trx.co_trx_id
AND		ah.posting_flag		= 100
AND		ah.co_asset_book_id	= tmp.co_asset_book_id
AND		ab.co_asset_book_id	= tmp.co_asset_book_id
AND		ah.apply_date		<= tmp.apply_date
AND		ah.trx_type			= trd.trx_type
AND		s.co_asset_id			= ab.co_asset_id	


SELECT @result = @@error
IF @result <> 0
	RETURN @result

IF @debug_level >= 3
BEGIN
	SELECT "Activity Headers"

	SELECT 	CONVERT(char(20), "Co Trx ID") + 
			CONVERT(char(20), "Asset Book ID" ) +
			CONVERT(char(20), "Trx Type" ) +
			CONVERT(char(15), "Apply Date" ) +
			CONVERT(char(20), "Post To GL" ) +
			CONVERT(char(20), "Sum Trx" ) 

	SELECT 	
			CONVERT(char(20), co_trx_id) + 
			CONVERT(char(20), co_asset_book_id) + 
			CONVERT(char(20), trx_type ) +
			CONVERT(char(15), apply_date, 112 ) +
			CONVERT(char(20), post_to_gl ) +
			CONVERT(char(20), sum_val ) 
	FROM	#amacthdr
	ORDER BY co_trx_id  


END





















UPDATE 	#amacthdr
SET		post_to_gl	= 0
WHERE	trx_type NOT IN  (60, 10 ,30, 70)
AND		trx_type NOT IN (
						  SELECT 	trx_type 
						  FROM 		amtrxdef 
						  WHERE 	post_to_gl = 1)





IF @post_depreciation = 0
BEGIN
	UPDATE 	#amacthdr
	SET		post_to_gl 	= 0
	WHERE	post_to_gl 	= 1
	AND 	trx_type	= 60

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END 




IF @post_additions = 0
BEGIN
   	UPDATE 	#amacthdr
  	SET		post_to_gl 	= 0
	WHERE	post_to_gl 	= 1
	AND 	trx_type	= 10

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END




IF @post_dispositions = 0
BEGIN

	UPDATE 	#amacthdr
  	SET		post_to_gl 	= 0
	WHERE	post_to_gl 	= 1
	AND 	trx_type    IN (30, 70)

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
END






IF @post_other_activities = 0
BEGIN

	UPDATE 	#amacthdr
  	SET		post_to_gl 	= 0
	WHERE	post_to_gl 	= 1
	AND 	trx_type	IN (
							SELECT trx_type 
							FROM amtrxdef 
							WHERE post_to_gl = 1)

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result
END



INSERT INTO #amactval
(
		co_trx_id, 
		account_type_id,
		account_id,
		account_code,
		account_reference_code,
		amount
)
SELECT
		v.co_trx_id,
		v.account_type_id,
		v.account_id,
		a.account_code,
		a.account_reference_code,
		v.amount
FROM	#amacthdr 	ah,
	   	amvalues	v,
	   	amacct		a
WHERE	v.co_trx_id			= ah.co_trx_id
AND		v.co_asset_book_id	= ah.co_asset_book_id
AND		ah.post_to_gl		= 1						
AND		v.account_id		= a.account_id
AND		(ABS((v.amount)-(0.0)) > 0.0000001)							
AND     ah.sum_val 			= 0
				
SELECT @result = @@error
IF @result <> 0
	RETURN @result


INSERT INTO #amsumactval
(
		apply_date, 
		trx_type,
		account_id,
		account_code,
		account_reference_code,
		amount,
		asset_org_id		
)
SELECT
		ah.apply_date,
		ah.trx_type,
		a.account_id,
		a.account_code,
		a.account_reference_code,
		(SIGN(ISNULL(SUM(v.amount), 0.0)) * ROUND(ABS(ISNULL(SUM(v.amount), 0.0)) + 0.0000001, @curr_precision)),
		ah.asset_org_id		
FROM	#amacthdr 	ah,
		amvalues	v,
		amacct		a
WHERE	v.co_trx_id			= ah.co_trx_id
AND		v.co_asset_book_id	= ah.co_asset_book_id
AND		ah.post_to_gl		= 1						
AND		v.account_id		= a.account_id
AND     ah.sum_val 			= 1
GROUP BY
		ah.apply_date,
		ah.trx_type,
		a.account_id,
		a.account_code,
		a.account_reference_code,
		ah.asset_org_id		

		
				
SELECT @result = @@error
IF @result <> 0
	RETURN @result




	
IF @debug_level >= 3
BEGIN
	SELECT "*** Depreciation Transaction Summary"

	SELECT 	CONVERT(char(20), "Account ID" ) +
			CONVERT(char(40), "Amount" )

	SELECT 	CONVERT(char(20), account_id ) +
			"$" + LTRIM(CONVERT(char(255), CONVERT(money, amount)))
	FROM	#amsumval
	ORDER BY account_id


	SELECT "*** Activity Headers"

	SELECT 	"Co Trx ID           Trx Type            Post to GL           Sum Value           Apply Date" 

	SELECT 	CONVERT(char(20), co_trx_id) + 
			CONVERT(char(20), trx_type ) +
			CONVERT(char(20), post_to_gl ) +
			CONVERT(char(20), sum_val ) + 
			CONVERT(char(8), apply_date, 112 )
	FROM	#amacthdr
	ORDER BY co_trx_id

	SELECT "*** Activity Values"

	SELECT 	CONVERT(char(20), "Co Trx ID") + 
			CONVERT(char(20), "Account ID" ) +
			CONVERT(char(40), "Amount" )

	SELECT 	CONVERT(char(20), co_trx_id) + 
			CONVERT(char(20), account_id ) +
			"$" + LTRIM(CONVERT(char(255), CONVERT(money, amount)))
	FROM	#amactval
	ORDER BY co_trx_id, account_id

	SELECT "*** Activity Summary"

	SELECT 	CONVERT(char(20), "Apply Date" ) +
			CONVERT(char(20), "Trx Type" ) +
			CONVERT(char(20), "Account ID" ) +
			CONVERT(char(40), "Amount" )

	SELECT 
			CONVERT(char(20), apply_date, 112 ) +
			CONVERT(char(20), trx_type ) +
			CONVERT(char(20), account_id ) +
			"$" + LTRIM(CONVERT(char(255), CONVERT(money, amount)))
	FROM	#amsumactval
	ORDER BY apply_date,trx_type,account_id

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amsumtrx.cpp" + ", line " + STR( 560, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amSummariseTrx_sp] TO [public]
GO
