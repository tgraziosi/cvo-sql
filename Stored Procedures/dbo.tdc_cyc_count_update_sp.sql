SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_cyc_count_update_sp]
	@user_id   varchar(50)
AS

DECLARE @product_line  	varchar(30),
	@exp_months	int,
	@err		int,
	@date_expires	datetime

SELECT @err = 0

BEGIN TRANSACTION

-- Check what project (DCS or WMS) we are running.
SELECT @product_line = (SELECT product FROM tdc_installation_info_tbl (NOLOCK) WHERE product IS NOT NULL)

IF @product_line NOT IN ('DCS', 'WMS')
BEGIN	
	RAISERROR ('Product version conflict in stored procedure: tdc_cyc_count_update_sp', 16, 1)
	RETURN -1
END

-- Get date expires in case we need to Adhoc Adjust some items that don't exist in lot_bin_stock.
-- Default - current date + 12 months
SELECT @date_expires = CONVERT(varchar(30), DATEADD(month, CAST((ISNULL( (SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'exp_date' AND active = 'Y'), 12)) AS int), getdate()), 101)

----------------------------------------------------------------------------------------------------------
--													--
--	Store all the records (combinations of location-part-lot-bin) that have allocations.		--
--													--
----------------------------------------------------------------------------------------------------------
TRUNCATE TABLE #cyc_count_allocated_parts

INSERT INTO #cyc_count_allocated_parts (location, part_no, lot_ser, bin_no, order_no, order_ext, order_type)
SELECT a.location, a.part_no, a.lot_ser, a.bin_no, a.order_no, a.order_ext, a.order_type
  FROM tdc_soft_alloc_tbl a (NOLOCK), 
       #tdc_cyc_master    b (NOLOCK)
 WHERE b.post_ver <> 0
   AND a.location = b.location
   AND a.part_no  = b.part_no
   AND ISNULL(a.lot_ser, '') = ISNULL(b.lot_ser, '')
   AND ISNULL(a.bin_no,  '') = ISNULL(b.bin_no,  '')
   AND b.post_qty < (SELECT SUM(c.qty) 
		       FROM tdc_soft_alloc_tbl c (NOLOCK) 
		      WHERE c.location = b.location
   			AND c.part_no  = b.part_no
   			AND ISNULL(c.lot_ser, '') = ISNULL(b.lot_ser, '')
   			AND ISNULL(c.bin_no,  '') = ISNULL(b.bin_no,  '')
		    )
 ORDER BY a.location, a.part_no, a.order_no, a.order_ext, a.order_type,  a.lot_ser, a.bin_no
-----------------------------------------------------------------------------------------------------------

IF @product_line = 'WMS'
BEGIN
	-- 1. Remove all the records that have allocations
	DELETE FROM #tdc_cyc_SN                
	 WHERE location + part_no + lot_ser IN (SELECT location + part_no + lot_ser FROM #cyc_count_allocated_parts)

	-- 2. if the quantity of I/O part is increased, I/O count is even, need to update IO_count into tdc_serial_no_track
	UPDATE tdc_serial_no_track                   
	   SET io_count       = io_count + 1,              
	       last_trans     = 'CYCCNT',                
	       serial_no_raw  = s.serial_no_raw,      
	       date_time      = getdate()                 
	  FROM tdc_serial_no_track t, 
               #tdc_cyc_SN         s
	 WHERE s.part_no      = t.part_no                 
	   AND s.lot_ser      = t.lot_ser                 
	   AND s.serial_no    = t.serial_no 
	   AND t.io_count % 2 = 0         
	   AND s.direction    = 1   

	IF (@@ERROR <> 0)
	BEGIN
		RAISERROR ('Update tdc_serial_no_track failed.', 16, 1)
		RETURN -1
	END

	-- 3.	
	DELETE FROM #tdc_cyc_SN FROM tdc_serial_no_track             
	 WHERE tdc_serial_no_track.part_no      = #tdc_cyc_SN.part_no   
	   AND tdc_serial_no_track.lot_ser      = #tdc_cyc_SN.lot_ser   
	   AND tdc_serial_no_track.serial_no    = #tdc_cyc_SN.serial_no 
	   AND tdc_serial_no_track.io_count % 2 = 1                  
	   AND #tdc_cyc_SN.direction            = 1                  

	IF (@@ERROR <> 0)
	BEGIN
		RAISERROR ('Delete from #tdc_cyc_SN failed.', 16, 1)
		RETURN -1
	END

	 -- 4. if the quantity of I/O part is increased, and it's a new part/lot/SN, need to insert into tdc_serial_no_track
	INSERT INTO tdc_serial_no_track(location, transfer_location, part_no, lot_ser, mask_code, 
	            serial_no, serial_no_raw, IO_count, init_control_type, init_trans, init_tx_control_no, 
	            last_control_type, last_trans, last_tx_control_no, date_time, [User_id], Arbc_No) 
	SELECT DISTINCT t.location, t.location, t.part_no, t.lot_ser, m.mask_code, t.serial_no, t.serial_no_raw, 
			1, '0', 'CYCCNT', 0, '0', 'CYCCNT', 0, getdate(), @user_id, NULL                       
          FROM #tdc_cyc_SN t, tdc_inv_master m, tdc_phy_cyc_count p    
    	 WHERE p.post_ver != 0                                         
      	   AND t.part_no   = p.part_no                                   
           AND t.lot_ser   = p.lot_ser                                   
      	   AND t.direction = 1                                         
      	   AND p.part_no   = m.part_no                        
      	   AND t.location  = p.location                                 

	IF (@@ERROR <> 0)
	BEGIN
		RAISERROR ('Insert into tdc_serial_no_track failed.', 16, 1)
		RETURN -1
	END

	-- 5. if the quantity of I/O part is decreased, need to change IO_count in tdc_serial_no_track
	UPDATE tdc_serial_no_track                             
	   SET IO_count   = IO_count + 1, 
	       last_trans = 'CYCCNT',           
	       date_time  = getdate()                                     
	  FROM #tdc_cyc_SN t, tdc_phy_cyc_count c, tdc_serial_no_track s 
	 WHERE t.part_no       = c.part_no                               
	   AND t.lot_ser       = c.lot_ser    
	   AND t.direction     = -1                               
	   AND t.location      = c.location                              
	   AND c.post_ver     != 0                                      
	   AND t.part_no       = s.part_no                               
	   AND t.lot_ser       = s.lot_ser                               
	   AND t.serial_no_raw = s.serial_no_raw                         
	   AND s.io_count % 2   = 1

	IF (@@ERROR <> 0)
	BEGIN
		RAISERROR ('Update tdc_serial_no_track failed.', 16, 1)
		RETURN -1
	END

END

--2. UPDATE Cycle Date in inv_list
UPDATE inv_list 
   SET cycle_date = getdate()   
  FROM inv_list a, tdc_phy_cyc_count b      
 WHERE b.post_ver      != 0      
   AND b.adm_actual_qty = b.post_qty
   AND a.location       = b.location
   AND a.part_no        = b.part_no                     
   AND b.location + b.part_no + ISNULL(b.lot_ser,'') NOT IN 
	(SELECT location + part_no + ISNULL(lot_ser,'') FROM #cyc_count_allocated_parts)	
	
IF (@@ERROR <> 0)
BEGIN
	RAISERROR ('Update Cycle Date in inv_list failed.', 16, 1)
	RETURN -1
END

--3. Insert into tdc_cyc_count_log	
INSERT INTO tdc_cyc_count_log  (team_id,userid,cyc_code,location,part_no,lot_ser,bin_no,child_serial_no,
		adm_actual_qty,tdc_actual_qty,count_qty,count_date,cycle_date,post_qty,post_pcs_qty,post_ver,
		post_pcs_ver,update_user,update_date)
SELECT team_id,userid,cyc_code,location,part_no,lot_ser,bin_no,child_serial_no, 
       adm_actual_qty,tdc_actual_qty,count_qty,count_date,cycle_date,post_qty, 
       post_pcs_qty, post_ver, post_pcs_ver,
       update_user = @user_id,
       update_date = getdate()  
  FROM tdc_phy_cyc_count                
 WHERE post_ver      != 0
   AND adm_actual_qty = post_qty 
   AND location + part_no + ISNULL(lot_ser,'') NOT IN 
	(SELECT location + part_no + ISNULL(lot_ser,'') FROM #cyc_count_allocated_parts)	
	
IF (@@ERROR <> 0)
BEGIN
	RAISERROR ('Insert into tdc_cyc_count_log failed.', 16, 1)
	RETURN -1
END

-- 4. Delete from tdc_phy_cyc_count
DELETE FROM tdc_phy_cyc_count 
 WHERE post_ver      != 0
   AND adm_actual_qty = post_qty 
   AND location + part_no + ISNULL(lot_ser,'') NOT IN 
	(SELECT location + part_no + ISNULL(lot_ser,'') FROM #cyc_count_allocated_parts)	
	
IF (@@ERROR <> 0)
BEGIN
	RAISERROR ('Delete from tdc_phy_cyc_count failed.', 16, 1)
	RETURN -1
END

-- 5. Insert into #adm_inv_adj
TRUNCATE TABLE #adm_inv_adj

-- Insert Lot/Bin Items
INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, 
			  direction, who_entered, reason_code, code) 		
SELECT DISTINCT pcc.location, pcc.part_no, pcc.bin_no, pcc.lot_ser,  
       		lbs.date_expires, ABS(pcc.adm_actual_qty - pcc.post_qty),                    
		CASE  
			WHEN (pcc.adm_actual_qty - pcc.post_qty) > 0
			THEN -1  
			WHEN (pcc.adm_actual_qty - pcc.post_qty) < 0
			THEN 1 
		END, @user_id, 'CYCLE CNT', 'CYC'
 FROM tdc_phy_cyc_count pcc, lot_bin_stock lbs
WHERE pcc.post_ver != 0
  AND pcc.adm_actual_qty <> pcc.post_qty
  AND pcc.location = lbs.location
  AND pcc.part_no  = lbs.part_no
  AND pcc.lot_ser  = lbs.lot_ser
  AND pcc.bin_no   = lbs.bin_no
  AND pcc.location + pcc.part_no + ISNULL(pcc.lot_ser,'') NOT IN 
	(SELECT location + part_no + ISNULL(lot_ser,'') FROM #cyc_count_allocated_parts)	

-- Insert Lot/Bin Items that don't exist in lot_bin_stock
INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, direction, who_entered, reason_code, code) 		
SELECT DISTINCT location, part_no, bin_no, lot_ser, @date_expires, post_qty, 1, @user_id, 'CYCLE CNT', 'CYC'
  FROM tdc_phy_cyc_count
 WHERE post_ver != 0
   AND adm_actual_qty <> post_qty
   AND ISNULL(adm_actual_qty, 0) = 0
   AND location + part_no + ISNULL(lot_ser,'') NOT IN 
	(SELECT location + part_no + ISNULL(lot_ser,'') FROM #cyc_count_allocated_parts)	

-- Insert Non Lot/Bin Items
INSERT INTO #adm_inv_adj (loc, part_no, bin_no, lot_ser, date_exp, qty, 
		  	   direction, who_entered, reason_code, code) 		
SELECT DISTINCT pcc.location, pcc.part_no, NULL, NULL, NULL,
                ABS(pcc.adm_actual_qty - pcc.post_qty),                    
	        CASE  
			WHEN (pcc.adm_actual_qty - pcc.post_qty) > 0
			THEN -1  
			WHEN (pcc.adm_actual_qty - pcc.post_qty) < 0
			THEN 1 
		END, @user_id, 'CYCLE CNT', 'CYC'
  FROM tdc_phy_cyc_count pcc, inventory inv
 WHERE pcc.post_ver != 0
   AND pcc.adm_actual_qty <> pcc.post_qty 
   AND pcc.location = inv.location
   AND pcc.part_no  = inv.part_no
   AND inv.lb_tracking = 'N'
   AND pcc.location + pcc.part_no + ISNULL(pcc.lot_ser,'') NOT IN 
	(SELECT location + part_no + ISNULL(lot_ser,'') FROM #cyc_count_allocated_parts)	
	
IF (@@ERROR <> 0)
BEGIN
	RAISERROR ('Insert into #adm_inv_adj failed.', 16, 1)
	RETURN -1
END

IF EXISTS (SELECT * FROM #adm_inv_adj WHERE qty IS NOT NULL AND qty <> 0)
BEGIN
	-- 6. Execute adm_inv_adj stored procedure
	EXEC @err = tdc_adm_inv_adj
	
	-- 7. An error occur
	IF (@err < 0)
	BEGIN
		RAISERROR ('adm_inv_adj stored procedure failed.', 16, 1)
		RETURN -1
	END
END
-- 8. Insert into tdc_cyc_count_log
INSERT INTO tdc_cyc_count_log(team_id,userid,cyc_code,location,part_no,lot_ser,bin_no,child_serial_no,
		adm_actual_qty,tdc_actual_qty,count_qty,count_date,cycle_date,post_qty,post_pcs_qty,post_ver,
		post_pcs_ver,update_user,update_date)
SELECT team_id,userid,cyc_code,location, part_no, lot_ser, bin_no, child_serial_no, 
       adm_actual_qty, tdc_actual_qty, count_qty, count_date, cycle_date, post_qty, 
       post_pcs_qty, post_ver, post_pcs_ver, 
       update_user = @user_id,
       update_date = getdate()
  FROM tdc_phy_cyc_count
 WHERE post_ver != 0
   AND location + part_no + ISNULL(lot_ser,'') NOT IN 
	(SELECT location + part_no + ISNULL(lot_ser,'') FROM #cyc_count_allocated_parts)	
	
IF (@@ERROR <> 0)
BEGIN
	RAISERROR ('Insert into tdc_cyc_count_log failed.', 16, 1)
	RETURN -1
END
        
-- 9. Delete Records that have been updated
DELETE FROM tdc_phy_cyc_count 
 WHERE post_ver != 0 
   AND location + part_no + ISNULL(lot_ser,'') NOT IN 
	(SELECT location + part_no + ISNULL(lot_ser,'') FROM #cyc_count_allocated_parts)	
	
IF (@@ERROR <> 0)
BEGIN
	RAISERROR ('Delete records, that have been updated, from tdc_phy_cyc_count failed.', 16, 1)
	RETURN -1
END

COMMIT TRAN
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_cyc_count_update_sp] TO [public]
GO
