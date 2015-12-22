SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

CREATE PROC [dbo].[glckbtchmode_sp]
AS
SELECT COUNT(*) FROM batchctl WHERE batch_ctrl_num IN 
	(SELECT batch_code FROM gltrx_all WHERE posted_flag = 0)
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glckbtchmode_sp] TO [public]
GO
