SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC	[dbo].[arageact_sp] 
		@date_asof		int,
		@cust_flag		smallint,		
		@prc_flag		smallint,   
		@slp_flag		smallint,		
		@ter_flag		smallint,   
		@from_cust		varchar(8),	
		@thru_cust		varchar(8),  
		@from_prc		varchar(8),	
		@thru_prc		varchar(8), 
		@from_slp		varchar(8),	
		@thru_slp		varchar(8),   
		@from_ter		varchar(8),	
		@thru_ter		varchar(8),
		@all_cust_flag	smallint,   
		@all_price_flag	smallint,   
		@all_slp_flag		smallint,   
		@all_terr_flag	smallint   
		
AS

DECLARE 
   	@age_brk1		smallint,	  
   	@age_brk2		smallint,            
   	@age_brk3		smallint,            
	@age_brk4		smallint,           
   	@age_brk5		smallint,     
   	@shp_flag		smallint,            
	@precision_home	smallint,
	@precision_oper	smallint,
	@multi_currency_flag	smallint,
	@MIN_ASCII 		int,	
	@MAX_ASCII 		int,		
	@MAX_DASCII		int,
	@position 		int









SELECT @date_asof = datediff(dd,"1/1/1800",getdate())+657072

SELECT	@precision_home = curr_precision,
	@multi_currency_flag = multi_currency_flag
FROM	glcurr_vw, glco
WHERE	glco.home_currency = glcurr_vw.currency_code

SELECT	@precision_oper = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.oper_currency = glcurr_vw.currency_code


SELECT @MIN_ASCII = 32,
	@MAX_ASCII = 254,
	@MAX_DASCII = 1200

SET @position = 1
WHILE @position <= 255
   BEGIN
	IF CHAR(@position) > CHAR(@MAX_ASCII)  SET @MAX_ASCII = @position
	SET @position = @position + 1
   END




IF ( @all_cust_flag = 1 )
	SELECT @from_cust = CHAR(@MIN_ASCII),
		@thru_cust = REPLICATE(ISNULL(CHAR(@MAX_DASCII), CHAR(@MAX_ASCII)),8)
IF ( @all_price_flag = 1 )
	SELECT	@from_prc = CHAR(@MIN_ASCII),
		@thru_prc = ISNULL(CHAR(@MAX_DASCII), CHAR(@MAX_ASCII))
IF ( @all_slp_flag = 1 )
	SELECT @from_slp = CHAR(@MIN_ASCII),
		@thru_slp = ISNULL(CHAR(@MAX_DASCII), CHAR(@MAX_ASCII))
IF ( @all_terr_flag = 1 )
	SELECT	@from_ter = CHAR(@MIN_ASCII),
		@thru_ter = ISNULL(CHAR(@MAX_DASCII), CHAR(@MAX_ASCII))
	



SELECT  
   	@age_brk1 = age_bracket1,
	@age_brk2 = age_bracket2,
	@age_brk3 = age_bracket3,
	@age_brk4 = age_bracket4,
	@age_brk5 = age_bracket5,
	@shp_flag = aractshp_flag
FROM    arco





IF @cust_flag = 1
BEGIN

	CREATE TABLE #aractcus (
					cust_code		varchar(8),
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

	


	CREATE TABLE #aractcus_zero (
					cust_code		varchar(8),
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
				  
	INSERT	#aractcus_zero
	SELECT	DISTINCT 
			customer_code,
			0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
	FROM 	artrxage
	WHERE	customer_code BETWEEN @from_cust AND @thru_cust

	


	INSERT	#aractcus 
	SELECT	customer_code, 
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
	AND	customer_code BETWEEN @from_cust AND @thru_cust
	AND	doc_ctrl_num = sub_apply_num
	AND	trx_type = sub_apply_type
	AND	ref_id > 0
	GROUP BY customer_code


	UPDATE	#aractcus_zero
	SET 	amt_age_bracket1 =	a.amt_age_bracket1,
	   	amt_age_bracket2 =	a.amt_age_bracket2,
	   	amt_age_bracket3 =	a.amt_age_bracket3,
	   	amt_age_bracket4 =	a.amt_age_bracket4,
	   	amt_age_bracket5 =	a.amt_age_bracket5,
	   	amt_age_bracket6 =	a.amt_age_bracket6,
		amt_age_b1_oper  =	a.amt_age_b1_oper,           
		amt_age_b2_oper  =	a.amt_age_b2_oper, 
		amt_age_b3_oper  =	a.amt_age_b3_oper, 
		amt_age_b4_oper  =	a.amt_age_b4_oper, 
		amt_age_b5_oper  =	a.amt_age_b5_oper, 
		amt_age_b6_oper  =	a.amt_age_b6_oper 
	FROM	#aractcus a
	WHERE	#aractcus_zero.cust_code = a.cust_code

	DROP TABLE #aractcus

	

 

	UPDATE	aractcus
	SET	amt_age_bracket1 =	cus.amt_age_bracket1,
		amt_age_bracket2 =	cus.amt_age_bracket2,
		amt_age_bracket3 =	cus.amt_age_bracket3,
		amt_age_bracket4 =	cus.amt_age_bracket4,
		amt_age_bracket5 =	cus.amt_age_bracket5,
		amt_age_bracket6 =	cus.amt_age_bracket6,
		amt_age_b1_oper  =	cus.amt_age_b1_oper,           
		amt_age_b2_oper  =	cus.amt_age_b2_oper, 
		amt_age_b3_oper  =	cus.amt_age_b3_oper, 
		amt_age_b4_oper  =	cus.amt_age_b4_oper, 
		amt_age_b5_oper  =	cus.amt_age_b5_oper, 
		amt_age_b6_oper  =	cus.amt_age_b6_oper,
		last_age_upd_date = @date_asof 
	FROM	#aractcus_zero cus
	WHERE 	customer_code = cust_code
	      
	DROP TABLE #aractcus_zero
	
	



	IF @shp_flag = 1
	BEGIN
	
		CREATE TABLE #aractshp (
						cust_code		varchar(8),
						ship_to_code		varchar(8),
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
					  

		CREATE TABLE #aractshp_zero (
						cust_code		varchar(8),
						ship_to_code		varchar(8),
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
					  
		INSERT	#aractshp_zero
		SELECT	DISTINCT 
				customer_code, ship_to_code,
				0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0
		FROM 	armaster
		WHERE	customer_code BETWEEN @from_cust AND @thru_cust
		AND	( LTRIM(ship_to_code) IS NOT NULL AND LTRIM(ship_to_code) != " " )
		

		


		INSERT	#aractshp 
		SELECT	age.customer_code,
			trx.ship_to_code, 
		SUM(SIGN(1- SIGN( @date_asof - age.date_aging - @age_brk1 )) 
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - age.date_aging - @age_brk2 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - age.date_aging - @age_brk3 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - age.date_aging - @age_brk4 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - age.date_aging - @age_brk5 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk5 - 0.5)) 
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1- SIGN( @date_asof - age.date_aging - @age_brk1 )) 
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - age.date_aging - @age_brk2 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - age.date_aging - @age_brk3 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - age.date_aging - @age_brk4 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - age.date_aging - @age_brk5 ))
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - age.date_aging - @age_brk5 - 0.5)) 
			* ROUND((amount + amt_fin_chg + amt_late_chg - amt_paid) * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper))
		FROM 	artrxage age, artrx trx
		WHERE	trx.trx_ctrl_num = age.trx_ctrl_num
		AND	trx.trx_type = age.trx_type
		AND	age.paid_flag = 0
		AND	age.doc_ctrl_num = age.sub_apply_num
		AND	age.trx_type = age.sub_apply_type
		AND	age.customer_code >= @from_cust
		AND	age.customer_code <= @thru_cust
		AND	age.ref_id > 0
		AND	( LTRIM(trx.ship_to_code) IS NOT NULL AND LTRIM(trx.ship_to_code) != " " )
		GROUP BY age.customer_code, trx.ship_to_code


		UPDATE	#aractshp_zero
		SET 	amt_age_bracket1 =	a.amt_age_bracket1,
		   	amt_age_bracket2 =	a.amt_age_bracket2,
		   	amt_age_bracket3 =	a.amt_age_bracket3,
		   	amt_age_bracket4 =	a.amt_age_bracket4,
		   	amt_age_bracket5 =	a.amt_age_bracket5,
		   	amt_age_bracket6 =	a.amt_age_bracket6,
			amt_age_b1_oper  =	a.amt_age_b1_oper,           
			amt_age_b2_oper  =	a.amt_age_b2_oper, 
			amt_age_b3_oper  =	a.amt_age_b3_oper, 
			amt_age_b4_oper  =	a.amt_age_b4_oper, 
			amt_age_b5_oper  =	a.amt_age_b5_oper, 
			amt_age_b6_oper  =	a.amt_age_b6_oper 
		FROM	#aractshp a
		WHERE	#aractshp_zero.cust_code = a.cust_code
		AND	#aractshp_zero.ship_to_code = a.ship_to_code

		DROP TABLE #aractshp

		      

 

		      UPDATE 	aractshp
		      SET 	amt_age_bracket1 =	cus.amt_age_bracket1,
			   	amt_age_bracket2 =	cus.amt_age_bracket2,
			   	amt_age_bracket3 =	cus.amt_age_bracket3,
			   	amt_age_bracket4 =	cus.amt_age_bracket4,
			   	amt_age_bracket5 =	cus.amt_age_bracket5,
			   	amt_age_bracket6 =	cus.amt_age_bracket6,
				amt_age_b1_oper  =	cus.amt_age_b1_oper,           
				amt_age_b2_oper  =	cus.amt_age_b2_oper, 
				amt_age_b3_oper  =	cus.amt_age_b3_oper, 
				amt_age_b4_oper  =	cus.amt_age_b4_oper, 
				amt_age_b5_oper  =	cus.amt_age_b5_oper, 
				amt_age_b6_oper  =	cus.amt_age_b6_oper,
				last_age_upd_date = @date_asof 
		      FROM	#aractshp_zero cus
		      WHERE 	customer_code = cust_code
		      AND	aractshp.ship_to_code = cus.ship_to_code
		      
	
		DROP TABLE #aractshp_zero
	
	END
END






IF @prc_flag = 1
BEGIN
   EXEC aragdact_sp 
        	@date_asof, 
        	@from_prc,   
        	@thru_prc,      
		@age_brk1,   
		@age_brk2,        
		@age_brk3, 
		@age_brk4,   
		@age_brk5
END




IF @ter_flag = 1
BEGIN
	EXEC aragtact_sp
        	@date_asof, 
        	@from_ter,   
        	@thru_ter,      
		@age_brk1,   
		@age_brk2,        
		@age_brk3, 
		@age_brk4,   
		@age_brk5
END




IF @slp_flag = 1
BEGIN
	EXEC aragsact_sp 
        	@date_asof, 
        	@from_slp,   
        	@thru_slp,      
		@age_brk1,   
		@age_brk2,        
		@age_brk3, 
		@age_brk4,   
		@age_brk5
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arageact_sp] TO [public]
GO
