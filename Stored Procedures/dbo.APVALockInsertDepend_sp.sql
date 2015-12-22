SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APVALockInsertDepend_sp]
				 @process_group_num 	varchar(16),
				 @debug_level			smallint = 0
AS

DECLARE
	@result					int


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvalid.cpp' + ', line ' + STR( 73, 5 ) + ' -- ENTRY: '

		BEGIN TRAN LOCKDEPS

		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvalid.cpp' + ', line ' + STR( 77, 5 ) + ' -- MSG: ' + 'mark vouchers in aptrx'
		UPDATE apvohdr
		SET state_flag = -1,
		    process_ctrl_num = @process_group_num
		FROM apvohdr a, #apvachg_work b
		WHERE a.trx_ctrl_num = b.apply_to_num
		AND a.state_flag = 1



		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvalid.cpp' + ', line ' + STR( 87, 5 ) + ' -- MSG: ' + 'insert vouchers that could not be marked in #ewerror'
		INSERT #ewerror(    module_id,
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
		SELECT				4000,
							31220,
							b.apply_to_num,
							'',
							0,
							0.0,
							1,
							b.trx_ctrl_num,
							0,
							'',
							0
		FROM apvohdr a, #apvachg_work b
		WHERE a.trx_ctrl_num = b.apply_to_num
		AND a.process_ctrl_num != @process_group_num


		COMMIT TRAN LOCKDEPS


	INSERT	#apvaxv_work(	
				trx_ctrl_num,
				user_trx_type_code,
				po_ctrl_num,
				vend_order_num,
				ticket_num,
				date_aging,
				date_due,
				date_doc,
				date_received,
				date_required,
				date_discount,
				fob_code,
				terms_code,
				org_id,
				db_action)
	SELECT	
				a.trx_ctrl_num,
				a.user_trx_type_code,
				a.po_ctrl_num,
				a.vend_order_num,
				a.ticket_num,
				a.date_aging,
				a.date_due,
				a.date_doc,
				a.date_received,
				a.date_required,
				a.date_discount,
				a.fob_code,
				a.terms_code,
				b.org_id,
				0
	FROM	apvohdr a, #apvachg_work b
	WHERE	a.process_ctrl_num = @process_group_num
	AND		a.state_flag = -1
	AND 	a.trx_ctrl_num = b.apply_to_num

	IF( @@error != 0)
		RETURN -1

	



	INSERT	#apvaxcdv_work
	(	
	   trx_ctrl_num		   ,
	   sequence_id		   ,
	   gl_exp_acct		   ,
	   rec_company_code	   ,
	   reference_code	   ,	
	   db_action 		   	
	)					   
	SELECT
		a0.trx_ctrl_num		   ,
		a0.sequence_id		   ,
		a0.gl_exp_acct		   ,
		a0.rec_company_code	   ,
		a0.reference_code	   ,
		0
	FROM	apvodet a0, #apvaxv_work a1
	WHERE	a0.trx_ctrl_num = a1.trx_ctrl_num

	IF( @@error != 0 )
		RETURN -1


	INSERT	#apvaxage_work(
				trx_ctrl_num,		
				trx_type,	
				ref_id,			
				date_doc,		
				date_due,	
				date_aging,	
				org_id,	
				db_action)
	SELECT
				a.trx_ctrl_num,		
				a.trx_type,		
				a.ref_id,	   	
				a.date_doc,		
				a.date_due,	
				a.date_aging,	
				h.org_id,	
				0
	FROM	aptrxage a, #apvaxv_work h
	WHERE	a.trx_ctrl_num = h.trx_ctrl_num
	AND	a.trx_type = 4091

	IF( @@error != 0)
		RETURN -1




	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvalid.cpp' + ', line ' + STR( 214, 5 ) + ' -- EXIT: '
	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVALockInsertDepend_sp] TO [public]
GO
