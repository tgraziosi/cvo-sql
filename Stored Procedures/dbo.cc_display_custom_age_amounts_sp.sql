SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_display_custom_age_amounts_sp] 	@customer_code		varchar(8),	
																										@date_type_parm		tinyint 	= 3,					 
																										@agebrk_user_id	 	int = 0,
																										@all_org_flag			smallint = 0,	 
																										@from_org varchar(30) = '',
																										@to_org varchar(30) = ''

 	
 	
AS
	SET NOCOUNT ON
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
		@str_age_bracket_1	varchar(20),
		@str_age_bracket_2	varchar(20),
		@str_age_bracket_3	varchar(20),
		@str_age_bracket_4	varchar(20),
		@str_age_bracket_5	varchar(20),
		@str_age_bracket_6	varchar(20),
		@str_age_bracket_7	varchar(20),
		@str_age_bracket_8	varchar(20),
		@str_age_bracket_9	varchar(20),
		@str_age_bracket_10	varchar(20)

	IF ( SELECT ib_flag FROM glco ) = 0
		SELECT @all_org_flag = 1


	SELECT 	@date_asof = DATEDIFF(dd, "1/1/1753", CONVERT(datetime, getdate())) + 639906


	IF @date_type_parm = 1
			SELECT @date_type_string = "Document Date"
	IF @date_type_parm = 2
			SELECT @date_type_string = "Apply Date"
	IF @date_type_parm = 4
			SELECT @date_type_string = "Due Date"
	IF @date_type_parm = 3
			SELECT @date_type_string = "Aging Date"

				
	SELECT	@precision_home 	= curr_precision,
		@multi_currency_flag 	= multi_currency_flag,
		@home_currency 		= home_currency,
		@home_symbol 		= symbol
	FROM	glcurr_vw, glco
	WHERE	glco.home_currency 	= glcurr_vw.currency_code


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
		cust_po_num		varchar(20)	NULL,
		paid_flag		smallint	NULL,
		rate_oper 		float		NULL ,
		org_id						varchar(30) 
	)



	CREATE TABLE #age_summary
	(	customer_code		varchar(8)	NULL,
		amount			float	NULL,
		amt_age_bracket1	float	NULL,
		amt_age_bracket2	float	NULL,
		amt_age_bracket3	float	NULL,
		amt_age_bracket4	float	NULL,
		amt_age_bracket5	float	NULL,
		amt_age_bracket6	float	NULL,
		amt_age_bracket7	float	NULL,		 
		amt_age_bracket8	float	NULL,		 
		amt_age_bracket9	float	NULL,		 
		amt_age_bracket10	float	NULL
	) 

	CREATE TABLE #non_zero_records
	(
		doc_ctrl_num 		varchar(16), 
		trx_type 		smallint, 
		customer_code 		varchar(8), 
		total 			float
	)


	IF @all_org_flag = 1
		INSERT #non_zero_records
		SELECT 	apply_to_num , 
						apply_trx_type, 
						customer_code, 
						SUM(amount) 
		FROM 	artrxage
		WHERE 	customer_code = @customer_code
		GROUP BY customer_code, apply_to_num, apply_trx_type 
		HAVING ABS(SUM(amount)) > 0.0000001 
	ELSE
		INSERT #non_zero_records
		SELECT 	apply_to_num , 
						apply_trx_type, 
						customer_code, 
						SUM(amount) 
		FROM 	artrxage
		WHERE 	customer_code = @customer_code
		AND	org_id BETWEEN @from_org AND @to_org
		GROUP BY customer_code, apply_to_num, apply_trx_type 
		HAVING ABS(SUM(amount)) > 0.0000001 
	



	INSERT #artrxage_tmp 
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
					'', 
					a.customer_code, 
					a.payer_cust_code, 
					'', 
					a.ref_id,
					cust_po_num,
					paid_flag,
					a.rate_oper,
					a.org_id 
	FROM 	artrxage a,#non_zero_records c 
	WHERE a.apply_to_num = c.doc_ctrl_num 
	AND 	a.apply_trx_type = c.trx_type 
	AND 	a.customer_code = c.customer_code
					


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




		
	UPDATE #artrxage_tmp
	SET amount = (SELECT ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home))
	
	IF @date_type_parm = 1
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

	IF @date_type_parm = 2
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

	IF @date_type_parm = 3
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
/*=========================================================================================================*/
	IF @date_type_parm = 4
		BEGIN	
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket1 = amount
			WHERE 	(@date_asof - date_due) < -30
			--	WHERE 	(@date_asof - date_due) <= @e_age_bracket_1

			UPDATE 	#artrxage_tmp
			SET 	amt_age_bracket2 = amount
			WHERE 	(@date_asof - date_due) >= -30
			AND 	(@date_asof - date_due) <= 0
			--	WHERE 	(@date_asof - date_due) >= @b_age_bracket_2 
			--	AND 	(@date_asof - date_due) <= @e_age_bracket_2

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket3 = amount
			WHERE 	(@date_asof - date_due) >= 1 
			AND 	(@date_asof - date_due) <= 30
			--	WHERE 	(@date_asof - date_due) >= @b_age_bracket_3 
			--	AND 	(@date_asof - date_due) <= @e_age_bracket_3

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket4 = amount
			WHERE 	(@date_asof - date_due) >= 31 
			AND 	(@date_asof - date_due) <= 60
			--	WHERE 	(@date_asof - date_due) >= @b_age_bracket_4 
			--	AND 	(@date_asof - date_due) <= @e_age_bracket_4

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket5 = amount
			WHERE 	(@date_asof - date_due) >= 61 
			AND 	(@date_asof - date_due) <= 90
			--	WHERE 	(@date_asof - date_due) >= @b_age_bracket_5 
			--	AND 	(@date_asof - date_due) <= @e_age_bracket_5
		
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket6 = amount
			WHERE 	(@date_asof - date_due) >= 91
			AND 	(@date_asof - date_due) <= 120
			--	WHERE 	(@date_asof - date_due) >= @b_age_bracket_6 
			--	AND 	(@date_asof - date_due) <= @e_age_bracket_6

			UPDATE #artrxage_tmp
			SET 	amt_age_bracket7 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_5 
			AND 	(@date_asof - date_due) <= @e_age_bracket_5
			--	WHERE 	(@date_asof - date_due) >= @b_age_bracket_7 
			--	AND 	(@date_asof - date_due) <= @e_age_bracket_7
		
			UPDATE #artrxage_tmp
			SET 	amt_age_bracket8 = amount
			WHERE 	(@date_asof - date_due) >= @b_age_bracket_10
			--	WHERE 	(@date_asof - date_due) >= @b_age_bracket_8 
			--	AND 	(@date_asof - date_due) <= @e_age_bracket_8

			--UPDATE #artrxage_tmp
			--SET 	amt_age_bracket9 = amount
			--WHERE 	(@date_asof - date_due) >= @b_age_bracket_10
			--	WHERE 	(@date_asof - date_due) >= @b_age_bracket_9 
			--	AND 	(@date_asof - date_due) <= @e_age_bracket_9
		
			--UPDATE #artrxage_tmp
			--SET 	amt_age_bracket10 = amount
			--WHERE 	(@date_asof - date_due) >= @b_age_bracket_10
		END

/*=========================================================================================================*/



	INSERT #age_summary
	SELECT 	customer_code, 
					SUM(amount),
					SUM(amt_age_bracket1),
					SUM(amt_age_bracket2),
					SUM(amt_age_bracket3),
					SUM(amt_age_bracket4),
					SUM(amt_age_bracket5),
					SUM(amt_age_bracket6),
					SUM(amt_age_bracket7),
					SUM(amt_age_bracket8),
					SUM(amt_age_bracket9),
					SUM(amt_age_bracket10)
	FROM 	#artrxage_tmp 
	GROUP BY customer_code

 				 
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


	SELECT 	customer_code,
					amount,
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
					@home_currency
	FROM #age_summary

	DROP TABLE #artrxage_tmp 
	DROP TABLE #age_summary
	DROP TABLE #non_zero_records 
	SET NOCOUNT OFF


GO
GRANT EXECUTE ON  [dbo].[cc_display_custom_age_amounts_sp] TO [public]
GO
