SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_inv_list_sp] 

	@intDataControl_Navigation INTEGER , 
	@strPart_No                VARCHAR(30) ='' ,
	@strLocation 		   VARCHAR(10) = ''
AS

DECLARE
	@intDelete                        AS INTEGER ,
	@intRefresh                       AS INTEGER ,
	@intCancel                        AS INTEGER ,
	@intMove_First                    AS INTEGER ,
	@intMove_Previous                 AS INTEGER ,
	@intMove_Next                     AS INTEGER ,
	@intMove_Last                     AS INTEGER ,
	@strMaxPart_No 		          AS VARCHAR(30),
	@strMinPart_No 			  AS VARCHAR(30),
	@strMaxLocation 		  AS VARCHAR(10),
	@strMinLocation 		  AS VARCHAR(10),
	@bitIn_Inventory	  	  AS BIT


SELECT @intDelete                 = 6
SELECT @intRefresh                = 4
SELECT @intCancel                 = 7
SELECT @intMove_First             = 15
SELECT @intMove_Previous          = 16
SELECT @intMove_Next              = 17
SELECT @intMove_Last              = 18

IF  @intDataControl_Navigation  = @intDelete 
	BEGIN

		SELECT @bitIn_Inventory = (ISNULL(IO_count,0) % 2) FROM tdc_serial_no_track (NOLOCK)
			WHERE part_no = @strPart_No
			AND   location = @strLocation	


		IF @bitIn_Inventory = 1
			BEGIN
				RAISERROR ('The specified part and location already exist in tdc_serial_no_track and need to be cleared first. ',16,1)
			END
		ELSE --the IO_count will be even if the part is out of inventory
			BEGIN

				DELETE FROM tdc_inv_list  
					WHERE part_no = @strPart_No
					AND location = @strLocation

				SELECT TOP 1 
					tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    					tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    					tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    					tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    					tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    					inv_master.type_code	, 	inv_master.uom, 
					inv_master.rpt_uom	, 	inv_master.category , 	
					inv_master.cycle_type	, 	inv_master.vendor , 	
					inv_master.account	, 	inv_master.freight_class,
					tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
		 		ISNULL(tdc_inv_list.vendor_sn,'N')  	AS vendor_sn ,	
					tdc_inv_master.mask_code,	inv_master.upc_code ,
					tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
					inv_master.status
		  		FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    					inv_master (NOLOCK) ON 
    					tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    					tdc_inv_list (NOLOCK) ON 
    					inv_master.part_no = tdc_inv_list.part_no

			END
		

	END


ELSE IF @intDataControl_Navigation  = @intRefresh OR  @intDataControl_Navigation  = @intCancel
	BEGIN 
		SELECT  
			tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    			tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    			tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    			tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    			tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    			inv_master.type_code	, 	inv_master.uom, 
			inv_master.rpt_uom	, 	inv_master.category , 	
			inv_master.cycle_type	, 	inv_master.vendor ,	 	
			inv_master.account	, 	inv_master.freight_class,
			tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
		 ISNULL(tdc_inv_list.vendor_sn,'N') 	AS vendor_sn ,	
			tdc_inv_master.mask_code,	inv_master.upc_code ,
			tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
			inv_master.status
		  FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    			inv_master (NOLOCK) ON 
    			tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    			tdc_inv_list (NOLOCK) ON 
    			inv_master.part_no = tdc_inv_list.part_no
		   WHERE tdc_inv_list.part_no 	= @strPart_No
		   AND   tdc_inv_list.location 	= @strLocation
   			
	END  

ELSE IF @intDataControl_Navigation  = @intMove_First
	BEGIN 
		SELECT TOP 1 
			tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    			tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    			tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    			tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    			tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    			inv_master.type_code	, 	inv_master.uom, 
			inv_master.rpt_uom	, 	inv_master.category , 	
			inv_master.cycle_type	, 	inv_master.vendor , 	
			inv_master.account	, 	inv_master.freight_class,
			tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
		 ISNULL(tdc_inv_list.vendor_sn,'N') 	AS vendor_sn ,	
			tdc_inv_master.mask_code,	inv_master.upc_code ,
			tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
			inv_master.status
		 FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    			inv_master (NOLOCK) ON 
    			tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    			tdc_inv_list (NOLOCK) ON 
    			inv_master.part_no = tdc_inv_list.part_no
		   ORDER BY tdc_inv_list.part_no, location

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Previous
	BEGIN 
		
		--FIRST lets see if there is a lesser location for this same part_no
		SELECT @strMaxLocation = ISNULL(MAX(location), '') FROM tdc_inv_list (NOLOCK)
			WHERE location < @strLocation
			AND part_no = @strPart_No

		IF @strMaxLocation = '' --There isn't a lesser location for this part_no so let's move to previous part_no
			BEGIN
				SELECT @strMaxPart_No = ISNULL(MAX(part_no), '') FROM tdc_inv_list (NOLOCK)
					WHERE part_no < @strPart_No

				IF @strMaxPart_No = '' --WE were on the first part_no , location to begin with
					BEGIN
						SELECT  
							tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    							tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    							tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    							tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    							tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    							inv_master.type_code	, 	inv_master.uom, 
							inv_master.rpt_uom	, 	inv_master.category , 	
							inv_master.cycle_type	, 	inv_master.vendor , 	
							inv_master.account	, 	inv_master.freight_class,
							tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
						 ISNULL(tdc_inv_list.vendor_sn,'N')  	AS vendor_sn ,	
							tdc_inv_master.mask_code,	inv_master.upc_code ,
							tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
							inv_master.status
		  				FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    							inv_master (NOLOCK) ON 
    							tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    							tdc_inv_list (NOLOCK) ON 
    							inv_master.part_no = tdc_inv_list.part_no
						   WHERE tdc_inv_list.part_no = @strPart_No
						   AND   location = @strLocation
					END
				ELSE
					BEGIN
						
						SELECT @strMaxLocation = MAX(location) FROM tdc_inv_list (NOLOCK)
										WHERE part_no = @strMaxPart_No 

						SELECT  
							tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    							tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    							tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    							tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    							tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    							inv_master.type_code	, 	inv_master.uom, 
							inv_master.rpt_uom	, 	inv_master.category , 	
							inv_master.cycle_type	, 	inv_master.vendor , 	
							inv_master.account	, 	inv_master.freight_class,
							tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
						 ISNULL(tdc_inv_list.vendor_sn,'N')  	AS vendor_sn,	
							tdc_inv_master.mask_code,	inv_master.upc_code ,
							tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
							inv_master.status
						FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    							inv_master (NOLOCK) ON 
    							tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    							tdc_inv_list (NOLOCK) ON 
    							inv_master.part_no = tdc_inv_list.part_no
						   WHERE tdc_inv_list.part_no = @strMaxPart_No
						   AND location = @strMaxLocation
					END
				
					

			END

		ELSE
			BEGIN
				SELECT  
					tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    					tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    					tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    					tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    					tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    					inv_master.type_code	, 	inv_master.uom, 
					inv_master.rpt_uom	, 	inv_master.category , 	
					inv_master.cycle_type	, 	inv_master.vendor , 	
					inv_master.account	, 	inv_master.freight_class,
					tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
				  ISNULL(tdc_inv_list.vendor_sn,'N')  	AS vendor_sn,	
					tdc_inv_master.mask_code,	inv_master.upc_code ,
					tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
					inv_master.status
		  		FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    					inv_master (NOLOCK) ON 
    					tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    					tdc_inv_list (NOLOCK) ON 
    					inv_master.part_no = tdc_inv_list.part_no
				   WHERE tdc_inv_list.part_no = @strPart_No
				   AND   location = @strMaxLocation 	

			END
		

	END




ELSE IF @intDataControl_Navigation  = @intMove_Next
	BEGIN 
		 
		--FIRST lets see if there is a greater location for this same part_no 
		SELECT @strMinLocation = ISNULL(MIN(location), '') FROM tdc_inv_list (NOLOCK)
			WHERE location > @strLocation
			AND part_no = @strPart_No

		IF @strMinLocation = '' --There isn't a greater location for this part_no so let's move to next part_no
			BEGIN
				SELECT @strMinPart_No = ISNULL(MIN(part_no), '') FROM tdc_inv_list (NOLOCK)
					WHERE part_no > @strPart_No

				IF @strMinPart_No = '' --WE were on the last part_no , location to begin with
					BEGIN
						SELECT  
							tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    							tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    							tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    							tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    							tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    							inv_master.type_code	, 	inv_master.uom, 
							inv_master.rpt_uom	, 	inv_master.category , 	
							inv_master.cycle_type	, 	inv_master.vendor , 	
							inv_master.account	, 	inv_master.freight_class,
							tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
						 ISNULL(tdc_inv_list.vendor_sn,'N')  	AS vendor_sn,		
							tdc_inv_master.mask_code,	inv_master.upc_code ,
							tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
							inv_master.status
		  				FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    							inv_master (NOLOCK) ON 
    							tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    							tdc_inv_list (NOLOCK) ON 
    							inv_master.part_no = tdc_inv_list.part_no
						WHERE tdc_inv_list.part_no  = @strPart_No
						AND   tdc_inv_list.location = @strLocation
					END
				ELSE
					BEGIN
						SELECT @strMinLocation = MIN(location) FROM tdc_inv_list (NOLOCK)
							WHERE part_no = @strMinPart_No 

						SELECT  
							tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    							tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    							tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    							tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    							tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    							inv_master.type_code	, 	inv_master.uom, 
							inv_master.rpt_uom	, 	inv_master.category , 	
							inv_master.cycle_type	, 	inv_master.vendor , 	
							inv_master.account	, 	inv_master.freight_class,
							tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
						 ISNULL(tdc_inv_list.vendor_sn,'N')  	AS vendor_sn,	
							tdc_inv_master.mask_code,	inv_master.upc_code ,
							tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
							inv_master.status
		  				FROM tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    							inv_master (NOLOCK) ON 
    							tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    							tdc_inv_list (NOLOCK) ON 
    							inv_master.part_no = tdc_inv_list.part_no
						WHERE tdc_inv_list.part_no  = @strMinPart_No
						AND   tdc_inv_list.location = @strMinLocation

					END
				
					

			END

		ELSE
			BEGIN
				SELECT  
					tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    					tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    					tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    					tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    					tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    					inv_master.type_code	, 	inv_master.uom, 
					inv_master.rpt_uom	, 	inv_master.category , 	
					inv_master.cycle_type	, 	inv_master.vendor , 	
					inv_master.account	, 	inv_master.freight_class,
					tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
				 ISNULL(tdc_inv_list.vendor_sn,'N')  	AS vendor_sn,		
					tdc_inv_master.mask_code,	inv_master.upc_code ,
					tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
					inv_master.status
		  		FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    					inv_master (NOLOCK) ON 
   					tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    					tdc_inv_list (NOLOCK) ON 
    					inv_master.part_no = tdc_inv_list.part_no
				   WHERE tdc_inv_list.part_no   = @strPart_No
				   AND   tdc_inv_list.location  = @strMinLocation 	
			END



	END  

ELSE IF @intDataControl_Navigation  = @intMove_Last
	BEGIN 
		SELECT @strMaxPart_No = MAX(part_no) FROM tdc_inv_list (NOLOCK)
		SELECT @strMaxLocation = MAX(location) FROM tdc_inv_list (NOLOCK) WHERE part_no = @strMaxPart_No 

		SELECT  
			tdc_inv_list.part_no	, 	tdc_inv_list.location, 
    			tdc_inv_list.unit_height, 	tdc_inv_list.unit_length, 
    			tdc_inv_list.unit_width	, 	tdc_inv_list.case_qty, 
    			tdc_inv_list.pack_qty	, 	tdc_inv_list.pallet_qty, 
    			tdc_inv_list.pcsn_flag	, 	inv_master.[description], 
    			inv_master.type_code	, 	inv_master.uom, 
			inv_master.rpt_uom	, 	inv_master.category , 	
			inv_master.cycle_type	, 	inv_master.vendor , 	
			inv_master.account	, 	inv_master.freight_class,
			tdc_inv_list.version_capture,   tdc_inv_list.warranty_track, 
		 ISNULL(tdc_inv_list.vendor_sn,'N')	AS vendor_sn,		
			tdc_inv_master.mask_code,	inv_master.upc_code ,
			tdc_inv_list.wo_batch_track ,	inv_master.allow_fractions ,
			inv_master.status
		  FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    			inv_master (NOLOCK) ON 
    			tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    			tdc_inv_list (NOLOCK) ON 
    			inv_master.part_no = tdc_inv_list.part_no	
		   WHERE tdc_inv_list.location = @strMaxLocation
		   AND   tdc_inv_list.part_no  = @strMaxPart_No

	END  

 RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_inv_list_sp] TO [public]
GO
