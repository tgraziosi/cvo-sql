SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[nbinsertnbtrxlog_sp] @proc_ctrl_num varchar(16), @net_ctrl_num varchar(16), @step varchar(8) ,@substep smallint, @trx_ctrl_num varchar(16)	

AS
	
Insert into nbtrxlog
	(proc_ctrl_num,
	net_ctrl_num ,
	log_description,
	step ,
	substep,
	error,
	trx_ctrl_num)
select @proc_ctrl_num,
	isnull(@net_ctrl_num,''),
	log_description + @trx_ctrl_num,
	step,
	substep,
	error,
	@trx_ctrl_num
From nbtrxlogdesc
Where step = @step
and substep = @substep


RETURN   0  


GO
GRANT EXECUTE ON  [dbo].[nbinsertnbtrxlog_sp] TO [public]
GO
