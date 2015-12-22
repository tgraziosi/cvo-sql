SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arstldpp_sp]	@settlement_ctrl_num varchar(16)

AS
BEGIN

DECLARE @inv_trx_ctrl_num varchar(16),
	@inv_amt_applied  float,
	@rec_amt_applied  float,
	@sequence	  int,
	@debug_level	  int,
	@inv_count	  int,
	@count		  int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arstldpp.cpp" + ", line " + STR( 47, 5 ) + " -- ENTRY: "

select @count = 1

select @inv_count = count(*) from #arinppdt4750

select @sequence = 1

select @inv_trx_ctrl_num = MIN(apply_to_num) from #arinppdt4750


while (@inv_count >= @count)
BEGIN

	insert into #arinppdt4750 
	(
	timestamp,
	trx_ctrl_num,
	doc_ctrl_num,
	sequence_id,
	trx_type,
	apply_to_num,
	apply_trx_type,
	customer_code,
	date_aging,
	amt_applied,
	amt_disc_taken,
	wr_off_flag,
	amt_max_wr_off,
	void_flag,
	line_desc,
	sub_apply_num,
	sub_apply_type,
	amt_tot_chg,	
	amt_paid_to_date,
	terms_code,
	posting_code,
	date_doc,	
	amt_inv,
	gain_home,
	gain_oper,
	inv_amt_applied,
	inv_amt_disc_taken,
	inv_amt_max_wr_off,
	inv_cur_code,
	writeoff_code,
	writeoff_amount,
	cross_rate,
	org_id
	)
	select 	NULL,
	@settlement_ctrl_num,
	MIN(i.doc_ctrl_num),
	@sequence,
	MIN(i.trx_type),
	i.apply_to_num,
	i.apply_trx_type,
	i.customer_code,
	MIN(i.date_aging),
	SUM(i.amt_applied),
	SUM(i.amt_disc_taken),
	MIN(i.wr_off_flag),
	SUM(i.amt_max_wr_off),
	MIN(i.void_flag),
	MIN(i.line_desc),
	MIN(i.sub_apply_num),
	MIN(i.sub_apply_type),
	MIN(i.amt_tot_chg),
	MIN(i.amt_paid_to_date),
	MIN(i.terms_code),
	MIN(i.posting_code),
	MIN(i.date_doc),
	SUM(i.amt_inv),
	SUM(i.gain_home),
	SUM(i.gain_oper),
	SUM(i.inv_amt_applied),
	SUM(i.inv_amt_disc_taken),
	SUM(i.inv_amt_max_wr_off),
	MIN(i.inv_cur_code),
	MIN(i.writeoff_code),
	SUM(i.writeoff_amount),
	MIN(i.cross_rate),
	MIN(i.org_id)
	from arinppdt i
	where i.apply_to_num = @inv_trx_ctrl_num
	and   i.trx_ctrl_num in (select trx_ctrl_num from arinppyt where settlement_ctrl_num = @settlement_ctrl_num)
	GROUP BY i.apply_to_num, i.apply_trx_type, i.customer_code


	delete #arinppdt4750 where apply_to_num = @inv_trx_ctrl_num and trx_ctrl_num <> @settlement_ctrl_num

	select @sequence = @sequence + 1

	select @count = @count + 1

	select @inv_trx_ctrl_num = MIN(apply_to_num) from #arinppdt4750 where apply_to_num > @inv_trx_ctrl_num

END

select @rec_amt_applied = SUM(amt_applied) from #arinppdt4750

select @rec_amt_applied = SUM(amt_payment) from #arinppyt4750


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arstldpp.cpp" + ", line " + STR( 151, 5 ) + " -- EXIT: "

select @rec_amt_applied, @inv_amt_applied


END

GO
GRANT EXECUTE ON  [dbo].[arstldpp_sp] TO [public]
GO
