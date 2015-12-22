SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 11/10/2012 - Issue #904 - Add alloc quantities and POM Date to stock view  
CREATE PROCEDURE [dbo].[tdc_get_graphical_bin_view_data_sp]  
 @template_id int,  
 @view_by_style int,  
 @userid  varchar(50),  
 @phy_batch int,  
 @team_id varchar(30),  
 @err_msg varchar(255) OUTPUT  
  
AS  
  
DECLARE   
 @location   varchar(10),  
 @current_bin  varchar(12),  
 @current_row  int,  
 @part_no  varchar(30),  
 @part_count  decimal(20,8),  
 @phy_cyc_count  decimal(20,8),  
 @shade_amt  decimal(20,8),  
 @shade_color  varchar(20),  
 @bin_max_defined  int,  -- 0 for No, 1 for Yes  
 @bin_max_value  decimal(20,8),  
 @bin_type_color  int,  
 @usage_type  varchar(10),  
 --ALLOCATED BINS  
 @alloc_w_max  int,  
 @alloc_wo_max  int,  
 @nonalloc_w_max  int,  
 @nonalloc_wo_max int,  
 @empty_bin  int,  
 --COUNTED BINS  
 @cntd_qty_equal_system int,  
 @cntd_qty_less_system int,  
 @bin_not_yet_counted int,  
 @noncntd  int,  
 --SLOTTED BINS  
 @slotgood_w_max  int,  
 @slotgood_wo_max int,  
 @slotbad_w_max  int,  
 @slotbad_wo_max  int,  
 --INSTOCK BINS  
 @instock_w_max  int,  
 @instock_wo_max  int,  
 @notinstock_w_max int,  
 @notinstock_wo_max int,  
 --BIN TYPE COLORS  
 @open_bin_color  int,  
 @prodin_bin_color int,  
 @prodout_bin_color int,  
 @quarantine_bin_color int,  
 @receipt_bin_color int,  
 @replenish_bin_color int,  
 @language   varchar(10)  
-- v1.0 Start
DECLARE	@pom_date		datetime,
		@pom_date_str	varchar(10)
-- v1.0 End
  
 SELECT @language = ISNULL(Language, 'us_english') FROM tdc_sec (nolock) WHERE userid = @userid  
  
 SELECT @location = location FROM tdc_graphical_bin_template (NOLOCK) WHERE template_id = @template_id  
 IF @view_by_style NOT IN (0, 1, 2, 4)  
 BEGIN   
  --'Invalid or Undefined view by style has been entered.'  
  SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 1 AND language = @language  
  RETURN -1  
 END  
 SELECT @phy_cyc_count = 0  
 --SET BIN TYPE COLORS  
 SELECT  @open_bin_color = open_color,   
  @prodin_bin_color = prodin_color,   
  @prodout_bin_color = prodout_color,   
  @quarantine_bin_color = quarantine_color,   
  @receipt_bin_color = receipt_color,   
  @replenish_bin_color = replenish_color  
  FROM tdc_graphical_bin_view_bin_type_color_tbl (NOLOCK)  
 WHERE template_viewbyid = @view_by_style  
  
 --SET BIN COLORS  
 --ALLOC VIEW  
 IF @view_by_style = 0  
 BEGIN  
  SELECT @alloc_w_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 1  
  SELECT @alloc_wo_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 2  
  SELECT @nonalloc_w_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 3  
  SELECT @nonalloc_wo_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 4  
  SELECT @empty_bin = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 5  
 END  
 --CYCLE COUNT VIEW  
 IF @view_by_style = 1  
 BEGIN  
  SELECT @cntd_qty_equal_system = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 1  
  SELECT @cntd_qty_less_system = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 2  
  SELECT @bin_not_yet_counted = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 3  
  SELECT @noncntd = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 4  
  SELECT @empty_bin = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 5  
 END  
 --PHYSICAL COUNT VIEW  
 IF @view_by_style = 2  
 BEGIN  
  SELECT @cntd_qty_equal_system = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 1  
  SELECT @cntd_qty_less_system = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 2  
  SELECT @bin_not_yet_counted = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 3  
  SELECT @noncntd = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 4  
  SELECT @empty_bin = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 5  
 END  
 --SLOTTING VIEW  
 IF @view_by_style = 3  
 BEGIN  
  SELECT @slotgood_w_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 1  
  SELECT @slotgood_wo_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 2  
  SELECT @slotbad_w_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 3  
  SELECT @slotbad_wo_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 4  
  SELECT @empty_bin = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 5  
 END  
 --IN STOCK VIEW  
 IF @view_by_style = 4  
 BEGIN  
  SELECT @instock_w_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 1  
  SELECT @instock_wo_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 2  
  SELECT @notinstock_w_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 3  
  SELECT @notinstock_wo_max = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 4  
  SELECT @empty_bin = bin_color   
   FROM tdc_graphical_bin_view_by_method_color_tbl (NOLOCK)  
   WHERE template_viewbyid = @view_by_style   
     AND seq_no = 5  
 END  
  
 --ALLOCATED QUANTITIES VIEW  
 IF @view_by_style = 0  
 BEGIN  
  INSERT INTO #tdc_graphical_bin_view_display_data (bin_no)  
   SELECT bin_no FROM tdc_graphical_bin_store WHERE template_id = @template_id ORDER BY row, col  
  
  DECLARE bin_view_update_cursor CURSOR FOR  
   SELECT rowid,  ISNULL(CASE WHEN bin_no LIKE '<%>' THEN '' ELSE bin_no END, '') FROM #tdc_graphical_bin_view_display_data ORDER BY rowid  
  OPEN bin_view_update_cursor  
  FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
   SELECT  @bin_max_value = ISNULL(maximum_level, 0), @usage_type = usage_type_code FROM tdc_bin_master (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
  
   SELECT @bin_type_color =   
     CASE @usage_type  
      WHEN 'OPEN'   THEN @open_bin_color  
      WHEN 'PRODIN'  THEN @prodin_bin_color  
      WHEN 'PRODOUT'  THEN @prodout_bin_color  
      WHEN 'QUARANTINE' THEN @quarantine_bin_color  
      WHEN 'RECEIPT'  THEN @receipt_bin_color  
      WHEN 'REPLENISH' THEN @replenish_bin_color  
      ELSE @empty_bin  
     END  
  
   IF @bin_max_value = 0  
    SELECT @bin_max_defined = 0  
   ELSE  
    SELECT @bin_max_defined = 1  
  
   --SET THE PART_NO  
   IF EXISTS(SELECT TOP 1 * FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location)  
   BEGIN  
    IF EXISTS(SELECT * FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
    BEGIN  
     IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id) 
HAVING Count(DISTINCT part_no) > 1)  
      SELECT @part_no = (SELECT TOP 1 part_no FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id))  
     ELSE  
      SELECT @part_no = 'Mixed'  
   
     --SET THE PART_COUNT  
     SELECT @part_count= ISNULL(SUM(qty), 0) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
     IF @part_count = 0   
     BEGIN  
      SELECT @part_no = '(Filtered Out)', @phy_cyc_count = 0  
     END  
     ELSE  
      SELECT @phy_cyc_count= ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
    END  
    ELSE  
    BEGIN  
     IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location HAVING Count(DISTINCT part_no) > 1)  
      SELECT @part_no = (SELECT TOP 1 part_no FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location)  
     ELSE  
      SELECT @part_no = 'Mixed'  
   
     --SET THE PART_COUNT  
     SELECT @part_count= ISNULL(SUM(qty), 0) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
	 -- v1.0 Start 
     SELECT @phy_cyc_count= ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
	 -- v1.0 End
    END  
  
    --SET THE SHADE_AMOUNT, SHADE_TYPE AND SHADE_COLOR  
    --WE WILL DRAW THE BINS DIFFERENTLY, DEPENDING ON WHETHER OR NOT BIN MAX AMOUNTS HAVE BEEN SET UP  
    IF @bin_max_defined = 1  
    BEGIN  
     SELECT  @shade_color = @alloc_w_max,  
      @shade_amt = (@part_count/@bin_max_value)*100  
    END  
    ELSE  
    BEGIN  
     SELECT  @shade_color = @alloc_wo_max,   
      @shade_amt = 100  
    END  
   END  
   ELSE  
   BEGIN  
    SELECT  @part_count = 0,   
     @shade_amt = 100,   
     @shade_color = @nonalloc_w_max  
  
    SELECT  @part_no = 'No Inv. Alloc'  
  
    IF @bin_max_defined <> 1  
     SELECT @shade_color = @nonalloc_wo_max  
   END  
  
   IF @current_bin = ''  
   BEGIN  
    SELECT  @shade_color = @empty_bin,  
     @bin_type_color = @empty_bin,  
     @part_no = ''  
   END  
  
   UPDATE #tdc_graphical_bin_view_display_data   
    SET part_no = @part_no, part_count = @part_count, shade_amt = @shade_amt, shade_color = @shade_color, bin_type_color = @bin_type_color, phy_cyc_count = @phy_cyc_count  
    WHERE rowid = @current_row  
   FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin  
  END  
  CLOSE bin_view_update_cursor  
  DEALLOCATE bin_view_update_cursor  
 END  
  
 --CYCLE COUNT VIEW  
 IF @view_by_style = 1  
 BEGIN  
  IF NOT EXISTS(SELECT * FROM tdc_phy_cyc_count (NOLOCK) WHERE team_id = @team_id AND location = @location)  
  BEGIN  
   --'Invalid Cycle Count has been entered.'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 2 AND language = @language  
   RETURN -2  
  END   
  
  INSERT INTO #tdc_graphical_bin_view_display_data (bin_no)  
   SELECT bin_no FROM tdc_graphical_bin_store WHERE template_id = @template_id ORDER BY row, col  
   
  DECLARE bin_view_update_cursor CURSOR FOR  
   SELECT rowid,  ISNULL(CASE WHEN bin_no LIKE '<%>' THEN '' ELSE bin_no END, '') FROM #tdc_graphical_bin_view_display_data ORDER BY rowid  
  OPEN bin_view_update_cursor  
  FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
   SELECT  @usage_type = usage_type_code FROM tdc_bin_master (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
  
   SELECT @bin_type_color =   
     CASE @usage_type  
      WHEN 'OPEN'   THEN @open_bin_color  
      WHEN 'PRODIN'  THEN @prodin_bin_color  
      WHEN 'PRODOUT'  THEN @prodout_bin_color  
      WHEN 'QUARANTINE' THEN @quarantine_bin_color  
      WHEN 'RECEIPT'  THEN @receipt_bin_color  
      WHEN 'REPLENISH' THEN @replenish_bin_color  
      ELSE @empty_bin  
     END  
   --SET THE PART_NO  
   IF EXISTS(SELECT TOP 1 * FROM tdc_phy_cyc_count (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND team_id = @team_id)  
   BEGIN  
    IF EXISTS(SELECT * FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
    BEGIN  
     IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM tdc_phy_cyc_count (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id) 
						AND team_id = @team_id HAVING Count(DISTINCT part_no) > 1)  
      SELECT @part_no = (SELECT TOP 1 part_no FROM tdc_phy_cyc_count (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id) AND team_id = @team_id)  
     ELSE  
      SELECT @part_no = 'Mixed'  
  
     --SET THE PART_COUNT ACCORDING TO THE SYSTEM  
     SELECT @part_count= ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
     IF @part_count = 0   
     BEGIN  
      SELECT @part_no = '(Filtered Out)'  
     END  
     SELECT @phy_cyc_count= ISNULL(SUM(count_qty), 0) FROM tdc_phy_cyc_count (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id) AND team_id = @team_id   
    END   
    ELSE  
    BEGIN  
     IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM tdc_phy_cyc_count (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND team_id = @team_id HAVING Count(DISTINCT part_no) > 1)  
      SELECT @part_no = (SELECT TOP 1 part_no FROM tdc_phy_cyc_count (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND team_id = @team_id)  
     ELSE  
      SELECT @part_no = 'Mixed'  
    
     --SET THE PART_COUNT  
     SELECT @part_count= ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
     SELECT @phy_cyc_count= ISNULL(SUM(count_qty), 0) FROM tdc_phy_cyc_count (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND team_id = @team_id   
    END   
    --SET THE SHADE_AMOUNT AND SHADE_COLOR  
    --WE WILL SHADE THE BINS DIFFERENTLY, DEPENDING ON WHETHER OR NOT ANY QUANTITIES OF PARTS HAVE BEEN COUNTED FOR THE SPECIFIED BIN  
    SELECT @shade_color =   
     CASE WHEN @phy_cyc_count = @part_count THEN @cntd_qty_equal_system  
          WHEN @phy_cyc_count <> @part_count AND @phy_cyc_count <> 0 THEN @cntd_qty_less_system   
          WHEN @phy_cyc_count <> @part_count AND @phy_cyc_count = 0 THEN @bin_not_yet_counted  
          WHEN @phy_cyc_count = 0 THEN @noncntd  
     END, @shade_amt = 100  
   END  
   ELSE  
   BEGIN  
    SELECT  @part_count = 0,   
     @shade_amt = 100,   
     @shade_color = @noncntd,  
     @part_no = 'No Inv. To Cnt'  
   END  
  
   IF @current_bin = ''  
   BEGIN  
    SELECT  @shade_color = @empty_bin,  
     @bin_type_color = @empty_bin,  
     @part_no = ''  
   END  
   
   UPDATE #tdc_graphical_bin_view_display_data   
    SET part_no = @part_no, part_count = @part_count, shade_amt = @shade_amt, shade_color = @shade_color, bin_type_color = @bin_type_color, phy_cyc_count = @phy_cyc_count  
    WHERE rowid = @current_row  
   FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin  
  END  
  CLOSE bin_view_update_cursor  
  DEALLOCATE bin_view_update_cursor  
 END  
  
 --PHYSICAL COUNT VIEW  
 IF @view_by_style = 2  
 BEGIN  
  IF NOT EXISTS(SELECT * FROM lot_bin_phy (NOLOCK) WHERE phy_batch = @phy_batch AND location = @location)  
  BEGIN  
   --'Invalid Physical Count batch number has been entered.'  
   SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 3 AND language = @language  
   RETURN -3  
  END  
  
  INSERT INTO #tdc_graphical_bin_view_display_data (bin_no)  
   SELECT bin_no FROM tdc_graphical_bin_store WHERE template_id = @template_id ORDER BY row, col  
   
  DECLARE bin_view_update_cursor CURSOR FOR  
   SELECT rowid,  ISNULL(CASE WHEN bin_no LIKE '<%>' THEN '' ELSE bin_no END, '') FROM #tdc_graphical_bin_view_display_data ORDER BY rowid  
  OPEN bin_view_update_cursor  
  FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
   SELECT  @usage_type = usage_type_code FROM tdc_bin_master (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
  
   SELECT @bin_type_color =   
     CASE @usage_type  
      WHEN 'OPEN'   THEN @open_bin_color  
      WHEN 'PRODIN'  THEN @prodin_bin_color  
      WHEN 'PRODOUT'  THEN @prodout_bin_color  
      WHEN 'QUARANTINE' THEN @quarantine_bin_color  
      WHEN 'RECEIPT'  THEN @receipt_bin_color  
      WHEN 'REPLENISH' THEN @replenish_bin_color  
      ELSE @empty_bin  
     END  
  
   --SET THE PART_NO  
   IF EXISTS(SELECT TOP 1 * FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location)  
   BEGIN  
    IF EXISTS(SELECT * FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
    BEGIN  
     IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id) HAVING Count(DISTINCT part_no) > 1)  
      SELECT @part_no = (SELECT TOP 1 part_no FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id))  
     ELSE  
      SELECT @part_no = 'Mixed'  
  
     --SET THE PART_COUNT ACCORDING TO THE SYSTEM  
     SELECT @part_count= ISNULL(SUM(qty), 0) FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
     IF @part_count = 0   
     BEGIN  
      SELECT @part_no = '(Filtered Out)'  
     END  
     SELECT @phy_cyc_count= ISNULL(SUM(qty_physical), 0) FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id) 
 
    END   
    ELSE  
    BEGIN  
     IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location HAVING Count(DISTINCT part_no) > 1)  
      SELECT @part_no = (SELECT TOP 1 part_no FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location)  
     ELSE  
      SELECT @part_no = 'Mixed'  
    
     --SET THE PART_COUNT  
     SELECT @part_count= ISNULL(SUM(qty), 0) FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
     SELECT @phy_cyc_count= ISNULL(SUM(qty_physical), 0) FROM lot_bin_phy (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
    END   
    --SET THE SHADE_AMOUNT AND SHADE_COLOR  
    --WE WILL SHADE THE BINS DIFFERENTLY, DEPENDING ON WHETHER OR NOT ANY QUANTITIES OF PARTS HAVE BEEN COUNTED FOR THE SPECIFIED BIN  
    SELECT @shade_color =   
     CASE WHEN @phy_cyc_count = @part_count THEN @cntd_qty_equal_system  
          WHEN @phy_cyc_count <> @part_count AND @phy_cyc_count <> 0 THEN @cntd_qty_less_system   
          WHEN @phy_cyc_count <> @part_count AND @phy_cyc_count = 0 THEN @bin_not_yet_counted  
          WHEN @phy_cyc_count = 0 THEN @noncntd  
     END, @shade_amt = 100  
   END  
   ELSE  
   BEGIN  
    SELECT  @part_count = 0,   
     @shade_amt = 100,   
     @shade_color = @noncntd,  
     @part_no = 'No Inv. To Cnt'  
   END  
  
   IF @current_bin = ''  
   BEGIN  
    SELECT  @shade_color = @empty_bin,  
     @bin_type_color = @empty_bin,  
     @part_no = ''  
   END  
   
   UPDATE #tdc_graphical_bin_view_display_data   
    SET part_no = @part_no, part_count = @part_count, shade_amt = @shade_amt, shade_color = @shade_color, bin_type_color = @bin_type_color, phy_cyc_count = @phy_cyc_count  
    WHERE rowid = @current_row  
   FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin  
  END  
  CLOSE bin_view_update_cursor  
  DEALLOCATE bin_view_update_cursor  
 END  
 --SLOTTING VIEW  
 IF @view_by_style = 3  
 BEGIN  
  RETURN 0  
 END  
  
 --IN STOCK QUANTITIES VIEW  
 IF @view_by_style = 4  
 BEGIN  
  INSERT INTO #tdc_graphical_bin_view_display_data (bin_no)  
   SELECT bin_no FROM tdc_graphical_bin_store WHERE template_id = @template_id ORDER BY row, col  
  
  DECLARE bin_view_update_cursor CURSOR FOR  
   SELECT rowid,  ISNULL(CASE WHEN bin_no LIKE '<%>' THEN '' ELSE bin_no END, '') FROM #tdc_graphical_bin_view_display_data ORDER BY rowid  
  OPEN bin_view_update_cursor  
  FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
   SELECT  @bin_max_value = ISNULL(maximum_level, 0), @usage_type = usage_type_code FROM tdc_bin_master (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
  
   SELECT @bin_type_color =   
     CASE @usage_type  
      WHEN 'OPEN'   THEN @open_bin_color  
      WHEN 'PRODIN'  THEN @prodin_bin_color  
      WHEN 'PRODOUT'  THEN @prodout_bin_color  
      WHEN 'QUARANTINE' THEN @quarantine_bin_color  
      WHEN 'RECEIPT'  THEN @receipt_bin_color  
      WHEN 'REPLENISH' THEN @replenish_bin_color  
      ELSE @empty_bin  
     END  
  
   IF @bin_max_value = 0  
    SELECT @bin_max_defined = 0  
   ELSE  
    SELECT @bin_max_defined = 1  
  
   --SET THE PART_NO  
   SET @pom_date = NULL
   IF EXISTS(SELECT TOP 1 * FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location)  
   BEGIN  
    IF EXISTS(SELECT * FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
    BEGIN  
     IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id) HAVING Count(DISTINCT part_no) > 1)  
	  BEGIN
		SELECT @part_no = (SELECT TOP 1 part_no FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id))  
		-- v1.0 Start
		SELECT @pom_date = field_28 FROM inv_master_add (NOLOCK) WHERE part_no = @part_no
		-- v1.0 End
	  END
     ELSE  
      SELECT @part_no = 'Mixed'  
     --SET THE PART_COUNT  
     SELECT @part_count= ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
	 -- v1.0 Start
     SELECT @phy_cyc_count = ISNULL(SUM(qty), 0) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location  AND part_no IN (SELECT part_no FROM #tdc_bin_view_part_filter_view_only_tbl (NOLOCK) WHERE template_id = @template_id)  
	 -- v1.0 End
     IF @part_count = 0   
     BEGIN  
      SELECT @part_no = '(Filtered Out)'  
     END  
    END   
    ELSE  
    BEGIN  
     IF NOT EXISTS(SELECT Count(DISTINCT part_no) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location HAVING Count(DISTINCT part_no) > 1)  
     BEGIN
      SELECT @part_no = (SELECT TOP 1 part_no FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location)  
		-- v1.0 Start
		SELECT @pom_date = field_28 FROM inv_master_add (NOLOCK) WHERE part_no = @part_no
		-- v1.0 End
	  END
     ELSE  
      SELECT @part_no = 'Mixed'  
   
     --SET THE PART_COUNT  
     SELECT @part_count= ISNULL(SUM(qty), 0) FROM lot_bin_stock (NOLOCK) WHERE bin_no = @current_bin AND location = @location  
     SELECT @phy_cyc_count = ISNULL(SUM(qty), 0) FROM tdc_soft_alloc_tbl (NOLOCK) WHERE bin_no = @current_bin AND location = @location
    END      --SET THE SHADE_AMOUNT, SHADE_TYPE AND SHADE_COLOR  
    --WE WILL DRAW THE BINS DIFFERENTLY, DEPENDING ON WHETHER OR NOT BIN MAX AMOUNTS HAVE BEEN SET UP  
    IF @bin_max_defined = 1  
    BEGIN  
     SELECT  @shade_color = @instock_w_max,  
      @shade_amt = (@part_count/@bin_max_value)*100  
    END  
    ELSE  
    BEGIN  
     SELECT  @shade_color = @instock_wo_max,   
      @shade_amt = 100  
    END  
   END  
   ELSE  
   BEGIN  
    SELECT  @part_count = 0,   
     @shade_amt = 100,   
     @shade_color = @notinstock_w_max  
  
    SELECT  @part_no = 'No Inv. In Bin'  
  
    IF @bin_max_defined <> 1  
     SELECT @shade_color = @notinstock_wo_max  
   END  
   IF @current_bin = ''  
   BEGIN  
    SELECT  @shade_color = @empty_bin,  
     @bin_type_color = @empty_bin,  
     @part_no = ''  
   END  
  
   -- v1.0 Start
   IF @pom_date IS NULL
		SET @pom_date_str = ''
   ELSE
	    SET @pom_date_str = CONVERT(varchar(10), @pom_date, 101)
   -- v1.0 End

   UPDATE #tdc_graphical_bin_view_display_data   
    SET part_no = @part_no, part_count = @part_count, shade_amt = @shade_amt, shade_color = @shade_color, bin_type_color = @bin_type_color, phy_cyc_count = @phy_cyc_count
    -- v1.0 Start
    , pom_date = @pom_date_str
    -- v1.0 End  
    WHERE rowid = @current_row  
   FETCH NEXT FROM bin_view_update_cursor INTO @current_row, @current_bin  
  END  
  CLOSE bin_view_update_cursor  
  DEALLOCATE bin_view_update_cursor  
 END  

RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_get_graphical_bin_view_data_sp] TO [public]
GO
