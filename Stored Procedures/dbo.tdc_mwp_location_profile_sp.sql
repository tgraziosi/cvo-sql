SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_location_profile_sp]

@control        INTEGER,
@lock 	   	INTEGER,
@location	VARCHAR(10),
@description	VARCHAR(255),
@err_msg	VARCHAR(255) OUTPUT
AS



if isnull(@location, '') = ''
BEGIN
	SET @err_msg = 'Location code is required'
	RETURN -1
END



IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_location_profile  -- Test for current records
		   WHERE         location_code = @location)
		
	BEGIN
		SET @err_msg = 'Location already exists' 
		Return -1
	END

	IF @lock = 1       -- Test for Locked location
        BEGIN
		IF NOT EXISTS (SELECT * FROM locations 
		                WHERE location = @location)

		BEGIN
			SET @err_msg = 'Cannot find location: ' + @location 
			RETURN -1
		END
        END
 
	INSERT INTO tdc_location_profile
	            (lock_to_location, location_code, location_description)
	VALUES      (@lock, @location, @description)
	  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	IF @lock = 1
	BEGIN
		IF NOT EXISTS (SELECT * FROM locations 
    		           WHERE	 location = @location)

		BEGIN
			SET @err_msg = 'Cannot find location: ' + @location
			RETURN -1
		END
	END
	
	IF NOT EXISTS (SELECT * FROM tdc_location_profile 
			WHERE        location_code = @location)
	Begin
		SET @err_msg = 'Cannot find location: ' + @location 
		RETURN -1
	END
 	

	UPDATE tdc_location_profile 
	   SET location_description = @description,
	       lock_to_location     = @lock	
	 WHERE location_code 	    = @location

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_location_profile 
	   		WHERE        location_code = @location)
	Begin
		SET @err_msg = 'Cannot find location: ' + @location 
		RETURN -1
	END

	IF EXISTS	 (SELECT * FROM tdc_location_department_profile 
	   			WHERE        location_code = @location)
	Begin
		SET @err_msg = 'Cannot delete location ' + @location + ', location is allocated' 
		RETURN -1
	END

	DELETE tdc_location_profile
	WHERE location_code = @location
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_location_profile_sp] TO [public]
GO
