SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_package_group_sp] 

	@intDataControl_Navigation INTEGER , 
	@strPkg_Group_Code         VARCHAR(10) =''
AS

DECLARE
	@intDelete                        AS INTEGER ,
	@intRefresh                       AS INTEGER ,
	@intCancel                        AS INTEGER ,
	@intMove_First                    AS INTEGER ,
	@intMove_Previous                 AS INTEGER ,
	@intMove_Next                     AS INTEGER ,
	@intMove_Last                     AS INTEGER ,
	@intCounter			  AS INTEGER

DECLARE @language varchar(10), @msg varchar(255)

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
		SELECT @intCounter = COUNT(*) FROM tdc_pkg_master (NOLOCK) WHERE pkg_group_code = @strPkg_Group_Code
		IF @intCounter = 0
			BEGIN	
				DELETE FROM tdc_package_group WHERE pkg_group_code = @strPkg_Group_Code

				SELECT TOP 1 * FROM tdc_package_group (NOLOCK)
   					ORDER BY  pkg_group_code
			END
		ELSE
			BEGIN
				-- The specified Group Code already exists in the package master table.
				SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_package_group_sp' AND err_no = -101 AND language = @language
				RAISERROR(@msg, 16,1)
			END
		

	END


ELSE IF @intDataControl_Navigation  = @intRefresh OR  @intDataControl_Navigation  = @intCancel
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_group (NOLOCK)
			WHERE pkg_group_code = @strPkg_Group_Code
   			ORDER BY  pkg_group_code

	END  

ELSE IF @intDataControl_Navigation  = @intMove_First
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_group (NOLOCK)
			ORDER BY  pkg_group_code

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Previous
	BEGIN 
		DECLARE @strMaxPkg_Group_Code VARCHAR(10) 

		SELECT @strMaxPkg_Group_Code = ISNULL(MAX(pkg_group_code),'')
			FROM tdc_package_group (NOLOCK)
			WHERE pkg_group_code < @strPkg_Group_Code

		IF @strMaxPkg_Group_Code = ''
			BEGIN
				SELECT TOP 1 * FROM tdc_package_group (NOLOCK)
					ORDER BY  pkg_group_code

			END
		ELSE
			BEGIN
				SELECT TOP 1 * FROM tdc_package_group (NOLOCK)
					WHERE pkg_group_code = @strMaxPkg_Group_Code
   					ORDER BY  pkg_group_code

			END

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Next
	BEGIN 
		DECLARE @strMinPkg_Group_Code VARCHAR(10) 

		SELECT @strMinPkg_Group_Code = ISNULL(MIN(pkg_group_code),'')
			FROM tdc_package_group (NOLOCK)
			WHERE pkg_group_code > @strPkg_Group_Code

		IF @strMinPkg_Group_Code = ''
			BEGIN
				SELECT TOP 1 * FROM tdc_package_group (NOLOCK)
					WHERE pkg_group_code  = (SELECT MAX(pkg_group_code) FROM tdc_package_group (NOLOCK))
   					ORDER BY  pkg_group_code

			END
		ELSE
			BEGIN
				SELECT TOP 1 * FROM tdc_package_group (NOLOCK)
					WHERE pkg_group_code = @strMinPkg_Group_Code
   					ORDER BY  pkg_group_code

			END

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Last
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_group (NOLOCK)
   			ORDER BY  pkg_group_code DESC

	END  

 RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_package_group_sp] TO [public]
GO
