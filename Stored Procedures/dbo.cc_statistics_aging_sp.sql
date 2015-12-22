SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cc_statistics_aging_sp]	@customer_code		varchar(8),	
																				@date_type_conv		smallint 	= 3,				
																				@date_asof		int,
																				@total float OUTPUT, 	
																				@age1	float OUTPUT, 	
																				@age2	float OUTPUT, 	
																				@age3	float OUTPUT, 	
																				@age4	float OUTPUT, 	
																				@age5	float OUTPUT, 	
																				@age6	float OUTPUT,
																				@all_org_flag			smallint = 0,	 
																				@from_org varchar(30) = '',
																				@to_org varchar(30) = '',
																				@age0	float OUTPUT
						
	
AS
	BEGIN

		SET QUOTED_IDENTIFIER OFF
		SET NOCOUNT ON

		DECLARE
			@e_age_bracket_1	smallint,
			@e_age_bracket_2	smallint,
			@e_age_bracket_3	smallint,
			@e_age_bracket_4	smallint,
			@e_age_bracket_5	smallint,

			@b_age_bracket_1	smallint,
			@b_age_bracket_2	smallint,
			@b_age_bracket_3	smallint,
			@b_age_bracket_4	smallint,
			@b_age_bracket_5	smallint,
			@b_age_bracket_6	smallint,
	 	@precision_home		smallint,
			@symbol			varchar(8),
			@home_currency		varchar(8),
			@multi_currency_flag	smallint,
			@date_type_string	varchar(14)
			

		SELECT @date_type_conv = 4


		IF @date_type_conv = 1
			SELECT @date_type_string = "Document Date"
		ELSE IF @date_type_conv = 2
			SELECT @date_type_string = "Applied Date"
		ELSE IF @date_type_conv = 3
			SELECT @date_type_string = "Aging Date"
		ELSE IF @date_type_conv = 4
			SELECT @date_type_string = "Due Date"

		
		SELECT	@precision_home 	= curr_precision,
			@multi_currency_flag 	= multi_currency_flag,
			@home_currency 		= home_currency,
			@symbol 		= symbol
		FROM	glcurr_vw, glco
		WHERE	glco.home_currency 	= glcurr_vw.currency_code
	


		SELECT 	@e_age_bracket_1 	= age_bracket1,
			@e_age_bracket_2 	= age_bracket2,
			@e_age_bracket_3 	= age_bracket3,
			@e_age_bracket_4 	= age_bracket4,
			@e_age_bracket_5 	= age_bracket5 
		FROM arco


		SELECT 	@b_age_bracket_2 	= @e_age_bracket_1 + 1,
			@b_age_bracket_3 	= @e_age_bracket_2 + 1,
			@b_age_bracket_4 	= @e_age_bracket_3 + 1,
			@b_age_bracket_5 	= @e_age_bracket_4 + 1,
			@b_age_bracket_6 	= @e_age_bracket_5 + 1 


		SELECT 	@e_age_bracket_1 	= 30,
						@e_age_bracket_2 	= 60,
						@e_age_bracket_3 	= 90,
						@e_age_bracket_4 	= 120,
						@e_age_bracket_5 	= 150


		SELECT 	@b_age_bracket_1 	= 1,
						@b_age_bracket_2 	= 31,
						@b_age_bracket_3 	= 61,
						@b_age_bracket_4 	= 91,
						@b_age_bracket_5 	= 121,
						@b_age_bracket_6 	= 151


		CREATE TABLE #artrxage_stats
		(
			trx_type 		smallint, 
			trx_ctrl_num 		varchar(16), 
			doc_ctrl_num 		varchar(16), 
			apply_to_num 		varchar(16), 
			apply_trx_type 		smallint, 
			sub_apply_num 		varchar(16), 
			sub_apply_type 		smallint, 
			territory_code 		varchar(8), 
			date_doc 		int, 
			date_due 		int, 
			date_aging 		int, 
			date_applied 		int, 
			amount 			float,	
			on_acct			float,
			amt_age_bracket1	float,	
			amt_age_bracket2 	float,
			amt_age_bracket3	float,
			amt_age_bracket4	float,
			amt_age_bracket5	float,
			amt_age_bracket6	float,		 
			nat_cur_code 		varchar(8), 
			rate_home 		float, 
			rate_type 		varchar(8), 
			customer_code 		varchar(8), 
			payer_cust_code 	varchar(8), 
			trx_type_code 		varchar(8), 
			ref_id 			int,

			date_required	int,
			amt_age_bracket0	float	)




		
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
			AND org_id BETWEEN @from_org AND @to_org



			GROUP BY customer_code, apply_to_num, apply_trx_type 
			HAVING ABS(SUM(amount)) > 0.0000001 
	




		INSERT #artrxage_stats 
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
				a.nat_cur_code, 
				a.rate_home, 
				' ', 
				a.customer_code, 
				a.payer_cust_code, 
				' ', 
				a.ref_id,

				h.date_required,
				0
			FROM 	artrxage a,#non_zero_records i, artrx_all h
			WHERE a.customer_code = @customer_code
			AND 	a.apply_to_num = i.doc_ctrl_num 
			AND 	a.apply_trx_type = i.trx_type 
			AND 	a.customer_code = i.customer_code 

			AND 	a.trx_ctrl_num = h.trx_ctrl_num



























		UPDATE #artrxage_stats
		SET 	date_due = b.date_due
		FROM 	#artrxage_stats, #artrxage_stats b
		WHERE #artrxage_stats.trx_ctrl_num = b.trx_ctrl_num
		AND 	#artrxage_stats.ref_id = -1
		AND 	b.ref_id = 0
		AND 	#artrxage_stats.date_due = 0 
		
		UPDATE #artrxage_stats 
		SET date_doc = b.date_doc
		FROM #artrxage_stats , #artrxage_stats b
		WHERE #artrxage_stats.trx_ctrl_num = b.trx_ctrl_num
		AND #artrxage_stats.ref_id = -1
		AND b.ref_id = 0
		AND #artrxage_stats.date_doc = 0 
		
		UPDATE #artrxage_stats 
		SET date_aging = b.date_aging
		FROM #artrxage_stats , #artrxage_stats b
		WHERE #artrxage_stats.trx_ctrl_num = b.trx_ctrl_num
		AND #artrxage_stats.ref_id = -1
		AND b.ref_id = 0
		AND #artrxage_stats.date_aging = 0
		
		UPDATE #artrxage_stats 
		SET date_applied = b.date_applied
		FROM #artrxage_stats , #artrxage_stats b
		WHERE #artrxage_stats.trx_ctrl_num = b.trx_ctrl_num
		AND #artrxage_stats.ref_id = -1
		AND b.ref_id = 0
		AND #artrxage_stats.date_applied = 0

	
		UPDATE #artrxage_stats
			SET amount = (SELECT ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home))


--select trx_ctrl_num , @date_asof_str , date_doc, @date_asof_str - date_doc, date_due, @date_asof - date_due, date_aging, @date_asof - date_aging, date_applied, @date_asof - date_applied, amount from #artrxage_stats 

		
		IF @date_type_conv = 1
			BEGIN	

				UPDATE #artrxage_stats
				SET 	amt_age_bracket0 = amount
				WHERE 	(@date_asof - date_doc) < @b_age_bracket_1

				UPDATE #artrxage_stats
				SET 	amt_age_bracket1 = amount

				WHERE 	(@date_asof - date_doc) >= @b_age_bracket_1
				AND 	(@date_asof - date_doc) <= @e_age_bracket_1
			
				UPDATE 	#artrxage_stats
				SET 	amt_age_bracket2 = amount
				WHERE 	(@date_asof - date_doc) >= @b_age_bracket_2
				AND 	(@date_asof - date_doc) <= @e_age_bracket_2
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket3 = amount
				WHERE 	(@date_asof - date_doc) >= @b_age_bracket_3
				AND 	(@date_asof - date_doc) <= @e_age_bracket_3
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket4 = amount
				WHERE 	(@date_asof - date_doc) >= @b_age_bracket_4
				AND 	(@date_asof - date_doc) <= @e_age_bracket_4
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket5 = amount
				WHERE 	(@date_asof - date_doc) >= @b_age_bracket_5
				AND 	(@date_asof - date_doc) <= @e_age_bracket_5
					
				UPDATE #artrxage_stats
				SET 	amt_age_bracket6 = amount
				WHERE 	(@date_asof - date_doc) >= @b_age_bracket_6
			END

		ELSE IF @date_type_conv = 2
			BEGIN	

				UPDATE #artrxage_stats
				SET 	amt_age_bracket0 = amount
				WHERE 	(@date_asof - date_applied) < @b_age_bracket_1

				UPDATE #artrxage_stats
				SET 	amt_age_bracket1 = amount

				WHERE 	(@date_asof - date_applied) >= @b_age_bracket_1
				AND 	(@date_asof - date_applied) <= @e_age_bracket_1
			
				UPDATE 	#artrxage_stats
				SET 	amt_age_bracket2 = amount
				WHERE 	(@date_asof - date_applied) >= @b_age_bracket_2
				AND 	(@date_asof - date_applied) <= @e_age_bracket_2
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket3 = amount
				WHERE 	(@date_asof - date_applied) >= @b_age_bracket_3
				AND 	(@date_asof - date_applied) <= @e_age_bracket_3
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket4 = amount
				WHERE 	(@date_asof - date_applied) >= @b_age_bracket_4
				AND 	(@date_asof - date_applied) <= @e_age_bracket_4
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket5 = amount
				WHERE 	(@date_asof - date_applied) >= @b_age_bracket_5
				AND 	(@date_asof - date_applied) <= @e_age_bracket_5
					
				UPDATE #artrxage_stats
				SET 	amt_age_bracket6 = amount
				WHERE 	(@date_asof - date_applied) >= @b_age_bracket_6

			END

		ELSE IF @date_type_conv = 3
			BEGIN	

				UPDATE #artrxage_stats
				SET 	amt_age_bracket0 = amount
				WHERE 	(@date_asof - date_aging) < @b_age_bracket_1

				UPDATE #artrxage_stats
				SET 	amt_age_bracket1 = amount

				WHERE 	(@date_asof - date_aging) >= @b_age_bracket_1
				AND 	(@date_asof - date_aging) <= @e_age_bracket_1
			
				UPDATE 	#artrxage_stats
				SET 	amt_age_bracket2 = amount
				WHERE 	(@date_asof - date_aging) >= @b_age_bracket_2
				AND 	(@date_asof - date_aging) <= @e_age_bracket_2
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket3 = amount
				WHERE 	(@date_asof - date_aging) >= @b_age_bracket_3
				AND 	(@date_asof - date_aging) <= @e_age_bracket_3
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket4 = amount
				WHERE 	(@date_asof - date_aging) >= @b_age_bracket_4
				AND 	(@date_asof - date_aging) <= @e_age_bracket_4
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket5 = amount
				WHERE 	(@date_asof - date_aging) >= @b_age_bracket_5
				AND 	(@date_asof - date_aging) <= @e_age_bracket_5
					
				UPDATE #artrxage_stats
				SET 	amt_age_bracket6 = amount
				WHERE 	(@date_asof - date_aging) >= @b_age_bracket_6
			END

		ELSE IF @date_type_conv = 4
			BEGIN	

				UPDATE #artrxage_stats
				SET 	amt_age_bracket0 = amount
				WHERE 	(@date_asof - date_due) < @b_age_bracket_1

				UPDATE #artrxage_stats
				SET 	amt_age_bracket1 = amount

				WHERE 	(@date_asof - date_due) >= @b_age_bracket_1
				AND 	(@date_asof - date_due) <= @e_age_bracket_1
			
				UPDATE 	#artrxage_stats
				SET 	amt_age_bracket2 = amount
				WHERE 	(@date_asof - date_due) >= @b_age_bracket_2
				AND 	(@date_asof - date_due) <= @e_age_bracket_2
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket3 = amount
				WHERE 	(@date_asof - date_due) >= @b_age_bracket_3
				AND 	(@date_asof - date_due) <= @e_age_bracket_3
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket4 = amount
				WHERE 	(@date_asof - date_due) >= @b_age_bracket_4
				AND 	(@date_asof - date_due) <= @e_age_bracket_4
			
				UPDATE #artrxage_stats
				SET 	amt_age_bracket5 = amount
				WHERE 	(@date_asof - date_due) >= @b_age_bracket_5
				AND 	(@date_asof - date_due) <= @e_age_bracket_5
					
				UPDATE #artrxage_stats
				SET 	amt_age_bracket6 = amount
				WHERE 	(@date_asof - date_due) >= @b_age_bracket_6
			END


































			SELECT 	@total = SUM(amount)
			FROM 	#artrxage_stats 
			SELECT	@age1 = SUM(amt_age_bracket1)
			FROM 	#artrxage_stats 
			SELECT	@age2 = SUM(amt_age_bracket2)
			FROM 	#artrxage_stats 
			SELECT	@age3 = SUM(amt_age_bracket3)
			FROM 	#artrxage_stats 
			SELECT	@age4 = SUM(amt_age_bracket4)
			FROM 	#artrxage_stats 
			SELECT	@age5 = SUM(amt_age_bracket5)
			FROM 	#artrxage_stats 
			SELECT	@age6 = SUM(amt_age_bracket6)
			FROM 	#artrxage_stats 
			SELECT	@age0 = SUM(amt_age_bracket0)
			FROM 	#artrxage_stats 
			











			
		DROP TABLE #artrxage_stats 		
		DROP TABLE #non_zero_records 

END 
GO
GRANT EXECUTE ON  [dbo].[cc_statistics_aging_sp] TO [public]
GO
