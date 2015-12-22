SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










                                                















CREATE PROC [dbo].[fs_apactinp_sp]
	@vendor_code	varchar(12),
	@pay_to_code	varchar(8),
	@class_code	varchar(8),
	@branch_code	varchar(8),
	@amt_net	float,
	@rate_home float,
	@rate_oper float
AS
DECLARE	@count smallint, @class smallint, @branch smallint, @payto smallint,
	@vend smallint
DECLARE 
	@home_precision	smallint,
	@oper_precision	smallint,
	@amt_net_home	float,
	@amt_net_oper	float


SELECT	@vend = apactvnd_flag,
	@class = apactcls_flag,
	@branch = apactbch_flag,
	@payto = apactpto_flag
FROM	apco

 
SELECT @home_precision = b.curr_precision,
	 @oper_precision = c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code


SELECT @amt_net_home = (SIGN(@amt_net * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(@amt_net * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @home_precision))
SELECT @amt_net_oper = (SIGN(@amt_net * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) * ROUND(ABS(@amt_net * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) + 0.0000001, @oper_precision))


IF 	@vend = 1
BEGIN
	
	IF ( NOT EXISTS ( SELECT vendor_code FROM apactvnd
	 WHERE vendor_code = @vendor_code ) )
	INSERT	apactvnd
	VALUES ( NULL,		
	 	@vendor_code,	
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
		0,
		0,
		0,
		0,
		0,
		0,
		@amt_net_home,	
		0,		
		'',		
		'',		
		'', 		
		'', 		
		'', 		
		'', 		
		'', 		
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
		0,		
		'',		
		'',		
		'',		
		'',		
		'',		
		0,		
		0,
		0,
		0,
		0,
		0,
		0,		
		@amt_net_oper,		
		0,		
		0)		
 ELSE
	UPDATE	apactvnd
	SET	amt_on_order = amt_on_order + @amt_net_home,
		amt_on_order_oper = amt_on_order_oper + @amt_net_oper
	WHERE vendor_code = @vendor_code
END
















































































































































































































GO
GRANT EXECUTE ON  [dbo].[fs_apactinp_sp] TO [public]
GO
