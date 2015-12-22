SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_package_class_sp] 

	@intDataControl_Navigation INTEGER , 
	@strPKG_Class_Code         VARCHAR(10) = ''
AS


DECLARE	@error_msg		VARCHAR(255),
	@language		VARCHAR(10),
	@intDelete 		AS INTEGER ,
	@intRefresh 		AS INTEGER ,
	@intCancel		AS INTEGER ,
	@intMove_First		AS INTEGER ,
	@intMove_Previous	AS INTEGER ,
	@intMove_Next		AS INTEGER ,
	@intMove_Last           AS INTEGER ,
	@intCounter		AS INTEGER

SELECT @intDelete                 = 6
SELECT @intRefresh                = 4
SELECT @intCancel                 = 7
SELECT @intMove_First             = 15
SELECT @intMove_Previous          = 16
SELECT @intMove_Next              = 17
SELECT @intMove_Last              = 18

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

IF  @intDataControl_Navigation  = @intDelete 
	BEGIN
		SELECT @intCounter = COUNT(*) FROM tdc_pkg_master (NOLOCK) WHERE pkg_class_code = @strPKG_Class_Code
		
		IF @intCounter = 0 
			BEGIN
				DELETE FROM tdc_package_class WHERE pkg_class_code = @strPKG_Class_Code

				SELECT TOP 1 * FROM tdc_package_class (NOLOCK)
   					ORDER BY  pkg_class_code
			END
		ELSE
			BEGIN
				-- 'The specified Class Code already exists in the package master table.'
				SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_package_class_sp' AND err_no = -101 AND language = @language 
				RAISERROR(@error_msg, 16, 1)
				SELECT TOP 1 * FROM tdc_package_class (NOLOCK) WHERE pkg_class_code = @strPKG_Class_Code
			END
	END


ELSE IF @intDataControl_Navigation  = @intRefresh OR  @intDataControl_Navigation  = @intCancel
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_class (NOLOCK)
			WHERE pkg_class_code = @strPKG_Class_Code
   			ORDER BY  pkg_class_code

	END  

ELSE IF @intDataControl_Navigation  = @intMove_First
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_class (NOLOCK)
			ORDER BY  pkg_class_code

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Previous
	BEGIN 
		DECLARE @strMaxPKG_Class_Code VARCHAR(10) 

		SELECT @strMaxPKG_Class_Code = ISNULL(MAX(pkg_class_code),'')
			FROM tdc_package_class (NOLOCK)
			WHERE pkg_class_code < @strPKG_Class_Code

		IF @strMaxPKG_Class_Code = ''
			BEGIN
				SELECT TOP 1 * FROM tdc_package_class (NOLOCK)
					ORDER BY  pkg_class_code

			END
		ELSE
			BEGIN
				SELECT TOP 1 * FROM tdc_package_class (NOLOCK)
					WHERE pkg_class_code = @strMaxPKG_Class_Code
   					ORDER BY  pkg_class_code

			END

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Next
	BEGIN 
		DECLARE @strMinPKG_Class_Code VARCHAR(10) 

		SELECT @strMinPKG_Class_Code = ISNULL(MIN(pkg_class_code),'')
			FROM tdc_package_class (NOLOCK)
			WHERE pkg_class_code > @strPKG_Class_Code

		IF @strMinPKG_Class_Code = ''
			BEGIN
				SELECT TOP 1 * FROM tdc_package_class (NOLOCK)
					WHERE pkg_class_code  = (SELECT MAX(pkg_class_code) FROM tdc_package_class (NOLOCK))
   					ORDER BY  pkg_class_code

			END
		ELSE
			BEGIN
				SELECT TOP 1 * FROM tdc_package_class (NOLOCK)
					WHERE pkg_class_code = @strMinPKG_Class_Code
   					ORDER BY  pkg_class_code

			END

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Last
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_class (NOLOCK)
   			ORDER BY  pkg_class_code DESC

	END  

 RETURN



GO
GRANT EXECUTE ON  [dbo].[tdc_package_class_sp] TO [public]
GO
