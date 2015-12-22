SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
--  
--  
-- CVO :: SEP.2010  -  Set Revenue Account on Line Item based on the Orders Territory Code  
--  
--  
-- v1.1 CB 15/11/2011 -  Add NOLOCK
  
CREATE PROCEDURE [dbo].[CVO_Set_Revenue_Acct_sp]  @Order_no Int, @Order_ext Int  
   
AS  
  
DECLARE @account_code  varchar(32),          
  @territory_code  varchar(8),  
  @BT_country_code varchar(4),  
  @CVO_Rev_Acct  varchar(32),          
  @i_gl_rev_acct  varchar(32),          
  @line_no   int  
  
  
SELECT  @territory_code = ISNULL(UPPER(SUBSTRING(ship_to_region,1,2)),' ') 
FROM	orders (NOLOCK) 
WHERE	order_no = @Order_no 
AND		ext = @Order_ext  -- v1.1
  
IF @territory_code = ''  
 RETURN  
 

UPDATE	o
SET		gl_rev_acct = SUBSTRING(gl_rev_acct,1,4) + @territory_code + SUBSTRING(gl_rev_acct,7,7) 
FROM	ord_list o (NOLOCK)
JOIN	glchart gl (NOLOCK)
ON		SUBSTRING(o.gl_rev_acct,1,4) + @territory_code + SUBSTRING(o.gl_rev_acct,7,7) = gl.account_code
WHERE	o.order_no = @Order_no
AND		o.order_ext = @Order_ext
AND		gl.inactive_flag = 0

IF EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE ISNULL(gl_rev_acct,'') = '' OR SUBSTRING(gl_rev_acct,5,2) <> @territory_code
			AND order_no = @Order_no AND order_ext = @Order_ext )
BEGIN
   RAISERROR 94106 'Revenue Account Invalid. The Transaction Cannot be Completed.'  
END

/*

 
DECLARE ORDER_CURSOR CURSOR FOR SELECT o.line_no, o.gl_rev_acct    
      FROM ord_list o (NOLOCK)  WHERE o.order_no = @Order_no AND o.order_ext = @Order_ext -- v1.1
  
OPEN ORDER_CURSOR  
FETCH NEXT FROM ORDER_CURSOR INTO @line_no, @i_gl_rev_acct  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  
 SELECT @CVO_Rev_Acct = SUBSTRING(@i_gl_rev_acct,1,4)+@territory_code+SUBSTRING(@i_gl_rev_acct,7,7)  
 IF NOT exists (SELECT 1 FROM glchart (nolock) WHERE account_code = @CVO_Rev_Acct AND inactive_flag = 0)     
  BEGIN             
   RAISERROR 94106 'Revenue Account Invalid. The Transaction Cannot be Completed.'  
   CLOSE ORDER_CURSOR  
   DEALLOCATE ORDER_CURSOR    
  RETURN             
 END              
  
 UPDATE ord_list SET gl_rev_acct = @CVO_Rev_Acct FROM ord_list  
  WHERE order_no = @Order_no AND order_ext = @Order_ext AND line_no = @line_no          
 --  
 FETCH NEXT FROM ORDER_CURSOR INTO @line_no, @i_gl_rev_acct  
  
END  
  
CLOSE ORDER_CURSOR  
DEALLOCATE ORDER_CURSOR  

*/ 

GO
GRANT EXECUTE ON  [dbo].[CVO_Set_Revenue_Acct_sp] TO [public]
GO
