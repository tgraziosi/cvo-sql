SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_get_part_from_uom_sp]
            @part_no varchar(30) output,
            @uom     varchar(10) output
AS

DECLARE @upc_len 	int,
	@upc_allowed	char(1),
	@upc_only	char(1),
	@text_entered	varchar(30)

SET @text_entered = @part_no
SET @part_no      = NULL
SET @uom          = NULL
SET @upc_allowed  = 'N'
SET @upc_only     = 'N'

SET @upc_len = LEN(@text_entered)

IF @upc_len = 0 
BEGIN
	RETURN
END

-- Get UPC config flags
SELECT @upc_allowed = ISNULL((SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'upc'),      'N')
SELECT @upc_only    = ISNULL((SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'upc_only'), 'N')

IF @upc_only = 'N' -- if we allow part numbers, we check them first.
BEGIN  
	
	SELECT @part_no = part_no, @uom = uom FROM inv_master (NOLOCK) WHERE part_no = @text_entered
	
	-------------------------------------------------
	-- Entered text is a valid part  
	-------------------------------------------------
  	IF ISNULL(@part_no, '') <> '' RETURN
END

-------------------------------------------------
-- Entered text is not a valid part
-------------------------------------------------

-- If UPC codes are allowed, check uom_id_code
IF @upc_allowed = 'Y'
BEGIN
 	
	IF @upc_len = 8	 SELECT @part_no = part_no, @uom = UOM FROM uom_id_code (nolock) WHERE EAN_8  = @text_entered
	IF @upc_len = 12 SELECT @part_no = part_no, @uom = UOM FROM uom_id_code (nolock) WHERE UPC    = @text_entered
	IF @upc_len = 13 SELECT @part_no = part_no, @uom = UOM FROM uom_id_code (nolock) WHERE EAN_13 = @text_entered
	IF @upc_len = 14 
	BEGIN	
		SELECT @part_no = part_no, @uom = UOM FROM uom_id_code (nolock) WHERE GTIN = @text_entered
		
		IF ISNULL(@part_no, '') = '' 
		BEGIN
			SELECT @part_no = part_no, @uom = UOM FROM uom_id_code (nolock) WHERE EAN_14 = @text_entered
		END
	END

	-------------------------------------------------
	-- We found a part and UOM for the entered UPC
	-------------------------------------------------
  	IF ISNULL(@part_no, '') <> '' RETURN
END


RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_get_part_from_uom_sp] TO [public]
GO
