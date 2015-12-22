SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_contacts_delete_sp]
	@customer_code	varchar(8),
	@contact_name	varchar(40)

AS


IF (SELECT COUNT(*) FROM cc_contacts WHERE customer_code = @customer_code AND contact_name = @contact_name) > 0 
	DELETE cc_contacts WHERE customer_code = @customer_code AND contact_name = @contact_name

GO
GRANT EXECUTE ON  [dbo].[cc_contacts_delete_sp] TO [public]
GO
