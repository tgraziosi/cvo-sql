SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_detail_custom_age_sp] 	@agebrk_user_id	 		 	varchar(5) = '',
																				@user_name	varchar(30) = '',
																				@company_db	varchar(30) = ''
 	

AS
	SET NOCOUNT ON
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db
 	
	DECLARE	@date_asof		int,
		@e_age_bracket_1	smallint,
		@e_age_bracket_2	smallint,
		@e_age_bracket_3	smallint,
		@e_age_bracket_4	smallint,
		@e_age_bracket_5	smallint,
		@e_age_bracket_6	smallint,
		@e_age_bracket_7	smallint,
		@e_age_bracket_8	smallint,
		@e_age_bracket_9	smallint,
		@b_age_bracket_2	smallint,
		@b_age_bracket_3	smallint,
		@b_age_bracket_4	smallint,
		@b_age_bracket_5	smallint,
		@b_age_bracket_6	smallint,
		@b_age_bracket_7	smallint,
		@b_age_bracket_8	smallint,
		@b_age_bracket_9	smallint,
		@b_age_bracket_10	smallint,
		@precision_home		smallint,
		@home_symbol			varchar(8),
		@home_currency		varchar(8),
		@multi_currency_flag	smallint,
		@date_type_string	varchar(25),
		@date_type_conv		tinyint,
		@where_clause		varchar(255),
		@date_where_clause	varchar(255),
		@str_age_bracket_1	varchar(20),
		@str_age_bracket_2	varchar(20),
		@str_age_bracket_3	varchar(20),
		@str_age_bracket_4	varchar(20),
		@str_age_bracket_5	varchar(20),
		@str_age_bracket_6	varchar(20),
		@str_age_bracket_7	varchar(20),
		@str_age_bracket_8	varchar(20),
		@str_age_bracket_9	varchar(20),
		@str_age_bracket_10	varchar(20),
		@company_name		varchar(30),
		@on_acct_string		varchar(20),
		@date_var		varchar(20),
		@balance_over_str1	varchar(60),
		@balance_over_str2	varchar(60),
		@balance_over_str3	varchar(60),
		@plat_date_str		varchar(20),
		@where_clause2		varchar(255),
		@terr_where_clause	varchar(255),
		@inc_future_str		varchar(40),

		@precision_oper		smallint,
		@oper_currency		varchar(8),
		@oper_symbol			varchar(8),
		@trx_terr_where_clause			varchar(255),

		@from_cust		varchar(8),
		@thru_cust		varchar(8),
		@from_terr		varchar(8),
		@thru_terr		varchar(8),
		@date_type_parm		smallint,
		@balance_over		smallint,
		@from_name		varchar(40),
		@thru_name		varchar(40),
		@exclude_on_accts	smallint,
		@all_cust_flag		smallint,
		@all_terr_flag		smallint,
		@all_name_flag		smallint,
		@balance_over_amt	decimal(28,2),
		@sequence		smallint,
		@str_date_asof		varchar(10),
		@bal_over_flag		smallint,
		@days_over_flag		smallint,
		@bal_over_operand	varchar(1),
		@days_over_operand	varchar(1),
		@days_over_num		smallint,
		@meet_cond		smallint,
		@all_post_flag		smallint,
		@from_post		varchar(8),		@thru_post		varchar(8),
		@all_workload_flag	smallint,
		@from_workload		varchar(8),		@thru_workload		varchar(8),
		@include_comments	smallint,		@inc_future		smallint,
		@terr_from_cust		smallint,
		@print_all_comments	smallint,
		@currency_basis		smallint,
		@all_org_flag	smallint,
		@from_org	varchar(30),
		@thru_org	varchar(30),
		@where_clause_org		varchar(255)


	SELECT	@from_cust 					= 		from_cust,
					@thru_cust 					= 		thru_cust,
					@from_terr 					= 		from_terr,
					@thru_terr 					= 		thru_terr,
					@date_type_parm 		= 		date_type_parm,
					@balance_over 			= 		balance_over,
					@from_name 					= 		from_name,
					@thru_name 					= 		thru_name,
					@exclude_on_accts 	= 		exclude_on_accts,
					@all_cust_flag 			= 		all_cust_flag,
					@all_terr_flag 			= 		all_terr_flag,
					@all_name_flag 			= 		all_name_flag,
					@balance_over_amt 	= 		balance_over_amt,
					@sequence 					= 		[sequence],
					@str_date_asof 			= 		str_date_asof,
					@bal_over_flag 			= 		bal_over_flag,
					@days_over_flag 		= 		days_over_flag,
					@bal_over_operand 	= 		bal_over_operand,
					@days_over_operand 	= 		days_over_operand,
					@days_over_num 			= 		days_over_num,
					@meet_cond 					= 		meet_cond,
					@all_post_flag 			= 		all_post_flag,
					@from_post 					= 		from_post,
					@thru_post 					= 		thru_post,
					@all_workload_flag 	= 		all_workload_flag,
					@from_workload 			= 		from_workload,
					@thru_workload 			= 		thru_workload,
					@include_comments 	= 		include_comments,
					@inc_future 				= 		inc_future,
					@terr_from_cust 		= 		terr_from_cust,
					@print_all_comments = 		print_all_comments,
					@currency_basis 		= 		currency_basis,
					@all_org_flag				=			all_org_flag,
					@from_org						=			from_org,
					@thru_org						=			thru_org
	FROM 		cc_custom_aging_params
	WHERE 	CONVERT(	 	varchar(5),agebrk_user_id) = @agebrk_user_id





	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@str_date_asof))), 0) = 0 OR @str_date_asof = '0'
		SELECT 	@date_asof = DATEDIFF(dd, "1/1/1753", CONVERT(datetime, getdate())) + 639906
	ELSE
		SELECT 	@date_asof = DATEDIFF(dd, "1/1/1753", CONVERT(datetime, @str_date_asof )) + 639906

	SELECT @plat_date_str = convert(varchar(20), @date_asof)

	IF @inc_future = 1
		SELECT @inc_future_str = "Include Future Transactions"


	SELECT @date_type_conv = @date_type_parm


	IF @date_type_conv = 1
		BEGIN
			SELECT @date_type_string = "Document Date"
			SELECT @date_var = "b.date_doc"			
		END	
	ELSE IF @date_type_conv = 2
		BEGIN
			SELECT @date_type_string = "Apply Date"
			SELECT @date_var = "b.date_applied"
		END	
	ELSE IF @date_type_conv = 4
		BEGIN
			SELECT @date_type_string = "Due Date"
			SELECT @date_var = "b.date_due"
		END	
	ELSE 
		BEGIN
			SELECT @date_type_string = "Aging Date"
			SELECT @date_var = "b.date_aging"
		END	



SELECT @where_clause = ' 0 = 0 '




	IF	@all_cust_flag = 0
		BEGIN
			
			IF ( ( SELECT CHARINDEX( "_", @from_cust ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_cust ) ) = 0 )
			 
				SELECT @where_clause = @where_clause + " AND ( ( c.customer_code >= '" + @from_cust + "' "
			ELSE
				SELECT @where_clause = @where_clause + " AND ( ( c.customer_code LIKE '" + @from_cust + "' "
		
			IF ( ( SELECT CHARINDEX( "_", @thru_cust ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @thru_cust ) ) = 0 )
				SELECT @where_clause = @where_clause + " AND c.customer_code <= '" + @thru_cust + "' ) )"
			ELSE
				SELECT @where_clause = @where_clause + " AND c.customer_code LIKE '" + @thru_cust + "' ) )"
		END 

 







	SELECT @terr_where_clause = '0 = 0'
 SELECT @trx_terr_where_clause = '0 = 0'
	IF ( @all_terr_flag = 0	AND @terr_from_cust = 1 )
		BEGIN
			
			IF ( ( SELECT CHARINDEX( "_", @from_terr ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_terr ) ) = 0 )
				SELECT @terr_where_clause = @terr_where_clause + " AND ( ( c.territory_code >= '" + @from_terr + "' "
			ELSE
				SELECT @terr_where_clause = @terr_where_clause + " AND ( ( c.territory_code LIKE '" + @from_terr + "' "

			IF ( ( SELECT CHARINDEX( "_", @thru_terr ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @thru_terr ) ) = 0 )
				SELECT @terr_where_clause = @terr_where_clause + " AND c.territory_code <= '" + @thru_terr + "' ) )"
			ELSE
				SELECT @terr_where_clause = @terr_where_clause + " AND c.territory_code LIKE '" + @thru_terr + "' ) )"
		END


	IF ( @all_terr_flag = 0	AND @terr_from_cust = 0 )
		BEGIN
			IF ( ( SELECT CHARINDEX( "_", @from_terr ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_terr ) ) = 0 )
				SELECT @terr_where_clause = @terr_where_clause + " AND c.customer_code IN ( SELECT customer_code FROM artrx WHERE  ( territory_code >= '" + @from_terr + "' "
			ELSE
				SELECT @terr_where_clause = @terr_where_clause + " AND c.customer_code IN ( SELECT customer_code FROM artrx WHERE  ( territory_code LIKE '" + @from_terr + "' "

			IF ( ( SELECT CHARINDEX( "_", @thru_terr ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @thru_terr ) ) = 0 )
				SELECT @terr_where_clause = @terr_where_clause + " AND c.territory_code <= '" + @thru_terr + "' ) )"
			ELSE
				SELECT @terr_where_clause = @terr_where_clause + " AND c.territory_code LIKE '" + @thru_terr + "' ) )"

			SELECT @trx_terr_where_clause = REPLACE (@terr_where_clause, 'c.customer_code', 'a.trx_ctrl_num')
			SELECT @trx_terr_where_clause = REPLACE (@trx_terr_where_clause, 'customer_code', 'trx_ctrl_num')

			SELECT @trx_terr_where_clause = REPLACE (@trx_terr_where_clause, 'c.territory_code', 'a.territory_code')
		END

	IF @all_name_flag = 0
		BEGIN
			
			IF ( ( SELECT CHARINDEX( "_", @from_name ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_name ) ) = 0 )
				SELECT @where_clause = @where_clause + " AND ( ( customer_name >= '" + @from_name + "' " 
			ELSE
				SELECT @where_clause = @where_clause + " AND ( ( customer_name LIKE '" + @from_name + "' " 

			IF ( ( SELECT CHARINDEX( "_", @thru_name ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @thru_name ) ) = 0 )
				SELECT @where_clause = @where_clause + " AND customer_name <= '" + @thru_name + "' ) )"
			ELSE
				SELECT @where_clause = @where_clause + " AND customer_name LIKE '" + @thru_name + "' ) ) "
		END

	IF @all_post_flag = 0
		BEGIN
			
			IF ( ( SELECT CHARINDEX( "_", @from_post ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_post ) ) = 0 )
				SELECT @where_clause = @where_clause + " AND ( ( posting_code >= '" + @from_post + "' "
			ELSE
				SELECT @where_clause = @where_clause + " AND ( ( posting_code LIKE '" + @from_post + "' "

			IF ( ( SELECT CHARINDEX( "_", @thru_post ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @thru_post ) ) = 0 )
				SELECT @where_clause = @where_clause + " AND posting_code <= '" + @thru_post + "' ) )"
			ELSE
				SELECT @where_clause = @where_clause + " AND posting_code LIKE '" + @thru_post + "' ) )"
		END

	SELECT @where_clause2 = ''

	IF @all_workload_flag = 0
		BEGIN
			
			IF ( ( SELECT CHARINDEX( "_", @from_workload ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_workload ) ) = 0 )
				SELECT @where_clause2 = " AND ( ( workload_code >= '" + @from_workload + "' "
			ELSE
				SELECT @where_clause2 = " AND ( ( workload_code LIKE '" + @from_workload + "' " 

			IF ( ( SELECT CHARINDEX( "_", @thru_workload ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @thru_workload ) ) = 0 )
				SELECT @where_clause2 = @where_clause2 + " AND workload_code <= '" + @thru_workload + "' ) )"
			ELSE
				SELECT @where_clause2 = " AND workload_code LIKE '" + @thru_workload + "' ) )"
		END


	SELECT @where_clause_org = ' 0 = 0 '

	IF @all_org_flag = 0
		BEGIN
			
			IF ( ( SELECT CHARINDEX( "_", @from_org ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_org ) ) = 0 )
				SELECT @where_clause_org = @where_clause_org + " AND ( ( org_id >= '" + @from_org + "' "
			ELSE
				SELECT @where_clause_org = @where_clause_org + " AND ( ( org_id LIKE '" + @from_org + "' " 

			IF ( ( SELECT CHARINDEX( "_", @thru_org ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @thru_org ) ) = 0 )
				SELECT @where_clause_org = @where_clause_org + " AND org_id <= '" + @thru_org + "' ) )"
			ELSE
				SELECT @where_clause_org = @where_clause_org + " AND org_id LIKE '" + @thru_org + "' ) )"
		END
		

				
	SELECT	@precision_home 	= curr_precision,
		@multi_currency_flag 	= multi_currency_flag,
		@home_currency 		= home_currency,
		@home_symbol 		= symbol,
		@company_name		= company_name
	FROM	glcurr_vw, glco
	WHERE	glco.home_currency 	= glcurr_vw.currency_code


	SELECT	@precision_oper 	= curr_precision,
		@oper_currency 		= home_currency,
		@oper_symbol 		= symbol
	FROM	glcurr_vw, glco
	WHERE	glco.oper_currency 	= glcurr_vw.currency_code



IF ( SELECT COUNT(*) FROM ccagebrk WHERE [user_id] = @agebrk_user_id ) > 0
	SELECT 	@e_age_bracket_1 	= age_bracket1,
					@e_age_bracket_2 	= age_bracket2,
					@e_age_bracket_3 	= age_bracket3,
					@e_age_bracket_4 	= age_bracket4,
					@e_age_bracket_5 	= age_bracket5,
					@e_age_bracket_6 	= age_bracket6,
					@e_age_bracket_7 	= age_bracket7,
					@e_age_bracket_8 	= age_bracket8,
					@e_age_bracket_9 	= age_bracket9 
	FROM ccagebrk
	WHERE [user_id] = @agebrk_user_id
ELSE
	SELECT 	@e_age_bracket_1 	= age_bracket1,
					@e_age_bracket_2 	= age_bracket2,
					@e_age_bracket_3 	= age_bracket3,
					@e_age_bracket_4 	= age_bracket4,
					@e_age_bracket_5 	= age_bracket5,
					@e_age_bracket_6 	= age_bracket6,
					@e_age_bracket_7 	= age_bracket7,
					@e_age_bracket_8 	= age_bracket8,
					@e_age_bracket_9 	= age_bracket9 
	FROM ccagebrk
	WHERE [user_id] = 0


	SELECT 	@b_age_bracket_2 	= @e_age_bracket_1 + 1,
		@b_age_bracket_3 	= @e_age_bracket_2 + 1,
		@b_age_bracket_4 	= @e_age_bracket_3 + 1,
		@b_age_bracket_5 	= @e_age_bracket_4 + 1,
		@b_age_bracket_6 	= @e_age_bracket_5 + 1, 
		@b_age_bracket_7 	= @e_age_bracket_6 + 1, 
		@b_age_bracket_8 	= @e_age_bracket_7 + 1, 
		@b_age_bracket_9 	= @e_age_bracket_8 + 1, 
		@b_age_bracket_10 	= @e_age_bracket_9 + 1 


	CREATE TABLE #artrxage_tmp
	(
		trx_type 		smallint	NULL, 
		trx_ctrl_num 		varchar(16)	NULL, 
		doc_ctrl_num 		varchar(16)	NULL, 
		apply_to_num 		varchar(16)	NULL, 
		apply_trx_type 		smallint	NULL, 
		sub_apply_num 		varchar(16)	NULL, 
		sub_apply_type 		smallint	NULL, 
		territory_code 		varchar(8)	NULL, 
		date_doc 		int		NULL, 
		date_due 		int		NULL, 
		date_aging 		int		NULL, 
		date_applied 		int		NULL, 
		amount 			float		NULL,	
		amt_age_bracket1	float		NULL,	
		amt_age_bracket2 	float		NULL,
		amt_age_bracket3	float		NULL,
		amt_age_bracket4	float		NULL,
		amt_age_bracket5	float		NULL,
		amt_age_bracket6	float		NULL,		 
		amt_age_bracket7	float		NULL,		 
		amt_age_bracket8	float		NULL,		 
		amt_age_bracket9	float		NULL,		 
		amt_age_bracket10	float		NULL,		 
		nat_cur_code 		varchar(8)	NULL, 
		rate_home 		float		NULL, 
		rate_type 		varchar(8)	NULL, 
		customer_code 		varchar(8)	NULL, 
		payer_cust_code 	varchar(8)	NULL, 
		trx_type_code 		varchar(8)	NULL, 
		ref_id 			int		NULL,
		company_name		varchar(30)	NULL,
		cust_po_num		varchar(20)	NULL,
		paid_flag		smallint	NULL,
		report_comment		varchar(255) 	NULL,
		rate_oper 		float		NULL,
		territory_desc		varchar(40)	NULL ,
		print_all_comments	smallint NULL,
 		org_id	varchar(30) NULL
	)


		
	CREATE TABLE #non_zero_records
	(
		doc_ctrl_num 		varchar(16)	NULL, 
		trx_type 		smallint	NULL, 
		customer_code 		varchar(8)	NULL, 
		total 			float		NULL
	)



	CREATE TABLE #customers
	(
		customer_code		varchar(8), territory_code varchar(8)
	)


	IF @all_workload_flag = 0

			EXEC	("INSERT #customers
			SELECT 	c.customer_code, c.territory_code
			FROM 	arcust c, ccwrkmem m	
			WHERE "	+ @where_clause + " " + @where_clause2 + " AND " + @terr_where_clause +
			" AND c.customer_code = m.customer_code ")
	ELSE

			EXEC	("INSERT #customers
			SELECT 	c.customer_code, c.territory_code
			FROM 	arcust c
			WHERE "	+ @where_clause + " AND " + @terr_where_clause )



	IF ( @terr_from_cust = 0 )
		SELECT @terr_where_clause = REPLACE (@terr_where_clause, 'c.territory_code', 'a.territory_code')




	IF @balance_over = 1	
	 	BEGIN
			EXEC( '	INSERT #non_zero_records
							SELECT 	apply_to_num , 
											apply_trx_type, 
											a.customer_code, 
											SUM(amount) 
							FROM 	artrxage a, #customers c
							WHERE 	a.customer_code = c.customer_code
							AND ' + @terr_where_clause +
						'	AND ' + @where_clause_org +
						'	GROUP BY a.customer_code, apply_to_num, apply_trx_type ' )
		END
	ELSE	

		IF @inc_future = 1
		 	BEGIN
				EXEC( '	INSERT #non_zero_records
								SELECT 	apply_to_num , 
												apply_trx_type, 
												a.customer_code, 
												SUM(amount) 
								FROM 	artrxage a, #customers c
								WHERE 	a.customer_code = c.customer_code
								AND ' + @terr_where_clause +
							'	AND ' + @where_clause_org +
							'	GROUP BY a.customer_code, apply_to_num, apply_trx_type
								HAVING ABS(SUM(amount)) > 0.0000001 ' )
			END
		ELSE
		 	BEGIN
			EXEC( '	INSERT #non_zero_records
							SELECT 	apply_to_num , 
											apply_trx_type, 
											a.customer_code, 
											SUM(amount) 
							FROM 	artrxage a, #customers c
							WHERE 	a.customer_code = c.customer_code
							AND	date_applied <= ' + @plat_date_str +
						'	AND ' + @terr_where_clause +
						'	AND ' + @where_clause_org +
						'	GROUP BY a.customer_code, apply_to_num, apply_trx_type 
							HAVING ABS(SUM(amount)) > 0.0000001	' )
			END









	IF @inc_future = 1
		EXEC (	' INSERT #artrxage_tmp ( trx_type, trx_ctrl_num, doc_ctrl_num, apply_to_num, apply_trx_type, sub_apply_num, sub_apply_type, territory_code, date_doc, date_due, date_aging, date_applied, amount, amt_age_bracket1, amt_age_bracket2, amt_age_bracket3, amt_age_bracket4, amt_age_bracket5, amt_age_bracket6, amt_age_bracket7, amt_age_bracket8, amt_age_bracket9, amt_age_bracket10, nat_cur_code, rate_home, rate_type, customer_code, payer_cust_code, trx_type_code, ref_id, company_name, cust_po_num, paid_flag, rate_oper, org_id )
							SELECT	a.trx_type, 
											a.trx_ctrl_num, 
											a.doc_ctrl_num, 
											a.apply_to_num, 
											a.apply_trx_type, 
											a.sub_apply_num, 
											a.sub_apply_type, 
											a.territory_code, 
											a.date_doc, 
											(1+ sign(sign(a.ref_id) - 1))*a.date_due + abs(sign(sign(a.ref_id)-1))*a.date_doc, 
											(1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc, 
											a.date_applied, 
											a.amount, 
											0,
											0,
											0,
											0,
											0,
											0,
											0,
											0,
											0,
											0,
											a.nat_cur_code, 
											a.rate_home, 
											" ", 
											a.customer_code, 
											a.payer_cust_code, 
											" ", 
											a.ref_id, "' +
											@company_name + '",
											cust_po_num,
											paid_flag,
											a.rate_oper,
											org_id
								FROM 	artrxage a,#non_zero_records c 
								WHERE a.apply_to_num = c.doc_ctrl_num 
								AND 	a.apply_trx_type = c.trx_type 
								AND 	a.customer_code = c.customer_code
								AND ' + @trx_terr_where_clause )
	ELSE
		EXEC (	' INSERT #artrxage_tmp ( trx_type, trx_ctrl_num, doc_ctrl_num, apply_to_num, apply_trx_type, sub_apply_num, sub_apply_type, territory_code, date_doc, date_due, date_aging, date_applied, amount, amt_age_bracket1, amt_age_bracket2, amt_age_bracket3, amt_age_bracket4, amt_age_bracket5, amt_age_bracket6, amt_age_bracket7, amt_age_bracket8, amt_age_bracket9, amt_age_bracket10, nat_cur_code, rate_home, rate_type, customer_code, payer_cust_code, trx_type_code, ref_id, company_name, cust_po_num, paid_flag, rate_oper, org_id )
							SELECT	a.trx_type, 
											a.trx_ctrl_num, 
											a.doc_ctrl_num, 
											a.apply_to_num, 
											a.apply_trx_type, 
											a.sub_apply_num, 
											a.sub_apply_type, 
											a.territory_code, 
											a.date_doc, 
											(1+ sign(sign(a.ref_id) - 1))*a.date_due + abs(sign(sign(a.ref_id)-1))*a.date_doc, 
											(1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc, 
											a.date_applied, 
											a.amount, 
											0,
											0,
											0,
											0,
											0,
											0,
											0,
											0,
											0,
											0,
											a.nat_cur_code, 
											a.rate_home, 
											" ", 
											a.customer_code, 
											a.payer_cust_code, 
											" ", 
											a.ref_id, "' +
											@company_name + '",
											cust_po_num,
											paid_flag,
											a.rate_oper,
											org_id
								FROM 	artrxage a,#non_zero_records c 
								WHERE a.apply_to_num = c.doc_ctrl_num 
								AND 	a.apply_trx_type = c.trx_type 
								AND 	a.customer_code = c.customer_code 
								AND ' + @trx_terr_where_clause +
							'	AND	date_applied <= ' + @plat_date_str )
					
			

		IF @terr_from_cust = 1
			UPDATE #artrxage_tmp
			SET territory_code = c.territory_code
			FROM #artrxage_tmp a, arcust c
			WHERE 	a.customer_code = c.customer_code 
			


	IF @exclude_on_accts = 1
		DELETE	#artrxage_tmp 
		WHERE	ref_id <= 0






	UPDATE #artrxage_tmp 
	SET date_due = b.date_due
	FROM #artrxage_tmp , #artrxage_tmp b
	WHERE #artrxage_tmp.doc_ctrl_num = b.doc_ctrl_num
	AND #artrxage_tmp.ref_id = -1
	AND b.ref_id = 0
	AND #artrxage_tmp.date_due = 0

	UPDATE #artrxage_tmp 
	SET date_doc = b.date_doc
	FROM #artrxage_tmp , #artrxage_tmp b
	WHERE #artrxage_tmp.doc_ctrl_num = b.doc_ctrl_num
	AND #artrxage_tmp.ref_id = -1
	AND b.ref_id = 0
	AND #artrxage_tmp.date_doc = 0

	UPDATE #artrxage_tmp 
	SET date_aging = b.date_aging
	FROM #artrxage_tmp , #artrxage_tmp b
	WHERE #artrxage_tmp.doc_ctrl_num = b.doc_ctrl_num
	AND #artrxage_tmp.ref_id = -1
	AND b.ref_id = 0
	AND #artrxage_tmp.date_aging = 0

	UPDATE #artrxage_tmp 
	SET date_applied = b.date_applied
	FROM #artrxage_tmp , #artrxage_tmp b
	WHERE #artrxage_tmp.doc_ctrl_num = b.doc_ctrl_num
	AND #artrxage_tmp.ref_id = -1
	AND b.ref_id = 0
	AND #artrxage_tmp.date_applied = 0





	IF ( @bal_over_flag + @days_over_flag > 0 )
		BEGIN
			CREATE TABLE 	#customers_to_print 
			(		customer_code varchar(8), 
					balance_home float, 
					balance_oper float, 
					limit_by_home smallint, 	
					bal_flag smallint,
					days_flag	smallint
			) 
			


			INSERT #customers_to_print 
			SELECT DISTINCT	a.customer_code, 
					0.0, 
					0.0, 
					b.limit_by_home, 
					0,
					0 
			FROM #artrxage_tmp a, arcust b 
			WHERE a.customer_code = b.customer_code 

			CREATE CLUSTERED INDEX tmp_cus_pr_ind1 on #customers_to_print (customer_code) 


			UPDATE #customers_to_print 
			SET 	balance_home = (SELECT ISNULL(SUM(ROUND(b.amount * ( SIGN(1 + SIGN(b.rate_home))*(b.rate_home) + (SIGN(ABS(SIGN(ROUND(b.rate_home,6))))/(b.rate_home + SIGN(1 - ABS(SIGN(ROUND(b.rate_home,6)))))) * SIGN(SIGN(b.rate_home) - 1) ),2)),0.0) 
						 FROM #artrxage_tmp b 
						 WHERE b.customer_code = a.customer_code), 
						balance_oper = (SELECT ISNULL(SUM(ROUND(b.amount * ( SIGN(1 + SIGN(b.rate_oper))*(b.rate_oper) + (SIGN(ABS(SIGN(ROUND(b.rate_oper,6))))/(b.rate_oper + SIGN(1 - ABS(SIGN(ROUND(b.rate_oper,6)))))) * SIGN(SIGN(b.rate_oper) - 1) ),2)),0.0) 
						 FROM #artrxage_tmp b 
						 WHERE b.customer_code = a.customer_code) 
			FROM 	#customers_to_print a 


			IF ( @bal_over_flag = 1 AND @meet_cond = 1 )
					EXEC (" UPDATE #customers_to_print 
						SET bal_flag = 1 
						FROM #customers_to_print 
						WHERE ROUND(SIGN(1 ) * balance_home,2) + ROUND(SIGN(1 - 1) * balance_oper,2) " + @bal_over_operand + " " + @balance_over_amt ) 

			IF ( ( @bal_over_flag = 1 AND @meet_cond = 0 ) OR ( @bal_over_flag = 0 ) )
				EXEC (" UPDATE #customers_to_print
				SET bal_flag = 1
				FROM #customers_to_print a " )

			IF ( @days_over_flag = 1 AND @meet_cond = 1 )
				EXEC (" UPDATE #customers_to_print

							SET days_flag = 4
							FROM #customers_to_print a
							WHERE EXISTS 	(SELECT * FROM #artrxage_tmp b
									 WHERE 	b.doc_ctrl_num = b.sub_apply_num
									 AND 	b.trx_type = b.sub_apply_type
									 AND 	b.customer_code = a.customer_code
									 AND 	" + @plat_date_str + " - " + @date_var + " " + @days_over_operand + " " + @days_over_num + " ) " )

			IF ( ( @days_over_flag = 1 AND @meet_cond = 0 ) OR ( @days_over_flag = 0 ) )
				EXEC (" UPDATE #customers_to_print

							SET days_flag = 4
							FROM #customers_to_print a " )





				DELETE 	#artrxage_tmp
				FROM	#customers_to_print a
				WHERE	#artrxage_tmp.customer_code = a.customer_code

				AND	bal_flag + days_flag <> 5





				
				
			DROP TABLE #customers_to_print
		END


	UPDATE #artrxage_tmp 
	SET trx_type_code = b.trx_type_code 
	FROM artrxtyp b 
	WHERE #artrxage_tmp.trx_type = b.trx_type 


		

	IF @currency_basis = 0
		UPDATE #artrxage_tmp
		SET amount = (SELECT ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home))
	ELSE
		UPDATE #artrxage_tmp
		SET amount = (SELECT ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper))



		

	IF @date_type_conv = 1
		BEGIN	
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket1 = amount
			WHERE 	(@date_asof - date_doc) <= @e_age_bracket_1

			UPDATE 	#artrxage_tmp
			SET 	amt_age_bracket2 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_2 
			AND 	(@date_asof - date_doc) <= @e_age_bracket_2

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket3 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_3 
			AND 	(@date_asof - date_doc) <= @e_age_bracket_3

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket4 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_4 
			AND 	(@date_asof - date_doc) <= @e_age_bracket_4

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket5 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_5 
			AND 	(@date_asof - date_doc) <= @e_age_bracket_5
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket6 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_6 
			AND 	(@date_asof - date_doc) <= @e_age_bracket_6
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket7 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_7 
			AND 	(@date_asof - date_doc) <= @e_age_bracket_7
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket8 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_8 
			AND 	(@date_asof - date_doc) <= @e_age_bracket_8
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket9 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_9 
			AND 	(@date_asof - date_doc) <= @e_age_bracket_9
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket10 = amount
			WHERE 	(@date_asof - date_doc) >= @b_age_bracket_10
		END

	ELSE IF @date_type_conv = 2
		BEGIN	
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket1 = amount
			WHERE 	(@date_asof - date_applied) <= @e_age_bracket_1

			UPDATE 	#artrxage_tmp
			SET 	amt_age_bracket2 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_2 
			AND 	(@date_asof - date_applied) <= @e_age_bracket_2

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket3 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_3 
			AND 	(@date_asof - date_applied) <= @e_age_bracket_3

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket4 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_4 
			AND 	(@date_asof - date_applied) <= @e_age_bracket_4

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket5 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_5 
			AND 	(@date_asof - date_applied) <= @e_age_bracket_5
		
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket6 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_6 
			AND 	(@date_asof - date_applied) <= @e_age_bracket_6
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket7 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_7 
			AND 	(@date_asof - date_applied) <= @e_age_bracket_7
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket8 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_8 
			AND 	(@date_asof - date_applied) <= @e_age_bracket_8
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket9 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_9 
			AND 	(@date_asof - date_applied) <= @e_age_bracket_9
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket10 = amount
			WHERE 	(@date_asof - date_applied) >= @b_age_bracket_10
		END

	ELSE IF @date_type_conv = 3
		BEGIN	
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket1 = amount
			WHERE 	(@date_asof - date_aging) <= @e_age_bracket_1

			UPDATE 	#artrxage_tmp
			SET 	amt_age_bracket2 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_2 
			AND 	(@date_asof - date_aging) <= @e_age_bracket_2

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket3 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_3 
			AND 	(@date_asof - date_aging) <= @e_age_bracket_3

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket4 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_4 
			AND 	(@date_asof - date_aging) <= @e_age_bracket_4

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket5 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_5 
			AND 	(@date_asof - date_aging) <= @e_age_bracket_5
	
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket6 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_6 
			AND 	(@date_asof - date_aging) <= @e_age_bracket_6
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket7 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_7 
			AND 	(@date_asof - date_aging) <= @e_age_bracket_7
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket8 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_8 
			AND 	(@date_asof - date_aging) <= @e_age_bracket_8
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket9 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_9 
			AND 	(@date_asof - date_aging) <= @e_age_bracket_9
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket10 = amount
			WHERE 	(@date_asof - date_aging) >= @b_age_bracket_10
		END

	ELSE IF @date_type_conv = 4
		BEGIN	
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket1 = amount
			WHERE 	(@date_asof - date_due) <= @e_age_bracket_1

			UPDATE 	#artrxage_tmp
			SET 	amt_age_bracket2 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_2 
			AND 	(@date_asof - date_due) <= @e_age_bracket_2

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket3 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_3 
			AND 	(@date_asof - date_due) <= @e_age_bracket_3

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket4 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_4 
			AND 	(@date_asof - date_due) <= @e_age_bracket_4

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket5 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_5 
			AND 	(@date_asof - date_due) <= @e_age_bracket_5
		
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket6 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_6 
			AND 	(@date_asof - date_due) <= @e_age_bracket_6
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket7 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_7 
			AND 	(@date_asof - date_due) <= @e_age_bracket_7
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket8 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_8 
			AND 	(@date_asof - date_due) <= @e_age_bracket_8
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket9 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_9 
			AND 	(@date_asof - date_due) <= @e_age_bracket_9
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket10 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_10
		END

	


 				 
	SELECT @str_age_bracket_1 = "Under  " + LTRIM(STR(@e_age_bracket_1))+ " Days"
	SELECT @str_age_bracket_2 = LTRIM(STR(@b_age_bracket_2)) + " - " + LTRIM(STR(@e_age_bracket_2)) + " Days"
	SELECT @str_age_bracket_3 = LTRIM(STR(@b_age_bracket_3)) + " - " + LTRIM(STR(@e_age_bracket_3)) + " Days"
	SELECT @str_age_bracket_4 = LTRIM(STR(@b_age_bracket_4)) + " - " + LTRIM(STR(@e_age_bracket_4)) + " Days"
	SELECT @str_age_bracket_5 = LTRIM(STR(@b_age_bracket_5)) + " - " + LTRIM(STR(@e_age_bracket_5)) + " Days"
	SELECT @str_age_bracket_6 = LTRIM(STR(@b_age_bracket_6)) + " - " + LTRIM(STR(@e_age_bracket_6)) + " Days"
	SELECT @str_age_bracket_7 = LTRIM(STR(@b_age_bracket_7)) + " - " + LTRIM(STR(@e_age_bracket_7)) + " Days"
	SELECT @str_age_bracket_8 = LTRIM(STR(@b_age_bracket_8)) + " - " + LTRIM(STR(@e_age_bracket_8)) + " Days"
	SELECT @str_age_bracket_9 = LTRIM(STR(@b_age_bracket_9)) + " - " + LTRIM(STR(@e_age_bracket_9)) + " Days"
	SELECT @str_age_bracket_10 = "Over  " + LTRIM(STR(@e_age_bracket_9))+ " Days"



	IF ( ISNULL( DATALENGTH( RTRIM( LTRIM( @from_terr ))), 0 ) = 0 ) 
		SELECT @from_terr = min(territory_code) FROM arterr where territory_code IS NOT NULL
	IF ( ISNULL( DATALENGTH( RTRIM( LTRIM( @thru_terr ))), 0 ) = 0 )
		SELECT @thru_terr = max(territory_code) FROM arterr
	IF ( ISNULL( DATALENGTH( RTRIM( LTRIM( @from_name ))), 0 ) = 0 )
		SELECT @from_name = min(customer_name) FROM arcust where customer_name IS NOT NULL
	IF ( ISNULL( DATALENGTH( RTRIM( LTRIM( @thru_name ))), 0 ) = 0 )
		SELECT @thru_name = max(customer_name) FROM arcust

	IF @exclude_on_accts = 0
		SELECT @on_acct_string = "Include On Accounts"
	ELSE
		SELECT @on_acct_string = "Exclude On Accounts"




	IF @include_comments = 1
	UPDATE 	#artrxage_tmp
	SET	report_comment = comment
	FROM	#artrxage_tmp t, cc_rpt_comments r
	WHERE	t.customer_code = r.customer_code



	IF @balance_over = 0
		SELECT @balance_over_str1 = " Open Invoices Only"
	ELSE 
		SELECT @balance_over_str1 = " Include Paid in Full"

	IF @bal_over_flag = 1

		SELECT @balance_over_str2 = " Customer Balance " + @bal_over_operand + " " + CONVERT(varchar(30), @balance_over_amt )
	ELSE
		SELECT @balance_over_str2 = "" 
	
	IF @days_over_flag = 1

		SELECT @balance_over_str3 = " Customer Balance " + @days_over_operand + " " + CONVERT(varchar(30), @days_over_num ) + " Days"
	ELSE
		SELECT @balance_over_str3 = ""


	UPDATE #artrxage_tmp
	SET	territory_desc = t.territory_desc
	FROM	#artrxage_tmp s, arterr t
	WHERE	s.territory_code = t.territory_code




 	IF @print_all_comments = 1
		BEGIN
			DECLARE @last_cust varchar(8), @comment_count int
			SELECT @last_cust = MIN(customer_code) FROM #artrxage_tmp
			WHILE @last_cust IS NOT NULL
				BEGIN
					SELECT @comment_count = COUNT(*) FROM cc_comments WHERE customer_code = @last_cust

					UPDATE 	#artrxage_tmp
					SET	print_all_comments = ISNULL(@comment_count,0)
					WHERE	customer_code = @last_cust

					SELECT @last_cust = MIN(customer_code) FROM #artrxage_tmp WHERE customer_code > @last_cust
				END
		END




	IF @sequence = 1
		SELECT 	c.customer_code,
			t.territory_code,
			'customer_name' = address_name, 			 
			'total_home' = amount, 
			amt_age_bracket1,
			amt_age_bracket2,
			amt_age_bracket3,
			amt_age_bracket4,
			amt_age_bracket5,
			amt_age_bracket6,
			amt_age_bracket7,
			amt_age_bracket8,
			amt_age_bracket9,
			amt_age_bracket10,
			'ab1' = @str_age_bracket_1,
			'ab2' = @str_age_bracket_2,
			'ab3' = @str_age_bracket_3,
			'ab4' = @str_age_bracket_4,
			'ab5' = @str_age_bracket_5,
			'ab6' = @str_age_bracket_6,
			'ab7' = @str_age_bracket_7,
			'ab8' = @str_age_bracket_8,
			'ab9' = @str_age_bracket_9,
			'ab10' = @str_age_bracket_10,
			'fromcust' = @from_cust,
			'thrucust' = @thru_cust,
			'fromname' = @from_name,
			'thruname' = @thru_name,
			'fromterr' = @from_terr,
			'thruterr' = @thru_terr,
			'datetype' = @date_type_string,
			'dateparm' = @date_type_parm,
			trx_ctrl_num,
			doc_ctrl_num, 
			apply_to_num,

			'agedate' = case when date_aging > 639906 then convert(datetime, dateadd(dd, date_aging - 639906, '1/1/1753')) else date_aging end,
			'duedate' = case when date_due > 639906 then convert(datetime, dateadd(dd, date_due - 639906, '1/1/1753')) else date_due end,
			'docdate' = case when date_doc > 639906 then convert(datetime, dateadd(dd, date_doc - 639906, '1/1/1753')) else date_doc end,
			'applydate' = case when date_applied > 639906 then convert(datetime, dateadd(dd, date_applied - 639906, '1/1/1753')) else date_applied end,
			'trxtype' = trx_type_code,
			company_name,
			cust_po_num,
			'onaccount' = @on_acct_string,
			'AllCust' = @all_cust_flag,
			'AllTerr' = @all_terr_flag,
			'AllName' = @all_name_flag,
			report_comment,
			'sequence' = @sequence,
			'CustBalOver' = @balance_over_amt,
 			'IncFuture' = @inc_future_str,
			'DateAsOf' = @str_date_asof,
			'DaysOver' = @days_over_num,
		 	'BalOperand' = @bal_over_operand,
			'DaysOperand' = @days_over_operand,
			'BalanceOverStr1' = @balance_over_str1,			
			'BalanceOverStr2' = @balance_over_str2,			
			'BalanceOverStr3' = @balance_over_str3,
			'MeetCond' = @meet_cond,
			'HomeSymbol' = @home_symbol,
			'FromPost' = @from_post,			'ThruPost' = @thru_post,
			'FromWkld' = @from_workload,			'ThruWkld' = @thru_workload,
			territory_desc,
			'companyid' = '1',	
			'TerrCodeFrom' = @terr_from_cust,
			'PrintAllComments' = print_all_comments,
			'CurrencyBasis' = @currency_basis,			
			'OperSymbol' = @oper_symbol,
			'AllPost' = @all_post_flag,
 'AllWorkload' = @all_workload_flag,
			'AllOrg' = @all_org_flag,
			'FromOrg' = @from_org,
			'ThruOrg' = @thru_org,
			org_id
			FROM #artrxage_tmp t, armaster c 
			WHERE t.customer_code = c.customer_code
			AND address_type = 0
			ORDER BY address_name , t.nat_cur_code, t.apply_to_num, t.sub_apply_num, t.date_aging, ABS(t.trx_type - 2021), t.date_applied

	ELSE IF @sequence = 2
		SELECT 	c.customer_code,
			t.territory_code,
			'customer_name' = address_name, 			 
			'total_home' = amount, 
			amt_age_bracket1,
			amt_age_bracket2,
			amt_age_bracket3,
			amt_age_bracket4,
			amt_age_bracket5,
			amt_age_bracket6,
			amt_age_bracket7,
			amt_age_bracket8,
			amt_age_bracket9,
			amt_age_bracket10,
			'ab1' = @str_age_bracket_1,
			'ab2' = @str_age_bracket_2,
			'ab3' = @str_age_bracket_3,
			'ab4' = @str_age_bracket_4,
			'ab5' = @str_age_bracket_5,
			'ab6' = @str_age_bracket_6,
			'ab7' = @str_age_bracket_7,
			'ab8' = @str_age_bracket_8,
			'ab9' = @str_age_bracket_9,
			'ab10' = @str_age_bracket_10,
			'fromcust' = @from_cust,
			'thrucust' = @thru_cust,
			'fromname' = @from_name,
			'thruname' = @thru_name,
			'fromterr' = @from_terr,
			'thruterr' = @thru_terr,
			'datetype' = @date_type_string,
			'dateparm' = @date_type_parm,
			trx_ctrl_num,
			doc_ctrl_num, 
			apply_to_num,

			'agedate' = case when date_aging > 639906 then convert(datetime, dateadd(dd, date_aging - 639906, '1/1/1753')) else date_aging end,
			'duedate' = case when date_due > 639906 then convert(datetime, dateadd(dd, date_due - 639906, '1/1/1753')) else date_due end,
			'docdate' = case when date_doc > 639906 then convert(datetime, dateadd(dd, date_doc - 639906, '1/1/1753')) else date_doc end,
			'applydate' = case when date_applied > 639906 then convert(datetime, dateadd(dd, date_applied - 639906, '1/1/1753')) else date_applied end,

			'trxtype' = trx_type_code,
			company_name,
			cust_po_num,
			'onaccount' = @on_acct_string,
			'AllCust' = @all_cust_flag,
			'AllTerr' = @all_terr_flag,
			'AllName' = @all_name_flag,
			report_comment,
			'sequence' = @sequence,
			'CustBalOver' = @balance_over_amt,
 			'IncFuture' = @inc_future_str,
			'DateAsOf' = @str_date_asof,
			'DaysOver' = @days_over_num,
		 	'BalOperand' = @bal_over_operand,
			'DaysOperand' = @days_over_operand,
			'BalanceOverStr1' = @balance_over_str1,			
			'BalanceOverStr2' = @balance_over_str2,			
			'BalanceOverStr3' = @balance_over_str3,
			'MeetCond' = @meet_cond,
			'HomeSymbol' = @home_symbol,
			'FromPost' = @from_post,			'ThruPost' = @thru_post,
			'FromWkld' = @from_workload,			'ThruWkld' = @thru_workload,
			territory_desc,
			'companyid' = '1',	
			'TerrCodeFrom' = @terr_from_cust,
			'PrintAllComments' = print_all_comments,
			'CurrencyBasis' = @currency_basis,			
			'OperSymbol' = @oper_symbol,
			'AllPost' = @all_post_flag,
 'AllWorkload' = @all_workload_flag,
			'AllOrg' = @all_org_flag,
			'FromOrg' = @from_org,
			'ThruOrg' = @thru_org,
			org_id
			FROM #artrxage_tmp t, armaster c 
			WHERE t.customer_code = c.customer_code
			AND address_type = 0
			ORDER BY t.territory_code , c.customer_code, t.nat_cur_code, t.apply_to_num, t.sub_apply_num, t.date_aging, ABS(t.trx_type - 2021), t.date_applied

	ELSE	
		SELECT 	c.customer_code,
			t.territory_code,
			'customer_name' = address_name, 			 
			'total_home' = amount, 
			amt_age_bracket1,
			amt_age_bracket2,
			amt_age_bracket3,
			amt_age_bracket4,
			amt_age_bracket5,
			amt_age_bracket6,
			amt_age_bracket7,
			amt_age_bracket8,
			amt_age_bracket9,
			amt_age_bracket10,
			'ab1' = @str_age_bracket_1,
			'ab2' = @str_age_bracket_2,
			'ab3' = @str_age_bracket_3,
			'ab4' = @str_age_bracket_4,
			'ab5' = @str_age_bracket_5,
			'ab6' = @str_age_bracket_6,
			'ab7' = @str_age_bracket_7,
			'ab8' = @str_age_bracket_8,
			'ab9' = @str_age_bracket_9,
			'ab10' = @str_age_bracket_10,
			'fromcust' = @from_cust,
			'thrucust' = @thru_cust,
			'fromname' = @from_name,
			'thruname' = @thru_name,
			'fromterr' = @from_terr,
			'thruterr' = @thru_terr,
			'datetype' = @date_type_string,
			'dateparm' = @date_type_parm,
			trx_ctrl_num,
			doc_ctrl_num, 
			apply_to_num,

			'agedate' = case when date_aging > 639906 then convert(datetime, dateadd(dd, date_aging - 639906, '1/1/1753')) else date_aging end,
			'duedate' = case when date_due > 639906 then convert(datetime, dateadd(dd, date_due - 639906, '1/1/1753')) else date_due end,
			'docdate' = case when date_doc > 639906 then convert(datetime, dateadd(dd, date_doc - 639906, '1/1/1753')) else date_doc end,
			'applydate' = case when date_applied > 639906 then convert(datetime, dateadd(dd, date_applied - 639906, '1/1/1753')) else date_applied end,

			'trxtype' = trx_type_code,
			company_name,
			cust_po_num,
			'onaccount' = @on_acct_string,
			'AllCust' = @all_cust_flag,
			'AllTerr' = @all_terr_flag,
			'AllName' = @all_name_flag,
			report_comment,
			'sequence' = @sequence,
			'CustBalOver' = @balance_over_amt,
 			'IncFuture' = @inc_future_str,
			'DateAsOf' = @str_date_asof,
			'DaysOver' = @days_over_num,
		 	'BalOperand' = @bal_over_operand,
			'DaysOperand' = @days_over_operand,
			'BalanceOverStr1' = @balance_over_str1,			
			'BalanceOverStr2' = @balance_over_str2,			
			'BalanceOverStr3' = @balance_over_str3,
			'MeetCond' = @meet_cond,
			'HomeSymbol' = @home_symbol,
			'FromPost' = @from_post,			'ThruPost' = @thru_post,
			'FromWkld' = @from_workload,			'ThruWkld' = @thru_workload,
			territory_desc,
			'companyid' = '1',	
			'TerrCodeFrom' = @terr_from_cust,
			'PrintAllComments' = print_all_comments,
			'CurrencyBasis' = @currency_basis,			
			'OperSymbol' = @oper_symbol,
			'AllPost' = @all_post_flag,
 'AllWorkload' = @all_workload_flag,
			'AllOrg' = @all_org_flag,
			'FromOrg' = @from_org,
			'ThruOrg' = @thru_org,
			org_id
			FROM #artrxage_tmp t, armaster c 
			WHERE t.customer_code = c.customer_code
			AND address_type = 0
			ORDER BY t.customer_code , t.nat_cur_code, t.apply_to_num, t.sub_apply_num, t.date_aging, ABS(t.trx_type - 2021), t.date_applied


	DROP TABLE #artrxage_tmp
	DROP TABLE #non_zero_records

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_logoff_sp' ) EXEC sm_logoff_sp 
	SET NOCOUNT OFF
GO
GRANT EXECUTE ON  [dbo].[cc_get_detail_custom_age_sp] TO [public]
GO
