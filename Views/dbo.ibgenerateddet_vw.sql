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


CREATE VIEW [dbo].[ibgenerateddet_vw]
AS
	SELECT
		CONVERT(varchar(36), det.id) id,
		CONVERT(varchar(32), hdr.trx_ctrl_num) trx_ctrl_num,
		sequence_id,
		CONVERT(varchar(60), org_id) org_id,
		CONVERT(varchar(80), det.doc_description) doc_description,
		det.amount,
		CONVERT(varchar(32), det.currency_code) currency_code,
		CONVERT(varchar(64), account_code) account_code,
		CONVERT(varchar(64), reference_code) reference_code,
		balance_oper,
		rate_oper,
		CONVERT(varchar(16), oper_currency) oper_currency,
		CONVERT(varchar(16), rate_type_oper) rate_type_oper,
		balance_home,
		rate_home,
		CONVERT(varchar(16), home_currency) home_currency,
		CONVERT(varchar(16), rate_type_home) rate_type_home,
		reconciled_flag = CASE reconciled_flag 
					WHEN 1 THEN 'Yes'
					ELSE 'No' END,
		dispute_flag = CASE dispute_flag
					WHEN 1 THEN 'Yes'
					ELSE 'No' END,
		CONVERT(varchar(16), dispute_code) dispute_code
	FROM ibdet det
		INNER JOIN ibhdr hdr
		ON det.id = hdr.id
GO
GRANT REFERENCES ON  [dbo].[ibgenerateddet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibgenerateddet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibgenerateddet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibgenerateddet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibgenerateddet_vw] TO [public]
GO
