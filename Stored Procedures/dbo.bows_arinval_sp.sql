SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE PROCEDURE [dbo].[bows_arinval_sp] @debug_level smallint = 0,    
     @user_id smallint    
AS    
 DECLARE    
  @error_account_code varchar(32),    
  @error_accounts_exist int,    
  @error_account_flg int,    
  @trx_ctrl_num   varchar(16),    
  @ARApplyDocPosted int    
    
BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinval.sp' + ', line ' + STR( 24, 5 ) + ' -- ENTRY: '    
    
 SELECT  @error_account_flg = ARErrorAccountFlag,    
  @error_account_code = ErrorAccountCode,    
  @ARApplyDocPosted = ARApplyDocPosted    
 FROM  bows_Config    
    
 SELECT  a.apply_to_num,    
  a.trx_ctrl_num,    
  a.trx_type    
 INTO #bows_badApplyTo    
 FROM #arinpchg a    
 WHERE NOT ISNULL(a.apply_to_num,'') = ''    
 AND a.trx_type = 2032    
 AND NOT EXISTS( SELECT  b.trx_ctrl_num    
    FROM  artrx b    
    WHERE b.doc_ctrl_num = a.apply_to_num    
    AND b.trx_type = 2031 )    
    
 IF (@ARApplyDocPosted=0)    
  INSERT #ewerror    
  SELECT  2000,    
    20204,    
    a.apply_to_num,    
   '',    
   0,    
   0.0,    
   1,    
   a.trx_ctrl_num,    
   0,    
   '',    
    0    
  FROM #bows_badApplyTo a    
 ELSE BEGIN    
  UPDATE a    
  SET a.apply_to_num = CASE WHEN @ARApplyDocPosted=2 THEN '' ELSE a.apply_to_num END,    
   a.hold_flag = CASE WHEN @ARApplyDocPosted=1 THEN 1 ELSE a.hold_flag END,    
   a.hold_desc = CASE WHEN (a.hold_desc='') AND (@ARApplyDocPosted=1) THEN 'Invalid Apply To. See Notes!' ELSE a.hold_desc END    
  FROM #arinpchg a, #bows_badApplyTo b    
  WHERE a.trx_ctrl_num = b.trx_ctrl_num    
  AND a.trx_type = b.trx_type    
    
  INSERT INTO #bows_doc_notes (    
   trx_ctrl_num,    
   trx_type,    
   link,    
   note,    
   position_mode    
  )    
  SELECT a.trx_ctrl_num,    
   a.trx_type,    
   'HEADER:APPLY TO DOC',    
   'The credit memo is applied to an invoice ' + a.apply_to_num +    
    ' which is not found in posted invoices.' +    
    CASE    
    WHEN (@ARApplyDocPosted = 1) THEN ' Credit Memo placed on hold. Invoice should be posted prior to Credit Memo.'    
    ELSE ' Credit memo amount is placed on account.'    
    END,    
   -1    
  FROM #bows_badApplyTo a    
 END    
 DROP TABLE #bows_badApplyTo    
    
 IF ((ISNULL(@error_account_flg,1)=1) AND (NOT @error_account_code IS NULL))    
 BEGIN    
  INSERT #bows_invalid_acct(    
   trx_ctrl_num,    
   trx_type,    
   sequence_id,    
   account_code,    
   reference_code)    
  SELECT    
   trx_ctrl_num,    
   trx_type,    
   sequence_id,    
   gl_rev_acct,    
   reference_code    
  FROM #arinpcdt    
  WHERE #arinpcdt.gl_rev_acct NOT IN (SELECT account_code FROM glchart_vw WHERE account_code=#arinpcdt.gl_rev_acct)    
    
  UPDATE #arinpcdt    
  SET gl_rev_acct = @error_account_code,    
   reference_code = ''    
  FROM #arinpcdt, #bows_invalid_acct    
  WHERE #arinpcdt.trx_ctrl_num = #bows_invalid_acct.trx_ctrl_num    
  AND #arinpcdt.trx_type = #bows_invalid_acct.trx_type    
  AND #arinpcdt.sequence_id = #bows_invalid_acct.sequence_id    
    
  INSERT INTO #bows_doc_notes (    
   trx_ctrl_num,    
   trx_type,    
   sequence_id,    
   note,    
   show_line_mode,    
   position_mode    
  )    
  SELECT trx_ctrl_num,    
   trx_type,    
   sequence_id,    
   'Invalid account:' + RTRIM(account_code) +    
    CASE WHEN ISNULL(reference_code,'')='' THEN '' ELSE ';' + CHAR(13) + 'Reference code:' + reference_code END,    
   1,     
   -1     
  FROM #bows_invalid_acct    
  ORDER BY trx_ctrl_num, sequence_id    
    
  UPDATE  #arinpchg    
  SET hold_flag = 1,    
   hold_desc = 'Invalid accounts. See Notes!'    
  FROM #arinpchg, #arinpcdt, #bows_invalid_acct    
  WHERE #arinpchg.trx_ctrl_num = #bows_invalid_acct.trx_ctrl_num    
  AND #arinpcdt.trx_type = #bows_invalid_acct.trx_type    
    
 END    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinval.sp' + ', line ' + STR( 149, 5 ) + ' -- EXIT: '    
 RETURN 0    
END    
GO
GRANT EXECUTE ON  [dbo].[bows_arinval_sp] TO [public]
GO
