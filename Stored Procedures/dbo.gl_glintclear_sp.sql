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
                                              CREATE PROC [dbo].[gl_glintclear_sp]  @rpt_ctry_code varchar(3), 
 @int_period_id int,  @int_ctrl_root varchar(16),  @disp_ctrl_num varchar(16),  @disp_err_num varchar(16), 
 @arr_ctrl_num varchar(16),  @arr_err_num varchar(16) AS BEGIN     UPDATE gl_glinthdr 
 SET amt_disp = 0.0, num_disp_line = 0,  amt_err_disp = 0.0, num_disp_err_line = 0, 
 amt_arr = 0.0, num_arr_line = 0,  amt_err_arr = 0.0, num_arr_err_line = 0  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
 IF @@error <> 0 RETURN 8100  DELETE FROM gl_glintdet  WHERE int_ctrl_num IN (@int_ctrl_root, @disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num) 
 IF @@error <> 0 RETURN 8100  DELETE FROM gl_glinterr  WHERE int_ctrl_num IN (@int_ctrl_root, @disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num) 
 IF @@error <> 0 RETURN 8100     UPDATE gl_glinphdr  SET disp_ctrl_num = "",  arr_ctrl_num = "", 
 int_rpt_cur_code = ""  WHERE disp_ctrl_num IN (@int_ctrl_root, @disp_ctrl_num, @disp_err_num) 
 OR arr_ctrl_num IN (@int_ctrl_root, @arr_ctrl_num, @arr_err_num)  OR disp_ctrl_num IS NULL 
 OR arr_ctrl_num IS NULL  IF @@error <> 0 RETURN 8100  UPDATE gl_glinpdet  SET disp_ctrl_num = "", disp_line_id = 0, 
 arr_ctrl_num = "", arr_line_id = 0,  int_err_code = 0, int_amt_rpt = 0.0  WHERE disp_ctrl_num IN (@int_ctrl_root, @disp_ctrl_num, @disp_err_num) 
 OR arr_ctrl_num IN (@int_ctrl_root, @arr_ctrl_num, @arr_err_num)  OR disp_ctrl_num IS NULL 
 OR arr_ctrl_num IS NULL  IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintclear_sp] TO [public]
GO
