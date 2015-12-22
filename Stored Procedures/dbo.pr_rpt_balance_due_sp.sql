SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[pr_rpt_balance_due_sp]		@contract_type		smallint = 0,	
																					@contract_status	smallint = 0,	
																					@member_type					smallint = 0,	
																					@exclude_pif			smallint = 0,	
																					@range						varchar(8000) = ' 0 = 0 ',
																					@tableh						varchar(50) = 'prrptph',
																					@tabled						varchar(50) = 'prrptpd'
AS

	DECLARE	@currency_type			varchar(20),
					@status_range				varchar(20),
					@type_range				varchar(20),
					@contract_type_str	varchar(5),
					@min_code 					varchar(8),
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
					@amt_accrued_str		varchar(50),
					@mem_table					varchar(20),
					@mem_code						varchar(20)




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


	
	IF ( @contract_type = 0 )
		SELECT @type_range = '( 0 )'
	IF ( @contract_type = 1 )
		SELECT @type_range = '( 1 )'
	IF ( @contract_type = 2 )
		SELECT @type_range = '( 2 )'
	IF ( @contract_type = 3 )
		SELECT @type_range = '( 3 )'
	IF ( @contract_type = 4 )
		SELECT @type_range = '( 0, 1, 2, 3 )'


	IF @member_type = 0
		BEGIN
			SELECT @mem_table = 'pr_customers'
			SELECT @mem_code = 'customer_code'
		END
	ELSE
		BEGIN
			SELECT @mem_table = 'pr_vendors'
			SELECT @mem_code = 'vendor_code'
		END

	EXEC(	'	INSERT ' + @tableh +
					'([contract_ctrl_num],
						[sequence_id],
						[member_code],
						[void],
						[date_entered],
						[userid],
						[amount_paid_to_date],
						[amount_accrued])
					SELECT 
						m.[contract_ctrl_num],
						[sequence_id], ' +
						@mem_code + ', ' +
					'	[void],
						m.[date_entered],
						m.[userid],
						CASE WHEN UPPER("' + @currency_type + '") = "HOME" THEN m.amount_paid_to_date_home ELSE m.amount_paid_to_date_oper END,
						CASE WHEN UPPER("' + @currency_type + '") = "HOME" THEN m.amount_accrued_home ELSE m.amount_accrued_oper END			
					FROM	' + @mem_table + ' m, pr_contracts c
					WHERE m.contract_ctrl_num = c.contract_ctrl_num
					AND	c.status IN ' + @status_range + 
				'	AND	c.type IN ' + @type_range +
				' AND ' + @range )



	IF ( @exclude_pif = 1 )
		EXEC(	'	DELETE ' + @tableh +
					'	WHERE	amount_accrued - amount_paid_to_date = 0 ' )

	EXEC(	'	INSERT ' + @tabled +
				'(	[detail_type],
						[contract_ctrl_num],
						[sequence_id],
						[member_code],
						[part_no],
						[source_trx_ctrl_num],
						[source_sequence_id],
						[source_doc_ctrl_num],
						[source_trx_type],
						[source_apply_date],
						[source_gross_amount],
						[amount_adjusted],
						[void_flag],
						[nat_cur_code],
						[conv_amount],
						[conv_adjusted],
						[conv_rebate_amount])
					SELECT
						1,
						e.[contract_ctrl_num],
						e.[sequence_id], ' +
						@mem_code + ', ' +
					'	[part_no],
						[source_trx_ctrl_num],
						[source_sequence_id],
						[source_doc_ctrl_num],
						[source_trx_type],
						[source_apply_date],
						[source_gross_amount],
						[amount_adjusted],
						[void_flag],
						[nat_cur_code],
						CASE WHEN UPPER("' + @currency_type + '") = "HOME" THEN home_amount ELSE oper_amount END,
						CASE WHEN UPPER("' + @currency_type + '") = "HOME" THEN home_adjusted ELSE oper_adjusted END,
						CASE WHEN UPPER("' + @currency_type + '") = "HOME" THEN home_rebate_amount ELSE oper_rebate_amount END
					FROM pr_events e, ' + @tableh + ' h 
					WHERE	e.contract_ctrl_num = h.contract_ctrl_num
					AND e.' + @mem_code + ' = h.member_code ' )

	IF @member_type = 0
	
		EXEC(	'	INSERT ' + @tabled +
					'(	[detail_type],
							[contract_ctrl_num],
							[sequence_id],
							[member_code],
							[check_num],
							[conv_check_amount],
							[date_entered])
						SELECT
							2,
							p.[contract_ctrl_num],
							p.[sequence_id], ' +
							@mem_code + ', ' +
						'	[check_num],
							CASE WHEN UPPER("' + @currency_type + '") = "HOME" THEN home_amount ELSE oper_amount END,
							p.date_entered
						FROM pr_customer_payments p, ' + @tableh + ' h 
						WHERE	p.contract_ctrl_num = h.contract_ctrl_num
						AND p.' + @mem_code + ' = h.member_code 
						AND [void_flag] = 0 ' )
	ELSE
	
		EXEC(	'	INSERT ' + @tabled +
					'(	[detail_type],
							[contract_ctrl_num],
							[sequence_id],
							[member_code],
							[check_num],
							[conv_check_amount],
							[date_entered])
						SELECT
							2,
							p.[contract_ctrl_num],
							p.[sequence_id], ' +
							@mem_code + ', ' +
						'	[check_num],
							CASE WHEN UPPER("' + @currency_type + '") = "HOME" THEN home_amount ELSE oper_amount END,
							p.date_entered
						FROM pr_vendor_payments p, ' + @tableh + ' h 
						WHERE	p.contract_ctrl_num = h.contract_ctrl_num
						AND p.' + @mem_code + ' = h.member_code 
						AND [void_flag] = 0 ' )


	IF @member_type = 0
		EXEC(	'	UPDATE ' + @tableh +
					'	SET member_name = customer_name,
								member_type = 0
						FROM	arcust c, ' + @tableh + ' t
						WHERE	c.customer_code = t.member_code ' )
	ELSE	
		EXEC(	'	UPDATE ' + @tableh +
					'	SET member_name = vendor_name,
								member_type = 1
						FROM	apvend v, ' + @tableh + ' t
						WHERE	v.vendor_code = t.member_code ' )




EXEC('SELECT * FROM ' + @tableh )
EXEC('SELECT * FROM ' + @tabled )


GO
GRANT EXECUTE ON  [dbo].[pr_rpt_balance_due_sp] TO [public]
GO
