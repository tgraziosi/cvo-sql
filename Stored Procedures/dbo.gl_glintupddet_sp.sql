SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[gl_glintupddet_sp]  @real_num varchar(16),  @err_code int,  @from_ctry_code_int varchar(3), 
 @to_ctry_code_int varchar(3),  @flag_ctry_orig smallint,  @orig_ctry_code_int varchar(3), 
 @ref_ctrl_num varchar(14),  @amt_rpt float,  @f_notr_code varchar(1),  @s_notr_code varchar(1), 
 @trans_code_int varchar(1),  @dlvry_code_int varchar(4),  @cmdty_code varchar(8), 
 @weight_flag smallint,  @weight_value float,  @supp_unit_flag smallint,  @supp_unit_value float, 
 @flag_notr_two_digit smallint,  @flag_vat_reg_num smallint,  @flag_stat_manner smallint, 
 @flag_regime smallint,  @flag_harbour smallint,  @flag_bundesland smallint,  @flag_department smallint, 
 @flag_trans smallint,  @flag_dlvry smallint,  @vat_reg_num varchar(17),  @stat_manner varchar(5), 
 @regime varchar(2),  @harbour varchar(4),  @bundesland varchar(2),  @department varchar(2), 
 @stat_amt_rpt float,  @cmdty_desc_1 varchar(40),  @cmdty_desc_2 varchar(40),  @cmdty_desc_3 varchar(40), 
 @cmdty_desc_4 varchar(40),  @cmdty_desc_5 varchar(40),  @err_count int,  @src_trx_id varchar(4), 
 @src_ctrl_num varchar(16),  @src_line_id int,  @line_id int OUTPUT AS BEGIN  DECLARE @cur_err_nbr int, 
 @cur_err_code int  SELECT @line_id = line_id  FROM gl_glintdet  WHERE int_ctrl_num = @real_num 
 AND from_ctry_code_int = @from_ctry_code_int  AND to_ctry_code_int = @to_ctry_code_int 
 AND (@flag_ctry_orig <> 1 OR @flag_ctry_orig = 1 AND orig_ctry_code_int = @orig_ctry_code_int) 
 AND cmdty_code = @cmdty_code  AND f_notr_code = @f_notr_code  AND (@flag_trans <> 1 OR @flag_trans = 1 AND trans_code_int = @trans_code_int) 
 AND (@flag_dlvry <> 1 OR @flag_dlvry = 1 AND dlvry_code_int = @dlvry_code_int)  AND err_code = @err_code 
 AND (@flag_notr_two_digit <> 1 OR @flag_notr_two_digit = 1 AND s_notr_code = @s_notr_code) 
 AND (@flag_vat_reg_num <> 1 OR @flag_vat_reg_num = 1 AND vat_reg_num = @vat_reg_num) 
 AND (@flag_stat_manner <> 1 OR @flag_stat_manner = 1 AND stat_manner = @stat_manner) 
 AND (@flag_regime <> 1 OR @flag_regime = 1 AND regime = @regime)  AND (@flag_harbour <> 1 OR @flag_harbour = 1 AND harbour = @harbour) 
 AND (@flag_bundesland <> 1 OR @flag_bundesland = 1 AND bundesland = @bundesland) 
 AND (@flag_department <> 1 OR @flag_department = 1 AND department = @department) 
 IF @@rowcount > 0  BEGIN  UPDATE gl_glintdet  SET amt_rpt = ISNULL(amt_rpt + @amt_rpt, 0.0), 
 stat_amt_rpt = ISNULL(stat_amt_rpt + @stat_amt_rpt, 0.0),  weight_value = ISNULL(weight_value + @weight_value, 0.0), 
 supp_unit_value = ISNULL(supp_unit_value + @supp_unit_value, 0.0),  num_of_trx = num_of_trx + 1 
 WHERE int_ctrl_num = @real_num AND line_id = @line_id  IF @@error <> 0 RETURN 8100 
 END  ELSE  BEGIN  SELECT @line_id = 1 + ISNULL(MAX(line_id), 0)  FROM gl_glintdet 
 WHERE int_ctrl_num = @real_num  INSERT gl_glintdet  (  int_ctrl_num, line_id, err_code, 
 num_of_trx, from_ctry_code_int, to_ctry_code_int,  orig_ctry_code_int, ref_ctrl_num, amt_rpt, 
 f_notr_code, s_notr_code, trans_code_int,  dlvry_code_int, cmdty_code, weight_flag, 
 weight_value, supp_unit_flag, supp_unit_value,  vat_reg_num, stat_manner, regime, 
 harbour, bundesland, department,  stat_amt_rpt, cmdty_desc_1, cmdty_desc_2,  cmdty_desc_3, cmdty_desc_4, cmdty_desc_5 
 )  VALUES  (  @real_num, @line_id, @err_code,  1, @from_ctry_code_int, @to_ctry_code_int, 
 @orig_ctry_code_int, @ref_ctrl_num, @amt_rpt,  @f_notr_code, @s_notr_code, @trans_code_int, 
 @dlvry_code_int, @cmdty_code, @weight_flag,  @weight_value, @supp_unit_flag, @supp_unit_value, 
 @vat_reg_num, @stat_manner, @regime,  @harbour, @bundesland, @department,  @stat_amt_rpt, @cmdty_desc_1, @cmdty_desc_2, 
 @cmdty_desc_3, @cmdty_desc_4, @cmdty_desc_5  )  IF @@error <> 0 RETURN 8100  END 
 SELECT @cur_err_nbr = 1  WHILE @cur_err_nbr <= @err_count  BEGIN  SELECT @cur_err_code = err_code 
 FROM #gl_glinterr  WHERE err_nbr = @cur_err_nbr  INSERT gl_glinterr  (int_ctrl_num, line_id, err_code, src_trx_id, src_ctrl_num, src_line_id) 
 VALUES  (@real_num, @line_id, @cur_err_code, @src_trx_id, @src_ctrl_num, @src_line_id) 
 SELECT @cur_err_nbr = @cur_err_nbr + 1  END  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_glintupddet_sp] TO [public]
GO
