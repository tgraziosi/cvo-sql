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
CREATE VIEW [dbo].[amvalues_rpt_vw] 
    AS
SELECT
timestamp,
co_trx_id,
co_asset_book_id,
account_type_id,
apply_date,
trx_type,
amount,
account_id,
posting_flag ,
datediff( day, '01/01/1900', apply_date) + 693596 as apply_date_jul
FROM	amvalues
GO
GRANT REFERENCES ON  [dbo].[amvalues_rpt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amvalues_rpt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amvalues_rpt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amvalues_rpt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amvalues_rpt_vw] TO [public]
GO
