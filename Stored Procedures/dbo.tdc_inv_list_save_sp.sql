SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_inv_list_save_sp]
		@intUpdate              INTEGER    ,
		@strPart_No             VARCHAR(30) ,
		@strLocation            VARCHAR(10)  ,
		@dcmUnit_Height		DECIMAL(20,8) ,
		@dcmUnit_Length		DECIMAL(20,8) ,
		@dcmUnit_Width		DECIMAL(20,8) ,
		@intCase_Qty		INTEGER , 
		@intPack_Qty		INTEGER , 
		@intPallet_Qty		INTEGER , 
		@bitPCSNFlag		BIT ,
		@bitVersion_Capture	BIT ,
		@bitWarranty_Track	BIT ,
		@bitWO_Batch_Track	BIT ,
		@strVendor_SN		VARCHAR(1) = 'N' ,
		@strUPC_Code		VARCHAR(12) = '' ,
		@strMask_Code		VARCHAR(15) = 'NONE'

 AS
/* This SP will: 1.) update the upc_code in inv_master for a particular part_no
		 2.) update/insert a mask_code in tdc_inv_master for a particular part_no 
		 3.) insert/update tdc_inv_list for a particular part_no / location combination */

/* @strMask_Code is the mask_code for a particular part in tdc_inv_master */

/* The @strNewPart_No and @strNewLocation variables are used when performing an Insert so 
	 that the location, and part_no 's match exactly those 
	 values that are stored in the location and inv_master tables */
DECLARE		@strNewPart_No             	VARCHAR(30) ,
		@strNewLocation            	VARCHAR(10),
		@strNewMaskCode			VARCHAR(15),
		@strVendor_SN_Original		CHAR(1),
		@bitSerialNoTrack_Exists	BIT

DECLARE @language varchar(10), @msg varchar(255)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

/*
On the TDC Inventory Maintenance screen, if a user chooses to change from S/N Inbound Tracked 
  to S/N Outbound or  N/A  tracked then we need to check the tdc_serial_no_track table for entries. 
  If any exist for that Location, Part combination then we need to stop them and 
  provide a dialog box indicating these records exist and they must be cleared first.

*/
SELECT @strVendor_SN_Original = ISNULL(vendor_sn,'') FROM tdc_inv_list (NOLOCK)
	WHERE part_no = @strPart_No
	AND   location = @strLocation

SELECT @bitSerialNoTrack_Exists = COUNT(*) FROM tdc_serial_no_track (NOLOCK)
	WHERE part_no = @strPart_No
	AND   location = @strLocation	

SELECT @strNewMaskCode = mask_code FROM tdc_serial_no_mask (NOLOCK)
	WHERE mask_code = @strMask_Code

IF @intUpdate = 1
   BEGIN
	IF @bitSerialNoTrack_Exists = 1 AND @strVendor_SN_Original <> @strVendor_SN 
		BEGIN
			-- The specified part and location already exist in tdc_serial_no_track and need to be cleared first. 
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_inv_list_save_sp' AND err_no = -101 AND language = @language
			RAISERROR (@msg,16,1)
		END
	ELSE
		BEGIN
			UPDATE inv_master SET upc_code = @strUPC_Code WHERE part_no = @strPart_No

			IF (SELECT COUNT(*) FROM tdc_inv_master WHERE part_no = @strPart_No) = 0
				BEGIN
					INSERT INTO tdc_inv_master (part_no,mask_code)  VALUES (@strPart_No , @strNewMaskCode )
				END
			ELSE
			
				BEGIN
					UPDATE tdc_inv_master SET mask_code = @strNewMaskCode
						WHERE part_no = @strPart_No
				END


			UPDATE tdc_inv_list SET
 				unit_height		=	@dcmUnit_Height, 
				unit_length		=	@dcmUnit_Length, 
				unit_width		=	@dcmUnit_Width, 
    				case_qty		=	@intCase_Qty, 
				pack_qty		=	@intPack_Qty, 
				pallet_qty		=	@intPallet_Qty, 
				pcsn_flag		=	@bitPCSNFlag ,
				version_capture		= 	@bitVersion_Capture ,
				warranty_track		=	@bitWarranty_Track ,
				wo_batch_track		=	@bitWO_Batch_Track ,
				vendor_sn		=	@strVendor_SN
	   		WHERE part_no = @strPart_No
	   		AND location = @strLocation

			


		END
      	

	
   END

ELSE
   BEGIN
	DECLARE @intCounter	AS INTEGER
	
	SELECT @intCounter = COUNT(*) FROM tdc_inv_list (NOLOCK) 
		WHERE part_no = @strPart_No
		AND location  = @strLocation

	IF @intCounter = 0
		BEGIN
		
			SELECT @strNewPart_No = part_no FROM inv_master (NOLOCK)
				WHERE part_no = @strPart_No

			SELECT @strNewLocation = location FROM locations (NOLOCK)
				WHERE location = @strLocation

			UPDATE inv_master SET upc_code = @strUPC_Code WHERE part_no = @strPart_No

			IF (SELECT COUNT(*) FROM tdc_inv_master WHERE part_no = @strPart_No) = 0
				BEGIN
					INSERT INTO tdc_inv_master (part_no,mask_code) VALUES (@strPart_No , @strNewMaskCode )
				END
			ELSE
				BEGIN
					UPDATE tdc_inv_master SET mask_code = @strNewMaskCode
						WHERE part_no = @strPart_No
				END

      			INSERT INTO tdc_inv_list (
					part_no 	, 	location ,
					unit_height	,	unit_length ,
					unit_width	,	case_qty ,
					pack_qty	,	pallet_qty ,
					pcsn_flag	,	version_capture ,
					warranty_track	,	vendor_sn ,
					wo_batch_track)
						
				VALUES ( 
					@strNewPart_No	,	@strNewLocation ,
					@dcmUnit_Height	,	@dcmUnit_Length ,
					@dcmUnit_Width	,	@intCase_Qty ,	
					@intPack_Qty	,	@intPallet_Qty ,		
					@bitPCSNFlag 	,	@bitVersion_Capture ,
					@bitWarranty_Track,	@strVendor_SN ,
					@bitWO_Batch_Track)



		END
	ELSE
		BEGIN
			-- 'The specified part and location already exists in tdc_inv_list.'
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_inv_list_save_sp' AND err_no = -102 AND language = @language
			RAISERROR (@msg,16,1)
		END



   END



IF @@ERROR = 0 
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
		 ISNULL(tdc_inv_list.vendor_sn,'N') 	AS vendor_sn,
			tdc_inv_master.mask_code,	inv_master.upc_code ,
			tdc_inv_list.wo_batch_track , 	inv_master.allow_fractions ,
			inv_master.status
		  FROM 	tdc_inv_master (NOLOCK) RIGHT OUTER JOIN
    			inv_master (NOLOCK) ON 
    			tdc_inv_master.part_no = inv_master.part_no RIGHT OUTER JOIN
    			tdc_inv_list (NOLOCK) ON 
    			inv_master.part_no = tdc_inv_list.part_no
		   WHERE tdc_inv_list.part_no = @strPart_No 
		   AND location = @strLocation 	
	END


RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_inv_list_save_sp] TO [public]
GO
