SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[gltcapcommit_error_sp]		@batch_ctrl_num	varchar(16),
 					@debug_level 	smallint = 0,
 					@trx_type    smallint = 0
AS

DECLARE
 	@result 		int

BEGIN

     IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcposterr.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

     IF( @trx_type = 4091)      /* 4091 =  Vouchers, 4092= DebitMemo */
     BEGIN 	
	
	
	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Records in #gltcpost_work"
		SELECT	"trx_ctrl_num:posted_flag:remote_state:batch_code:"
		SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
			STR(posted_flag, 4) + ":" +
			STR(remote_state,4) + ":" +
			ISNULL(batch_code, " ")
			FROM	#gltcpost_work
		
		SELECT 'dumping #apvochg_work'
		SELECT 'trx_ctrl_num:trx_type:doc_ctrl_num:batch_code:posted_flag'
		SELECT ISNULL( trx_ctrl_num , ' ' ) + ":" +
		        STR(trx_type,7) + ":" +
			ISNULL( doc_ctrl_num,  ' ' ) + ":" +
			ISNULL(batch_code, ' ') + ":" +
			STR(posted_flag,4)
		   	FROM #apvochg_work  WHERE batch_code = @batch_ctrl_num

		SELECT	"Records in #gltrx"
		SELECT	"journal_ctrl_num:source_batch_code:batch_code:process_group_num"
		SELECT	ISNULL(journal_ctrl_num, " ") + ":" +
			ISNULL(source_batch_code, " ") + ":" +
			ISNULL(batch_code, " ") + ":" +
			ISNULL(process_group_num, " ")
			FROM	#gltrx

		SELECT	"Records in #gltrxdet"
		SELECT	"journal_ctrl_num:trx_type:batch_code:process_group_num"
		SELECT	ISNULL(journal_ctrl_num, " ") + ":" +
			STR(trx_type,7 )+ ":" +
			ISNULL(document_2, ' ') 
			FROM	#gltrxdet
		
		
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
	 	-20104,
		'',
		'',
		0,
		0.0,
		0,
		gltc.trx_ctrl_num,
		0,
		ISNULL(gltc.trx_ctrl_num, ''),
		0
	FROM	#gltcpost_work gltc
	WHERE	gltc.remote_state <> 3
	AND	gltc.batch_code = @batch_ctrl_num

	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Records in #ewerror"
		SELECT	"err_code:flag1:trx_ctrl_num:source_ctrl_num"
		SELECT	STR(err_code, 7) + ":" +
			STR(flag1, 4) + ":" +
			ISNULL(trx_ctrl_num ,' ')+ ":" +
			ISNULL(source_ctrl_num, ' ')
		FROM	#ewerror
	END

       INSERT  perror (
	 	process_ctrl_num,
		batch_code,
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
	SELECT  h.process_group_num,
		gltc.batch_code,
		4000,
	 	-20105,
		'',
		'',
		0,
		0.0,
		0,
		gltc.trx_ctrl_num,
		0,
		'',
		0
	FROM	#gltcpost_work gltc, #gltrx h
	WHERE	gltc.remote_state <> 3 AND gltc.batch_code = @batch_ctrl_num
	AND	h.source_batch_code = gltc.batch_code	
	AND	gltc.trx_ctrl_num 
	        NOT IN (SELECT trx_ctrl_num FROM perror WHERE batch_code = @batch_ctrl_num)


	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Records in perror"
	        SELECT	"process_ctrl_num:batch_code:err_code:trx_ctrl_num:source_ctrl_num"
		SELECT	ISNULL(process_ctrl_num,' ') + ":" +
			ISNULL(batch_code,' ') + ":" +
			STR(err_code, 7) + ":" +
			ISNULL(trx_ctrl_num,' ') + ":" +
			ISNULL(source_ctrl_num, ' ')
		FROM	perror WHERE batch_code = @batch_ctrl_num
        END
/*
	DELETE	#gltrxdet 
	FROM 	#gltrxdet d, #gltrx h, #gltcpost_work gltc
	WHERE  	h.journal_ctrl_num = d.journal_ctrl_num
	AND	h.source_batch_code = gltc.batch_code 
	AND     gltc.batch_code = @batch_ctrl_num
        AND     gltc.remote_state <> 3

	DELETE	#gltrx 
	FROM 	#gltrx gltrx, #gltcpost_work gltc
	WHERE  	gltrx.source_batch_code = gltc.batch_code
	AND 	gltc.batch_code = @batch_ctrl_num
	AND     gltc.remote_state <> 3
*/
	DELETE	#apvochg_work
	FROM 	#apvochg_work apvo, #gltcpost_work gltc
	WHERE 	gltc.remote_state <> 3
	AND 	gltc.trx_ctrl_num = apvo.trx_ctrl_num
	AND 	gltc.batch_code = @batch_ctrl_num

    END

    IF( @trx_type = 4092)      /* 4091 =  Vouchers, 4092= DebitMemo */
    BEGIN

	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Records in #gltcpost_work"
		SELECT	"trx_ctrl_num:posted_flag:remote_state:batch_code:"
		SELECT	ISNULL(trx_ctrl_num, " ") + ":" +
			STR(posted_flag, 4) + ":" +
			STR(remote_state,4) + ":" +
			ISNULL(batch_code, " ")
			FROM	#gltcpost_work
		
		SELECT 'dumping #apvochg_work'
		SELECT 'trx_ctrl_num:trx_type:doc_ctrl_num:batch_code:posted_flag'
		SELECT ISNULL( trx_ctrl_num , ' ' ) + ":" +
		        STR(trx_type,7) + ":" +
			ISNULL( doc_ctrl_num,  ' ' ) + ":" +
			ISNULL(batch_code, ' ') + ":" +
			STR(posted_flag,4)
		   	FROM #apdmchg_work  WHERE batch_code = @batch_ctrl_num

		SELECT	"Records in #gltrx"
		SELECT	"journal_ctrl_num:source_batch_code:batch_code:process_group_num"
		SELECT	ISNULL(journal_ctrl_num, " ") + ":" +
			ISNULL(source_batch_code, " ") + ":" +
			ISNULL(batch_code, " ") + ":" +
			ISNULL(process_group_num, " ")
			FROM	#gltrx

		SELECT	"Records in #gltrxdet"
		SELECT	"journal_ctrl_num:trx_type:batch_code:process_group_num"
		SELECT	ISNULL(journal_ctrl_num, " ") + ":" +
			STR(trx_type,7 )+ ":" +
			ISNULL(document_2, ' ') 
			FROM	#gltrxdet
		
		
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
	 	-20104,
		'',
		'',
		0,
		0.0,
		0,
		gltc.trx_ctrl_num,
		0,
		ISNULL(gltc.trx_ctrl_num, ''),
		0
	FROM	#gltcpost_work gltc
	WHERE	gltc.remote_state <> 3
	AND	gltc.batch_code = @batch_ctrl_num

	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Records in #ewerror"
		SELECT	"err_code:flag1:trx_ctrl_num:source_ctrl_num"
		SELECT	STR(err_code, 7) + ":" +
			STR(flag1, 4) + ":" +
			ISNULL(trx_ctrl_num ,' ')+ ":" +
			ISNULL(source_ctrl_num, ' ')
		FROM	#ewerror
	END

       INSERT  perror (
	 	process_ctrl_num,
		batch_code,
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
	SELECT  h.process_group_num,
		gltc.batch_code,
		4000,
	 	-20105,
		'',
		'',
		0,
		0.0,
		0,
		gltc.trx_ctrl_num,
		0,
		'',
		0
	FROM	#gltcpost_work gltc, #gltrx h
	WHERE	gltc.remote_state <> 3 AND gltc.batch_code = @batch_ctrl_num
	AND	h.source_batch_code = gltc.batch_code	
	AND	gltc.trx_ctrl_num 
	        NOT IN (SELECT trx_ctrl_num FROM perror WHERE batch_code = @batch_ctrl_num)


	IF( @debug_level >= 2 )
	BEGIN
		SELECT	"Records in perror"
	        SELECT	"process_ctrl_num:batch_code:err_code:trx_ctrl_num:source_ctrl_num"
		SELECT	ISNULL(process_ctrl_num,' ') + ":" +
			ISNULL(batch_code,' ') + ":" +
			STR(err_code, 7) + ":" +
			ISNULL(trx_ctrl_num,' ') + ":" +
			ISNULL(source_ctrl_num, ' ')
		FROM	perror WHERE batch_code = @batch_ctrl_num
        END
/*
	DELETE	#gltrxdet 
	FROM 	#gltrxdet d, #gltrx h, #gltcpost_work gltc
	WHERE  	h.journal_ctrl_num = d.journal_ctrl_num
	AND	h.source_batch_code = gltc.batch_code 
	AND     gltc.batch_code = @batch_ctrl_num
        AND     gltc.remote_state <> 3

	DELETE	#gltrx 
	FROM 	#gltrx gltrx, #gltcpost_work gltc
	WHERE  	gltrx.source_batch_code = gltc.batch_code
	AND 	gltc.batch_code = @batch_ctrl_num
	AND     gltc.remote_state <> 3
*/
	DELETE	#apdmchg_work
	FROM 	#apdmchg_work apdm, #gltcpost_work gltc
	WHERE 	gltc.remote_state <> 3
	AND 	gltc.trx_ctrl_num = apdm.trx_ctrl_num
	AND 	gltc.batch_code = @batch_ctrl_num




    END


        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcapcommerr.sp" + " -- EXIT: "

END
GO
GRANT EXECUTE ON  [dbo].[gltcapcommit_error_sp] TO [public]
GO
