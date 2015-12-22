SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\archkinv.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[archkinv_sp] @x_posted_flag int
AS

DECLARE 	@acct_code 	char(32), 	@gl_acct_code 	varchar(32),
 	@tcn 	char(32), 	@trx_type 	int, 
 	@dcn 	char(32), 	@posting_code	char(8), 	
 	@process_id	int, 		@last_tcn	char(32),
 	@sq_id 	int, 	@result 	int,
 	@date_applied 	int,	@min_trx_ctrl_num	varchar(16),
 	@min_sequence_id	int

SET ROWCOUNT 0
select 	@result = 0, 	@tcn = ' '

SELECT @process_id = CONVERT(int, hostprocess )
 FROM master..sysprocesses
 WHERE spid = @@spid

DELETE 	aractst 
WHERE	proc_key = @process_id

WHILE(1 = 1)
BEGIN
	SELECT	@last_tcn = @tcn
 
 	SELECT	@min_trx_ctrl_num = MIN(trx_ctrl_num)
 	FROM 	arinppyt
 	WHERE 	posted_flag = @x_posted_flag
 	AND 	trx_ctrl_num > @last_tcn
 
 	SELECT @tcn = trx_ctrl_num, @trx_type = trx_type, @date_applied = date_applied
 	FROM 	arinppyt
 	WHERE 	posted_flag = @x_posted_flag
	AND 	trx_ctrl_num = @min_trx_ctrl_num
 
 

 IF ( @@rowcount = 0 )
 BREAK

 SELECT @sq_id = 0

 
 WHILE ( 1 = 1 )
 BEGIN
 
 	 SELECT @min_sequence_id = MIN(sequence_id)
	 FROM arinppdt
 WHERE trx_ctrl_num = @tcn
 AND trx_type = @trx_type
 AND sequence_id > @sq_id
		
	 SELECT @posting_code = posting_code, 	
	 @sq_id = sequence_id,
 @dcn = apply_to_num
 FROM arinppdt
 WHERE trx_ctrl_num = @tcn
 AND trx_type = @trx_type
 AND sequence_id = @min_sequence_id
 
	 

 IF ( @@rowcount = 0 ) BREAK
 
 EXEC @result = arvpcode_sp @process_id, @posting_code, @date_applied, 1
 
 
 IF ( @result > 0 )	BREAK
 ELSE
 CONTINUE
 END

 IF ( @result > 0 ) BREAK
 ELSE
 CONTINUE
END

DELETE 	aractst 
WHERE	proc_key = @process_id


IF ( @result > 0 )
 SELECT 1
ELSE
 SELECT 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[archkinv_sp] TO [public]
GO
