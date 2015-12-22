CREATE TABLE [dbo].[receipts_all]
(
[timestamp] [timestamp] NOT NULL,
[receipt_no] [int] NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sku_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[release_date] [datetime] NOT NULL,
[recv_date] [datetime] NOT NULL,
[part_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_cost] [decimal] (20, 8) NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_measure] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [int] NULL,
[freight_cost] [decimal] (20, 8) NOT NULL,
[account_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ext_cost] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vend_inv_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[pro_number] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bl_no] [int] NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__receipts___lb_tr__44BF7C42] DEFAULT ('N'),
[freight_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_inv_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_unit] [decimal] (20, 8) NOT NULL,
[voucher_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_key] [int] NULL,
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__receipts___qc_fl__45B3A07B] DEFAULT ('N'),
[qc_no] [int] NULL CONSTRAINT [DF__receipts___qc_no__46A7C4B4] DEFAULT ((0)),
[rejected] [decimal] (20, 8) NULL CONSTRAINT [DF__receipts___rejec__479BE8ED] DEFAULT ((0)),
[over_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__receipts___over___48900D26] DEFAULT ('N'),
[std_cost] [decimal] (20, 8) NULL CONSTRAINT [DF__receipts___std_c__4984315F] DEFAULT ((0)),
[std_direct_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__receipts___std_d__4A785598] DEFAULT ((0)),
[std_ovhd_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__receipts___std_o__50312EEE] DEFAULT ((0)),
[std_util_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__receipts___std_u__4B6C79D1] DEFAULT ((0)),
[nat_curr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[oper_factor] [decimal] (20, 8) NOT NULL,
[curr_factor] [decimal] (20, 8) NOT NULL,
[oper_cost] [decimal] (20, 8) NOT NULL,
[curr_cost] [decimal] (20, 8) NOT NULL,
[project1] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__receipts___proje__4C609E0A] DEFAULT (' '),
[project2] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__receipts___proje__4D54C243] DEFAULT (' '),
[project3] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__receipts___proje__4E48E67C] DEFAULT (' '),
[tax_included] [decimal] (20, 8) NULL,
[po_line] [int] NULL CONSTRAINT [DF__receipts___po_li__4F3D0AB5] DEFAULT ((0)),
[return_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[receipt_batch_no] [int] NOT NULL,
[amt_nonrecoverable_tax] [decimal] (20, 8) NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delrec] ON [dbo].[receipts_all]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_RECV' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 71399, 'You Can Not Delete A Receipt!' 
	return
	end
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insrec] ON [dbo].[receipts_all] FOR INSERT AS
BEGIN

-- 2/98- JLK - Insert Into in_gltrxdet for GL intergration at receipts time
-- 9/98- RAF - Lot/Bin DropShip logic.
--10/98- JLK - Added reference code Lookup for the inventory GL transaction
--10/98- JLK - Added logic for tax included on receipt

if exists (select 1 from config where flag='TRIG_INS_RECV' and value_str='DISABLE') return

declare @ordext int, @ordno int, @line_no int, @reference_code varchar(32)

declare
@i_receipt_no int ,
@i_po_no varchar (16) ,
@i_part_no varchar (30) ,
@i_sku_no varchar (30) ,
@i_location varchar (10) ,
@i_release_date datetime ,
@i_recv_date datetime ,
@i_part_type varchar (10) ,
@i_unit_cost decimal(20, 8) ,
@i_quantity decimal(20, 8) ,
@i_vendor varchar (12) ,
@i_unit_measure char (2) ,
@i_prod_no int ,
@i_freight_cost decimal(20, 8) ,
@i_account_no varchar (32) ,
@i_status char (1) ,
@i_ext_cost decimal(20, 8) ,
@i_who_entered varchar (20) ,
@i_vend_inv_no varchar (20) ,
@i_conv_factor decimal(20, 8) ,
@i_pro_number varchar (20) ,
@i_bl_no int ,
@i_lb_tracking char (1) ,
@i_freight_flag char (1) ,
@i_freight_vendor varchar (12) ,
@i_freight_inv_no varchar (20) ,
@i_freight_account varchar (32) ,
@i_freight_unit decimal(20, 8) ,
@i_voucher_no varchar (16) ,
@i_note varchar (255) ,
@i_po_key int ,
@i_qc_flag char (1),
@i_qc_no int ,
@i_rejected decimal(20, 8) ,
@i_over_flag char (1) ,
@i_std_cost decimal(20, 8) ,
@i_std_direct_dolrs decimal(20, 8) ,
@i_std_ovhd_dolrs decimal(20, 8) ,
@i_std_util_dolrs decimal(20, 8) ,
@i_nat_curr varchar (8) ,
@i_oper_factor decimal(20, 8) ,
@i_curr_factor decimal(20, 8) ,
@i_oper_cost decimal(20, 8) ,
@i_curr_cost decimal(20, 8) ,
@i_project1 varchar (75) ,
@i_project2 varchar (75) ,
@i_project3 varchar (75) ,
@i_tax_included decimal(20, 8) ,
@i_po_line int ,
@i_amt_nonrecoverable_tax decimal(20,8),
@i_org_id varchar(30),
@tempcost decimal(20,8),							-- mls 4/10/02 SCR 28686
@line_descr varchar(50), @line_descri varchar(50)				-- mls 4/10/02 SCR 28686

DECLARE @posting_code varchar(8), @pur_acct varchar(32),
@cost_var_acct varchar(32), @cost_var_direct_code varchar(32), @cost_var_ovhd_code varchar(32), 
@cost_var_util_code varchar(32), @stdaccount varchar(32), 
@direct_acct varchar(32), @ovhd_acct varchar(32),
@util_acct varchar(32), @typ char(1), @company_id int, @iloop int, @invcost decimal(20,8),
@stdcost decimal(20,8), @retval int, @close_percent decimal(20,8),
@lot varchar(25),@rcode varchar(10), @bin varchar(12),@dtexp datetime,
@qty decimal(20,8), 
@unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8),@labor decimal(20,8),@utility decimal(20,8), 
@qc_acct varchar(32), @ref_code varchar(32),							-- mls 1/24/03 SCR 29278
@old_i_acct varchar(32), @old_r_acct varchar(32), @old_i_ref_cd varchar(32), @old_r_ref_cd varchar(32) -- mls 1/24/03 SCR 30555

DECLARE @rel_ord_line int									-- mls 12/11/02 SCR 30429
DECLARE @receipt_cost decimal(20,8)

DECLARE @in_stock decimal(20,8), @temp_qty decimal(20,8), @d_unitcost decimal(20,8), @dummycost decimal(20,8), @COGS int
DECLARE @d_direct decimal(20,8), @d_overhead decimal(20,8), @d_utility decimal(20,8)

DECLARE @use_ac char(1)									-- mls 10/4/99
DECLARE @RCV_MISC_IN_COGP char(1)

DECLARE @ar_cgs_code varchar(32), @ar_cgs_direct_code varchar(32), @ar_cgs_ovhd_code varchar(32),
	@ar_cgs_util_code varchar(32), @i_acct varchar(32)

DECLARE @r_acct varchar(32)
DECLARE @skip_costing int, @status char(1)							-- mls 5/8/00 SCR 22830  

DECLARE @rel_status char(1), @temp_cost decimal(20,8)

DECLARE @a_tran_id int, @a_tran_data varchar(255),
  @a_unitcost decimal(20,8), @a_direct decimal(20,8), @a_overhead decimal(20,8), @a_labor decimal(20,8),
  @a_utility decimal(20,8), @msg varchar(500), @l_in_stock decimal(20,8)

declare @i_uomcost decimal(20,8)
declare @cogs_qty decimal(20,8), @cgp_unitcost decimal(20,8), @c_qty decimal(20,8),
@i_unitcost decimal(20,8), @i_direct decimal(20,8), @i_overhead decimal(20,8), @i_utility decimal(20,8),
@c_unitcost decimal(20,8), @c_direct decimal(20,8), @c_overhead decimal(20,8), @c_utility decimal(20,8),
@v_unitcost decimal(20,8), @v_direct decimal(20,8), @v_overhead decimal(20,8), @v_utility decimal(20,8),
@n_unitcost decimal(20,8), @n_direct decimal(20,8), @n_overhead decimal(20,8), @n_utility decimal(20,8)

declare @pl_receiving_loc varchar(10), @pc_account_no varchar(32), @pl_account_no varchar(32)
declare @rel_int_order_no int, @rel_int_ord_line int, @ord_list_shipped decimal(20,8)

declare @m_lb_tracking char(1), @m_status char(1),
@lb_sum decimal(20,8), @uom_sum decimal(20,8), @part_cnt int, @lb_part varchar(30), @lb_loc varchar(10),

@inv_lot_bin int,
@rc int, @mtd_qty decimal(20,8)
declare @tax_code varchar(10), @tax_included decimal(20,8), @nonrec_tax decimal(20,8)

declare @max_to_ship decimal(20,8), @l_row int, @l_qty decimal(20,8), @t_qty decimal(20,8)

select @close_percent = NULL, @use_ac = NULL

DECLARE recins CURSOR LOCAL FOR
SELECT i.receipt_no, i.po_no, i.part_no, i.sku_no, i.location, i.release_date, 
i.recv_date, i.part_type, i.unit_cost, i.quantity, i.vendor, i.unit_measure, 
i.prod_no, i.freight_cost, i.account_no, i.status, i.ext_cost, i.who_entered, 
i.vend_inv_no, i.conv_factor, i.pro_number, i.bl_no, i.lb_tracking, i.freight_flag, 
i.freight_vendor, i.freight_inv_no, i.freight_account, i.freight_unit, i.voucher_no, 
i.note, i.po_key, i.qc_flag, i.qc_no, i.rejected, i.over_flag, i.std_cost, 
i.std_direct_dolrs, i.std_ovhd_dolrs, i.std_util_dolrs, i.nat_curr, i.oper_factor, 
i.curr_factor, i.oper_cost, i.curr_cost, i.project1, i.project2, i.project3, 
i.tax_included, i.po_line ,
m.lb_tracking, m.status,
isnull(i.amt_nonrecoverable_tax,0),
isnull(i.organization_id,'')
from inserted i
left outer join inv_master m (nolock) on m.part_no = i.part_no

OPEN recins
FETCH NEXT FROM recins INTO
@i_receipt_no, @i_po_no, @i_part_no, @i_sku_no, @i_location, @i_release_date, 
@i_recv_date, @i_part_type, @i_unit_cost, @i_quantity, @i_vendor, @i_unit_measure, 
@i_prod_no, @i_freight_cost, @i_account_no, @i_status, @i_ext_cost, @i_who_entered, 
@i_vend_inv_no, @i_conv_factor, @i_pro_number, @i_bl_no, @i_lb_tracking, @i_freight_flag, 
@i_freight_vendor, @i_freight_inv_no, @i_freight_account, @i_freight_unit, @i_voucher_no, 
@i_note, @i_po_key, @i_qc_flag, @i_qc_no, @i_rejected, @i_over_flag, @i_std_cost, 
@i_std_direct_dolrs, @i_std_ovhd_dolrs, @i_std_util_dolrs, @i_nat_curr, @i_oper_factor, 
@i_curr_factor, @i_oper_cost, @i_curr_cost, @i_project1, @i_project2, @i_project3, 
@i_tax_included, @i_po_line ,
@m_lb_tracking, @m_status, @i_amt_nonrecoverable_tax, @i_org_id

While @@FETCH_STATUS = 0
begin

select @rel_status = status,
@rel_ord_line = ord_line,									-- mls 12/11/02 SCR 30429
@rel_int_order_no = int_order_no,
@rel_int_ord_line = int_ord_line
from releases 
where (po_no=@i_po_no) and (part_no = @i_part_no) and (release_date = @i_release_date) 
  and case when isnull(po_line,0)=0 then @i_po_line else po_line end = @i_po_line 		-- mls 7/12/01 SCR 6603

if @@ROWCOUNT = 0
BEGIN
  rollback tran
  exec adm_raiserror 81333, 'There Is Not A Valid Release For This Item!'
  return
END

if @rel_status = 'C'
begin
  rollback tran
  exec adm_raiserror 81331, 'You Can Not Receive A Purchase Item Which Is Closed!'
  return
END

if @rel_int_order_no is not null and @rel_int_ord_line is not null 
begin
  select @ord_list_shipped = sum(shipped)
  from ord_list
  where order_no = @rel_int_order_no and line_no = @rel_int_ord_line
    and part_no = @i_part_no and status > 'R'

  if isnull(@ord_list_shipped,0) = 0
  begin
    set @msg = 'This receipt is for material from an internal vendor organization.  The material has yet to be shipped' +
      ' by the other organization on their sales order [' + convert(varchar(10), @rel_int_order_no) + '].  Please contact the internal vendor to have them ship the material' +
      ' before you receive it.'
    rollback tran
    exec adm_raiserror 98000, @msg
    return
  end
end

if @i_part_type != 'M'
begin
  if @m_lb_tracking is null
  begin
    rollback tran
    exec adm_raiserror 832111 ,'Part does not exists in inventory.'
    RETURN
  end

  IF isnull(@m_status,'') = 'C'
  BEGIN
    rollback tran
    exec adm_raiserror 81334 ,'You can not receive Custom Kit Items.'
    RETURN
  END

  IF NOT exists(select 1 from inv_list where (part_no = @i_part_no) and (location = @i_location) )
  BEGIN
    rollback tran
    exec adm_raiserror 50001 ,'You Cannot Enter a Location That Is Not Valid For This Part!'
    return
  END
END

  if @inv_lot_bin is null
    select @inv_lot_bin = isnull((select 1 from config (nolock) where flag='INV_LOT_BIN' and upper(value_str) = 'YES' ),0)

  if isnull(@m_lb_tracking,'N') != @i_lb_tracking
  begin
    rollback tran
    exec adm_raiserror 832112 ,'Lot bin tracking flag mismatch with inventory.'
    RETURN
  end

  select @lb_sum = sum(qty * direction),
    @uom_sum = sum(uom_qty * direction),
    @part_cnt = count(distinct (part_no + '!@#' + location)) ,
    @lb_part = min(part_no),
    @lb_loc = min(location)
  from lot_bin_recv (nolock)
  where tran_no = @i_receipt_no

  if isnull(@m_lb_tracking,'') = 'Y' 
  begin
    if @inv_lot_bin = 1
    begin 
      if @part_cnt = 0
      begin
        rollback tran
        exec adm_raiserror 832113, 'No lot bin records found on lot_bin_recv for this receipt.'
        RETURN
      end
      if @part_cnt > 1
      begin
        rollback tran
        exec adm_raiserror 832113, 'More than one parts lot bin records found on lot_bin_recv for this receipt.'
        RETURN
      end
      if @uom_sum != @i_quantity
      begin
        select @msg = 'Receipt uom qty of [' + convert(varchar,@i_quantity) + '] does not equal the lot and bin uom qty of [' + convert(varchar,@uom_sum) + '].'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end
      if @lb_sum != (@i_quantity * @i_conv_factor)
      begin
        select @msg = 'Receipt qty of [' + convert(varchar,(@i_quantity * @i_conv_factor)) + '] does not equal the lot and bin qty of [' + convert(varchar,@lb_sum) + '].'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end
      if @lb_part != @i_part_no or @lb_loc != @i_location
      begin
        select @msg = 'Part/Location on lot_bin_recv is not the same as on receipts table.'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end
    end
    else
    begin
      if @part_cnt > 0
      begin
        select @msg = 'You cannot have lot bin records on an inbound transaction when you are not lb tracking.'
        rollback tran
        exec adm_raiserror 832114, @msg
        RETURN
      end
    end
  end
  else
  begin
    if @part_cnt > 0
    begin
      rollback tran
      exec adm_raiserror 832114, 'Lot bin records found on lot_bin_recv for this not lot/bin tracked part.'
      RETURN
    end
  end

if @i_part_type = 'M' and @i_qc_flag = 'Y'					-- mls 3/28/02 SCR 28575 start
begin
  rollback tran
  exec adm_raiserror 81335 ,'You can not QC miscellaneous parts.'
  RETURN
end										-- mls 3/28/02 SCR 28575 end

if @close_percent is NULL
begin
  select @close_percent=
    isnull(( select convert(decimal(20,8),value_str)/100.0 from config (nolock)
    where flag='RCV_CLOSE_PCT'),0.05)

  select @use_ac = isnull((select 'Y' from config (nolock) 						-- mls 5/3/00
    where flag = 'INV_USE_AVG_COST' and value_str like 'Y%'),'N')						-- mls 5/3/00

  select @RCV_MISC_IN_COGP = isnull((select 'Y' from config (nolock) 					-- mls 5/9/01 SCR 26911
    where flag = 'RCV_MISC_IN_COGP' and Upper(substring(value_str,1,1)) = 'Y'),'N')						

  SELECT @company_id = company_id from glco (nolock)							-- mls 5/3/00
end

if @i_org_id = ''												-- I/O start
begin
  select @i_org_id = dbo.adm_get_locations_org_fn(@i_location)
  select @i_account_no = dbo.adm_mask_acct_fn (@i_account_no, @i_org_id)

  update receipts_all
  set organization_id = @i_org_id , account_no = @i_account_no
  where receipt_no = @i_receipt_no
end
else
begin
  if @i_org_id != dbo.adm_get_locations_org_fn(@i_location)
  begin
    select @msg = 'Organization ([' + @i_org_id + ']) is not the current organization for Location ([' + @i_location + ']).'
    rollback tran
    exec adm_raiserror 832115,@msg
    RETURN
  end
end														-- I/O end

SELECT @COGS = 0, @in_stock = 0
SELECT @skip_costing = 0									-- mls 5/8/00 SCR 22830

--Get reference from po line for GL inventory transaction
SELECT @reference_code = isnull(reference_code,''),
@pl_account_no = account_no,
@pl_receiving_loc = receiving_loc,
@tax_code = tax_code
FROM pur_list(nolock)
WHERE po_no = @i_po_no AND part_no = @i_part_no and line = @i_po_line

if @@rowcount = 0
begin
    select @msg = 'The PO detail line could not be found for part [' + @i_part_no + '] on PO line [' + convert(varchar(10), @i_po_line)
      + '] of PO [' + @i_po_no + '].'
    rollback tran
    exec adm_raiserror 8308242, @msg
    return
end  

--Get stock amount in inventory
exec @rc = fs_calc_receipt_tax_wrap @i_po_no, @i_po_line, @tax_code, @i_quantity, @i_unit_cost, 
  1, @tax_included OUT, @nonrec_tax OUT

if @rc < 0
begin 
  rollback tran
  exec adm_raiserror 832111, 'Error returned calculating receipt taxes.'
  RETURN
end

if @i_tax_included != @tax_included or @i_amt_nonrecoverable_tax != @nonrec_tax
begin
  update receipts_all
  set tax_included = @tax_included,
    amt_nonrecoverable_tax = @nonrec_tax
  where receipt_no = @i_receipt_no

  set @i_tax_included = @tax_included
  set @i_amt_nonrecoverable_tax = @nonrec_tax
end

select @qty = (@i_quantity * @i_conv_factor),
  @a_direct = 0, @a_overhead = 0, @a_utility = 0, @a_labor = 0,
  @direct = 0, @overhead = 0, @labor = 0, @utility = 0, @labor = 0

if @i_tax_included = 0
  select @unitcost = @i_unit_cost
else
  select @unitcost = ((( (@i_unit_cost * @i_quantity) -
    (case when @i_curr_factor >= 0 then @i_tax_included * @i_curr_factor	-- mls 5/2/01 SCR 26874
     else @i_tax_included / abs(@i_curr_factor) end)				-- mls 5/2/01 SCR 26874
     ) / @i_quantity))

select @i_uomcost = @unitcost
select @unitcost = @i_uomcost * @i_quantity +  isnull(@i_amt_nonrecoverable_tax,0)

--if @i_part_type != 'M' 
--begin
  if @i_quantity != 0
  begin
    select         
      @a_tran_data = 'I' +		-- insert
        isnull(@i_qc_flag,'N') + @i_part_type

    select @cgp_unitcost = - @unitcost

    exec @retval = adm_inv_tran 
      'R', @i_receipt_no, 0, 0, @i_part_no, @i_location, @i_quantity, @i_recv_date, @i_unit_measure, 
      @i_conv_factor, @i_status, @a_tran_data OUT, DEFAULT, 
      @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT,
      @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT

    if @retval <> 1
    begin
      rollback tran
      select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
      exec adm_raiserror 83202, @msg
      RETURN
    end

    select @cogs_qty = convert(decimal(20,8),substring(@a_tran_data,1,30)),
      @n_unitcost = convert(decimal(20,8),substring(@a_tran_data,31,30)),
      @n_direct = convert(decimal(20,8),substring(@a_tran_data,61,30)),
      @n_overhead = convert(decimal(20,8),substring(@a_tran_data,91,30)),
      @n_utility = convert(decimal(20,8),substring(@a_tran_data,121,30))

    select @d_unitcost = @a_unitcost, @d_direct = @a_direct, @d_overhead = @a_overhead, @d_utility = @a_utility

    select @i_unitcost = @unitcost, @i_direct =  @direct, @i_overhead =  @overhead, @i_utility =  @utility
    select @c_unitcost = 0, @c_direct = 0, @c_overhead = 0, @c_utility = 0
    if @COGS != 0
      select @c_unitcost = -@cgp_unitcost - @unitcost,
        @c_direct = - @direct,
        @c_overhead = - @overhead,
        @c_utility = - @utility, @c_qty = @cogs_qty

    if @i_part_type = 'M' 					-- mls 7/7/04 SCR 33133
    begin
      select @i_unitcost = -@cgp_unitcost ,
        @i_direct = 0,
        @i_overhead = 0,
        @i_utility = 0
    end

    select @v_unitcost = - @i_unitcost - @cgp_unitcost - @c_unitcost,
      @v_direct = - @i_direct - @c_direct,
      @v_overhead = - @i_overhead - @c_overhead,
      @v_utility = - @i_utility - @c_utility

     











    if @i_part_type != 'M'
    begin
      if @i_qc_flag != 'Y' 
      begin
        update inv_recv
        set last_cost = cost,
          cost = @i_unit_cost / @i_conv_factor,							-- mls 2/7/03 SCR 30650
          last_recv_date = @i_recv_date,
          recv_mtd = (recv_mtd + (@i_quantity * @i_conv_factor) ),
          recv_ytd = (recv_ytd + (@i_quantity * @i_conv_factor) )
        where part_no=@i_part_no and location=@i_location

        -- mls 1/18/05 SCR 34050
        select @mtd_qty =  (@i_quantity * @i_conv_factor)
        exec @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'R', @mtd_qty
        if @rc < 1
        begin
          select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
          rollback tran
          exec adm_raiserror 9910141, @msg
          return
        end
      end
      else
      begin
        update inv_recv
        set hold_rcv = (hold_rcv + (@i_quantity * @i_conv_factor) )
        where part_no = @i_part_no and location = @i_location
      end
    end
  end

--BEGIN Lot/Bin DropShipment logic.
--Moved to before update of releaese							-- mls 01/24/06 SCR 36077


if @i_lb_tracking = 'Y'
begin
  select @ordno = 0			-- mls 7/27/99 SCR 70 19958

  if @rel_ord_line is not null								-- mls 12/11/02 SCR 30429 start
  begin
    select @ordno=oap.order_no, @line_no= @rel_ord_line
    from orders_auto_po oap
    where	oap.po_no = @i_po_no and oap.part_no= @i_part_no and oap.line_no = @rel_ord_line
  end
  else
  begin
    select @ordno=oap.order_no, @line_no=oap.line_no
    from orders_auto_po oap
    where	oap.po_no = @i_po_no and oap.part_no= @i_part_no
  end											-- mls 12/11/02 SCR 30429 end
	
  if isnull(@ordno,0) <> 0 and @i_qc_flag != 'Y'						-- mls 7/27/99 SCR 70 19958
  begin									-- mls 7/27/99 SCR 70 19958
    select @ordext=isnull((select max(ext) from orders_all where order_no=@ordno and status < 'S'),-1)

    if @ordext < 0
    begin
      rollback tran
      exec adm_raiserror 81328, 'Error. Cannot find open drop ship order!'
      return
    end

    if @i_location not like 'DROP%'
    begin
     select @max_to_ship = isnull((select ordered * conv_factor from ord_list (nolock)
     where order_no = @ordno and order_ext = @ordext and line_no = @line_no),0)
     select @max_to_ship = @max_to_ship + isnull((select sum(qty * direction) from lot_bin_ship (nolock)
     where tran_no = @ordno and tran_ext = @ordext and line_no = @line_no),0)
     if @max_to_ship < 0   set @max_to_ship = 0
    end

    select @t_qty = 0
    select @l_row = isnull((select min(row_id) from lot_bin_recv r (nolock)
      where tran_no = @i_receipt_no),NULL)
    while @l_row is not NULL
    begin
    select @l_qty = qty * direction
    from lot_bin_recv where row_id = @l_row and tran_no = @i_receipt_no

    if @i_location not like 'DROP%'
    begin
      select @l_qty = case when @max_to_ship < (@t_qty + @l_qty) then @max_to_ship - @t_qty else @l_qty end
      select @t_qty = @t_qty + @l_qty
    end
   
    UPDATE lot_bin_ship							-- mls 7/27/99 SCR 70 19958 start
    SET uom_qty=s.uom_qty + @l_qty / s.conv_factor,
      qty=s.qty + @l_qty
    FROM lot_bin_ship s, lot_bin_recv x
    WHERE s.tran_no=@ordno and s.tran_ext=@ordext and
      s.line_no=@line_no and s.lot_ser=x.lot_ser and s.bin_no=x.bin_no 
      and x.tran_no = @i_receipt_no and x.row_id = @l_row		-- mls 7/27/99 SCR 70 19958 end

    INSERT lot_bin_ship (qc_flag, tran_code, uom, date_expires, date_tran, uom_qty,
      conv_factor, cost, qty, tran_no, line_no, tran_ext, direction, part_no, who,
      bin_no, location, lot_ser )
    SELECT 'N', 'Q', uom, date_expires, date_tran, @l_qty / conv_factor, conv_factor, cost, @l_qty,
      @ordno, @line_no, @ordext, -1, part_no, who, bin_no, location, lot_ser
    FROM lot_bin_recv x
    WHERE tran_no = @i_receipt_no and row_id = @l_row
      and not exists (select 1 from lot_bin_ship l				-- mls 7/27/99 SCR 70 19958 start
        WHERE l.tran_no=@ordno and l.tran_ext=@ordext and
          l.line_no=@line_no and l.lot_ser=x.lot_ser and l.bin_no=x.bin_no)

      if @l_qty = @max_to_ship and @i_location not like 'DROP%'
        select @l_row = NULL
      else
        select @l_row = isnull((select min(row_id) from lot_bin_recv r (nolock)
          where tran_no = @i_receipt_no and row_id > @l_row),NULL)
    end
  end -- ordno <> 0							-- mls 7/27/99 SCR 70 19958 end
end

--This is the END of Lot/Bin DropShip logic.

-- sync location column change to releases table
update releases
set received = received + @i_quantity,
location = @i_location
where (po_no=@i_po_no) and (part_no = @i_part_no) and (release_date = @i_release_date) 
and case when isnull(po_line,0)=0 then @i_po_line else po_line end = @i_po_line 		-- mls 7/12/01 SCR 6603

update releases
set status='C'
where (po_no=@i_po_no) and (part_no = @i_part_no) and (release_date = @i_release_date)
  and case when isnull(po_line,0)=0 then @i_po_line else po_line end = @i_po_line 		-- mls 7/12/01 SCR 6603
  and quantity > 0 and ((((quantity - received) / 1.0000) / quantity) <= @close_percent) 


if @i_qc_flag = 'Y'
BEGIN
  --Need to QC the part before release it.
  --Note: the process use QC account
  select @lot=null, @bin=null, @dtexp=null

  if @i_lb_tracking = 'Y'
  begin
    select @lot = lot_ser, @bin = bin_no, @dtexp = date_expires
    from lot_bin_recv b
    where b.location = @i_location and b.part_no = @i_part_no and b.tran_no = @i_receipt_no 
  end

  exec fs_enter_qc 'R', @i_receipt_no, 0, 0, @i_part_no, @i_location, 
    @lot, @bin, @qty, @i_vendor, @i_who_entered, @rcode, @dtexp

  select @skip_costing = 0					-- mls 1/24/03 SCR 29278
END

if @i_part_type = 'M'										-- mls 2/1/01 SCR 25824
BEGIN
  select @typ = 'A',									-- mls 5/9/01 SCR 26911
    @status = NULL									-- mls 12/11/03 

  if @RCV_MISC_IN_COGP = 'N'								-- mls 5/9/01 SCR 26911
    select @skip_costing = 1								-- mls 5/8/00 SCR 22830
  else
  begin
    SELECT @posting_code = apacct_code
    FROM locations_all (nolock)
    WHERE location = @i_location
  end
END
else
begin
  SELECT @typ = m.inv_cost_method,
  @skip_costing = case when (isnull(m.status,'V') = 'V' ) and @RCV_MISC_IN_COGP = 'N' then 1 else 0 end,
  @posting_code = l.acct_code,
  @status = m.status											-- mls 12/11/03
  FROM inv_list l(nolock), inv_master m(nolock)
  WHERE m.part_no = l.part_no AND l.part_no = @i_part_no AND l.location = @i_location
end

if @i_qc_flag != 'Y' and @i_part_type != 'M'								-- mls 5/9/01 SCR 26911
begin
  --Case of no need for QC.
  if exists ( select 1 from agents WHERE part_no = @i_part_no and agent_type = 'R' )
  begin
    exec @retval=fs_agent @i_part_no, 'R', @i_receipt_no, @i_recv_date, @i_who_entered, @qty	-- mls 6/2/00 SCR 22994

    if @retval= -3
    begin
      rollback tran
      exec adm_raiserror 81324 ,'Agent Error... Outsource item not found on this Prod No!'
      return
    end

    if @retval < =0
    begin
      rollback tran
      exec adm_raiserror 81325, 'Agent Error... Try Re-Saving!'
      return
    end
  end --END IF
end --END IF QC


if @i_prod_no > 0												-- mls 5/3/00
begin
  exec @retval = fs_wip_prod @i_prod_no, @i_receipt_no, @i_part_no, @i_location, @i_quantity				-- mls 5/3/00

  if @retval <= 0
  begin
    rollback tran
    exec adm_raiserror 81327, 'Error Auto-Posting Production/WIP from Receiving!'
    return
  end
end


if (@skip_costing = 1)	GOTO SKIP_GL_TRANS							-- mls 5/8/00 SCR 22830

--BEGIN GL TRANSACTIONS
--Insert GL Transaction Table for GL Cost Xfer to Acct


if (@skip_costing = 1)	
begin
  if @pl_receiving_loc <> @i_location
  begin
    update pur_list
    set receiving_loc = @i_location,
      location = @i_location
    WHERE po_no = @i_po_no AND part_no = @i_part_no and line = @i_po_line									
  end
  
  GOTO SKIP_GL_TRANS							-- mls 5/8/00 SCR 22830
end

-- Get Accounts
SELECT @pur_acct = ap_cgp_code,
  @cost_var_acct = cost_var_code,
  @cost_var_direct_code = cost_var_direct_code, -- SCR 18779
  @cost_var_ovhd_code = cost_var_ovhd_code, -- SCR 18779
  @cost_var_util_code = cost_var_util_code, -- SCR 18779
  @pc_account_no = dbo.adm_mask_acct_fn (inv_acct_code, @i_org_id),
  @direct_acct = inv_direct_acct_code,
  @ovhd_acct = inv_ovhd_acct_code,
  @util_acct = inv_util_acct_code,
  @ar_cgs_code = ar_cgs_code,
  @ar_cgs_direct_code = ar_cgs_direct_code ,
  @ar_cgs_ovhd_code = ar_cgs_ovhd_code,
  @ar_cgs_util_code = ar_cgs_util_code,
  @qc_acct = qc_acct_code						-- mls 1/24/03 SCR 29278
FROM in_account(nolock)
WHERE acct_code = @posting_code


select @ref_code = @reference_code
if @pl_account_no <> @i_account_no or @pl_receiving_loc <> @i_location				-- mls 3/12/03 SCR 30824 start
begin
  if (@i_part_type = 'M' or isnull(@status,'V') = 'V')
  begin
    if @pl_account_no <> @i_account_no
    begin
      rollback tran
      exec adm_raiserror 830824 ,'The account code is not the same as the account code on the purchase order for a miscellaneous or NQB part!'
      return
    end
  end
  else
  begin 
    if @pl_receiving_loc <> @i_location and @pc_account_no <> @i_account_no
    begin
      rollback tran
      exec adm_raiserror 8308243 ,'The account code on the receipt is not the same as the account code for the inventory posting code'
      return
    end
  end

  if @pl_account_no <> @i_account_no
  begin
    select @ref_code= ''
    if exists (select 1 from glrefact (nolock) where @i_account_no like account_mask and reference_flag = 1)
    begin
      if not exists (select 1 from glratyp t (nolock), glref r (nolock)
        where t.reference_type = r.reference_type and @i_account_no like t.account_mask and
        r.status_flag = 0 and r.reference_code  = @reference_code)
      begin
        select @msg = 'The receipts account code [' + @i_account_no + '] requires a reference code.'
        if @reference_code <> ''
          select @msg = @msg + '  Reference code ([' + @reference_code + ']) is not valid for the account.'
        rollback tran
        exec adm_raiserror 830824, @msg
        return
      end
      select @ref_code = @reference_code
    end
    if exists (select 1 from glrefact (nolock) where @i_account_no like account_mask and reference_flag = 2)
    begin
      if exists (select 1 from glratyp t (nolock), glref r (nolock)
        where t.reference_type = r.reference_type and @i_account_no like t.account_mask and
        r.status_flag = 0 and r.reference_code  = @reference_code)
      select @ref_code = @reference_code
    end
  end
end											-- mls 3/12/03 SCR 30824 end

if @pl_account_no <> @i_account_no or @reference_code <> @ref_code or @pl_receiving_loc <> @i_location
begin
  update pur_list
  set account_no = @i_account_no,
    reference_code = @ref_code,
    receiving_loc = @i_location,
    location = @i_location
  WHERE po_no = @i_po_no AND part_no = @i_part_no and line = @i_po_line									

  select @reference_code = @ref_code
end

--select @temp_qty = @qty * -1
select @tempcost = @cgp_unitcost / @qty

--Insert into Purchase Expense Account
if @cgp_unitcost != 0
begin
  select @ref_code = ''									-- mls 1/24/03 SCR 30555 start
  if exists (select 1 from glrefact (nolock) where @pur_acct like account_mask and reference_flag > 1)
  begin
    if exists (select 1 from glratyp t (nolock), glref r (nolock)
      where t.reference_type = r.reference_type and @pur_acct like t.account_mask and
              r.status_flag = 0 and r.reference_code  = @reference_code)
      select @ref_code = @reference_code
  end											-- mls 1/21/03 SCR 30555 end

  exec @retval = adm_gl_insert @i_part_no, @i_location, 'R', @i_receipt_no, 0, 0,
    @i_recv_date, @qty, @tempcost,						-- mls 6/2/00 SCR 22994
    @pur_acct, @i_nat_curr, @i_curr_factor, @i_oper_factor, @company_id,		-- mls 2/9/01 SCR 24318
    DEFAULT, @ref_code, @a_tran_id, 'ap_cgp_acct', @cgp_unitcost					-- mls 1/24/03 SCR 30555
    

  IF @retval <= 0
  BEGIN
    rollback tran
    exec adm_raiserror 81313, 'Error Inserting COGP GL Costing Record!'
    return
  END
END

  if @i_qc_flag != 'Y'
  begin
    SELECT @invcost = @unitcost --Set Inventory Matl Cost to Standard!

    --Inventory Accounts
    SELECT @iloop = 1
    select @old_r_acct = '', @old_r_ref_cd = ''							-- mls 1/24/03 SCR 30555

    WHILE @iloop <= 4
    BEGIN
      Select @stdcost =
        CASE @iloop
        WHEN 1 THEN @v_unitcost WHEN 2 THEN @v_direct WHEN 3 THEN @v_overhead WHEN 4 THEN @v_utility END,
      @stdaccount =
        CASE @iloop
        WHEN 1 THEN @cost_var_acct WHEN 2 THEN @cost_var_direct_code 
        WHEN 3 THEN @cost_var_ovhd_code WHEN 4 THEN @cost_var_util_code END,
      @line_descr =
        CASE @iloop
        WHEN 1 THEN 'cost_var_acct' WHEN 2 THEN 'cost_var_direct_acct'
        WHEN 3 THEN 'cost_var_ovhd_acct' WHEN 4 THEN 'cost_var_util_acct' END

      IF @stdcost != 0
      BEGIN
        select @ref_code = ''									-- mls 1/24/03 SCR 30555 start
        if @old_r_acct = @stdaccount									
          select @ref_code = @old_r_ref_cd
        else
        begin
          if exists (select 1 from glrefact (nolock) where @stdaccount like account_mask and reference_flag > 1)
          begin
            if exists (select 1 from glratyp t (nolock), glref r (nolock)
              where t.reference_type = r.reference_type and @stdaccount like t.account_mask and
              r.status_flag = 0 and r.reference_code  = @reference_code)
            select @ref_code = @reference_code
          end
          select @old_r_acct = @stdaccount, @old_r_ref_cd = @ref_code
        end											-- mls 1/21/03 SCR 30555 end

        select @temp_cost = @stdcost / @qty

       exec @retval = adm_gl_insert @i_part_no, @i_location, 'R', @i_receipt_no, 0, 0,
          @i_recv_date, @qty, @temp_cost, @stdaccount,				-- mls 6/2/00 SCR 22994
          @i_nat_curr, @i_curr_factor, @i_oper_factor, @company_id,		-- mls 2/9/01 SCR 24318
	  DEFAULT,@ref_code, @a_tran_id, @line_descr, @stdcost,1			-- mls 1/24/03 SCR 30555 -- mls 4/10/02 SCR 28686

        IF @retval <= 0
        BEGIN
          rollback tran
          exec adm_raiserror 81310 ,'Error Inserting Cost Variance GL Costing Record!'
          return
        END
      END

      SELECT @iloop = @iloop + 1
    END --While
	

    --Inventory Accounts
    SELECT @iloop = 1

    WHILE @iloop <= 4
    BEGIN
      Select @stdcost =
        CASE @iloop
        WHEN 1 THEN @i_unitcost WHEN 2 THEN @i_direct WHEN 3 THEN @i_overhead WHEN 4 THEN @i_utility END,
      @stdaccount =
        CASE @iloop
        WHEN 1 THEN @i_account_no WHEN 2 THEN @direct_acct WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct END,
      @line_descr =
        CASE @iloop
        WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

      IF @stdcost != 0
      BEGIN
        select @ref_code = @reference_code							-- mls 1/24/03 SCR 30555 start
        if @iloop != 1
        begin        
          select @ref_code = ''									-- mls 1/24/03 SCR 30555 start
          if @old_r_acct = @stdaccount									
            select @ref_code = @old_r_ref_cd
          else
          begin
            if exists (select 1 from glrefact (nolock) where @stdaccount like account_mask and reference_flag > 1)
            begin
              if exists (select 1 from glratyp t (nolock), glref r (nolock)
                where t.reference_type = r.reference_type and @stdaccount like t.account_mask and
                r.status_flag = 0 and r.reference_code  = @reference_code)
              select @ref_code = @reference_code
            end
            select @old_r_acct = @stdaccount, @old_r_ref_cd = @ref_code
          end											-- mls 1/21/03 SCR 30555 end
        end
 
        select @temp_cost = @stdcost / @qty
        exec @retval = adm_gl_insert @i_part_no, @i_location, 'R', @i_receipt_no, 0, 0,
          @i_recv_date, @qty, @temp_cost, @stdaccount,				-- mls 6/2/00 SCR 22994
          @i_nat_curr, @i_curr_factor, @i_oper_factor, @company_id,		-- mls 2/9/01 SCR 24318
	  DEFAULT,@ref_code,@a_tran_id, @line_descr,@stdcost			-- mls 1/24/03 SCR 30555 -- mls 4/10/02 SCR 28686

        IF @retval <= 0
        BEGIN
          rollback tran
          exec adm_raiserror 81311, 'Error Inserting Inventory GL Costing Record!'
          return
        END
      END

      SELECT @iloop = @iloop + 1
    END --While
  END -- qc != 'Y'


--Insert into Inventory Account
--Send reference code to SP for Inventory Account

select @temp_qty = @qty

  if @i_qc_flag = 'Y'
  begin
  select @tempcost = @i_unitcost / @qty
  select @line_descr = case @i_qc_flag when 'Y' then 'QC_acct' else 'inv_acct' end	-- mls 1/24/03 SCR 29278 start
  select @i_acct = case @i_qc_flag when 'Y' then @qc_acct else @i_account_no end
  select @ref_code = case @i_qc_flag when 'Y' then '' else @reference_code end		-- mls 1/21/03 SCR 30555 start

    if exists (select 1 from glrefact (nolock) where @i_acct like account_mask and reference_flag > 1)
    begin
      if exists (select 1 from glratyp t (nolock), glref r (nolock)
        where t.reference_type = r.reference_type and @i_acct like t.account_mask and
                r.status_flag = 0 and r.reference_code  = @reference_code)
        select @ref_code = @reference_code
    end
											-- mls 1/24/03 SCR 29278 end
  exec @retval = adm_gl_insert @i_part_no, @i_location, 'R', @i_receipt_no, 0, 0,	-- mls 4/10/02 SCR 28686 start
    @i_recv_date, @qty, @tempcost, @i_acct,						-- mls 1/24/03 SCR 29278
    @i_nat_curr, @i_curr_factor, @i_oper_factor, @company_id,DEFAULT, @ref_code,	-- mls 1/24/03 SCR 30555
    @a_tran_id, @line_descr, @i_unitcost, 1
    
  select @invcost = @invcost * @qty

IF @retval <= 0
BEGIN
  rollback tran
  exec adm_raiserror 81312, 'Error Inserting QC GL Costing Record!'
  return
END
  end											-- mls 1/21/03 SCR 30555 end

IF ( @COGS <> 0 )
BEGIN
  IF (@COGS = 1)
    select @temp_qty = @qty
  ELSE
    select @temp_qty = abs(@in_stock)

  --Loop through and create Cost of Good Sold Account.
  SELECT @iloop = 1
  select @old_i_ref_cd = '', @old_i_acct = '', @old_r_ref_cd = '', @old_r_acct = ''	-- mls 1/24/03 SCR 30555

  WHILE @iloop <= 4
  BEGIN
    SELECT 
      @invcost =
        CASE @iloop
          WHEN 1 THEN @c_unitcost WHEN 2 THEN @c_direct
          WHEN 3 THEN @c_overhead WHEN 4 THEN @c_utility END,
      @i_acct =
        CASE @iloop
          WHEN 1 THEN @ar_cgs_code WHEN 2 THEN @ar_cgs_direct_code
          WHEN 3 THEN @ar_cgs_ovhd_code WHEN 4 THEN @ar_cgs_util_code END,
      @r_acct =
        CASE @iloop
          WHEN 1 THEN '' WHEN 2 THEN @direct_acct WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct END,
      @line_descr =
        CASE @iloop
          WHEN 1 THEN 'ar_cgs_acct' WHEN 2 THEN 'ar_cgs_direct_acct'
          WHEN 3 THEN 'ar_cgs_ovhd_acct' WHEN 4 THEN 'ar_cgs_util_acct' END

    If @invcost <> 0
    Begin
      select @ref_code = ''									-- mls 1/24/03 SCR 30555 start
      if @old_i_acct = @i_acct									
        select @ref_code = @old_i_ref_cd
      else
      begin
        if exists (select 1 from glrefact (nolock) where @i_acct like account_mask and reference_flag > 1)
        begin
          if exists (select 1 from glratyp t (nolock), glref r (nolock)
            where t.reference_type = r.reference_type and @i_acct like t.account_mask and
            r.status_flag = 0 and r.reference_code  = @reference_code)
          select @ref_code = @reference_code
        end
        select @old_i_acct = @i_acct, @old_i_ref_cd = @ref_code
      end											-- mls 1/21/03 SCR 30555 end

      select @tempcost = @invcost / @temp_qty
      exec @retval = adm_gl_insert @i_part_no, @i_location, 'R', @i_receipt_no, 0, 0,
        @i_recv_date, @temp_qty, @tempcost,					-- mls 6/2/00 SCR 22994
        @i_acct, @i_nat_curr, @i_curr_factor, @i_oper_factor, @company_id,	-- mls 2/9/01 SCR 24318
	DEFAULT,@ref_code,@a_tran_id, @line_descr,@invcost				-- mls 1/24/03 SCR 30555 -- mls 4/10/02 SCR 28686

      IF @retval <= 0
      BEGIN
        rollback tran
        exec adm_raiserror 81313, 'Error Inserting COGS GL Costing Record!'
        return
      END
    end

    SELECT @iloop = @iloop + 1
  END --While
END

SKIP_GL_TRANS:											-- mls 5/3/00 SCR 22830

FETCH NEXT FROM recins into
@i_receipt_no, @i_po_no, @i_part_no, @i_sku_no, @i_location, @i_release_date, 
@i_recv_date, @i_part_type, @i_unit_cost, @i_quantity, @i_vendor, @i_unit_measure, 
@i_prod_no, @i_freight_cost, @i_account_no, @i_status, @i_ext_cost, @i_who_entered, 
@i_vend_inv_no, @i_conv_factor, @i_pro_number, @i_bl_no, @i_lb_tracking, @i_freight_flag, 
@i_freight_vendor, @i_freight_inv_no, @i_freight_account, @i_freight_unit, @i_voucher_no, 
@i_note, @i_po_key, @i_qc_flag, @i_qc_no, @i_rejected, @i_over_flag, @i_std_cost, 
@i_std_direct_dolrs, @i_std_ovhd_dolrs, @i_std_util_dolrs, @i_nat_curr, @i_oper_factor, 
@i_curr_factor, @i_oper_cost, @i_curr_cost, @i_project1, @i_project2, @i_project3, 
@i_tax_included, @i_po_line ,
@m_lb_tracking, @m_status, @i_amt_nonrecoverable_tax, @i_org_id
end 


CLOSE recins
DEALLOCATE recins

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
CREATE TRIGGER [dbo].[t700updrec] ON [dbo].[receipts_all]   FOR UPDATE  AS   
BEGIN  
  
--10/98- JLK - Added reference code Lookup for the inventory GL transaction  
--10/98- JLK - Added logic for tax included on receipt  
if exists (select * from config (nolock) where flag='TRIG_UPD_REC' and value_str='DISABLE') return -- mls 5/8/01 #37  
  
if update(qc_no) and NOT ( UPDATE(unit_cost) OR UPDATE(quantity) OR UPDATE(part_no) or  
UPDATE(location) or update(status) or update(qc_flag)) return  
  
if update(amt_nonrecoverable_tax) and update(tax_included) and NOT ( UPDATE(unit_cost) OR UPDATE(quantity) OR UPDATE(part_no) or  
UPDATE(location) or update(status) or update(qc_flag)) return  
  
IF update(unit_cost) and update(quantity)  
BEGIN  
  rollback tran  
  exec adm_raiserror 91334, 'You Cannot Update Cost and Quantity in Same Transaction! (Split The Transactions)!'  
  return  
END  
  
IF update(std_cost) or update(std_direct_dolrs) or update(std_ovhd_dolrs) or update(std_util_dolrs)  
BEGIN  
  rollback tran  
  exec adm_raiserror 91335 ,'You Cannot Update Std Cost on a Receipt!'  
  return  
END  
  
declare  
@i_receipt_no int ,  
@i_po_no varchar (16) ,  
@i_part_no varchar (30) ,  
@i_sku_no varchar (30) ,  
@i_location varchar (10) ,  
@i_release_date datetime ,  
@i_recv_date datetime ,  
@i_part_type varchar (10) ,  
@i_unit_cost decimal(20, 8) ,  
@i_quantity decimal(20, 8) ,  
@i_vendor varchar (12) ,  
@i_unit_measure char (2) ,  
@i_prod_no int ,  
@i_freight_cost decimal(20, 8) ,  
@i_account_no varchar (32) ,  
@i_status char (1) ,  
@i_ext_cost decimal(20, 8) ,  
@i_who_entered varchar (20) ,  
@i_vend_inv_no varchar (20) ,  
@i_conv_factor decimal(20, 8) ,  
@i_pro_number varchar (20) ,  
@i_bl_no int ,  
@i_lb_tracking char (1) ,  
@i_freight_flag char (1) ,  
@i_freight_vendor varchar (12) ,  
@i_freight_inv_no varchar (20) ,  
@i_freight_account varchar (32) ,  
@i_freight_unit decimal(20, 8) ,  
@i_voucher_no varchar (16) ,  
@i_note varchar (255) ,  
@i_po_key int ,  
@i_qc_flag char (1),  
@i_qc_no int ,  
@i_rejected decimal(20, 8) ,  
@i_over_flag char (1) ,  
@i_std_cost decimal(20, 8) ,  
@i_std_direct_dolrs decimal(20, 8) ,  
@i_std_ovhd_dolrs decimal(20, 8) ,  
@i_std_util_dolrs decimal(20, 8) ,  
@i_nat_curr varchar (8) ,  
@i_oper_factor decimal(20, 8) ,  
@i_curr_factor decimal(20, 8) ,  
@i_oper_cost decimal(20, 8) ,  
@i_curr_cost decimal(20, 8) ,  
@i_project1 varchar (75) ,  
@i_project2 varchar (75) ,  
@i_project3 varchar (75) ,  
@i_tax_included decimal(20, 8) ,  
@i_po_line int,  
@i_amt_nonrecoverable_tax decimal(20,8),  
@i_org_id varchar(30)  
declare  
@d_receipt_no int ,  
@d_po_no varchar (16) ,  
@d_part_no varchar (30) ,  
@d_sku_no varchar (30) ,  
@d_location varchar (10) ,  
@d_release_date datetime ,  
@d_recv_date datetime ,  
@d_part_type varchar (10) ,  
@d_unit_cost decimal(20, 8) ,  
@d_quantity decimal(20, 8) ,  
@d_vendor varchar (12) ,  
@d_unit_measure char (2) ,  
@d_prod_no int ,  
@d_freight_cost decimal(20, 8) ,  
@d_account_no varchar (32) ,  
@d_status char (1) ,  
@d_ext_cost decimal(20, 8) ,  
@d_who_entered varchar (20) ,  
@d_vend_inv_no varchar (20) ,  
@d_conv_factor decimal(20, 8) ,  
@d_pro_number varchar (20) ,  
@d_bl_no int ,  
@d_lb_tracking char (1) ,  
@d_freight_flag char (1) ,  
@d_freight_vendor varchar (12) ,  
@d_freight_inv_no varchar (20) ,  
@d_freight_account varchar (32) ,  
@d_freight_unit decimal(20, 8) ,  
@d_voucher_no varchar (16) ,  
@d_note varchar (255) ,  
@d_po_key int ,  
@d_qc_flag char (1),  
@d_qc_no int ,  
@d_rejected decimal(20, 8) ,  
@d_over_flag char (1) ,  
@d_std_cost decimal(20, 8) ,  
@d_std_direct_dolrs decimal(20, 8) ,  
@d_std_ovhd_dolrs decimal(20, 8) ,  
@d_std_util_dolrs decimal(20, 8) ,  
@d_nat_curr varchar (8) ,  
@d_oper_factor decimal(20, 8) ,  
@d_curr_factor decimal(20, 8) ,  
@d_oper_cost decimal(20, 8) ,  
@d_curr_cost decimal(20, 8) ,  
@d_project1 varchar (75) ,  
@d_project2 varchar (75) ,  
@d_project3 varchar (75) ,  
@d_tax_included decimal(20, 8) ,  
@d_po_line int,  
@d_amt_nonrecoverable_tax decimal(20,8)  
  
declare @icostf float,      -- mls 2/28/02 SCR 28448 start  
@iopercostf float, @dopercostf float, @dopercostf2 float,  
@dcostf float,        
@dcostf2 float       -- mls 2/28/02 SCR 28448 end  
  
DECLARE @posting_code varchar(8)  
DECLARE @pur_acct   varchar(32),@var_acct     varchar(32),  
 @direct_acct varchar(32)  
DECLARE @ovhd_acct  varchar(32),@util_acct    varchar(32),@ins_account   varchar(32),@recv_acct varchar(32)  
DECLARE @reference_code varchar(32), @company_id int, @iloop int, @inchg int, @prchg int, @typ char(1),  
  @tax_code varchar(10), @tax_included decimal(20,8), @nonrec_tax decimal(20,8)  
  
DECLARE @layer_qty decimal(20,8), @stdutil decimal(20,8)  
DECLARE @varmatl   decimal(20,8), @invdelta  decimal(20,8), @prdelta   decimal(20,8), @nrtdelta decimal(20,8)  
DECLARE @stdcost   decimal(20,8), @stddirect decimal(20,8), @stdovhd   decimal(20,8), @cost    decimal(20,8)  
DECLARE @icost     decimal(20,8), @qty       decimal(20,8)  
DECLARE @qc_stock_account varchar(10), @inv_stock_account varchar(10)  
DECLARE @negcost decimal(20,8), @negdirect decimal(20,8), @negovhd decimal(20,8), @negutil decimal(20,8)  
  
DECLARE @i_uomcost decimal(20,8), @d_uomcost decimal(20,8)  
--rev3 start  
DECLARE @opervarmatl   decimal(20,8), @operprdelta   decimal(20,8)  
DECLARE @operstdcost   decimal(20,8), @operstddirect decimal(20,8),  @operstdutil decimal(20,8)  
DECLARE @operstdovhd   decimal(20,8), @opercost    decimal(20,8), @iopercost     decimal(20,8)  
  
DECLARE @dopercost decimal(20,8), @operdirect decimal(20,8), @operoverhead decimal(20,8)  
DECLARE @operutility decimal(20,8)  
--rev3 end  
--tip: you can search for these variables for the changes that I make.  
  
--rev5 start  
DECLARE @avg_cost decimal(20,8),@avg_dir decimal(20,8), @avg_oh decimal(20,8), @avg_utl decimal(20,8)  -- mls 9/18/00 23804  
DECLARE @use_update_proc int  
--rev5 end  
DECLARE @qc_acct varchar(32), @ref_code varchar(32), @cgs_ref_code varchar(32),    -- mls 1/24/03 SCR 29278  
@old_c_acct varchar(32), @old_r_acct varchar(32), @old_c_ref_cd varchar(32), @old_r_ref_cd varchar(32) -- mls 1/24/03 SCR 30555  
  
DECLARE @RCV_MISC_IN_COGP char(1)         -- mls 5/9/01 SCR 26911  
  
  
DECLARE @dir_var_acct varchar(32), @ovhd_var_acct varchar(32), @util_var_acct varchar(32)  
  
  
  
DECLARE @close_percent decimal(20,8), @retval int, @dqty decimal(20,8),  
  @iqty decimal(20,8),@iaccount varchar(10), @daccount varchar(10),   
  @tran_date datetime, @apply_date datetime, @dcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8),  
  @labor decimal(20,8), @utility decimal(20,8), @COGS int, @in_stock decimal(20,8), @temp_qty decimal(20,8),   
  @dummycost decimal(20,8), @ar_cgs_code varchar(32), @ar_cgs_direct_code  varchar(32), @ar_cgs_ovhd_code varchar(32),   
  @ar_cgs_util_code varchar(32),   
  @diff_qty decimal(20,8), @COGS_acct varchar(32), @COGS_matl decimal(20,8),   
  @directdelta decimal(20,8),  @ovhddelta decimal(20,8), @utildelta decimal(20,8),  
  @tempQty decimal(20,8), @count int, @seq1_qty decimal(20,8), @seq2_qty decimal(20,8),  
  @misc_ind int,           -- mls 2/4/00 SCR 22365  
  @o_avg_cost decimal(20,8), @use_ac char(1),        -- mls 5/4/00 SCR 22565  
  @o_direct_dolrs decimal(20,8), @o_ovhd_dolrs decimal(20,8),@o_util_dolrs decimal(20,8),  -- mls 5/4/00 SCR 22565  
  @o_in_stock decimal(20,8),  
--, @ins_avg_cost decimal(20,8),       -- mls 5/4/00 SCR 22565  
--  @ins_direct_dolrs decimal(20,8), @ins_ovhd_dolrs decimal(20,8),@ins_util_dolrs decimal(20,8),  -- mls 5/4/00 SCR 22565  
  @org_id varchar(30),  
  @skip_costing int, @inv_status char(1)        -- mls 5/8/00 SCR 22830  
  
DECLARE @inv_val decimal(20,8), @chg_val decimal(20,8),   -- mls 2/11/02 SCR 28338  
  @iinv int, @irecv int,  
  @varqty decimal(20,8), @varucost decimal(20,8),   -- mls 4/10/02 SCR 28686  
  @errmsg varchar(255),   
  @line_descr varchar(50), @line_descrv varchar(50)  
  
DECLARE @a_tran_id int, @a_tran_data varchar(255), @a_tran_qty decimal(20,8), @msg varchar(255),  
  @d_unitcost decimal(20,8), @d_direct decimal(20,8), @d_overhead decimal(20,8), @d_utility decimal(20,8), @d_labor decimal(20,8),  
  @n_unitcost decimal(20,8), @n_direct decimal(20,8), @n_overhead decimal(20,8), @n_utility decimal(20,8),  
  @vi_unitcost decimal(20,8), @vi_direct decimal(20,8), @vi_overhead decimal(20,8), @vi_utility decimal(20,8),  
  @ci_unitcost decimal(20,8), @ci_direct decimal(20,8), @ci_overhead decimal(20,8), @ci_utility decimal(20,8), @ci_qty decimal(20,8),  
  @ii_unitcost decimal(20,8), @ii_direct decimal(20,8), @ii_overhead decimal(20,8), @ii_utility decimal(20,8),   
  @vp_unitcost decimal(20,8), @vp_direct decimal(20,8), @vp_overhead decimal(20,8), @vp_utility decimal(20,8), -- mls 2/24/05 SCR 34297  
  @cp_unitcost decimal(20,8), @cp_direct decimal(20,8), @cp_overhead decimal(20,8), @cp_utility decimal(20,8),  -- mls 2/24/05 SCR 34297  
  @ip_unitcost decimal(20,8), @ip_direct decimal(20,8), @ip_overhead decimal(20,8), @ip_utility decimal(20,8),  -- mls 2/24/05 SCR 34297  
  @cgpp_unitcost decimal(20,8), @i_tran_id int, @p_tran_id int, @i_tran_qty decimal(20,8), @p_tran_qty decimal(20,8), -- mls 2/24/05 SCR 34297  
  @i_inv_qty decimal(20,8), @p_inv_qty decimal(20,8),  
  @cgpi_unitcost decimal(20,8), @totcost decimal(20,8), @vi_qty decimal(20,8),  
  @unitcost decimal(20,8), @cogs_qty decimal(20,8), @inv_qty decimal(20,8)  
  
declare @m_lb_tracking char(1), @m_status char(1),  
@lb_sum decimal(20,8), @uom_sum decimal(20,8), @part_cnt int, @lb_part varchar(30), @lb_loc varchar(10),  
  
@inv_lot_bin int,  
@rc int, @mtd_qty decimal(20,8)  
  
SELECT @company_id = company_id from glco (nolock)  
select @use_ac = isnull((select 'Y' from config (nolock) where flag = 'INV_USE_AVG_COST' and value_str like 'Y%'),'N')  
select @close_percent=isnull((select convert(decimal(20,8),value_str)/100.0 from config (nolock) where flag='RCV_CLOSE_PCT'),0.05)  
  
SELECT @count = 1, @qc_stock_account = NULL, @inv_stock_account = NULL, @tran_date = getdate()  
  
DECLARE recupd CURSOR LOCAL FOR  
SELECT i.receipt_no, i.po_no, i.part_no, i.sku_no, i.location, i.release_date,   
i.recv_date, i.part_type, i.unit_cost, i.quantity, i.vendor, i.unit_measure,   
i.prod_no, i.freight_cost, i.account_no, i.status, i.ext_cost, i.who_entered,   
i.vend_inv_no, i.conv_factor, i.pro_number, i.bl_no, i.lb_tracking, i.freight_flag,   
i.freight_vendor, i.freight_inv_no, i.freight_account, i.freight_unit, i.voucher_no,   
i.note, i.po_key, i.qc_flag, i.qc_no, i.rejected, i.over_flag, i.std_cost,   
i.std_direct_dolrs, i.std_ovhd_dolrs, i.std_util_dolrs, i.nat_curr, i.oper_factor,   
i.curr_factor, i.oper_cost, i.curr_cost, i.project1, i.project2, i.project3,   
isnull(i.tax_included,0) , i.po_line, isnull(i.amt_nonrecoverable_tax,0), isnull(i.organization_id,''),  
d.receipt_no, d.po_no, d.part_no, d.sku_no, d.location, d.release_date,   
d.recv_date, d.part_type, d.unit_cost, d.quantity, d.vendor, d.unit_measure,   
d.prod_no, d.freight_cost, d.account_no, d.status, d.ext_cost, d.who_entered,   
d.vend_inv_no, d.conv_factor, d.pro_number, d.bl_no, d.lb_tracking, d.freight_flag,   
d.freight_vendor, d.freight_inv_no, d.freight_account, d.freight_unit, d.voucher_no,   
d.note, d.po_key, d.qc_flag, d.qc_no, d.rejected, d.over_flag, d.std_cost,   
d.std_direct_dolrs, d.std_ovhd_dolrs, d.std_util_dolrs, d.nat_curr, d.oper_factor,   
d.curr_factor, d.oper_cost, d.curr_cost, d.project1, d.project2, d.project3,   
isnull(d.tax_included,0), d.po_line , isnull(d.amt_nonrecoverable_tax,0),  
m.lb_tracking, m.status  
from inserted i  
join deleted d on i.receipt_no = d.receipt_no  
left outer join inv_master m on m.part_no = i.part_no  
  
OPEN recupd  
FETCH NEXT FROM recupd INTO  
@i_receipt_no, @i_po_no, @i_part_no, @i_sku_no, @i_location, @i_release_date,   
@i_recv_date, @i_part_type, @i_unit_cost, @i_quantity, @i_vendor, @i_unit_measure,   
@i_prod_no, @i_freight_cost, @i_account_no, @i_status, @i_ext_cost, @i_who_entered,   
@i_vend_inv_no, @i_conv_factor, @i_pro_number, @i_bl_no, @i_lb_tracking, @i_freight_flag,   
@i_freight_vendor, @i_freight_inv_no, @i_freight_account, @i_freight_unit, @i_voucher_no,   
@i_note, @i_po_key, @i_qc_flag, @i_qc_no, @i_rejected, @i_over_flag, @i_std_cost,   
@i_std_direct_dolrs, @i_std_ovhd_dolrs, @i_std_util_dolrs, @i_nat_curr, @i_oper_factor,   
@i_curr_factor, @i_oper_cost, @i_curr_cost, @i_project1, @i_project2, @i_project3,   
@i_tax_included, @i_po_line, @i_amt_nonrecoverable_tax, @i_org_id,  
@d_receipt_no, @d_po_no, @d_part_no, @d_sku_no, @d_location, @d_release_date,   
@d_recv_date, @d_part_type, @d_unit_cost, @d_quantity, @d_vendor, @d_unit_measure,   
@d_prod_no, @d_freight_cost, @d_account_no, @d_status, @d_ext_cost, @d_who_entered,   
@d_vend_inv_no, @d_conv_factor, @d_pro_number, @d_bl_no, @d_lb_tracking, @d_freight_flag,   
@d_freight_vendor, @d_freight_inv_no, @d_freight_account, @d_freight_unit, @d_voucher_no,   
@d_note, @d_po_key, @d_qc_flag, @d_qc_no, @d_rejected, @d_over_flag, @d_std_cost,   
@d_std_direct_dolrs, @d_std_ovhd_dolrs, @d_std_util_dolrs, @d_nat_curr, @d_oper_factor,   
@d_curr_factor, @d_oper_cost, @d_curr_cost, @d_project1, @d_project2, @d_project3,   
@d_tax_included, @d_po_line , @d_amt_nonrecoverable_tax,  
@m_lb_tracking, @m_status  
  
While @@FETCH_STATUS = 0  
begin  
if @i_org_id = ''            -- I/O start  
begin  
  select @i_org_id = dbo.adm_get_locations_org_fn(@i_location)  
  select @i_account_no = dbo.adm_mask_acct_fn (@i_account_no, @i_org_id)  
  
  update receipts_all  
  set organization_id = @i_org_id , account_no = @i_account_no  
  where receipt_no = @i_receipt_no  
end  
else  
begin  
  set @org_id = dbo.adm_get_locations_org_fn(@i_location)  
  if @i_org_id != @org_id  
  begin  
    select @i_org_id = @org_id,  
      @i_account_no = dbo.adm_mask_acct_fn(@i_account_no,@org_id)  
    update receipts_all  
    set organization_id = @org_id,  
      account_no = @i_account_no  
    where receipt_no = @i_receipt_no      
  end  
end              -- I/O end  
  
  SELECT @reference_code = isnull(reference_code,''),  
    @tax_code = tax_code  
  FROM pur_list(nolock)  
  WHERE po_no = @i_po_no AND part_no = @i_part_no and  
    line = case when isnull(@i_po_line,0)=0 then line else @i_po_line end   -- mls 7/16/01 SCR 6603  
  
  if (@i_quantity != @d_quantity or @i_unit_cost != @d_unit_cost or  
    @i_tax_included != @d_tax_included or @i_amt_nonrecoverable_tax != @d_amt_nonrecoverable_tax)  
  begin  
    exec @rc = fs_calc_receipt_tax_wrap @i_po_no, @i_po_line, @tax_code, @i_quantity, @i_unit_cost,   
      1, @tax_included OUT, @nonrec_tax OUT  
  
    if @rc < 0  
    begin   
      rollback tran  
      exec adm_raiserror 832111, 'Error returned calculating receipt taxes.'  
      RETURN  
    end  
    if @i_tax_included != @tax_included or @i_amt_nonrecoverable_tax != @nonrec_tax  
    begin  
      update receipts_all  
      set tax_included = @tax_included,  
        amt_nonrecoverable_tax = @nonrec_tax  
      where receipt_no = @i_receipt_no  
  
      set @i_tax_included = @tax_included  
      set @i_amt_nonrecoverable_tax = @nonrec_tax  
    end  
  end  
  
  SELECT @COGS = 0,  
    @misc_ind = 0,           -- mls 2/4/00 SCR 22365  
    @skip_costing = 0  
  
  if @i_part_type != 'M'  
  begin  
    if @m_lb_tracking is null  
    begin  
      rollback tran  
      exec adm_raiserror 832111,'Part does not exists in inventory.'  
      RETURN  
    end  
  
    IF isnull(@m_status,'') = 'C'  
    BEGIN  
      rollback tran  
      exec adm_raiserror 81334 ,'You can not receive Custom Kit Items.'  
      RETURN  
    END  
  
    IF NOT exists(select 1 from inv_list where (part_no = @i_part_no) and (location = @i_location) )  
    BEGIN  
      rollback tran  
      exec adm_raiserror 50001, 'You Cannot Enter a Location That Is Not Valid For This Part!'  
      return  
    END  
  END  
  
  
  if isnull(@m_lb_tracking,'N') != @i_lb_tracking  
  begin  
    rollback tran  
    exec adm_raiserror 832112, 'Lot bin tracking flag mismatch with inventory.'  
    RETURN  
  end  
  
  if @inv_lot_bin is null  
    select @inv_lot_bin = isnull((select 1 from config (nolock) where flag='INV_LOT_BIN' and upper(value_str) = 'YES' ),0)  
  
  select @lb_sum = sum(qty * direction),  
    @uom_sum = sum(uom_qty * direction),  
    @part_cnt = count(distinct (part_no + '!@#' + location)) ,  
    @lb_part = min(part_no),  
    @lb_loc = min(location)  
  from lot_bin_recv (nolock)  
  where tran_no = @i_receipt_no  
  
  select @lb_sum = isnull(@lb_sum,0), @uom_sum = isnull(@uom_sum,0)  
  
  if isnull(@m_lb_tracking,'') = 'Y'   
  begin  
    if @inv_lot_bin = 1  
    begin  
      if @part_cnt = 0 and @i_quantity != 0  
      begin  
        rollback tran  
        exec adm_raiserror 832113,'No lot bin records found on lot_bin_recv for this receipt.'  
        RETURN  
      end  
      if @part_cnt > 1  
      begin  
        rollback tran  
        exec adm_raiserror 832113, 'More than one parts lot bin records found on lot_bin_recv for this receipt.'  
        RETURN  
      end  
      if @uom_sum != @i_quantity  
      begin  
        select @msg = 'Receipt uom qty of ([' + convert(varchar,@i_quantity) + ']) does not equal the lot and bin uom qty of ([' + convert(varchar,@uom_sum) + ']).'  
        rollback tran  
        exec adm_raiserror 832113, @msg  
        RETURN  
      end  
      if @lb_sum != (@i_quantity * @i_conv_factor)  
      begin  
        select @msg = 'Receipt qty of ([' + convert(varchar,(@i_quantity * @i_conv_factor)) + ']) does not equal the lot and bin qty of ([' + convert(varchar,@lb_sum) + ']).'  
        rollback tran  
        exec adm_raiserror 832113, @msg  
        RETURN  
      end  
      if (@lb_part != @i_part_no or @lb_loc != @i_location) and @part_cnt > 0  
      begin  
        select @msg = 'Part/Location on lot_bin_recv is not the same as on receipts table.'  
        rollback tran  
        exec adm_raiserror 832115, @msg  
        RETURN  
      end  
    end  
    else  
    begin  
      if @part_cnt > 0  
      begin  
        select @msg = 'You cannot have lot bin records on an inbound transaction when you are not lb tracking.'  
        rollback tran  
        exec adm_raiserror 832114, @msg  
        RETURN  
      end  
    end  
  end  
  else  
  begin  
    if @part_cnt > 0  
    begin  
      rollback tran  
      exec adm_raiserror 832114, 'Lot bin records found on lot_bin_recv for this not lot/bin tracked part.'  
      RETURN  
    end  
  end  
  
  SELECT  
    @iqty = (@i_quantity * @i_conv_factor),                         
    @icostf = CASE @i_quantity     -- mls 2/28/02 SCR 28448  
      WHEN 0 THEN (@i_unit_cost / @i_conv_factor)   
      ELSE (@i_unit_cost * @i_quantity)   
      END,  
    @iopercostf  = CASE @i_quantity  
      WHEN 0 THEN (@i_oper_cost / @i_conv_factor)  
      ELSE (@i_oper_cost * @i_quantity)  
      END,  
    @dqty  = (@d_quantity * @d_conv_factor),  
    @dcostf = CASE @d_quantity  
      WHEN 0 THEN (@d_unit_cost / @d_conv_factor)  
      ELSE (@d_unit_cost * @d_quantity)       -- mls 2/28/02 SCR 28448  
      END,  
    @dopercostf  = CASE @d_quantity  
      WHEN 0 THEN (@d_oper_cost / @d_conv_factor)  
      ELSE (@d_oper_cost * @d_quantity)  
      END  
  
  if @d_tax_included = 0 and @i_tax_included = 0  
  begin  
    select   
    @dcostf2 = 0,     -- mls 5/2/01 SCR 26874  
    @dopercostf2 = 0,     -- mls 5/2/01 SCR 26874  
    @icost = (@i_unit_cost / @i_conv_factor),  
    @iopercost  = (@i_oper_cost / @i_conv_factor),  
    @dcost = (@d_unit_cost / @d_conv_factor),  
    @dopercost = (@d_oper_cost / @d_conv_factor),  
    @i_uomcost = @i_unit_cost,  
    @d_uomcost = @d_unit_cost  
  end  
  else  
  begin  
    select   
    @dcostf2 = (case when @d_curr_factor >= 0 then @d_tax_included * @d_curr_factor  -- mls 2/28/02 SCR 28448  
      else @d_tax_included / abs(@d_curr_factor) end),     -- mls 5/2/01 SCR 26874  
    @dopercostf2 = (case when @d_oper_factor >= 0 then @d_tax_included * @d_oper_factor -- mls 2/28/02 SCR 28448  
      else @d_tax_included / abs(@d_oper_factor) end),     -- mls 5/2/01 SCR 26874  
    @icost = CASE @i_quantity  
      WHEN 0 THEN @icostf -           CASE @d_quantity when 0 then 0 else ((  
        (case when @d_curr_factor >= 0 then @d_tax_included * @d_curr_factor else @d_tax_included / abs(@d_curr_factor) end) -- mls 5/2/01 SCR 26874  
        / @d_quantity)/ @d_conv_factor) end -- mls 2/2/01 SCR 24078  
      ELSE ((((@icostf) -   
        (case when @i_curr_factor >= 0 then @i_tax_included * @i_curr_factor else @i_tax_included / abs(@i_curr_factor) end) -- mls 10/28/02 SCR 28835  
                    -- mls 5/2/01 SCR 26874  
        ) / @i_quantity) / @i_conv_factor)  
      END,  
    @iopercost  = CASE @i_quantity  
      WHEN 0 THEN @iopercostf -  
        CASE @d_quantity when 0 then 0 else ((  
        (case when @d_oper_factor >= 0 then @d_tax_included * @d_oper_factor else @d_tax_included / abs(@d_oper_factor) end) -- mls 5/2/01 SCR 26874  
        / @d_quantity)/ @d_conv_factor) end -- mls 2/28/02 SCR 28448  
      ELSE ((((@iopercostf) -   
        (case when @i_oper_factor >= 0 then @i_tax_included * @i_oper_factor else @i_tax_included / abs(@i_oper_factor) end) -- mls 10/28/02 SCR 28835  
                    -- mls 5/2/01 SCR 26874  
        ) / @i_quantity) / @i_conv_factor)  
      END  
  
    select        -- mls 2/28/02 SCR 28448  
      @dcost = case @d_quantity  
        when 0 then @dcostf  
        else (((@dcostf - @dcostf2) / @d_quantity) / @d_conv_factor) end,  
      @dopercost = case @d_quantity  
        when 0 then @dopercostf   
        else (((@dopercostf - @dopercostf2) / @d_quantity) / @d_conv_factor) end  
  
    select @i_uomcost = @icost * @i_conv_factor,  
      @d_uomcost = @dcost * @d_conv_factor  
  end  
  
  IF @i_qc_flag != @d_qc_flag and (@iqty != @dqty or @icost != @dcost)      -- mls 2/3/03 SCR 29278 start  
  BEGIN  
    rollback tran  
    exec adm_raiserror 50001, 'You Cannot release receipt from qc hold and change price or qty at the same time'  
    return  
  END             -- mls 2/3/03 SCR 29278 end  
  
  if @RCV_MISC_IN_COGP is NULL  
  begin  
    select @RCV_MISC_IN_COGP = isnull((select 'Y' from config (nolock)      -- mls 5/9/01 SCR 26911  
      where flag = 'RCV_MISC_IN_COGP' and Upper(substring(value_str,1,1)) = 'Y'),'N')        
  end  
  if @qc_stock_account is NULL and @i_part_type != 'M' and (@d_qc_flag = 'Y' or @i_qc_flag = 'Y')  
  begin  
    select @qc_stock_account = isnull((select value_str from config (nolock) where flag='QC_STOCK_ACCOUNT'),'QC')  
  end  
  if @inv_stock_account is NULL and @i_part_type != 'M' and (@d_qc_flag != 'Y' or @i_qc_flag != 'Y')  
  begin  
    select @inv_stock_account = isnull((select value_str from config (nolock) where flag='INV_STOCK_ACCOUNT'),'STOCK')  
  end  
   
  IF @i_qc_flag = 'Y' and ((@i_qc_no = 0 and @d_qc_no != 0) or @d_qc_flag != 'Y')    -- mls 1/31/03 SCR 30555  
  BEGIN  
    rollback tran  
    exec adm_raiserror 91333 ,'You Cannot Change An Item To QC Check AFTER Receiving Is Entered (Use Inventory Adjustments) !'  
    return  
  END  
  if @d_status >= 'T' and @d_qc_flag != 'Y'  
  begin  
    rollback tran  
    exec adm_raiserror 91331 ,'You Cannot Update A Vouchered Receipt!'  
    return  
  end  
  if @i_part_no != @d_part_no or @i_location != @d_location  
  begin  
    rollback tran  
    exec adm_raiserror 50002, 'You Cannot Change the part number or location on a receipt!'  
    return  
  end  
  if @i_part_type != @d_part_type  
  begin  
    rollback tran  
    exec adm_raiserror 50003, 'You Cannot Change the part type on a receipt!'  
    return  
  end  
  
  if @i_part_type = 'M' and @i_qc_flag = 'Y'     -- mls 3/28/02 SCR 28575 start  
  begin  
    rollback tran  
    exec adm_raiserror 81335, 'You can not QC miscellaneous parts.'  
    RETURN  
  end          -- mls 3/28/02 SCR 28575 end  
  
  if @i_ext_cost != round((@i_unit_cost * @i_quantity),8)      -- mls 1/30/01 SCR 21701 start  
  begin  
    update receipts_all  
    set ext_cost = (@i_unit_cost * @i_quantity)  
    where receipt_no = @i_receipt_no  
  end            -- mls 1/30/01 SCR 21701 end  
  
  IF @i_part_type != 'M'  
  BEGIN  
  
    --Get stock amount in inventory  
    select   
      @typ = m.inv_cost_method,  
      @inv_status = m.status,         -- mls 5/8/00 SCR 22830  
      @o_avg_cost = l.avg_cost,         -- mls 5/3/00 SCR 22565 start  
      @o_direct_dolrs = l.avg_direct_dolrs,  
      @o_ovhd_dolrs = l.avg_ovhd_dolrs,  
      @o_util_dolrs = l.avg_util_dolrs,        -- mls 5/3/00 SCR 22565 end  
      @stdcost = l.std_cost,   
      @stddirect = l.std_direct_dolrs,   
      @stdovhd = l.std_ovhd_dolrs,   
      @stdutil = l.std_util_dolrs,  
      @posting_code = l.acct_code  
    from inv_list l (nolock)  
    join inv_master m (nolock) on m.part_no = l.part_no  
    where l.part_no =  @i_part_no and l.location = @i_location  
  
    select @daccount = case when @d_qc_flag = 'Y' then @qc_stock_account else @inv_stock_account end,  
      @iaccount = case when @i_qc_flag = 'Y' then @qc_stock_account else @inv_stock_account end,  
      @misc_ind = 0, @skip_costing = 0  
  
    if @typ in ('1','2','3','4','5','6','7','8','9') select @typ = 'W'    -- mls 5/3/00 SCR 22565   
    --Default to Average  
    IF @typ NOT IN ('A','F','L','W','S','E') select @typ='A'  
  
    if (isnull(@inv_status, 'V') = 'V'  and @RCV_MISC_IN_COGP = 'N')     -- mls 5/9/01 SCR 26911  
      -- or @i_qc_flag = 'Y'         -- mls 1/31/03 SCR 30555  
      select @skip_costing = 1   -- mls 5/8/00 SCR 22830  
  END  
  ELSE  
  BEGIN  
    SELECT @typ = 'A', @in_stock = 0, @misc_ind = 1  
  
    if @RCV_MISC_IN_COGP = 'N' select @skip_costing = 1     -- mls 5/9/01 SCR 26911  
  END  
  
--Subtract mtd and ytd in inv_recv with deleted quantity.  
SELECT @inchg = 0, @prchg = 0, @invdelta = @iqty  - @dqty  
IF (@d_qc_flag = 'Y' and @i_qc_flag != 'Y') select @invdelta = @iqty    -- mls 8/8/00 SCR 23859   
IF @invdelta = 0  SELECT @invdelta = @iqty,  @inchg = 1  
  
SELECT @prdelta  = @icost - @dcost, @operprdelta  = @iopercost - @dopercost,  
  @nrtdelta = isnull(@i_amt_nonrecoverable_tax,0) - isnull(@d_amt_nonrecoverable_tax,0)  
  
IF @prdelta = 0 and @nrtdelta = 0   
  select @prdelta = @icost, @prchg   = 1, @operprdelta = @iopercost  -- mls 10/20/00 SCR 24686  
else  
  if @prdelta = 0  select @prdelta = @icost, @operprdelta = @iopercost  
  
IF @inchg = 0 and @prchg = 0 and   
  (@i_unit_cost != @d_unit_cost)    -- mls 2/24/05 SCR 34297  
BEGIN  
  rollback tran  
  exec adm_raiserror 91334, 'You Cannot Update Cost/taxes and Quantity in Same Transaction! (Split The Transactions)!'  
  return  
END  
  
  select @apply_date = NULL        -- mls 12/2/02 SCR 30381  
           -- mls 3/28/02 SCR 28076 start  
  if @i_qc_flag != @d_qc_flag and @d_qc_flag = 'Y'  
  begin  
    select @apply_date = isnull((select max(date_complete) from qc_results  -- mls 12/2/02 SCR 30381  
      where tran_code = 'R' and tran_no = @i_receipt_no),NULL)  
  end           -- mls 3/28/02 SCR 28076 end  
  
  -- Get the apply date that was entered : Begin SCR 21159  
  if @apply_date is null  
  begin  
    SELECT @apply_date = IsNull(( select max(chg.apply_date)  
    FROM adm_pomchchg_all chg (nolock), adm_pomchcdt det (nolock)   
    WHERE det.receipt_no = @i_receipt_no AND det.match_ctrl_int = chg.match_ctrl_int and   
      chg.match_posted_flag != -999), getdate())     -- mls 3/17/04 SCR 32540  
           -- mls 12/2/02 SCR 30381  
           -- mls 3/28/02 SCR 28076  
  end  
  
  select @inv_qty = 0, @i_inv_qty = 0, @p_inv_qty = 0  
  
  select @layer_qty = 0          -- mls 5/9/01 SCR 26911  
  
  select @ii_unitcost = 0, @ii_direct = 0, @ii_overhead = 0, @ii_utility = 0  -- mls 2/24/05 SCR 34297  
  select @vi_unitcost = 0, @vi_direct = 0, @vi_overhead = 0, @vi_utility = 0  -- mls 2/24/05 SCR 34297  
  select @ip_unitcost = 0, @ip_direct = 0, @ip_overhead = 0, @ip_utility = 0  -- mls 2/24/05 SCR 34297  
  select @vp_unitcost = 0, @vp_direct = 0, @vp_overhead = 0, @vp_utility = 0  -- mls 2/24/05 SCR 34297  
  select @cp_unitcost = 0, @cp_direct = 0, @cp_overhead = 0, @cp_utility = 0  -- mls 5/23/06 SCR 34297  
  select @cgpi_unitcost = 0, @cgpp_unitcost = 0      -- mls 2/24/05 SCR 34297  
  select @i_tran_qty = 0, @p_tran_qty = 0  
  
  -- mls 2/24/05 - SCR 34297 - moved code here so that we can create gl transactions right after  
  --                           call to adm_inv_tran  
  
  --Get reference from po line for GL inventory transaction  
  SELECT @reference_code = isnull(reference_code,'')  
  FROM pur_list(nolock)  
  WHERE po_no = @i_po_no AND part_no = @i_part_no and  
    line = case when isnull(@i_po_line,0)=0 then line else @i_po_line end   -- mls 7/16/01 SCR 6603  
  
  if @misc_ind = 1          -- mls 5/9/01 SCR 26911 start  
  BEGIN  
   SELECT  @posting_code = apacct_code  
   FROM locations_all (nolock)   
   WHERE location = @i_location  
  end            -- mls 5/9/01 SCR 26911 end  
  
    
  -- Get Accounts  
  SELECT @pur_acct = ap_cgp_code,  
    @var_acct      = cost_var_code,  
    @dir_var_acct  = cost_var_direct_code,  
    @ovhd_var_acct = cost_var_ovhd_code,  
    @util_var_acct = cost_var_util_code,  
    @direct_acct   = inv_direct_acct_code,  
    @ovhd_acct     = inv_ovhd_acct_code,  
    @util_acct     = inv_util_acct_code,  
    @recv_acct     = rec_var_code,  
    @ar_cgs_code   = ar_cgs_code,        --SCR 21358  
    @ar_cgs_direct_code  = ar_cgs_direct_code ,  
    @ar_cgs_ovhd_code = ar_cgs_ovhd_code,  
    @ar_cgs_util_code = ar_cgs_util_code,  
    @qc_acct = qc_acct_code      -- mls 1/24/03 SCR 29278  
  FROM in_account(nolock)  
  WHERE acct_code = @posting_code  
  
  select @cp_unitcost = 0, @cp_direct = 0, @cp_overhead = 0, @cp_utility = 0  
  select @ci_unitcost = 0, @ci_direct = 0, @ci_overhead = 0, @ci_utility = 0  
  
  if @inchg = 0 -- change in quantity  
  begin  
    IF (@d_qc_flag = 'Y' and @i_qc_flag != 'Y')  
      select @a_tran_qty = @i_quantity  
    else  
      select @a_tran_qty = @i_quantity - @d_quantity  
    select @cgpi_unitcost = (@a_tran_qty ) * (@i_uomcost)   
  
    IF (@d_qc_flag = 'Y' and @i_qc_flag != 'Y')        -- mls 5/28/09  
      select @cgpi_unitcost = @cgpi_unitcost + isnull(@i_amt_nonrecoverable_tax,0)  
  
    select           
      @a_tran_data = 'U' +  -- update  
        isnull(@i_qc_flag,'N') + @i_part_type +  
        isnull(@d_qc_flag,'N') + 'I' +  
        convert(varchar(30),@invdelta) + replicate(' ',30 - datalength(convert(varchar(30),@invdelta))) +  
        convert(char(1), @skip_costing) +  
        convert(varchar(30),@iqty) + replicate(' ',30 - datalength(convert(varchar(30),@iqty))) +  
        convert(varchar(30),@icost) + replicate(' ',30 - datalength(convert(varchar(30),@icost))) +  
        convert(varchar(30),@i_amt_nonrecoverable_tax) + replicate(' ',30 - datalength(convert(varchar(30),@i_amt_nonrecoverable_tax))),  
      @unitcost = @cgpi_unitcost , @direct = 0, @overhead = 0, @utility = 0, @labor = 0   -- mls 5/28/09  
  
    exec @retval =  adm_inv_tran  
      'R', @i_receipt_no, 0, 0, @i_part_no, @i_location, @a_tran_qty, @apply_date, @i_unit_measure,   
      @i_conv_factor, @i_status, @a_tran_data OUT, DEFAULT,   
      @a_tran_id OUT, @d_unitcost OUT, @d_direct OUT, @d_overhead OUT, @d_utility OUT, @d_labor OUT,  
      @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT  
    if @retval <> 1  
    begin  
      rollback tran  
      select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'  
      exec adm_raiserror 83202, @msg  
      RETURN  
    end  
  
    select @a_tran_qty = @invdelta  
    select @i_tran_id = @a_tran_id, @i_tran_qty = @a_tran_qty, @i_inv_qty = @a_tran_qty  
    select @cogs_qty = convert(decimal(20,8),substring(@a_tran_data,1,30)),  
      @n_unitcost = convert(decimal(20,8),substring(@a_tran_data,31,30)),  
      @n_direct = convert(decimal(20,8),substring(@a_tran_data,61,30)),  
      @n_overhead = convert(decimal(20,8),substring(@a_tran_data,91,30)),  
      @n_utility = convert(decimal(20,8),substring(@a_tran_data,121,30)),  
      @inv_qty = @a_tran_qty  
  
    select @ii_unitcost =  @unitcost, @ii_direct =  @direct, @ii_overhead =  @overhead,  
    @ii_utility =  @utility  
    select @cgpi_unitcost = -@cgpi_unitcost  
    select @ci_unitcost = 0, @ci_direct = 0, @ci_overhead = 0, @ci_utility = 0  
    if @COGS != 0 and @cogs_qty != 0  
      select @ci_unitcost = -@cgpi_unitcost - @unitcost, --(@cogs_qty * @n_unitcost),  
        @ci_direct = - @direct, --(@cogs_qty * @n_direct),  
        @ci_overhead = - @overhead, --(@cogs_qty * @n_overhead),  
        @ci_utility = - @utility, --(@cogs_qty * @n_utility),   
        @ci_qty = @cogs_qty  
  
    if @i_part_type = 'M'    -- mls 7/7/04 SCR 33133  
    begin  
      select @ii_unitcost = -@cgpi_unitcost, @ii_direct = 0, @ii_overhead = 0, @ii_utility = 0  
    end  
  
    select @vi_unitcost = - @ii_unitcost - @cgpi_unitcost - @ci_unitcost,  
      @vi_direct = - @ii_direct - @ci_direct,  
      @vi_overhead = - @ii_overhead - @ci_overhead,  
      @vi_utility = - @ii_utility - @ci_utility  
  end  
  
  -- mls 2/24/05 SCR 34297 - moved this if statement before price change in case tax included change  
  --                         causes us to do the price change section of code  
  if @i_part_type != 'M'         
  begin  
    if @i_qc_flag != 'Y'  
    begin  
      update inv_recv  
      set last_cost = cost,  
        cost = @i_unit_cost / @i_conv_factor,       -- mls 2/7/03 SCR 30650  
        last_recv_date = @i_recv_date,  
        recv_mtd = (recv_mtd + case when @inchg = 0 then @invdelta else 0 end ),  
        recv_ytd = (recv_ytd + case when @inchg = 0 then @invdelta else 0 end ),  
        hold_rcv = hold_rcv - case when @d_qc_flag = 'Y' then (@d_quantity * @d_conv_factor) else 0 end -- mls 1/15/04 SCR 32334  
      where part_no=@i_part_no and location=@i_location  
  
      -- mls 1/18/05 SCR 34050  
      select @mtd_qty =  case when @inchg = 0 then @invdelta else 0 end   
      exec @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'R', @mtd_qty  
      if @rc < 1  
      begin  
        select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'  
        rollback tran  
        exec adm_raiserror 9910141, @msg  
        return  
      end  
    end  
    else  
    begin  
      update inv_recv  
      set hold_rcv = hold_rcv + case when @inchg = 0 then @invdelta else 0 end  
      where part_no = @i_part_no and location = @i_location  
    end  
  end  
  
  if @prchg = 0 -- change in cost  
  begin  
    select @cp_unitcost = 0, @cp_direct = 0, @cp_overhead = 0, @cp_utility = 0  
    select @a_tran_qty = @i_quantity   
    select @cgpp_unitcost = -((@a_tran_qty * @i_uomcost) -  
 ((@d_quantity * @d_uomcost) - (@cgpi_unitcost))) - (@i_amt_nonrecoverable_tax - @d_amt_nonrecoverable_tax)    -- mls 2/24/05 SCR 34297  
  
    if @COGS = 2 -- (- to +)        -- mls 2/24/05 SCR 34297  
    begin  
      select @cp_unitcost = @cgpp_unitcost  
      select @unitcost = @ip_unitcost + @cgpp_unitcost  + @cp_unitcost,  
        @direct = 0, @overhead = 0, @utility = 0  
    end  
    else  
    begin  
      select           
        @a_tran_data = 'U' +  -- update  
          isnull(@i_qc_flag,'N') + @i_part_type +  
          isnull(@d_qc_flag,'N') + 'C' +  
          convert(varchar(30),0) + replicate(' ',30 - datalength(convert(varchar(30),0))) + -- mls 2/24/05 SCR 34297  
          convert(char(1), @skip_costing) +  
          convert(varchar(30),@iqty) + replicate(' ',30 - datalength(convert(varchar(30),@iqty))) +  
          convert(varchar(30),@icost) + replicate(' ',30 - datalength(convert(varchar(30),@icost))) +  
          convert(varchar(30),@i_amt_nonrecoverable_tax) + replicate(' ',30 - datalength(convert(varchar(30),@i_amt_nonrecoverable_tax))),  
        @unitcost = -@cgpp_unitcost, @direct = 0, @overhead = 0, @utility = 0, @labor = 0, -- mls 2/24/05 SCR 34297  
        @a_tran_id = 0  
  
      exec @retval = adm_inv_tran   
        'R', @i_receipt_no, 0, 0, @i_part_no, @i_location, @a_tran_qty, @apply_date, @i_unit_measure,   
        @i_conv_factor, @i_status, @a_tran_data OUT, DEFAULT,   
        @a_tran_id OUT, @d_unitcost OUT, @d_direct OUT, @d_overhead OUT, @d_utility OUT, @d_labor OUT,  
        @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT  
      if @retval <> 1  
      begin  
        rollback tran  
        select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'  
        exec adm_raiserror 83202, @msg  
        RETURN  
      end  
  
      select @cogs_qty = convert(decimal(20,8),substring(@a_tran_data,1,30)),  
        @n_unitcost = convert(decimal(20,8),substring(@a_tran_data,31,30)),  
        @n_direct = convert(decimal(20,8),substring(@a_tran_data,61,30)),  
        @n_overhead = convert(decimal(20,8),substring(@a_tran_data,91,30)),  
        @n_utility = convert(decimal(20,8),substring(@a_tran_data,121,30))  
  
      select @cgpp_unitcost = -((@a_tran_qty * @i_uomcost) -      -- mls 2/24/05 SCR 34297  
        ((@d_quantity * @d_uomcost) - (@cgpi_unitcost)))- (@i_amt_nonrecoverable_tax - @d_amt_nonrecoverable_tax)  
      select @a_tran_qty = @a_tran_qty * @i_conv_factor  
      select @inv_qty = (@a_tran_qty ) - @cogs_qty  
      select @p_tran_id = @a_tran_id, @p_tran_qty = @a_tran_qty, @p_inv_qty = @inv_qty  
  
      select @ip_unitcost = @unitcost, @ip_direct = @direct,      -- mls 2/24/05 SCR 34297  
        @ip_overhead = @overhead, @ip_utility =  @utility  
    end  
    select @vp_unitcost = -@cgpp_unitcost - @unitcost,       -- mls 2/24/05 SCR 34297  
      @vp_direct = @direct, @vp_overhead = @overhead,   
      @vp_utility = @utility  
    select @cgpp_unitcost = @cgpp_unitcost       -- mls 2/24/05 SCR 34297  
  
  end  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
    
    
  if @d_quantity != @i_quantity  
  begin  
    --Subtract received in inv_recv with deleted quantity.  
    if @d_po_no = @i_po_no and @d_release_date = @i_release_date and @d_po_line = @i_po_line  
    begin  
      update releases   
      set received = received - @d_quantity + @i_quantity,  
        status = case when @i_quantity < @d_quantity then 'O'   
          when ((received - @d_quantity + @i_quantity) > 0 and   
            (((quantity - (received - @d_quantity + @i_quantity))/1.0000) / quantity) <= @close_percent)   
          then 'C' else status end  
      where (po_no = @d_po_no) and (part_no = @d_part_no) and (release_date = @d_release_date)   
        and (location = @d_location)   
 and (case when isnull(po_line,0)=0 then @d_po_line else po_line end = @d_po_line)   -- mls 5/9/01 #39  
    end  
    else  
    begin  
      if @d_quantity != 0  
      begin  
        update releases   
          set received = received - @d_quantity,  
            status = case when @d_quantity > 0 then 'O' else status end  
        where (po_no = @d_po_no) and (part_no = @d_part_no) and (release_date = @d_release_date)   
          and (location = @d_location)  
     and (case when isnull(po_line,0)=0 then @d_po_line else po_line end = @d_po_line)   -- mls 5/9/01 #39  
      end  
  
      update releases  
      set received = received + @i_quantity,  
        status = case when @i_quantity < @d_quantity then 'O'   
        when ((received + @i_quantity) > 0 and   
          (((quantity - (received + @i_quantity))/1.0000) / quantity) <= @close_percent)   
          then 'C' else status end  
      where (po_no = @i_po_no) and (part_no = @i_part_no) and (release_date = @i_release_date)   
        and (location = @i_location)  
 and (case when isnull(po_line,0)=0 then @i_po_line else po_line end = @i_po_line)   -- mls 5/9/01 #39  
    end  
  
    update releases            -- mls 12/11/02 SCR 29295  
    set status='C'  
    where (po_no=@i_po_no) and (part_no = @i_part_no) and (release_date = @i_release_date)   
      and case when isnull(po_line,0)=0 then @i_po_line else po_line end = @i_po_line     
      and quantity > 0 and ((((quantity - received) / 1.0000) / quantity) <= @close_percent)   
      and status != 'C'  
  end  
  
  if @i_qc_flag = 'Y'  
  BEGIN  
    update qc_results   
    set qc_qty = @iqty          -- mls 2/22/01 SCR 26024   
    where qc_no = @i_qc_no and status != 'S'   
  END  
  
  SELECT @direct = 0, @overhead = 0, @utility = 0, @opercost = 0, @operdirect = 0, @operoverhead = 0, @operutility = 0  
  
--  select @ins_avg_cost = 0, @ins_direct_dolrs = 0, @ins_ovhd_dolrs = 0, @ins_util_dolrs = 0  -- mls 5/8/00 SCR 22585  
  
  if @skip_costing = 1   GOTO SKIP_GL_TRANS       -- mls 5/8/00 SCR 22830  
  
  
  select @old_r_acct = '', @old_r_ref_cd = '', @old_c_acct = '', @old_c_ref_cd = ''  -- mls 1/24/03 SCR 30555  
  
  if (@prchg = 0 or @inchg = 0)   
  BEGIN  
    select @ins_account = case when @d_qc_flag = 'Y' and @i_qc_flag != 'Y' then @qc_acct else @pur_acct end, -- mls 2/03/03 SCR 29278  
      @line_descr = case when @d_qc_flag = 'Y' and @i_qc_flag != 'Y' then 'QC_acct' else 'ap_cgp_acct' end, -- mls 2/03/03 SCR 29278  
      @ref_code = ''        -- mls 1/24/03 SCR 30555 start  
  
  
    if @cgpi_unitcost <> 0  
    begin  
      select @cost = @cgpi_unitcost / @i_tran_qty  
    
      if exists (select 1 from glrefact (nolock) where @ins_account like account_mask and reference_flag > 1)  
      begin  
        if exists (select 1 from glratyp t (nolock), glref r (nolock)  
          where t.reference_type = r.reference_type and @ins_account like t.account_mask and  
                r.status_flag = 0 and r.reference_code  = @reference_code)  
          select @ref_code = @reference_code  
      end           -- mls 1/21/03 SCR 30555 end  
  
      --Insert into Purchase Expense Acct  
      exec @retval = adm_gl_insert  @i_part_no, @i_location, 'R', @i_receipt_no, 0,0,  
        @apply_date, @i_tran_qty, @cost, @ins_account, @i_nat_curr, @i_curr_factor,   -- mls 2/03/03 SCR 29278 -- mls 4/11/02 SCR 28686  
        @i_oper_factor, @company_id, DEFAULT, @ref_code, @i_tran_id, @line_descr,   -- mls 4/12/02 SCR 28686  
        @cgpi_unitcost  
  
      IF @retval <= 0  
      BEGIN  
        rollback tran  
  select @msg = 'Error Inserting ' + @line_descr + ' GL Costing Record!'  
        exec adm_raiserror 91310, @msg  
        return  
      END  
    end  
    if @cgpp_unitcost <> 0  
    begin  
      select @cost = @cgpp_unitcost / @p_tran_qty  
    
      if @cgpi_unitcost = 0  
      begin  
        if exists (select 1 from glrefact (nolock) where @ins_account like account_mask and reference_flag > 1)  
        begin  
          if exists (select 1 from glratyp t (nolock), glref r (nolock)  
            where t.reference_type = r.reference_type and @ins_account like t.account_mask and  
                  r.status_flag = 0 and r.reference_code  = @reference_code)  
            select @ref_code = @reference_code  
        end           -- mls 1/21/03 SCR 30555 end  
      end  
  
      --Insert into Purchase Expense Acct  
      exec @retval = adm_gl_insert  @i_part_no, @i_location, 'R', @i_receipt_no, 0,0,  
        @apply_date, @p_tran_qty, @cost, @ins_account, @i_nat_curr, @i_curr_factor,   -- mls 2/03/03 SCR 29278 -- mls 4/11/02 SCR 28686  
        @i_oper_factor, @company_id, DEFAULT, @ref_code, @p_tran_id, @line_descr,   -- mls 4/12/02 SCR 28686  
        @cgpp_unitcost  
  
      IF @retval <= 0  
      BEGIN  
        rollback tran  
  select @msg = 'Error Inserting ' + @line_descr + ' GL Costing Record!'  
        exec adm_raiserror 91310, @msg  
        return  
      END  
    end  
  
    SELECT @iloop = 1        
    WHILE @iloop <= 8  
    BEGIN   
      Select @totcost =   
        CASE @iloop  
          WHEN 1 THEN @ii_unitcost     
          WHEN 2 THEN @ii_direct   
          WHEN 3 THEN @ii_overhead     
          WHEN 4 THEN @ii_utility     
          WHEN 5 THEN @ip_unitcost     
          WHEN 6 THEN @ip_direct   
          WHEN 7 THEN @ip_overhead     
          WHEN 8 THEN @ip_utility     
        END  
      
      Select @ins_account =   
        CASE @iloop  
          WHEN 1 THEN @i_account_no  
          WHEN 2 THEN @direct_acct  
          WHEN 3 THEN @ovhd_acct  
          WHEN 4 THEN @util_acct  
          WHEN 5 THEN @i_account_no  
          WHEN 6 THEN @direct_acct  
          WHEN 7 THEN @ovhd_acct  
          WHEN 8 THEN @util_acct  
        END,  
        @line_descr = case @iloop  
          WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct'  
          WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct'  
          WHEN 5 THEN 'inv_acct' WHEN 6 THEN 'inv_direct_acct'  
          WHEN 7 THEN 'inv_ovhd_acct' WHEN 8 THEN 'inv_util_acct'  
        END  
  
      select @inv_qty = case when @iloop < 5 then @i_inv_qty else @p_inv_qty end  
      select @a_tran_id = case when @iloop < 5 then @i_tran_id else @p_tran_id end  
  
   set @msg = @line_descr  
      if @i_qc_flag = 'Y'  
      begin  
        select @ins_account = @qc_acct,  
          @line_descr = replace(@line_descr,'inv','qc')  
        set @msg = @line_descr  
      end  
               
      select @line_descr = @line_descr + case when @iloop < 5 then ' (qty chg)' else ' (pr chg)' end  
      if @inv_qty != 0 select @cost = @totcost / @inv_qty  
      IF @totcost <> 0 or (@iloop in (1,5) and @a_tran_id != 0)  
      BEGIN  
        select @ref_code = @reference_code       -- mls 1/24/03 SCR 30555 start  
        if @iloop != 1  
        begin  
          select @ref_code = ''  
          if @old_r_acct = @ins_account           
            select @ref_code = @old_r_ref_cd  
          else  
          begin  
            if exists (select 1 from glrefact (nolock) where @ins_account like account_mask and reference_flag > 1)  
            begin  
              if exists (select 1 from glratyp t (nolock), glref r (nolock)  
                where t.reference_type = r.reference_type and @ins_account like t.account_mask and  
                r.status_flag = 0 and r.reference_code  = @reference_code)  
                select @ref_code = @reference_code  
            end  
            select @old_r_acct = @ins_account, @old_r_ref_cd = @ref_code  
          end           -- mls 1/21/03 SCR 30555 end  
        end  
                       
        exec @retval = adm_gl_insert  @i_part_no, @i_location, 'R', @i_receipt_no,   
          0, 0, @apply_date, @inv_qty, @cost,      -- mls 6/2/00 SCR 22994   
          @ins_account, @i_nat_curr, @i_curr_factor, @i_oper_factor, @company_id, -- mls 2/9/01 SCR 24318  
          DEFAULT, @ref_code, @a_tran_id, @line_descr, @totcost, @iloop    
  
        IF @retval <= 0  
        BEGIN  
          rollback tran  
		  select @msg = 'Error Inserting [' + @msg + '] GL Costing Record!'  
          exec adm_raiserror 91311, @msg  
          return  
        END  
      END  
  
      SELECT @iloop = @iloop + 1  
    END --While  
    SELECT @iloop = 1  
    WHILE @iloop <= 8  
    BEGIN   
      Select @varmatl =   
        CASE @iloop  
          WHEN 1 THEN @vi_unitcost  
          WHEN 2 THEN @vi_direct  
          WHEN 3 THEN @vi_overhead  
          WHEN 4 THEN @vi_utility   
          WHEN 5 THEN @vp_unitcost     
          WHEN 6 THEN @vp_direct   
          WHEN 7 THEN @vp_overhead     
          WHEN 8 THEN @vp_utility     
        END  
                  
      Select @ins_account =   
        CASE @iloop  
          WHEN 1 THEN @var_acct  
          WHEN 2 THEN @dir_var_acct  
          WHEN 3 THEN @ovhd_var_acct  
          WHEN 4 THEN @util_var_acct  
          WHEN 5 THEN @var_acct  
          WHEN 6 THEN @dir_var_acct  
          WHEN 7 THEN @ovhd_var_acct  
          WHEN 8 THEN @util_var_acct  
        END,  
        @line_descr = case @iloop  
          WHEN 1 THEN 'cost_var_acct' WHEN 2 THEN 'cost_var_direct_acct'  
          WHEN 3 THEN 'cost_var_ovhd_acct' WHEN 4 THEN 'cost_var_util_acct'  
          WHEN 5 THEN 'cost_var_acct' WHEN 6 THEN 'cost_var_direct_acct'  
          WHEN 7 THEN 'cost_var_ovhd_acct' WHEN 8 THEN 'cost_var_util_acct'  
        END  
  
      select @inv_qty = case when @iloop < 5 then @i_inv_qty else @p_inv_qty end  
      select @a_tran_id = case when @iloop < 5 then @i_tran_id else @p_tran_id end  
  
      set @msg = @line_descr  
      if @iloop in (1,5) and @typ not in ('S','W')  
        select @ins_account = @recv_acct, @line_descr = 'rcpt_var_acct',@msg = 'rcpt_var_acct',  
          @varmatl = case when @iloop = 1 then @vi_unitcost + @vi_direct + @vi_overhead + @vi_utility  
             else @vp_unitcost + @vp_direct + @vp_overhead + @vp_utility end                                         
  
      select @line_descr = @line_descr + case when @iloop < 5 then ' (qty chg)' else ' (pr chg)' end  
      IF @varmatl != 0   
      BEGIN  
        select @ref_code = ''        -- mls 1/21/03 SCR 30555 start  
        if @old_r_acct = @ins_account           
          select @ref_code = @old_r_ref_cd  
        else  
        begin  
          if exists (select 1 from glrefact (nolock) where @ins_account like account_mask and reference_flag > 1)  
          begin  
            if exists (select 1 from glratyp t (nolock), glref r (nolock)  
              where t.reference_type = r.reference_type and @ins_account like t.account_mask and  
              r.status_flag = 0 and r.reference_code  = @reference_code)  
              select @ref_code = @reference_code  
          end  
          select @old_r_acct = @ins_account, @old_r_ref_cd = @ref_code  
        end           -- mls 1/21/03 SCR 30555 end  
        select @vi_qty = case when @iloop < 5   
          then @inv_qty when isnull(@ci_qty,0) = 0 then @inv_qty else @ci_qty end    -- mls 2/24/05 SCR 34297  
 if @vi_qty = 0 select @vi_qty = @a_tran_qty  
  
        if @iloop not in (1,5) and @typ not in ( 'S','W')  select @varmatl = 0  
  
        select @cost = @varmatl / @vi_qty  
  
        exec @retval = adm_gl_insert  @d_part_no, @d_location, 'R', @i_receipt_no,   
          0, 0, @apply_date, @vi_qty, @cost,      -- mls 6/2/00 SCR 22994   
          @ins_account, @i_nat_curr, @i_curr_factor, @i_oper_factor, @company_id, -- mls 2/9/01 SCR 24318  
          DEFAULT, @ref_code, @a_tran_id, @line_descr, @varmatl    -- mls 1/21/03 SCR 30555 -- mls 4/12/02 SCR 28686  
  
        IF @retval <= 0  
        BEGIN  
          rollback tran  
    select @msg = 'Error Inserting [' + @msg + '] GL Costing Record!'  
          exec adm_raiserror 91311, @msg  
          return  
        END  
      END  
  
      SELECT @iloop = @iloop + 1  
    END -- while loop  
  
    SELECT @iloop = 1  
    WHILE @iloop <= 8  
    BEGIN   
      Select @varmatl =   
        CASE @iloop  
          WHEN 1 THEN @ci_unitcost  
          WHEN 2 THEN @ci_direct  
          WHEN 3 THEN @ci_overhead  
          WHEN 4 THEN @ci_utility   
          WHEN 5 THEN @cp_unitcost  
          WHEN 6 THEN @cp_direct  
          WHEN 7 THEN @cp_overhead  
          WHEN 8 THEN @cp_utility   
        END  
                  
      Select @ins_account =   
        CASE @iloop  
          WHEN 1 THEN @ar_cgs_code  
          WHEN 2 THEN @ar_cgs_direct_code  
          WHEN 3 THEN @ar_cgs_ovhd_code  
          WHEN 4 THEN @ar_cgs_util_code  
          WHEN 5 THEN @ar_cgs_code  
          WHEN 6 THEN @ar_cgs_direct_code  
          WHEN 7 THEN @ar_cgs_ovhd_code  
          WHEN 8 THEN @ar_cgs_util_code  
        END,  
        @line_descr = case @iloop  
          WHEN 1 THEN 'ar_cgs_acct' WHEN 2 THEN 'ar_cgs_direct_acct'  
          WHEN 3 THEN 'ar_cgs_ovhd_acct' WHEN 4 THEN 'ar_cgs_util_acct'  
          WHEN 5 THEN 'ar_cgs_acct' WHEN 6 THEN 'ar_cgs_direct_acct'  
          WHEN 7 THEN 'ar_cgs_ovhd_acct' WHEN 8 THEN 'ar_cgs_util_acct'  
        END  
  
      select @inv_qty = case when @iloop < 5 then @i_inv_qty else @p_inv_qty end  
      select @a_tran_id = case when @iloop < 5 then @i_tran_id else @p_tran_id end  
      select @vi_qty = case when @iloop < 5 then @ci_qty else @inv_qty end  
  
   select @msg = @line_descr  
      select @line_descr = @line_descr + case when @iloop < 5 then ' (qty chg)' else ' (pr chg)' end  
      IF @varmatl != 0   
      BEGIN  
        select @ref_code = ''        -- mls 1/21/03 SCR 30555 start  
        if @old_r_acct = @ins_account           
          select @ref_code = @old_r_ref_cd  
        else  
        begin  
          if exists (select 1 from glrefact (nolock) where @ins_account like account_mask and reference_flag > 1)  
        begin  
            if exists (select 1 from glratyp t (nolock), glref r (nolock)  
              where t.reference_type = r.reference_type and @ins_account like t.account_mask and  
              r.status_flag = 0 and r.reference_code  = @reference_code)  
              select @ref_code = @reference_code  
          end  
          select @old_r_acct = @ins_account, @old_r_ref_cd = @ref_code  
        end           -- mls 1/21/03 SCR 30555 end  
  
        select @cost = @varmatl / @vi_qty  
  
        exec @retval = adm_gl_insert  @d_part_no, @d_location, 'R', @i_receipt_no,   
          0, 0, @apply_date, @vi_qty, @cost,      -- mls 6/2/00 SCR 22994   
          @ins_account, @i_nat_curr, @i_curr_factor, @i_oper_factor, @company_id, -- mls 2/9/01 SCR 24318  
          DEFAULT, @ref_code, @a_tran_id, @line_descr, @varmatl    -- mls 1/21/03 SCR 30555 -- mls 4/12/02 SCR 28686  
  
        IF @retval <= 0  
        BEGIN  
          rollback tran  
    select @msg = 'Error Inserting [' + @msg + '] GL Costing Record!'  
          exec adm_raiserror 91311, @msg  
          return  
        END  
      END  
  
      SELECT @iloop = @iloop + 1  
    END -- while loop  
  end -- inchg = 0 or prchg = 0  
  
    
  if @d_quantity != @i_quantity or @i_qc_flag != @d_qc_flag   -- mls 12/11/02 SCR 29220  
  begin  
    SELECT @invdelta = @iqty - @dqty  
  
    if @d_qc_flag = 'Y'   SELECT @invdelta = @iqty  
  
    if @i_qc_flag != 'Y'   
    begin  
      if exists ( select 1 from agents (nolock) WHERE part_no = @i_part_no and agent_type = 'R' )  
      begin  
        exec @retval = fs_agent @i_part_no, 'R', @i_receipt_no, @i_recv_date, @i_who_entered, @invdelta  
        if @retval= -3   
        begin  
          rollback tran  
          exec adm_raiserror 91324, 'Agent Error... Outsource item not found on this Prod No!'  
          return  
        end  
  
        if @retval<0   
        begin  
          rollback tran  
          exec adm_raiserror 91325 ,'Agent Error... Try Re-Saving!'  
          return  
        end  
      end  
    end  --IF qc  
  end          -- mls 12/11/02 SCR 29220  
  
  SKIP_GL_TRANS:  
  
  if @d_quantity != @i_quantity       -- mls 12/11/02 SCR 29220  
  begin  
      
      
    if isnull(@d_prod_no,0) > 0  
    begin  
      select @invdelta =(@d_quantity * -1)   
  
        
        
      exec @retval=fs_wip_prod @d_prod_no, @i_receipt_no, @d_part_no, @d_location, @invdelta  
  
      if @retval<=0   
      begin  
        rollback tran  
        exec adm_raiserror 91327, 'Error Auto-Posting Production/WIP from Receiving!'  
        return  
      end  
    end  
  
    if isnull(@i_prod_no,0) > 0  
    begin  
        
        
      exec @retval=fs_wip_prod @i_prod_no, @i_receipt_no, @i_part_no, @i_location, @i_quantity  
      if @retval<=0   
      begin  
        rollback tran  
        exec adm_raiserror 91328, 'Error Auto-Posting Production/WIP from Receiving!'  
        return  
      end  
    end  
      
  end  --if dl_qty != in_qty  
  
  
  
FETCH NEXT FROM recupd into  
@i_receipt_no, @i_po_no, @i_part_no, @i_sku_no, @i_location, @i_release_date,   
@i_recv_date, @i_part_type, @i_unit_cost, @i_quantity, @i_vendor, @i_unit_measure,   
@i_prod_no, @i_freight_cost, @i_account_no, @i_status, @i_ext_cost, @i_who_entered,   
@i_vend_inv_no, @i_conv_factor, @i_pro_number, @i_bl_no, @i_lb_tracking, @i_freight_flag,   
@i_freight_vendor, @i_freight_inv_no, @i_freight_account, @i_freight_unit, @i_voucher_no,   
@i_note, @i_po_key, @i_qc_flag, @i_qc_no, @i_rejected, @i_over_flag, @i_std_cost,   
@i_std_direct_dolrs, @i_std_ovhd_dolrs, @i_std_util_dolrs, @i_nat_curr, @i_oper_factor,   
@i_curr_factor, @i_oper_cost, @i_curr_cost, @i_project1, @i_project2, @i_project3,   
@i_tax_included, @i_po_line, @i_amt_nonrecoverable_tax, @i_org_id,  
@d_receipt_no, @d_po_no, @d_part_no, @d_sku_no, @d_location, @d_release_date,   
@d_recv_date, @d_part_type, @d_unit_cost, @d_quantity, @d_vendor, @d_unit_measure,   
@d_prod_no, @d_freight_cost, @d_account_no, @d_status, @d_ext_cost, @d_who_entered,   
@d_vend_inv_no, @d_conv_factor, @d_pro_number, @d_bl_no, @d_lb_tracking, @d_freight_flag,   
@d_freight_vendor, @d_freight_inv_no, @d_freight_account, @d_freight_unit, @d_voucher_no,   
@d_note, @d_po_key, @d_qc_flag, @d_qc_no, @d_rejected, @d_over_flag, @d_std_cost,   
@d_std_direct_dolrs, @d_std_ovhd_dolrs, @d_std_util_dolrs, @d_nat_curr, @d_oper_factor,   
@d_curr_factor, @d_oper_cost, @d_curr_cost, @d_project1, @d_project2, @d_project3,   
@d_tax_included, @d_po_line , @d_amt_nonrecoverable_tax,  
@m_lb_tracking, @m_status  
  
end   
  
  
CLOSE recupd  
DEALLOCATE recupd  
  
end  
  
GO
CREATE NONCLUSTERED INDEX [rec3] ON [dbo].[receipts_all] ([qc_flag]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [rec1] ON [dbo].[receipts_all] ([receipt_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [rec2] ON [dbo].[receipts_all] ([recv_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[receipts_all] TO [public]
GO
GRANT SELECT ON  [dbo].[receipts_all] TO [public]
GO
GRANT INSERT ON  [dbo].[receipts_all] TO [public]
GO
GRANT DELETE ON  [dbo].[receipts_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[receipts_all] TO [public]
GO
