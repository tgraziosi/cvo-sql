SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_valid_invntryAdmin_fld_sp]
	@strField        VARCHAR(40) , 
	@strFindCriteria VARCHAR(50) ,
	@strPart_No	 VARCHAR(30) = ''
AS



IF @strField = 'location' --ensure that the location user entered for this part exists
			  --in inv_list for this part
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM inv_list(NOLOCK) 
			WHERE location = @strFindCriteria
			AND   part_no  = @strPart_No

	END


ELSE IF @strField = 'part_no'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM inv_master(NOLOCK) 
			WHERE part_no = @strFindCriteria
			AND UOM <> 'HR'
			AND lb_tracking = 'Y'
			AND status IN ('H' , 'P')
			--AND allow_fractions = 0
	END


ELSE IF @strField = 'inv_list_part_no' --If WMSInventory Entry Tab is in view Mode and 
					--user types in a part that exists in tdc_inv_list
					-- then we will retrieve the first record for that part  		
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_inv_list (NOLOCK) WHERE part_no = @strFindCriteria
	END

ELSE IF @strField = 'inv_list_location' --If WMSInventory Entry Tab is in view Mode and 
					--user types in a valid location for a part then we 
					-- want to retrieve that record
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_inv_list(NOLOCK) 
			WHERE location = @strFindCriteria
			AND   part_no  = @strPart_No

	END

ELSE IF @strField = 'mask_code' --this validates the mask_code a user types in on BOTH the Inventory Entry
				--tab as well as the Serial No Mask tab
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_serial_no_mask 
			WHERE mask_code = @strFindCriteria

	END

RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_valid_invntryAdmin_fld_sp] TO [public]
GO
