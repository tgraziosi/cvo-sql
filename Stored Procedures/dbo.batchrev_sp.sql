SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\batchrev.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[batchrev_sp] @Posted_Flag int,
				@BatchUserId	smallint
AS


UPDATE batchctl
SET posted_flag = 0,
	selected_user_id = NULL, 
	selected_flag = 0
WHERE posted_flag = @Posted_Flag
AND selected_user_id = @BatchUserId



RETURN


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[batchrev_sp] TO [public]
GO
