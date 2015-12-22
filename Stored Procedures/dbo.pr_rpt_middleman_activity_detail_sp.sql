SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_rpt_middleman_activity_detail_sp]	@contract_status	smallint = 0,	
																											@exclude_pif			smallint = 0,	
																											@suppress_detail	smallint = 0,	
																											@prt_address			smallint = 0, 
																											@prt_copy					smallint = 0, 
																											@range						varchar(8000) = ' 0 = 0 ',
																											@tableh						varchar(50) = 'prrptmah',
																											@tabled						varchar(50) = 'prrptmad',
																											@table_i_h				varchar(50) = 'prrptinvh',
																											@table_i_d				varchar(50) = 'prrptinvd'



AS


	CREATE TABLE #events
	(
		[contract_ctrl_num]						varchar(16) NULL,
		[sequence_id]									int NULL,
		[process_ctrl_num]						varchar(16) NULL,
		[post_date]										int NULL,
		[customer_code]								varchar(8) NULL,
		[price_class]									varchar(8) NULL,
		[na_parent_code]							varchar(8) NULL,
		[vendor_code]									varchar(12) NULL,	-- SCR 2017
		[vendor_class]								varchar(8) NULL,
		[part_no]											varchar(30) NULL,
		[part_category]								varchar(10) NULL,
		[source_trx_ctrl_num]					varchar(16) NULL,
		[source_sequence_id]					int NULL,
		[source_doc_ctrl_num]					varchar(16) NULL,
		[source_trx_type]							int NULL,
		[source_apply_date]						int NULL,
		[source_qty_shipped]					float NULL,
		[source_unit_price]						float NULL,
		[source_gross_amount]					float NULL,
		[source_discount_amount]			float NULL,
		[amount_adjusted]							float NULL,
		[void_flag]										int NULL,
		[nat_cur_code]								varchar(8) NULL,
		[rate_type_home]							varchar(8) NULL,
		[rate_type_oper]							varchar(8) NULL,
		[rate_home]										float NULL,
		[rate_oper]										float NULL,
		[home_amount]									float NULL,
		[oper_amount]									float NULL,
		[home_adjusted]								float NULL,
		[oper_adjusted]								float NULL,
		[userid]											int NULL,
		[home_rebate_amount]					float NULL,
		[oper_rebate_amount]					float NULL,

		[description]									varchar(255) NULL,
		[start_date]									int NULL,
		[end_date]										int NULL,
		[status]											int NULL,
		[type]												int NULL,
		[amount_paid_to_date_home]		float NULL,		
		[amount_paid_to_date_oper]		float NULL,		
		[amount_accrued_home]					float NULL,
		[amount_accrued_oper]					float NULL,

		[customer_name]								varchar(40) NULL,

		[vendor_name]									varchar(40) NULL,

		[class_desc]									varchar(40) NULL,

		[price_desc]									varchar(40) NULL,

		[part_desc]										varchar(255) NULL,

		[category_desc]								varchar(40) NULL,

		[trx_type_code]								varchar(8) NULL
	)


	DECLARE	@currency_type			varchar(20),
					@status_range				varchar(20),
					@min_code 					varchar(12),		-- SCR 2017
					@min_contract 			varchar(16),
					@amt_paid 					float,
					@amt_accrued 				float,
					@amt_paid_str				varchar(50),
					@amt_accrued_str		varchar(50),
					@co_addr1						varchar(40),
					@co_addr2						varchar(40),
					@co_addr3						varchar(40),
					@co_addr4						varchar(40),
					@co_addr5						varchar(40),
					@co_addr6						varchar(40),
					@prt_address_str		varchar(5),
					@prt_copy_str				varchar(5)



	SELECT @currency_type = text_value 
	FROM pr_config 
	WHERE item_name = 'CURRENCY'


	SELECT @status_range = '( 0 )'
	
	IF ( @contract_status = 0 )
		SELECT @status_range = '( 0 )'
	IF ( @contract_status = 1 )
		SELECT @status_range = '( 1 )'
	IF ( @contract_status = 2 )
		SELECT @status_range = '( 0, 1 )'

	SELECT	@co_addr1 = addr1,		
					@co_addr2 = addr2,
					@co_addr3 = addr3,
					@co_addr4 = addr4,
					@co_addr5 = addr5,
					@co_addr6 = addr6
	FROM 	arco

	SELECT	@prt_address_str = CONVERT(varchar(5), @prt_address ),
					@prt_copy_str = CONVERT(varchar(5), @prt_copy )



	EXEC('INSERT #events
			(			[contract_ctrl_num],
						[sequence_id],
						[process_ctrl_num],
						[post_date],
						[customer_code],
						[price_class],
						[na_parent_code],
						[vendor_code],
						[vendor_class],
						[part_no],
						[part_category],
						[source_trx_ctrl_num],
						[source_sequence_id],
						[source_doc_ctrl_num],
						[source_trx_type],
						[source_apply_date],
						[source_qty_shipped],
						[source_unit_price],
						[source_gross_amount],
						[source_discount_amount],
						[amount_adjusted],
						[void_flag],
						[nat_cur_code],
						[rate_type_home],
						[rate_type_oper],
						[rate_home],
						[rate_oper],
						[home_amount],
						[oper_amount],
						[home_adjusted],
						[oper_adjusted],
						[home_rebate_amount],
						[oper_rebate_amount],
		
						[description],
						[start_date],
						[end_date],
						[status],
						[type],
						[amount_paid_to_date_home],
						[amount_paid_to_date_oper],
						[amount_accrued_home],
						[amount_accrued_oper]
			)
		SELECT	e.[contract_ctrl_num],
						[sequence_id],
						[process_ctrl_num],
						[post_date],
						ISNULL([customer_code], ""),
						[price_class],
						[na_parent_code],
						ISNULL([vendor_code],""),
						[vendor_class],
						[part_no],
						[part_category],
						[source_trx_ctrl_num],
						[source_sequence_id],
						[source_doc_ctrl_num],
						[source_trx_type],
						[source_apply_date],
						[source_qty_shipped],
						[source_unit_price],
						[source_gross_amount],
						[source_discount_amount],
						[amount_adjusted],
						[void_flag],
						[nat_cur_code],
						[rate_type_home],
						[rate_type_oper],
						[rate_home],
						[rate_oper],
						[home_amount],
						[oper_amount],
						[home_adjusted],
						[oper_adjusted],
						[home_rebate_amount],
						[oper_rebate_amount],
		
						[description],
						[start_date],
						[end_date],
						[status],
						[type],
						[amount_paid_to_date_home],
						[amount_paid_to_date_oper],
						[amount_accrued_home],
						[amount_accrued_oper]
				FROM 	pr_contracts c, pr_events e
				WHERE c.contract_ctrl_num = e.contract_ctrl_num
				AND	[void_flag] = 0
				AND [type] = 3
				AND	c.status IN ' + @status_range + 
			' AND ' + @range )

	CREATE INDEX #events_idx1 ON #events(contract_ctrl_num)
																										

	UPDATE 	#events
	SET			[customer_name] = c.[customer_name]
	FROM		#events e, arcust c
	WHERE		e.[customer_code] = c.[customer_code]

	UPDATE 	#events
	SET			[vendor_name] = v.[vendor_name]
	FROM		#events e, apvend v
	WHERE		e.[vendor_code] = v.[vendor_code]


	UPDATE 	#events
	SET 		[home_rebate_amount] = [home_rebate_amount] * -1,
					[oper_rebate_amount] = [oper_rebate_amount] * -1,
					[source_unit_price] = [source_unit_price] * -1,
					[source_gross_amount] = [source_gross_amount] * -1,
					[source_discount_amount] = [source_discount_amount] * -1,
					[amount_adjusted] = [amount_adjusted] * -1,
					[home_amount] = [home_amount] * -1,
					[oper_amount] = [oper_amount] * -1,
					[home_adjusted] = [home_adjusted] * -1,
					[oper_adjusted] = [oper_adjusted] * -1
	WHERE		[source_trx_type] IN ( 2032, 4092 )



	UPDATE #events
	SET		[trx_type_code] = a.[trx_type_code]
	FROM	#events e, artrxtyp a
	WHERE	e.[source_trx_type] = a.[trx_type]


	DELETE #events
	WHERE ( ( ISNULL(DATALENGTH(LTRIM(RTRIM(customer_code))),0) = 0 ) AND ( ISNULL(DATALENGTH(LTRIM(RTRIM(vendor_code))),0) = 0 ) )






	SELECT @min_contract = MIN([contract_ctrl_num]) FROM #events
	WHILE @min_contract IS NOT NULL
		BEGIN
			SELECT @min_code = MIN([customer_code]) FROM #events WHERE [contract_ctrl_num] = @min_contract  AND ISNULL(DATALENGTH(LTRIM(RTRIM(customer_code))),0) > 0
			WHILE @min_code IS NOT NULL
				BEGIN
					SELECT 	@amt_paid = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	[amount_paid_to_date_home] ELSE [amount_paid_to_date_oper] END,
									@amt_accrued = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	[amount_accrued_home] ELSE [amount_accrued_oper] END
					FROM		pr_customers
					WHERE		[customer_code] = @min_code
					AND			[contract_ctrl_num] = @min_contract


					IF ( @exclude_pif = 1 )
						BEGIN
							IF @amt_accrued <= @amt_paid
								BEGIN
									GOTO next_cust
								END
						END

					SELECT 	@amt_paid_str = ISNULL(CONVERT(varchar(50), @amt_paid ),0),
									@amt_accrued_str = ISNULL(CONVERT(varchar(50), @amt_accrued ),0)

		
					EXEC(	' INSERT ' + @tableh + ' ( [contract_ctrl_num], [customer_code] )
									SELECT "' + @min_contract + '", "' +  @min_code + '"')

					EXEC( '	UPDATE ' + @tableh +
								' SET		[customer_name] = e.[customer_name],
												[description] = e.[description],
												[start_date] = CASE WHEN e.[start_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, e.[start_date] - 639906, "1/1/1753")) ELSE e.[start_date] end,
												[end_date] = CASE WHEN e.[end_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, e.[end_date] - 639906, "1/1/1753")) ELSE e.[end_date] end,
												[status] = CASE WHEN e.[status] = 0 THEN "ACTIVE" ELSE "INACTIVE" END,
												[type] = e.[type],
												[amt_paid] = ' + @amt_paid_str + ', ' +
											'	[amt_accrued] = ' + @amt_accrued_str + ', ' +
											'	[member_type] = 0
									FROM	#events e,  ' + @tableh + ' h ' +
								'	WHERE	h.[customer_code] = "' + @min_code + '" ' +
								'	AND		h.[contract_ctrl_num] = "' + @min_contract + '" ' +
								'	AND		h.[customer_code] = e.[customer_code]
									AND		h.[contract_ctrl_num] = e.[contract_ctrl_num] ' )


					IF ( @suppress_detail = 1 )
						GOTO	next_cust

							EXEC(	'	INSERT ' + @tabled + 
															'([contract_ctrl_num],
																[customer_code], 
																[part_no], 
																[source_trx_ctrl_num],
																[source_doc_ctrl_num],
																[source_trx_type],
																[source_apply_date],
																[source_qty_shipped],
																[source_gross_amount],
																[nat_cur_code],
																[converted_gross_amount],
																[amt_accrued],
																[trx_type_code],
																[currency_type])
											SELECT "' + @min_contract + '", ' + 
														'"' +  @min_code + '", ' +
															'	e.[part_no],
													 			e.[source_trx_ctrl_num],
																e.[source_doc_ctrl_num],
																e.[source_trx_type],
																e.[source_apply_date],
																e.[source_qty_shipped],
																e.[source_gross_amount],
																e.[nat_cur_code],
																CASE	WHEN ( UPPER( "' + @currency_type + '" ) = "HOME" ) THEN [home_amount] ELSE [oper_amount] END,
																CASE	WHEN ( UPPER( "' + @currency_type + '" ) = "HOME" ) THEN [home_rebate_amount] ELSE [oper_rebate_amount] END,
																e.[trx_type_code], "' +
																@currency_type + '" ' +
												'	FROM	#events e,  ' + @tableh + ' h ' +
										'	WHERE	h.[customer_code] = "' + @min_code + '" ' +
										'	AND		h.[contract_ctrl_num] = "' + @min_contract + '" ' +
										'	AND		h.[customer_code] = e.[customer_code]
											AND		h.[contract_ctrl_num] = e.[contract_ctrl_num] ')

next_cust:
						SELECT 	@min_code = MIN([customer_code]) 
						FROM 		#events 
						WHERE 	[contract_ctrl_num] = @min_contract
						AND			[customer_code] > @min_code
				END	
			SELECT 	@min_contract = MIN([contract_ctrl_num]) 
			FROM 		#events
			WHERE 	[contract_ctrl_num] > @min_contract
		END	



	UPDATE #events
	SET		[trx_type_code] = a.[trx_type_code]
	FROM	#events e, aptrxtyp a
	WHERE	e.[source_trx_type] = a.[trx_type]

	SELECT @min_contract = MIN([contract_ctrl_num]) FROM #events
	WHILE @min_contract IS NOT NULL
		BEGIN
			SELECT @min_code = MIN([vendor_code]) FROM #events WHERE [contract_ctrl_num] = @min_contract  AND ISNULL(DATALENGTH(LTRIM(RTRIM(vendor_code))),0) > 0
			WHILE @min_code IS NOT NULL
				BEGIN
					SELECT 	@amt_paid = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	[amount_paid_to_date_home] ELSE [amount_paid_to_date_oper] END,
									@amt_accrued = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	[amount_accrued_home] ELSE [amount_accrued_oper] END
					FROM		pr_vendors
					WHERE		[vendor_code] = @min_code
					AND			[contract_ctrl_num] = @min_contract
		

					IF ( @exclude_pif = 1 )
						BEGIN
							IF @amt_accrued <= @amt_paid
								BEGIN
									GOTO next_vend
								END
						END

					SELECT 	@amt_paid_str = ISNULL(CONVERT(varchar(50), @amt_paid ),0),
									@amt_accrued_str = ISNULL(CONVERT(varchar(50), @amt_accrued ),0)

					EXEC(	' INSERT ' + @tableh + ' ( [contract_ctrl_num], [vendor_code] )
									SELECT "' + @min_contract + '", "' +  @min_code + '"')
		
					EXEC( '	UPDATE ' + @tableh +
								' SET		[vendor_name] = e.[vendor_name],
												[description] = e.[description],
												[start_date] = CASE WHEN e.[start_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, e.[start_date] - 639906, "1/1/1753")) ELSE e.[start_date] end,
												[end_date] = CASE WHEN e.[end_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, e.[end_date] - 639906, "1/1/1753")) ELSE e.[end_date] end,
												[status] = CASE WHEN e.[status] = 0 THEN "ACTIVE" ELSE "INACTIVE" END,
												[type] = e.[type],
												[amt_paid] = ' + @amt_paid_str + ', ' +
											'	[amt_accrued] = ' + @amt_accrued_str + ', ' +
											'	[member_type] = 1
									FROM	#events e,  ' + @tableh + ' h ' +
								'	WHERE	h.[vendor_code] = "' + @min_code + '" ' +
								'	AND		h.[contract_ctrl_num] = "' + @min_contract + '" ' +
								'	AND		h.[vendor_code] = e.[vendor_code]
									AND		h.[contract_ctrl_num] = e.[contract_ctrl_num] ' )


					IF ( @suppress_detail = 1 )
						GOTO	next_vend

							EXEC(	'	INSERT ' + @tabled + 
															'([contract_ctrl_num],
																[vendor_code], 
																[part_no], 
																[source_trx_ctrl_num],
																[source_doc_ctrl_num],
																[source_trx_type],
																[source_apply_date],
																[source_qty_shipped],
																[source_gross_amount],
																[nat_cur_code],
																[converted_gross_amount],
																[amt_accrued],
																[trx_type_code],
																[currency_type])
											SELECT "' + @min_contract + '", ' + 
														'"' +  @min_code + '", ' +
															'	e.[part_no],
													 			e.[source_trx_ctrl_num],
																e.[source_doc_ctrl_num],
																e.[source_trx_type],
																e.[source_apply_date],
																e.[source_qty_shipped],
																e.[source_gross_amount],
																e.[nat_cur_code],
																CASE	WHEN ( UPPER( "' + @currency_type + '" ) = "HOME" ) THEN [home_amount] ELSE [oper_amount] END,
																CASE	WHEN ( UPPER( "' + @currency_type + '" ) = "HOME" ) THEN [home_rebate_amount] ELSE [oper_rebate_amount] END,
																e.[trx_type_code], "' +
																@currency_type + '" ' +
												'	FROM	#events e,  ' + @tableh + ' h ' +
										'	WHERE	h.[vendor_code] = "' + @min_code + '" ' +
										'	AND		h.[contract_ctrl_num] = "' + @min_contract + '" ' +
										'	AND		h.[vendor_code] = e.[vendor_code]
											AND		h.[contract_ctrl_num] = e.[contract_ctrl_num] ')

next_vend:
						SELECT 	@min_code = MIN([vendor_code]) 
						FROM 		#events 
						WHERE 	[contract_ctrl_num] = @min_contract
						AND			[vendor_code] > @min_code
				END	
			SELECT 	@min_contract = MIN([contract_ctrl_num]) 
			FROM 		#events
			WHERE 	[contract_ctrl_num] > @min_contract
		END	



	EXEC(	'INSERT ' + @table_i_h + 
				' ( trx_ctrl_num, 
						trx_type, 
						contract_ctrl_num,
						customer_code, 
						batch_code,
						copies, 
						ship_via_code, 
						doc_ctrl_num, 
						image_id,
						date_doc,
						date_due,
						amt_net, 
						amt_discount,
						amt_freight, 
						amt_tax, 
						amt_gross,
						amt_paid, 
						amt_due, 
						customer_addr1,
						customer_addr2, 
						customer_addr3, 
						customer_addr4,
						customer_addr5, 
						customer_addr6, 
						ship_to_addr1,
						ship_to_addr2, 
						ship_to_addr3, 
						ship_to_addr4,
						ship_to_addr5, 
						ship_to_addr6, 
						apply_to_num,
						cust_po_num,
						date_shipped, 
						comment_line,
						fob_desc, 
						order_ctrl_num, 
						salesperson_name, 
						terms_desc,
						not_prev_printed, 
						nat_cur_code 
					)
		SELECT	DISTINCT t.trx_ctrl_num, 
						t.trx_type, 
						p.contract_ctrl_num,
						t.customer_code, 
						t.batch_code,
						1, 
						t.freight_code, 
						t.doc_ctrl_num, 
						1,
						dateadd(dd,t.date_doc - 657072,"1/1/1800"),
						dateadd(dd,t.date_due - 657072,"1/1/1800"),
						t.amt_net, 
						t.amt_discount,
						t.amt_freight, 
						t.amt_tax, 
						t.amt_gross,
						t.amt_paid_to_date, 
						t.amt_net - t.amt_paid_to_date, 
						x.addr1,
						x.addr2, 
						x.addr3, 
						x.addr4,
						x.addr5, 
						x.addr6, 
						x.ship_addr1,
						x.ship_addr2, 
						x.ship_addr3, 
						x.ship_addr4,
						x.ship_addr5, 
						x.ship_addr6, 
						t.apply_to_num,
						t.cust_po_num,
						dateadd(dd,t.date_shipped-657072,"1/1/1800"), 
						t.comment_code,
						t.fob_code, 
						t.order_ctrl_num, 
						t.salesperson_code, 
						t.terms_code,
						0, 
						t.nat_cur_code
		FROM artrx t 
			LEFT OUTER JOIN artrxxtr x ON (t.trx_ctrl_num = x.trx_ctrl_num AND t.trx_type = x.trx_type), 
			' + @tabled + ' p
		WHERE t.trx_type = 2031 
		AND t.trx_ctrl_num = p.source_trx_ctrl_num ')
 

	EXEC(	'UPDATE ' + @table_i_h +
				' SET terms_desc = ISNULL(SUBSTRING(arterms.terms_desc,1,20),""),
							salesperson_name = ISNULL(arsalesp.salesperson_name, ""),
							ship_via_code = ISNULL(arfrcode.ship_via_code, ""),
							comment_line = ISNULL(arcommnt.comment_line, ""),
							addr_sort1 = armaster.addr_sort1,
							addr_sort2 = armaster.addr_sort2,
							addr_sort3 = armaster.addr_sort3,
							copies = armaster.invoice_copies,
							symbol = glcurr_vw.symbol,
							curr_precision = glcurr_vw.curr_precision,
							fob_desc = arfob.fob_desc
					FROM ' + @table_i_h + ' archarge
						LEFT OUTER JOIN arcommnt ON (archarge.comment_line = arcommnt.comment_code)
						LEFT OUTER JOIN arterms ON (archarge.terms_desc = arterms.terms_code)
						LEFT OUTER JOIN arfrcode ON (archarge.ship_via_code = arfrcode.freight_code)
						LEFT OUTER JOIN arfob ON (archarge.fob_desc = arfob.fob_code)
						LEFT OUTER JOIN arsalesp ON (archarge.salesperson_name = arsalesp.salesperson_code ), 
						armaster, arco, glcurr_vw
					WHERE archarge.customer_code = armaster.customer_code
					AND armaster.address_type = 0
					AND archarge.nat_cur_code = glcurr_vw.currency_code' )


	EXEC(	'UPDATE ' + @table_i_h +
				' SET co_addr1 = "' + @co_addr1 + '",
							co_addr2 = "' + @co_addr2 + '",
							co_addr3 = "' + @co_addr3 + '",
							co_addr4 = "' + @co_addr4 + '",
							co_addr5 = "' + @co_addr5 + '",
							co_addr6 = "' + @co_addr6 + '",
							prt_address	= ' + @prt_address_str + ',
							prt_copy	= ' +  @prt_copy_str )



	EXEC(	'INSERT ' + @table_i_d +
				'(	trx_ctrl_num, 
						trx_type, 
						sequence_id, 
						symbol, 
						curr_precision,
						location_code, 
						item_code, 
						line_desc,
						qty_ordered, 
						qty_shipped, 
						qty_back_ordered,
						unit_code, 
						unit_price, 
						unit_cost,
						weight, 
						serial_id, 
						tax_code,
						gl_rev_acct, 
						disc_prc_flag, 
						discount_amt,
						discount_prc, 
						extended_price, 
						calc_tax, 
						reference_code) 
						SELECT a.trx_ctrl_num, 
						a.trx_type, 
						b.sequence_id, 
						a.symbol, 
						a.curr_precision,
						b.location_code, 
						b.item_code, 
						ISNULL(line_desc, ""),
						b.qty_ordered, 
						b.qty_shipped, 
						b.qty_ordered - b.qty_shipped,
						b.unit_code, 
						b.unit_price, 
						b.amt_cost,
						b.weight, 
						b.serial_id, 
						b.tax_code,
						b.gl_rev_acct, 
						b.disc_prc_flag, 
						b.discount_amt,
						b.discount_prc, 
						b.extended_price, 
						b.calc_tax, 
						b.reference_code 
				FROM ' + @table_i_h + ' a, artrxcdt b
				WHERE a.trx_ctrl_num = b.trx_ctrl_num
				AND a.trx_type = b.trx_type ' )







			
																										
	DROP TABLE #events

GO
GRANT EXECUTE ON  [dbo].[pr_rpt_middleman_activity_detail_sp] TO [public]
GO
