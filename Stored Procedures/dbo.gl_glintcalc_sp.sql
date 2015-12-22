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
                                         CREATE PROC [dbo].[gl_glintcalc_sp]  @rpt_ctry_code varchar(3), 
 @int_period_id int AS BEGIN DECLARE  @return_code int,  @from_date int,  @to_date int, 
 @post_flag smallint,  @int_ctrl_root varchar(16),  @disp_ctrl_num varchar(16),  @disp_err_num varchar(16), 
 @arr_ctrl_num varchar(16),  @arr_err_num varchar(16),  @rpt_cur_code varchar(8) 
    SELECT @from_date = from_date,  @to_date = to_date,  @post_flag = post_flag, 
 @int_ctrl_root = int_ctrl_root,  @disp_ctrl_num = disp_ctrl_num,  @disp_err_num = disp_err_num, 
 @arr_ctrl_num = arr_ctrl_num,  @arr_err_num = arr_err_num,  @rpt_cur_code = rpt_cur_code 
 FROM gl_glinthdr  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
 IF @@rowcount <> 1 RETURN 8140  IF @post_flag <> 0 RETURN 8143  BEGIN TRANSACTION 
    UPDATE gl_glinthdr  SET post_flag = -1  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id AND post_flag = 0 
 IF @@rowcount <> 1  BEGIN  ROLLBACK TRANSACTION  RETURN 8141  END     EXEC @return_code = gl_glintclear_sp 
 @rpt_ctry_code, @int_period_id, @int_ctrl_root, @disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num 
 IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     
           CREATE TABLE #gl_glinphdr 
(
 src_trx_id varchar(4),   src_ctrl_num varchar(16),   src_doc_num varchar(36),   post_flag smallint,  
 esl_ctrl_num varchar(16),   disp_ctrl_num varchar(16),   arr_ctrl_num varchar(16),  
 home_ctry_code varchar(3),   rpt_ctry_code varchar(3),   date_applied int,   nat_cur_code varchar(8),  
 esl_rpt_cur_code varchar(8),   int_rpt_cur_code varchar(8),   trans_code varchar(3),  
 dlvry_code varchar(4),   vat_reg_num varchar(17),   rate_type varchar(8)  
)
            CREATE TABLE #gl_glinpdet 
(
 rec_num int IDENTITY(1, 1),  src_trx_id varchar(4),   src_ctrl_num varchar(16),  
 src_line_id int,   esl_ctrl_num varchar(16),   esl_line_id int,   disp_ctrl_num varchar(16),  
 disp_line_id int,   arr_ctrl_num varchar(16),   arr_line_id int,   esl_err_code int,  
 int_err_code int,   from_ctry_code varchar(3),   to_ctry_code varchar(3),   orig_ctry_code varchar(3),  
 qty_item float,   amt_nat float,   esl_amt_rpt float,   int_amt_rpt float,   indicator_esl varchar(1),  
 disp_flow_flag smallint,   disp_f_notr_code varchar(1),   disp_s_notr_code varchar(1),  
 arr_flow_flag smallint,   arr_f_notr_code varchar(1),   arr_s_notr_code varchar(1),  
 cmdty_code varchar(8),   weight_value float,   supp_unit_value float,      disp_stat_amt_nat float,  
 arr_stat_amt_nat float,   disp_stat_amt_rpt float,   arr_stat_amt_rpt float,   stat_manner varchar(5),  
 regime varchar(2),   harbour varchar(4),   bundesland varchar(2),   department varchar(2)  
)
            CREATE TABLE #gl_glinterr (err_nbr int, err_code int)  INSERT INTO #gl_glinphdr 
 (  src_trx_id, src_ctrl_num, src_doc_num,  post_flag, esl_ctrl_num, disp_ctrl_num, 
 arr_ctrl_num, home_ctry_code, rpt_ctry_code,  date_applied, nat_cur_code, esl_rpt_cur_code, 
 int_rpt_cur_code, trans_code, dlvry_code,  vat_reg_num, rate_type  )  SELECT  src_trx_id, src_ctrl_num, src_doc_num, 
 post_flag, esl_ctrl_num, disp_ctrl_num,  arr_ctrl_num, home_ctry_code, rpt_ctry_code, 
 date_applied, nat_cur_code, esl_rpt_cur_code,  int_rpt_cur_code, trans_code, dlvry_code, 
 vat_reg_num, rate_type  FROM gl_glinphdr  WHERE rpt_ctry_code = @rpt_ctry_code AND date_applied <= @to_date AND (disp_ctrl_num = '' OR arr_ctrl_num = '') 
 IF @@error <> 0 RETURN 8100  INSERT INTO #gl_glinpdet  (  src_trx_id, src_ctrl_num, src_line_id, 
 esl_ctrl_num, esl_line_id, disp_ctrl_num,  disp_line_id, arr_ctrl_num, arr_line_id, 
 esl_err_code, int_err_code, from_ctry_code,  to_ctry_code, orig_ctry_code, qty_item, 
 amt_nat, esl_amt_rpt, int_amt_rpt,  indicator_esl, disp_flow_flag, disp_f_notr_code, 
 disp_s_notr_code, arr_flow_flag, arr_f_notr_code,  arr_s_notr_code, cmdty_code, weight_value, 
 supp_unit_value, disp_stat_amt_nat, arr_stat_amt_nat,  disp_stat_amt_rpt, arr_stat_amt_rpt, stat_manner, 
 regime, harbour, bundesland,  department  )  SELECT  src_trx_id, src_ctrl_num, src_line_id, 
 esl_ctrl_num, esl_line_id, disp_ctrl_num,  disp_line_id, arr_ctrl_num, arr_line_id, 
 esl_err_code, int_err_code, from_ctry_code,  to_ctry_code, orig_ctry_code, qty_item, 
 amt_nat, esl_amt_rpt, int_amt_rpt,  indicator_esl, disp_flow_flag, disp_f_notr_code, 
 disp_s_notr_code, arr_flow_flag, arr_f_notr_code,  arr_s_notr_code, cmdty_code, weight_value, 
 supp_unit_value, disp_stat_amt_nat, arr_stat_amt_nat,  disp_stat_amt_rpt, arr_stat_amt_rpt, stat_manner, 
 regime, harbour, bundesland,  department  FROM gl_glinpdet d  WHERE CONVERT(char(4), d.src_trx_id) + CONVERT(char(16), d.src_ctrl_num) 
 IN (SELECT CONVERT(char(4), h.src_trx_id) + CONVERT(char(16), h.src_ctrl_num)  FROM #gl_glinphdr h) 
 IF @@error <> 0 RETURN 8100  CREATE UNIQUE INDEX #gl_glinphdr_0 ON #gl_glinphdr (src_trx_id, src_ctrl_num) 
 IF @@error <> 0 RETURN 8100  CREATE UNIQUE INDEX #gl_glinpdet_0 ON #gl_glinpdet (src_trx_id, src_ctrl_num, src_line_id) 
 IF @@error <> 0 RETURN 8100     EXEC @return_code = adm_glmark_sp  IF @return_code <> 0 
 BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     EXEC @return_code = gl_glintcurcvt_sp @rpt_ctry_code, @rpt_cur_code 
 IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     EXEC @return_code = gl_glintagrdet_sp 
 @rpt_ctry_code, @int_period_id,  @int_ctrl_root, @disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num, 
 @from_date  IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN @return_code 
 END     EXEC @return_code = gl_glintflush_sp  IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION 
 RETURN @return_code  END     DROP TABLE #gl_glinpdet  DROP TABLE #gl_glinphdr 
 DROP TABLE #gl_glinterr     EXEC @return_code = gl_glintrounddet_sp  @rpt_ctry_code, @disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num 
 IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     EXEC @return_code = gl_glintupdhdr_sp 
 @rpt_ctry_code, @int_period_id, @disp_ctrl_num, @disp_err_num, @arr_ctrl_num, @arr_err_num 
 IF @return_code <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN @return_code  END     UPDATE gl_glinthdr SET post_flag = 0 WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
 IF @@error <> 0  BEGIN  ROLLBACK TRANSACTION  RETURN 8100  END  COMMIT TRANSACTION 
 RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintcalc_sp] TO [public]
GO
