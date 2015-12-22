SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apvdspch.SPv - e7.2.2 : 1.17
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                











 



					 










































 




























































































































































































































































CREATE PROCEDURE [dbo].[apvdspch_sp]
	@cash_acct varchar(32), @from_check int, 
	@last_check int, 	 @sys_date int,
	@user_id smallint, 	 @x_posted_flag smallint
AS


DECLARE @next_check 	int, 		@doc_num		varchar(16),
		@int_holder 	int, 		@check_len int, 
		@char_holder 	varchar(80),	@company_code 	varchar(8),
		@from_check_save 	int



Select @company_code = company_code from glco

	SELECT @int_holder = check_start_col,
		@check_len = check_length,
		@char_holder = check_num_mask,
		@next_check = next_check_num
	FROM apcash
	WHERE cash_acct_code = @cash_acct

	SELECT @from_check_save = @from_check

BEGIN TRAN

WHILE ( @from_check <= @last_check )
BEGIN


	
	SELECT @doc_num = SUBSTRING( @char_holder, 1, @int_holder - 1 )
	 + RIGHT("0000000000000000" +
	 RTRIM( LTRIM( STR( @from_check, 16, 0 ) ) ), @check_len )

	
	IF NOT EXISTS( SELECT trx_ctrl_num FROM appyhdr
	 WHERE doc_ctrl_num = @doc_num AND
	 cash_acct_code = @cash_acct )
	 AND NOT EXISTS(SELECT trx_ctrl_num FROM apvchdr
	 WHERE doc_ctrl_num = @doc_num AND
	 cash_acct_code = @cash_acct ) 
	 AND NOT EXISTS
	 ( SELECT trx_ctrl_num FROM apinppyt WHERE doc_ctrl_num = @doc_num
	 AND trx_type = 4111 AND cash_acct_code = @cash_acct )
	BEGIN
	 INSERT apvchdr (
					trx_ctrl_num,
					doc_ctrl_num,
					batch_code,
					date_applied,
					date_doc,
					date_entered,
					vendor_code,
					pay_to_code,
					cash_acct_code,
					payment_code,
					state_flag,
					void_flag,
					amt_net,
					amt_discount,
					user_id,
					print_batch_num,
					process_ctrl_num,
					currency_code
					)
	 VALUES (
	 @doc_num,
	 @doc_num,
		 "",
 	 @sys_date, 
	 @sys_date, 
	 @sys_date,
	 " ", 
	 " ",
	 @cash_acct, 
	 "VDSPCHK",
	 @x_posted_flag,
	 4,
	 0.0,
	 0.0,
	 @user_id,
	 0,
		 "",
		 ""
		 )
	END

	
	SELECT @from_check = @from_check + 1
END


	
	IF ((@next_check <= @last_check) AND (@next_check >= @from_check_save))
		UPDATE apcash
		SET next_check_num = @last_check + 1
 WHERE cash_acct_code = @cash_acct

COMMIT TRAN

GO
GRANT EXECUTE ON  [dbo].[apvdspch_sp] TO [public]
GO
