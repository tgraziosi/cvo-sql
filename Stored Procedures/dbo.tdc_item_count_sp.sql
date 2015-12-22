SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 08/11/2012 - Issue #888 - Add Res type to cycle count init

CREATE PROC [dbo].[tdc_item_count_sp] @err_msg  varchar(255) OUTPUT,  
								 @team_id  varchar(30),  
								 @location  varchar(10),  
								 @from_item  varchar(30),  
								 @to_item  varchar(30),  
								 @range_start  varchar(30),  
								 @range_end  varchar(30),
								 @res_type varchar(10) = '' -- v1.0  
AS  
  
DECLARE @flag int, @language varchar(10)  
  
SELECT @err_msg = 'OK'  
SELECT @flag = 0  
  
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')  
  
/* make sure that the location code passed is valid */  
   
IF NOT EXISTS (SELECT * FROM locations (NOLOCK) WHERE location = @location AND void = 'N')  
BEGIN  
	-- Invalid location:  
	SELECT @err_msg = err_msg + @location FROM tdc_lookup_error (NOLOCK) WHERE module = 'SPR' AND trans = 'tdc_item_count_sp' AND err_no = -110 AND language = @language  
	RETURN -110  
END  
    
IF (@from_item <= @to_item)  
BEGIN  
	/* For L/B Tracked Items ******/  
	SELECT @flag = count(*)   
	FROM inv_master i (nolock), lot_bin_stock l (nolock), tdc_phy_cyc_count c (nolock)  
	WHERE l.location = @location  
	AND c.location = l.location  
	AND i.status not in ('R', 'C', 'V', 'K')  
	AND i.void <> 'V'    -- IA 08/08/00 Exclude Voided Items  
	AND c.team_id  = @team_id  
	AND i.part_no between @from_item AND @to_item  
	AND l.lot_ser = c.lot_ser  
	AND i.lb_tracking = 'Y'  
	AND c.part_no = l.part_no  
	AND c.part_no = i.part_no  
	AND c.bin_no = l.bin_no  
  
	/* For Non L/B Tracked Items ******/  
	IF(@flag = 0)  
		SELECT @flag = count(*)   
		FROM inventory i (nolock), tdc_phy_cyc_count c (nolock)  
		WHERE i.location = @location  
		AND c.location = i.location  
		AND i.status not in ('R', 'C', 'V', 'K')  
		AND i.void <> 'V'   -- IA 08/08/00 Exclude Voided Items  
		AND c.team_id  = @team_id  
		AND i.part_no between @from_item AND @to_item  
		AND i.lb_tracking = 'N'  
		AND c.part_no = i.part_no  
END  
ELSE  
BEGIN  
	-- exclude range item > @to_item and item < @from_item  
	SELECT @flag = count(*)   
	FROM inv_master i (nolock), lot_bin_stock l (nolock), tdc_phy_cyc_count c (nolock)  
	WHERE l.location = @location  
    AND c.location = l.location  
    AND i.status not in ('R', 'C', 'V', 'K')  
    AND i.void <> 'V'    -- IA 08/08/00 Exclude Voided Items  
    AND c.team_id  = @team_id  
    AND l.part_no >= @from_item  
    AND l.lot_ser = c.lot_ser  
    AND i.lb_tracking = 'Y'  
    AND c.part_no = l.part_no  
    AND c.part_no = i.part_no  
    AND c.bin_no = l.bin_no  
  
	/* For Non L/B Tracked Items ******/  
	IF(@flag = 0)  
		SELECT @flag = count(*)   
		FROM inventory i (nolock), tdc_phy_cyc_count c (nolock)  
		WHERE i.location = @location  
		AND c.location = i.location  
		AND i.status not in ('R', 'C', 'V', 'K')  
		AND i.void <> 'V'   -- IA 08/08/00 Exclude Voided Items  
		AND c.team_id  = @team_id  
		AND i.part_no >= @from_item   
		AND i.lb_tracking = 'N'  
		AND c.part_no = i.part_no  
  
	/* For L/B Tracked Items ******/  
	IF(@flag = 0)  
		SELECT @flag = count(*)   
		FROM inv_master i (nolock), lot_bin_stock l (nolock), tdc_phy_cyc_count c (nolock)  
		WHERE l.location = @location  
		AND c.location = l.location  
		AND i.status not in ('R', 'C', 'V', 'K')  
		AND i.void <> 'V'   -- IA 08/08/00 Exclude Voided Items  
		AND c.team_id  = @team_id  
		AND l.part_no <= @to_item  
		AND l.lot_ser = c.lot_ser  
		AND i.lb_tracking = 'Y'  
		AND c.part_no = l.part_no  
		AND c.part_no = i.part_no  
		AND c.bin_no = l.bin_no  
  
	/* For Non L/B Tracked Items ******/  
	IF(@flag = 0)  
		SELECT @flag = count(*)   
		FROM inventory i (nolock), tdc_phy_cyc_count c (nolock)  
		WHERE i.location = @location  
		AND c.location = i.location  
		AND i.status not in ('R', 'C', 'V', 'K')  
		AND i.void <> 'V'   -- IA 08/08/00 Exclude Voided Items  
		AND c.team_id  = @team_id  
		AND i.part_no <= @to_item  
		AND i.lb_tracking = 'N'  
		AND c.part_no = i.part_no  
END  
  
IF (@flag > 0)  
BEGIN  
	-- Some Items in Requested Range are already in Process  
	SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_item_count_sp' AND err_no = -120 AND language = @language  
	RETURN(-120)  
END  
  
BEGIN TRAN  
  
/* if pcs is not installed, then serial# remains NULL  */  
/* else populate serial#'s from the tdc_pcs_item table */  
  
IF (@from_item <= @to_item)  
BEGIN  
	/***** For Lot/Bin Tracked Items ***************************/  
	INSERT INTO tdc_phy_cyc_count  
	(team_id, cyc_code, location, part_no, lot_ser, bin_no, cycle_date, range_type, range_start, range_end)  
	SELECT DISTINCT @team_id, i.cycle_type, @location, l.part_no, l.lot_ser, l.bin_no, getdate(), 'PART', @range_start, @range_end  
	FROM lot_bin_stock l (nolock), inv_master i (nolock), tdc_bin_master t (nolock)  
	WHERE l.location = @location  
    AND l.bin_no = t.bin_no  
    AND t.usage_type_code IN ('OPEN', 'REPLENISH')  
    AND l.part_no = i.part_no  
    AND l.part_no between @from_item and @to_item  
    AND i.lb_tracking = 'Y'  
    AND i.status not in ('R', 'C', 'V', 'K')  
    AND i.void <> 'V'    -- IA 08/08/00 Exclude Voided Items  
	AND (i.type_code = @res_type OR @res_type = '')
  
	/********* For Non L/B Tracked Items ************************/  
	INSERT INTO tdc_phy_cyc_count  
	(team_id, cyc_code, location, part_no, cycle_date, range_type, range_start, range_end)  
	SELECT  @team_id, cycle_type, location, part_no, getdate(), 'PART', @range_start, @range_end  
	FROM inventory (nolock)  
	WHERE location = @location  
    AND part_no between @from_item and @to_item  
    AND lb_tracking = 'N'  
    AND status not in ('R', 'C', 'V', 'K')  
    AND void <> 'V'    -- IA 08/08/00 Exclude Voided Items  
    AND in_stock <> 0    -- IA 02-17-00 not allow qty = 0 
	AND (type_code = @res_type OR @res_type = '') 
END  
ELSE   
BEGIN  
	/***** For Lot/Bin Tracked Items ***************************/   
	INSERT INTO tdc_phy_cyc_count  
	(team_id, cyc_code, location, part_no, lot_ser, bin_no, cycle_date, range_type, range_start, range_end)  
	SELECT DISTINCT @team_id, i.cycle_type, @location, l.part_no, l.lot_ser, l.bin_no, getdate(), 'PART', @range_start, @range_end  
	FROM lot_bin_stock l (nolock), inv_master i (nolock), tdc_bin_master t (nolock)  
	WHERE l.location = @location  
    AND l.bin_no = t.bin_no  
    AND t.usage_type_code IN ('OPEN', 'REPLENISH')  
    AND l.part_no = i.part_no  
    AND l.part_no >= @from_item  
    AND i.lb_tracking = 'Y'  
    AND i.status not in ('R', 'C', 'V', 'K')  
    AND i.void <> 'V'    -- IA 08/08/00 Exclude Voided Items  
	AND (i.type_code = @res_type OR @res_type = '')

	INSERT INTO tdc_phy_cyc_count  
	(team_id, cyc_code, location, part_no, lot_ser, bin_no, cycle_date, range_type, range_start, range_end)  
	SELECT DISTINCT @team_id, i.cycle_type, @location, l.part_no, l.lot_ser, l.bin_no, getdate(), 'PART', @range_start, @range_end  
	FROM lot_bin_stock l (nolock), inv_master i (nolock), tdc_bin_master t (nolock)  
	WHERE l.location = @location  
    AND l.bin_no = t.bin_no  
    AND t.usage_type_code IN ('OPEN', 'REPLENISH')  
    AND l.part_no = i.part_no  
    AND l.part_no <= @to_item  
    AND i.lb_tracking = 'Y'  
    AND i.status not in ('R', 'C', 'V', 'K')  
    AND i.void <> 'V'    -- IA 08/08/00 Exclude Voided Items  
	AND (i.type_code = @res_type OR @res_type = '')
  
	/***** For Non L/B Tracked Items ***************************/   
	INSERT INTO tdc_phy_cyc_count  
	(team_id, cyc_code, location, part_no, cycle_date, range_type, range_start, range_end)  
	SELECT  @team_id, cycle_type, location, part_no, getdate(), 'PART', @range_start, @range_end  
	FROM inventory (nolock)  
	WHERE location = @location  
    AND part_no >= @from_item  
    AND lb_tracking = 'N'  
    AND status not in ('R', 'C', 'V', 'K')  
    AND void <> 'V'    -- IA 08/08/00 Exclude Voided Items  
    AND in_stock <> 0    -- IA 02-17-00 not allow qty = 0  
	AND (type_code = @res_type OR @res_type = '')

	INSERT INTO tdc_phy_cyc_count  
	(team_id, cyc_code, location, part_no, cycle_date, range_type, range_start, range_end)  
	SELECT  @team_id, cycle_type, location, part_no, getdate(), 'PART', @range_start, @range_end  
	FROM inventory (nolock)  
	WHERE location = @location  
    AND part_no <= @to_item  
    AND lb_tracking = 'N'  
    AND status not in ('R', 'C', 'V', 'K')  
    AND void <> 'V'    -- IA 08/08/00 Exclude Voided Items  
    AND in_stock <> 0    -- IA 02-17-00 not allow qty = 0  
	AND (type_code = @res_type OR @res_type = '')
  
END  
  
COMMIT TRAN  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_item_count_sp] TO [public]
GO
