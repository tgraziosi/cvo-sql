SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[gltcpost_sp] 	@batch_ctrl_num	varchar(16),
 				@debug_level 	smallint = 0

AS

DECLARE
 	@result 		int

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcpost.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

	IF( @debug_level > 1  )
	BEGIN
	 SELECT 'dumping #arinpchg_work'
	 SELECT 'trx_ctrl_num:trx_type:doc_ctrl_num:batch_code:posted_flag'
	 SELECT ISNULL( trx_ctrl_num , ' ' ) + ":" + STR(trx_type,7) + ":" + 
	        ISNULL( doc_ctrl_num,  ' ' ) + ":" + ISNULL(batch_code, ' ') + ":" +
	        STR(posted_flag,4)
	   FROM #arinpchg_work  WHERE batch_code = @batch_ctrl_num
	END




	INSERT #gltcpost_work (
		trx_ctrl_num,
		trx_type,
		posted_flag,
		remote_doc_id,
		remote_state,
		remote_amt_gross,
		remote_amt_tax,
		date_doc,
		doc_ctrl_num, 
		batch_code,
		remote_error
		)
	SELECT
		gltc.trx_ctrl_num,
		gltc.trx_type,
		1,
		gltc.remote_doc_id,
		gltc.remote_state,
		gltc.remote_amt_gross,
		gltc.remote_amt_tax,
		gltc.date_doc,
		arin.doc_ctrl_num, 
		arin.batch_code,
		0
	FROM argltcrecon_vw gltc, #arinpchg_work arin
	WHERE gltc.trx_ctrl_num = arin.trx_ctrl_num
	AND arin.batch_code = @batch_ctrl_num

        IF( @debug_level > 1 )
	BEGIN
	   SELECT	"Records in #gltcpost_work"
	   SELECT	"trx_ctrl_num:trx_type:posted_flag:remote_state:batch_code"
	   SELECT	ISNULL(trx_ctrl_num,' ' ) + ":" +
			STR(trx_type,7 ) + ":" +
			STR(posted_flag,4) + ":" +
			STR(remote_state,4)+ ":" +
			ISNULL(batch_code, ' ')
			FROM	#gltcpost_work
	END






	IF (( SELECT COUNT(*) FROM #ewerror ) = 0)
	BEGIN
	 IF( @debug_level > 1 )
	  BEGIN 
	     SELECT 'No records in  #ewerror'
	  END
	 RETURN 0
        END
        ELSE
        BEGIN
           IF( @debug_level > 1 )
	    BEGIN
		SELECT	"Records in #ewerror"
		SELECT	"err_code:flag1:trx_ctrl_num:source_ctrl_num"
		SELECT	STR(err_code, 7) + ":" +
			STR(flag1, 4) + ":" +
			ISNULL(trx_ctrl_num, ' ') + ":" +
			ISNULL(source_ctrl_num, ' ')
			FROM	#ewerror
	    END
        END
        
	UPDATE	#gltcpost_work 
		SET	batch_code = ' ',
			posted_flag = 0
		FROM	#gltcpost_work gltc, #ewerror b
		WHERE	gltc.trx_ctrl_num = b.trx_ctrl_num

	IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcpost.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
			RETURN 34563
		END

END
GO
GRANT EXECUTE ON  [dbo].[gltcpost_sp] TO [public]
GO
