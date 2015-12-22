SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
 CREATE VIEW [dbo].[epmchhdr]
				AS
				SELECT  timestamp, 	match_ctrl_num, 	vendor_code, 		vendor_remit_to, 
					vendor_invoice_no, date_match, 		tolerance_hold_flag, 	tolerance_approval_flag, 
					validated_flag, vendor_invoice_date, 	invoice_receive_date, 	apply_date, 
					aging_date, 	due_date, 		discount_date, 		amt_net, 
					amt_discount, 	amt_tax, 		amt_freight, 		amt_misc, 
					amt_due, 	match_posted_flag, 	amt_tax_included, 	trx_ctrl_num, 	
					nat_cur_code, 	rate_type_home, 	rate_type_oper, 	rate_home, 
					rate_oper, 	batch_code, 		org_id 
				FROM  epmchhdr_all
			      
GO
GRANT REFERENCES ON  [dbo].[epmchhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[epmchhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[epmchhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[epmchhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[epmchhdr] TO [public]
GO
