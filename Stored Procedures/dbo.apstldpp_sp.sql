SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[apstldpp_sp]	@settlement_ctrl_num varchar(16)

AS
BEGIN

DECLARE @vo_trx_ctrl_num varchar(16),
	@vo_amt_applied  float,
	@pay_amt_applied  float,
	@sequence	  int,
	@debug_level	  int,
	@vo_count	  int,
	@count		  int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apstldpp.cpp" + ", line " + STR( 47, 5 ) + " -- ENTRY: "

select @count = 1

select @vo_count = count(*) from #apinppdt3450

select @sequence = 1

select @vo_trx_ctrl_num = MIN(apply_to_num) from #apinppdt3450


while (@vo_count >= @count)
BEGIN


	insert into #apinppdt3450 
	select 
	NULL,
	@settlement_ctrl_num,
	MIN(i.trx_type),
	@sequence,
	i.apply_to_num,
	i.apply_trx_type,
	SUM(i.amt_applied),
	SUM(i.amt_disc_taken),
	MIN(i.line_desc),
	MIN(void_flag),
	MIN(i.payment_hold_flag),
	i.vendor_code,
	SUM(i.vo_amt_applied),
	SUM(i.vo_amt_disc_taken),
	SUM(i.gain_home),
	SUM(i.gain_oper),
	MIN(i.nat_cur_code), 
	MIN(i.cross_rate),
	i.org_id
	from apinppdt i
	where i.apply_to_num = @vo_trx_ctrl_num
	and   i.trx_ctrl_num in (select trx_ctrl_num from apinppyt where settlement_ctrl_num = @settlement_ctrl_num)
	GROUP BY i.apply_to_num, i.apply_trx_type, i.vendor_code, i.org_id

	delete #apinppdt3450 where apply_to_num = @vo_trx_ctrl_num and trx_ctrl_num <> @settlement_ctrl_num

	select @sequence = @sequence + 1

	select @count = @count + 1

	select @vo_trx_ctrl_num = MIN(apply_to_num) from #apinppdt3450 where apply_to_num > @vo_trx_ctrl_num


END

select @pay_amt_applied = SUM(amt_applied) from #apinppdt3450

select @pay_amt_applied = SUM(amt_payment) from #apinppyt3450


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apstldpp.cpp" + ", line " + STR( 104, 5 ) + " -- EXIT: "

select @pay_amt_applied, @vo_amt_applied


END

GO
GRANT EXECUTE ON  [dbo].[apstldpp_sp] TO [public]
GO
