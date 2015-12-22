SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE  VIEW [dbo].[apdmhdr] AS  
				SELECT timestamp, trx_ctrl_num, doc_ctrl_num, apply_to_num, user_trx_type_code, batch_code, po_ctrl_num, 
					vend_order_num, ticket_num, date_posted, date_applied, date_doc, date_entered, posting_code, vendor_code, 
					pay_to_code, branch_code, class_code, comment_code, fob_code, tax_code, state_flag, amt_gross, amt_discount, 
					amt_freight, amt_tax, amt_misc, amt_net, amt_restock, amt_tax_included, frt_calc_tax, doc_desc, user_id, 
					journal_ctrl_num, intercompany_flag, process_ctrl_num, currency_code, rate_type_home, rate_type_oper, 
					rate_home, rate_oper, org_id, tax_freight_no_recoverable 
				FROM apdmhdr_all 
GO
GRANT REFERENCES ON  [dbo].[apdmhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[apdmhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[apdmhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[apdmhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdmhdr] TO [public]
GO
