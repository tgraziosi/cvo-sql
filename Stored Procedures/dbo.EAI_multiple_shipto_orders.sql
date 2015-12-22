SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[EAI_multiple_shipto_orders] @order_no int,
                                            @ext int
AS

DECLARE @result                 int,
	@ship_to		varchar(10),
	@line_ext		int


BEGIN

DECLARE  @location_def varchar(10)


if exists ( select value_str from config (nolock) where flag='EAI_LOC') 
  SELECT @location_def = value_str from config (nolock) where flag='EAI_LOC'



CREATE TABLE #ord_list_temp (
	order_no int NOT NULL ,
	order_ext int NOT NULL ,
	line_no int NOT NULL ,
	location varchar (10) NULL ,
	part_no varchar (30) NOT NULL ,
	description varchar (255) NULL ,
	time_entered datetime NOT NULL ,
	ordered decimal(20, 8) NOT NULL ,
	shipped decimal(20, 8) NOT NULL ,
	price decimal(20, 8) NOT NULL ,
	price_type char (1) NULL ,
	note varchar (255) NULL ,
	status char (1) NOT NULL ,
	cost decimal(20, 8) NOT NULL ,
	who_entered varchar (20) NULL ,
	sales_comm decimal(20, 8) NOT NULL ,
	temp_price decimal(20, 8) NULL ,
	temp_type char (1) NULL ,
	cr_ordered decimal(20, 8) NOT NULL ,
	cr_shipped decimal(20, 8) NOT NULL ,
	discount decimal(20, 8) NOT NULL ,
	uom char (2) NULL ,
	conv_factor decimal(20, 8) NOT NULL ,
	void char (1) NULL ,
	void_who varchar (20) NULL ,
	void_date datetime NULL ,
	std_cost decimal(20, 8) NOT NULL ,
	cubic_feet decimal(20, 8) NOT NULL ,
	printed char (1) NULL ,
	lb_tracking char (1) NULL  ,
	labor decimal(20, 8) NOT NULL ,
	direct_dolrs decimal(20, 8) NOT NULL ,
	ovhd_dolrs decimal(20, 8) NOT NULL ,
	util_dolrs decimal(20, 8) NOT NULL ,
	taxable int NULL ,
	weight_ea decimal(20, 8) NULL ,
	qc_flag char (1) ,
	reason_code varchar (10) NULL ,
	qc_no int NULL ,
	rejected decimal(20, 8) NULL ,
	part_type char (1) NULL ,
	orig_part_no varchar (30) NULL ,
	back_ord_flag char (1) NULL ,
	gl_rev_acct varchar (32) NULL ,
	total_tax decimal(20, 8) NOT NULL ,
	tax_code varchar (10) NULL ,
	curr_price decimal(20, 8) NOT NULL ,
	oper_price decimal(20, 8) NOT NULL ,
	display_line int NOT NULL ,
	std_direct_dolrs decimal(20, 8) NULL ,
	std_ovhd_dolrs decimal(20, 8) NULL ,
	std_util_dolrs decimal(20, 8) NULL ,
	reference_code varchar (32) NULL ,
	contract varchar (16) NULL,
	agreement_id varchar(32) NULL,
 	ship_to varchar(10) NULL,
	service_agreement_flag char(1) ,
	inv_available_flag char(1) ,
	create_po_flag		smallint NULL,
	load_group_no		int NULL,
	return_code		varchar(10) NULL, 
	user_count		int NULL,
    cust_po   varchar(20) NULL,
	organization_id varchar(30) NULL,
	picked_dt datetime NULL,
	who_picked_id varchar(30) NULL,
	printed_dt datetime NULL,
	who_unpicked_id varchar(30) NULL,
	unpicked_dt datetime NULL	
)

CREATE TABLE #ord_list (
	order_no int NOT NULL ,
	order_ext int NOT NULL ,
	line_no int NOT NULL ,
	location varchar (10) NULL ,
	part_no varchar (30) NOT NULL ,
	description varchar (255) NULL ,
	time_entered datetime NOT NULL ,
	ordered decimal(20, 8) NOT NULL ,
	shipped decimal(20, 8) NOT NULL ,
	price decimal(20, 8) NOT NULL ,
	price_type char (1) NULL ,
	note varchar (255) NULL ,
	status char (1) NOT NULL ,
	cost decimal(20, 8) NOT NULL ,
	who_entered varchar (20) NULL ,
	sales_comm decimal(20, 8) NOT NULL ,
	temp_price decimal(20, 8) NULL ,
	temp_type char (1) NULL ,
	cr_ordered decimal(20, 8) NOT NULL ,
	cr_shipped decimal(20, 8) NOT NULL ,
	discount decimal(20, 8) NOT NULL ,
	uom char (2) NULL ,
	conv_factor decimal(20, 8) NOT NULL ,
	void char (1) NULL ,
	void_who varchar (20) NULL ,
	void_date datetime NULL ,
	std_cost decimal(20, 8) NOT NULL ,
	cubic_feet decimal(20, 8) NOT NULL ,
	printed char (1) NULL ,
	lb_tracking char (1) NULL  ,
	labor decimal(20, 8) NOT NULL ,
	direct_dolrs decimal(20, 8) NOT NULL ,
	ovhd_dolrs decimal(20, 8) NOT NULL ,
	util_dolrs decimal(20, 8) NOT NULL ,
	taxable int NULL ,
	weight_ea decimal(20, 8) NULL ,
	qc_flag char (1) ,
	reason_code varchar (10) NULL ,
	qc_no int NULL ,
	rejected decimal(20, 8) NULL ,
	part_type char (1) NULL ,
	orig_part_no varchar (30) NULL ,
	back_ord_flag char (1) NULL ,
	gl_rev_acct varchar (32) NULL ,
	total_tax decimal(20, 8) NOT NULL ,
	tax_code varchar (10) NULL ,
	curr_price decimal(20, 8) NOT NULL ,
	oper_price decimal(20, 8) NOT NULL ,
	display_line int IDENTITY NOT NULL ,
	std_direct_dolrs decimal(20, 8) NULL ,
	std_ovhd_dolrs decimal(20, 8) NULL ,
	std_util_dolrs decimal(20, 8) NULL ,
	reference_code varchar (32) NULL ,
	contract varchar (16) NULL,
	agreement_id varchar(32) NULL,
 	ship_to varchar(10) NULL,
	service_agreement_flag char(1) ,
	inv_available_flag char(1) ,
	create_po_flag	smallint NULL,
	load_group_no	int NULL,
	return_code	varchar(10) NULL, 
	user_count	int NULL,
    cust_po   varchar(20) NULL,
	organization_id varchar(30) NULL,
	picked_dt datetime NULL,
	who_picked_id varchar(30) NULL,
	printed_dt datetime NULL,
	who_unpicked_id varchar(30) NULL,
	unpicked_dt datetime NULL	
)

CREATE TABLE #orders(
	  order_no     int   NOT NULL,
	  ext          int   NOT NULL,
	  cust_code    varchar(10) NOT NULL,
	  ship_to      varchar(10) NULL,
	  req_ship_date   datetime   NOT NULL,
	  sch_ship_date   datetime   NULL,
	  date_shipped    datetime   NULL,
	  date_entered    datetime   NOT NULL,
	  cust_po         varchar(20) NULL,
	  who_entered     varchar(20) NULL,
	  status          char(1) NOT NULL,
	  attention       varchar(40) NULL,
	  phone           varchar(20) NULL,
	  terms           varchar(10) NULL,
	  routing     varchar(20) NULL,
	  special_instr     varchar(255) NULL,
	  invoice_date     datetime   NULL,
	  total_invoice     decimal(20, 8) NOT NULL,
	  total_amt_order     decimal(20, 8) NOT NULL,
	  salesperson     varchar(10) NULL,
	  tax_id     varchar(10) NOT NULL,
	  tax_perc     decimal(20, 8) NOT NULL,
	  invoice_no     int   NULL,
	  fob     varchar(10) NULL,
	  freight     decimal(20, 8) NULL,
	  printed     char(1) NULL,
	  discount     decimal(20, 8) NULL,
	  label_no     int   NULL,
	  cancel_date     datetime   NULL,
	  new     char(1) NULL,
	  ship_to_name     varchar(40) NULL,
	  ship_to_add_1     varchar(40) NULL,
	  ship_to_add_2     varchar(40) NULL,
	  ship_to_add_3     varchar(40) NULL,
	  ship_to_add_4     varchar(40) NULL,
	  ship_to_add_5     varchar(40) NULL,
	  ship_to_city     varchar(40) NULL,
	  ship_to_state     varchar(40) NULL,
	  ship_to_zip     varchar(15) NULL,
	  ship_to_country     varchar(40) NULL,
	  ship_to_region     varchar(10) NULL,
	  cash_flag     char(1) NULL,
	  type     char(1) NOT NULL,
	  back_ord_flag     char(1) NULL,
	  freight_allow_pct     decimal(20, 8) NULL,
	  route_code     varchar(10) NULL,
	  route_no     decimal(20, 8) NULL,
	  date_printed     datetime   NULL,
	  date_transfered     datetime   NULL,
	  cr_invoice_no     int   NULL,
	  who_picked     varchar(20) NULL,
	  note     varchar(255) NULL,
	  void     char(1) NULL,
	  void_who     varchar(20) NULL,
	  void_date     datetime   NULL,
	  changed     char(1) NULL,
	  remit_key     varchar(10) NULL,
	  forwarder_key     varchar(10) NULL,
	  freight_to     varchar(10) NULL,
	  sales_comm     decimal(20, 8) NULL,
	  freight_allow_type     varchar(10) NULL,
	  cust_dfpa     char(1) NULL,
	  location     varchar(10) NULL,
	  total_tax     decimal(20, 8) NULL,
	  total_discount     decimal(20, 8) NULL,
	  f_note     varchar(200) NULL,
	  invoice_edi     char(1) NULL,
	  edi_batch     varchar(10) NULL,
	  post_edi_date     datetime   NULL,
	  blanket     char(1) NULL,
	  gross_sales     decimal(20, 8) NULL,
	  load_no     int   NULL,
	  curr_key     varchar(10) NULL,
	  curr_type     char(1) NULL,
	  curr_factor     decimal(20, 8) NULL,
	  bill_to_key     varchar(10) NULL,
	  oper_factor     decimal(20, 8) NULL,
	  tot_ord_tax     decimal(20, 8) NULL,
	  tot_ord_disc     decimal(20, 8) NULL,
	  tot_ord_freight     decimal(20, 8) NULL,
	  posting_code     varchar(10) NULL,
	  rate_type_home     varchar(8) NULL,
	  rate_type_oper     varchar(8) NULL,
	  reference_code     varchar(32) NULL,
	  hold_reason     varchar(10) NULL,
	  dest_zone_code     varchar(8) NULL,
	  orig_no     int   NULL,
	  orig_ext     int   NULL,
	  tot_tax_incl     decimal(20, 8) NULL,
	  process_ctrl_num     varchar(32) NULL,
	  batch_code     varchar(16) NULL,
	  tot_ord_incl     decimal(20, 8) NULL,
	  barcode_status     char(2) NULL,
	  multiple_flag     char(1) NOT NULL,
	  so_priority_code     char(1) NULL,
	  FO_order_no     varchar(30) NULL,
	  blanket_amt     float   NULL,
	  user_priority     varchar(8) NULL,
	  user_category     varchar(10) NULL,
	  from_date     datetime   NULL,
	  to_date     datetime   NULL,
	  consolidate_flag     smallint   NULL,
	  proc_inv_no     varchar(32) NULL,
	  sold_to_addr1     varchar(40) NULL,
	  sold_to_addr2     varchar(40) NULL,
	  sold_to_addr3     varchar(40) NULL,
	  sold_to_addr4     varchar(40) NULL,
	  sold_to_addr5     varchar(40) NULL,
	  sold_to_addr6     varchar(40) NULL,
	  user_code     varchar(8) NOT NULL,
	  user_def_fld1     varchar(255) NULL,
	  user_def_fld2     varchar(255) NULL,
	  user_def_fld3     varchar(255) NULL,
	  user_def_fld4     varchar(255) NULL,
	  user_def_fld5     float   NULL,
	  user_def_fld6     float   NULL,
	  user_def_fld7     float   NULL,
	  user_def_fld8     float   NULL,
	  user_def_fld9     int   NULL,
	  user_def_fld10     int   NULL,
	  user_def_fld11     int   NULL,
	  user_def_fld12     int   NULL,
	  eprocurement_ind     int   NULL,
	  sold_to     varchar(10) NULL,
	  sopick_ctrl_num     varchar(32) NULL,
	  organization_id     varchar(30) NULL,
	  last_picked_dt     datetime   NULL,
	  internal_so_ind     int   NULL,
	  ship_to_country_cd     varchar(3) NULL,
	  sold_to_city     varchar(40) NULL,
	  sold_to_state     varchar(40) NULL,
	  sold_to_zip     varchar(15) NULL,
	  sold_to_country_cd     varchar(3) NULL,
	  tax_valid_ind     int   NULL,
	  addr_valid_ind     int   NULL
	)



INSERT #ord_list_temp
(
order_no, order_ext, line_no, location, part_no, description, time_entered, ordered, shipped, price, 
price_type, note, status, cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped, 
discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor, 
direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, 
part_type, orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, 
display_line, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id,  
ship_to, service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, user_count,
cust_po, organization_id, picked_dt ,  who_picked_id,    printed_dt, who_unpicked_id, unpicked_dt
)	
SELECT	
order_no, order_ext, line_no, @location_def 'location', part_no, description, time_entered, ordered, shipped, price, 
price_type, note, status, cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped, 
discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor, 
direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, 
part_type, orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, 
display_line, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id,  
ship_to, service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, user_count,
cust_po, organization_id, picked_dt ,  who_picked_id,    printed_dt, who_unpicked_id, unpicked_dt
FROM ord_list
WHERE order_no = @order_no 
AND order_ext = @ext 

SELECT @result = 0

SELECT @line_ext = 1

DECLARE MultipleShipOrd CURSOR FOR
	SELECT ship_to FROM #ord_list_temp WHERE order_no = @order_no AND order_ext = @ext

OPEN MultipleShipOrd

FETCH NEXT FROM MultipleShipOrd into @ship_to

WHILE @@FETCH_STATUS = 0
BEGIN


	INSERT #ord_list
	(
	order_no, order_ext, line_no, location, part_no, description, time_entered, ordered, shipped, price, 
	price_type, note, status, cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped, 
	discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor, 
	direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, 
	part_type, orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, 
	std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id,  
	ship_to, service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, user_count
	)	
	SELECT	
	order_no, @line_ext, line_no, @location_def 'location', part_no, description, time_entered, ordered, shipped, price, 
	price_type, note, status, cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped, 
	discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor, 
	direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, 
	part_type, orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, 
	std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id,  
	ship_to, service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, 
	user_count
	FROM #ord_list_temp
	WHERE order_no= @order_no 
	AND order_ext= @ext 
	AND ship_to = @ship_to

	INSERT #orders (	
      order_no      ,ext          ,cust_code   ,ship_to       ,req_ship_date        ,sch_ship_date
      ,date_shipped  ,date_entered ,cust_po     ,who_entered   ,status               ,attention       
      ,phone         ,terms        ,routing      , special_instr ,invoice_date       ,total_invoice 
      ,total_amt_order ,salesperson   ,tax_id    ,tax_perc      ,invoice_no          ,fob           
      ,freight        ,printed        ,discount    ,label_no            ,cancel_date   ,new 
      ,ship_to_name   ,ship_to_add_1  ,ship_to_add_2   ,ship_to_add_3   ,ship_to_add_4 ,ship_to_add_5 
      ,ship_to_city  ,ship_to_state    ,ship_to_zip    ,ship_to_country,ship_to_region,cash_flag 
      ,type           ,back_ord_flag   ,freight_allow_pct ,route_code ,route_no      ,date_printed
      ,date_transfered ,cr_invoice_no  ,who_picked     ,note            ,void          ,void_who      
      ,void_date      ,changed       ,remit_key        ,forwarder_key  ,freight_to      ,sales_comm      
      ,freight_allow_type ,cust_dfpa     ,location         ,total_tax      ,total_discount   ,f_note     
      ,invoice_edi      ,edi_batch     ,post_edi_date    ,blanket        ,gross_sales      ,load_no      
      ,curr_key      ,curr_type       ,curr_factor    ,bill_to_key    ,oper_factor      ,tot_ord_tax      
      ,tot_ord_disc  ,tot_ord_freight ,posting_code   ,rate_type_home ,rate_type_oper   ,reference_code  
      ,hold_reason   ,dest_zone_code  ,orig_no        ,orig_ext        ,tot_tax_incl    ,process_ctrl_num 
      ,batch_code      ,tot_ord_incl   ,barcode_status  ,multiple_flag   ,so_priority_code  ,FO_order_no
      ,blanket_amt     ,user_priority  ,user_category   ,from_date     ,to_date      ,consolidate_flag
      ,proc_inv_no     ,sold_to_addr1  ,sold_to_addr2   ,sold_to_addr3 ,sold_to_addr4 ,sold_to_addr5
      ,sold_to_addr6   ,user_code     ,user_def_fld1    ,user_def_fld2 ,user_def_fld3 ,user_def_fld4
      ,user_def_fld5   ,user_def_fld6  ,user_def_fld7   ,user_def_fld8  ,user_def_fld9  ,user_def_fld10
      ,user_def_fld11  ,user_def_fld12 ,eprocurement_ind ,sold_to     ,sopick_ctrl_num  ,organization_id
      ,last_picked_dt  ,internal_so_ind  ,ship_to_country_cd ,sold_to_city  ,sold_to_state  ,sold_to_zip
      ,sold_to_country_cd ,tax_valid_ind ,addr_valid_ind
	)
	SELECT	
	ord.order_no,   @line_ext,    ord.cust_code,   @ship_to,    ord.req_ship_date, ord.sch_ship_date,
	ord.date_shipped, ord.date_entered, ord.cust_po ,ord.who_entered,  ord.status, convert(varchar(40),cust.attention_name), 
	convert(varchar(20),cust.attention_phone),  ord.terms, convert(varchar(20),	cust.ship_via_code), ord.special_instr, 
	ord.invoice_date, ord.total_invoice, 
	SUM(lst.price * lst.ordered) 'total_amt_order', ord.salesperson , ord.tax_id, ord.tax_perc, ord.invoice_no, 
	convert(varchar(10),cust.fob_code),
	ord.freight,  ord.printed,   ord.discount, ord.label_no, 	ord.cancel_date, ord.new , 
	convert(varchar(40),cust.address_name ) ,	 convert(varchar(40),cust.addr1), convert(varchar(40),cust.addr2), 
	convert(varchar(40),cust.addr3), convert(varchar(40),cust.addr4), 	 convert(varchar(40),cust.addr5), 
	convert(varchar(10),cust.city), convert(varchar(2),cust.state),	 convert(varchar(10),cust.postal_code),
	convert(varchar(40),cust.country_code),	  convert(varchar(10),cust.territory_code), ord.cash_flag,
	ord.type, ord.back_ord_flag, 	ord.freight_allow_pct, ord.route_code, ord.route_no, ord.date_printed,
	ord.date_transfered,	 ord.cr_invoice_no, ord.who_picked, ord.note, 	ord.void, ord.void_who,
	ord.void_date, ord.changed, ord.remit_key, convert(varchar(10),cust.forwarder_code), ord.freight_to, 
	ord.sales_comm,
	ord.freight_allow_type, 	ord.cust_dfpa, @location_def 'location', SUM(lst.total_tax) /*'total_tax'*/,
	ord.total_discount, ord.f_note,
	ord.invoice_edi, ord.edi_batch, ord.post_edi_date, ord.blanket, 	ord.gross_sales, ord.load_no,
	ord.curr_key, ord.curr_type, ord.curr_factor, ord.bill_to_key, ord.oper_factor, SUM(lst.total_tax) 'tot_ord_tax',
	(SUM(lst.price * lst.ordered) * SUM (lst.discount)) / 100 /*'tot_ord_disc'*/,ord.tot_ord_freight, ord.posting_code, 
	ord.rate_type_home, ord.rate_type_oper, 	ord.reference_code,
        ord.hold_reason, convert(varchar(8),cust.dest_zone_code), @order_no, ord.orig_ext, ord.tot_tax_incl, ord.process_ctrl_num,
        ord.batch_code, ord.tot_ord_incl, ord.barcode_status, ord.multiple_flag, ord.so_priority_code, ord.FO_order_no, 
        ord.blanket_amt, ord.user_priority,	 ord.user_category, ord.from_date,  ord.to_date, 	ord.consolidate_flag,
        ord.proc_inv_no,  ord.sold_to_addr1, ord.sold_to_addr2, ord.sold_to_addr3, ord.sold_to_addr4, ord.sold_to_addr5, 
	ord.sold_to_addr6, ord.user_code, ord.user_def_fld1, ord.user_def_fld2,	 ord.user_def_fld3, ord.user_def_fld4,
	ord.user_def_fld5, 	ord.user_def_fld6, ord.user_def_fld7, ord.user_def_fld8, ord.user_def_fld9, 
	ord.user_def_fld10,
	ord.user_def_fld11, ord.user_def_fld12 ,ord.eprocurement_ind ,ord.sold_to     ,ord.sopick_ctrl_num  ,
	ord.organization_id,
	ord.last_picked_dt  ,ord.internal_so_ind  ,ord.ship_to_country_cd ,ord.sold_to_city  ,ord.sold_to_state  ,
	ord.sold_to_zip,
	ord.sold_to_country_cd ,ord.tax_valid_ind ,ord.addr_valid_ind
	FROM orders_all ord , #ord_list lst,  armaster_all cust  /* arshipto cust  */ 
	WHERE ord.order_no = @order_no 
	AND   ord.ext = @ext
	AND   ord.order_no = lst.order_no
	AND   lst.order_ext = @line_ext
	AND   ord.cust_code = cust.customer_code
	AND   cust.ship_to_code = @ship_to 
	GROUP BY
	ord.order_no, ord.cust_code, ord.req_ship_date, ord.sch_ship_date, ord.date_shipped, ord.date_entered, ord.cust_po , 
	ord.who_entered, ord.status, cust.attention_name, cust.attention_phone, ord.terms, cust.ship_via_code, ord.special_instr, ord.invoice_date, ord.total_invoice, 
	ord.salesperson , ord.tax_id, ord.tax_perc, ord.invoice_no, cust.fob_code, ord.freight, ord.printed, ord.discount, ord.label_no, 
	ord.cancel_date, ord.new , cust.address_name, cust.addr1, cust.addr2, cust.addr3, cust.addr4, cust.addr5, 
	cust.city, cust.state, cust.postal_code, cust.country_code, cust.territory_code, ord.cash_flag, ord.type, ord.back_ord_flag, 
	ord.freight_allow_pct, ord.route_code, ord.route_no, ord.date_printed, ord.date_transfered, ord.cr_invoice_no, ord.who_picked, ord.note, 
	ord.void, ord.void_who, ord.void_date, ord.changed, ord.remit_key, cust.forwarder_code, ord.freight_to, ord.sales_comm, ord.freight_allow_type, 
	ord.cust_dfpa, ord.location, ord.total_discount, ord.f_note, ord.invoice_edi, ord.edi_batch, ord.post_edi_date, ord.blanket, 
	ord.gross_sales, ord.load_no, ord.curr_key, ord.curr_type, ord.curr_factor, ord.bill_to_key, ord.oper_factor, 
	ord.tot_ord_freight, ord.posting_code, ord.rate_type_home, ord.rate_type_oper, ord.reference_code, ord.hold_reason, cust.dest_zone_code, 
	ord.orig_ext, ord.tot_tax_incl, ord.process_ctrl_num, ord.batch_code, ord.tot_ord_incl, ord.barcode_status, ord.multiple_flag, 
	ord.so_priority_code, ord.FO_order_no, ord.blanket_amt, ord.user_priority, ord.user_category, ord.from_date,  ord.to_date, 
	ord.consolidate_flag, ord.proc_inv_no,  ord.sold_to_addr1, ord.sold_to_addr2, ord.sold_to_addr3, ord.sold_to_addr4, ord.sold_to_addr5, 
	ord.sold_to_addr6, ord.user_code, ord.user_def_fld1, ord.user_def_fld2, ord.user_def_fld3, ord.user_def_fld4, ord.user_def_fld5, 
	ord.user_def_fld6, ord.user_def_fld7, ord.user_def_fld8, ord.user_def_fld9, ord.user_def_fld10, ord.user_def_fld11, ord.user_def_fld12,
	ord.eprocurement_ind ,ord.sold_to     ,ord.sopick_ctrl_num  , ord.organization_id,
	ord.last_picked_dt  ,ord.internal_so_ind  ,ord.ship_to_country_cd , ord.sold_to_city  ,ord.sold_to_state  ,ord.sold_to_zip,
	ord.sold_to_country_cd ,ord.tax_valid_ind ,ord.addr_valid_ind
	
    
	INSERT orders_all 	
 
     (	order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_shipped, date_entered, cust_po , 
	who_entered, status, attention, phone, terms, routing, special_instr, invoice_date, total_invoice, 
	total_amt_order, salesperson , tax_id, tax_perc, invoice_no, fob, freight, printed, discount, label_no, 
	cancel_date, new, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_add_5, 
	ship_to_city, ship_to_state, ship_to_zip, ship_to_country, ship_to_region, cash_flag, type, back_ord_flag, 
	freight_allow_pct, route_code, route_no, date_printed, date_transfered, cr_invoice_no, who_picked, note, 
	void, void_who, void_date, changed, remit_key, forwarder_key, freight_to, sales_comm, freight_allow_type, 
	cust_dfpa, location, total_tax, total_discount, f_note, invoice_edi, edi_batch, post_edi_date, blanket, 
	gross_sales, load_no, curr_key, curr_type, curr_factor, bill_to_key, oper_factor, tot_ord_tax, tot_ord_disc,
	tot_ord_freight, posting_code, rate_type_home, rate_type_oper, reference_code, hold_reason, dest_zone_code, 
	orig_no, orig_ext, tot_tax_incl, process_ctrl_num, batch_code, tot_ord_incl, barcode_status, multiple_flag, 
	so_priority_code, FO_order_no, blanket_amt, user_priority, user_category, from_date,  to_date, 
	consolidate_flag, proc_inv_no,  sold_to_addr1, sold_to_addr2, sold_to_addr3, sold_to_addr4, sold_to_addr5, 
	sold_to_addr6, user_code, user_def_fld1, user_def_fld2, user_def_fld3, user_def_fld4, user_def_fld5, 
	user_def_fld6, user_def_fld7, user_def_fld8, user_def_fld9, user_def_fld10, user_def_fld11, user_def_fld12,
	eprocurement_ind , sold_to     ,  sopick_ctrl_num  , organization_id, last_picked_dt,  internal_so_ind ,
	ship_to_country_cd , sold_to_city  , sold_to_state, sold_to_zip, sold_to_country_cd, tax_valid_ind ,
	addr_valid_ind

	)
	SELECT
	order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_shipped, date_entered, cust_po , 
	who_entered,  status ,	attention, phone, terms, routing, special_instr, invoice_date, total_invoice, 
	total_amt_order, salesperson , tax_id, tax_perc, invoice_no, fob, freight, printed, discount, label_no, 
	cancel_date, new, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_add_5, 
	ship_to_city, ship_to_state, ship_to_zip, ship_to_country, ship_to_region, cash_flag, type, back_ord_flag, 
	freight_allow_pct, route_code, route_no, date_printed, date_transfered, cr_invoice_no, who_picked, note, 
	void, void_who, void_date, changed, remit_key, forwarder_key, freight_to, sales_comm, freight_allow_type, 
	cust_dfpa, location, total_tax, total_discount, f_note, invoice_edi, edi_batch, post_edi_date, blanket, 
	gross_sales, load_no, curr_key, curr_type, curr_factor, bill_to_key, oper_factor, tot_ord_tax, tot_ord_disc,
	tot_ord_freight, posting_code, rate_type_home, rate_type_oper, reference_code, hold_reason, dest_zone_code, 
	orig_no, orig_ext, tot_tax_incl, process_ctrl_num, batch_code, tot_ord_incl, barcode_status, multiple_flag, 
	so_priority_code, FO_order_no, blanket_amt, user_priority, user_category, from_date,  to_date, 
	consolidate_flag, proc_inv_no,  sold_to_addr1, sold_to_addr2, sold_to_addr3, sold_to_addr4, sold_to_addr5, 
	sold_to_addr6, user_code, user_def_fld1, user_def_fld2, user_def_fld3, user_def_fld4, user_def_fld5, 
	user_def_fld6, user_def_fld7, user_def_fld8, user_def_fld9, user_def_fld10, user_def_fld11, user_def_fld12,
	eprocurement_ind , sold_to     ,  sopick_ctrl_num  , @location_def 'organization_id' , last_picked_dt  , 
	internal_so_ind ,
	ship_to_country_cd , sold_to_city  , sold_to_state, sold_to_zip, sold_to_country_cd , tax_valid_ind ,
	addr_valid_ind
	FROM #orders 


--    ALTER TABLE ord_list DISABLE TRIGGER t700insordl 

	INSERT ord_list

	(
	order_no, order_ext, line_no, location, part_no, description, time_entered, ordered, shipped, price, 
	price_type, note, status, cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped, 
	discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor, 
	direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, 
	part_type, orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, 
	display_line, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id,  
	ship_to, service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, user_count,
	cust_po, organization_id, picked_dt ,  who_picked_id,    printed_dt, who_unpicked_id, unpicked_dt
	)	
	SELECT	
	order_no, order_ext, line_no, location, part_no, description, time_entered, ordered, shipped, price, 
	price_type, note, status ,
	cost, who_entered, sales_comm, temp_price, temp_type, cr_ordered, cr_shipped, 
	discount, uom, conv_factor, void, void_who, void_date, std_cost, cubic_feet, printed, lb_tracking, labor, 
	direct_dolrs, ovhd_dolrs, util_dolrs, taxable, weight_ea, qc_flag, reason_code, qc_no, rejected, 
	part_type, orig_part_no, back_ord_flag, gl_rev_acct, total_tax, tax_code, curr_price, oper_price, 
	display_line, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, reference_code, contract, agreement_id,  
	ship_to, service_agreement_flag, inv_available_flag, create_po_flag, load_group_no, return_code, user_count,
	cust_po, organization_id, picked_dt ,  who_picked_id,    printed_dt, who_unpicked_id, unpicked_dt
	FROM #ord_list
	


--    ALTER TABLE ord_list ENABLE TRIGGER t700insordl 
 
 
	INSERT ord_list_kit
	(
	order_no,	order_ext  ,		line_no  ,	location,
	part_no ,	part_type ,		ordered ,	shipped ,
	status ,	lb_tracking ,		cr_ordered ,	cr_shipped ,
	uom,		conv_factor,		cost ,		labor,
	direct_dolrs,	ovhd_dolrs,		util_dolrs,	note ,
	qty_per,	qc_flag,		qc_no  ,	description
	)
	SELECT  
	kit.order_no,	@line_ext	  ,	kit.line_no  ,	kit.location,
	kit.part_no ,	kit.part_type ,		kit.ordered ,	kit.shipped ,
	kit.status ,	kit.lb_tracking ,	kit.cr_ordered ,kit.cr_shipped ,
	kit.uom,	kit.conv_factor,	kit.cost ,	kit.labor,
	kit.direct_dolrs,kit.ovhd_dolrs,	kit.util_dolrs,	kit.note ,
	kit.qty_per,	kit.qc_flag,		kit.qc_no  ,	kit.description
	FROM  ord_list_kit kit, #ord_list lst
	WHERE kit.order_no = @order_no
	AND   kit.order_ext = @ext
	AND   kit.line_no = lst.line_no
	AND   kit.part_no = lst.part_no

	INSERT ord_rep
	(
	order_no,	order_ext,	salesperson,	sales_comm,
	percent_flag,	exclusive_flag,	split_flag,	note,
	display_line
	) 
	SELECT 
	order_no,	@line_ext,	salesperson,	sales_comm,
	percent_flag,	exclusive_flag,	split_flag,	note,
	display_line
	FROM  ord_rep rep
	WHERE rep.order_no = @order_no
	AND   rep.order_ext = @ext

	INSERT ord_payment
	(
	order_no,		order_ext,		seq_no,				trx_desc,
	date_doc,		payment_code,		amt_payment,			prompt1_inp,
	prompt2_inp,		prompt3_inp,		prompt4_inp,			amt_disc_taken,
	cash_acct_code,		doc_ctrl_num
	)
	SELECT 
	pay.order_no,		@line_ext,		pay.seq_no,			pay.trx_desc,
	pay.date_doc,		pay.payment_code,	ord.total_amt_order,		pay.prompt1_inp,
	pay.prompt2_inp,	pay.prompt3_inp,	pay.prompt4_inp,		pay.amt_disc_taken,
	pay.cash_acct_code,	pay.doc_ctrl_num
	FROM  ord_payment pay, orders_all ord
	WHERE pay.order_no = @order_no
	AND   pay.order_ext = @ext
	AND   pay.order_no = ord.order_no
	AND   ord.ext = @line_ext

 	DELETE #ord_list_temp WHERE ship_to = @ship_to


	SELECT @line_ext = @line_ext + 1


DELETE #orders
DELETE #ord_list


FETCH NEXT FROM MultipleShipOrd into @ship_to

END

CLOSE MultipleShipOrd
DEALLOCATE MultipleShipOrd
/***** SCR 374 ***/
ALTER TABLE orders_all DISABLE TRIGGER EAI_orders_insupd
ALTER TABLE ord_list DISABLE TRIGGER EAI_ord_list_insupddel

update orders_all set status = 'L' where order_no = @order_no and ext = 0 and status = 'N'
update ord_list   set status = 'L' where order_no = @order_no and order_ext = 0 and status = 'N'

ALTER TABLE orders_all ENABLE TRIGGER EAI_orders_insupd
ALTER TABLE ord_list ENABLE TRIGGER EAI_ord_list_insupddel

/**** SCR 374 ******/

DELETE ord_payment WHERE order_no = @order_no AND order_ext = @ext

DROP TABLE #orders
DROP TABLE #ord_list
DROP TABLE #ord_list_temp

SELECT @result

RETURN

END
GO
GRANT EXECUTE ON  [dbo].[EAI_multiple_shipto_orders] TO [public]
GO
