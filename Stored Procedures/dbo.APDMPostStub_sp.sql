SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apdmps.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 




























































































































































































































































CREATE PROCEDURE [dbo].[APDMPostStub_sp]	
	@batch_ctrl_num		varchar(16),	
	@proc_group_num		varchar(16),	
	@posted_user		varchar(30),
	@proc_user_id		smallint,
	@debug_level		smallint = 0			

AS

DECLARE
	@result	smallint

	SELECT	@result = 0	

	


RETURN @result
GO
GRANT EXECUTE ON  [dbo].[APDMPostStub_sp] TO [public]
GO