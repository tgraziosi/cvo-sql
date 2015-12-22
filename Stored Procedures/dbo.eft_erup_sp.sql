SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_erup.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




 
CREATE PROCEDURE [dbo].[eft_erup_sp]
@e_code	 int ,
@char_parm1 varchar(12),
@char_parm2 varchar(8) 

AS




DECLARE 

	 @seq_id int,
		@user_id smallint,
		@time datetime



	SELECT @user_id 			= user_id(),
	 @time 			= getdate()
		 


	SELECT @seq_id = max(seq_id)
 FROM eft_errlst

 IF @seq_id IS NULL
 SELECT @seq_id = 0
		ELSE
		SELECT @seq_id = @seq_id + 1

	
		INSERT eft_errlst 
 
 		(seq_id ,client_id, user_id, e_code, time, char_parm_1,
 		char_parm_2 ,e_ldesc)
 
 		SELECT
 		@seq_id,client_id,@user_id , @e_code, @time,
 		@char_parm1,@char_parm2,e_ldesc
 		FROM aperrdef
 		WHERE e_code = @e_code

GO
GRANT EXECUTE ON  [dbo].[eft_erup_sp] TO [public]
GO
