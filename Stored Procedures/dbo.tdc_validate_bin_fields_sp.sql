SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_validate_bin_fields_sp]
	@strField        VARCHAR(40) , 
	@strFindCriteria VARCHAR(50) ,
	@strOptional     VARCHAR(20) = '' , 
	@strOptional2    VARCHAR(20) = ''	
AS

DECLARE @intViewMode AS VARCHAR(2)

SELECT @intViewMode = '2'

IF @strField = 'location'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM locations(NOLOCK) WHERE location = @strFindCriteria

	END

ELSE IF @strField = 'usage_type_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_bin_usage_type(NOLOCK) WHERE usage_type_code = @strFindCriteria
	END

ELSE IF @strField = 'size_group_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_bin_size_group(NOLOCK) WHERE size_group_code = @strFindCriteria
	END

ELSE IF @strField = 'cost_group_code'
	BEGIN
		SELECT COUNT(*) AS COUNTER FROM tdc_bin_cost_group(NOLOCK) WHERE cost_group_code = @strFindCriteria
	END

ELSE IF @strField = 'group_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_bin_group(NOLOCK) WHERE group_code = @strFindCriteria
			--AND group_code_id = @strOptional
	END

ELSE IF @strField = 'part_no'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM inv_master(NOLOCK) WHERE part_no = @strFindCriteria
			AND uom <> 'HR'
		        AND lb_tracking = 'Y'
	END

ELSE IF @strField = 'currency_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM mccu1_vw (NOLOCK) WHERE currency_code = @strFindCriteria
	END

ELSE IF @strField = 'bin_replenish_insert' --this has to ensure that the bin_no exists in bin_master with this location
					   -- AND that it doesn't exist in bin_replenishment with this location and part_no
					   -- we'll return 0 for okay to perform insert OR 1 if not okay 
	BEGIN
		DECLARE
			@intBinMaster_Counter 		AS INTEGER ,
			@intBinReplenish_Counter	AS INTEGER

		SELECT @intBinMaster_Counter = COUNT(*) FROM tdc_bin_master (NOLOCK)
                        WHERE bin_no = @strFindCriteria
			AND usage_type_code = 'REPLENISH'
			AND location = @strOptional

		SELECT @intBinReplenish_Counter = COUNT(*) FROM tdc_bin_replenishment (NOLOCK)
			WHERE bin_no = @strFindCriteria
			AND location = @strOptional
			AND part_no  = @strOptional2
		
		IF @intBinMaster_Counter = 1 AND  @intBinReplenish_Counter = 0 --OKAY TO PERFORM INSERT INTO tdc_bin_replenishment
			BEGIN
				SELECT COUNTER = 0
			END
		ELSE
			BEGIN
				SELECT COUNTER = 1
			END

		
	END

ELSE IF @strField = 'bin_replenish_location'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_bin_master(NOLOCK) WHERE location = @strFindCriteria
	END

ELSE IF @strField = 'bin_no' 
	IF @strOptional2 <> @intViewMode
		BEGIN
			SELECT COUNT(*)AS COUNTER FROM tdc_bin_master(NOLOCK) 
				WHERE bin_no = @strFindCriteria
				AND location = @strOptional
		END
	ELSE
		BEGIN
			SELECT COUNT(*)AS COUNTER FROM tdc_bin_master(NOLOCK) 
				WHERE bin_no = @strFindCriteria
		END

ELSE IF @strField = 'replenish_bin_no' --if on replenishment Tab in View Mode and Type a value
					-- then we need to validate it exists
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_bin_replenishment(NOLOCK) WHERE bin_no = @strFindCriteria
	END

RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_validate_bin_fields_sp] TO [public]
GO
