SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_package_usage_type_sp] 

	@intDataControl_Navigation INTEGER , 
	@strUsage_Type_Code         VARCHAR(10) =''
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
		SELECT @intCounter = COUNT(*) FROM tdc_pkg_master (NOLOCK) WHERE pkg_usage_type_code = @strUsage_Type_Code

		IF @intCounter = 0
			BEGIN
				DELETE FROM tdc_package_usage_type WHERE usage_type_code = @strUsage_Type_Code

				SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK)
   					ORDER BY  usage_type_code
			END
		ELSE
			BEGIN
				-- The specified usage type code already exists in package master.
				SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_package_usage_type_sp' AND err_no = -101 AND language = @language
				RAISERROR (@msg,16,1)
			END

	END


ELSE IF @intDataControl_Navigation  = @intRefresh OR  @intDataControl_Navigation  = @intCancel
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK)
			WHERE usage_type_code = @strUsage_Type_Code
   			ORDER BY  usage_type_code

	END  

ELSE IF @intDataControl_Navigation  = @intMove_First
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK)
			ORDER BY  usage_type_code

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Previous
	BEGIN 
		DECLARE @strMaxUsage_Type_Code VARCHAR(10) 

		SELECT @strMaxUsage_Type_Code = ISNULL(MAX(usage_type_code),'')
			FROM tdc_package_usage_type (NOLOCK)
			WHERE usage_type_code < @strUsage_Type_Code

		IF @strMaxUsage_Type_Code = ''
			BEGIN
				SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK)
					ORDER BY  usage_type_code

			END
		ELSE
			BEGIN
				SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK)
					WHERE usage_type_code = @strMaxUsage_Type_Code
   					ORDER BY  usage_type_code

			END

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Next
	BEGIN 
		DECLARE @strMinUsage_Type_Code VARCHAR(10) 

		SELECT @strMinUsage_Type_Code = ISNULL(MIN(usage_type_code),'')
			FROM tdc_package_usage_type (NOLOCK)
			WHERE usage_type_code > @strUsage_Type_Code

		IF @strMinUsage_Type_Code = ''
			BEGIN
				SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK)
					WHERE usage_type_code  = (SELECT MAX(usage_type_code) FROM tdc_package_usage_type (NOLOCK) )
   					ORDER BY  usage_type_code

			END
		ELSE
			BEGIN
				SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK)
					WHERE usage_type_code = @strMinUsage_Type_Code
   					ORDER BY  usage_type_code

			END

	END  

ELSE IF @intDataControl_Navigation  = @intMove_Last
	BEGIN 
		SELECT TOP 1 * FROM tdc_package_usage_type (NOLOCK)
   			ORDER BY  usage_type_code DESC

	END  

 RETURN



GO
GRANT EXECUTE ON  [dbo].[tdc_package_usage_type_sp] TO [public]
GO
