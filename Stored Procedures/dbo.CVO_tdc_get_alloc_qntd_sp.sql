SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].CVO_tdc_get_alloc_qntd_sp    Script Date: 08/09/2010  *****
SED009 -- AutoAllocation    
Object:      Procedure CVO_tdc_get_alloc_qntd_sp  
Source file: CVO_tdc_get_alloc_qntd_sp.sql
Author:		 Craig Boston
Created:	 12/08/2010
Function:    Return the stock qty by bin group
Modified:    
Calls:    
Called by:   WMS74 -- Allocation Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
exec CVO_tdc_get_alloc_qntd_sp '001','BC900PIN5218','HIGHBAY'
*/
-- v1.1 CB 25/09/2012 Need to include MGTB2B records for the moving of custom frames
-- v1.2 CB 03/10/2016 - #1606 - Direct Putaway & Fast Track Cart

CREATE PROCEDURE  [dbo].[CVO_tdc_get_alloc_qntd_sp]  @location VARCHAR(10), @part_no VARCHAR(30), @bin_group VARCHAR(30), @fasttrack int = 0 -- v1.2
AS
BEGIN
  
	DECLARE @apptype varchar(10),
			@custom_bin varchar(20) -- v1.1

	--EXEC tdc_get_version_sp @apptype OUTPUT
	SELECT	@custom_bin = value_str FROM tdc_config (NOLOCK) WHERE [function] = 'CVO_CUSTOM_BIN' -- v1.1

	SET @apptype = 'WMS'
  
	IF (@location = '%')  
	BEGIN  
   
		-- Called from the eBO inventory screen this should return list for all locations  
		IF EXISTS (SELECT * FROM inv_master (NOLOCK) WHERE lb_tracking = 'Y' AND part_no = @part_no)  
		BEGIN  
			-- Lot bin tracked part  
			SELECT	b.location, 
					@part_no AS part_no,  
					ISNULL(( SELECT sum(qty)   
			FROM	tdc_soft_alloc_tbl a (nolock)  
			WHERE	a.location = b.location  
			AND		a.part_no  = @part_no  
-- v1.1     AND		order_no > 0
			AND		(order_no <> 0 OR (order_no = 0 AND dest_bin = @custom_bin)) -- v1.1
			AND		a.bin_no in (SELECT bin_no FROM tdc_bin_master (NOLOCK)  
									WHERE usage_type_code IN ('OPEN','REPLENISH') AND group_code = @bin_group AND location = b.location)), 0)  
					+ ISNULL(( SELECT sum(qty) FROM lot_bin_stock s (nolock)  
								WHERE s.location = b.location  
								AND s.part_no = @part_no  
								AND s.bin_no in (SELECT bin_no FROM tdc_bin_master (NOLOCK)  
												WHERE usage_type_code = 'PRODIN'   AND group_code = @bin_group
													AND location = b.location)), 0) AS allocated_amt,  
					ISNULL( (SELECT sum(qty) FROM lot_bin_stock lbs (nolock)  
								WHERE lbs.location = b.location  
								AND lbs.part_no  = @part_no  
								AND bin_no IN (SELECT bin_no FROM tdc_bin_master tbm (nolock)  
												WHERE usage_type_code = 'QUARANTINE'  AND group_code = @bin_group 
												AND tbm.location = lbs.location)), 0) AS quarantine_amt, 
					@apptype AS apptype  
			FROM	locations b (nolock)  
		END  
		ELSE  
		BEGIN  
			-- Non lot bin tracked part  
			SELECT	location, part_no, allocated_amt = sum(qty), quarantined_amt = 0, @apptype AS apptype  
			FROM	tdc_soft_alloc_tbl (nolock)  
			WHERE	part_no = @part_no  
			AND		order_no <> 0  
			GROUP BY location, part_no  
		END  
	END  
	ELSE  
	BEGIN  
		-- Called from eBO screen that requires information on one particular location  
		IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE location = @location AND part_no = @part_no 
					AND (order_no <> 0 OR (order_no = 0 AND dest_bin = @custom_bin))) -- v1.1 
		BEGIN  
			-- Some inventory is allocated 
			-- v1.2 Start
			IF (@fasttrack = 0)
			BEGIN 
				SELECT	location, part_no,   
						allocated_amt = sum(qty) + ISNULL((SELECT sum(qty)    
															FROM lot_bin_stock (nolock)  
															WHERE location = @location  
															AND part_no = @part_no  
															AND bin_no in (SELECT bin_no   
																			FROM tdc_bin_master (NOLOCK)  
																			WHERE usage_type_code = 'PRODIN'  
																			AND group_code = @bin_group
																			AND location = @location)), 0),   
						quarantined_amt = ISNULL((SELECT sum(qty) FROM lot_bin_stock (nolock)  
													WHERE location = @location  
													AND part_no = @part_no  
													AND bin_no in (SELECT bin_no   
																	FROM tdc_bin_master (nolock)  
																	WHERE usage_type_code = 'QUARANTINE'   AND group_code = @bin_group
																	AND location = @location)), 0), 
						@apptype AS apptype  
				FROM	tdc_soft_alloc_tbl (nolock)  
				WHERE	location = @location   
				AND		part_no = @part_no  
	-- v1.1		AND		order_no <> 0
				AND		(order_no <> 0 OR (order_no = 0 AND dest_bin = @custom_bin)) -- v1.1	
				AND		bin_no in (SELECT bin_no FROM tdc_bin_master (NOLOCK)  
									WHERE usage_type_code IN ('OPEN','REPLENISH') AND group_code = @bin_group
									AND location = @location AND LEFT(bin_no,4) <> 'ZZZ-') 
				GROUP BY location, part_no  
			END
			ELSE
			BEGIN
				SELECT	location, part_no,   
						allocated_amt = sum(qty) + ISNULL((SELECT sum(qty)    
															FROM lot_bin_stock (nolock)  
															WHERE location = @location  
															AND part_no = @part_no  
															AND bin_no in (SELECT bin_no   
																			FROM tdc_bin_master (NOLOCK)  
																			WHERE usage_type_code = 'PRODIN'  
																			AND group_code = @bin_group
																			AND location = @location)), 0),   
						quarantined_amt = ISNULL((SELECT sum(qty) FROM lot_bin_stock (nolock)  
													WHERE location = @location  
													AND part_no = @part_no  
													AND bin_no in (SELECT bin_no   
																	FROM tdc_bin_master (nolock)  
																	WHERE usage_type_code = 'QUARANTINE'   AND group_code = @bin_group
																	AND location = @location)), 0), 
						@apptype AS apptype  
				FROM	tdc_soft_alloc_tbl (nolock)  
				WHERE	location = @location   
				AND		part_no = @part_no  
	-- v1.1		AND		order_no <> 0
				AND		(order_no <> 0 OR (order_no = 0 AND dest_bin = @custom_bin)) -- v1.1	
				AND		bin_no in (SELECT bin_no FROM tdc_bin_master (NOLOCK)  
									WHERE usage_type_code IN ('OPEN','REPLENISH') AND group_code = @bin_group
									AND location = @location AND LEFT(bin_no,4) = 'ZZZ-') 
				GROUP BY location, part_no  
			END
			-- v1.2 End
		END  
		ELSE  
		BEGIN  
			-- No inventory is allocated  
			SELECT	@location, 
					@part_no, 
					allocated_amt = 0,  
					quarantined_amt = ISNULL((SELECT sum(qty)    
												FROM lot_bin_stock  (NOLOCK) 
												WHERE location = @location 
												AND part_no = @part_no 
												AND bin_no in (SELECT bin_no   
																FROM tdc_bin_master  (NOLOCK) 
																WHERE usage_type_code = 'QUARANTINE'   AND group_code = @bin_group
																AND location = @location)), 0), 
					@apptype AS apptype  
		END  
	END  
END
GO
GRANT EXECUTE ON  [dbo].[CVO_tdc_get_alloc_qntd_sp] TO [public]
GO
