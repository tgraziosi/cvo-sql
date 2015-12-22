SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_cost_accum] @part varchar(30), @loc varchar(10), @tran_code char(1), @tran_no int,
  @tran_ext int, @tran_line int, @seq_no int, @account varchar(10), @tran_date datetime
as

if @tran_code not in ('I','P')	return 1

if not exists (select 1 from config (nolock) where upper(flag) = 'INV_ACCUM_COST_LAYER' and upper(value_str) like 'Y%') return 1

DECLARE @sum_qty decimal(20,8), @sum_bal decimal(20,8), @accum_qty decimal(20,8), @accum_bal decimal(20,8),
@sum_m_cost decimal(20,8), @sum_d_cost decimal(20,8), @sum_o_cost decimal(20,8), @sum_u_cost decimal(20,8) -- mls 8/4/03 SCR 31312

if @tran_code = 'I'
begin
  select @sum_qty = sum(quantity), @sum_bal = sum(balance),
    @sum_m_cost = sum(isnull(tot_mtrl_cost,unit_cost * balance)),
    @sum_d_cost = sum(isnull(tot_dir_cost,direct_dolrs * balance)),
    @sum_o_cost = sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),
    @sum_u_cost = sum(isnull(tot_util_cost,util_dolrs * balance))
  from inv_costing
  where part_no = @part and location = @loc and tran_code = @tran_code and account = @account

  update inv_costing
  set quantity = @sum_qty, balance = @sum_bal,
    tot_mtrl_cost = @sum_m_cost, tot_dir_cost = @sum_d_cost, tot_ovhd_cost = @sum_o_cost,
    tot_util_cost = @sum_u_cost
  where part_no = @part and location = @loc and tran_code = @tran_code and sequence = @seq_no and account = @account

  insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,
	tran_ext,tran_line,account,tran_date,tran_age,unit_cost,quantity,
	inv_cost_bal,direct_dolrs,ovhd_dolrs,labor,util_dolrs, audit, org_cost,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost) 
  select part_no,location,-1,@tran_code,
	@tran_no,@tran_ext,@tran_line,account,@tran_date,tran_age,unit_cost,quantity,
	balance,direct_dolrs,ovhd_dolrs,labor,util_dolrs,audit, org_cost,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost
	from inv_costing where part_no=@part and
	location=@loc and account=@account  and tran_code = @tran_code and sequence != @seq_no

  if @@error > 0 return 0

  delete inv_costing where part_no=@part and
	location=@loc and
	account=@account and tran_code = @tran_code and sequence != @seq_no
end
else
if @tran_code = 'P'
begin
  select @sum_qty = sum(quantity), @sum_bal = sum(balance),
    @sum_m_cost = sum(isnull(tot_mtrl_cost,unit_cost * balance)),
    @sum_d_cost = sum(isnull(tot_dir_cost,direct_dolrs * balance)),
    @sum_o_cost = sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),
    @sum_u_cost = sum(isnull(tot_util_cost,util_dolrs * balance))
  from inv_costing
  where part_no = @part and location = @loc and tran_code = @tran_code and account = @account and
    tran_no = @tran_no and tran_ext = @tran_ext

  update inv_costing
  set quantity = @sum_qty, balance = @sum_bal,
    tot_mtrl_cost = @sum_m_cost, tot_dir_cost = @sum_d_cost, tot_ovhd_cost = @sum_o_cost,
    tot_util_cost = @sum_u_cost
  where part_no = @part and location = @loc and tran_code = @tran_code and sequence = @seq_no and 
    account = @account and tran_no = @tran_no and tran_ext = @tran_ext 

  insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,
	tran_ext,tran_line,account,tran_date,tran_age,unit_cost,quantity,
	inv_cost_bal,direct_dolrs,ovhd_dolrs,labor,util_dolrs, audit, org_cost,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost) 
  select part_no,location,-1,@tran_code,
	@tran_no,@tran_ext,@tran_line,account,@tran_date,tran_age,unit_cost,quantity,
	balance,direct_dolrs,ovhd_dolrs,labor,util_dolrs,audit, org_cost,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost
	from inv_costing where part_no=@part and
	location=@loc and account=@account  and tran_code = @tran_code and sequence != @seq_no and
	tran_no = @tran_no and tran_ext = @tran_ext

  if @@error > 0 return 0

  delete inv_costing where part_no=@part and
	location=@loc and tran_no = @tran_no and tran_ext = @tran_ext and
	account=@account and tran_code = @tran_code and sequence != @seq_no
end

GO
GRANT EXECUTE ON  [dbo].[fs_cost_accum] TO [public]
GO
