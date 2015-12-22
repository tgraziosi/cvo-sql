SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/****** Object:  Stored Procedure [dbo].[CVO_Print_Caricom_Invoice_sp]    Script Date: 05/26/2010  *****  
SED004 -- Control Packing -- Print International Documents  
Object:      Stored Procedure CVO_Print_Caricom_Invoice_sp    
Source file: CVO_Print_Caricom_Invoice_sp.sql  
Author:   Jesus Velazquez  
Created:  05/26/2010  
Function:    After shipping prints Caricom Invoice  
Modified:      
Calls:      
Called by:   WMS -- Shipping Screen  
Copyright:   Epicor Software 2010.  All rights reserved.    
*/  
  
-- v1.1 CB 20/07/2011 68668-012 - Print from sales order  
-- v2.0 TM 10/28/2011 Fix issue in Sold To field  
-- v10.0 CB 22/06/2012 Use allocated quantites  
-- v10.1 CB 10/07/2012 CVO-CF-1 - Custom frame Processing  
-- v10.2 CT 22/08/2012 Only print freight charge on last page  
-- v10.3 CB 30/08/2012 Only print total value on the last page  
-- tag 11/8/2013 - get invoice number from cvo_order_invoice, if available 
  
CREATE PROCEDURE  [dbo].[CVO_Print_Caricom_Invoice_sp]     
   @order_no  INT,  
   @order_ext  INT,  
   @module   VARCHAR(3),  
   @trans   VARCHAR(20),  
   @trans_source VARCHAR(2),  
   @station_id     VARCHAR(20),  
   @is_lastpage SMALLINT -- v10.1  
AS  
  
BEGIN  
 --Header vars  
 DECLARE @format_id          VARCHAR(40),      
   @printer_id         VARCHAR(30),  
   @number_of_copies INT,  
   @max_lines_per_page INT,  
   @avail_lines_detail INT,  
   @LP_CUST_NAME  VARCHAR(40),  
   @LP_CUST_ADDR1  VARCHAR(40),  
   @LP_CUST_ADDR2  VARCHAR(40),  
   @LP_INVOICE_NOS  VARCHAR(10),  
   @LP_CUST_PO   VARCHAR(20),  
   @LP_SHIP_TO_NAME VARCHAR(40),       
   @LP_SHIP_TO_ADD_1 VARCHAR(40),  
   @LP_SHIP_TO_ADD_2 VARCHAR(40),  
   @LP_SHIP_TO_ADD_3 VARCHAR(40),   --v2.0  
   @LP_SHIP_TO_ADD_4 VARCHAR(40),   --v2.0  
   @LP_TERMS   VARCHAR(10),  
   @LP_PORT   VARCHAR(20),   
   @LP_CURRENCY  VARCHAR(10),  
   @LP_SHIP_TO_COUNTRY VARCHAR(40),  
   @LP_CARRIER   VARCHAR(20),  
   @LP_SHP_DATE  VARCHAR(20),  
   @is_POP    INT,       --v2.0  
   @LP_POP_MSG   VARCHAR(65)      --v2.0   
  
  
 --Detail vars  
 DECLARE @row_id    INT,  
   @LP_CARTON_NO  INT,  
   @PREV_CARTON_NO  INT,  
   @LP_PART_NO_DESC VARCHAR(50),  
   @TYPE_CODE   VARCHAR(10),  
   @ADD_CASE   CHAR(1),  
   @LP_CASES_INCLUDED VARCHAR(15),  
   @LINE_NO   INT,  
   @FROM_LINE_NO  INT,      --v2.0  
   @LP_ORIGIN   VARCHAR(40),  
   @LP_QTY    DECIMAL(20,0),  
   @LP_UNIT_VALUE  DECIMAL(20,2),  
   @LP_TOTAL_VALUE  DECIMAL(20,2),  
   @i     INT    
  
 --Footer vars  
 DECLARE @LP_FT_TOTAL_AMOUNT VARCHAR(40),  
   @LP_WEIGHT   VARCHAR(40),  
   @LP_TOTAL_FREIGHT DECIMAL(20,2)    --v2.0  
     
 --add vars  
 DECLARE @frame VARCHAR(10),  
         @case  VARCHAR(10)  
           
 SET @format_id  = ''    
 SET @printer_id = 0   
 SET @number_of_copies = 0       
   
 SET @frame = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_FRAME')  
 SET @case  = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')  
     
 SELECT @format_id  = ISNULL(format_id,'')  
 FROM   tdc_label_format_control (NOLOCK)  
 WHERE  module   = @module  AND   
     trans   = @trans  AND   
     trans_source  = @trans_source  
  
 SELECT  @printer_id   = ISNULL(printer,0),   
   @number_of_copies = ISNULL(quantity,0)    
 FROM tdc_tx_print_routing (NOLOCK)   
 WHERE module    = @module  AND  
   trans    = @trans  AND  
   trans_source  = @trans_source AND     
   format_id   = @format_id    AND  
   user_station_id  = @station_id   
  
 --max number of pages to print per page  
 SELECT  @max_lines_per_page = CAST(detail_lines AS INT)   
 FROM    tdc_tx_print_detail_config (NOLOCK)  
 WHERE trans_source = 'VB'  AND   
   module       = 'SHP' AND   
   trans        = @trans   
  
 --max number of detail lines existing in .lwl file  
 SET @avail_lines_detail = 37  
  
 --if user wants to print more lines than existing then  
 IF @max_lines_per_page > @avail_lines_detail  
  SET @max_lines_per_page = @avail_lines_detail  
  
 TRUNCATE TABLE #PrintData    
 TRUNCATE TABLE #PrintData_Output  
   
 -- Firstly, insert *FORMAT and all the data that we pass.  
 INSERT INTO #PrintData_Output ( format_id,  printer_id,  number_of_copies)     
 VALUES (@format_id, @printer_id, @number_of_copies)      
  
 --Get Header Info  
 SELECT @LP_CUST_NAME  = ISNULL(CompanyName,''),  
     @LP_CUST_ADDR1 = ISNULL(address1,'') + ', ' + ISNULL(address2,''),   
     @LP_CUST_ADDR2 = ISNULL(city,'')     + ', ' + ISNULL(state,'')    + ' ' + ISNULL(zipCode,'')  
 FROM   tdc_contact_reg (NOLOCK)  
 WHERE  ServerName = @@SERVERNAME      
      
 --BEGIN SED008 -- Global Ship To  
 --JVM 07/28/2010  
 IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
  AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> ''  
  AND sold_to <> cust_code)  --v2.0  
  SELECT @LP_SHIP_TO_NAME    = ISNULL(address_name ,''),    
      @LP_SHIP_TO_ADD_1   = ISNULL(addr1   ,''),   
      @LP_SHIP_TO_ADD_2   = ISNULL(addr2   ,''),   
      @LP_SHIP_TO_ADD_3   = ISNULL(addr3  ,''),    --v2.0  
      @LP_SHIP_TO_ADD_4   = ISNULL(addr4  ,''),    --v2.0  
      @LP_SHIP_TO_COUNTRY = ISNULL(g.description ,'')    --v2.0  
  FROM   armaster_all a (NOLOCK), gl_country g (NOLOCK)    --v2.0  
  WHERE  address_type = 9 AND a.country_code = g.country_code AND  --v2.0  
      customer_code = (SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)  
 ELSE  
  SELECT @LP_SHIP_TO_NAME  = ISNULL(ship_to_name  ,''),    
      @LP_SHIP_TO_ADD_1 = ISNULL(ship_to_add_1  ,''),   
      @LP_SHIP_TO_ADD_2 = ISNULL(ship_to_add_2  ,''),  
      @LP_SHIP_TO_ADD_3 = ISNULL(ship_to_add_3  ,''),  --v2.0  
      @LP_SHIP_TO_ADD_4 = ISNULL(ship_to_add_4  ,''),  --v2.0  
      @LP_SHIP_TO_COUNTRY = ISNULL(g.description,'')    --v2.0  
  FROM   orders a (NOLOCK), gl_country g (NOLOCK)      --v2.0  
  WHERE  order_no  = @order_no AND  
      ext       = @order_ext AND  
      a.ship_to_country_cd = g.country_code      --v2.0  
 --END   SED008 -- Global Ship To  
   
 -- tag 11/8/2013 
 -- SELECT @LP_INVOICE_NOS  = ISNULL(invoice_no,0),      --v2.0  
 SELECT @LP_INVOICE_NOS  = ISNULL(oi.doc_ctrl_num,isnull(o.invoice_no,0)),      --v2.0  
     @LP_CUST_PO   = ISNULL(cust_po   ,''),  
     @LP_TERMS   = ISNULL(terms    ,''),  
     @LP_PORT    = 'New York'     ,   
     @LP_CURRENCY   = curr_key      ,   
     @LP_CARRIER   = ISNULL(a.addr1,'')   ,  
     @LP_SHP_DATE   = CONVERT(VARCHAR,sch_ship_date, 111)  
 FROM   orders o (NOLOCK)  
  LEFT OUTER JOIN arshipv a (NOLOCK) ON o.routing = a.ship_via_code 
-- tag 11/8/2013
  left outer join cvo_order_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext 
 WHERE  o.order_no = @order_no AND o.ext = @order_ext  
  
--v2.0  If not yet invoiced then use Order#  
 IF @LP_INVOICE_NOS = '0'                   --v2.0  
   BEGIN                        --v2.0  
  SELECT @LP_INVOICE_NOS = CAST(@order_no AS varchar(10))+'-'+CAST(@order_ext AS varchar(4))  --v2.0  
   END                        --v2.0  
  
 SELECT @LP_TOTAL_FREIGHT = tot_ord_freight  
   FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext  
  
 SELECT @LP_WEIGHT = SUM(CAST(weight AS DECIMAL(20,2)))   
 FROM tdc_carton_tx (NOLOCK)  
 WHERE order_no = @order_no AND   
   order_ext = @order_ext  
  
 -- v1.1 If weight is still null then get the weight from the order line  
 IF @LP_WEIGHT IS NULL  
 BEGIN  
  -- v10.0 Start  
  SELECT @LP_WEIGHT = CAST(SUM(CAST(weight AS decimal(20,2))) AS varchar(40))  
  FROM #PrintData_detail  
  WHERE order_no = @order_no   
  AND  order_ext = @order_ext  
  
  IF @LP_WEIGHT IS NULL  
  BEGIN  
   SELECT @LP_WEIGHT =  SUM(CAST((weight_ea * ordered) AS DECIMAL(20,2)))   
   FROM ord_list (NOLOCK)  
   WHERE order_no = @order_no AND   
     order_ext = @order_ext  
  END  
  -- v10.0 End  
 END  
  
 SELECT @LP_WEIGHT = @LP_WEIGHT + ' LB'     --v2.0  
  
 --Insert Header  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_NAME'  ,@LP_CUST_NAME  )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR1'  ,@LP_CUST_ADDR1  )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR2'  ,@LP_CUST_ADDR2  )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_INVOICE_NOS' ,@LP_INVOICE_NOS )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_PO'  ,@LP_CUST_PO  )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_NAME' ,@LP_SHIP_TO_NAME )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_1' ,@LP_SHIP_TO_ADD_1 )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_2' ,@LP_SHIP_TO_ADD_2 )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_3' ,@LP_SHIP_TO_ADD_3 )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_4' ,@LP_SHIP_TO_ADD_4 )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TERMS'   ,@LP_TERMS   )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_PORT'   ,@LP_PORT   )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CURRENCY'  ,@LP_CURRENCY  )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_COUNTRY',@LP_SHIP_TO_COUNTRY)  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CARRIER'  ,@LP_CARRIER  )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_WEIGHT'   ,@LP_WEIGHT   )  
 INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHP_DATE'  ,@LP_SHP_DATE  )  
 --INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_FREIGHT'  ,@LP_TOTAL_FREIGHT)  --v2.0  
  
  
 --First Insert Frames  
    --@avail_lines_detail  
    declare @cur VARCHAR(400)  
 SET @cur = '  
    DECLARE lines_cur CURSOR FOR   
    SELECT  TOP ' + CAST(@max_lines_per_page AS VARCHAR(2))  + ' row_id, carton_no, part_no_desc, type_code, add_case, line_no, from_line_no, origin, qty, unit_value, total_value  
 FROM    #PrintData_detail  
 WHERE   type_code <> '''+ @case +'''  
 ORDER BY carton_no, type_code  
 OPEN lines_cur'  
 exec (@cur)  
  
 SET @i = 0  
 FETCH NEXT FROM lines_cur   
 INTO @row_id, @LP_CARTON_NO, @LP_PART_NO_DESC, @TYPE_CODE, @ADD_CASE, @LINE_NO, @FROM_LINE_NO, @LP_ORIGIN, @LP_QTY, @LP_UNIT_VALUE, @LP_TOTAL_VALUE  
  
 WHILE @@FETCH_STATUS = 0  
 BEGIN   
    SET @i = @i + 1     
    SET @LP_CASES_INCLUDED = ''  
      
   IF @LP_CARTON_NO = @PREV_CARTON_NO  
  SET @LP_CARTON_NO = ''  
   ELSE  
  SET @PREV_CARTON_NO = @LP_CARTON_NO   
  
-- v10.1    IF @TYPE_CODE <> @case AND EXISTS(SELECT * FROM #PrintData_detail WHERE order_no = @order_no AND order_ext = @order_ext AND type_code = @case AND from_line_no =  @LINE_NO)  
    IF @TYPE_CODE <> @case AND EXISTS(SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no =  @LINE_NO AND add_case = 'Y') -- v10.1  
  SET @LP_CASES_INCLUDED = 'CASES INCLUDED'    
  
    IF @LP_UNIT_VALUE = 0 AND @FROM_LINE_NO = 0 AND @TYPE_CODE <> 'CASE'  
    BEGIN  
   IF @TYPE_CODE IN ('FRAME','SUN')  
    BEGIN   
        SET @is_POP = 1  
        SET @LP_PART_NO_DESC = '(*) '+@LP_PART_NO_DESC  
     SET @LP_UNIT_VALUE = 1.00  
     SET @LP_TOTAL_VALUE = @LP_QTY * @LP_UNIT_VALUE  
    END  
   ELSE  
    BEGIN   
     SET @LP_UNIT_VALUE = 0.05  
     SET @LP_TOTAL_VALUE = @LP_QTY * @LP_UNIT_VALUE  
    END  
    END  
  
  IF @TYPE_CODE = 'POP'  
   BEGIN   
     SET @is_POP = 1  
     SET @LP_PART_NO_DESC = '(*) '+@LP_PART_NO_DESC  
   END  
  
    UPDATE #Print_Doc_Total SET doc_total = doc_total + @LP_TOTAL_VALUE    --v4.0  
  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CARTON_NO_'     + CAST(@i AS CHAR(2)),@LP_CARTON_NO  )  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_PART_NO_DESC_'   + CAST(@i AS CHAR(2)),@LP_PART_NO_DESC )     
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_ORIGIN_'   + CAST(@i AS CHAR(2)),@LP_ORIGIN  )  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_QTY_'   + CAST(@i AS CHAR(2)),@LP_QTY   )  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_UNIT_VALUE_'  + CAST(@i AS CHAR(2)),@LP_UNIT_VALUE )  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_VALUE_' + CAST(@i AS CHAR(2)),@LP_TOTAL_VALUE )  
  
    DELETE #PrintData_detail WHERE row_id = @row_id  
  
    FETCH NEXT FROM lines_cur   
    INTO @row_id, @LP_CARTON_NO, @LP_PART_NO_DESC, @TYPE_CODE, @ADD_CASE, @LINE_NO, @FROM_LINE_NO, @LP_ORIGIN, @LP_QTY, @LP_UNIT_VALUE, @LP_TOTAL_VALUE  
 END  
  
 CLOSE lines_cur  
 DEALLOCATE lines_cur  
  
 SET @PREV_CARTON_NO = ''  
  
 --Then Insert Cases  
 SET @cur = '  
    DECLARE  cases_lines_cur CURSOR FOR   
    SELECT   carton_no, MAX(origin), SUM(CAST(qty AS decimal(20,0)))  
 FROM     #PrintData_detail  
 WHERE   type_code = '''+ @case +'''  
 GROUP BY carton_no  
 ORDER by carton_no  
 OPEN cases_lines_cur'  
 exec (@cur)  
  
 --SET @i = 0  
 FETCH NEXT FROM cases_lines_cur   
 INTO @LP_CARTON_NO, @LP_ORIGIN, @LP_QTY  
  
 WHILE @@FETCH_STATUS = 0 AND @i < @max_lines_per_page  
 BEGIN   
  
--if @i < @max_lines_per_page  
--begin  
    SET @i = @i + 1         
    SET @LP_PART_NO_DESC   = 'CASES: COST ARE INCLUDED W/FRAMES'  
       SET @LP_CASES_INCLUDED = ''  
       --SET @LP_UNIT_VALUE     = ''  
       --SET @LP_TOTAL_VALUE    = ''  
  
   IF @LP_CARTON_NO = @PREV_CARTON_NO  
  SET @LP_CARTON_NO = ''  
   ELSE  
  SET @PREV_CARTON_NO = @LP_CARTON_NO  
  
    INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_CARTON_NO_'   + CAST(@i AS CHAR(2)),@LP_CARTON_NO)  
    INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_PART_NO_DESC_'   + CAST(@i AS CHAR(2)),@LP_PART_NO_DESC)  
    INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_ORIGIN_'    + CAST(@i AS CHAR(2)),'')     --v2.0  
    INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_QTY_'     + CAST(@i AS CHAR(2)),'')     --v2.0  
    INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_UNIT_VALUE_'   + CAST(@i AS CHAR(2)),'')  
    INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_TOTAL_VALUE_'   + CAST(@i AS CHAR(2)),'')  
    --INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_CASES_INCLUDED_' + CAST(@i AS CHAR(2)),@LP_CASES_INCLUDED )  
  
    DELETE #PrintData_detail WHERE type_code = @case  
--end  
    FETCH NEXT FROM cases_lines_cur   
    INTO @LP_CARTON_NO, @LP_ORIGIN, @LP_QTY  
 END  
  
 CLOSE cases_lines_cur  
 DEALLOCATE cases_lines_cur   
  
 WHILE @i < @avail_lines_detail  
 BEGIN   
    SET @i = @i + 1     
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CARTON_NO_'     + CAST(@i AS CHAR(2)), '')  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_PART_NO_DESC_'   + CAST(@i AS CHAR(2)), '')  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CASES_INCLUDED_' + CAST(@i AS CHAR(2)), '')  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_ORIGIN_'   + CAST(@i AS CHAR(2)), '')  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_QTY_'   + CAST(@i AS CHAR(2)), '')  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_UNIT_VALUE_'  + CAST(@i AS CHAR(2)), '')  
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_VALUE_' + CAST(@i AS CHAR(2)), '')  
 END  
   
 --Insert Footer  
 SET @LP_FT_TOTAL_AMOUNT = ''       
  
 IF NOT EXISTS(SELECT * FROM #PrintData_detail WHERE type_code IN (@frame,@case))  
 BEGIN  
  SELECT @LP_FT_TOTAL_AMOUNT = '$ ' + CAST(CAST(total_invoice AS DECIMAL(20,2)) AS VARCHAR(40))  
  FROM orders (NOLOCK)    
  WHERE order_no = @order_no AND   
    ext   = @order_ext        
  
  -- v1.1 If total is still null then get the total from the order  
  IF (SELECT total_invoice FROM orders (NOLOCK)  
    WHERE order_no = @order_no AND   
      ext   = @order_ext) = 0  
  BEGIN  
   SELECT @LP_FT_TOTAL_AMOUNT = '$ ' + CAST(CAST(total_amt_order AS DECIMAL(20,2)) AS VARCHAR(40))  
   FROM orders (NOLOCK)  
   WHERE order_no = @order_no AND   
     ext   = @order_ext    
  END  
  
 END   
  
 SET @LP_POP_MSG = ''  --v2.0  
  
   IF @is_pop = 1  
  BEGIN  
  SET @LP_POP_MSG = '* PROMOTIONAL MATERIAL. NO COMMERCIAL VALUE. FOR CUSTOMS ONLY.'  
  INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_POP_MSG', @LP_POP_MSG)  --v2.1  
  END  
  
 -- START v10.2  
 IF ISNULL(@is_lastpage,0) = 1  
 BEGIN  
  SELECT @LP_FT_TOTAL_AMOUNT = CONVERT(varchar(40),CAST(doc_total AS DECIMAL(20,2))) + @LP_TOTAL_FREIGHT FROM #Print_Doc_Total  
  
  INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_FREIGHT'  ,@LP_TOTAL_FREIGHT)  --v2.0  
  INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TOTAL_AMOUNT', @LP_FT_TOTAL_AMOUNT) -- v10.3  
 END  
 ELSE  
 BEGIN  
  SELECT @LP_FT_TOTAL_AMOUNT = CONVERT(varchar(40),CAST(doc_total AS DECIMAL(20,2))) FROM #Print_Doc_Total  
  
  INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_FREIGHT'  ,'')  --v2.0  
  INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TOTAL_AMOUNT', '') -- v10.3  
 END  
 -- END v10.2  
  
  
   
END  
  
  
GO
GRANT EXECUTE ON  [dbo].[CVO_Print_Caricom_Invoice_sp] TO [public]
GO
