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
                                                      CREATE PROC [dbo].[gl_glintupdhdr_sp] 
 @rpt_ctry_code varchar(3),  @int_period_id int,  @disp_ctrl_num varchar(16),  @disp_err_num varchar(16), 
 @arr_ctrl_num varchar(16),  @arr_err_num varchar(16) AS BEGIN DECLARE  @amt_disp float, 
 @amt_arr float,  @amt_err_disp float,  @amt_err_arr float,  @num_disp_line int, 
 @num_disp_err_line int,  @num_arr_line int,  @num_arr_err_line int DECLARE  @pos_total float, 
 @neg_total float     SELECT @amt_disp = 0.0, @num_disp_line = 0,  @amt_err_disp = 0.0, @num_disp_err_line = 0, 
 @amt_arr = 0.0, @num_arr_line = 0,  @amt_err_arr = 0.0, @num_arr_err_line = 0   
  SELECT @num_disp_line = COUNT(*) FROM gl_glintdet WHERE int_ctrl_num = @disp_ctrl_num 
 SELECT @pos_total = 0.0, @neg_total = 0.0   SELECT @pos_total = SUM(ISNULL(stat_amt_rpt, 0.0)) 
 FROM gl_glintdet  WHERE int_ctrl_num = @disp_ctrl_num  AND CONVERT(CHAR(3), @rpt_ctry_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 IN (SELECT CONVERT(CHAR(3), country_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 FROM gl_notr  WHERE neg_flag_total = 0)   SELECT @neg_total = SUM(ISNULL(stat_amt_rpt, 0.0)) 
 FROM gl_glintdet  WHERE int_ctrl_num = @disp_ctrl_num  AND CONVERT(CHAR(3), @rpt_ctry_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 IN (SELECT CONVERT(CHAR(3), country_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 FROM gl_notr  WHERE neg_flag_total = 1)  SELECT @amt_disp = ISNULL(@pos_total, 0.0) - ISNULL(@neg_total, 0.0) 
    SELECT @num_disp_err_line = COUNT(*) FROM gl_glintdet WHERE int_ctrl_num = @disp_err_num 
 SELECT @pos_total = 0.0, @neg_total = 0.0   SELECT @pos_total = SUM(ISNULL(stat_amt_rpt, 0.0)) 
 FROM gl_glintdet  WHERE int_ctrl_num = @disp_err_num  AND CONVERT(CHAR(3), @rpt_ctry_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 IN (SELECT CONVERT(CHAR(3), country_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 FROM gl_notr  WHERE neg_flag_total = 0)   SELECT @neg_total = SUM(ISNULL(stat_amt_rpt, 0.0)) 
 FROM gl_glintdet  WHERE int_ctrl_num = @disp_err_num  AND CONVERT(CHAR(3), @rpt_ctry_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 IN (SELECT CONVERT(CHAR(3), country_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 FROM gl_notr  WHERE neg_flag_total = 1)  SELECT @amt_err_disp = ISNULL(@pos_total, 0.0) - ISNULL(@neg_total, 0.0) 
    SELECT @num_arr_line = COUNT(*) FROM gl_glintdet WHERE int_ctrl_num = @arr_ctrl_num 
 SELECT @pos_total = 0.0, @neg_total = 0.0   SELECT @pos_total = SUM(ISNULL(stat_amt_rpt, 0.0)) 
 FROM gl_glintdet  WHERE int_ctrl_num = @arr_ctrl_num  AND CONVERT(CHAR(3), @rpt_ctry_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 IN (SELECT CONVERT(CHAR(3), country_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 FROM gl_notr  WHERE neg_flag_total = 0)   SELECT @neg_total = SUM(ISNULL(stat_amt_rpt, 0.0)) 
 FROM gl_glintdet  WHERE int_ctrl_num = @arr_ctrl_num  AND CONVERT(CHAR(3), @rpt_ctry_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 IN (SELECT CONVERT(CHAR(3), country_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 FROM gl_notr  WHERE neg_flag_total = 1)  SELECT @amt_arr = ISNULL(@pos_total, 0.0) - ISNULL(@neg_total, 0.0) 
    SELECT @num_arr_err_line = COUNT(*) FROM gl_glintdet WHERE int_ctrl_num = @arr_err_num 
 SELECT @pos_total = 0.0, @neg_total = 0.0   SELECT @pos_total = SUM(ISNULL(stat_amt_rpt, 0.0)) 
 FROM gl_glintdet  WHERE int_ctrl_num = @arr_err_num  AND CONVERT(CHAR(3), @rpt_ctry_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 IN (SELECT CONVERT(CHAR(3), country_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 FROM gl_notr  WHERE neg_flag_total = 0)   SELECT @neg_total = SUM(ISNULL(stat_amt_rpt, 0.0)) 
 FROM gl_glintdet  WHERE int_ctrl_num = @arr_err_num  AND CONVERT(CHAR(3), @rpt_ctry_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 IN (SELECT CONVERT(CHAR(3), country_code) + CONVERT(CHAR(1), f_notr_code) + CONVERT(CHAR(1), s_notr_code) 
 FROM gl_notr  WHERE neg_flag_total = 1)  SELECT @amt_err_arr = ISNULL(@pos_total, 0.0) - ISNULL(@neg_total, 0.0) 
    UPDATE gl_glinthdr  SET amt_disp = @amt_disp, num_disp_line = @num_disp_line, 
 amt_err_disp = @amt_err_disp, num_disp_err_line = @num_disp_err_line,  amt_arr = @amt_arr, num_arr_line = @num_arr_line, 
 amt_err_arr = @amt_err_arr, num_arr_err_line = @num_arr_err_line  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
 IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintupdhdr_sp] TO [public]
GO
