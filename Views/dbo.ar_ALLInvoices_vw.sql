SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_ALLInvoices_vw]
AS
	SELECT  	ar.timestamp,		ar.customer_code,		ar.trx_ctrl_num,			ar.doc_ctrl_num,			
				0 AS hold_flag,		ar.posted_flag,			ar.gl_trx_id,				ar.paid_flag,		
				ar.nat_cur_code,	ar.amt_net,				ar.amt_paid_to_date,		(ar.amt_tot_chg - ar.amt_paid_to_date)*(SIGN(1 + SIGN(datediff(dd,'1/1/80',getdate())+722815 - ar.date_due))* SIGN(1 - ar.paid_flag)) AS amt_past_due,		
				ar.date_doc,		ar.date_applied,		ar.date_due,				ar.date_shipped,
				ar.cust_po_num,		ar.order_ctrl_num,		ar.trx_type,				ar.date_aging,		
				armaster_all.address_name AS customer_name,
				past_due_status=case CONVERT(int,SIGN(1 + SIGN(datediff(dd,'1/1/80',getdate())+722815 - ar.date_due))* SIGN(1 - ar.paid_flag))
					when 0 then 'NO'
					when 1 then 'YES'
				end,
				ar.org_id,			ar.user_id	
				FROM artrx ar 
					LEFT OUTER JOIN armaster_all ON armaster_all.customer_code = ar.customer_code 
				WHERE trx_type = 2031
	UNION
	SELECT		ar.timestamp,			ar.customer_code,		ar.trx_ctrl_num,			ar.doc_ctrl_num,			
				ar.hold_flag,			ar.posted_flag,			'' AS gl_trx_id,			0 AS paid_flag,			
				ar.nat_cur_code,		ar.amt_net,				'' AS amt_paid_to_date,		0 AS amt_past_due,				
				ar.date_doc,			'' AS date_applied,		ar.date_due,				'' AS date_shipped,		
				ar.cust_po_num,			ar.order_ctrl_num,		ar.trx_type,				ar.date_aging,			
				armaster_all.address_name AS customer_name,
				past_due_status='NO',
				ar.org_id,				ar.user_id		
				FROM arinpchg ar 
					LEFT OUTER JOIN armaster_all ON armaster_all.customer_code = ar.customer_code 
				WHERE trx_type = 2031
GO
GRANT SELECT ON  [dbo].[ar_ALLInvoices_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_ALLInvoices_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_ALLInvoices_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_ALLInvoices_vw] TO [public]
GO
