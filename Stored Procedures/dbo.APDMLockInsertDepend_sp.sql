SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

   CREATE PROC [dbo].[APDMLockInsertDepend_sp]  @process_group_num varchar(16),  @debug_level smallint = 0 
AS DECLARE  @result int IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apdmlid.sp" + ", line " + STR( 72, 5 ) + " -- ENTRY: " 
 BEGIN TRAN LOCKDEPS  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apdmlid.sp" + ", line " + STR( 76, 5 ) + " -- MSG: " + "mark vouchers in aptrx" 
 UPDATE apvohdr  SET state_flag = -1,  process_ctrl_num = @process_group_num  FROM apvohdr a, #apdmchg_work b 
 WHERE a.trx_ctrl_num = b.apply_to_num  AND a.state_flag = 1  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apdmlid.sp" + ", line " + STR( 86, 5 ) + " -- MSG: " + "insert vouchers that could not be marked in #ewerror" 
 INSERT #ewerror( module_id,  err_code,  info1,  info2,  infoint,  infofloat,  flag1, 
 trx_ctrl_num,  sequence_id,  source_ctrl_num,  extra  )  SELECT 4000,  21150,  b.apply_to_num, 
 "",  0,  0.0,  1,  b.trx_ctrl_num,  0,  "",  0  FROM apvohdr a, #apdmchg_work b 
 WHERE a.trx_ctrl_num = b.apply_to_num  AND a.process_ctrl_num != @process_group_num 
 COMMIT TRAN LOCKDEPS  INSERT #apdmxv_work(  trx_ctrl_num,  amt_net,  amt_paid_to_date) 
 SELECT  a.trx_ctrl_num,  a.amt_net,  a.amt_paid_to_date  FROM apvohdr a, #apdmchg_work b 
 WHERE a.process_ctrl_num = @process_group_num  AND a.state_flag = -1  AND a.trx_ctrl_num = b.apply_to_num 
 IF( @@error != 0)  RETURN -1         INSERT #apdmxcdv_work  (  trx_ctrl_num,  sequence_id, 
 qty_returned,  qty_prev_returned,  db_action  )  SELECT  a.trx_ctrl_num,  a.sequence_id, 
 a.qty_returned,  a.qty_returned,  0  FROM apvodet a, #apdmxv_work b  WHERE a.trx_ctrl_num = b.trx_ctrl_num 
 IF( @@error != 0 )  RETURN -1  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\apdmlid.sp" + ", line " + STR( 162, 5 ) + " -- EXIT: " 
 RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[APDMLockInsertDepend_sp] TO [public]
GO
