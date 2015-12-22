SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[adm_ep_ins_xfr_line]
@proc_po_no		varchar(20),		 --	REQUIRED
@vendor_cd		varchar(12),		 -- REQUIRED
@part_no		varchar(30),		 --	REQUIRED
@ordered		decimal(20,8),		 --	REQUIRED
@line_no		integer = NULL,		 --	default NULL (get max + 1 line)
@time_entered	datetime = NULL,	 --	default getdate()
@comment		varchar(255) = NULL, -- default NULL
@who_entered	varchar(20) = NULL,	 -- default user_name()
@uom			char(2) = NULL		 -- default inv_master.uom (must have valid
									 --conversion to stocking UOM)
as

declare @status char(1), @xfer_no int,
@from_loc varchar(10), @to_loc varchar(10), @i_uom char(2),
@conv_factor decimal(20,8), @new_line int,
@x_part_no varchar(30), @chk_sku_ind int

if @proc_po_no is NULL  return -10
if @part_no is NULL return -20
if isnull(@ordered,0) <= 0 return -30

if @time_entered is null set @time_entered = getdate()
if @who_entered is null  set @who_entered = suser_name()

select @xfer_no = xfer_no,
  @status = status,
  @from_loc = from_loc,
  @to_loc = to_loc
from xfers_all (nolock) where proc_po_no = @proc_po_no

if @@rowcount = 0  return -11
if @status != 'N'  return -12
if isnull(@xfer_no,0)= 0 return -13

set @chk_sku_ind = 0
while 1=1
begin
  select @i_uom = uom
    from inv_master (nolock) 
  where part_no = @part_no

  if @@rowcount > 0 break

  if @chk_sku_ind > 0 return -21

  set @chk_sku_ind = 1

  select @part_no = sku_no
  from vendor_sku (nolock)
  where vend_sku = @part_no and vendor_no = @vendor_cd

  if @@rowcount = 0 return -21
end

if not exists (select 1 from inv_list (nolock) where part_no = @part_no
  and location = @from_loc)  return -22
if not exists (select 1 from inv_list (nolock) where part_no = @part_no
  and location = @to_loc)  return -23

set @conv_factor = 1

if @uom is null set @uom = @i_uom
if @i_uom != @uom
begin
  select @conv_factor = conv_factor
  from uom_table (nolock)
  where item = @part_no and std_uom = @i_uom and alt_uom = @uom

  if @@rowcount = 0
  begin
    select @conv_factor = conv_factor
    from uom_table (nolock)
    where item = 'STD' and std_uom = @i_uom and alt_uom = @uom

    if @@rowcount = 0  return -40
  end
end

if isnull(@line_no,0) =0
begin
  select @new_line = 1
  select @line_no = isnull((select max(line_no) from xfer_list (nolock)
    where xfer_no = @xfer_no),0) + 1
end
else
begin
  select @x_part_no from xfer_list (nolock)
    where xfer_no = @xfer_no and line_no = @line_no

  if @@rowcount > 0
  begin
    if @x_part_no <> @part_no  return -100
    return 100
  end
end

if @new_line = 0
begin
  return 100
end 
else
begin
  begin tran

  insert xfer_list (xfer_no,line_no,from_loc,to_loc,part_no,description,
    time_entered,ordered,shipped,comment,status,cost,com_flag,who_entered,
    temp_cost,uom,conv_factor,std_cost,from_bin,to_bin,lot_ser,date_expires,
    lb_tracking,labor,direct_dolrs,ovhd_dolrs,util_dolrs,display_line,
    qty_rcvd,reference_code,adj_code,amt_variance)
  select @xfer_no, @line_no, @from_loc, @to_loc, @part_no, description,
    @time_entered, @ordered, 0, @comment, @status, avg_cost * @conv_factor, NULL, @who_entered,
    0, @uom, @conv_factor, 0, NULL, 'IN TRANSIT', 'N/A', getdate(), lb_tracking,
    0, avg_direct_dolrs  * @conv_factor, avg_ovhd_dolrs  * @conv_factor, 
    avg_util_dolrs  * @conv_factor, @line_no, NULL, NULL, NULL, 0
  from inventory_unsecured_vw (nolock)
  where part_no = @part_no and location = @from_loc

  if @@error <> 0
  begin
    rollback tran
    return -200
  end 

  commit tran
end

return 1
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_xfr_line] TO [public]
GO
