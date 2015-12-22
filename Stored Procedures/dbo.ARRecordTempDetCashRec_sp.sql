SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2010 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2010 Epicor Software Corporation, 2010    
                  All Rights Reserved                    
*/                                                




create procedure [dbo].[ARRecordTempDetCashRec_sp]
	@table_name varchar(50) = '#arinppdt4700',
	@trx_ctrl_num  varchar(16),
	@doc_ctrl_num varchar(16),
	@sequence_id int,
	@trx_type smallint,
	@apply_to_num varchar(16),
	@apply_trx_type varchar(16),
	@customer_code varchar(8),
 	@date_aging int,
	@amt_applied float,
	@amt_disc_taken float,
	@wr_off_flag smallint,
	@amt_max_wr_off float,
	@void_flag smallint,
	@line_desc varchar(40),
	@sub_apply_num varchar(16),
	@sub_apply_type smallint,
	@amt_tot_chg float,
	@amt_paid_to_date float,
	@terms_code varchar(8),
	@posting_code varchar(8),
	@date_doc int,
 	@amt_inv float,
 	@gain_home float,
	@gain_oper float,
 	@inv_amt_applied float,
	@inv_amt_disc_taken float,
	@inv_amt_max_wr_off float,
	@inv_cur_code varchar(8),
	@writeoff_code varchar(8),
	@writeoff_amount	float,
	@cross_rate	float,
	@org_id	varchar(30),
	@chargeback	smallint,
	@chargeref	varchar(16),
	@chargeamt	float,
	@cb_reason_code	varchar(8),
	@cb_responsibility_code	varchar(8),
	@cb_store_number	varchar(16),
	@cb_reason_desc	varchar(40),
	@cb_nat_cur_code	varchar(8),
	@cb_credit_memo	smallint
AS

create table #temp_vars (
	trx_ctrl_num  varchar(16),
	doc_ctrl_num varchar(16),
	sequence_id int,
	trx_type smallint,
	apply_to_num varchar(16),
	apply_trx_type varchar(16),
	customer_code varchar(8),
 	date_aging int,
	amt_applied float,
	amt_disc_taken float,
	wr_off_flag smallint,
	amt_max_wr_off float,
	void_flag smallint,
	line_desc varchar(40),
	sub_apply_num varchar(16),
	sub_apply_type smallint,
	amt_tot_chg float,
	amt_paid_to_date float,
	terms_code varchar(8),
	posting_code varchar(8),
	date_doc int,
 	amt_inv float,
 	gain_home float,
	gain_oper float,
 	inv_amt_applied float,
	inv_amt_disc_taken float,
	inv_amt_max_wr_off float,
	inv_cur_code varchar(8),
	writeoff_code varchar(8),
	writeoff_amount	float,
	cross_rate	float,
	org_id	varchar(30),
	chargeback	smallint,
	chargeref	varchar(16),
	chargeamt	float,
	cb_reason_code	varchar(8),
	cb_responsibility_code	varchar(8),
	cb_store_number	varchar(16),
	cb_reason_desc	varchar(40),
	cb_nat_cur_code	varchar(8),
	cb_credit_memo	smallint)  

insert into #temp_vars 
(	trx_ctrl_num,	doc_ctrl_num,
	sequence_id,	trx_type,	apply_to_num,
	apply_trx_type,	customer_code, 	date_aging,
	amt_applied,	amt_disc_taken,	wr_off_flag,
	amt_max_wr_off,	void_flag,	line_desc,
	sub_apply_num,	sub_apply_type,	amt_tot_chg,
	amt_paid_to_date,	terms_code,	posting_code,
	date_doc, 	amt_inv, 	gain_home,
	gain_oper, 	inv_amt_applied, inv_amt_disc_taken,
	inv_amt_max_wr_off,	inv_cur_code, writeoff_code,
	writeoff_amount, cross_rate, org_id,
	chargeback, chargeref, chargeamt,
	cb_reason_code, cb_responsibility_code, cb_store_number,
	cb_reason_desc, cb_nat_cur_code, cb_credit_memo)  
values(@trx_ctrl_num,	@doc_ctrl_num,
	@sequence_id,	@trx_type,	@apply_to_num,
	@apply_trx_type,	@customer_code, 	@date_aging,
	@amt_applied,	@amt_disc_taken,	@wr_off_flag,
	@amt_max_wr_off,	@void_flag,	@line_desc,
	@sub_apply_num,	@sub_apply_type,	@amt_tot_chg,
	@amt_paid_to_date,	@terms_code,	@posting_code,
	@date_doc, 	@amt_inv, 	@gain_home,
	@gain_oper, 	@inv_amt_applied, @inv_amt_disc_taken,
	@inv_amt_max_wr_off,	@inv_cur_code, @writeoff_code,
	@writeoff_amount, @cross_rate, @org_id,
	@chargeback, @chargeref, @chargeamt,
	@cb_reason_code, @cb_responsibility_code, @cb_store_number,
	@cb_reason_desc, @cb_nat_cur_code, @cb_credit_memo)  


exec('delete a
		from ' + @table_name + ' a, #temp_vars b
		where a.trx_ctrl_num = b.trx_ctrl_num
		and a.trx_type = b.trx_type
		and a.apply_to_num = b.apply_to_num
		and a.apply_trx_type = b.apply_trx_type 
		and a.customer_code = b.customer_code ')

if LTRIM(RTRIM(@apply_to_num)) <> ''
begin
	exec('	INSERT INTO ' + @table_name + ' ( 	trx_ctrl_num,	doc_ctrl_num,
	sequence_id,	trx_type,	apply_to_num,
	apply_trx_type,	customer_code, 	date_aging,
	amt_applied,	amt_disc_taken,	wr_off_flag,
	amt_max_wr_off,	void_flag,	line_desc,
	sub_apply_num,	sub_apply_type,	amt_tot_chg,
	amt_paid_to_date,	terms_code,	posting_code,
	date_doc, 	amt_inv, 	gain_home,
	gain_oper, 	inv_amt_applied, inv_amt_disc_taken,
	inv_amt_max_wr_off,	inv_cur_code, writeoff_code,
	writeoff_amount, cross_rate, org_id,
	chargeback, chargeref, chargeamt,
	cb_reason_code, cb_responsibility_code, cb_store_number,
	cb_reason_desc, cb_nat_cur_code, cb_credit_memo)  
	SELECT trx_ctrl_num,	doc_ctrl_num,
	sequence_id,	trx_type,	apply_to_num,
	apply_trx_type,	customer_code, 	date_aging,
	amt_applied,	amt_disc_taken,	wr_off_flag,
	amt_max_wr_off,	void_flag,	line_desc,
	sub_apply_num,	sub_apply_type,	amt_tot_chg,
	amt_paid_to_date,	terms_code,	posting_code,
	date_doc, 	amt_inv, 	gain_home,
	gain_oper, 	inv_amt_applied, inv_amt_disc_taken,
	inv_amt_max_wr_off,	inv_cur_code, writeoff_code,
	writeoff_amount, cross_rate, org_id,
	chargeback, chargeref, chargeamt,
	cb_reason_code, cb_responsibility_code, cb_store_number,
	cb_reason_desc, cb_nat_cur_code, cb_credit_memo
	FROM #temp_vars ')
end

DROP TABLE #temp_vars

return 0
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ARRecordTempDetCashRec_sp] TO [public]
GO
