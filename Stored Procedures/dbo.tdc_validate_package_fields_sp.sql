SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_validate_package_fields_sp]
	@strField        VARCHAR(40) , 
	@strFindCriteria VARCHAR(50)
AS



IF @strField = 'usage_type_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_package_usage_type(NOLOCK) WHERE usage_type_code = @strFindCriteria

	END

ELSE IF @strField = 'pkg_group_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_package_group(NOLOCK) WHERE pkg_group_code = @strFindCriteria
	END

ELSE IF @strField = 'pkg_class_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_package_class(NOLOCK) WHERE pkg_class_code = @strFindCriteria
	END

ELSE IF @strField = 'part_no'
	BEGIN
		SELECT COUNT(*) AS COUNTER
			FROM inv_master (NOLOCK) INNER JOIN
    			     inv_list (NOLOCK) ON inv_master.part_no = inv_list.part_no 
			WHERE inv_list.part_no = @strFindCriteria
			AND   UOM <> 'HR'
	END

ELSE IF @strField = 'currency_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM mccu1_vw(NOLOCK) WHERE currency_code = @strFindCriteria
	END

ELSE IF @strField = 'pkg_code'
	BEGIN
		SELECT COUNT(*)AS COUNTER FROM tdc_pkg_master(NOLOCK) WHERE pkg_code = @strFindCriteria
	END


RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_validate_package_fields_sp] TO [public]
GO
