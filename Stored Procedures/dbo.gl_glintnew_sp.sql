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
                                            CREATE PROC [dbo].[gl_glintnew_sp]  @rpt_ctry_code varchar(3), 
 @rpt_yy_period varchar(2),  @rpt_mm_period varchar(2),  @from_date int,  @to_date int 
AS BEGIN DECLARE  @int_period_id int,  @int_ctrl_root varchar(16),  @disp_ctrl_num varchar(16), 
 @disp_err_num varchar(16),  @arr_ctrl_num varchar(16),  @arr_err_num varchar(16), 
 @rpt_cur_code varchar(8),  @vat_num_prefix varchar(3),  @vat_reg_num varchar(17), 
 @vat_branch_id varchar(4),  @agent_flag smallint,  @agent_vat_num_prefix varchar(3), 
 @agent_vat_reg_num varchar(17),  @agent_vat_branch_id varchar(4),  @company_name varchar(35) 
DECLARE  @flag_notr_two_digit smallint,  @flag_vat_reg_num smallint,  @flag_stat_manner smallint, 
 @flag_regime smallint,  @flag_harbour smallint,  @flag_bundesland smallint,  @flag_department smallint, 
 @flag_amt smallint,  @flag_trans smallint,  @flag_dlvry smallint,  @flag_stat_amt smallint, 
 @flag_cur_ident smallint,  @flag_cmdty_desc smallint,  @flag_ctry_orig smallint 
DECLARE  @return_code int,  @error_flag smallint,  @last_date int,  @ec_flag smallint, 
 @dist_sell_flag smallint,  @home_ctry_code varchar(3),  @rpt_cur_ident int     SELECT @ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @rpt_ctry_code 
 IF @@rowcount <> 1 RETURN 8110  IF @ec_flag <> 1 RETURN 8111  SELECT @rpt_cur_code = ISNULL(currency_code, ''), 
 @flag_notr_two_digit = ISNULL(@flag_notr_two_digit, 0), @flag_vat_reg_num = ISNULL(flag_vat_reg_num, 0), 
 @flag_stat_manner = ISNULL(flag_stat_manner, 0), @flag_regime = ISNULL(flag_regime, 0), 
 @flag_harbour = ISNULL(flag_harbour, 0), @flag_bundesland = ISNULL(flag_bundesland, 0), 
 @flag_department = ISNULL(flag_department, 0), @flag_amt = ISNULL(flag_amt, 0), 
 @flag_trans = ISNULL(flag_trans, 0), @flag_dlvry = ISNULL(flag_dlvry, 0),  @flag_stat_amt = ISNULL(flag_stat_amt, 0), @flag_cur_ident = ISNULL(flag_cur_ident, 0), 
 @flag_cmdty_desc = ISNULL(flag_cmdty_desc, 0), @flag_ctry_orig = ISNULL(flag_ctry_orig, 0) 
 FROM gl_glctry WHERE country_code = @rpt_ctry_code  IF @@rowcount <> 1 RETURN 8110 
    EXEC @return_code = gl_gethomectry_sp @home_ctry_code OUTPUT  IF @return_code <> 0 RETURN 8110 
 IF EXISTS (SELECT * FROM gl_glinthdr WHERE rpt_ctry_code = @rpt_ctry_code AND post_flag = 0) 
 RETURN 8144  SELECT @last_date = MAX(to_date) FROM gl_glinthdr WHERE rpt_ctry_code = @rpt_ctry_code 
 IF @from_date >= @to_date OR NOT @last_date IS NULL AND @from_date <> @last_date + 1 
 RETURN 8146     SELECT @vat_num_prefix = ISNULL(vat_num_prefix, ''),  @vat_reg_num = ISNULL(vat_reg_num, ''), 
 @vat_branch_id = ISNULL(vat_branch_id, ''),  @agent_flag = ISNULL(agent_flag, 0), 
 @agent_vat_num_prefix = ISNULL(agent_vat_num_prefix, ''),  @agent_vat_reg_num = ISNULL(agent_vat_reg_num, ''), 
 @agent_vat_branch_id = ISNULL(agent_vat_branch_id, ''),  @company_name = ISNULL(company_name, '') 
 FROM gl_rptctry WHERE country_code = @rpt_ctry_code  IF @@rowcount <> 1 RETURN 8110 
    SELECT @int_period_id = ISNULL(MAX(int_period_id), 0) + 1 FROM gl_glinthdr WHERE rpt_ctry_code = @rpt_ctry_code 
 EXEC fmtctlnm_sp @int_period_id, "00000000", @int_ctrl_root OUTPUT, @error_flag OUTPUT 
 IF @error_flag <> 0 RETURN 8145  SELECT @int_ctrl_root = ISNULL(LTRIM(RTRIM(@rpt_ctry_code)), '') + ISNULL(LTRIM(RTRIM(@int_ctrl_root)), '') 
 IF @int_ctrl_root = '' RETURN 8145  SELECT @disp_ctrl_num = @int_ctrl_root + "D", @disp_err_num = @int_ctrl_root + "DE" 
 SELECT @arr_ctrl_num = @int_ctrl_root + "A", @arr_err_num = @int_ctrl_root + "AE" 
    SELECT @dist_sell_flag = 0  IF @home_ctry_code <> @rpt_ctry_code SELECT @dist_sell_flag = 1 
    SELECT @rpt_cur_ident = 0  IF @flag_cur_ident = 1  BEGIN  SELECT @rpt_cur_ident = ISNULL(rpt_cur_ident, -1) 
 FROM gl_identcurcvt  WHERE currency_code = @rpt_cur_code  IF @@rowcount <> 1 OR @rpt_cur_ident < 0 RETURN 8137 
 END     INSERT gl_glinthdr  (  rpt_ctry_code, int_period_id, rpt_yy_period,  rpt_mm_period, from_date, to_date, 
 post_flag, dist_sell_flag, rpt_cur_code,  int_ctrl_root,  disp_ctrl_num, amt_disp, num_disp_line, 
 disp_err_num, amt_err_disp, num_disp_err_line,  arr_ctrl_num, amt_arr, num_arr_line, 
 arr_err_num, amt_err_arr, num_arr_err_line,  vat_num_prefix, vat_reg_num, vat_branch_id, 
 agent_flag,  agent_vat_num_prefix, agent_vat_reg_num, agent_vat_branch_id,  company_name, flag_notr_two_digit, flag_vat_reg_num, 
 flag_stat_manner, flag_regime, flag_harbour,  flag_bundesland, flag_department, flag_amt, 
 flag_trans, flag_dlvry, flag_stat_amt,  flag_cur_ident, flag_cmdty_desc, flag_ctry_orig, 
 rpt_cur_ident  )  VALUES  (  @rpt_ctry_code, @int_period_id, @rpt_yy_period,  @rpt_mm_period, @from_date, @to_date, 
 0, 0, @rpt_cur_code,  @int_ctrl_root,  @disp_ctrl_num, 0.0, 0,  @disp_err_num, 0.0, 0, 
 @arr_ctrl_num, 0.0, 0,  @arr_err_num, 0.0, 0,  @vat_num_prefix, @vat_reg_num, @vat_branch_id, 
 @agent_flag,  @agent_vat_num_prefix, @agent_vat_reg_num, @agent_vat_branch_id,  @company_name, @flag_notr_two_digit, @flag_vat_reg_num, 
 @flag_stat_manner, @flag_regime, @flag_harbour,  @flag_bundesland, @flag_department, @flag_amt, 
 @flag_trans, @flag_dlvry, @flag_stat_amt,  @flag_cur_ident, @flag_cmdty_desc, @flag_ctry_orig, 
 @rpt_cur_ident  )  IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintnew_sp] TO [public]
GO
