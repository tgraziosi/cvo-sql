SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APPYCalculatePaymentDist_sp]  @debug_level smallint = 0
AS
 
	DECLARE @age_flag smallint,
			@age_trx_ctrl_num varchar(16),
			@det_flag smallint,
			@det_trx_ctrl_num varchar(16),
			@sequence_id int,
			@age_amt_unpaid float,
			@det_amt_disc_taken float,
			@det_amt_applied float,
			@age_date_aging int,
			@det_apply_to_num varchar(16),
			@det_date_applied int,
			@det_date_doc int,
			@det_doc_ctrl_num varchar(16),
			@det_line_desc varchar(40),
			@det_payment_type smallint,
			@det_cash_acct_code varchar(32),
			@det_vo_amt_applied float,
			@det_vo_amt_disc_taken float,
			@disc float,
			@amt float,
			@vo_amt float,
			@vo_disc float,
			@gain_home float,
			@gain_oper float,
			@old_trx_num varchar(16),
			@old_age_trx_ctrl_num varchar(16),
			@age_paid float,
			@home_precision	smallint,
			@oper_precision smallint

 
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 82, 5 ) + ' -- ENTRY: '

SELECT @home_precision = b.curr_precision,
	   @oper_precision = c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code


SELECT trx_ctrl_num, cnt = COUNT(trx_ctrl_num)
INTO #split_aged
FROM #appyagev_work
GROUP BY trx_ctrl_num

IF EXISTS (SELECT trx_ctrl_num FROM #split_aged WHERE cnt > 1)
BEGIN


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 100, 5 ) + ' -- MSG: ' + 'Create tables #age_temp and #pay_detail'
		CREATE TABLE #age_temp (trx_ctrl_num varchar(16), 
								date_aging int, 
								amt_unpaid float, 
								mark_flag smallint)
		IF @@error != 0
		   RETURN -1

		CREATE CLUSTERED INDEX ind_1 ON #age_temp (trx_ctrl_num, date_aging)
		IF @@error != 0
		   RETURN -1

		CREATE TABLE #pay_detail (trx_ctrl_num varchar(16), 
								  apply_to_num varchar(16), 
								  vo_amt_applied float,
								  vo_amt_disc_taken float,
								  mark_flag smallint)
		IF @@error != 0
		   RETURN -1

		CREATE CLUSTERED INDEX ind_2 ON #pay_detail ( apply_to_num, trx_ctrl_num)
		IF @@error != 0
		   RETURN -1


		CREATE TABLE #paydist_age (trx_ctrl_num varchar(16), 
					  sequence_id int, 
					  apply_to_num varchar(16), 
					  date_aging int, 
					  vo_amt_applied float,
					  vo_amt_disc_taken float)

		IF @@error != 0
		   RETURN -1


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 136, 5 ) + ' -- MSG: ' + 'Insert aging records into #age_temp'
		INSERT #age_temp   (trx_ctrl_num, 
						   	date_aging, 
						   	amt_unpaid, 
						   	mark_flag)
		SELECT a.trx_ctrl_num, 
			   a.date_aging,
			   a.amount, 
			   0
		FROM #appyagev_work a, #split_aged b
		WHERE a.trx_ctrl_num = b.trx_ctrl_num
		AND b.cnt > 1

		IF @@error != 0
		   RETURN -1


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 153, 5 ) + ' -- MSG: ' + 'Insert payment detail records into #pay_detail'
		INSERT #pay_detail 	(trx_ctrl_num, 
							 apply_to_num, 
							 vo_amt_applied,
							 vo_amt_disc_taken,
							 mark_flag)
		SELECT a.trx_ctrl_num,
			   a.apply_to_num,
			   a.vo_amt_applied,
			   a.vo_amt_disc_taken,
			   0
		FROM #appypdt_work a, #appypyt_work b, #split_aged c
		WHERE a.trx_ctrl_num = b.trx_ctrl_num
		AND a.apply_to_num = c.trx_ctrl_num
		IF @@error != 0
		   RETURN -1


		SELECT @age_flag = 1,
		       @det_flag = 1,
			   @old_age_trx_ctrl_num = NULL,
			   @age_paid = 0.0


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 177, 5 ) + ' -- MSG: ' + 'Calculate the payment distribution for split aging'
		WHILE (1=1)
		   BEGIN

			  IF @age_flag = 1
			     BEGIN
					SET ROWCOUNT 1
					SELECT @age_trx_ctrl_num = trx_ctrl_num,
						   @age_date_aging = date_aging,
						   @age_amt_unpaid = amt_unpaid
					FROM #age_temp
					WHERE mark_flag = 0

					IF @@rowcount = 0 BREAK

					SET ROWCOUNT 0

					IF (@age_trx_ctrl_num != @old_age_trx_ctrl_num)
					   BEGIN
						  SELECT @age_paid = amt_paid_to_date
						  FROM #appytrxv_work
						  WHERE trx_ctrl_num = @age_trx_ctrl_num

						  SELECT @old_age_trx_ctrl_num = @age_trx_ctrl_num
					   END	

					IF ( ((@age_paid) >= (@age_amt_unpaid) - 0.0000001) )
					   BEGIN
							SELECT @age_paid = @age_paid - @age_amt_unpaid
							UPDATE #age_temp
							SET mark_flag = 1
							WHERE trx_ctrl_num = @age_trx_ctrl_num
							AND date_aging = @age_date_aging
							CONTINUE
					   END	
					ELSE
					   BEGIN
					   		SELECT @age_amt_unpaid = @age_amt_unpaid - @age_paid
					   		SELECT @age_paid = 0
					   END

					SELECT @age_flag = 0

				 END
			  IF @det_flag = 1
				 BEGIN
					SET ROWCOUNT 1
					SELECT @det_trx_ctrl_num = trx_ctrl_num,
						   @det_apply_to_num = apply_to_num,
						   @det_vo_amt_applied = vo_amt_applied,
						   @det_vo_amt_disc_taken = vo_amt_disc_taken
					FROM #pay_detail
					WHERE mark_flag = 0

					IF @@rowcount = 0 BREAK

					SET ROWCOUNT 0


					SELECT @det_flag = 0

				 END


				   IF @age_trx_ctrl_num > @det_apply_to_num
				      BEGIN
						 UPDATE #pay_detail
						 SET mark_flag = 1
						 WHERE apply_to_num = @det_apply_to_num

						 SELECT @det_flag = 1
						 CONTINUE
					  END
				   ELSE IF @age_trx_ctrl_num < @det_apply_to_num
				      BEGIN
						 UPDATE #age_temp
						 SET mark_flag = 1
						 WHERE trx_ctrl_num = @age_trx_ctrl_num

						 SELECT @age_flag = 1
						 CONTINUE
					  END

			   IF ( (ABS((@age_amt_unpaid)-(@det_vo_amt_applied + @det_vo_amt_disc_taken)) < 0.0000001) )
				  BEGIN
					 INSERT #paydist_age
							 (trx_ctrl_num, 
							  sequence_id, 
							  apply_to_num, 
							  date_aging, 
							  vo_amt_applied,
							  vo_amt_disc_taken)
					 VALUES(
					 @det_trx_ctrl_num,
					 0,
					 @det_apply_to_num,
					 @age_date_aging,
					 @det_vo_amt_applied,
					 @det_vo_amt_disc_taken 
					 )
					 IF @@error != 0
						   RETURN -1


					 SET ROWCOUNT 1
					 
					 UPDATE #pay_detail
					 SET mark_flag = 1
					 WHERE trx_ctrl_num = @det_trx_ctrl_num
					 AND apply_to_num = @det_apply_to_num
					 
					 UPDATE #age_temp
					 SET mark_flag = 1
					 WHERE trx_ctrl_num = @age_trx_ctrl_num
					 AND date_aging = @age_date_aging

					 SET ROWCOUNT 0

					 
					 
					 SELECT @age_flag = 1, @det_flag = 1

					 CONTINUE
				  END
					 	
			   ELSE IF ( ((@age_amt_unpaid) > (@det_vo_amt_applied + @det_vo_amt_disc_taken) + 0.0000001) )
			      BEGIN
					 INSERT #paydist_age
							 (trx_ctrl_num, 
							  sequence_id, 
							  apply_to_num, 
							  date_aging, 
							  vo_amt_applied,
							  vo_amt_disc_taken
							  )
					 VALUES(
					 @det_trx_ctrl_num,
					 0,
					 @det_apply_to_num,
					 @age_date_aging,
					 @det_vo_amt_applied,
					 @det_vo_amt_disc_taken
					 )
					 IF @@error != 0
						   RETURN -1


					 SELECT @age_amt_unpaid = @age_amt_unpaid - @det_vo_amt_applied - @det_vo_amt_disc_taken

					 SET ROWCOUNT 1
					 
					 UPDATE #pay_detail
					 SET mark_flag = 1
					 WHERE trx_ctrl_num = @det_trx_ctrl_num
					 AND apply_to_num = @det_apply_to_num
					 
					 SET ROWCOUNT 0

					 SELECT @det_flag = 1
					 CONTINUE

				  END

			   ELSE IF ( ((@age_amt_unpaid) < (@det_vo_amt_applied + @det_vo_amt_disc_taken) - 0.0000001) )
			      BEGIN

					 IF ( ((@det_amt_disc_taken) >= (@age_amt_unpaid) - 0.0000001) )
					    BEGIN
						   SELECT @vo_disc = @age_amt_unpaid
						   SELECT @vo_amt = 0.0
						END
					 ELSE
					    BEGIN
						   SELECT @vo_disc = @det_vo_amt_disc_taken
						   SELECT @vo_amt = @age_amt_unpaid - @det_vo_amt_disc_taken
						END

					 INSERT #paydist_age
							 (trx_ctrl_num, 
							  sequence_id, 
							  apply_to_num, 
							  date_aging, 
							  vo_amt_applied,
							  vo_amt_disc_taken
							  )
					 VALUES(
					 @det_trx_ctrl_num,
					 0,
					 @det_apply_to_num,
					 @age_date_aging,
					 @vo_amt,
					 @vo_disc
					 )
					 IF @@error != 0
						   RETURN -1


					 SELECT @det_vo_amt_disc_taken = @det_vo_amt_disc_taken - @vo_disc
				     SELECT @det_vo_amt_applied = @det_vo_amt_applied - @vo_amt


					 SET ROWCOUNT 1
					 
					 
					 UPDATE #age_temp
					 SET mark_flag = 1
					 WHERE trx_ctrl_num = @age_trx_ctrl_num
					 AND date_aging = @age_date_aging

					 SET ROWCOUNT 0
					 SELECT @age_flag = 1

					 CONTINUE
				  END

		   END


SET ROWCOUNT 0

INSERT #paydist (trx_ctrl_num,
				 sequence_id,
				 doc_ctrl_num,
				 cash_acct_code,
				 payment_type,
				 line_desc,
				 apply_to_num, 
				 date_aging, 
				 date_doc,
				 amt_applied, 
				 amt_disc_taken,
				 vo_amt_applied,
				 vo_amt_disc_taken,
				 gain_home,
				 gain_oper,
				 percent_paid,
				 year,
				org_id)					
SELECT		a.trx_ctrl_num,
			a.sequence_id,
			b.doc_ctrl_num,
			b.cash_acct_code,
			b.payment_type,
			c.line_desc,
			a.apply_to_num,
			a.date_aging,
			b.date_doc,
			(SIGN(c.amt_applied * (a.vo_amt_applied * SIGN(c.vo_amt_applied))/(c.vo_amt_applied + (SIGN(ABS(c.vo_amt_applied))-1))) * ROUND(ABS(c.amt_applied * (a.vo_amt_applied * SIGN(c.vo_amt_applied))/(c.vo_amt_applied + (SIGN(ABS(c.vo_amt_applied))-1))) + 0.0000001, d.curr_precision)),
			(SIGN(c.amt_disc_taken * (a.vo_amt_disc_taken * SIGN(c.vo_amt_disc_taken))/(c.vo_amt_disc_taken + (SIGN(ABS(c.vo_amt_disc_taken))-1))) * ROUND(ABS(c.amt_disc_taken * (a.vo_amt_disc_taken * SIGN(c.vo_amt_disc_taken))/(c.vo_amt_disc_taken + (SIGN(ABS(c.vo_amt_disc_taken))-1))) + 0.0000001, d.curr_precision)),
			a.vo_amt_applied,
			a.vo_amt_disc_taken,
			(SIGN(c.gain_home * (a.vo_amt_applied * SIGN(c.vo_amt_applied))/(c.vo_amt_applied + (SIGN(ABS(c.vo_amt_applied))-1))) * ROUND(ABS(c.gain_home * (a.vo_amt_applied * SIGN(c.vo_amt_applied))/(c.vo_amt_applied + (SIGN(ABS(c.vo_amt_applied))-1))) + 0.0000001, @home_precision)),
			(SIGN(c.gain_oper * (a.vo_amt_applied * SIGN(c.vo_amt_applied))/(c.vo_amt_applied + (SIGN(ABS(c.vo_amt_applied))-1))) * ROUND(ABS(c.gain_oper * (a.vo_amt_applied * SIGN(c.vo_amt_applied))/(c.vo_amt_applied + (SIGN(ABS(c.vo_amt_applied))-1))) + 0.0000001, @oper_precision)),
			0.0,
			0,
			c.org_id						
FROM #paydist_age a, #appypyt_work b, #appypdt_work c, glcurr_vw d
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.trx_ctrl_num = c.trx_ctrl_num
AND a.apply_to_num = c.apply_to_num
AND b.nat_cur_code = d.currency_code


SELECT trx_ctrl_num, 
	   apply_to_num, 
	   date_aging = MIN(date_aging),
	   amt_applied = SUM(amt_applied), 
	   amt_disc_taken = SUM(amt_disc_taken), 
	   gain_home = SUM(gain_home), 
	   gain_oper = SUM(gain_oper)
INTO #temp
FROM #paydist
GROUP BY trx_ctrl_num, apply_to_num


UPDATE #temp
SET amt_applied = b.amt_applied - #temp.amt_applied,
	amt_disc_taken = b.amt_disc_taken - #temp.amt_disc_taken,
	gain_home = b.gain_home - #temp.gain_home,
	gain_oper = b.gain_oper - #temp.gain_oper
FROM #temp, #appypdt_work b
WHERE #temp.trx_ctrl_num = b.trx_ctrl_num
AND #temp.apply_to_num = b.apply_to_num

UPDATE #paydist
SET amt_applied = #paydist.amt_applied + b.amt_applied,
	amt_disc_taken = #paydist.amt_disc_taken + b.amt_disc_taken,
	gain_home = #paydist.gain_home + b.gain_home,
	gain_oper = #paydist.gain_oper + b.gain_oper
FROM #paydist, #temp b
WHERE #paydist.trx_ctrl_num = b.trx_ctrl_num
AND #paydist.apply_to_num = b.apply_to_num
AND #paydist.date_aging = b.date_aging


DROP TABLE #temp

DROP TABLE #age_temp
DROP TABLE #pay_detail
DROP TABLE #paydist_age
END


INSERT #paydist (trx_ctrl_num,
				 sequence_id,
				 doc_ctrl_num,
				 cash_acct_code,
				 payment_type,
				 line_desc,
				 apply_to_num, 
				 date_aging, 
				 date_doc,
				 amt_applied, 
				 amt_disc_taken,
				 vo_amt_applied,
				 vo_amt_disc_taken,
				 gain_home,
				 gain_oper,
				 percent_paid,
				 year,	
				org_id)						
SELECT		a.trx_ctrl_num,
			a.sequence_id,
			b.doc_ctrl_num,
			b.cash_acct_code,
			b.payment_type,
			a.line_desc,
			a.apply_to_num,
			d.date_aging,
			b.date_doc,
			a.amt_applied,
			a.amt_disc_taken,
			a.vo_amt_applied,
			a.vo_amt_disc_taken,
			a.gain_home,
			a.gain_oper,
			0.0,
			0,
			a.org_id						
FROM #appypdt_work a, #appypyt_work b, #split_aged c, #appyagev_work d
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.apply_to_num = c.trx_ctrl_num
AND a.apply_to_num = d.trx_ctrl_num
AND c.cnt = 1



IF EXISTS (SELECT trx_ctrl_num FROM #split_aged WHERE cnt > 1)
BEGIN


			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 528, 5 ) + ' -- MSG: ' + 'Update sequence ids'
			
			UPDATE #paydist
			SET sequence_id = 0
			WHERE trx_ctrl_num IN (SELECT trx_ctrl_num FROM #paydist WHERE sequence_id = 0)


			SELECT @old_trx_num = ''
			WHILE (1=1)
				BEGIN
					SET ROWCOUNT 1

					SELECT @det_trx_ctrl_num = trx_ctrl_num
					FROM #paydist
					WHERE sequence_id = 0

					IF @@rowcount = 0 BREAK

					SET ROWCOUNT 0

					IF @old_trx_num != @det_trx_ctrl_num
					   BEGIN
							SELECT @old_trx_num = @det_trx_ctrl_num
							SELECT @sequence_id = 1 +
							   (select max (sequence_id) from 
							   #paydist where trx_ctrl_num = @det_trx_ctrl_num)

					   END

					SET ROWCOUNT 1
					UPDATE #paydist
					SET sequence_id = @sequence_id
					WHERE sequence_id = 0

					SELECT @sequence_id = @sequence_id + 1

				END

END

SET ROWCOUNT 0

DROP TABLE #split_aged















IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 587, 5 ) + ' -- MSG: ' + 'Update transaction control numbers for on_acct payments'
UPDATE #paydist
SET trx_ctrl_num = c.trx_ctrl_num
FROM #paydist, #appypyt_work b, #appytrxp_work c
WHERE #paydist.trx_ctrl_num = b.trx_ctrl_num
AND #paydist.payment_type IN (2,3)
AND b.doc_ctrl_num = c.doc_ctrl_num
AND b.cash_acct_code = c.cash_acct_code

IF @@error != 0
   RETURN -1




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 602, 5 ) + ' -- MSG: ' + 'Update sequence ids for on_acct payments'

UPDATE #paydist
SET sequence_id = #paydist.sequence_id + b.next_sequence_id 
FROM #paydist, #appytrxp_work b
WHERE #paydist.payment_type IN (2,3)
AND #paydist.trx_ctrl_num = b.trx_ctrl_num

IF @@error != 0
   RETURN -1



   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'appycpd.cpp' + ', line ' + STR( 615, 5 ) + ' -- EXIT: '
   RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYCalculatePaymentDist_sp] TO [public]
GO
