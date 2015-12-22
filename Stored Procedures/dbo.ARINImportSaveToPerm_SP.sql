SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARINImportSaveToPerm_SP] @user_id		smallint,
					 @debug_level		smallint = 0
						
AS
BEGIN
	DECLARE	
		@batch_code	varchar( 16 ),
		@result 	smallint
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinistp.sp" + ", line " + STR( 24, 5 ) + " -- ENTRY: "
	
	DELETE	#arinpchg
	FROM	#ewerror
	WHERE	#arinpchg.trx_ctrl_num = #ewerror.trx_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinistp.sp" + ", line " + STR( 31, 5 ) + " -- EXIT: "
	 	RETURN 34563
	END
	
	DELETE	#arinpcdt
	FROM	#ewerror
	WHERE	#arinpcdt.trx_ctrl_num = #ewerror.trx_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinistp.sp" + ", line " + STR( 40, 5 ) + " -- EXIT: "
	 	RETURN 34563
	END
	
	DELETE	#arinpage
	FROM	#ewerror
	WHERE	#arinpage.trx_ctrl_num = #ewerror.trx_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinistp.sp" + ", line " + STR( 49, 5 ) + " -- EXIT: "
	 	RETURN 34563
	END
	
	DELETE	#arinptax
	FROM	#ewerror
	WHERE	#arinptax.trx_ctrl_num = #ewerror.trx_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinistp.sp" + ", line " + STR( 58, 5 ) + " -- EXIT: "
	 	RETURN 34563
	END
	
	DELETE	#arinprev
	FROM	#ewerror
	WHERE	#arinprev.trx_ctrl_num = #ewerror.trx_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinistp.sp" + ", line " + STR( 67, 5 ) + " -- EXIT: "
	 	RETURN 34563
	END
	



CREATE TABLE #arinbat
(
	date_applied		int, 
	process_group_num	varchar(16),
	trx_type		smallint,
	batch_ctrl_num char(16) NULL,
	flag			smallint
)


CREATE TABLE #arbatsum
(
	batch_ctrl_num char(16) NOT NULL,
	actual_number int NOT NULL,
	actual_total float NOT NULL
)


CREATE TABLE #arbatnum
(
	date_applied		int,
	process_group_num	varchar(16),
	trx_type		smallint,
	flag			smallint,
	batch_ctrl_num		char(16) NULL,
	batch_description char(30) NULL,
	company_code char(8) NULL,
	seq			numeric identity
)


	BEGIN TRAN

	EXEC	@result = arinsav_sp	@user_id, @batch_code OUTPUT

	IF ( @result != 0 )
	BEGIN
		ROLLBACK TRAN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinistp.sp" + ", line " + STR( 82, 5 ) + " -- EXIT: "
		RETURN @result
	END

	COMMIT TRAN
	
	DROP TABLE #arinbat
	DROP TABLE #arbatsum
	DROP TABLE #arbatnum

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinistp.sp" + ", line " + STR( 92, 5 ) + " -- EXIT: "
	
	RETURN	0
END
GO
GRANT EXECUTE ON  [dbo].[ARINImportSaveToPerm_SP] TO [public]
GO
