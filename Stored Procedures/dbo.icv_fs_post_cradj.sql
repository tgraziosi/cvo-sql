SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                









CREATE PROCEDURE [dbo].[icv_fs_post_cradj] @user VARCHAR(10), @process_ctrl_num VARCHAR(16), @err int OUT AS 

DECLARE @rowcount	int
DECLARE @result		int
DECLARE @user_id	int
DECLARE	@precision_gl	smallint
DECLARE @buf		char(255)

DECLARE @order_ctrl_num	char(16)
DECLARE @cm_order_ctrl_num 	char(16)
DECLARE @trx_ctrl_num	char(16)
DECLARE @cm_trx_ctrl_num	char(16)
DECLARE @cr_trx_ctrl_num	char(16)
DECLARE @new_ctrl_num	char(16)
DECLARE @new_ctrl_num2	char(16)
DECLARE @doc_ctrl_num	char(16)
DECLARE @input_tables	int
DECLARE @inv_input_table	int
DECLARE @cm_input_table		int
DECLARE @cust_code	char(10)
DECLARE @order_no	int
DECLARE @ext		int
DECLARE	@orig_no	int
DECLARE @orig_ext	int
DECLARE @amt_payment	float
DECLARE @amt_of_return	float
DECLARE @inv_rate_home	float
DECLARE @inv_rate_oper	float

DECLARE @date_entered	int
DECLARE @date_applied	int
DECLARE @date_doc	int
DECLARE @payment_code	char(8)
DECLARE @payment_type	int
DECLARE @prompt1_inp	char(30)
DECLARE @prompt2_inp	char(30)
DECLARE @prompt3_inp	char(30)
DECLARE @prompt4_inp	char(30)
DECLARE @deposit_num	char(16)
DECLARE @cash_acct_code	char(32)
DECLARE @nat_cur_code	char(8)
DECLARE @rate_type_home	char(8)
DECLARE @rate_type_oper	char(8)
DECLARE	@rate_home	float
DECLARE	@rate_oper	float
DECLARE	@amt_discount	float
DECLARE	@reference_code	char(32)

DECLARE @apply_to_num	char(16)
DECLARE @apply_trx_type	int
DECLARE @date_aging	int
DECLARE @new_amt_applied	float
DECLARE @amt_applied	float
DECLARE @amt_disc_taken	float
DECLARE @wr_off_flag	int
DECLARE @amt_max_wr_off	float
DECLARE @void_flag	int
DECLARE	@line_desc	char(40)
DECLARE @sub_apply_num	char(16)
DECLARE @sub_apply_type	int
DECLARE @amt_tot_chg	float
DECLARE @amt_paid_to_date	float
DECLARE @terms_code	char(8)
DECLARE @posting_code	char(8)
DECLARE @amt_inv	float
DECLARE @gain_home	float
DECLARE @gain_oper	float
DECLARE @new_inv_amt_applied	float
DECLARE @inv_amt_applied	float
DECLARE @inv_amt_max_wr_off	float
DECLARE @inv_cur_code	char(8)
DECLARE @inv_amt_disc_taken	float

DECLARE @new_gain_home	float
DECLARE @new_gain_oper	float




DECLARE @batch_proc_flag	SMALLINT
DECLARE @batch_code		CHAR(16)
DECLARE @company_code		CHAR(8)
DECLARE	@LogActivity		CHAR(3)
DECLARE @complete_date		INT
DECLARE @complete_time		INT
DECLARE @complete_user		CHAR(30)
DECLARE @batch_description	CHAR(30)
DECLARE @adm_org_id VARCHAR(30)

SET NOCOUNT ON


SELECT @buf = UPPER(configuration_text_value)
  FROM icv_config
 WHERE UPPER(configuration_item_name) = 'LOG ACTIVITY'

IF @@rowcount <> 1
	SELECT @buf = 'NO'

IF @buf = 'YES'
BEGIN
	SELECT @LogActivity = 'YES'
END
ELSE
BEGIN
	SELECT @LogActivity = 'NO'
END

SELECT @buf = 'Entering icv_fs_post_cradj'
EXEC icv_Log_sp @buf, @LogActivity
SELECT @buf = '@user = ' + @user
EXEC icv_Log_sp @buf, @LogActivity
SELECT @buf = '@process_ctrl_num = ' + @process_ctrl_num
EXEC icv_Log_sp @buf, @LogActivity
SELECT @buf = 'spid = ' + CONVERT(CHAR,@@spid)
EXEC icv_Log_sp @buf, @LogActivity

SELECT @user_id = user_id
  FROM glusers_vw
 WHERE LOWER(user_name) = LOWER(@user)

IF @user_id IS NULL 
BEGIN
	SELECT @user_id = 1
END

SELECT @precision_gl = 2
SELECT @precision_gl = curr_precision
  FROM glco, glcurr_vw
 WHERE glco.home_currency = glcurr_vw.currency_code




SELECT @batch_proc_flag = batch_proc_flag 
  FROM arco

SELECT @company_code = company_code
  FROM glcomp_vw, arco
 WHERE glcomp_vw.company_id = arco.company_id

SELECT 	@complete_date = DATEDIFF(DD, '1/1/80', CONVERT(DATETIME,GETDATE()))+722815,
	@complete_time = DATEPART(HH,GETDATE())*3600 + DATEPART(MI,GETDATE())*60 + DATEPART(SS,GETDATE()),
	@complete_user = SUSER_NAME()

DECLARE cradj_cursor CURSOR FOR 
   SELECT a.order_no, a.ext, a.orig_no, a.orig_ext, a.cust_code, a.organization_id
     FROM orders AS a, icv_orders AS b
    WHERE a.process_ctrl_num = @process_ctrl_num
      AND a.status = 'T'				
      AND a.type = 'C'					
      AND a.order_no = b.order_no
      AND a.ext = b.ext
      AND ISNULL(b.cr_adj_status,'') not in ('I','E','T')		

OPEN cradj_cursor
FETCH NEXT FROM cradj_cursor INTO @order_no, @ext, @orig_no, @orig_ext, @cust_code, @adm_org_id
				
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	IF @@FETCH_STATUS <> -2
	BEGIN
		UPDATE icv_orders
		   SET cr_adj_status = 'I', cr_adj_error = 0000
		 WHERE order_no = @order_no
		   AND ext = @ext

		SELECT @order_ctrl_num = RTRIM(LTRIM(CONVERT(CHAR, @orig_no))) + '-' + RTRIM(LTRIM(CONVERT(CHAR, @orig_ext)))
		SELECT @cm_order_ctrl_num = RTRIM(LTRIM(CONVERT(CHAR, @order_no))) + '-' + RTRIM(LTRIM(CONVERT(CHAR, @ext)))

		SELECT @amt_of_return = ord_amt
		  FROM icv_ord_payment_dtl
		 WHERE order_no = @order_no
		   AND ext = @ext
		   AND auth_sequence = (SELECT MAX(auth_sequence) 
					  FROM icv_ord_payment_dtl 
					 WHERE order_no = @order_no
					   AND ext = @ext
					   AND response_flag = 'C')

		




		


		SELECT @trx_ctrl_num = ''
		SELECT @trx_ctrl_num = trx_ctrl_num,
			@inv_rate_home = rate_home,
			@inv_rate_oper = rate_oper,
			@amt_tot_chg = amt_net,
			@amt_inv = amt_net,
			@inv_input_table = 1
		  FROM arinpchg
		 WHERE order_ctrl_num = @order_ctrl_num
		   AND customer_code = @cust_code
		   AND trx_type = 2031

		IF @trx_ctrl_num = ''
		BEGIN
			SELECT @trx_ctrl_num = trx_ctrl_num,
				@inv_rate_home = rate_home,
				@inv_rate_oper = rate_oper,
				@amt_inv = amt_net,
				@amt_tot_chg = amt_tot_chg,
				@inv_input_table = 0
			  FROM artrx
			 WHERE order_ctrl_num = @order_ctrl_num
			   AND customer_code = @cust_code
			   AND trx_type = 2031
		END

		


		IF @trx_ctrl_num = ''
		BEGIN
			UPDATE icv_orders
			   SET cr_adj_status = 'E', cr_adj_error = 0010
			 WHERE order_no = @order_no
			   AND ext = @ext
			GOTO FETCHNEXT
		END

		


		SELECT @cm_trx_ctrl_num = ''
		SELECT @cm_trx_ctrl_num = trx_ctrl_num,
			@cm_input_table = 1
		  FROM arinpchg
		 WHERE order_ctrl_num = @cm_order_ctrl_num
		   AND customer_code = @cust_code
		   AND trx_type = 2032

		IF @cm_trx_ctrl_num = ''
		BEGIN
			SELECT @cm_trx_ctrl_num = trx_ctrl_num,
				@cm_input_table = 0
			  FROM artrx
			 WHERE order_ctrl_num = @cm_order_ctrl_num
			   AND customer_code = @cust_code
			   AND trx_type = 2032
		END

		


		IF @cm_trx_ctrl_num = ''
		BEGIN
			UPDATE icv_orders
			   SET cr_adj_status = 'E', cr_adj_error = 0020 -- was 0011
			 WHERE order_no = @order_no
			   AND ext = @ext
			GOTO FETCHNEXT
		END



		



 
		DELETE icv_crtemp
		 WHERE spid = @@spid

		INSERT INTO icv_crtemp
		  SELECT @@spid, doc_ctrl_num, 0, 0
		    FROM artrx
		   WHERE source_trx_ctrl_num = @trx_ctrl_num
		     AND customer_code = @cust_code
		     AND trx_type = 2111
		     AND void_flag = 0

		INSERT INTO icv_crtemp
		  SELECT @@spid, doc_ctrl_num, 0, 1
		    FROM arinptmp
		   WHERE trx_ctrl_num = @trx_ctrl_num
		     AND customer_code = @cust_code

		INSERT INTO icv_crtemp
		  SELECT @@spid, doc_ctrl_num, 0, 2
		    FROM arinppyt
		   WHERE source_trx_ctrl_num = @trx_ctrl_num
		     AND customer_code = @cust_code

		UPDATE icv_crtemp 
		   SET flg = 1
		  FROM icv_crtemp a, arinppyt b
		 WHERE a.doc_ctrl_num = b.doc_ctrl_num
		   AND b.trx_type = 2121
		   AND customer_code = @cust_code
		   AND source_trx_ctrl_num = @trx_ctrl_num
		   AND spid = @@spid

		SELECT @doc_ctrl_num = ''
		SELECT @doc_ctrl_num = doc_ctrl_num,
			@input_tables = input_tables
		  FROM icv_crtemp
		 WHERE flg = 0
		   AND spid = @@spid

		SELECT @rowcount = @@rowcount

		


		IF @doc_ctrl_num = ''
		BEGIN
			UPDATE icv_orders
			   SET cr_adj_status = 'E', cr_adj_error = 0030 -- was 0020
			 WHERE order_no = @order_no
			   AND ext = @ext
			GOTO FETCHNEXT
		END

		


		IF @rowcount > 1
		BEGIN
			UPDATE icv_orders
			   SET cr_adj_status = 'E', cr_adj_error = 0040 -- was 0030
			 WHERE order_no = @order_no
			   AND ext = @ext
			GOTO FETCHNEXT
		END


		







		IF @input_tables > 0
		BEGIN
			IF @input_tables = 1
			BEGIN
				SELECT @amt_payment = amt_payment
				  FROM arinptmp
				 WHERE doc_ctrl_num = @doc_ctrl_num
				   AND customer_code = @cust_code
			END

			IF @input_tables = 2
			BEGIN
				SELECT @amt_payment = amt_payment
				  FROM arinppyt
				 WHERE doc_ctrl_num = @doc_ctrl_num
				   AND customer_code = @cust_code
			END
		

			


			IF ROUND(@amt_of_return,@precision_gl) > ROUND(@amt_payment,@precision_gl)
			BEGIN
				UPDATE icv_orders
				   SET cr_adj_status = 'E', cr_adj_error = 0050 -- was 0040
				 WHERE order_no = @order_no
				   AND ext = @ext
				GOTO FETCHNEXT
			END

			BEGIN TRANSACTION

			SELECT @buf = CONVERT(CHAR,ROUND(@amt_of_return,@precision_gl)) + ' = ' + CONVERT(CHAR,ROUND(@amt_payment,@precision_gl))
			EXEC icv_Log_sp @buf, @LogActivity

			IF ROUND(@amt_of_return,@precision_gl) = ROUND(@amt_payment,@precision_gl)
			BEGIN
				IF @input_tables = 1
				BEGIN
					DELETE arinptmp
					 WHERE doc_ctrl_num = @doc_ctrl_num
					   AND customer_code = @cust_code
					   AND trx_ctrl_num = @trx_ctrl_num
				END

				IF @input_tables = 2
				BEGIN
					DELETE arinppyt
					 WHERE doc_ctrl_num = @doc_ctrl_num
					   AND customer_code = @cust_code
					   AND source_trx_ctrl_num = @trx_ctrl_num
				END
			END
			ELSE
			BEGIN
				IF @input_tables = 1
				BEGIN
					UPDATE arinptmp
					   SET amt_payment = ROUND(@amt_payment,@precision_gl) - ROUND(@amt_of_return,@precision_gl)
					 WHERE doc_ctrl_num = @doc_ctrl_num
					   AND customer_code = @cust_code
					   AND trx_ctrl_num = @trx_ctrl_num
				END

				IF @input_tables = 2
				BEGIN
					UPDATE arinppyt
					   SET amt_payment = ROUND(@amt_payment,@precision_gl) - ROUND(@amt_of_return,@precision_gl)
					 WHERE doc_ctrl_num = @doc_ctrl_num
					   AND customer_code = @cust_code
					   AND source_trx_ctrl_num = @trx_ctrl_num
				END
			END

			UPDATE icv_orders
			   SET cr_adj_status = 'T', cr_adj_error = 0000
			 WHERE order_no = @order_no
			   AND ext = @ext

			COMMIT TRANSACTION
		END

		





		IF @input_tables = 0
		BEGIN
			SELECT @amt_payment = amt_net
			  FROM artrx
			 WHERE doc_ctrl_num = @doc_ctrl_num
			   AND customer_code = @cust_code
			   AND trx_type = 2111

			


			IF ROUND(@amt_of_return,@precision_gl) > ROUND(@amt_payment,@precision_gl)
			BEGIN
				UPDATE icv_orders
				   SET cr_adj_status = 'E', cr_adj_error = 0050 -- was 0060
				 WHERE order_no = @order_no
				   AND ext = @ext
				GOTO FETCHNEXT
			END


			


			IF ROUND(@amt_of_return,@precision_gl) = ROUND(@amt_payment,@precision_gl)
			BEGIN
				SELECT @buf = CONVERT(CHAR,ROUND(@amt_of_return,@precision_gl)) + ' = ' + CONVERT(CHAR,ROUND(@amt_payment,@precision_gl))	
				EXEC icv_Log_sp @buf, @LogActivity
				EXEC @result = arnewnum_sp 2121, @new_ctrl_num OUTPUT
				IF @result != 0
				BEGIN
					UPDATE icv_orders
					   SET cr_adj_status = 'E', cr_adj_error = 0060 -- was 0070
					 WHERE order_no = @order_no
					   AND ext = @ext
					GOTO FETCHNEXT
				END
				EXEC appdate_sp @date_entered OUTPUT 
				IF @cm_input_table = 1
				BEGIN
					SELECT @date_applied = date_applied,
						@date_doc = date_doc
					  FROM arinpchg
					 WHERE trx_ctrl_num = @cm_trx_ctrl_num
					   AND customer_code = @cust_code
					   AND trx_type = 2032
				END
				ELSE
				BEGIN
					SELECT @date_applied = date_applied,
						@date_doc = date_doc
					  FROM artrx
					 WHERE trx_ctrl_num = @cm_trx_ctrl_num
					   AND customer_code = @cust_code
					   AND trx_type = 2032
				END
				SELECT @payment_code = payment_code,
					@payment_type = payment_type,
					@prompt1_inp = prompt1_inp,
					@prompt2_inp = prompt2_inp,
					@prompt3_inp = prompt3_inp,
					@prompt4_inp = prompt4_inp,
					@deposit_num = deposit_num,
					@cash_acct_code = cash_acct_code,
					@nat_cur_code = nat_cur_code,
					@rate_type_home	= rate_type_home,
					@rate_type_oper = rate_type_oper,
					@rate_home = rate_home,
					@rate_oper = rate_oper,
					@amt_discount = amt_discount,
					@reference_code = reference_code
				  FROM artrx
				 WHERE doc_ctrl_num = @doc_ctrl_num
				   AND customer_code = @cust_code
				   AND trx_type = 2111
				SELECT @apply_to_num = apply_to_num,
					@apply_trx_type = apply_trx_type,
					@date_aging = date_aging,
					@amt_applied = amt_applied,
					@amt_disc_taken = amt_disc_taken,
					@amt_max_wr_off = amt_wr_off,
					@void_flag = void_flag,
					@line_desc = line_desc,
					@sub_apply_num = sub_apply_num,
					@sub_apply_type = sub_apply_type,
					@amt_paid_to_date = amt_paid_to_date,
					@terms_code = terms_code,
					@posting_code = posting_code,
					@gain_home = gain_home,
					@gain_oper = gain_oper,
					@inv_amt_max_wr_off = inv_amt_wr_off,
					@inv_amt_disc_taken = inv_amt_disc_taken,
					@inv_cur_code = inv_cur_code
				  FROM artrxpdt
				 WHERE doc_ctrl_num = @doc_ctrl_num
				   AND sequence_id = 1
				   AND customer_code = @cust_code
				   AND trx_type = 2111

				IF @amt_max_wr_off > 0
				BEGIN
					SELECT @wr_off_flag = 1
				END
				ELSE
				BEGIN
					SELECT @wr_off_flag = 0
				END



				BEGIN TRANSACTION

				


				IF @batch_proc_flag = 1
				BEGIN
					EXEC @result = arnxtbat_sp 2000,
								   '',
								   2060,
								   @user_id,
								   @date_applied,
								   @company_code,
								   @batch_code OUTPUT,
								   0,
								   @adm_org_id
					SELECT @buf = 'Batch code: ' + @batch_code + ' Result: ' + STR(@result)
					EXEC icv_Log_sp @buf, @LogActivity

					UPDATE batchctl
					   SET completed_date = @complete_date,
					       completed_time = @complete_time,
					       control_number = 1,
					       control_total = @amt_payment,
					       actual_number = 1,
					       actual_total = @amt_payment,
					       completed_user = @complete_user,
					       batch_description = 'CCA CR VOID'
					 WHERE batch_ctrl_num = @batch_code
				END
				ELSE
				BEGIN
					SELECT @batch_code = ''
				END
				

				


				INSERT INTO arinppyt
					(timestamp, trx_ctrl_num, doc_ctrl_num, trx_desc, batch_code, trx_type, 
					non_ar_flag, non_ar_doc_num, gl_acct_code, date_entered, date_applied, 
					date_doc, customer_code, payment_code, payment_type, amt_payment, 
					amt_on_acct, prompt1_inp, prompt2_inp, prompt3_inp, prompt4_inp,
					deposit_num, bal_fwd_flag, printed_flag, posted_flag, hold_flag,
					wr_off_flag, on_acct_flag, user_id, max_wr_off, days_past_due, void_type,
					cash_acct_code, origin_module_flag, process_group_num, source_trx_ctrl_num,
					source_trx_type, nat_cur_code, rate_type_home, rate_type_oper, rate_home,
					rate_oper, amt_discount, reference_code, org_id)
					VALUES
					(NULL, @new_ctrl_num, @doc_ctrl_num, 'Void ICVerify Cash Receipt', @batch_code, 2121,
					0, '', '', @date_entered, @date_applied,
					@date_doc, @cust_code, @payment_code, @payment_type, @amt_payment,
					0.0, @prompt1_inp, @prompt2_inp, @prompt3_inp, @prompt4_inp,
					@deposit_num, 0, 0, 0, 0,
					0, 0, @user_id, 0, 0, 2,
					@cash_acct_code, NULL, NULL, @trx_ctrl_num,
					2031, @nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home,
					@rate_oper, @amt_discount, @reference_code, @adm_org_id)

				INSERT INTO arinppdt
					(timestamp, trx_ctrl_num, doc_ctrl_num, sequence_id, trx_type, apply_to_num, apply_trx_type,
					customer_code, date_aging, amt_applied, amt_disc_taken, wr_off_flag, amt_max_wr_off,
					void_flag, line_desc, sub_apply_num, sub_apply_type, amt_tot_chg, amt_paid_to_date, terms_code,
					posting_code, date_doc, amt_inv, gain_home, gain_oper, inv_amt_applied, inv_amt_disc_taken,
					inv_amt_max_wr_off, inv_cur_code, org_id)
					VALUES
					(NULL, @new_ctrl_num, @doc_ctrl_num, 1, 2121, @apply_to_num, @apply_trx_type,
					@cust_code, @date_aging, @amt_applied, @amt_disc_taken, @wr_off_flag, @amt_max_wr_off, 
					@void_flag, @line_desc, @sub_apply_num, @sub_apply_type, @amt_tot_chg, @amt_paid_to_date, @terms_code,
					@posting_code, @date_doc, @amt_inv, @gain_home, @gain_oper, @amt_applied, @inv_amt_disc_taken,
					@inv_amt_max_wr_off, @inv_cur_code, @adm_org_id)

				UPDATE icv_orders
				   SET cr_adj_status = 'T', cr_adj_error = 0000
				 WHERE order_no = @order_no
				   AND ext = @ext

				COMMIT TRANSACTION
			END
			ELSE
			BEGIN
			



				SELECT @buf = CONVERT(CHAR,ROUND(@amt_of_return,@precision_gl)) + ' <> ' + CONVERT(CHAR,ROUND(@amt_payment,@precision_gl))
				EXEC icv_Log_sp @buf, @LogActivity
				SELECT @buf = CONVERT(CHAR,ROUND(@amt_payment,@precision_gl)) + ' - ' + CONVERT(CHAR,ROUND(@amt_of_return,@precision_gl)) + ' = ' + CONVERT(CHAR,ROUND(@amt_payment,@precision_gl) - ROUND(@amt_of_return,@precision_gl))
				EXEC icv_Log_sp @buf, @LogActivity

				EXEC @result = arnewnum_sp 2121, @new_ctrl_num OUTPUT
				IF @result != 0
				BEGIN
					UPDATE icv_orders
					   SET cr_adj_status = 'E', cr_adj_error = 0060 -- was 0071
					 WHERE order_no = @order_no
					   AND ext = @ext
					GOTO FETCHNEXT
				END
				EXEC @result = arnewnum_sp 2111, @new_ctrl_num2 OUTPUT
				IF @result != 0
				BEGIN
					UPDATE icv_orders
					   SET cr_adj_status = 'E', cr_adj_error = 0060 -- was 0072
					 WHERE order_no = @order_no
					   AND ext = @ext
					GOTO FETCHNEXT
				END
				EXEC appdate_sp @date_entered OUTPUT 
				IF @cm_input_table = 1
				BEGIN
					SELECT @date_applied = date_applied,
						@date_doc = date_doc
					  FROM arinpchg
					 WHERE trx_ctrl_num = @cm_trx_ctrl_num
					   AND customer_code = @cust_code
					   AND trx_type = 2032
				END
				ELSE
				BEGIN
					SELECT @date_applied = date_applied,
						@date_doc = date_doc
					  FROM artrx
					 WHERE trx_ctrl_num = @cm_trx_ctrl_num
					   AND customer_code = @cust_code
					   AND trx_type = 2032
				END
				SELECT @payment_code = payment_code,
					@payment_type = payment_type,
					@prompt1_inp = prompt1_inp,
					@prompt2_inp = prompt2_inp,
					@prompt3_inp = prompt3_inp,
					@prompt4_inp = prompt4_inp,
					@deposit_num = deposit_num,
					@cash_acct_code = cash_acct_code,
					@nat_cur_code = nat_cur_code,
					@rate_type_home	= rate_type_home,
					@rate_type_oper = rate_type_oper,
					@rate_home = rate_home,
					@rate_oper = rate_oper,
					@amt_discount = amt_discount,
					@reference_code = reference_code,
					@cr_trx_ctrl_num = trx_ctrl_num
				  FROM artrx
				 WHERE doc_ctrl_num = @doc_ctrl_num
				   AND customer_code = @cust_code
				   AND trx_type = 2111
				SELECT @apply_to_num = apply_to_num,
					@apply_trx_type = apply_trx_type,
					@date_aging = date_aging,
					@amt_applied = amt_applied,
					@amt_disc_taken = amt_disc_taken,
					@amt_max_wr_off = amt_wr_off,
					@void_flag = void_flag,
					@line_desc = line_desc,
					@sub_apply_num = sub_apply_num,
					@sub_apply_type = sub_apply_type,
					@amt_paid_to_date = amt_paid_to_date,
					@terms_code = terms_code,
					@posting_code = posting_code,
					@gain_home = gain_home,
					@gain_oper = gain_oper,
					@inv_amt_disc_taken = inv_amt_disc_taken,
					@inv_amt_max_wr_off = inv_amt_wr_off,
					@inv_cur_code = inv_cur_code
				  FROM artrxpdt
				 WHERE doc_ctrl_num = @doc_ctrl_num
				   AND sequence_id = 1
				   AND customer_code = @cust_code
				   AND trx_type = 2111

				SELECT @buf = 'doc_ctrl_num = ' + @doc_ctrl_num + ', cust_code = ' + @cust_code
				EXEC icv_Log_sp @buf, @LogActivity

				IF @amt_max_wr_off > 0
				BEGIN
					SELECT @wr_off_flag = 1
				END
				ELSE
				BEGIN
					SELECT @wr_off_flag = 0
				END

				SELECT	@new_amt_applied = ROUND(@amt_payment - @amt_of_return, @precision_gl)
				SELECT 	@inv_amt_applied = @amt_applied,
					@new_inv_amt_applied = @new_amt_applied

				SELECT @buf = '@inv_amt_applied: ' + CONVERT(CHAR,@inv_amt_applied) + ', @amt_applied: ' + CONVERT(CHAR,@amt_applied)
				EXEC icv_Log_sp @buf, @LogActivity
				SELECT @buf = '@new_inv_amt_applied: ' + CONVERT(CHAR,@new_inv_amt_applied) + ', @new_amt_applied: ' + CONVERT(CHAR,@new_amt_applied)
				EXEC icv_Log_sp @buf, @LogActivity

				


				SELECT @new_gain_home = 
					ROUND((@amt_payment - @amt_of_return) * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ), @precision_gl) - 
			 		ROUND(@new_inv_amt_applied * ( SIGN(1 + SIGN(@inv_rate_home))*(@inv_rate_home) + (SIGN(ABS(SIGN(ROUND(@inv_rate_home,6))))/(@inv_rate_home + SIGN(1 - ABS(SIGN(ROUND(@inv_rate_home,6)))))) * SIGN(SIGN(@inv_rate_home) - 1) ), @precision_gl)
				SELECT @new_gain_oper = 
					ROUND((@amt_payment - @amt_of_return) * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ), @precision_gl) - 
					ROUND(@new_inv_amt_applied * ( SIGN(1 + SIGN(@inv_rate_oper))*(@inv_rate_oper) + (SIGN(ABS(SIGN(ROUND(@inv_rate_oper,6))))/(@inv_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@inv_rate_oper,6)))))) * SIGN(SIGN(@inv_rate_oper) - 1) ), @precision_gl)


				BEGIN TRANSACTION

				


				IF @batch_proc_flag = 1
				BEGIN
					EXEC @result = arnxtbat_sp 2000,
								   '',
								   2060,
								   @user_id,
								   @date_applied,
								   @company_code,
								   @batch_code OUTPUT,
								   0,
								   @adm_org_id
					SELECT @buf = 'Batch code: ' + @batch_code + ' Result: ' + STR(@result)
					EXEC icv_Log_sp @buf, @LogActivity

					UPDATE batchctl
					   SET completed_date = @complete_date,
					       completed_time = @complete_time,
					       control_number = 1,
					       control_total = @amt_payment,
					       actual_number = 1,
					       actual_total = @amt_payment,
					       completed_user = @complete_user,
					       batch_description = 'CCA CR VOID'
					 WHERE batch_ctrl_num = @batch_code

				END
				ELSE
				BEGIN
					SELECT @batch_code = ''
				END

				


				INSERT INTO arinppyt
					(timestamp, trx_ctrl_num, doc_ctrl_num, trx_desc, batch_code, trx_type, 
					non_ar_flag, non_ar_doc_num, gl_acct_code, date_entered, date_applied, 
					date_doc, customer_code, payment_code, payment_type, amt_payment, 
					amt_on_acct, prompt1_inp, prompt2_inp, prompt3_inp, prompt4_inp,
					deposit_num, bal_fwd_flag, printed_flag, posted_flag, hold_flag,
					wr_off_flag, on_acct_flag, user_id, max_wr_off, days_past_due, void_type,
					cash_acct_code, origin_module_flag, process_group_num, source_trx_ctrl_num,
					source_trx_type, nat_cur_code, rate_type_home, rate_type_oper, rate_home,
					rate_oper, amt_discount, reference_code, org_id)
					VALUES
					(NULL, @new_ctrl_num, @doc_ctrl_num, 'Void ICVerify Cash Receipt', @batch_code, 2121,
					0, '', '', @date_entered, @date_applied,
					@date_doc, @cust_code, @payment_code, @payment_type, @amt_payment,
					0.0, @prompt1_inp, @prompt2_inp, @prompt3_inp, @prompt4_inp,
					@deposit_num, 0, 0, 0, 0,
					0, 0, @user_id, 0, 0, 2,
					@cash_acct_code, NULL, NULL, @trx_ctrl_num,
					2031, @nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home,
					@rate_oper, @amt_discount, @reference_code, @adm_org_id)

				INSERT INTO arinppdt
					(timestamp, trx_ctrl_num, doc_ctrl_num, sequence_id, trx_type, apply_to_num, apply_trx_type,
					customer_code, date_aging, amt_applied, amt_disc_taken, wr_off_flag, amt_max_wr_off,
					void_flag, line_desc, sub_apply_num, sub_apply_type, amt_tot_chg, amt_paid_to_date, terms_code,
					posting_code, date_doc, amt_inv, gain_home, gain_oper, inv_amt_applied, inv_amt_disc_taken,
					inv_amt_max_wr_off, inv_cur_code, org_id)
					VALUES
					(NULL, @new_ctrl_num, @doc_ctrl_num, 1, 2121, @apply_to_num, @apply_trx_type,
					@cust_code, @date_aging, @amt_applied, @amt_disc_taken, @wr_off_flag, @amt_max_wr_off, 
					@void_flag, @line_desc, @sub_apply_num, @sub_apply_type, @amt_tot_chg, @amt_paid_to_date, @terms_code,
					@posting_code, @date_doc, @amt_inv, @gain_home, @gain_oper, @inv_amt_applied, @inv_amt_disc_taken,
					@inv_amt_max_wr_off, @inv_cur_code, @adm_org_id)

				


				IF @batch_proc_flag = 1
				BEGIN
					EXEC @result = arnxtbat_sp 2000,
								   '',
								   2050,
								   @user_id,
								   @date_applied,
								   @company_code,
								   @batch_code OUTPUT,
								   0,
								   @adm_org_id
					SELECT @buf = 'Batch code: ' + @batch_code + ' Result: ' + STR(@result)
					EXEC icv_Log_sp @buf, @LogActivity

					UPDATE batchctl
					   SET completed_date = @complete_date,
					       completed_time = @complete_time,
					       control_number = 1,
					       control_total = @amt_payment,
					       actual_number = 1,
					       actual_total = @amt_payment,
					       completed_user = @complete_user,
					       batch_description = 'CCA CR ADJUSTMENT'
					 WHERE batch_ctrl_num = @batch_code

				END
				ELSE
				BEGIN
					SELECT @batch_code = ''
				END

				-- get settlement number - mls 7/8/04 SCR 33067
				DECLARE @settlement_ctrl_num varchar(16), @num int 
				EXEC ARGetNextControl_SP 2015, @settlement_ctrl_num OUTPUT, @num OUTPUT 

				SELECT @buf = 'Settlement Number: ' + isnull(@settlement_ctrl_num,'<NULL>')
				EXEC icv_Log_sp @buf, @LogActivity

				


				INSERT INTO arinppyt
					(timestamp, trx_ctrl_num, doc_ctrl_num, trx_desc, batch_code, trx_type, 
					non_ar_flag, non_ar_doc_num, gl_acct_code, date_entered, date_applied, 
					date_doc, customer_code, payment_code, payment_type, amt_payment, 
					amt_on_acct, prompt1_inp, prompt2_inp, prompt3_inp, prompt4_inp,
					deposit_num, bal_fwd_flag, printed_flag, posted_flag, hold_flag,
					wr_off_flag, on_acct_flag, user_id, max_wr_off, days_past_due, void_type,
					cash_acct_code, origin_module_flag, process_group_num, source_trx_ctrl_num,
					source_trx_type, nat_cur_code, rate_type_home, rate_type_oper, rate_home,
					rate_oper, amt_discount, reference_code,
					settlement_ctrl_num, org_id)					-- mls SCR 33067 7/8/04
					VALUES
					(NULL, @new_ctrl_num2, @cr_trx_ctrl_num, 'ICVerify Cash Receipt', @batch_code, 2111,
					0, '', '', @date_entered, @date_applied,
					@date_doc, @cust_code, @payment_code, @payment_type, ROUND(@amt_payment,@precision_gl) - ROUND(@amt_of_return,@precision_gl),
					0.0, @prompt1_inp, @prompt2_inp, @prompt3_inp, @prompt4_inp,
					@deposit_num, 0, 0, 0, 0,
					0, 0, @user_id, 0, 0, 2,
					@cash_acct_code, NULL, NULL, @trx_ctrl_num,
					2031, @nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home,
					@rate_oper, @amt_discount, @reference_code,
					@settlement_ctrl_num, @adm_org_id)					-- mls SCR 33067 7/8/04

				exec ARCRAddStlRec_SP @settlement_ctrl_num			-- mls SCR 33067 7/8/04

				INSERT INTO arinppdt
					(timestamp, trx_ctrl_num, doc_ctrl_num, sequence_id, trx_type, apply_to_num, apply_trx_type,
					customer_code, date_aging, amt_applied, amt_disc_taken, wr_off_flag, amt_max_wr_off,
					void_flag, line_desc, sub_apply_num, sub_apply_type, amt_tot_chg, amt_paid_to_date, terms_code,
					posting_code, date_doc, amt_inv, gain_home, gain_oper, inv_amt_applied, inv_amt_disc_taken,
					inv_amt_max_wr_off, inv_cur_code, org_id)
					VALUES
					(NULL, @new_ctrl_num2, @cr_trx_ctrl_num, 1, 2111, @apply_to_num, @apply_trx_type,
					@cust_code, @date_aging, @new_amt_applied, @amt_disc_taken, @wr_off_flag, @amt_max_wr_off, 
					@void_flag, @line_desc, @sub_apply_num, @sub_apply_type, @amt_tot_chg, @amt_paid_to_date, @terms_code,
					@posting_code, @date_doc, @amt_inv, @new_gain_home, @new_gain_oper, @new_inv_amt_applied, @inv_amt_disc_taken,
					@inv_amt_max_wr_off, @inv_cur_code, @adm_org_id)

				UPDATE icv_orders
				   SET cr_adj_status = 'T', cr_adj_error = 0000
				 WHERE order_no = @order_no
				   AND ext = @ext

				COMMIT TRANSACTION
			END


			
		END
	END
FETCHNEXT:
	FETCH NEXT FROM cradj_cursor INTO @order_no, @ext, @orig_no, @orig_ext, @cust_code, @adm_org_id
END




CLOSE cradj_cursor
DEALLOCATE cradj_cursor

DELETE icv_crtemp 
 WHERE spid = @@spid

SELECT @err = 1
RETURN
GO
GRANT EXECUTE ON  [dbo].[icv_fs_post_cradj] TO [public]
GO
