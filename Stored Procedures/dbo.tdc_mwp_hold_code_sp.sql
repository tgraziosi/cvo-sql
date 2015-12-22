SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_hold_code_sp]

@control        INTEGER,
@Code 	   	VARCHAR(10),
@description	VARCHAR(255),
@err_msg	VARCHAR(255) OUTPUT
AS

IF isnull(@code, '') = ''
BEGIN
	SET @err_msg = 'Hold code is required'
	RETURN -1
END


IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_mwo_hold_code  -- Test for current records
		   WHERE         hold_code = @Code)
		
	BEGIN
		SET @err_msg = 'Code already exists'
 		Return -1
	END

	INSERT INTO tdc_mwo_hold_code
	            (hold_code, hold_code_description)
	VALUES      (@Code, @description)
	  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	
	IF NOT EXISTS (SELECT * FROM tdc_mwo_hold_code 
			WHERE        hold_code = @Code)
	Begin
		SET @err_msg = 'Cannot find code: ' + @Code 
		RETURN -1
	END
 	

	UPDATE tdc_mwo_hold_code 
	   SET hold_code_description	   	= @description	
	 WHERE hold_code 	    		= @Code

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_mwo_hold_code 
	   		WHERE         hold_code = @Code)
	Begin
		SET @err_msg = 'Cannot find code: ' + @Code
		RETURN -1
	END

	DELETE tdc_mwo_hold_code
	WHERE hold_code = @Code
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_hold_code_sp] TO [public]
GO
