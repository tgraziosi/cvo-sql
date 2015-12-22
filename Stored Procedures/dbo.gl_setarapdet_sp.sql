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
CREATE PROC [dbo].[gl_setarapdet_sp] 
 @src_trx_id varchar(4),  @src_ctrl_num varchar(16),  @src_line_id int,  @total_amt_nat float, 
 @new_cv_code smallint,  @cv_code varchar(12),  @new_cv_branch_code smallint,  @cv_branch_code varchar(8), 
 @new_location_code smallint,  @location_code varchar(8),  @new_item_code smallint, 
 @item_code varchar(30),  @new_line_desc smallint,  @line_desc varchar(60),  @new_qty_item smallint, 
 @qty_item float,  @new_amt_nat smallint,  @amt_nat float,  @is_detail_freight smallint, 
 @new_amt_freight smallint,  @amt_freight float,  @new_zone_code smallint,  @zone_code varchar(8), 
 @new_unit_code smallint,  @unit_code varchar(10) 
AS 
BEGIN 

DECLARE  @return_code int, 
	 @tmp_return_code int,  
	@is_input_exist smallint,  
	@home_ctry_code varchar(3),  
	@rpt_ctry_code varchar(3), 
	@from_ctry_code varchar(3),  
	@to_ctry_code varchar(3),  
	@orig_ctry_code varchar(3), 
	@vat_num varchar(17),  
	@location_flag smallint,  
	@cmdty_code varchar(8),  
	@rpt_flag smallint, 
	 @weight_flag smallint,  
	@supp_unit_flag smallint,  
	@weight_value float,  
	@supp_unit_value float, 
	 @total_amt float     

SELECT @is_input_exist = 1, @return_code = 0  SELECT @src_ctrl_num = LTRIM(RTRIM(@src_ctrl_num)) 
 IF @src_trx_id IS NULL OR @src_ctrl_num IS NULL OR @src_line_id IS NULL  BEGIN  SELECT @return_code = 8101 
 RETURN @return_code  END  IF @src_trx_id = '' OR @src_ctrl_num = '' OR @src_line_id <= 0 
 BEGIN  SELECT @return_code = 8101  RETURN @return_code  END  SELECT @location_code = ISNULL(LTRIM(RTRIM(@location_code)), ''), 
 @item_code = ISNULL(LTRIM(RTRIM(@item_code)), ''),  @amt_nat = ISNULL(@amt_nat, 0.0), 
 @amt_freight = ISNULL(@amt_freight, 0.0),  @qty_item = ISNULL(@qty_item, 0.0)   
  IF NOT EXISTS  (SELECT * FROM gl_glinpdet  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id) 
 BEGIN  SELECT @is_input_exist = 0  INSERT gl_glinpdet  (  src_trx_id, src_ctrl_num, src_line_id, 
 esl_ctrl_num, esl_line_id, disp_ctrl_num,  disp_line_id, arr_ctrl_num, arr_line_id, 
 esl_err_code, int_err_code, from_ctry_code,  to_ctry_code, orig_ctry_code, qty_item, 
 amt_nat, esl_amt_rpt, int_amt_rpt,  indicator_esl, disp_flow_flag, disp_f_notr_code, 
 disp_s_notr_code, arr_flow_flag, arr_f_notr_code,  arr_s_notr_code, cmdty_code, weight_value, 
 supp_unit_value, disp_stat_amt_nat, arr_stat_amt_nat,  disp_stat_amt_rpt, arr_stat_amt_rpt, stat_manner, 
 regime, harbour, bundesland,  department, item_code, line_desc  )  VALUES  (  @src_trx_id, @src_ctrl_num, @src_line_id, 
 '', 0, '',  0, '', 0,  0, 0, '',  '', '', @qty_item,  @amt_nat, 0.0, 0.0,  ' ', 0, '', 
 '', 0, '',  '', '', 0.0,  0.0, @amt_nat, @amt_nat,  0.0, 0.0, '',  '', '', '',  '', '', @line_desc 
 )  IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END 
 END     SELECT @location_flag = 0  IF @location_code <> '' SELECT @location_flag = 1 
 IF @is_input_exist = 0 OR @new_cv_code = 1 OR @new_cv_branch_code = 1 OR @new_location_code = 1 
 BEGIN  IF @src_trx_id = "2031" OR @src_trx_id = "OEIV"  OR @src_trx_id = "2032" OR @src_trx_id = "OECM" 
 EXEC @return_code = adm_getarvatctry_sp  1, @cv_code, @cv_branch_code,  @location_flag, @location_code, 
 @home_ctry_code OUTPUT, @rpt_ctry_code OUTPUT, @from_ctry_code OUTPUT,  @to_ctry_code OUTPUT, @vat_num OUTPUT 
 ELSE  EXEC @return_code = adm_getapvatctry_sp  1, @cv_code, @cv_branch_code,  @location_flag, @location_code, 
 @home_ctry_code OUTPUT, @rpt_ctry_code OUTPUT, @from_ctry_code OUTPUT,  @to_ctry_code OUTPUT, @vat_num OUTPUT 
 IF @return_code = 0  BEGIN  UPDATE gl_glinpdet  SET from_ctry_code = @from_ctry_code, to_ctry_code = @to_ctry_code 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
 END     IF @is_input_exist = 0 OR @new_cv_code = 1 OR @new_cv_branch_code = 1 OR @new_location_code = 1 
 BEGIN  UPDATE gl_glinpdet  SET disp_flow_flag = ISNULL(n.disp_flow_flag, 0),  disp_f_notr_code = ISNULL(n.disp_f_notr_code, ''), 
 disp_s_notr_code = ISNULL(n.disp_s_notr_code, ''),  arr_flow_flag = ISNULL(n.arr_flow_flag, 0), 
 arr_f_notr_code = ISNULL(n.arr_f_notr_code, ''),  arr_s_notr_code = ISNULL(n.arr_s_notr_code, ''), 
 stat_manner = ISNULL(n.stat_manner, ''),  regime = ISNULL(n.regime, '')  FROM gl_glnotr n 
 WHERE gl_glinpdet.src_trx_id = @src_trx_id AND gl_glinpdet.src_ctrl_num = @src_ctrl_num AND gl_glinpdet.src_line_id = @src_line_id 
 AND n.country_code = @rpt_ctry_code AND n.src_trx_id = @src_trx_id  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END     IF @is_input_exist = 0 OR @new_item_code = 1 OR @new_qty_item = 1 OR @new_unit_code = 1 
 BEGIN  EXEC @tmp_return_code = gl_cvtcmdty_sp  @item_code, @qty_item, @unit_code, @rpt_ctry_code, 
 @rpt_flag OUTPUT, @cmdty_code OUTPUT, @orig_ctry_code OUTPUT,  @weight_flag OUTPUT, @weight_value OUTPUT, @supp_unit_flag OUTPUT, 
 @supp_unit_value OUTPUT  UPDATE gl_glinpdet  SET orig_ctry_code = @orig_ctry_code, 
 item_code = @item_code,  cmdty_code = @cmdty_code,  weight_value = @weight_value, 
 supp_unit_value = @supp_unit_value  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
    IF @new_line_desc = 1  BEGIN  UPDATE gl_glinpdet  SET line_desc = ISNULL(@line_desc, '') 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
    IF @new_qty_item = 1  BEGIN  UPDATE gl_glinpdet  SET qty_item = ISNULL(@qty_item, 0.0) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
    IF @new_amt_nat = 1  BEGIN  UPDATE gl_glinpdet  SET amt_nat = ISNULL(@amt_nat, 0.0) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 

    IF @is_input_exist = 0 OR @new_amt_nat = 1 OR @new_amt_freight = 1  OR @new_cv_code = 1 OR @new_cv_branch_code = 1 OR @new_location_code = 1 OR @new_zone_code = 1 
 BEGIN  
		EXEC @return_code = gl_statamtcalc_sp
			@src_trx_id,        @src_ctrl_num, @src_line_id,    @total_amt_nat,
			@is_detail_freight, @amt_freight,  @cv_code,
			@cv_branch_code,    @zone_code,    @location_code,
			''

	IF @return_code <> 0 RETURN @return_code 

 END     

IF EXISTS( SELECT name FROM sysobjects WHERE name = "locations")
BEGIN
	IF @location_flag <> 0 AND (@is_input_exist = 0 OR @new_location_code = 1)
	BEGIN
		UPDATE gl_glinpdet
		SET harbour = ISNULL(s.harbour, ''),
			bundesland = ISNULL(s.bundesland, ''),
			department = ISNULL(s.department, '')
		FROM locations s
		WHERE gl_glinpdet.src_trx_id = @src_trx_id AND gl_glinpdet.src_ctrl_num = @src_ctrl_num  AND gl_glinpdet.src_line_id = @src_line_id
		AND s.location = @location_code

		IF @@error <> 0
		BEGIN
			SELECT @return_code = 8100
			RETURN @return_code
		END
	END
END
ELSE
BEGIN
	IF @is_input_exist = 0 OR @new_cv_code = 1 OR @new_cv_branch_code = 1 OR @new_location_code = 1 
	BEGIN  
		UPDATE gl_glinpdet  
			SET harbour = ISNULL(s.harbour, '')  
		FROM gl_rptctry s 
		WHERE gl_glinpdet.src_trx_id = @src_trx_id 
		AND gl_glinpdet.src_ctrl_num = @src_ctrl_num 
		AND gl_glinpdet.src_line_id = @src_line_id 
		AND gl_glinpdet.harbour = ''  
		AND s.country_code = @home_ctry_code  

		IF @@error <> 0 
		BEGIN  
			SELECT @return_code = 8100  
			RETURN @return_code  
		END  

		UPDATE gl_glinpdet 
			SET bundesland = ISNULL(s.bundesland, '')  
		FROM gl_rptctry s  
		WHERE gl_glinpdet.src_trx_id = @src_trx_id 
		AND gl_glinpdet.src_ctrl_num = @src_ctrl_num 
		AND gl_glinpdet.src_line_id = @src_line_id 
		AND gl_glinpdet.bundesland = ''  
		AND s.country_code = @home_ctry_code  

		IF @@error <> 0 
		BEGIN  
			SELECT @return_code = 8100  
			RETURN @return_code  
		END  
	
		UPDATE gl_glinpdet 
			SET department = ISNULL(s.department, '')  
		FROM gl_rptctry s  
		WHERE gl_glinpdet.src_trx_id = @src_trx_id 
		AND gl_glinpdet.src_ctrl_num = @src_ctrl_num 
		AND gl_glinpdet.src_line_id = @src_line_id 
		AND gl_glinpdet.department = ''  
		AND s.country_code = @home_ctry_code  

		IF @@error <> 0 
		BEGIN  
			SELECT @return_code = 8100  
			RETURN @return_code  
		END  

	END  
END

RETURN @return_code 
END 
GO
GRANT EXECUTE ON  [dbo].[gl_setarapdet_sp] TO [public]
GO
