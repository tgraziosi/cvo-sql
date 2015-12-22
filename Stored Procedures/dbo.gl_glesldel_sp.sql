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
                                         CREATE PROC [dbo].[gl_glesldel_sp]  @home_ctry_code varchar(3), 
 @esl_period_id int AS BEGIN DECLARE  @return_code int,  @post_flag smallint,  @esl_ctrl_root varchar(16), 
 @esl_ctrl_num varchar(16),  @esl_err_num varchar(16)     SELECT @post_flag = post_flag, 
 @esl_ctrl_root = esl_ctrl_root,  @esl_ctrl_num = esl_ctrl_num,  @esl_err_num = esl_err_num 
 FROM gl_gleslhdr  WHERE home_ctry_code = @home_ctry_code AND esl_period_id = @esl_period_id 
 IF @@rowcount <> 1 RETURN 8140  IF @post_flag <> 0 RETURN 8143  BEGIN TRANSACTION 
    UPDATE gl_gleslhdr  SET post_flag = -1  WHERE home_ctry_code = @home_ctry_code AND esl_period_id = @esl_period_id AND post_flag = 0 
 IF @@rowcount <> 1  BEGIN  ROLLBACK TRANSACTION  RETURN 8141  END     EXEC @return_code = gl_gleslclear_sp 
 @home_ctry_code, @esl_period_id, @esl_ctrl_root, @esl_ctrl_num, @esl_err_num  IF @return_code <> 0 
 BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     DELETE gl_gleslhdr WHERE home_ctry_code = @home_ctry_code AND esl_period_id = @esl_period_id 
 IF @@error <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN 8100  END  COMMIT TRANSACTION 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glesldel_sp] TO [public]
GO
