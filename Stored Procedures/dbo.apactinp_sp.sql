SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apactinp.SPv - e7.2.2 : 1.11
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                















CREATE PROC [dbo].[apactinp_sp]
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
		0,		
		@amt_net_home,	
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
		0,		
		@amt_net_oper,		
		0)		
 ELSE
	UPDATE	apactvnd
	SET	amt_vouch_unposted = amt_vouch_unposted + @amt_net_home,
		amt_vouch_unposted_oper = amt_vouch_unposted_oper + @amt_net_oper
	WHERE vendor_code = @vendor_code
END



IF 	@payto = 1 AND @pay_to_code IS NOT NULL AND @pay_to_code != SPACE(8)
BEGIN
	
	IF ( NOT EXISTS ( SELECT vendor_code FROM apactpto
	 WHERE vendor_code = @vendor_code
	 AND pay_to_code = @pay_to_code ) )
	INSERT	apactpto
	VALUES ( NULL,		
	 	@vendor_code,	
	 	@pay_to_code,	
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
		0,		
		@amt_net_home,	
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
		0,		
		@amt_net_oper,		
		0)		
 ELSE
	UPDATE	apactpto
	SET	amt_vouch_unposted = amt_vouch_unposted + @amt_net_home,
		amt_vouch_unposted_oper = amt_vouch_unposted_oper + @amt_net_oper
	WHERE pay_to_code = @pay_to_code
	AND	vendor_code = @vendor_code
END


IF 	@class = 1 AND @class_code IS NOT NULL AND @class_code != SPACE(8)
BEGIN
	
	IF ( NOT EXISTS ( SELECT class_code FROM apactcls
	 WHERE class_code = @class_code ) )
	INSERT	apactcls
	VALUES ( NULL,		
	 	@class_code,	
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
		0,		
		@amt_net_home,	
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
		0,		
		@amt_net_oper,		
		0)		
 ELSE
	UPDATE	apactcls
	SET	amt_vouch_unposted = amt_vouch_unposted + @amt_net_home,
		amt_vouch_unposted_oper = amt_vouch_unposted_oper + @amt_net_oper
	WHERE	class_code = @class_code
END


IF 	@branch = 1 AND @branch_code IS NOT NULL AND @branch_code != SPACE(8)
BEGIN
	
	IF ( NOT EXISTS ( SELECT branch_code FROM apactbch
	 WHERE branch_code = @branch_code ) )
	INSERT	apactbch
	VALUES ( NULL,		
	 	@branch_code,	
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
		0,		
		@amt_net_home,	
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
		0,		
		@amt_net_oper,		
		0)		
 ELSE
	UPDATE	apactbch
	SET	amt_vouch_unposted = amt_vouch_unposted + @amt_net_home,
		amt_vouch_unposted_oper = amt_vouch_unposted_oper + @amt_net_oper
	WHERE	branch_code = @branch_code
END


GO
GRANT EXECUTE ON  [dbo].[apactinp_sp] TO [public]
GO
