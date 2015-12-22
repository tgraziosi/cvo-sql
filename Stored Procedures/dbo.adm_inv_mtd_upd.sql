SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[adm_inv_mtd_upd]
  @i_part_no varchar(30), @i_location varchar(10), @i_tran_type char(1), 
  @i_qty decimal(20,8), @i_amt decimal(20,8) = 0 as

begin

if @i_qty = 0 and @i_amt = 0
  return 1
 
declare @inv_chg decimal(20,8),
  @i_mtd decimal(20,8), @p_mtd decimal(20,8), 
  @u_mtd decimal(20,8), @s_mtd decimal(20,8), @r_mtd decimal(20,8), @x_mtd decimal(20,8) ,
  @period int

select @inv_chg = @i_qty
select @i_mtd = 0
select @p_mtd = 0
select @u_mtd = 0
select @s_mtd = 0
select @r_mtd = 0
select @x_mtd = 0

select @period = period
  from adm_inv_mtd_cal_f()


if @i_tran_type = 'I'
  select @i_mtd = @i_qty, @inv_chg = 0
if @i_tran_type = 'P'
  select @p_mtd = @i_qty, @inv_chg = 0
if @i_tran_type = 'U'
  select @u_mtd = @i_qty, @inv_chg = 0
if @i_tran_type = 'S'
  select @s_mtd = @i_qty, @inv_chg = 0
if @i_tran_type = 'R'
  select @r_mtd = @i_qty, @inv_chg = 0
if @i_tran_type = 'X'
  select @x_mtd = @i_qty, @inv_chg = 0

if @inv_chg != 0
  return -1

update mtd
set issued_qty = issued_qty + @i_mtd,
  produced_qty = produced_qty + @p_mtd,
  usage_qty = usage_qty + @u_mtd,
  sales_qty = sales_qty + @s_mtd,
  sales_amt = sales_amt + @i_amt,
  recv_qty = recv_qty + @r_mtd,
  xfer_qty = xfer_qty + @x_mtd
from adm_inv_mtd mtd 
where mtd.part_no = @i_part_no and mtd.location = @i_location
and mtd.period = @period

if @@rowcount = 0
begin
  insert adm_inv_mtd
  (part_no, location, period, issued_qty, produced_qty, usage_qty, sales_qty, sales_amt,
    recv_qty, xfer_qty)
  select
    @i_part_no, @i_location, @period, @i_mtd, @p_mtd, @u_mtd, @s_mtd, @i_amt, @r_mtd, @x_mtd

  if @@error <> 0
    return -2

  return 3
end

return 2
end 
GO
GRANT EXECUTE ON  [dbo].[adm_inv_mtd_upd] TO [public]
GO
