SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[aragsact_sp] 
		@date_asof	int,		
 		@from_slp	varchar(8),	
 		@thru_slp	varchar(8), 
 		@age_brk1	smallint, 	 
 		@age_brk2	smallint,
		@age_brk3	smallint, 	
		@age_brk4	smallint, 	
		@age_brk5	smallint
AS

DECLARE 
	@precision_home	smallint,
	@precision_oper	smallint

SELECT	@precision_home = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.home_currency = glcurr_vw.currency_code

SELECT	@precision_oper = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.oper_currency = glcurr_vw.currency_code

BEGIN

	CREATE TABLE #aractslp (
					salesperson_code	varchar(8),
					amt_age_bracket1	float,
					amt_age_bracket2	float,
					amt_age_bracket3	float,
					amt_age_bracket4	float,
					amt_age_bracket5	float,
					amt_age_bracket6	float,
					amt_age_b1_oper	float, 
					amt_age_b2_oper	float, 
					amt_age_b3_oper	float, 
					amt_age_b4_oper	float, 
					amt_age_b5_oper	float, 
					amt_age_b6_oper	float 
				 )
				 
	CREATE TABLE #aractslp_zero (
					salesperson_code	varchar(8),
					amt_age_bracket1	float,
					amt_age_bracket2	float,
					amt_age_bracket3	float,
					amt_age_bracket4	float,
					amt_age_bracket5	float,
					amt_age_bracket6	float,
					amt_age_b1_oper	float, 
					amt_age_b2_oper	float, 
					amt_age_b3_oper	float, 
					amt_age_b4_oper	float, 
					amt_age_b5_oper	float, 
					amt_age_b6_oper	float 
				 )

	INSERT	#aractslp_zero
	SELECT	DISTINCT 
			salesperson_code,
			0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
	FROM	arsalesp
	WHERE	salesperson_code >= @from_slp
	AND	salesperson_code <= @thru_slp
	AND	( LTRIM(salesperson_code) IS NOT NULL AND LTRIM(salesperson_code) != " " )
	
	INSERT	#aractslp 
	SELECT	salesperson_code, 
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper))
	FROM 	artrxage
	WHERE	paid_flag = 0
	AND	doc_ctrl_num = sub_apply_num
	AND	trx_type = sub_apply_type
	AND	salesperson_code >= @from_slp
	AND	salesperson_code <= @thru_slp
	AND	ref_id > 0
	AND	( LTRIM(salesperson_code) IS NOT NULL AND LTRIM(salesperson_code) != " " )
	GROUP BY salesperson_code

	UPDATE	#aractslp_zero
	SET 	amt_age_bracket1 =	a.amt_age_bracket1,
	 	amt_age_bracket2 =	a.amt_age_bracket2,
	 	amt_age_bracket3 =	a.amt_age_bracket3,
	 	amt_age_bracket4 =	a.amt_age_bracket4,
	 	amt_age_bracket5 =	a.amt_age_bracket5,
	 	amt_age_bracket6 =	a.amt_age_bracket6,
		amt_age_b1_oper =	a.amt_age_b1_oper, 
		amt_age_b2_oper =	a.amt_age_b2_oper, 
		amt_age_b3_oper =	a.amt_age_b3_oper, 
		amt_age_b4_oper =	a.amt_age_b4_oper, 
		amt_age_b5_oper =	a.amt_age_b5_oper, 
		amt_age_b6_oper =	a.amt_age_b6_oper 
	FROM	#aractslp a
	WHERE	#aractslp_zero.salesperson_code = a.salesperson_code

	DROP TABLE #aractslp

	  

	 UPDATE 	aractslp
	 SET 	amt_age_bracket1 =	cus.amt_age_bracket1,
		 	amt_age_bracket2 =	cus.amt_age_bracket2,
		 	amt_age_bracket3 =	cus.amt_age_bracket3,
		 	amt_age_bracket4 =	cus.amt_age_bracket4,
		 	amt_age_bracket5 =	cus.amt_age_bracket5,
		 	amt_age_bracket6 =	cus.amt_age_bracket6,
			amt_age_b1_oper =	cus.amt_age_b1_oper, 
			amt_age_b2_oper =	cus.amt_age_b2_oper, 
			amt_age_b3_oper =	cus.amt_age_b3_oper, 
			amt_age_b4_oper =	cus.amt_age_b4_oper, 
			amt_age_b5_oper =	cus.amt_age_b5_oper, 
			amt_age_b6_oper =	cus.amt_age_b6_oper, 
			last_age_upd_date = @date_asof 
	 FROM	#aractslp_zero cus
	 WHERE 	cus.salesperson_code = aractslp.salesperson_code
	 
	DROP TABLE #aractslp_zero
 
END




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[aragsact_sp] TO [public]
GO
