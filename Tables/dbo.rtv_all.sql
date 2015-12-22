CREATE TABLE [dbo].[rtv_all]
(
[timestamp] [timestamp] NOT NULL,
[rtv_no] [int] NOT NULL,
[vendor_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_of_order] [datetime] NOT NULL,
[date_order_due] [datetime] NULL,
[vend_rma_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
[terms] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attn] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rtv_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[total_amt_order] [decimal] (20, 8) NULL,
[restock_fee] [decimal] (20, 8) NOT NULL,
[freight] [decimal] (20, 8) NOT NULL,
[date_to_pay] [datetime] NULL,
[vend_inv_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_inv_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[post_to_ap] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_amt] [decimal] (20, 8) NULL,
[currency_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_factor] [decimal] (20, 8) NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[oper_factor] [decimal] (20, 8) NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_date] [datetime] NOT NULL,
[doc_date] [datetime] NOT NULL,
[match_ctrl_int] [int] NOT NULL,
[amt_tax_included] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__rtv_all__amt_tax__3D1FF128] DEFAULT ((0)),
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_valid_ind] [int] NULL,
[addr_valid_ind] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insrtv] ON [dbo].[rtv_all] FOR insert AS 
BEGIN
declare @addr1  varchar(255), @addr2 varchar(255)  , @addr3 varchar(255) , @addr4  varchar(255),
  @addr5 varchar(255) , @addr6 varchar(255) ,
  @city varchar(255), @state varchar(255) , @zip varchar(255) ,
  @country_cd varchar(3), @country varchar(255),
  @rtn int, @rc int

DECLARE @i_rtv_no int, @i_vendor_no varchar(12), @i_location varchar(10), @i_status char(1),
@i_printed char(1), @i_date_of_order datetime, @i_date_order_due datetime,
@i_vend_rma_no varchar(20), @i_ship_to_no varchar(10), @i_ship_name varchar(40),
@i_ship_address1 varchar(40), @i_ship_address2 varchar(40), @i_ship_address3 varchar(40),
@i_ship_address4 varchar(40), @i_ship_address5 varchar(40), @i_ship_city varchar(40),
@i_ship_state varchar(40), @i_ship_zip varchar(10), @i_ship_via varchar(10), @i_fob varchar(10),
@i_terms varchar(10), @i_attn varchar(30), @i_rtv_type char(1), @i_who_entered varchar(20),
@i_total_amt_order decimal(20,8), @i_restock_fee decimal(20,8), @i_freight decimal(20,8),
@i_date_to_pay datetime, @i_vend_inv_no varchar(20), @i_freight_flag char(1),
@i_freight_vendor varchar(12), @i_freight_inv_no varchar(20), @i_void char(1),
@i_void_who varchar(20), @i_void_date datetime, @i_post_to_ap char(1), @i_note varchar(255),
@i_tax_code varchar(10), @i_tax_amt decimal(20,8), @i_currency_key varchar(10),
@i_curr_factor decimal(20,8), @i_rate_type_home varchar(8), @i_rate_type_oper varchar(8),
@i_oper_factor decimal(20,8), @i_posting_code varchar(8), @i_apply_date datetime,
@i_doc_date datetime, @i_match_ctrl_int int, @i_amt_tax_included decimal(20,8),
@i_organization_id varchar(30),
@i_ship_to_country_cd varchar(3), @i_tax_valid_ind int, @i_addr_valid_ind int

declare @msg varchar(255), @org_id varchar(30)

DECLARE t700insrtv_cursor CURSOR LOCAL STATIC FOR
SELECT i.rtv_no, i.vendor_no, i.location, i.status, i.printed, i.date_of_order, i.date_order_due,
i.vend_rma_no, i.ship_to_no, i.ship_name, i.ship_address1, i.ship_address2, i.ship_address3,
i.ship_address4, i.ship_address5, i.ship_city, i.ship_state, i.ship_zip, i.ship_via, i.fob,
i.terms, i.attn, i.rtv_type, i.who_entered, i.total_amt_order, i.restock_fee, i.freight,
i.date_to_pay, i.vend_inv_no, i.freight_flag, i.freight_vendor, i.freight_inv_no, i.void,
i.void_who, i.void_date, i.post_to_ap, i.note, i.tax_code, i.tax_amt, i.currency_key,
i.curr_factor, i.rate_type_home, i.rate_type_oper, i.oper_factor, i.posting_code, i.apply_date,
i.doc_date, i.match_ctrl_int, i.amt_tax_included, isnull(i.organization_id,''),
i.ship_to_country_cd, i.tax_valid_ind, isnull(i.addr_valid_ind,0)
from inserted i

OPEN t700insrtv_cursor

if @@cursor_rows = 0
begin
CLOSE t700insrtv_cursor
DEALLOCATE t700insrtv_cursor
return
end

FETCH NEXT FROM t700insrtv_cursor into
@i_rtv_no, @i_vendor_no, @i_location, @i_status, @i_printed, @i_date_of_order, @i_date_order_due,
@i_vend_rma_no, @i_ship_to_no, @i_ship_name, @i_ship_address1, @i_ship_address2,
@i_ship_address3, @i_ship_address4, @i_ship_address5, @i_ship_city, @i_ship_state, @i_ship_zip,
@i_ship_via, @i_fob, @i_terms, @i_attn, @i_rtv_type, @i_who_entered, @i_total_amt_order,
@i_restock_fee, @i_freight, @i_date_to_pay, @i_vend_inv_no, @i_freight_flag, @i_freight_vendor,
@i_freight_inv_no, @i_void, @i_void_who, @i_void_date, @i_post_to_ap, @i_note, @i_tax_code,
@i_tax_amt, @i_currency_key, @i_curr_factor, @i_rate_type_home, @i_rate_type_oper,
@i_oper_factor, @i_posting_code, @i_apply_date, @i_doc_date, @i_match_ctrl_int,
@i_amt_tax_included, @i_organization_id,
@i_ship_to_country_cd, @i_tax_valid_ind, @i_addr_valid_ind

While @@FETCH_STATUS = 0
begin
  if @i_organization_id = ''											-- I/O start
  begin
    select @i_organization_id = dbo.adm_get_locations_org_fn(@i_location)
    if @i_organization_id = ''
    begin
      select @msg = 'Organization not defined for Location ([' + @i_location + ']).'
      rollback tran
      exec adm_raiserror 832115 ,@msg
      RETURN
    end
    else
      update rtv_all
      set organization_id = @i_organization_id 
      where rtv_no = @i_rtv_no and isnull(organization_id,'') != @i_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location) 
    if @i_organization_id != @org_id 
    begin
      select @i_organization_id = @org_id
      update rtv_all
      set organization_id = @i_organization_id 
      where rtv_no = @i_rtv_no and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end

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
      @country_cd = @i_ship_to_country_cd

    exec @rtn = adm_parse_address 1, 0, 
      @addr1  OUT, @addr2  OUT, @addr3  OUT, @addr4  OUT, @addr5  OUT, @addr6  OUT,
      @city OUT, @state OUT, @zip OUT, @country_cd OUT, @country OUT

    exec @rc = adm_validate_address_wrap 'AP', @addr1 OUT, @addr2 OUT, @addr3 OUT,
      @addr4 OUT, @addr5 OUT, @city OUT, @state OUT, @zip OUT, @country_cd OUT, 0

    if @rtn <> 2 or @rc <> 2 
    begin
      update rtv_all
      set ship_address1 = @addr1,
        ship_address2 = @addr2,
        ship_address3 = @addr3,
        ship_address4 = @addr4,
        ship_address5 = @addr5,
        ship_city = @city,
        ship_state = @state,
        ship_zip = @zip,
        ship_to_country_cd = @country_cd,
        addr_valid_ind = case when @rc > 0 then 1 else 0 end
      where rtv_no = @i_rtv_no 
    end

  end


FETCH NEXT FROM t700insrtv_cursor into
@i_rtv_no, @i_vendor_no, @i_location, @i_status, @i_printed, @i_date_of_order, @i_date_order_due,
@i_vend_rma_no, @i_ship_to_no, @i_ship_name, @i_ship_address1, @i_ship_address2,
@i_ship_address3, @i_ship_address4, @i_ship_address5, @i_ship_city, @i_ship_state, @i_ship_zip,
@i_ship_via, @i_fob, @i_terms, @i_attn, @i_rtv_type, @i_who_entered, @i_total_amt_order,
@i_restock_fee, @i_freight, @i_date_to_pay, @i_vend_inv_no, @i_freight_flag, @i_freight_vendor,
@i_freight_inv_no, @i_void, @i_void_who, @i_void_date, @i_post_to_ap, @i_note, @i_tax_code,
@i_tax_amt, @i_currency_key, @i_curr_factor, @i_rate_type_home, @i_rate_type_oper,
@i_oper_factor, @i_posting_code, @i_apply_date, @i_doc_date, @i_match_ctrl_int,
@i_amt_tax_included, @i_organization_id,
@i_ship_to_country_cd, @i_tax_valid_ind, @i_addr_valid_ind
end -- while

CLOSE t700insrtv_cursor
DEALLOCATE t700insrtv_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updrtv] ON [dbo].[rtv_all] FOR update AS 
BEGIN

if update(rtv_no)
begin
  rollback tran
  exec adm_raiserror 91031 ,'You cannot change the rtv number.'
  return
end

DECLARE @i_rtv_no int, @i_vendor_no varchar(12), @i_location varchar(10), @i_status char(1),
@i_printed char(1), @i_date_of_order datetime, @i_date_order_due datetime,
@i_vend_rma_no varchar(20), @i_ship_to_no varchar(10), @i_ship_name varchar(40),
@i_ship_address1 varchar(40), @i_ship_address2 varchar(40), @i_ship_address3 varchar(40),
@i_ship_address4 varchar(40), @i_ship_address5 varchar(40), @i_ship_city varchar(40),
@i_ship_state varchar(40), @i_ship_zip varchar(10), @i_ship_via varchar(10), @i_fob varchar(10),
@i_terms varchar(10), @i_attn varchar(30), @i_rtv_type char(1), @i_who_entered varchar(20),
@i_total_amt_order decimal(20,8), @i_restock_fee decimal(20,8), @i_freight decimal(20,8),
@i_date_to_pay datetime, @i_vend_inv_no varchar(20), @i_freight_flag char(1),
@i_freight_vendor varchar(12), @i_freight_inv_no varchar(20), @i_void char(1),
@i_void_who varchar(20), @i_void_date datetime, @i_post_to_ap char(1), @i_note varchar(255),
@i_tax_code varchar(10), @i_tax_amt decimal(20,8), @i_currency_key varchar(10),
@i_curr_factor decimal(20,8), @i_rate_type_home varchar(8), @i_rate_type_oper varchar(8),
@i_oper_factor decimal(20,8), @i_posting_code varchar(8), @i_apply_date datetime,
@i_doc_date datetime, @i_match_ctrl_int int, @i_amt_tax_included decimal(20,8),
@i_organization_id varchar(30)
declare
@d_rtv_no int, @d_vendor_no varchar(12), @d_location varchar(10), @d_status char(1),
@d_printed char(1), @d_date_of_order datetime, @d_date_order_due datetime,
@d_vend_rma_no varchar(20), @d_ship_to_no varchar(10), @d_ship_name varchar(40),
@d_ship_address1 varchar(40), @d_ship_address2 varchar(40), @d_ship_address3 varchar(40),
@d_ship_address4 varchar(40), @d_ship_address5 varchar(40), @d_ship_city varchar(40),
@d_ship_state varchar(40), @d_ship_zip varchar(10), @d_ship_via varchar(10), @d_fob varchar(10),
@d_terms varchar(10), @d_attn varchar(30), @d_rtv_type char(1), @d_who_entered varchar(20),
@d_total_amt_order decimal(20,8), @d_restock_fee decimal(20,8), @d_freight decimal(20,8),
@d_date_to_pay datetime, @d_vend_inv_no varchar(20), @d_freight_flag char(1),
@d_freight_vendor varchar(12), @d_freight_inv_no varchar(20), @d_void char(1),
@d_void_who varchar(20), @d_void_date datetime, @d_post_to_ap char(1), @d_note varchar(255),
@d_tax_code varchar(10), @d_tax_amt decimal(20,8), @d_currency_key varchar(10),
@d_curr_factor decimal(20,8), @d_rate_type_home varchar(8), @d_rate_type_oper varchar(8),
@d_oper_factor decimal(20,8), @d_posting_code varchar(8), @d_apply_date datetime,
@d_doc_date datetime, @d_match_ctrl_int int, @d_amt_tax_included decimal(20,8),
@d_organization_id varchar(30)

declare @msg varchar(255), @org_id varchar(30)

DECLARE t700updrtv__cursor CURSOR LOCAL STATIC FOR
SELECT i.rtv_no, i.vendor_no, i.location, i.status, i.printed, i.date_of_order, i.date_order_due,
i.vend_rma_no, i.ship_to_no, i.ship_name, i.ship_address1, i.ship_address2, i.ship_address3,
i.ship_address4, i.ship_address5, i.ship_city, i.ship_state, i.ship_zip, i.ship_via, i.fob,
i.terms, i.attn, i.rtv_type, i.who_entered, i.total_amt_order, i.restock_fee, i.freight,
i.date_to_pay, i.vend_inv_no, i.freight_flag, i.freight_vendor, i.freight_inv_no, i.void,
i.void_who, i.void_date, i.post_to_ap, i.note, i.tax_code, i.tax_amt, i.currency_key,
i.curr_factor, i.rate_type_home, i.rate_type_oper, i.oper_factor, i.posting_code, i.apply_date,
i.doc_date, i.match_ctrl_int, i.amt_tax_included, isnull(i.organization_id,''),
d.rtv_no, d.vendor_no, d.location, d.status, d.printed, d.date_of_order, d.date_order_due,
d.vend_rma_no, d.ship_to_no, d.ship_name, d.ship_address1, d.ship_address2, d.ship_address3,
d.ship_address4, d.ship_address5, d.ship_city, d.ship_state, d.ship_zip, d.ship_via, d.fob,
d.terms, d.attn, d.rtv_type, d.who_entered, d.total_amt_order, d.restock_fee, d.freight,
d.date_to_pay, d.vend_inv_no, d.freight_flag, d.freight_vendor, d.freight_inv_no, d.void,
d.void_who, d.void_date, d.post_to_ap, d.note, d.tax_code, d.tax_amt, d.currency_key,
d.curr_factor, d.rate_type_home, d.rate_type_oper, d.oper_factor, d.posting_code, d.apply_date,
d.doc_date, d.match_ctrl_int, d.amt_tax_included, isnull(d.organization_id,'')
from inserted i, deleted d
where i.rtv_no = d.rtv_no

OPEN t700updrtv__cursor

if @@cursor_rows = 0
begin
CLOSE t700updrtv__cursor
DEALLOCATE t700updrtv__cursor
return
end

FETCH NEXT FROM t700updrtv__cursor into
@i_rtv_no, @i_vendor_no, @i_location, @i_status, @i_printed, @i_date_of_order, @i_date_order_due,
@i_vend_rma_no, @i_ship_to_no, @i_ship_name, @i_ship_address1, @i_ship_address2,
@i_ship_address3, @i_ship_address4, @i_ship_address5, @i_ship_city, @i_ship_state, @i_ship_zip,
@i_ship_via, @i_fob, @i_terms, @i_attn, @i_rtv_type, @i_who_entered, @i_total_amt_order,
@i_restock_fee, @i_freight, @i_date_to_pay, @i_vend_inv_no, @i_freight_flag, @i_freight_vendor,
@i_freight_inv_no, @i_void, @i_void_who, @i_void_date, @i_post_to_ap, @i_note, @i_tax_code,
@i_tax_amt, @i_currency_key, @i_curr_factor, @i_rate_type_home, @i_rate_type_oper,
@i_oper_factor, @i_posting_code, @i_apply_date, @i_doc_date, @i_match_ctrl_int,
@i_amt_tax_included, @i_organization_id,
@d_rtv_no, @d_vendor_no, @d_location, @d_status, @d_printed, @d_date_of_order, @d_date_order_due,
@d_vend_rma_no, @d_ship_to_no, @d_ship_name, @d_ship_address1, @d_ship_address2,
@d_ship_address3, @d_ship_address4, @d_ship_address5, @d_ship_city, @d_ship_state, @d_ship_zip,
@d_ship_via, @d_fob, @d_terms, @d_attn, @d_rtv_type, @d_who_entered, @d_total_amt_order,
@d_restock_fee, @d_freight, @d_date_to_pay, @d_vend_inv_no, @d_freight_flag, @d_freight_vendor,
@d_freight_inv_no, @d_void, @d_void_who, @d_void_date, @d_post_to_ap, @d_note, @d_tax_code,
@d_tax_amt, @d_currency_key, @d_curr_factor, @d_rate_type_home, @d_rate_type_oper,
@d_oper_factor, @d_posting_code, @d_apply_date, @d_doc_date, @d_match_ctrl_int,
@d_amt_tax_included, @d_organization_id

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
      update rtv_all
      set organization_id = @i_organization_id 
      where rtv_no = @i_rtv_no and isnull(organization_id,'') != @i_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location) 
    if @i_organization_id != @org_id 
    begin
      select @i_organization_id = @org_id
      update rtv_all
      set organization_id = @i_organization_id 
      where rtv_no = @i_rtv_no and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end


FETCH NEXT FROM t700updrtv__cursor into
@i_rtv_no, @i_vendor_no, @i_location, @i_status, @i_printed, @i_date_of_order, @i_date_order_due,
@i_vend_rma_no, @i_ship_to_no, @i_ship_name, @i_ship_address1, @i_ship_address2,
@i_ship_address3, @i_ship_address4, @i_ship_address5, @i_ship_city, @i_ship_state, @i_ship_zip,
@i_ship_via, @i_fob, @i_terms, @i_attn, @i_rtv_type, @i_who_entered, @i_total_amt_order,
@i_restock_fee, @i_freight, @i_date_to_pay, @i_vend_inv_no, @i_freight_flag, @i_freight_vendor,
@i_freight_inv_no, @i_void, @i_void_who, @i_void_date, @i_post_to_ap, @i_note, @i_tax_code,
@i_tax_amt, @i_currency_key, @i_curr_factor, @i_rate_type_home, @i_rate_type_oper,
@i_oper_factor, @i_posting_code, @i_apply_date, @i_doc_date, @i_match_ctrl_int,
@i_amt_tax_included, @i_organization_id,
@d_rtv_no, @d_vendor_no, @d_location, @d_status, @d_printed, @d_date_of_order, @d_date_order_due,
@d_vend_rma_no, @d_ship_to_no, @d_ship_name, @d_ship_address1, @d_ship_address2,
@d_ship_address3, @d_ship_address4, @d_ship_address5, @d_ship_city, @d_ship_state, @d_ship_zip,
@d_ship_via, @d_fob, @d_terms, @d_attn, @d_rtv_type, @d_who_entered, @d_total_amt_order,
@d_restock_fee, @d_freight, @d_date_to_pay, @d_vend_inv_no, @d_freight_flag, @d_freight_vendor,
@d_freight_inv_no, @d_void, @d_void_who, @d_void_date, @d_post_to_ap, @d_note, @d_tax_code,
@d_tax_amt, @d_currency_key, @d_curr_factor, @d_rate_type_home, @d_rate_type_oper,
@d_oper_factor, @d_posting_code, @d_apply_date, @d_doc_date, @d_match_ctrl_int,
@d_amt_tax_included, @d_organization_id
end -- while

CLOSE t700updrtv__cursor
DEALLOCATE t700updrtv__cursor

END
GO
CREATE NONCLUSTERED INDEX [rtv2] ON [dbo].[rtv_all] ([match_ctrl_int], [rtv_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [rtv1] ON [dbo].[rtv_all] ([rtv_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rtv_all] TO [public]
GO
GRANT SELECT ON  [dbo].[rtv_all] TO [public]
GO
GRANT INSERT ON  [dbo].[rtv_all] TO [public]
GO
GRANT DELETE ON  [dbo].[rtv_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[rtv_all] TO [public]
GO
