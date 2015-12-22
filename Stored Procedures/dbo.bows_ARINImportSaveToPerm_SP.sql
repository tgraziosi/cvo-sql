SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE PROCEDURE [dbo].[bows_ARINImportSaveToPerm_SP] @user_id  smallint,    
      @debug_level  smallint = 0    
    
AS    
BEGIN    
 DECLARE    
  @batch_code  varchar( 16 ),    
  @result   smallint,    
  @user_name   varchar(30),    
  @batch_description  varchar(30),    
  @batch_close_flg  int,    
  @batch_hold_flg  int,    
  @completed_date  int,    
  @completed_time  int,    
  @company_code   varchar(8),    
  @datenow  int    
    
 DECLARE    
   @next_control_num  varchar(16),    
   @next_document_num  varchar(16),    
   @next_number  int,    
   @next_number_type  int,    
   @link    varchar(16),    
  @trx_type  int,    
  @printed_flag  smallint    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 51, 5 ) + ' -- ENTRY: '    
    
 SELECT  @company_code = glcomp_vw.company_code    
  FROM  glcomp_vw (nolock), glco    
  WHERE  glcomp_vw.company_id = glco.company_id    
    
 SELECT @datenow = datediff( day, '01/01/1900', getdate() ) + 693596    
    
 IF EXISTS(SELECT 1 FROM #bows_doc_notes) BEGIN    
    
  UPDATE  #bows_doc_notes    
  SET mark_flag = 0    
    
  INSERT #bows_doc_notes(    
   trx_ctrl_num, trx_type,sequence_id,    
   link,note,show_line_mode,position_mode,mark_flag)    
  SELECT trx_ctrl_num, trx_type,sequence_id,    
   link,note,show_line_mode,position_mode,1    
  FROM #bows_doc_notes    
  ORDER BY trx_ctrl_num, position_mode, sequence_id    
    
  INSERT #comments(    
    company_code,    
   key_1,    
    key_type,    
   sequence_id,    
   date_created,    
    created_by,    
    date_updated,    
   updated_by,    
   link_path,    
    note)    
  SELECT @company_code,    
   trx_ctrl_num,    
   trx_type,    
   note_sequence + 1 -    
    ISNULL((SELECT MIN(b.note_sequence)    
    FROM #bows_doc_notes b    
    WHERE b.trx_ctrl_num = a.trx_ctrl_num    
    AND b.mark_flag=1),0),    
   @datenow,    
   @user_id,    
   @datenow,    
   @user_id,    
   CASE    
     WHEN (show_line_mode=1) and (not sequence_id is null) THEN    
    LEFT(('Line: ' + convert(varchar,sequence_id) +    
  CASE WHEN link IS NULL THEN '' ELSE ';' + link END), 255)    
     ELSE link    
   END,    
   CASE    
    WHEN (show_line_mode=2) and (not sequence_id is null) THEN    
  LEFT(('Line: ' + convert(varchar,sequence_id) + ';' + ISNULL(note,'')), 255)    
    ELSE note    
   END    
  FROM #bows_doc_notes a    
  WHERE a.mark_flag = 1    
  ORDER BY note_sequence    
 END    
    
 DELETE #arinpchg    
 FROM #ewerror    
 WHERE #arinpchg.trx_ctrl_num = #ewerror.trx_ctrl_num    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 122, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 DELETE #arinpcdt    
 FROM #ewerror    
 WHERE #arinpcdt.trx_ctrl_num = #ewerror.trx_ctrl_num    
 AND #arinpcdt.trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #arinpchg)    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 132, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 DELETE #arinpage    
 FROM #ewerror    
 WHERE #arinpage.trx_ctrl_num = #ewerror.trx_ctrl_num    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 141, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 DELETE #arinptax    
 FROM #ewerror    
 WHERE #arinptax.trx_ctrl_num = #ewerror.trx_ctrl_num    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 150, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 DELETE #arinprev    
 FROM #ewerror    
 WHERE #arinprev.trx_ctrl_num = #ewerror.trx_ctrl_num    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 159, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 DELETE #arinpcom    
 FROM #ewerror    
 WHERE #arinpcom.trx_ctrl_num = #ewerror.trx_ctrl_num    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 169, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 DELETE #comments    
 FROM #ewerror    
 WHERE #comments.key_1 = #ewerror.trx_ctrl_num    
 IF( @@error != 0 )    
 BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 178, 5 ) + ' -- EXIT: '    
   RETURN 34563    
 END    
    
 IF NOT EXISTS(SELECT 1 FROM #arinpchg)    
  RETURN -1    
    
     
    
 SELECT @link=CHAR(0)    
 WHILE (1=1) BEGIN    
  SET ROWCOUNT 1    
  SELECT  @link   = link,    
   @trx_type = trx_type,    
   @printed_flag  = printed_flag    
    FROM  #arinpchg    
    WHERE link > @link    
   ORDER BY link    
    
  IF @@rowcount=0 BREAK    
  SET ROWCOUNT 0    
    
  SELECT @next_number_type=CASE    
   WHEN (@trx_type=2031) THEN 2000    
   WHEN (@trx_type=2032) THEN 2020    
   ELSE 2000    
   END    
    
  EXEC @result = ARGetNextControl_SP     
     @next_number_type,    
      @next_control_num OUTPUT,    
      @next_number OUTPUT    
    
  IF (@printed_flag = 1) BEGIN    
   SELECT @next_number_type=CASE    
    WHEN (@trx_type=2031) THEN 2001    
    WHEN (@trx_type=2032) THEN 2021    
    ELSE 2001    
    END    
    
   EXEC @result = ARGetNextControl_SP     
     @next_number_type,    
      @next_document_num OUTPUT,    
      @next_number OUTPUT    
  END    
    
   UPDATE #arinpchg    
    SET  trx_ctrl_num  = @next_control_num,    
   doc_ctrl_num = CASE @printed_flag WHEN 1 THEN @next_document_num ELSE doc_ctrl_num END,     
   doc_desc = CASE @printed_flag WHEN 1 THEN doc_desc+' '+@next_document_num ELSE doc_desc END    --Rev SCR 6965    
   WHERE  link = @link    
  IF( @@error != 0 ) BEGIN    
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 235, 5 ) + ' -- EXIT: '    
   RETURN 34563    
  END    
 END --(1=1)    
 SET ROWCOUNT 0    
    
 UPDATE d    
  SET  d.trx_ctrl_num = h.trx_ctrl_num,    
  d.trx_type = h.trx_type,    
  d.doc_ctrl_num = h.doc_ctrl_num    
 FROM #arinpcdt d, #arinpchg h    
 WHERE  d.link = h.link    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 249, 5 ) + ' -- EXIT: '    
  RETURN 34563    
 END    
    
 UPDATE d    
  SET  d.trx_ctrl_num = h.trx_ctrl_num,    
  d.trx_type = h.trx_type,    
  d.doc_ctrl_num = h.doc_ctrl_num    
 FROM #arinpage d, #arinpchg h    
 WHERE  d.trx_ctrl_num = h.link    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 261, 5 ) + ' -- EXIT: '    
  RETURN 34563    
 END    
    
 UPDATE d    
  SET  d.trx_ctrl_num = h.trx_ctrl_num,    
  d.trx_type = h.trx_type    
 FROM #arinptax d, #arinpchg h    
 WHERE  d.trx_ctrl_num = h.link    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 271, 5 ) + ' -- EXIT: '    
  RETURN 34563    
 END    
    
 UPDATE d    
  SET  d.trx_ctrl_num = h.trx_ctrl_num,    
  d.trx_type = h.trx_type    
 FROM #arinprev d, #arinpchg h    
 WHERE  d.trx_ctrl_num = h.link    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 281, 5 ) + ' -- EXIT: '    
  RETURN 34563    
 END    
    
 UPDATE d    
  SET  d.trx_ctrl_num = h.trx_ctrl_num,    
  d.trx_type = h.trx_type    
 FROM #arinpcom d, #arinpchg h    
 WHERE  d.trx_ctrl_num = h.link    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 291, 5 ) + ' -- EXIT: '    
  RETURN 34563    
 END    
    
 UPDATE  d    
  SET  d.key_1 = h.trx_ctrl_num    
 FROM #comments d, #arinpchg h    
 WHERE  d.key_1 = h.link    
 IF( @@error != 0 ) BEGIN    
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 301, 5 ) + ' -- EXIT: '    
  RETURN 34563    
 END    
    
 UPDATE  b    
 SET  b.trx_ctrl_num = a.trx_ctrl_num    
 FROM #arinpchg a, #bows_arinpchg_link b    
 WHERE a.link=b.trx_ctrl_num    
    
 IF @debug_level>5 BEGIN    
  SELECT '**** #arinpchg before save ****'    
  SELECT * FROM #arinpchg    
  SELECT '**** #arinpcdt before save ****'    
  SELECT * FROM #arinpcdt    
  SELECT '**** #arinpage before save ****'    
  SELECT * FROM #arinpage    
  SELECT '**** #arinptax before save ****'    
  SELECT * FROM #arinptax    
  SELECT '**** #arinprev before save ****'    
  SELECT * FROM #arinprev    
  SELECT '**** #arinpcom before save ****'    
  SELECT * FROM #arinpcom    
  SELECT '**** #comments before save ****'    
  SELECT * FROM #comments    
 END    
    
CREATE TABLE #arinbat    
(    
 date_applied  int,    
 process_group_num varchar(16),    
 trx_type  smallint,    
 batch_ctrl_num char(16) NULL,    
 flag   smallint,    
 org_id  varchar(30)    
)    
    
CREATE TABLE #arbatsum    
(    
 batch_ctrl_num char(16) NOT NULL,    
 actual_number int NOT NULL,    
 actual_total float NOT NULL    
)    
    
CREATE TABLE #arbatnum    
(    
 date_applied  int,    
 process_group_num varchar(16),    
 trx_type  smallint,    
 flag   smallint,    
 batch_ctrl_num  char(16) NULL,    
 batch_description char(30) NULL,    
 company_code char(8) NULL,    
 seq   numeric identity,     
 org_id  varchar(30)    
)    
    
 SELECT  @batch_description  = ARBatchDescription,    
  @batch_close_flg  = ARBatchCloseFlag,    
  @batch_hold_flg  = ARBatchHoldFlag    
 FROM  bows_Config    
    
 SELECT  @user_name = [user_name]    
 FROM  ewusers_vw    
 WHERE  [user_id] = @user_id    
    
  exec appdate_sp @completed_date output    
  exec apptime_sp @completed_time output    
    
 BEGIN TRAN    
    
  EXEC @result = bows_arinsav_sp @user_id, @batch_code OUTPUT    
    
  IF ( @result != 0 )    
  BEGIN    
   ROLLBACK TRAN    
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 353, 5 ) + ' -- EXIT: '    
   RETURN @result    
  END    
    
  IF EXISTS(SELECT 1 FROM #comments)    
  BEGIN    
   INSERT comments(    
     company_code,    
     key_1,    
     key_type,    
    sequence_id,    
     date_created,    
     created_by,    
     date_updated,    
    updated_by,    
    link_path,    
     note)    
   SELECT    
     company_code,    
     key_1,    
     key_type,    
    sequence_id,    
     date_created,    
     created_by,    
     date_updated,    
    updated_by,    
    link_path,    
     note    
   FROM #comments    
  END    
    
  IF EXISTS( SELECT 1 FROM arco WHERE batch_proc_flag = 1 )    
  BEGIN    
   SELECT @batch_description = ISNULL(@batch_description, 'Imported batch') + ': ' + CONVERT(char(12), GETDATE(), 3)    
   IF ((ISNULL(@batch_close_flg,1) = 1) AND (ISNULL(@batch_hold_flg,0) = 0))    
   BEGIN       
    UPDATE  batchctl    
    SET batch_description = @batch_description,    
     completed_user = batchctl.start_user,    
     completed_date = @completed_date,    
     completed_time = @completed_time,    
     control_number = batchctl.actual_number,    
     control_total = batchctl.actual_total    
    FROM batchctl, arinpchg, #bows_arinpchg_link    
    WHERE  batchctl.batch_ctrl_num = arinpchg.batch_code    
    AND arinpchg.trx_ctrl_num = #bows_arinpchg_link.trx_ctrl_num    
    SELECT @result = @@error    
    IF ( @result != 0 )    
    BEGIN    
     ROLLBACK TRANSACTION    
     IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 408, 5 ) + ' -- EXIT: '    
     RETURN @result    
     END    
   END ELSE    
   BEGIN    
    UPDATE  batchctl    
    SET batch_description = @batch_description,    
     hold_flag = ISNULL(@batch_hold_flg,0)    
    FROM batchctl, arinpchg, #bows_arinpchg_link    
    WHERE  batchctl.batch_ctrl_num = arinpchg.batch_code    
    AND arinpchg.trx_ctrl_num = #bows_arinpchg_link.trx_ctrl_num    
    SELECT @result = @@error    
    IF ( @result != 0 )    
    BEGIN    
     ROLLBACK TRANSACTION    
     IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 423, 5 ) + ' -- EXIT: '    
     RETURN @result    
     END    
   END    
    
   IF (ISNULL(@batch_hold_flg,0)=0)    
   BEGIN    
    UPDATE  batchctl    
    SET hold_flag = 1    
    FROM batchctl, arinpchg, #bows_invalid_acct    
    WHERE  batchctl.batch_ctrl_num = arinpchg.batch_code    
    AND arinpchg.trx_ctrl_num = #bows_invalid_acct.trx_ctrl_num    
    AND arinpchg.trx_type = #bows_invalid_acct.trx_type    
    SELECT @result = @@error    
    IF ( @result != 0 )    
    BEGIN    
     ROLLBACK TRANSACTION    
     IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 440, 5 ) + ' -- EXIT: '    
     RETURN @result    
     END    
   END    
  END    
    
 COMMIT TRAN    
    
 DROP TABLE #arinbat    
    
 DROP TABLE #arbatsum    
 DROP TABLE #arbatnum    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinistp.sp' + ', line ' + STR( 453, 5 ) + ' -- EXIT: '    
    
 RETURN 0    
END 
GO
GRANT EXECUTE ON  [dbo].[bows_ARINImportSaveToPerm_SP] TO [public]
GO
