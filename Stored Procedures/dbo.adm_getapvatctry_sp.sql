SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[adm_getapvatctry_sp] 
 @vend_flag smallint,  @vendor_code varchar(12),  @pay_to_code varchar(8),  @location_flag smallint, 
 @location_code varchar(8),  @home_ctry_code varchar(3) OUTPUT,  @rpt_ctry_code varchar(3) OUTPUT, 
 @vend_ctry varchar(3) OUTPUT,  @to_ctry varchar(3) OUTPUT,  @vend_vat_num varchar(17) OUTPUT 
AS BEGIN DECLARE  @return_code int     SELECT @home_ctry_code = '', @rpt_ctry_code = '', @vend_ctry = '', @to_ctry = '', @vend_vat_num = '' 
 SELECT @vendor_code = ISNULL(@vendor_code, ''), @pay_to_code = ISNULL(@pay_to_code, ''), @location_code = ISNULL(@location_code, '') 
    EXEC @return_code = gl_gethomectry_sp @home_ctry_code OUTPUT  IF @return_code <> 0 RETURN 8110 
 SELECT @rpt_ctry_code = @home_ctry_code, @to_ctry = @home_ctry_code     
IF @vend_flag = 1 
 BEGIN  
	IF @pay_to_code <> ''  
		SELECT @vend_ctry = ISNULL(country_code, ''), @vend_vat_num = ISNULL(tax_id_num, '') 
 		FROM appayto  
		WHERE vendor_code = @vendor_code AND pay_to_code = @pay_to_code  

IF @vend_ctry = '' SELECT @vend_ctry = ISNULL(country_code, '') FROM adm_vend_all WHERE vendor_code = @vendor_code 
 IF @vend_vat_num = '' SELECT @vend_vat_num = ISNULL(tax_id_num, '') FROM adm_vend_all WHERE vendor_code = @vendor_code 
 IF @vend_ctry = '' RETURN 8110  END     

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'locations' )
	BEGIN
		IF @location_flag = 1  
			SELECT @to_ctry = country_code 
			FROM locations_all
			WHERE location = @location_code 
	END
 IF @to_ctry IS NULL OR @to_ctry = '' SELECT @to_ctry = @home_ctry_code     IF @home_ctry_code = '' OR @rpt_ctry_code = '' OR @to_ctry = '' RETURN 8110 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[adm_getapvatctry_sp] TO [public]
GO
