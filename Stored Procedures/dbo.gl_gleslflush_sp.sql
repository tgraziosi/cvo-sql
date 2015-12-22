SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[gl_gleslflush_sp] AS BEGIN     UPDATE gl_glinphdr  SET esl_ctrl_num = ISNULL( 
 (SELECT esl_ctrl_num FROM #gl_glinphdr t  WHERE gl_glinphdr.src_trx_id = t.src_trx_id AND gl_glinphdr.src_ctrl_num = t.src_ctrl_num), 
 ''),  post_flag = ISNULL(  (SELECT post_flag FROM #gl_glinphdr t  WHERE gl_glinphdr.src_trx_id = t.src_trx_id AND gl_glinphdr.src_ctrl_num = t.src_ctrl_num), 
 0),  esl_rpt_cur_code = ISNULL(  (SELECT esl_rpt_cur_code FROM #gl_glinphdr t  WHERE gl_glinphdr.src_trx_id = t.src_trx_id AND gl_glinphdr.src_ctrl_num = t.src_ctrl_num), 
 '')  WHERE CONVERT(char(4), gl_glinphdr.src_trx_id) + CONVERT(char(16), gl_glinphdr.src_ctrl_num) 
 IN (SELECT CONVERT(char(4), t.src_trx_id) + CONVERT(char(16), t.src_ctrl_num)  FROM #gl_glinphdr t) 
 IF @@error <> 0 RETURN 8100     UPDATE gl_glinpdet  SET esl_ctrl_num = ISNULL(  (SELECT esl_ctrl_num FROM #gl_glinpdet t 
 WHERE gl_glinpdet.src_trx_id = t.src_trx_id AND gl_glinpdet.src_ctrl_num = t.src_ctrl_num AND gl_glinpdet.src_line_id = t.src_line_id), 
 ''),  esl_line_id = ISNULL(  (SELECT esl_line_id FROM #gl_glinpdet t  WHERE gl_glinpdet.src_trx_id = t.src_trx_id AND gl_glinpdet.src_ctrl_num = t.src_ctrl_num AND gl_glinpdet.src_line_id = t.src_line_id), 
 0),  esl_err_code = ISNULL(  (SELECT esl_err_code FROM #gl_glinpdet t  WHERE gl_glinpdet.src_trx_id = t.src_trx_id AND gl_glinpdet.src_ctrl_num = t.src_ctrl_num AND gl_glinpdet.src_line_id = t.src_line_id), 
 0),  esl_amt_rpt = ISNULL(  (SELECT esl_amt_rpt FROM #gl_glinpdet t  WHERE gl_glinpdet.src_trx_id = t.src_trx_id AND gl_glinpdet.src_ctrl_num = t.src_ctrl_num AND gl_glinpdet.src_line_id = t.src_line_id), 
 0.0)  WHERE CONVERT(char(4), gl_glinpdet.src_trx_id) + CONVERT(char(16), gl_glinpdet.src_ctrl_num) 
 IN (SELECT CONVERT(char(4), t.src_trx_id) + CONVERT(char(16), t.src_ctrl_num)  FROM #gl_glinpdet t) 
 IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslflush_sp] TO [public]
GO
