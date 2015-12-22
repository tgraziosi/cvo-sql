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
                                             CREATE PROC [dbo].[gl_gleslnew_sp]  @home_ctry_code varchar(3), 
 @rpt_yy_period varchar(2),  @rpt_mm_period varchar(2),  @from_date int,  @to_date int 
AS BEGIN DECLARE  @esl_period_id int,  @esl_ctrl_root varchar(16),  @esl_ctrl_num varchar(16), 
 @esl_err_num varchar(16),  @vat_num_prefix varchar(3),  @vat_reg_num varchar(17), 
 @vat_branch_id varchar(4),  @agent_flag smallint,  @agent_vat_num_prefix varchar(3), 
 @agent_vat_reg_num varchar(17),  @agent_vat_branch_id varchar(4),  @company_name varchar(35) 
DECLARE  @return_code int,  @error_flag smallint,  @last_date int,  @rpt_cur_code varchar(8), 
 @ec_flag smallint     SELECT @ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @home_ctry_code 
 IF @@rowcount <> 1 RETURN 8110  IF @ec_flag <> 1 RETURN 8111  SELECT @rpt_cur_code = ISNULL(currency_code, '') FROM gl_glctry WHERE country_code = @home_ctry_code 
 IF @@rowcount <> 1 RETURN 8110  IF EXISTS (SELECT * FROM gl_gleslhdr WHERE home_ctry_code = @home_ctry_code AND post_flag <> 1) 
 RETURN 8144  SELECT @last_date = MAX(to_date) FROM gl_gleslhdr WHERE home_ctry_code = @home_ctry_code 
 IF @from_date >= @to_date OR NOT @last_date IS NULL AND @from_date <> @last_date + 1 
 RETURN 8146     SELECT @vat_num_prefix = ISNULL(vat_num_prefix, ''),  @vat_reg_num = ISNULL(vat_reg_num, ''), 
 @vat_branch_id = ISNULL(vat_branch_id, ''),  @agent_flag = ISNULL(agent_flag, 0), 
 @agent_vat_num_prefix = ISNULL(agent_vat_num_prefix, ''),  @agent_vat_reg_num = ISNULL(agent_vat_reg_num, ''), 
 @agent_vat_branch_id = ISNULL(agent_vat_branch_id, ''),  @company_name = ISNULL(company_name, '') 
 FROM gl_rptctry WHERE country_code = @home_ctry_code  IF @@rowcount <> 1 RETURN 8110 
    SELECT @esl_period_id = ISNULL(MAX(esl_period_id), 0) + 1 FROM gl_gleslhdr WHERE home_ctry_code = @home_ctry_code 
 EXEC fmtctlnm_sp @esl_period_id, "00000000", @esl_ctrl_root OUTPUT, @error_flag OUTPUT 
 IF @error_flag <> 0 RETURN 8145  SELECT @esl_ctrl_root = ISNULL(LTRIM(RTRIM(@home_ctry_code)), '') + ISNULL(LTRIM(RTRIM(@esl_ctrl_root)), '') 
 IF @esl_ctrl_root = '' RETURN 8145  SELECT @esl_ctrl_num = @esl_ctrl_root + "L", @esl_err_num = @esl_ctrl_root + "LE" 
    INSERT gl_gleslhdr  (  home_ctry_code, esl_period_id, rpt_yy_period,  rpt_mm_period, from_date, to_date, 
 post_flag, rpt_cur_code, esl_ctrl_root,  esl_ctrl_num, amt_esl, num_line_esl,  esl_err_num, amt_err, num_line_err, 
 vat_num_prefix, vat_reg_num, vat_branch_id,  agent_flag,  agent_vat_num_prefix, agent_vat_reg_num, agent_vat_branch_id, 
 company_name  )  VALUES  (  @home_ctry_code, @esl_period_id, @rpt_yy_period,  @rpt_mm_period, @from_date, @to_date, 
 0, @rpt_cur_code, @esl_ctrl_root,  @esl_ctrl_num, 0.0, 0,  @esl_err_num, 0.0, 0, 
 @vat_num_prefix, @vat_reg_num, @vat_branch_id,  @agent_flag,  @agent_vat_num_prefix, @agent_vat_reg_num, @agent_vat_branch_id, 
 @company_name  )  IF @@error <> 0 RETURN 8100  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslnew_sp] TO [public]
GO
