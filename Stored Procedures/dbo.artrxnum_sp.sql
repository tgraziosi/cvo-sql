SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\artrxnum.SPv - e7.2.2 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                










 



					 










































 




























































































































































































































































CREATE PROC [dbo].[artrxnum_sp]	@trx_type 		smallint,
						@trx_ctrl_num 	varchar(16) OUTPUT, 
						@err_num 		smallint OUTPUT
AS

DECLARE	@mask_str	varchar(16),
		@trx_num	varchar(16),
		@num		int,
		@num_type	int
	
	



	IF(@trx_type = 2031)
		SELECT @num_type = 2000
	ELSE
		SELECT @num_type = 2000

	EXEC @err_num = ARGetNextControl_SP	@num_type,
										@trx_num OUTPUT,
										@num OUTPUT

	IF @err_num != 0
		RETURN

	
	IF EXISTS( SELECT trx_ctrl_num 
			 FROM arinpchg
			 WHERE trx_ctrl_num = @trx_num
				 )
		SELECT @err_num = -18
	ELSE

		IF EXISTS( SELECT trx_ctrl_num 
		 FROM artrx
			 	 WHERE trx_ctrl_num = @trx_num
					)
			SELECT @err_num = -19
		ELSE
			SELECT @trx_ctrl_num = @trx_num


	RETURN



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[artrxnum_sp] TO [public]
GO
