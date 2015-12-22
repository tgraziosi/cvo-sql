SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE  [dbo].[tdc_package_fields_find_sp] 
	@strField VARCHAR(30)
AS

IF @strField = 'part_no'
	BEGIN

		SELECT inv_list.part_no, inv_master.[description], inv_list.location
			FROM inv_master (NOLOCK) INNER JOIN
    			     inv_list (NOLOCK) ON 
                             inv_master.part_no = inv_list.part_no
			WHERE (inv_master.uom <> 'HR')
			ORDER BY inv_list.part_no
	END

ELSE IF @strField = 'pkg_class_code'
	BEGIN
		SELECT pkg_class_code , [description] FROM tdc_package_class (NOLOCK) ORDER BY pkg_class_code
	END

ELSE IF   @strField  = 'pkg_group_code'
	BEGIN
		SELECT pkg_group_code, [description] FROM tdc_package_group (NOLOCK)  ORDER BY pkg_group_code

	END

ELSE IF   @strField  = 'usage_type_code'
	BEGIN
		SELECT usage_type_code, [description] From tdc_package_usage_type (NOLOCK)  ORDER BY usage_type_code
	END

ELSE IF @strField = 'currency_code'
	BEGIN
		SELECT currency_code, [Description] FROM mccu1_vw (NOLOCK) ORDER BY currency_code
	END

ELSE IF @strField = 'pkg_code '
	BEGIN
		SELECT pkg_code , pkg_usage_type_code, pkg_class_code, pkg_group_code ,  Status
			FROM tdc_pkg_master (NOLOCK) ORDER BY pkg_code
	END

RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_package_fields_find_sp] TO [public]
GO
