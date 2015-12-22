SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[gl_glintagrdet_sp]  @rpt_ctry_code varchar(3),  @int_period_id int,  @int_ctrl_root varchar(16), 
 @disp_ctrl_num varchar(16),  @disp_err_num varchar(16),  @arr_ctrl_num varchar(16), 
 @arr_err_num varchar(16),  @from_date int AS BEGIN DECLARE  @src_trx_id varchar(4), 
 @src_ctrl_num varchar(16),  @src_line_id int,  @post_flag smallint,  @err_code int, 
 @from_ctry_code varchar(3),  @to_ctry_code varchar(3),  @orig_ctry_code varchar(3), 
 @date_applied int,  @amt_rpt float,  @disp_stat_amt_rpt float,  @arr_stat_amt_rpt float, 
 @trans_code varchar(3),  @dlvry_code varchar(4),  @vat_reg_num varchar(17),  @disp_flow_flag smallint, 
 @disp_f_notr_code varchar(1),  @disp_s_notr_code varchar(1),  @arr_flow_flag smallint, 
 @arr_f_notr_code varchar(1),  @arr_s_notr_code varchar(1),  @cmdty_code varchar(8), 
 @weight_value float,  @supp_unit_value float DECLARE  @from_ctry_code_int varchar(3), 
 @to_ctry_code_int varchar(3),  @orig_ctry_code_int varchar(3),  @trans_code_int varchar(1), 
 @dlvry_code_int varchar(4),  @weight_flag smallint,  @supp_unit_flag smallint DECLARE 
 @flag_notr_two_digit smallint,  @flag_vat_reg_num smallint,  @flag_stat_manner smallint, 
 @flag_regime smallint,  @flag_harbour smallint,  @flag_bundesland smallint,  @flag_department smallint, 
 @flag_trans smallint,  @flag_dlvry smallint,  @flag_cmdty_desc smallint,  @flag_ctry_orig smallint, 
 @stat_manner varchar(5),  @regime varchar(2),  @harbour varchar(4),  @bundesland varchar(2), 
 @department varchar(2),  @cmdty_desc_1 varchar(40),  @cmdty_desc_2 varchar(40), 
 @cmdty_desc_3 varchar(40),  @cmdty_desc_4 varchar(40),  @cmdty_desc_5 varchar(40) 
DECLARE  @return_code int,  @max_rec_num int,  @cur_rec_num int,  @disp_real_num varchar(16), 
 @disp_line_id int,  @arr_real_num varchar(16),  @arr_line_id int,  @is_trx_setup smallint, 
 @rpt_flag smallint,  @rpt_ec_flag smallint,  @from_ec_flag smallint,  @to_ec_flag smallint, 
 @dist_sell_flag smallint,  @err_count int     SELECT @rpt_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @rpt_ctry_code 
 SELECT @dist_sell_flag = ISNULL(dist_sell_flag, 0),  @flag_notr_two_digit = ISNULL(flag_notr_two_digit, 0), @flag_vat_reg_num = ISNULL(flag_vat_reg_num, 0), 
 @flag_stat_manner = ISNULL(flag_stat_manner, 0), @flag_regime = ISNULL(flag_regime, 0), 
 @flag_harbour = ISNULL(flag_harbour, 0), @flag_bundesland = ISNULL(flag_bundesland, 0), 
 @flag_department = ISNULL(flag_department, 0), @flag_trans = ISNULL(flag_trans, 0), 
 @flag_dlvry = ISNULL(flag_dlvry, 0), @flag_cmdty_desc = ISNULL(flag_cmdty_desc, 0), 
 @flag_ctry_orig = ISNULL(flag_ctry_orig, 0)  FROM gl_glinthdr  WHERE rpt_ctry_code = @rpt_ctry_code AND int_period_id = @int_period_id 
    SELECT @max_rec_num = MAX(rec_num), @cur_rec_num = MIN(rec_num) - 1 FROM #gl_glinpdet 
 WHILE @cur_rec_num <= @max_rec_num  BEGIN     SELECT @cur_rec_num = @cur_rec_num + 1 
 SELECT @src_trx_id = h.src_trx_id,  @src_ctrl_num = h.src_ctrl_num,  @src_line_id = d.src_line_id, 
 @post_flag = h.post_flag,  @date_applied = h.date_applied,  @trans_code = h.trans_code, 
 @dlvry_code = h.dlvry_code,  @vat_reg_num = h.vat_reg_num,  @err_code = d.int_err_code, 
       @from_ctry_code =  CASE d.arr_f_notr_code  WHEN 2 THEN d.to_ctry_code  ELSE d.from_ctry_code 
 END,  @to_ctry_code =  CASE d.arr_f_notr_code  WHEN 2 THEN d.from_ctry_code  ELSE d.to_ctry_code 
 END,     @orig_ctry_code = d.orig_ctry_code,  @amt_rpt = d.int_amt_rpt,  @disp_stat_amt_rpt = d.disp_stat_amt_rpt, 
 @arr_stat_amt_rpt = d.arr_stat_amt_rpt,  @cmdty_code = d.cmdty_code,  @weight_value = d.weight_value, 
 @supp_unit_value = d.supp_unit_value,  @disp_flow_flag = d.disp_flow_flag,  @disp_f_notr_code = d.disp_f_notr_code, 
 @disp_s_notr_code = d.disp_s_notr_code,  @arr_flow_flag = d.arr_flow_flag,  @arr_f_notr_code = d.arr_f_notr_code, 
 @arr_s_notr_code = d.arr_s_notr_code,  @stat_manner = d.stat_manner,  @regime = d.regime, 
 @harbour = d.harbour,  @bundesland = d.bundesland,  @department = d.department  FROM #gl_glinphdr h, #gl_glinpdet d 
 WHERE h.src_trx_id = d.src_trx_id  AND h.src_ctrl_num = d.src_ctrl_num  AND d.rec_num = @cur_rec_num 
 IF @@rowcount <> 1 CONTINUE     DELETE FROM #gl_glinterr     SELECT @err_count = 0 
 SELECT @disp_real_num = @int_ctrl_root, @arr_real_num = @int_ctrl_root, @disp_line_id = 0, @arr_line_id = 0 
 SELECT @from_ctry_code_int = '', @to_ctry_code_int = '', @orig_ctry_code_int = '' 
 SELECT @trans_code_int = '', @dlvry_code_int = '', @weight_flag = 0, @supp_unit_flag = 0 
 SELECT @cmdty_desc_1 = '', @cmdty_desc_2 = '', @cmdty_desc_3 = '', @cmdty_desc_4 = '', @cmdty_desc_5 = '' 
 SELECT @rpt_flag = 0              SELECT @rpt_flag = ISNULL(rpt_flag_int, 0), @weight_flag = ISNULL(weight_flag, 0), 
 @supp_unit_flag = ISNULL(supp_unit_flag, 0), @cmdty_desc_1 = ISNULL(cmdty_desc_1, ''), 
 @cmdty_desc_2 = ISNULL(cmdty_desc_2, ''), @cmdty_desc_3 = ISNULL(cmdty_desc_3, ''), 
 @cmdty_desc_4 = ISNULL(cmdty_desc_4, ''), @cmdty_desc_5 = ISNULL(cmdty_desc_5, '') 
 FROM gl_cmdty WHERE cmdty_code = @cmdty_code  IF @@rowcount <> 1  BEGIN  IF @err_code = 0 SELECT @err_code = 8116 
 SELECT @err_count = @err_count + 1  INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8116) 
 END  IF @rpt_flag <>1 CONTINUE      SELECT @from_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @from_ctry_code 
 IF @@rowcount <> 1  BEGIN  IF @err_code = 0 SELECT @err_code = 8127  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8127)  END  ELSE  BEGIN 
 SELECT @from_ctry_code_int = ISNULL(ctry_code_int, '') FROM gl_glctrycvt  WHERE country_code = @rpt_ctry_code AND ctry_code = @from_ctry_code 
 IF @from_ctry_code_int = ''  BEGIN  IF @err_code = 0 SELECT @err_code = 8127  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8127)  END  END    
 SELECT @to_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @to_ctry_code 
 IF @@rowcount <> 1  BEGIN  IF @err_code = 0 SELECT @err_code = 8128  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8128)  END  ELSE  BEGIN 
 SELECT @to_ctry_code_int = ISNULL(ctry_code_int, '') FROM gl_glctrycvt  WHERE country_code = @rpt_ctry_code AND ctry_code = @to_ctry_code 
 IF @to_ctry_code_int = ''  BEGIN  IF @err_code = 0 SELECT @err_code = 8128  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8128)  END  END    
 SELECT @orig_ctry_code_int = ISNULL(ctry_code_int, '') FROM gl_glctrycvt  WHERE country_code = @rpt_ctry_code AND ctry_code = @orig_ctry_code 
 IF @flag_ctry_orig = 1 AND @orig_ctry_code_int = ''  BEGIN  if @err_code = 0 SELECT @err_code = 8129 
 SELECT @err_count = @err_count + 1  INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8129) 
 END                              IF @err_code = 0  AND ( @from_ctry_code_int = @to_ctry_code_int 
 OR @from_ec_flag <> 1 OR @to_ec_flag <> 1 OR @rpt_ec_flag <> 1  OR @disp_flow_flag <> 1 AND @arr_flow_flag <> 1 
 OR @rpt_flag <> 1  OR @post_flag <> 1 )  CONTINUE     IF @flag_trans <> 0  BEGIN 
 SELECT @trans_code_int = ISNULL(trans_code_int, '') FROM gl_gltranscvt  WHERE country_code = @rpt_ctry_code AND trans_code = @trans_code 
 IF @trans_code_int = ''  BEGIN  IF @err_code = 0 SELECT @err_code = 8112  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8112)  END  END  IF @flag_dlvry <> 0 
 BEGIN  SELECT @dlvry_code_int = ISNULL(dlvry_code_int, '') FROM gl_gldlvrycvt  WHERE country_code = @rpt_ctry_code AND dlvry_code = @dlvry_code 
 IF @dlvry_code_int = ''  BEGIN  IF @err_code = 0 SELECT @err_code = 8113  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8113)  END  END    
 SELECT @weight_value = ISNULL(@weight_value, 0.0), @supp_unit_value = ISNULL(@supp_unit_value, 0.0) 
 IF @weight_flag <> 0 AND @weight_value <= 0.0  BEGIN  IF @err_code = 0 SELECT @err_code = 8117 
 SELECT @err_count = @err_count + 1  INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8117) 
 END  IF @supp_unit_flag <> 0 AND @supp_unit_value <= 0.0  BEGIN  IF @err_code = 0 SELECT @err_code = 8118 
 SELECT @err_count = @err_count + 1  INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8118) 
 END  SELECT @disp_flow_flag = ISNULL(@disp_flow_flag, 0),  @disp_f_notr_code = ISNULL(@disp_f_notr_code, ''), @disp_s_notr_code = ISNULL(@disp_s_notr_code, '') 
 IF @disp_flow_flag = 1 AND (@disp_f_notr_code = '' OR @flag_notr_two_digit <> 0 AND @disp_s_notr_code = '') 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8138  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8138)  END  SELECT @arr_flow_flag = ISNULL(@arr_flow_flag, 0), 
 @arr_f_notr_code = ISNULL(@arr_f_notr_code, ''), @arr_s_notr_code = ISNULL(@arr_s_notr_code, '') 
 IF @arr_flow_flag = 1 AND (@arr_f_notr_code = '' OR @flag_notr_two_digit <> 0 AND @arr_s_notr_code = '') 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8139  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8139)  END     IF @dist_sell_flag <> 1 AND @flag_vat_reg_num <> 0 AND @vat_reg_num = '' 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8132  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8132)  END       IF @flag_bundesland <> 0 AND @bundesland = '' 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8134  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8134)  END  IF @flag_department <> 0 AND @department = '' 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8135  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8135)  END  IF @flag_stat_manner <> 0 AND @stat_manner = '' 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8130  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8130)  END  IF @flag_regime <> 0 AND @regime = '' 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8131  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8131)  END  IF @flag_cmdty_desc <> 0 AND @cmdty_desc_1 = '' AND @cmdty_desc_2 = '' 
 AND @cmdty_desc_3 = '' AND @cmdty_desc_4 = '' AND @cmdty_desc_5 = ''  BEGIN  IF @err_code = 0 SELECT @err_code = 8136 
 SELECT @err_count = @err_count + 1  INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8136) 
 END      IF @date_applied < @from_date  BEGIN  IF @err_code = 0 SELECT @err_code = 8102 
 SELECT @err_count = @err_count + 1  INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8102) 
 END     IF @err_code = 0  SELECT @disp_real_num = @disp_ctrl_num, @arr_real_num = @arr_ctrl_num 
 ELSE  SELECT @disp_real_num = @disp_err_num, @arr_real_num = @arr_err_num     IF @disp_flow_flag <> 1 
 SELECT @disp_real_num = @int_ctrl_root  ELSE  BEGIN  EXEC @return_code = gl_glintupddet_sp 
 @disp_real_num, @err_code, @from_ctry_code_int,  @to_ctry_code_int, @flag_ctry_orig, @orig_ctry_code_int, @src_ctrl_num, 
 @amt_rpt, @disp_f_notr_code, @disp_s_notr_code,  @trans_code_int, @dlvry_code_int, @cmdty_code, 
 @weight_flag, @weight_value, @supp_unit_flag,  @supp_unit_value, @flag_notr_two_digit, @flag_vat_reg_num, 
 @flag_stat_manner, @flag_regime, @flag_harbour,  @flag_bundesland, @flag_department, @flag_trans, 
 @flag_dlvry, @vat_reg_num, @stat_manner,  @regime, @harbour, @bundesland,  @department, @disp_stat_amt_rpt, @cmdty_desc_1, 
 @cmdty_desc_2, @cmdty_desc_3, @cmdty_desc_4,  @cmdty_desc_5, @err_count, @src_trx_id, 
 @src_ctrl_num, @src_line_id,  @disp_line_id OUTPUT  IF @return_code <> 0 RETURN @return_code 
 END     IF @arr_flow_flag <> 1  SELECT @arr_real_num = @int_ctrl_root  ELSE  BEGIN 
 EXEC @return_code = gl_glintupddet_sp  @arr_real_num, @err_code, @from_ctry_code_int, 
 @to_ctry_code_int, @flag_ctry_orig, @orig_ctry_code_int, @src_ctrl_num,  @amt_rpt, @arr_f_notr_code, @arr_s_notr_code, 
 @trans_code_int, @dlvry_code_int, @cmdty_code,  @weight_flag, @weight_value, @supp_unit_flag, 
 @supp_unit_value, @flag_notr_two_digit, @flag_vat_reg_num,  @flag_stat_manner, @flag_regime, @flag_harbour, 
 @flag_bundesland, @flag_department, @flag_trans,  @flag_dlvry, @vat_reg_num, @stat_manner, 
 @regime, @harbour, @bundesland,  @department, @arr_stat_amt_rpt, @cmdty_desc_1, 
 @cmdty_desc_2, @cmdty_desc_3, @cmdty_desc_4,  @cmdty_desc_5, @err_count, @src_trx_id, 
 @src_ctrl_num, @src_line_id,  @arr_line_id OUTPUT  IF @return_code <> 0 RETURN @return_code 
 END     UPDATE #gl_glinphdr  SET disp_ctrl_num = @disp_real_num, arr_ctrl_num = @arr_real_num 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  IF @@error <> 0 RETURN 8100 
    UPDATE #gl_glinpdet  SET disp_ctrl_num = @disp_real_num, disp_line_id = @disp_line_id, 
 arr_ctrl_num = @arr_real_num, arr_line_id = @arr_line_id,  int_err_code = @err_code 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0 RETURN 8100  END  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintagrdet_sp] TO [public]
GO
