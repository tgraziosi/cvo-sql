SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glproclg.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[glproclg_sp]
	@kp_id		int,
	@user_id	smallint,
	@client_id	smallint,
	@ctrl_num	varchar(16),
	@document_1	varchar(16)=NULL,
	@document_2	varchar(30)=NULL,
	@char_parm_1 	varchar(40)=NULL,
	@char_parm_2	varchar(40)=NULL,
	@char_parm_3	varchar(128)=NULL,
	@float_parm_1	float	 =NULL,	
	@float_parm_2	float	 =NULL,	
	@float_parm_3	float	 =NULL,	
	@int_parm_1	int	 =NULL,	
	@int_parm_2	int	 =NULL,	
	@int_parm_3	int	 =NULL,	
	@sint_parm_1	smallint =0,	
	@sint_parm_2	smallint =0,	
	@sint_parm_3	smallint =0,
	@float_parm_4	float	 =NULL,	
	@float_parm_5	float	 =NULL	

AS DECLARE
	@sys_date 	 int 	

	
	EXEC appdate_sp @sys_date OUTPUT

	
	INSERT glproclg VALUES (
	 NULL,	 @kp_id,	 @user_id,	 @client_id,	 
	 @ctrl_num,	 getdate(),	 @sys_date, @document_1,	 
	 @document_2,	 @char_parm_1, @char_parm_2, @char_parm_3, 
	 @float_parm_1, @float_parm_2, @float_parm_3, @int_parm_1,	 
	 @int_parm_2,	 @int_parm_3,	 @sint_parm_1, @sint_parm_2, 
	 @sint_parm_3, @float_parm_4, @float_parm_5)

RETURN 0


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glproclg_sp] TO [public]
GO
