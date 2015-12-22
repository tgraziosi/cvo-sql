SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apbatnum.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





CREATE PROCEDURE [dbo].[apbatnum_sp]
	@batch_flag smallint OUTPUT, 	
	@batch_ctrl_num char(16) OUTPUT 	
as
declare
	@ap_batch_proc_flag 	smallint,	
	@next_batch_ctrl_num	varchar(16),	
	@batch_ctrl_num_mask	varchar(16),	
	@mask_len		int,
	@num_len		int,
	@zero_pos		int,
	@pound_pos		int,
	@stuff_pos		int
	
	
	SELECT @batch_ctrl_num = " "
	SELECT @batch_flag = -1
	
	
	SELECT @ap_batch_proc_flag = batch_proc_flag		
	FROM apco

	IF (@@ROWCOUNT = 0) 			
		RETURN

	SELECT @batch_flag = @ap_batch_proc_flag
	IF (@batch_flag = 0)					
		RETURN

	
	UPDATE apnumber
	SET next_batch_ctrl_num = next_batch_ctrl_num + 1

	IF (@@ROWCOUNT = 0)					
	BEGIN
		SELECT @batch_flag = -2
		RETURN
	END

	SELECT @next_batch_ctrl_num = convert(varchar(16),next_batch_ctrl_num - 1),
	 @batch_ctrl_num_mask = batch_ctrl_num_mask
	FROM apnumber

	IF (@@ROWCOUNT = 0)					
	BEGIN
		SELECT @batch_flag = -3
		RETURN
	END

	
	SELECT @mask_len = datalength(rtrim(@batch_ctrl_num_mask))
	SELECT @num_len = datalength(rtrim(@next_batch_ctrl_num))
	
	
	SELECT @zero_pos = charindex("0",@batch_ctrl_num_mask)
	IF(@zero_pos > 0)
	BEGIN
		SELECT @stuff_pos = @zero_pos +
			(@mask_len - (@zero_pos - 1) - @num_len)
		IF(@stuff_pos >= @zero_pos)
		 	SELECT @batch_ctrl_num = rtrim(stuff(@batch_ctrl_num_mask,
			 @stuff_pos, @num_len, @next_batch_ctrl_num))
		ELSE
		BEGIN	
		 	SELECT @batch_flag = -4
			RETURN
		END
	END
	ELSE
	BEGIN
		SELECT @pound_pos = charindex("#",@batch_ctrl_num_mask)
		IF(@pound_pos > 0)
		BEGIN
			IF((@mask_len - @pound_pos + 1) >= @num_len)
				SELECT @batch_ctrl_num =
			 	 substring(@batch_ctrl_num_mask, 1, @pound_pos - 1)
			 	 + @next_batch_ctrl_num
			ELSE
			BEGIN
				SELECT @batch_flag = -5
				RETURN
			END
		END
		ELSE
			SELECT @batch_ctrl_num = @batch_ctrl_num_mask +
					@next_batch_ctrl_num
	END

	




GO
GRANT EXECUTE ON  [dbo].[apbatnum_sp] TO [public]
GO
