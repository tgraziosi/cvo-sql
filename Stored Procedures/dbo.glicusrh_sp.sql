SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glicusrh.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                
















 



					 










































 







































































































































































































































































 




























CREATE PROCEDURE	[dbo].[glicusrh_sp]	
			@process_ctrl_num	varchar(16),
			@org_company_code	varchar(8),
			@rec_company_code	varchar(8),
			@journal_ctrl_num	varchar(16),
			@new_journal_ctrl_num	varchar(16)
AS

BEGIN
	

	RETURN	0

	
END



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glicusrh_sp] TO [public]
GO