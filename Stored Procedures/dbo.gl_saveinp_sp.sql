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
                                              CREATE PROC [dbo].[gl_saveinp_sp]  @src_trx_id varchar(4), 
 @src_ctrl_num varchar(16),  @ctrl_int int,  @ext_int int,  @ctrl_str varchar(16), 
 @ext_str varchar(20),  @alt_ctrl_str varchar(16)

AS BEGIN 
	DECLARE   	@return_code	int, @flag_esl smallint,  @flag_int smallint,  @src_doc_num varchar(36),  @home_ctry_code varchar(3), 
 @rpt_ctry_code varchar(3),  @vat_reg_num varchar(17),  @post_flag smallint,  @flag_harbour smallint, 
 @flag_bundesland smallint,  @flag_stat_manner smallint,  @flag_department smallint, 
 @flag_regime smallint,  @flag_amt smallint,  @flag_trans smallint,  @flag_dlvry smallint, 
 @flag_stat_amt smallint,  @flag_notr_two_digit smallint     SELECT @return_code = 0, @flag_esl = 0, @flag_int = 0 
    SELECT @post_flag = ISNULL(post_flag, 0) FROM gl_glinphdr WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@rowcount > 0 AND @post_flag <> 0  BEGIN  SELECT @return_code = 8143  RETURN @return_code 
 END     EXEC @return_code = gl_makesrcnum_sp  @src_trx_id, 0, @ctrl_int, @ext_int, @ctrl_str, @ext_str, @alt_ctrl_str, 
 @src_doc_num OUTPUT  IF @return_code <> 0 RETURN @return_code  UPDATE gl_glinphdr SET src_doc_num = ISNULL(@src_doc_num, '') WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END    
 SELECT @home_ctry_code = home_ctry_code, @rpt_ctry_code = rpt_ctry_code, @vat_reg_num = vat_reg_num 
 FROM gl_glinphdr  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @return_code = 0  AND (@home_ctry_code = ''  OR @rpt_ctry_code = ''  OR EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND (from_ctry_code = '' OR to_ctry_code = ''))) 
 SELECT @return_code = 8110     IF EXISTS (SELECT * FROM gl_glinpdet  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 AND @home_ctry_code IN (SELECT country_code FROM gl_ec_country_vw)  AND from_ctry_code IN (SELECT country_code FROM gl_ec_country_vw) 
 AND to_ctry_code IN (SELECT country_code FROM gl_ec_country_vw)  AND @home_ctry_code <> to_ctry_code 
 AND @vat_reg_num <> '')  SELECT @flag_esl = 1  IF EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND @rpt_ctry_code IN (SELECT country_code FROM gl_ec_country_vw) 
 AND from_ctry_code IN (SELECT country_code FROM gl_ec_country_vw)  AND to_ctry_code IN (SELECT country_code FROM gl_ec_country_vw) 
 AND from_ctry_code <> to_ctry_code)  SELECT @flag_int = 1  IF @flag_esl = 0 AND @flag_int = 0 RETURN @return_code 
    SELECT @flag_harbour = ISNULL(flag_harbour, 0),  @flag_bundesland = ISNULL(flag_bundesland, 0), 
 @flag_stat_manner = ISNULL(flag_stat_manner, 0),  @flag_department = ISNULL(flag_department, 0), 
 @flag_regime = ISNULL(flag_regime, 0),  @flag_amt = ISNULL(flag_amt, 0),  @flag_trans = ISNULL(flag_trans, 0), 
 @flag_dlvry = ISNULL(flag_dlvry, 0),  @flag_stat_amt = ISNULL(flag_stat_amt, 0), 
 @flag_notr_two_digit = ISNULL(flag_notr_two_digit, 0)  FROM gl_glctry WHERE country_code = @rpt_ctry_code 
    IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinphdr  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 AND date_applied <= 0)  SELECT @return_code = 8146  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinphdr 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND nat_cur_code = '') 
 SELECT @return_code = 8120  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinphdr 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND trans_code = '') 
 SELECT @return_code = 8112  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinphdr 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND dlvry_code = '') 
 SELECT @return_code = 8113     IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinphdr 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND @flag_trans = 1 AND trans_code = '') 
 SELECT @return_code = 8112  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinphdr 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND @flag_dlvry = 1 AND dlvry_code = '') 
 SELECT @return_code = 8113     IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND orig_ctry_code = '') 
 SELECT @return_code = 8110  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND qty_item < 0.0) 
 SELECT @return_code = 8123  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND amt_nat < 0.0) 
 SELECT @return_code = 8124  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND  (disp_flow_flag <> 0 AND disp_f_notr_code = '' OR arr_flow_flag <> 0 AND arr_f_notr_code = '' 
 OR @flag_notr_two_digit <> 0 AND disp_flow_flag <> 0 AND disp_s_notr_code = ''  OR @flag_notr_two_digit <> 0 AND arr_flow_flag <> 0 AND arr_s_notr_code = '')) 
 SELECT @return_code = 8115  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND cmdty_code = '') 
 SELECT @return_code = 8116  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND weight_value < 0.0) 
 SELECT @return_code = 8125  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND supp_unit_value < 0.0) 
 SELECT @return_code = 8126     IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND  (@flag_notr_two_digit <> 0 AND disp_flow_flag <> 0 AND disp_s_notr_code = '' 
 OR @flag_notr_two_digit <> 0 AND arr_flow_flag <> 0 AND arr_s_notr_code = ''))  SELECT @return_code = 8115 
 IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 AND @flag_stat_manner = 1 AND stat_manner = '')  SELECT @return_code = 8130  IF @return_code = 0 
 AND EXISTS (SELECT * FROM gl_glinpdet  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 AND @flag_regime = 1 AND regime = '')  SELECT @return_code = 8131  IF @return_code = 0 
 AND EXISTS (SELECT * FROM gl_glinpdet  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 AND @flag_amt = 1 AND amt_nat < 0.0)  SELECT @return_code = 8124  IF @return_code = 0 
 AND EXISTS (SELECT * FROM gl_glinpdet  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 AND @flag_stat_amt = 1 AND (disp_stat_amt_nat < 0.0 OR arr_stat_amt_nat < 0.0)) 
 SELECT @return_code = 8124  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND @flag_harbour = 1 AND harbour = '') 
 SELECT @return_code = 8133  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND @flag_bundesland = 1 AND bundesland = '') 
 SELECT @return_code = 8134  IF @return_code = 0  AND EXISTS (SELECT * FROM gl_glinpdet 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  AND @flag_department = 1 AND department = '') 
 SELECT @return_code = 8135  RETURN @return_code END 
GO
GRANT EXECUTE ON  [dbo].[gl_saveinp_sp] TO [public]
GO
