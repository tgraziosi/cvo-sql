CREATE TABLE [dbo].[adm_pomchchg_all]
(
[timestamp] [timestamp] NOT NULL,
[match_ctrl_int] [int] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_remit_to] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_invoice_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_match] [datetime] NOT NULL,
[printed_flag] [smallint] NOT NULL,
[vendor_invoice_date] [datetime] NOT NULL,
[invoice_receive_date] [datetime] NOT NULL,
[apply_date] [datetime] NOT NULL,
[aging_date] [datetime] NOT NULL,
[due_date] [datetime] NOT NULL,
[discount_date] [datetime] NOT NULL,
[amt_net] [decimal] (20, 8) NOT NULL,
[amt_discount] [decimal] (20, 8) NOT NULL,
[amt_tax] [decimal] (20, 8) NOT NULL,
[amt_freight] [decimal] (20, 8) NOT NULL,
[amt_misc] [decimal] (20, 8) NOT NULL,
[amt_due] [decimal] (20, 8) NOT NULL,
[match_posted_flag] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_tax_included] [decimal] (20, 8) NOT NULL,
[trx_type] [int] NULL,
[po_no] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_gross] [decimal] (20, 8) NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[curr_factor] [decimal] (20, 8) NULL,
[oper_factor] [decimal] (20, 8) NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_pomch__tax_c__66371554] DEFAULT (''),
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_pomch__terms__672B398D] DEFAULT (''),
[one_time_vend_ind] [int] NULL,
[pay_to_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_nonrecoverable_tax] [decimal] (20, 8) NULL,
[tax_freight_no_recoverable] [decimal] (20, 8) NULL,
[amt_nonrecoverable_incl_tax] [decimal] (20, 8) NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_to_country_cd] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tax_valid_ind] [int] NULL,
[pay_to_addr_valid_ind] [int] NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insmchchg] ON [dbo].[adm_pomchchg_all] FOR insert,update AS 
BEGIN

DECLARE @i_match_ctrl_int int, @i_vendor_code varchar(12), @i_vendor_remit_to char(8),
@i_vendor_invoice_no varchar(20), @i_date_match datetime, @i_printed_flag smallint,
@i_vendor_invoice_date datetime, @i_invoice_receive_date datetime, @i_apply_date datetime,
@i_aging_date datetime, @i_due_date datetime, @i_discount_date datetime,
@i_amt_net decimal(20,8), @i_amt_discount decimal(20,8), @i_amt_tax decimal(20,8),
@i_amt_freight decimal(20,8), @i_amt_misc decimal(20,8), @i_amt_due decimal(20,8),
@i_match_posted_flag smallint, @i_nat_cur_code varchar(8), @i_amt_tax_included decimal(20,8),
@i_trx_type int, @i_po_no int, @i_location varchar(10), @i_amt_gross decimal(20,8),
@i_process_group_num varchar(16), @i_rate_type_home varchar(8), @i_rate_type_oper varchar(8),
@i_curr_factor decimal(20,8), @i_oper_factor decimal(20,8), @i_tax_code varchar(8),
@i_terms_code varchar(8), @i_one_time_vend_ind int, @i_pay_to_addr1 varchar(40),
@i_pay_to_addr2 varchar(40), @i_pay_to_addr3 varchar(40), @i_pay_to_addr4 varchar(40),
@i_pay_to_addr5 varchar(40), @i_pay_to_addr6 varchar(40), @i_attention_name varchar(40),
@i_attention_phone varchar(30), @i_amt_nonrecoverable_tax decimal(20,8),
@i_tax_freight_no_recoverable decimal(20,8), @i_amt_nonrecoverable_incl_tax decimal(20,8),
@i_organization_id varchar(30),
@i_pay_to_city varchar(40), @i_pay_to_state varchar(40), @i_pay_to_zip varchar(15),
@i_pay_to_country_cd varchar(3), @i_tax_valid_ind int, @i_pay_to_addr_valid_ind int,
@d_match_ctrl_int int, @d_vendor_code varchar(12), @d_vendor_remit_to char(8),
@d_vendor_invoice_no varchar(20), @d_date_match datetime, @d_printed_flag smallint,
@d_vendor_invoice_date datetime, @d_invoice_receive_date datetime, @d_apply_date datetime,
@d_aging_date datetime, @d_due_date datetime, @d_discount_date datetime,
@d_amt_net decimal(20,8), @d_amt_discount decimal(20,8), @d_amt_tax decimal(20,8),
@d_amt_freight decimal(20,8), @d_amt_misc decimal(20,8), @d_amt_due decimal(20,8),
@d_match_posted_flag smallint, @d_nat_cur_code varchar(8), @d_amt_tax_included decimal(20,8),
@d_trx_type int, @d_po_no int, @d_location varchar(10), @d_amt_gross decimal(20,8),
@d_process_group_num varchar(16), @d_rate_type_home varchar(8), @d_rate_type_oper varchar(8),
@d_curr_factor decimal(20,8), @d_oper_factor decimal(20,8), @d_tax_code varchar(8),
@d_terms_code varchar(8), @d_one_time_vend_ind int, @d_pay_to_addr1 varchar(40),
@d_pay_to_addr2 varchar(40), @d_pay_to_addr3 varchar(40), @d_pay_to_addr4 varchar(40),
@d_pay_to_addr5 varchar(40), @d_pay_to_addr6 varchar(40), @d_attention_name varchar(40),
@d_attention_phone varchar(30), @d_amt_nonrecoverable_tax decimal(20,8),
@d_tax_freight_no_recoverable decimal(20,8), @d_amt_nonrecoverable_incl_tax decimal(20,8),
@d_organization_id varchar(30),
@d_pay_to_city varchar(40), @d_pay_to_state varchar(40), @d_pay_to_zip varchar(15),
@d_pay_to_country_cd varchar(3), @d_tax_valid_ind int, @d_pay_to_addr_valid_ind int

declare @msg varchar(255), @org_id varchar(30)
declare @addr1  varchar(255), @addr2 varchar(255)  , @addr3 varchar(255) , @addr4  varchar(255),
  @addr5 varchar(255) , @addr6 varchar(255) ,
  @city varchar(255), @state varchar(255) , @zip varchar(255) ,
  @country_cd varchar(3), @country varchar(255),
  @rtn int, @rc int

DECLARE t700updadm__cursor CURSOR LOCAL STATIC FOR
SELECT i.match_ctrl_int, i.vendor_code, i.vendor_remit_to, i.vendor_invoice_no, i.date_match,
i.printed_flag, i.vendor_invoice_date, i.invoice_receive_date, i.apply_date, i.aging_date,
i.due_date, i.discount_date, i.amt_net, i.amt_discount, i.amt_tax, i.amt_freight, i.amt_misc,
i.amt_due, i.match_posted_flag, i.nat_cur_code, i.amt_tax_included, i.trx_type, i.po_no,
i.location, i.amt_gross, i.process_group_num, i.rate_type_home, i.rate_type_oper,
i.curr_factor, i.oper_factor, i.tax_code, i.terms_code, i.one_time_vend_ind, i.pay_to_addr1,
i.pay_to_addr2, i.pay_to_addr3, i.pay_to_addr4, i.pay_to_addr5, i.pay_to_addr6,
i.attention_name, i.attention_phone, i.amt_nonrecoverable_tax, i.tax_freight_no_recoverable,
i.amt_nonrecoverable_incl_tax, isnull(i.organization_id,''),
i.pay_to_city, i.pay_to_state, i.pay_to_zip,
i.pay_to_country_cd, i.tax_valid_ind, isnull(i.pay_to_addr_valid_ind,0),
d.match_ctrl_int, d.vendor_code, d.vendor_remit_to, d.vendor_invoice_no, d.date_match,
d.printed_flag, d.vendor_invoice_date, d.invoice_receive_date, d.apply_date, d.aging_date,
d.due_date, d.discount_date, d.amt_net, d.amt_discount, d.amt_tax, d.amt_freight, d.amt_misc,
d.amt_due, d.match_posted_flag, d.nat_cur_code, d.amt_tax_included, d.trx_type, d.po_no,
d.location, d.amt_gross, d.process_group_num, d.rate_type_home, d.rate_type_oper,
d.curr_factor, d.oper_factor, d.tax_code, d.terms_code, d.one_time_vend_ind, d.pay_to_addr1,
d.pay_to_addr2, d.pay_to_addr3, d.pay_to_addr4, d.pay_to_addr5, d.pay_to_addr6,
d.attention_name, d.attention_phone, d.amt_nonrecoverable_tax, d.tax_freight_no_recoverable,
d.amt_nonrecoverable_incl_tax, d.organization_id,
d.pay_to_city, d.pay_to_state, d.pay_to_zip,
d.pay_to_country_cd, d.tax_valid_ind, isnull(d.pay_to_addr_valid_ind,0)
from inserted i
left outer join deleted d on i.match_ctrl_int = d.match_ctrl_int

OPEN t700updadm__cursor

if @@cursor_rows = 0
begin
CLOSE t700updadm__cursor
DEALLOCATE t700updadm__cursor
return
end

FETCH NEXT FROM t700updadm__cursor into
@i_match_ctrl_int, @i_vendor_code, @i_vendor_remit_to, @i_vendor_invoice_no, @i_date_match,
@i_printed_flag, @i_vendor_invoice_date, @i_invoice_receive_date, @i_apply_date, @i_aging_date,
@i_due_date, @i_discount_date, @i_amt_net, @i_amt_discount, @i_amt_tax, @i_amt_freight,
@i_amt_misc, @i_amt_due, @i_match_posted_flag, @i_nat_cur_code, @i_amt_tax_included,
@i_trx_type, @i_po_no, @i_location, @i_amt_gross, @i_process_group_num, @i_rate_type_home,
@i_rate_type_oper, @i_curr_factor, @i_oper_factor, @i_tax_code, @i_terms_code,
@i_one_time_vend_ind, @i_pay_to_addr1, @i_pay_to_addr2, @i_pay_to_addr3, @i_pay_to_addr4,
@i_pay_to_addr5, @i_pay_to_addr6, @i_attention_name, @i_attention_phone,
@i_amt_nonrecoverable_tax, @i_tax_freight_no_recoverable, @i_amt_nonrecoverable_incl_tax,
@i_organization_id,
@i_pay_to_city, @i_pay_to_state, @i_pay_to_zip, @i_pay_to_country_cd, @i_tax_valid_ind,
@i_pay_to_addr_valid_ind,
@d_match_ctrl_int, @d_vendor_code, @d_vendor_remit_to, @d_vendor_invoice_no, @d_date_match,
@d_printed_flag, @d_vendor_invoice_date, @d_invoice_receive_date, @d_apply_date, @d_aging_date,
@d_due_date, @d_discount_date, @d_amt_net, @d_amt_discount, @d_amt_tax, @d_amt_freight,
@d_amt_misc, @d_amt_due, @d_match_posted_flag, @d_nat_cur_code, @d_amt_tax_included,
@d_trx_type, @d_po_no, @d_location, @d_amt_gross, @d_process_group_num, @d_rate_type_home,
@d_rate_type_oper, @d_curr_factor, @d_oper_factor, @d_tax_code, @d_terms_code,
@d_one_time_vend_ind, @d_pay_to_addr1, @d_pay_to_addr2, @d_pay_to_addr3, @d_pay_to_addr4,
@d_pay_to_addr5, @d_pay_to_addr6, @d_attention_name, @d_attention_phone,
@d_amt_nonrecoverable_tax, @d_tax_freight_no_recoverable, @d_amt_nonrecoverable_incl_tax,
@d_organization_id,
@d_pay_to_city, @d_pay_to_state, @d_pay_to_zip, @d_pay_to_country_cd, @d_tax_valid_ind,
@d_pay_to_addr_valid_ind

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
      update adm_pomchchg_all
      set organization_id = @i_organization_id 
      where match_ctrl_int = @i_match_ctrl_int and isnull(organization_id,'') != @i_organization_id
  end
  else
  begin
    select @org_id = dbo.adm_get_locations_org_fn(@i_location) 
    if @i_organization_id != @org_id and isnull(@d_match_posted_flag,0) != 1
    begin
      select @i_organization_id = @org_id
      update adm_pomchchg_all
      set organization_id = @i_organization_id 
      where match_ctrl_int = @i_match_ctrl_int and isnull(organization_id,'') != @i_organization_id
    end
  end														-- I/O end

  if @i_pay_to_addr_valid_ind = 0 and @i_one_time_vend_ind = 1 and @d_match_ctrl_int is null
    and exists (select 1 from artax (nolock) where tax_code = @i_tax_code and isnull(tax_connect_flag,0) = 1)  
  begin
    select @addr1 = @i_pay_to_addr2,
      @addr2 = @i_pay_to_addr3,
      @addr3 = @i_pay_to_addr4,
      @addr4 = @i_pay_to_addr5,
      @addr5 = @i_pay_to_addr6,
      @addr6 = '',
      @city = '',
      @state = '',
      @zip = '',
      @country_cd = @i_pay_to_country_cd

    exec @rtn = adm_parse_address 1, 0, 
      @addr1  OUT, @addr2  OUT, @addr3  OUT, @addr4  OUT, @addr5  OUT, @addr6  OUT,
      @city OUT, @state OUT, @zip OUT, @country_cd OUT, @country OUT

    exec @rc = adm_validate_address_wrap 'AP', @addr1 OUT, @addr2 OUT, @addr3 OUT,
      @addr4 OUT, @addr5 OUT, @city OUT, @state OUT, @zip OUT, @country_cd OUT, 0

    if @rtn <> 2 or @rc <> 2 
    begin
      update adm_pomchchg_all
      set pay_to_addr2 = @addr1,
        pay_to_addr3 = @addr2,
        pay_to_addr4 = @addr3,
        pay_to_addr5 = @addr4,
        pay_to_addr6 = @addr5,
        pay_to_city = @city,
        pay_to_state = @state,
        pay_to_zip = @zip,
        pay_to_country_cd = @country_cd,
        pay_to_addr_valid_ind = case when @rc > 0 then 1 else 0 end
      where match_ctrl_int = @i_match_ctrl_int
    end
  end

FETCH NEXT FROM t700updadm__cursor into
@i_match_ctrl_int, @i_vendor_code, @i_vendor_remit_to, @i_vendor_invoice_no, @i_date_match,
@i_printed_flag, @i_vendor_invoice_date, @i_invoice_receive_date, @i_apply_date, @i_aging_date,
@i_due_date, @i_discount_date, @i_amt_net, @i_amt_discount, @i_amt_tax, @i_amt_freight,
@i_amt_misc, @i_amt_due, @i_match_posted_flag, @i_nat_cur_code, @i_amt_tax_included,
@i_trx_type, @i_po_no, @i_location, @i_amt_gross, @i_process_group_num, @i_rate_type_home,
@i_rate_type_oper, @i_curr_factor, @i_oper_factor, @i_tax_code, @i_terms_code,
@i_one_time_vend_ind, @i_pay_to_addr1, @i_pay_to_addr2, @i_pay_to_addr3, @i_pay_to_addr4,
@i_pay_to_addr5, @i_pay_to_addr6, @i_attention_name, @i_attention_phone,
@i_amt_nonrecoverable_tax, @i_tax_freight_no_recoverable, @i_amt_nonrecoverable_incl_tax,
@i_organization_id,
@i_pay_to_city, @i_pay_to_state, @i_pay_to_zip, @i_pay_to_country_cd, @i_tax_valid_ind,
@i_pay_to_addr_valid_ind,
@d_match_ctrl_int, @d_vendor_code, @d_vendor_remit_to, @d_vendor_invoice_no, @d_date_match,
@d_printed_flag, @d_vendor_invoice_date, @d_invoice_receive_date, @d_apply_date, @d_aging_date,
@d_due_date, @d_discount_date, @d_amt_net, @d_amt_discount, @d_amt_tax, @d_amt_freight,
@d_amt_misc, @d_amt_due, @d_match_posted_flag, @d_nat_cur_code, @d_amt_tax_included,
@d_trx_type, @d_po_no, @d_location, @d_amt_gross, @d_process_group_num, @d_rate_type_home,
@d_rate_type_oper, @d_curr_factor, @d_oper_factor, @d_tax_code, @d_terms_code,
@d_one_time_vend_ind, @d_pay_to_addr1, @d_pay_to_addr2, @d_pay_to_addr3, @d_pay_to_addr4,
@d_pay_to_addr5, @d_pay_to_addr6, @d_attention_name, @d_attention_phone,
@d_amt_nonrecoverable_tax, @d_tax_freight_no_recoverable, @d_amt_nonrecoverable_incl_tax,
@d_organization_id,
@d_pay_to_city, @d_pay_to_state, @d_pay_to_zip, @d_pay_to_country_cd, @d_tax_valid_ind,
@d_pay_to_addr_valid_ind
end -- while

CLOSE t700updadm__cursor
DEALLOCATE t700updadm__cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [PK_adm_pomchchg_1__10] ON [dbo].[adm_pomchchg_all] ([match_ctrl_int]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [pomchchg_idx1] ON [dbo].[adm_pomchchg_all] ([match_ctrl_int], [vendor_code], [vendor_invoice_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [pomchchg_idx2] ON [dbo].[adm_pomchchg_all] ([match_posted_flag], [process_group_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_pomchchg_all] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_pomchchg_all] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_pomchchg_all] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_pomchchg_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_pomchchg_all] TO [public]
GO
