SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_package_class_save_sp] 
	@intUpdate                 INTEGER ,
	@strPKG_Class_Code         VARCHAR(10),
	@strDescription            VARCHAR(80),
	@dteLast_Modified_Date     DATETIME , 
	@strModified_By            VARCHAR(50),
	@strPC_Udef_A			   VARCHAR(10),
	@strPC_Udef_B		   VARCHAR(10),
	@strPC_Udef_C		   VARCHAR(10),
	@strPC_Udef_D		   VARCHAR(10),
	@strPC_Udef_E		   VARCHAR(10),
	@strOldPKG_Class_Code      VARCHAR(10)
AS

IF @intUpdate = 1 --UPDATE
	BEGIN
		UPDATE tdc_package_class SET 
			pkg_class_code 		= @strPKG_Class_Code,
			[description]     	= @strDescription ,
			last_modified_date	= @dteLast_Modified_Date ,
			modified_by		= @strModified_By ,
			pc_udef_a		= @strPC_Udef_A ,
			pc_udef_b		= @strPC_Udef_B ,
			pc_udef_c		= @strPC_Udef_C ,
			pc_udef_d		= @strPC_Udef_D , 
			pc_udef_e		= @strPC_Udef_E

			WHERE pkg_class_code = @strOldPKG_Class_Code

	END

ELSE
	BEGIN
		INSERT INTO tdc_package_class 
		(pkg_class_code            , [description] , 
		 last_modified_date        , modified_by ,
		 pc_udef_a                 , pc_udef_b ,
		 pc_udef_c                 , pc_udef_d ,
		 pc_udef_e                 )
		  
			VALUES (@strPKG_Class_Code , @strDescription ,
				  @dteLast_Modified_Date , @strModified_By ,	
				  @strPC_Udef_A      , @strPC_Udef_B ,
				  @strPC_Udef_C      , @strPC_Udef_D ,
				  @strPC_Udef_E )
	END

IF @@ERROR = 0 --NO ERRORS
	BEGIN
		SELECT TOP 1 * FROM tdc_package_class (NOLOCK) WHERE pkg_class_code = @strPKG_Class_Code
	END

RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_package_class_save_sp] TO [public]
GO
