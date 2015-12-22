SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[gl_glintcurcvt_sp]  @rpt_ctry_code varchar(3),  @rpt_cur_code varchar(8) 
AS BEGIN DECLARE  @src_trx_id varchar(4),  @src_ctrl_num varchar(16),  @src_line_id int, 
 @post_flag smallint,  @err_code int,  @from_ctry_code varchar(3),  @to_ctry_code varchar(3), 
 @date_applied int,  @nat_cur_code varchar(8),  @disp_flow_flag smallint,  @arr_flow_flag smallint, 
 @amt_nat float,  @disp_stat_amt_nat float,  @arr_stat_amt_nat float DECLARE  @max_rec_num int, 
 @cur_rec_num int,  @rate_type varchar(8),  @rate_type_ctry varchar(8),  @rate_type_trx varchar(8), 
 @curr_precision smallint,  @rpt_ec_flag smallint,  @from_ec_flag smallint,  @to_ec_flag smallint, 
 @amt_rpt float,  @disp_stat_amt_rpt float,  @arr_stat_amt_rpt float,  @rate_used float 
    SELECT @rpt_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @rpt_ctry_code 
 SELECT @rate_type_ctry = ISNULL(rate_type_int, '') FROM gl_glctry WHERE country_code = @rpt_ctry_code 
 SELECT @curr_precision = curr_precision FROM glcurr_vw WHERE currency_code = @nat_cur_code 
 SELECT @curr_precision = ISNULL(@curr_precision, 2)     SELECT @max_rec_num = MAX(rec_num), @cur_rec_num = MIN(rec_num) - 1 FROM #gl_glinpdet 
 WHILE @cur_rec_num <= @max_rec_num  BEGIN     SELECT @cur_rec_num = @cur_rec_num + 1 
 SELECT @src_trx_id = h.src_trx_id,  @src_ctrl_num = h.src_ctrl_num,  @src_line_id = d.src_line_id, 
 @post_flag = h.post_flag,  @err_code = d.int_err_code,  @from_ctry_code = d.from_ctry_code, 
 @to_ctry_code = d.to_ctry_code,  @date_applied = h.date_applied,  @nat_cur_code = h.nat_cur_code, 
 @rate_type_trx = h.rate_type,  @disp_flow_flag = d.disp_flow_flag,  @arr_flow_flag = d.arr_flow_flag, 
 @amt_nat = d.amt_nat,  @disp_stat_amt_nat = d.disp_stat_amt_nat,  @arr_stat_amt_nat = d.arr_stat_amt_nat 
 FROM #gl_glinphdr h, #gl_glinpdet d  WHERE h.src_trx_id = d.src_trx_id  AND h.src_ctrl_num = d.src_ctrl_num 
 AND d.rec_num = @cur_rec_num  IF @@rowcount <> 1 CONTINUE     SELECT @amt_rpt = 0.0, @disp_stat_amt_rpt = 0.0, @arr_stat_amt_rpt = 0.0 
    SELECT @from_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @from_ctry_code 
 SELECT @to_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @to_ctry_code 
    IF @from_ctry_code = @to_ctry_code OR @from_ec_flag <> 1 OR @to_ec_flag <> 1 OR @rpt_ec_flag <> 1 
 OR @disp_flow_flag <> 1 AND @arr_flow_flag <> 1  OR @post_flag <> 1  CONTINUE   
  IF @rate_type_ctry = '' SELECT @rate_type = @rate_type_trx ELSE SELECT @rate_type = @rate_type_ctry 
    EXEC CVO_Control..mccurcvt_sp  @date_applied,  1,  @nat_cur_code,  @amt_nat,  @rpt_cur_code, 
 @rate_type,  @amt_rpt OUTPUT,  @rate_used OUTPUT,  0  IF @rpt_cur_code IS NULL OR @amt_rpt IS NULL 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8119  SELECT @amt_rpt = 0.0  END     EXEC CVO_Control..mccurcvt_sp 
 @date_applied,  1,  @nat_cur_code,  @disp_stat_amt_nat,  @rpt_cur_code,  @rate_type, 
 @disp_stat_amt_rpt OUTPUT,  @rate_used OUTPUT,  0  IF @rpt_cur_code IS NULL OR @disp_stat_amt_rpt IS NULL 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8119  SELECT @disp_stat_amt_rpt = 0.0 
 END     EXEC CVO_Control..mccurcvt_sp  @date_applied,  1,  @nat_cur_code,  @arr_stat_amt_nat, 
 @rpt_cur_code,  @rate_type,  @arr_stat_amt_rpt OUTPUT,  @rate_used OUTPUT,  0  IF @rpt_cur_code IS NULL OR @arr_stat_amt_rpt IS NULL 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8119  SELECT @arr_stat_amt_rpt = 0.0 
 END     UPDATE #gl_glinphdr  SET int_rpt_cur_code = @rpt_cur_code  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0 RETURN 8100      UPDATE #gl_glinpdet  SET int_err_code = @err_code, 
 int_amt_rpt = ROUND(@amt_rpt, @curr_precision),  disp_stat_amt_rpt = ROUND(@disp_stat_amt_rpt, @curr_precision), 
 arr_stat_amt_rpt = ROUND(@arr_stat_amt_rpt, @curr_precision)  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0 RETURN 8100  END  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintcurcvt_sp] TO [public]
GO
