SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pkg_master_save_sp] 
	@intUpdate                 	INTEGER ,
	@strPkgCode                    	VARCHAR(10),
	@strPkg_Usage_Type_Code		VARCHAR(10),
	@strPkg_Class_Code		VARCHAR(10),
	@strPkg_Group_Code		VARCHAR(10),
	@strCost_Currency		VARCHAR(10),
	@mnyPm_Cost_Udef_A		MONEY ,
	@mnyPm_Cost_Udef_B		MONEY ,
	@mnyPm_Cost_Udef_C		MONEY ,
	@mnyPm_Cost_Udef_D		MONEY ,
	@intPm_Int_Udef_E		INTEGER , 
	@intPm_Int_Udef_F		INTEGER ,
	@strPm_Udef_A			VARCHAR(30) ,
	@strPm_Udef_B			VARCHAR(30) ,
	@strPm_Udef_C			VARCHAR(30) ,
	@strPm_Udef_D			VARCHAR(30) ,
	@strPm_Udef_E			VARCHAR(30) ,
	@fltDim_Int_X			FLOAT ,
	@fltDim_Int_Y			FLOAT ,
	@fltDim_Int_Z			FLOAT ,
	@fltDim_Int_C			FLOAT ,	
	@fltDim_Ext_X			FLOAT , 
	@fltDim_Ext_Y			FLOAT , 
	@fltDim_Ext_Z			FLOAT , 
	@fltDim_Ext_C			FLOAT , 
	@strDim_UOM			VARCHAR(25) ,
	@fltWeight			FLOAT ,
	@strModified_By			VARCHAR(50) , 
	@strStatus			CHAR(1) ,
	@strOldPkgCode                	VARCHAR(10)
AS

DECLARE @strNewPkg_Usage_Type_Code	VARCHAR(10),
	@strNewPkg_Class_Code		VARCHAR(10),
	@strNewPkg_Group_Code		VARCHAR(10),
	@strNewCost_Currency		VARCHAR(10)


SELECT @strNewPkg_Usage_Type_Code = usage_type_code FROM tdc_package_usage_type (NOLOCK)
	WHERE usage_type_code = @strPkg_Usage_Type_Code

SELECT @strNewPkg_Class_Code = pkg_class_code FROM tdc_package_class (NOLOCK)
	WHERE pkg_class_code = @strPkg_Class_Code

SELECT @strNewPkg_Group_Code = pkg_group_code FROM tdc_package_group (NOLOCK)
	WHERE pkg_group_code = @strPkg_Group_Code

SELECT @strNewCost_Currency = currency_code FROM mccu1_vw (NOLOCK)
	WHERE currency_code = @strCost_Currency


IF @intUpdate = 1 --UPDATE
	BEGIN
		UPDATE tdc_pkg_master SET
			pkg_code		 	= @strPkgCode , 
			pkg_usage_type_code 		= @strNewPkg_Usage_Type_Code , 
    			pkg_class_code 			= @strNewPkg_Class_Code , 
			pkg_group_code			= @strNewPkg_Group_Code ,
			status 				= @strStatus , 
			weight 				= @fltWeight , 
			dim_uom 			= @strDim_UOM , 
    			dim_int_x			= @fltDim_Int_X , 
			dim_int_y 			= @fltDim_Int_Y , 
			dim_int_z 			= @fltDim_Int_Z , 
			dim_int_c 			= @fltDim_Int_C , 
   			dim_ext_x 			= @fltDim_Ext_X , 
			dim_ext_y 			= @fltDim_Ext_Y , 
			dim_ext_z 			= @fltDim_Ext_Z , 
			dim_ext_c 			= @fltDim_Ext_C , 
    			last_modified_date 		= GETDATE() , 
			modified_by 			= @strModified_By , 
    			cost_currency 			= @strNewCost_Currency , 			
    			pm_cost_udef_a 			= @mnyPm_Cost_Udef_A , 
			pm_cost_udef_b 			= @mnyPm_Cost_Udef_B , 
    			pm_cost_udef_c 			= @mnyPm_Cost_Udef_C , 
			pm_cost_udef_d 			= @mnyPm_Cost_Udef_D , 
    			pm_int_udef_e 			= @intPm_Int_Udef_E , 
			pm_int_udef_f 			= @intPm_Int_Udef_F , 
			pm_udef_a 			= @strPm_Udef_A , 
    			pm_udef_b 			= @strPm_Udef_B , 
			pm_udef_c 			= @strPm_Udef_C , 
			pm_udef_d 			= @strPm_Udef_D , 
    			pm_udef_e 			= @strPm_Udef_E
		WHERE  pkg_code = @strOldPkgCode
	END

ELSE
	BEGIN
		INSERT INTO tdc_pkg_master 
		(	pkg_code		 	,	pkg_usage_type_code , 
    			pkg_class_code			,	pkg_group_code ,
			status 				, 
			weight 				, 	dim_uom  , 
    			dim_int_x			, 	dim_int_y  , 
			dim_int_z 			, 	dim_int_c  , 
   			dim_ext_x 			, 	dim_ext_y , 
			dim_ext_z 			, 	dim_ext_c , 
    			last_modified_date 		, 	modified_by , 
    			cost_currency 			,
    			pm_cost_udef_a 			, 	pm_cost_udef_b , 
    			pm_cost_udef_c 			, 	pm_cost_udef_d , 
    			pm_int_udef_e 			,	pm_int_udef_f  , 
			pm_udef_a 			, 	pm_udef_b , 
			pm_udef_c 			, 	pm_udef_d , 
    			pm_udef_e)

			VALUES (
				@strPkgCode       	, 	@strNewPkg_Usage_Type_Code , 
    				@strNewPkg_Class_Code 	,	@strNewPkg_Group_Code ,
			    	@strStatus 		, 
				@fltWeight 		, 	@strDim_UOM , 
				@fltDim_Int_X 		, 	@fltDim_Int_Y , 
				@fltDim_Int_Z 		, 	@fltDim_Int_C , 
				@fltDim_Ext_X 		, 	@fltDim_Ext_Y , 
				@fltDim_Ext_Z 		, 	@fltDim_Ext_C , 
				GETDATE() 	        , 	@strModified_By , @strNewCost_Currency , 
				@mnyPm_Cost_Udef_A 	, 	@mnyPm_Cost_Udef_B , 
				@mnyPm_Cost_Udef_C 	, 	@mnyPm_Cost_Udef_D , 
				@intPm_Int_Udef_E 	, 	@intPm_Int_Udef_F , 
				@strPm_Udef_A 		, 	@strPm_Udef_B , 
				@strPm_Udef_C 		, 	@strPm_Udef_D , 
				@strPm_Udef_E)			
				

	END

IF @@ERROR = 0 --NO ERRORS
	BEGIN
		SELECT TOP 1 * FROM tdc_pkg_master(NOLOCK) WHERE pkg_code  = @strPkgCode
	END

RETURN


GO
GRANT EXECUTE ON  [dbo].[tdc_pkg_master_save_sp] TO [public]
GO
