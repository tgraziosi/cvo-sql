SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_inv_validate_mask_sp]
@mask_code	VARCHAR(15),
@mask_data	VARCHAR(50),
@edit_mode	INT,--1) Insert, 2)Edit
@errmsg		VARCHAR(255) OUTPUT
AS 

DECLARE 
@I		INT,
@char		CHAR,
@foundchar	INT,
@language	varchar(10)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

IF @edit_mode = 1 --Insert mode
BEGIN
	IF ISNULL(@mask_code, '') = '' 
	BEGIN
		-- 'Mask code is required'
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_validate_mask_sp' AND err_no = -101 AND language = @language 
		RETURN -1
	END

	IF ISNULL(@mask_data, '') = '' 
	BEGIN
		-- 'Mask data is required'
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_validate_mask_sp' AND err_no = -102 AND language = @language 
		RETURN -1
	END

	IF EXISTS(SELECT * FROM tdc_serial_no_mask (NOLOCK)    
		  WHERE mask_code = @mask_code)
	BEGIN
		-- 'Mask code already exists'
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_validate_mask_sp' AND err_no = -103 AND language = @language 
                RETURN -1
	END
                
END
ELSE-- Edit mode
BEGIN
	IF EXISTS (SELECT * FROM tdc_serial_no_track (NOLOCK)   
		   WHERE mask_code = @mask_code)
	BEGIN
		-- 'Mask code is in use'
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_validate_mask_sp' AND err_no = -104 AND language = @language 
		RETURN -1
	END
	IF EXISTS (SELECT * FROM tdc_inv_master (NOLOCK)   
		   WHERE mask_code = @mask_code)
	BEGIN
		-- 'Mask code is in use'
		SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_validate_mask_sp' AND err_no = -104 AND language = @language 
		RETURN -1
	END

END

--Make sure the first character is not a '!'
IF LEFT(@mask_data, 1) = '!'
BEGIN
	-- 'The optional variable may not be at the beginning of the mask data'
	SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_validate_mask_sp' AND err_no = -105 AND language = @language 
	RETURN -1
END

--Make sure the '!' is not in the middle
SELECT @foundchar = 0
SELECT @I = 1
WHILE (@I < LEN(@mask_data + 'z'))
BEGIN

	SELECT @char = SUBSTRING(@mask_data, @I, 1)
	IF @char = '!'
		SELECT @foundchar = 1
	ELSE
	BEGIN
		IF @foundchar = 1
		BEGIN
			-- 'The optional variable may not be in the middle of the mask data'
			SELECT @errmsg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_validate_mask_sp' AND err_no = -106 AND language = @language 
			RETURN -1
		END
	END
SELECT @I = @I + 1
END
RETURN 1

GO
GRANT EXECUTE ON  [dbo].[tdc_inv_validate_mask_sp] TO [public]
GO
