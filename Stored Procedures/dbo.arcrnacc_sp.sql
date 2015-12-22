SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
CREATE PROC [dbo].[arcrnacc_sp] @customer_code varchar(8),  
    @relation_code varchar(8),  
    @tier_level  smallint,  
    @amount_home  float,  
    @amount_oper  float,  
    @module  smallint,  
    @amt_over  float    OUTPUT,   
    @credit_failed varchar(8) OUTPUT  
AS  
DECLARE   
  @credit_limit   float,   
  @credit_check_failed  smallint,   
  @next_customer  varchar(8),  
  @total_unposted_cm  float,  
  @limit_by_home  smallint,  
  @curr_precision  smallint,  
  @check_credit_limit  smallint,  
  @over_amt   float  
  
  
SELECT  @credit_failed = NULL,   
  @amt_over = 0.0,  
  @next_customer = @customer_code,   
  @credit_check_failed = 0  
  
  
  
DELETE #arcrchk  
  
  
WHILE (@tier_level > 0)							--v3.0 AND @credit_check_failed = 0 )  
BEGIN  
   
 EXEC arcranst_sp @tier_level, @relation_code, @customer_code, @next_customer OUTPUT  
  
 SELECT @check_credit_limit = ISNULL(check_credit_limit,0),  
  @credit_limit = ISNULL(credit_limit,0.0),  
  @limit_by_home = ISNULL(limit_by_home,0)  
 FROM #arcrchk  
 WHERE customer_code = @next_customer  
  
   
 IF (@limit_by_home = 0)  
  SELECT @curr_precision = curr_precision,  
   @amount_home = ROUND(@amount_home, curr_precision)  
  FROM glco (NOLOCK), glcurr_vw (NOLOCK)
  WHERE home_currency = currency_code  
 ELSE  
  SELECT @curr_precision = curr_precision,  
   @amount_oper = ROUND(@amount_oper, curr_precision)  
  FROM glco (NOLOCK), glcurr_vw  (NOLOCK)
  WHERE oper_currency = currency_code  
  
   
 IF ( @module = 4 )  
  SELECT @credit_limit = credit_limit  
  FROM arcust (NOLOCK)  
  WHERE customer_code = @next_customer  
  AND check_credit_limit = 1  
  
   
 IF ( @check_credit_limit > 0 )  
 BEGIN  
  IF(@limit_by_home = 0)   
  BEGIN  
     
   SELECT @total_unposted_cm = ISNULL( SUM(ROUND(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ),@curr_precision)), 0.0 )  
   FROM arinpchg (NOLOCK), #arcrchk  
   WHERE arinpchg.customer_code = #arcrchk.customer_code  
   AND trx_type = 2032  
   AND hold_flag = 0  
    
    SELECT @amt_over =  @amount_home - @total_unposted_cm - @credit_limit +  
       ISNULL((SELECT SUM( amt_balance   
         + amt_inv_unposted   
         + amt_on_order  
        - amt_on_acct )   
     FROM aractcus (NOLOCK), #arcrchk  
     WHERE aractcus.customer_code = #arcrchk.customer_code ),0.0)  
  END  
  ELSE   
  BEGIN  
     
   SELECT @total_unposted_cm = ISNULL( SUM(ROUND(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ),@curr_precision)), 0.0 )  
   FROM arinpchg (NOLOCK) 
   WHERE customer_code = @customer_code  
   AND trx_type = 2032  
   AND hold_flag = 0  
    
      
    SELECT @amt_over =  @amount_oper - @total_unposted_cm - @credit_limit +   
       ISNULL((SELECT SUM( amt_balance_oper   
         + amt_inv_unp_oper   
         + amt_on_order_oper  
        - amt_on_acct_oper )   
     FROM aractcus (NOLOCK), #arcrchk  
     WHERE aractcus.customer_code = #arcrchk.customer_code ),0.0)  
  END  
 END   
   
   
	IF ( SIGN(@amt_over) > 0 AND @check_credit_limit > 0)
	  BEGIN
		SELECT @credit_failed = @next_customer
		SELECT @credit_check_failed = 1
	  END
	ELSE
	  BEGIN
		SELECT	@customer_code = @next_customer
		SELECT	@total_unposted_cm = 0.0, @over_amt = 0.0
	  END
 
	SELECT	@tier_level = @tier_level - 1        
	SELECT	@customer_code = @next_customer

	IF ( @credit_check_failed = 1 and  @tier_level = 0)  
	  BEGIN
		BREAK
	  END
END  
  
RETURN  
  
GO
GRANT EXECUTE ON  [dbo].[arcrnacc_sp] TO [public]
GO
