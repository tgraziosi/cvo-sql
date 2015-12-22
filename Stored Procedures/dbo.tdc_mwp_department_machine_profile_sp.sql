SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_department_machine_profile_sp]

@control		INTEGER,
@department 		VARCHAR(10),
@machine		VARCHAR(30),
@old_location		VARCHAR(10), /* grab old recordset location for editing existing record */
@old_department		VARCHAR(10), /* grab old recordset department for editing existing record */
@err_msg		VARCHAR(255) OUTPUT
AS



if isnull(@department, '') = ''
BEGIN
	SET @err_msg = 'Department code is required'
	RETURN -1
END



if isnull(@machine, '') = ''
BEGIN
	SET @err_msg = 'Machine code is required'
	RETURN -1
END

IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_department_machine_profile  -- Test for current records
		   WHERE	department_code = @department AND         
				machine_code = @machine)
		
	BEGIN
		SET @err_msg = 'Allocation already exists' 
		Return -1
	END

	 
	INSERT INTO tdc_department_machine_profile
	            (department_code, machine_code)
	VALUES      (@department, @machine)  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	
	IF NOT EXISTS (SELECT * FROM tdc_department_machine_profile 
			WHERE       department_code = @department OR
    				    machine_code = @machine)
	Begin
		SET @err_msg = 'Cannot find allocation: ' + @machine 
		RETURN -1
	END

	IF EXISTS (SELECT * FROM tdc_department_machine_profile  -- Test for current records
		   WHERE	department_code = @department AND         
				machine_code = @machine)
	Begin
	 	SET @err_msg = 'Allocation already exists: ' + @machine 
		RETURN -1
	End

	UPDATE tdc_department_machine_profile 
	   SET department_code	    = @department,
	       machine_code	    = @machine	
	 WHERE department_code	    = @old_location
	   AND machine_code 	    = @old_department 
		

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_department_machine_profile 
			WHERE       department_code = @department AND
    				    machine_code = @machine)
	Begin
		SET @err_msg = 'Cannot find allocation: ' + @machine 
		RETURN -1
	END

	DELETE	tdc_department_machine_profile
	WHERE 	machine_code = @machine AND 
		department_code = @department
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_department_machine_profile_sp] TO [public]
GO
