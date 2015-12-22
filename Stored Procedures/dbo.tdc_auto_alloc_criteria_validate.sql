SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 01/04/2011 - 14.Planners Workbench
-- v1.1 CB 30/09/2011 - Add exit code for templates where the location is not set up
-- v1.2 CB 20/04/2015 - Performance Changes
CREATE PROC [dbo].[tdc_auto_alloc_criteria_validate]  
 @order_no int,  
 @order_ext int,  
 @process_template varchar(20) OUTPUT  
   
AS  
  
DECLARE @criteria_fill_percent int,  
 @actual_fill_percent int,  
 @location varchar(10),  
 @priority int 
  
--BEGIN SED009 -- AutoAllocation    
--JVM 07/09/2010
DECLARE @user_code VARCHAR(8)
SELECT @user_code = ISNULL(user_stat_code,'') 
FROM   so_usrstat (NOLOCK)
WHERE  default_flag = 1 AND 
       status_code = 'A'
--END   SED009 -- AutoAllocation  

-- v1.2 Start
CREATE TABLE #auto_alloc_criteria (
	row_id					int IDENTITY(1,1),
	priority				int NULL,
	process_template_code	varchar(50) NULL,
	location				varchar(10) NULL,
	fill_percent			int NULL)

DECLARE	@row_id			int,
		@last_row_id	int

SET @last_row_id = 0
-- v1.2 End
  
SELECT @actual_fill_percent = -1  

-- v1.2 Start
--DECLARE auto_alloc_criteria_cur   
--CURSOR FOR   

INSERT	#auto_alloc_criteria (priority, process_template_code, location, fill_percent) 
-- v1.2 End 
 SELECT DISTINCT tdc_auto_alloc_templates_tbl.priority, tdc_auto_alloc_templates_tbl.process_template_code, ord_list.location, tdc_plw_criteria_templates.fill_percent  
   FROM orders (NOLOCK),   
        ord_list(NOLOCK),   
        armaster(NOLOCK),  
        tdc_order(NOLOCK),  
        tdc_plw_criteria_templates(NOLOCK),  
        tdc_auto_alloc_templates_tbl(NOLOCK)  
  WHERE orders.order_no     = @order_no  
    AND orders.ext    = @order_ext  
    AND orders.order_no     = ord_list.order_no   
    AND orders.ext          = ord_list.order_ext   
    AND orders.cust_code    = armaster.customer_code  
    AND orders.cust_code    = armaster.customer_code  
    AND orders.ship_to      = armaster.ship_to_code  
    AND orders.type         = 'I'     
    AND tdc_order.order_no  = orders.order_no  
    AND tdc_order.order_ext = orders.ext  
    AND tdc_auto_alloc_templates_tbl.criteria_template_code = tdc_plw_criteria_templates.template_code  
    AND armaster.address_type = (SELECT MAX(address_type)   
                     FROM armaster (NOLOCK)   
                 WHERE customer_code = orders.cust_code   
                    AND ship_to_code  = orders.ship_to)   
   
 --Location  
 AND(tdc_plw_criteria_templates.location = 'ALL' OR tdc_plw_criteria_templates.location = ord_list.location)  

--BEGIN SED009 -- AutoAllocation    
--JVM 07/09/2010
 /*AND((tdc_plw_criteria_templates.order_status = 3) OR( orders.status =  CASE tdc_plw_criteria_templates.order_status WHEN 0 THEN 'N'    
                   WHEN 1 THEN 'P'  
                   WHEN 2 THEN 'Q' END))  */ 
 AND((tdc_plw_criteria_templates.order_status = 3) OR( orders.status =  CASE tdc_plw_criteria_templates.order_status WHEN 0 THEN 'N'    
																	   WHEN 1 THEN 'P'  
																	   WHEN 2 THEN 'Q' END)
												   OR( orders.status = 'A' AND orders.user_code = @user_code AND orders.hold_reason IN (SELECT hold_code FROM CVO_alloc_hold_values_tbl (NOLOCK))))  
--END   SED009 -- AutoAllocation    
																	   
 --Order Priority  
 AND((tdc_plw_criteria_templates.order_priority_range = 0)   
  OR ((tdc_plw_criteria_templates.order_priority_range = 1 AND orders.so_priority_code BETWEEN tdc_plw_criteria_templates.order_priority_start AND tdc_plw_criteria_templates.order_priority_end)   
  OR (tdc_plw_criteria_templates.order_priority_range = 2 AND orders.so_priority_code NOT BETWEEN tdc_plw_criteria_templates.order_priority_start AND tdc_plw_criteria_templates.order_priority_end)))  
   
 --Ship Date Start  
 AND((tdc_plw_criteria_templates.ship_date_start = 0)   
  OR ((DATEDIFF(DAY, orders.sch_ship_date, GETDATE()) <= tdc_plw_criteria_templates.ship_date_start)))  
   
 --Ship Date End  
 AND((tdc_plw_criteria_templates.ship_date_end = 0)   
  OR ((DATEDIFF(DAY, GETDATE(), orders.sch_ship_date) <= tdc_plw_criteria_templates.ship_date_end)))  
   
 --Sold To  
 AND((tdc_plw_criteria_templates.sold_to = 'ALL') OR (orders.cust_code = tdc_plw_criteria_templates.sold_to))  
   
 --Ship To  
 AND((tdc_plw_criteria_templates.ship_to = 'ALL') OR (orders.cust_code = tdc_plw_criteria_templates.ship_to))  
   
            
 --Territory  
 AND((tdc_plw_criteria_templates.territory = 'ALL') OR (orders.ship_to_region = tdc_plw_criteria_templates.territory))  
   
 --Dest Zone  
 AND((tdc_plw_criteria_templates.destination_zone = 'ALL') OR (orders.dest_zone_code = tdc_plw_criteria_templates.destination_zone))  
   
 --Carrier  
 --AND((tdc_plw_criteria_templates.destination_zone = 'ALL') OR (orders.dest_zone_code = tdc_plw_criteria_templates.destination_zone))  
   
 --Postalcode  
 --If cboCriteriaTemplate.ListIndex = 0 Then  
       
    
 --Cust Opt1  
 AND((tdc_plw_criteria_templates.cust_op1 = 'ALL') OR (armaster.addr_sort1 = tdc_plw_criteria_templates.cust_op1))  
   
 --Cust Opt1  
 AND((tdc_plw_criteria_templates.cust_op2 = 'ALL') OR (armaster.addr_sort1 = tdc_plw_criteria_templates.cust_op2))  
   
 --Cust Opt1  
 AND((tdc_plw_criteria_templates.cust_op3 = 'ALL') OR (armaster.addr_sort1 = tdc_plw_criteria_templates.cust_op3))    
      
 --Ship To Name  
 AND((tdc_plw_criteria_templates.ship_to_name = 'ALL') OR (orders.ship_to_name = tdc_plw_criteria_templates.ship_to_name))  
   
       
 --Ship To City  
 AND((tdc_plw_criteria_templates.ship_to_city = 'ALL') OR (orders.ship_to_city = tdc_plw_criteria_templates.ship_to_city))  
   
 --Ship To State  
 AND((tdc_plw_criteria_templates.ship_to_state = 'ALL') OR (orders.ship_to_state = tdc_plw_criteria_templates.ship_to_state))  
   
 --Ship To Country  
 AND((tdc_plw_criteria_templates.ship_to_country = 'ALL') OR (orders.ship_to_country = tdc_plw_criteria_templates.ship_to_country))  
   
    
 --Cust PO   
 AND((tdc_plw_criteria_templates.cust_po = 'ALL') OR (orders.cust_po = tdc_plw_criteria_templates.cust_po))  
   
 --User Status  
 AND((tdc_plw_criteria_templates.user_status_code = 'ALL') OR (orders.user_code = tdc_plw_criteria_templates.user_status_code))  
   
 --Category  
 AND((tdc_plw_criteria_templates.user_category = 'ALL') OR (orders.user_category = tdc_plw_criteria_templates.user_category))  
   
 --Load No   
 AND ((ISNULL(tdc_plw_criteria_templates.load_no, 0) = 0) OR (CAST(orders.order_no AS VARCHAR) + '-' + CAST(orders.ext AS VARCHAR)   
     IN( SELECT CAST(order_no AS VARCHAR) + '-' + CAST(order_ext AS VARCHAR)   
                                       FROM load_list(NOLOCK)   
                                      WHERE load_no =  tdc_plw_criteria_templates.load_no)) )  

-- v1.0 Start
-- Delivery Start Date
 AND((tdc_plw_criteria_templates.delivery_date_start = 0)   
  OR ((DATEDIFF(DAY, orders.req_ship_date, GETDATE()) <= tdc_plw_criteria_templates.delivery_date_start)))  
   
-- Delivery End Date
 AND((tdc_plw_criteria_templates.delivery_date_end = 0)   
  OR ((DATEDIFF(DAY, GETDATE(), orders.req_ship_date) <= tdc_plw_criteria_templates.delivery_date_end)))  

-- User Hold
 AND ((tdc_plw_criteria_templates.user_hold = 'NONE' AND (orders.hold_reason = '' OR orders.hold_reason IN (SELECT hold_code FROM CVO_alloc_hold_values_tbl (NOLOCK)))) 
	OR (tdc_plw_criteria_templates.user_hold = 'ALL' AND orders.hold_reason IN (SELECT hold_code FROM adm_oehold))
    OR (orders.hold_reason = tdc_plw_criteria_templates.user_hold))

-- Order Type
 AND((tdc_plw_criteria_templates.order_type_code = 'ALL') OR (orders.user_category = tdc_plw_criteria_templates.order_type_code))  

-- v1.0 End   
 -- Carrier Filter       
 AND ((NOT EXISTS(SELECT * FROM tdc_sia_carrier_code_filter_tbl(NOLOCK)  
       WHERE template_code = tdc_plw_criteria_templates.template_code)) OR orders.routing IN(SELECT carrier_code   
                  FROM tdc_sia_carrier_code_filter_tbl(NOLOCK)  
                        WHERE template_code = tdc_plw_criteria_templates.template_code))  
   
 -- Postal Code Filter  
 AND ((NOT EXISTS(SELECT * FROM tdc_sia_postal_code_filter_tbl(NOLOCK)  
       WHERE template_code = tdc_plw_criteria_templates.template_code)) OR orders.ship_to_zip IN(SELECT postal_code   
                  FROM tdc_sia_postal_code_filter_tbl(NOLOCK)  
                        WHERE template_code = tdc_plw_criteria_templates.template_code))  
   
 -- Part Filter  
 AND ((NOT EXISTS(SELECT * FROM tdc_sia_part_filter_tbl(NOLOCK)  
     WHERE template_code = tdc_plw_criteria_templates.template_code)) OR EXISTS(SELECT a.part_no  
               FROM ord_list a(NOLOCK),  
                    tdc_sia_part_filter_tbl b(NOLOCK)  
              WHERE a.order_no = ord_list.order_no  
                AND a.order_ext = ord_list.order_ext  
                AND a.location = ord_list.location  
                AND b.template_code = tdc_plw_criteria_templates.template_code   
                AND a.location = b.location  
                AND a.part_no = b.part_no  
              UNION   
             SELECT a.part_no   
               FROM ord_list_kit a(NOLOCK),  
                    tdc_sia_part_filter_tbl b(NOLOCK)  
              WHERE a.order_no = ord_list.order_no  
                AND a.order_ext = ord_list.order_ext  
                AND a.location = ord_list.location  
                AND b.template_code = tdc_plw_criteria_templates.template_code   
                AND a.location = b.location  
                AND a.part_no = b.part_no))  
 ORDER BY tdc_auto_alloc_templates_tbl.priority  

-- v1.3 Start
SELECT	TOP 1 @row_id = row_id,
		@priority = priority,
		@process_template = process_template_code,
		@location = location,
		@criteria_fill_percent = fill_percent
FROM	#auto_alloc_criteria
WHERE	row_id > @last_row_id
ORDER BY row_id ASC

WHILE (@@ROWCOUNT <> 0)  
-- v1.3 OPEN auto_alloc_criteria_cur  
-- v1.3 FETCH NEXT FROM auto_alloc_criteria_cur INTO @priority, @process_template, @location, @criteria_fill_percent  
  
-- v1.3 WHILE @@FETCH_STATUS = 0  
BEGIN  

-- v1.1
	IF NOT EXISTS (SELECT 1 FROM dbo.tdc_plw_process_templates WHERE template_code = @process_template
					AND location = @location)
	BEGIN
-- v1.3	  CLOSE auto_alloc_criteria_cur  
-- v1.3	  DEALLOCATE auto_alloc_criteria_cur  
	  RETURN -1 
	END

 -- If fill percent is 0, a record has been found that passed the criteria.  
 -- return success  
 IF @criteria_fill_percent = 0  
 BEGIN  
-- v1.3  CLOSE auto_alloc_criteria_cur  
-- v1.3  DEALLOCATE auto_alloc_criteria_cur  
  RETURN 0  
 END  
  
 -- If fill percent is greater than 0 and the actual fill percent has not been filled,   
 -- determine the actual fill percent  
 ELSE IF @criteria_fill_percent > 0 AND ISNULL(@actual_fill_percent, -1) = -1   
 BEGIN  
  EXEC @actual_fill_percent = tdc_auto_alloc_get_fill_pct_sp @order_no, @order_ext, @location  
 END  
  
 -- If the actual fill percent is greater than the criteria fill percent, return success  
 IF ISNULL(@actual_fill_percent, -1) >= @criteria_fill_percent  
 BEGIN  
-- v1.3  CLOSE auto_alloc_criteria_cur  
-- v1.3  DEALLOCATE auto_alloc_criteria_cur  
  RETURN 0  
 END  

SET @last_row_id = @row_id
  
SELECT	TOP 1 @row_id = row_id,
		@priority = priority,
		@process_template = process_template_code,
		@location = location,
		@criteria_fill_percent = fill_percent
FROM	#auto_alloc_criteria
WHERE	row_id > @last_row_id
ORDER BY row_id ASC  


-- v1.3 FETCH NEXT FROM auto_alloc_criteria_cur INTO @priority, @process_template, @location, @criteria_fill_percent  
END  
-- v1.3 CLOSE auto_alloc_criteria_cur  
-- v1.3 DEALLOCATE auto_alloc_criteria_cur  
  
-- If code flow makes it here, return -1 (failure)  
RETURN -1  
  
GO
GRANT EXECUTE ON  [dbo].[tdc_auto_alloc_criteria_validate] TO [public]
GO
