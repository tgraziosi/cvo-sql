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
                                          CREATE PROC [dbo].[gl_gleslunpost_sp]  @home_ctry_code varchar(3), 
 @esl_period_id int AS BEGIN DECLARE  @unpost_flag smallint  UPDATE gl_gleslhdr  SET post_flag = 0 
 WHERE home_ctry_code = @home_ctry_code AND esl_period_id = @esl_period_id AND post_flag = 1 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslunpost_sp] TO [public]
GO
