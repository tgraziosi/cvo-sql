SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC	[dbo].[cc_aging_nat_accts_sp]	@cbAllApplyTo			smallint = 1,
												@txtFromApplyTo		varchar(16) = '',
												@txtToApplyTo			varchar(16) = '',
												@cbAllCust				smallint = 1,
												@txtFromCust			varchar(8) = '',
												@txtToCust				varchar(8) = '',
												@cbAllName				smallint = 1,
												@txtFromName			varchar(40) = '',
												@txtToName				varchar(40) = '',
												@cbAllAcctCode			smallint = 1,
												@txtFromAcctCode		varchar(32) = '',
												@txtToAcctCode			varchar(32) = '',
												@cbAllNatAcct			smallint = 1,
												@txtFromNatAcct		varchar(32) = '',
												@txtToNatAcct			varchar(32) = '',
												@cbAllPriceCode		smallint = 1,
												@txtFromPrice			varchar(8) = '',
												@txtToPrice				varchar(8) = '',
												@cbAllPostingCode		smallint = 1,
												@txtFromPostingCode	varchar(8) = '',
												@txtToPostingCode		varchar(8) = '',
												@cbAllSalesCode		smallint = 1,
												@txtFromSales			varchar(8) = '',
												@txtToSales				varchar(8) = '',
												@cbAllTerr				smallint = 1,
												@txtFromTerr			varchar(8) = '',
												@txtToTerr				varchar(8) = '',
												@cbAllWorkload			smallint = 1,
												@txtFromWorkload		varchar(8) = '',
												@txtToWorkload			varchar(8) = '',
												@dtAsOfDate				varchar(12),
												@title					varchar(60) = '',		
												@order_by_currency	smallint = 0,
												@incl_future_trx		smallint = 0,
												@incl_trx_pif			smallint = 0,
												@age_on_date			smallint = 0, 
												@prt_over_days			smallint = 0,
												@over_days				int = 0, 
												@prt_over_amt 			smallint = 0,
												@over_amt				float = 0, 
												@prt_ovr_cd_lim		smallint = 0,
												@prt_ovr_ag_lim		smallint = 0,
												@cond_req				smallint = 0,		 
												@home_totals			smallint = 1,		
												@apply_date_rate		smallint = 0,		
												@override_rate_type	varchar(9) = '',
												@relation_code			varchar(17) = '',												
												@order					varchar(1000) = '',
												@order_num				smallint = 0,	










												@rptTable				varchar(255) = 'rpt_araging',
												@all_org_flag			smallint = 0,	 
												@from_org varchar(30) = '',
												@to_org varchar(30) = ''




AS
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF

	DECLARE	@company_name		varchar(30),
				@brkt1_e				smallint,
				@brkt2_e				smallint,
				@brkt3_e				smallint,
				@brkt4_e				smallint,
				@brkt5_e				smallint,
				@def_rel_code		varchar(8),

				@brkt2_b				smallint,
				@brkt3_b				smallint,
				@brkt4_b				smallint,
				@brkt5_b				smallint,
				@brkt6_b				smallint,


				@mc_flag				smallint,
				@mask_home			varchar(100),
				@mask_oper			varchar(100),
				@precision_home	smallint,
				@precision_oper	smallint,
				@home_symbol		varchar(8),
				@oper_symbol		varchar(8),
				@home_currency		varchar(8),
				@oper_currency		varchar(8),



				@tier_label1		varchar(20),
				@tier_label2		varchar(20),
				@tier_label3		varchar(20),
				@tier_label4		varchar(20),
				@tier_label5		varchar(20),
				@tier_label6		varchar(20),
				@tier_label7		varchar(20),
				@tier_label8		varchar(20),
				@tier_label9		varchar(20),
				@tier_label10		varchar(20),
				@tiered_flag		smallint,
				@tier_credit		smallint,

				@hdr_str_1			varchar(65),
				@hdr_str_2			varchar(65),
				@hdr_str_3			varchar(65),
				@hdr_str_4			varchar(65),
				@hdr_str_5			varchar(65),
				@hdr_str_6			varchar(65),

				@contact_phone 	varchar(30),
				@age_date_column	varchar(30),
				@maskx				varchar(255),
				@order_string	varchar(255),
				@order_string2	varchar(255),
				@where_future	varchar(255),
				@where_pif	varchar(255),
				@from_pif	varchar(255),
				@err_from_currency	varchar(8),
				@err_to_currency	varchar(8),
				@err_rate_type	varchar(8),
				@err_date_applied	int,
				@rate_error	varchar(255),
				@to_currency	varchar(8),
				@rate_type_str	varchar(8),
				@rate_type_where	varchar(65),
				@rate_str	varchar(255),
				@err_flag	smallint,
				@group_by0_col	varchar(255),
				@group_by1_col	varchar(255),
				@group_by2_col	varchar(255),
				@group_by3_col	varchar(255),
				@group_by4_col	varchar(255),
				@txt_groupby0	varchar(255),
				@txt_groupby1	varchar(255),
				@phone_mask	varchar(255), 
				@total_home float,
				@na_credit_string	varchar(25),
				@order_by_na smallint,
				@na_range	varchar(255),
				@artierrl	varchar(25),
				@where_clause varchar(8000),
				@as_of_date				int,
				@now	int,												
				@as_of_date_str	varchar(20),
				@brkt1_e_str varchar(15),
				@brkt2_e_str varchar(15),
				@brkt3_e_str varchar(15),
				@brkt4_e_str varchar(15),
				@brkt5_e_str varchar(15),
				@brkt6_e_str varchar(15),
				@brkt2_b_str varchar(15),
				@brkt3_b_str varchar(15),
				@brkt4_b_str varchar(15),
				@brkt5_b_str varchar(15),
				@precision_home_str varchar(15),
				@precision_oper_str varchar(15),
				@err_date_applied_str varchar(15),
				@home_totals_str varchar(25),
				@over_amt_str varchar(25),
				@over_days_str varchar(25),
				@prt_ovr_ag_lim_str varchar(10),
				@prt_over_days_str varchar(10),
				@prt_ovr_cd_lim_str varchar(10),
				@prt_over_amt_str varchar(10),

				@where_clause2		varchar(255),
				@temp_table				varchar(255),
				@where_clause_org		varchar(255),

				@relation_where		varchar(255),

				@brkt1_b				smallint,
				@hdr_str_0			varchar(65),
				@brkt1_b_str varchar(15)


		SELECT @age_on_date = 1 

	SELECT @temp_table = '#rpt_araging'

			CREATE TABLE #customers_to_print 
			(	customer_code varchar(8),
				balance_home float	NULL,
				balance_oper float	NULL,
				limit_by_home smallint	NULL,
				flag smallint	NULL
			)

			CREATE TABLE #void_brackets 
			(	trx_ctrl_num	varchar(16)	NULL, 
				trx_type			smallint	NULL, 
				doc_ctrl_num	varchar(16)	NULL,
				customer_code	varchar(8)	NULL, 
				ref_id			smallint	NULL, 
				bracket			smallint	NULL
			)


			CREATE TABLE #parent_totals
			(	parent			varchar(8)	NULL, 
				balance_home	float	NULL,
				home_total		float	NULL, 
				balance_oper	float	NULL,
				oper_total		float	NULL
			)

			CREATE TABLE #parent_validation
			(	parent			varchar(8)	NULL, 
				flag				smallint	NULL
			)
								
			CREATE TABLE #parent_validation2
			(	parent			varchar(8)	NULL, 
				flag				smallint	NULL
			)

			CREATE TABLE #pif (apply_to_num varchar(16))				

CREATE TABLE	#rpt_araging

(	trx_type 		smallint NULL,
		ref_id 			smallint NULL,
		trx_ctrl_num 	varchar(16) NULL,
		doc_ctrl_num 	varchar(16) NULL,
		order_ctrl_num 	varchar(16) NULL,
		cust_po_num 		varchar(20) NULL,
		cash_acct_code 	varchar(32) NULL,
		apply_to_num 	varchar(16) NULL,
		apply_trx_type 	smallint NULL,
		sub_apply_num 	varchar(16) NULL,
		sub_apply_type 	smallint NULL,
		date_doc 		datetime NULL,
		date_due 		datetime NULL,
		date_aging 	datetime NULL,
		date_applied 	datetime NULL,
		amount 		float NULL,
		customer_code 	varchar(8) NULL,
		nat_cur_code 		varchar(8) NULL,
		rate_type 		varchar(8) NULL,
		rate_home 		float NULL,
		rate_oper 		float NULL,
		customer_name 	varchar(40) NULL,
		contact_name 		varchar(40) NULL,
		contact_phone 	varchar(40) NULL,
		attention_name 	varchar(40) NULL,
		attention_phone	varchar(30) NULL,
		addr1 			varchar(40) NULL,
		addr2 			varchar(40) NULL,
		addr3 			varchar(40) NULL,
		addr4 			varchar(40) NULL,
		addr5 			varchar(40) NULL,
		addr6 			varchar(40) NULL,
		status_desc 		varchar(40) NULL,
		parent 			varchar(8) NULL,
		child_1 		varchar(8) NULL,
		child_2 		varchar(8) NULL,
		child_3 		varchar(8) NULL,
		child_4 		varchar(8) NULL,
		child_5 		varchar(8) NULL,
		child_6 		varchar(8) NULL,
		child_7 		varchar(8) NULL,
		child_8 		varchar(8) NULL,
		child_9 		varchar(8) NULL,
		groupby0 			varchar(40) NULL,
		groupby1 			varchar(40) NULL,
		groupby2 			varchar(40) NULL,
		groupby3 			varchar(40) NULL,
		bracket 			smallint NULL,
		days_aged 		int NULL,
		trx_type_code 	varchar(8) NULL,
		status_type 		smallint NULL,
		symbol 			varchar(8) NULL,
		curr_precision 	smallint NULL,
		num_currencies 	smallint NULL,
		date_entered 		int NULL,
		org_id					varchar(30) NULL,
		region_id varchar(30) NULL	)
										









	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@relation_code))),0) = 0
		SELECT @relation_where = ' 0 = 0 '
	ELSE
		SELECT @relation_where = 'n.relation_code = "' + @relation_code + '" '

	SELECT @err_flag = 0, @rate_error = ''



	SELECT	@mc_flag = a.multi_currency_flag,
				@mask_home = b.currency_mask,
				@mask_oper = c.currency_mask,
				@precision_home = b.curr_precision,
				@precision_oper = c.curr_precision,
				@home_symbol = b.symbol,
				@oper_symbol = c.symbol,
				@home_currency = a.home_currency,
				@oper_currency = a.oper_currency
	FROM 		glco a, glcurr_vw b, glcurr_vw c
	WHERE 	a.home_currency = b.currency_code
	AND 	a.oper_currency = c.currency_code



	SELECT @as_of_date = datediff(dd, '1/1/1753', @dtAsOfDate) + 639906

	SELECT @as_of_date_str = CONVERT(varchar(15), @as_of_date)
	SELECT @precision_home_str = CONVERT(varchar(15),@precision_home )
	SELECT @precision_oper_str = CONVERT(varchar(15),@precision_oper )
	SELECT @err_date_applied_str = CONVERT(varchar(15),@err_date_applied )
	SELECT @home_totals_str = CONVERT(varchar(25),@home_totals )
	SELECT @over_amt_str = CONVERT(varchar(25),@over_amt )
	SELECT @over_days_str = CONVERT(varchar(25),@over_days )
	SELECT @prt_ovr_ag_lim_str = CONVERT(varchar(10),@prt_ovr_ag_lim )
	SELECT @prt_over_days_str = CONVERT(varchar(10),@prt_over_days )
	SELECT @prt_ovr_cd_lim_str = CONVERT(varchar(10),@prt_ovr_cd_lim )
	SELECT @prt_over_amt_str = CONVERT(varchar(10),@prt_over_amt )



 



	SELECT	@brkt1_e = age_bracket1,
				@brkt2_e = age_bracket2,
				@brkt3_e = age_bracket3,
				@brkt4_e = age_bracket4,
				@brkt5_e = age_bracket5,
				@company_name = company_name,
				@def_rel_code = report_rel_code
	FROM 	arco 

	SELECT 	@now = DATEDIFF(dd, '1/1/1753', CONVERT(datetime, GETDATE())) + 639906
	SELECT	@artierrl = ''




	SELECT	@brkt2_b = @brkt1_e + 1,
				@brkt3_b = @brkt2_e + 1,
				@brkt4_b = @brkt3_e + 1,
				@brkt5_b = @brkt4_e + 1,
				@brkt6_b = @brkt5_e + 1


		SELECT 	@brkt1_e 	= 30,
						@brkt2_e 	= 60,
						@brkt3_e 	= 90,
						@brkt4_e 	= 120,
						@brkt5_e 	= 150


		SELECT 	@brkt1_b 	= 1,
						@brkt2_b 	= 31,
						@brkt3_b 	= 61,
						@brkt4_b 	= 91,
						@brkt5_b 	= 121,
						@brkt6_b 	= 151




	SELECT	@hdr_str_0 = 'Future',
					@hdr_str_1 = 'Current',
					@hdr_str_2 = STR(@brkt1_b) + '-' + STR(@brkt1_e),
					@hdr_str_3 = STR(@brkt2_b) + '-' + STR(@brkt2_e),
					@hdr_str_4 = STR(@brkt3_b) + '-' + STR(@brkt3_e),
					@hdr_str_5 = STR(@brkt4_b) + '-' + STR(@brkt4_e),
					@hdr_str_6 = 'OVER ' + STR(@brkt4_b)

	SELECT @brkt1_e_str = CONVERT(varchar(15),@brkt1_e) 
	SELECT @brkt2_e_str = CONVERT(varchar(15),@brkt2_e)
	SELECT @brkt3_e_str = CONVERT(varchar(15),@brkt3_e)
	SELECT @brkt4_e_str = CONVERT(varchar(15),@brkt4_e)
	SELECT @brkt5_e_str = CONVERT(varchar(15),@brkt5_e)
	SELECT @brkt1_b_str = CONVERT(varchar(15),@brkt1_b)
	SELECT @brkt2_b_str = CONVERT(varchar(15),@brkt2_b)
	SELECT @brkt3_b_str = CONVERT(varchar(15),@brkt3_b)
	SELECT @brkt4_b_str = CONVERT(varchar(15),@brkt4_b)
	SELECT @brkt5_b_str = CONVERT(varchar(15),@brkt5_b)

												

	SELECT @where_clause = ' 0 = 0 '

	IF @cbAllApplyTo = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromApplyTo ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromApplyTo ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( a.apply_to_num >= "' + @txtFromApplyTo + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( a.apply_to_num LIKE "' + @txtFromApplyTo + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToApplyTo ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToApplyTo ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND a.apply_to_num <= "' + @txtToApplyTo + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND a.apply_to_num LIKE "' + @txtToApplyTo + '" ) )'
		END
												
	IF @cbAllCust = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromCust ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromCust ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( a.customer_code >= "' + @txtFromCust + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( a.customer_code LIKE "' + @txtFromCust + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToCust ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToCust ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND a.customer_code <= "' + @txtToCust + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND a.customer_code LIKE "' + @txtToCust + '" ) )'
		END
												
	IF @cbAllName = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromName ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromName ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( b.customer_name >= "' + @txtFromName + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( b.customer_name LIKE "' + @txtFromName + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToName ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToName ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND b.customer_name <= "' + @txtToName + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND b.customer_name LIKE "' + @txtToName + '" ) )'
		END

	IF @cbAllAcctCode = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromAcctCode ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromAcctCode ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( a.account_code >= "' + @txtFromAcctCode + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( a.account_code LIKE "' + @txtFromAcctCode + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToAcctCode ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToAcctCode ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND a.account_code <= "' + @txtToAcctCode + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND a.account_code LIKE "' + @txtToAcctCode + '" ) )'
		END

	SELECT @na_range = ' AND 1 = 1 '

	IF @cbAllNatAcct = 0
		BEGIN
 	SELECT 	@artierrl = ', artierrl n',
 				@na_range = ' AND a.customer_code = n.rel_cust AND n.relation_code = "' + @relation_code + '" ' 

			IF ( ( SELECT CHARINDEX( '_', @txtFromNatAcct ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromNatAcct ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( n.parent >= "' + @txtFromNatAcct + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( n.parent LIKE "' + @txtFromNatAcct + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToNatAcct ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToNatAcct ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND n.parent <= "' + @txtToNatAcct + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND n.parent LIKE "' + @txtToNatAcct + '" ) )'
		END

	IF @cbAllPriceCode = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromPrice ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromPrice ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( a.price_code >= "' + @txtFromPrice + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( a.price_code LIKE "' + @txtFromPrice + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToPrice ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToPrice ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND a.price_code <= "' + @txtToPrice + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND a.price_code LIKE "' + @txtToPrice + '" ) )'
		END
												
	IF @cbAllPostingCode = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromPostingCode ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromPostingCode ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( b.posting_code >= "' + @txtFromPostingCode + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( b.posting_code LIKE "' + @txtFromPostingCode + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToPostingCode ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToPostingCode ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND b.posting_code <= "' + @txtToPostingCode + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND b.posting_code LIKE "' + @txtToPostingCode + '" ) )'
		END
											
	IF @cbAllSalesCode = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromSales ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromSales ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( a.salesperson_code >= "' + @txtFromSales + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( a.salesperson_code LIKE "' + @txtFromSales + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToSales ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToSales ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND a.salesperson_code <= "' + @txtToSales + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND a.salesperson_code LIKE "' + @txtToSales + '" ) )'
		END
												
	IF @cbAllTerr = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromTerr ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromTerr ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND ( ( a.territory_code >= "' + @txtFromTerr + '" '
			ELSE
				SELECT @where_clause = @where_clause + ' AND ( ( a.territory_code LIKE "' + @txtFromTerr + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToTerr ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToTerr ) ) = 0 )
				SELECT @where_clause = @where_clause + ' AND a.territory_code <= "' + @txtToTerr + '" ) )'
			ELSE
				SELECT @where_clause = @where_clause + ' AND a.territory_code LIKE "' + @txtToTerr + '" ) )'
		END
												
	SELECT @where_clause2 = ' 0 = 0 '

	IF @cbAllWorkload = 0
		BEGIN
			IF ( ( SELECT CHARINDEX( '_', @txtFromWorkload ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtFromWorkload ) ) = 0 )
				SELECT @where_clause2 = @where_clause2 + ' AND ( ( w.workload_code >= "' + @txtFromWorkload + '" '
			ELSE
				SELECT @where_clause2 = @where_clause2 + ' AND ( ( w.workload_code LIKE "' + @txtFromWorkload + '" '
		
			IF ( ( SELECT CHARINDEX( '_', @txtToWorkload ) ) = 0 AND ( SELECT CHARINDEX( '%', @txtToWorkload ) ) = 0 )
				SELECT @where_clause2 = @where_clause2 + ' AND w.workload_code <= "' + @txtToWorkload + '" ) )'
			ELSE
				SELECT @where_clause2 = @where_clause2 + ' AND w.workload_code LIKE "' + @txtToWorkload + '" ) )'
		END


	SELECT @where_clause_org = ' 0 = 0 '

	IF @all_org_flag = 0
		BEGIN
			
			IF ( ( SELECT CHARINDEX( "_", @from_org ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @from_org ) ) = 0 )
				SELECT @where_clause_org = @where_clause_org + " AND ( ( a.org_id >= '" + @from_org + "' "
			ELSE
				SELECT @where_clause_org = @where_clause_org + " AND ( ( a.org_id LIKE '" + @from_org + "' " 

			IF ( ( SELECT CHARINDEX( "_", @to_org ) ) = 0
			 AND ( SELECT CHARINDEX( "%", @to_org ) ) = 0 )
				SELECT @where_clause_org = @where_clause_org + " AND a.org_id <= '" + @to_org + "' ) )"
			ELSE
				SELECT @where_clause_org = @where_clause_org + " AND a.org_id LIKE '" + @to_org + "' ) )"
		END

	CREATE TABLE #customers
	(
		customer_code		varchar(8)
	)

	IF @cbAllWorkload = '0'
			EXEC	(	'	INSERT #customers
								SELECT 	c.customer_code
								FROM 	arcust c, ccwrkmem w	
								WHERE '	+ @where_clause2 +
							' AND c.customer_code = w.customer_code ' )
			ELSE
				EXEC(	'	INSERT #customers
								SELECT 	customer_code
								FROM 	arcust ' )



	SELECT @age_date_column = CASE @age_on_date
 WHEN 0 THEN 'date_aging'
		WHEN 1 THEN 'date_due'
		WHEN 2 THEN 'date_doc'
		WHEN 3 THEN 'date_applied'
	END


SELECT @age_date_column = 'date_due'
 

	IF @as_of_date = 0
		SELECT @as_of_date = @now








	IF ISNULL(DATALENGTH(LTRIM(RTRIM(@title))),0) = 0
		SELECT @title = 'Aged Receivable Report'

	SELECT @title = @title + ' By: ';

 
	IF @order_num = 0
		BEGIN	
			IF @order_by_currency = 1 
 		SELECT @title = @title + 'Currency Code/'

	 SELECT @title = @title + 'Customer Code'
		END

	IF @order_num = 1
		SELECT	@title = @title + 'Customer Name'

	IF @order_num = 2
		SELECT	@title = @title + 'Salesperson Code'

	IF @order_num = 3
		SELECT	@title = @title + 'Territory Code'

	IF @order_num = 4
		SELECT	@title = @title + 'Territory Code/Salesperson Code'

	IF @order_num = 5
		SELECT	@title = @title + 'Price Code'
 
	IF @order_num = 7
		SELECT	@title = @title + 'Account Code'

	IF @order_num = 8
		SELECT	@title = @title + 'Organization Id'

	IF @order_num = 6
		BEGIN
			SELECT 	@title = @title + 'National Account', 
						@tier_label1 = '',
						@tier_label2 = '',
						@tier_label3 = '',
						@tier_label4 = '',
						@tier_label5 = '',
						@tier_label6 = '',
						@tier_label7 = '',
						@tier_label8 = '',
						@tier_label9 = '',
						@tier_label10 = ''
 
			IF ISNULL(DATALENGTH(RTRIM(LTRIM(@relation_code))),0) > 0
				
			 SELECT	@tier_label1 = a3.tier_label1,
							@tier_label2 = a3.tier_label2,
							@tier_label3 = a3.tier_label3,
							@tier_label4 = a3.tier_label4,
							@tier_label5 = a3.tier_label5,
							@tier_label6 = a3.tier_label6,
							@tier_label7 = a3.tier_label7,
							@tier_label8 = a3.tier_label8,
							@tier_label9 = a3.tier_label9,
							@tier_label10 = a3.tier_label10,
							@tiered_flag = a3.tiered_flag
			 FROM arrelcde a3
			 WHERE a3.relation_code = @relation_code
 
 


			IF ISNULL(DATALENGTH(RTRIM(LTRIM(@tier_label1))),0) = 0
				SELECT @tier_label1 = 'National Account'

		END


	IF ( @order_by_currency = 1 AND @order_num <> 0 )
		SELECT @title = @title + '/Currency Code' 

	IF @order_by_currency = 1
		SELECT 	@order_string = 'a.nat_cur_code,',
 			@order_string2 = ''
	ELSE
		SELECT 	@order_string = '',
					@order_string2 = 'a.nat_cur_code,'



	IF @incl_future_trx = 1
 	SELECT @where_future = '1 = 1'
	ELSE
 		SELECT @where_future = 'a.date_applied <= ' + @as_of_date_str

	IF @cbAllNatAcct = 0
		SELECT 	@artierrl = ', artierrl n ',
					@na_range = ' AND a.customer_code = n.rel_cust AND n.relation_code = "' + @relation_code + '" ' 

	ELSE
		SELECT 	@artierrl = '',
					@na_range = '' 


	IF @incl_trx_pif = 1
		SELECT 	@where_pif = '1 = 1',
					@from_pif = ''
	ELSE 		
		BEGIN

			EXEC (' 	INSERT #pif (apply_to_num)
						SELECT a.apply_to_num 
						FROM artrxage a, #customers c, arcust b ' + @artierrl +       
					'	WHERE a.customer_code = b.customer_code
						AND		a.customer_code = c.customer_code
						AND ' + @where_clause +  @na_range +
					'	AND ' + @where_future +
					' AND ' + @where_clause_org +
					'	GROUP BY apply_to_num
						HAVING ABS(SUM(amount)) > 0.000001' )

			SELECT 	@where_pif = ' a.apply_to_num = c.apply_to_num ',
 						@from_pif = ', #pif c '

		END

	SELECT 	@txt_groupby0 = '""',
				@txt_groupby1 = '""',
				@group_by0_col = '""',
				@group_by1_col = '""',
				@group_by2_col = '""',
				@group_by3_col = '""'

	IF @order_num = 1
		SELECT	@group_by0_col = 'b.customer_name',
					@txt_groupby0 = 'Customer:'
	ELSE IF @order_num = 2
		SELECT 	@group_by0_col = 'a.salesperson_code',
					@txt_groupby0 = 'Salesperson:'
	ELSE IF @order_num = 3
		SELECT	@group_by0_col = 'a.territory_code',
					@txt_groupby0 = 'Territory:'

	ELSE IF @order_num = 4
		SELECT	@group_by0_col = 'a.territory_code',
					@group_by1_col = 'a.salesperson_code',
					@txt_groupby0 = 'Territory:',
					@txt_groupby1 = 'Salesperson:'
	ELSE IF @order_num = 5
		SELECT	@group_by0_col = 'a.price_code',
					@txt_groupby0 = 'Price Class:'
	ELSE IF @order_num = 7
		SELECT	@group_by0_col = 'a.account_code',
					@txt_groupby0 = 'Account Code:'
	





	IF @order_by_currency = 1
		SELECT	@group_by2_col = 'a.nat_cur_code',
					@group_by3_col = 'a.customer_code'
	ELSE
		SELECT	@group_by2_col = 'a.customer_code',
					@group_by3_col = 'a.nat_cur_code'




	IF ( @order_num = 6 OR @cbAllNatAcct = 0 )
		EXEC( 'INSERT ' + @temp_table + 
				' (trx_type, 			ref_id, 				trx_ctrl_num,
					doc_ctrl_num, 		order_ctrl_num,	cust_po_num,
					cash_acct_code,	apply_to_num, 		apply_trx_type,
					sub_apply_num,		sub_apply_type,
					date_doc,
					date_due,
					date_aging,
					date_applied,
					amount,				customer_code,		nat_cur_code,
					rate_type,			rate_home,			rate_oper,
					customer_name,		contact_name,		contact_phone,
					attention_name,	attention_phone,	addr1,
					addr2,				addr3,				addr4,
					addr5,				addr6,				status_desc,
					parent,				child_1,				child_2,
					child_3,				child_4,				child_5,
					child_6,				child_7,				child_8,
					child_9,				groupby0,			groupby1,
					groupby2,			groupby3,			bracket,
					days_aged,			trx_type_code,		status_type,
					symbol,				curr_precision,	num_currencies,
					org_id
		SELECT	a.trx_type,			a.ref_id,			a.trx_ctrl_num,
					a.doc_ctrl_num,	a.order_ctrl_num,	a.cust_po_num,
					a.account_code,	a.apply_to_num,	a.apply_trx_type, 
					a.sub_apply_num,	a.sub_apply_type, 
					case when a.date_doc < 657072 then NULL else dateadd(dd,a.date_doc-657072,"1/1/1800") end,
					case when a.date_due < 657072 then NULL else dateadd(dd,a.date_due-657072,"1/1/1800") end,
					case when h.date_required < 657072 then NULL else dateadd(dd,h.date_required-657072,"1/1/1800") end,
					case when a.date_applied < 657072 then NULL else dateadd(dd,a.date_applied-657072,"1/1/1800") end,
					a.amount,			a.customer_code,	a.nat_cur_code,
					"",					a.rate_home,		a.rate_oper,
					b.customer_name,	b.contact_name,	b.contact_phone,
					b.attention_name,	b.attention_phone,b.addr1,
					b.addr2,				b.addr3,				b.addr4,
					b.addr5,				b.addr6,				"",
					n.parent,			n.child_1,			n.child_2,
					n.child_3,			n.child_4,			n.child_5,
					n.child_6,			n.child_7,			n.child_8,
					n.child_9, ' +		@group_by0_col + ', ' + @group_by1_col + ', ' +
					@group_by2_col + ',' + @group_by3_col + ', 	4,
					0,						d.trx_type_code,	b.status_type,
					e.symbol,			e.curr_precision,	1, a.org_id ' +
				'	FROM artrxage a, arcust b, glcurr_vw e, artrxtyp d, artierrl n, artrx_all h ' + @from_pif +
				'	WHERE ' + @where_future +
				'	AND ' + @where_pif + 
				'	AND a.customer_code = b.customer_code
					AND a.trx_type = d.trx_type
					AND a.nat_cur_code = e.currency_code
					AND a.customer_code = n.rel_cust
					AND a.trx_ctrl_num = h.trx_ctrl_num
					AND n.relation_code = "' + @relation_code + '" 
					AND ' + @where_clause +
				' AND ' + @where_clause_org )
	ELSE
		EXEC( 'INSERT ' + @temp_table + 
				' (trx_type, 			ref_id, 				trx_ctrl_num,
					doc_ctrl_num, 		order_ctrl_num,	cust_po_num,
					cash_acct_code,	apply_to_num, 		apply_trx_type,
					sub_apply_num,		sub_apply_type,
					date_doc,
					date_due,
					date_aging,
					date_applied,
					amount,				customer_code,		nat_cur_code,
					rate_type,			rate_home,			rate_oper,
					customer_name,		contact_name,		contact_phone,
					attention_name,	attention_phone,	addr1,
					addr2,				addr3,				addr4,
					addr5,				addr6,				status_desc,
					groupby0,			groupby1,			groupby2,
					groupby3,			bracket,				days_aged,
					trx_type_code,		status_type,		symbol,
					curr_precision,	num_currencies, org_id
		)
		SELECT	a.trx_type,			a.ref_id,			a.trx_ctrl_num,
					a.doc_ctrl_num,	a.order_ctrl_num,	a.cust_po_num,
					a.account_code,	a.apply_to_num,	a.apply_trx_type, 
					a.sub_apply_num,	a.sub_apply_type, 
					case when a.date_doc < 657072 then NULL else dateadd(dd,a.date_doc-657072,"1/1/1800") end,
					case when a.date_due < 657072 then NULL else dateadd(dd,a.date_due-657072,"1/1/1800") end,
					case when h.date_required < 657072 then NULL else dateadd(dd,h.date_required-657072,"1/1/1800") end,
					case when a.date_applied < 657072 then NULL else dateadd(dd,a.date_applied-657072,"1/1/1800") end,
					a.amount,			a.customer_code,	a.nat_cur_code,
					"",					a.rate_home,		a.rate_oper,
					b.customer_name,	b.contact_name,	b.contact_phone,
					b.attention_name,	b.attention_phone,b.addr1,
					b.addr2,				b.addr3,				b.addr4,
					b.addr5,				b.addr6,				"", ' +
					@group_by0_col + ',' + @group_by1_col + ',' + @group_by2_col + ', ' + 
					@group_by3_col + ', 					4,						0,
					d.trx_type_code,	b.status_type,		e.symbol,
					e.curr_precision,	1, a.org_id ' +
		'	FROM artrxage a, arcust b, glcurr_vw e, artrxtyp d, artrx_all h ' + @from_pif +
		'	WHERE ' + @where_future +
		'	AND ' + @where_pif + 
		'	AND a.customer_code = b.customer_code
			AND a.trx_type = d.trx_type
			AND a.nat_cur_code = e.currency_code
			AND a.trx_ctrl_num = h.trx_ctrl_num
			AND ' + @where_clause +
		' AND ' + @where_clause_org )






 
	EXEC( ' UPDATE ' + @temp_table +
			' SET days_aged = datediff(dd, ' + @age_date_column + ', "' + @dtAsOfDate + '") 
			 FROM ' + @temp_table + 
			' WHERE trx_type in (2021, 2031) ')






	EXEC( ' UPDATE ' + @temp_table +
			' SET date_due = date_doc,
					date_aging = date_doc
			 WHERE trx_type IN (2111, 2161, 2032) AND (ref_id <= 0) ')
















	EXEC( ' UPDATE ' + @temp_table +
			' SET bracket = CASE 	WHEN datediff(dd, ' + @age_date_column + ', "' + @dtAsOfDate + '") < 1 THEN 0 
											WHEN datediff(dd, ' + @age_date_column + ', "' + @dtAsOfDate + '") BETWEEN 1 AND 30 THEN 1
											WHEN datediff(dd, ' + @age_date_column + ', "' + @dtAsOfDate + '") BETWEEN 31 AND 60 THEN 2
											WHEN datediff(dd, ' + @age_date_column + ', "' + @dtAsOfDate + '") BETWEEN 61 AND 90 THEN 3
											WHEN datediff(dd, ' + @age_date_column + ', "' + @dtAsOfDate + '") BETWEEN 91 AND 120 THEN 4
											WHEN datediff(dd, ' + @age_date_column + ', "' + @dtAsOfDate + '") BETWEEN 120 AND 150 THEN 5
											WHEN datediff(dd, ' + @age_date_column + ', "' + @dtAsOfDate + '") > 150 THEN 6
								 END
				WHERE trx_type in (2111, 2161)
				AND apply_trx_type = trx_type ')
 



















	EXEC( ' UPDATE ' + @temp_table +
			' SET bracket = CASE 	WHEN ' + @as_of_date_str + ' - a.' + @age_date_column + ' < 1 THEN 0
											WHEN ' + @as_of_date_str + ' - a.' + @age_date_column + ' BETWEEN 1 AND 30 THEN 1
											WHEN ' + @as_of_date_str + ' - a.' + @age_date_column + ' BETWEEN 31 AND 60 THEN 2
											WHEN ' + @as_of_date_str + ' - a.' + @age_date_column + ' BETWEEN 61 AND 90 THEN 3
											WHEN ' + @as_of_date_str + ' - a.' + @age_date_column + ' BETWEEN 91 AND 120 THEN 4
											WHEN ' + @as_of_date_str + ' - a.' + @age_date_column + ' BETWEEN 120 AND 150 THEN 5
											WHEN ' + @as_of_date_str + ' - a.' + @age_date_column + ' > 150 THEN 6
									END
			FROM artrxage a, ' + @temp_table + ' b 
			WHERE a.doc_ctrl_num = b.apply_to_num 
			AND (b.apply_trx_type in (2021, 2031) OR a.trx_type in (2021, 2031))
			AND a.trx_type in (2021, 2031)
			AND (case when a.date_due < 657072 then NULL else dateadd(dd,a.date_due - 657072, "1/1/1800") end) = b.date_due ')

















	EXEC( ' UPDATE ' + @temp_table +
			' SET bracket = CASE 	WHEN datediff(dd, date_due, "' + @dtAsOfDate + '") < 1 THEN 0 
											WHEN datediff(dd, date_due, "' + @dtAsOfDate + '") BETWEEN 1 AND 30 THEN 1
											WHEN datediff(dd, date_due, "' + @dtAsOfDate + '") BETWEEN 31 AND 60 THEN 2
											WHEN datediff(dd, date_due, "' + @dtAsOfDate + '") BETWEEN 61 AND 90 THEN 3
											WHEN datediff(dd, date_due, "' + @dtAsOfDate + '") BETWEEN 91 AND 120 THEN 4
											WHEN datediff(dd, date_due, "' + @dtAsOfDate + '") BETWEEN 120 AND 150 THEN 5
											WHEN datediff(dd, date_due, "' + @dtAsOfDate + '") > 150 THEN 6
								 END
			WHERE doc_ctrl_num <> apply_to_num
			AND trx_type in (2021, 2031) ')






	EXEC( ' INSERT #void_brackets
				SELECT a.trx_ctrl_num, a.trx_type, a.doc_ctrl_num,a.customer_code, a.ref_id, b.bracket
				from ' + @temp_table + ' a, ' + @temp_table + ' b 
				where b.trx_type = b.apply_trx_type
				and b.trx_type = 2111
				and a.doc_ctrl_num = b.doc_ctrl_num
				and a.apply_to_num = b.apply_to_num
				and a.apply_trx_type = b.apply_trx_type
				and a.trx_type != b.trx_type
				and a.bracket != b.bracket
			 	AND ' + @where_clause_org )

	EXEC ( ' update ' + @temp_table +
			 ' set bracket = v.bracket
				from ' + @temp_table + ' a, #void_brackets v
				where a.trx_ctrl_num = v.trx_ctrl_num
				and a.trx_type = v.trx_type
				and a.doc_ctrl_num = v.doc_ctrl_num
				and a.customer_code = v.customer_code
				and a.ref_id = v.ref_id ')


	IF @apply_date_rate = 1
		BEGIN		
			CREATE TABLE #rates 
			(	from_currency varchar(8),
				to_currency varchar(8),
		 	rate_type varchar(8),
				date_applied int,
				rate float
			)
 
			IF @home_totals = 1
				SELECT 	@to_currency = @home_currency,
							@rate_str = 'rate_home',
		 			@rate_type_str = 'rate_type_home'
			ELSE
				SELECT	@to_currency = @oper_currency,
							@rate_str = 'rate_oper',
							@rate_type_str = 'rate_type_oper'

			IF	ISNULL(DATALENGTH(LTRIM(RTRIM(@override_rate_type))),0) = 0
				BEGIN
					EXEC( ' UPDATE ' + @temp_table +
							' SET rate_type = ' + @rate_type_str +
							' FROM ' + @temp_table + ' a, artrx b
							 WHERE a.trx_ctrl_num = b.trx_ctrl_num ')
		
					SELECT	@rate_type_where = ' AND a.rate_type = b.rate_type ',
								@rate_type_str = ' rate_type '
				END
			ELSE
				SELECT	@rate_type_str = @override_rate_type,
		 			@rate_type_where = ''

			SELECT 	@rate_type_str = @override_rate_type,
									@rate_type_where = ''

			EXEC ( ' INSERT 	#rates (from_currency, to_currency, rate_type, date_applied, rate)
						SELECT 	DISTINCT nat_cur_code, "' + @to_currency + '", ' +
									@rate_type_str + ',' + @as_of_date_str + ', 0.0
						FROM ' + @temp_table )


			EXEC cvo_control..mcrates_sp

			

			IF (SELECT COUNT(*) FROM #rates WHERE rate = 0.0) > 0
				BEGIN
					SELECT @err_flag = 1
					SELECT 	@err_from_currency = from_currency,
								@err_to_currency = to_currency,
								@err_rate_type = rate_type,
								@err_date_applied = date_applied
					FROM #rates
					WHERE rate = 0.0

					SELECT @rate_error = 'Cannot get rate from ' + @err_from_currency + ' to ' + @err_to_currency +
		 ' with rate type ' + @err_rate_type + ' on ' + @err_date_applied_str
					GOTO final_select
				END

			EXEC ( ' UPDATE ' + @temp_table + 
					 ' SET ' + @rate_str + ' = b.rate
						FROM ' + @temp_table + ' a, #rates b
						WHERE a.nat_cur_code = b.from_currency ' +
						@rate_type_where )


		END			





	IF @prt_over_amt + @prt_ovr_cd_lim + @prt_over_days + @prt_ovr_ag_lim <> 0
		BEGIN		
			


			EXEC ( ' INSERT #customers_to_print
						SELECT DISTINCT a.customer_code, 0.0, 0.0, b.limit_by_home, 0
						FROM ' + @temp_table + ' a, arcust b
						WHERE a.customer_code = b.customer_code ')
 
			CREATE CLUSTERED INDEX tmp_cus_pr_ind1 on #customers_to_print (customer_code)

			IF @prt_over_amt + @prt_ovr_cd_lim != 0
				BEGIN	
					EXEC ( ' UPDATE #customers_to_print
								SET balance_home = (SELECT ISNULL(SUM(ROUND(b.amount * ( SIGN(1 + SIGN(b.rate_home))*(b.rate_home) + (SIGN(ABS(SIGN(ROUND(b.rate_home,6))))/(b.rate_home + SIGN(1 - ABS(SIGN(ROUND(b.rate_home,6)))))) * SIGN(SIGN(b.rate_home) - 1) ), ' +  @precision_home_str + ')),0.0) 
															 FROM ' + @temp_table + ' b
															 WHERE b.customer_code = a.customer_code),
									 balance_oper = (SELECT ISNULL(SUM(ROUND(b.amount * ( SIGN(1 + SIGN(b.rate_oper))*(b.rate_oper) + (SIGN(ABS(SIGN(ROUND(b.rate_oper,6))))/(b.rate_oper + SIGN(1 - ABS(SIGN(ROUND(b.rate_oper,6)))))) * SIGN(SIGN(b.rate_oper) - 1) ), ' +  @precision_oper_str + ')),0.0) 
															 FROM ' + @temp_table + ' b
															 WHERE b.customer_code = a.customer_code)
								FROM #customers_to_print a ' )

					


					IF @prt_over_amt = 1
						BEGIN	
		 	IF @order_num = 6
								BEGIN
									EXEC ( ' INSERT   #parent_totals
												SELECT n.parent, sum(a.balance_home) home_total, sum(balance_oper) oper_total
												FROM #customers_to_print a, artierrl n
												WHERE a.customer_code = n.rel_cust
												AND ' + @relation_where + 
											'	GROUP BY n.parent ')
		
									EXEC ( ' UPDATE #customers_to_print
												SET balance_home = home_total, balance_oper = oper_total
												FROM #parent_totals a, artierrl n
												WHERE #customers_to_print.customer_code = n.rel_cust
												AND ' + @relation_where + 
											'	AND n.parent = a.parent ')
								END
		
							EXEC ( ' UPDATE #customers_to_print
										SET flag = 1
										FROM #customers_to_print
										WHERE ROUND(SIGN(' + @home_totals_str + ' ) * balance_home, ' + @precision_home_str + ') 
												+ ROUND(SIGN(1 - ' + @home_totals_str + ') * balance_oper, ' + @precision_oper_str + ') 
												> ' + @over_amt_str )
						END	
					


					IF @prt_ovr_cd_lim = 1
						BEGIN	
							IF @order_num != 6
								EXEC ( ' UPDATE #customers_to_print
											SET flag = flag | 2
											FROM #customers_to_print a, arcust b
											WHERE a.customer_code = b.customer_code
											AND b.check_credit_limit = 1
											AND ROUND(SIGN(1 - b.limit_by_home) * a.balance_home,' + @precision_home_str + ') 
												+ ROUND(SIGN(b.limit_by_home) * a.balance_oper, ' + @precision_oper_str + ')
												> b.credit_limit ')
							ELSE
								BEGIN	
									CREATE TABLE #parent_credit_check(parent varchar(8), rel_cust varchar(8), limit_by_home smallint,aging_balance float, credit_limit float)
		
									EXEC ( ' INSERT #parent_credit_check
												SELECT DISTINCT n.parent, n.rel_cust, b.limit_by_home,0.0,b.credit_limit
												FROM #customers_to_print a, arcust b, artierrl n
												WHERE a.customer_code = b.customer_code
												AND b.customer_code = n.rel_cust
												AND ' + @relation_where )
		 
									SELECT @tier_credit = 0
		 
									WHILE( @tier_credit < 10 )
										BEGIN
											IF @tier_credit = 0
												SELECT na_credit_string = 'n.parent'
											IF @tier_credit = 1
												SELECT na_credit_string = 'n.child_1'
											IF @tier_credit = 2
												SELECT na_credit_string = 'n.child_2'
											IF @tier_credit = 3
												SELECT na_credit_string = 'n.child_3'
											IF @tier_credit = 4
												SELECT na_credit_string = 'n.child_4'
											IF @tier_credit = 5
												SELECT na_credit_string = 'n.child_5'
											IF @tier_credit = 6
												SELECT na_credit_string = 'n.child_6'
											IF @tier_credit = 7
												SELECT na_credit_string = 'n.child_7'
											IF @tier_credit = 8
												SELECT na_credit_string = 'n.child_8'
											IF @tier_credit = 9
												SELECT na_credit_string = 'n.child_9'
		 
		 
											EXEC ( ' UPDATE #parent_credit_check
														SET aging_balance = ( SELECT SUM((1 - a.limit_by_home) * balance_home + a.limit_by_home * balance_oper)
																						FROM #customers_to_print a, artierrl n
																						WHERE ' + @relation_where + 
																					'	AND p.parent = n.parent
																						AND p.rel_cust = ' + @na_credit_string +
																					 ' AND n.rel_cust = a.customer_code)
														FROM #parent_credit_check p ')
		 
											SELECT @tier_credit = @tier_credit + 1
										END
		
									EXEC ( ' UPDATE #customers_to_print
												SET flag = flag | 2
												FROM #customers_to_print a, #parent_credit_check b, artierrl n
												WHERE a.customer_code = b.rel_cust
												AND b.parent = n.parent
												AND ' + @relation_where + '"
												AND b.aging_balance > credit_limit ')
		 
								END	
						END	
				END	

			IF @prt_over_days + @prt_ovr_ag_lim != 0
				BEGIN	
					

			
			 IF @prt_over_days = 1
						BEGIN	
							IF @order_num = 6
								BEGIN	
									EXEC ( ' INSERT #parent_validation
												SELECT DISTINCT n.parent, 0
												FROM artierrl n, #customers_to_print a
												WHERE n.rel_cust = a.customer_code
												AND ' + @relation_where)
				 
									EXEC ( ' UPDATE #parent_validation
												SET flag = 1
												FROM ' + @temp_table + '.b, artierrl n
												WHERE b.doc_ctrl_num = b.sub_apply_num
												AND b.trx_type = b.sub_apply_type
												AND datediff(dd, b.' + @age_date_column + ', ' + @as_of_date_str + ') > ' + @over_days_str +
											' AND   b.customer_code = n.rel_cust
												AND ' + @relation_where + 
											'	AND n.parent = #parent_validation.parent ')
												 
									EXEC ( ' UPDATE #customers_to_print
												SET flag = #customers_to_print.flag | 4
												FROM #parent_validation a, artierrl n 
												WHERE #customers_to_print.customer_code = n.rel_cust 
												AND ' + @relation_where + 
											'	AND n.parent = a.parent
												AND a.flag = 1 ')
												 
								END	
							ELSE
								EXEC ( ' UPDATE #customers_to_print
											SET flag = flag | 4 
											FROM #customers_to_print a 
											WHERE EXISTS (SELECT * FROM ' + @temp_table + ' b
																WHERE b.doc_ctrl_num = b.sub_apply_num 
																AND b.trx_type = b.sub_apply_type
																AND datediff(dd, b.' + @age_date_column + ', ' + @as_of_date_str + ') > ' + @over_days_str +
															'	AND b.customer_code = a.customer_code)')
						END	

					IF @prt_ovr_ag_lim = 1
						BEGIN	
							CREATE TABLE #ag_brk_map ( aging_limit_bracket smallint, aging_bracket_days smallint ) 
				 
							INSERT #ag_brk_map ( aging_limit_bracket, aging_bracket_days )
							SELECT 1, age_bracket1
				 			FROM arco
				
							INSERT #ag_brk_map ( aging_limit_bracket, aging_bracket_days )
							SELECT 2, age_bracket2
							FROM arco
				
							INSERT #ag_brk_map ( aging_limit_bracket, aging_bracket_days )
							SELECT 3, age_bracket3
							FROM arco
				
							INSERT #ag_brk_map ( aging_limit_bracket, aging_bracket_days )
							SELECT 4, age_bracket4
							FROM arco
				
							INSERT #ag_brk_map ( aging_limit_bracket, aging_bracket_days )
							SELECT 5, age_bracket5
							FROM arco
				 
							IF @order_num = 6
								BEGIN	
									EXEC ( ' INSERT #parent_validation2
												SELECT DISTINCT n.parent, 0
												FROM artierrl n, #customers_to_print a
												WHERE n.rel_cust = a.customer_code
												AND ' + @relation_where )
				 
									EXEC ( ' UPDATE #parent_validation2
												SET flag = 1
												FROM ' + @temp_table + ' b, artierrl n, arcust d, #ag_brk_map ag
												WHERE b.ref_id > 0
												AND b.amount > 0.0000001
												AND datediff(dd, b.' + @age_date_column + ', ' + @as_of_date_str + ') > convert(int,ag.aging_bracket_days)
												AND b.customer_code = n.rel_cust
												AND ' + @relation_where + 
											'	AND b.customer_code = d.customer_code
												AND d.aging_limit_bracket = ag.aging_limit_bracket
												AND n.parent = #parent_validation2.parent ')
									 
									EXEC ( ' UPDATE #customers_to_print
												SET flag = #customers_to_print.flag | 8
												FROM #parent_validation2 a, artierrl n
												WHERE #customers_to_print.customer_code = n.rel_cust
												AND ' + @relation_where + 
											'	AND n.parent = a.parent
												AND a.flag = 1 ')
									 
								END	
							ELSE
								EXEC ( ' UPDATE #customers_to_print
											SET flag = flag | 8
											FROM #customers_to_print a
											WHERE EXISTS ( SELECT * FROM ' + @temp_table +  ' b, arcust d, #ag_brk_map ag
																WHERE b.ref_id > 0
																AND b.amount > 0.0000001
																AND datediff(dd, b.' + @age_date_column + ', ' + @as_of_date_str + ') > convert(int,ag.aging_bracket_days)
																AND b.customer_code = a.customer_code
																AND b.customer_code = d.customer_code
																AND d.aging_limit_bracket = ag.aging_limit_bracket
																AND d.check_aging_limit = 1) ')
				 
				 
						END	
				END	

			


			IF @cond_req = 1
				EXEC ( ' DELETE ' + @temp_table +
						 ' FROM  #customers_to_print a
							WHERE ' + @temp_table + '.customer_code = a.customer_code
							AND flag != ( ' + @prt_ovr_ag_lim_str + ' * 8) | ( ' + @prt_over_days_str + ' * 4) | ( ' + @prt_ovr_cd_lim_str + ' * 2) | ( ' + @prt_over_amt_str + ' ) ' )
			ELSE
				EXEC ( ' DELETE ' + @temp_table +
						 ' FROM  #customers_to_print a
							WHERE ' + @temp_table + '.customer_code = a.customer_code
							AND flag = 0 ')
		END	


	IF @mc_flag > 0
		BEGIN
			CREATE TABLE #ctemp (customer_code varchar(12), num smallint)

			EXEC ( ' INSERT #ctemp (customer_code,num)
						SELECT customer_code, COUNT(DISTINCT nat_cur_code)
						FROM ' + @temp_table + ' GROUP BY customer_code ')

			EXEC ( ' UPDATE ' + @temp_table +
					 ' SET num_currencies = b.num
						FROM ' + @temp_table + ' a, #ctemp b
						WHERE a.customer_code = b.customer_code
						AND b.num > 1 ')

		END
 
	SELECT 	@contact_phone = '(111) 111-1111 Ext.111111111111111111',
				@phone_mask = @contact_phone,
				@phone_mask = REPLACE(@phone_mask,'1','x')

 
	IF @order_num = 6
		SELECT @order_by_na = 1
	ELSE
		SELECT @order_by_na = 0
 
	EXEC ( ' UPDATE ' + @temp_table + 
			 ' SET date_entered = t.date_entered
				FROM ' + @temp_table + ' a, artrx t
				WHERE a.doc_ctrl_num = t.doc_ctrl_num AND a.customer_code = t.customer_code
				AND a.trx_ctrl_num = t.trx_ctrl_num AND a.trx_type = t.trx_type ')
 




	IF @age_on_date = 2
		EXEC ( ' UPDATE ' + @temp_table + 
				 ' SET date_doc = case when a.date_doc < 657072 then NULL else dateadd(dd,a.date_doc-657072,"1/1/1800") end
					FROM ' + @temp_table + ' r, artrxage a
					WHERE r.customer_code = a.customer_code
					AND r.doc_ctrl_num = a.doc_ctrl_num
					AND a.trx_type = 2111
					AND r.trx_type != 2111 ')
	ELSE IF @age_on_date = 3
		EXEC ( ' UPDATE ' + @temp_table +
				 ' SET date_applied = case when a.date_applied < 657072 then NULL else dateadd(dd,a.date_applied-657072,"1/1/1800") end
					FROM ' + @temp_table + ' r, artrxage a
					WHERE r.customer_code = a.customer_code
					AND r.doc_ctrl_num = a.doc_ctrl_num
					AND a.trx_type = 2111
					AND r.trx_type != 2111 ')
 
final_select:

	EXEC(	'	INSERT ' + @rptTable +
				'	SELECT * FROM #rpt_araging ' )


IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pif') IS NOT NULL)
	DROP TABLE #pif
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#rates') IS NOT NULL)
	DROP TABLE #rates
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#customers_to_print') IS NOT NULL)
	DROP TABLE #customers_to_print
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#parent_credit_check') IS NOT NULL)
	DROP TABLE #parent_credit_check
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#ag_brk_map') IS NOT NULL)
	DROP TABLE #ag_brk_map
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#ctemp') IS NOT NULL)
	DROP TABLE #ctemp
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#parent_validation') IS NOT NULL)
	DROP TABLE #parent_validation 
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#parent_validation2') IS NOT NULL)
	DROP TABLE #parent_validation2
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#void_brackets') IS NOT NULL)
	DROP TABLE #void_brackets
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pif') IS NOT NULL)
	DROP TABLE #pif
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#cc_rpt_eboage') IS NOT NULL)
	DROP TABLE #cc_rpt_eboage



	SET NOCOUNT Off

	SELECT 	@err_flag,
				@rate_error,
				@phone_mask,
				@company_name,
				@mc_flag,
				@title,
				@hdr_str_1,
				@hdr_str_2,
				@hdr_str_3,
				@hdr_str_4,
				@order_by_na,
				@tier_label1,
				@tier_label2,
				@tier_label3,
				@tier_label4,
				@tier_label5,
				@tier_label6,
				@tier_label7,
				@tier_label8,
				@tier_label9,
				@tier_label10,
				@txt_groupby0,
				@txt_groupby1,
				@precision_home,
				@precision_oper,
				@home_symbol,
				@oper_symbol,
				@home_currency,
				@oper_currency,
				@hdr_str_5,
				@hdr_str_6,
				@hdr_str_0

GO
GRANT EXECUTE ON  [dbo].[cc_aging_nat_accts_sp] TO [public]
GO
