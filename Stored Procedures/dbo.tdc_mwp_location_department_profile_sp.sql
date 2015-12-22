SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_location_department_profile_sp]

@control		INTEGER,
@location		VARCHAR(10),
@department		VARCHAR(10),
@old_location		VARCHAR(10), /* grab old recordset location for editing existing record */
@old_department		VARCHAR(10), /* grab old recordset department for editing existing record */
@err_msg		VARCHAR(255) OUTPUT
AS



if isnull(@location, '') = ''
BEGIN
	SET @err_msg = 'Location code is required'
	RETURN -1
END



if isnull(@department, '') = ''
BEGIN
	SET @err_msg = 'Department code is required'
	RETURN -1
END

IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_location_department_profile  -- Test for current records
		   WHERE	location_code = @location AND         
				department_code = @department)
		
	BEGIN
		SET @err_msg = 'Allocation already exists' 
		Return -1
	END

	 
	INSERT INTO tdc_location_department_profile
	            (location_Code, department_code)
	VALUES      (@location, @department)  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	
	IF NOT EXISTS (SELECT * FROM tdc_location_department_profile 
			WHERE       location_code = @location OR
    				    department_code = @department)
	Begin
		SET @err_msg = 'Cannot find allocation: ' + @department 
		RETURN -1
	END

	IF EXISTS (SELECT * FROM tdc_location_department_profile  -- Test for current records
		   WHERE	location_code = @location AND         
				department_code = @department)
	Begin
	 	SET @err_msg = 'Allocation already exists: ' + @department 
		RETURN -1
	End

	UPDATE tdc_location_department_profile 
	   SET location_code	    = @location,
	       department_code	    = @department	
	 WHERE location_code	    = @old_location
	   AND department_Code 	    = @old_department 
		

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_location_department_profile 
			WHERE       location_code = @location AND
    				    department_code = @department)
	Begin
		SET @err_msg = 'Cannot find allocation: ' + @department 
		RETURN -1
	END

	DELETE	tdc_location_department_profile
	WHERE 	Department_Code = @department AND 
		Location_code = @location
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_location_department_profile_sp] TO [public]
GO
