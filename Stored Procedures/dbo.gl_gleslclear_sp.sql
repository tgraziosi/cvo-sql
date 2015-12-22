SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                            CREATE PROC [dbo].[gl_gleslclear_sp]  @home_ctry_code varchar(3), 
 @esl_period_id int,  @esl_ctrl_root varchar(16),  @esl_ctrl_num varchar(16),  @esl_err_num varchar(16) 
AS BEGIN     UPDATE gl_gleslhdr  SET amt_esl = 0.0, num_line_esl = 0, amt_err = 0.0, num_line_err = 0 
 WHERE home_ctry_code = @home_ctry_code AND esl_period_id = @esl_period_id  IF @@error <> 0 RETURN 8100 
 DELETE FROM gl_glesldet WHERE esl_ctrl_num IN (@esl_ctrl_root, @esl_ctrl_num, @esl_err_num) 
 IF @@error <> 0 RETURN 8100  DELETE FROM gl_gleslerr WHERE esl_ctrl_num IN (@esl_ctrl_root, @esl_ctrl_num, @esl_err_num) 
 IF @@error <> 0 RETURN 8100     UPDATE gl_glinphdr  SET esl_ctrl_num = "", esl_rpt_cur_code = "" 
 WHERE esl_ctrl_num IN (@esl_ctrl_root, @esl_ctrl_num, @esl_err_num) OR esl_ctrl_num IS NULL 
 IF @@error <> 0 RETURN 8100  UPDATE gl_glinpdet  SET esl_ctrl_num = "", esl_line_id = 0, esl_err_code = 0, esl_amt_rpt = 0.0 
 WHERE esl_ctrl_num IN (@esl_ctrl_root, @esl_ctrl_num, @esl_err_num) OR esl_ctrl_num IS NULL 
 IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslclear_sp] TO [public]
GO
