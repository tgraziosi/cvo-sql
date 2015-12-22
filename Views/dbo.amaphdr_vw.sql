SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amaphdr_vw] 
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
FROM   	amaphdr	hdr,
		CVO_Control..mccurr	curr
WHERE  	hdr.completed_flag 		= 0
AND		hdr.nat_currency_code 	= curr.currency_code

GO
GRANT REFERENCES ON  [dbo].[amaphdr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amaphdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amaphdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amaphdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amaphdr_vw] TO [public]
GO
