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


CREATE VIEW [dbo].[arverifydoc_vw]
AS
	SELECT 
	   doc_ctrl_num
	FROM 
	   arinpchg_all
	UNION
	SELECT
	   doc_ctrl_num
	FROM 
	   artrx_all
GO
GRANT REFERENCES ON  [dbo].[arverifydoc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arverifydoc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arverifydoc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arverifydoc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arverifydoc_vw] TO [public]
GO
