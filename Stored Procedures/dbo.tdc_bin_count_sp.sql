SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_bin_count_sp]	
		@err_msg 	varchar(255) OUTPUT,
		@team_id 	varchar(30),
		@location 	varchar(10),
		@from_bin 	varchar(12),
		@to_bin 	varchar(12),
		@range_start 	varchar(30),
		@range_end 	varchar(30)

AS

DECLARE @flag int
DECLARE @language varchar(10)

SELECT @err_msg = 'OK'
SELECT @flag = 0
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

/* make sure that the location code passed is valid */
IF NOT EXISTS (SELECT * FROM locations (nolock) WHERE location = @location AND void = 'N')
BEGIN
	-- 'Invalid location'
 	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock)
         WHERE module = 'SPR' AND trans = 'tdc_bin_count_sp' AND err_no = -110 AND language = @language

	RETURN -110
END

/* IA 01/20/00	 			  */
/* Check is any of records already exists */
/* in tdc_phy_cyc_count table 	          */

IF (@from_bin <= @to_bin)
BEGIN
	SELECT @flag = count(*) 
	  FROM lot_bin_stock l (nolock), tdc_phy_cyc_count c (nolock) 
	 WHERE l.location = @location
	   AND c.location = l.location			
	   AND c.team_id  = @team_id
	   AND l.part_no  = c.part_no
	   AND l.bin_no between @from_bin AND @to_bin
	   AND l.lot_ser = c.lot_ser
	   AND c.bin_no = l.bin_no
END
ELSE
BEGIN
	SELECT @flag = count(*) 
	  FROM lot_bin_stock l (nolock), tdc_phy_cyc_count c (nolock)
	 WHERE l.location = @location
	   AND c.location = l.location
	   AND c.team_id  = @team_id
	   AND l.part_no  = c.part_no
	   AND l.bin_no >= @from_bin
	   AND l.lot_ser = c.lot_ser
	   AND c.bin_no = l.bin_no

	IF(@flag = 0)
		SELECT @flag = count(*) 
		  FROM lot_bin_stock l (nolock), tdc_phy_cyc_count c (nolock)
		 WHERE l.location = @location
		   AND c.location = l.location
		   AND c.team_id  = @team_id
		   AND l.part_no  = c.part_no
		   AND l.bin_no <= @to_bin
		   AND l.lot_ser = c.lot_ser
		   AND c.bin_no = l.bin_no
END

IF (@flag > 0)
BEGIN
	-- 'Some Items in Requested Range are already in Process'
 	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock)
         WHERE module = 'SPR' AND trans = 'tdc_bin_count_sp' AND err_no = -120 AND language = @language

	RETURN -120
END


--BEGIN TRAN

IF (@from_bin <= @to_bin)
BEGIN
	INSERT INTO tdc_phy_cyc_count
		(team_id, cyc_code, location, part_no, lot_ser, bin_no, cycle_date, range_type, range_start, range_end)
	SELECT DISTINCT @team_id, i.cycle_type, l.location, l.part_no, l.lot_ser, l.bin_no, getdate(), 'BIN', @range_start, @range_end
	  FROM lot_bin_stock l (nolock), inventory i (nolock), tdc_bin_master t (nolock)
	 WHERE l.location = @location
	   AND l.bin_no = t.bin_no
	   AND t.usage_type_code in ('OPEN', 'REPLENISH')
	   AND l.location = i.location
	   AND l.part_no = i.part_no
	   AND l.bin_no between @from_bin AND @to_bin				
END
ELSE 
BEGIN
	INSERT INTO tdc_phy_cyc_count
		(team_id, cyc_code, location, part_no, lot_ser, bin_no, cycle_date, range_type, range_start, range_end)
	SELECT DISTINCT @team_id, i.cycle_type, l.location, l.part_no, l.lot_ser, l.bin_no, getdate(), 'BIN', @range_start, @range_end
	  FROM lot_bin_stock l (nolock), inventory i (nolock), tdc_bin_master t (nolock)
	 WHERE l.location = @location
	   AND l.bin_no = t.bin_no
	   AND t.usage_type_code in ('OPEN', 'REPLENISH')
	   AND l.location = i.location
	   AND l.part_no = i.part_no
	   AND (l.bin_no >= @from_bin OR l.bin_no <= @to_bin)		
END

--COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_bin_count_sp] TO [public]
GO
