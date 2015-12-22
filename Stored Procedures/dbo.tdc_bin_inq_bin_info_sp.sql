SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 12/03/2012 - Display primary / secondary bins for the part even with no stock  
                                           
CREATE PROCEDURE [dbo].[tdc_bin_inq_bin_info_sp]  
 @AND_Criteria  varchar(4000),  
 @view_by int -- 0: View by Bin; 1: View by Part  
AS  
  
DECLARE @insert_clause   varchar(500),  
 @lb_stock_clause varchar(4000),  
 @cdock_passbin_clause varchar(4000),  
 @totebin_clause  varchar(4000),  
 @stlbin_clause  varchar(4000),  
 @otherbins_clause varchar(4000), 
 @primsec_bins varchar(4000) -- v1.0 
  
TRUNCATE TABLE #tdc_bin_inq_bin_info  
  
IF @AND_Criteria IS NULL SET @AND_Criteria = ''  
  
-- All  BINs from lot_bin_stock  
SET @insert_clause   = 'INSERT INTO #tdc_bin_inq_bin_info (location, bin_no, usage_type, size_group, cost_group, group_code, inactive)'  
  
SET @lb_stock_clause = 'SELECT DISTINCT a.location, a.bin_no, b.usage_type_code, b.size_group_code, b.cost_group_code, b.group_code,  
          CASE b.status WHEN ''A'' THEN 0 ELSE -1 END  
            FROM lot_bin_stock  a (NOLOCK),   
          tdc_bin_master b (NOLOCK),   
          inv_master     c (NOLOCK)                  
    WHERE a.bin_no   = b.bin_no                                            
      AND a.location = b.location   
      AND a.part_no  = c.part_no '        
                          
  
-- All  CDOCK & PASSBIN BINs  
SET @cdock_passbin_clause = 'SELECT DISTINCT a.location, a.dest_bin bin_no, b.usage_type_code, b.size_group_code, b.cost_group_code, b.group_code,  
               CASE b.status WHEN ''A'' THEN 0 ELSE -1 END  
             FROM tdc_soft_alloc_tbl a (NOLOCK),   
                                    tdc_bin_master     b (NOLOCK),   
                                    inv_master         c (NOLOCK)             
          WHERE a.dest_bin = b.bin_no                                            
               AND a.location = b.location                                            
              AND b.usage_type_code IN (''CDOCK'', ''PASSBIN'')                          
               AND a.dest_bin IS NOT NULL   
           AND a.part_no  = c.part_no '                                            
  
  
-- All  TOTEBINs   
SET @totebin_clause = 'SELECT DISTINCT a.location, a.bin_no, b.usage_type_code, b.size_group_code, b.cost_group_code, b.group_code,   
         CASE b.status WHEN ''A'' THEN 0 ELSE -1 END  
                  FROM tdc_tote_bin_tbl a (NOLOCK),   
         tdc_bin_master   b (NOLOCK),   
         inv_master       c (NOLOCK)                 
   WHERE a.bin_no   = b.bin_no                                            
     AND a.location = b.location   
     AND a.part_no  = c.part_no '        
                          
-- All  STLBINs   
SET @stlbin_clause = 'SELECT DISTINCT b.location, a.stlbin_no, b.usage_type_code, b.size_group_code, b.cost_group_code, b.group_code,     
                 CASE b.status WHEN ''A'' THEN 0 ELSE -1 END  
          FROM tdc_carton_tx a (NOLOCK), tdc_bin_master b (NOLOCK), inv_master c (NOLOCK), tdc_carton_detail_tx d (NOLOCK)                  
                WHERE a.stlbin_no = b.bin_no   
           AND a.carton_no = d.carton_no  
    AND d.part_no   = c.part_no '                                                        
  
-- All other bins  
SET @otherbins_clause = 'SELECT DISTINCT location, bin_no, usage_type_code, size_group_code, cost_group_code, group_code,      
           CASE b.status WHEN ''A'' THEN 0 ELSE -1 END  
             FROM tdc_bin_master b (NOLOCK)                  
     WHERE bin_no + ''|$$$|'' + location NOT IN   
     (SELECT DISTINCT bin_no + ''|$$$|'' + location FROM #tdc_bin_inq_bin_info) '   
  
-- v1.0 Primary and secondary bins with no stock
SET @primsec_bins = 'SELECT DISTINCT m.location, m.bin_no, m.usage_type_code, m.size_group_code, 
				m.cost_group_code, m.group_code, CASE m.status WHEN ''A'' THEN 0 ELSE -1 END
				FROM tdc_bin_master m (NOLOCK) JOIN tdc_bin_part_qty t (NOLOCK) ON m.location = t.location AND m.bin_no = t.bin_no 
				JOIN  inv_master c (NOLOCK) ON t.part_no = c.part_no JOIN locations b (NOLOCK) ON t.location = b.location '


IF @view_by = 0 -- View by Bin  
BEGIN  
 EXEC (  
  @insert_clause        +   
        @lb_stock_clause      + @AND_Criteria + ' UNION ' +  
        @cdock_passbin_clause + @AND_Criteria + ' UNION ' +  
        @totebin_clause       + @AND_Criteria + ' UNION ' +  
        @stlbin_clause        + @AND_Criteria + ' UNION ' +  
        @otherbins_clause     + @AND_Criteria  
      )  
END  
ELSE  -- View by Part  
BEGIN  
 EXEC (  
  @insert_clause        +   
        @lb_stock_clause      + @AND_Criteria + ' UNION ' +  
        @cdock_passbin_clause + @AND_Criteria + ' UNION ' +  
        @totebin_clause       + @AND_Criteria + ' UNION ' +  
        @stlbin_clause        + @AND_Criteria + ' UNION ' + -- v1.0
		@primsec_bins		  + @AND_Criteria -- v1.0
      )  
END  
  
RETURN  
GO
GRANT EXECUTE ON  [dbo].[tdc_bin_inq_bin_info_sp] TO [public]
GO
