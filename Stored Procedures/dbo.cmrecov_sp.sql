SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\CM\PROCS\cmrecov.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 






































































































































































































































































































































































































































































































































































































 







































CREATE PROCEDURE [dbo].[cmrecov_sp]	@process_group_num	varchar(16), 
							@batch_code			varchar(16),
							@debug smallint
AS

DECLARE @batch_proc_flag	smallint,
 @process_type		smallint,
		@trx_ctrl_num 		varchar(16),
		@result 			smallint



SELECT @process_type = process_type
FROM pcontrol_vw
WHERE process_ctrl_num = @process_group_num


 
SELECT @batch_proc_flag = batch_proc_flag FROM cmco


IF @process_type = 7010
 BEGIN



	IF (@batch_proc_flag = 0)
		UPDATE cmmanhdr
		SET posted_flag = 0,
		 process_group_num = '',
			batch_code = ''
		WHERE process_group_num = @process_group_num
		AND (batch_code = @batch_code
			 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))
	ELSE
		UPDATE cmmanhdr
		SET posted_flag = 0,
	 	process_group_num = ''
		WHERE process_group_num = @process_group_num
		AND (batch_code = @batch_code
			 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))
		
 

 END



IF @process_type = 7030
 BEGIN



	IF (@batch_proc_flag = 0)
		UPDATE cminpbtr
		SET posted_flag = 0,
		 process_group_num = '',
			batch_code = ''
		WHERE process_group_num = @process_group_num
		AND (batch_code = @batch_code
			 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))
	ELSE
		UPDATE cminpbtr
		SET posted_flag = 0,
	 	process_group_num = ''
		WHERE process_group_num = @process_group_num
		AND (batch_code = @batch_code
			 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))
		
 

 END


IF (@batch_proc_flag = 0)
			UPDATE batchctl
			SET void_flag = 1,
			 posted_flag = 0
			WHERE process_group_num = @process_group_num
			AND (batch_ctrl_num = @batch_code
				 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))
			AND posted_flag = -1
			AND batch_type BETWEEN 7000 AND 8000
		ELSE
			BEGIN
				UPDATE batchctl
				SET posted_flag = 0,
				 process_group_num = ''
				WHERE process_group_num = @process_group_num
				AND (batch_ctrl_num = @batch_code
					 OR ( LTRIM(@batch_code) IS NULL OR LTRIM(@batch_code) = " " ))
				AND posted_flag = -1

		 	END

RETURN 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[cmrecov_sp] TO [public]
GO
