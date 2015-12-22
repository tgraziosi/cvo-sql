SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apactsum.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 




























































































































































































































































CREATE PROC [dbo].[apactsum_sp]		@apactvnd	smallint,
					@apactpto	smallint,
					@apactbch	smallint,
					@apactcls	smallint,
					@apsumvnd	smallint,
					@apsumpto	smallint,
					@apsumbch	smallint,
					@apsumcls	smallint,
					@apsumvi	smallint
 	 
AS


	IF( @apactvnd = 1 )
 	BEGIN
 		EXEC apuavnd_sp 
		END

	IF( @apactpto = 1 )
 	BEGIN
	 	EXEC apuapto_sp 
 	END

	IF( @apactbch = 1 )
 	BEGIN
	 	EXEC apuabch_sp 
 	END
 	 	
	IF( @apactcls = 1 )
 	BEGIN
	 	EXEC apuacls_sp 
 	END
	IF( @apsumvnd = 1 )
 	BEGIN
	 	EXEC apusvnd_sp 
 	END

	IF( @apsumpto = 1 )
 	BEGIN
	 	EXEC apuspto_sp 
 	END
 	
	IF( @apsumbch = 1 )
 	BEGIN
	 	EXEC apusbch_sp 
 	END
 	
	IF( @apsumcls = 1 )
 	BEGIN
	 	EXEC apuscls_sp 
 	END
GO
GRANT EXECUTE ON  [dbo].[apactsum_sp] TO [public]
GO
