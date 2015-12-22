SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\appaypst.VWv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW [dbo].[appaypst_vw]
	AS SELECT *
	FROM apinppyt
	WHERE trx_type IN (4111,4011)
	AND ( printed_flag = 1 OR printed_flag = 2 )
	AND		(settlement_ctrl_num is null or settlement_ctrl_num = '')


GO
GRANT REFERENCES ON  [dbo].[appaypst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[appaypst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[appaypst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[appaypst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[appaypst_vw] TO [public]
GO
