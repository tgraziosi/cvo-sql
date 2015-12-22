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
                                         CREATE PROC [dbo].[gl_glintpost_sp]  @rpt_ctry_code varchar(3), 
 @int_period_id int AS BEGIN DECLARE  @post_flag smallint,  @disp_ctrl_num varchar(16), 
 @arr_ctrl_num varchar(16)  SELECT @post_flag = post_flag,  @disp_ctrl_num = disp_ctrl_num, 
 @arr_ctrl_num = arr_ctrl_num  FROM gl_glinthdr  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
 IF @@rowcount <> 1 RETURN 8140  IF @post_flag <> 0 RETURN 8143  UPDATE gl_glinthdr 
 SET post_flag = 1  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id AND post_flag = 0 
 IF @@rowcount <> 1 RETURN 8141  IF @@error <> 0 RETURN 8100       UPDATE gl_glintdet 
 SET weight_flag = 1,  supp_unit_flag = 1  WHERE int_ctrl_num = @disp_ctrl_num OR int_ctrl_num = @arr_ctrl_num 
   IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintpost_sp] TO [public]
GO
