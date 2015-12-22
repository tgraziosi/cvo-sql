SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[tdc_serialno_mask_sp]

	@intDataControl_Navigation  	INTEGER , 
	@strMask_Code               	VARCHAR(15) ='' ,
	@strMask_Data            	VARCHAR(50) ='' ,
	@intTab_Mode			INTEGER = 0 
 AS

/*We ONLY want to allow a user to DELETE a mask code if: 
			1.) the mask_code is NOT tied to a part in tdc_inv_master
			2.) the mask code DOES NOT exist in tdc_serial_no_track
			3.) the mask code is NOT the DEFAULT MASK CODE ('NONE')

  We ONLY want to allow a user to UPDATE a mask code if:
			1.)  the mask_code is NOT tied to a part in tdc_inv_master
			2.) the mask code DOES NOT exist in tdc_serial_no_track
*/

DECLARE
	@intSave		   AS INTEGER ,
	@intDelete                 AS INTEGER ,
	@intRefresh                AS INTEGER ,
	@intCancel                 AS INTEGER ,
	@intMove_First             AS INTEGER ,
	@intMove_Previous          AS INTEGER ,
	@intMove_Next              AS INTEGER ,
	@intMove_Last              AS INTEGER ,
	@intCounter		   AS INTEGER ,
	@intSerialTrack_Counter	   AS INTEGER ,
	@strMinMask_Code 	   AS VARCHAR(15),
	@strMaxMask_Code 	   AS VARCHAR(15),
	@intInsertMode		   AS INTEGER ,
	@intEditMode		   AS INTEGER ,
	@strDEFAULT_MASKCODE	   AS VARCHAR (15)

DECLARE @language varchar(10), @msg varchar(255)

SELECT @strDEFAULT_MASKCODE = 'NONE'
SELECT @intSave                	 = 2
SELECT @intDelete                = 6
SELECT @intRefresh               = 4
SELECT @intCancel                = 7
SELECT @intMove_First            = 15
SELECT @intMove_Previous         = 16
SELECT @intMove_Next             = 17
SELECT @intMove_Last             = 18

SELECT @intInsertMode            = 0
SELECT @intEditMode              = 1

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

IF  @intDataControl_Navigation  = @intDelete 
	BEGIN

		IF @strMask_Code = @strDEFAULT_MASKCODE
			BEGIN
				-- 'Cannot delete the Default Mask Code.'
				SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_serialno_mask_sp' AND err_no = -101 AND language = @language
				RAISERROR (@msg, 16, 1)				
			END	
		ELSE	
			BEGIN
				SELECT @intSerialTrack_Counter = COUNT(*) FROM tdc_serial_no_track (NOLOCK)
					WHERE  mask_code = @strMask_Code
				SELECT @intCounter = COUNT(*) FROM tdc_inv_master (NOLOCK) 
					WHERE  mask_code = @strMask_Code
	
				IF @intCounter = 0 AND @intSerialTrack_Counter = 0
					BEGIN
						DELETE FROM tdc_serial_no_mask  WHERE  mask_code = @strMask_Code

						SELECT TOP 1 *   FROM tdc_serial_no_mask (NOLOCK)
  			 				ORDER BY mask_code
					END
				ELSE
					BEGIN
						-- 'The specified mask code is in use and CANNOT be modified.'
						SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_serialno_mask_sp' AND err_no = -102 AND language = @language
						RAISERROR (@msg, 16, 1)
					END
			END
		

	END


ELSE IF @intDataControl_Navigation  = @intRefresh OR  @intDataControl_Navigation  = @intCancel
	BEGIN 
		SELECT TOP 1 * FROM tdc_serial_no_mask (NOLOCK)
			WHERE  mask_code = @strMask_Code


	END  

ELSE IF @intDataControl_Navigation  = @intMove_First
	BEGIN 

		SELECT TOP 1 *   FROM tdc_serial_no_mask (NOLOCK)
  			 ORDER BY mask_code ASC 


	END  

ELSE IF @intDataControl_Navigation  = @intMove_Previous
	BEGIN 
			
		--FIRST lets see if there is a lesser mask_code
		SELECT @strMaxMask_Code = ISNULL(MAX(mask_code),'')
			FROM tdc_serial_no_mask (NOLOCK)
			WHERE mask_code < @strMask_Code
			

		IF @strMaxMask_Code = '' --There ISN'T a lesser mask_code so just move first

			BEGIN
				SELECT TOP 1 *   FROM tdc_serial_no_mask (NOLOCK)
  			 		ORDER BY mask_code ASC 

			END

		ELSE  --There IS a lesser mask_code SO lets return it
			BEGIN
				SELECT * FROM tdc_serial_no_mask (NOLOCK)
					WHERE mask_code  = @strMaxMask_Code

			END


	END  

ELSE IF @intDataControl_Navigation  = @intMove_Next
	BEGIN 

			
		--FIRST lets see if there is a greater mask_code
		SELECT @strMinMask_Code = ISNULL(MIN(mask_code),'')
			FROM tdc_serial_no_mask (NOLOCK)
			WHERE mask_code > @strMask_Code
			

		IF @strMinMask_Code = '' --There ISN'T a greater mask_code so just bring back the last record

			BEGIN
				SELECT TOP 1 * FROM tdc_serial_no_mask (NOLOCK)
					ORDER BY mask_code DESC

			END

		ELSE  --There IS a mask_code SO return it

			BEGIN
				SELECT * FROM tdc_serial_no_mask (NOLOCK)
					WHERE  mask_code = @strMinMask_Code

			END



	END  


ELSE IF @intDataControl_Navigation  = @intMove_Last
	BEGIN 
		SELECT TOP 1 * FROM tdc_serial_no_mask (NOLOCK)
			ORDER BY mask_code DESC

	END  

ELSE IF @intDataControl_Navigation  = @intSave --Then we need to check what Mode the Tab is in
	BEGIN 

		IF @intTab_Mode = @intInsertMode
			BEGIN
				--Lets ensure this mask_code DOES NOT already exist
				SELECT @intCounter = COUNT(*) FROM tdc_serial_no_mask (NOLOCK) 
					WHERE  mask_code = @strMask_Code
				IF @intCounter = 0 
					BEGIN
						INSERT INTO tdc_serial_no_mask (mask_code, mask_data)
						VALUES (@strMask_Code, @strMask_Data)

						SELECT * FROM tdc_serial_no_mask WHERE mask_code = @strMask_Code			
					END

				ELSE
					BEGIN
						-- 'The specified mask code already exists.'
						SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_serialno_mask_sp' AND err_no = -103 AND language = @language
						RAISERROR (@msg, 16, 1)
					END

			END

		ELSE
			--DO NOT permit a user to update a mask code if:
			-- 1.) the mask code is tied to a part in tdc_inv_master 
			-- 2.) the mask code exists in tdc_serial_no_track
			BEGIN
				SELECT @intCounter = COUNT(*) FROM tdc_inv_master (NOLOCK) 
					WHERE  mask_code = @strMask_Code

				SELECT @intSerialTrack_Counter = COUNT(*) FROM tdc_serial_no_track (NOLOCK)
					WHERE  mask_code = @strMask_Code

				IF @intSerialTrack_Counter = 0 AND @intCounter = 0
					BEGIN
						UPDATE tdc_serial_no_mask SET mask_data = @strMask_Data
							WHERE mask_code = @strMask_Code

						SELECT * FROM tdc_serial_no_mask (NOLOCK)WHERE mask_code = @strMask_Code
							END
				ELSE
					BEGIN
						-- 'The specified mask code is in use and CANNOT be modified.'
						SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_serialno_mask_sp' AND err_no = -102 AND language = @language
						RAISERROR (@msg, 16, 1)
					END

			END

	END  





 RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_serialno_mask_sp] TO [public]
GO
