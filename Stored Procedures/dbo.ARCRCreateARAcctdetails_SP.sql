SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 











































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRCreateARAcctdetails_SP]	@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									








IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcara.cpp", 63, "Entering ARCRCreateARAcctdetails_SP", @PERF_time_last OUTPUT








BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcara.cpp" + ", line " + STR( 73, 5 ) + " -- ENTRY: "

	IF (@debug_level > 0 )
	BEGIN
		select "dumping #artrxpdt_work....."
		select "trx_ctrl_num = "+trx_ctrl_num +
			"trx_type = "+STR(trx_type, 6) +
			"customer_code = "+customer_code +
			"sub_apply_num = "+sub_apply_num +
			"sub_apply_type = "+STR(sub_apply_type, 6) +
			"amt_applied = "+STR(amt_applied, 10, 2 ) +
			"amt_disc_taken = "+STR(amt_disc_taken, 10, 2 )+
			"amt_wr_off = "+STR(amt_wr_off, 10, 2 )
		from 	#artrxpdt_work
	END
	
	


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
		pyt.date_applied,			dbo.IBAcctMask_fn(acct.ar_acct_code,artrx.org_id), 
		trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			(pdt.inv_amt_applied + pdt.inv_amt_disc_taken + pdt.inv_amt_wr_off) * (-1),
		artrx.nat_cur_code,	  		artrx.rate_type_home,
		artrx.rate_type_oper,		artrx.rate_home,
		artrx.rate_oper,			pyt.trx_type,
		0,					pyt.trx_ctrl_num,
                artrx.org_id        
	FROM	#artrxpdt_work pdt, #arinppyt_work pyt, #artrx_work artrx, araccts acct
	WHERE	pdt.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pdt.trx_type = pyt.trx_type
	AND	pdt.sub_apply_num = artrx.doc_ctrl_num
	AND	pdt.sub_apply_type = artrx.trx_type
	AND	artrx.posting_code = acct.posting_code
	AND	pyt.batch_code = @batch_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcara.cpp" + ", line " + STR( 122, 5 ) + " -- EXIT: "
		RETURN 34563
	END


	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN
		/* Begin mod: CB0001 - Add debit entry to the AR account for chargebacks */	
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
			pyt.date_applied,			dbo.IBAcctMask_fn(acct.ar_acct_code, pyt.org_id),
			trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			cbt.total_chargebacks,
			pyt.nat_cur_code,	 		pyt.rate_type_home,
			pyt.rate_type_oper,			pyt.rate_home,
			pyt.rate_oper,				pyt.trx_type,
			0,					pyt.trx_ctrl_num,
                pyt.org_id        	
		FROM	#arinppyt_work pyt,araccts acct, arcbtot cbt, armaster cust
		WHERE	pyt.customer_code = cust.customer_code
		AND	cust.address_type = 0
		AND 	cust.posting_code = acct.posting_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	cbt.trx_ctrl_num = pyt.trx_ctrl_num
		AND 	pyt.payment_type = 1
	
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrcara.sp" + ", line " + STR( 115, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		/* End mod: CB00001 */
	END
	
	IF (@debug_level > 0)
		BEGIN
			SELECT "dumping argldist after AR account details are added"
			SELECT	"date_applied journal_type rec_company_code account code description document_1 document_2"
			SELECT	STR(date_applied, 7) + ":" +
					account_code + ":" +
					description + ":" +
					document_1 + ":" +
					document_2
			FROM	#argldist
					
			SELECT	"document_2 reference_code home_balance home_cur_code nat_balance nat_cur_code rate trx_type seq_ref_id"
			SELECT	document_2 + ":" +
					STR(nat_balance, 10, 4) + ":" +
					nat_cur_code + ":" +
					STR(trx_type, 5 ) + ":" +
					STR(seq_ref_id, 6)
			FROM	#argldist
	END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcara.cpp" + ", line " + STR( 147, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcara.cpp", 148, "Leaving ARCRCreateARAcctdetails_SP", @PERF_time_last OUTPUT
RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARCRCreateARAcctdetails_SP] TO [public]
GO
