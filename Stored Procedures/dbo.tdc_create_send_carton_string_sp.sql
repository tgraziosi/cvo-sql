SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v3.0 TM 10-24-2011	If order is COLLECT then Send the Customers Account# 
-- v3.1	CT 15/01/2014	Issue #1413 - 3rd Party Freight changes
-- v3.2 CT 19/05/2014	Issue #572 - Deal with cartons containing multiple orders
-- v3.3 CB 17/06/2014	Remove code for global ship to as this is only done at masterpack level
-- v3.4 CB 04/07/2014	Change to v3.3 - Check if PL order
-- v3.5 CT 18/02/2015	Issue #1534 - For cartons containing multiple orders which belong to a masterpack consolidation, send first order number

-- CREATE TABLE #tdc_temp_manifest_string  (Pos INT NOT NULL, FieldValue VARCHAR(255) NULL, FieldName VARCHAR(255) NULL) 

CREATE PROCEDURE [dbo].[tdc_create_send_carton_string_sp]    
 @station_id  varchar(3),    
 @operator  varchar(50),    
 @carton_no  int,    
 @last_carton CHAR(1),    
 @err_msg varchar(255) OUTPUT    
AS    
    
DECLARE    
 @carton_contains_multiple_orders char(1),    
 @pos   int,    
 @shipper   varchar(255),    
 @carton_seq    int,    
 @carton_total  int,    
 @unit_total  int,    
 @order_no   int,    
 @order_ext  int,    
 @field_length  int,    
 @field_value  varchar(255),    
 @freight_allow_type  varchar(10),  
  
 @cust_code varchar(8),      --v3.0  
 @routing varchar(30),      --v3.0  
 @sold_to varchar (10), 
 -- START v3.5
 @mp_order_no   int, 
 @ismpcarton smallint 
 -- END v3.5
    
  
--##################################################################    
--Initialize the variables    
--##################################################################    
    
SET @ismpcarton = 0 -- v3.5

IF EXISTS(SELECT * FROM tdc_stage_carton (NOLOCK)    
 WHERE carton_no = @carton_no)     
BEGIN    
 SELECT @err_msg = 'Carton already freighted'    
 RETURN -1    
END    
    
SELECT @operator = REPLACE(@operator,'cvoptical\','')
    
---------------------------------------------------------------------------------------------    
-- Find out if there are multiple orders per carton    
---------------------------------------------------------------------------------------------    
IF(SELECT COUNT(carton_no)     
     FROM tdc_carton_tx (NOLOCK)    
    WHERE carton_no = @carton_no) > 1    
BEGIN    
 SELECT @carton_contains_multiple_orders = 'Y'    
END    
ELSE    
BEGIN    
 SELECT @carton_contains_multiple_orders = 'N'    
END    
 
IF @carton_contains_multiple_orders = 'N'    
BEGIN    
 --Get the carton seq number    
 SELECT @order_no = order_no, @order_ext = order_ext FROM tdc_carton_tx(NOLOCK)    
  WHERE carton_no = @carton_no    
     
 EXEC tdc_calc_carton_seq @carton_no    
     
 EXEC tdc_get_carton_seq @carton_no, @carton_seq OUTPUT, @carton_total OUTPUT, @unit_total OUTPUT,0    
    
 --If COD, set lastcart flag to 'Y'    
 -- SCR36603    
 SELECT @freight_allow_type = ISNULL((    
 SELECT MIN(o.freight_allow_type)     
    FROM orders o (NOLOCK),     
         tdc_carton_tx c (NOLOCK)    
   WHERE c.carton_no = @carton_no    
     AND o.order_no = c.order_no    
     AND o.ext = c.order_ext), '')    
 -- SCR36603    
    
 --Get the shipper from armaster    
 SELECT @shipper = ISNULL((    
-- SELECT a.addr_sort3  --Call#1833908ESC  09/10/09    
 SELECT TOP 1 a.addr3    
   FROM armaster_all a (NOLOCK),    
        orders   o (NOLOCK)    
  WHERE a.customer_code = o.cust_code    
    AND order_no = @order_no    
    AND ext      = @order_ext    
    AND a.ship_to_code = o.ship_to), '') --Call#1833908ESC  09/10/09    
     
 IF @freight_allow_type = 'COD'    
  SET @last_carton = 'Y'    
    
END    
ELSE    
BEGIN 
 -- START v3.2 - remove this check
 /*   
 IF NOT EXISTS(SELECT * FROM tdc_carton_tx WHERE carton_no = @carton_no AND charge_code = '8')    
 BEGIN    
  SELECT @err_msg = 'Freight Code must be ''8'''    
  RETURN -2    
 END    
 */
  
 SELECT @carton_seq = 0, @carton_total = 0, @unit_total = 0, @order_no = 0, @order_ext = 0     
 SELECT @last_carton = 'N'    
    
 -- START v3.5
 IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) INNER JOIN cvo_masterpack_consolidation_det b (NOLOCK)  
    ON a.order_no = b.order_no AND a.order_ext = b.order_ext WHERE a.carton_no = @carton_no)  
 BEGIN  
	 SELECT TOP 1   
	  @mp_order_no = order_no  
	 FROM   
	  tdc_carton_tx(NOLOCK)        
	 WHERE   
	  carton_no = @carton_no  
	 ORDER BY  
	  order_no   
  
	SET @ismpcarton = 1  
 END  
 -- END v3.5

 IF (SELECT COUNT(DISTINCT ISNULL(a.addr_sort3, ''))    
       FROM armaster a(NOLOCK),    
     orders o(NOLOCK),    
     tdc_carton_Tx c(NOLOCK)    
      WHERE a.customer_code = o.cust_code    
        AND o.order_no = c.order_no    
        AND o.ext = c.order_ext    
        AND c.carton_no = @carton_no) = 1    
 BEGIN    
   -- SCR36603    
  SELECT  @shipper = ISNULL((    
  SELECT TOP 1 a.addr_sort3    
           FROM armaster a(NOLOCK),    
         orders o(NOLOCK),    
         tdc_carton_Tx c(NOLOCK)    
          WHERE a.customer_code = o.cust_code    
            AND o.order_no = c.order_no    
            AND o.ext = c.order_ext    
            AND c.carton_no = @carton_no), '')    
 END    
 ELSE    
  SELECT @shipper = ''    
END    
    
    
    
-- Remove all the records for unfreight or freight        
DELETE FROM #tdc_temp_manifest_string    
    
--##################################################################    
--Start loading the temp table    
--##################################################################    
    
-- STATION_ID     
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'STATION_ID')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'   AND fieldname = 'STATION_ID'     
    
 INSERT INTO #tdc_temp_manifest_string (pos,fieldvalue, fieldname)     
 VALUES (@pos, LEFT(@station_id + SPACE(@field_length), @field_length), 'STATION_ID')    
END    
    
-- OPERATOR    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'OPERATOR')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON' AND fieldname = 'OPERATOR'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)     
 VALUES (@pos, LEFT(@operator + SPACE(@field_length),@field_length), 'OPERATOR')    
END    
    
-- ORDER    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'ORDER')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'ORDER'     
 
 -- START v3.5
 IF @ismpcarton = 1  
 BEGIN       
	 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)        
	 VALUES (@pos, LEFT(CAST(@mp_order_no AS varchar(255)) + SPACE(@field_length),@field_length), 'ORDER')        
 END  
 ELSE  
 BEGIN  
	 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)        
	 VALUES (@pos, LEFT(CAST(@order_no AS varchar(255)) + SPACE(@field_length),@field_length), 'ORDER')        
 END  
 -- END v3.5
    
END    
    
    
-- CARTON    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CARTON')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CARTON'     
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(CAST(@carton_no AS varchar(255)) + SPACE(@field_length),@field_length),    
  'CARTON')    
    
END    
    
-- WEIGHT    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'WEIGHT')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'WEIGHT'     
    
 SELECT TOP 1 @field_value = CAST(ISNULL(weight, 0.0) AS varchar(25))    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'WEIGHT')    
    
END    
    
-- Cost (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'COST')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),    
        @pos = startpos     
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'COST'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'COST')    
    
END    
--  
--Comment out original code  
--    
/*  
-- Length (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'LENGTH')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'LENGTH'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'LENGTH')    
    
END    
    
-- Width (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'WIDTH')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'WIDTH'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'WIDTH')    
    
END    
    
-- Height (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'HEIGHT')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'HEIGHT'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'HEIGHT')    
    
END    
--  
-- End comment out original code  
--  
*/  
  
--  
--New Code  
--  
-- Length (NOT USED)  
-- CVO Length for DIM weight  
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)   
 WHERE message = 'SENDCARTON'   
 AND fieldname = 'LENGTH')   
BEGIN  
SELECT @field_value = ''  
/* COMMENT OUT ORIGINAL CODE  
  
 SELECT @field_length = ((endpos - startpos) +1) ,  
        @pos = startpos  
  FROM tdc_mis_msg_layout_tbl (NOLOCK)   
  WHERE message = 'SENDCARTON'     
  AND fieldname = 'LENGTH'   
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, SPACE(@field_length), 'LENGTH')  
  
END COMMENT OUT ORIGINAL CODE   */  
  
  
/************* CONVENTIONS FOR MODIFICATION ******************  
Exterior dimensions will be used  
Length = x dimension from package master - field name dim_ext_x  
Height = y dimension from package master - field name dim_ext_y  
Width = z dimension from package master - field name dim_ext_z  
UOM is understood as inches but any uom can be used provided it is applied across all packages  
*/  
  
-- START v3.2
IF ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> ('') or    
    ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> null or    
    ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> 'NEW' 
/*   
 IF ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> ('') or    
    ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> null or    
    ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> 'NEW'    
*/
 -- END v3.2
 BEGIN  
  SELECT @field_value = ISNULL(d.dim_ext_x  , '')  
     FROM orders o (NOLOCK),   
          tdc_carton_tx c (NOLOCK),  
   tdc_pkg_master d (NOLOCK)  
    WHERE c.carton_no = @carton_no  
      AND o.order_no = c.order_no  
      AND o.ext = c.order_ext  
      AND c.carton_type = d.pkg_code  
 END  
 -- START v3.2   
 IF ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) = 'NEW'    
 --IF ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) = 'NEW'    
 -- END v3.2
 BEGIN  
  SELECT @field_value = ISNULL(d.length  , '')  
     FROM orders o (NOLOCK),   
          tdc_carton_tx c (NOLOCK),  
   tho_case_dimensions d (NOLOCK)  
    WHERE c.carton_no = @carton_no  
      AND o.order_no = c.order_no  
      AND o.ext = c.order_ext  
      AND c.carton_no = d.carton_no  
 END  
   
 IF @field_value <> ''  
 BEGIN  
   
  SELECT @field_length = ((endpos - startpos) +1) ,  
         @pos = startpos  
   FROM tdc_mis_msg_layout_tbl (NOLOCK)   
   WHERE message = 'SENDCARTON'     
   AND fieldname = 'LENGTH'   
   
  INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
  VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'LENGTH')  
   
   
 END  
   
 ELSE  
 BEGIN  
   
  SELECT @field_length = ((endpos - startpos) +1) ,  
         @pos = startpos  
   FROM tdc_mis_msg_layout_tbl (NOLOCK)   
   WHERE message = 'SENDCARTON'     
   AND fieldname = 'LENGTH'   
   
  INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
  VALUES (@pos, SPACE(@field_length), 'LENGTH')  
 END  
  
  
END  
  
  
  
-- Width (NOT USED)  
-- CVO Width for DIM weight  
  
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)   
 WHERE message = 'SENDCARTON'   
 AND fieldname = 'WIDTH')   
BEGIN  
SELECT @field_value = ''  
/* COMMENT OUT ORIGINAL CODE  
  
 SELECT @field_length = ((endpos - startpos) +1) ,  
        @pos = startpos  
  FROM tdc_mis_msg_layout_tbl (NOLOCK)   
  WHERE message = 'SENDCARTON'     
  AND fieldname = 'WIDTH'   
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, SPACE(@field_length), 'WIDTH')  
  
END COMMENT OUT ORIGINAL CODE   */  
  
  
/************* CONVENTIONS FOR MODIFICATION ******************  
Exterior dimensions will be used  
Length = x dimension from package master - field name dim_ext_x  
Height = y dimension from package master - field name dim_ext_y  
Width = z dimension from package master - field name dim_ext_z  
UOM is understood as inches but any uom can be used provided it is applied across all packages  
*/  
  
-- START v3.2    
IF ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> ('') or    
   ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> null or    
   ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> 'NEW'    

/*
IF ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> ('') or    
   ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> null or    
   ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> 'NEW'    
*/
-- END v3.2
BEGIN  
 SELECT @field_value = ISNULL(d.dim_ext_z  , '')  
    FROM orders o (NOLOCK),   
         tdc_carton_tx c (NOLOCK),  
  tdc_pkg_master d (NOLOCK)  
   WHERE c.carton_no = @carton_no  
     AND o.order_no = c.order_no  
     AND o.ext = c.order_ext  
     AND c.carton_type = d.pkg_code  
END  
-- START v3.2    
IF ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) = 'NEW'    
--IF ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) = 'NEW'    
-- END v3.2
BEGIN  
 SELECT @field_value = ISNULL(d.width  , '')  
    FROM orders o (NOLOCK),   
         tdc_carton_tx c (NOLOCK),  
  tho_case_dimensions d (NOLOCK)  
   WHERE c.carton_no = @carton_no  
     AND o.order_no = c.order_no  
     AND o.ext = c.order_ext  
     AND c.carton_no = d.carton_no  
END  
  
IF @field_value <> ''  
BEGIN  
  
 SELECT @field_length = ((endpos - startpos) +1) ,  
        @pos = startpos  
  FROM tdc_mis_msg_layout_tbl (NOLOCK)   
  WHERE message = 'SENDCARTON'     
  AND fieldname = 'WIDTH'   
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'WIDTH')  
  
  
END  
  
ELSE  
BEGIN  
  
 SELECT @field_length = ((endpos - startpos) +1) ,  
        @pos = startpos  
  FROM tdc_mis_msg_layout_tbl (NOLOCK)   
  WHERE message = 'SENDCARTON'     
  AND fieldname = 'WIDTH'   
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, SPACE(@field_length), 'WIDTH')  
END  
  
  
END  
  
  
-- Height (NOT USED)  
-- CVO Height for DIM weight  
  
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)   
 WHERE message = 'SENDCARTON'   
 AND fieldname = 'HEIGHT')   
BEGIN  
SELECT @field_value = ''  
/* COMMENT OUT ORIGINAL CODE  
  
 SELECT @field_length = ((endpos - startpos) +1) ,  
        @pos = startpos  
  FROM tdc_mis_msg_layout_tbl (NOLOCK)   
  WHERE message = 'SENDCARTON'     
  AND fieldname = 'HEIGHT'   
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, SPACE(@field_length), 'HEIGHT')  
  
END COMMENT OUT ORIGINAL CODE   */  
  
  
/************* CONVENTIONS FOR MODIFICATION ******************  
Exterior dimensions will be used  
Length = x dimension from package master - field name dim_ext_x  
Height = y dimension from package master - field name dim_ext_y  
Width = z dimension from package master - field name dim_ext_z  
UOM is understood as inches but any uom can be used provided it is applied across all packages  
*/  
  
  
 -- START v3.2   
 IF ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> ('') or    
    ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> null or    
    ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> 'NEW'    
/*
 IF ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> ('') or    
    ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> null or    
    ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) <> 'NEW'    
*/
 -- END v3.2
 BEGIN  
  SELECT @field_value = ISNULL(d.dim_ext_y  , '')  
     FROM orders o (NOLOCK),   
          tdc_carton_tx c (NOLOCK),  
   tdc_pkg_master d (NOLOCK)  
    WHERE c.carton_no = @carton_no  
      AND o.order_no = c.order_no  
      AND o.ext = c.order_ext  
      AND c.carton_type = d.pkg_code  
 END  
 -- START v3.2
 IF ( SELECT TOP 1 carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) = 'NEW'    
 --IF ( SELECT carton_type FROM tdc_carton_tx WHERE carton_no = @carton_no) = 'NEW'    
 -- END v3.2
 BEGIN  
  SELECT @field_value = ISNULL(d.height  , '')  
     FROM orders o (NOLOCK),   
          tdc_carton_tx c (NOLOCK),  
   tho_case_dimensions d (NOLOCK)  
    WHERE c.carton_no = @carton_no  
      AND o.order_no = c.order_no  
      AND o.ext = c.order_ext  
      AND c.carton_no = d.carton_no  
 END  
  
 IF @field_value <> ''  
 BEGIN  
   
   
  SELECT @field_length = ((endpos - startpos) +1) ,  
         @pos = startpos  
   FROM tdc_mis_msg_layout_tbl (NOLOCK)   
   WHERE message = 'SENDCARTON'     
   AND fieldname = 'HEIGHT'   
   
  INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
  VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'HEIGHT')  
   
   
 END  
  
 ELSE  
 BEGIN  
   
  SELECT @field_length = ((endpos - startpos) +1) ,  
         @pos = startpos  
   FROM tdc_mis_msg_layout_tbl (NOLOCK)   
   WHERE message = 'SENDCARTON'     
   AND fieldname = 'HEIGHT'   
   
  INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
  VALUES (@pos, SPACE(@field_length), 'HEIGHT')  
 END  
  
END  
  
-- End CVO modification  
  
  
--  
-- End New Code  
--  
  
    
-- DimUnit (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'DIMUNIT')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'DIMUNIT'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'DIMUNIT')    
    
END    
    
-- ShipToId    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOID')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOID'     
    
 -- START v3.2
 SELECT TOP 1 @field_value = ISNULL((      
  SELECT TOP 1 ship_to_no      
    FROM tdc_carton_tx (NOLOCK)       
   WHERE carton_no = @carton_no), '')
/*     
 SELECT TOP 1 @field_value = ISNULL((      
  SELECT ship_to_no      
    FROM tdc_carton_tx (NOLOCK)       
   WHERE carton_no = @carton_no), '')      
 */
 -- END v3.2  
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOID')    
    
END    
    
-- ShipToName    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTONAME')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTONAME'     
    
 SELECT TOP 1 @field_value = ISNULL([name], '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTONAME')    
    
END    
    
-- ShipToAdr1    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOADR1')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOADR1'     
    
 SELECT TOP 1 @field_value = ISNULL(address1, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOADR1')    
    
END    
    
-- ShipToAdr2    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOADR2')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOADR2'     
    
 SELECT TOP 1 @field_value = ISNULL(address2, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOADR2')    
    
END    
    
-- ShipToATTN    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOATTN')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOATTN'     
    
 SELECT TOP 1 @field_value = ISNULL(attention, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOATTN')    
    
END    
-- ShipToCity    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOCITY')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOCITY'     
    
 SELECT TOP 1 @field_value = ISNULL(city, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOCITY')    
    
END    
    
-- ShipToST    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOSTAT')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOSTAT'     
    
 SELECT TOP 1 @field_value = ISNULL(state, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOSTAT')    
    
END    
    
-- ShipToZip    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOZIP')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOZIP'     
    
 SELECT TOP 1 @field_value = ISNULL(zip, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOZIP')    
    
END    
    
-- ShipToCountry    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOCNTRY')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOCNTRY'     
    
 SELECT TOP 1 @field_value = ISNULL(country, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOCNTRY')    
    
END    
    
-- Carrier    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'CARRIER')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CARRIER'     
    
 SELECT TOP 1 @field_value = ISNULL(carrier_code, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 --BEGIN SED009 -- Clippership Integration      -- T McGrady NOV.30.2010  -- Code was missing  
 DECLARE @clippership_code VARCHAR(255)  
  
 SELECT DISTINCT @clippership_code = ISNULL(clippership_code,'')   -- T Mcgrady NOV.30.2010  
 FROM   CVO_Carriers   
 WHERE  Carrier = @field_value -- 'CARRIER'  
  
 IF (RTRIM(@clippership_code) <> '' )  
  SET @field_value = @clippership_code  
 --END   SED009 -- Clippership Integration  
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CARRIER')    
    
END    
    
-- Mode (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'MODE')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'MODE'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'MODE')    
    
END    
    
-- ChargeCode    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'CHARGECODE')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CHARGECODE'     
    
 SELECT TOP 1 @field_value = ISNULL(charge_code, ''), @order_no = order_no, @order_ext = order_ext   
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
  
--v3.0 BEGIN  
 SELECT @freight_allow_type = freight_allow_type, @routing = routing, @cust_code = cust_code,   
     @sold_to = sold_to  --v3.0  
   FROM orders WHERE order_no = @order_no AND ext = @order_ext          --v3.0  
  
 -- START v3.1
 IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'																
 --IF @freight_allow_type = 'COLLECT'															--v3.0
 -- END v3.1
 BEGIN                       --v3.0  
	SELECT @field_value = '2'                 --v3.0  
 END                        --v3.0  
--v3.0 END  
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CHARGECODE')    
    
END    
    
-- Invoice Code (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'INVOCECODE')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'INVOCECODE'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'INVOCECODE')    
    
END    
    
-- Total Order Value    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
     WHERE message = 'SENDCARTON' AND fieldname = 'TOTORDVAL')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) + 1),     
        @pos = startpos    
   FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON' AND fieldname = 'TOTORDVAL'     
    
 SELECT TOP 1 @field_value = CAST(SUM((o.gross_sales - o.total_discount) + (o.freight + o.total_tax)) AS VARCHAR)    
     FROM tdc_carton_tx c (NOLOCK), orders o (NOLOCK)     
  WHERE c.carton_no = @carton_no    
    AND o.order_no  = c.order_no    
    AND o.ext       = c.order_ext    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length), @field_length), 'TOTORDVAL')    
END    
    
-- Total Carton Value    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
     WHERE message = 'SENDCARTON' AND fieldname = 'TOTVAL')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) + 1),     
        @pos = startpos    
   FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON' AND fieldname = 'TOTVAL'     
    
  --Get total value of carton contents prior to freighting    
  EXEC tdc_calc_carton_value_sp @carton_no    
    
 SELECT @field_value = SUM(ISNULL(carton_content_value, 0) + ISNULL(carton_tax_value, 0))    
     FROM tdc_carton_tx (NOLOCK)    
  WHERE carton_no = @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
VALUES (@pos, LEFT(@field_value  + SPACE(@field_length), @field_length), 'TOTVAL')    
END    
    
-- SHIPPER    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'SHIPPER')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),    
        @pos = startpos    
   FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON' AND fieldname = 'SHIPPER'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)     
 VALUES (@pos, LEFT(@shipper + SPACE(@field_length),@field_length), 'SHIPPER')    
END    
    
-- CUSTOMERNR    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON' AND fieldname = 'CUSTOMERNR')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUSTOMERNR'     
    
 SELECT TOP 1 @field_value = ISNULL(cust_code, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUSTOMERNR')    
    
END    
    
-- Part No (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'PART_NR')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'PART_NR'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'PART_NR')    
    
END    
    
-- Part Desc (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'PART_DESC')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'PART_DESC'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'PART_DESC')    
    
END    
    
-- UPC (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'UPC')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'UPC'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'UPC')    
    
END    
    
-- ALTORDER (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'ALTORDER')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'ALTORDER'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'ALTORDER')    
    
END    
    
-- Cust Po    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_PO')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUST_PO'     
    
 SELECT TOP 1 @field_value = ISNULL(cust_po, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUST_PO')    
    
END    
    
    
-- LASTTRAN (Always 'N')    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'LASTTRAN')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'LASTTRAN'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, 'N' + SPACE(@field_length-1), 'LASTTRAN')    
    
END    
    
    
-- LASTCART     
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'LASTCART')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'LASTCART'     
 INSERT INTO #tdc_temp_manifest_string (pos,fieldvalue, fieldname)     
 VALUES (@pos, LEFT(@last_carton + SPACE(@field_length),@field_length), 'LASTCART')    
    
END    
    
-- CUST_NAME (NOT USED)  
  
  
   
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_NAME')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUST_NAME'  
  
-- v4.0 Begin  
     
SELECT @field_value = ''   

-- START v3.1
IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'	  
--IF @freight_allow_type = 'COLLECT'                   
-- END v3.1
BEGIN   
   IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
    AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   BEGIN  
                        
   SELECT @field_value = (SELECT sold_to_addr1 FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
   END    
                
 END                          
--v4.0 END  
  
--     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
-- VALUES (@pos, SPACE(@field_length), 'CUST_NAME')    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUST_NAME')    
    
END    
    
-- CUST_ADDR1 (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_ADDR1')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUST_ADDR1'     
  
-- v4.0 Begin  
     
SELECT @field_value = ''   
  
 -- START v3.1
 IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'	
 --IF @freight_allow_type = 'COLLECT'                   
 -- END v3.1
  BEGIN   
   IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
    AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   BEGIN  
                        
   SELECT @field_value = (SELECT sold_to_addr2 FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
   END    
                
  END                          
--v4.0 END  
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUST_ADDR1')    
    
END    
    
-- CUST_ADDR2 (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_ADDR2')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUST_ADDR2'     
    
-- v4.0 Begin  
     
SELECT @field_value = ''   
 -- START v3.1
 IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'	 
 --IF @freight_allow_type = 'COLLECT'                   
 -- END v3.1
  BEGIN   
   IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
    AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   BEGIN  
                        
   SELECT @field_value = (SELECT sold_to_addr3 FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
   END    
                
  END                          
--v4.0 END  
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUST_ADDR2')     
    
END    
    
-- CUST_ATTN (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_ATTN')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'     
  AND fieldname = 'CUST_ATTN'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'CUST_ATTN')    
    
END    
    
-- CUST_CITY (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_CITY')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUST_CITY'     
    
  
-- v4.0 Begin  
     
SELECT @field_value = ''   
  
 -- START v3.1
 IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'	 
 --IF @freight_allow_type = 'COLLECT'                   
 -- END v3.1                   
  BEGIN   
   IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
    AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   BEGIN  
                        
   SELECT @field_value = (SELECT sold_to_city FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
   END    
                
  END                          
--v4.0 END  
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUST_CITY')      
    
END    
    
-- CUST_STATE (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_STATE')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUST_STATE'     
    
-- v4.0 Begin  
     
SELECT @field_value = ''   
  
 -- START v3.1
 IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'	 
 --IF @freight_allow_type = 'COLLECT'                   
 -- END v3.1
  BEGIN   
   IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
    AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   BEGIN  
                        
   SELECT @field_value = (SELECT sold_to_state FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
   END    
                
  END                          
--v4.0 END  
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUST_STATE')    
    
END    
    
-- CUST_ZIP (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_ZIP')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUST_ZIP'     
    
-- v4.0 Begin  
     
SELECT @field_value = ''   
  
 -- START v3.1
 IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'	 
 --IF @freight_allow_type = 'COLLECT'                   
 -- END v3.1
  BEGIN   
   IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
    AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   BEGIN  
                        
   SELECT @field_value = (SELECT sold_to_zip FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
   END    
                
  END                          
--v4.0 END  
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUST_ZIP')  
    
END    
    
-- CUST_CNTRY (NOT USED)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUST_CNTRY')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUST_CNTRY'     
    
-- v4.0 Begin  
     
SELECT @field_value = ''   
  
 -- START v3.1
 IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'	 
 --IF @freight_allow_type = 'COLLECT'                   
 -- END v3.1
  BEGIN   
   IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
    AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   BEGIN  
                        
   SELECT @field_value = (SELECT ISNULL(sold_to_country_cd,'US') FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
   END    
                
  END                          
--v4.0 END  
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUST_CNTRY')  
    
END    
    
-- 3PB_ACCOUNT Value    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = '3PB_ACCOUNT')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = '3PB_ACCOUNT'     
  
--v3.0 BEGIN  
    
-- SELECT TOP 1 @field_value = ship_to_add_5    
--  FROM tdc_carton_tx c (NOLOCK), orders o (NOLOCK)     
--  WHERE c.carton_no =  @carton_no    
--  AND o.order_no = c.order_no    
--  AND o.ext = c.order_ext    
--      
-- IF @field_value LIKE '3PB=%'     
--  SELECT @field_value = SUBSTRING(@field_value , 5 ,LEN(@field_value)-4)    
-- ELSE    
  
 SELECT @field_value = ''      
  
 IF @freight_allow_type = 'COLLECT'             --v3.0  
 BEGIN 
 -- START v3.1  
	SELECT @field_value = IsNull(account,'') FROM cust_carrier_account    --v3.0  
    WHERE cust_code = @cust_code AND routing = @routing        --v3.0  
    AND freight_allow_type = @freight_allow_type         --v3.0  
/*	
   IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
    AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
    BEGIN  
                         
     SELECT @field_value = IsNull(account,'') FROM cust_carrier_account    --v3.0  
      WHERE cust_code = @sold_to AND routing = @routing        --v3.0  
      AND freight_allow_type = @freight_allow_type   
  
    END  
   ELSE  
    BEGIN  
                   --v3.0  
    SELECT @field_value = IsNull(account,'') FROM cust_carrier_account    --v3.0  
     WHERE cust_code = @cust_code AND routing = @routing        --v3.0  
       AND freight_allow_type = @freight_allow_type         --v3.0  
       
    END
*/   
 END  
 ELSE
 BEGIN
	 IF @freight_allow_type = 'THRDPRTY'
	 BEGIN
		SELECT @field_value = IsNull(account,'') FROM cust_carrier_account				
		WHERE cust_code = @sold_to AND routing = @routing 						
		AND freight_allow_type = @freight_allow_type	
	 END
	 ELSE  
	 BEGIN  
	   SELECT @field_value = ''                --v3.0  
	 END 
 END
 -- END v3.1 
--v3.0 END  
  
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), '3PB_ACCOUNT')    
    
END    
    
-- Dest Zone    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'DEST_ZONE')     
BEGIN    
 SELECT @field_value = ISNULL(dest_zone_code, '') FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext    
    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'DEST_ZONE'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'DEST_ZONE')    
    
END    
    
-- CUSTOM1 (Reserved)  
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)   
            WHERE message = 'SENDCARTON'   
            AND fieldname = 'CUSTOM1')   
BEGIN  
-- Begin Custom for CVO  
  
-- Customer Phone Number required for FEDEX  
-- select * from orders_all where order_no > 900  
  
  
  SELECT @field_value =  CASE  isnull(o.phone,'')  
    --WHEN isnull(o.phone) THEN  '1-631-787-1500'  
       WHEN '' THEN '1-631-787-1500'  
    ELSE o.phone END  
               FROM orders o (NOLOCK),   
                    tdc_carton_tx c (NOLOCK)  
         WHERE c.carton_no = @carton_no  
                AND o.order_no = c.order_no  
                AND o.ext = c.order_ext  
  
-- End Custom for CVO  
  
            SELECT @field_length = ((endpos - startpos) +1) ,  
                   @pos = startpos  
                        FROM tdc_mis_msg_layout_tbl (NOLOCK)   
                        WHERE message = 'SENDCARTON'     
                        AND fieldname = 'CUSTOM1'   
  
            INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
  
-- Begin Custom for CVO  
            VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'CUSTOM1')  
-- End Custom for CVO  
  
   
  
END  
  
  
-- CUSTOM2 (Reserved)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUSTOM2')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUSTOM2'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'CUSTOM2')    
    
END    
-- CUSTOM3 (Reserved)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUSTOM3')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUSTOM3'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'CUSTOM3')    
    
END    
-- CUSTOM4 (Reserved)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUSTOM4')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUSTOM4'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'CUSTOM4')    
    
END    
    
-- CUSTOM5 (Reserved)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUSTOM5')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUSTOM5'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'CUSTOM5')    
    
END    
    
-- CUSTOM6 (Reserved)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUSTOM6')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUSTOM6'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'CUSTOM6')    
    
END    
    
-- CUSTOM7 (Reserved)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUSTOM7')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUSTOM7'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'CUSTOM7')    
    
END    
    
-- CUSTOM8 (Reserved)    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CUSTOM8')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CUSTOM8'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, SPACE(@field_length), 'CUSTOM8')    
    
END    
    
-- CARTON_SEQ    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CARTON_SEQ')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CARTON_SEQ'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)     
 VALUES (@pos, LEFT(cast(@carton_seq as varchar) + SPACE(@field_length),@field_length), 'CARTON_SEQ')    
    
END    
    
-- CARTON_TOTAL    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'CARTON_TOTAL')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'CARTON_TOTAL'     
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)     
 VALUES (@pos, LEFT(cast(@carton_total as varchar) + SPACE(@field_length),@field_length), 'CARTON_TOTAL')    
    
END    
    
-- UNIT_TOTAL    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'UNIT_TOTAL')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'UNIT_TOTAL'     
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)     
 VALUES (@pos, LEFT(cast(@unit_total as varchar) + SPACE(@field_length),@field_length), 'UNIT_TOTAL')    
    
END    
    
    
-- ORDER_EXT    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'ORDER_EXT')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1) ,    
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'ORDER_EXT'     
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)     
 VALUES (@pos, LEFT(CAST(@order_ext AS varchar(255)) + SPACE(@field_length),@field_length), 'ORDER_EXT')    
    
END    
    
-- SHIPTOADR3    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK)     
 WHERE message = 'SENDCARTON'     
 AND fieldname = 'SHIPTOADR3')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1),     
        @pos = startpos    
  FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON'       
  AND fieldname = 'SHIPTOADR3'     
    
 SELECT TOP 1 @field_value = ISNULL(address3, '')    
  FROM tdc_carton_tx (NOLOCK)     
  WHERE carton_no =  @carton_no    
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), 'SHIPTOADR3')    
    
END    
    
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'FREIGHT_TYPE')     
BEGIN    
 SELECT @field_length = ((endpos - startpos) +1), @pos = startpos    
   FROM tdc_mis_msg_layout_tbl (NOLOCK)     
  WHERE message = 'SENDCARTON' AND fieldname = 'FREIGHT_TYPE'     
    
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@freight_allow_type + SPACE(@field_length), @field_length), 'FREIGHT_TYPE')    
END    

-- v3.4 Start
IF NOT EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND RIGHT(user_category,2) = 'PL')
BEGIN

	-- v3.3
	    
	--BEGIN SED008 -- Global Ship To  
	--JVM 07/28/2010  
	DECLARE  @g_ship_to_code VARCHAR(255)  
	  ,@g_ship_to_name VARCHAR(255)  
	  ,@g_addr1   VARCHAR(255)  
	  ,@g_addr2   VARCHAR(255)  
	  ,@g_addr3   VARCHAR(255)  
	  ,@g_attention_name  VARCHAR(255)  
	  ,@g_city   VARCHAR(255)  
	  ,@q_state   VARCHAR(255)  
	  ,@g_postal_code  VARCHAR(255)  
	  ,@g_country_code VARCHAR(255)  
	  
	--SELECT a.ship_to_code, a.address_name, a.addr1, a.addr2, a.addr3, a.attention_name, a.city, a.state,  a.postal_code, a.country_code FROM    armaster_all a  (NOLOCK) WHERE   a.customer_code = (SELECT sold_to FROM orders (NOLOCK) WHERE order_no = 333 AND ext = 0 ) AND      address_type = 9     
	--SELECT FieldName, FieldValue FROM #tdc_temp_manifest_string WHERE FieldName IN ('SHIPTOID', 'SHIPTONAME', 'SHIPTOADR1', 'SHIPTOADR2', 'SHIPTOADR3', 'SHIPTOATTN', 'SHIPTOCITY', 'SHIPTOSTAT', 'SHIPTOZIP', 'SHIPTOCNTRY') ORDER BY FieldName  
	  
	IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
	BEGIN  
	 SELECT @g_ship_to_code  = ISNULL(a.ship_to_code  , '')  
		,@g_ship_to_name  = ISNULL(a.address_name  , '')  
		,@g_addr1    = ISNULL(a.addr1   , '')  
		,@g_addr2    = ISNULL(a.addr2   , '')  
		,@g_addr3    = ISNULL(a.addr3   , '')  
		,@g_attention_name = ISNULL(a.attention_name , '')  
		,@g_city    = ISNULL(a.city    , '')  
		,@q_state    = ISNULL(a.state   , '')  
		,@g_postal_code  = ISNULL(a.postal_code  , '')  
		,@g_country_code  = ISNULL(a.country_code  , '')  
	 FROM  armaster_all a  (NOLOCK)   
	 WHERE a.customer_code = (SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext ) AND  
		   address_type = 9  
	  
	 -- ShipToId    
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOID')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOID'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_ship_to_code + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOID'  
	 END       
	   
	 -- ShipToName    
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTONAME')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTONAME'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_ship_to_name + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTONAME'  
	 END       
	  
	 -- ShipToAdr1    
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOADR1')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOADR1'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_addr1 + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOADR1'  
	 END   
	   
	 -- ShipToAdr2  
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOADR2')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOADR2'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_addr2 + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOADR2'  
	 END    
	  
	 -- ShipToAdr3  
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOADR3')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOADR3'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_addr3 + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOADR3'  
	 END    
	   
	 -- ShipToATTN  
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOATTN')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOATTN'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_attention_name + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOATTN'  
	 END    
	  
	 -- ShipToCity  
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOCITY')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOCITY'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_city + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOCITY'  
	 END    
	  
	 -- ShipToST  
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOSTAT')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOSTAT'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@q_state + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOSTAT'  
	 END   
	  
	 -- ShipToZip  
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOZIP')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOZIP'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_postal_code + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOZIP'  
	 END   
	  
	 -- ShipToCountry  
	 IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) WHERE message = 'SENDCARTON' AND fieldname = 'SHIPTOCNTRY')     
	 BEGIN  
	  SELECT @field_length = ((endpos - startpos) +1)   
	  FROM   tdc_mis_msg_layout_tbl (NOLOCK)     
	  WHERE  message = 'SENDCARTON'AND fieldname = 'SHIPTOCNTRY'   
	  
	  UPDATE #tdc_temp_manifest_string  
	  SET    FieldValue = LEFT(@g_country_code + SPACE(@field_length), @field_length)  
	  WHERE  fieldname = 'SHIPTOCNTRY'  
	 END  
	   
	--SELECT FieldName, FieldValue FROM #tdc_temp_manifest_string WHERE FieldName IN ('SHIPTOID', 'SHIPTONAME', 'SHIPTOADR1', 'SHIPTOADR2', 'SHIPTOADR3', 'SHIPTOATTN', 'SHIPTOCITY', 'SHIPTOSTAT', 'SHIPTOZIP', 'SHIPTOCNTRY') ORDER BY FieldName  
	    
	END     
	--END   SED008 -- Global Ship To     
	-- v3.3 End
END
-- v3.4 End

RETURN 1  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[tdc_create_send_carton_string_sp] TO [public]
GO
