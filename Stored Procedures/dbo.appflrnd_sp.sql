SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\appflrnd.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC	[dbo].[appflrnd_sp]	@round_num float OUT, 
				@precision smallint = NULL,
				@option smallint = NULL
AS

IF @round_num IS NULL
BEGIN
	SELECT @round_num = 0
	RETURN
END

IF @option IS NULL
BEGIN
	IF @precision IS NULL
		SELECT @round_num = ROUND( @round_num, 2 )
	ELSE
		SELECT @round_num = ROUND( @round_num, @precision )
END
	


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appflrnd_sp] TO [public]
GO
