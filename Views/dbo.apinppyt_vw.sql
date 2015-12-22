SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\VW\apinppyt.VWv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                




CREATE VIEW [dbo].[apinppyt_vw]
	AS	SELECT	*
	FROM	apinppyt
	WHERE 	trx_type = 4111
	AND	printed_flag NOT IN(1, 3)
	AND	settlement_ctrl_num IS NULL
GO
GRANT REFERENCES ON  [dbo].[apinppyt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apinppyt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apinppyt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apinppyt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apinppyt_vw] TO [public]
GO
