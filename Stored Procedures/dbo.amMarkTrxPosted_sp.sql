SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amMarkTrxPosted_sp] 
(
	@process_ctrl_num	smProcessCtrlNum, 		
	@trx_type			smTrxType,		 		
	@debug_level		smDebugLevel 	= 0		
)

AS 
DECLARE 
	@result				smErrorCode,
	@message			smErrorLongDesc,
	@trans_started		smLogical


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammrkpst.sp" + ", line " + STR( 124, 5 ) + " -- ENTRY: "



CREATE TABLE #amtrxastqty
(
	co_trx_id			int NOT NULL,
	co_asset_id			int	NOT NULL,	
	change_in_quantity	int		
)

INSERT 	#amtrxastqty (co_trx_id, co_asset_id,change_in_quantity)
SELECT 	DISTINCT 	co_trx_id, co_asset_id,0.0
FROM 	#amacthdr 

UPDATE 	#amtrxastqty
SET		change_in_quantity 	= a.change_in_quantity
FROM	#amacthdr a, #amtrxastqty b		 
WHERE	a.co_trx_id 	= b.co_trx_id 
AND 	a.co_asset_id 	= b.co_asset_id


IF @debug_level >= 3
BEGIN
	SELECT	"amtrxastqty Table"	
	SELECT "================="
	SELECT	CONVERT( char(20), "co_trx_id" ) +
			CONVERT( char(20), "co_asset_id" ) +
			CONVERT( char(20), "change_in_quantity" ) 		
	SELECT	
			CONVERT( char(20), tmp.co_trx_id ) +
			CONVERT( char(20), tmp.co_asset_id ) +
			CONVERT( char(20), tmp.change_in_quantity )
	FROM	#amtrxastqty	tmp
END


CREATE TABLE #amastqty_nopost
(	
	co_asset_id			int	NOT NULL,	
	change_in_quantity	int				
)

INSERT INTO #amastqty_nopost
(
	co_asset_id,
	change_in_quantity
)
SELECT	
		tmp.co_asset_id,
		ISNULL(SUM(change_in_quantity), 0)
FROM 	#amtrxastqty tmp
GROUP BY co_asset_id

CREATE INDEX #amastqty_nop_temp on #amastqty_nopost (co_asset_id)

IF @debug_level >= 3
BEGIN
	SELECT	"Asset Qty Table"
	SELECT	"==============="
	
	SELECT	CONVERT( char(20), "co_asset_id" ) +
			CONVERT( char(20), "change_in_quantity" ) 		
	SELECT	
			CONVERT( char(20), tmp.co_asset_id ) +
			CONVERT( char(20), tmp.change_in_quantity )
	FROM	#amastqty_nopost	tmp
END


DROP TABLE #amtrxastqty


SELECT @trans_started = 0
IF (@@trancount = 0)
BEGIN
	BEGIN TRANSACTION 
	SELECT @trans_started = 1 
END

IF @debug_level >= 3
	SELECT point_1="update amtrxhdr depreciation"

UPDATE 	amtrxhdr
SET 	posting_flag 		= 1,
		date_posted			= GETDATE()
FROM 	#amtrxhdr 	tmp,
		amtrxhdr 	th
WHERE 	tmp.co_trx_id		= th.co_trx_id

SELECT @result = @@error 

IF (@result != 0)
BEGIN
	IF @debug_level >= 3
		SELECT point_1="rollback"

	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 



IF @debug_level >= 3
	SELECT point_2="update amtrxhdr activities"

UPDATE 	amtrxhdr
SET 	posting_flag			= 1,
		date_posted 			= GETDATE()
FROM 	#amacthdr tmp,
		amtrxhdr trx
WHERE 	tmp.co_trx_id 			= trx.co_trx_id
AND		tmp.post_to_gl			= 1

SELECT @result = @@error 
IF (@result != 0)
BEGIN
	IF @debug_level >= 3
		SELECT point_2="rollback"

	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 


IF @debug_level >= 3
 	SELECT point_3="update amtrxhdr trx- no post to GL"

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
	IF @debug_level >= 3 
		SELECT point_3="rollback"

	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 



IF @debug_level >= 3 
		SELECT point_4="update amasset"

UPDATE	amasset
SET		orig_quantity 			= a.orig_quantity + aq.change_in_quantity
FROM	#amastqty_nopost 	aq,
		amasset		a
WHERE	a.co_asset_id 			= aq.co_asset_id
AND		aq.change_in_quantity	!= 0 



SELECT @result = @@error 
IF (@result != 0)
BEGIN

	IF @debug_level >= 3 
		SELECT point_3="rollback"

	DROP TABLE #amastqty_nopost
	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 





IF @debug_level >= 3 
		SELECT point_4="update amacthst"

UPDATE 	amacthst
SET 	posting_flag 			= 1,
		journal_ctrl_num		= ""
FROM 	#amacthdr 	tmp,
		amacthst 	ah
WHERE 	tmp.co_trx_id 			= ah.co_trx_id
AND		tmp.co_asset_book_id	= ah.co_asset_book_id

SELECT @result = @@error 

IF (@result != 0)
BEGIN

	IF @debug_level >= 3 
		SELECT point_4="rollback"

	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 


IF @debug_level >= 3 
		SELECT point_5="delete amtrxast"

DELETE amtrxast
FROM	amtrxast ta, #amtrxhdr tmp
WHERE 	ta.co_trx_id		= tmp.co_trx_id 

SELECT @result = @@error 
IF (@result != 0)
BEGIN

	IF @debug_level >= 3 
		SELECT point_5="rollback"

	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 


IF @debug_level >= 3 
		SELECT point_6="delete amtrxast"

DELETE amtrxast
FROM	amtrxast ta, #amacthdr tmp
WHERE 	ta.co_trx_id		= tmp.co_trx_id 

SELECT @result = @@error 
IF (@result != 0)
BEGIN

	IF @debug_level >= 3 
		SELECT point_6="rollback"

	IF (@trans_started = 1)
		ROLLBACK TRANSACTION
	RETURN @result
END 


IF @trx_type = 50
BEGIN
	

	IF @debug_level >= 3 
		SELECT point_7="update amvalues"

	UPDATE 	amvalues
	SET 	posting_flag 	= 1
	FROM 	#amtrxhdr tmp,
			amvalues v
	WHERE 	v.co_trx_id 	= tmp.co_trx_id

	SELECT @result = @@error

	IF (@result != 0)
	BEGIN 
		IF @debug_level >= 3 
			SELECT point_7="rollback"

		IF (@trans_started = 1)
			ROLLBACK TRANSACTION 
		RETURN @result
	END
END

IF (@trans_started = 1)
	COMMIT TRANSACTION 

DROP TABLE #amastqty_nopost



IF @debug_level >= 3
BEGIN
	SELECT	th.trx_ctrl_num, 
			th.co_trx_id, 
			th.posting_flag
	FROM	#amtrxhdr 	tmp,
			amtrxhdr	th
	WHERE	th.co_trx_id 	= tmp.co_trx_id

	SELECT	v.co_trx_id, 
			v.posting_flag
	FROM	#amtrxhdr 	tmp,
			amvalues	v
	WHERE	v.co_trx_id 	= tmp.co_trx_id

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammrkpst.sp" + ", line " + STR( 472, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amMarkTrxPosted_sp] TO [public]
GO
