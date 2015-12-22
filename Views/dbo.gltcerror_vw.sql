SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[gltcerror_vw]
AS
SELECT e.trx_ctrl_num, e.doc_ctrl_num, t.description trx_type_description, 
e.batch_code, m.app_code, e.err_code, e.tc_details, e.tc_helplink, 
e.tc_name, e.tc_refersto, e.tc_severity, e.tc_source, e.tc_summary, 
e.tc_transactionid, e.totalamount, 
e.taxamount, e.date_doc, e.remote_doc_id
FROM gltcerror e, CVO_Control..smapp m, ibtrxtype t
WHERE m.app_id = e.module_id
AND t.trx_type = e.trx_type
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[gltcerror_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcerror_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcerror_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcerror_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcerror_vw] TO [public]
GO
