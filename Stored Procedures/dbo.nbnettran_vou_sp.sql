SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[nbnettran_vou_sp]  @net_ctrl_num varchar(16), @vendor_code varchar(12), 
 @customer_code varchar(8), @currency_code varchar(8) AS  Declare  @return int,  @trx_ctrl_num varchar(16), 
 @doc_ctrl_num varchar(16),  @tmp_cust_code varchar(8),  @tmp_cur_code varchar(8), 
 @tmp_vend_code varchar(12),  @tmp_doc_ctrl_num varchar(16),  @amt_applied float, 
 @amt_disc_taken float,  @amt_max_wr_off float,  @valid_payer_flag int,  @sequence_id int 
BEGIN  Select @return = 0    Select  net_ctrl_num =@net_ctrl_num, apply_trx = 0, sequence_id = IDENTITY(int, 1, 1), 
 trx_ctrl_num =a.trx_ctrl_num, doc_ctrl_num=a.doc_ctrl_num, trx_type = 4091,  trx_type_desc=b.trx_type_desc, amt_net = a.amt_net-a.amt_paid_to_date, amt_payment = 0, amt_committed = 0, 
 nat_cur_code = a.currency_code, date_applied = a.date_applied, vendor_code = a.vendor_code 
 into ##nbnetcre  From  apvohdr a,  aptrxtyp b  Where  a.vendor_code = @vendor_code 
 AND a.currency_code = @currency_code  AND a.paid_flag = 0  AND b.trx_type = 4091 
 And a.amt_net-a.amt_paid_to_date > 0  Order by  date_applied asc  Select @return = @@ERROR 
 IF @return <> 0  return @return  Declare credit_cursor CURSOR FOR  Select sequence_id, trx_ctrl_num, vendor_code 
 From ##nbnetcre  Order By  sequence_id asc  Open credit_cursor  Fetch Next From credit_cursor Into @sequence_id, @tmp_doc_ctrl_num, @tmp_vend_code 
 While @@FETCH_STATUS = 0  Begin  Select  @amt_applied = isnull( sum(vo_amt_applied) ,0), 
 @amt_disc_taken = isnull( sum(vo_amt_disc_taken) ,0)  From apinppdt  Where  apply_to_num = @tmp_doc_ctrl_num 
 AND vendor_code = @tmp_vend_code  And trx_type in ( 4111 )  Select  @amt_applied = @amt_applied + isnull( sum( amt_net ) ,0) 
 From apinpchg  Where  apply_to_num = @tmp_doc_ctrl_num  AND trx_type = 4092  AND vendor_code = @tmp_vend_code 
 Update ##nbnetcre  Set amt_net = amt_net - ( @amt_applied + @amt_disc_taken )  Where sequence_id = @sequence_id 
 Select @return = @@ERROR  IF @return <> 0  return @return  Fetch Next From credit_cursor Into @sequence_id, @tmp_doc_ctrl_num, @tmp_vend_code 
 End  Close credit_cursor  Deallocate credit_cursor  return @return END 

 /**/
GO
GRANT EXECUTE ON  [dbo].[nbnettran_vou_sp] TO [public]
GO
