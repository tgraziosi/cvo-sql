SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_get_non_promo_order_commission_sp](@order_no int, @order_ext int)  
AS  
BEGIN  
 DECLARE @use_commission smallint,  
   @commission decimal (20,8),  
   @cust_code varchar(10),  
   @salesperson varchar(10),  
   @price_code varchar(8)  
  
 -- Get information we need to do this  
 SELECT  
  @cust_code = a.cust_code,  
  @salesperson = a.salesperson,  
  @price_code = c.price_code  
 FROM  
  dbo.orders_all a (NOLOCK)  
 INNER JOIN  
  dbo.armaster_all c (NOLOCK)  
 ON  
  a.cust_code = c.customer_code  
 WHERE  
  a.order_no = @order_no  
  AND a.ext = @order_ext  
  AND c.address_type = 0  
  

 -- 1.CHECK FOR CUSTOMER LEVEL COMMISSION  
 IF (ISNULL(@cust_code,'') <> '')   
 BEGIN  
  SELECT  @use_commission = 0,  
    @commission = 0  
  
  SELECT   
   @use_commission = commissionable,  
   @commission = commission  
  FROM  
   dbo.cvo_armaster_all (NOLOCK)  
  WHERE  
   customer_code = @cust_code  
   AND address_type = 0  
  
  IF (ISNULL(@use_commission,0) = 1) AND (@commission IS NOT NULL)  
  BEGIN  
   SELECT @commission
   RETURN  
  END  
 END  
  
 -- 2.CHECK FOR SALESPERSON LEVEL COMMISSION  
 IF (ISNULL(@salesperson,'') <> '')   
 BEGIN  
  SELECT  @use_commission = 0,  
    @commission = 0  
  
  SELECT   
   @use_commission = escalated_commissions,  
   @commission = commission  
  FROM  
   dbo.arsalesp (NOLOCK)  
  WHERE  
   salesperson_code = @salesperson  
  
  IF (ISNULL(@use_commission,0) = 1) AND (@commission IS NOT NULL)  
  BEGIN  
   SELECT @commission  
   RETURN
  END  
 END  
  
 -- 3.CHECK FOR PRICE CLASS LEVEL COMMISSION  
 IF (ISNULL(@price_code,'') <> '')   
 BEGIN  
  SELECT @commission = 0  
  
  SELECT   
   @commission = commission_pct  
  FROM  
   dbo.cvo_comm_pclass (NOLOCK)  
  WHERE  
   price_code = @price_code  
  
  IF @commission IS NOT NULL  
  BEGIN  
   SELECT @commission  
   RETURN
  END  
 END  
  
 -- No commission found - return 0  
 SELECT 0  
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_get_non_promo_order_commission_sp] TO [public]
GO
