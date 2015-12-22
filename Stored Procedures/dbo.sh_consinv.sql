SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[sh_consinv] @user varchar(30),        -- mls 5/22/00 SCR 22851
  @process_ctrl_num varchar(16) , @err int OUT,
  @group_flag int = 1,  -- jac 04-13-04 0=CUST_CODE 1=SHIPTO, 2=NATNL ACCT 
  @online_call int 
AS
set nocount on



DECLARE  @disc_prc_flag smallint,
         @exclusive_flag smallint,
         @module_id smallint,
         @next_serial_id smallint,
         @percent_flag smallint,
         @printed_flag smallint,
         @split_flag smallint,
         @trx_type smallint,
         @user_id smallint,
         @val_mode smallint


DECLARE  @company_id int,
         @date_aging int,
         @date_applied int,
         @date_entered int,
         @date_doc int,
         @date_due int,
         @date_posted int,
         @date_required int,
         @date_shipped int,
         @ext int,
	 	 @tmp_ext int, 
         @invoice int,
         @irow int,
         @num int,
         @numord int,
         @oldext int,
         @ord int,
         @ord_id int,
         @precision int, 
         @records int,
         @recurring_flag int,
         @result int,
         @rid int,
         @sequence_id int,
         @xlp int

DECLARE  @discount money

DECLARE  @amt_commission decimal(20,8), 
         @amt_discount decimal(20,8),
         @amt_disc_taken decimal(20,8),
         @amt_due decimal(20,8),
         @amt_final_tax decimal(20,8), 
         @amt_freight decimal(20,8),
         @amt_gross decimal(20,8),
         @amt_net decimal(20,8),
         @amt_paid decimal(20,8),
         @amt_tax decimal(20,8),
         @amt_tax_included decimal(20,8),
         @amt_taxable decimal(20,8),
         @discount_amt decimal(20,8), 
         @discount_prc decimal(20,8),
         @extended_price decimal(20,8), 
         @home_rate decimal(20,8),
         @line_tax decimal(20,8),
         @oper_rate decimal(20,8),
         @payment decimal(20,8),
         @qty_ordered decimal(20,8), 
         @qty_returned decimal(20,8), 
         @qty_shipped decimal(20,8), 
         @total_cost decimal(20,8),
         @total_weight decimal(20,8),
         @unit_cost decimal(20,8),
         @unit_price decimal(20,8)

DECLARE  @aging_date datetime

DECLARE	 @aging char(1),
         @ord_type char(1),
         @printed char(1), 
         @type char(1),
         @unit_code char(2), 
         @locacct char(2),
         @customer char(10), 
         @inv_account char(32),
         @cog_account char(32),
         @rev_account char(32)

DECLARE	 @territory varchar(6),
         @customer_code varchar(8),
         @def_post varchar(8),
         @dest_zone_code varchar(8),
         @fin_code varchar(8),
         @fob_code varchar(8),
         @freight_code varchar(8),
         @nat_cur_code varchar(8),
         @payment_code varchar(8),
         @price_code varchar(8),
         @posting_code varchar(8),
         @rate_type_home varchar(8),
         @rate_type_oper varchar(8),
         @salesperson_code varchar(8),
         @ship_to_code varchar(8),
         @tax_code varchar(8),
         @tax_id varchar(8),
         @tax_type_code varchar(8),
	 @old_tax_type_code varchar(8),
         @terms_code varchar(8),
         @territory_code varchar(8),
         @loc varchar(10),
         @location_code varchar(10),            
         @contract varchar(12),                 
         @batch_num varchar(16),
         @batch_code	varchar(16),
         @check_no varchar(16),
         @doc_ctrl_num varchar(16),
         @new_batch_code varchar(16), 
         @old_batch varchar(16),
         @order_ctrl_num varchar(16),
         @plt_name varchar(16),
         @process_group_num varchar(16),
         @trx_ctrl_num varchar(16),
         @cust_po_num varchar(20),
         @attention_phone varchar(30),
         @item_code varchar(30), 
         @prompt1_inp varchar(30),
         @prompt2_inp varchar(30),
         @prompt3_inp varchar(30),
         @prompt4_inp varchar(30),
         @cash_acct_code varchar(32), 
         @gl_rev_acct varchar(32),
         @reference_code varchar(32), 
         @misc_acct varchar(50),
         @attention_name varchar(40),
         @customer_addr1 varchar(40),
         @customer_addr2 varchar(40),
         @customer_addr3 varchar(40),
         @customer_addr4 varchar(40),
         @customer_addr5 varchar(40),
         @customer_addr6 varchar(40),
         @doc_desc varchar(40),
         @ship_to_addr1 varchar(40),
         @ship_to_addr2 varchar(40),
         @ship_to_addr3	varchar(40),
         @ship_to_addr4 varchar(40),
         @ship_to_addr5	varchar(40),
         @ship_to_addr6	varchar(40),
         @trx_desc varchar(40),
         @job_acct varchar(50), 
         @line_desc varchar(255)

DECLARE @AR_INCL_NON_TAX char(1)						-- mls 12/22/00 SCR 23738

DECLARE @home_currency varchar(8), @oper_currency varchar(8),
        @home_override_flag smallint, @oper_override_flag smallint,
        @divide_flag_h smallint, @divide_flag_o smallint
DECLARE @tmp_ctrl_num varchar(16)
DECLARE @old_order_no int, @old_order_ext int          -- mls 11/05/03 SCR 31944
declare @rc int , @tax_rc int, @err_msg varchar(255)

DECLARE @order_no     int, 
  @salesperson_no   smallint, 
  @territory_no     smallint, 
  @dest_zone_no     smallint, 
  @location_no     smallint, 
  @rate_type_home_no   smallint, 
  @rate_type_oper_no   smallint,
  @old_order    int,
  @old_ext    int,
  @cust_code    varchar (10),
  @last_cust_code    varchar (10),
  @curr_key    varchar (10),
  @terms      varchar (10),
  @ship_to    varchar (10),
  @remit_key    varchar (10),
  @freight_to    varchar (10),
  @invno      int,
  @old_max_order     int,
  @order_ext    int,
  @line_no    int,
  @max_order    int,
  @get_next_invoice_no  char(1),
  @parent      varchar(10)

declare @msg varchar(32), @msg2 varchar(255), @in_cursor int

SELECT @module_id  = 2001
SELECT @company_id = company_id FROM arco
SELECT @aging      = isnull((select value_str FROM config WHERE flag = 'ACCNT_AGING'),'R')

SELECT @AR_INCL_NON_TAX = isnull((select upper(substring(value_str,1,1))   
  FROM config WHERE flag = 'AR_INCL_NON_TAX'),'N')        -- mls 12/22/00 SCR 23738

SELECT @printed    = value_str FROM config WHERE flag = 'PLT_PRINT_INV'
SELECT @home_currency = home_currency,  @oper_currency = oper_currency 
  FROM glco (nolock)  

declare @org_id varchar(30)


SELECT @user_id  = user_id, @plt_name = user_name
  FROM  glusers_vw
  WHERE lower(user_name) = lower(@user)


IF @user_id is NULL  
BEGIN
  
  Select @user_id  = 1
  Select @plt_name = 'sa'
END

create table #orders (
  doc_ctrl_num varchar(16),  trx_ctrl_num varchar(16), trx_type int)
create index to_1 on #orders (doc_ctrl_num)

CREATE TABLE #adm_results
(
  module_id smallint,
  err_code  int,
  info1 char(32),
  info2 char(255),
  infoint int,
  infofloat float,
  flag1 smallint,
  trx_ctrl_num char(16),
  sequence_id int,
  source_ctrl_num char(16),
  extra int,
  order_no int,
  order_ext int,
  ewerror_ind int
)

CREATE TABLE #ewerror
(
  module_id smallint,
  err_code  int,
  info1 char(32),
  info2 char(32),
  infoint int,
  infofloat float,
  flag1 smallint,
  trx_ctrl_num char(16),
  sequence_id int,
  source_ctrl_num char(16),
  extra int
)

CREATE TABLE #arvalchg
(
  trx_ctrl_num    varchar(16),
  doc_ctrl_num    varchar(16),
  doc_desc  varchar(40),
  apply_to_num    varchar(16),
  apply_trx_type  smallint,
  order_ctrl_num  varchar(16),
  batch_code      varchar(16),
  trx_type        smallint,
  date_entered    int,
  date_applied    int,
  date_doc        int,
  date_shipped    int,
  date_required   int,
  date_due        int,
  date_aging      int,
  customer_code   varchar(8),
  ship_to_code    varchar(8),
  salesperson_code        varchar(8),
  territory_code  varchar(8),
  comment_code    varchar(8),
  fob_code        varchar(8),
  freight_code    varchar(8),
  terms_code      varchar(8),
  fin_chg_code    varchar(8),
  price_code      varchar(8),
  dest_zone_code  varchar(8),
  posting_code    varchar(8),
  recurring_flag  smallint,
  recurring_code  varchar(8),
  tax_code        varchar(8),
  cust_po_num     varchar(20),
  total_weight    float,
  amt_gross       float,
  amt_freight     float,
  amt_tax float,
  amt_tax_included  float,
  amt_discount    float,
  amt_net float,
  amt_paid        float,
  amt_due float,
  amt_cost        float,
  amt_profit      float,
  next_serial_id  smallint,
  printed_flag    smallint,
  posted_flag     smallint,
  hold_flag       smallint,
  hold_desc  varchar(40),
  user_id smallint,
  customer_addr1  varchar(40),
  customer_addr2  varchar(40),
  customer_addr3  varchar(40),
  customer_addr4  varchar(40),
  customer_addr5  varchar(40),
  customer_addr6  varchar(40),
  ship_to_addr1  varchar(40),
  ship_to_addr2  varchar(40),
  ship_to_addr3  varchar(40),
  ship_to_addr4  varchar(40),
  ship_to_addr5  varchar(40),
  ship_to_addr6  varchar(40),
  attention_name  varchar(40),
  attention_phone  varchar(30),  
  amt_rem_rev     float,
  amt_rem_tax     float,
  date_recurring  int,
  location_code   varchar(8),
  process_group_num       varchar(16) NULL,
  source_trx_ctrl_num     varchar(16) NULL,
  source_trx_type smallint NULL,
  amt_discount_taken      float NULL,
  amt_write_off_given     float NULL,
  nat_cur_code    varchar(8),     
  rate_type_home  varchar(8),     
  rate_type_oper  varchar(8),     
  rate_home       float,  
  rate_oper       float,   
  temp_flag  smallint  NULL,
  org_id		varchar(30) NULL, 
  interbranch_flag int NULL, 		temp_flag2 	smallint NULL		
)

CREATE TABLE #arterm (
	date_doc		int,
	terms_code		varchar(8),
	date_due		int,
	date_discount		int
)

--Create temp processing Tables
CREATE TABLE #arinpchg(
	trx_ctrl_num		varchar(16),
	doc_ctrl_num		varchar(16),
	doc_desc		varchar(40),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	order_ctrl_num	varchar(16),
	batch_code		varchar(16),
	trx_type		smallint,
	date_entered		int,
	date_applied		int,
	date_doc		int,
	date_shipped		int,
	date_required		int,
	date_due		int,
	date_aging		int,
	customer_code		varchar(8),
	ship_to_code		varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	comment_code		varchar(8),
	fob_code		varchar(8),
	freight_code		varchar(8),
	terms_code		varchar(8),
	fin_chg_code		varchar(8),
	price_code		varchar(8),
	dest_zone_code	varchar(8),
	posting_code		varchar(8),
	recurring_flag	smallint,
	recurring_code	varchar(8),
	tax_code		varchar(8),
	cust_po_num		varchar(20),
	total_weight		float,
	amt_gross		float,
	amt_freight		float,
	amt_tax		float,
	amt_tax_included	float,
	amt_discount		float,
	amt_net		float,
	amt_paid		float,
	amt_due		float,
	amt_cost		float,
	amt_profit		float,
	next_serial_id	smallint,
	printed_flag		smallint,
	posted_flag		smallint,
	hold_flag		smallint,
	hold_desc		varchar(40),
	user_id		smallint,
	customer_addr1	varchar(40),
	customer_addr2	varchar(40),
	customer_addr3	varchar(40),
	customer_addr4	varchar(40),
	customer_addr5	varchar(40),
	customer_addr6	varchar(40),
	ship_to_addr1		varchar(40),
	ship_to_addr2		varchar(40),
	ship_to_addr3		varchar(40),
	ship_to_addr4		varchar(40),
	ship_to_addr5		varchar(40),
	ship_to_addr6		varchar(40),
	attention_name	varchar(40),
	attention_phone	varchar(30),
	amt_rem_rev		float,
	amt_rem_tax		float,
	date_recurring	int,
	location_code		varchar(8),
	process_group_num	varchar(16),
	trx_state		smallint NULL,
	mark_flag		smallint	 NULL,
	amt_discount_taken	float NULL,
	amt_write_off_given	float NULL,	
	source_trx_ctrl_num	varchar(16) NULL,
	source_trx_type	smallint NULL,
	nat_cur_code		varchar(8),	
	rate_type_home	varchar(8),	
	rate_type_oper	varchar(8),	
	rate_home		float,	
	rate_oper		float,	
	edit_list_flag	smallint,
	ddid varchar(32) NULL,	-- rev 4 
	org_id varchar(30) NULL,
  customer_city varchar(40), customer_state varchar(40), customer_postal_code varchar(15), customer_country_code varchar(3),
  ship_to_city varchar(40), ship_to_state varchar(40), ship_to_postal_code varchar(15), ship_to_country_code varchar(3),
  writeoff_code varchar(8) NULL
)

CREATE UNIQUE INDEX #arinpchg_ind_0 ON #arinpchg ( trx_ctrl_num, trx_type )
CREATE INDEX 	#arinpchg_ind_1 ON	#arinpchg (batch_code)

CREATE TABLE #arinpage(
	trx_ctrl_num		varchar(16),
	sequence_id		int,	
	doc_ctrl_num		varchar(16),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	trx_type		smallint,
	date_applied		int,
	date_due		int,
	date_aging		int,
	customer_code		varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	price_code		varchar(8),
	amt_due		float,
	trx_state		smallint	NULL,
	mark_flag		smallint	NULL
)

CREATE UNIQUE INDEX arinpage_ind_0 ON #arinpage ( trx_ctrl_num, trx_type, sequence_id )

CREATE TABLE #arinptax (
	trx_ctrl_num	varchar(16),
	trx_type	smallint,
	sequence_id	int,
	tax_type_code	varchar(8),
	amt_taxable	float,
	amt_gross	float,
	amt_tax	float,
	amt_final_tax	float,
	trx_state 	smallint	NULL,
	mark_flag 	smallint	NULL
)

CREATE UNIQUE INDEX arinptax_ind_0 ON #arinptax ( trx_ctrl_num, trx_type, sequence_id )

CREATE TABLE #arinpcom (
	trx_ctrl_num	varchar(16),
	trx_type	smallint,
	sequence_id	int,
	salesperson_code	varchar(8),
	amt_commission	float,
	percent_flag	smallint,
	exclusive_flag	smallint,
	split_flag	smallint, 
	trx_state smallint NULL,
	mark_flag smallint NULL
)

CREATE UNIQUE INDEX arinpcom_ind_0 ON #arinpcom ( trx_ctrl_num, trx_type, sequence_id )

CREATE TABLE #arinptmp (
        timestamp		timestamp,
	trx_ctrl_num		varchar(16),	
	doc_ctrl_num		varchar(16),	
	trx_desc		varchar(40),
	date_doc		int,
        customer_code		varchar(8),
	payment_code		varchar(8),
        amt_payment		float,
	prompt1_inp		varchar(30),
	prompt2_inp		varchar(30),
	prompt3_inp		varchar(30),
	prompt4_inp		varchar(30),
	amt_disc_taken		float,
	cash_acct_code		varchar(32)
)

create table #arinpcdt (
	trx_ctrl_num	 	varchar(16),
	doc_ctrl_num	 	varchar(16),
	sequence_id	 	int,
	trx_type	 	smallint,
	location_code	 	varchar(8),
	item_code	 	varchar(30),
	bulk_flag	 	smallint,
	date_entered	 	int,
	line_desc	 	varchar(60),
	qty_ordered	 	float,
	qty_shipped	 	float,
	unit_code	 	varchar(8),
	unit_price	 	float,
	unit_cost	 	float,
	weight	 		float,
	serial_id	 	int,
	tax_code	 	varchar(8),
	gl_rev_acct	 	varchar(32),
	disc_prc_flag	 	smallint,
	discount_amt	 	float,
	commission_flag	smallint,
	rma_num		varchar(16),
	return_code	 	varchar(8),
	qty_returned	 	float,
	qty_prev_returned	float,
	new_gl_rev_acct	varchar(32),
	iv_post_flag	 	smallint,
	oe_orig_flag	 	smallint,
	discount_prc		float,	
	extended_price	float,	
	calc_tax		float,
	reference_code	varchar(32)	NULL,
	trx_state		smallint	NULL,
	mark_flag		smallint	NULL,
	cust_po			varchar(20)	NULL,
	org_id			varchar(30)	NULL
)

CREATE UNIQUE INDEX arinpcdt_ind_0 ON #arinpcdt ( trx_ctrl_num, trx_type, sequence_id )

create table #t1 (
     tax_type_code varchar(8) NOT NULL,
     tax_amt       decimal(20,8) NOT NULL,
     row_id        int identity(1,1) 
   )

-- ******************************************************************************
CREATE TABLE #post_orders (
	order_no int,
	ext int,
	tmp_ctrl_num		varchar(16),
	trx_ctrl_num		varchar(16),
	doc_ctrl_num		varchar(16),
	doc_desc		varchar(40),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	order_ctrl_num	varchar(16),
	batch_code		varchar(16),
	trx_type		smallint,
	date_entered		int,
	date_applied		int,
	date_doc		int,
	date_shipped		int,
	date_required		int,
	date_due		int,
	date_aging		int,
	customer_code		varchar(8),
	ship_to_code		varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	comment_code		varchar(8),
	fob_code		varchar(8),
	freight_code		varchar(8),
	terms_code		varchar(8),
	fin_chg_code		varchar(8),
	price_code		varchar(8),
	dest_zone_code	varchar(8),
	posting_code		varchar(8),
	recurring_flag	smallint,
	recurring_code	varchar(8),
	tax_code		varchar(8),
	cust_po_num		varchar(20),
	total_weight		float,
	amt_gross		float,
	amt_freight		float,
	amt_tax		float,
	amt_tax_included	float,
	amt_discount		float,
	amt_net		float,
	amt_paid		float,
	amt_due		float,
	amt_cost		float,
	amt_profit		float,
	next_serial_id	smallint,
	printed_flag		smallint,
	posted_flag		smallint,
	hold_flag		smallint,
	hold_desc		varchar(40),
	user_id		smallint,
	customer_addr1	varchar(40),
	customer_addr2	varchar(40),
	customer_addr3	varchar(40),
	customer_addr4	varchar(40),
	customer_addr5	varchar(40),
	customer_addr6	varchar(40),
	ship_to_addr1		varchar(40),
	ship_to_addr2		varchar(40),
	ship_to_addr3		varchar(40),
	ship_to_addr4		varchar(40),
	ship_to_addr5		varchar(40),
	ship_to_addr6		varchar(40),
	attention_name	varchar(40),
	attention_phone	varchar(30),
	amt_rem_rev		float,
	amt_rem_tax		float,
	date_recurring	int,
	location_code		varchar(8),
	process_group_num	varchar(16),
	trx_state		smallint NULL,
	mark_flag		smallint	 NULL,
	amt_discount_taken	float NULL,
	amt_write_off_given	float NULL,	
	source_trx_ctrl_num	varchar(16) NULL,
	source_trx_type	smallint NULL,
	nat_cur_code		varchar(8),	
	rate_type_home	varchar(8),	
	rate_type_oper	varchar(8),	
	rate_home		float,	
	rate_oper		float,	
	edit_list_flag	smallint,
	nat_precision	int ,
	home_override_flag smallint,
	oper_override_flag smallint,
	organization_id varchar(30) NULL,
    ship_to_city varchar(40) null,
    ship_to_state varchar(40) null,
    ship_to_country_cd varchar(40) NULL,
    ship_to_zip varchar(15)
)
CREATE INDEX post_orders1 on #post_orders (order_no, ext)
CREATE INDEX post_orders2 on #post_orders (tmp_ctrl_num)
CREATE INDEX post_orders4 on #post_orders (terms_code, date_doc)
CREATE INDEX post_orders5 on #post_orders (nat_cur_code)
CREATE INDEX post_orders6 on #post_orders (doc_ctrl_num)

CREATE TABLE #post_orders_values (
	order_no 		int,
	ext 			int,
	salesperson_no 		smallint, 
	territory_no 		smallint, 
	dest_zone_no 		smallint, 
	location_no 		smallint, 
	rate_type_home_no 	smallint, 
	rate_type_oper_no 	smallint,
	cust_code		varchar (10), 	
	curr_key		varchar (10), 	
	posting_code		varchar (10), 
	terms			varchar (10),
	tax_id			varchar (10), 
	ship_to			varchar (10), 
	remit_key		varchar (10), 	
	freight_to 		varchar (10),
	organization_id		varchar (30) NULL)

CREATE INDEX post_orders_values1 on #post_orders_values (order_no, ext)

CREATE TABLE #post_orders_det ( order_no int, ext int, max_order int, max_ext int, 
	cust_code		varchar (10), 	
	curr_key		varchar (10), 	
	posting_code		varchar (10), 
	terms			varchar (10),
	tax_id			varchar (10), 
	ship_to			varchar (10), 
	remit_key		varchar (10), 	
	freight_to 		varchar (10),
	invoice_no		int,
        cust_po                 varchar(20) NULL,
	organization_id		varchar(30) NULL,
    doc_ctrl_num  varchar(16)
	)

CREATE INDEX post_orders_det1 on #post_orders_det (order_no, ext)

CREATE TABLE #ord_list (
  doc_ctrl_num varchar(16),
	order_no int NOT NULL ,	order_ext int NOT NULL ,	line_no int NOT NULL ,	location varchar (10) NULL ,	part_no varchar (30) NOT NULL ,	description varchar (255) NULL ,
	time_entered datetime NOT NULL ,	ordered decimal(20, 8) NOT NULL ,	shipped decimal(20, 8) NOT NULL ,	price decimal(20, 8) NOT NULL ,	price_type char (1) NULL ,
	note varchar (255) NULL ,	status char (1) NOT NULL ,	cost decimal(20, 8) NOT NULL ,	who_entered varchar (20) NULL ,	sales_comm decimal(20, 8) NOT NULL ,	temp_price decimal(20, 8) NULL ,
	temp_type char (1) NULL ,	cr_ordered decimal(20, 8) NOT NULL ,	cr_shipped decimal(20, 8) NOT NULL ,	discount decimal(20, 8) NOT NULL ,	uom char (2) NULL ,	conv_factor decimal(20, 8) NOT NULL ,
	void char (1) NULL ,	void_who varchar (20) NULL ,	void_date datetime NULL ,	std_cost decimal(20, 8) NOT NULL ,	cubic_feet decimal(20, 8) NOT NULL ,	printed char (1) NULL ,
	lb_tracking char (1) NULL ,	labor decimal(20, 8) NOT NULL ,	direct_dolrs decimal(20, 8) NOT NULL ,	ovhd_dolrs decimal(20, 8) NOT NULL ,	util_dolrs decimal(20, 8) NOT NULL ,	taxable int NULL ,
	weight_ea decimal(20, 8) NULL ,	qc_flag char (1) NULL ,	reason_code varchar (10) NULL ,	row_id int IDENTITY (1, 1) NOT NULL ,	qc_no int NULL ,	rejected decimal(20, 8) NULL ,
	part_type char (1) NULL ,	orig_part_no varchar (30) NULL ,	back_ord_flag char (1) NULL ,	gl_rev_acct varchar (32) NULL ,	total_tax decimal(20, 8) NOT NULL ,tax_code varchar (10) NULL ,
	curr_price decimal(20, 8) NOT NULL ,	oper_price decimal(20, 8) NOT NULL ,display_line int NOT NULL ,	std_direct_dolrs decimal(20, 8) NULL ,	std_ovhd_dolrs decimal(20, 8) NULL ,	std_util_dolrs decimal(20, 8) NULL ,
	reference_code varchar (32) NULL ,	contract varchar (16) NULL,	agreement_id varchar(32) NULL, 	ship_to varchar(10) NULL,	service_agreement_flag char(1) NULL ,	inv_available_flag char(1) NOT NULL ,
	create_po_flag		smallint NULL,	load_group_no		int NULL,	return_code		varchar(10) NULL, 	user_count		int NULL, 	max_order int, 	max_ext int,
	cust_po varchar(20) NULL , organization_id varchar(30) NULL)

CREATE INDEX ord_list_temp_0 on #ord_list (doc_ctrl_num, row_id)
CREATE INDEX ord_list_temp_1 on #ord_list (order_no,order_ext)

CREATE TABLE #ord_list_tax (
    doc_ctrl_num varchar(16),
	order_no int, order_ext int, sequence_id int, tax_type_code varchar(8),
    amt_taxable decimal(20,8), amt_gross decimal(20,8), amt_tax decimal(20,8),
    amt_final_tax decimal(20,8) )

-- ******************************************************************************

 	INSERT #post_orders
(       order_no, 		ext,			tmp_ctrl_num,
	trx_ctrl_num,		doc_ctrl_num,		doc_desc,
	apply_to_num,		apply_trx_type,		order_ctrl_num,
	batch_code, 		trx_type,		date_entered,
	date_applied,		date_doc,		date_shipped,
	date_required,		date_due,		date_aging,
	customer_code, 		ship_to_code, 		salesperson_code,
	territory_code,		comment_code,		fob_code,
	freight_code,		terms_code,		fin_chg_code,
	price_code,		dest_zone_code,		posting_code,
	recurring_flag,		recurring_code,		tax_code,
	cust_po_num,		total_weight, 		amt_gross,
	amt_freight, 		amt_tax, 		amt_discount,
	amt_net,		amt_paid,		amt_due,				
	amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,
	hold_desc,		user_id,		customer_addr1,
	customer_addr2,		customer_addr3,		customer_addr4,
	customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,
	ship_to_addr5,		ship_to_addr6,		attention_name,
	attention_phone,	amt_rem_rev,		amt_rem_tax,
	date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,
	amt_write_off_given,	source_trx_ctrl_num,	source_trx_type,
	nat_cur_code,		rate_type_home,		rate_type_oper,
	rate_home,		rate_oper,		edit_list_flag, 
	amt_tax_included, 	nat_precision, 		home_override_flag, 
	oper_override_flag,	organization_id, ship_to_city, ship_to_state, ship_to_zip,
  ship_to_country_cd  ) 

select	MAX(o.order_no) , MAX(o.ext) , 
	convert(varchar(11),MAX(o.order_no)) + '-' + convert(varchar(4),MAX(o.ext)) , 
	'' , 	'' ,	'SO:' , 
 	'' ,	0 , 
	(convert(varchar(10),MAX(o.order_no)) + '-' + convert(varchar(10),MAX(o.ext))) ,
	'' ,	2031 ,	datediff(day,'01/01/1900',getdate()) + 693596 ,
	CASE @aging
	   WHEN 'R' THEN datediff(day,'01/01/1900',MAX(o.date_shipped)) + 693596
	   ELSE  datediff(day,'01/01/1900',MAX(isnull(o.invoice_date,getdate()))) + 693596
	END ,

	CASE @aging
	   WHEN 'R' THEN datediff(day,'01/01/1900',MAX(o.date_shipped)) + 693596
	   ELSE  datediff(day,'01/01/1900',MAX(isnull(o.invoice_date,getdate()))) + 693596
	END ,
	datediff(day,'01/01/1900',MAX(o.date_shipped)) + 693596 ,
	datediff(day,'01/01/1900',MAX(o.req_ship_date)) + 693596 ,
	0 ,
	CASE @aging
	   WHEN 'R' THEN datediff(day,'01/01/1900',MAX(ISNULL(o.date_shipped, 0))) + 693596
	   ELSE  datediff(day,'01/01/1900',MAX(isnull(o.invoice_date,getdate()))) + 693596
	END ,
 	a.customer_code , 
	CASE WHEN @group_flag = 1 THEN o.ship_to ELSE '' END  , '' ,
	'' ,	'' ,	'' ,
	isnull(o.freight_to,'') , o.terms , MAX(isnull(a.fin_chg_code,'')) , 
	MAX(isnull(a.price_code,'')) , '' , o.posting_code , 
	0 ,	'' ,	o.tax_id , 
	max(isnull(o.cust_po,'')) , 
				0 ,		SUM(o.gross_sales) ,
	SUM(o.freight) , SUM(o.total_tax) , SUM(o.total_discount) ,
	SUM((isnull(o.gross_sales, 0) + isnull(o.freight, 0) + isnull(o.total_tax, 0)) - isnull(o.total_discount, 0)) ,
				0.0 ,
	SUM((isnull(o.gross_sales, 0) + isnull(o.freight, 0) + isnull(o.total_tax, 0)) - isnull(o.total_discount, 0)) ,
	0 ,		0 ,		0 ,
	CASE @printed WHEN 'A' THEN 1 ELSE 0 END ,
	0 ,		0 ,
	'' ,		@user_id , 
	isnull(MAX(a.addr1),'') , isnull(MAX(a.addr2),'') , 
	isnull(MAX(a.addr3),'') , isnull(MAX(a.addr4),'') ,
	isnull(MAX(a.addr5),'') , isnull(MAX(a.addr6),'') ,
	CASE WHEN @group_flag = 1 THEN isnull(MAX(o.ship_to_name),'') ELSE '' END  , 
	CASE WHEN @group_flag = 1 THEN isnull(MAX(o.ship_to_add_1),'') ELSE '' END , 
	CASE WHEN @group_flag = 1 THEN isnull(MAX(o.ship_to_add_2),'') ELSE '' END , 
	CASE WHEN @group_flag = 1 THEN isnull(MAX(o.ship_to_add_3),'') ELSE '' END ,
	CASE WHEN @group_flag = 1 THEN isnull(MAX(o.ship_to_add_4),'') ELSE '' END , 
	CASE WHEN @group_flag = 1 THEN isnull(MAX(o.ship_to_add_5),'') ELSE '' END , 
	CASE WHEN @group_flag = 1 THEN isnull(MAX(a.attention_name),'') ELSE '' END , 
	CASE WHEN @group_flag = 1 THEN isnull(MAX(a.attention_phone),'') ELSE '' END , 
	0 ,	0 ,	0 ,
	'' ,	MAX(o.process_ctrl_num) ,
	0 ,	0 ,	0.0 ,
	0.0 , '' , 0 , 
	o.curr_key , MAX(o.rate_type_home) , 
	MAX(o.rate_type_oper) ,
	MAX(o.curr_factor) , MAX(o.oper_factor) , 
	0 ,	isnull(SUM(o.tot_tax_incl),0) , 	-- mls 10/04/06 SCR 36994
	1 ,	0 , 0 ,
	o.organization_id,
  isnull(max(a.city),''),
  isnull(max(a.state),''),
  isnull(max(a.postal_code),''),
  isnull(max(a.country_code),'')
FROM 	orders_all o , adm_cust_all a (nolock)
WHERE 	o.process_ctrl_num 	= @process_ctrl_num			--'POST000000001219'
 
 AND 	((@group_flag <> 2 AND o.cust_code = a.customer_code) OR 
	 (@group_flag = 2 AND a.customer_code = ISNULL((SELECT parent FROM arnarel (NOLOCK) WHERE child = o.cust_code), o.cust_code)))  
 AND     o.consolidate_flag = 1	
GROUP BY a.customer_code, 	o.curr_key, 	o.posting_code, o.terms,
	o.tax_id, 	CASE WHEN @group_flag = 1 THEN o.ship_to ELSE '' END, 	
	isnull(o.remit_key,''), 	isnull(o.freight_to,''), o.organization_id

INSERT #post_orders_values (
	order_no,		ext,
	salesperson_no,		territory_no, 
	dest_zone_no, 		location_no, 
	rate_type_home_no, 	rate_type_oper_no,
	cust_code, 	curr_key, 	posting_code, 	terms,
	tax_id, 	ship_to, 	remit_key, 	freight_to , organization_id)
SELECT	MAX(o.order_no), MAX(o.ext), 
	salesperson_no 		= count (distinct o.salesperson), 
	territory_no 		= count (distinct o.ship_to_region), 
	dest_zone_no 		= count (distinct o.dest_zone_code),
	location_no 		= count (distinct o.location),
	rate_type_home_no 	= count (distinct o.rate_type_home),
	rate_type_oper_no 	= count (distinct o.rate_type_oper), 
	a.customer_code, 	o.curr_key, 	o.posting_code, o.terms,
	o.tax_id, 	CASE WHEN @group_flag = 1 THEN o.ship_to ELSE '' END, 	o.remit_key, 	isnull(o.freight_to,''),
	o.organization_id
FROM 	orders_all o (NOLOCK), adm_cust_all a (NOLOCK)
WHERE 	o.process_ctrl_num 	= @process_ctrl_num
AND 	((@group_flag <> 2 AND o.cust_code = a.customer_code) OR 
	 (@group_flag = 2 AND a.customer_code = ISNULL((SELECT parent FROM arnarel (NOLOCK) WHERE child = o.cust_code), o.cust_code)))  
GROUP BY a.customer_code, 	o.curr_key, 	o.posting_code, o.terms,
	o.tax_id, 	CASE WHEN @group_flag = 1 THEN o.ship_to ELSE '' END, 	o.remit_key, 	isnull(o.freight_to,''),
	o.organization_id

INSERT 	#post_orders_det ( order_no, ext, max_order, max_ext,
	cust_code, 	curr_key, 	posting_code, 	terms,
	tax_id, 	ship_to, 	remit_key, 	freight_to,
	invoice_no ,    cust_po,	organization_id,doc_ctrl_num)

SELECT	order_no, ext, 0, 0,
	a.customer_code, 	curr_key, 	o.posting_code, 	terms,
	tax_id, 	CASE WHEN @group_flag = 1 THEN ship_to ELSE '' END, 	remit_key, 	isnull(freight_to,''),
	invoice_no,
        isnull(o.cust_po,''), o.organization_id, ''
FROM	orders_all o(NOLOCK), adm_cust_all a (NOLOCK)
WHERE	process_ctrl_num = @process_ctrl_num
AND 	((@group_flag <> 2 AND o.cust_code = a.customer_code) OR 
	 (@group_flag = 2 AND a.customer_code = ISNULL((SELECT parent FROM arnarel (NOLOCK) WHERE child = o.cust_code), o.cust_code)))  

DECLARE update_post_orders_values CURSOR 
FOR
SELECT 	order_no, 
	ext, 
	salesperson_no, 
	territory_no, 
	dest_zone_no, 
	location_no, 
	rate_type_home_no, 
	rate_type_oper_no,
	cust_code, 	curr_key, 	posting_code, 	terms,
	tax_id, 	ship_to, 	remit_key, 	freight_to , organization_id
FROM 	#post_orders_values
 
 
OPEN update_post_orders_values

SELECT 	@old_order = 0, 
	@old_ext = 0,
	@get_next_invoice_no = 'N',
	@last_cust_code = NULL

FETCH NEXT FROM update_post_orders_values 
INTO	@order_no, 
	@ext, 
	@salesperson_no,
	@territory_no,
	@dest_zone_no,
	@location_no,
	@rate_type_home_no,
	@rate_type_oper_no,
	@cust_code, 	@curr_key, 	@posting_code, 	@terms,
	@tax_id, 	@ship_to, 	@remit_key, 	@freight_to, @org_id

WHILE @@FETCH_STATUS = 0
BEGIN
	select @tmp_ext = max(ext) from orders_all
        where process_ctrl_num = @process_ctrl_num and order_no = @order_no

	IF @salesperson_no > 1
	BEGIN

		UPDATE 	#post_orders
		SET 	salesperson_code = a.salesperson_code
		FROM 	#post_orders p , adm_cust_all a
		WHERE	p.customer_code = a.customer_code
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END
	ELSE
	BEGIN

		UPDATE 	#post_orders
		SET 	salesperson_code = o.salesperson
		FROM 	#post_orders p , orders_all o
		WHERE	p.order_no	= o.order_no
		AND	o.ext		= @tmp_ext
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END
		
	IF @territory_no > 1
	BEGIN

		UPDATE 	#post_orders
		SET 	territory_code = a.territory_code
		FROM 	#post_orders p , adm_cust_all a
		WHERE	p.customer_code = a.customer_code
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END
	ELSE
	BEGIN

		UPDATE 	#post_orders
		SET 	territory_code = o.ship_to_region
		FROM 	#post_orders p , orders_all o
		WHERE	p.order_no	= o.order_no
		AND	o.ext		= @tmp_ext
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END

	IF @dest_zone_no > 1
	BEGIN

		UPDATE 	#post_orders
		SET 	dest_zone_code = a.dest_zone_code
		FROM 	#post_orders p , adm_cust_all a
		WHERE	p.customer_code = a.customer_code
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END
	ELSE
	BEGIN

		UPDATE 	#post_orders
		SET 	dest_zone_code = o.dest_zone_code
		FROM 	#post_orders p , orders_all o
		WHERE	p.order_no	= o.order_no
		AND	o.ext		= @tmp_ext
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END

	IF @location_no > 1
	BEGIN

		UPDATE 	#post_orders
		SET 	location_code = substring(a.location_code,1,8)
		FROM 	#post_orders p , adm_cust_all a
		WHERE	p.customer_code = a.customer_code
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END
	ELSE
	BEGIN

		UPDATE 	#post_orders
		SET 	location_code = substring(o.location,1,8)
		FROM 	#post_orders p , orders_all o
		WHERE	p.order_no	= o.order_no
		AND	o.ext		= @tmp_ext
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END

	IF @rate_type_home_no > 1
	BEGIN

		UPDATE 	#post_orders
		SET 	rate_type_home = a.rate_type_home
		FROM 	#post_orders p , adm_cust_all a
		WHERE	p.customer_code = a.customer_code
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END
	ELSE
	BEGIN

		UPDATE 	#post_orders
		SET 	rate_type_home = o.rate_type_home
		FROM 	#post_orders p , orders_all o
		WHERE	p.order_no	= o.order_no
		AND	o.ext		= @tmp_ext
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END

	IF @rate_type_oper_no > 1
	BEGIN

		UPDATE 	#post_orders
		SET 	rate_type_oper = a.rate_type_oper
		FROM 	#post_orders p , adm_cust_all a
		WHERE	p.customer_code = a.customer_code
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END
	ELSE
	BEGIN

		UPDATE 	#post_orders
		SET 	rate_type_oper = o.rate_type_oper
		FROM 	#post_orders p , orders_all o
		WHERE	p.order_no	= o.order_no
		AND	o.ext		= @tmp_ext
		AND	p.order_no 	= @order_no
		AND	p.ext		= @ext

	END
 
	SELECT @doc_ctrl_num = NULL
	WHILE (@doc_ctrl_num IS NULL)
	  BEGIN
      	    EXEC @result = ARGetNextControl_SP 2001, @doc_ctrl_num OUTPUT, @invno OUTPUT, 0
      	    IF @doc_ctrl_num IS NULL 
            begin
      select @msg2 = 'Could not generate masked doc control number.'
      select @msg = ''
      set @err = -1

      goto write_admresults
            end
      	    SELECT @doc_ctrl_num = RTRIM(@doc_ctrl_num)
      	    IF EXISTS(	SELECT 	doc_ctrl_num
			FROM	artrx
			WHERE  	doc_ctrl_num = @doc_ctrl_num
			AND	trx_type = 2021 )
		BEGIN
		  SELECT @doc_ctrl_num = ''
		  CONTINUE
		END
      	    IF EXISTS(	SELECT	doc_ctrl_num
			FROM	arinpchg
			WHERE	doc_ctrl_num = @doc_ctrl_num
			AND	trx_type = 2021 )
		BEGIN
		  SELECT @doc_ctrl_num = ''
		  CONTINUE
		END
	  END
 

	if (@invno is null OR @invno < 1) select @invno = 0

	UPDATE	#post_orders_det
	SET 	max_order 	= @order_no, 
		max_ext		= @ext,
		invoice_no 	= @invno,
    doc_ctrl_num = @doc_ctrl_num
	WHERE	cust_code 	= @cust_code
	and	curr_key 	= @curr_key
	and	posting_code 	= @posting_code
	and	terms 		= @terms
	and	tax_id 		= @tax_id
	and	ship_to 	= @ship_to
	and	remit_key 	= @remit_key
	and	freight_to 	= @freight_to
	and	organization_id = @org_id

	UPDATE 	#post_orders
	SET 	doc_ctrl_num	= @doc_ctrl_num
	WHERE	order_no 	= @order_no
	AND	ext		= @ext
	
	SELECT 	@old_order = @order_no, 
		@old_ext = @ext

	FETCH NEXT FROM update_post_orders_values 
	INTO	@order_no, 
		@ext, 
		@salesperson_no,
		@territory_no,
		@dest_zone_no,
		@location_no,
		@rate_type_home_no,
		@rate_type_oper_no,
		@cust_code, 	@curr_key, 	@posting_code, 	@terms,
		@tax_id, 	@ship_to, 	@remit_key, 	@freight_to, @org_id

END
  
CLOSE update_post_orders_values
DEALLOCATE update_post_orders_values


IF NOT EXISTS (select 1 from #post_orders)
BEGIN
  SELECT @err = 1 
  select @msg2 = ''
  select @msg = 'OK'
  set @result = @err

  goto write_admresults
END

if exists (select 1 from #post_orders where doc_ctrl_num = '')
begin
  select @err = 15
 select @msg2 = 'Error 15'
  select @msg = ''
  set @result = @err

  goto write_admresults
end




insert into #ord_list (doc_ctrl_num, order_no ,	order_ext ,	line_no ,	location ,	part_no ,	description ,
	time_entered ,	ordered ,	shipped ,	price ,	price_type ,
	note ,	status ,	cost ,	who_entered ,	sales_comm ,	temp_price ,
	temp_type ,	cr_ordered ,	cr_shipped ,	discount,	uom ,	conv_factor ,
	void ,	void_who ,	void_date ,	std_cost ,	cubic_feet ,	printed ,
	lb_tracking ,	labor ,	direct_dolrs  ,	ovhd_dolrs ,	util_dolrs ,	taxable ,
	weight_ea ,	qc_flag  ,	reason_code ,	qc_no ,	rejected ,
	part_type ,	orig_part_no ,	back_ord_flag ,	gl_rev_acct ,	total_tax , tax_code ,
	curr_price ,	oper_price ,display_line ,	std_direct_dolrs ,	std_ovhd_dolrs ,	std_util_dolrs ,
	reference_code ,	contract ,	agreement_id , 	ship_to ,	service_agreement_flag ,	inv_available_flag ,
	create_po_flag	,	load_group_no,	return_code, 	user_count,	max_order , 	max_ext, cust_po, organization_id )
select 
	d.doc_ctrl_num, l.order_no ,	l.order_ext ,	l.line_no ,	location ,	part_no ,	description ,
	time_entered ,	ordered ,	shipped ,	price ,	price_type ,
	note ,	status ,	cost ,	who_entered ,	sales_comm ,	temp_price ,
	temp_type ,	cr_ordered ,	cr_shipped ,	discount,	uom ,	conv_factor ,
	void ,	void_who ,	void_date ,	std_cost ,	cubic_feet ,	printed ,
	lb_tracking ,	labor ,	direct_dolrs  ,	ovhd_dolrs ,	util_dolrs ,	taxable ,
	weight_ea ,	qc_flag  ,	reason_code ,	qc_no ,	rejected ,
	part_type ,	orig_part_no ,	back_ord_flag ,	gl_rev_acct ,	total_tax , tax_code ,
	curr_price ,	oper_price ,display_line ,	std_direct_dolrs ,	std_ovhd_dolrs ,	std_util_dolrs ,
	reference_code ,	contract ,	agreement_id , 	CASE WHEN @group_flag = 1 THEN l.ship_to ELSE '' END ,	service_agreement_flag ,	inv_available_flag ,
	create_po_flag	,	load_group_no,	return_code, 	user_count,	d.max_order , 	d.max_ext , l.cust_po, l.organization_id
from 	ord_list l, #post_orders_det d
WHERE 	l.order_no 	= d.order_no
AND 	l.order_ext 	= d.ext
AND 	(l.shipped > 0 or l.cr_shipped > 0)
ORDER BY l.order_no, l.order_ext,l.line_no


select @tmp_ctrl_num = isnull((select min(tmp_ctrl_num) from #post_orders),NULL)

while @tmp_ctrl_num is not NULL
begin
	select 	@trx_type = trx_type ,
		@date_applied = date_applied,
		@nat_cur_code = nat_cur_code,
		@rate_type_home = rate_type_home,
		@rate_type_oper = rate_type_oper,
		@home_rate = rate_home,
		@oper_rate = rate_oper,
    @doc_ctrl_num = doc_ctrl_num
	from 	#post_orders 
	where tmp_ctrl_num = @tmp_ctrl_num

  EXEC @result = arnewnum_sp @trx_type, @trx_ctrl_num OUTPUT
  IF ( @result != 0 )
  BEGIN
    SELECT @err = 19
    exec  adm_post_ar_cons_cancel_tax @msg2 out
    select @msg2 = 'Error 19'
    select @msg = ''

    goto write_admresults
  END

  DECLARE @ltrx_ctrl_num varchar(16)

  DECLARE update_order_cursor CURSOR LOCAL FORWARD_ONLY STATIC FOR
  SELECT distinct oi.trx_ctrl_num
  FROM #post_orders_det o
  left outer join orders_invoice oi on oi.order_no = o.order_no and oi.order_ext = o.ext
  WHERE o.doc_ctrl_num = @doc_ctrl_num

  OPEN update_order_cursor 

  WHILE @@cursor_rows != 0
  BEGIN
    FETCH NEXT FROM update_order_cursor INTO @ltrx_ctrl_num

    if @@FETCH_STATUS <> 0
      BREAK

    exec @rc = TXavataxlink_upd_sp @ltrx_ctrl_num, @trx_type, 'DELETE', @msg2 out
  END
  CLOSE update_order_cursor 
  DEALLOCATE update_order_cursor 

  delete oi
  from #post_orders_det o
  join orders_invoice oi on oi.order_no = o.order_no and oi.order_ext = o.ext
  WHERE o.doc_ctrl_num = @doc_ctrl_num

  INSERT orders_invoice ( order_no, order_ext, doc_ctrl_num, trx_ctrl_num )
  SELECT a.order_no, a.ext, @doc_ctrl_num, @trx_ctrl_num
  FROM #post_orders_det a
  where a.doc_ctrl_num = @doc_ctrl_num

  select @rc = 1

  exec @tax_rc = adm_calculate_consinvtax_wrap @doc_ctrl_num = @doc_ctrl_num,
    @debug = 0, @batch_call = 1,  @doctype = 1, @trx_ctrl_num = @trx_ctrl_num, 
    @err_msg = @err_msg OUT
  if @tax_rc <> 1
  begin
    exec adm_post_ar_cons_cancel_tax @msg2 out
    set @err = -2
    set @msg = 'Tax not calculated successfully'
    set @msg2 = @err_msg
    set @result = @tax_rc

    goto write_admresults
  end

  insert #orders (doc_ctrl_num, trx_ctrl_num, trx_type)
  select @doc_ctrl_num, @trx_ctrl_num, @trx_type

  IF ( @@error != 0 )
  BEGIN
    select @msg = 'Could not insert on #orders table'
    exec adm_post_ar_cons_cancel_tax @msg2 out
    set @err = -2
    set @msg2 = ''
    set @result = @tax_rc

    goto write_admresults
  END     

  select @precision = curr_precision
  from glcurr_vw (nolock)
  where currency_code = @nat_cur_code

  select @home_override_flag = ISNULL(( select override_flag
  FROM 	glcurate_vw (nolock)
  WHERE from_currency = @nat_cur_code AND to_currency = @home_currency
  AND rate_type = @rate_type_home AND inactive_flag = 0),0)

  select @oper_override_flag = ISNULL(( select override_flag
  FROM 	glcurate_vw (nolock)
  WHERE from_currency = @nat_cur_code AND to_currency = @oper_currency
  AND rate_type = @rate_type_oper AND inactive_flag = 0),0)

  IF(@home_override_flag = 0)
  BEGIN
    EXEC @result = adm_mccurate_sp
      @date_applied,	@nat_cur_code,	@home_currency,		
      @rate_type_home, @home_rate OUTPUT, 0, @divide_flag_h	OUTPUT
		
    IF ( @result != 0 ) SELECT @home_rate = 0
  END

  IF(@oper_override_flag = 0)
  BEGIN
    EXEC @result = adm_mccurate_sp
      @date_applied, @nat_cur_code, @oper_currency,		
      @rate_type_oper, @oper_rate OUTPUT, 0, @divide_flag_o OUTPUT
					
    IF ( @result != 0 ) SELECT @oper_rate = 0
  END








		
INSERT #arinpcdt (trx_ctrl_num,	doc_ctrl_num,	sequence_id,	trx_type,	location_code,
	item_code,	bulk_flag,	date_entered,	line_desc, 	qty_ordered,
	qty_shipped,	unit_code,	unit_price,	unit_cost,	weight,
	serial_id,	tax_code,	gl_rev_acct,	disc_prc_flag,	discount_amt,
	commission_flag,	rma_num,	return_code,	qty_returned,
	qty_prev_returned,	new_gl_rev_acct,	iv_post_flag,	oe_orig_flag,
	trx_state,	mark_flag,	discount_prc,	extended_price,	calc_tax,
	reference_code, cust_po, org_id)
SELECT
	@trx_ctrl_num,	o.doc_ctrl_num,	l.row_id,	o.trx_type,	substring(l.location,1,8),
	l.part_no,	0,	o.date_entered,	
	case when isnull(l.contract,'') != '' then
	  Substring( convert(varchar(60),isnull(l.description,'')), 1, ( 60 - ( len( isnull(l.contract,'') ) + 11 ) )) + ' Contract: ' + l.contract
          else convert(varchar(60),isnull(l.description,''))
        end,
	case o.trx_type when 2031 then l.ordered else 0 end,
	case o.trx_type when 2031 then l.shipped else 0 end,
	l.uom,	l.curr_price,	(l.cost + l.direct_dolrs + l.ovhd_dolrs + l.util_dolrs), 
	isnull(weight_ea * (shipped + cr_shipped),0), 0,l.tax_code,	l.gl_rev_acct,	1,	
	CASE o.trx_type
          WHEN 2031 THEN round(( (l.shipped  * l.curr_price) * (l.discount / 100.00)),@precision)	-- mls 10/16/00 SCR 24556
          ELSE round(( (l.cr_shipped * l.curr_price) *  (l.discount / 100.00)),@precision)		-- mls 10/16/00 SCR 24556
        END,
	0,	'',
	case o.trx_type when 2031 then '' else isnull(l.return_code,'') end,				-- mls 5/18/05 SCR 34563
	case o.trx_type when 2031 then 0 else l.cr_shipped end,
	0,	'',	0,	1, 	0,	0,	l.discount,	
        CASE o.trx_type
          WHEN 2031 THEN round(l.shipped * l.curr_price,@precision) - 
		round(( (l.shipped * l.curr_price) * (l.discount / 100.00)),@precision)			-- mls 10/16/00 SCR 24556
          ELSE round(l.cr_shipped * l.curr_price,@precision) -  
		round(( (l.cr_shipped * l.curr_price) * (l.discount / 100.00)),@precision) 		-- mls 10/27/00 SCR 24556
          END,
	l.total_tax, isnull(l.reference_code,''), 
        isnull(l.cust_po,d.cust_po), l.organization_id							-- mls 10/19/04 SCR 33381
  
  FROM  #post_orders o, #ord_list l (nolock), #post_orders_det d
  WHERE o.order_no = d.max_order 
	AND o.ext = d.max_ext 
	AND l.order_no = d.order_no
	AND l.order_ext = d.ext
	and o.tmp_ctrl_num = @tmp_ctrl_num 
	and (l.shipped > 0 or l.cr_shipped > 0) 					-- mls 1/21/2000
  

  IF ( @@error != 0 )
  BEGIN
    exec adm_post_ar_cons_cancel_tax @msg2 out
    select @err = 70
    select @msg2 = 'Error inserting into #arinpcdt'
    select @msg = ''
    set @result = @err

    goto write_admresults
  END     

	-- SCR 18116 thl 09/08/99 start
	if ( @contract != '' ) begin
		if ( len( @line_desc ) + len( @contract ) + 11 > 255 ) 
		begin
			select @line_desc = Substring( @line_desc, 1, ( 255 - ( len( @contract ) + 11 ) ) )
		end
		select @line_desc = @line_desc + ' Contract: ' + @contract
	end
	-- SCR 18116 thl 09/08/99 end


  
  SELECT @total_weight = sum(weight), @total_cost = sum(unit_cost * (qty_shipped + qty_returned))
  FROM #arinpcdt 
  where trx_ctrl_num = @trx_ctrl_num

  Update #post_orders
  set trx_ctrl_num = @trx_ctrl_num,
      total_weight = @total_weight,
      amt_cost = @total_cost,
      rate_home = @home_rate,
      rate_oper = @oper_rate,
      nat_precision = @precision,
      home_override_flag = @home_override_flag,
      oper_override_flag = @oper_override_flag
  where tmp_ctrl_num = @tmp_ctrl_num

  	select @tmp_ctrl_num = isnull((select min(tmp_ctrl_num) 
	from #post_orders 
	where tmp_ctrl_num > @tmp_ctrl_num),NULL)

END -- while tmp_ctrl_num not null


insert into #arterm
select distinct date_doc, terms_code,0,0
from #post_orders

exec ARGetTermInfo_SP

Update #post_orders
set date_due = a.date_due
from #arterm a, #post_orders o
where a.terms_code = o.terms_code and a.date_doc = o.date_doc

update o									-- mls 3/8/06 SCR 35922
set comment_code = isnull(a.inv_comment_code,'')
from #post_orders o
join adm_cust_all a (nolock) on a.customer_code = o.customer_code

INSERT #arinpchg ( 
	trx_ctrl_num,		doc_ctrl_num,		doc_desc,
    	apply_to_num,		apply_trx_type,		order_ctrl_num,
	batch_code, 		trx_type,		date_entered,
	date_applied,		date_doc,		date_shipped,
	date_required,		date_due,		date_aging,
 	customer_code, 		ship_to_code, 		salesperson_code,
	territory_code,		comment_code,		fob_code,
	freight_code,		terms_code,		fin_chg_code,
	price_code,		dest_zone_code,		posting_code,
 	recurring_flag,		recurring_code,		tax_code,
 	cust_po_num,		total_weight, 		amt_gross,
 	amt_freight, 		amt_tax, 		amt_discount,
 	amt_net,		amt_paid,		amt_due,				
	amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,
	hold_desc,		user_id,		customer_addr1,
	customer_addr2,		customer_addr3,		customer_addr4,
	customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,
	ship_to_addr5,		ship_to_addr6,		attention_name,
	attention_phone,	amt_rem_rev,		amt_rem_tax,
	date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,
	amt_write_off_given,	source_trx_ctrl_num,	source_trx_type,
	nat_cur_code,		rate_type_home,		rate_type_oper,
	rate_home,		rate_oper,		edit_list_flag, 
	amt_tax_included,	org_id,
	customer_city, customer_state, customer_postal_code, customer_country_code,
	ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code,
	writeoff_code)
select
	trx_ctrl_num,		doc_ctrl_num,		doc_desc + tmp_ctrl_num + '' + convert(varchar(10),user_id),
    	apply_to_num,		apply_trx_type,		order_ctrl_num,
	batch_code, 		trx_type,		date_entered,
	date_applied,		date_doc,		date_shipped,
	date_required,		date_due,		date_aging,
 	customer_code, 		ship_to_code, 		salesperson_code,
	territory_code,		comment_code,		fob_code,
	'',			terms_code,		fin_chg_code,			-- mls 4/20/06 SCR 36110
	price_code,		dest_zone_code,		posting_code,
 	recurring_flag,		recurring_code,		tax_code,
 	cust_po_num,		total_weight, 		amt_gross,
 	amt_freight, 		amt_tax, 		amt_discount,
 	amt_net,		amt_paid,		amt_due,				
	amt_cost,		amt_profit,		next_serial_id,
	printed_flag,		posted_flag,		hold_flag,
	hold_desc,		user_id,		customer_addr1,
	customer_addr2,		customer_addr3,		customer_addr4,
	customer_addr5,		customer_addr6,		ship_to_addr1,
	ship_to_addr2,		ship_to_addr3,		ship_to_addr4,
	ship_to_addr5,		ship_to_addr6,		attention_name,
	attention_phone,	amt_rem_rev,		amt_rem_tax,
	date_recurring,		location_code,		process_group_num,
	trx_state,		mark_flag,		amt_discount_taken,
	amt_write_off_given,	source_trx_ctrl_num,	source_trx_type,
	nat_cur_code,		rate_type_home,		rate_type_oper,
	rate_home,		rate_oper,		edit_list_flag, 
	amt_tax_included,	organization_id,
	ship_to_city, ship_to_state, ship_to_zip, ship_to_country_cd,
	ship_to_city, ship_to_state, ship_to_zip, ship_to_country_cd, 
	''
FROM #post_orders

IF ( @@error != 0 )
BEGIN
  exec adm_post_ar_cons_cancel_tax @msg2 out
  SELECT @err = 20 
  select @msg2 = 'Error inserting #arinpchg'
  select @msg = ''
  set @result = @err

  goto write_admresults
END

  update r
  set amt_gross = o.amt_gross,
    amt_tax = o.amt_tax,
    doc_ctrl_num = o.doc_ctrl_num
  from gltcrecon r
  join #post_orders o on r.trx_ctrl_num = o.trx_ctrl_num and r.trx_type = o.trx_type


-- Call gltrxcra_sp  --Aging Record
INSERT #arinpage (
	trx_ctrl_num,	sequence_id,		doc_ctrl_num,	apply_to_num,
	apply_trx_type,	trx_type,	date_applied,	date_due,
	date_aging,	customer_code,	salesperson_code,	territory_code,
	price_code,	amt_due,	trx_state,	mark_flag )
SELECT	trx_ctrl_num,	1,		doc_ctrl_num,	'',
	0,	trx_type,	date_applied,	date_due,
	date_aging,	customer_code,	salesperson_code,	territory_code,
	price_code,	amt_net,	2,	0 
FROM #post_orders

IF ( @@error != 0 )
BEGIN
  exec adm_post_ar_cons_cancel_tax @msg2 out
  SELECT @err = 30
  select @msg2 = 'Error inserting #arinpage'
  select @msg = ''
  set @result = @err

  goto write_admresults
END

--Process Commissions
INSERT #arinpcom (
	trx_ctrl_num,	trx_type,	sequence_id,	salesperson_code,
	amt_commission,	percent_flag,	exclusive_flag,	split_flag,
	trx_state,	mark_flag )
SELECT  trx_ctrl_num,	trx_type,	display_line,	r.salesperson,
	r.sales_comm,	r.percent_flag,	r.exclusive_flag, r.split_flag,					-- mls 1/24/01 SCR 25381
	2,	0 
FROM #post_orders o, ord_rep r (nolock)
where o.order_no = r.order_no and o.ext = r.order_ext 


IF ( @@error != 0 )
BEGIN
  exec adm_post_ar_cons_cancel_tax @msg2 out
  SELECT @err = 50
  select @msg2 = 'Error inserting #arinpcom'
  select @msg = ''
  set @result = @err
  goto write_admresults
END
	


--Process Tax Records
INSERT 	#arinptax (	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,
	amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	trx_state,
	mark_flag )
SELECT  o.trx_ctrl_num,  2031,  t.sequence_id,  t.tax_type_code,          -- mls 9/29/03 SCR 31944
  t.amt_taxable,  t.amt_gross,  t.amt_tax,  t.amt_final_tax,  2,   0
FROM   #post_orders o, #ord_list_tax t (nolock)
where   o.doc_ctrl_num = t.doc_ctrl_num
and   (@AR_INCL_NON_TAX = 'Y' or t.amt_final_tax <> 0)            -- mls 12/22/00 SCR 23738


IF ( @@error != 0 )
BEGIN
  exec adm_post_ar_cons_cancel_tax @msg2 out
  SELECT @err = 60
  select @msg2 = 'Error inserting #arinptax'
  select @msg = ''
  set @result = @err

  goto write_admresults
END

CREATE TABLE #arvalcdt (
	trx_ctrl_num		varchar(16),
	doc_ctrl_num		varchar(16),
	sequence_id	 	int,
	trx_type	 	smallint,
	location_code		varchar(8),
	item_code	 	varchar(30),
	bulk_flag	 	smallint,
	date_entered		int,
	line_desc	 	varchar(60),		
	qty_ordered	 	float,
	qty_shipped	 	float,
	unit_code	 	varchar(8),
	unit_price	 	float,
	unit_cost	 	float,
	extended_price	float,
	weight	 		float,

	serial_id	 	int,
	tax_code	 	varchar(8),
	gl_rev_acct	 	varchar(32),
	disc_prc_flag		smallint,
	discount_amt		float,
	discount_prc		float,
	commission_flag	smallint,
	rma_num		varchar(16),
	return_code	 	varchar(8),
	qty_returned		float,
	qty_prev_returned	float,
	new_gl_rev_acct	varchar(32),		
	iv_post_flag		smallint,	
	oe_orig_flag		smallint,	
	calc_tax		float,
	reference_code	varchar(32) NULL,
	temp_flag		smallint NULL,
	org_id			varchar(30) NULL,
	temp_flag2		int NULL
)

CREATE TABLE #arvalage (
	trx_ctrl_num		varchar(16),
	sequence_id		int,	
	doc_ctrl_num		varchar(16),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	trx_type		smallint,
	date_applied		int,
	date_due		int,
	date_aging		int,
	customer_code		varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	price_code		varchar(8),
	amt_due		float,
	temp_flag	  	smallint NULL
)


CREATE TABLE #arvaltax (
	trx_ctrl_num		varchar(16),
	trx_type        	smallint,
	sequence_id     	int,
	tax_type_code   	varchar(8),
	amt_taxable     	float,
	amt_gross       	float,
	amt_tax 		float,
	amt_final_tax   	float,
	temp_flag	  	smallint NULL
)

CREATE TABLE #arvaltmp (
	trx_ctrl_num		varchar(16),	
	doc_ctrl_num		varchar(16), 
	date_doc		int,
	customer_code		varchar(8),
	payment_code		varchar(8),
	amt_payment		float,
	amt_disc_taken	float,
	cash_acct_code	varchar(32),
	temp_flag	  	smallint NULL
)

CREATE TABLE #arvalrev (
	trx_ctrl_num	varchar(16),
	sequence_id	int,
	rev_acct_code	varchar(32),
	apply_amt	float,
	trx_type	smallint,
        reference_code  varchar(32) NULL,
	temp_flag 	smallint,
	org_id		varchar(30) NULL
)

CREATE TABLE #arinbat (
	date_applied		int, 
	process_group_num	varchar(16),
	trx_type		smallint,
	batch_ctrl_num char(16) NULL,
	flag			smallint,
	org_id			varchar(30) NULL
)

CREATE TABLE #arbatsum (
	batch_ctrl_num char(16) NOT NULL,
	actual_number int NOT NULL,
	actual_total float NOT NULL
)

CREATE TABLE #arbatnum(
	date_applied		int,
	process_group_num	varchar(16),
	trx_type		smallint,
	flag			smallint,
	batch_ctrl_num		char(16) NULL,
	batch_description   char(30)            NULL,
	company_code        char(8)             NULL,
	seq			numeric identity,
	org_id			varchar(30) NULL
)

CREATE TABLE #aritemp (
	code varchar(8),
	code2 varchar(8),
	mark_flag	smallint,
	amt_home float,
	amt_oper float
)


--Populate validation files
EXEC @result = ARINSrcInsertValTables_SP

IF @result !=  0
BEGIN
  exec adm_post_ar_cons_cancel_tax @msg2 out
  select @err = 70
  select @msg2 = 'Error with ARINSrcInsertValTables_SP'
  select @msg = ''

  goto write_admresults
END


IF @trx_type =  2031  
BEGIN


	EXEC @result = arinvedt_sp 1 
	IF @result !=  0
	BEGIN
    exec adm_post_ar_cons_cancel_tax @msg2 out
    select @err = 80
    select @msg2 = 'Error with arinvedt_sp'
    select @msg = ''

    goto write_admresults
	END


	DELETE from #ewerror 								
	where err_code = 20001  	
  DELETE from #ewerror where err_code = 20097    -- mls 4/21/06 SCR 35623
  DELETE from #ewerror where err_code = 20070      -- mls 4/21/06 SCR 35623

	IF (select count(*) from #ewerror) > 0
	begin
    select @err = 90
    exec adm_post_ar_cons_cancel_tax @msg2 out

    insert #adm_results (
      module_id,   err_code,   info1,     info2 ,
      infoint,     infofloat ,   flag1 ,   trx_ctrl_num ,   sequence_id , 
      source_ctrl_num ,  extra, order_no, order_ext, ewerror_ind)
    select 
      e.module_id,   e.err_code,   e.info1,   e.info2 ,
      e.infoint,     e.infofloat ,   e.flag1 ,   e.trx_ctrl_num,  e.sequence_id, 
      e.source_ctrl_num , e.extra,   p.order_no,   p.ext, 1
    from #ewerror e, #post_orders p
    where e.trx_ctrl_num = p.trx_ctrl_num
    set @result = @err
    goto ret_process
	END

END


BEGIN TRAN

EXEC @result = arinsav_sp @user_id, @new_batch_code OUTPUT

IF @result !=  0
BEGIN

  ROLLBACK TRAN
  exec adm_post_ar_cons_cancel_tax @msg2 out
  select @err = 95
  select @msg2 = 'Error with arinsav_sp'
  select @msg = ''

  goto write_admresults

END



UPDATE 	o
SET 	o.invoice_no 	=  p.invoice_no
FROM 	#post_orders_det p, orders_all o
WHERE 	p.order_no 	= o.order_no 
AND	p.ext 		= o.ext 


COMMIT TRAN

  select @msg = 'OK'
  select @msg2 = ''
  set @err = 1
  set @result = 1

write_admresults:
  insert #adm_results (
    module_id,   err_code,   info1,     info2 ,
    infoint,     infofloat ,   flag1 ,   trx_ctrl_num ,   sequence_id , 
    source_ctrl_num ,  extra, order_no, order_ext, ewerror_ind)
  select 
    18000,   @result,   @msg ,   @msg2,
    0,     0 ,   '' ,   '',  '',
    @trx_ctrl_num , '',   @ord,   @ext, 0


ret_process:

    select @err, 0,   module_id,   err_code,   info1,   
      case when ewerror_ind = 0 then '' else info2 end ,
      infoint,     infofloat ,   flag1 ,   trx_ctrl_num ,   sequence_id , 
      source_ctrl_num ,  extra,     order_no,   order_ext,
    a.refer_to, a.field_desc, 
      case when ewerror_ind = 1 then a.err_desc else info2 end err_desc
    from #adm_results e
    left outer join aredterr a on a.e_code = e.err_code and e.ewerror_ind = 1

return @err


GO
GRANT EXECUTE ON  [dbo].[sh_consinv] TO [public]
GO
