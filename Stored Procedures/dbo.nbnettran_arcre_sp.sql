SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[nbnettran_arcre_sp]  @net_ctrl_num varchar(16), @vendor_code varchar(12), 
 @customer_code varchar(8), @currency_code varchar(8) AS  Declare  @return int,  @trx_ctrl_num varchar(16), 
 @doc_ctrl_num varchar(16),  @tmp_cust_code varchar(8),  @tmp_cur_code varchar(8), 
 @tmp_vend_code varchar(12),  @tmp_doc_ctrl_num varchar(16),  @amt_applied float, 
 @amt_disc_taken float,  @amt_max_wr_off float,  @valid_payer_flag int,  @sequence_id int 
BEGIN  Select @return = 0    Insert into ##nbnetcre(  net_ctrl_num, apply_trx,  trx_ctrl_num, doc_ctrl_num, trx_type, 
 trx_type_desc, amt_net, amt_payment,  amt_committed, nat_cur_code, date_applied, 
 vendor_code )  Select  @net_ctrl_num, 0,  t.trx_ctrl_num, t.doc_ctrl_num, case when t.payment_type = 1 then 2111 else 2032 end, 
 "", t.amt_on_acct, 0,  0, t.nat_cur_code, t.date_applied,  t.customer_code  From 
 artrx t, #arvpay p  Where  t.customer_code = p.customer_code  AND trx_type = 2111 
 AND payment_type in ( 1 , 3)  AND t.nat_cur_code = @currency_code  AND void_flag = 0 
 AND amt_on_acct > 0  Order By  payment_type asc,  date_applied asc  Select @return = @@ERROR 
 IF @return <> 0  return @return  Update ##nbnetcre  Set  amt_net = a.amt_net - (p.amt_payment - p.amt_on_acct) 
 From ##nbnetcre a, arinppyt p  Where p.trx_type = 2111  AND p.payment_type in ( 2, 4 ) 
 AND p.non_ar_flag = 0  AND a.doc_ctrl_num = p.doc_ctrl_num  AND a.trx_type in ( 2111 , 2032 ) 
 Select @return = @@ERROR  IF @return <> 0  return @return  Update ##nbnetcre  Set 
 trx_type_desc = p.trx_type_desc  From ##nbnetcre a, artrxtyp p  Where  a.trx_type = p.trx_type 
 AND a.trx_type in ( 2111 , 2032 )  Select @return = @@ERROR  IF @return <> 0  return @return 
 return @return END 

 /**/
GO
GRANT EXECUTE ON  [dbo].[nbnettran_arcre_sp] TO [public]
GO
