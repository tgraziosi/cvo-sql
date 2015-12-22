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















CREATE PROCEDURE [dbo].[gltcGetLocalStatus_sp] @trx_ctrl_num varchar(16), @trx_type int, @posted_flag int OUTPUT, @UpdateRecon_flag int = 0
AS
BEGIN
	






	
	IF (@trx_type = 4091)
	BEGIN
		select @posted_flag = 1 from apvohdr where trx_ctrl_num = @trx_ctrl_num 
		if @@rowcount > 0
			GOTO SetValueLabel
	END
	ELSE IF (@trx_type = 4092)
	BEGIN
		select @posted_flag = 1 from apdmhdr where trx_ctrl_num = @trx_ctrl_num 
		if @@rowcount > 0
			GOTO SetValueLabel
	END
	IF (@trx_type in (4091,4092))
	BEGIN
		select @posted_flag = 0 from apinpchg where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
		if @@rowcount > 0
			GOTO SetValueLabel
		else
		begin
			select @posted_flag = 2
			GOTO SetValueLabel 
		end
	END
	
	IF (@trx_type in (2031,2032))
	BEGIN
		select @posted_flag = 1 from artrx where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
		if @@rowcount > 0
			GOTO SetValueLabel

		select @posted_flag = 0 from arinpchg where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
		if @@rowcount > 0
			GOTO SetValueLabel
		else
		begin
			select @posted_flag = 2
			GOTO SetValueLabel
		end			
	END

SetValueLabel:
	IF ( @UpdateRecon_flag = 1 )
	BEGIN
		IF exists(select 1 from gltcrecon 
					where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
					and posted_flag != @posted_flag)
		UPDATE gltcrecon SET posted_flag = @posted_flag WHERE trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
	END
		
END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[gltcGetLocalStatus_sp] TO [public]
GO
