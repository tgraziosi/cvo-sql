SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_ins_count_sp]	
		@err_msg varchar(255) OUTPUT, 
		@team_id varchar(30),
		@cyc_code varchar(10),
		@location varchar(10)
AS

DECLARE @cyc_days int, @num_items int, @item_count int, @flag int
DECLARE @language varchar(10), @temp_part varchar(30), @lb_tracking char(1)
DECLARE @cycle datetime
	
SELECT @err_msg = 'OK'
SELECT @flag = 0

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

/* make sure that the cycle code passed is valid */
 
IF NOT EXISTS (SELECT * FROM cycle_types (nolock) WHERE kys = @cyc_code)
BEGIN
	--Invalid cycle code: 
	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE module = 'SPR' AND trans = 'tdc_ins_count_sp' AND err_no = -105 AND language = @language

	SELECT @err_msg = @err_msg + @cyc_code
	RETURN(-105)
END

/* make sure that the location code passed is valid */
 
IF NOT EXISTS (SELECT * FROM locations (nolock) WHERE location = @location AND void = 'N')
BEGIN
	--Invalid location:
	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE module = 'SPR' AND trans = 'tdc_ins_count_sp' AND err_no = -110 AND language = @language

	SELECT @err_msg = @err_msg + @location
	RETURN(-110)
END

SELECT @cyc_days = cycle_days, @num_items = num_items 
  FROM cycle_types (nolock) 
 WHERE kys = @cyc_code

/******************************************/
/* IA 01/20/00	 			  */
/* Check is any of records already exists */
/* in tdc_phy_cyc_count table 	          */
/******************************************/

SELECT @flag = count(*) 
  FROM inventory i (nolock), tdc_phy_cyc_count c (nolock)
 WHERE i.location = @location 
   AND i.location   = c.location
   AND i.cycle_type = @cyc_code
   AND i.cycle_type = c.cyc_code
   AND i.part_no    = c.part_no
   AND c.team_id    = @team_id
   AND i.status not in ('R', 'C', 'V')
   AND i.void <> 'V'		-- added IA 08/07/2000. Exclude Voided Items

IF (@flag > 0)
BEGIN
	-- 'Some Items in Requested Range are already in Process'
	SELECT @err_msg = err_msg 
	  FROM tdc_lookup_error (nolock) 
	 WHERE module = 'SPR' AND trans = 'tdc_ins_count_sp' AND err_no = -120 AND language = @language

	RETURN(-120)
END


/* When @item_count = @num_items the maximum number of */
/* item to count for this @cyc_code has been reached.  */
SELECT @item_count = 0

BEGIN TRAN

DECLARE Item_cursor CURSOR FOR
	SELECT a.part_no, a.lb_tracking, a.cycle_date
	  FROM inventory a (nolock), inv_master b (nolock)
	 WHERE a.location = @location
	   AND a.part_no = b.part_no
	   AND a.cycle_type = @cyc_code
	   AND a.status NOT IN ('R', 'C', 'V')
	   AND a.in_stock > 0	-- don't include these items. users can add it when counting
	   AND ( CASE WHEN a.cycle_date IS NOT NULL THEN DATEDIFF(day, a.cycle_date, getdate()) 
		      ELSE DATEDIFF(day, b.entered_date, getdate()) END ) > @cyc_days
	ORDER BY a.cycle_date
FOR READ ONLY

OPEN Item_cursor
FETCH NEXT FROM Item_cursor INTO @temp_part, @lb_tracking, @cycle

WHILE ((@@FETCH_STATUS = 0) AND (@item_count < @num_items))
BEGIN
	IF (@lb_tracking = 'Y')
	BEGIN
	-- insert all lot_bin_tracked parts that are scheduled for counting
		INSERT INTO tdc_phy_cyc_count
			(team_id, cyc_code, location, part_no, lot_ser, bin_no, cycle_date, range_type)
		SELECT DISTINCT @team_id, @cyc_code, @location, @temp_part, b.lot_ser, b.bin_no, getdate(), 'CODE'
		  FROM lot_bin_stock b (nolock) 
		  JOIN tdc_bin_master c (nolock) ON c.location = b.location  AND c.bin_no = b.bin_no
		 WHERE 1=1
		   AND b.location = @location
		   AND b.part_no = @temp_part
		   AND c.usage_type_code in ('OPEN', 'REPLENISH')
		   -- AND C.group_code NOT IN ( 'RESERVE' )
	END
	ELSE
	BEGIN
		INSERT INTO tdc_phy_cyc_count
			(team_id, cyc_code, location, part_no, cycle_date, range_type)
		VALUES(@team_id, @cyc_code, @location, @temp_part, getdate(), 'CODE')		
	END	
	
	SELECT @item_count = @item_count + 1
	FETCH NEXT FROM Item_cursor INTO @temp_part, @lb_tracking, @cycle
END			

DEALLOCATE Item_cursor

COMMIT TRAN

RETURN(0)



GO
GRANT EXECUTE ON  [dbo].[tdc_ins_count_sp] TO [public]
GO
