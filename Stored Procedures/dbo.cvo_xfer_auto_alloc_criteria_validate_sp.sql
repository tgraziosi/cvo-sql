SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[cvo_xfer_auto_alloc_criteria_validate_sp]    
 @xfer_no int,    
 @process_template varchar(20) OUTPUT    
     
AS    
    
DECLARE @criteria_fill_percent int,    
		@actual_fill_percent int,    
		@location varchar(10),    
		@priority int   
      
SELECT @actual_fill_percent = -1    
   
DECLARE auto_alloc_criteria_cur     
CURSOR FOR    
 SELECT DISTINCT cvo_xfer_auto_alloc_templates_tbl.priority, cvo_xfer_auto_alloc_templates_tbl.process_template_code, xfer_list.from_loc, tdc_plw_criteria_templates.fill_percent    
   FROM xfers (NOLOCK),     
        xfer_list(NOLOCK),     
        tdc_plw_criteria_templates(NOLOCK),    
        cvo_xfer_auto_alloc_templates_tbl(NOLOCK)    
  WHERE xfers.xfer_no     = @xfer_no    
    AND xfers.xfer_no     = xfer_list.xfer_no     
    AND cvo_xfer_auto_alloc_templates_tbl.criteria_template_code = tdc_plw_criteria_templates.template_code    
        
 -- Locations    
 AND(tdc_plw_criteria_templates.location = 'ALL' OR tdc_plw_criteria_templates.location = xfer_list.from_loc)    
 AND(tdc_plw_criteria_templates.to_loc = 'ALL' OR tdc_plw_criteria_templates.to_loc = xfer_list.to_loc)    
  
 --Ship Date Start    
 AND((tdc_plw_criteria_templates.ship_date_start = 0)     
  OR ((DATEDIFF(DAY, xfers.sch_ship_date, GETDATE()) <= tdc_plw_criteria_templates.ship_date_start)))    
     
 --Ship Date End    
 AND((tdc_plw_criteria_templates.ship_date_end = 0)     
  OR ((DATEDIFF(DAY, GETDATE(), xfers.sch_ship_date) <= tdc_plw_criteria_templates.ship_date_end)))    
                   
-- Delivery Start Date  
 AND((tdc_plw_criteria_templates.delivery_date_start = 0)     
  OR ((DATEDIFF(DAY, xfers.req_ship_date, GETDATE()) <= tdc_plw_criteria_templates.delivery_date_start)))    
     
-- Delivery End Date  
 AND((tdc_plw_criteria_templates.delivery_date_end = 0)     
  OR ((DATEDIFF(DAY, GETDATE(), xfers.req_ship_date) <= tdc_plw_criteria_templates.delivery_date_end)))    
   
 -- Carrier Filter         
 AND ((NOT EXISTS(SELECT * FROM tdc_sia_carrier_code_filter_tbl(NOLOCK)    
       WHERE template_code = tdc_plw_criteria_templates.template_code)) OR xfers.routing IN(SELECT carrier_code     
                  FROM tdc_sia_carrier_code_filter_tbl(NOLOCK)    
                        WHERE template_code = tdc_plw_criteria_templates.template_code))    
     
 -- Part Filter    
 AND ((NOT EXISTS(SELECT * FROM tdc_sia_part_filter_tbl(NOLOCK)    
     WHERE template_code = tdc_plw_criteria_templates.template_code)) OR EXISTS(SELECT a.part_no    
               FROM xfer_list a(NOLOCK),    
                    tdc_sia_part_filter_tbl b(NOLOCK)    
              WHERE a.xfer_no = xfer_list.xfer_no    
                AND a.from_loc = xfer_list.from_loc
                AND b.template_code = tdc_plw_criteria_templates.template_code     
                AND a.from_loc = b.location    
                AND a.part_no = b.part_no ))     
 ORDER BY cvo_xfer_auto_alloc_templates_tbl.priority    
    
OPEN auto_alloc_criteria_cur    
FETCH NEXT FROM auto_alloc_criteria_cur INTO @priority, @process_template, @location, @criteria_fill_percent    
    
WHILE @@FETCH_STATUS = 0    
BEGIN    
  
 IF NOT EXISTS (SELECT 1 FROM dbo.tdc_plw_process_templates WHERE template_code = @process_template  
     AND location = @location)  
 BEGIN  
   CLOSE auto_alloc_criteria_cur    
   DEALLOCATE auto_alloc_criteria_cur    
   RETURN -1   
 END  
  
 -- If fill percent is 0, a record has been found that passed the criteria.    
 -- return success    
 IF @criteria_fill_percent = 0    
 BEGIN    
  CLOSE auto_alloc_criteria_cur    
  DEALLOCATE auto_alloc_criteria_cur    
  RETURN 0    
 END    
    
 -- If fill percent is greater than 0 and the actual fill percent has not been filled,     
 -- determine the actual fill percent    
 ELSE IF @criteria_fill_percent > 0 AND ISNULL(@actual_fill_percent, -1) = -1     
 BEGIN    
  EXEC @actual_fill_percent = cvo_transfer_fill_pct_sp @xfer_no 
 END    
    
 -- If the actual fill percent is greater than the criteria fill percent, return success    
 IF ISNULL(@actual_fill_percent, -1) >= @criteria_fill_percent    
 BEGIN    
  CLOSE auto_alloc_criteria_cur    
  DEALLOCATE auto_alloc_criteria_cur    
  RETURN 0    
 END    
    
    
 FETCH NEXT FROM auto_alloc_criteria_cur INTO @priority, @process_template, @location, @criteria_fill_percent    
END    
CLOSE auto_alloc_criteria_cur    
DEALLOCATE auto_alloc_criteria_cur    
    
-- If code flow makes it here, return -1 (failure)    
RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[cvo_xfer_auto_alloc_criteria_validate_sp] TO [public]
GO
