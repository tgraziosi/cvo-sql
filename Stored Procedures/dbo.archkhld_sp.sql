SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[archkhld_sp]
AS

DECLARE	
		@customer_code	varchar(8),
		@customer_count	int,	
		@amt_home		float,
		@amt_oper		float,
		@amt_over		float, 
		@date_over		int, 
		@credit_failed	varchar(8), 
		@aging_failed		varchar(8), 
		@credit_check_relcode	varchar(8),
		@ret_stat		smallint,
		@module		smallint,
		@home_precision	smallint,
		@oper_precision	smallint,
		@cur_date		int
		

BEGIN

SELECT @cur_date = datediff(dd,"1/1/80",getdate())+722815

SELECT	@home_precision = curr_precision
FROM	glco, glcurr_vw
WHERE	glco.home_currency = glcurr_vw.currency_code
	
SELECT	@oper_precision = curr_precision
FROM	glco, glcurr_vw
WHERE	glco.oper_currency = glcurr_vw.currency_code


CREATE TABLE #customers
(
	id	numeric identity,
	customer_code	varchar(16),
	amt_oper	float,
	amt_home	float
)

INSERT	#customers (customer_code, amt_oper, amt_home)
SELECT	customer_code, 
	SUM((SIGN(amt_due * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_due * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),
	SUM((SIGN(amt_due * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_due * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision)))
FROM	#arvalchg
GROUP BY customer_code

SELECT @customer_count = @@rowcount



SELECT	@module = 4

WHILE ( @customer_count > 0 )
BEGIN
 
		
	SELECT	@amt_home = amt_home,
		@amt_oper = amt_oper,
		@customer_code = customer_code
	FROM	#customers
	WHERE	id = @customer_count
 
	SELECT	@customer_count = @customer_count - 1
	
	EXEC @ret_stat = archklmt_sp	@customer_code, 
						@amt_home,
						@amt_oper,
						@cur_date, 
						@module, 
						@amt_over		OUTPUT, 
						@date_over		OUTPUT, 
						@credit_failed	OUTPUT, 
						@aging_failed		OUTPUT, 
						@credit_check_relcode OUTPUT
	
	IF ( @ret_stat = -1 )
	BEGIN
		
		UPDATE #arvalchg
		SET temp_flag = 1,
			date_applied = 20920
		WHERE customer_code = @customer_code
		AND	temp_flag = 0
		CONTINUE
	END
 
	
	IF ( @ret_stat = -2 )
	BEGIN
		
		UPDATE #arvalchg
		SET temp_flag = 1,
			date_applied = 20921
		WHERE customer_code = @customer_code
		AND	temp_flag = 0
		CONTINUE
	END


END 

DROP TABLE #customers

RETURN
END
GO
GRANT EXECUTE ON  [dbo].[archkhld_sp] TO [public]
GO
