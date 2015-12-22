SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 24/10/2012 - based on f_recalc_coop_dollars, but changed to SP as need to insert into cvo_coop_dollars_history table

-- versons for function  
-- vx.1 TAG    - Added order history tables  
-- vx.2 CT 26/09/2012 - Fixed bug with  NULL @total_sales  
-- vx.3 CT 19/10/2012 - When calculating if customer has reached coop threshold, only use orders which are of the correct order category   
            
CREATE PROC [dbo].[cvo_recalc_coop_dollars_sp](	@cust_code VARCHAR(8),
												@coop_dollars_return decimal(20,8) OUTPUT,
												@write_history SMALLINT = 0)            
AS              
BEGIN  
  
  
 declare @coop_eligible varchar(8),   
   @coop_threshold_flag char(1),   
   @coop_threshold_amount decimal(20,8),   
   @coop_dollars decimal(20,8),   
   @coop_notes varchar(255),   
   @coop_cust_rate_flag char(1),   
   @coop_cust_rate int,   
  
   @coop_general_rate DECIMAL(20,8),   
   @coop_general_account varchar(40),  
   @coop_general_minsales DECIMAL(20,8),  
  
   @order_category varchar(40),  
   @user_category varchar(40),  
  
   @rate_for_use DECIMAL(20,8),  
   @minsales_for_use decimal(20,8),  
   @coop_dollars_amount decimal(20,8),  
   @customer_code VARCHAR(10),  
  
   --Cursor Variables  
   @order_no_cur int,   
   @ext_cur int,   
   @total_amt_order_cur decimal(20,8),  
   @coop_points_calculated decimal(20,8),  
   @coop_date datetime,  
   @coop_percentage decimal(20,8)  
     
 DECLARE @order_type char(1),   
   @coop_ytd DECIMAL(20,8)   
  
 DECLARE @total_sales decimal(20,8), -- vx.1  
   @total_sales_hist decimal(20,8) -- vx.2  
  

 SET @coop_dollars_return = 0

 --Get all the values from tables into the variables at the customer level  
 SELECT @coop_eligible = ISNULL(t.coop_eligible, ''),   
     @coop_threshold_flag = ISNULL(t.coop_threshold_flag, ''),   
     @coop_threshold_amount = ISNULL(t.coop_threshold_amount, 0),   
     @coop_dollars = t.coop_dollars,  
     @coop_notes = ISNULL(t.coop_notes, ''),   
     @coop_cust_rate_flag = ISNULL(t.coop_cust_rate_flag, ''),   
     @coop_cust_rate = ISNULL(t.coop_cust_rate, 0)  
 FROM CVO_armaster_all t (NOLOCK)  
 WHERE t.customer_code = @cust_code  
   AND t.address_type = 0  
  
 --Get the values from tables into variables at application level  
 select @coop_general_account = ISNULL(value_str, '') from config (NOLOCK) where flag = 'COOP_ACCOUNT'  
 select @coop_general_minsales = CAST(ISNULL(value_str, '0') as DECIMAL(20,8))  from config (NOLOCK) where flag = 'COOP_MINSALES'  
 select @coop_general_rate = CAST(ISNULL(value_str, '0') as DECIMAL(20,8)) from config (NOLOCK) where flag = 'COOP_RATE'   
  
  
--***********Validations*******************************************************************  
 -- 1st - Check if the customer is coop eligible or not -------------------  
 if @coop_eligible <> 'Y'  
  begin  
   return 0  
  end  
  
 -- AMENDEZ, Verify the threshold amount  
 -- 2nd and 3rd - Check if the threshold is assigned ----------  
 if @coop_threshold_flag = 'Y'  --Then its by customer level  
 BEGIN  
  IF @coop_threshold_amount = 0  
  BEGIN  
   IF @coop_general_minsales = 0  
   BEGIN  
    return 0  
   END  
   ELSE  
   BEGIN  
    SELECT @minsales_for_use = @coop_general_minsales  
   END  
  END  
  ELSE  
  BEGIN  
   SELECT @minsales_for_use = @coop_threshold_amount  
  END  
 END  
 ELSE --It's by application level  
 BEGIN  
  IF @coop_general_minsales = 0  
  BEGIN  
   return 0  
  END  
  ELSE  
  BEGIN  
   SELECT @minsales_for_use = @coop_general_minsales  
  END  
 END  
     
 -- AMENDEZ, Verify the rate porcentage  
 -- 2nd and 3rd - Check if the Rate is assigned ----------  
 IF @coop_cust_rate = 0  
 BEGIN  
  IF @coop_general_rate = 0  
  BEGIN  
   return 0  
  END  
  ELSE  
  BEGIN  
   SELECT @rate_for_use = @coop_general_rate  
  END  
 END  
 ELSE  
 BEGIN  
  SELECT @rate_for_use = @coop_cust_rate  
 END  
  
   
 --Check if the customer reach the Rate Sales of the year   
 -- START vx.1  
 SELECT   
  @total_sales = SUM(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END)   
 FROM   
  dbo.orders (NOLOCK)            -- TLM : Fix  
 WHERE   
  cust_code = @cust_code    
  AND orders.status > 'S'   
  AND orders.status <> 'V'               
  AND orders.invoice_date BETWEEN (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)) AND  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))  
  AND ((orders.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (orders.[type] = 'C')) -- vx.3  
  
 -- START vx.2  
 --select @total_sales = @total_sales + (select sum(CASE WHEN type = 'C' THEN ((ISNULL(total_amt_order,0)   
 SELECT   
  @total_sales_hist = SUM(CASE WHEN type = 'C' THEN ((ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0)) * -1) ELSE ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0) END)   
 FROM   
  dbo.cvo_orders_all_hist (NOLOCK)           -- TLM : Fix  
 WHERE   
  cust_code = @cust_code    
  AND status > 'S'   
  AND status <> 'V'               
  AND invoice_date BETWEEN (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)) AND  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))  
  AND ((user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR ([type] = 'C')) -- vx.3  
  
 SET @total_sales = ISNULL(@total_sales,0) + ISNULL(@total_sales_hist,0)  
 -- END vx.2  
--  
-- if ISNULL((select sum(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END) from orders (NOLOCK) -- vx.4            -- TLM : Fix  
--    where cust_code = @cust_code    
--    and orders.status > 'S' and orders.status <> 'V'               
--    and orders.invoice_date   
--    between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))     
--    and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))  
--    ),0) < @minsales_for_use  
 If @total_sales <@minsales_for_use  
    -- END vx.1  
 begin  
  return 0  
 end  
  
--***********End Validations****************************************************************??  
  
  
 select @coop_date = getdate()   
   
  
 --Sum accumulated points   
   
 --For each order of the current year calculate the coop dollars  
 select @coop_dollars_amount = 0  
  
 DECLARE coop_order CURSOR FOR  
   SELECT   
    order_no,   
    ext,   
    ISNULL(CASE WHEN type = 'C' THEN ((ISNULL(gross_sales,0) - ISNULL(total_discount,0)) * -1) ELSE ISNULL(gross_sales,0) - ISNULL(total_discount,0) END,0),
	ISNULL(invoice_date,date_shipped)   
   from orders (NOLOCK)  
   where cust_code = @cust_code  
   AND ((orders.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (orders.[type] = 'C')) 
   and orders.invoice_date               
   between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))     
   and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))   
   -- START vx.1  
   UNION  
   SELECT   
    order_no,   
    ext,   
    ISNULL(CASE WHEN type = 'C' THEN ((ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0)) * -1) ELSE ISNULL(total_amt_order,0) - ISNULL(tot_ord_disc,0) END,0),
	ISNULL(invoice_date,date_shipped)   
   from cvo_orders_all_hist oh (NOLOCK)  
   where cust_code = @cust_code  
   AND ((oh.user_category IN (SELECT order_category FROM CVO_order_types WHERE category_eligible = 'Y')) OR (oh.[type] = 'C')) 
   and oh.invoice_date               
   between (SELECT DATEADD(yy, DATEDIFF(yy,0,getdate()), 0))     
   and  (SELECT dateadd(year, 1, dateadd(ms,-3,DATEADD(yy, DATEDIFF(yy,0,getdate() ), 0))))   
   -- END vx.1  
   
 OPEN coop_order            
 FETCH NEXT FROM coop_order           
 INTO  @order_no_cur,   
    @ext_cur,   
    @total_amt_order_cur,
	@coop_date        
                
   WHILE @@FETCH_STATUS = 0   
   BEGIN       
     
  set @coop_percentage = @rate_for_use / cast(100 as decimal(20,8))  
  set @coop_points_calculated =  ROUND(@total_amt_order_cur  * @coop_percentage,2)  
  SET @coop_dollars_amount = @coop_dollars_amount + @coop_points_calculated   
  
  IF ISNULL(@write_history,0) = 1
  BEGIN 
	INSERT cvo_coop_dollars_history(order_no, order_ext, coop_dollars, coop_date, customer_code)
	VALUES(@order_no_cur, @ext_cur, @coop_points_calculated, @coop_date, @cust_code)
  END

   FETCH NEXT FROM coop_order            
   INTO  @order_no_cur,   
     @ext_cur,   
     @total_amt_order_cur,
	 @coop_date                 
   END            
  
  CLOSE coop_order  
  DEALLOCATE coop_order  
  SET @coop_dollars_return = @coop_dollars_amount  
  
  
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_recalc_coop_dollars_sp] TO [public]
GO
