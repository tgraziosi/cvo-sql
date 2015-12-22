SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                                             CREATE PROC [dbo].[ar_setarhdr_sp] 
 @trx_ctrl_num varchar(16),  @order_ctrl_num varchar(16),  @is_invoice smallint, 
 @new_customer_code smallint,  @customer_code varchar(8),  @new_ship_to_code smallint, 
 @ship_to_code varchar(8),  @new_date_applied smallint,  @date_applied int,  @new_nat_cur_code smallint, 
 @nat_cur_code varchar(8),  @new_freight_code smallint,  @freight_code varchar(8), 
 @new_fob_code smallint,  @fob_code varchar(8),  @new_rate_type smallint,  @rate_type varchar(8), 
 @src_trx_id varchar(4) OUTPUT,  @src_ctrl_num varchar(16) OUTPUT,  @is_input_exist smallint OUTPUT 
AS BEGIN DECLARE  @src_doc_num varchar(36),  @home_ctry_code varchar(3),  @rpt_ctry_code varchar(3), 
 @vat_reg_num varchar(17) DECLARE  @return_code int,  @cust_ctry varchar(3),  @buf_from varchar(3) 
    SELECT @src_trx_id = '', @src_doc_num = '', @return_code = 0  SELECT @is_input_exist = 1 
 SELECT @src_ctrl_num = ISNULL(LTRIM(RTRIM(@src_ctrl_num)), ''),  @trx_ctrl_num = ISNULL(LTRIM(RTRIM(@trx_ctrl_num)), ''), 
 @order_ctrl_num = ISNULL(LTRIM(RTRIM(@order_ctrl_num)), '')  SELECT @date_applied = ISNULL(@date_applied, 0), @nat_cur_code = ISNULL(@nat_cur_code, '') 
    IF @is_invoice <> 0  IF @order_ctrl_num <> ''  SELECT @src_trx_id = "OEIV",  @src_doc_num = @order_ctrl_num 
 ELSE  SELECT @src_trx_id = "2031",  @src_doc_num = @trx_ctrl_num  ELSE  IF @order_ctrl_num <> '' 
 SELECT @src_trx_id = "OECM",  @src_doc_num = @order_ctrl_num  ELSE  SELECT @src_trx_id = "2032", 
 @src_doc_num = @trx_ctrl_num     IF NOT EXISTS (SELECT * FROM gl_glinphdr WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num) 
 BEGIN  SELECT @src_ctrl_num = src_ctrl_num FROM gl_glinphdr WHERE src_trx_id = @src_trx_id AND src_doc_num = @src_doc_num 
    IF @@rowcount <> 1 OR @src_ctrl_num IS NULL OR @src_ctrl_num = ''  BEGIN     
       EXEC glgetsrcctrl_sp @src_ctrl_num OUTPUT        SELECT @src_doc_num = '####-' + @src_trx_id + "-" + LTRIM(RTRIM(@src_ctrl_num)) 
 SELECT @is_input_exist = 0  END  END     IF @is_input_exist = 0  BEGIN  INSERT gl_glinphdr 
 (  src_trx_id, src_ctrl_num, src_doc_num,  post_flag, esl_ctrl_num, disp_ctrl_num, 
 arr_ctrl_num, home_ctry_code, rpt_ctry_code,  date_applied, nat_cur_code, esl_rpt_cur_code, 
 int_rpt_cur_code, trans_code, dlvry_code,  vat_reg_num, rate_type  )  VALUES  ( 
 @src_trx_id, @src_ctrl_num, @src_doc_num,  0, '', '',  '', '', '',  @date_applied, @nat_cur_code, '', 
 '', '', '',  '', @rate_type  )  IF @@error <> 0 RETURN 8100  END     IF @is_input_exist = 0 OR @new_customer_code = 1 OR @new_ship_to_code = 1 
 BEGIN  EXEC @return_code = adm_getarvatctry_sp  1, @customer_code, @ship_to_code, 
 0, '',  @home_ctry_code OUTPUT, @rpt_ctry_code OUTPUT, @buf_from OUTPUT,  @cust_ctry OUTPUT, @vat_reg_num OUTPUT 
 IF @return_code = 0  BEGIN  UPDATE gl_glinphdr  SET home_ctry_code = @home_ctry_code, rpt_ctry_code = @rpt_ctry_code, vat_reg_num = @vat_reg_num 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  IF @@error <> 0 RETURN 8100 
 END  END     IF @new_date_applied = 1  BEGIN  UPDATE gl_glinphdr SET date_applied = ISNULL(@date_applied, 0) 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  IF @@error <> 0 RETURN 8100 
 END     IF @new_nat_cur_code = 1  BEGIN  UPDATE gl_glinphdr SET nat_cur_code = ISNULL(@nat_cur_code, '') 
 WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num  IF @@error <> 0 RETURN 8100 
 END     IF @is_input_exist = 0 OR @new_freight_code = 1  BEGIN  IF @order_ctrl_num <> '' 
 UPDATE gl_glinphdr  SET trans_code = ISNULL(s.trans_code, '')  FROM arshipv s, orders_invoice i, orders o 
 WHERE gl_glinphdr.src_trx_id = @src_trx_id  AND gl_glinphdr.src_ctrl_num = @src_ctrl_num 
 AND i.doc_ctrl_num = @trx_ctrl_num  AND i.order_no = o.order_no  AND i.order_ext = o.ext 
 AND o.routing = s.ship_via_code  ELSE  UPDATE gl_glinphdr  SET trans_code = ISNULL(s.trans_code, '') 
 FROM arshipv s, arfrcode f  WHERE gl_glinphdr.src_trx_id = @src_trx_id AND gl_glinphdr.src_ctrl_num = @src_ctrl_num 
 AND f.freight_code = @freight_code AND s.ship_via_code = f.ship_via_code  IF @@error <> 0 RETURN 8100 
 END     IF @is_input_exist = 0 OR @new_fob_code = 1  BEGIN  UPDATE gl_glinphdr  SET dlvry_code = ISNULL(f.dlvry_code, '') 
 FROM arfob f  WHERE gl_glinphdr.src_trx_id = @src_trx_id AND gl_glinphdr.src_ctrl_num = @src_ctrl_num 
 AND f.fob_code = @fob_code  IF @@error <> 0 RETURN 8100  END     IF @new_rate_type = 1 
 BEGIN  UPDATE gl_glinphdr  SET rate_type = ISNULL(@rate_type, '')  WHERE gl_glinphdr.src_trx_id = @src_trx_id AND gl_glinphdr.src_ctrl_num = @src_ctrl_num 
 IF @@error <> 0 RETURN 8100  END  RETURN @return_code END 
GO
GRANT EXECUTE ON  [dbo].[ar_setarhdr_sp] TO [public]
GO
