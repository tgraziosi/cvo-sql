SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apagdact.SPv - e7.2.2 : 1.10
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




	





CREATE PROCEDURE [dbo].[apagdact_sp]
	@date_asof int,		@class_flag smallint,	@branch_flag smallint,	
	@from_cls char(8),	@end_cls char(8),	@from_bch char(8),	
	@end_bch char(8),	@age_brk1 smallint, 	@age_brk2 smallint, 	
	@age_brk3 smallint, 	@age_brk4 smallint, 	@age_brk5 smallint
AS


IF @class_flag = 1
BEGIN

	
	UPDATE apactcls
	SET	amt_age_bracket1 = 0,
		amt_age_bracket2 = 0,
		amt_age_bracket3 = 0,
		amt_age_bracket4 = 0,
		amt_age_bracket5 = 0,
		amt_age_bracket6 = 0
	WHERE class_code BETWEEN @from_cls AND @end_cls

 SELECT class_code,
		age_bracket1=sum(amount - amt_paid_to_date)
 INTO #actcls1
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging <= @age_brk1
 AND class_code BETWEEN @from_cls AND @end_cls 
GROUP	BY class_code 

UPDATE apactcls
SET amt_age_bracket1 = age_bracket1
FROM apactcls,#actcls1
WHERE apactcls.class_code = #actcls1.class_code
AND age_bracket1 IS NOT NULL


 SELECT class_code,
 		age_bracket2 = sum(amount - amt_paid_to_date)
 INTO #actcls2
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging BETWEEN @age_brk1 + 1 AND @age_brk2
 AND class_code BETWEEN @from_cls AND @end_cls 
GROUP	BY class_code 

UPDATE apactcls
SET amt_age_bracket2 = age_bracket2
FROM apactcls,#actcls2
WHERE apactcls.class_code = #actcls2.class_code
AND age_bracket2 IS NOT NULL




 SELECT class_code,
 		age_bracket3 = sum(amount - amt_paid_to_date)
 INTO #actcls3
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging BETWEEN @age_brk2 + 1 AND @age_brk3
 AND class_code BETWEEN @from_cls AND @end_cls 
GROUP	BY class_code 

UPDATE apactcls
SET amt_age_bracket3 = age_bracket3
FROM apactcls,#actcls3
WHERE apactcls.class_code = #actcls3.class_code
AND age_bracket3 IS NOT NULL


 SELECT class_code,
 		age_bracket4 = sum(amount - amt_paid_to_date)
 INTO #actcls4
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging BETWEEN @age_brk3 + 1 AND @age_brk4
 AND class_code BETWEEN @from_cls AND @end_cls 
GROUP	BY class_code 

UPDATE apactcls
SET amt_age_bracket4 = age_bracket4
FROM apactcls,#actcls4
WHERE apactcls.class_code = #actcls4.class_code
AND age_bracket4 IS NOT NULL



 SELECT class_code,
 		age_bracket5 = sum(amount - amt_paid_to_date)
 INTO #actcls5
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging BETWEEN @age_brk4 + 1 AND @age_brk5
 AND class_code BETWEEN @from_cls AND @end_cls 
GROUP	BY class_code 

UPDATE apactcls
SET amt_age_bracket5 = age_bracket5
FROM apactcls,#actcls5
WHERE apactcls.class_code = #actcls5.class_code
AND age_bracket5 IS NOT NULL



 SELECT class_code,
 		age_bracket6 = sum(amount - amt_paid_to_date)
 INTO #actcls6
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging > @age_brk5
 AND class_code BETWEEN @from_cls AND @end_cls 
GROUP	BY class_code 


UPDATE apactcls
SET amt_age_bracket6 = age_bracket6
FROM apactcls,#actcls6
WHERE apactcls.class_code = #actcls6.class_code
AND age_bracket6 IS NOT NULL



 SELECT class_code,
 on_acct_amt = sum(amount)
 INTO #actcls7
 FROM	aptrxage
 WHERE	apply_to_num = "ONACCT"
 AND	class_code BETWEEN @from_cls AND @end_cls
 GROUP	BY class_code 




UPDATE apactcls
SET amt_age_bracket6 = amt_age_bracket6 - on_acct_amt
FROM apactcls,#actcls7
WHERE apactcls.class_code = #actcls7.class_code
AND on_acct_amt IS NOT NULL



UPDATE	apactcls
SET	amt_balance = 

(SIGN(( amt_age_bracket1 + amt_age_bracket2 + amt_age_bracket3 + amt_age_bracket4 + amt_age_bracket5 + amt_age_bracket6 )) * ROUND(ABS(( amt_age_bracket1 + amt_age_bracket2 + amt_age_bracket3 + amt_age_bracket4 + amt_age_bracket5 + amt_age_bracket6 )) + 0.0000001, 2))


DROP TABLE #actcls1
DROP TABLE #actcls2
DROP TABLE #actcls3
DROP TABLE #actcls4
DROP TABLE #actcls5
DROP TABLE #actcls6
DROP TABLE #actcls7

END


IF @branch_flag = 1
BEGIN

	
	UPDATE apactbch
	SET	amt_age_bracket1 = 0,
		amt_age_bracket2 = 0,
		amt_age_bracket3 = 0,
		amt_age_bracket4 = 0,
		amt_age_bracket5 = 0,
		amt_age_bracket6 = 0
	WHERE	branch_code BETWEEN @from_bch AND @end_bch

 SELECT branch_code,
		age_bracket1=sum(amount - amt_paid_to_date)
 INTO #actbch1
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging <= @age_brk1
 AND branch_code BETWEEN @from_bch AND @end_bch 
GROUP	BY branch_code 

UPDATE apactbch
SET amt_age_bracket1 = age_bracket1
FROM apactbch,#actbch1
WHERE apactbch.branch_code = #actbch1.branch_code
AND age_bracket1 IS NOT NULL


 SELECT branch_code,
 		age_bracket2 = sum(amount - amt_paid_to_date)
 INTO #actbch2
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging BETWEEN @age_brk1 + 1 AND @age_brk2
 AND branch_code BETWEEN @from_bch AND @end_bch 
GROUP	BY branch_code 

UPDATE apactbch
SET amt_age_bracket2 = age_bracket2
FROM apactbch,#actbch2
WHERE apactbch.branch_code = #actbch2.branch_code
AND age_bracket2 IS NOT NULL




 SELECT branch_code,
 		age_bracket3 = sum(amount - amt_paid_to_date)
 INTO #actbch3
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging BETWEEN @age_brk2 + 1 AND @age_brk3
 AND branch_code BETWEEN @from_bch AND @end_bch 
GROUP	BY branch_code 

UPDATE apactbch
SET amt_age_bracket3 = age_bracket3
FROM apactbch,#actbch3
WHERE apactbch.branch_code = #actbch3.branch_code
AND age_bracket3 IS NOT NULL


 SELECT branch_code,
 		age_bracket4 = sum(amount - amt_paid_to_date)
 INTO #actbch4
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging BETWEEN @age_brk3 + 1 AND @age_brk4
 AND branch_code BETWEEN @from_bch AND @end_bch 
GROUP	BY branch_code 

UPDATE apactbch
SET amt_age_bracket4 = age_bracket4
FROM apactbch,#actbch4
WHERE apactbch.branch_code = #actbch4.branch_code
AND age_bracket4 IS NOT NULL



 SELECT branch_code,
 		age_bracket5 = sum(amount - amt_paid_to_date)
 INTO #actbch5
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging BETWEEN @age_brk4 + 1 AND @age_brk5
 AND branch_code BETWEEN @from_bch AND @end_bch 
GROUP	BY branch_code 

UPDATE apactbch
SET amt_age_bracket5 = age_bracket5
FROM apactbch,#actbch5
WHERE apactbch.branch_code = #actbch5.branch_code
AND age_bracket5 IS NOT NULL



 SELECT branch_code,
 		age_bracket6 = sum(amount - amt_paid_to_date)
 INTO #actbch6
 FROM	aptrxage
 WHERE	trx_type IN ( 4031, 4091 )			
 AND	paid_flag = 0
 AND	@date_asof - date_aging > @age_brk5
 AND branch_code BETWEEN @from_bch AND @end_bch 
GROUP	BY branch_code 


UPDATE apactbch
SET amt_age_bracket6 = age_bracket6
FROM apactbch,#actbch6
WHERE apactbch.branch_code = #actbch6.branch_code
AND age_bracket6 IS NOT NULL



 SELECT branch_code,
 on_acct_amt = sum(amount)
 INTO #actbch7
 FROM	aptrxage
 WHERE	apply_to_num = "ONACCT"
 AND	branch_code BETWEEN @from_bch AND @end_bch
 GROUP	BY branch_code 




UPDATE apactbch
SET amt_age_bracket6 = amt_age_bracket6 - on_acct_amt
FROM apactbch,#actbch7
WHERE apactbch.branch_code = #actbch7.branch_code
AND on_acct_amt IS NOT NULL



UPDATE	apactbch
SET	amt_balance = 

(SIGN(( amt_age_bracket1 + amt_age_bracket2 + amt_age_bracket3 + amt_age_bracket4 + amt_age_bracket5 + amt_age_bracket6 )) * ROUND(ABS(( amt_age_bracket1 + amt_age_bracket2 + amt_age_bracket3 + amt_age_bracket4 + amt_age_bracket5 + amt_age_bracket6 )) + 0.0000001, 2))


DROP TABLE #actbch1
DROP TABLE #actbch2
DROP TABLE #actbch3
DROP TABLE #actbch4
DROP TABLE #actbch5
DROP TABLE #actbch6
DROP TABLE #actbch7

END


GO
GRANT EXECUTE ON  [dbo].[apagdact_sp] TO [public]
GO
