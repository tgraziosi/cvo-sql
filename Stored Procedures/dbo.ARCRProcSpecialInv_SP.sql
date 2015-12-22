SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










 



					 










































 





























































































































































































































































































































































































































































































 









































































































CREATE PROC [dbo].[ARCRProcSpecialInv_SP] @batch_ctrl_num varchar( 16 ),
 @trx_ctrl_num varchar( 16),
 @max_sequence_id int OUTPUT,  
 @customer_code varchar( 8 ),
 @apply_to_num varchar( 16 ),
 @apply_trx_type int,
 @amt_applied float, 
 @amt_disc_taken float, 
 @amt_max_wr_off float, 
 @wr_off_flag smallint, 
 @gain_home float,
 @gain_oper float,
 @debug_level smallint = 0, 
 @perf_level smallint = 0
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE 
 
 @doc_ctrl_num varchar( 16 ), 
 @trx_type smallint, 
 @date_aging int,
 @date_due int,
 @amt_due float,
 @inv_amt_applied float, 
 @inv_amt_disc_taken float,
 @sequence_id int,
 @overpay_flag int,  
 @curr_precision smallint,
 @first_rec smallint 
 
BEGIN
 IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrpsi.sp", 93, "Entering ARCRProcSpecialInv_SP", @PERF_time_last OUTPUT
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrpsi.sp" + ", line " + STR( 94, 5 ) + " -- ENTRY: "
 
 IF (@debug_level >= 2 )
 BEGIN
 SELECT "Arguments passed in from arcrppd.sp...."
 SELECT "trx_ctrl_num = " + @trx_ctrl_num +
 "apply_to_num = " + @apply_to_num +
 "amt_applied = " + STR(@amt_applied, 10, 2 ) +
 "amt_disc_taken = " + STR(@amt_disc_taken, 10, 2 ) +
 "wr_off_flag = " + STR(@wr_off_flag, 3 ) +
 "max_sequence_id = " + STR(@max_sequence_id, 3) +
 "gain_home = " + STR(@gain_home, 10, 2 ) +
 "gain_oper = " + STR(@gain_oper, 10, 2 )
 END
 
 DELETE #arcrinv
 
 SELECT @overpay_flag = 0
 
 IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrpsi.sp", 113, "Start INSERT #arcrinv...", @PERF_time_last OUTPUT
 
 IF ( @apply_to_num = 'BAL-FORWARD' )
 
 INSERT #arcrinv ( doc_ctrl_num, 
 trx_type,
 apply_to_num, 
 apply_trx_type,
 date_aging, 
 date_due, 
 amt_due, 
 inv_amt_applied,
 inv_amt_disc_taken,
 inv_amt_wr_off,
 gain_home,
 gain_oper,
 sequence_id ) 
 SELECT doc_ctrl_num, 
 trx_type, 
 apply_to_num,
 apply_trx_type, 
 date_aging,
 date_due,
 ROUND( (amount+amt_fin_chg+amt_late_chg-amt_paid ), curr_precision),
 0.0, 0.0, 0.0, 0.0, 0.0, 0
 FROM #artrxage_work, glcurr_vw
 WHERE customer_code = @customer_code
 AND paid_flag = 0 
 AND doc_ctrl_num = sub_apply_num 
 AND trx_type = sub_apply_type
 AND nat_cur_code = currency_code 

 ELSE
 
 
 INSERT #arcrinv ( doc_ctrl_num, 
 trx_type,
 apply_to_num,
 apply_trx_type,
 date_aging, 
 date_due, 
 amt_due,
 inv_amt_applied,
 inv_amt_disc_taken,
 inv_amt_wr_off,
 gain_home,
 gain_oper,
 sequence_id )
 SELECT doc_ctrl_num, 
 trx_type, 
 apply_to_num,
 apply_trx_type, 
 date_aging, 
 date_due, 
 ROUND(( amount+amt_fin_chg+amt_late_chg-amt_paid ), curr_precision),
 0.0, 0.0, 0.0, 0.0, 0.0, 0
 FROM #artrxage_work, glcurr_vw
 WHERE trx_type in (2021, 2031, 2071)
 AND apply_to_num = @apply_to_num
 AND apply_trx_type = @apply_trx_type
 AND nat_cur_code = currency_code
 
 IF( @@error != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrpsi.sp" + ", line " + STR( 180, 5 ) + " -- EXIT: "
 RETURN 34563
 END

 IF (@debug_level >= 2 )
 BEGIN
 SELECT "dumping #arcrinv..."
 SELECT "doc_ctrl_num = " + doc_ctrl_num +
 "date_aging = " + STR(date_aging, 8 ) +
 "date_due = " + STR(date_due, 8 ) +
 "amt_due = " + STR(amt_due, 10, 2 ) +
 "gain_home = " + STR(gain_home, 10, 2 ) +
 "gain_oper = " + STR(gain_oper, 10, 2 )
 FROM #arcrinv
 END
 
 IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrpsi.sp", 196, "Start UPDATE #arcrinv.amt_due...", @PERF_time_last OUTPUT

 
 UPDATE #arcrinv
 SET amt_due = amt_due - ISNULL
 ((SELECT SUM(inv_amt_applied+inv_amt_disc_taken+inv_amt_wr_off)
 FROM #artrxpdt_work pdt, #artrxage_work age
 WHERE pdt.apply_to_num = #arcrinv.apply_to_num
 AND pdt.apply_trx_type = #arcrinv.apply_trx_type
 AND pdt.date_aging = #arcrinv.date_aging
 AND pdt.apply_to_num = age.doc_ctrl_num
 AND pdt.apply_trx_type = age.trx_type
 AND pdt.sequence_id = age.ref_id
 AND age.date_due = #arcrinv.date_due
 AND pdt.sub_apply_num = #arcrinv.doc_ctrl_num ), 0.0 )
 
 IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrpsi.sp", 216, "Going into @amt_applied>0 WHILE loop", @PERF_time_last OUTPUT


 SELECT @first_rec = 1
  
 WHILE ( ROUND(@amt_applied,6) > 0.0 ) 
 BEGIN
 SET ROWCOUNT 1
 
 SELECT @doc_ctrl_num = doc_ctrl_num,
 @trx_type = trx_type,
 @date_aging = date_aging,
 @date_due = date_due,
 @amt_due = amt_due
 FROM #arcrinv
 WHERE amt_due > 0.0
 OR @overpay_flag = 1
 ORDER BY date_due 
 
 IF ( @@rowcount = 0 )
 BEGIN
 
 SELECT @overpay_flag = 1
 CONTINUE
 END
 
 SET ROWCOUNT 0
 
 
 IF ( @first_rec = 1 )
 BEGIN
 UPDATE #arcrinv
 SET gain_home = @gain_home,
 gain_oper = @gain_oper
 WHERE doc_ctrl_num = @doc_ctrl_num
 AND trx_type = @trx_type
 AND date_aging = @date_aging
 AND date_due = @date_due
 
 SELECT @first_rec = 0
 END
 
 
 IF ( @debug_level >= 2 )
 SELECT "Processing.." + 
 @doc_ctrl_num + " " + 
 STR(@date_aging, 8 ) + 
 STR(@date_due, 8 ) + 
 STR(@amt_due, 10, 2) +
 STR(@max_sequence_id, 3)
 
 SELECT @max_sequence_id = @max_sequence_id + 1
 
 
 IF ( @overpay_flag = 1 )
 SELECT @inv_amt_applied = @amt_applied,
 @amt_applied = 0.0
 
 ELSE IF ( @amt_applied > @amt_due ) 
 BEGIN
 SELECT @inv_amt_applied = @amt_due,
 @amt_applied = @amt_applied - @amt_due
 
 END 
 ELSE IF ( @amt_applied < @amt_due )
 SELECT @inv_amt_applied = @amt_applied,
 @amt_applied = 0.0
 
 ELSE
 SELECT @inv_amt_applied = @amt_due,
 @amt_applied = 0.0
 
 UPDATE #arcrinv
 SET inv_amt_applied = inv_amt_applied + @inv_amt_applied,
 amt_due = amt_due - @inv_amt_applied,
 sequence_id = @max_sequence_id
 WHERE doc_ctrl_num = @doc_ctrl_num
 AND trx_type = @trx_type
 AND date_aging = @date_aging
 AND date_due = @date_due
 
 IF (@debug_level >= 2 )
 SELECT "after applying to " + @doc_ctrl_num + ":" + 
 "@amt_applied = " + STR( @amt_applied, 10, 2 )
 
 END
 
 IF (@debug_level >= 2 )
 BEGIN
 SELECT "dumping #arcrinv....after using up @amt_applied"
 SELECT "doc_ctrl_num = " + doc_ctrl_num +
 "date_aging = " + STR(date_aging, 8 ) +
 "amt_due = " + STR(amt_due, 10, 2 ) +
 "inv_amt_applied " + STR(inv_amt_applied, 10, 2) +
 "inv_amt_disc_taken " + STR(inv_amt_disc_taken, 10, 2)+
 "inv_amt_wr_off " + STR(inv_amt_wr_off, 10, 2) +
 "gain_home = " + STR(gain_home, 10, 2 ) +
 "gain_oper = " + STR(gain_oper, 10, 2) +
 "sequence_id " + STR(sequence_id, 8 ) 
 FROM #arcrinv
 END
 
 IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrpsi.sp", 330, "Going into @amt_disc_taken>0 WHILE loop", @PERF_time_last OUTPUT
  
 WHILE ( ROUND(@amt_disc_taken,6) > 0.0 ) 
 BEGIN
 SET ROWCOUNT 1
 
 SELECT @doc_ctrl_num = doc_ctrl_num,
 @trx_type = trx_type,
 @date_aging = date_aging,
 @date_due = date_due,
 @amt_due = amt_due,
 @sequence_id = sequence_id
 FROM #arcrinv
 WHERE SIGN(amt_due) + @overpay_flag > 0.0
 ORDER BY date_due
 
 IF ( @@rowcount = 0 )
 BEGIN
 SELECT @overpay_flag = 1
 CONTINUE
 END
 
 SET ROWCOUNT 0
 
 
 IF ( @sequence_id = 0 ) 
 SELECT @max_sequence_id = @max_sequence_id + 1
 
 
 IF ( @overpay_flag = 1 )
 SELECT @inv_amt_disc_taken = @amt_disc_taken,
 @amt_disc_taken = 0.0
 IF ( @amt_disc_taken > @amt_due ) 
 SELECT @inv_amt_disc_taken = @amt_due,
 @amt_disc_taken = @amt_disc_taken - @amt_due
 ELSE IF ( @amt_disc_taken < @amt_due )
 SELECT @inv_amt_disc_taken = @amt_disc_taken,
 @amt_disc_taken = 0.0
 ELSE
 SELECT @inv_amt_disc_taken = @amt_due,
 @amt_disc_taken = 0.0
 
 UPDATE #arcrinv
 SET inv_amt_disc_taken = @inv_amt_disc_taken,
 amt_due = amt_due - @inv_amt_disc_taken,
 sequence_id = ABS(SIGN(sequence_id)-1)*@max_sequence_id
 + SIGN(sequence_id)*sequence_id 
 WHERE doc_ctrl_num = @doc_ctrl_num
 AND trx_type = @trx_type
 AND date_aging = @date_aging
 AND date_due = @date_due
 END
 
 IF (@debug_level >= 2 )
 BEGIN
 SELECT "dumping #arcrinv....after using up @amt_disc_taken"
 SELECT "doc_ctrl_num = " + doc_ctrl_num +
 "date_aging = " + STR(date_aging, 8 ) +
 "date_due = " + STR(date_due, 8 ) +
 "amt_due = " + STR(amt_due, 10, 2 ) +
 "inv_amt_applied " + STR(inv_amt_applied, 10, 2) +
 "inv_amt_disc_taken " + STR(inv_amt_disc_taken, 10, 2)+
 "inv_amt_wr_off " + STR(inv_amt_wr_off, 10, 2) +
 "sequence_id " + STR(sequence_id, 8 ) 
 FROM #arcrinv
 END

 IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrpsi.sp", 404, "Going into @wr_off_flag=1 WHILE loop", @PERF_time_last OUTPUT
 
 
 WHILE (@wr_off_flag = 1)
 BEGIN
 SET ROWCOUNT 1
 
 SELECT @doc_ctrl_num = doc_ctrl_num,
 @trx_type = trx_type,
 @date_aging = date_aging,
 @date_due = date_due,
 @amt_due = amt_due,
 @sequence_id = sequence_id
 FROM #arcrinv
 WHERE amt_due > 0.0
 ORDER BY date_due
 
 IF ( @@rowcount = 0 )
 BEGIN
 SET ROWCOUNT 0
 BREAK 
 END
 
 SET ROWCOUNT 0
 
 
 IF ( @sequence_id = 0 ) 
 SELECT @max_sequence_id = @max_sequence_id + 1

 
 IF ( ROUND(@amt_max_wr_off,6) < ROUND(@amt_due,6) )
 BEGIN
 SELECT "!!! Error in split aged payment"
 UPDATE #arcrinv
 SET inv_amt_wr_off = 0.0,
 amt_due = 0.0,
 sequence_id = ABS(SIGN(sequence_id)-1)*@max_sequence_id
 + SIGN(sequence_id)*sequence_id 
 WHERE doc_ctrl_num = @doc_ctrl_num
 AND trx_type = @trx_type
 AND date_aging = @date_aging
 AND date_due = @date_due
 END
 ELSE 
 UPDATE #arcrinv
 SET inv_amt_wr_off = @amt_due,
 amt_due = 0.0,
 sequence_id = ABS(SIGN(sequence_id)-1)*@max_sequence_id
 + SIGN(sequence_id)*sequence_id 
 WHERE doc_ctrl_num = @doc_ctrl_num
 AND trx_type = @trx_type
 AND date_aging = @date_aging
 AND date_due = @date_due
 END
 
 IF (@debug_level >= 2 )
 BEGIN
 SELECT "dumping #arcrinv....after processing wr_off_flag"
 SELECT "doc_ctrl_num = " + doc_ctrl_num +
 "date_aging = " + STR(date_aging, 8 ) +
 "date_due = " + STR(date_due, 8 ) +
 "amt_due = " + STR(amt_due, 10, 2 ) +
 "inv_amt_applied " + STR(inv_amt_applied, 10, 2) +
 "inv_amt_disc_taken " + STR(inv_amt_disc_taken, 10, 2)+
 "inv_amt_wr_off " + STR(inv_amt_wr_off, 10, 2) +
 "sequence_id " + STR(sequence_id, 8 ) 
 FROM #arcrinv
 END
 
 IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrpsi.sp", 478, "Start DELETE #arcrinv...", @PERF_time_last OUTPUT

 
 DELETE #arcrinv
 WHERE inv_amt_applied = 0.0
 AND inv_amt_disc_taken = 0.0
 AND inv_amt_wr_off = 0.0

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrpsi.sp" + ", line " + STR( 489, 5 ) + " -- EXIT: " 
 IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcrpsi.sp", 490, "Leaving ARCRProcSpecialInv_SP", @PERF_time_last OUTPUT 
 RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCRProcSpecialInv_SP] TO [public]
GO
