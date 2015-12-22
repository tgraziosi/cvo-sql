SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[autostl_sp] 	@description varchar(40),
				@settlement_ctrl_num varchar(16)

AS
DECLARE @today integer,
	@cur_time integer,
	@min_date_applied integer,
	@last_date_applied integer,
	@new_bcn varchar(16),
	@ret_status integer,
	@num integer,
	@batch_code varchar(16),
	@company_code varchar(8),
	@result integer,
	@actual_number integer,
	@actual_total float,
	@user_name varchar(10),
	@user_id int,
 	@inv_total_home float,
 	@inv_total_oper float,
 	@disc_total_home float,
 	@disc_total_oper float,
 	@wroff_total_home float,
 	@wroff_total_oper float,
 	@gain_total_home float,
 	@gain_total_oper float,
 	@loss_total_home float,
 	@loss_total_oper float,
 	@doc_sum_entered float,
	@cr_total_home float,
 	@cr_total_oper float,
 	@cm_total_home float,
 	@cm_total_oper float,
 	@cb_total_home float,
 	@cb_total_oper float,
	@customer varchar(8),
	@currency  varchar(4), 
	@batch varchar(16), 
	@rate_type_home varchar(8),   
	@rate_home integer, 
	@rate_type_oper varchar(8),
	@rate_oper integer,
	@inv_total_nat float,
	@cb_total_nat float	



/* Get today's date */
EXEC appdate_sp @today OUTPUT

/* Get the current time */
SELECT 	@cur_time = datepart(hour,getdate())*3600+ datepart(minute,getdate())*60+  datepart(second,getdate())

/* Get the company code */
SELECT	@company_code = company_code 
FROM 	arco a, glcomp_vw b
WHERE 	a.company_id=b.company_id

SELECT 	@min_date_applied = 0,
	@last_date_applied = 0

WHILE 1=1
BEGIN
	SELECT 	@min_date_applied = min(date_applied)
	FROM	#arinppyt_work
	WHERE	date_applied > @last_date_applied

	IF @min_date_applied IS NULL BREAK

	SELECT 	@last_date_applied = @min_date_applied

	/* Set the actual totals of the batch */
	SELECT	@actual_number = count(*) 
	FROM	#arinppyt_work 
	WHERE	settlement_ctrl_num = @settlement_ctrl_num

	SELECT	@actual_total = sum(amt_payment)
	FROM	#arinppyt_work 
	WHERE	settlement_ctrl_num = @settlement_ctrl_num
	
	SELECT 	@user_name = current_user

	SELECT  @user_id = isnull(user_id,1)
	FROM	ewusers_vw
	WHERE	user_name = @user_name

	IF @user_id IS NULL SELECT @user_id = 1
	
	SELECT  @customer = customer_code,
		@currency = nat_cur_code, 
		@batch = batch_code, 
		@rate_type_home = rate_type_home,   
		@rate_home = rate_home,   
		@rate_type_oper = rate_type_oper, 
		@rate_oper = rate_oper
	FROM #arinppyt_work
	WHERE	settlement_ctrl_num = @settlement_ctrl_num


	INSERT arinpstlhdr ( 	settlement_ctrl_num,
 				description,
 				hold_flag,
				posted_flag,
 				date_entered,
 				date_applied, 
 				user_id,
 				process_group_num,
 				doc_count_expected,
 				doc_count_entered,
 				doc_sum_expected,
 				doc_sum_entered,
 				cr_total_home,
 				cr_total_oper,
 				oa_cr_total_home,
 				oa_cr_total_oper,
 				cm_total_home,
 				cm_total_oper,
 				inv_total_home,
 				inv_total_oper,
 				disc_total_home,
 				disc_total_oper,
 				wroff_total_home,
 				wroff_total_oper,
 				onacct_total_home,
 				onacct_total_oper,
 				gain_total_home,
 				gain_total_oper,
 				loss_total_home,
 				loss_total_oper,
				customer_code,
				nat_cur_code, 
				batch_code, 
				rate_type_home,   
				rate_home,   
				rate_type_oper, 
				rate_oper,
				inv_amt_nat, 
				amt_doc_nat,  
				amt_dist_nat,
				amt_on_acct,
				settle_flag)
			VALUES (@settlement_ctrl_num,
				@description,
				0,
				0,
				@today,
				@min_date_applied,
				@user_id,
				null,
				@actual_number,
				@actual_number,
				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
 				0,
				@customer,
				@currency, 
				@batch, 
				@rate_type_home,   
				@rate_home,   
				@rate_type_oper, 
				@rate_oper,
				0, 
				0,  
				0,
				0,
				0)	

 SELECT @doc_sum_entered = ISNULL(sum(amt_payment),0)
 FROM #arinppyt_work p, arinpstlhdr s
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num

 SELECT @cr_total_home = ISNULL(sum(amt_payment * ( SIGN(1 + SIGN(p.rate_home))*(p.rate_home) + (SIGN(ABS(SIGN(ROUND(p.rate_home,6))))/(p.rate_home + SIGN(1 - ABS(SIGN(ROUND(p.rate_home,6)))))) * SIGN(SIGN(p.rate_home) - 1) )),0), 
 	@cr_total_oper = ISNULL(sum(amt_payment * ( SIGN(1 + SIGN(p.rate_oper))*(p.rate_oper) + (SIGN(ABS(SIGN(ROUND(p.rate_oper,6))))/(p.rate_oper + SIGN(1 - ABS(SIGN(ROUND(p.rate_oper,6)))))) * SIGN(SIGN(p.rate_oper) - 1) )),0)
 FROM #arinppyt_work p, arinpstlhdr s
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num
 AND p.payment_type = 1

 SELECT @cm_total_home = ISNULL(sum( amt_payment * ( SIGN(1 + SIGN(p.rate_home))*(p.rate_home) + (SIGN(ABS(SIGN(ROUND(p.rate_home,6))))/(p.rate_home + SIGN(1 - ABS(SIGN(ROUND(p.rate_home,6)))))) * SIGN(SIGN(p.rate_home) - 1) )),0),
 	@cm_total_oper = ISNULL(sum( amt_payment * ( SIGN(1 + SIGN(p.rate_oper))*(p.rate_oper) + (SIGN(ABS(SIGN(ROUND(p.rate_oper,6))))/(p.rate_oper + SIGN(1 - ABS(SIGN(ROUND(p.rate_oper,6)))))) * SIGN(SIGN(p.rate_oper) - 1) )),0)
 FROM #arinppyt_work p, arinpstlhdr s
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num
 AND p.payment_type = 4

 SELECT @inv_total_home = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(p.rate_home))*(p.rate_home) + (SIGN(ABS(SIGN(ROUND(p.rate_home,6))))/(p.rate_home + SIGN(1 - ABS(SIGN(ROUND(p.rate_home,6)))))) * SIGN(SIGN(p.rate_home) - 1) ) ), 0.0 ), 
 @inv_total_oper = ISNULL( SUM( amt_applied * ( SIGN(1 + SIGN(p.rate_oper))*(p.rate_oper) + (SIGN(ABS(SIGN(ROUND(p.rate_oper,6))))/(p.rate_oper + SIGN(1 - ABS(SIGN(ROUND(p.rate_oper,6)))))) * SIGN(SIGN(p.rate_oper) - 1) ) ), 0.0 ), 
 @inv_total_nat = ISNULL( SUM( amt_applied), 0.0 ), 
 @disc_total_home = ISNULL( SUM( amt_disc_taken * ( SIGN(1 + SIGN(p.rate_home))*(p.rate_home) + (SIGN(ABS(SIGN(ROUND(p.rate_home,6))))/(p.rate_home + SIGN(1 - ABS(SIGN(ROUND(p.rate_home,6)))))) * SIGN(SIGN(p.rate_home) - 1) ) ), 0.0 ), 
 @disc_total_oper = ISNULL( SUM( amt_disc_taken * ( SIGN(1 + SIGN(p.rate_oper))*(p.rate_oper) + (SIGN(ABS(SIGN(ROUND(p.rate_oper,6))))/(p.rate_oper + SIGN(1 - ABS(SIGN(ROUND(p.rate_oper,6)))))) * SIGN(SIGN(p.rate_oper) - 1) ) ), 0.0 )
 FROM arinpstlhdr s, #arinppyt_work p, #arinppdt_work d
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num
 AND d.trx_ctrl_num = p.trx_ctrl_num
 AND d.trx_type = p.trx_type

 SELECT @gain_total_home = ISNULL( SUM( gain_home ), 0.0 )
 FROM arinpstlhdr s, arinppyt p, arinppdt d
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num
 AND d.trx_ctrl_num = p.trx_ctrl_num
 AND d.trx_type = p.trx_type
 AND d.gain_home > 0

 SELECT @gain_total_oper = ISNULL( SUM(gain_oper), 0.0 )
 FROM arinpstlhdr s, arinppyt p, arinppdt d
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num
 AND d.trx_ctrl_num = p.trx_ctrl_num
 AND d.trx_type = p.trx_type
 AND d.gain_oper > 0

 SELECT @loss_total_home = ISNULL( SUM( gain_home ), 0.0 )
 FROM arinpstlhdr s, arinppyt p, arinppdt d
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num
 AND d.trx_ctrl_num = p.trx_ctrl_num
 AND d.trx_type = p.trx_type
 AND d.gain_home < 0

 SELECT @loss_total_oper = ISNULL( SUM(gain_oper), 0.0 )
 FROM arinpstlhdr s, arinppyt p, arinppdt d
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num
 AND d.trx_ctrl_num = p.trx_ctrl_num
 AND d.trx_type = p.trx_type
 AND d.gain_oper < 0

 SELECT @cb_total_home = ISNULL( SUM( total_chargebacks * ( SIGN(1 + SIGN(p.rate_home))*(p.rate_home) + (SIGN(ABS(SIGN(ROUND(p.rate_home,6))))/(p.rate_home + SIGN(1 - ABS(SIGN(ROUND(p.rate_home,6)))))) * SIGN(SIGN(p.rate_home) - 1) ) ), 0.0 ), 
 @cb_total_oper = ISNULL( SUM( total_chargebacks * ( SIGN(1 + SIGN(p.rate_oper))*(p.rate_oper) + (SIGN(ABS(SIGN(ROUND(p.rate_oper,6))))/(p.rate_oper + SIGN(1 - ABS(SIGN(ROUND(p.rate_oper,6)))))) * SIGN(SIGN(p.rate_oper) - 1) ) ), 0.0 ),
 @cb_total_nat = ISNULL( SUM( total_chargebacks), 0.0 )
 FROM arinpstlhdr s, #arinppyt_work p, #arcbtot d
 WHERE p.settlement_ctrl_num = s.settlement_ctrl_num
 AND s.settlement_ctrl_num = @settlement_ctrl_num
 AND d.trx_ctrl_num = p.trx_ctrl_num

 UPDATE arinpstlhdr
 SET
 doc_sum_expected = @doc_sum_entered,
 doc_sum_entered = @doc_sum_entered,
 cr_total_home = @cr_total_home,
 cr_total_oper = @cr_total_oper,
 cm_total_home = @cm_total_home,
 cm_total_oper = @cm_total_oper,
 onacct_total_home = @cr_total_home +  @cm_total_home + @cb_total_home - @inv_total_home, 
 onacct_total_oper = @cr_total_oper +  @cm_total_oper + @cb_total_oper- @inv_total_oper ,
 inv_total_home = @inv_total_home,
 inv_total_oper = @inv_total_oper,
 disc_total_home = @disc_total_home,
 disc_total_oper = @disc_total_oper,
 wroff_total_home = 0,
 wroff_total_oper = 0,
 gain_total_home = @gain_total_home,
 gain_total_oper = @gain_total_oper,
 loss_total_home = @loss_total_home,
 loss_total_oper = @loss_total_oper,
 inv_amt_nat = @inv_total_nat, 
 amt_doc_nat = @doc_sum_entered,  
 amt_dist_nat = @inv_total_nat,
 amt_on_acct = isnull(round(@doc_sum_entered + @cb_total_nat - @inv_total_nat,2),0)
 WHERE settlement_ctrl_num = @settlement_ctrl_num
			
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[autostl_sp] TO [public]
GO
