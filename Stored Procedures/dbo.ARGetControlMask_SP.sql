SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\argcm.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                

 








 



					 










































 








































































































































































































































































































































































































































































































CREATE PROCEDURE [dbo].[ARGetControlMask_SP] 	@num_type int, 
										@mask varchar(35) output, 
										@debug_level int = 0
										
AS

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argcm.sp" + ", line " + STR( 43, 5 ) + " -- ENTRY: "



	SELECT	@mask = rtrim(mask)
	FROM 	ewnumber
	WHERE 	num_type = @num_type

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/argcm.sp" + ", line " + STR( 53, 5 ) + " -- EXIT: "
		
	RETURN 0

END 

GO
GRANT EXECUTE ON  [dbo].[ARGetControlMask_SP] TO [public]
GO
