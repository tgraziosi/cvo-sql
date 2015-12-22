SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetDescription_sp] 
(
	@category_code          smGenericCode, 			
	@location_code          smGenericCode, 			
	@employee_code          smGenericCode, 			
	@assettype_code         smGenericCode, 			
	@status_code            smGenericCode, 			
        @org_id                 varchar(30),		        
	@category_desc          smStdDescription OUTPUT, 	
	@location_desc          smStdDescription OUTPUT, 	
	@employee_desc          smStdDescription OUTPUT, 	
	@assettype_desc         smStdDescription OUTPUT, 	
	@status_desc            smStdDescription OUTPUT, 	
        @org_desc 		varchar(60)      OUTPUT,	
	@debug_level			smDebugLevel	 = 0		
)
AS 

DECLARE 
	@message        smErrorLongDesc, 
	@ret_status     smErrorCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amgetdes.cpp" + ", line " + STR( 73, 5 ) + " -- ENTRY: "

 
SELECT @category_desc = " ",
 	   @location_desc = " ",
	   @employee_desc = " ",
	   @assettype_desc = " ",
	   @status_desc = " ",
	   @org_desc = ""	

IF @category_code IS NOT NULL
BEGIN
	EXEC @ret_status = amGetFieldDescription_sp 
						@category_code, 
						5, 
						@category_desc OUTPUT 
	IF @ret_status <> 0
		RETURN @ret_status
END

IF @debug_level >= 3
	SELECT category = @category_desc		   

IF @location_code IS NOT NULL
BEGIN
	EXEC @ret_status = amGetFieldDescription_sp 
						@location_code, 
						1, 
						@location_desc OUTPUT 
	IF @ret_status <> 0
		RETURN @ret_status
END

IF @debug_level >= 3
	SELECT location = @location_desc		   

IF @employee_code IS NOT NULL
BEGIN
	EXEC @ret_status = amGetFieldDescription_sp 
						@employee_code, 
						2, 
						@employee_desc OUTPUT 
	IF @ret_status <> 0
		RETURN @ret_status
END

IF @debug_level >= 3
	SELECT employee = @employee_desc		   

IF @assettype_code IS NOT NULL
BEGIN
	EXEC @ret_status = amGetFieldDescription_sp 
						@assettype_code, 
						3, 
						@assettype_desc OUTPUT 
	IF @ret_status <> 0
		RETURN @ret_status
END

IF @debug_level >= 3
	SELECT asset_type = @assettype_code		   

IF 	( LTRIM(@status_code) IS NOT NULL AND LTRIM(@status_code) != " " )
BEGIN
	EXEC @ret_status = amGetFieldDescription_sp 
						@status_code, 
						4, 
						@status_desc OUTPUT 
	IF @ret_status <> 0
		RETURN @ret_status
END

IF @debug_level >= 3
	SELECT status = @status_desc	

IF @org_id IS NOT NULL
BEGIN
	EXEC @ret_status = amGetFieldDescription_sp 
						@org_id, 
						6, 
						@org_desc OUTPUT 
	IF @ret_status <> 0
		RETURN @ret_status
END

IF @debug_level >= 3
	SELECT org = @org_id		   

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amgetdes.cpp" + ", line " + STR( 161, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetDescription_sp] TO [public]
GO
