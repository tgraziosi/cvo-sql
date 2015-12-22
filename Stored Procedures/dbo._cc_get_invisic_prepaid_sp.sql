SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[_cc_get_invisic_prepaid_sp]
	@customer_code varchar(8)

AS

SET QUOTED_IDENTIFIER OFF

	DECLARE @client_id varchar(20)

	SELECT @client_id = ClientID FROM axClient WHERE code = @customer_code

	SELECT DISTINCT InvoiceNumber 
	FROM 	axDocument d , axItem i, axAppliedItems a
	where 	d.DocumentID = a.DocumentID
	AND	a.ItemID = i.ItemID
	AND	ItemTypeID = 3
	AND 	d.ClientID = @client_id
	AND	UPPER(InvoiceNumber) NOT LIKE 'PREPAID%'


GO
GRANT EXECUTE ON  [dbo].[_cc_get_invisic_prepaid_sp] TO [public]
GO
