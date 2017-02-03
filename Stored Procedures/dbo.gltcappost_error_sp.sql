SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[gltcappost_error_sp] 	@batch_ctrl_num	varchar(16),
 				@debug_level 	smallint = 0,
 				@trx_type    smallint = 0

AS

DECLARE
 	@result 		int,
 	@tax_connect_flag int

BEGIN
      select @tax_connect_flag = 0
      select @tax_connect_flag = tax_connect_flag from apco

     IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcposterr.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

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

		SELECT	"Records in #gltcpost_work"
		SELECT	"trx_ctrl_num:posted_flag:remote_state:remote_error:batch_code:remote_doc_id"
		SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
			STR(posted_flag, 4) + ":" +
			STR(remote_state,4) + ":" +
			STR(remote_error,10) + ":" +
			ISNULL(batch_code, ' ')+":" +
			STR(remote_doc_id,20)
		FROM	#gltcpost_work
	END
	
	
	
	INSERT #ewerror (
			module_id,
			err_code,
			info1,
			info2,
			infoint,
			infofloat,
			flag1,
			trx_ctrl_num,
			sequence_id,
			source_ctrl_num,
			extra
		)

	SELECT  4000,
			gltc.remote_error * -1,
			apvo.vendor_code,
			apvo.doc_ctrl_num,
			0,
			0.0,
			1,
			gltc.trx_ctrl_num,
			0,
			ISNULL(apvo.trx_ctrl_num, ""),
			0
		FROM	#gltcpost_work gltc, #apvochg_work apvo
		WHERE	gltc.remote_error > 0
		AND 	gltc.trx_ctrl_num = apvo.trx_ctrl_num
		AND	apvo.batch_code = @batch_ctrl_num

		--type  0 = error 1 = warn 2 = ignore   in apedterr table
		
        IF @tax_connect_flag = 0
        BEGIN

		INSERT #ewerror (
			module_id,
			err_code,
			info1,
			info2,
			infoint,
			infofloat,
			flag1,
			trx_ctrl_num,
			sequence_id,
			source_ctrl_num,
			extra
		)

		SELECT  4000,
			-20104,
			apvo.vendor_code,
			apvo.doc_ctrl_num,
			0,
			0.0,
			1,
			gltc.trx_ctrl_num,
			0,
			ISNULL(apvo.trx_ctrl_num, ""),
			0
		FROM	#gltcpost_work gltc, #apvochg_work apvo
		WHERE	gltc.trx_ctrl_num = apvo.trx_ctrl_num
		AND	apvo.batch_code = @batch_ctrl_num

       END


	UPDATE	#gltcpost_work 
		SET	posted_flag = 0
		FROM	#gltcpost_work gltc, #ewerror b,  apedterr aperr
		WHERE	gltc.trx_ctrl_num = b.trx_ctrl_num AND 
				(gltc.remote_error * -1)  = aperr.err_code AND
       				aperr.err_type = 0 

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcapposterr.sp" + ", line " + STR( 100, 5 ) + " -- UPDATE ERR: "
		RETURN 34563
	END
       
       
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
 
 		SELECT	"Records in #gltcpost_work"
 		SELECT	"trx_ctrl_num:posted_flag:remote_state:remote_error:batch_code:remote_doc_id"
 		SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
 			STR(posted_flag, 4) + ":" +
 			STR(remote_state,4) + ":" +
 			STR(remote_error,10) + ":" +
 			ISNULL(batch_code, ' ')+":" +
 			STR(remote_doc_id,20)
 		FROM	#gltcpost_work
 	END
 	
 	
 	
 	INSERT #ewerror (
 			module_id,
 			err_code,
 			info1,
 			info2,
 			infoint,
 			infofloat,
 			flag1,
 			trx_ctrl_num,
 			sequence_id,
 			source_ctrl_num,
 			extra
 		)
 
 	SELECT  4000,
 			gltc.remote_error * -1,
 			apdm.vendor_code,
 			apdm.doc_ctrl_num,
 			0,
 			0.0,
 			1,
 			gltc.trx_ctrl_num,
 			0,
 			ISNULL(apdm.trx_ctrl_num, ""),
 			0
 		FROM	#gltcpost_work gltc, #apdmchg_work apdm
 		WHERE	gltc.remote_error > 0
 		AND 	gltc.trx_ctrl_num = apdm.trx_ctrl_num
 		AND	apdm.batch_code = @batch_ctrl_num
 
 		--type  0 = error 1 = warn 2 = ignore   in apedterr table
 		
        IF @tax_connect_flag = 0
        BEGIN

		INSERT #ewerror (
			module_id,
			err_code,
			info1,
			info2,
			infoint,
			infofloat,
			flag1,
			trx_ctrl_num,
			sequence_id,
			source_ctrl_num,
			extra
		)

		SELECT  4000,
			-20104,
			apdm.vendor_code,
 			apdm.doc_ctrl_num,
 			0,
 			0.0,
 			1,
 			gltc.trx_ctrl_num,
 			0,
 			ISNULL(apdm.trx_ctrl_num, ""),
 			0
 		FROM	#gltcpost_work gltc, #apdmchg_work apdm
 		WHERE	gltc.trx_ctrl_num = apdm.trx_ctrl_num
 		AND	apdm.batch_code = @batch_ctrl_num

       END
 		
 
 	UPDATE	#gltcpost_work 
 		SET	posted_flag = 0
 		FROM	#gltcpost_work gltc, #ewerror b,  apedterr aperr
 		WHERE	gltc.trx_ctrl_num = b.trx_ctrl_num AND 
 				(gltc.remote_error * -1)  = aperr.err_code AND
        				aperr.err_type = 0 
 
 	IF( @@error != 0 )
 	BEGIN
 		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcapposterr.sp" + ", line " + STR( 100, 5 ) + " -- UPDATE ERR: "
 		RETURN 34563
 	END

    END
       
	
	IF ( @debug_level > 1 )
	BEGIN
	    SELECT	"Records in #gltcpost_work before save to #ewerror"
	    SELECT	"trx_ctrl_num:posted_flag:remote_state:remote_error:batch_code:remote_doc_id"
	    SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
			STR(posted_flag, 4) + ":" +
			STR(remote_state,4) + ":" +
			STR(remote_error,10) + ":" +
			ISNULL(batch_code, ' ')+":" +
			STR(remote_doc_id,20)
	    FROM	#gltcpost_work
        END   
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcposterr.sp" +  " -- EXIT: " 

END

GO
GRANT EXECUTE ON  [dbo].[gltcappost_error_sp] TO [public]
GO
