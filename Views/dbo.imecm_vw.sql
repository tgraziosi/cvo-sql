SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imecm_vw] AS 

SELECT 	company_code,
	process_ctrl_num,
	source_ctrl_num,
	order_ctrl_num,
	trx_ctrl_num,
	doc_desc,
	doc_ctrl_num,
	apply_to_num,
	apply_trx_type,
	trx_type,
	date_applied,
	date_doc,
	date_shipped,
	date_due,
	date_aging,
	customer_code,
	ship_to_code,
	salesperson_code,
	territory_code,
	comment_code,
	posting_code,
	terms_code,
	cust_po_num,
	hold_flag,
	hold_desc,
	recurring_flag,
	recurring_code,
	tax_code,
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper,
	prepay_discount,
	prepay_amt,
	prepay_doc_num,
	processed_flag = 
		CASE processed_flag
			WHEN 0 then 'Unprocessed'
			WHEN 1 then 'Processed (Final)'
			WHEN 2 then 'Error'
		END,
	date_processed,
    writeoff_code,
	org_id
  FROM [CVO_Control]..imarhdr
 WHERE	trx_type = 2032


                                             
GO
GRANT REFERENCES ON  [dbo].[imecm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imecm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imecm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imecm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imecm_vw] TO [public]
GO
