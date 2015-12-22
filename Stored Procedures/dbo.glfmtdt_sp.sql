SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glfmtdt.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[glfmtdt_sp]
 	@jul_date	int,
		@jul_date_fmt	varchar(24) OUTPUT


AS 

DECLARE		@year	smallint,
		@month	smallint,
		@day	smallint

BEGIN


	EXEC	appdtjul_sp	@year OUTPUT,
				@month	OUTPUT,
				@day	OUTPUT,
				@jul_date
	
	SELECT	@jul_date_fmt = LTRIM(RTRIM(STR(@month))) + "/"+
				LTRIM(RTRIM(STR(@day))) + "/" +
				LTRIM(RTRIM(STR(@year)))
 	RETURN 0
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glfmtdt_sp] TO [public]
GO
