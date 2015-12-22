SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








































CREATE PROC [dbo].[adm_setivdet_sp] 
 @src_trx_id varchar(4),  @src_ctrl_num varchar(16),  @src_line_id int,  @is_shipped smallint, 
 @new_from_loc smallint,  @from_loc varchar(8),  @new_to_loc smallint,  @to_loc varchar(8), 
 @new_item_code smallint,  @item_code varchar(30),  @new_qty_item smallint,  @qty_item float, 
 @new_amt_nat smallint,  @amt_nat float,  @is_detail_freight smallint,  @new_amt_freight smallint, 
 @amt_freight float,  @new_unit_code smallint,  @unit_code varchar(10),  @return_code int OUTPUT 
AS BEGIN DECLARE  @tmp_return_code int,  @is_input_exist smallint,  @home_ctry_code varchar(3), 
 @rpt_ctry_code varchar(3),  @from_ctry_code varchar(3),  @to_ctry_code varchar(3), 
 @orig_ctry_code varchar(3),  @cmdty_code varchar(8),  @rpt_flag smallint,  @weight_flag smallint, 
 @supp_unit_flag smallint,  @weight_value float,  @supp_unit_value float,  @total_amt float 
    SELECT @is_input_exist = 1, @return_code = 0  SELECT @src_ctrl_num = LTRIM(RTRIM(@src_ctrl_num)) 
 IF @src_trx_id IS NULL OR @src_ctrl_num IS NULL OR @src_line_id IS NULL  BEGIN  SELECT @return_code = 8101 
 RETURN @return_code  END  IF @src_trx_id = '' OR @src_ctrl_num = '' OR @src_line_id <= 0 
 BEGIN  SELECT @return_code = 8101  RETURN @return_code  END  SELECT @from_loc = ISNULL(LTRIM(RTRIM(@from_loc)), ''), 
 @to_loc = ISNULL(LTRIM(RTRIM(@to_loc)), ''),  @item_code = ISNULL(LTRIM(RTRIM(@item_code)), ''), 
 @amt_nat = ISNULL(@amt_nat, 0.0),  @amt_freight = ISNULL(@amt_freight, 0.0),  @qty_item = ISNULL(@qty_item, 0.0), 
 @unit_code = ISNULL(LTRIM(RTRIM(@unit_code)), '')     IF NOT EXISTS  (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id) 
 BEGIN  SELECT @is_input_exist = 0  INSERT gl_glinpdet  (  src_trx_id, src_ctrl_num, src_line_id, 
 esl_ctrl_num, esl_line_id, disp_ctrl_num,  disp_line_id, arr_ctrl_num, arr_line_id, 
 esl_err_code, int_err_code, from_ctry_code,  to_ctry_code, orig_ctry_code, qty_item, 
 amt_nat, esl_amt_rpt, int_amt_rpt,  indicator_esl, disp_flow_flag, disp_f_notr_code, 
 disp_s_notr_code, arr_flow_flag, arr_f_notr_code,  arr_s_notr_code, cmdty_code, weight_value, 
 supp_unit_value, disp_stat_amt_nat, arr_stat_amt_nat,  disp_stat_amt_rpt, arr_stat_amt_rpt, stat_manner, 
 regime, harbour, bundesland,  department  )  VALUES  (  @src_trx_id, @src_ctrl_num, @src_line_id, 
 '', 0, '',  0, '', 0,  0, 0, '',  '', '', @qty_item,  @amt_nat, 0.0, 0.0,  ' ', 0, '', 
 '', 0, '',  '', '', 0.0,  0.0, 0.0, 0.0,  0.0, 0.0, '',  '', '', '',  ''  )  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END     IF @is_input_exist = 0 OR @new_from_loc = 1 OR @new_to_loc = 1 
 BEGIN     EXEC @return_code = gl_gethomectry_sp @home_ctry_code OUTPUT  IF @return_code <> 0 
 BEGIN  SELECT @return_code = 8110  RETURN @return_code  END  SELECT @rpt_ctry_code = @home_ctry_code 
    SELECT @from_ctry_code = ISNULL(country_code, '') FROM locations_all WHERE location = @from_loc 
 SELECT @to_ctry_code = ISNULL(country_code, '') FROM locations_all WHERE location = @to_loc 
    UPDATE gl_glinpdet  SET from_ctry_code = @from_ctry_code, to_ctry_code = @to_ctry_code 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END    
 UPDATE gl_glinpdet  SET disp_flow_flag = ISNULL(n.disp_flow_flag, 0),  disp_f_notr_code = ISNULL(n.disp_f_notr_code, ''), 
 disp_s_notr_code = ISNULL(n.disp_s_notr_code, ''),  arr_flow_flag = ISNULL(n.arr_flow_flag, 0), 
 arr_f_notr_code = ISNULL(n.arr_f_notr_code, ''),  arr_s_notr_code = ISNULL(n.arr_s_notr_code, ''), 
 stat_manner = ISNULL(n.stat_manner, ''),  regime = ISNULL(n.regime, '')  FROM gl_glnotr n 
 WHERE gl_glinpdet.src_trx_id = @src_trx_id AND gl_glinpdet.src_ctrl_num = @src_ctrl_num AND gl_glinpdet.src_line_id = @src_line_id 
 AND n.country_code = @rpt_ctry_code AND n.src_trx_id = @src_trx_id  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END     UPDATE gl_glinpdet 
 SET harbour = ISNULL(s.harbour, ''),  bundesland = ISNULL(s.bundesland, ''),  department = ISNULL(s.department, '') 
 FROM locations_all s  WHERE gl_glinpdet.src_trx_id = @src_trx_id AND gl_glinpdet.src_ctrl_num = @src_ctrl_num AND gl_glinpdet.src_line_id = @src_line_id 
 AND (@is_shipped <> 0 AND s.location = @from_loc OR @is_shipped = 0 AND s.location = @to_loc) 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  UPDATE gl_glinpdet 
 SET harbour = ISNULL(s.harbour, '')  FROM gl_rptctry s  WHERE gl_glinpdet.src_trx_id = @src_trx_id AND gl_glinpdet.src_ctrl_num = @src_ctrl_num AND gl_glinpdet.src_line_id = @src_line_id 
 AND gl_glinpdet.harbour = ''  AND s.country_code = @home_ctry_code  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  UPDATE gl_glinpdet 
 SET bundesland = ISNULL(s.bundesland, '')  FROM gl_rptctry s  WHERE gl_glinpdet.src_trx_id = @src_trx_id AND gl_glinpdet.src_ctrl_num = @src_ctrl_num AND gl_glinpdet.src_line_id = @src_line_id 
 AND gl_glinpdet.bundesland = ''  AND s.country_code = @home_ctry_code  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  UPDATE gl_glinpdet 
 SET department = ISNULL(s.department, '')  FROM gl_rptctry s  WHERE gl_glinpdet.src_trx_id = @src_trx_id AND gl_glinpdet.src_ctrl_num = @src_ctrl_num AND gl_glinpdet.src_line_id = @src_line_id 
 AND gl_glinpdet.department = ''  AND s.country_code = @home_ctry_code  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END     IF @is_input_exist = 0 OR @new_item_code = 1 OR @new_qty_item = 1 OR @new_unit_code = 1 
 BEGIN  EXEC @tmp_return_code = gl_cvtcmdty_sp  @item_code, @qty_item, @unit_code, 
 @rpt_flag OUTPUT, @cmdty_code OUTPUT, @orig_ctry_code OUTPUT,  @weight_flag OUTPUT, @weight_value OUTPUT, @supp_unit_flag OUTPUT, 
 @supp_unit_value OUTPUT  IF @tmp_return_code = 0  BEGIN  UPDATE gl_glinpdet  SET orig_ctry_code = @orig_ctry_code, 
 cmdty_code = @cmdty_code,  weight_value = @weight_value,  supp_unit_value = @supp_unit_value 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
 END     IF @new_qty_item = 1  BEGIN  UPDATE gl_glinpdet  SET qty_item = ISNULL(@qty_item, 0.0) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
    IF @new_amt_nat = 1  BEGIN  UPDATE gl_glinpdet  SET amt_nat = ISNULL(@amt_nat, 0.0) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
    IF @is_input_exist = 0 OR @new_amt_nat = 1 OR @new_amt_freight = 1  OR @is_shipped <> 0 AND @new_to_loc = 1 
 OR @is_shipped = 0 AND @new_from_loc = 1  BEGIN  IF @is_shipped <> 0  EXEC @return_code = gl_statamtcalc_sp 
 @src_trx_id, @src_ctrl_num, @src_line_id,  @is_detail_freight, @amt_freight, '', 
 '', '', @from_loc,  @to_loc  ELSE  EXEC @return_code = gl_statamtcalc_sp  @src_trx_id, @src_ctrl_num, @src_line_id, 
 @is_detail_freight, @amt_freight, '',  '', '', @to_loc,  @from_loc  IF @return_code <> 0 RETURN @return_code 
 END  RETURN @return_code END 
GO
GRANT EXECUTE ON  [dbo].[adm_setivdet_sp] TO [public]
GO
