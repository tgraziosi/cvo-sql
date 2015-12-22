SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                

















CREATE VIEW [dbo].[atmtcinv_vw]
AS
SELECT  d.invoice_no, d.vendor_code, d.part_no, d.po_no, i.description,
d.qty, d.unit_price, e.qty as qty_r, e.unit_price as unit_price_r,h.nat_cur_code, currency_mask
FROM atmtcdet d 
LEFT OUTER JOIN inv_master i
	on i.part_no=d.part_no
LEFT OUTER JOIN atmtchdr h
	ON h.invoice_no=d.invoice_no
LEFT OUTER JOIN atmtcerr e
	ON d.invoice_no=e.invoice_no
	AND d.vendor_code=e.vendor_code
	AND d.po_no= e.po_no
	AND d.part_no=e.part_no
LEFT JOIN glcurr_vw gl
	ON h.nat_cur_code= gl.currency_code

GO
GRANT REFERENCES ON  [dbo].[atmtcinv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[atmtcinv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[atmtcinv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[atmtcinv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[atmtcinv_vw] TO [public]
GO
