SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v3.0 TM  10-24-2011  If order is COLLECT then Send the Customers Account#  
-- v3.1	CT	15/01/2014	Issue #1413 - 3rd Party Freight changes 
-- tag 081914 - remove default phone number for CVO

CREATE PROCEDURE [dbo].[tdc_create_send_master_pack_string_sp]  
 @station_id  VARCHAR(25),  
 @operator  VARCHAR(50),  
 @pack_no  INT,  
 @err_msg VARCHAR(255) OUTPUT  
AS  
  
  
/*DECLARE @Shipper  VARCHAR(255)  
DECLARE @CartonSEQ   INT  
DECLARE @CartonTotal INT  
DECLARE @UnitTotal INT  
DECLARE @OrderNo  INT  
DECLARE @OrderExt INT*/  
  
DECLARE @pos   int,  
 @field_length  int,  
 @field_value  varchar(255),  
 @freight_allow_type varchar(10),  
 @carton_no  int,  
 @order_no   int,         --v3.0  
 @order_ext  int,         --v3.0  
 @cust_code varchar(8),      --v3.0  
 @routing varchar(30)      --v3.0  
  
--##################################################################  
--Initialize the variables  
--##################################################################  
  
IF (SELECT COUNT(*) FROM tdc_stage_carton (NOLOCK)  
 WHERE carton_no = @pack_no) > 0   
BEGIN  
 SELECT @err_msg = 'Master Pack already freighted'  
 RETURN -1  
END   
  
  
-- Remove all the records for unfreight or freight      
TRUNCATE TABLE #tdc_temp_manifest_string  
  
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
  
 IF(SELECT COUNT(DISTINCT order_no)     
   FROM tdc_carton_tx a(NOLOCK),  
        tdc_master_pack_ctn_tbl b(NOLOCK)  
  WHERE a.carton_no = b.carton_no  
    AND b.pack_no = @pack_no) = 1  
 BEGIN  
  SELECT DISTINCT @field_value = CAST(order_no AS VARCHAR)  
    FROM tdc_carton_tx a(NOLOCK),  
         tdc_master_pack_ctn_tbl b(NOLOCK)  
   WHERE a.carton_no = b.carton_no  
     AND b.pack_no = @pack_no  
 END  
 ELSE  
  SELECT @field_value = ''  
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, LEFT(@field_value + SPACE(@field_length),@field_length), 'ORDER')  
  
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
 VALUES (@pos, LEFT(CAST(@pack_no AS VARCHAR(255)) + SPACE(@field_length),@field_length),  
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
  
 SELECT @field_value = CAST(ISNULL(weight, 0.0) AS VARCHAR(25))  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, SPACE(@field_length), 'SHIPTOID')  
  
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
  
 SELECT @field_value = ISNULL([name], '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 SELECT @field_value = ISNULL(address1, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 SELECT @field_value = ISNULL(address2, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 SELECT @field_value = ISNULL(attention, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 SELECT @field_value = ISNULL(city, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 SELECT @field_value = ISNULL(state, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 SELECT @field_value = ISNULL(zip, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 SELECT @field_value = ISNULL(country, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
 SELECT @field_value = ISNULL(carrier_code, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
 --BEGIN SED009 -- Clippership Integration  
 --JVM 10/25/2010  
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
  
 IF(SELECT COUNT(DISTINCT ISNULL(charge_code, ''))  
      FROM tdc_carton_tx a(NOLOCK),  
    tdc_master_pack_ctn_tbl b(NOLOCK)  
     WHERE b.pack_no = @pack_no  
       AND a.carton_no = b.carton_no) = 1  
 BEGIN  
  SELECT @field_value = ISNULL(charge_code, '')  
   FROM tdc_carton_tx (NOLOCK)   
   WHERE carton_no =  @pack_no  
 END  
 ELSE  
  SELECT @field_value = ''  
  
--v3.0 BEGIN  
 SELECT TOP 1 @order_no = order_no, @order_ext = order_ext         --v3.0  
   FROM tdc_carton_tx a (NOLOCK), tdc_master_pack_ctn_tbl b(NOLOCK)        --v3.0  
  WHERE b.pack_no = @pack_no AND a.carton_no = b.carton_no          --v3.0  
  
 SELECT @freight_allow_type = freight_allow_type, @routing = routing, @cust_code = cust_code     --v3.0  
   FROM orders WHERE order_no = @order_no AND ext = @order_ext         --v3.0  
  
 -- START v3.1
 IF @freight_allow_type = 'COLLECT' OR @freight_allow_type = 'THRDPRTY'																
 --IF @freight_allow_type = 'COLLECT'															--v3.0
 -- END v3.1 
 BEGIN               --v3.0  
   SELECT @field_value = '2'           --v3.0  
 END               --v3.0  
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
  
 SELECT @field_value = CAST(SUM((b.gross_sales - b.total_discount) + (b.freight + b.total_tax)) AS VARCHAR(255))  
    FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
  WHERE c.pack_no = @pack_no  
    AND a.carton_no = c.carton_no  
    AND b.order_no  = a.order_no  
    AND b.ext       = a.order_ext  
   
  
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
 DECLARE cur CURSOR FOR   
  SELECT carton_no FROM tdc_master_pack_ctn_tbl WHERE pack_no = @pack_no  
 OPEN cur  
 FETCH NEXT FROM cur INTO @carton_no  
 WHILE @@FETCH_STATUS = 0  
 BEGIN  
   EXEC tdc_calc_carton_value_sp @carton_no  
 END  
 CLOSE cur  
 DEALLOCATE CUR  
  
 SELECT @field_value = (SELECT SUM(ISNULL(carton_content_value, 0) + ISNULL(carton_tax_value, 0))  
     FROM tdc_carton_tx a(NOLOCK),  
        tdc_master_pack_ctn_tbl b(NOLOCK)  
  WHERE b.pack_no = @pack_no  
    AND a.carton_no = b.carton_no)  
  
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
 VALUES (@pos, SPACE(@field_length), 'SHIPPER')  
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
  
 SELECT @field_value = ISNULL(cust_code, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
  
   
 IF(SELECT COUNT(DISTINCT cust_po)     
   FROM tdc_carton_tx a(NOLOCK),  
        tdc_master_pack_ctn_tbl b(NOLOCK)  
  WHERE a.carton_no = b.carton_no  
    AND b.pack_no = @pack_no) = 1  
 BEGIN  
  SELECT DISTINCT @field_value = cust_po  
    FROM tdc_carton_tx a(NOLOCK),  
         tdc_master_pack_ctn_tbl b(NOLOCK)  
   WHERE a.carton_no = b.carton_no  
     AND b.pack_no = @pack_no  
 END  
 ELSE  
  SELECT @field_value = ''  
  
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
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, LEFT('N' + SPACE(@field_length),@field_length), 'LASTCART')  
  
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
   --IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
   -- AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
  
  
   IF EXISTS(SELECT DISTINCT b.sold_to   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
     
   BEGIN  
                        
   --SELECT @field_value = (SELECT sold_to_addr1 FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
  
    SELECT @field_value = (SELECT TOP 1 b.sold_to_addr1   
        FROM tdc_carton_tx a (NOLOCK),   
         orders b (NOLOCK),  
         tdc_master_pack_ctn_tbl c(NOLOCK)  
      WHERE c.pack_no = @pack_no  
        AND a.carton_no = c.carton_no  
        AND b.order_no  = a.order_no  
        AND b.ext       = a.order_ext)  
        --AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
  
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
   --IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
   -- AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
  
   IF EXISTS(SELECT DISTINCT b.sold_to   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
     
   BEGIN  
                        
   --SELECT @field_value = (SELECT sold_to_addr2 FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
    SELECT @field_value = (SELECT TOP 1 b.sold_to_addr2   
        FROM tdc_carton_tx a (NOLOCK),   
         orders b (NOLOCK),  
         tdc_master_pack_ctn_tbl c(NOLOCK)  
      WHERE c.pack_no = @pack_no  
        AND a.carton_no = c.carton_no  
        AND b.order_no  = a.order_no  
        AND b.ext       = a.order_ext)  
  
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
   --IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
   -- AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
  
   IF EXISTS(SELECT DISTINCT b.sold_to   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
     
   BEGIN  
                        
   --SELECT @field_value = (SELECT sold_to_addr3 FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
    SELECT @field_value = (SELECT TOP 1 b.sold_to_addr3   
        FROM tdc_carton_tx a (NOLOCK),   
         orders b (NOLOCK),  
         tdc_master_pack_ctn_tbl c(NOLOCK)  
      WHERE c.pack_no = @pack_no  
        AND a.carton_no = c.carton_no  
        AND b.order_no  = a.order_no  
        AND b.ext       = a.order_ext)  
  
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
   --IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
   -- AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
  
   IF EXISTS(SELECT DISTINCT b.sold_to   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
     
   BEGIN  
                        
   --SELECT @field_value = (SELECT sold_to_city FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
    SELECT @field_value = (SELECT TOP 1 b.sold_to_city   
        FROM tdc_carton_tx a (NOLOCK),   
         orders b (NOLOCK),  
         tdc_master_pack_ctn_tbl c(NOLOCK)  
      WHERE c.pack_no = @pack_no  
        AND a.carton_no = c.carton_no  
        AND b.order_no  = a.order_no  
        AND b.ext       = a.order_ext)  
  
  
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
   --IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
   -- AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   IF EXISTS(SELECT DISTINCT b.sold_to   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
  
   BEGIN  
                        
   --SELECT @field_value = (SELECT sold_to_state FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
    SELECT @field_value = (SELECT TOP 1 b.sold_to_state  
        FROM tdc_carton_tx a (NOLOCK),   
         orders b (NOLOCK),  
         tdc_master_pack_ctn_tbl c(NOLOCK)  
      WHERE c.pack_no = @pack_no  
        AND a.carton_no = c.carton_no  
        AND b.order_no  = a.order_no  
        AND b.ext       = a.order_ext)  
  
  
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
   --IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
   -- AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
     
   IF EXISTS(SELECT DISTINCT b.sold_to   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
  
   BEGIN  
                        
   --SELECT @field_value = (SELECT sold_to_zip FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
    SELECT @field_value = (SELECT TOP 1 b.sold_to_zip  
        FROM tdc_carton_tx a (NOLOCK),   
         orders b (NOLOCK),  
         tdc_master_pack_ctn_tbl c(NOLOCK)  
      WHERE c.pack_no = @pack_no  
        AND a.carton_no = c.carton_no  
        AND b.order_no  = a.order_no  
        AND b.ext       = a.order_ext)  
  
  
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
   --IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
   -- AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
  
   IF EXISTS(SELECT DISTINCT b.sold_to   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
     
   BEGIN  
                        
   --SELECT @field_value = (SELECT ISNULL(sold_to_country_cd,'US') FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)   
  
    SELECT @field_value = (SELECT TOP 1 ISNULL(b.sold_to_country_cd,'US')   
        FROM tdc_carton_tx a (NOLOCK),   
         orders b (NOLOCK),  
         tdc_master_pack_ctn_tbl c(NOLOCK)  
      WHERE c.pack_no = @pack_no  
        AND a.carton_no = c.carton_no  
        AND b.order_no  = a.order_no  
        AND b.ext       = a.order_ext)  
  
  
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
   --IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext   
   -- AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
  
   IF EXISTS(SELECT DISTINCT b.sold_to   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
     
    BEGIN  
                         
     SELECT @field_value = (select TOP 1  IsNull(d.account,'')   
       FROM tdc_carton_tx a (NOLOCK),   
        orders b (NOLOCK),  
        tdc_master_pack_ctn_tbl c(NOLOCK),  
        cust_carrier_account d (NOLOCK)  
     WHERE c.pack_no = @pack_no  
       AND a.carton_no = c.carton_no  
       AND b.order_no  = a.order_no  
       AND b.ext       = a.order_ext  
       --AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
       AND d.cust_code = b.sold_to   
       AND b.routing = d.routing        --v3.0  
       AND d.freight_allow_type = d.freight_allow_type)  
  
      --WHERE cust_code = @sold_to AND routing = @routing        --v3.0  
      --AND freight_allow_type = @freight_allow_type   
  */
   END  
   ELSE  
   BEGIN  
		IF @freight_allow_type = 'THRDPRTY'
		BEGIN
			SELECT @field_value = (select TOP 1  IsNull(d.account,'')   
			FROM tdc_carton_tx a (NOLOCK),   
				orders b (NOLOCK),  
				tdc_master_pack_ctn_tbl c(NOLOCK),  
				cust_carrier_account d (NOLOCK)  
			WHERE c.pack_no = @pack_no  
				AND a.carton_no = c.carton_no  
				AND b.order_no  = a.order_no  
				AND b.ext       = a.order_ext  
				--AND b.sold_to IS NOT NULL AND LTRIM (b.sold_to) <> '' AND RTRIM (b.sold_to) <> '')  
				AND d.cust_code = b.sold_to   
				AND b.routing = d.routing        --v3.0  
				-- AND d.freight_allow_type = d.freight_allow_type
				AND b.freight_allow_type = d.freight_allow_type) 
			/*
			SELECT @field_value = IsNull(account,'') FROM cust_carrier_account    --v3.0  
			 WHERE cust_code = @cust_code AND routing = @routing        --v3.0  
			   AND freight_allow_type = @freight_allow_type         --v3.0  
		   */
		END  
		ELSE  
		BEGIN  
			SELECT @field_value = ''                --v3.0  
		END   
 END  
 -- END v3.1
  
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)    
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), '3PB_ACCOUNT')    
    
END    
/*    
--v3.0 BEGIN  
 IF @freight_allow_type = 'COLLECT'             --v3.0  
   BEGIN                    --v3.0  
  SELECT @field_value = IsNull(account,'') FROM cust_carrier_account    --v3.0  
   WHERE cust_code = @cust_code AND routing = @routing        --v3.0  
     AND freight_allow_type = @freight_allow_type         --v3.0  
   END   
 ELSE  
   BEGIN  
  SELECT @field_value = ''                --v3.0  
   END  
--v3.0 END  
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)  
 VALUES (@pos, LEFT(@field_value  + SPACE(@field_length),@field_length), '3PB_ACCOUNT')  
  
END  
*/  
  
  
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
    -- tag 081914 - remove default phone number
	--   WHEN '' THEN '1-631-787-1500'  
	   WHEN '' THEN ''  
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
 VALUES (@pos, SPACE(@field_length), 'CARTON_SEQ')  
  
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
 VALUES (@pos, SPACE(@field_length), 'CARTON_TOTAL')  
  
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
 VALUES (@pos, SPACE(@field_length), 'UNIT_TOTAL')  
  
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
  
 IF(SELECT COUNT(DISTINCT order_ext)     
   FROM tdc_carton_tx a(NOLOCK),  
        tdc_master_pack_ctn_tbl b(NOLOCK)  
  WHERE a.carton_no = b.carton_no  
    AND b.pack_no = @pack_no) = 1  
 BEGIN  
  SELECT DISTINCT @field_value = CAST(order_ext AS VARCHAR)  
    FROM tdc_carton_tx a(NOLOCK),  
         tdc_master_pack_ctn_tbl b(NOLOCK)  
   WHERE a.carton_no = b.carton_no  
     AND b.pack_no = @pack_no  
 END  
 ELSE  
  SELECT @field_value = ''  
  
 INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname)   
 VALUES (@pos, LEFT(@field_value + SPACE(@field_length),@field_length), 'ORDER_EXT')  
  
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
  
 SELECT @field_value = ISNULL(address3, '')  
  FROM tdc_master_pack_tbl (NOLOCK)   
  WHERE pack_no =  @pack_no  
  
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
    
SELECT TOP 1 @order_no  = a.order_no  
            ,@order_ext = a.order_ext  
FROM    tdc_carton_tx a(NOLOCK)  
       ,tdc_master_pack_ctn_tbl b(NOLOCK)  
WHERE  a.carton_no = b.carton_no AND   
       b.pack_no   = @pack_no  
  
IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')  
BEGIN  
 SELECT @g_ship_to_code  = ISNULL(a.ship_to_code  , '')  
    ,@g_ship_to_name  = ISNULL(a.address_name  , '')  
    ,@g_addr1    = ISNULL(a.addr2   , '')  
    ,@g_addr2    = ISNULL(a.addr3   , '')  
    ,@g_addr3    = ISNULL(a.addr4   , '')  
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
RETURN 1  
  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[tdc_create_send_master_pack_string_sp] TO [public]
GO
