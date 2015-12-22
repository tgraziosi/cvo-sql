SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_address_info_sp] 
	@customer_code varchar(8)

AS

	
	SELECT	addr1, 
				addr2, 
				addr3, 
				addr4, 
				addr5, 
				addr6, 
				url,
				'date_opened' = CASE WHEN ISNULL(date_opened,0) > 639906 THEN CONVERT(datetime, DATEADD(dd, date_opened - 639906, '1/1/1753')) ELSE '' END, 
				contact_name, 
				contact_phone, 
				tlx_twx, 
				phone_2
	FROM arcust
	WHERE customer_code = @customer_code
 
GO
GRANT EXECUTE ON  [dbo].[cc_get_address_info_sp] TO [public]
GO
