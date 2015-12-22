SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO








































CREATE PROC [dbo].[adm_setoehdr_sp] 
 @order_no int,  @ext int,  @is_invoice smallint,  @new_customer_code smallint,  @customer_code varchar(8), 
 @new_ship_to_code smallint,  @ship_to_code varchar(8),  @new_apply_date smallint, 
 @apply_date datetime,  @new_nat_cur_code smallint,  @nat_cur_code varchar(8),  @new_ship_via_code smallint, 
 @ship_via_code varchar(8),  @new_fob_code smallint,  @fob_code varchar(8),  @src_trx_id varchar(4) OUTPUT, 
 @src_ctrl_num varchar(16) OUTPUT,  @is_input_exist smallint OUTPUT,  @return_code int OUTPUT 
AS BEGIN DECLARE  @src_doc_num varchar(36),  @home_ctry_code varchar(3),  @rpt_ctry_code varchar(3), 
 @date_applied int,  @vat_reg_num varchar(17) DECLARE  @cust_ctry varchar(3),  @buf_from varchar(3) 
    SELECT @src_trx_id = '', @src_doc_num = '', @return_code = 0  SELECT @is_input_exist = 1 
 SELECT @src_ctrl_num = ISNULL(LTRIM(RTRIM(@src_ctrl_num)), ''),  @order_no = ISNULL(@order_no, 0), 
 @ext = ISNULL(@ext, 0)  SELECT @apply_date = ISNULL(@apply_date, '01/01/1900'), @nat_cur_code = ISNULL(@nat_cur_code, '') 
    IF @is_invoice <> 0  SELECT @src_trx_id = "OEIV",  @src_doc_num = LTRIM(RTRIM(STR(@order_no, 16))) + '-' + LTRIM(RTRIM(STR(@ext, 16))) 
 ELSE  SELECT @src_trx_id = "OECM",  @src_doc_num = LTRIM(RTRIM(STR(@order_no, 16))) + '-' + LTRIM(RTRIM(STR(@ext, 16))) 
    SELECT @date_applied = DATEDIFF(day, '01/01/1900', @apply_date) + 693596     IF NOT EXISTS (SELECT * FROM gl_glinphdr WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num) 
 BEGIN  SELECT @src_ctrl_num = src_ctrl_num FROM gl_glinphdr WHERE src_trx_id = @src_trx_id AND src_doc_num = @src_doc_num 
    IF @@rowcount <> 1 OR @src_ctrl_num IS NULL OR @src_ctrl_num = ''  BEGIN  SELECT @src_ctrl_num = LTRIM(RTRIM(STR(ISNULL(COUNT(*), 0) + 1, 16))) FROM gl_glinphdr 
 SELECT @src_doc_num = '####-' + @src_trx_id + "-" + LTRIM(RTRIM(@src_ctrl_num)) 
 SELECT @is_input_exist = 0  END  END     IF @is_input_exist = 0  BEGIN  INSERT gl_glinphdr 
 (  src_trx_id, src_ctrl_num, src_doc_num,  post_flag, esl_ctrl_num, disp_ctrl_num, 
 arr_ctrl_num, home_ctry_code, rpt_ctry_code,  date_applied, nat_cur_code, esl_rpt_cur_code, 
 int_rpt_cur_code, trans_code, dlvry_code,  vat_reg_num  )  VALUES  (  @src_trx_id, @src_ctrl_num, @src_doc_num, 
 0, '', '',  '', '', '',  @date_applied, @nat_cur_code, '',  '', '', '',  ''  )  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END     IF @is_input_exist = 0 OR @new_customer_code = 1 OR @new_ship_to_code = 1 
 BEGIN  EXEC @return_code = adm_getarvatctry_sp  1, @customer_code, @ship_to_code, 
 0, '',  @home_ctry_code OUTPUT, @rpt_ctry_code OUTPUT, @buf_from OUTPUT,  @cust_ctry OUTPUT, @vat_reg_num OUTPUT 
 IF @return_code = 0  BEGIN  UPDATE gl_glinphdr  SET home_ctry_code = @home_ctry_code, rpt_ctry_code = @rpt_ctry_code, vat_reg_num = @vat_reg_num 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END  END     IF @new_apply_date = 1 
 BEGIN  UPDATE gl_glinphdr SET date_applied = ISNULL(@date_applied, 0)  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
    IF @new_nat_cur_code = 1  BEGIN  UPDATE gl_glinphdr SET nat_cur_code = ISNULL(@nat_cur_code, '') 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END     IF @is_input_exist = 0 OR @new_ship_via_code = 1 
 BEGIN  UPDATE gl_glinphdr  SET trans_code = ISNULL(s.trans_code, '')  FROM arshipv s 
 WHERE gl_glinphdr.src_trx_id = @src_trx_id AND gl_glinphdr.src_ctrl_num = @src_ctrl_num 
 AND s.ship_via_code = @ship_via_code  IF @@error <> 0  BEGIN  SELECT @return_code = 8100 
 RETURN @return_code  END  END     IF @is_input_exist = 0 OR @new_fob_code = 1  BEGIN 
 UPDATE gl_glinphdr  SET dlvry_code = ISNULL(f.dlvry_code, '')  FROM arfob f  WHERE gl_glinphdr.src_trx_id = @src_trx_id AND gl_glinphdr.src_ctrl_num = @src_ctrl_num 
 AND f.fob_code = @fob_code  IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code 
 END  END  RETURN @return_code END 
GO
GRANT EXECUTE ON  [dbo].[adm_setoehdr_sp] TO [public]
GO
