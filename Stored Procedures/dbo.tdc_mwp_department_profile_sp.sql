SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_department_profile_sp]

@control        INTEGER,
@department	VARCHAR(50),
@description	VARCHAR(255),
@err_msg	VARCHAR(255) OUTPUT
AS



if isnull(@department, '') = ''
BEGIN
	SET @err_msg = 'Department code is required'
	RETURN -1
END

IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_department_profile  -- Test for current records
		   WHERE         Department_Code = @department)
		
	BEGIN
		SET @err_msg = 'Department already exists' 
		Return -1
	END

	 
	INSERT INTO tdc_department_profile
	            (department_Code, department_description)
	VALUES      (@department, @description)
	  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	
	IF NOT EXISTS (SELECT * FROM tdc_department_profile 
			WHERE        Department_Code = @department)
	Begin
		SET @err_msg = 'Cannot find department: ' + @department 
		RETURN -1
	END
 	

	UPDATE tdc_department_profile 
	   SET department_description = @description
	 WHERE department_Code 	    = @department

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_department_profile 
	   		WHERE        Department_Code = @department)
	Begin
		SET @err_msg = 'Cannot find department: ' + @department 
		RETURN -1
	END

	IF EXISTS 		(SELECT * FROM tdc_department_machine_profile
			 	 WHERE		department_code = @department)
		
	BEGIN	
		SET @err_msg = 'Cannot delete ' + @department + ', department is allocated'
		RETURN -1
 	END

	IF EXISTS 		(SELECT * FROM tdc_location_department_profile
				  WHERE		department_code = @department)

	BEGIN	
		SET @err_msg = 'Cannot delete ' + @department + ', department is allocated'
		RETURN -1
 	END

	DELETE tdc_department_profile
	WHERE Department_Code = @department
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_department_profile_sp] TO [public]
GO
