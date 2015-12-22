SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_contacts_select_sp]
	@customer_code	varchar(8),
	@contact_name	varchar(40) = '',
	@all		smallint = 0

AS

IF @all = 0
	SELECT 	contact_name,
		contact_phone,
		contact_fax,
		contact_email,
		comment,
		customer_code 
	FROM	cc_contacts 
	WHERE	customer_code = @customer_code
	AND	contact_name = @contact_name
	ORDER BY contact_name

ELSE
	SELECT 	contact_name,
		contact_phone,
		contact_fax,
		contact_email,
		comment,
		customer_code
	FROM	cc_contacts 
	WHERE	customer_code = @customer_code
	ORDER BY customer_code, contact_name



GO
GRANT EXECUTE ON  [dbo].[cc_contacts_select_sp] TO [public]
GO
