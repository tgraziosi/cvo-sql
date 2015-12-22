SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                














CREATE PROCEDURE [dbo].[gltcReconSetUnhold_sp] @trx_ctrl_num varchar(16), @trx_type int, @new_hold_flag int
AS
BEGIN
	IF (@trx_type in (4091,4092))
	BEGIN
		if exists(select 1 from apinpchg 
				where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
				and hold_flag = 1)
			UPDATE apinpchg SET hold_flag = @new_hold_flag 
			WHERE trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
	END
	
	IF (@trx_type in (2031,2032))
	BEGIN
		if exists(select 1 from arinpchg 
				where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
				and hold_flag = 1)
			UPDATE arinpchg SET hold_flag = @new_hold_flag 
			WHERE trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
	END
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[gltcReconSetUnhold_sp] TO [public]
GO
