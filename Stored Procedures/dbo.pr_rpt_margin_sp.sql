SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[pr_rpt_margin_sp]	@range						varchar(8000) = ' 0 = 0 ',
																	@tabled						varchar(50) = 'prrptmgd',
																	@tableh						varchar(50) = 'prrptmgh'


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
		[source_amt_cost]						float NULL,	 --rdh
		[home_amt_cost]							float NULL,
		[oper_amt_cost]							float NULL,
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


	CREATE TABLE #prrptmgh
	(
		[contract_ctrl_num]						varchar(16) NULL,
		[description]									varchar(255) NULL,
		[start_date]									datetime NULL,
		[end_date]										datetime NULL,
		[type]												int NULL,
		[total_extended]							float NULL,
		[total_cost]									float NULL,
		[total_rebate]								float NULL,		
		[total_margin]								float NULL,
		[mem_type]										smallint NULL,
		[type_str]										varchar(20) NULL
	)

	
	CREATE TABLE #prrptmgd
	(
		[contract_ctrl_num]						varchar(16) NULL,
		[part_no]											varchar(30) NULL,
		[part_desc]										varchar(255) NULL,
		[source_trx_type]							int NULL,
		[source_extended]							float NULL,
		[source_amt_cost]							float NULL,
		[trx_type_code]								varchar(8) NULL,
		[rebate_amount]								float	NULL,
		[margin]											float NULL
	)

	CREATE TABLE #contracts
	(
		[contract_ctrl_num]						varchar(16) NULL
	)


	DECLARE	@currency_type			varchar(20),
					@min_contract 			varchar(16),
					@total_unit_price		float,
					@total_qty					int,
					@total_extended			float,
					@total_cost					float,
					@total_rebate				float,
					@total_margin				float




	SELECT @currency_type = text_value 
	FROM pr_config 
	WHERE item_name = 'CURRENCY'



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
						[source_amt_cost],
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
						[home_amt_cost],
						[oper_amt_cost],
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
						[source_amt_cost],
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
						[home_amt_cost],
						[oper_amt_cost],
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
				AND	c.status = 0 
				AND ' + @range )

	CREATE INDEX #events_idx1 ON #events(contract_ctrl_num)


	DELETE #events WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(part_no))),0) = 0


	UPDATE #events
	SET		[trx_type_code] = a.[trx_type_code]
	FROM	#events e, artrxtyp a
	WHERE	e.[source_trx_type] = a.[trx_type]
	AND	e.[source_trx_type] IN (2031, 2032)

	UPDATE #events
	SET		[trx_type_code] = a.[trx_type_code]
	FROM	#events e, aptrxtyp a
	WHERE	e.[source_trx_type] = a.[trx_type]
	AND	e.[source_trx_type] IN (4091, 4092)


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
					[oper_adjusted] = [oper_adjusted] * -1,
					[home_amt_cost] = [home_amt_cost] * -1,
					[oper_amt_cost] = [oper_amt_cost] * -1
	WHERE		[source_trx_type] IN ( 2032, 4092 )


	INSERT 	#contracts	(	[contract_ctrl_num]	)
	SELECT 	DISTINCT	[contract_ctrl_num] 
	FROM 		#events


	INSERT 	#prrptmgd
	(
		[contract_ctrl_num],
		[part_no],
		[source_trx_type],
		[source_extended],
		[source_amt_cost],
		[trx_type_code],
		[rebate_amount]
	)
	SELECT	e.[contract_ctrl_num],
					[part_no],
					[source_trx_type],
					[source_extended] = CASE WHEN UPPER(@currency_type) = 'HOME' THEN SUM([home_amount]) ELSE SUM([oper_amount]) END,
					[source_amt_cost] = CASE WHEN UPPER(@currency_type) = 'HOME' THEN SUM([home_amt_cost]) ELSE SUM([home_amt_cost]) END,
					[trx_type_code],
					[rebate_amount] = CASE WHEN UPPER(@currency_type) = 'HOME' THEN SUM([home_rebate_amount]) ELSE SUM([oper_rebate_amount]) END
	FROM		#events e, #contracts c
	WHERE		e.[contract_ctrl_num] = c.[contract_ctrl_num]
	GROUP BY e.[contract_ctrl_num], [source_trx_type], [trx_type_code], [part_no]


	UPDATE 	#prrptmgd
	SET 		[margin] = ( ( [source_extended] - [rebate_amount] - [source_amt_cost] ) / ( [source_extended] - [rebate_amount] ) )
	WHERE 	[source_extended] <> 0


	UPDATE 	#prrptmgd
	SET 		[source_amt_cost]= 0.00,
					[margin] = 0.00
	WHERE 	[source_trx_type] IN (4091, 4092)


	UPDATE 	#prrptmgd
	SET			[part_desc] = i.[description]
	FROM		#prrptmgd d, inv_master i
	WHERE		d.part_no = i.part_no








	SELECT @min_contract = MIN([contract_ctrl_num]) FROM #contracts
	WHILE @min_contract IS NOT NULL
		BEGIN

			SELECT 	@total_extended = SUM([source_extended]),
							@total_cost = SUM([source_amt_cost]),
							@total_rebate = SUM([rebate_amount]),
							@total_margin = SUM([margin])
			FROM		#prrptmgd
			WHERE		[contract_ctrl_num] = @min_contract
			AND			[source_trx_type] = 2031

			INSERT	#prrptmgh
			(
							[contract_ctrl_num],
							[description],
							[start_date],
							[end_date],
							[type],
							[total_extended],
							[total_cost],
							[total_rebate],
							[total_margin],
							[mem_type]
			)
			SELECT	c.[contract_ctrl_num],
							[description],
							[start_date] = CASE WHEN [start_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [start_date] - 639906, '1/1/1753')) ELSE [start_date] END,
							[end_date] = CASE WHEN [end_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [end_date] - 639906, '1/1/1753')) ELSE [end_date] END,
							[type],
							[total_extended] = @total_extended,
							[total_cost] = @total_cost,
							[total_rebate] = @total_rebate,
							[total_margin] = @total_margin,
							[mem_type] = 2031
			FROM	#contracts t, pr_contracts c
			WHERE	t.[contract_ctrl_num] = c.[contract_ctrl_num]
			AND		c.[contract_ctrl_num] = @min_contract


			SELECT 	@total_extended = SUM([source_extended]),
							@total_cost = SUM([source_amt_cost]),
							@total_rebate = SUM([rebate_amount]),
							@total_margin = SUM([margin])
			FROM		#prrptmgd
			WHERE		[contract_ctrl_num] = @min_contract
			AND			[source_trx_type] = 2032

			INSERT	#prrptmgh
			(
							[contract_ctrl_num],
							[description],
							[start_date],
							[end_date],
							[type],
							[total_extended],
							[total_cost],
							[total_rebate],
							[total_margin],
							[mem_type]
			)
			SELECT	c.[contract_ctrl_num],
							[description],
							[start_date] = CASE WHEN [start_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [start_date] - 639906, '1/1/1753')) ELSE [start_date] END,
							[end_date] = CASE WHEN [end_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [end_date] - 639906, '1/1/1753')) ELSE [end_date] END,
							[type],
							[total_extended] = @total_extended,
							[total_cost] = @total_cost,
							[total_rebate] = @total_rebate,
							[total_margin] = @total_margin,
							[mem_type] = 2032
			FROM	#contracts t, pr_contracts c
			WHERE	t.[contract_ctrl_num] = c.[contract_ctrl_num]
			AND		c.[contract_ctrl_num] = @min_contract



			SELECT 	@total_extended = SUM([source_extended]),
							@total_rebate = SUM([rebate_amount])
			FROM		#prrptmgd
			WHERE		[contract_ctrl_num] = @min_contract
			AND			[source_trx_type] = 4091


			INSERT	#prrptmgh
			(
							[contract_ctrl_num],
							[description],
							[start_date],
							[end_date],
							[type],
							[total_extended],
							[total_cost],
							[total_rebate],
							[total_margin],
							[mem_type]
			)
			SELECT	t.[contract_ctrl_num],
							[description],
							[start_date] = CASE WHEN [start_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [start_date] - 639906, '1/1/1753')) ELSE [start_date] END,
							[end_date] = CASE WHEN [end_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [end_date] - 639906, '1/1/1753')) ELSE [end_date] END,
							[type],
							[total_extended] = @total_extended,
							[total_cost] = 0,
							[total_rebate] = @total_rebate,
							[total_margin] = 0,
							[mem_type] = 4091
			FROM	#contracts t, pr_contracts c
			WHERE	t.[contract_ctrl_num] = c.[contract_ctrl_num]
			AND		c.[contract_ctrl_num] = @min_contract



			SELECT 	@total_extended = SUM([source_extended]),
							@total_rebate = SUM([rebate_amount])
			FROM		#prrptmgd
			WHERE		[contract_ctrl_num] = @min_contract
			AND			[source_trx_type] = 4092


			INSERT	#prrptmgh
			(
							[contract_ctrl_num],
							[description],
							[start_date],
							[end_date],
							[type],
							[total_extended],
							[total_cost],
							[total_rebate],
							[total_margin],
							[mem_type]
			)
			SELECT	t.[contract_ctrl_num],
							[description],
							[start_date] = CASE WHEN [start_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [start_date] - 639906, '1/1/1753')) ELSE [start_date] END,
							[end_date] = CASE WHEN [end_date] > 639906 THEN CONVERT(datetime, DATEADD(dd, [end_date] - 639906, '1/1/1753')) ELSE [end_date] END,
							[type],
							[total_extended] = @total_extended,
							[total_cost] = 0,
							[total_rebate] = @total_rebate,
							[total_margin] = 0,
							[mem_type] = 4092
			FROM	#contracts t, pr_contracts c
			WHERE	t.[contract_ctrl_num] = c.[contract_ctrl_num]
			AND		c.[contract_ctrl_num] = @min_contract


			SELECT 	@min_contract = MIN([contract_ctrl_num]) 
			FROM 		#contracts
			WHERE		[contract_ctrl_num] > @min_contract
		END


	UPDATE #prrptmgh
	SET	[type_str] = CASE WHEN [type] = 0 THEN 'Rebate'
												WHEN [type] = 1 THEN 'Promotion'
												WHEN [type] = 2 THEN 'Accumulator'
												WHEN [type] = 3 THEN 'Middleman'
										END


	EXEC(	'	INSERT ' + @tableh +
				'	SELECT * FROM #prrptmgh ORDER BY [contract_ctrl_num], [mem_type]' )

	EXEC(	'	INSERT ' + @tabled +
				'	SELECT * FROM #prrptmgd ORDER BY [contract_ctrl_num], [part_no]' )






GO
GRANT EXECUTE ON  [dbo].[pr_rpt_margin_sp] TO [public]
GO
