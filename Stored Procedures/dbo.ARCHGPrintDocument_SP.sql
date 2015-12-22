SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCHGPrintDocument_SP]	@process_group_num	varchar( 16 ),
					@relation_code	varchar( 8 ),
					@nat_acct_rng		smallint,
					@debug_level		smallint = 0,
					@perf_level		smallint = 0    
AS

DECLARE
	@result        	int,
	@tran_started		smallint,
	@num			int

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'archgpd.cpp' + ', line ' + STR( 53, 5 ) + ' -- ENTRY: '


	



		INSERT	#archarge_work
		(
			trx_ctrl_num,			trx_type,			batch_code,		
			date_doc,			date_due,			amt_net,
			amt_discount,			amt_freight,			amt_tax,
			amt_gross,			amt_paid,			amt_due,
			customer_addr1,		customer_addr2,		customer_addr3,
			customer_addr4,		customer_addr5,		customer_addr6,
			ship_to_addr1,		ship_to_addr2,		ship_to_addr3,
			ship_to_addr4,		ship_to_addr5,		ship_to_addr6,
			apply_to_num,			customer_code,		cust_po_num,
			date_shipped,			fob_code,			order_ctrl_num,
			terms_desc,			salesperson_name,		ship_via_code,
			comment_line,			parent,			addr_sort1,			
			addr_sort2,			addr_sort3,			copies,			
			rel_cust,			nat_currency_mask,		recurring_flag
		)
		SELECT	arinpchg.trx_ctrl_num,	arinpchg.trx_type,		arinpchg.batch_code,
			arinpchg.date_doc,		arinpchg.date_due,		arinpchg.amt_net,
			arinpchg.amt_discount,	arinpchg.amt_freight,	arinpchg.amt_tax,
			arinpchg.amt_gross,		arinpchg.amt_paid,		arinpchg.amt_due,
			arinpchg.customer_addr1,	arinpchg.customer_addr2,	arinpchg.customer_addr3,
			arinpchg.customer_addr4,	arinpchg.customer_addr5,	arinpchg.customer_addr6,
			arinpchg.ship_to_addr1,	arinpchg.ship_to_addr2,	arinpchg.ship_to_addr3,
			arinpchg.ship_to_addr4,	arinpchg.ship_to_addr5,	arinpchg.ship_to_addr6,
			arinpchg.apply_to_num,	arinpchg.customer_code,	arinpchg.cust_po_num,
			arinpchg.date_shipped,	arinpchg.fob_code,		arinpchg.order_ctrl_num,
			terms_code,			salesperson_code,		freight_code,
			comment_code,			'',				'',				
			'',				'',				0,
			'',				nat_cur_code,			arinpchg.recurring_flag
		FROM	arinpchg
		WHERE	arinpchg.process_group_num = @process_group_num


	IF( @nat_acct_rng != 0 )
	BEGIN
		



		UPDATE	#archarge_work
		SET
			terms_desc = ISNULL(SUBSTRING(arterms.terms_desc,1,20),''),			
			salesperson_name = ISNULL(arsalesp.salesperson_name, ''),						
			ship_via_code = ISNULL(arfrcode.ship_via_code, ''),
			comment_line = ISNULL(arcommnt.comment_line, ''),							
			parent = artierrl.parent,			
			addr_sort1 = armaster.addr_sort1,			
			addr_sort2 = armaster.addr_sort2,			
			addr_sort3 = armaster.addr_sort3,
			copies = armaster.invoice_copies,			
			rel_cust = artierrl.rel_cust,			
			nat_currency_mask = glcurr_vw.currency_mask
		FROM	#archarge_work archarge
				LEFT OUTER JOIN arcommnt ON (archarge.comment_line = arcommnt.comment_code)
				LEFT OUTER JOIN arterms  ON (archarge.terms_desc = arterms.terms_code)
				LEFT OUTER JOIN arfrcode ON (archarge.ship_via_code = arfrcode.freight_code)
				LEFT OUTER JOIN arsalesp ON (archarge.salesperson_name = arsalesp.salesperson_code), 
			artierrl, armaster, arco, glcurr_vw
		WHERE	artierrl.relation_code = @relation_code
		AND	artierrl.rel_cust = archarge.customer_code
		AND	archarge.customer_code = armaster.customer_code
		AND	armaster.address_type = 0
		AND	archarge.nat_currency_mask = glcurr_vw.currency_code
	END
	ELSE
	BEGIN
		UPDATE	#archarge_work
		SET
			terms_desc = ISNULL(SUBSTRING(arterms.terms_desc,1,20),''),			
			salesperson_name = ISNULL(arsalesp.salesperson_name, ''),						
			ship_via_code = ISNULL(arfrcode.ship_via_code, ''),
			comment_line = ISNULL(arcommnt.comment_line, ''),							
			addr_sort1 = armaster.addr_sort1,			
			addr_sort2 = armaster.addr_sort2,			
			addr_sort3 = armaster.addr_sort3,
			copies = armaster.invoice_copies,			
			nat_currency_mask = glcurr_vw.currency_mask
		FROM	#archarge_work archarge
				LEFT OUTER JOIN arcommnt ON (archarge.comment_line = arcommnt.comment_code)
				LEFT OUTER JOIN arterms ON  (archarge.terms_desc = arterms.terms_code)
				LEFT OUTER JOIN arfrcode ON (archarge.ship_via_code = arfrcode.freight_code)
				LEFT OUTER JOIN arsalesp ON (archarge.salesperson_name = arsalesp.salesperson_code),
			armaster, arco, glcurr_vw
		WHERE archarge.customer_code = armaster.customer_code
		AND	armaster.address_type = 0
		AND	archarge.nat_currency_mask = glcurr_vw.currency_code
	END	


	


	INSERT	#arnumblk
	(
		num_type,				get_num,				masked,
		char16_ref1,				char8_ref1,				smallint_ref1
	)
	SELECT	2001,					0,					arinpchg.doc_ctrl_num,
		#archarge_work.trx_ctrl_num,	#archarge_work.customer_code,	#archarge_work.trx_type	
	FROM	#archarge_work, arinpchg
	WHERE	#archarge_work.trx_type = 2031
	AND	#archarge_work.customer_code = arinpchg.customer_code
	AND	#archarge_work.trx_ctrl_num = arinpchg.trx_ctrl_num
	AND	#archarge_work.trx_type = arinpchg.trx_type


	


	INSERT	#arnumblk
	(
		num_type,				get_num,				masked,
		char16_ref1,				char8_ref1,				smallint_ref1
	)
	SELECT	2021,					0,					arinpchg.doc_ctrl_num,
		#archarge_work.trx_ctrl_num,	#archarge_work.customer_code,	#archarge_work.trx_type
	FROM	#archarge_work, arinpchg
	WHERE	#archarge_work.trx_type = 2032
	AND	#archarge_work.customer_code = arinpchg.customer_code
	AND	#archarge_work.trx_ctrl_num = arinpchg.trx_ctrl_num
	AND	#archarge_work.trx_type = arinpchg.trx_type


	





	SET ROWCOUNT 1000

	UPDATE	#arnumblk
	SET	get_num = 1
	WHERE	masked = ''

	SET ROWCOUNT 0

	SELECT @num = count(get_num)
	FROM	#arnumblk
	WHERE	get_num = 1

	WHILE ( @num > 0 )
	BEGIN

	




	EXEC @result = ARGetNumberBlock_SP	@process_group_num,
						@debug_level


		UPDATE	#arnumblk
		SET	get_num = 1
		FROM	arinpchg
		WHERE	doc_ctrl_num = masked
		AND	get_num = 2
		

		UPDATE #arnumblk
		SET	get_num = 1
		FROM	artrx
		WHERE	doc_ctrl_num = masked
		AND	get_num = 2

		


		UPDATE	arinpchg
		SET	doc_ctrl_num = #arnumblk.masked,
			printed_flag = 1
		FROM	#arnumblk
		WHERE	process_group_num = @process_group_num
		AND	arinpchg.customer_code = #arnumblk.char8_ref1
		AND	arinpchg.trx_ctrl_num = #arnumblk.char16_ref1
		AND	arinpchg.trx_type = #arnumblk.smallint_ref1
		AND	#arnumblk.get_num = 2

		UPDATE	#arnumblk
		SET	get_num = 3
		WHERE	get_num = 2


		SET ROWCOUNT 1000

		UPDATE	#arnumblk
		SET	get_num = 1
		WHERE	masked = ''

		SET ROWCOUNT 0

		SELECT @num = count(get_num)
		FROM	#arnumblk
		WHERE	get_num = 1

	END

	UPDATE	arinpchg
	SET	printed_flag = 1
	FROM	#arnumblk
	WHERE	process_group_num = @process_group_num
	AND	arinpchg.customer_code = #arnumblk.char8_ref1
	AND	arinpchg.trx_ctrl_num = #arnumblk.char16_ref1
	AND	arinpchg.trx_type = #arnumblk.smallint_ref1
	AND	#arnumblk.get_num = 0

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'archgpd.cpp' + ', line ' + STR( 271, 5 ) + ' -- EXIT: '
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCHGPrintDocument_SP] TO [public]
GO
