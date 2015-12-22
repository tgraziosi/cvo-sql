SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 




















































































































































































































































































































CREATE PROCEDURE [dbo].[arinppdt_sp]  @batch_ctrl_num varchar( 16 ),
          @debug_level    smallint = 0,
          @perf_level   smallint = 0
WITH RECOMPILE
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
  @status   int

SELECT  @status = 0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinppdt.cpp' + ', line ' + STR( 44, 5 ) + ' -- ENTRY: '


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arinppdt.cpp', 47, 'entry arinppdt_sp', @PERF_time_last OUTPUT












DELETE  arinppdt
FROM  #arinppdt_work a, arinppdt b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND a.trx_type = b.trx_type


AND db_action > 0

SELECT  @status = @@error

IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arinppdt.cpp', 70, 'delete arinppdt: delete action', @PERF_time_last OUTPUT

IF ( @status = 0 )
BEGIN
  INSERT  arinppdt ( trx_ctrl_num,
         doc_ctrl_num,
         sequence_id,
         trx_type,
         apply_to_num,
         apply_trx_type,
         customer_code,
         date_aging,
         amt_applied,
         amt_disc_taken,
         wr_off_flag,
         amt_max_wr_off,
         void_flag,
         line_desc,
         sub_apply_num,
         sub_apply_type,
         amt_tot_chg,
         amt_paid_to_date,
         terms_code,
         posting_code,
         date_doc,
         amt_inv,
         gain_home,
         gain_oper,
         inv_amt_applied,
         inv_amt_disc_taken,
         inv_amt_max_wr_off,
         inv_cur_code,
	org_id   )

  SELECT       trx_ctrl_num,
         doc_ctrl_num,
         sequence_id,
         trx_type,
         apply_to_num,
         apply_trx_type,
         customer_code,
         date_aging,
         amt_applied,
         amt_disc_taken,
         wr_off_flag,
         amt_max_wr_off,
         void_flag,
         line_desc,
         sub_apply_num,
         sub_apply_type,
         amt_tot_chg,
         amt_paid_to_date,
         terms_code,
         posting_code,
         date_doc,
         amt_inv,
         gain_home,
         gain_oper,
         inv_amt_applied,
         inv_amt_disc_taken,
         inv_amt_max_wr_off,
         inv_cur_code,
	org_id
  FROM  #arinppdt_work
  WHERE db_action > 0
  AND   db_action < 4

  SELECT  @status = @@error

  IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arinppdt.cpp', 139, 'insert arinppdt: insert action', @PERF_time_last OUTPUT
END


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arinppdt.cpp', 143, 'exit arinppdt_sp', @PERF_time_last OUTPUT

RETURN @status

GO
GRANT EXECUTE ON  [dbo].[arinppdt_sp] TO [public]
GO
