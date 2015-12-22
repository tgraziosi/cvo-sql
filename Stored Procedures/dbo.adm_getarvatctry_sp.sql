SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[adm_getarvatctry_sp] 
 @cust_flag smallint,  @customer_code varchar(8),  @ship_to_code varchar(8),  @location_flag smallint, 
 @location_code varchar(8),  @home_ctry_code varchar(3) OUTPUT,  @rpt_ctry_code varchar(3) OUTPUT, 
 @from_ctry varchar(3) OUTPUT,  @cust_ctry varchar(3) OUTPUT,  @cust_vat_num varchar(17) OUTPUT 
AS BEGIN DECLARE  @return_code int     SELECT @home_ctry_code = '', @rpt_ctry_code = '', @cust_ctry = '', @from_ctry = '', @cust_vat_num = '' 
 SELECT @customer_code = ISNULL(@customer_code, ''), @ship_to_code = ISNULL(@ship_to_code, ''), @location_code = ISNULL(@location_code, '') 
    EXEC @return_code = gl_gethomectry_sp @home_ctry_code OUTPUT  IF @return_code <> 0 RETURN 8110 
 SELECT @rpt_ctry_code = @home_ctry_code, @from_ctry = @home_ctry_code     IF @cust_flag = 1 
 BEGIN  IF @ship_to_code <> ''  SELECT @cust_ctry = ISNULL(country_code, ''), @cust_vat_num = ISNULL(tax_id_num, '') 
 FROM adm_shipto_all  WHERE customer_code = @customer_code AND ship_to_code = @ship_to_code 
 IF @cust_ctry = '' SELECT @cust_ctry = ISNULL(country_code, '') FROM adm_cust_all WHERE customer_code = @customer_code 
 IF @cust_vat_num = '' SELECT @cust_vat_num = ISNULL(tax_id_num, '') FROM adm_cust_all WHERE customer_code = @customer_code 
 IF @cust_ctry = '' RETURN 8110  IF @cust_vat_num = '' SELECT @rpt_ctry_code = @cust_ctry 
 END 

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'locations' )
	BEGIN
    
		IF @location_flag = 1  
			SELECT @from_ctry = country_code 
			FROM locations_all
			WHERE location = @location_code 
	END
 IF @from_ctry IS NULL OR @from_ctry = '' SELECT @from_ctry = @home_ctry_code    
 IF @home_ctry_code = '' OR @rpt_ctry_code = '' OR @from_ctry = '' RETURN 8110  RETURN 0 
END 
GO
GRANT EXECUTE ON  [dbo].[adm_getarvatctry_sp] TO [public]
GO
