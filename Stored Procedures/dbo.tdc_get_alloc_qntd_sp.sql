SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_get_alloc_qntd_sp]
	@location varchar(10),
	@part_no  varchar(30)
AS

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
		SELECT b.location, @part_no AS part_no,
			ISNULL(( SELECT sum(qty) 
				   FROM tdc_soft_alloc_tbl a (nolock)
				  WHERE a.location = b.location
				    AND a.part_no  = @part_no
-- v1.1			    AND order_no > 0), 0)
				    AND (order_no <> 0 OR (order_no = 0 AND dest_bin = @custom_bin))), 0) -- v1.1
			+
 			ISNULL(( SELECT sum(qty)  
				   FROM lot_bin_stock s (nolock)
				  WHERE s.location = b.location
				    AND s.part_no = @part_no
				    AND s.bin_no in (SELECT bin_no 
	                                    	       FROM tdc_bin_master (NOLOCK) -- v1.2
				            	      WHERE usage_type_code = 'PRODIN' 
							AND location = b.location)), 0) AS allocated_amt,
			ISNULL( (SELECT sum(qty)
				   FROM	lot_bin_stock lbs (nolock)
				  WHERE lbs.location = b.location
				    AND lbs.part_no  = @part_no
				    AND bin_no IN (SELECT bin_no 
					  	     FROM tdc_bin_master tbm (nolock)
						    WHERE usage_type_code = 'QUARANTINE' 
						      AND tbm.location = lbs.location)), 0) AS quarantine_amt, @apptype AS apptype
		  FROM locations b (nolock)
	END
	ELSE
	BEGIN
		-- Non lot bin tracked part
		SELECT location, part_no, allocated_amt = sum(qty), quarantined_amt = 0, @apptype AS apptype
		  FROM tdc_soft_alloc_tbl (nolock)
		 WHERE part_no = @part_no
		   AND order_no <> 0
		GROUP BY location, part_no
	END
END
ELSE
BEGIN
	-- Called from eBO screen that requires information on one particular location
	IF EXISTS (SELECT * FROM tdc_soft_alloc_tbl (nolock) WHERE location = @location AND part_no = @part_no 
			AND (order_no <> 0 OR (order_no = 0 AND dest_bin = @custom_bin) OR (order_no = 0 AND bin_no = @custom_bin))) -- v1.1 v1.3
	BEGIN
		-- Some inventory is allocated
		SELECT	location, part_no, 
			allocated_amt = sum(qty) + ISNULL((SELECT sum(qty)  
							     FROM lot_bin_stock (nolock)
							    WHERE location = @location
							      AND part_no = @part_no
							      AND bin_no in (SELECT bin_no 
				                                    	       FROM tdc_bin_master (NOLOCK)  -- v1.2
	                        			            	      WHERE usage_type_code = 'PRODIN' 
										AND location = @location)), 0), 
			quarantined_amt = ISNULL((SELECT sum(qty)  
						    FROM lot_bin_stock (nolock)
						   WHERE location = @location
						     AND part_no = @part_no
						     AND bin_no in (SELECT bin_no 
			                                    	      FROM tdc_bin_master (nolock)
                        			            	     WHERE usage_type_code = 'QUARANTINE' 
								       AND location = @location)), 0), @apptype AS apptype
		  FROM tdc_soft_alloc_tbl (nolock)
		 WHERE location = @location 
		   AND part_no = @part_no
-- v1.1	   AND order_no <> 0
		   AND (order_no <> 0 OR (order_no = 0 AND dest_bin = @custom_bin) OR (order_no = 0 AND bin_no = @custom_bin)) -- v1.1 v1.3
		GROUP BY location, part_no
	END
	ELSE
	BEGIN
		-- No inventory is allocated
		SELECT	@location, @part_no, allocated_amt = 0,
			quarantined_amt = ISNULL((SELECT sum(qty)  
						   FROM	lot_bin_stock (NOLOCK) -- v1.4
						  WHERE	location = @location AND
							part_no = @part_no AND
							bin_no in (SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK)  -- v1.2
								    WHERE usage_type_code = 'QUARANTINE' 
								      AND location = @location)), 0), @apptype AS apptype
	END
END

GO
GRANT EXECUTE ON  [dbo].[tdc_get_alloc_qntd_sp] TO [public]
GO
