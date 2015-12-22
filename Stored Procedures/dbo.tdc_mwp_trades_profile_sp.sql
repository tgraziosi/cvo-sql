SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_mwp_trades_profile_sp]


@control   		        INTEGER,
@id_code			VARCHAR(10),
@first_name	   		VARCHAR(25),
@last_name			VARCHAR(25),
@skill_type			VARCHAR(20),
@skill_class			VARCHAR(20),
@status				VARCHAR(8),
@err_msg			VARCHAR(255) OUTPUT
AS


if isnull(@id_code, '') = ''
BEGIN
	SET @err_msg = 'Code type is required'
	RETURN -1
END


if isnull(@first_name, '') = ''
BEGIN
	SET @err_msg = 'First name is required'
	RETURN -1
END


if isnull(@last_name, '') = ''
BEGIN
	SET @err_msg = 'Last name is required'
	RETURN -1
END


if isnull(@skill_type, '') = ''
BEGIN
	SET @err_msg = 'Skill type is required'
	RETURN -1
END


if isnull(@skill_class, '') = ''
BEGIN
	SET @err_msg = 'Skill class is required'
	RETURN -1
END


if isnull(@status, '') = ''
BEGIN
	SET @err_msg = 'Status is required'
	RETURN -1
END

IF @control = 1 -- Insert New
BEGIN
	IF EXISTS (SELECT * FROM tdc_mwo_trades_profile  -- Test for current records
		   WHERE         tradesperson_id_code = @id_code)
		
	BEGIN
		SET @err_msg = 'ID code already exists' 
		Return -1
	END

	INSERT INTO tdc_mwo_trades_profile
	            (tradesperson_id_code, tradesperson_first_name, Tradesperson_last_name,
		     tradesperson_skill_type, tradesperson_skill_class, status)
	VALUES      (@id_code, @first_name, @last_name, @skill_type, @skill_class, @status)
	  
END

ELSE IF @control = 2 -- Update Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_mwo_trades_profile 
			WHERE      tradesperson_id_code  = @id_code)
	Begin
		SET @err_msg = 'Cannot find ID code:' + @id_code
		RETURN -1
	END
 	

	UPDATE tdc_mwo_trades_profile 
	   SET  tradesperson_first_name 		= @first_name,
	        tradesperson_last_name			= @last_name,
		tradesperson_skill_type  		= @skill_type,
		tradesperson_skill_class		= @skill_class,
		status					= @status
	 WHERE tradesperson_id_code 	  		= @id_code

END

ELSE IF @control = 3 -- Delete Existing
BEGIN
	IF NOT EXISTS (SELECT * FROM tdc_mwo_trades_profile 
	   		WHERE        tradesperson_id_code = @id_code)
	Begin
		
		SET @err_msg = 'Cannot find id_code: ' + @id_code
		RETURN -1
	END

	DELETE tdc_mwo_trades_profile
	WHERE tradesperson_id_code = @id_code
END

Return 1

GO
GRANT EXECUTE ON  [dbo].[tdc_mwp_trades_profile_sp] TO [public]
GO
