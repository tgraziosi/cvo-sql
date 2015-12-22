SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_rpt_contract_activity_summary_sp]	@contract_type		smallint = 0,	
																											@contract_status	smallint = 0,	
																											@exclude_pif			smallint = 0,	
																											@suppress_detail	smallint = 0,	
																											@range						varchar(8000) = ' 0 = 0 ',
																											@mem_type					smallint = 0,	
																											@tableh						varchar(50) = 'prrptcah',
																											@tabled						varchar(50) = 'prrptcad'


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
					@contract_type_str	varchar(5),
					@min_code 					varchar(12),		-- SCR 2017
					@min_contract 			varchar(16),
					@amt_paid 					float,
					@amt_accrued 				float,
					@min_part 					varchar(30),
					@qty_shipped 				int,
					@shipped_net 				float,
					@qty_returned 			int,
					@returned_net 			float,
					@qty_shipped_str		varchar(10),
					@shipped_net_str		varchar(50),
					@qty_returned_str		varchar(10),
					@returned_net_str		varchar(50),
					@amt_paid_str				varchar(50),
					@amt_accrued_str		varchar(50)



	SELECT @currency_type = text_value 
	FROM pr_config 
	WHERE item_name = 'CURRENCY'



	SELECT @contract_type_str = CONVERT(varchar(5), @contract_type )

	SELECT @status_range = '( 0 )'
	
	IF ( @contract_status = 0 )
		SELECT @status_range = '( 0 )'
	IF ( @contract_status = 1 )
		SELECT @status_range = '( 1 )'
	IF ( @contract_status = 2 )
		SELECT @status_range = '( 0, 1 )'



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
				FROM 	pr_contracts c, pr_events e
				WHERE c.contract_ctrl_num = e.contract_ctrl_num
				AND	[void_flag] = 0
				AND [type] = ' +	@contract_type_str +
			' AND	c.status IN ' + @status_range + 
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
					[oper_rebate_amount] = [oper_rebate_amount] * -1
	WHERE		[source_trx_type] IN ( 2032, 4092 )






	IF @mem_type = 0	
		BEGIN

			DELETE #events WHERE ISNULL(DATALENGTH(LTRIM(RTRIM(customer_code))),0) = 0
			SELECT @min_contract = MIN([contract_ctrl_num]) FROM #events
			WHILE @min_contract IS NOT NULL
				BEGIN
					SELECT @min_code = MIN([customer_code]) FROM #events WHERE [contract_ctrl_num] = @min_contract
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

							SELECT 	@amt_paid_str = ISNULL(CONVERT(varchar(30), @amt_paid ),0),
											@amt_accrued_str = ISNULL(CONVERT(varchar(30), @amt_accrued ),0)

		
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
													'	[amt_accrued] = ' + @amt_accrued_str +
										'	FROM	#events e,  ' + @tableh + ' h ' +
										'	WHERE	h.[customer_code] = "' + @min_code + '" ' +
										'	AND		h.[contract_ctrl_num] = "' + @min_contract + '" ' +
										'	AND		h.[customer_code] = e.[customer_code]
											AND		h.[contract_ctrl_num] = e.[contract_ctrl_num] ' )


							IF ( @suppress_detail = 1 )
								GOTO	next_cust







							SELECT @min_part = MIN([part_no])
							FROM 		#events 
							WHERE 	[contract_ctrl_num] = @min_contract
							AND			[customer_code] = @min_code

							WHILE @min_part IS NOT NULL
								BEGIN
									SELECT 	@qty_shipped = SUM([source_qty_shipped]),
													@shipped_net = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	SUM([home_amount]) ELSE SUM([oper_amount]) END
									FROM	#events
									WHERE	[contract_ctrl_num] = @min_contract
									AND		[customer_code] = @min_code
									AND		[part_no] = @min_part
									AND		[source_trx_type]	= 2031

									SELECT 	@qty_returned = SUM([source_qty_shipped]),
													@returned_net = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	SUM([home_amount]) ELSE SUM([oper_amount]) END
									FROM	#events
									WHERE	[contract_ctrl_num] = @min_contract
									AND		[customer_code] = @min_code
									AND		[part_no] = @min_part
									AND		[source_trx_type]	IN ( 2032 )


									SELECT	@amt_accrued = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	SUM([home_rebate_amount]) ELSE SUM([oper_rebate_amount]) END
									FROM		#events
									WHERE		[customer_code] = @min_code
									AND			[contract_ctrl_num] = @min_contract
									AND			[part_no] = @min_part

									SELECT 	@qty_shipped_str = ISNULL(CONVERT(varchar(10), @qty_shipped ),0),
													@shipped_net_str = ISNULL(CONVERT(varchar(30), @shipped_net ),0),
													@qty_returned_str = ISNULL(CONVERT(varchar(10), @qty_returned ),0),
													@returned_net_str = ISNULL(CONVERT(varchar(30), @returned_net * -1 ),0),
													@amt_accrued_str = ISNULL(CONVERT(varchar(30), @amt_accrued ),0)

		
									EXEC(	'	INSERT ' + @tabled + '([contract_ctrl_num],[customer_code],[part_no])
													SELECT "' + @min_contract + '", "' +  @min_code + '", "' + @min_part + '" ')


									EXEC( '	UPDATE ' + @tabled +
												'	SET	[sum_qty_shipped] = ' + @qty_shipped_str + ', ' +
														'	[sum_shipped_net] = ' + @shipped_net_str + ', ' +
														'	[sum_qty_returned] = ' + @qty_returned_str + ', ' +
														'	[sum_returned_net] = ' + @returned_net_str + ', ' +
														'	[amt_accrued] = ' + @amt_accrued_str +
												'	FROM	#events e,  ' + @tabled + ' d ' +
												'	WHERE	d.[customer_code] = "' + @min_code + '" ' +
												'	AND		d.[contract_ctrl_num] = "' + @min_contract + '" ' +
												'	AND		d.[part_no] = "' + @min_part + '" ' +
												'	AND		d.[customer_code] = e.[customer_code]
													AND		d.[contract_ctrl_num] = e.[contract_ctrl_num] 
													AND		d.[part_no] = e.[part_no] ')

									SELECT @min_part = MIN([part_no])
									FROM		#events
									WHERE		[customer_code] = @min_code
									AND			[contract_ctrl_num] = @min_contract
									AND			[part_no] > @min_part
								END	
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
		END	
	ELSE	
		BEGIN

			DELETE #events WHERE ISNULL(DATALENGTH(LTRIM(RTRIM(vendor_code))),0) = 0
			SELECT @min_contract = MIN([contract_ctrl_num]) FROM #events
			WHILE @min_contract IS NOT NULL
				BEGIN
					SELECT @min_code = MIN([vendor_code]) FROM #events WHERE [contract_ctrl_num] = @min_contract
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
		
							SELECT 	@amt_paid_str = ISNULL(CONVERT(varchar(30), @amt_paid ),0),
											@amt_accrued_str = ISNULL(CONVERT(varchar(30), @amt_accrued ),0)

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
													'	[amt_accrued] = ' + @amt_accrued_str +
										'	FROM	#events e,  ' + @tableh + ' h ' +
										'	WHERE	h.[vendor_code] = "' + @min_code + '" ' +
										'	AND		h.[contract_ctrl_num] = "' + @min_contract + '" ' +
										'	AND		h.[vendor_code] = e.[vendor_code]
											AND		h.[contract_ctrl_num] = e.[contract_ctrl_num] ' )


							IF ( @suppress_detail = 1 )
								GOTO	next_vend







							SELECT @min_part = MIN([part_no])
							FROM 		#events 
							WHERE 	[contract_ctrl_num] = @min_contract
							AND			[vendor_code] = @min_code

							WHILE @min_part IS NOT NULL
								BEGIN
									SELECT 	@qty_shipped = SUM([source_qty_shipped]),
													@shipped_net = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	SUM([home_amount]) ELSE SUM([oper_amount]) END
									FROM	#events
									WHERE	[contract_ctrl_num] = @min_contract
									AND		[vendor_code] = @min_code
									AND		[part_no] = @min_part
									AND		[source_trx_type]	= 4091

									SELECT 	@qty_returned = SUM([source_qty_shipped]),
													@returned_net = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	SUM([home_amount]) ELSE SUM([oper_amount]) END
									FROM	#events
									WHERE	[contract_ctrl_num] = @min_contract
									AND		[vendor_code] = @min_code
									AND		[part_no] = @min_part
									AND		[source_trx_type]	IN ( 4092 )


									SELECT	@amt_accrued = CASE	WHEN ( UPPER( @currency_type ) = 'HOME' ) THEN 	SUM([home_rebate_amount]) ELSE SUM([oper_rebate_amount]) END
									FROM		#events
									WHERE		[vendor_code] = @min_code
									AND			[contract_ctrl_num] = @min_contract
									AND			[part_no] = @min_part

									SELECT 	@qty_shipped_str = ISNULL(CONVERT(varchar(10), @qty_shipped ),0),
													@shipped_net_str = ISNULL(CONVERT(varchar(30), @shipped_net ),0),
													@qty_returned_str = ISNULL(CONVERT(varchar(10), @qty_returned ),0),
													@returned_net_str = ISNULL(CONVERT(varchar(30), @returned_net * -1 ),0),
													@amt_accrued_str = ISNULL(CONVERT(varchar(30), @amt_accrued ),0)

		
									EXEC(	'	INSERT ' + @tabled + '([contract_ctrl_num],[vendor_code],[part_no])
													SELECT "' + @min_contract + '", "' +  @min_code + '", "' + @min_part + '" ')
		
									EXEC( '	UPDATE ' + @tabled +
												'	SET	[sum_qty_shipped] = ' + @qty_shipped_str + ', ' +
														'	[sum_shipped_net] = ' + @shipped_net_str + ', ' +
														'	[sum_qty_returned] = ' + @qty_returned_str + ', ' +
														'	[sum_returned_net] = ' + @returned_net_str + ', ' +
														'	[amt_accrued] = ' + @amt_accrued_str +
												'	FROM	#events e,  ' + @tabled + ' d ' +
												'	WHERE	d.[vendor_code] = "' + @min_code + '" ' +
												'	AND		d.[contract_ctrl_num] = "' + @min_contract + '" ' +
												'	AND		d.[part_no] = "' + @min_part + '" ' +
												'	AND		d.[vendor_code] = e.[vendor_code]
													AND		d.[contract_ctrl_num] = e.[contract_ctrl_num] 
													AND		d.[part_no] = e.[part_no] ')

									SELECT @min_part = MIN([part_no])
									FROM		#events
									WHERE		[vendor_code] = @min_code
									AND			[contract_ctrl_num] = @min_contract
									AND			[part_no] > @min_part
								END	
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
		END	







					
																										
	DROP TABLE #events

GO
GRANT EXECUTE ON  [dbo].[pr_rpt_contract_activity_summary_sp] TO [public]
GO
