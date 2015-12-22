SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

                                                                                 
                                                                              CREATE PROC [dbo].[ARINApplyChildInvoices_SP] @batch_ctrl_num varchar( 16 ), 
 @debug_level smallint,  @perf_level smallint AS    DECLARE  @PERF_time_last datetime 
SELECT @PERF_time_last = GETDATE()    IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\arinaci.sp", 35, "Entering ARINApplyChildInvoices_SP", @PERF_time_last OUTPUT 
DECLARE  @result int BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinaci.sp" + ", line " + STR( 41, 5 ) + " -- ENTRY: " 
                   CREATE TABLE #apply_to_amounts  (  doc_ctrl_num varchar( 16 ), 
 trx_type smallint,  amount float  )  IF( @@error != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinaci.sp" + ", line " + STR( 68, 5 ) + " -- EXIT: " 
 RETURN 34563  END  INSERT #apply_to_amounts  (  doc_ctrl_num, trx_type, amount 
 )  SELECT apply_to_num, apply_trx_type, SUM(amt_net)  FROM #arinpchg_work arinpchg 
 WHERE batch_code = @batch_ctrl_num  AND amt_net != 0.0  GROUP BY apply_to_num, apply_trx_type 
 IF( @@error != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinaci.sp" + ", line " + STR( 83, 5 ) + " -- EXIT: " 
 RETURN 34563  END  UPDATE #artrx_work  SET amt_tot_chg = amt_tot_chg + amount, 
    db_action = db_action | 1  FROM #apply_to_amounts  WHERE #apply_to_amounts.doc_ctrl_num = #artrx_work.doc_ctrl_num 
 AND #apply_to_amounts.trx_type = #artrx_work.trx_type  IF( @@error != 0 )  BEGIN 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinaci.sp" + ", line " + STR( 97, 5 ) + " -- EXIT: " 
 RETURN 34563  END  DROP TABLE #apply_to_amounts  IF( @@error != 0 )  BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinaci.sp" + ", line " + STR( 104, 5 ) + " -- EXIT: " 
 RETURN 34563  END       UPDATE #artrx_work  SET paid_flag = 0,  date_paid = 0, 
 db_action = artrx.db_action | 1  FROM #artrx_work artrx, #arinpchg_work arinpchg 
 WHERE artrx.apply_to_num = arinpchg.apply_to_num  AND artrx.apply_trx_type = arinpchg.apply_trx_type 
 AND arinpchg.amt_net > 0.0  AND arinpchg.batch_code = @batch_ctrl_num  IF( @@error != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinaci.sp" + ", line " + STR( 123, 5 ) + " -- EXIT: " 
 RETURN 34563  END       UPDATE #artrxage_work  SET paid_flag = 0,  date_paid = 0, 
 db_action = artrxage.db_action | 1  FROM #artrxage_work artrxage, #arinpchg_work arinpchg 
 WHERE artrxage.apply_to_num = arinpchg.apply_to_num  AND artrxage.apply_trx_type = arinpchg.apply_trx_type 
 AND arinpchg.amt_net > 0.0  AND arinpchg.batch_code = @batch_ctrl_num  IF( @@error != 0 ) 
 BEGIN  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinaci.sp" + ", line " + STR( 142, 5 ) + " -- EXIT: " 
 RETURN 34563  END                  IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp\\arinaci.sp", 160, "Leaving ARINApplyChildInvoices_SP", @PERF_time_last OUTPUT 
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\arinaci.sp" + ", line " + STR( 161, 5 ) + " -- EXIT: " 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[ARINApplyChildInvoices_SP] TO [public]
GO
