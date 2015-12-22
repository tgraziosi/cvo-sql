SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APPAProcessPayments_sp]    	@user_id int,
										@debug_level smallint = 0

AS
	DECLARE
			@trx_ctrl_num varchar(16),
			@current_date int,
			@result int,
			@pay_ctrl_num varchar(16),
			@company_code varchar(8),

			@trx_desc                       varchar(40),
			@cash_acct_code         varchar(32),
			@vendor_code        varchar(12),
			@pay_to_code        varchar(8),
			@approval_code          varchar(8),
			@payment_code           varchar(8),
		    @payment_type           smallint,
			@amt_payment            float,
			@amt_on_acct            float,
			@printed_flag           smallint,
			@hold_flag                      smallint,
			@approval_flag      smallint,
			@gen_id                         int,
			@amt_disc_taken         float,


			@sequence_id	int,
			@apply_to_num           varchar(16),
			@apply_trx_type         smallint,       
			@amt_applied         float,          
			@py_amt_disc_taken      float,  
			@line_desc           varchar(40),
			@payment_hold_flag      smallint,
			@home_cur_code	varchar(8),
			@oper_cur_code	varchar(8),
			@home_precision smallint,
			@oper_precision smallint,
			@nat_cur_code varchar(8),
			@vo_amt_applied float,
			@vo_amt_disc_taken float,
			@rate_home float,
			@rate_oper float,
			@rate_type_home varchar(8),
			@rate_type_oper varchar(8),
			@gain_home float,
			@gain_oper float,
			@org_id	varchar(30)


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appapp.cpp' + ', line ' + STR( 97, 5 ) + ' -- ENTRY: '


EXEC appdate_sp @current_date OUTPUT

SELECT @company_code = a.company_code, 
	   @home_cur_code = a.home_currency,
	   @oper_cur_code = a.oper_currency,
	   @home_precision = b.curr_precision,
	   @oper_precision =  c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code


CREATE TABLE #pyheader (
						trx_ctrl_num varchar(16),
						trx_desc                       varchar(40),
						cash_acct_code         varchar(32),
						vendor_code        varchar(12),
						pay_to_code        varchar(8),
						approval_code          varchar(8),
						payment_code           varchar(8),
					    payment_type           smallint,
						amt_payment            float,
						amt_on_acct            float,
						printed_flag           smallint,
						hold_flag                      smallint,
						approval_flag      smallint,
						gen_id                         int,
						amt_disc_taken         float,
						nat_cur_code		varchar(8),
					    rate_type_home		varchar(8),
					    rate_type_oper		varchar(8),
					    rate_home			float,
					    rate_oper			float,  
						org_id	varchar(30) NULL,
						mark_flag smallint
						)

CREATE TABLE #pydetail (
						trx_ctrl_num  varchar(16),
						sequence_id int,
						apply_to_num           varchar(16),
						apply_trx_type         smallint,       
						amt_applied         float,          
						py_amt_disc_taken      float,  
						line_desc           varchar(40),
						payment_hold_flag      smallint,
						vo_amt_applied		float,
						vo_amt_disc_taken	float,
						gain_home			float,
						gain_oper			float,
						nat_cur_code		varchar(8),
						cross_rate			float,
						rate_type_home		varchar(8),
						mark_flag smallint
						)




INSERT #pyheader (	trx_ctrl_num,
					trx_desc,
					cash_acct_code,
					vendor_code,
					pay_to_code,
					approval_code,
					payment_code,
				    payment_type,
					amt_payment,
					amt_on_acct,
					printed_flag,
					hold_flag,
					approval_flag,
					gen_id,
					amt_disc_taken,
					nat_cur_code,
					rate_type_home,
					rate_type_oper,
					rate_home,
					rate_oper,
					org_id,
					mark_flag
				 )
SELECT				a.trx_ctrl_num,
					a.trx_desc,
					a.cash_acct_code,
					a.vendor_code,
					a.pay_to_code,
					a.approval_code,
					a.payment_code,
				    a.payment_type,
					0.0,
					a.amt_on_acct,
					4,
					a.hold_flag,
					a.approval_flag,
					a.gen_id,
					0.0,
					a.nat_cur_code,
					a.rate_type_home,
					a.rate_type_oper,
					0.0,
					0.0,
					a.org_id,
					0
FROM	#appapyt_work a
WHERE	a.void_type = 5


CREATE TABLE #appapdt_tmp (trx_ctrl_num varchar(16),
			 apply_to_num varchar(16),
			 line_desc varchar(40),
			 nat_cur_code varchar(8),
			 vo_amt_applied float,
			 vo_amt_disc_taken float)

INSERT #appapdt_tmp (trx_ctrl_num,
		 apply_to_num,
		 line_desc,
		 nat_cur_code,
		 vo_amt_applied,
		 vo_amt_disc_taken)	
SELECT 	trx_ctrl_num, 
	apply_to_num,
	MAX(line_desc) line_desc,
	MAX(nat_cur_code) nat_cur_code,
	SUM(vo_amt_applied) vo_amt_applied, 
	SUM(vo_amt_disc_taken) vo_amt_disc_taken 
FROM #appapdt_work 
GROUP BY trx_ctrl_num, apply_to_num


INSERT #pydetail (	trx_ctrl_num,
					sequence_id,
					apply_to_num,
					apply_trx_type,
					amt_applied,
					py_amt_disc_taken,
					line_desc,
					payment_hold_flag,
					vo_amt_applied,
					vo_amt_disc_taken,
					gain_home,
					gain_oper,
					nat_cur_code,
					cross_rate,
					rate_type_home,
					mark_flag
				)
SELECT 				a.trx_ctrl_num,
					1,
					a.apply_to_num,
					4091,
					0.0,
					0.0,
					a.line_desc,
					0,
					a.vo_amt_applied,
					a.vo_amt_disc_taken,
					0.0,
					0.0,
					a.nat_cur_code,
					0.0,
					c.rate_type_home,
					0
FROM	#appapdt_tmp a, #pyheader b, #appatrxv_work c
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.apply_to_num = c.trx_ctrl_num


DROP TABLE #appapdt_tmp


UPDATE #pyheader
SET printed_flag = 0
FROM #pyheader, appymeth b
WHERE #pyheader.payment_code = b.payment_code
AND b.payment_type = 2

UPDATE #pyheader
SET hold_flag = 1
FROM #pyheader, appymeth b
WHERE #pyheader.payment_code = b.payment_code
AND b.payment_type = 1


CREATE TABLE #rates (from_currency varchar(8),
				   to_currency varchar(8),
				   rate_type varchar(8),
				   date_applied int,
				   rate float)
IF @@error <> 0
   RETURN -1

CREATE TABLE #temp (from_currency varchar(8),
					to_currency varchar(8),
					rate_type varchar(8))

INSERT #temp (from_currency,
			  to_currency,
			  rate_type)
SELECT DISTINCT nat_cur_code,
		        @home_cur_code,
			    rate_type_home
FROM #pyheader
WHERE nat_cur_code != @home_cur_code



INSERT #temp (from_currency,
			  to_currency,
			  rate_type)
SELECT DISTINCT nat_cur_code,
		        @oper_cur_code,
			    rate_type_oper
FROM #pyheader
WHERE nat_cur_code != @oper_cur_code


INSERT #temp (from_currency,
			  to_currency,
			  rate_type)
SELECT DISTINCT nat_cur_code,
		        @home_cur_code,
			    rate_type_home
FROM #pydetail
WHERE nat_cur_code != @home_cur_code




INSERT #rates (	from_currency,
				to_currency,
				rate_type,
				date_applied,
				rate )
SELECT DISTINCT from_currency,
				to_currency,
				rate_type,
				@current_date,
				0.0
FROM #temp


DROP TABLE #temp


EXEC CVO_Control..mcrates_sp

UPDATE #pyheader
SET rate_home = 1.0
WHERE nat_cur_code = @home_cur_code

UPDATE #pyheader
SET rate_oper = 1.0
WHERE nat_cur_code = @oper_cur_code


UPDATE #pyheader
SET rate_home = b.rate
FROM #pyheader, #rates b
WHERE #pyheader.nat_cur_code = b.from_currency
AND @home_cur_code = b.to_currency
AND #pyheader.rate_type_home = b.rate_type


UPDATE #pyheader
SET rate_oper = b.rate
FROM #pyheader, #rates b
WHERE #pyheader.nat_cur_code = b.from_currency
AND @oper_cur_code = b.to_currency
AND #pyheader.rate_type_oper = b.rate_type

UPDATE #pydetail
SET cross_rate = 1.0
FROM #pydetail, #pyheader b
WHERE #pydetail.nat_cur_code = b.nat_cur_code
AND #pydetail.trx_ctrl_num = b.trx_ctrl_num


UPDATE #pydetail
SET cross_rate = ( SIGN(1 + SIGN(b.rate))*(b.rate) + (SIGN(ABS(SIGN(ROUND(b.rate,6))))/(b.rate + SIGN(1 - ABS(SIGN(ROUND(b.rate,6)))))) * SIGN(SIGN(b.rate) - 1) )/( SIGN(1 + SIGN(c.rate_home))*(c.rate_home) + (SIGN(ABS(SIGN(ROUND(c.rate_home,6))))/(c.rate_home + SIGN(1 - ABS(SIGN(ROUND(c.rate_home,6)))))) * SIGN(SIGN(c.rate_home) - 1) )
FROM #pydetail, #rates b, #pyheader c
WHERE #pydetail.nat_cur_code = b.from_currency
AND @home_cur_code = b.to_currency
AND #pydetail.rate_type_home = b.rate_type
AND #pydetail.trx_ctrl_num = c.trx_ctrl_num


UPDATE #pydetail
SET amt_applied = (SIGN(#pydetail.vo_amt_applied * #pydetail.cross_rate) * ROUND(ABS(#pydetail.vo_amt_applied * #pydetail.cross_rate) + 0.0000001, c.curr_precision)),
    py_amt_disc_taken = (SIGN(#pydetail.vo_amt_disc_taken * #pydetail.cross_rate) * ROUND(ABS(#pydetail.vo_amt_disc_taken * #pydetail.cross_rate) + 0.0000001, c.curr_precision))
FROM #pydetail, #pyheader b, glcurr_vw c
WHERE #pydetail.trx_ctrl_num = b.trx_ctrl_num
AND b.nat_cur_code = c.currency_code





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appapp.cpp' + ', line ' + STR( 399, 5 ) + ' -- MSG: ' + '---calculate gain/loss amounts'
UPDATE #pydetail
SET gain_home = (SIGN(#pydetail.vo_amt_applied * ( SIGN(1 + SIGN(b.rate_home))*(b.rate_home) + (SIGN(ABS(SIGN(ROUND(b.rate_home,6))))/(b.rate_home + SIGN(1 - ABS(SIGN(ROUND(b.rate_home,6)))))) * SIGN(SIGN(b.rate_home) - 1) )) * ROUND(ABS(#pydetail.vo_amt_applied * ( SIGN(1 + SIGN(b.rate_home))*(b.rate_home) + (SIGN(ABS(SIGN(ROUND(b.rate_home,6))))/(b.rate_home + SIGN(1 - ABS(SIGN(ROUND(b.rate_home,6)))))) * SIGN(SIGN(b.rate_home) - 1) )) + 0.0000001, @home_precision))
				- (SIGN(#pydetail.amt_applied * ( SIGN(1 + SIGN(c.rate_home))*(c.rate_home) + (SIGN(ABS(SIGN(ROUND(c.rate_home,6))))/(c.rate_home + SIGN(1 - ABS(SIGN(ROUND(c.rate_home,6)))))) * SIGN(SIGN(c.rate_home) - 1) )) * ROUND(ABS(#pydetail.amt_applied * ( SIGN(1 + SIGN(c.rate_home))*(c.rate_home) + (SIGN(ABS(SIGN(ROUND(c.rate_home,6))))/(c.rate_home + SIGN(1 - ABS(SIGN(ROUND(c.rate_home,6)))))) * SIGN(SIGN(c.rate_home) - 1) )) + 0.0000001, @home_precision)),
    gain_oper = (SIGN(#pydetail.vo_amt_applied * ( SIGN(1 + SIGN(b.rate_oper))*(b.rate_oper) + (SIGN(ABS(SIGN(ROUND(b.rate_oper,6))))/(b.rate_oper + SIGN(1 - ABS(SIGN(ROUND(b.rate_oper,6)))))) * SIGN(SIGN(b.rate_oper) - 1) )) * ROUND(ABS(#pydetail.vo_amt_applied * ( SIGN(1 + SIGN(b.rate_oper))*(b.rate_oper) + (SIGN(ABS(SIGN(ROUND(b.rate_oper,6))))/(b.rate_oper + SIGN(1 - ABS(SIGN(ROUND(b.rate_oper,6)))))) * SIGN(SIGN(b.rate_oper) - 1) )) + 0.0000001, @oper_precision))
			    - (SIGN(#pydetail.amt_applied * ( SIGN(1 + SIGN(c.rate_oper))*(c.rate_oper) + (SIGN(ABS(SIGN(ROUND(c.rate_oper,6))))/(c.rate_oper + SIGN(1 - ABS(SIGN(ROUND(c.rate_oper,6)))))) * SIGN(SIGN(c.rate_oper) - 1) )) * ROUND(ABS(#pydetail.amt_applied * ( SIGN(1 + SIGN(c.rate_oper))*(c.rate_oper) + (SIGN(ABS(SIGN(ROUND(c.rate_oper,6))))/(c.rate_oper + SIGN(1 - ABS(SIGN(ROUND(c.rate_oper,6)))))) * SIGN(SIGN(c.rate_oper) - 1) )) + 0.0000001, @oper_precision))
FROM #pydetail, #appatrxv_work b, #pyheader c
WHERE #pydetail.apply_to_num = b.trx_ctrl_num
AND #pydetail.trx_ctrl_num = c.trx_ctrl_num


UPDATE #pyheader
SET amt_payment = ISNULL((SELECT SUM(b.amt_applied) 
				   FROM #pydetail b
				   WHERE b.trx_ctrl_num = #pyheader.trx_ctrl_num),0) + #pyheader.amt_on_acct,
    amt_disc_taken = ISNULL((SELECT SUM(b.py_amt_disc_taken)
					  FROM #pydetail b
					  WHERE b.trx_ctrl_num = #pyheader.trx_ctrl_num),0)
FROM #pyheader



WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
		  SELECT 	@trx_ctrl_num = trx_ctrl_num,
					@trx_desc = trx_desc,
					@cash_acct_code = cash_acct_code,
					@vendor_code = vendor_code,
					@pay_to_code = pay_to_code,
					@approval_code = approval_code,
					@payment_code = payment_code,
				    @payment_type = payment_type,
					@amt_payment = amt_payment,
					@amt_on_acct = amt_on_acct,
					@printed_flag = printed_flag,
					@hold_flag = hold_flag,
					@approval_flag = approval_flag,
					@gen_id = gen_id,
					@amt_disc_taken = amt_disc_taken,
					@nat_cur_code = nat_cur_code,
					@rate_type_home = rate_type_home,
					@rate_type_oper = rate_type_oper,
					@rate_home = rate_home,
					@rate_oper = rate_oper,
					@org_id	= org_id
		  FROM #pyheader
		  WHERE mark_flag = 0
	  
	  
	  	  IF @@rowcount = 0 BREAK
	  
	  SET ROWCOUNT 0

			SELECT @pay_ctrl_num = NULL	      
	
			EXEC @result = appycrh_sp
					   4000,
					   2,
					   @pay_ctrl_num  OUTPUT,
				   	   4111,
					   '',
					   @trx_desc,
					   ' ',         
					   @cash_acct_code,
					   @current_date,
					   @current_date,
					   @current_date,
				   	   @vendor_code,
					   @pay_to_code,
					   @approval_code,
					   @payment_code,
					   @payment_type,
				   	   @amt_payment,
					   @amt_on_acct,
					   0, 
					   @printed_flag,
					   @hold_flag,
					   @approval_flag,
					   @gen_id,
					   @user_id,
					   0,
					   @amt_disc_taken,
					   0,
					   @company_code,
					   ' ',
					   @nat_cur_code,
					   @rate_type_home,
					   @rate_type_oper,
					   @rate_home,
					   @rate_oper,
						@org_id
			IF(@result != 0)
				RETURN @result


			WHILE (1=1)
				BEGIN
					SET ROWCOUNT 1
						SELECT 	@sequence_id = sequence_id,
								@apply_to_num = apply_to_num,
								@apply_trx_type = apply_trx_type,
								@amt_applied = amt_applied,
								@py_amt_disc_taken = py_amt_disc_taken,
								@line_desc = line_desc,
								@payment_hold_flag = payment_hold_flag,
								@vo_amt_applied = vo_amt_applied,
								@vo_amt_disc_taken = vo_amt_disc_taken,
								@gain_home = gain_home,
								@gain_oper = gain_oper,
								@nat_cur_code = nat_cur_code
						FROM #pydetail
						WHERE trx_ctrl_num = @trx_ctrl_num
						AND mark_flag = 0

						IF @@rowcount = 0 break

					SET ROWCOUNT 0

						EXEC @result = appycrd_sp
					   4000,
					   2,
					   @pay_ctrl_num,
					   4111,
					   @sequence_id,
					   @apply_to_num,
					   @apply_trx_type,
					   @amt_applied,
					   @py_amt_disc_taken,
					   @line_desc,
					   0,
					   @payment_hold_flag,
					   @vendor_code,
					   @vo_amt_applied,
					   @vo_amt_disc_taken,
					   @gain_home,
					   @gain_oper,
					   @nat_cur_code,
						@org_id

			IF(@result != 0)
				RETURN @result


				SET ROWCOUNT 1
				UPDATE #pydetail
				SET mark_flag = 1
				WHERE trx_ctrl_num = @trx_ctrl_num
				AND mark_flag = 0
				SET ROWCOUNT 0

			END

			SET ROWCOUNT 1
			UPDATE #pyheader		    
			SET mark_flag = 1
			WHERE mark_flag = 0
			SET ROWCOUNT 0

	END

DROP TABLE #pyheader
DROP TABLE #pydetail

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appapp.cpp' + ', line ' + STR( 563, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPAProcessPayments_sp] TO [public]
GO
