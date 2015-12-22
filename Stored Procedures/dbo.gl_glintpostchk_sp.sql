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
                                         CREATE PROC [dbo].[gl_glintpostchk_sp]  @rpt_ctry_code varchar(3), 
 @int_period_id int AS BEGIN DECLARE  @intra_errors int  select @intra_errors = num_disp_err_line + num_arr_err_line from gl_glinthdr 
 WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id AND post_flag = 0 
 IF @intra_errors <>0 RETURN 8193  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintpostchk_sp] TO [public]
GO
