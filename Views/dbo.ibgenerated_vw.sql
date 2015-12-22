SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[ibgenerated_vw]
AS

	SELECT 	
		CONVERT (varchar(36), hdr.id) id,
		CONVERT (varchar(32), link.trx_ctrl_num) trx_ctrl_num,
		CONVERT (varchar(32), hdr.trx_ctrl_num) ib_trx_ctrl_num,
		CONVERT (varchar(80), hdr.doc_description) doc_description,
		CONVERT (varchar(60), hdr.controlling_org_id) controlling_org_id,
		CONVERT (varchar(60), hdr.detail_org_id) detail_org_id,
		hdr.date_entered,
		hdr.date_applied,
		CONVERT (varchar(60), t.description) trx_type,
		CONVERT (float, hdr.amount) amount,
		CONVERT (varchar(32), hdr.currency_code) currency_code,
		CONVERT (varchar(16), hdr.tax_code) tax_code,
		x_date_entered = datediff( day, '01/01/1900', hdr.date_entered) + 693596,
		x_date_applied = datediff( day, '01/01/1900', hdr.date_applied) + 693596

	FROM ibhdr hdr
	INNER JOIN iblink link
		ON hdr.id = link.id
		AND link.sequence_id = 2
	INNER JOIN ibtrxtype t
		ON hdr.trx_type = t.trx_type
	
GO
GRANT REFERENCES ON  [dbo].[ibgenerated_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibgenerated_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibgenerated_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibgenerated_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibgenerated_vw] TO [public]
GO
