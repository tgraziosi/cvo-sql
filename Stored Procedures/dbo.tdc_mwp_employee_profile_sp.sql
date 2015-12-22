SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_employee_profile_sp]

@control        INTEGER,
@lock 	   	INTEGER,
@Code		VARCHAR(10),
@employee	VARCHAR(40),
@err_msg	VARCHAR(255) OUTPUT
AS


if isnull(@code,'') = ''
begin
	Set @err_msg = 'Employee code is required'
	return -1
end


if isnull(@employee,'') = ''
begin
	set @err_msg = 'Employee name is required'
	return -1
end



IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_employee_profile  -- Test for current records
		   WHERE         employee_code = @code)
		
	BEGIN
		SET @err_msg = 'Employee code already exists' 
		Return -1
	END

	IF @lock = 1       -- Test for Locked location
        BEGIN
		IF NOT EXISTS (SELECT * FROM employee 
		                WHERE kys = @code)

		BEGIN
			SET @err_msg = 'Cannot find employee code: ' + @code
 			RETURN -1
		END
        END
 
	INSERT INTO tdc_employee_profile
	            (lock_to_employee, employee_code, employee_name)
	VALUES      (@lock, @code, @employee)
	  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	IF @lock = 1
	BEGIN
		IF NOT EXISTS (SELECT * FROM employee
    		          WHERE	 kys = @code)

		BEGIN
			SET @err_msg = 'Cannot find employee code: ' + @code
			RETURN -1
		END
	END
	
	IF NOT EXISTS (SELECT * FROM tdc_employee_profile 
			WHERE        employee_code = @code)
	Begin
		SET @err_msg = 'Cannot find employee code: ' + @code
		RETURN -1
	END
 	

	UPDATE tdc_employee_profile 
	   SET employee_name		= @employee,
	       lock_to_employee     	= @lock	
	 WHERE employee_code 	    	= @code

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_employee_profile 
	   		WHERE       employee_code = @code)
	Begin
		SET @err_msg = 'Cannot find employee code: ' + @code 
		RETURN -1
	END

	DELETE tdc_employee_profile
	WHERE employee_code = @code
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_employee_profile_sp] TO [public]
GO
