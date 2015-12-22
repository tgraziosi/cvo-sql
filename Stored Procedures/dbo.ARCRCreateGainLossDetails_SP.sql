SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 





































































































































































































































































































































































































































































































































































































                       


































































































CREATE PROC [dbo].[ARCRCreateGainLossDetails_SP]		@batch_ctrl_num     varchar( 16 ),
                                			@debug_level        smallint = 0,
                                			@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
    	@result             	int,
	@company_code		varchar(8)

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcgld.cpp", 62, "Entering ARCRCreateGainLossDetails_SP", @PERF_time_last OUTPUT






BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "

	SELECT	@company_code = company_code
	FROM	glco
	IF ( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 76, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @debug_level > 0 )
	BEGIN
		SELECT "arinppyt_work before insert into argldist"
		SELECT doc_ctrl_num + "trx_type" + STR(trx_type) + customer_code
		FROM #arinppyt_work
		WHERE	batch_code = @batch_ctrl_num
	END
	
	CREATE TABLE #g_l_accts
	(
		nat_cur_code	varchar( 8 ),
		posting_code	varchar( 8 ),
		ar_acct_code	varchar( 32 ),
		gain_acct	varchar( 32 ),
		loss_acct	varchar( 32 )
	)
	
	INSERT #g_l_accts
	SELECT DISTINCT pdt.inv_cur_code, inv.posting_code, dbo.IBAcctMask_fn(acct.ar_acct_code,pyt.org_id), "", ""
	FROM	#artrx_work inv, #arinppyt_work pyt, #artrxpdt_work pdt, araccts acct
	WHERE	pdt.apply_to_num = inv.doc_ctrl_num
	AND	pdt.apply_trx_type = inv.trx_type
	AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	inv.posting_code = acct.posting_code
	AND	(pdt.inv_cur_code != pyt.nat_cur_code
	    OR  pdt.gain_home != 0.0 
	    OR  pdt.gain_oper != 0.0)
	    
	IF ( @@rowcount != 0 )
	BEGIN
		SELECT mc.currency_code, gl.ar_acct_code, sequence_id = MIN(mc.sequence_id)
		INTO	#temp
		FROM	CVO_Control..mccocdt mc, #g_l_accts gl
		WHERE	mc.company_code = @company_code
		AND	gl.ar_acct_code like mc.acct_mask
		AND	gl.nat_cur_code = mc.currency_code
		GROUP BY mc.currency_code, gl.ar_acct_code
		
		UPDATE	#g_l_accts
		SET	gain_acct = mc.rea_gain_acct,
			loss_acct = mc.rea_loss_acct
		FROM	#g_l_accts gl, #temp t, CVO_Control..mccocdt mc
		WHERE	gl.nat_cur_code = t.currency_code
		AND	gl.ar_acct_code = t.ar_acct_code
		AND	t.currency_code = mc.currency_code
		AND	t.sequence_id = mc.sequence_id
		AND	mc.company_code = @company_code
		
		DROP TABLE #temp

		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 134, 5 ) + " -- MSG: " + "debit invoice amounts to gain accounts for 2nd currency"
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
                        org_id        
		)
		SELECT
			pyt.date_applied,			dbo.IBAcctMask_fn(gl.gain_acct, pdt.org_id) ,
			trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			pdt.inv_amt_applied,
			artrx.nat_cur_code,	  		artrx.rate_type_home,
			artrx.rate_type_oper,		artrx.rate_home,
			artrx.rate_oper,			pyt.trx_type,
			pdt.sequence_id,			pyt.trx_ctrl_num,
                        pdt.org_id	
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work artrx, #g_l_accts gl
		WHERE	pdt.sub_apply_num = artrx.doc_ctrl_num
		AND	pdt.sub_apply_type = artrx.trx_type
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.gain_home >= 0.0
		AND	pyt.nat_cur_code != pdt.inv_cur_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	artrx.nat_cur_code = gl.nat_cur_code
		AND	artrx.posting_code = gl.posting_code

		IF ( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 168, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 172, 5 ) + " -- MSG: " + "debit invoice amounts to loss accounts for 2nd currency"
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
                        org_id	                                                
		)
		SELECT
			pyt.date_applied,			dbo.IBAcctMask_fn(gl.loss_acct,   pdt.org_id  ) ,
			trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			pdt.inv_amt_applied,
			artrx.nat_cur_code,	  		artrx.rate_type_home,
			artrx.rate_type_oper,		artrx.rate_home,
			artrx.rate_oper,			pyt.trx_type,
			pdt.sequence_id,			pyt.trx_ctrl_num,
                        pdt.org_id                                        	
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work artrx, #g_l_accts gl
		WHERE	pdt.sub_apply_num = artrx.doc_ctrl_num
		AND	pdt.sub_apply_type = artrx.trx_type
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.gain_home < 0.0
		AND	pyt.nat_cur_code != pdt.inv_cur_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	artrx.nat_cur_code = gl.nat_cur_code
		AND	artrx.posting_code = gl.posting_code

		IF ( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 206, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 210, 5 ) + " -- MSG: " + "credit payment amounts to gain accounts for 2nd currency"
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
                        org_id        	
		)
		SELECT
			pyt.date_applied,			dbo.IBAcctMask_fn(gl.gain_acct, pdt.org_id) ,
			trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			-pdt.amt_applied,
			pyt.nat_cur_code,	  		pyt.rate_type_home,
			pyt.rate_type_oper,			pyt.rate_home,
			pyt.rate_oper,			pyt.trx_type,
			pdt.sequence_id,			pyt.trx_ctrl_num,
                        pdt.org_id      
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work artrx, #g_l_accts gl
		WHERE	pdt.sub_apply_num = artrx.doc_ctrl_num
		AND	pdt.sub_apply_type = artrx.trx_type
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.gain_home >= 0.0
		AND	pyt.nat_cur_code != pdt.inv_cur_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	artrx.nat_cur_code = gl.nat_cur_code
		AND	artrx.posting_code = gl.posting_code

		IF ( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 244, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 248, 5 ) + " -- MSG: " + "credit payment amounts to loss accounts for 2nd currency"
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
                        org_id        	
		)
		SELECT
			pyt.date_applied,			dbo.IBAcctMask_fn(gl.loss_acct,pdt.org_id ) ,
			trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			-pdt.amt_applied,
			pyt.nat_cur_code,	  		pyt.rate_type_home,
			pyt.rate_type_oper,			pyt.rate_home,
			pyt.rate_oper,			pyt.trx_type,
			pdt.sequence_id,			pyt.trx_ctrl_num,
                        pdt.org_id      	
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work artrx, #g_l_accts gl
		WHERE	pdt.sub_apply_num = artrx.doc_ctrl_num
		AND	pdt.sub_apply_type = artrx.trx_type
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.gain_home < 0.0
		AND	pyt.nat_cur_code != pdt.inv_cur_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	artrx.nat_cur_code = gl.nat_cur_code
		AND	artrx.posting_code = gl.posting_code

		IF ( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 282, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 286, 5 ) + " -- MSG: " + "adjust amounts to gain accounts for 1st currency"
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
			home_balance,				oper_balance,
                        org_id        	
		)
		SELECT
			pyt.date_applied,			dbo.IBAcctMask_fn( gl.gain_acct, pdt.org_id),
			trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			0.0,
			pyt.nat_cur_code,	  		artrx.rate_type_home,
			artrx.rate_type_oper,	      	0.0,
			0.0,					pyt.trx_type,
			pdt.sequence_id,			pyt.trx_ctrl_num,
			-pdt.gain_home,			-pdt.gain_oper,
                        pdt.org_id        
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work artrx, #g_l_accts gl
		WHERE	pdt.sub_apply_num = artrx.doc_ctrl_num
		AND	pdt.sub_apply_type = artrx.trx_type
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.gain_home >= 0.0
		AND	pyt.nat_cur_code = pdt.inv_cur_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	( pdt.gain_home != 0.0 OR pdt.gain_oper != 0.0 )
		AND	artrx.nat_cur_code = gl.nat_cur_code
		AND	artrx.posting_code = gl.posting_code

		IF ( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 323, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 327, 5 ) + " -- MSG: " + "adjust amounts to loss accounts for 1st currency"
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
			home_balance,				oper_balance,
                        org_id        	
		)
		SELECT
			pyt.date_applied,			dbo.IBAcctMask_fn(gl.loss_acct,pdt.org_id) ,
			trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			0.0,
			pyt.nat_cur_code,	  		artrx.rate_type_home,
			artrx.rate_type_oper,	      	0.0,
			0.0,					pyt.trx_type,
			pdt.sequence_id,			pyt.trx_ctrl_num,
			-pdt.gain_home,			-pdt.gain_oper,
                        pdt.org_id     
		FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work artrx, #g_l_accts gl
		WHERE	pdt.sub_apply_num = artrx.doc_ctrl_num
		AND	pdt.sub_apply_type = artrx.trx_type
		AND	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pyt.trx_type = pdt.trx_type
		AND	pdt.gain_home < 0.0
		AND	pyt.nat_cur_code = pdt.inv_cur_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	artrx.nat_cur_code = gl.nat_cur_code
		AND	artrx.posting_code = gl.posting_code

		IF ( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 363, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	END

	IF (@debug_level > 0)
		BEGIN
			SELECT "dumping argldist after Gain Loss details are added"
			SELECT	"account code description document_1 document_2 home_balance oper_balance"
			SELECT	STR(date_applied, 7) + ":" +
				account_code + ":" +
				description + ":" +
				document_1 + ":" +
				document_2 + ":" +
				STR(home_balance, 10, 4) + ":" +
				STR(oper_balance, 10, 4) 
			FROM	#argldist
					
			SELECT	"document_2 home_balance oper_balance nat_balance nat_cur_code rate_home rate_oper trx_type seq_ref_id org_id"
			SELECT	document_2 + ":" +
				STR(home_balance, 10, 4) + ":" +
				STR(oper_balance, 10, 4) + ":" +
				STR(nat_balance, 10, 4) + ":" +
				nat_cur_code + ":" +
				STR(rate_home, 10, 6) + ":" +
				STR(rate_oper, 10, 6) + ":" +
				STR(trx_type, 5 ) + ":" +
				STR(seq_ref_id, 6) +
                                org_id 
			FROM	#argldist
		END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcgld.cpp" + ", line " + STR( 395, 5 ) + " -- EXIT: "
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcgld.cpp", 396, "Leaving ARCRCreateGainLossDetails_SP", @PERF_time_last OUTPUT
    RETURN 0 

END
GO
GRANT EXECUTE ON  [dbo].[ARCRCreateGainLossDetails_SP] TO [public]
GO
