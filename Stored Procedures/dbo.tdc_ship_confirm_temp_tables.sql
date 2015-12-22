SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CB 23/01/2012	Re-check for orders on stagehold and remove if orders have been processed

CREATE PROC [dbo].[tdc_ship_confirm_temp_tables]  
 @index   int, -- (0=To Confirm, 1=TDC Shipped, 2=Confirmed, 3=All Records  
  @stage_no varchar(11),   
 @carrier_code   varchar(10),   
 @station_id varchar(3)  
AS  
  
DECLARE @pack_no   int,  
 @upd_stage_no   varchar(11),  
 @upd_tdc_ship_flag  char(1),  
 @upd_adm_ship_flag  char(1),  
 @upd_tdc_ship_date  datetime,  
 @upd_adm_ship_date  datetime,  
 @upd_order_no   int,  
 @upd_order_ext   int,   
 @group_id  varchar(12)  
  
SELECT @group_id = group_id FROM tdc_pack_station_tbl (NOLOCK) WHERE station_id = @station_id  
  
-------------------------------------------------------------------------------------------  
-- Insert the fedex data  
-------------------------------------------------------------------------------------------  
INSERT INTO #temp_fedex_close_tbl (sel_flg, location)                          
SELECT sel_flg =                                                               
          CASE WHEN (EXISTS (SELECT location                                   
                               FROM tdc_fedex_close_request b (NOLOCK)         
                              WHERE b.location = a.location                    
                                AND b.station_id = @station_id  
                     )       )                                                 
               THEN -1                                                         
               ELSE 0                                                          
          END,                                                                 
       location                                                                
  FROM locations a (NOLOCK)                                       
       
-------------------------------------------------------------------------------------------  
-- Insert the cartons that are not masterpack  
-------------------------------------------------------------------------------------------   
INSERT INTO #temp_ship_confirm_display_tbl(stage_no, carton_no, master_pack, order_no, order_ext, tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date, carrier_code)  
SELECT stage_no, carton_no, 'N',   
 order_no = CASE WHEN (SELECT COUNT(order_no)   
    FROM tdc_carton_tx b(NOLOCK)  
          WHERE b.carton_no = a.carton_no) > 1  
   THEN -1  
   ELSE (SELECT TOP 1 order_no  
    FROM tdc_carton_tx b(NOLOCK)  
          WHERE b.carton_no = a.carton_no)  
   END,  
 order_ext = CASE WHEN (SELECT COUNT(order_ext)   
    FROM tdc_carton_tx b(NOLOCK)  
          WHERE b.carton_no = a.carton_no) > 1  
   THEN -1  
   ELSE (SELECT TOP 1 order_ext  
    FROM tdc_carton_tx b(NOLOCK)  
          WHERE b.carton_no = a.carton_no)  
   END,  
 tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date,  
 carrier_code =  (SELECT TOP 1 carrier_code  
          FROM tdc_carton_tx b(NOLOCK)  
        WHERE b.carton_no = a.carton_no)  
     
  FROM tdc_stage_carton a(NOLOCK)  
 WHERE (@stage_no = 'ALL' OR stage_no = @stage_no)  
   AND master_pack = 'N'  
   AND tdc_ship_flag = CASE WHEN @index IN(1, 2) THEN 'Y'  
       --WHEN @index = 0 THEN 'Y'  
       ELSE tdc_ship_flag END  
   AND adm_ship_flag = CASE WHEN @index = 2 THEN 'Y'  
       WHEN @index IN(0, 1) THEN 'N'  
       ELSE adm_ship_flag END  
   AND (@carrier_code = 'ALL' OR carton_no IN(SELECT carton_no FROM tdc_carton_tx WHERE carrier_code = @carrier_code))  
   AND EXISTS (SELECT * FROM tdc_carton_tx (NOLOCK) WHERE carton_no = a.carton_no)  
  
-------------------------------------------------------------------------------------------  
-- If master_pack is enabled  
-------------------------------------------------------------------------------------------   
IF EXISTS(SELECT * FROM tdc_config(NOLOCK)  
    WHERE [function] = 'master_pack'  
      AND active = 'Y')  
BEGIN  
  
 -------------------------------------------------------------------------------------------  
 -- If master packing  
 -------------------------------------------------------------------------------------------   
 IF EXISTS(SELECT * FROM tdc_pack_station_tbl(NOLOCK)  
     WHERE group_id = @group_id  
       AND station_id = @station_id  
       AND manifest_point != 'Carton Packing')  
 BEGIN  
  INSERT INTO #temp_ship_confirm_display_tbl(stage_no, carton_no, master_pack, order_no, order_ext)  
  SELECT DISTINCT '', pack_no, 'Y', -1, -1  
    FROM tdc_master_pack_ctn_tbl a(NOLOCK),  
          tdc_stage_carton b(NOLOCK)  
   WHERE (@stage_no = 'ALL' OR b.stage_no = @stage_no)  
     AND b.master_pack = 'Y'  
     AND b.tdc_ship_flag = CASE WHEN @index IN(1, 2) THEN 'Y'  
        -- WHEN @index = 0 THEN 'N'  
         ELSE tdc_ship_flag END  
     AND b.adm_ship_flag = CASE WHEN @index = 2 THEN 'Y'  
         WHEN @index IN(0, 1) THEN 'N'  
         ELSE adm_ship_flag END  
     AND b.carton_no = a.carton_no  
  
  DECLARE display_cur CURSOR FOR  
  SELECT carton_no  
    FROM #temp_ship_confirm_display_tbl  
   WHERE stage_no = ''  
  
  OPEN display_cur  
  FETCH NEXT FROM display_cur INTO @pack_no  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
   SELECT @upd_stage_no = NULL  
  
   SELECT TOP 1 @upd_stage_no = stage_no,  
         @upd_tdc_ship_flag = tdc_ship_flag,  
         @upd_adm_ship_flag = adm_ship_flag,  
         @upd_tdc_ship_date = tdc_ship_date,  
         @upd_adm_ship_date = adm_ship_date  
     FROM tdc_stage_carton a(NOLOCK),  
          tdc_master_pack_ctn_tbl b(NOLOCK)  
    WHERE a.carton_no = b.carton_no  
      AND b.pack_no = @pack_no  
  
     
   IF (SELECT COUNT(DISTINCT order_no)  
         FROM tdc_carton_tx a(NOLOCK),  
              tdc_master_pack_ctn_tbl b(NOLOCK)  
        WHERE a.carton_no = b.carton_no  
          AND b.pack_no = @pack_no) = 1  
   BEGIN  
        SELECT TOP 1 @upd_order_no = order_no,  
          @upd_order_ext = order_ext  
             FROM tdc_carton_tx a(NOLOCK),  
                  tdc_master_pack_ctn_tbl b(NOLOCK)  
            WHERE a.carton_no = b.carton_no  
              AND b.pack_no = @pack_no  
   END  
   ELSE  
    SELECT @upd_order_no = -1, @upd_order_ext = -1  
     
     
   -- If the records have been removed from the stage_carton table,  
   -- remove the record from display  
   IF @upd_stage_no IS NULL  
   BEGIN  
    DELETE FROM #temp_ship_confirm_display_tbl  
     WHERE carton_no = @pack_no  
   END  
  
   UPDATE #temp_ship_confirm_display_tbl  
      SET stage_no = @upd_stage_no,  
          tdc_ship_flag = @upd_tdc_ship_flag,  
          adm_ship_flag = @upd_adm_ship_flag,  
          tdc_ship_date = @upd_tdc_ship_date,  
          adm_ship_date = @upd_adm_ship_date  
    WHERE carton_no = @pack_no  
  
   FETCH NEXT FROM display_cur INTO @pack_no  
  END  
  CLOSE display_cur  
  DEALLOCATE display_cur  
    
   
 END  
 ELSE  
 -------------------------------------------------------------------------------------------  
 -- If carton packing  
 -------------------------------------------------------------------------------------------   
 BEGIN  
  INSERT INTO #temp_ship_confirm_display_tbl(stage_no, carton_no, master_pack, order_no, order_ext, tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date, carrier_code)  
  SELECT stage_no, carton_no, 'Y',   
   order_no = ISNULL((SELECT CASE WHEN (SELECT COUNT(order_no)   
      FROM tdc_carton_tx b(NOLOCK)  
            WHERE b.carton_no = a.carton_no) > 1  
     THEN -1  
     ELSE (SELECT TOP 1 order_no  
      FROM tdc_carton_tx b(NOLOCK)  
            WHERE b.carton_no = a.carton_no)  
     END), -1),  
   order_ext = ISNULL((SELECT CASE WHEN (SELECT COUNT(order_ext)   
      FROM tdc_carton_tx b(NOLOCK)  
            WHERE b.carton_no = a.carton_no) > 1  
     THEN -1  
     ELSE (SELECT TOP 1 order_ext  
      FROM tdc_carton_tx b(NOLOCK)  
            WHERE b.carton_no = a.carton_no)  
     END), -1),  
   tdc_ship_flag, adm_ship_flag, tdc_ship_date, adm_ship_date,  
   carrier_code = (SELECT TOP 1 carrier_code  
       FROM tdc_carton_tx b(NOLOCK)  
      WHERE b.carton_no = a.carton_no)  
    FROM tdc_stage_carton a(NOLOCK)  
   WHERE (@stage_no = 'ALL' OR stage_no = @stage_no)  
     AND master_pack = 'Y'  
     AND tdc_ship_flag = CASE WHEN @index IN(1, 2) THEN 'Y'  
       --  WHEN @index = 0 THEN 'N'  
         ELSE tdc_ship_flag END  
     AND adm_ship_flag = CASE WHEN @index = 2 THEN 'Y'  
         WHEN @index IN(0, 1) THEN 'N'  
         ELSE adm_ship_flag END  
    
 END  
END  
  
-- v1.1 Start
CREATE TABLE #stage_check (
	stage_no	varchar(20),
	on_hold		int)

INSERT	#stage_check (stage_no, on_hold)
SELECT	c.stage_no, MAX(ISNULL(a.stage_hold,0))
FROM	cvo_orders_all a (NOLOCK)
JOIN	tdc_carton_tx b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.ext = b.order_ext
JOIN	tdc_stage_carton c (NOLOCK)
ON		b.carton_no = c.carton_no
GROUP BY c.stage_no

DELETE	a
FROM	cvo_stage a (NOLOCK)
JOIN	#stage_check b (NOLOCK)
ON		a.stage_no = b.stage_no
WHERE	b.on_hold = 0

DROP TABLE #stage_check

-- v1.1 End

-- v1.0 Start  
UPDATE a  
SET  stage_hold = CASE WHEN b.stage_no IS NOT NULL THEN 'Y' ELSE 'N' END  
 FROM #temp_ship_confirm_display_tbl a  
 LEFT JOIN dbo.cvo_stage b (NOLOCK)  
 ON  a.stage_no = b.stage_no  
  
-- v1.0 End  
RETURN  
GO
GRANT EXECUTE ON  [dbo].[tdc_ship_confirm_temp_tables] TO [public]
GO
