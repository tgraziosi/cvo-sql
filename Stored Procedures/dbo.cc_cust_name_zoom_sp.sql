SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_cust_name_zoom_sp]
	 @cust_code varchar(8)
	

AS

select distinct customer_name from arcust
		where customer_code = @cust_code

GO
GRANT EXECUTE ON  [dbo].[cc_cust_name_zoom_sp] TO [public]
GO
