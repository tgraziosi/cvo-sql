CREATE TABLE [dbo].[pur_list]
(
[timestamp] [timestamp] NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_sku] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_no] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_cost] [decimal] (20, 8) NOT NULL,
[unit_measure] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rel_date] [datetime] NOT NULL,
[qty_ordered] [decimal] (20, 8) NOT NULL,
[qty_received] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ext_cost] [decimal] (20, 8) NULL,
[conv_factor] [decimal] (20, 8) NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line] [int] NULL,
[taxable] [int] NULL,
[prev_qty] [decimal] (20, 8) NULL,
[po_key] [int] NULL,
[weight_ea] [decimal] (20, 8) NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_factor] [decimal] (20, 8) NULL,
[oper_factor] [decimal] (20, 8) NULL,
[total_tax] [decimal] (20, 8) NULL,
[curr_cost] [decimal] (20, 8) NULL,
[oper_cost] [decimal] (20, 8) NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[project1] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__pur_list__projec__009F5C1F] DEFAULT (' '),
[project2] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__pur_list__projec__01938058] DEFAULT (' '),
[project3] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__pur_list__projec__0287A491] DEFAULT (' '),
[tolerance_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipto_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[receiving_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[shipto_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[receipt_batch_no] [int] NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[add_to_stock_ind] [int] NULL,
[orig_part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr_valid_ind] [int] NULL,
[ship_via_method] [smallint] NULL,
[over_ride] [smallint] NULL,
[plrecd] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700delpurl] ON [dbo].[pur_list]   FOR DELETE AS 
begin
declare	@vendor_code	varchar(12),
	@pay_to_code	varchar(8),
	@class_code	varchar(8),
	@branch_code	varchar(8),
	@amt_net	decimal(20,8),
	@rate_home decimal(20,8),
	@rate_oper decimal(20,8),
	@rtn int,
	@hstat char(1),
        @po_approval_status char(1)
declare @prodno int, @prodext int, @prodlin int

declare	@d_po_no varchar (16)  ,
	@d_part_no varchar (30)  ,
	@d_location varchar (10)  ,
	@d_type char (1)  ,
	@d_vend_sku varchar (30)  ,
	@d_account_no varchar (32)  ,
	@d_description varchar (255)  ,
	@d_unit_cost decimal(20, 8)  ,
	@d_unit_measure varchar (2)  ,
	@d_note varchar (255)  ,
	@d_rel_date datetime  ,
	@d_qty_ordered decimal(20, 8)  ,
	@d_qty_received decimal(20, 8)  ,
	@d_who_entered varchar (20)  ,
	@d_status char (1)  ,
	@d_ext_cost decimal(20, 8)  ,
	@d_conv_factor decimal(20, 8)  ,
	@d_void char (1)  ,
	@d_void_who varchar (20)  ,
	@d_void_date datetime  ,
	@d_lb_tracking char (1)  ,
	@d_line int  ,
	@d_taxable int  ,
	@d_prev_qty decimal(20, 8)  ,
	@d_po_key int  ,
	@d_weight_ea decimal(20, 8)  ,
	@d_row_id int  ,
	@d_tax_code varchar (10)  ,
	@d_curr_factor decimal(20, 8)  ,
	@d_oper_factor decimal(20, 8)  ,
	@d_total_tax decimal(20, 8)  ,
	@d_curr_cost decimal(20, 8)  ,
	@d_oper_cost decimal(20, 8)  ,
	@d_reference_code varchar (32)  ,
	@d_project1 varchar (75)  ,
	@d_project2 varchar (75)  ,
	@d_project3 varchar (75) 

if exists (select * from config where flag='TRIG_DEL_PURL' and value_str='DISABLE') return

DECLARE delpurl CURSOR LOCAL FOR
SELECT po_no, part_no, location, qty_ordered, qty_received, line, taxable, total_tax, curr_cost
FROM deleted

OPEN delpurl
FETCH NEXT FROM delpurl into
@d_po_no, @d_part_no, @d_location, 
@d_qty_ordered, @d_qty_received, @d_line, @d_taxable, @d_total_tax, @d_curr_cost

While @@FETCH_STATUS = 0
begin

  if @d_qty_received <> 0 
  begin
    rollback tran
    exec adm_raiserror 71131 ,'You Can Not Delete A Received Item!'
    return
  end

  delete releases 
  where po_no = @d_po_no and part_no = @d_part_no and
    case when isnull(po_line,0)=0 then @d_line else po_line end = @d_line 	-- mls 5/9/01 #1


  UPDATE purchase_all
  SET total_amt_order = total_amt_order - ( (@d_curr_cost * @d_qty_ordered) - 
    case when @d_taxable = 0 then @d_total_tax else 0 end ) 
  WHERE po_no = @d_po_no

  
  Select @vendor_code = vendor_no,
    @rate_home = curr_factor,
    @rate_oper = oper_factor,
    @hstat = status,
    @po_approval_status = isnull(approval_status,'')
  from purchase_all (nolock)
  where po_no=@d_po_no

  if @po_approval_status = 'P' 							-- mls 7/17/03 SCR 31491
  begin	
    rollback tran
    exec adm_raiserror 71139 ,'This purchase order is being processed by eProcurement.  It cannot be changed.'
    return
  end

  Select @pay_to_code = pay_to_code,
    @class_code = vend_class_code,
    @branch_code = branch_code
  from adm_vend_all (nolock)
  where vendor_code = @vendor_code

  Select @amt_net = (@d_curr_cost * (@d_qty_ordered - @d_qty_received))

  if @hstat < 'N' or @d_status < 'N' select @amt_net = 0

  if @amt_net > 0 
  begin
    select @amt_net = -1 * @amt_net
    exec @rtn = fs_apactinp_sp  @vendor_code,  @pay_to_code, @class_code, @branch_code,
      @amt_net,      @rate_home,   @rate_oper

    if @@error <> 0 or @rtn <> 0 
    begin
      rollback tran
      exec adm_raiserror 71132, 'Error updating activity tables with new amount.'
      return
    end
  end
  

 FETCH NEXT FROM delpurl into
   @d_po_no, @d_part_no, @d_location, 
   @d_qty_ordered, @d_qty_received, @d_line, @d_taxable, @d_total_tax, @d_curr_cost
end 

CLOSE delpurl
DEALLOCATE delpurl

end


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700inspurl] ON [dbo].[pur_list]   FOR INSERT  AS 
BEGIN
if exists (select * from config where flag='TRIG_INS_PURL' and value_str='DISABLE') return

declare @i_po_no varchar(16), @i_part_no varchar(30), @i_location varchar(10), @i_type char(1),
  @i_unit_measure varchar(2), @i_qty_ordered decimal(20,8), @i_qty_received decimal(20,8), @i_status char(1),
  @i_curr_cost decimal(20,8), @i_total_tax decimal(20,8), @i_taxable int,@i_shipto_code varchar(10),
  @i_receiving_loc varchar(10), @i_organization_id varchar(30), @i_row_id int, @i_account_no varchar(32),
  @i_add_to_stock_ind int, @i_orig_part_type char(1),
  @i_addr_valid_ind int,
  @i_addr1  varchar(40), @i_addr2 varchar(40), @i_addr3 varchar(40), @i_addr4 varchar(40), @i_addr5 varchar(40), @i_country_cd varchar(3),
  @i_tax_code varchar(10)

declare @addr1  varchar(255), @addr2 varchar(255)  , @addr3 varchar(255) , @addr4  varchar(255),
  @addr5 varchar(255) , @addr6 varchar(255) ,
  @city varchar(255), @state varchar(255) , @zip varchar(255) ,
  @country_cd varchar(3), @country varchar(255),
  @rtn int, @rc int

declare @l_po_no varchar(16), @ap_vend_flag int, @po_location varchar(10)

declare	@vendor_code	varchar(12),
	@amt_net	decimal(20,8),
	@rate_home decimal(20,8),
	@rate_oper decimal(20,8),
	@po_status char(1),
	@home_precision	smallint,
	@oper_precision	smallint,
	@amt_net_home	float,
	@amt_net_oper	float,
	@p_prod_no int,
        @po_approval_status char(1),
	@msg varchar(255), 
	@org_id varchar(30),
	@po_org_id varchar(30)

DECLARE updpurl CURSOR LOCAL FOR
select 
  i.po_no, i.part_no, i.location, i.type, i.unit_measure, i.qty_ordered, i.qty_received, i.status,
  i.curr_cost, i.total_tax, isnull(i.taxable,1), i.shipto_code,i.receiving_loc,						-- mls 3/12/03 SCR 30821
  isnull(i.organization_id,''), i.row_id, i.account_no,
  i.add_to_stock_ind, i.orig_part_type,
  isnull(i.addr_valid_ind,0), addr1, addr2, addr3, addr4, addr5, country_cd,
  isnull(i.tax_code,'')
from inserted i
order by i.po_no, i.line, i.part_no

select @l_po_no = '', @ap_vend_flag = NULL

OPEN updpurl

FETCH NEXT FROM updpurl INTO
  @i_po_no, @i_part_no, @i_location, @i_type, @i_unit_measure, @i_qty_ordered, @i_qty_received, @i_status,
  @i_curr_cost, @i_total_tax, @i_taxable,@i_shipto_code, @i_receiving_loc, @i_organization_id, @i_row_id,
  @i_account_no,
  @i_add_to_stock_ind, @i_orig_part_type,
  @i_addr_valid_ind, @i_addr1, @i_addr2, @i_addr3, @i_addr4, @i_addr5, @i_country_cd,
  @i_tax_code
WHILE @@FETCH_STATUS = 0
begin
  if @i_organization_id = ''										-- I/O start										
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_receiving_loc)

    if @i_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_receiving_loc + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
    else
    begin
      if @i_organization_id != dbo.adm_get_locations_org_fn(@i_shipto_code)
      begin
        select @msg = 'Organization ([' + @i_organization_id + ']) not valid for Ship to Location ([' + @i_shipto_code + ']).'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end
    end
  end
  else
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_receiving_loc)

    if @i_organization_id != dbo.adm_get_locations_org_fn(@i_shipto_code)
    begin
      select @msg = 'Organization ([' + @i_organization_id + ']) not valid for Ship to Location ([' + @i_shipto_code + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
  end														-- I/O end

  if @i_orig_part_type is NULL
    select @i_orig_part_type = @i_type,
      @i_add_to_stock_ind = 1

  if @i_add_to_stock_ind is NULL
    select @i_add_to_stock_ind = case when @i_type = 'M' and @i_orig_part_type = 'P' then 0 else 1 end

  update pur_list
  set organization_id = @i_organization_id ,
    account_no = dbo.adm_mask_acct_fn (account_no, @i_organization_id),
    orig_part_type = @i_orig_part_type,
    add_to_stock_ind = @i_add_to_stock_ind
  where row_id = @i_row_id  and po_no = @i_po_no 

  if @ap_vend_flag is NULL
  begin
    SELECT @ap_vend_flag = isnull((select apactvnd_flag from apco (nolock)),0)

    SELECT @home_precision = b.curr_precision, @oper_precision = c.curr_precision
    FROM glco a (nolock), glcurr_vw b (nolock), glcurr_vw c (nolock)
    WHERE a.home_currency = b.currency_code AND a.oper_currency = c.currency_code
  end

  IF @i_type != 'M' 
  begin
    if not exists (SELECT 1 FROM inv_list (nolock)
      WHERE  part_no =  @i_part_no and location = @i_receiving_loc)
    BEGIN
      rollback tran	
      exec adm_raiserror 81101, 'Inventory Parte Missing.  The transaction is being rolled back.'
      RETURN
    END
  END
  if @i_type = 'P'
  begin
    IF exists( select 1 from inv_master m (nolock) where part_no = @i_part_no and status = 'C')
    BEGIN
      rollback tran
      exec adm_raiserror 81102, 'You can not purchase Custom Kit Items.'
      RETURN
    END
  end

  if isnull(@i_unit_measure,'') = '' 
  begin
    rollback tran
    exec adm_raiserror 91131, 'You Cannot have a blank Unit Of Measure!'
    return
  end

  if @l_po_no != @i_po_no
  begin
    select @p_prod_no = prod_no,
      @vendor_code = vendor_no,
      @rate_home = curr_factor,
      @rate_oper = oper_factor,
      @po_status = status,
      @po_approval_status = isnull(approval_status,'')	,			-- mls 7/17/03 SCR 31491
      @po_org_id = organization_id,
      @po_location = location
    from purchase_all (nolock) 
    where po_no = @i_po_no

    IF @@ROWCOUNT = 0
    BEGIN
      rollback tran	
      exec adm_raiserror 81103, 'Purchase Order Header Missing. The transaction is being rolled back.'
      RETURN
    END

    IF @po_status not in ('O','H')
    begin
      rollback tran	
      exec adm_raiserror 81131, 'Purchase Order Closed....Cannot Add Items!'
      RETURN
    END

    if @i_receiving_loc not in (select location from dbo.adm_get_related_locs_fn('po',@po_org_id,4))
    begin
      select @msg = 'Location ([' + @i_receiving_loc + ']) is not related to the header Location ([' + @po_location + ']).  Change the po line receiving location'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end 

    if @po_approval_status = 'P' 							-- mls 7/17/03 SCR 31491
    begin	
      rollback tran
      exec adm_raiserror 81139, 'This purchase order is being processed by eProcurement.  It cannot be changed.'
      return
    end
  end

  
  if isnull(@p_prod_no,0) > 0
  begin
    if NOT exists(select 1 from prod_list
      where prod_no = @p_prod_no and prod_ext = 0 and part_no = @i_part_no and
      location = @i_receiving_loc)
    begin	
      rollback tran
      exec adm_raiserror 81138, 'Is NOT Listed On Job - Please Add Then Re-Enter.'
      return
    end
  end

  if ((@i_curr_cost * @i_qty_ordered) - (@i_total_tax * (1-@i_taxable))) != 0
  begin
    UPDATE purchase_all 
    SET total_amt_order= total_amt_order + ((@i_curr_cost * @i_qty_ordered) - 
      (@i_total_tax * (1-@i_taxable)))
    WHERE po_no = @i_po_no
  end

  
 
  if @ap_vend_flag = 1 and @po_status > 'M' and @i_status > 'M'
  begin
    Select @amt_net = (@i_curr_cost * (@i_qty_ordered - @i_qty_received))

    if @amt_net > 0
    begin
      SELECT @amt_net_home = (SIGN(@amt_net * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + 
        (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(@amt_net * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @home_precision))
      SELECT @amt_net_oper = (SIGN(@amt_net * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + 
        (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) * ROUND(ABS(@amt_net * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) + 0.0000001, @oper_precision))

      IF NOT EXISTS ( SELECT 1 FROM apactvnd WHERE vendor_code = @vendor_code )
      begin
        INSERT apactvnd
        VALUES ( NULL,@vendor_code,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,@amt_net_home,0,'','','', '', 
          '', '', '', 0, 0, 0, 0, 0,0,0,0,0,0,0,'','','','','',0,0,0,0,0,0,0,@amt_net_oper,0,0)
      end
      ELSE
      begin
        UPDATE apactvnd
        SET amt_on_order = amt_on_order + @amt_net_home,
          amt_on_order_oper = amt_on_order_oper + @amt_net_oper
        WHERE vendor_code = @vendor_code
      end

      if @@error <> 0 
      begin
        rollback tran
        exec adm_raiserror 91132, 'Error updating activity tables with new amount.'
        return
      end
    END
  END 

  if @i_addr_valid_ind = 0
      and exists (select 1 from artax (nolock) where tax_code = @i_tax_code and isnull(tax_connect_flag,0) = 1)
  begin
    select @addr1 = @i_addr1,
      @addr2 = @i_addr2,
      @addr3 = @i_addr3,
      @addr4 = @i_addr4,
      @addr5 = @i_addr5,
      @addr6 = '',
      @city = '',
      @state = '',
      @zip = '',
      @country_cd = @i_country_cd

    exec @rtn = adm_parse_address 1, 0, 
      @addr1  OUT, @addr2  OUT, @addr3  OUT, @addr4  OUT, @addr5  OUT, @addr6  OUT,
      @city OUT, @state OUT, @zip OUT, @country_cd OUT, @country OUT

    exec @rc = adm_validate_address_wrap 'AP', @addr1 OUT, @addr2 OUT, @addr3 OUT,
      @addr4 OUT, @addr5 OUT, @city OUT, @state OUT, @zip OUT, @country_cd OUT, 0

    if @rtn <> 2 or @rc <> 2 
    begin
      update pur_list
      set addr1 = @addr1,
        addr2 = @addr2,
        addr3 = @addr3,
        addr4 = @addr4,
        addr5 = @addr5,
        city = @city,
        state = @state,
        zip = @zip,
        country_cd = @country_cd,
        addr_valid_ind = case when @rc > 0 then 1 else 0 end
      where po_no = @i_po_no and row_id = @i_row_id
    end
  end

  select @l_po_no = @i_po_no

  FETCH NEXT FROM updpurl INTO
    @i_po_no, @i_part_no, @i_location, @i_type, @i_unit_measure, @i_qty_ordered, @i_qty_received, @i_status,
    @i_curr_cost, @i_total_tax, @i_taxable, @i_shipto_code, @i_receiving_loc, @i_organization_id, @i_row_id,
    @i_account_no,
    @i_add_to_stock_ind, @i_orig_part_type,
    @i_addr_valid_ind, @i_addr1, @i_addr2, @i_addr3, @i_addr4, @i_addr5, @i_country_cd,
    @i_tax_code
end 
END


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE TRIGGER [dbo].[t700updpurl] ON [dbo].[pur_list]   FOR UPDATE  AS 

/*
DROP TABLE CVO_PO_AUDIT
delete from CVO_PO_AUDIT
CREATE TABLE CVO_PO_AUDIT (
field_name varchar(30),
field_from varchar(255),
field_to varchar(255),
po_no varchar(16),
po_line varchar(100),
part_no varchar(30),
modified_date datetime,
modified_by varchar(30)  )

SELECT * FROM CVO_PO_AUDIT
*/
-- Audits created by ELabarbera 11/11/13
-- PO SHIPTO_CODE
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'SHIP_TO_CODE' AS field_name, d.shipto_code, i.shipto_code, i.po_no, i.line, i.part_no, getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.row_id = d.row_id
		and i.shipto_code<>d.shipto_code
-- PO SHIP_VIA_METHOD
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'SHIP_VIA_METHOD' AS field_name, d.ship_via_method, i.ship_via_method, i.po_no, i.line, i.part_no, getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.row_id = d.row_id
		and  i.ship_via_method<> d.ship_via_method
-- UNIT COST
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'UNIT_COST' AS field_name, d.ship_via_method, i.ship_via_method, i.po_no, i.line, i.part_no, getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.row_id = d.row_id
		and  i.unit_cost<> d.unit_cost
-- QUANTITY CHANGE
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'QUANTITY' AS field_name, d.ship_via_method, i.ship_via_method, i.po_no, i.line, i.part_no, getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.row_id = d.row_id
		and  i.QTY_ORDERED<> d.QTY_ORDERED
  
BEGIN

declare @l_po_no varchar(16), @l_part_no varchar(30), @ap_vend_flag int, @l_line int		-- mls #2

declare	@vendor_code	varchar(12),
	@i_amt_net	decimal(20,8),
	@d_amt_net	decimal(20,8),
	@rate_home decimal(20,8),
	@rate_oper decimal(20,8),
	@po_status char(1),
	@home_precision	smallint,
	@oper_precision	smallint,
	@amt_net_home	float,
	@amt_net_oper	float,
        @p_prod_no int,
        @po_approval_status char(1)

declare	@i_po_no varchar (16)  ,
	@i_part_no varchar (30)  ,
	@i_location varchar (10)  ,
	@i_type char (1)  ,
	@i_vend_sku varchar (30)  ,
	@i_account_no varchar (32)  ,
	@i_description varchar (255)  ,
	@i_unit_cost decimal(20, 8)  ,
	@i_unit_measure varchar (2)  ,
	@i_note varchar (255)  ,
	@i_rel_date datetime  ,
	@i_qty_ordered decimal(20, 8)  ,
	@i_qty_received decimal(20, 8)  ,
	@i_who_entered varchar (20)  ,
	@i_status char (1)  ,
	@i_ext_cost decimal(20, 8)  ,
	@i_conv_factor decimal(20, 8)  ,
	@i_void char (1)  ,
	@i_void_who varchar (20)  ,
	@i_void_date datetime  ,
	@i_lb_tracking char (1)  ,
	@i_line int  ,
	@i_taxable int  ,
	@i_prev_qty decimal(20, 8)  ,
	@i_po_key int  ,
	@i_weight_ea decimal(20, 8)  ,
	@i_row_id int  ,
	@i_tax_code varchar (10)  ,
	@i_curr_factor decimal(20, 8)  ,
	@i_oper_factor decimal(20, 8)  ,
	@i_total_tax decimal(20, 8)  ,
	@i_curr_cost decimal(20, 8)  ,
	@i_oper_cost decimal(20, 8)  ,
	@i_reference_code varchar (32)  ,
	@i_project1 varchar (75)  ,
	@i_project2 varchar (75)  ,
	@i_project3 varchar (75),
        @i_shipto_code varchar (10),
        @i_receiving_loc varchar(10),
	@i_organization_id varchar(30),
	@i_add_to_stock_ind int,
	@i_orig_part_type char(1)
declare	@d_po_no varchar (16)  ,
	@d_part_no varchar (30)  ,
	@d_location varchar (10)  ,
	@d_type char (1)  ,
	@d_vend_sku varchar (30)  ,
	@d_account_no varchar (32)  ,
	@d_description varchar (255)  ,
	@d_unit_cost decimal(20, 8)  ,
	@d_unit_measure varchar (2)  ,
	@d_note varchar (255)  ,
	@d_rel_date datetime  ,
	@d_qty_ordered decimal(20, 8)  ,
	@d_qty_received decimal(20, 8)  ,
	@d_who_entered varchar (20)  ,
	@d_status char (1)  ,
	@d_ext_cost decimal(20, 8)  ,
	@d_conv_factor decimal(20, 8)  ,
	@d_void char (1)  ,
	@d_void_who varchar (20)  ,
	@d_void_date datetime  ,
	@d_lb_tracking char (1)  ,
	@d_line int  ,
	@d_taxable int  ,
	@d_prev_qty decimal(20, 8)  ,
	@d_po_key int  ,
	@d_weight_ea decimal(20, 8)  ,
	@d_row_id int  ,
	@d_tax_code varchar (10)  ,
	@d_curr_factor decimal(20, 8)  ,
	@d_oper_factor decimal(20, 8)  ,
	@d_total_tax decimal(20, 8)  ,
	@d_curr_cost decimal(20, 8)  ,
	@d_oper_cost decimal(20, 8)  ,
	@d_reference_code varchar (32)  ,
	@d_project1 varchar (75)  ,
	@d_project2 varchar (75)  ,
	@d_project3 varchar (75),
	@d_shipto_code varchar (10),
        @d_receiving_loc varchar(10),
	@d_organization_id varchar(30),
	@d_add_to_stock_ind int,
	@d_orig_part_type char(1)

declare @msg varchar(255), @org_id varchar(30), @po_org_id varchar(30), @po_location varchar(10)

if exists (select * from config where flag='TRIG_UPD_PURL' and value_str='DISABLE') return

DECLARE updpurl CURSOR LOCAL FOR
select 
  i.po_no, i.part_no, i.location, i.type, i.unit_measure, i.qty_ordered, i.qty_received, i.status,
  i.curr_cost, i.total_tax, isnull(i.taxable,1), i.line,i.shipto_code, i.receiving_loc, i.organization_id, i.row_id,
  i.account_no, i.add_to_stock_ind, i.orig_part_type,
  d.po_no, d.part_no, d.location, d.type, d.unit_measure, d.qty_ordered, d.qty_received, d.status,
  d.curr_cost, d.total_tax, isnull(d.taxable,1), d.line,d.shipto_code, d.receiving_loc, d.organization_id,
  d.account_no, d.add_to_stock_ind, d.orig_part_type
from inserted i, deleted d
where i.row_id = d.row_id
order by i.po_no, i.part_no

select @l_po_no = '', @l_part_no = '', @ap_vend_flag = NULL, @l_line = 0

OPEN updpurl
FETCH NEXT FROM updpurl INTO
  @i_po_no, @i_part_no, @i_location, @i_type, @i_unit_measure, @i_qty_ordered, @i_qty_received, 
  @i_status, @i_curr_cost, @i_total_tax, @i_taxable, @i_line,@i_shipto_code, @i_receiving_loc, @i_organization_id, @i_row_id,
  @i_account_no, @i_add_to_stock_ind, @i_orig_part_type,
  @d_po_no, @d_part_no, @d_location, @d_type, @d_unit_measure, @d_qty_ordered, @d_qty_received, 
  @d_status, @d_curr_cost, @d_total_tax, @d_taxable, @d_line,@d_shipto_code, @d_receiving_loc, @d_organization_id,
  @d_account_no, @d_add_to_stock_ind, @d_orig_part_type

While @@FETCH_STATUS = 0
begin
  if @ap_vend_flag is NULL
  begin
    SELECT @ap_vend_flag = isnull((select apactvnd_flag from apco (nolock)),0)

    SELECT @home_precision = b.curr_precision, @oper_precision = c.curr_precision
    FROM glco a (nolock), glcurr_vw b (nolock), glcurr_vw c (nolock)
    WHERE a.home_currency = b.currency_code AND a.oper_currency = c.currency_code
  end

  if @i_organization_id = ''										-- I/O start										
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_receiving_loc)

    if @i_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_receiving_loc + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
    else
    begin
      if @i_organization_id != dbo.adm_get_locations_org_fn(@i_shipto_code)
      begin
        select @msg = 'Organization ([' + @i_organization_id + ']) not valid for Ship to Location ([' + @i_shipto_code + ']).'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end

      update pur_list
      set organization_id = @i_organization_id ,
        account_no = dbo.adm_mask_acct_fn (account_no, @i_organization_id)
      where po_no = @i_po_no and row_id = @i_row_id and isnull(organization_id,'') != @i_organization_id
    end
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_receiving_loc)

    if @i_organization_id != @org_id
    begin
      select @i_organization_id = @org_id
      update pur_list
      set organization_id = @i_organization_id ,
        account_no = dbo.adm_mask_acct_fn (account_no, @i_organization_id)
      where po_no = @i_po_no and row_id = @i_row_id and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end

  if @i_orig_part_type is NULL or @i_add_to_stock_ind is null
  begin
    if @i_orig_part_type is null
      select @i_orig_part_type = @i_type,
        @i_add_to_stock_ind = 1

    if @i_add_to_stock_ind is NULL
      select @i_add_to_stock_ind = case when @i_type = 'M' and @i_orig_part_type = 'P' then 0 else 1 end

    update pur_list
    set add_to_stock_ind = @i_add_to_stock_ind,
      orig_part_type = @i_orig_part_type
    where row_id = @i_row_id and po_no = @i_po_no
  end

  if isnull(@d_add_to_stock_ind,1) != isnull(@i_add_to_stock_ind,1)
  begin
    if exists (select 1 from receipts r (nolock) where po_no = @i_po_no and po_line = @i_line and status < 'S')
      or @i_qty_received > 0
    begin
      select @msg = 'Cannot change add to stock indicator on a purchase line that has received qty or unmatched receipts.'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end

    if isnull(@i_add_to_stock_ind,1) = 0 and @i_type = 'P'
      update pur_list
      set type = 'M',
        orig_part_type = 'P'
      where row_id = @i_row_id and po_no = @i_po_no

    if @i_type = 'M' and isnull(@i_add_to_stock_ind,1) = 1 and @i_orig_part_type = 'P'
      update pur_list
      set type = 'P',
        orig_part_type = 'P',
        add_to_stock_ind = 1
      where row_id = @i_row_id and po_no = @i_po_no

    if @i_type = 'M' and isnull(@i_add_to_stock_ind,1) = 0 and @i_orig_part_type = 'M'
      update pur_list
      set add_to_stock_ind = 1
      where row_id = @i_row_id and po_no = @i_po_no
  end    


  if isnull(@d_account_no,'') = '' and isnull(@i_account_no,'') != ''
  begin
    update pur_list
    set account_no = dbo.adm_mask_acct_fn(@i_account_no, @i_organization_id)
    where po_no = @i_po_no and row_id = @i_row_id
  end 

  if @i_part_no != @d_part_no
  begin
    rollback tran
    exec adm_raiserror 91135, 'You Can Not Change Part Number.. Delete Item!'
    return
  end
  if @i_line != @d_line and @d_line != 0								-- mls 5/9/01 start #2
  begin
	rollback tran
	exec adm_raiserror 91135 ,'You Can Not Change Line Number.. Delete Item!'
	return
  end													-- mls 5/9/01 end #2
  if @i_po_no != @d_po_no
  begin
    rollback tran
    exec adm_raiserror 91136, 'You Can Not Change PO Number.. Delete Item!'
    return
  end

  if NOT (@i_receiving_loc = @d_receiving_loc and @i_type = @d_type 
    and isnull(@i_add_to_stock_ind,1) = isnull(@d_add_to_stock_ind,1)) and @i_type != 'M'
  begin
    IF not exists (SELECT 1 FROM inv_list (nolock)
    WHERE  part_no =  @i_part_no AND location = @i_receiving_loc)
    BEGIN
      rollback tran
      exec adm_raiserror 91101, 'Inventory Part2 Missing.  The transaction is being rolled back.'
      RETURN
    END
  end

  if @l_po_no != @i_po_no
  begin
    if @l_po_no != ''
    begin
      if update(status) and @po_status != 'H'
      begin
        update purchase_all 
        set status=isnull((select min(status) from 
          pur_list where pur_list.po_no = @l_po_no and pur_list.status='O'),'C') 
        where po_no = @l_po_no
      end 
    end

    select @p_prod_no = prod_no,
      @vendor_code = vendor_no,
      @rate_home = curr_factor,
      @rate_oper = oper_factor,
      @po_status = status,
      @po_approval_status = isnull(approval_status,''),				-- mls 7/17/03 SCR 31491
      @po_org_id = isnull(organization_id,''),
      @po_location = location
    from purchase_all (nolock) 
    where po_no = @i_po_no

    if @po_approval_status = 'P' 							-- mls 7/17/03 SCR 31491
    begin	
      rollback tran
      exec adm_raiserror 91139 ,'This purchase order is being processed by eProcurement.  It cannot be changed.'
      return
    end

    if @i_status != 'C'
    begin
      if @po_org_id = ''
        select @po_org_id = dbo.adm_get_locations_org_fn(@po_location)

      if @i_receiving_loc not in (select location from dbo.adm_get_related_locs_fn( 'po',@po_org_id,99)) -- only has to be valid for financials
      begin
        select @msg = 'Location ([' + @i_receiving_loc + ']) is not related to the header Location ([' + @po_location + ']).  Change the po line receiving location'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end 
    end 
  end

  
  if NOT (@i_receiving_loc = @d_receiving_loc)
  begin
    if isnull(@p_prod_no,0) > 0
    begin
      if NOT exists(select 1 from prod_list (nolock)
      where prod_no = @p_prod_no and prod_ext=0 and part_no=@i_part_no and location=@i_receiving_loc)
      begin	
        rollback tran
        exec adm_raiserror 91138, 'Is NOT Listed On Job - Please Add Then Re-Enter.'
        return
      end
    end
	
    update releases 
    set location=@i_receiving_loc 
    where po_no=@i_po_no and part_no=@i_part_no and
      case when isnull(po_line,0)=0 then @i_line else po_line end = @i_line	
      and location != @i_receiving_loc 	
  end

  if @d_unit_measure != @i_unit_measure 
  begin
    if isnull(@d_unit_measure,'') = '' 
    begin
      rollback tran
      exec adm_raiserror 91131 ,'You Cannot have a blank Unit Of Measure!'
      return
    end
    if exists (select 1 from releases (nolock) where po_no = @i_po_no)
    begin
      rollback tran
      exec adm_raiserror 91131, 'You Can Not Change Unit Of Measure! Delete Item Then Insert New Item With Correct Unit Of Measure!'
      return
    end
  end

  if @d_qty_ordered != @i_qty_ordered and @i_status != 'O'
  begin
    rollback tran	
    exec adm_raiserror 91137, 'You Can Not Update Purchase Order Items That Are Closed!'
    RETURN
  end	

  if NOT (@i_curr_cost = @d_curr_cost and @i_qty_ordered = @d_qty_ordered and
    @i_total_tax = @d_total_tax and @i_taxable = @d_taxable)
  BEGIN
    if  ((@d_curr_cost * @d_qty_ordered) - (@d_total_tax * (1-@d_taxable))) -
      ((@i_curr_cost * @i_qty_ordered) - (@i_total_tax * (1-@i_taxable))) != 0
    BEGIN
      UPDATE purchase_all 
      SET total_amt_order= total_amt_order - 
        ((@d_curr_cost * @d_qty_ordered) - (@d_total_tax * (1-@d_taxable))) +
        ((@i_curr_cost * @i_qty_ordered) - (@i_total_tax * (1-@i_taxable)))
      WHERE po_no = @i_po_no 
    END
  END

  
   
  IF @ap_vend_flag = 1 and @po_status > 'M' and 
    NOT (@i_curr_cost = @d_curr_cost and @i_qty_ordered = @d_qty_ordered and
    @i_qty_received = @d_qty_received and @i_status = @d_status) 
  BEGIN
    select 
      @i_amt_net = case when @i_status < 'N' then 0 else 
        (@i_curr_cost * (@i_qty_ordered - @i_qty_received)) end,
      @d_amt_net = case when @d_status < 'N' then 0 else 
        (@d_curr_cost * (@d_qty_ordered - @d_qty_received)) end

    select @i_amt_net = 
      case when @i_amt_net > 0 then @i_amt_net else 0 end -
      case when @d_amt_net > 0 then @d_amt_net else 0 end

    if @i_amt_net > 0
    begin
      SELECT @amt_net_home = (SIGN(@i_amt_net * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + 
        (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(@i_amt_net * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @home_precision))
      SELECT @amt_net_oper = (SIGN(@i_amt_net * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + 
        (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) * ROUND(ABS(@i_amt_net * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) + 0.0000001, @oper_precision))

      IF NOT EXISTS ( SELECT 1 FROM apactvnd WHERE vendor_code = @vendor_code )
      begin
        INSERT apactvnd
        VALUES ( NULL,@vendor_code,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,@amt_net_home,0,'','','', '', 
          '', '', '', 0, 0, 0, 0, 0,0,0,0,0,0,0,'','','','','',0,0,0,0,0,0,0,@amt_net_oper,0,0)
      end
      ELSE
      begin
        UPDATE apactvnd
        SET amt_on_order = amt_on_order + @amt_net_home,
          amt_on_order_oper = amt_on_order_oper + @amt_net_oper
        WHERE vendor_code = @vendor_code
      end

      if @@error <> 0 
      begin
        rollback tran
        exec adm_raiserror 91132, 'Error updating activity tables with new amount.'
        return
      end
    END
  END 

  select @l_po_no = @i_po_no, @l_part_no = @i_part_no

 FETCH NEXT FROM updpurl into
  @i_po_no, @i_part_no, @i_location, @i_type, @i_unit_measure, @i_qty_ordered, @i_qty_received, 
  @i_status, @i_curr_cost, @i_total_tax, @i_taxable, @i_line,@i_shipto_code, @i_receiving_loc, @i_organization_id, @i_row_id,
  @i_account_no, @i_add_to_stock_ind, @i_orig_part_type,
  @d_po_no, @d_part_no, @d_location, @d_type, @d_unit_measure, @d_qty_ordered, @d_qty_received, 
  @d_status, @d_curr_cost, @d_total_tax, @d_taxable, @d_line,@d_shipto_code, @d_receiving_loc, @d_organization_id,
  @d_account_no, @d_add_to_stock_ind, @d_orig_part_type
end 

if @l_po_no != ''
begin
  if update(status) and @po_status != 'H'
  begin
    update purchase_all 
    set status=isnull((select min(status) from 
      pur_list where pur_list.po_no = @l_po_no and pur_list.status='O'),'C') 
    where po_no = @l_po_no
  end 
end

CLOSE updpurl
DEALLOCATE updpurl

END






GO
CREATE NONCLUSTERED INDEX [purl_m1] ON [dbo].[pur_list] ([part_no], [po_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [purlkey] ON [dbo].[pur_list] ([po_key], [line], [part_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [purlist1] ON [dbo].[pur_list] ([po_no], [line], [part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pur_list] TO [public]
GO
GRANT SELECT ON  [dbo].[pur_list] TO [public]
GO
GRANT INSERT ON  [dbo].[pur_list] TO [public]
GO
GRANT DELETE ON  [dbo].[pur_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[pur_list] TO [public]
GO
