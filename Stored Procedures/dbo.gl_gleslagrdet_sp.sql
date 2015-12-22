SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[gl_gleslagrdet_sp]  @home_ctry_code varchar(3),  @esl_ctrl_root varchar(16), 
 @esl_ctrl_num varchar(16),  @esl_err_num varchar(16),  @from_date int AS BEGIN DECLARE 
 @src_trx_id varchar(4),  @src_ctrl_num varchar(16),  @src_line_id int,  @post_flag smallint, 
 @err_code int,  @to_ctry_code varchar(3),  @date_applied int,  @amt_rpt float,  @vat_reg_num varchar(17), 
 @indicator_esl varchar(1),  @cmdty_code varchar(8) DECLARE  @ctrl_num varchar(16), 
 @esl_line_id int,  @to_ctry_code_vat varchar(3) DECLARE  @max_rec_num int,  @cur_rec_num int, 
 @is_trx_setup smallint,  @rpt_flag_esl smallint,  @neg_flag_esl smallint,  @rpt_flag_cmdty smallint, 
 @home_ec_flag smallint,  @to_ec_flag smallint,  @err_count int,  @cur_err_nbr int, 
 @cur_err_code int     SELECT @home_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @home_ctry_code 
    SELECT @max_rec_num = MAX(rec_num), @cur_rec_num = MIN(rec_num) - 1 FROM #gl_glinpdet 
 WHILE @cur_rec_num <= @max_rec_num  BEGIN     SELECT @cur_rec_num = @cur_rec_num + 1 
 SELECT @src_trx_id = h.src_trx_id,  @src_trx_id = h.src_trx_id,  @src_ctrl_num = h.src_ctrl_num, 
 @src_line_id = d.src_line_id,  @post_flag = h.post_flag,  @err_code = d.esl_err_code, 
 @to_ctry_code = d.to_ctry_code,  @date_applied = h.date_applied,  @amt_rpt = d.esl_amt_rpt, 
 @vat_reg_num = h.vat_reg_num,  @indicator_esl = d.indicator_esl,  @cmdty_code = d.cmdty_code 
 FROM #gl_glinphdr h, #gl_glinpdet d  WHERE h.src_trx_id = d.src_trx_id  AND h.src_ctrl_num = d.src_ctrl_num 
 AND d.rec_num = @cur_rec_num  IF @@rowcount <> 1 CONTINUE     DELETE FROM #gl_glinterr 
    SELECT @err_count = 0  SELECT @ctrl_num = @esl_ctrl_root, @esl_line_id = 0  SELECT @rpt_flag_esl = 0, @neg_flag_esl = 0, @rpt_flag_cmdty = 0, @to_ctry_code_vat = '' 
             SELECT @rpt_flag_cmdty = ISNULL(rpt_flag_esl, 0) FROM gl_cmdty WHERE cmdty_code = @cmdty_code 

 IF @@rowcount <> 1  BEGIN  IF @err_code = 0 SELECT @err_code = 8116  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8116)  END  IF @rpt_flag_cmdty <> 1 CONTINUE  

IF @vat_reg_num = '' 
BEGIN  
	IF @err_code = 0 
		SELECT @err_code = 8132  

	SELECT @err_count = @err_count + 1 
	INSERT #gl_glinterr (err_nbr, err_code) 
	VALUES (@err_count, 8132)  
END       


    SELECT @to_ec_flag = ISNULL(ec_member, 0) FROM gl_country WHERE country_code = @to_ctry_code 
 IF @@rowcount <> 1  BEGIN  IF @err_code = 0 SELECT @err_code = 8128  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8128)  END  ELSE  BEGIN 
 SELECT @to_ctry_code_vat = ISNULL(ctry_code_vat, '') FROM gl_glctry WHERE country_code = @to_ctry_code 
 IF @@rowcount <> 1  BEGIN  IF @err_code = 0 SELECT @err_code = 8128  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8128)  END  END    
 SELECT @rpt_flag_esl = ISNULL(rpt_flag_esl, 0), @neg_flag_esl = ISNULL(neg_flag_esl, 0) 
 FROM gl_glnotr  WHERE country_code = @home_ctry_code AND src_trx_id = @src_trx_id 
 IF @@rowcount = 1  SELECT @is_trx_setup = 1  ELSE  BEGIN  SELECT @is_trx_setup = 0 
 IF @err_code = 0 SELECT @err_code = 8109  SELECT @err_count = @err_count + 1  INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8109) 
 END                         IF @is_trx_setup = 1 AND @rpt_flag_esl = 0  CONTINUE 
 
IF @err_code = 0  AND ( @to_ctry_code = @home_ctry_code OR @to_ec_flag <> 1 OR @home_ec_flag <> 1 
 OR @post_flag <> 1  OR @rpt_flag_esl <> 1  OR @rpt_flag_cmdty <> 1 )  CONTINUE   

  IF @neg_flag_esl = 1 SELECT @amt_rpt = -1.0 * @amt_rpt      IF @date_applied < @from_date 
 BEGIN  IF @err_code = 0 SELECT @err_code = 8102  SELECT @err_count = @err_count + 1 
 INSERT #gl_glinterr (err_nbr, err_code) VALUES (@err_count, 8102)  END     IF @err_code = 0 
 SELECT @ctrl_num = @esl_ctrl_num  ELSE  SELECT @ctrl_num = @esl_err_num     SELECT @esl_line_id = line_id 
 FROM gl_glesldet  WHERE esl_ctrl_num = @ctrl_num  AND to_ctry_code_vat = @to_ctry_code_vat 
 AND vat_reg_num = @vat_reg_num  AND err_code = @err_code  IF @@rowcount > 0  BEGIN 
 UPDATE gl_glesldet  SET amt_rpt = ISNULL(amt_rpt + @amt_rpt, 0.0),  num_of_trx = num_of_trx + 1 
 WHERE esl_ctrl_num = @ctrl_num AND line_id = @esl_line_id  IF @@error <> 0 RETURN 8100 
 END  ELSE  BEGIN  SELECT @esl_line_id = 1 + ISNULL(MAX(line_id), 0) FROM gl_glesldet WHERE esl_ctrl_num = @ctrl_num 
 INSERT gl_glesldet  (  esl_ctrl_num, line_id, err_code,  num_of_trx, to_ctry_code_vat, vat_reg_num, 
 amt_rpt, indicator_esl  )  VALUES  (  @ctrl_num, @esl_line_id, @err_code,  1, @to_ctry_code_vat, @vat_reg_num, 
 @amt_rpt, @indicator_esl  )  IF @@error <> 0 RETURN 8100  SELECT @cur_err_nbr = 1 
 WHILE @cur_err_nbr <= @err_count  BEGIN  SELECT @cur_err_code = err_code  FROM #gl_glinterr 
 WHERE err_nbr = @cur_err_nbr  INSERT gl_gleslerr  (esl_ctrl_num, line_id, err_code) 
 VALUES  (@ctrl_num, @esl_line_id, @cur_err_code)  SELECT @cur_err_nbr = @cur_err_nbr + 1 
 END  END     UPDATE #gl_glinphdr  SET esl_ctrl_num = @ctrl_num  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0 RETURN 8100     UPDATE #gl_glinpdet  SET esl_ctrl_num = @ctrl_num, esl_line_id = @esl_line_id, esl_err_code = @err_code 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id = @src_line_id 
 IF @@error <> 0 RETURN 8100  END  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_gleslagrdet_sp] TO [public]
GO
