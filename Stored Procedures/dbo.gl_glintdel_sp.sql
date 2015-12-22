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
                                         CREATE PROC [dbo].[gl_glintdel_sp]  @rpt_ctry_code varchar(3), 
 @int_period_id int AS BEGIN DECLARE  @return_code int,  @post_flag smallint,  @int_ctrl_root varchar(16), 
 @disp_ctrl_num varchar(16),  @disp_err_num varchar(16),  @arr_ctrl_num varchar(16), 
 @arr_err_num varchar(16)     SELECT @post_flag = post_flag,  @int_ctrl_root = int_ctrl_root, 
 @disp_ctrl_num = disp_ctrl_num,  @disp_err_num = disp_err_num,  @arr_ctrl_num = arr_ctrl_num, 
 @arr_err_num = arr_err_num  FROM gl_glinthdr  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
 IF @@rowcount <> 1 RETURN 8140  IF @post_flag <> 0 RETURN 8143  BEGIN TRANSACTION 
    UPDATE gl_glinthdr  SET post_flag = -1  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id AND post_flag = 0 
 IF @@rowcount <> 1  BEGIN  ROLLBACK TRANSACTION  RETURN 8141  END     EXEC @return_code = gl_glintclear_sp 
 @rpt_ctry_code, @int_period_id, @int_ctrl_root, @disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num 
 IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN 8100  END     DELETE gl_glinthdr WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
 IF @@error <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN 8100  END  COMMIT TRANSACTION 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintdel_sp] TO [public]
GO
