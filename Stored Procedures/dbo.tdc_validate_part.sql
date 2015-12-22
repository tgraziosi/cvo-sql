SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        					  */
/* TDC SFDC/WMS Pack-Out Part Verification - This sp will take as */
/* input the scanned part number and check to see if it is valid. */
/* If so, then the corresponding part number will be returned.    */
/*								  */
/* 	Rules:							  */
/*	 1)	The ADM Part Number (inv_master.part_no)	  */
/* 	 2)	The Item's UPC number.  (inv_master.upc_code)     */
/*	 3)	The Xref Part#: (cust_xref.cust_part for part_no and customer_key */
/*								  */
/* 04/14/1998	Initial		CAC				  */
/*								  */

CREATE PROCEDURE [dbo].[tdc_validate_part] (
  @in_cust_code varchar(10), 
  @in_part_no varchar(30), 
  @out_part_no varchar(30) OUTPUT,
  @LB_Tracked char(1) OUTPUT)
AS
	/* Declare local variables */
	DECLARE @err int
	DECLARE @cnt int
	DECLARE @tpart varchar(30)
	DECLARE @Upc char(1)
	DECLARE @Upc_Only char(1)

	SELECT @err = 0
	SELECT @cnt = 0
	SELECT @tpart = ''
	SELECT @out_part_no = 'NOTFOUND'
--	SELECT @SerialCapture = 'N'
	SELECT @LB_Tracked = 'N'
	SELECT @Upc = active FROM tdc_config WHERE [function] = 'upc'
	SELECT @Upc_only = active  FROM tdc_config WHERE [function] = 'upc_only'

	IF (@Upc <> 'Y')
	-- no UPC, allow only part number
	  BEGIN
		SELECT @cnt=Count(*)
		  FROM inv_master
		  WHERE part_no = @in_part_no

		IF (@cnt > 0) 
			BEGIN
				-- part found in inv_master
				SELECT @out_part_no = @in_part_no
			END 
	  END
	ELSE
	  BEGIN
		-- UPC code allowed, check if UPC only
		IF (@Upc_only = 'Y')
		  BEGIN
			-- Allow only UPC code
			SELECT @tpart=part_no
			  FROM inv_master
			  WHERE upc_code = @in_part_no
			IF (@tpart <> '') 
			  BEGIN
				-- UPC code found
				SELECT @out_part_no = @tpart
			  END 
		  END
		ELSE
		  BEGIN
			-- Allow either UPC Code or part number
			SELECT @cnt=Count(*)
			  FROM inv_master
			  WHERE part_no = @in_part_no

			-- check if entry exists as a part number
			IF (@cnt > 0) 
			  BEGIN
				-- part found in inv_master
				SELECT @out_part_no = @in_part_no
			  END 
			ELSE
			  BEGIN
				-- part not found, check if UPC
				SELECT @tpart=part_no
				  FROM inv_master
				  WHERE upc_code = @in_part_no
				IF (@tpart <> '') 
				  BEGIN
					-- UPC code found
					SELECT @out_part_no = @tpart
				  END 
			  END
		  END
	  END

	/*
	 * If the part was found, then check the TDC serialized capture flag to determine
	 * whether or not the part is serialized or not.  FOR NOW, we're using
	 * the table 'tdc_inv_master'.  This tablename will more than likely need to 
	 * be renamed based upon the customer(s) requirements.
	 * FOR NOW this will be hardcoded to 1 for serialized.
	 */
	IF (@out_part_no <> 'NOTFOUND')
	  BEGIN
		-- Per Rod, serial is at inv_list level now - 04/19/00
/*		SELECT @SerialCapture = 'N'
		SELECT @SerialCapture = CONVERT(char(1),tdc_serial_capture)
		  FROM tdc_inv_master
		  WHERE part_no = @out_part_no*/

		SELECT @LB_Tracked = 'N'
		SELECT @LB_Tracked = LB_Tracking
		  FROM inv_master
		  WHERE part_no = @out_part_no
	  END
RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_validate_part] TO [public]
GO
