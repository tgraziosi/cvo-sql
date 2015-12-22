SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[ibhdr]
		 	AS
		 	SELECT 	timestamp, id, trx_ctrl_num, date_entered, date_applied, trx_type, controlling_org_id, detail_org_id,
		 	 	amount, currency_code, tax_code, doc_description, create_date, create_username, last_change_date, 
		 		last_change_username 
		 	FROM ibhdr_all
	               
GO
GRANT REFERENCES ON  [dbo].[ibhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[ibhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[ibhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[ibhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibhdr] TO [public]
GO
