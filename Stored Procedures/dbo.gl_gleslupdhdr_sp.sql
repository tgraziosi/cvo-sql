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
                                           CREATE PROC [dbo].[gl_gleslupdhdr_sp]  @home_ctry_code varchar(3), 
 @esl_period_id int,  @esl_ctrl_num varchar(16),  @esl_err_num varchar(16) AS BEGIN 
DECLARE  @amt_esl float,  @num_line_esl int,  @amt_err float,  @num_line_err int 
    SELECT @amt_esl = 0.0, @num_line_esl = 0, @amt_err = 0.0, @num_line_err = 0   
  SELECT @num_line_esl = COUNT(*) FROM gl_glesldet WHERE esl_ctrl_num = @esl_ctrl_num 
 SELECT @amt_esl = ISNULL(SUM(amt_rpt), 0.0) FROM gl_glesldet WHERE esl_ctrl_num = @esl_ctrl_num 
    SELECT @num_line_err = COUNT(*) FROM gl_glesldet WHERE esl_ctrl_num = @esl_err_num 
 SELECT @amt_err = ISNULL(SUM(amt_rpt), 0.0) FROM gl_glesldet WHERE esl_ctrl_num = @esl_err_num 
    UPDATE gl_gleslhdr  SET amt_esl = @amt_esl, num_line_esl = @num_line_esl,  amt_err = @amt_err, num_line_err = @num_line_err 
 WHERE home_ctry_code = @home_ctry_code AND esl_period_id = @esl_period_id  IF @@error <> 0 RETURN 8100 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslupdhdr_sp] TO [public]
GO
