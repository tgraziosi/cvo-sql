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
                                          CREATE PROC [dbo].[gl_gleslrounddet_sp]  @home_ctry_code varchar(3), 
 @esl_ctrl_num varchar(16),  @esl_err_num varchar(16) AS BEGIN DECLARE @round_esl smallint 
    SELECT @round_esl = round_esl FROM gl_glctry WHERE country_code = @home_ctry_code 
 IF @@rowcount <> 1 OR @round_esl <> 0 AND @round_esl <> 1 AND @round_esl <> 2  RETURN 8121 
    IF @round_esl = 0  UPDATE gl_glesldet SET amt_rpt = CEILING(amt_rpt) WHERE esl_ctrl_num IN (@esl_ctrl_num, @esl_err_num) 
 IF @@error <> 0 RETURN 8100     IF @round_esl = 1  UPDATE gl_glesldet SET amt_rpt = ROUND(amt_rpt, 0) WHERE esl_ctrl_num IN (@esl_ctrl_num, @esl_err_num) 
 IF @@error <> 0 RETURN 8100     IF @round_esl = 2  UPDATE gl_glesldet SET amt_rpt = FLOOR(amt_rpt) WHERE esl_ctrl_num IN (@esl_ctrl_num, @esl_err_num) 
 IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslrounddet_sp] TO [public]
GO
