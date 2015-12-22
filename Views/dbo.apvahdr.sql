SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[apvahdr]
			AS
			SELECT timestamp, trx_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num, vend_order_num, ticket_num, 
			date_posted, date_applied, date_aging, date_due, date_doc, date_entered, date_received, date_required, date_discount, fob_code, terms_code, 
			state_flag, doc_desc, user_id, journal_ctrl_num, process_ctrl_num, org_id
			FROM apvahdr_all 
GO
GRANT REFERENCES ON  [dbo].[apvahdr] TO [public]
GO
GRANT SELECT ON  [dbo].[apvahdr] TO [public]
GO
GRANT INSERT ON  [dbo].[apvahdr] TO [public]
GO
GRANT DELETE ON  [dbo].[apvahdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvahdr] TO [public]
GO
