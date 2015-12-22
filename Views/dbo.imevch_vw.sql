SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imevch_vw] AS 

SELECT 	company_code,
	process_ctrl_num,
	source_trx_ctrl_num,
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	apply_to_num,
	po_ctrl_num,
	ticket_num,
	date_applied,
	date_aging,
	date_due,
	date_doc,
	date_received,
	date_required,
	date_discount,
	posting_code,
	vendor_code,
	pay_to_code,
	branch_code,
	comment_code,
	tax_code,
	terms_code,
	payment_code,
	hold_flag,
	doc_desc,
	hold_desc,
	intercompany_flag,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	pay_to_addr1,
	pay_to_addr2,
	pay_to_addr3,
	pay_to_addr4,
	pay_to_addr5,
	pay_to_addr6,
	attention_name,
	attention_phone,
	approval_code,
	approval_flag,
	processed_flag = 
		CASE processed_flag
			WHEN 0 then 'Unprocessed'
			WHEN 1 then 'Processed (Final)'
			WHEN 2 then 'Error'
		END,
	date_processed,
	org_id,
	tax_freight_no_recoverable
  FROM [CVO_Control]..imaphdr
 WHERE	trx_type = 4091


                                             
GO
GRANT REFERENCES ON  [dbo].[imevch_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imevch_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imevch_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imevch_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imevch_vw] TO [public]
GO
