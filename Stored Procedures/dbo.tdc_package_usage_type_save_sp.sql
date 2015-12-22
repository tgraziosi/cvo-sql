SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_package_usage_type_save_sp] 
	@intUpdate                 	INTEGER ,
	@strUsage_Type_Code         	VARCHAR(10),
	@strDescription            	VARCHAR(80),
	@strOldUsage_Type_Code      	VARCHAR(10)
AS

IF @intUpdate = 1 --UPDATE
	BEGIN
		UPDATE tdc_package_usage_type SET 
			usage_type_code 	= @strUsage_Type_Code,
			[description]     	= @strDescription 

			WHERE usage_type_code = @strOldUsage_Type_Code

	END

ELSE
	BEGIN
		INSERT INTO tdc_package_usage_type 
		(usage_type_code            , [description] )
		  
			VALUES (@strUsage_Type_Code , @strDescription )
	END

IF @@ERROR = 0 --NO ERRORS
	BEGIN
		SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK) WHERE usage_type_code = @strUsage_Type_Code
	END

RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_package_usage_type_save_sp] TO [public]
GO
