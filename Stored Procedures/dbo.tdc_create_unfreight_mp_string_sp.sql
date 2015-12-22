SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_create_unfreight_mp_string_sp]
	@station_id 		varchar(25),
	@user_id 		varchar(50),
	@pack_no 		int,
	@err_msg		varchar(255) OUTPUT
AS

DECLARE
	@status 	varchar(3),	
	@field_length	int,
	@pos		int


SELECT @status = NULL
SELECT @status = status 
  FROM tdc_master_pack_tbl (NOLOCK) 
 WHERE pack_no = @pack_no

IF @status IS NULL 
BEGIN
	SELECT @err_msg = 'Invalid pack no'
	RETURN -1
END

IF (@status = 'X')
BEGIN
	SELECT @err_msg = 'Master pack already shipped'
	RETURN -2
END

IF @status NOT IN('S', 'F')
BEGIN
	SELECT @err_msg = 'Master pack has not been freighted'
	RETURN -3
END
    
--Check if carton has been shipped.   
IF EXISTS(SELECT *
	    FROM tdc_stage_carton a(NOLOCK),
		 tdc_master_pack_ctn_tbl b(NOLOCK)
	   WHERE a.carton_no  = b.carton_no
	     AND b.pack_no = @pack_no
	     AND tdc_ship_flag = 'Y')          
BEGIN
	SELECT @err_msg = 'Cannot unfreight a master pack that has been shipped'
        RETURN -4
END

--Make sure carton is not in stage to load   
IF (SELECT active FROM tdc_config(NOLOCK) WHERE [function] = 'stage_to_load_flag') = 'Y' 
BEGIN
	IF EXISTS(SELECT * 
		    FROM tdc_carton_tx a(NOLOCK),
			 tdc_master_pack_ctn_tbl b(NOLOCK)
                   WHERE a.carton_no = b.carton_no
		     AND b.pack_no = @pack_no
		     AND ISNULL(stlbin_no,'') <> '')
	BEGIN
		SELECT @err_msg = 'Cannot unfreight a carton in a Stage To Load bin.'
		RETURN -5
	END
END


-- Remove all the records for unfreight or freight    
TRUNCATE TABLE #tdc_temp_manifest_string

--##################################################################
--Start loading the temp table
--##################################################################

-- STATION_ID 
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) 
	WHERE message = 'UNFREIGHT' 
	AND fieldname = 'STATION_ID') 
BEGIN
	SELECT @field_length = ((endpos - startpos) +1) ,
	       @pos = startpos
		FROM tdc_mis_msg_layout_tbl (NOLOCK) 
		WHERE message = 'UNFREIGHT'   
		AND fieldname = 'STATION_ID' 
	INSERT INTO #tdc_temp_manifest_string (pos,fieldvalue, fieldname) 
	VALUES (@pos, LEFT(@station_id + SPACE(@field_length),@field_length), 'STATION_ID')

END
 
-- OPERATOR
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) 
	WHERE message = 'UNFREIGHT' 
	AND fieldname = 'OPERATOR') 
BEGIN
	SELECT @field_length = ((endpos - startpos) +1) ,
	       @pos = startpos
		FROM tdc_mis_msg_layout_tbl (NOLOCK) 
		WHERE message = 'UNFREIGHT'   
		AND fieldname = 'OPERATOR' 
	INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname) 
	VALUES (@pos, LEFT(@user_id + SPACE(@field_length),@field_length), 'OPERATOR')

END 

-- void
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) 
	WHERE message = 'UNFREIGHT' 
	AND fieldname = 'VOID') 
BEGIN
	SELECT @field_length = ((endpos - startpos) +1) ,
	       @pos = startpos
		FROM tdc_mis_msg_layout_tbl (NOLOCK) 
		WHERE message = 'UNFREIGHT'   
		AND fieldname = 'VOID' 
	INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname) 
	VALUES (@pos, LEFT('VOID' + SPACE(@field_length),@field_length), 'VOID')

END 
    
-- CARTON
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) 
	WHERE message = 'UNFREIGHT' 
	AND fieldname = 'CARTON') 
BEGIN
	SELECT @field_length = ((endpos - startpos) +1) ,
	       @pos = startpos
		FROM tdc_mis_msg_layout_tbl (NOLOCK) 
		WHERE message = 'UNFREIGHT'   
		AND fieldname = 'CARTON' 
	INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname) 
	VALUES (@pos, LEFT(CAST(@pack_no AS varchar(30)) + SPACE(@field_length),@field_length), 'CARTON')

END 

-- CARTON seq
IF EXISTS (SELECT * FROM tdc_mis_msg_layout_tbl (NOLOCK) 
	WHERE message = 'UNFREIGHT' 
	AND fieldname = 'CARTON_SEQ') 
BEGIN
	SELECT @field_length = ((endpos - startpos) +1) ,
	       @pos = startpos
		FROM tdc_mis_msg_layout_tbl (NOLOCK) 
		WHERE message = 'UNFREIGHT'   
		AND fieldname = 'CARTON_SEQ' 
	INSERT INTO #tdc_temp_manifest_string (pos, fieldvalue, fieldname) 
	VALUES (@pos,  SPACE(@field_length) , 'CARTON_SEQ')

END 

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_create_unfreight_mp_string_sp] TO [public]
GO
