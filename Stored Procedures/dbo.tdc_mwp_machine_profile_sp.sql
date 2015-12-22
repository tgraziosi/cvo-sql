SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_machine_profile_sp]


@control        INTEGER,
@lock 	   	INTEGER,
@machine	VARCHAR(30),
@description	VARCHAR(255),
@err_msg	VARCHAR(255) OUTPUT
AS


if isnull(@machine, '') = ''
BEGIN
	SET @err_msg = 'Machine code is required'
	RETURN -1
END





IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_machine_profile  -- Test for current records
		   WHERE         machine_code = @machine)
		
	BEGIN
		SET @err_msg = 'Machine already exists' 
		Return -1
	END

	IF @lock = 1       -- Test for Locked location
        BEGIN
		IF NOT EXISTS (	SELECT part_no FROM inv_master (NOLOCK)
				WHERE status = 'R' AND part_no = @machine)
		BEGIN
			SET @err_msg = 'Cannot find machine: ' + @machine
			RETURN -1
		END
        END
 
	INSERT INTO tdc_machine_profile
	            (lock_to_resource, machine_code, machine_description)
	VALUES      (@lock, @machine, @description)
	  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	IF @lock = 1
	BEGIN
		IF NOT EXISTS (	SELECT part_no FROM inv_master (NOLOCK)
				WHERE status = 'R' AND part_no = @machine)
		BEGIN
			SET @err_msg = 'Cannot find machine: ' + @machine
			RETURN -1
		END
	END
	
	IF NOT EXISTS (SELECT * FROM tdc_machine_profile 
			WHERE        machine_code = @machine)
	Begin
		SET @err_msg = 'Cannot find machine: ' + @machine
		RETURN -1
	END
 	

	UPDATE tdc_machine_profile 
	   SET machine_description  = @description,
	       lock_to_resource     = @lock	
	 WHERE machine_code 	    = @machine

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_machine_profile 
	   		WHERE        machine_code = @machine)
	Begin
		
	SET @err_msg = 'Cannot find machine: ' + @machine
		RETURN -1
	END

	IF EXISTS (SELECT * FROM tdc_department_machine_profile 
	   		WHERE        machine_code = @machine)
	Begin
		
		SET @err_msg = 'Cannot delete machine ' + @machine + ', already allocated'
		RETURN -1
	END

	DELETE tdc_machine_profile
	WHERE machine_code = @machine
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_machine_profile_sp] TO [public]
GO
