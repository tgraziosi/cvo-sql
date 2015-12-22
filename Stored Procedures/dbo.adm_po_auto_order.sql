SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[adm_po_auto_order] @row_id int, @ord int output, @ext int output, @msg varchar(255) OUT
as
declare @rc int, @lrow int, @err int, @cnt int
-- type
-- H - order header
-- L - ord_list
-- R - order release
CREATE TABLE #TxLineInput
(
	control_number		varchar(16),
	reference_number	int,
	tax_code			varchar(8),
	quantity			float,
	extended_price		float,
	discount_amount		float,
	tax_type			smallint,
	currency_code		varchar(8)
)

CREATE TABLE #TxInfo
(	control_number		varchar(16),	sequence_id		int,		tax_type_code		varchar(8),
	amt_taxable		float,		amt_gross		float,		amt_tax			float,
	amt_final_tax		float,		currency_code		varchar(8),	tax_included_flag	smallint	)


create table #TXLineInput_ex(
  row_id int identity,
  control_number varchar(16) not null,
  reference_number int not null,
  trx_type int not null default(0),
  currency_code	varchar(8),
  curr_precision int,
  amt_tax decimal(20,8) default(0),
  amt_final_tax decimal(20,8) default(0),
  tax_code varchar(8),
  freight decimal(20,8) default(0),
  qty decimal(20,8) default(1),
  unit_price decimal(20,8) default(0),
  extended_price decimal(20,8) default(0),
  amt_discount decimal(20,8) default(0),
  err_no int default(0),
  action_flag int default(0),
  seqid int,
  calc_tax decimal(20,8) default(0),
  vat_prc decimal(20,8) default(0),
  amt_nonrecoverable_tax decimal(20,8) default(0),
  amtTaxCalculated decimal(20,8) default(0))

  select @rc = @@error
  if @rc <> 0  
  begin
    select @msg = 'Error (' + convert(varchar,@rc) + ') Creating #TXLineInput_ex temp table'
    return -1
  end

create index adm_ti1 on #TXLineInput_ex(row_id)
create index adm_ti2 on #TXLineInput_ex(control_number, reference_number)

create table #TXtaxtype (
  row_id int identity,
  ttr_row int,
  tax_type varchar(8),
  ext_amt decimal(20,8),
  amt_gross decimal(20,8),
  amt_taxable decimal(20,8),
  amt_tax decimal(20,8),
  amt_final_tax decimal(20,8),
  amt_tax_included decimal(20,8),
  save_flag int,
  tax_rate decimal(20,8),
  prc_flag int,
  prc_type int,
  cents_code_flag int,
  cents_code varchar(8),
  cents_cnt int,
  tax_based_type int,
  tax_included_flag int,
  modify_base_prc decimal(20,8),
  base_range_flag int,
  base_range_type int,
  base_taxed_type int,
  min_base_amt decimal(20,8),
  max_base_amt decimal(20,8),
  tax_range_flag int,
  tax_range_type int,
  min_tax_amt decimal(20,8),
  max_tax_amt decimal(20,8),
  recoverable_flag int,
  dtl_incl_ind int NULL)

  select @rc = @@error
  if @rc <> 0  
  begin
    select @msg = 'Error (' + convert(varchar,@rc) + ') Creating #TXtaxtype temp table'
    return -2
  end

create index adm_tt1 on #TXtaxtype(row_id)
create index adm_tt2 on #TXtaxtype(ttr_row)

create table #TXtaxtyperec (
  row_id int identity,
  tc_row int,
  tax_code varchar(8),
  seq_id int,
  base_id int,
  cur_amt decimal(20,8),
  old_tax decimal(20,8),
  tax_type varchar(8))

  select @rc = @@error
  if @rc <> 0  
  begin
    select @msg = 'Error (' + convert(varchar,@rc) + ') Creating #TXtaxtyperec temp table'
    return -3
  end

create index adm_ttr1 on #TXtaxtyperec(row_id)
create index adm_ttr2 on #TXtaxtyperec(tc_row)
create index adm_ttr3 on #TXtaxtyperec(tax_code, tc_row, seq_id)

create table #TXtaxcode (
  row_id int identity,
  ti_row int,
  control_number varchar(16),
  tax_code varchar(8),
  amt_tax decimal(20,8),
  tax_included_flag int,
  tax_type_cnt int,
  tot_extended_amt decimal(20,8))

  select @rc = @@error
  if @rc <> 0  
  begin
    select @msg = 'Error (' + convert(varchar,@rc) + ') Creating #TXtaxcode temp table'
    return -4
  end

create index adm_tc1 on #TXtaxcode(row_id)
create index adm_tc2 on #TXtaxcode(control_number, tax_code)

create table #TXcents (
  row_id int identity,
  cents_code varchar(8),
  to_cent decimal(20,8),
  tax_cents decimal(20,8))

  select @rc = @@error
  if @rc <> 0  
  begin
    select @msg = 'Error (' + convert(varchar,@rc) + ') Creating #cents temp table'
    return -5
  end

create index c1 on #TXcents(cents_code,row_id)


  create table #ins_order(
  customer_code varchar(10) NULL,
  ship_to varchar(10) NULL,
  ship_to_name varchar(40) NULL,
  addr1 varchar(40) NULL,
  addr2 varchar(40) NULL,
  addr3 varchar(40) NULL,
  addr4 varchar(40) NULL,
  addr5 varchar(40) NULL,
  cust_po varchar(20) NULL,
  back_ord_flag char(1)  NULL,
  location char(10)  NULL,
  req_ship_date datetime  NULL,
  sch_ship_date datetime  NULL,
  note varchar(255) NULL,
  si varchar(255) NULL,
  tax_id varchar(10) NULL,
  routing varchar(20) NULL,
  fob varchar(10) NULL,
  forwarder varchar(10) NULL,
  freight_to varchar(10) NULL,
  freight_allow_type varchar(10) NULL,
  salesperson varchar(10) NULL,
  ship_to_region varchar(10) NULL,
  posting_code varchar(10) NULL,
  remit varchar(10) NULL,
  terms_code varchar(10) NULL,
  dest_zone_code varchar(10) NULL,
  hold_reason varchar(10) NULL,
  attention varchar(40) NULL,
  phone varchar(20) NULL,
  tot_freight decimal(20,8) NULL,
  curr_code varchar(10) NULL,
  city varchar(40) NULL,
  state varchar(40) NULL,
  zip varchar(15) NULL,
  country_cd varchar(3) NULL,
  row_id int identity(1,1))
  
  select @rc = @@error
  if @rc <> 0  
  begin
    select @msg = 'Error (' + convert(varchar,@rc) + ') Creating ins_order temp table'
    return -6
  end

  create table #ins_ord_list_rel (
  list_ind int NULL,
  part_sort varchar(255) NULL,
  orig_part_no varchar(30) NULL,
  part_no varchar(30) NULL,
  location varchar(10) NULL,
  uom char(2) NULL,
  part_type char(1) NULL,
  description varchar(255) NULL,
  price decimal(20,8) NULL,
  price_type char(1) NULL,
  discount decimal(20,8) NULL,
  back_ord_flag char(1) NULL,
  note varchar(255) NULL,
  create_po_ind int NULL,
  gl_rev_acct varchar(32) NULL,
  tax_code varchar(10) NULL,
  reference_code varchar(32) NULL,
  conv_factor decimal(20,8) NULL,
  l_ordered decimal(20,8) NULL,
  sch_ship_date datetime NULL,
  ordered decimal(20,8) NULL,
  cust_po varchar(20) NULL,
  rel_row_id int NULL,
  pr_row_id int NULL,
  row_id int identity(1,1))

  select @rc = @@error
  if @rc <> 0  
  begin
    select @msg = 'Error (' + convert(varchar,@rc) + ') Creating ins_ord_list_rel temp table'
    return -7
  end

  create index iolr1 on #ins_ord_list_rel (list_ind,part_sort,row_id)

  
  if @row_id > 0
  begin
    insert #ins_order (
    customer_code, ship_to, ship_to_name, addr1,addr2,addr3,addr4,addr5,
    cust_po, curr_code,
     back_ord_flag, location, req_ship_date, sch_ship_date, note, si, tax_id, routing, fob,
    forwarder, freight_to, freight_allow_type, salesperson, ship_to_region, posting_code, remit, terms_code,
    dest_zone_code, hold_reason, attention, phone, tot_freight, city, state, zip, country_cd)
    select
    customer_code, '', shipto_name, addr1,addr2,addr3,addr4,addr5, '',curr_key,
     pr_o_back_ord_flag, pr_o_location, pr_o_req_ship_date, pr_o_sch_ship_date, pr_o_note, pr_o_si, pr_o_tax_id, pr_o_routing, pr_o_fob,
    pr_o_forwarder, pr_o_freight_to, pr_o_freight_allow_type, pr_o_salesperson, pr_o_ship_to_region, pr_o_posting_code, pr_o_remit, pr_o_terms_code,
    pr_o_dest_zone_code, pr_o_hold_reason, pr_o_attention, pr_o_phone, pr_o_tot_freight,
    city, state, zip, country_cd
    from adm_req_orders_vw
    where rel_row_id = @row_id and pr_hdr_ind = 1
    
    if @@rowcount = 0
    begin
      select @msg =  'Could not find header record on adm_req_orders_vw view'
      return -101
    end

    exec @rc = adm_ins_order_hdr 1,@@identity,@ord OUTPUT, @ext OUTPUT

    if @rc < 1
    begin
      select @msg = 'Error creating orders record'
      return -102
    end

    declare @cust_sort varchar(300), @vendor varchar(255), @group_no int
    select @cust_sort = cust_sort, @vendor = vendor_org_id,
    @group_no = group_no
    from adm_req_orders_vw
    where rel_row_id = @row_id

    insert #ins_ord_list_rel (
    list_ind, part_sort, orig_part_no, part_no, location, uom, part_type, description, price, price_type, discount,
    back_ord_flag, note, create_po_ind, gl_rev_acct, tax_code, reference_code, conv_factor,
    l_ordered, sch_ship_date, ordered, cust_po, rel_row_id, pr_row_id)
    select pr_list_ind, part_sort, vend_sku,pr_part_no, pr_location, pr_uom, pr_part_type, pr_description, pr_price, pr_price_type, pr_discount,
    pr_back_ord_flag, pr_note, pr_create_po_ind, pr_gl_rev_acct, pr_tax_code, pr_reference_code, pr_conv_factor,
    pr_l_ordered, convert(datetime,convert(varchar(10),pr_sch_ship_date,121) + ' 00:00:00.000'), pr_ordered, cust_po, rel_row_id, pr_row_id
    from adm_req_orders_vw
    where cust_sort = @cust_sort and  vendor_org_id = @vendor and group_no = @group_no


    delete from #ins_ord_list_rel
    where pr_row_id is null

    if not exists(select 1 from #ins_ord_list_rel)
    begin
      select @msg =  'No Order Details found'
      return -103
    end

    exec @rc = adm_ins_ord_list 1, @ord, @ext, 0

    if @rc < 1
    begin
      select @msg =  'Error creating ord_list record'
      return -104
    end


    exec @rc = adm_ins_ord_rel @ord, @ext out

    if @rc < 1
    begin
      select @msg =  'Error creating releases'
      return -105
    end

    update orders_all
    set internal_so_ind = 1
    where order_no = @ord

    select @rc = @@error
    if @rc <> 0
    begin
      select @msg =  'Error (' + convert(varchar,@rc) + ') updating order with internal_so_ind'
      return -106
    end
  

    set @cnt = -1

    while @cnt < @ext
    begin
      select @cnt = @cnt + 1
      EXEC fs_calculate_oetax @ord, @cnt, @err OUT, 0
      exec fs_updordtots @ord, @cnt
    end
		return 1
  end

  select @msg = 'Need to provide a release row id'
  return -999
GO
GRANT EXECUTE ON  [dbo].[adm_po_auto_order] TO [public]
GO
