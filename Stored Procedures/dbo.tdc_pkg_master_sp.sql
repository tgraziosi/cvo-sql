SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pkg_master_sp] 

	@intDataControl_Navigation INTEGER , 
	@strPkg_Code               VARCHAR(10) =''
AS

DECLARE
	@intDelete                        AS INTEGER ,
	@intRefresh                       AS INTEGER ,
	@intCancel                        AS INTEGER ,
	@intMove_First                    AS INTEGER ,
	@intMove_Previous                 AS INTEGER ,
	@intMove_Next                     AS INTEGER ,
	@intMove_Last                     AS INTEGER 

SELECT @intDelete                 = 6
SELECT @intRefresh                = 4
SELECT @intCancel                 = 7
SELECT @intMove_First             = 15
SELECT @intMove_Previous          = 16
SELECT @intMove_Next              = 17
SELECT @intMove_Last              = 18

IF  @intDataControl_Navigation  = @intDelete 
	BEGIN
		DELETE FROM tdc_pkg_master WHERE pkg_code = @strPkg_Code
--					   AND location   = @strLocation	
--		IF EXISTS(SELECT * FROM tdc_pkg_master (NOLOCK)
--			   WHERE location = @strLocation)
		
--			SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
--			 WHERE location = @strLocation
		
--		ELSE

			SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
	   			ORDER BY  pkg_code
		

	END


ELSE IF @intDataControl_Navigation  = @intRefresh OR  @intDataControl_Navigation  = @intCancel
	BEGIN 
		SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
			WHERE pkg_code = @strPkg_Code
		--	AND location   = @strLocation
   			ORDER BY  pkg_code

	END  

ELSE IF @intDataControl_Navigation  = @intMove_First
	BEGIN 
		SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
		 --WHERE location = @strLocation
		ORDER BY  pkg_code

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Previous
	BEGIN 
		DECLARE @strMaxPkg_Code VARCHAR(10) 

		SELECT @strMaxPkg_Code = ISNULL(MAX(pkg_code),'')
			FROM tdc_pkg_master (NOLOCK)
			WHERE pkg_code < @strPkg_Code
			--AND location   = @strLocation

		IF @strMaxPkg_Code = ''
			BEGIN
				SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
					ORDER BY  pkg_code

			END
		ELSE
			BEGIN
				SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
					WHERE pkg_code = @strMaxPkg_Code
					--AND location   = @strLocation
   					ORDER BY  pkg_code

			END

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Next
	BEGIN 
		DECLARE @strMinPkg_Code VARCHAR(10) 

		SELECT @strMinPkg_Code = ISNULL(MIN(pkg_code),'')
			FROM tdc_pkg_master (NOLOCK)
			WHERE pkg_code > @strPkg_Code
			--GROUP BY  pkg_code  

		IF @strMinPkg_Code = ''
			BEGIN
				SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
					WHERE pkg_code  = (SELECT MAX(pkg_code) FROM tdc_pkg_master (NOLOCK))
   					ORDER BY  pkg_code

			END
		ELSE
			BEGIN
				SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
					WHERE pkg_code = @strMinPkg_Code
					--AND location   = @strLocation
   					ORDER BY  pkg_code

			END

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Last
	BEGIN 
		SELECT TOP 1 * FROM tdc_pkg_master (NOLOCK)
		 	ORDER BY  pkg_code DESC

	END  

 RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_pkg_master_sp] TO [public]
GO
