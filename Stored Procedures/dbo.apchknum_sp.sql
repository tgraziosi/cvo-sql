SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apchknum.SPv - e7.2.2 : 1.7
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





CREATE PROCEDURE [dbo].[apchknum_sp]
	@trx_ctrl_num char(16), @trx_type smallint, @cash_acct char(32),
	@next_check_num int, @print_batch_num int, @retry_flag smallint
AS

DECLARE @docnum char(16)

WHILE ( 1 = 1 )
BEGIN
	BEGIN TRAN

		SELECT @docnum = NULL

		SELECT @docnum = SUBSTRING(check_num_mask, 1,
			check_start_col -1) + RIGHT("0000000000000000" +
			RTRIM(LTRIM(STR(@next_check_num, 16, 0))),
			check_length)
		FROM apcash
		WHERE cash_acct_code = @cash_acct

		
		IF @docnum IS NULL
		BEGIN
			ROLLBACK TRAN
			RETURN
		END

	COMMIT TRAN

	

	BREAK
END

BEGIN TRAN

	
	UPDATE apinppyt
	SET doc_ctrl_num = @docnum,
		print_batch_num = @print_batch_num
	WHERE trx_ctrl_num = @trx_ctrl_num
	AND trx_type = @trx_type

	UPDATE apchkstb
	SET check_num = @docnum,
		print_batch_num = @print_batch_num,
		cash_acct_code = @cash_acct 
	WHERE payment_num = @trx_ctrl_num

 

	UPDATE apchkdsb
	SET check_num = @docnum,
		cash_acct_code = @cash_acct
	WHERE check_ctrl_num = @trx_ctrl_num
	
	UPDATE apexpdst
	SET check_num = @docnum,
		print_batch_num = @print_batch_num,
		cash_acct_code = @cash_acct 
	WHERE payment_num = @trx_ctrl_num

COMMIT TRAN 



GO
GRANT EXECUTE ON  [dbo].[apchknum_sp] TO [public]
GO
