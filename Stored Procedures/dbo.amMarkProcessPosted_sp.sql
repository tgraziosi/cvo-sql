SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amMarkProcessPosted_sp] 
(
	@process_ctrl_num	smProcessCtrlNum, 	
	@trx_type			smTrxType,		 	
	@batch_ctrl_num		smBatchCode,		
	@debug_level		smDebugLevel 	= 0	
)

AS 
DECLARE 
	@result				smErrorCode,
	@message			smErrorLongDesc,
	@trans_started		smLogical


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammkprps.sp" + ", line " + STR( 75, 5 ) + " -- ENTRY: "


SELECT @trans_started = 0
IF (@@trancount = 0)
BEGIN
	BEGIN TRANSACTION 
	SELECT @trans_started = 1 
END


UPDATE 	amtrxhdr
SET 	batch_ctrl_num		= tmp.batch_ctrl_num,
		journal_ctrl_num	= tmp.journal_ctrl_num,
		posting_flag 		= 1,
		date_posted			= GETDATE()
FROM 	#amtrxhdr tmp,
		amtrxhdr th
WHERE 	tmp.co_trx_id 		= th.co_trx_id

SELECT @result = @@error 

IF (@result != 0)
BEGIN
	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 



UPDATE 	amtrxhdr
SET 	journal_ctrl_num		= tmp.journal_ctrl_num,
		posting_flag			= 1,
		date_posted 			= GETDATE()
FROM 	#amacthdr tmp,
		amtrxhdr trx
WHERE 	tmp.co_trx_id 			= trx.co_trx_id
AND		tmp.post_to_gl			= 1

SELECT @result = @@error 
IF (@result != 0)
BEGIN
	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 



UPDATE 	amtrxhdr
SET 	posting_flag			= 1
FROM 	#amacthdr tmp,
		amtrxhdr trx
WHERE 	tmp.co_trx_id 			= trx.co_trx_id
AND		tmp.post_to_gl			= 0
AND		trx.posting_flag		!= 1

SELECT @result = @@error 
IF (@result != 0)
BEGIN
	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 



UPDATE	amasset
SET		orig_quantity 			= a.orig_quantity + aq.change_in_quantity
FROM	#amastqty 	aq,
		amasset		a
WHERE	a.co_asset_id 			= aq.co_asset_id
AND		aq.change_in_quantity	!= 0

SELECT @result = @@error 
IF (@result != 0)
BEGIN

	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 



UPDATE 	amacthst
SET 	journal_ctrl_num		= tmp.journal_ctrl_num,
		posting_flag 			= 1
FROM 	#amacthdr tmp,
		amacthst ah
WHERE 	tmp.co_trx_id 			= ah.co_trx_id
AND		tmp.co_asset_book_id	= ah.co_asset_book_id

SELECT @result = @@error 
IF (@result != 0)
BEGIN
	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 



DELETE amtrxast
FROM	amtrxast ta, #amtrxhdr tmp
WHERE 	ta.co_trx_id		= tmp.co_trx_id 

SELECT @result = @@error 
IF (@result != 0)
BEGIN
	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 


IF @trx_type = 50
BEGIN
	

	UPDATE 	amvalues
	SET 	posting_flag 	= 1
	FROM 	#amtrxhdr tmp,
			amvalues v
	WHERE 	tmp.co_trx_id 	= v.co_trx_id

	SELECT @result = @@error
	IF (@result != 0)
	BEGIN 
		IF (@trans_started = 1)
			ROLLBACK TRANSACTION 
		RETURN @result
	END
END


EXEC @result = batupdst_sp	
					@batch_ctrl_num, 
					1

IF (@result != 0)
BEGIN
	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 


IF (@trans_started = 1)
	COMMIT TRANSACTION 




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammkprps.sp" + ", line " + STR( 294, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amMarkProcessPosted_sp] TO [public]
GO
