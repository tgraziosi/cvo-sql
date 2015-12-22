SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





































CREATE PROC [dbo].[adm_setivhdr_sp] 
 @xfer_no int,  @is_shipped smallint,  @new_from_loc smallint,  @from_loc varchar(8), 
 @new_to_loc smallint,  @to_loc varchar(8),  @new_apply_date smallint,  @apply_date datetime, 
 @new_routing smallint,  @routing varchar(20),  @new_fob_code smallint,  @fob_code varchar(8), 
 @src_trx_id varchar(4) OUTPUT,  @src_ctrl_num varchar(16) OUTPUT,  @is_input_exist smallint OUTPUT, 
 @return_code int OUTPUT AS BEGIN DECLARE  @src_doc_num varchar(36),  @home_ctry_code varchar(3), 
 @rpt_ctry_code varchar(3),  @date_applied int,  @nat_cur_code varchar(8),  @vat_reg_num varchar(17) 
DECLARE  @from_ctry varchar(3),  @to_ctry varchar(3),  @rate_type varchar(8)     SELECT @src_trx_id = '', @src_doc_num = '', @return_code = 0 
 SELECT @is_input_exist = 1  SELECT @src_ctrl_num = ISNULL(LTRIM(RTRIM(@src_ctrl_num)), ''), 
 @xfer_no = ISNULL(@xfer_no, 0)  SELECT @apply_date = ISNULL(@apply_date, '01/01/1900') 
    IF @is_shipped <> 0  SELECT @src_trx_id = 'IVSH',  @src_doc_num = LTRIM(RTRIM(STR(@xfer_no, 16))) 
 ELSE  SELECT @src_trx_id = 'IVRV',  @src_doc_num = LTRIM(RTRIM(STR(@xfer_no, 16))) 
    SELECT @date_applied = DATEDIFF(day, '01/01/1900', @apply_date) + 693596     IF NOT EXISTS (SELECT * FROM gl_glinphdr WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num) 
 BEGIN  SELECT @src_ctrl_num = src_ctrl_num FROM gl_glinphdr WHERE src_trx_id = @src_trx_id AND src_doc_num = @src_doc_num 
    IF @@rowcount <> 1 OR @src_ctrl_num IS NULL OR @src_ctrl_num = ''  BEGIN  SELECT @src_ctrl_num = LTRIM(RTRIM(STR(ISNULL(COUNT(*), 0) + 1, 16))) FROM gl_glinphdr 
 SELECT @src_doc_num = '%%###-' + @src_trx_id + '-' + LTRIM(RTRIM(@src_ctrl_num)) 
 SELECT @is_input_exist = 0  END  END     IF @is_input_exist = 0  BEGIN  INSERT gl_glinphdr 
 (  src_trx_id, src_ctrl_num, src_doc_num,  post_flag, esl_ctrl_num, disp_ctrl_num, 
 arr_ctrl_num, home_ctry_code, rpt_ctry_code,  date_applied, nat_cur_code, esl_rpt_cur_code, 
 int_rpt_cur_code, trans_code, dlvry_code,  vat_reg_num, rate_type  )  VALUES  ( 
 @src_trx_id, @src_ctrl_num, @src_doc_num,  0, '', '',  '', '', '',  @date_applied, '', '', 
 '', '', '',  '', ''  )  IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code 
 END  END     IF @is_input_exist = 0 OR @new_from_loc = 1 OR @new_to_loc = 1  BEGIN 
    EXEC @return_code = gl_gethomectry_sp @home_ctry_code OUTPUT  SELECT @rpt_ctry_code = @home_ctry_code 
    SELECT @nat_cur_code = ISNULL(home_currency, ''),  @rate_type = ISNULL(rate_type_home, '') 
 FROM glco     SELECT @from_ctry = ISNULL(country_code, '') FROM locations_all WHERE location = @from_loc 
 SELECT @to_ctry = ISNULL(country_code, '') FROM locations_all WHERE location = @to_loc 
    IF @is_shipped <> 0  SELECT @vat_reg_num = ISNULL(vat_reg_num, '') FROM gl_rptctry WHERE country_code = @to_ctry 
 ELSE  SELECT @vat_reg_num = ISNULL(vat_reg_num, '') FROM gl_rptctry WHERE country_code = @from_ctry 
 UPDATE gl_glinphdr  SET home_ctry_code = ISNULL(@home_ctry_code, ''),  rpt_ctry_code = ISNULL(@rpt_ctry_code, ''), 
 nat_cur_code = ISNULL(@nat_cur_code, ''),  vat_reg_num = ISNULL(@vat_reg_num, ''), 
 rate_type = ISNULL(@rate_type, '')  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END 
    IF @new_apply_date = 1  BEGIN  UPDATE gl_glinphdr SET date_applied = ISNULL(@date_applied, 0) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  IF @@error <> 0 
 BEGIN  SELECT @return_code = 8100  RETURN @return_code  END  END     IF @is_input_exist = 0 OR @new_routing = 1 
 BEGIN  UPDATE gl_glinphdr  SET trans_code = ISNULL(s.trans_code, '')  FROM arshipv s 
 WHERE gl_glinphdr.src_trx_id = @src_trx_id AND gl_glinphdr.src_ctrl_num = @src_ctrl_num 
 AND s.ship_via_code = @routing  IF @@error <> 0  BEGIN  SELECT @return_code = 8100 
 RETURN @return_code  END  END     IF @is_input_exist = 0 OR @new_fob_code = 1  BEGIN 
 UPDATE gl_glinphdr  SET dlvry_code = ISNULL(f.dlvry_code, '')  FROM arfob f  WHERE gl_glinphdr.src_trx_id = @src_trx_id AND gl_glinphdr.src_ctrl_num = @src_ctrl_num 
 AND f.fob_code = @fob_code  IF @@error <> 0  BEGIN  SELECT @return_code = 8100  RETURN @return_code 
 END  END  RETURN @return_code END 
GO
GRANT EXECUTE ON  [dbo].[adm_setivhdr_sp] TO [public]
GO
