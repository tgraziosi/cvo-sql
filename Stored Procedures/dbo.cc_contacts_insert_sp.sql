SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_contacts_insert_sp]
	@customer_code	varchar(8),
	@contact_name	varchar(40),
	@contact_phone	varchar(40),
	@contact_fax	varchar(40),
	@contact_email	varchar(60),
	@comment	varchar(255)

AS


IF (SELECT COUNT(*) FROM cc_contacts WHERE customer_code = @customer_code AND contact_name = @contact_name) > 0 
	DELETE cc_contacts WHERE customer_code = @customer_code AND contact_name = @contact_name

INSERT 	cc_contacts 
VALUES(	@customer_code,
	@contact_name,
	@contact_phone,
	@contact_fax,
	@contact_email,
	@comment )


GO
GRANT EXECUTE ON  [dbo].[cc_contacts_insert_sp] TO [public]
GO
