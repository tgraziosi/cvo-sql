SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glgetpid.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[glgetpid_sp]	@select_output	smallint = 0

AS DECLARE
	@process_id	int

SELECT	@process_id = 0

SELECT	@process_id = spid + CONVERT( int, CONVERT( varbinary(4), hostprocess )) + kpid
FROM	master..sysprocesses
WHERE	spid = @@spid

IF ( @select_output = 1 )
	SELECT	@process_id

RETURN @process_id




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glgetpid_sp] TO [public]
GO
