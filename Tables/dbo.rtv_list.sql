CREATE TABLE [dbo].[rtv_list]
(
[timestamp] [timestamp] NOT NULL,
[rtv_no] [int] NOT NULL,
[line_no] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_expires] [datetime] NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_sku] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_cost] [decimal] (20, 8) NOT NULL,
[unit_measure] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_date] [datetime] NULL,
[qty_ordered] [decimal] (20, 8) NOT NULL,
[qty_received] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[conv_factor] [decimal] (20, 8) NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[taxable] [int] NULL,
[post_to_ap] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[reason_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_cost] [decimal] (20, 8) NOT NULL,
[oper_cost] [decimal] (20, 8) NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_tax] [decimal] (20, 8) NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700delrtvl] ON [dbo].[rtv_list] FOR DELETE AS
BEGIN
if exists (select * from deleted where status >='S')
begin
	if exists (select * from config where flag='TRIG_DEL_RTVL' and value_str='DISABLE')
		return
	else
		begin
		rollback tran
		exec adm_raiserror 71531 ,'You Can NOT Delete An RTV Item That Is Closed, Or Voided!'
		return
		end
end
declare @xlp int
select @xlp=isnull((select min(deleted.row_id) from deleted),0)
while @xlp > 0
BEGIN
  UPDATE rtv_all 
    set total_amt_order = total_amt_order - (deleted.curr_cost * deleted.qty_ordered)
    from deleted
    where rtv_all.rtv_no = deleted.rtv_no and deleted.row_id = @xlp
  
  SELECT @xlp=isnull((select min(deleted.row_id) from deleted where row_id > @xlp),0)
END
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insrtvl] ON [dbo].[rtv_list] FOR INSERT AS
BEGIN
DECLARE @i_rtv_no int, @i_line_no int, @i_part_no varchar(30), @i_location varchar(10),
@i_lot_ser varchar(25), @i_bin_no varchar(12), @i_date_expires datetime, @i_type char(1),
@i_vend_sku varchar(30), @i_account_no varchar(32), @i_description varchar(255),
@i_unit_cost decimal(20,8), @i_unit_measure varchar(2), @i_rel_date datetime,
@i_qty_ordered decimal(20,8), @i_qty_received decimal(20,8), @i_who_entered varchar(20),
@i_status char(1), @i_conv_factor decimal(20,8), @i_void char(1), @i_void_who varchar(20),
@i_void_date datetime, @i_lb_tracking char(1), @i_taxable int, @i_post_to_ap char(1),
@i_note varchar(255), @i_row_id int, @i_reason_code varchar(10), @i_curr_cost decimal(20,8),
@i_oper_cost decimal(20,8), @i_reference_code varchar(32), @i_tax_code varchar(10),
@i_total_tax decimal(20,8), @i_organization_id varchar(30)

declare @issue_rtv_acct varchar(32),  @issno int,  @issue_ref_code varchar(32),
  @msg varchar(255),
  @rtv_location varchar(10), @rtv_org_id varchar(30)

set @issue_rtv_acct = NULL

DECLARE t700insrtv__cursor CURSOR LOCAL STATIC FOR
SELECT i.rtv_no, i.line_no, i.part_no, i.location, i.lot_ser, i.bin_no, i.date_expires, i.type,
i.vend_sku, i.account_no, i.description, i.unit_cost, i.unit_measure, i.rel_date,
i.qty_ordered, i.qty_received, i.who_entered, i.status, i.conv_factor, i.void, i.void_who,
i.void_date, i.lb_tracking, i.taxable, i.post_to_ap, i.note, i.row_id, i.reason_code,
i.curr_cost, i.oper_cost, i.reference_code, i.tax_code, i.total_tax, isnull(i.organization_id,'')
from inserted i

OPEN t700insrtv__cursor

if @@cursor_rows = 0
begin
CLOSE t700insrtv__cursor
DEALLOCATE t700insrtv__cursor
return
end

FETCH NEXT FROM t700insrtv__cursor into
@i_rtv_no, @i_line_no, @i_part_no, @i_location, @i_lot_ser, @i_bin_no, @i_date_expires, @i_type,
@i_vend_sku, @i_account_no, @i_description, @i_unit_cost, @i_unit_measure, @i_rel_date,
@i_qty_ordered, @i_qty_received, @i_who_entered, @i_status, @i_conv_factor, @i_void,
@i_void_who, @i_void_date, @i_lb_tracking, @i_taxable, @i_post_to_ap, @i_note, @i_row_id,
@i_reason_code, @i_curr_cost, @i_oper_cost, @i_reference_code, @i_tax_code, @i_total_tax,
@i_organization_id

While @@FETCH_STATUS = 0
begin
  if @i_type != 'M'
  begin
    IF not exists (SELECT 1 FROM dbo.inv_list WHERE part_no =  @i_part_no AND location =  @i_location)
    BEGIN
      rollback tran
      exec adm_raiserror 81501 ,'Inventory Part Missing.  The transaction is being rolled back.'
      RETURN
    END

    IF Exists( select 1 from inv_master m (nolock) where @i_part_no=m.part_no and m.status='C' )
    BEGIN
      rollback tran
      exec adm_raiserror 81502 ,'You can not return to vendor Custom Kit Items.'
      RETURN
    END
  end 

  if @i_organization_id = ''										-- I/O start										
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_location)

    if @i_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_location + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
  end
  else
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_location)
  end														-- I/O end

    select @rtv_location = location,
      @rtv_org_id = organization_id
    from rtv_all (nolock) 
    where rtv_no = @i_rtv_no

    IF @@ROWCOUNT = 0
    BEGIN
      rollback tran	
      exec adm_raiserror 81103, 'Return to Vendor Header Missing. The transaction is being rolled back.'
      RETURN
    END

    if @i_location != @rtv_location
    begin
      if @i_location not in (select location from dbo.adm_get_related_locs_fn('po',@rtv_org_id,99))
      begin
        select @msg = 'Location ([' + @i_location + ']) is not related to the header location ([' + @rtv_location + ']).  Change the rtv line location'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end 
    end

  update rtv_list
  set organization_id = @i_organization_id ,
    account_no = dbo.adm_mask_acct_fn (account_no, @i_organization_id)
  where row_id = @i_row_id  and rtv_no = @i_rtv_no 

  if @i_type != 'M' and @i_status = 'S' 
  BEGIN
    UPDATE next_iss_no set last_no=last_no + 1
    SELECT @issno = last_no from next_iss_no

    if @issue_rtv_acct is null
    begin
      select @issue_rtv_acct = isnull((select account from issue_code (nolock) where code = 'RTV'),NULL)

      if @issue_rtv_acct is NULL
      begin
        rollback tran
        exec adm_raiserror 91531, 'RTV inventory adjustment code does not exist or the GL account is not entered'
        return
      end       
    end

    set @issue_rtv_acct = dbo.adm_mask_acct_fn (@issue_rtv_acct, @i_organization_id)

    select @issue_ref_code = ''
    if exists (select 1 from glrefact (nolock) where @issue_rtv_acct like account_mask and reference_flag > 1)
    begin
      if exists (select 1 from glratyp t (nolock), glref r (nolock)
        where t.reference_type = r.reference_type and @issue_rtv_acct like t.account_mask and
        r.status_flag = 0 and r.reference_code  = @i_reference_code)
      begin
        select @issue_ref_code = @i_reference_code
      end
    end

    if @i_lb_tracking = 'Y'
    begin
	INSERT INTO lot_serial_bin_issue
		( tran_no, tran_ext, line_no, part_no, location, 
		bin_no, tran_code, date_tran, date_expires, 
		qty, direction, who, lot_ser) 
	(SELECT @issno, 0, 1, @i_part_no, @i_location, 
		@i_bin_no, 'I', rtv_all.apply_date, @i_date_expires, 
		@i_qty_ordered * @i_conv_factor,-1, @i_who_entered, @i_lot_ser
		from  rtv_all (nolock)
        where rtv_all.rtv_no = @i_rtv_no)
    end

    INSERT into issues_all
	(issue_no   , part_no     , location_from  , 
	 location_to, avg_cost    , who_entered    , 
	 code       , issue_date  , note           , 
	 qty        , inventory   ,direction   , 
	 lb_tracking, direct_dolrs, ovhd_dolrs     , 
	 util_dolrs , labor       , reason_code    ,
         mtrl_reference_cd_expense, direct_reference_cd_expense,
         ovhd_reference_cd_expense, util_reference_cd_expense,
         mtrl_account_expense, direct_account_expense,
         ovhd_account_expense, util_account_expense )
      SELECT @issno, @i_part_no, @i_location, 
        '', case when @i_post_to_ap = 'N' then (@i_unit_cost / @i_conv_factor) else 0 end, @i_who_entered, 
        'RTV',rtv_all.apply_date, @i_note, 
        (@i_qty_ordered * @i_conv_factor), case when @i_post_to_ap = 'N' then 'N' else 'P' end, -1,
	@i_lb_tracking, 0,0,0,0,
	'RTV'+convert( varchar( 7 ), @i_rtv_no ),
        @issue_ref_code, @issue_ref_code, @issue_ref_code, @issue_ref_code,
        @issue_rtv_acct, @issue_rtv_acct,
        @issue_rtv_acct, @issue_rtv_acct
        from  rtv_all (nolock), inv_master im, inv_list il
        where  @i_rtv_no = rtv_all.rtv_no and im.part_no = il.part_no and
		@i_part_no = il.part_no and @i_location = il.location

    UPDATE rtv_list set taxable = @issno where row_id = @i_row_id
  END



  UPDATE rtv_all 
    set total_amt_order = isnull(total_amt_order,0) + (@i_curr_cost * @i_qty_ordered)
    where rtv_all.rtv_no = @i_rtv_no 



FETCH NEXT FROM t700insrtv__cursor into
@i_rtv_no, @i_line_no, @i_part_no, @i_location, @i_lot_ser, @i_bin_no, @i_date_expires, @i_type,
@i_vend_sku, @i_account_no, @i_description, @i_unit_cost, @i_unit_measure, @i_rel_date,
@i_qty_ordered, @i_qty_received, @i_who_entered, @i_status, @i_conv_factor, @i_void,
@i_void_who, @i_void_date, @i_lb_tracking, @i_taxable, @i_post_to_ap, @i_note, @i_row_id,
@i_reason_code, @i_curr_cost, @i_oper_cost, @i_reference_code, @i_tax_code, @i_total_tax,
@i_organization_id
end -- while

CLOSE t700insrtv__cursor
DEALLOCATE t700insrtv__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updrtvl] ON [dbo].[rtv_list] FOR update AS 
BEGIN

declare @ext_cost decimal(20,8), @curr_precision int, @issno int

DECLARE @i_rtv_no int, @i_line_no int, @i_part_no varchar(30), @i_location varchar(10),
@i_lot_ser varchar(25), @i_bin_no varchar(12), @i_date_expires datetime, @i_type char(1),
@i_vend_sku varchar(30), @i_account_no varchar(32), @i_description varchar(255),
@i_unit_cost decimal(20,8), @i_unit_measure varchar(2), @i_rel_date datetime,
@i_qty_ordered decimal(20,8), @i_qty_received decimal(20,8), @i_who_entered varchar(20),
@i_status char(1), @i_conv_factor decimal(20,8), @i_void char(1), @i_void_who varchar(20),
@i_void_date datetime, @i_lb_tracking char(1), @i_taxable int, @i_post_to_ap char(1),
@i_note varchar(255), @i_row_id int, @i_reason_code varchar(10), @i_curr_cost decimal(20,8),
@i_oper_cost decimal(20,8), @i_reference_code varchar(32), @i_tax_code varchar(10),
@i_total_tax decimal(20,8), @i_organization_id varchar(30),
@d_rtv_no int, @d_line_no int, @d_part_no varchar(30), @d_location varchar(10),
@d_lot_ser varchar(25), @d_bin_no varchar(12), @d_date_expires datetime, @d_type char(1),
@d_vend_sku varchar(30), @d_account_no varchar(32), @d_description varchar(255),
@d_unit_cost decimal(20,8), @d_unit_measure varchar(2), @d_rel_date datetime,
@d_qty_ordered decimal(20,8), @d_qty_received decimal(20,8), @d_who_entered varchar(20),
@d_status char(1), @d_conv_factor decimal(20,8), @d_void char(1), @d_void_who varchar(20),
@d_void_date datetime, @d_lb_tracking char(1), @d_taxable int, @d_post_to_ap char(1),
@d_note varchar(255), @d_row_id int, @d_reason_code varchar(10), @d_curr_cost decimal(20,8),
@d_oper_cost decimal(20,8), @d_reference_code varchar(32), @d_tax_code varchar(10),
@d_total_tax decimal(20,8), @d_organization_id varchar(30)

declare @issue_rtv_acct varchar(32), @issue_ref_code varchar(32),
  @msg varchar(255), @org_id varchar(30), @rtv_location varchar(10), @rtv_org_id varchar(30)


DECLARE t700updrtv__cursor CURSOR LOCAL STATIC FOR
SELECT i.rtv_no, i.line_no, i.part_no, i.location, i.lot_ser, i.bin_no, i.date_expires, i.type,
i.vend_sku, i.account_no, i.description, i.unit_cost, i.unit_measure, i.rel_date,
i.qty_ordered, i.qty_received, i.who_entered, i.status, i.conv_factor, i.void, i.void_who,
i.void_date, i.lb_tracking, i.taxable, i.post_to_ap, i.note, i.row_id, i.reason_code,
i.curr_cost, i.oper_cost, i.reference_code, i.tax_code, i.total_tax, isnull(i.organization_id,''),
d.rtv_no, d.line_no, d.part_no, d.location, d.lot_ser, d.bin_no, d.date_expires, d.type,
d.vend_sku, d.account_no, d.description, d.unit_cost, d.unit_measure, d.rel_date,
d.qty_ordered, d.qty_received, d.who_entered, d.status, d.conv_factor, d.void, d.void_who,
d.void_date, d.lb_tracking, d.taxable, d.post_to_ap, d.note, d.row_id, d.reason_code,
d.curr_cost, d.oper_cost, d.reference_code, d.tax_code, d.total_tax, isnull(d.organization_id,'')
from inserted i, deleted d
where i.row_id=d.row_id

OPEN t700updrtv__cursor
FETCH NEXT FROM t700updrtv__cursor into
@i_rtv_no, @i_line_no, @i_part_no, @i_location, @i_lot_ser, @i_bin_no, @i_date_expires, @i_type,
@i_vend_sku, @i_account_no, @i_description, @i_unit_cost, @i_unit_measure, @i_rel_date,
@i_qty_ordered, @i_qty_received, @i_who_entered, @i_status, @i_conv_factor, @i_void,
@i_void_who, @i_void_date, @i_lb_tracking, @i_taxable, @i_post_to_ap, @i_note, @i_row_id,
@i_reason_code, @i_curr_cost, @i_oper_cost, @i_reference_code, @i_tax_code, @i_total_tax, @i_organization_id,
@d_rtv_no, @d_line_no, @d_part_no, @d_location, @d_lot_ser, @d_bin_no, @d_date_expires, @d_type,
@d_vend_sku, @d_account_no, @d_description, @d_unit_cost, @d_unit_measure, @d_rel_date,
@d_qty_ordered, @d_qty_received, @d_who_entered, @d_status, @d_conv_factor, @d_void,
@d_void_who, @d_void_date, @d_lb_tracking, @d_taxable, @d_post_to_ap, @d_note, @d_row_id,
@d_reason_code, @d_curr_cost, @d_oper_cost, @d_reference_code, @d_tax_code, @d_total_tax, @d_organization_id

While @@FETCH_STATUS = 0
begin

  IF @i_type != 'M'
  begin
    if not exists (select 1 FROM dbo.inv_list (nolock)
      WHERE  dbo.inv_list.part_no =  @i_part_no AND  dbo.inv_list.location =  @i_location)
    BEGIN
      rollback tran
      exec adm_raiserror 91501, 'Inventory Part Missing.  The transaction is being rolled back.'
      RETURN
    END
  end

  if @i_organization_id = ''										-- I/O start										
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_location)

    if @i_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_location + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
    else
    begin
      update rtv_list
      set organization_id = @i_organization_id ,
        account_no = dbo.adm_mask_acct_fn (account_no, @i_organization_id)
      where rtv_no = @i_rtv_no and row_id = @i_row_id and isnull(organization_id,'') != @i_organization_id
    end
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location)

    if @i_organization_id != @org_id
    begin
      select @i_organization_id = @org_id
      update rtv_list
      set organization_id = @i_organization_id ,
        account_no = dbo.adm_mask_acct_fn (account_no, @i_organization_id)
      where rtv_no = @i_rtv_no and row_id = @i_row_id and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end

    select @rtv_location = location,
      @rtv_org_id = organization_id
    from rtv_all (nolock) 
    where rtv_no = @i_rtv_no

    if @i_location != @rtv_location
    begin
      if @i_location not in (select location from dbo.adm_get_related_locs_fn( 'po',@rtv_org_id,99))
      begin
        select @msg = 'Location ([' + @i_location + ']) is not related to the header location  ([' + @rtv_location + ']).  Change the rtv line location'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end 
    end 

  select @ext_cost = @i_curr_cost * @i_qty_ordered

  select @curr_precision = isnull((select gl.curr_precision 
    from glcurr_vw gl (nolock), rtv_all r (nolock)
    where gl.currency_code = r.currency_key and r.rtv_no = @i_rtv_no),2)

  UPDATE rtv_all
    set total_amt_order = total_amt_order + round((@ext_cost),@curr_precision)
  where rtv_all.rtv_no = @i_rtv_no

  select @ext_cost = @d_curr_cost * @d_qty_ordered

  select @curr_precision = isnull((select gl.curr_precision 
    from glcurr_vw gl (nolock), rtv_all r (nolock)
    where gl.currency_code = r.currency_key and r.rtv_no = @d_rtv_no),2)

  UPDATE rtv_all
    set total_amt_order = total_amt_order - round((@ext_cost),@curr_precision)
  where rtv_all.rtv_no = @d_rtv_no						-- mls 5/30/03 SCR 31262 end

  if @d_status = 'S'
  BEGIN
    if update(rtv_no) or update(line_no ) or update(part_no ) or update(location )  or 
    update(type ) or update(vend_sku ) or update(account_no ) or 
    update(description) or update(unit_cost ) or update(unit_measure ) or 
    update(rel_date ) or update(qty_ordered) or update(qty_received ) or 
    update(who_entered) or update(status ) or update(conv_factor) or 
    update(void ) or update(void_who ) or update(void_date) or 
    update(lb_tracking) or update(post_to_ap ) or update(note) or update(row_id) 
    BEGIN
      if exists (select 1 from config (nolock) where flag='TRIG_UPD_RTVL' and value_str='DISABLE')
        return
      else
      BEGIN
        rollback tran
        exec adm_raiserror 91531 ,'You Can NOT Update An RTV Item That Is Closed, Or Voided!'
        return
      END
    END
  END

  if @i_type != 'M' and @i_status = 'S' and @d_status != 's' 
  BEGIN
    UPDATE next_iss_no set last_no=last_no + 1
    SELECT @issno = last_no from next_iss_no

    select @issue_rtv_acct = isnull((select account from issue_code (nolock) where code = 'RTV'),NULL)

    if @issue_rtv_acct is NULL
    begin
        rollback tran
        exec adm_raiserror 91531, 'RTV inventory adjustment code does not exist or the GL account is not entered'
        return
    end       

    set @issue_rtv_acct = dbo.adm_mask_acct_fn (@issue_rtv_acct, @i_organization_id)

    select @issue_ref_code = ''
    if exists (select 1 from glrefact (nolock) where @issue_rtv_acct like account_mask and reference_flag > 1)
    begin
      if exists (select 1 from glratyp t (nolock), glref r (nolock)
        where t.reference_type = r.reference_type and @issue_rtv_acct like t.account_mask and
        r.status_flag = 0 and r.reference_code  = @i_reference_code)
      begin
        select @issue_ref_code = @i_reference_code
      end
    end

    if @i_lb_tracking = 'Y'
    begin
      INSERT INTO lot_serial_bin_issue (
        tran_no, tran_ext, line_no, part_no, location, 
	bin_no, tran_code, date_tran, date_expires, 
	qty, direction, who, lot_ser) 
      SELECT @issno, 0, 1, @i_part_no, @i_location, 
        @i_bin_no, 'I', apply_date, @i_date_expires, 
        (@i_qty_ordered * @i_conv_factor),-1, @i_who_entered, @i_lot_ser
      from  rtv_all (nolock)
      where rtv_no = @i_rtv_no
    end


    insert into issues_all (
      issue_no   , part_no     , location_from  , 
      location_to, avg_cost    , who_entered    , 
      code       , issue_date  , note           , 
      qty        , inventory   ,  direction   , 
      lb_tracking, direct_dolrs, ovhd_dolrs     , 
      util_dolrs , labor       , reason_code    ,
      mtrl_reference_cd_expense, direct_reference_cd_expense,
      ovhd_reference_cd_expense, util_reference_cd_expense,
      mtrl_account_expense, direct_account_expense,
      ovhd_account_expense, util_account_expense )
    select @issno, @i_part_no, @i_location, 
      '', case when @i_post_to_ap = 'Y' then 0 else (@i_unit_cost / @i_conv_factor) end, @i_who_entered, 
      'RTV', apply_date, @i_note, 
      (@i_qty_ordered * @i_conv_factor), case when @i_post_to_ap = 'Y' then 'P' else 'N' end, -1, 
      @i_lb_tracking, 0, 0, 0, 0, 'RTV'+convert( varchar( 7 ), @i_rtv_no ),
      @issue_ref_code, @issue_ref_code, @issue_ref_code, @issue_ref_code,
      @issue_rtv_acct, @issue_rtv_acct,
      @issue_rtv_acct, @issue_rtv_acct
    from  rtv_all (nolock)
    where rtv_no = @i_rtv_no


    update rtv_list set taxable = @issno where row_id = @i_row_id
  end


FETCH NEXT FROM t700updrtv__cursor into
@i_rtv_no, @i_line_no, @i_part_no, @i_location, @i_lot_ser, @i_bin_no, @i_date_expires, @i_type,
@i_vend_sku, @i_account_no, @i_description, @i_unit_cost, @i_unit_measure, @i_rel_date,
@i_qty_ordered, @i_qty_received, @i_who_entered, @i_status, @i_conv_factor, @i_void,
@i_void_who, @i_void_date, @i_lb_tracking, @i_taxable, @i_post_to_ap, @i_note, @i_row_id,
@i_reason_code, @i_curr_cost, @i_oper_cost, @i_reference_code, @i_tax_code, @i_total_tax, @i_organization_id,
@d_rtv_no, @d_line_no, @d_part_no, @d_location, @d_lot_ser, @d_bin_no, @d_date_expires, @d_type,
@d_vend_sku, @d_account_no, @d_description, @d_unit_cost, @d_unit_measure, @d_rel_date,
@d_qty_ordered, @d_qty_received, @d_who_entered, @d_status, @d_conv_factor, @d_void,
@d_void_who, @d_void_date, @d_lb_tracking, @d_taxable, @d_post_to_ap, @d_note, @d_row_id,
@d_reason_code, @d_curr_cost, @d_oper_cost, @d_reference_code, @d_tax_code, @d_total_tax, @d_organization_id
end -- while

CLOSE t700updrtv__cursor
DEALLOCATE t700updrtv__cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [rtvl1] ON [dbo].[rtv_list] ([rtv_no], [part_no], [lot_ser], [bin_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rtv_list] TO [public]
GO
GRANT SELECT ON  [dbo].[rtv_list] TO [public]
GO
GRANT INSERT ON  [dbo].[rtv_list] TO [public]
GO
GRANT DELETE ON  [dbo].[rtv_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[rtv_list] TO [public]
GO
