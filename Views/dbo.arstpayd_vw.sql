SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
               CREATE VIEW [dbo].[arstpayd_vw] AS SELECT artrx.* FROM artrx WHERE artrx.doc_ctrl_num = apply_to_num 
 AND (( artrx.doc_ctrl_num NOT IN (SELECT ctrlnum from arstctrl WHERE artrx.trx_type = arstctrl.ctrltype )) 
 OR ( artrx.doc_ctrl_num NOT IN (SELECT doc_ctrl_num FROM ntdocs WHERE artrx.trx_type = ntdocs.trx_type ))) 
 AND (artrx.trx_type = apply_trx_type  AND artrx.trx_type in (2021, 2031)  AND artrx.paid_flag = 0 
 AND void_flag = 0) 

 /**/
GO
GRANT REFERENCES ON  [dbo].[arstpayd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arstpayd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arstpayd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arstpayd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arstpayd_vw] TO [public]
GO
