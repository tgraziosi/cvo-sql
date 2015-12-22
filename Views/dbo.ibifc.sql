SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[ibifc]
	                 AS
	                 SELECT timestamp, id, date_entered, date_applied, trx_type, controlling_org_id, detail_org_id, amount, 
		                currency_code, tax_code, recipient_code, originator_code, tax_payable_code, tax_expense_code, 
		                state_flag, process_ctrl_num, link1, link2, link3, username, reference_code, hold_flag, hold_desc 
	                 FROM ibifc_all
	               
GO
GRANT REFERENCES ON  [dbo].[ibifc] TO [public]
GO
GRANT SELECT ON  [dbo].[ibifc] TO [public]
GO
GRANT INSERT ON  [dbo].[ibifc] TO [public]
GO
GRANT DELETE ON  [dbo].[ibifc] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibifc] TO [public]
GO
