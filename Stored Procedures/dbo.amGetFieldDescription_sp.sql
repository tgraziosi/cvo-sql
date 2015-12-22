SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetFieldDescription_sp] 
(
    @generic_code 		varchar(30), 				
    @field_type     	smFieldType, 				
	@description 		varchar(60) OUTPUT, 	
	@debug_level		smDebugLevel	= 0			
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amflddes.cpp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

IF @field_type between 1 and 6 
BEGIN 
	
        
        IF @field_type = 6					        				 
	BEGIN 
		SELECT 	@description 	= organizationname 
		FROM 	amOrganization_vw 
		WHERE 	org_id 	= @generic_code 
        IF @@rowcount = 1 
			RETURN 0 
	END 
	
        IF @field_type = 5 						 
	BEGIN 
		SELECT 	@description 	= category_description 
		FROM 	amcat 
		WHERE 	category_code 	= @generic_code 
               
        IF @@rowcount = 1 
			RETURN 0 
	END 

	IF @field_type = 1 						 
	BEGIN 
		SELECT 	@description 	= location_description 
		FROM 	amloc 
		WHERE 	location_code 	= @generic_code 
        
        IF @@rowcount = 1 
       		RETURN 0         
	END 

	IF @field_type 	= 2 						 
    BEGIN 
		SELECT 	@description 	= employee_name 
		FROM 	amemp 
		WHERE 	employee_code 	= @generic_code 
	                
		IF @@rowcount = 1 
			RETURN 0         
	END 

	IF @field_type = 3 						 
        BEGIN 
	    SELECT  @description 	= asset_type_description 
	    FROM    amasttyp 
	    WHERE   asset_type_code = @generic_code 
        
        IF @@rowcount = 1 
			RETURN 0         
	END 

    IF @field_type = 4 					 
    BEGIN 
       	SELECT  @description 	= status_description 
       	FROM    amstatus 
	   	WHERE   status_code 	= @generic_code 
      
       	IF @@rowcount = 1 
			RETURN 0         
   	END 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amflddes.cpp" + ", line " + STR( 123, 5 ) + " -- EXIT: "

RETURN 20020 
GO
GRANT EXECUTE ON  [dbo].[amGetFieldDescription_sp] TO [public]
GO
