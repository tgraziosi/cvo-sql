SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROC [dbo].[arcranst_sp] @tier_level  smallint,  
    @relation_code varchar(8),  
    @customer_code varchar(8),  
    @next_customer varchar(8) OUTPUT  
AS  
BEGIN  
  
   
 DELETE #arcrchk  
   
   
 IF ( @tier_level = 1 )  
 BEGIN  
  SELECT @next_customer = parent  
  FROM artierrl (NOLOCK)  
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND parent = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 2 )  
 BEGIN  
  SELECT @next_customer = child_1  
  FROM artierrl (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND child_1 = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 3 )  
 BEGIN  
  SELECT @next_customer = child_2  
  FROM artierrl (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND child_2 = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 4 )  
 BEGIN  
  SELECT @next_customer = child_3  
  FROM artierrl (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK)  
  WHERE relation_code = @relation_code  
  AND child_3 = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 5 )  
 BEGIN  
  SELECT @next_customer = child_4  
  FROM artierrl (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND child_4 = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 6 )  
 BEGIN  
  SELECT @next_customer = child_5  
  FROM artierrl  (NOLOCK)
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND child_5 = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 7 )  
 BEGIN  
  SELECT @next_customer = child_6  
  FROM artierrl (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK)  
  WHERE relation_code = @relation_code  
  AND child_6 = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 8 )  
 BEGIN  
  SELECT @next_customer = child_7  
  FROM artierrl (NOLOCK)  
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND child_7 = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 9 )  
 BEGIN  
  SELECT @next_customer = child_8  
  FROM artierrl (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND child_8 = @next_customer  
  AND rel_cust = customer_code  
 END  
 ELSE  
 IF ( @tier_level = 10 )  
 BEGIN  
  SELECT @next_customer = child_9  
  FROM artierrl (NOLOCK) 
  WHERE relation_code = @relation_code  
  AND rel_cust = @customer_code  
  
  INSERT #arcrchk  
  SELECT DISTINCT rel_cust, check_credit_limit, credit_limit, limit_by_home  
  FROM artierrl (NOLOCK), arcust (NOLOCK)  
  WHERE relation_code = @relation_code  
  AND child_9 = @next_customer  
  AND rel_cust = customer_code  
 END  
END  
  
RETURN  
GO
GRANT EXECUTE ON  [dbo].[arcranst_sp] TO [public]
GO
