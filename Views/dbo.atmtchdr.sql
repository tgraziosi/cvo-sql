SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[atmtchdr]
	AS
	SELECT 	timestamp, 	invoice_no, 	vendor_code, 	amt_net, 	date_doc, 
	date_discount, 	nat_cur_code, 	status, 	date_posted, 	date_imported, 
	num_failed, 	date_failed, 	source_module, 	error_desc, 	amt_tax, 	
	amt_discount, 	amt_freight, 	amt_misc, 	org_id 
	FROM atmtchdr_all
	
GO
GRANT REFERENCES ON  [dbo].[atmtchdr] TO [public]
GO
GRANT SELECT ON  [dbo].[atmtchdr] TO [public]
GO
GRANT INSERT ON  [dbo].[atmtchdr] TO [public]
GO
GRANT DELETE ON  [dbo].[atmtchdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[atmtchdr] TO [public]
GO
