SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\date2str.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[date2str_sp] ( @aDate int, @result_str varchar(12) OUTPUT)
AS
	DECLARE @mm int, @dd int, @yy int
	IF ( @aDate < 0 )
	BEGIN
		SELECT	@result_str = convert(varchar, @aDate)
		RETURN
	END

	EXEC	appdtjul_sp @yy OUTPUT, @mm OUTPUT, @dd OUTPUT, @aDate

	SELECT	@result_str = convert(varchar, @mm) + "-" + convert(varchar, @dd) + "-" + convert(varchar, @yy)

RETURN


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[date2str_sp] TO [public]
GO
