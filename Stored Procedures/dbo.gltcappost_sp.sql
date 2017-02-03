SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[gltcappost_sp] 	@batch_ctrl_num	varchar(16),
 				@debug_level 	smallint = 0,
 				@trx_type    smallint = 0

AS

DECLARE
 	@result 		int,
 	@batch_process_flag     int 

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcappost.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

     IF( @trx_type = 4091)      /* 4091 =  Vouchers, 4092= DebitMemo */
     BEGIN


	IF( @debug_level > 1 )
	BEGIN
	 SELECT 'dumping #apvochg_work'
	 SELECT 'trx_ctrl_num:trx_type:doc_ctrl_num:batch_code:posted_flag'
	 SELECT ISNULL( trx_ctrl_num , ' ' ) + STR(trx_type,7) + 
	        ISNULL( doc_ctrl_num,  ' ' ) + ISNULL(batch_code, ' ') +
	        STR(posted_flag,4)
	   FROM #apvochg_work  WHERE batch_code = @batch_ctrl_num
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
		apvo.doc_ctrl_num, 
		apvo.batch_code,
		0
	FROM apgltcrecon_vw gltc, #apvochg_work apvo
	WHERE gltc.trx_ctrl_num = apvo.trx_ctrl_num
	AND apvo.batch_code = @batch_ctrl_num

	IF ( @debug_level > 1 )
	BEGIN
		    SELECT	"Records in #gltcpost_work "
		    SELECT	"trx_ctrl_num:posted_flag:remote_state:remote_error:batch_code:remote_doc_id"
		    SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
				STR(posted_flag, 4) + ":" +
				STR(remote_state,4) + ":" +
				STR(remote_error,4) + ":" +
				ISNULL(batch_code, " ")+":" +
				STR(remote_doc_id,20)
		    FROM	#gltcpost_work
        END 

	IF (( SELECT COUNT(*) FROM #ewerror ) = 0)
	 RETURN 0

          
        UPDATE	#gltcpost_work 
		SET	 posted_flag = 0
		FROM	#gltcpost_work gltc, #ewerror b, apedterr aperr
		WHERE	gltc.trx_ctrl_num = b.trx_ctrl_num AND 
		        ( gltc.remote_error = aperr.err_code OR 
			b.err_code = aperr.err_code ) AND
		        aperr.err_type = 0 
     
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcappost.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	/* voucher to tcc post */
    END


    IF( @trx_type = 4092)      /* 4091 =  Vouchers, 4092= DebitMemo */
    BEGIN
    
	IF( @debug_level > 1 )
	BEGIN
	 SELECT 'dumping #apdmchg_work'
	 SELECT 'trx_ctrl_num:trx_type:doc_ctrl_num:batch_code:posted_flag'
	 SELECT ISNULL( trx_ctrl_num , ' ' ) + STR(trx_type,7) + 
	        ISNULL( doc_ctrl_num,  ' ' ) + ISNULL(batch_code, ' ') +
	        STR(posted_flag,4)
	   FROM #apdmchg_work  WHERE batch_code = @batch_ctrl_num
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
		apvo.doc_ctrl_num, 
		apvo.batch_code,
		0
	FROM apgltcrecon_vw gltc, #apdmchg_work apvo
	WHERE gltc.trx_ctrl_num = apvo.trx_ctrl_num
	AND apvo.batch_code = @batch_ctrl_num

	IF ( @debug_level > 1 )
	BEGIN
		    SELECT	"Records in #gltcpost_work "
		    SELECT	"trx_ctrl_num:posted_flag:remote_state:remote_error:batch_code:remote_doc_id"
		    SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
				STR(posted_flag, 4) + ":" +
				STR(remote_state,4) + ":" +
				STR(remote_error,4) + ":" +
				ISNULL(batch_code, " ")+":" +
				STR(remote_doc_id,20)
		    FROM	#gltcpost_work
        END 

	IF (( SELECT COUNT(*) FROM #ewerror ) = 0)
	 RETURN 0

          
        UPDATE	#gltcpost_work 
		SET	 posted_flag = 0
		FROM	#gltcpost_work gltc, #ewerror b, apedterr aperr
		WHERE	gltc.trx_ctrl_num = b.trx_ctrl_num AND 
		        ( gltc.remote_error = aperr.err_code OR 
			b.err_code = aperr.err_code ) AND
		        aperr.err_type = 0 

     
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcappost.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	/* debit memo to tcc post */

    END
	
	
END

GO
GRANT EXECUTE ON  [dbo].[gltcappost_sp] TO [public]
GO
