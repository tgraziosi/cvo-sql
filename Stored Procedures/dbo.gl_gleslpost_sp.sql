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
                                         CREATE PROC [dbo].[gl_gleslpost_sp]  @home_ctry_code varchar(3), 
 @esl_period_id int AS BEGIN DECLARE  @post_flag smallint  SELECT @post_flag = post_flag 
 FROM gl_gleslhdr  WHERE home_ctry_code = @home_ctry_code AND esl_period_id = @esl_period_id 
 IF @@rowcount <> 1 RETURN 8140  IF @post_flag <> 0 RETURN 8143  UPDATE gl_gleslhdr 
 SET post_flag = 1  WHERE home_ctry_code = @home_ctry_code AND esl_period_id = @esl_period_id AND post_flag = 0 
 IF @@rowcount <> 1 RETURN 8141  IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslpost_sp] TO [public]
GO
