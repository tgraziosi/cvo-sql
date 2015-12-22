CREATE TABLE [dbo].[purchase_all]
(
[timestamp] [timestamp] NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_of_order] [datetime] NOT NULL,
[date_order_due] [datetime] NULL,
[ship_to_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_address1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_address2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_address3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_address4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_address5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_via] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fob] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attn] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[footing] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blanket] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_amt_order] [decimal] (20, 8) NULL,
[freight] [decimal] (20, 8) NULL,
[date_to_pay] [datetime] NULL,
[discount] [decimal] (20, 8) NULL,
[prepaid_amt] [decimal] (20, 8) NULL,
[vend_inv_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_inv_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_key] [int] NOT NULL,
[po_ext] [int] NULL,
[curr_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_factor] [decimal] (20, 8) NULL CONSTRAINT [DF__purchase___curr___79F25E90] DEFAULT ((1)),
[buyer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[prod_no] [int] NULL CONSTRAINT [DF__purchase___prod___7AE682C9] DEFAULT ((0)),
[oper_factor] [decimal] (20, 8) NULL CONSTRAINT [DF__purchase___oper___7BDAA702] DEFAULT ((1)),
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_tax] [decimal] (20, 8) NULL CONSTRAINT [DF__purchase___total__7CCECB3B] DEFAULT ((0)),
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[expedite_flag] [smallint] NOT NULL,
[vend_order_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[requested_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[approved_by] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_category] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[blanket_flag] [smallint] NOT NULL,
[date_blnk_from] [datetime] NULL,
[date_blnk_to] [datetime] NULL,
[amt_blnk_limit] [float] NULL,
[etransmit_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[approval_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[etransmit_date] [datetime] NULL,
[eprocurement_last_sent_date] [datetime] NULL,
[eprocurement_last_recv_date] [datetime] NULL,
[user_def_fld1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_purchase_user_def_fld1] DEFAULT (''),
[user_def_fld2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_purchase_user_def_fld2] DEFAULT (''),
[user_def_fld3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_purchase_user_def_fld3] DEFAULT (''),
[user_def_fld4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_purchase_user_def_fld4] DEFAULT (''),
[user_def_fld5] [float] NULL CONSTRAINT [DF_purchase_user_def_fld5] DEFAULT ((0.0)),
[user_def_fld6] [float] NULL CONSTRAINT [DF_purchase_user_def_fld6] DEFAULT ((0.0)),
[user_def_fld7] [float] NULL CONSTRAINT [DF_purchase_user_def_fld7] DEFAULT ((0.0)),
[user_def_fld8] [float] NULL CONSTRAINT [DF_purchase_user_def_fld8] DEFAULT ((0.0)),
[user_def_fld9] [int] NULL CONSTRAINT [DF_purchase_user_def_fld9] DEFAULT ((0)),
[user_def_fld10] [int] NULL CONSTRAINT [DF_purchase_user_def_fld10] DEFAULT ((0)),
[user_def_fld11] [int] NULL CONSTRAINT [DF_purchase_user_def_fld11] DEFAULT ((0)),
[user_def_fld12] [int] NULL CONSTRAINT [DF_purchase_user_def_fld12] DEFAULT ((0)),
[one_time_vend_ind] [int] NULL,
[vendor_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[internal_po_ind] [int] NULL,
[ship_country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_valid_ind] [int] NULL,
[addr_valid_ind] [int] NULL,
[vendor_addr_valid_ind] [int] NULL,
[proc_po_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[approval_flag] [smallint] NULL,
[ship_via_method] [smallint] NULL,
[confirm_date] [datetime] NULL,
[departure_date] [datetime] NULL,
[inhouse_date] [datetime] NULL,
[confirmed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delpur] ON [dbo].[purchase_all]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_PUR' and value_str='DISABLE')
	return
else
  if (select count(*) from pur_list, deleted where 
    pur_list.po_no=deleted.po_no and
    pur_list.qty_received > 0) > 0
  begin
    rollback tran
    exec adm_raiserror 71031 ,'You Cannot Delete Purchase Order With Received Items!'
  end

  if exists (select 1 from deleted where isnull(approval_status,'') = 'P')				-- mls 7/17/03 SCR 31491
  begin	
    rollback tran
    exec adm_raiserror 71039, 'This purchase order is being processed by eProcurement.  It cannot be deleted.'
    return
  end

  if exists (select 1 from deleted where etransmit_date is not NULL or isnull(etransmit_status,'') = 'P') -- mls 7/17/03 SCR 31491
  begin	
    rollback tran
    exec adm_raiserror 71039 ,'This purchase order has been or is being transmitted by eProcurement.  It cannot be deleted.'
    return
  end

  delete pur_list 
  from pur_list, deleted 
  where pur_list.po_no=deleted.po_no
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600inspur] ON [dbo].[purchase_all]   FOR INSERT  AS 
BEGIN

if exists (select * from config (nolock) where flag='TRIG_INS_PUR' and value_str='DISABLE') return

DECLARE @i_po_no varchar(16), @i_status char(1), @i_po_type char(2), @i_printed char(1),
@i_vendor_no varchar(12), @i_date_of_order datetime, @i_date_order_due datetime,
@i_ship_to_no varchar(10), @i_ship_name varchar(40), @i_ship_address1 varchar(40),
@i_ship_address2 varchar(40), @i_ship_address3 varchar(40), @i_ship_address4 varchar(40),
@i_ship_address5 varchar(40), @i_ship_city varchar(40), @i_ship_state varchar(40),
@i_ship_zip varchar(15), @i_ship_via varchar(10), @i_fob varchar(10), @i_tax_code varchar(10),
@i_terms varchar(10), @i_attn varchar(30), @i_footing varchar(255), @i_blanket char(1),
@i_who_entered varchar(20), @i_total_amt_order decimal(20,8), @i_freight decimal(20,8),
@i_date_to_pay datetime, @i_discount decimal(20,8), @i_prepaid_amt decimal(20,8),
@i_vend_inv_no varchar(20), @i_email char(1), @i_email_name varchar(20), @i_freight_flag char(1),
@i_freight_vendor varchar(12), @i_freight_inv_no varchar(20), @i_void char(1),
@i_void_who varchar(20), @i_void_date datetime, @i_note varchar(255), @i_po_key int,
@i_po_ext int, @i_curr_key varchar(10), @i_curr_type char(1), @i_curr_factor decimal(20,8),
@i_buyer varchar(10), @i_location varchar(10), @i_prod_no int, @i_oper_factor decimal(20,8),
@i_hold_reason varchar(10), @i_phone varchar(30), @i_total_tax decimal(20,8),
@i_rate_type_home varchar(8), @i_rate_type_oper varchar(8), @i_reference_code varchar(32),
@i_posting_code varchar(8), @i_user_code varchar(8), @i_expedite_flag smallint,
@i_vend_order_no varchar(16), @i_requested_by varchar(40), @i_approved_by varchar(40),
@i_user_category varchar(8), @i_blanket_flag smallint, @i_date_blnk_from datetime,
@i_date_blnk_to datetime, @i_amt_blnk_limit float, @i_organization_id varchar(30),
@i_ship_to_organization_id varchar(30),
@i_addr_valid_ind int, @i_vendor_addr_valid_ind int,
@i_ship_country_cd varchar(3),
@i_one_time_vend_ind int, @i_vendor_addr1 varchar(40), @i_vendor_addr2 varchar(40), 
@i_vendor_addr3 varchar(40), @i_vendor_addr4 varchar(40),
@i_vendor_addr5 varchar(40), @i_vendor_addr6 varchar(40), 
@i_vendor_city varchar(40), @i_vendor_state varchar(40),
@i_vendor_zip varchar(15), @i_vendor_country_cd varchar(3)

Declare @msg varchar(255), @org_id varchar(30)
declare @addr1  varchar(255), @addr2 varchar(255)  , @addr3 varchar(255) , @addr4  varchar(255),
  @addr5 varchar(255) , @addr6 varchar(255) ,
  @city varchar(255), @state varchar(255) , @zip varchar(255) ,
  @country_cd varchar(3), @country varchar(255),
  @rtn int, @rc int

DECLARE t700inspurc_cursor CURSOR LOCAL STATIC FOR
SELECT i.po_no, i.status, i.po_type, i.printed, i.vendor_no, i.date_of_order, i.date_order_due,
i.ship_to_no, i.ship_name, i.ship_address1, i.ship_address2, i.ship_address3, i.ship_address4,
i.ship_address5, i.ship_city, i.ship_state, i.ship_zip, i.ship_via, i.fob, i.tax_code, i.terms,
i.attn, i.footing, i.blanket, i.who_entered, i.total_amt_order, i.freight, i.date_to_pay,
i.discount, i.prepaid_amt, i.vend_inv_no, i.email, i.email_name, i.freight_flag,
i.freight_vendor, i.freight_inv_no, i.void, i.void_who, i.void_date, i.note, i.po_key,
i.po_ext, i.curr_key, i.curr_type, i.curr_factor, i.buyer, i.location, i.prod_no,
i.oper_factor, i.hold_reason, i.phone, i.total_tax, i.rate_type_home, i.rate_type_oper,
i.reference_code, i.posting_code, i.user_code, i.expedite_flag, i.vend_order_no,
i.requested_by, i.approved_by, i.user_category, i.blanket_flag, i.date_blnk_from,
i.date_blnk_to, i.amt_blnk_limit, isnull(i.organization_id,''), isnull(i.ship_to_organization_id,''),
isnull(i.addr_valid_ind,0), isnull(i.vendor_addr_valid_ind,0),
i.ship_country_cd,
isnull(i.one_time_vend_ind,0), i.vendor_addr1, i.vendor_addr2, i.vendor_addr3, i.vendor_addr4,
i.vendor_addr5, i.vendor_addr6, i.vendor_city, i.vendor_state,
i.vendor_zip, i.vendor_country_cd
from inserted i

OPEN t700inspurc_cursor
FETCH NEXT FROM t700inspurc_cursor into
@i_po_no, @i_status, @i_po_type, @i_printed, @i_vendor_no, @i_date_of_order, @i_date_order_due,
@i_ship_to_no, @i_ship_name, @i_ship_address1, @i_ship_address2, @i_ship_address3,
@i_ship_address4, @i_ship_address5, @i_ship_city, @i_ship_state, @i_ship_zip, @i_ship_via,
@i_fob, @i_tax_code, @i_terms, @i_attn, @i_footing, @i_blanket, @i_who_entered,
@i_total_amt_order, @i_freight, @i_date_to_pay, @i_discount, @i_prepaid_amt, @i_vend_inv_no,
@i_email, @i_email_name, @i_freight_flag, @i_freight_vendor, @i_freight_inv_no, @i_void,
@i_void_who, @i_void_date, @i_note, @i_po_key, @i_po_ext, @i_curr_key, @i_curr_type,
@i_curr_factor, @i_buyer, @i_location, @i_prod_no, @i_oper_factor, @i_hold_reason, @i_phone,
@i_total_tax, @i_rate_type_home, @i_rate_type_oper, @i_reference_code, @i_posting_code,
@i_user_code, @i_expedite_flag, @i_vend_order_no, @i_requested_by, @i_approved_by,
@i_user_category, @i_blanket_flag, @i_date_blnk_from, @i_date_blnk_to, @i_amt_blnk_limit,
@i_organization_id, @i_ship_to_organization_id,
@i_addr_valid_ind, @i_vendor_addr_valid_ind,
@i_ship_country_cd,
@i_one_time_vend_ind , @i_vendor_addr1 , @i_vendor_addr2 , 
@i_vendor_addr3 , @i_vendor_addr4 ,
@i_vendor_addr5 , @i_vendor_addr6 , 
@i_vendor_city , @i_vendor_state ,
@i_vendor_zip , @i_vendor_country_cd 

While @@FETCH_STATUS = 0
begin
  if @i_organization_id = ''											-- I/O start
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
      update purchase_all
      set organization_id = @i_organization_id 
      where po_no = @i_po_no and isnull(organization_id,'') != @i_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location) 
    if @i_organization_id != @org_id 
    begin
      select @i_organization_id = @org_id
      update purchase_all
      set organization_id = @i_organization_id 
      where po_no = @i_po_no and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end
  if @i_ship_to_organization_id = ''											-- I/O start
  begin
    select @i_ship_to_organization_id = dbo.adm_get_locations_org_fn(@i_ship_to_no)
    if @i_ship_to_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_ship_to_no + ']).'
      rollback tran
      exec adm_raiserror 832115, @msg
      RETURN
    end
    else
      update purchase_all
      set ship_to_organization_id = @i_ship_to_organization_id 
      where po_no = @i_po_no and isnull(ship_to_organization_id,'') != @i_ship_to_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_ship_to_no) 
    if @i_ship_to_organization_id != @org_id 
    begin
      select @i_ship_to_organization_id = @org_id
      update purchase_all
      set ship_to_organization_id = @i_ship_to_organization_id 
      where po_no = @i_po_no and isnull(ship_to_organization_id,'') != @i_ship_to_organization_id
    end
  end														-- I/O end
  
--  Update pur_list 
--  set location= @i_ship_to_no 
--  where (po_no = @i_po_no) and (location != @i_ship_to_no)

  
  if (@i_prod_no > 0)
  begin
    if NOT exists (select 1 from produce_all (nolock)
      where prod_no = @i_prod_no and prod_ext=0 and status < 'R')
    begin	
      rollback tran
      exec adm_raiserror 81031, 'Not A Valid Job OR Job Is Completed - Please Correct And Re-Enter.'
      return
    end
  end

  if not exists (select 1 from po_usrstat (nolock) where user_stat_code = @i_user_code and -- mls 2/26/03 SCR 30772 start
    status_code = @i_status and isnull(void,'N') = 'N')
  begin
    update p
    set user_code = s.user_stat_code
    from purchase_all p, po_usrstat s
    where p.po_no = @i_po_no
      and s.status_code = @i_status and isnull(s.void,'N') = 'N' and s.default_flag = 1
  end											   -- mls 2/26/03 SCR 30772 end

  if @i_addr_valid_ind = 0
    and exists (select 1 from artax (nolock) where tax_code = @i_tax_code and isnull(tax_connect_flag,0) = 1)
  begin
    select @addr1 = @i_ship_address1,
      @addr2 = @i_ship_address2,
      @addr3 = @i_ship_address3,
      @addr4 = @i_ship_address4,
      @addr5 = @i_ship_address5,
      @addr6 = '',
      @city = '',
      @state = '',
      @zip = '',
      @country_cd = @i_ship_country_cd

    exec @rtn = adm_parse_address 1, 0, 
      @addr1  OUT, @addr2  OUT, @addr3  OUT, @addr4  OUT, @addr5  OUT, @addr6  OUT,
      @city OUT, @state OUT, @zip OUT, @country_cd OUT, @country OUT

    exec @rc = adm_validate_address_wrap 'AP', @addr1 OUT, @addr2 OUT, @addr3 OUT,
      @addr4 OUT, @addr5 OUT, @city OUT, @state OUT, @zip OUT, @country_cd OUT, 0

    if @rtn <> 2 or @rc <> 2 
    begin
      update purchase_all
      set ship_address1 = @addr1,
        ship_address2 = @addr2,
        ship_address3 = @addr3,
        ship_address4 = @addr4,
        ship_address5 = @addr5,
        ship_city = @city,
        ship_state = @state,
        ship_zip = @zip,
        ship_country_cd = @country_cd,
        addr_valid_ind = case when @rc > 0 then 1 else 0 end
      where po_no = @i_po_no
    end
  end
  if @i_vendor_addr_valid_ind = 0 and @i_one_time_vend_ind = 1
    and exists (select 1 from artax (nolock) where tax_code = @i_tax_code and isnull(tax_connect_flag,0) = 1)
  begin
    select @rc = 0, @rtn = 0
    select @addr1 = @i_vendor_addr2,
      @addr2 = @i_vendor_addr3,
      @addr3 = @i_vendor_addr4,
      @addr4 = @i_vendor_addr5,
      @addr5 = @i_vendor_addr6,
      @addr6 = '',
      @city = '',
      @state = '',
      @zip = '',
      @country_cd = @i_vendor_country_cd

    exec @rtn = adm_parse_address 1, 0, 
      @addr1  OUT, @addr2  OUT, @addr3  OUT, @addr4  OUT, @addr5  OUT, @addr6  OUT,
      @city OUT, @state OUT, @zip OUT, @country_cd OUT, @country OUT

    exec @rc = adm_validate_address_wrap @addr1 OUT, @addr2 OUT, @addr3 OUT,
      @addr4 OUT, @addr5 OUT, @city OUT, @state OUT, @zip OUT, @country_cd OUT, 0

    if @rtn <> 2 or @rc <> 2 
    begin
      update purchase_all
      set vendor_addr2 = @addr1,
        vendor_addr3 = @addr2,
        vendor_addr4 = @addr3,
        vendor_addr5 = @addr4,
        vendor_addr6 = @addr5,
        vendor_city = @city,
        vendor_state = @state,
        vendor_zip = @zip,
        vendor_country_cd = @country_cd,
        vendor_addr_valid_ind = case when @rc > 0 then 1 else 0 end
      where po_no = @i_po_no
    end
  end

  FETCH NEXT FROM t700inspurc_cursor into
  @i_po_no, @i_status, @i_po_type, @i_printed, @i_vendor_no, @i_date_of_order, @i_date_order_due,
  @i_ship_to_no, @i_ship_name, @i_ship_address1, @i_ship_address2, @i_ship_address3,
  @i_ship_address4, @i_ship_address5, @i_ship_city, @i_ship_state, @i_ship_zip, @i_ship_via,
  @i_fob, @i_tax_code, @i_terms, @i_attn, @i_footing, @i_blanket, @i_who_entered,
  @i_total_amt_order, @i_freight, @i_date_to_pay, @i_discount, @i_prepaid_amt, @i_vend_inv_no,
  @i_email, @i_email_name, @i_freight_flag, @i_freight_vendor, @i_freight_inv_no, @i_void,
  @i_void_who, @i_void_date, @i_note, @i_po_key, @i_po_ext, @i_curr_key, @i_curr_type,
  @i_curr_factor, @i_buyer, @i_location, @i_prod_no, @i_oper_factor, @i_hold_reason, @i_phone,
  @i_total_tax, @i_rate_type_home, @i_rate_type_oper, @i_reference_code, @i_posting_code,
  @i_user_code, @i_expedite_flag, @i_vend_order_no, @i_requested_by, @i_approved_by,
  @i_user_category, @i_blanket_flag, @i_date_blnk_from, @i_date_blnk_to, @i_amt_blnk_limit,
  @i_organization_id, @i_ship_to_organization_id,
  @i_addr_valid_ind, @i_vendor_addr_valid_ind,
  @i_ship_country_cd,
  @i_one_time_vend_ind , @i_vendor_addr1 , @i_vendor_addr2 , 
  @i_vendor_addr3 , @i_vendor_addr4 ,
  @i_vendor_addr5 , @i_vendor_addr6 , 
  @i_vendor_city , @i_vendor_state ,
  @i_vendor_zip , @i_vendor_country_cd 
end -- while

---- 4/1/14 EL - removed to add to cvo_po_audit
---- inserts audit data for hold information on purchase orders
--INSERT cvopurchaseaudit (movement, po_no, location, o_status, o_user_code, o_hold_reason, n_status, n_user_code, n_hold_reason, user_id, audit_date) SELECT 'ADD' as movement, po_no, location, '' as o_status, '' as o_user_code, '' as o_hold_reason, status as n_status, user_code as n_user_code, hold_reason as n_hold_reason, who_entered as user_id, getdate()
--from inserted 

CLOSE t700inspurc_cursor
DEALLOCATE t700inspurc_cursor
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[t600updpur] ON [dbo].[purchase_all]   FOR UPDATE  AS 
-- Audits created by ELabarbera 11/11/13
-- Departure_date
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'Departure_Date' AS field_name, d.departure_date, i.departure_date, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.po_no = d.po_no
		and i.departure_date<>d.departure_date
-- inhouse_date
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'inhouse_date' AS field_name, d.inhouse_date, i.inhouse_date, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.po_no = d.po_no
		and i.inhouse_date<>d.inhouse_date
-- confirm_date
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'confirm_date_Header' AS field_name, d.confirm_date, i.confirm_date, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.po_no = d.po_no
		and i.confirm_date<>d.confirm_date
-- Expedited_flag
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'Expedite_flag' AS field_name, d.Expedite_flag, i.Expedite_flag, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.po_no = d.po_no
		and i.Expedite_flag<>d.Expedite_flag
-- ATTN
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'ATTN' AS field_name, d.ATTN, i.ATTN, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.po_no = d.po_no
		and i.ATTN<>d.ATTN
-- NOTE
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'NOTE' AS field_name, d.NOTE, i.NOTE, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.po_no = d.po_no
		and i.NOTE<>d.NOTE
-- hold_reason  -- 4/1/14 EL as per TB
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'HOLDREASON' AS field_name, d.hold_reason, i.hold_reason, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.po_no = d.po_no
		and i.hold_reason<>d.hold_reason
-- Status   -- 4/1/14 EL - to get rid of old audit table cvopurchaseaudit
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'Status' AS field_name, d.Status, i.Status, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.po_no = d.po_no
		and i.Status<>d.Status



BEGIN
declare @i_po_no varchar(16), @i_prod_no int, @i_ship_to_no varchar(10), @i_printed char(1), @i_status char(1),
@i_ship_name varchar(40), @i_ship_address1 varchar(40), @i_ship_address2 varchar(40), @i_ship_address3 varchar(40), 
@i_ship_address4 varchar(40), @i_ship_address5 varchar(40), 
@i_user_code varchar(8), @i_approval_status char(1), @i_etransmit_status char(1),
@i_organization_id varchar(30), @i_ship_to_organization_id varchar(30), @i_location varchar(10)
declare @d_po_no varchar(16), @d_prod_no int, @d_ship_to_no varchar(10), @d_printed char(1), @d_status char(1),
@d_ship_name varchar(40), @d_ship_address1 varchar(40), @d_ship_address2 varchar(40), @d_ship_address3 varchar(40), 
@d_ship_address4 varchar(40), @d_ship_address5 varchar(40), 
@d_user_code varchar(8), @d_approval_status char(1), @d_etransmit_status char(1),
@d_organization_id varchar(30), @d_ship_to_organization_id varchar(30),  @d_location varchar(10)


declare @ordno int, @ordext int,
  @msg varchar(255), @org_id varchar(30)

if update(po_no)
begin
  rollback tran
  exec adm_raiserror 91031 ,'You cannot change the po number.'
  return
end

DECLARE updpur CURSOR LOCAL FOR
select i.po_no, isnull(i.prod_no,0), isnull(i.ship_to_no,''), isnull(i.printed,''), isnull(i.status,''),
isnull(i.ship_name,''),isnull(i.ship_address1,''),isnull(i.ship_address2,''),isnull(i.ship_address3,''),
isnull(i.ship_address4,''),isnull(i.ship_address5,''),i.user_code, isnull(i.approval_status,''),
i.etransmit_status, isnull(i.organization_id,''), isnull(i.ship_to_organization_id,''), i.location,
isnull(d.prod_no,''), isnull(d.ship_to_no,''), isnull(d.printed,''), isnull(d.status,''),
isnull(d.ship_name,''),isnull(d.ship_address1,''),isnull(d.ship_address2,''),isnull(d.ship_address3,''),
isnull(d.ship_address4,''),isnull(d.ship_address5,''),d.user_code, isnull(d.approval_status,''),
d.etransmit_status, isnull(i.organization_id,''), isnull(i.ship_to_organization_id,''), d.location
from inserted i, deleted d
where i.po_no = d.po_no

OPEN updpur

FETCH NEXT FROM updpur INTO
@i_po_no, @i_prod_no, @i_ship_to_no, @i_printed, @i_status,
@i_ship_name, @i_ship_address1, @i_ship_address2,@i_ship_address3,@i_ship_address4,@i_ship_address5,
@i_user_code, @i_approval_status, @i_etransmit_status, @i_organization_id, @i_ship_to_organization_id, @i_location,
@d_prod_no, @d_ship_to_no, @d_printed, @d_status,
@d_ship_name, @d_ship_address1, @d_ship_address2, @d_ship_address3, @d_ship_address4, @d_ship_address5,
@d_user_code, @d_approval_status, @d_etransmit_status, @d_organization_id, @d_ship_to_organization_id, @d_location

WHILE @@FETCH_STATUS = 0
begin
  if @i_approval_status = 'P' and @d_approval_status = 'P'				-- mls 7/17/03 SCR 31491
  begin	
    rollback tran
    exec adm_raiserror 91039, 'This purchase order is being processed by eProcurement.  It cannot be changed.'
    return
  end

  if @i_organization_id = ''											-- I/O start
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
      update purchase_all
      set organization_id = @i_organization_id 
      where po_no = @i_po_no and isnull(organization_id,'') != @i_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location) 
    if @i_organization_id != @org_id 
    begin
      if @d_status = 'C'
      begin
        select @msg = 'Organization ([' + @i_organization_id + ']) is not the current organization for Location ([' + @i_location + ']).'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end
      else
      begin
        select @i_organization_id = @org_id
        update purchase_all
        set organization_id = @i_organization_id 
        where po_no = @i_po_no and isnull(organization_id,'') != @i_organization_id
      end
    end
  end														-- I/O end
  if @i_ship_to_organization_id = ''											-- I/O start
  begin
    select @i_ship_to_organization_id = dbo.adm_get_locations_org_fn(@i_ship_to_no)
    if @i_ship_to_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_ship_to_no + ']).'
      rollback tran
      exec adm_raiserror 832115 ,@msg
      RETURN
    end
    else
      update purchase_all
      set ship_to_organization_id = @i_ship_to_organization_id 
      where po_no = @i_po_no and isnull(ship_to_organization_id,'') != @i_ship_to_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_ship_to_no) 
    if @i_ship_to_organization_id != @org_id 
    begin
      if @d_status = 'C'
      begin
        select @msg = 'Organization ([' + @i_ship_to_organization_id + ']) is not the current organization for Location ([' + @i_ship_to_no + ']).'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end
      else
      begin
        select @i_ship_to_organization_id = @org_id
        update purchase_all
        set ship_to_organization_id = @i_ship_to_organization_id 
        where po_no = @i_po_no and isnull(ship_to_organization_id,'') != @i_ship_to_organization_id
      end
    end
  end														-- I/O end
  
  if @i_prod_no != @d_prod_no and @i_prod_no > 0
  begin
    if NOT exists ( select 1 from produce_all (nolock) 
      where prod_no=@i_prod_no and prod_ext = 0 and status < 'R')
    begin	
      rollback tran
      exec adm_raiserror 91031 ,'Not A Valid Job OR Job Is Completed - Please Correct And Re-Enter.'
      return
    end

    if NOT exists ( select 1 from prod_list (nolock), pur_list (nolock)
      where prod_list.prod_no = @i_prod_no and prod_list.prod_ext=0 and 
      prod_list.part_no=pur_list.part_no and prod_list.location=pur_list.receiving_loc )	-- mls 3/12/03 SCR 30821
    begin	
      rollback tran
      exec adm_raiserror 91038 ,'Item Is NOT Listed On Job - Please Add Then Re-Enter.'
      return
    end
  end
      
  if (@i_status != @d_status and @d_status = 'H') or
    (@i_printed != @d_printed and @i_printed = 'Y')
    begin
    Update pur_list 
    set prev_qty = case when @i_printed != @d_printed and @i_printed = 'Y' then qty_ordered else prev_qty end,
      status = case when @i_status != @d_status and @d_status = 'H' and status != 'C' then @i_status else status end      
    where po_no = @i_po_no and
      ((prev_qty != case when @i_printed != @d_printed and @i_printed = 'Y' then qty_ordered else prev_qty end)
      or (status != case when @i_status != @d_status and @d_status = 'H'  and status != 'C' then @i_status else status end))      
  end

  if (@i_status != @d_status and @d_status = 'H') or
    (@i_printed != @d_printed and @i_printed = 'Y')
  begin
    UPDATE releases 
    set prev_qty = case when @i_printed != @d_printed and @i_printed = 'Y' then quantity else prev_qty end,
      status = case when @i_status != @d_status and @d_status = 'H'  and status != 'C' then @i_status else status end      
    WHERE po_no = @i_po_no and
      ((prev_qty != case when @i_printed != @d_printed and @i_printed = 'Y' then quantity else prev_qty end and status != 'C')
      or (status != case when @i_status != @d_status and @d_status = 'H'  and status != 'C' then @i_status else status end))
  end

  if (@i_status != @d_status and @i_status = 'V')
  begin
    update pur_list set status = 'C', void = 'V' where po_no = @i_po_no and status != 'C'
    update releases set status = 'C' where po_no = @i_po_no and status != 'C'
    update purchase set status = 'C', void = 'V', approval_flag = 0 where po_no = @i_po_no
  end
            
  if (@i_status != @d_status) or @i_user_code != @d_user_code or @i_user_code = ''	-- mls 2/26/03 SCR 30772 start
  begin
    if not exists (select 1 from po_usrstat (nolock) where user_stat_code = @i_user_code and
      status_code = @i_status and isnull(void,'N') = 'N')
    begin
      update p
      set user_code = s.user_stat_code
      from purchase_all p, po_usrstat s
      where p.po_no = @i_po_no
        and s.status_code = @i_status and isnull(s.void,'N') = 'N' and s.default_flag = 1
    end
  end										-- mls 2/26/03 SCR 30772 end

  if NOT (@i_ship_name = @d_ship_name and @i_ship_address1 = @d_ship_address1 and
    @i_ship_address2 = @d_ship_address2 and @i_ship_address3 = @d_ship_address3 and 
    @i_ship_address4 = @d_ship_address4 and @i_ship_address5 = @d_ship_address5 ) and
    @i_ship_to_no like 'DROP%'
  begin
    
    select @ordno = isnull( ( select min( o.order_no ) from orders_auto_po o (nolock)
      where o.po_no=@i_po_no),0)
     			
    if ( @ordno > 0 )
    begin
      update orders_auto_po 
      set status='M' 
      where order_no=@ordno and status='P'
      
      select @ordext=( select max( ext ) from orders_all where order_no=@ordno )

      update orders_all 
      set ship_to_name=@i_ship_name,
        ship_to_add_1=@i_ship_address1,
        ship_to_add_2=@i_ship_address2,
        ship_to_add_3=@i_ship_address3,
        ship_to_add_4=@i_ship_address4,
        ship_to_add_5=@i_ship_address5,
        ship_to_city='',
        ship_to_state='',
        ship_to_zip=''
      where order_no=@ordno and ext=@ordext 
         
      update orders_auto_po 
      set status='P' 
      where order_no=@ordno and status='M'
    end 

    update pur_list
    set shipto_name = @i_ship_name,
     addr1 = @i_ship_address1,
     addr2 = @i_ship_address2,
     addr3 = @i_ship_address3,
     addr4 = @i_ship_address4,
     addr5 = @i_ship_address5
    where po_no = @i_po_no and shipto_code = @i_ship_to_no
  end 

  FETCH NEXT FROM updpur INTO
@i_po_no, @i_prod_no, @i_ship_to_no, @i_printed, @i_status,
@i_ship_name, @i_ship_address1, @i_ship_address2,@i_ship_address3,@i_ship_address4,@i_ship_address5,
@i_user_code, @i_approval_status, @i_etransmit_status, @i_organization_id, @i_ship_to_organization_id, @i_location,
@d_prod_no, @d_ship_to_no, @d_printed, @d_status,
@d_ship_name, @d_ship_address1, @d_ship_address2, @d_ship_address3, @d_ship_address4, @d_ship_address5,
@d_user_code, @d_approval_status, @d_etransmit_status, @d_organization_id, @d_ship_to_organization_id, @d_location
END 

CLOSE updpur
DEALLOCATE updpur

---- 4/1/14 EL - removed to add to cvo_po_audit
---- inserts audit data for hold information on purchase orders
--INSERT cvopurchaseaudit (movement, po_no, location, o_status, o_user_code, o_hold_reason, n_status, n_user_code, n_hold_reason, user_id, audit_date) SELECT 'UPD' as movement, i.po_no, i.location, d.status as o_status, d.user_code as o_user_code, d.hold_reason as o_hold_reason, i.status as n_status, i.user_code as n_user_code, i.hold_reason as n_hold_reason, i.who_entered as user_id, getdate()
--from inserted i, deleted d
--where i.po_no = d.po_no


END



GO
CREATE NONCLUSTERED INDEX [purchkey] ON [dbo].[purchase_all] ([po_key]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [purch1] ON [dbo].[purchase_all] ([po_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [purch2] ON [dbo].[purchase_all] ([proc_po_no], [po_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [purchstat] ON [dbo].[purchase_all] ([status], [po_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [purch3] ON [dbo].[purchase_all] ([status], [proc_po_no], [po_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[purchase_all] TO [public]
GO
GRANT SELECT ON  [dbo].[purchase_all] TO [public]
GO
GRANT INSERT ON  [dbo].[purchase_all] TO [public]
GO
GRANT DELETE ON  [dbo].[purchase_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[purchase_all] TO [public]
GO
