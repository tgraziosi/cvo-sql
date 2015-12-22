SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[appayedt_sp] @only_errors smallint,  @called_from smallint = 0,  @debug_level smallint = 0 
AS DECLARE  @result int,  @batch_mode smallint,  @error_level smallint IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\appayedt.sp" + ", line " + STR( 51, 5 ) + " -- ENTRY: " 
IF ((SELECT COUNT(*) FROM #appyvpyt) < 1) RETURN 0 IF @only_errors = 1  SELECT @error_level = 0 
ELSE  SELECT @error_level = 1 EXEC @result = appehdr1_sp @error_level, @called_from, @debug_level 
EXEC @result = appehdr2_sp @error_level, @called_from, @debug_level EXEC @result = appehdr3_sp @error_level, @called_from, @debug_level 
EXEC @result = appedet1_sp @error_level, @called_from, @debug_level EXEC @result = appesub1_sp @error_level, @called_from, @debug_level 
IF (@only_errors = 1)  DELETE #ewerror  FROM #ewerror a, apedterr b  WHERE a.err_code = b.err_code 
 AND b.err_type > 0 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + " " + "tmp\\appayedt.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: " 
   if (select credit_invoice_flag from apco) = 1 begin  delete #ewerror where err_code = 600 
 update #ewerror  set sequence_id = -1  from #ewerror a,  apinppdt b,  apvohdr c 
 where a.trx_ctrl_num = b.trx_ctrl_num  and a.sequence_id = b.sequence_id  and b.apply_to_num = c.trx_ctrl_num 
 and a.err_code = 570  and c.amt_net < 0  delete #ewerror where sequence_id = -1 
end    RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[appayedt_sp] TO [public]
GO
