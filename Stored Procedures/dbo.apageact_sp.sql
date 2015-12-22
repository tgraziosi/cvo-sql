SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apageact.SPv - e7.2.2 : 1.16
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



	











CREATE PROCEDURE [dbo].[apageact_sp]
		@date_asof int,		@vend_flag smallint,		@pto_flag smallint,	
		@branch_flag smallint,	@class_flag smallint,	
		@all_vendor_flag smallint,	@from_vend char(12),		@end_vend char(12),		
		@all_pto_flag smallint,	@from_pto char(8),		@end_pto char(8),
		@all_bch_flag smallint,	@from_bch char(8),		@end_bch char(8),	
		@all_cls_flag smallint,	@from_cls char(8),		@end_cls char(8),	
		@proc_key smallint,		@user_id smallint,		@orig_flag smallint
AS

DECLARE	@age_brk1 smallint, 	@age_brk2 smallint, 	@age_brk3 smallint, 	
		@age_brk4 smallint, 	@age_brk5 smallint,		@pay_to_flag smallint,
		@MIN_ASCII int,	@MAX_ASCII int,		@MAX_DASCII	int,
		@precision_home smallint, @precision_oper smallint

EXEC status_sp "APAGEACT", @proc_key, @user_id,
	"Processing ...", 0.0, @orig_flag, 0

SELECT	@precision_home = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.home_currency = glcurr_vw.currency_code

SELECT	@precision_oper = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.oper_currency = glcurr_vw.currency_code


SELECT	@age_brk1 = age_bracket1,
	@age_brk2 = age_bracket2,
	@age_brk3 = age_bracket3,
	@age_brk4 = age_bracket4,
	@age_brk5 = age_bracket5,
	@pay_to_flag = apactpto_flag
FROM	apco

SELECT @MIN_ASCII = 32,
	@MAX_ASCII = 255,
	@MAX_DASCII = 1200


IF ( @all_vendor_flag = 1 )
	SELECT @from_vend = CHAR(@MIN_ASCII),
		@end_vend = ISNULL(CHAR(@MAX_DASCII), CHAR(@MAX_ASCII))
IF ( @all_pto_flag = 1 )
	SELECT	@from_pto = CHAR(@MIN_ASCII),
		@end_pto = ISNULL(CHAR(@MAX_DASCII), CHAR(@MAX_ASCII))
IF ( @all_bch_flag = 1 )
	SELECT @from_bch = CHAR(@MIN_ASCII),
		@end_bch = ISNULL(CHAR(@MAX_DASCII), CHAR(@MAX_ASCII))
IF ( @all_cls_flag = 1 )
	SELECT	@from_cls = CHAR(@MIN_ASCII),
		@end_cls = ISNULL(CHAR(@MAX_DASCII), CHAR(@MAX_ASCII))
	




IF @vend_flag = 1
BEGIN
	CREATE TABLE #apactvnd (
					vendor_code		varchar(12),
					amt_age_bracket1	float,
					amt_age_bracket2	float,
					amt_age_bracket3	float,
					amt_age_bracket4	float,
					amt_age_bracket5	float,
					amt_age_bracket6	float,
					amt_age_bracket1_oper	float, 
					amt_age_bracket2_oper	float, 
					amt_age_bracket3_oper	float, 
					amt_age_bracket4_oper	float, 
					amt_age_bracket5_oper	float, 
					amt_age_bracket6_oper	float 
				 )


	INSERT #apactvnd
	SELECT	vendor_code, 
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper))
	FROM 	aptrxage
	WHERE	vendor_code BETWEEN @from_vend AND @end_vend
	GROUP BY vendor_code



	UPDATE apactvnd
	SET	amt_age_bracket1 = b.amt_age_bracket1,
		amt_age_bracket2 = b.amt_age_bracket2,
		amt_age_bracket3 = b.amt_age_bracket3,
		amt_age_bracket4 = b.amt_age_bracket4,
		amt_age_bracket5 = b.amt_age_bracket5,
		amt_age_bracket6 = b.amt_age_bracket6,
		amt_age_bracket1_oper = b.amt_age_bracket1_oper,
		amt_age_bracket2_oper = b.amt_age_bracket2_oper,
		amt_age_bracket3_oper = b.amt_age_bracket3_oper,
		amt_age_bracket4_oper = b.amt_age_bracket4_oper,
		amt_age_bracket5_oper = b.amt_age_bracket5_oper,
		amt_age_bracket6_oper = b.amt_age_bracket6_oper
	FROM apactvnd, #apactvnd b
	WHERE apactvnd.vendor_code = b.vendor_code

END


IF @pto_flag = 1
BEGIN
	CREATE TABLE #apactpto (
					vendor_code		varchar(12),
					pay_to_code		varchar(8),
					amt_age_bracket1	float,
					amt_age_bracket2	float,
					amt_age_bracket3	float,
					amt_age_bracket4	float,
					amt_age_bracket5	float,
					amt_age_bracket6	float,
					amt_age_bracket1_oper	float, 
					amt_age_bracket2_oper	float, 
					amt_age_bracket3_oper	float, 
					amt_age_bracket4_oper	float, 
					amt_age_bracket5_oper	float, 
					amt_age_bracket6_oper	float 
				 )


	INSERT #apactpto
	SELECT	vendor_code, 
			pay_to_code,
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper))
	FROM 	aptrxage
	WHERE	vendor_code BETWEEN @from_vend AND @end_vend
	AND		pay_to_code BETWEEN @from_pto AND @end_pto
	AND		pay_to_code != ""
	GROUP BY vendor_code, pay_to_code



	UPDATE apactpto
	SET	amt_age_bracket1 = b.amt_age_bracket1,
		amt_age_bracket2 = b.amt_age_bracket2,
		amt_age_bracket3 = b.amt_age_bracket3,
		amt_age_bracket4 = b.amt_age_bracket4,
		amt_age_bracket5 = b.amt_age_bracket5,
		amt_age_bracket6 = b.amt_age_bracket6,
		amt_age_bracket1_oper = b.amt_age_bracket1_oper,
		amt_age_bracket2_oper = b.amt_age_bracket2_oper,
		amt_age_bracket3_oper = b.amt_age_bracket3_oper,
		amt_age_bracket4_oper = b.amt_age_bracket4_oper,
		amt_age_bracket5_oper = b.amt_age_bracket5_oper,
		amt_age_bracket6_oper = b.amt_age_bracket6_oper
	FROM apactpto, #apactpto b
	WHERE apactpto.vendor_code = b.vendor_code
	AND apactpto.pay_to_code = b.pay_to_code


END


IF @branch_flag = 1
BEGIN
	CREATE TABLE #apactbch (
					branch_code		varchar(8),
					amt_age_bracket1	float,
					amt_age_bracket2	float,
					amt_age_bracket3	float,
					amt_age_bracket4	float,
					amt_age_bracket5	float,
					amt_age_bracket6	float,
					amt_age_bracket1_oper	float, 
					amt_age_bracket2_oper	float, 
					amt_age_bracket3_oper	float, 
					amt_age_bracket4_oper	float, 
					amt_age_bracket5_oper	float, 
					amt_age_bracket6_oper	float 
				 )


	INSERT #apactbch
	SELECT	branch_code, 
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper))
	FROM 	aptrxage
	WHERE	branch_code BETWEEN @from_bch AND @end_bch
	GROUP BY branch_code



	UPDATE apactbch
	SET	amt_age_bracket1 = b.amt_age_bracket1,
		amt_age_bracket2 = b.amt_age_bracket2,
		amt_age_bracket3 = b.amt_age_bracket3,
		amt_age_bracket4 = b.amt_age_bracket4,
		amt_age_bracket5 = b.amt_age_bracket5,
		amt_age_bracket6 = b.amt_age_bracket6,
		amt_age_bracket1_oper = b.amt_age_bracket1_oper,
		amt_age_bracket2_oper = b.amt_age_bracket2_oper,
		amt_age_bracket3_oper = b.amt_age_bracket3_oper,
		amt_age_bracket4_oper = b.amt_age_bracket4_oper,
		amt_age_bracket5_oper = b.amt_age_bracket5_oper,
		amt_age_bracket6_oper = b.amt_age_bracket6_oper
	FROM apactbch, #apactbch b
	WHERE apactbch.branch_code = b.branch_code

END

IF @class_flag = 1
BEGIN
	CREATE TABLE #apactcls (
					class_code		varchar(8),
					amt_age_bracket1	float,
					amt_age_bracket2	float,
					amt_age_bracket3	float,
					amt_age_bracket4	float,
					amt_age_bracket5	float,
					amt_age_bracket6	float,
					amt_age_bracket1_oper	float, 
					amt_age_bracket2_oper	float, 
					amt_age_bracket3_oper	float, 
					amt_age_bracket4_oper	float, 
					amt_age_bracket5_oper	float, 
					amt_age_bracket6_oper	float 
				 )


	INSERT #apactcls
	SELECT	class_code, 
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home)),
		SUM(SIGN(1- SIGN( @date_asof - date_aging - @age_brk1 )) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk2 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk3 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk4 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@date_asof - date_aging - @age_brk5 ))
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper)),
		SUM(SIGN(1 + SIGN(@date_asof - date_aging - @age_brk5 - 0.5)) 
			* ROUND(amount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper))
	FROM 	aptrxage
	WHERE	vendor_code BETWEEN @from_cls AND @end_cls
	GROUP BY class_code



	UPDATE apactcls
	SET	amt_age_bracket1 = b.amt_age_bracket1,
		amt_age_bracket2 = b.amt_age_bracket2,
		amt_age_bracket3 = b.amt_age_bracket3,
		amt_age_bracket4 = b.amt_age_bracket4,
		amt_age_bracket5 = b.amt_age_bracket5,
		amt_age_bracket6 = b.amt_age_bracket6,
		amt_age_bracket1_oper = b.amt_age_bracket1_oper,
		amt_age_bracket2_oper = b.amt_age_bracket2_oper,
		amt_age_bracket3_oper = b.amt_age_bracket3_oper,
		amt_age_bracket4_oper = b.amt_age_bracket4_oper,
		amt_age_bracket5_oper = b.amt_age_bracket5_oper,
		amt_age_bracket6_oper = b.amt_age_bracket6_oper
	FROM apactcls, #apactcls b
	WHERE apactcls.class_code = b.class_code

END


EXEC status_sp "APAGEACT", @proc_key, @user_id,
	"Done", 100.0, @orig_flag, 0

GO
GRANT EXECUTE ON  [dbo].[apageact_sp] TO [public]
GO
