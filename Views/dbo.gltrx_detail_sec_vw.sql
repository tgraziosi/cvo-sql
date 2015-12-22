SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                



























CREATE VIEW [dbo].[gltrx_detail_sec_vw] 
AS
	SELECT  journal_ctrl_num
	FROM 	gltrxdet z
	WHERE z.offset_flag = 0
	GROUP BY journal_ctrl_num 
	HAVING count(1) = ( SELECT count(1) FROM gltrxdet a , Organization b 
		WHERE a.org_id = b.organization_id  and a.journal_ctrl_num = z.journal_ctrl_num
		)
GO
GRANT REFERENCES ON  [dbo].[gltrx_detail_sec_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrx_detail_sec_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrx_detail_sec_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrx_detail_sec_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrx_detail_sec_vw] TO [public]
GO
