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
                                            CREATE PROC [dbo].[gl_insertdet_sp]  @src_trx_id varchar(4), 
 @src_ctrl_num varchar(16),  @src_line_id int,  @return_code int OUTPUT AS BEGIN 
DECLARE  @num_lines int     SELECT @return_code = 0, @num_lines = 0  SELECT @src_ctrl_num = LTRIM(RTRIM(@src_ctrl_num)) 
 IF @src_trx_id IS NULL OR @src_ctrl_num IS NULL OR @src_line_id IS NULL  BEGIN  SELECT @return_code = 8101 
 RETURN @return_code  END  IF @src_trx_id = '' OR @src_ctrl_num = '' OR @src_line_id <= 0 
 BEGIN  SELECT @return_code = 8101  RETURN @return_code  END  BEGIN TRANSACTION   
  SELECT @num_lines = COUNT(*) FROM gl__glinpdet WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num 
 IF @src_line_id > @num_lines SELECT @src_line_id = @num_lines + 1     UPDATE gl__glinpdet 
 SET src_line_id = src_line_id + 1  WHERE src_trx_id = @src_trx_id AND src_ctrl_num = @src_ctrl_num AND src_line_id >= @src_line_id 
 IF @@error <> 0  BEGIN  ROLLBACK TRANSACTION  SELECT @return_code = 8100  RETURN @return_code 
 END     INSERT gl__glinpdet  (  src_trx_id, src_ctrl_num, src_line_id,  esl_ctrl_num, esl_line_id, disp_ctrl_num, 
 disp_line_id, arr_ctrl_num, arr_line_id,  esl_err_code, int_err_code, from_ctry_code, 
 to_ctry_code, orig_ctry_code, qty_item,  amt_nat, esl_amt_rpt, int_amt_rpt,  indicator_esl, disp_flow_flag, disp_f_notr_code, 
 disp_s_notr_code, arr_flow_flag, arr_f_notr_code,  arr_s_notr_code, cmdty_code, weight_value, 
 supp_unit_value, disp_stat_amt_nat, arr_stat_amt_nat,  disp_stat_amt_rpt, arr_stat_amt_rpt, stat_manner, 
 regime, harbour, bundesland,  department  )  VALUES  (  @src_trx_id, @src_ctrl_num, @src_line_id, 
 '', 0, '',  0, '', 0,  0, 0, '',  '', '', 0.0,  0.0, 0.0, 0.0,  ' ', 0, '',  '', 0, '', 
 '', '', 0.0,  0.0, 0.0, 0.0,  0.0, 0.0, '',  '', '', '',  ''  )  IF @@error <> 0 
 BEGIN  ROLLBACK TRANSACTION  SELECT @return_code = 8100  RETURN @return_code  END 
 COMMIT TRANSACTION  RETURN 0 END 
GO
GRANT EXECUTE ON  [dbo].[gl_insertdet_sp] TO [public]
GO
