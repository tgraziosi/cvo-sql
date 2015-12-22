SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glputerr.SPv - e7.2.2 : 1.7
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[glputerr_sp]
 @client_id char(20),
 @user_id int,
 @e_code int,
 @filename varchar(32)=NULL,
 @linenum int =NULL,
 @char_parm_1 varchar(80)=NULL,
 @char_parm_2 varchar(80)=NULL,
 @int_parm_1 int =NULL,
 @int_parm_2 int =NULL

AS DECLARE
 @seq_id int, 
 @e_level int, 
 @active smallint, 
	@sys_date 	 int 	


SELECT @e_level = NULL,
 @active = NULL,
 @seq_id = NULL


SELECT @seq_id = max(seq_id) + 1
FROM glerrlst

IF (@seq_id IS NULL)
 SELECT @seq_id = 1


IF NOT EXISTS
 (SELECT e_code 
 FROM glerrdef
 WHERE e_code = @e_code
 AND client_id = @client_id )
BEGIN
 SELECT	@char_parm_2 = "Invalid error code from client: "+ rtrim( @client_id ) +
				" Error code: "+ CONVERT( char(5), @e_code ),
		@int_parm_1 = @e_code
	SELECT	@e_code = 0,
		@char_parm_1 = NULL,
		@int_parm_2 = NULL
END

SELECT @active = e_active, @e_level = e_level
FROM glerrdef
WHERE e_code = @e_code


EXEC appdate_sp @sys_date output



IF ( @active = 1 and @e_level != 0 )
 INSERT glerrlst (	timestamp,
			seq_id,
			proc_id,
			client_id,
			user_id,
			e_code,
			time,
			date_entered,
			filename,
			linenum,
			char_parm_1,
			char_parm_2,
			int_parm_1,
			int_parm_2 )
 VALUES (		NULL,
		 @seq_id, 
			@@spid,
			@client_id,
			@user_id,
			@e_code, 
			getdate(),
			@sys_date,
			@filename,
			@linenum,
			@char_parm_1,
			@char_parm_2,
			@int_parm_1,
			@int_parm_2) 

 
RETURN @e_level





/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glputerr_sp] TO [public]
GO
