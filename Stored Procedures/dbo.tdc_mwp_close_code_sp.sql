SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_close_code_sp]

@control        INTEGER,
@code 	   	VARCHAR(10),
@type		VARCHAR(13),
@description	VARCHAR(255),
@err_msg	VARCHAR(255) OUTPUT
AS


if isnull(@type, '') = ''
BEGIN
	SET @err_msg = 'Code type is required'
	RETURN -1
END

if isnull(@code, '') = ''
BEGIN
	SET @err_msg = 'Close code is required'
	RETURN -1
END

IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_mwo_close_code  -- Test for current records
		   WHERE         close_code = @code)
		
	BEGIN
		SET @err_msg = 'Code already exists'
 		Return -1
	END

	INSERT INTO tdc_mwo_close_code
	            (close_code, code_type, close_code_description)
	VALUES      (@code, @type, @description)
	  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	
	IF NOT EXISTS (SELECT * FROM tdc_mwo_close_code 
			WHERE        close_code = @code)
	Begin
		SET @err_msg = 'Cannot find code: ' + @code 
		RETURN -1
	END
 	

	UPDATE tdc_mwo_close_code 
	   SET Code_type 	    		= @type,
	       close_code_description   	= @description	
	 WHERE close_code 	    		= @code

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_mwo_close_code 
	   		WHERE         close_code = @code)
	Begin
		SET @err_msg = 'Cannot find code: ' + @code
		RETURN -1
	END

	DELETE tdc_mwo_close_code
	WHERE close_code = @code
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_close_code_sp] TO [public]
GO
