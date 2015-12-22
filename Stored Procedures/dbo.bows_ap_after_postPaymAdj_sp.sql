SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2009 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2009 Epicor Software Corporation, 2009    
                  All Rights Reserved                    
*/                                                

create proc [dbo].[bows_ap_after_postPaymAdj_sp]
	@batch_ctrl_num		varchar(16),
	@debug_level		smallint = 0
as

return 0
GO
GRANT EXECUTE ON  [dbo].[bows_ap_after_postPaymAdj_sp] TO [public]
GO
