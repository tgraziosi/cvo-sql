SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[gltcpost_error_sp] 	@batch_ctrl_num	varchar(16),
 				@debug_level 	smallint = 0

AS

DECLARE
 	@result   int,
        @tax_connect_flag int
BEGIN

        select @tax_connect_flag = tax_connect_flag from arco 
        
        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcposterr.sp" + " Insert records not posted  "
	
	IF ( @debug_level > 1 )
	BEGIN
	    SELECT	"Records in #gltcpost_work"
	    SELECT	"trx_ctrl_num:posted_flag:remote_state:remote_error:batch_code:remote_doc_id"
	    SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
			STR(posted_flag, 4) + ":" +
			STR(remote_state,4) + ":" +
			STR(remote_error,4) + ":" +
			ISNULL(batch_code, " ")+":" +
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

	SELECT  2000,
	 	gltc.remote_error,
		arin.customer_code,
		arin.doc_ctrl_num,
		0,
		0.0,
		1,
		gltc.trx_ctrl_num,
		0,
		ISNULL(arin.source_trx_ctrl_num, ""),
		0
	FROM	#gltcpost_work gltc, #arinpchg_work arin
	WHERE	gltc.remote_error > 0
	AND 	gltc.trx_ctrl_num = arin.trx_ctrl_num
	AND	arin.batch_code = @batch_ctrl_num


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

		SELECT  2000,
			20104,
			arin.customer_code,
			arin.doc_ctrl_num,
			0,
			0.0,
			1,
			gltc.trx_ctrl_num,
			0,
			ISNULL(arin.source_trx_ctrl_num, ""),
			0
		FROM	#gltcpost_work gltc, #arinpchg_work arin
		WHERE	gltc.trx_ctrl_num = arin.trx_ctrl_num
		AND	arin.batch_code = @batch_ctrl_num

       END


	UPDATE	#gltcpost_work 
		SET	posted_flag = 0
		FROM	#gltcpost_work gltc, #ewerror b
		WHERE	gltc.trx_ctrl_num = b.trx_ctrl_num

	IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcposterr.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
			RETURN 34563
		END
       IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcposterr.sp" +  " -- EXIT: " 
       IF ( @debug_level > 1 )
       	BEGIN
       	    SELECT	"Records in #gltcpost_work before save to #ewerror"
       	    SELECT	"trx_ctrl_num:posted_flag:remote_state:remote_error:batch_code:remote_doc_id"
       	    SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
       			STR(posted_flag, 4) + ":" +
       			STR(remote_state,4) + ":" +
       			STR(remote_error,4) + ":" +
       			ISNULL(batch_code, " ")+":" +
       			STR(remote_doc_id,20)
       	    FROM	#gltcpost_work
	END


END
GO
GRANT EXECUTE ON  [dbo].[gltcpost_error_sp] TO [public]
GO
