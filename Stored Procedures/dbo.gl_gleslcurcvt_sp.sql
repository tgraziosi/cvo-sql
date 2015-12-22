SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[gl_gleslcurcvt_sp]  @home_ctry_code varchar(3),  @rpt_cur_code varchar(8) 
AS BEGIN DECLARE  @src_trx_id varchar(4),  @src_ctrl_num varchar(16),  @src_line_id int, 
 @post_flag smallint,  @err_code int,  @to_ctry_code varchar(3),  @date_applied int, 
 @nat_cur_code varchar(8),  @amt_nat float,  @vat_reg_num varchar(17) DECLARE  @max_rec_num int, 
 @cur_rec_num int,  @rpt_flag_esl smallint,  @rate_type varchar(8),  @rate_type_ctry varchar(8), 
 @rate_type_trx varchar(8),  @curr_precision smallint,  @home_ec_flag smallint,  @to_ec_flag smallint, 
 @amt_rpt float,  @rate_used float     SELECT @home_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @home_ctry_code 
 SELECT @rate_type_ctry = ISNULL(rate_type_esl, '') FROM gl_glctry WHERE country_code = @home_ctry_code 
 SELECT @curr_precision = curr_precision FROM glcurr_vw WHERE currency_code = @nat_cur_code 
 SELECT @curr_precision = ISNULL(@curr_precision, 2)     SELECT @max_rec_num = MAX(rec_num), @cur_rec_num = MIN(rec_num) - 1 FROM #gl_glinpdet 
 WHILE @cur_rec_num <= @max_rec_num  BEGIN     SELECT @cur_rec_num = @cur_rec_num + 1 
 SELECT @src_trx_id = h.src_trx_id,  @src_ctrl_num = h.src_ctrl_num,  @src_line_id = d.src_line_id, 
 @post_flag = h.post_flag,  @err_code = d.esl_err_code,  @to_ctry_code = d.to_ctry_code, 
 @date_applied = h.date_applied,  @nat_cur_code = h.nat_cur_code,  @rate_type_trx = h.rate_type, 
   @amt_nat = d.disp_stat_amt_nat,  @vat_reg_num = h.vat_reg_num  FROM #gl_glinphdr h, #gl_glinpdet d 
 WHERE h.src_trx_id = d.src_trx_id  AND h.src_ctrl_num = d.src_ctrl_num  AND d.rec_num = @cur_rec_num 
 IF @@rowcount <> 1 CONTINUE     SELECT @rpt_flag_esl = 0, @amt_rpt = 0.0     SELECT @to_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @to_ctry_code 
    SELECT @rpt_flag_esl = rpt_flag_esl FROM gl_glnotr WHERE country_code = @home_ctry_code AND src_trx_id = @src_trx_id 
    IF @to_ctry_code = @home_ctry_code OR @to_ec_flag <> 1 OR @home_ec_flag <> 1 
 OR @post_flag <> 1  OR @rpt_flag_esl <> 1  OR @vat_reg_num = ''  CONTINUE     IF @rate_type_ctry = '' SELECT @rate_type = @rate_type_trx ELSE SELECT @rate_type = @rate_type_ctry 
    EXEC CVO_Control..mccurcvt_sp  @date_applied,  1,  @nat_cur_code,  @amt_nat,  @rpt_cur_code, 
 @rate_type,  @amt_rpt OUTPUT,  @rate_used OUTPUT,  0  IF @rpt_cur_code IS NULL OR @amt_rpt IS NULL 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8119  SELECT @amt_rpt = 0.0  END     UPDATE #gl_glinphdr 
 SET esl_rpt_cur_code = @rpt_cur_code  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0 RETURN 8100      UPDATE #gl_glinpdet  SET esl_err_code = @err_code, esl_amt_rpt = ROUND(@amt_rpt, @curr_precision) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0 RETURN 8100  END  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslcurcvt_sp] TO [public]
GO
