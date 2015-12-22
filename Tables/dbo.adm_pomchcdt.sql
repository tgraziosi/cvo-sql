CREATE TABLE [dbo].[adm_pomchcdt]
(
[timestamp] [timestamp] NOT NULL,
[match_ctrl_int] [int] NOT NULL,
[match_line_num] [int] NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_int] [int] NOT NULL,
[po_line_num] [int] NOT NULL,
[gl_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_ordered] [decimal] (20, 8) NOT NULL,
[unit_price] [decimal] (20, 8) NOT NULL,
[match_unit_price] [decimal] (20, 8) NOT NULL,
[qty_invoiced] [decimal] (20, 8) NOT NULL,
[match_posted_flag] [int] NOT NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[item_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_ref_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax] [decimal] (20, 8) NULL,
[amt_tax_included] [decimal] (20, 8) NULL,
[calc_tax] [decimal] (20, 8) NULL,
[receipt_no] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[project1] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__adm_pomch__proje__5DA1CF53] DEFAULT (''),
[project2] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__adm_pomch__proje__5E95F38C] DEFAULT (''),
[project3] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__adm_pomch__proje__5F8A17C5] DEFAULT (''),
[nat_curr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oper_factor] [decimal] (20, 8) NULL,
[curr_factor] [decimal] (18, 0) NULL,
[oper_cost] [decimal] (20, 8) NULL,
[curr_cost] [decimal] (20, 8) NULL,
[misc] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__adm_pomchc__misc__607E3BFE] DEFAULT ('N'),
[amt_nonrecoverable_tax] [decimal] (20, 8) NULL,
[amt_tax_det] [decimal] (20, 8) NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[adm_pomchcdt_delete] ON [dbo].[adm_pomchcdt] 
FOR DELETE

AS

DECLARE @xlp int, @receipt int, @misc char(1),@flag int
DECLARE @oqty decimal(20,8),@vqty decimal(20,8),@oprice decimal(20,8), @vprice decimal(20,8)

BEGIN

if EXISTS(select * from deleted where match_posted_flag = 1) 
 BEGIN
   rollback tran
   exec adm_raiserror 83299 ,'You Can Not Delete An Match Record that has been Vouchered!' 
   RETURN
 END


--Loop for posted records
SELECT @xlp = isnull((select min(row_id) from deleted ),0)

WHERE @xlp != 0
 BEGIN

   SELECT @receipt = receipt_no,
          @misc    = misc,
          @flag    = match_posted_flag
    FROM deleted
    WHERE row_id = @xlp

   if @misc != 'Y'
    BEGIN  
      --Update receipt Status as New

         UPDATE receipts_all
          SET status = 'R'
          WHERE receipt_no = @receipt            
    END

   select @xlp = isnull((select min(row_id) from deleted WHERE row_id > @xlp ),0)


 END

END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

































CREATE TRIGGER [dbo].[t700insmchcdt] ON [dbo].[adm_pomchcdt] FOR insert,update AS 
BEGIN
DECLARE @mchchg_type        int,
        @glco_company_id  int,
        @retval      int,
        @iloop       int,
        @glqty       decimal( 20, 8 )
DECLARE @typ         char( 1 ),
        @tran_code   char( 1 )
DECLARE @mchchg_apply_date    datetime
DECLARE @stdcost       decimal( 20, 8 ),
        @stddirect     decimal( 20, 8 ),
        @expcost       decimal( 20, 8 ),
        @cgpcost       decimal( 20, 8 ),
        @stdovhd       decimal( 20, 8 ),
        @stdutil       decimal( 20, 8 ),
        @varmatl       decimal( 20, 8 ),
        @tempcost      decimal( 20, 8 ),
        @tempqty       decimal( 20, 8 )
DECLARE @posting_code   varchar( 8 ),
        @glco_home_currency       varchar( 8 ),
        @mchchg_vendor         varchar( 12 ),
        @mchchg_voucher_no     varchar( 16 ),
        @pur_acct       varchar( 32 ),
        @cost_var_mtrl_acct  varchar( 32 ),
        @cost_var_dir_acct  varchar( 32 ),
        @cost_var_ovhd_acct  varchar( 32 ),
        @cost_var_util_acct  varchar( 32 ),

        @stdaccount     varchar( 32 ),
        @line_descr     varchar( 50 ),		-- mls 4/23/02 SCR 28686
        @issue_ref_code varchar( 32 )		-- mls 11/05/03 SCR 32021

DECLARE @receipts_status char(1),
  @receipts_quantity decimal( 20, 8 ),
  @receipts_ext_cost decimal( 20, 8 ),
  @receipts_unit_cost decimal( 20, 8 ),
  @receipts_curr_cost decimal( 20, 8 ),
  @receipts_tax_included decimal( 20, 8 ),
  @receipts_amt_nonrecoverable_tax decimal( 20, 8 )

declare @msg varchar(255), @mchchg_org_id varchar(30), @mchchg_location varchar(10), @org_id varchar(30)

DECLARE @i_match_ctrl_int int, @i_match_line_num int, @i_po_ctrl_num varchar(16),
@i_po_ctrl_int int, @i_po_line_num int, @i_gl_acct varchar(32), @i_qty_ordered decimal(20,8),
@i_unit_price decimal(20,8), @i_match_unit_price decimal(20,8), @i_qty_invoiced decimal(20,8),
@i_match_posted_flag int, @i_conv_factor decimal(20,8), @i_part_no varchar(30),
@i_item_desc varchar(60), @i_gl_ref_code varchar(32), @i_tax_code varchar(8),
@i_amt_tax decimal(20,8), @i_amt_tax_included decimal(20,8), @i_calc_tax decimal(20,8),
@i_receipt_no int, @i_location varchar(10), @i_row_id int, @i_project1 varchar(75),
@i_project2 varchar(75), @i_project3 varchar(75), @i_nat_curr varchar(8),
@i_oper_factor decimal(20,8), @i_curr_factor decimal(18,0), @i_oper_cost decimal(20,8),
@i_curr_cost decimal(20,8), @i_misc char(1),
@i_amt_nonrecoverable_tax decimal(20,8), @i_organization_id varchar(30),
@d_match_ctrl_int int, @d_match_line_num int, @d_po_ctrl_num varchar(16),
@d_po_ctrl_int int, @d_po_line_num int, @d_gl_acct varchar(32), @d_qty_ordered decimal(20,8),
@d_unit_price decimal(20,8), @d_match_unit_price decimal(20,8), @d_qty_invoiced decimal(20,8),
@d_match_posted_flag int, @d_conv_factor decimal(20,8), @d_part_no varchar(30),
@d_item_desc varchar(60), @d_gl_ref_code varchar(32), @d_tax_code varchar(8),
@d_amt_tax decimal(20,8), @d_amt_tax_included decimal(20,8), @d_calc_tax decimal(20,8),
@d_receipt_no int, @d_location varchar(10), @d_row_id int, @d_project1 varchar(75),
@d_project2 varchar(75), @d_project3 varchar(75), @d_nat_curr varchar(8),
@d_oper_factor decimal(20,8), @d_curr_factor decimal(18,0), @d_oper_cost decimal(20,8),
@d_curr_cost decimal(20,8), @d_misc char(1),
@d_amt_nonrecoverable_tax decimal(20,8)

declare @mchchg_curr_factor decimal(20,8), @mchchg_oper_factor decimal(20,8)	-- mls 10/28/02 SCR 28835

DECLARE @a_tran_id int, @rcpt_upd_int int

SELECT @glco_company_id  = company_id, @glco_home_currency    = home_currency
FROM glco (nolock)

select @tran_code      = 'V'

DECLARE t700updadm__cursor CURSOR LOCAL FOR
SELECT i.match_ctrl_int, i.match_line_num, i.po_ctrl_num, i.po_ctrl_int, i.po_line_num,
i.gl_acct, i.qty_ordered, i.unit_price, i.match_unit_price, i.qty_invoiced,
i.match_posted_flag, i.conv_factor, i.part_no, i.item_desc, i.gl_ref_code, i.tax_code,
i.amt_tax, i.amt_tax_included, i.calc_tax, i.receipt_no, i.location, i.row_id, i.project1,
i.project2, i.project3, i.nat_curr, i.oper_factor, i.curr_factor, i.oper_cost, i.curr_cost,
i.misc,i.amt_nonrecoverable_tax, isnull(i.organization_id,''),
d.match_ctrl_int, d.match_line_num, d.po_ctrl_num, d.po_ctrl_int, d.po_line_num,
d.gl_acct, d.qty_ordered, d.unit_price, d.match_unit_price, d.qty_invoiced,
d.match_posted_flag, d.conv_factor, d.part_no, d.item_desc, d.gl_ref_code, d.tax_code,
d.amt_tax, d.amt_tax_included, d.calc_tax, d.receipt_no, d.location, d.row_id, d.project1,
d.project2, d.project3, d.nat_curr, d.oper_factor, d.curr_factor, d.oper_cost, d.curr_cost,
d.misc, d.amt_nonrecoverable_tax
from inserted i
left outer join deleted d on i.row_id = d.row_id

OPEN t700updadm__cursor
FETCH NEXT FROM t700updadm__cursor into
@i_match_ctrl_int, @i_match_line_num, @i_po_ctrl_num, @i_po_ctrl_int, @i_po_line_num, @i_gl_acct,
@i_qty_ordered, @i_unit_price, @i_match_unit_price, @i_qty_invoiced, @i_match_posted_flag,
@i_conv_factor, @i_part_no, @i_item_desc, @i_gl_ref_code, @i_tax_code, @i_amt_tax,
@i_amt_tax_included, @i_calc_tax, @i_receipt_no, @i_location, @i_row_id, @i_project1,
@i_project2, @i_project3, @i_nat_curr, @i_oper_factor, @i_curr_factor, @i_oper_cost,
@i_curr_cost, @i_misc, @i_amt_nonrecoverable_tax, @i_organization_id,
@d_match_ctrl_int, @d_match_line_num, @d_po_ctrl_num, @d_po_ctrl_int, @d_po_line_num, @d_gl_acct,
@d_qty_ordered, @d_unit_price, @d_match_unit_price, @d_qty_invoiced, @d_match_posted_flag,
@d_conv_factor, @d_part_no, @d_item_desc, @d_gl_ref_code, @d_tax_code, @d_amt_tax,
@d_amt_tax_included, @d_calc_tax, @d_receipt_no, @d_location, @d_row_id, @d_project1,
@d_project2, @d_project3, @d_nat_curr, @d_oper_factor, @d_curr_factor, @d_oper_cost,
@d_curr_cost, @d_misc, @d_amt_nonrecoverable_tax

While @@FETCH_STATUS = 0
begin
  if @i_organization_id = ''										-- I/O start										
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_location)

    if @i_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_location + ')].'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
    else
    begin
      update adm_pomchcdt
      set organization_id = @i_organization_id ,
        gl_acct = dbo.adm_mask_acct_fn (gl_acct, @i_organization_id)
      where match_ctrl_int = @i_match_ctrl_int and row_id = @i_row_id and isnull(organization_id,'') != @i_organization_id
    end
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location)

    if @i_organization_id != @org_id
    begin
      select @i_organization_id = @org_id
      update adm_pomchcdt
      set organization_id = @i_organization_id ,
        gl_acct = dbo.adm_mask_acct_fn (gl_acct, @i_organization_id)
      where match_ctrl_int = @i_match_ctrl_int and row_id = @i_row_id and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end

select @i_gl_ref_code = isnull( @i_gl_ref_code, '' )

--Get System values for tranasaction
SELECT  @mchchg_vendor     = vendor_code,
  @mchchg_voucher_no = vendor_invoice_no,
  @mchchg_type       = trx_type,
  @mchchg_apply_date  = apply_date,
  @mchchg_curr_factor = curr_factor,				-- mls 10/28/02 SCR 28835
  @mchchg_oper_factor = oper_factor,				-- mls 10/28/02 SCR 28835
  @mchchg_org_id      = isnull(organization_id,''),
  @mchchg_location    = location
FROM adm_pomchchg_all (nolock)
WHERE match_ctrl_int = @i_match_ctrl_int

if @mchchg_org_id = ''
  select @mchchg_org_id = dbo.adm_get_locations_org_fn(@mchchg_location)

if @i_location not in (select location from dbo.adm_get_related_locs_fn( 'match',@mchchg_org_id,99))
begin
  select @msg = 'Organization ([' + @i_organization_id + ']) is not related to the header organization ([' + @mchchg_org_id + ']).  Change or remove the match line location'
  rollback tran
  exec adm_raiserror 832115, @msg
  RETURN
end 

IF ( @i_misc != 'Y' )
BEGIN
  --Must do different updates to receipts for triggers to cost properly!!!
  select @receipts_status = status,
    @receipts_quantity = quantity,
    @receipts_ext_cost = ext_cost,
    @receipts_unit_cost = unit_cost,
    @receipts_curr_cost = curr_cost,
    @receipts_tax_included = tax_included,
    @receipts_amt_nonrecoverable_tax = isnull(amt_nonrecoverable_tax,0)
    from receipts_all where receipt_no = @i_receipt_no

  if @@rowcount = 0  select @receipts_status = NULL

  set @rcpt_upd_int = 0
  if @receipts_status is not NULL and
    (@receipts_quantity != @i_qty_invoiced or @receipts_ext_cost != (@receipts_unit_cost * @i_qty_invoiced))
  begin
    UPDATE receipts_all
    SET quantity = @i_qty_invoiced,
      ext_cost = unit_cost * @i_qty_invoiced,				-- mls 1/29/01 SCR 21701
      oper_factor = @mchchg_oper_factor,				-- mls 10/28/02 SCR 28835
      curr_factor = @mchchg_curr_factor 				-- mls 10/28/02 SCR 28835
    WHERE receipt_no = @i_receipt_no 

    select @receipts_quantity = @i_qty_invoiced,
      @receipts_ext_cost = @receipts_unit_cost * @i_qty_invoiced,
      @rcpt_upd_int = 1
  end

  if @receipts_status is not NULL and
    (@receipts_unit_cost != @i_match_unit_price or @receipts_curr_cost != @i_curr_cost or 
     @receipts_ext_cost != (@i_match_unit_price * @receipts_quantity) or 
     @receipts_tax_included != case when @d_match_posted_flag is NULL and @i_amt_tax_included = 0
      then @receipts_tax_included else @i_amt_tax_included end or
    (@receipts_amt_nonrecoverable_tax != @i_amt_nonrecoverable_tax))
  begin
    UPDATE receipts_all
    SET unit_cost = @i_match_unit_price,
      curr_cost = @i_curr_cost,
      ext_cost = @i_match_unit_price * quantity,					-- mls 1/29/01 SCR 21701
      tax_included = case when @d_match_posted_flag is NULL and @i_amt_tax_included = 0	-- mls 5/3/01 SCR 26874
        then tax_included 				-- mls 5/3/01 SCR 26874
        else @i_amt_tax_included end,				-- mls 5/3/01 SCR 26874
      amt_nonrecoverable_tax = @i_amt_nonrecoverable_tax,
      oper_factor = @mchchg_oper_factor,				-- mls 10/28/02 SCR 28835
      curr_factor = @mchchg_curr_factor					-- mls 10/28/02 SCR 28835
    WHERE receipt_no = @i_receipt_no 

    set @rcpt_upd_int = 1
  end

  if @receipts_status is not null
  begin
    IF @i_match_posted_flag = 1 and @receipts_status != 'T'
      --Update receipt Status as Vouchered
      UPDATE receipts_all
      SET status = 'T'
      WHERE receipt_no = @i_receipt_no
    ELSE IF @i_match_posted_flag = -999 and @receipts_status != 'R'
      --Update receipt Status as New
      UPDATE receipts_all
      SET status = 'R'
      WHERE receipt_no = @i_receipt_no
    ELSE IF @i_match_posted_flag = 0 and @receipts_status != 'S'
      --Update receipt Status matched
      UPDATE receipts_all
      SET status = 'S', voucher_no = @mchchg_voucher_no
      WHERE receipt_no = @i_receipt_no
  end
END

IF @mchchg_type = 4092 and @i_match_posted_flag = 0 and 
  ((isnull(@d_match_posted_flag,0) = -1)	-- mls 10/22/02 #5
  or ((@i_qty_invoiced != isnull(@d_qty_invoiced,0)) or (@i_match_unit_price != isnull(@d_match_unit_price,0))))
												-- mls 5/3/01 SCR 26874
BEGIN
  select @typ = ''
  if NOT exists (select 1 from inv_list l (nolock) where l.part_no = @i_part_no and l.location = @i_location)
  BEGIN
    SELECT @typ = 'A', @posting_code = apacct_code
    FROM locations_all (nolock)
    WHERE location = @i_location
  END
  ELSE
  BEGIN
    SELECT @typ = inv_cost_method, @posting_code = acct_code,
      @stdcost   = std_cost, @stddirect = std_direct_dolrs,
      @stdovhd   = std_ovhd_dolrs, @stdutil   = std_util_dolrs
    FROM inventory(nolock)
    WHERE part_no  = @i_part_no AND location = @i_location
  END

  --Default to Average if not in list
  if @typ NOT IN ('A','F','L','W','S') select @typ='A'

  -- Get Accounts
  SELECT @pur_acct      = ap_cgp_code,
         @cost_var_mtrl_acct = cost_var_code,
         @cost_var_dir_acct = cost_var_direct_code,
         @cost_var_ovhd_acct = cost_var_ovhd_code,
         @cost_var_util_acct = cost_var_util_code
  FROM in_account(nolock)
  WHERE acct_code = @posting_code 

  select @d_curr_factor = isnull(@d_curr_factor,@mchchg_curr_factor)

  if @mchchg_curr_factor < 0
    select @i_match_unit_price = @i_curr_cost / abs(@mchchg_curr_factor)
  else
    select @i_match_unit_price = @i_curr_cost * @mchchg_curr_factor

  if @d_curr_factor < 0
    select @d_match_unit_price = @d_curr_cost / abs(@d_curr_factor)
  else
    select @d_match_unit_price = @d_curr_cost * @d_curr_factor

  select @expcost = (@i_match_unit_price * @i_qty_invoiced) - 
    case when @mchchg_curr_factor >= 0 then @i_amt_tax_included * @mchchg_curr_factor else
    @i_amt_tax_included / abs(@mchchg_curr_factor) end			-- mls 10/28/02 SCR 28835

  if isnull(@d_match_posted_flag,0) = 0 and
    (@i_match_unit_price != isnull(@d_match_unit_price,0))
    select @expcost = @expcost - ((@d_match_unit_price * @d_qty_invoiced) - 
      case when @d_curr_factor >= 0 then @d_amt_tax_included * @d_curr_factor else
      @d_amt_tax_included / abs(@d_curr_factor) end)				-- mls 10/28/02 SCR 28835

  select @cgpcost = @expcost, @expcost = -@expcost
  select @glqty = @i_qty_invoiced * @i_conv_factor

  if @typ = 'S' and isnull(@d_match_posted_flag,0) = -1		-- mls 1/14/05 SCR 34087
  begin
    --Inventory Accounts
    SELECT @iloop = 1

    WHILE @iloop <= 4
    BEGIN
      Select @stdcost =
        CASE @iloop WHEN 1 THEN @stdcost WHEN 2 THEN @stddirect WHEN 3 THEN @stdovhd WHEN 4 THEN @stdutil END,
        @stdaccount =
        CASE @iloop WHEN 1 THEN @cost_var_mtrl_acct WHEN 2 THEN @cost_var_dir_acct 
          WHEN 3 THEN @cost_var_ovhd_acct WHEN 4 THEN @cost_var_util_acct END,
        @line_descr = 
        CASE @iloop when 1 then 'cost_var_acct' when 2 then 'cost_var_direct_acct' when 3 then 'cost_var_ovhd_acct'
          when 4 then 'cost_var_util_acct' end

      select @tempcost = @stdcost * @glqty

      if @iloop = 1
        select @tempcost = @tempcost - @cgpcost

      IF @tempcost != 0
      BEGIN
        select @issue_ref_code = ''								-- mls 11/05/03 SCR 32031 start
        if exists (select 1 from glrefact (nolock) where @stdaccount like account_mask and reference_flag > 1)
        begin
          if exists (select 1 from glratyp t (nolock), glref r (nolock)
            where t.reference_type = r.reference_type and @stdaccount like t.account_mask and
            r.status_flag = 0 and r.reference_code  = @i_gl_ref_code)
          begin
            select @issue_ref_code = @i_gl_ref_code
          end
        end											-- mls 11/05/03 SCR 32031 end

        select @stdcost = @tempcost / @glqty
        exec @retval = adm_gl_insert  @i_part_no,@i_location,@tran_code,@i_match_ctrl_int,0,0,
          @mchchg_apply_date,@glqty,@stdcost,@stdaccount,@i_nat_curr,@mchchg_curr_factor,@mchchg_oper_factor,
          @glco_company_id,
          DEFAULT,@issue_ref_code,@a_tran_id,@line_descr,@tempcost				-- mls 4/23/02 SCR 28686
        IF @retval <= 0
        BEGIN
          rollback tran
          exec adm_raiserror 81311, 'Error Inserting GL Costing Record!'
          return
        END
      END

      select @expcost = @expcost - @tempcost
      SELECT @iloop = @iloop + 1
    END --While
  end

  --Insert into Inventory Account
  select @tempcost = @expcost / @glqty

  if @typ = 'S' and isnull(@d_match_posted_flag,0) = 0				-- mls 1/14/05 SCR 34087 start
    exec @retval = adm_gl_insert  @i_part_no,@i_location,@tran_code,@i_match_ctrl_int,0,0,
      @mchchg_apply_date,@glqty,@tempcost,@cost_var_mtrl_acct,@i_nat_curr,@mchchg_curr_factor,@mchchg_oper_factor, -- mls 10/28/02 SCR 28835
      @glco_company_id,DEFAULT,@i_gl_ref_code,
      @a_tran_id, 'cost_var_acct',@expcost					-- mls 4/23/02 SCR 28686
  else										-- mls 1/14/05 SCR 34087 end
    exec @retval = adm_gl_insert  @i_part_no,@i_location,@tran_code,@i_match_ctrl_int,0,0,
      @mchchg_apply_date,@glqty,@tempcost,@i_gl_acct,@i_nat_curr,@mchchg_curr_factor,@mchchg_oper_factor, -- mls 10/28/02 SCR 28835
      @glco_company_id,DEFAULT,@i_gl_ref_code,
      @a_tran_id, 'exp_acct',@expcost					-- mls 4/23/02 SCR 28686

  IF @retval <= 0
  BEGIN
    rollback tran
    exec adm_raiserror 81312, 'Error Inserting GL Costing Record!'
    return
  END

  select @issue_ref_code = ''								-- mls 11/05/03 SCR 32031 start
  if exists (select 1 from glrefact (nolock) where @pur_acct like account_mask and reference_flag > 1)
  begin
    if exists (select 1 from glratyp t (nolock), glref r (nolock)
      where t.reference_type = r.reference_type and @pur_acct like t.account_mask and
      r.status_flag = 0 and r.reference_code  = @i_gl_ref_code)
    begin
      select @issue_ref_code = @i_gl_ref_code
    end
  end											-- mls 11/05/03 SCR 32031 end

  --Insert into Purchase Expense Account
  select @tempcost = @cgpcost / @glqty
  exec @retval = adm_gl_insert  @i_part_no,@i_location,@tran_code,@i_match_ctrl_int,0,0,
    @mchchg_apply_date,@glqty,@tempcost,@pur_acct,@i_nat_curr,@mchchg_curr_factor,@mchchg_oper_factor, -- mls 10/28/02 SCR 28835
    @glco_company_id,
    DEFAULT,@issue_ref_code,@a_tran_id, 'ap_cgp_acct',@cgpcost						-- mls 4/23/02 SCR 28686

  IF @retval <= 0
  BEGIN
    rollback tran
    exec adm_raiserror 81313, 'Error Inserting GL Costing Record!'
    return
  END
END

FETCH NEXT FROM t700updadm__cursor into
@i_match_ctrl_int, @i_match_line_num, @i_po_ctrl_num, @i_po_ctrl_int, @i_po_line_num, @i_gl_acct,
@i_qty_ordered, @i_unit_price, @i_match_unit_price, @i_qty_invoiced, @i_match_posted_flag,
@i_conv_factor, @i_part_no, @i_item_desc, @i_gl_ref_code, @i_tax_code, @i_amt_tax,
@i_amt_tax_included, @i_calc_tax, @i_receipt_no, @i_location, @i_row_id, @i_project1,
@i_project2, @i_project3, @i_nat_curr, @i_oper_factor, @i_curr_factor, @i_oper_cost,
@i_curr_cost, @i_misc, @i_amt_nonrecoverable_tax, @i_organization_id,
@d_match_ctrl_int, @d_match_line_num, @d_po_ctrl_num, @d_po_ctrl_int, @d_po_line_num, @d_gl_acct,
@d_qty_ordered, @d_unit_price, @d_match_unit_price, @d_qty_invoiced, @d_match_posted_flag,
@d_conv_factor, @d_part_no, @d_item_desc, @d_gl_ref_code, @d_tax_code, @d_amt_tax,
@d_amt_tax_included, @d_calc_tax, @d_receipt_no, @d_location, @d_row_id, @d_project1,
@d_project2, @d_project3, @d_nat_curr, @d_oper_factor, @d_curr_factor, @d_oper_cost,
@d_curr_cost, @d_misc, @d_amt_nonrecoverable_tax
end -- while

CLOSE t700updadm__cursor
DEALLOCATE t700updadm__cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [PK_adm_pomchcdt_1__10] ON [dbo].[adm_pomchcdt] ([match_ctrl_int], [match_line_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [pomchchg_idx1] ON [dbo].[adm_pomchcdt] ([po_ctrl_int], [po_line_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_pomchcdt] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_pomchcdt] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_pomchcdt] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_pomchcdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_pomchcdt] TO [public]
GO
