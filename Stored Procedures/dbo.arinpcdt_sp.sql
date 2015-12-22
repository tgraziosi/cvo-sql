SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[arinpcdt_sp]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0
WITH RECOMPILE
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@status 	int

SELECT 	@status = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinpcdt.cpp' + ', line ' + STR( 42, 5 ) + ' -- ENTRY: '

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arinpcdt.cpp', 44, 'entry arinpcdt_sp', @PERF_time_last OUTPUT











DELETE	arinpcdt
FROM	#arinpcdt_work a, arinpcdt b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num 
AND	a.trx_type = b.trx_type 
AND	a.sequence_id = b.sequence_id 
AND	db_action > 0

SELECT	@status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arinpcdt.cpp', 65, 'delete arinpdct: delete action', @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
	INSERT	arinpcdt	( 
				trx_ctrl_num,
				doc_ctrl_num,
				sequence_id,
				trx_type,
				location_code,	 
				item_code,
				bulk_flag,
				date_entered,
				line_desc,
				qty_ordered,
				qty_shipped,
				unit_code,
				unit_price,
				unit_cost,
				extended_price,
				weight,	 
				serial_id,
				tax_code,
				gl_rev_acct,
				disc_prc_flag,	 
				discount_amt,
				discount_prc,
				commission_flag,	 
				rma_num,	 
				return_code,
				qty_returned,
				qty_prev_returned,
				new_gl_rev_acct,	 
				iv_post_flag,
				oe_orig_flag,
				calc_tax,
				reference_code,
				new_reference_code,
				cust_po,
				org_id
				)
	
	SELECT			trx_ctrl_num,  
				doc_ctrl_num,
				sequence_id,
				trx_type,
				location_code,	
				item_code,
				bulk_flag,
				date_entered,
				line_desc,
				qty_ordered,
				qty_shipped,
				unit_code,
				unit_price,
				unit_cost,
				extended_price,
				weight,	
				serial_id,
				tax_code,
				gl_rev_acct,
				disc_prc_flag,	
				discount_amt,
				discount_prc,
				commission_flag,	
				rma_num,	
				return_code,
				qty_returned,
				qty_prev_returned,
				new_gl_rev_acct,	
				iv_post_flag,
				oe_orig_flag,
				calc_tax,
				reference_code,
				new_reference_code,
				cust_po,
				org_id
	FROM	#arinpcdt_work
	WHERE	db_action > 0
	AND 	db_action < 4

	SELECT @status = @@error

	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arinpcdt.cpp', 148, 'insert arinpcdt: insert action', @PERF_time_last OUTPUT
END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arinpcdt.cpp', 152, 'exit arinpcdt_sp', @PERF_time_last OUTPUT

RETURN @status
GO
GRANT EXECUTE ON  [dbo].[arinpcdt_sp] TO [public]
GO
