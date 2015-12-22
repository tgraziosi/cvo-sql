SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
  
CREATE PROC [dbo].[aractinp_sp] @customer_code varchar( 8 ),  
    @ship_to_code  varchar( 8 ),  
    @price_code   varchar( 8 ),  
    @salesperson_code varchar( 8 ),  
    @territory_code varchar( 8 ),  
    @amt_home  float,  
    @amt_oper  float,  
    @module_id  smallint   
AS  
  
  
DECLARE @cust   smallint,   
  @slp   smallint,  
  @prc   smallint,  
  @shp   smallint,  
  @ter   smallint,  
  @transtart smallint,  
  @custc  varchar( 8 ),  
  @pricec varchar( 8 ),  
  @custs  varchar( 8 ),  
  @salepc varchar( 8 ),  
  @terrc  varchar( 8 ),  
  @custst varchar( 8 )  
  
  
SELECT @cust = NULL  
  
SELECT @cust = aractcus_flag,  
 @prc = aractprc_flag,  
 @shp = aractshp_flag,  
 @slp = aractslp_flag,  
 @ter = aractter_flag  
FROM arco  (NOLOCK) -- v1.0
  
IF @cust IS NULL  
 RETURN -1  
  
SELECT @custc = customer_code  
FROM aractcus  (NOLOCK) -- v1.0
WHERE customer_code = @customer_code  
  
SELECT  @pricec = price_code   
FROM  aractprc  (NOLOCK) -- v1.0
WHERE  price_code = @price_code   
  
SELECT @custs = customer_code,   
  @custst = ship_to_code  
FROM aractshp  (NOLOCK) -- v1.0
WHERE customer_code = @customer_code   
AND  ship_to_code = @ship_to_code  
  
SELECT @salepc = salesperson_code   
FROM aractslp (NOLOCK) -- v1.0  
WHERE  salesperson_code = @salesperson_code  
  
SELECT  @terrc = territory_code   
FROM  aractter  (NOLOCK) -- v1.0 
WHERE territory_code = @territory_code  
  
IF (@@trancount = 0)  
BEGIN  
 SELECT @transtart = 1  
 BEGIN TRAN  
END  
ELSE  
BEGIN  
 SELECT @transtart = 0  
END  
  
  
IF @cust = 1 AND ( LTRIM(@customer_code) IS NOT NULL AND LTRIM(@customer_code) != " " )  
BEGIN  
 IF ( @custc = @customer_code )  
  IF ( @module_id = 2000 )   
   UPDATE aractcus  
   SET amt_inv_unposted = amt_inv_unposted + @amt_home,  
    amt_inv_unp_oper = amt_inv_unp_oper + @amt_oper    
   WHERE customer_code = @customer_code  
  ELSE      
   UPDATE aractcus  
   SET amt_on_order = amt_on_order + @amt_home,  
    amt_on_order_oper = amt_on_order_oper + @amt_oper    
   WHERE customer_code = @customer_code  
    
 ELSE  
  INSERT aractcus  
  VALUES ( NULL,    
  @customer_code,    
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
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  @amt_home*(ABS(SIGN(@module_id-2000))),    
  @amt_home*(1+SIGN(@module_id-2000)),   
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
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
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  @amt_oper*(ABS(SIGN(@module_id-2000))),    
  @amt_oper*(1+SIGN(@module_id-2000)),   
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  0)      
    
  IF (@@error != 0)  
  BEGIN  
   IF (@transtart = 1 )  
    ROLLBACK TRAN  
   RETURN -1  
  END  
   
END  
  
  
IF @prc = 1 AND ( LTRIM(@price_code) IS NOT NULL AND LTRIM(@price_code) != " " )  
BEGIN  
 IF ( @pricec = @price_code )   
  IF ( @module_id = 2000 )   
   UPDATE aractprc  
   SET amt_inv_unposted = amt_inv_unposted + @amt_home,  
    amt_inv_unp_oper = amt_inv_unp_oper + @amt_oper    
   WHERE price_code = @price_code  
  ELSE     
   UPDATE aractprc  
   SET amt_on_order = amt_on_order + @amt_home,  
    amt_on_order_oper = amt_on_order_oper + @amt_oper    
   WHERE price_code = @price_code  
    
 ELSE  
  INSERT aractprc  
  VALUES ( NULL,    
  @price_code,     
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
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  @amt_home*(ABS(SIGN(@module_id-2000))),    
  @amt_home*(1+SIGN(@module_id-2000)),   
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
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
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  @amt_oper*(ABS(SIGN(@module_id-2000))),    
  @amt_oper*(1+SIGN(@module_id-2000)),   
  0.0,      
  0.0,      
  0.0,      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  0)      
  
  IF (@@error != 0)  
  BEGIN  
   IF (@transtart = 1 )  
    ROLLBACK TRAN  
   RETURN -1  
  END  
END  
  
  
IF @shp = 1 AND ( LTRIM(@customer_code) IS NOT NULL AND LTRIM(@customer_code) != " " ) AND ( LTRIM(@ship_to_code) IS NOT NULL AND LTRIM(@ship_to_code) != " " )   
BEGIN  
 IF ( @custs = @customer_code and @custst = @ship_to_code )  
  IF ( @module_id = 2000 )   
    UPDATE aractshp  
   SET amt_inv_unposted = amt_inv_unposted + @amt_home,  
    amt_inv_unp_oper = amt_inv_unp_oper + @amt_oper    
    WHERE customer_code = @customer_code  
    AND ship_to_code = @ship_to_code  
  ELSE     
    UPDATE aractshp  
   SET amt_on_order = amt_on_order + @amt_home,  
    amt_on_order_oper = amt_on_order_oper + @amt_oper    
    WHERE customer_code = @customer_code  
    AND ship_to_code = @ship_to_code  
  
 ELSE   
 INSERT aractshp  
 VALUES (NULL,      
  @customer_code,    
  @ship_to_code,    
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
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  @amt_home*(ABS(SIGN(@module_id-2000))),    
  @amt_home*(1+SIGN(@module_id-2000)),   
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
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
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  @amt_oper*(ABS(SIGN(@module_id-2000))),    
  @amt_oper*(1+SIGN(@module_id-2000)),   
  0.0,      
  0.0,      
  0.0,      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  0)      
  
  IF (@@error != 0)  
  BEGIN  
   IF (@transtart = 1 )  
    ROLLBACK TRAN  
   RETURN -1  
  END  
END  
  
  
  
IF @slp = 1 AND ( LTRIM(@salesperson_code) IS NOT NULL AND LTRIM(@salesperson_code) != " " )  
BEGIN  
 IF ( @salepc = @salesperson_code )  
  IF ( @module_id = 2000 )   
   UPDATE aractslp  
   SET amt_inv_unposted = amt_inv_unposted + @amt_home,  
    amt_inv_unp_oper = amt_inv_unp_oper + @amt_oper    
   WHERE salesperson_code = @salesperson_code  
  ELSE  
   UPDATE aractslp  
   SET amt_on_order = amt_on_order + @amt_home,  
    amt_on_order_oper = amt_on_order_oper + @amt_oper    
   WHERE salesperson_code = @salesperson_code  
    
 ELSE  
  INSERT aractslp  
  VALUES (NULL,     
  @salesperson_code,    
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
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  @amt_home*(ABS(SIGN(@module_id-2000))),    
  @amt_home*(1+SIGN(@module_id-2000)),   
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
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
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  @amt_oper*(ABS(SIGN(@module_id-2000))),    
  @amt_oper*(1+SIGN(@module_id-2000)),   
  0.0,      
  0.0,      
  0.0,      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  0)      
  
  IF (@@error != 0)  
  BEGIN  
   IF (@transtart = 1 )  
    ROLLBACK TRAN  
   RETURN -1  
  END  
END  
   
  
IF @ter = 1 AND ( LTRIM(@territory_code) IS NOT NULL AND LTRIM(@territory_code) != " " )  
BEGIN  
 IF ( @terrc = @territory_code )  
  IF ( @module_id = 2000 )   
   UPDATE aractter  
   SET amt_inv_unposted = amt_inv_unposted + @amt_home,  
    amt_inv_unp_oper = amt_inv_unp_oper + @amt_oper    
   WHERE territory_code = @territory_code  
  ELSE  
   UPDATE aractter  
   SET amt_on_order = amt_on_order + @amt_home,  
    amt_on_order_oper = amt_on_order_oper + @amt_oper    
   WHERE territory_code = @territory_code  
 ELSE  
  INSERT aractter  
  VALUES (NULL,    
  @territory_code,    
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
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  0,      
  @amt_home*(ABS(SIGN(@module_id-2000))),    
  @amt_home*(1+SIGN(@module_id-2000)),   
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
  " ",      
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
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  0.0,      
  @amt_oper*(ABS(SIGN(@module_id-2000))),    
  @amt_oper*(1+SIGN(@module_id-2000)),   
  0.0,      
  0.0,      
  0.0,      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  ' ',      
  0)      
  
  IF (@@error != 0)  
  BEGIN  
   IF (@transtart = 1 )  
    ROLLBACK TRAN  
   RETURN -1  
  END  
END  
  
IF ( @transtart = 1 )  
 COMMIT TRAN  
  
RETURN 0  
  
  
  
/**/                                                
GO
GRANT EXECUTE ON  [dbo].[aractinp_sp] TO [public]
GO
