SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCopyToGL_sp] 
(
	@process_ctrl_num 	smProcessCtrlNum, 	
	@batch_ctrl_num		smBatchCode,
	@org_company 		smCompanyCode,		
	@trx_type			smTrxType,
	@debug_level		smDebugLevel 	= 0	
)
AS 

DECLARE 
	@result 			smErrorCode,
	@tran_started		smLogical		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcptogl.sp" + ", line " + STR( 100, 5 ) + " -- ENTRY: "



CREATE TABLE #amastqty
(	
	co_asset_id			int	NOT NULL,	
	change_in_quantity	int	NOT NULL	
)




INSERT INTO #amastqty
(
	co_asset_id,
	change_in_quantity
)
SELECT	
		co_asset_id,
		ISNULL(SUM(change_in_quantity), 0)
FROM 	#amacthdr tmp
WHERE	tmp.post_to_gl 	= 1
GROUP BY co_asset_id

CREATE INDEX #amastqty_temp on #amastqty (co_asset_id)

IF @debug_level >= 3
BEGIN
	SELECT	"Asset Qty Table"
	SELECT	"==============="
	
	SELECT	CONVERT( char(20), "co_asset_id" ) +
			CONVERT( char(20), "change_in_quantity" ) 		
	SELECT	
			CONVERT( char(20), tmp.co_asset_id ) +
			CONVERT( char(20), tmp.change_in_quantity )
	FROM	#amastqty	tmp
END
	

IF @@trancount > 0
BEGIN
	SELECT @tran_started = 1
	BEGIN TRANSACTION 
END
ELSE
	SELECT	@tran_started = 0

EXEC @result = amMarkProcessPosted_sp 
				@process_ctrl_num,
				@trx_type,
				@batch_ctrl_num,
				@debug_level 
				WITH RECOMPILE

IF (@result <> 0)
BEGIN
	IF @tran_started = 1
		ROLLBACK TRANSACTION 
	RETURN @result
END

EXEC @result = gltrxsav_sp 
				@process_ctrl_num, 
				@org_company,
				@debug_level

IF (@result <> 0)
BEGIN
	IF @tran_started = 1
		ROLLBACK TRANSACTION 
END
ELSE
BEGIN
	IF @tran_started = 1
		COMMIT TRANSACTION 	
END

DROP TABLE #amastqty

IF @result = 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcptogl.sp" + ", line " + STR( 173, 5 ) + " -- EXIT: "

RETURN @result

GO
GRANT EXECUTE ON  [dbo].[amCopyToGL_sp] TO [public]
GO
