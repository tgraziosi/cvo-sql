SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amapcom_vw] 
AS 

SELECT 
		hdr.timestamp,
 hdr.company_id, 
 hdr.trx_ctrl_num, 
 hdr.doc_ctrl_num, 
 hdr.vendor_code,
 hdr.apply_date,
 hdr.nat_currency_code,
		nat_currency_mask = curr.currency_mask,
		nat_curr_precision = curr.curr_precision,
 hdr.amt_net,
 hdr.org_id 
FROM 	amaphdr	hdr,
		CVO_Control..mccurr	curr,
	IB_Organization_vw Org_vw
WHERE 	hdr.completed_flag 		= 1
AND		hdr.nat_currency_code 	= curr.currency_code
AND    hdr.org_id = Org_vw.org_id

GO
GRANT REFERENCES ON  [dbo].[amapcom_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amapcom_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amapcom_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amapcom_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amapcom_vw] TO [public]
GO
