SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_post_ar_group] @user varchar(30),				-- mls 5/22/00 SCR 22851
                            @process_ctrl_num varchar(16)
AS



DECLARE  @disc_prc_flag smallint,
         @exclusive_flag smallint,
         @module_id smallint,
         @next_serial_id smallint,
         @percent_flag smallint,
         @printed_flag smallint,
         @split_flag smallint,
         @trx_type smallint,
         @user_id smallint,
         @val_mode smallint,
         @err int


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
         @xlp int,
		 @msg varchar(32), @msg2 varchar(255), @err_msg varchar(255),
	     @consolidate_flag int, @eprocurement_ind int

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

DECLARE	@aging char(1),
         @ord_type char(1),
         @printed char(1), 
         @type char(1),
         @unit_code char(2), 
         @locacct char(2),
         @customer char(10), 
         @inv_account char(32),
         @cog_account char(32),
         @rev_account char(32)

DECLARE	@territory varchar(6),
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
DECLARE @tcn_mask varchar(16),  @first_tcn int

DECLARE @home_currency varchar(8), @oper_currency varchar(8),
@home_override_flag smallint, @oper_override_flag smallint,
@divide_flag_h smallint, @divide_flag_o smallint
DECLARE @tmp_ctrl_num varchar(16)

-- Get system Default Values 

SELECT @module_id  = 2001
SELECT @company_id = company_id FROM arco
SELECT @aging      = isnull((select value_str FROM config WHERE flag = 'ACCNT_AGING'),'R')

SELECT @AR_INCL_NON_TAX = isnull((select upper(substring(value_str,1,1)) 	
  FROM config WHERE flag = 'AR_INCL_NON_TAX'),'N')				-- mls 12/22/00 SCR 23738

SELECT @printed    = value_str FROM config WHERE flag = 'PLT_PRINT_INV'
SELECT @home_currency = home_currency,	@oper_currency = oper_currency 
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
  order_no int,				ext int,					trx_ctrl_num varchar(16),
  trx_type int)

create index to_0 on #orders (order_no, ext)
create index to_1 on #orders (trx_type, trx_ctrl_num)

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
	info2 char(255),
	infoint int,
	infofloat float,
	flag1 smallint,
	trx_ctrl_num char(16),
	sequence_id int,
	source_ctrl_num char(16),
	extra int
)
CREATE TABLE #arvalchg (
  trx_ctrl_num	  varchar(16),		doc_ctrl_num    varchar(16),		doc_desc	varchar(40),
  apply_to_num    varchar(16),		apply_trx_type  smallint,		order_ctrl_num  varchar(16),
  batch_code      varchar(16),		trx_type        smallint,		date_entered    int,
  date_applied    int,			date_doc        int,			date_shipped    int,
  date_required   int,			date_due        int,			date_aging      int,
  customer_code   varchar(8),		ship_to_code    varchar(8),		salesperson_code varchar(8),
  territory_code  varchar(8),		comment_code    varchar(8),		fob_code        varchar(8),
  freight_code    varchar(8),		terms_code      varchar(8),		fin_chg_code    varchar(8),
  price_code      varchar(8),		dest_zone_code  varchar(8),		posting_code    varchar(8),
  recurring_flag  smallint,		recurring_code  varchar(8),		tax_code        varchar(8),
  cust_po_num     varchar(20),		total_weight    float,			amt_gross       float,
  amt_freight     float,		amt_tax 	float,			amt_tax_included float,
  amt_discount    float,		amt_net 	float,			amt_paid        float,
  amt_due 	  float,		amt_cost        float,			amt_profit      float,
  next_serial_id  smallint,		printed_flag    smallint,		posted_flag     smallint,
  hold_flag       smallint,		hold_desc	varchar(40),		user_id 	smallint,
  customer_addr1  varchar(40),		customer_addr2	varchar(40),		customer_addr3	varchar(40),
  customer_addr4  varchar(40),		customer_addr5	varchar(40),		customer_addr6	varchar(40),
  ship_to_addr1	  varchar(40),		ship_to_addr2	varchar(40),		ship_to_addr3	varchar(40),
  ship_to_addr4	  varchar(40),		ship_to_addr5	varchar(40),		ship_to_addr6	varchar(40),
  attention_name  varchar(40),		attention_phone	varchar(30),		amt_rem_rev     float,
  amt_rem_tax     float,		date_recurring  int,			location_code   varchar(8),
  process_group_num varchar(16) NULL, 	source_trx_ctrl_num varchar(16) NULL,   source_trx_type smallint NULL,	
  amt_discount_taken float NULL,	amt_write_off_given float NULL,		nat_cur_code    varchar(8),
  rate_type_home  varchar(8),  		rate_type_oper  varchar(8),  		rate_home       float, 
  rate_oper       float, 		temp_flag	smallint NULL, 		org_id		varchar(30) NULL, 
  interbranch_flag int NULL, 		temp_flag2 	smallint NULL		)




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
	org_id	varchar(30) NULL,
  customer_city varchar(40), customer_state varchar(40), customer_postal_code varchar(15), customer_country_code varchar(3),
  ship_to_city varchar(40), ship_to_state varchar(40), ship_to_postal_code varchar(15), ship_to_country_code varchar(3),
writeoff_code varchar(8)
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
	cust_po 		VARCHAR(20)	NULL,	-- REV 11
	org_id			varchar(30)	NULL
)

CREATE UNIQUE INDEX arinpcdt_ind_0 ON #arinpcdt ( trx_ctrl_num, trx_type, sequence_id )


-- mls 12/30/03 SCR 32276 end
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
  customer_city varchar(40), customer_state varchar(40), customer_postal_code varchar(15), customer_country_code varchar(3),
  ship_to_city varchar(40), ship_to_state varchar(40), ship_to_postal_code varchar(15), ship_to_country_code varchar(3)
)
CREATE INDEX post_orders1 on #post_orders (order_no, ext)
CREATE INDEX post_orders2 on #post_orders (tmp_ctrl_num)
CREATE INDEX post_orders4 on #post_orders (terms_code, date_doc)
CREATE INDEX post_orders5 on #post_orders (nat_cur_code)


-- ******************************************************************************
CREATE TABLE #consolidated_post_orders (
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
	organization_id varchar(30),
  customer_city varchar(40), customer_state varchar(40), customer_postal_code varchar(15), customer_country_code varchar(3),
  ship_to_city varchar(40), ship_to_state varchar(40), ship_to_postal_code varchar(15), ship_to_country_code varchar(3)
)
CREATE INDEX cons_post_orders1 on #consolidated_post_orders (order_no, ext)
CREATE INDEX cons_post_orders2 on #consolidated_post_orders (tmp_ctrl_num)
CREATE INDEX cons_post_orders4 on #consolidated_post_orders (terms_code, date_doc)
CREATE INDEX cons_post_orders5 on #consolidated_post_orders (nat_cur_code)

-- ******************************************************************************
declare @rc int , @tax_rc int, @in_cursor int
    select @rc = 1
    set @in_cursor = 0
    DECLARE orders_cursor CURSOR LOCAL STATIC FOR
    SELECT o.order_no, o.ext
	FROM load_master_all l
	join orders_all o (nolock) on l.load_no = o.load_no and o.status in ('R','S','W')
	WHERE l.process_ctrl_num = @process_ctrl_num 

    OPEN orders_cursor
	set @in_cursor = 1
    FETCH NEXT FROM orders_cursor into @ord, @ext

    While @@FETCH_STATUS = 0
    begin
      if not exists (select 1 from ord_list where order_no = @ord
        and order_ext = @ext and (shipped <> 0))
      begin
		  set @err = -10
		  set @msg2 = 'Cannot post a load with orders that are not shipped'
		  set @msg = ''
          set @result = -10

		  goto write_admresults
      end

        exec @tax_rc = fs_calculate_oetax_wrap @ord = @ord, @ext = @ext,
          @batch_call = 1
        if @tax_rc <> 1
        begin
		  set @err = -2
		  set @msg = 'Tax not calculated successfully'
		  set @msg2 = @err_msg
          set @result = @tax_rc

		  goto write_admresults
        end
     
      FETCH NEXT FROM orders_cursor into @ord, @ext
    end

    close orders_cursor
    deallocate orders_cursor
    set @in_cursor = 0

    begin tran
    UPDATE load_master_all
    SET status = 'S'
    WHERE process_ctrl_num = @process_ctrl_num and status < 'S'

    IF @@error <> 0   
    BEGIN
      rollback tran
	  set @err = -3
	  set @msg2 = 'Error updating load to status S'
	  set @msg = ''
      set @result = -3

	  goto write_admresults
    END

    if exists (select 1 FROM orders_all o, load_master_all l 
      WHERE l.process_ctrl_num = @process_ctrl_num and l.load_no = o.load_no and
      o.status = 'R')
    begin
      rollback tran
	  set @err = -30
	  set @msg2 = 'Load in status S but orders on load in status R'
	  set @msg = ''
      set @result = -30

	  goto write_admresults
    end

if exists (select 1 from config (nolock) where upper(flag) = 'CCA' and upper(value_str) = 'Y')
begin
  if exists (select 1 from config (nolock) where upper(flag) = 'ICV_CREDIT' and upper(value_str) like 'Y%')
    and exists (select 1 FROM orders_all o, load_master_all l 
      WHERE l.process_ctrl_num = @process_ctrl_num and l.load_no = o.load_no and
      o.status in ('S','W') and o.type = 'C')
  begin
    select @rc = 1
    DECLARE orders_cursor CURSOR LOCAL STATIC FOR
    SELECT o.order_no, o.ext
    FROM load_master_all l
    join orders_all o on  l.load_no = o.load_no and o.status in ('S','W') and o.type = 'C'
    WHERE l.process_ctrl_num = @process_ctrl_num 

    OPEN orders_cursor
    set @in_cursor = 1
    FETCH NEXT FROM orders_cursor into @ord, @ext

    While @@FETCH_STATUS = 0
    begin
      exec @rc = adm_cca_process 'CR', @ord, @ext
      if @rc in (0,-2)
        break

      FETCH NEXT FROM orders_cursor into @ord, @ext
    end

    close orders_cursor
    deallocate orders_cursor
    set @in_cursor = 0

    if @rc in (0,-2)
    begin
		  ROLLBACK TRAN

		  set @err = -4
		  set @msg = ''
  	      select @msg2 = 'Error return from credit card process (' + convert(varchar,@rc) + ')'
          set @result = @rc

		  goto write_admresults
    end
  end

  if exists (select 1 from config (nolock) where upper(flag) = 'ICV_POST' and upper(value_str) in ('A','S','B'))
    and exists (select 1 FROM orders_all o, load_master_all l 
      WHERE l.process_ctrl_num = @process_ctrl_num and l.load_no = o.load_no and
      o.status in ('S','W') and o.type = 'I')
  begin
    select @rc = 1
    DECLARE orders_cursor CURSOR LOCAL STATIC FOR
    SELECT o.order_no, o.ext
    FROM load_master_all l 
    join orders_all o on l.load_no = o.load_no and o.status in ('S','W') and o.type = 'I'
      WHERE l.process_ctrl_num = @process_ctrl_num

    OPEN orders_cursor
    set @in_cursor = 1
    FETCH NEXT FROM orders_cursor into @ord, @ext

    While @@FETCH_STATUS = 0
    begin
      exec @rc = adm_cca_process 'PST', @ord, @ext
      if @rc in (0,-2)
        break

      FETCH NEXT FROM orders_cursor into @ord, @ext
    end

    close orders_cursor
    deallocate orders_cursor
    set @in_cursor = 0

    if @rc in (0,-2)
    begin
	    ROLLBACK TRAN

        select @msg = ''
	    select @msg2 = 'Error return from credit card process (' + convert(varchar,@rc) + ')'
		  set @err = -4
          set @result = @rc

		  goto write_admresults
    end
  end
end

COMMIT TRAN


    DECLARE orders_cursor CURSOR LOCAL STATIC FOR
    SELECT o.order_no, o.ext,
      case when o.type = 'I' then 2031 else 2032 end trx_type, oi.trx_ctrl_num,
      oi.doc_ctrl_num
	FROM load_master_all l
	join orders_all o (nolock) on l.load_no = o.load_no
	left outer join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
	WHERE l.process_ctrl_num = @process_ctrl_num and o.status in ('S','W')
      and isnull(o.consolidate_flag,0) = 0 and isnull(o.eprocurement_ind,0) = 0

    OPEN orders_cursor
    set @in_cursor = 1
    FETCH NEXT FROM orders_cursor into @ord, @ext, @trx_type, @trx_ctrl_num,
      @doc_ctrl_num

    While @@FETCH_STATUS = 0
    begin
      IF (@doc_ctrl_num is null)
      BEGIN
        exec adm_post_ar_cancel_tax @msg2 out
        select @msg2 = 'Record not on orders invoice table'
        select @msg = ''
        set @err = -21
        set @result = @err

	    goto write_admresults
      END

      if isnull(@trx_ctrl_num,'') = ''
      BEGIN
        EXEC @result = adm_arnewnum_sp @trx_type, 1, @first_tcn OUT, @tcn_mask OUTPUT
        IF ( @result != 0 )
        BEGIN
		  exec adm_post_ar_cancel_tax @msg2 out
          select @msg2 = 'Could not generate trx control number.'
          select @msg = ''
		  set @err = -20
          set @result = @err

		  goto write_admresults
        END

        select @trx_ctrl_num = dbo.adm_fmtctlnm_fn(@first_tcn, @tcn_mask)

        update orders_invoice set trx_ctrl_num = @trx_ctrl_num
        where order_no = @ord and order_ext = @ext
      END
      else
      begin
        -- if tax record exists, remove it
        exec @tax_rc = adm_post_ar_cancel_tax @msg2 OUT, @trx_ctrl_num, @trx_type
        if @tax_rc < 1
        begin
		  exec adm_post_ar_cancel_tax @msg2 out
          select @msg = ''
		  set @err = -21
          set @result = @err

		  goto write_admresults
        end      
      end

      if isnull(@trx_ctrl_num,'') = ''
      BEGIN
        exec adm_post_ar_cancel_tax @msg2 out
        select @msg2 = 'Could not generate masked trx control number.'
        select @msg = ''
        set @err = -22
        set @result = @err

	    goto write_admresults
      END

        exec @tax_rc = fs_calculate_oetax_wrap @ord = @ord, @ext = @ext,
          @debug = 0, @batch_call = 1,  @doctype = 1, @trx_ctrl_num = @trx_ctrl_num, 
          @err_msg = @err_msg OUT
        if @tax_rc <> 1
        begin
		  exec adm_post_ar_cancel_tax @msg2 out

		  set @err = -2
		  set @msg = 'Tax not calculated successfully'
		  set @msg2 = @err_msg
          set @result = @tax_rc

		  goto write_admresults
        end

        insert #orders (order_no, ext, trx_ctrl_num, trx_type)
	    select	@ord,  @ext, @trx_ctrl_num, @trx_type

        IF ( @@error != 0 )
	    BEGIN
		  exec adm_post_ar_cancel_tax @msg2 out

		  set @err = -2
		  set @msg = 'Tax not calculated successfully'
		  set @msg2 = ''
          set @result = 0

		  goto write_admresults
  	    END

      FETCH NEXT FROM orders_cursor into @ord, @ext, @trx_type, @trx_ctrl_num,
        @doc_ctrl_num
    end

    close orders_cursor
    deallocate orders_cursor
    set @in_cursor = 0


select @ord = 0, @ext = 0

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
	oper_override_flag,	organization_id ,
	customer_city, customer_state, customer_postal_code, customer_country_code,
	ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code)
select	
  o.order_no,  o.ext,
  convert(varchar(11),o.order_no) + '-' + convert(varchar(4),o.ext),	-- tmp_ctrl_num 
  t.trx_ctrl_num,  oi.doc_ctrl_num, 	
  CASE type WHEN 'I' THEN 'SO:' ELSE 'CM:' END, -- doc_desc
  '', 0, (convert(varchar(10),o.order_no) + '-' + convert(varchar(10),o.ext)),  
  '', CASE type WHEN 'I' THEN 2031 ELSE 2032 END, 			
  datediff(day,'01/01/1900',getdate()) + 693596, 
  CASE @aging
    WHEN 'R' THEN datediff(day,'01/01/1900',o.date_shipped) + 693596
    ELSE  datediff(day,'01/01/1900',invoice_date) + 693596
  END, -- date_applied,		
  CASE @aging
    WHEN 'R' THEN datediff(day,'01/01/1900',o.date_shipped) + 693596
    ELSE  datediff(day,'01/01/1900',invoice_date) + 693596
  END, -- date_doc,			
  datediff(day,'01/01/1900',o.date_shipped) + 693596, -- date_shipped,
  datediff(day,'01/01/1900',req_ship_date) + 693596, -- date_required,		
  0, -- date_due,			
  CASE @aging
    WHEN 'R' THEN datediff(day,'01/01/1900',o.date_shipped) + 693596
    ELSE  datediff(day,'01/01/1900',invoice_date) + 693596
  END, -- date_aging,
  cust_code,  isnull(ship_to,''), isnull(salesperson,''), 
  isnull(ship_to_region,''),  isnull(a.inv_comment_code,''),  fob,				-- mls 3/8/06 SCR 35922
  '',  terms,  a.fin_chg_code, isnull(a.price_code,''), 			-- mls 4/20/06 SCR 36110
										-- mls 11/19/03 SCR 31069
  isnull(o.dest_zone_code,' '), o.posting_code, 
  CASE type WHEN 'I' THEN 0 ELSE 1 END, '', tax_id, 
  isnull(cust_po,' '), 0, gross_sales, freight, total_tax, 
  total_discount, (gross_sales + freight + total_tax) - total_discount,
  0.0, 
  case type when 'I' then (gross_sales + freight + total_tax) - total_discount
  else 0 end,
  0, 0, 0,  CASE @printed WHEN 'A' THEN 1 ELSE 0 END,
  0, 0, '', @user_id, isnull(a.addr1,' '), isnull(a.addr2,' '), 
  isnull(a.addr3,' '), isnull(a.addr4,' '), isnull(a.addr5,' '), 
  isnull(a.addr6,' '), isnull(o.ship_to_name,' '), 
  isnull(o.ship_to_add_1,' '), isnull(o.ship_to_add_2,' '), 
  isnull(o.ship_to_add_3,' '), isnull(o.ship_to_add_4,' '), 
  isnull(o.ship_to_add_5,' '), isnull(a.attention_name,' '),
  isnull(a.attention_phone,' '), 0, 0, 0, substring(o.location,1,8), 
  @process_ctrl_num, 0, 0, 0.0, 0.0, '', 0, curr_key, 
  o.rate_type_home, o.rate_type_oper, o.curr_factor, 
  o.oper_factor, 0, isnull(tot_tax_incl,0), 1,  0, 0,
  o.organization_id,
  a.city, a.state, a.postal_code, a.country_code,
  o.ship_to_city, o.ship_to_state, o.ship_to_zip, o.ship_to_country_cd
FROM  load_master_all l 
 join orders_all o on l.load_no = o.load_no 
 join #orders t on t.order_no = o.order_no and t.ext = o.ext
 left outer join adm_cust_all a (nolock) on o.cust_code  = a.customer_code 
 left outer join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
WHERE l.process_ctrl_num = @process_ctrl_num 

INSERT #consolidated_post_orders
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
	oper_override_flag,	organization_id ,
	customer_city, customer_state, customer_postal_code, customer_country_code,
	ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code)
select	
  o.order_no,  o.ext,
  convert(varchar(11),o.order_no) + '-' + convert(varchar(4),o.ext),	-- tmp_ctrl_num 
  '',  oi.doc_ctrl_num, 	
  CASE type WHEN 'I' THEN 'SO:' ELSE 'CM:' END, -- doc_desc
  '', 0, (convert(varchar(10),o.order_no) + '-' + convert(varchar(10),o.ext)),  
  '', CASE type WHEN 'I' THEN 2031 ELSE 2032 END, 			
  datediff(day,'01/01/1900',getdate()) + 693596, 
  CASE @aging
    WHEN 'R' THEN datediff(day,'01/01/1900',o.date_shipped) + 693596
    ELSE  datediff(day,'01/01/1900',invoice_date) + 693596
  END, -- date_applied,		
  CASE @aging
    WHEN 'R' THEN datediff(day,'01/01/1900',o.date_shipped) + 693596
    ELSE  datediff(day,'01/01/1900',invoice_date) + 693596
  END, -- date_doc,			
  datediff(day,'01/01/1900',o.date_shipped) + 693596, -- date_shipped,
  datediff(day,'01/01/1900',req_ship_date) + 693596, -- date_required,		
  0, -- date_due,			
  CASE @aging
    WHEN 'R' THEN datediff(day,'01/01/1900',o.date_shipped) + 693596
    ELSE  datediff(day,'01/01/1900',invoice_date) + 693596
  END, -- date_aging,
  cust_code,  isnull(ship_to,''), isnull(salesperson,''), 
  isnull(ship_to_region,''),  '',  fob,
  '',  terms,  a.fin_chg_code, isnull(a.price_code,''), 			-- mls 4/20/06 SCR 36110
										-- mls 11/19/03 SCR 31069
  isnull(o.dest_zone_code,' '), o.posting_code, 
  CASE type WHEN 'I' THEN 0 ELSE 1 END, '', tax_id, 
  isnull(cust_po,' '), 0, gross_sales, freight, total_tax, 
  total_discount, (gross_sales + freight + total_tax) - total_discount,
  0.0, 
  case type when 'I' then (gross_sales + freight + total_tax) - total_discount
  else 0 end,
  0, 0, 0,  CASE @printed WHEN 'A' THEN 1 ELSE 0 END,
  0, 0, '', @user_id, isnull(a.addr1,' '), isnull(a.addr2,' '), 
  isnull(a.addr3,' '), isnull(a.addr4,' '), isnull(a.addr5,' '), 
  isnull(a.addr6,' '), isnull(o.ship_to_name,' '), 
  isnull(o.ship_to_add_1,' '), isnull(o.ship_to_add_2,' '), 
  isnull(o.ship_to_add_3,' '), isnull(o.ship_to_add_4,' '), 
  isnull(o.ship_to_add_5,' '), isnull(a.attention_name,' '),
  isnull(a.attention_phone,' '), 0, 0, 0, substring(o.location,1,8), 
  @process_ctrl_num, 0, 0, 0.0, 0.0, '', 0, curr_key, 
  o.rate_type_home, o.rate_type_oper, o.curr_factor, 
  o.oper_factor, 0, isnull(tot_tax_incl,0), 1,  0, 0,
  o.organization_id,
  a.city, a.state, a.postal_code, a.country_code,
  o.ship_to_city, o.ship_to_state, o.ship_to_zip, o.ship_to_country_cd
FROM  load_master_all l 
 join orders_all o on l.load_no = o.load_no and o.status in ('S','W') and o.consolidate_flag = 1
    and	isnull(o.eprocurement_ind,0) = 0
 left outer join adm_cust_all a (nolock) on o.cust_code  = a.customer_code 
 left outer join orders_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
WHERE l.process_ctrl_num = @process_ctrl_num 

if not exists (select 1 from #post_orders) and not exists(select 1 from #consolidated_post_orders)
BEGIN
  update l
  set status = 'T',posted_dt = getdate(), posted_who_nm = @user
  from orders_all o, load_master_all l
  where o.status in ('S','W') and l.load_no = o.load_no 
    and l.process_ctrl_num = @process_ctrl_num and l.status != 'T'

update 	o								-- mls 7/16/03 SCR 31491
set status = 'T',
  date_transfered = dateadd(day, (CASE @aging WHEN 'R' THEN 
    datediff(day, '01/01/1900', o.date_shipped) + 693596
  ELSE
    datediff(day, '01/01/1900', o.invoice_date) + 693596
  END) - 693596, '01/01/1900'),
  process_ctrl_num  = '',
  invoice_no = -1	
FROM orders_all o, load_master_all l 
WHERE l.process_ctrl_num = @process_ctrl_num and l.load_no = o.load_no and
o.status in ('S','W') and	isnull(eprocurement_ind,0) = 1

	    select @msg = 'OK'
	    select @msg2 = ''
		set @err = 1
        set @result = 1

        goto write_admresults
END

if exists (select 1 from #post_orders)		
BEGIN

	if exists (select 1 from #post_orders where doc_ctrl_num = '')
	begin
        exec adm_post_ar_cancel_tax @msg2 out

	    select @msg = ''
	    select @msg2 = 'No doc_ctrl number found'
		set @err = -5
        set @result = -5

        goto write_admresults
	end

	select @tmp_ctrl_num = isnull((select min(tmp_ctrl_num) from #post_orders),NULL)

	while @tmp_ctrl_num is not NULL
	begin
	  select @trx_type = trx_type ,
	    @date_applied = date_applied,
	    @nat_cur_code = nat_cur_code,
	    @rate_type_home = rate_type_home,
	    @rate_type_oper = rate_type_oper,
	    @home_rate = rate_home,
	    @oper_rate = rate_oper,
		@trx_ctrl_num = trx_ctrl_num,
	    @ord = order_no,
		@ext = ext
	  from #post_orders 
	  where tmp_ctrl_num = @tmp_ctrl_num

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
		
-- *********************************************************************************
-- EXEC @result = arincrd_sp @module_id,
	INSERT #arinpcdt (trx_ctrl_num,	doc_ctrl_num,	sequence_id,	trx_type,	location_code,
		item_code,	bulk_flag,	date_entered,	line_desc, 	qty_ordered,
		qty_shipped,	unit_code,	unit_price,	unit_cost,	weight,
		serial_id,	tax_code,	gl_rev_acct,	disc_prc_flag,	discount_amt,
		commission_flag,	rma_num,	return_code,	qty_returned,
		qty_prev_returned,	new_gl_rev_acct,	iv_post_flag,	oe_orig_flag,
		trx_state,	mark_flag,	discount_prc,	extended_price,	calc_tax,
		reference_code, cust_po, org_id)
	select
		@trx_ctrl_num,	o.doc_ctrl_num,	l.line_no,	o.trx_type,	substring(l.location,1,8),
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
		l.total_tax, isnull(l.reference_code,''), isnull(l.cust_po,o.cust_po_num), 
		l.organization_id
	  FROM  #post_orders o, ord_list l (nolock)
	  WHERE o.order_no = l.order_no and o.ext = l.order_ext and o.tmp_ctrl_num = @tmp_ctrl_num and
		(l.shipped > 0 or l.cr_shipped > 0) 					-- mls 1/21/2000

			-- SCR 18116 thl 09/08/99 start
			if ( @contract != ' ' ) begin
				if ( len( @line_desc ) + len( @contract ) + 11 > 255 ) begin
					select @line_desc = Substring( @line_desc, 1, ( 255 - ( len( @contract ) + 11 ) ) )
				end
				select @line_desc = @line_desc + ' Contract: ' + @contract
			end
			-- SCR 18116 thl 09/08/99 end

	  IF ( @@error != 0 )
	  BEGIN
  	    exec adm_post_ar_cancel_tax @msg2 out
	    select @msg = ''
	    select @msg2 = 'Error 70'
		set @err = 70
        set @result = 70

        goto write_admresults
	  END     

	  
	  SELECT @total_weight = sum(weight), @total_cost = sum(unit_cost * (qty_shipped + qty_returned))
	  FROM #arinpcdt 
	  where trx_ctrl_num = @trx_ctrl_num

	  Update #post_orders
	  set total_weight = @total_weight,
	      amt_cost = @total_cost,
	      rate_home = @home_rate,
	      rate_oper = @oper_rate,
	      nat_precision = @precision,
	      home_override_flag = @home_override_flag,
	      oper_override_flag = @oper_override_flag
	  where tmp_ctrl_num = @tmp_ctrl_num

	  select @tmp_ctrl_num = isnull((select min(tmp_ctrl_num) from #post_orders where tmp_ctrl_num > @tmp_ctrl_num),NULL)
	END -- while tmp_ctrl_num not null

	--Process Payment Record
	INSERT #arinptmp (
		trx_ctrl_num,	doc_ctrl_num,	trx_desc,	date_doc,	customer_code,
		payment_code,	amt_payment,	prompt1_inp,	prompt2_inp,	prompt3_inp,
		prompt4_inp,	amt_disc_taken,	cash_acct_code	)
	SELECT	i.trx_ctrl_num,	o.doc_ctrl_num,	o.trx_desc, i.date_doc,	i.customer_code,
		o.payment_code,	o.amt_payment,	prompt1_inp,	prompt2_inp,	prompt3_inp,
		prompt4_inp,	o.amt_disc_taken, isnull(c.account_code,'') 			-- mls 4/21/06 SCR 35623
	FROM ord_payment o (nolock)
	join arpymeth p (nolock) on o.payment_code = p.payment_code
	join #post_orders i  on i.order_no = o.order_no and i.ext = o.order_ext
	left outer join  glchart c (nolock) on c.account_code = dbo.IBAcctMask_fn(p.asset_acct_code,i.organization_id)

	IF ( @@error != 0 )
	begin
	  exec adm_post_ar_cancel_tax @msg2 out

	    select @msg = ''
	    select @msg2 = 'Error 40'
		set @err = 40
        set @result = 40
        goto write_admresults
	END

	Update #post_orders
	set amt_paid = o.amt_payment + o.amt_disc_taken,
	  amt_due = 
	  CASE 
	  WHEN ((i.amt_gross + i.amt_freight + i.amt_tax) - i.amt_discount - (o.amt_payment + o.amt_disc_taken) < 0) 
	    or i.trx_type = 2032 THEN 0
	  ELSE (i.amt_gross + i.amt_freight + i.amt_tax) - i.amt_discount - (o.amt_payment + o.amt_disc_taken) 
	  END
	from #post_orders i, #arinptmp o
	where i.trx_ctrl_num = o.trx_ctrl_num

	insert into #arterm
	select distinct date_doc, terms_code,0,0
	from #post_orders

	exec ARGetTermInfo_SP

	Update #post_orders
	set date_due = a.date_due
	from #arterm a, #post_orders o
	where a.terms_code = o.terms_code and a.date_doc = o.date_doc

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
		amt_tax_included ,	org_id,
	customer_city, customer_state, customer_postal_code, customer_country_code,
	ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code, writeoff_code)
	select
		trx_ctrl_num,		doc_ctrl_num,		doc_desc + tmp_ctrl_num + ' ' + convert(varchar(10),user_id),
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
		amt_tax_included,	organization_id,
	customer_city, customer_state, customer_postal_code, customer_country_code,
	ship_to_city, ship_to_state, ship_to_postal_code, ship_to_country_code, ''
	FROM #post_orders

	IF ( @@error != 0 )
	BEGIN
  	    exec adm_post_ar_cancel_tax @msg2 out
	    select @msg = ''
	    select @msg2 = 'Error 20'
		set @err = 20
        set @result = 20
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
	  exec adm_post_ar_cancel_tax @msg2 out

	    select @msg = ''
	    select @msg2 = 'Error 30'
		set @err = 30
        set @result = 30
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
	  exec adm_post_ar_cancel_tax @msg2 out

	    select @msg = ''
	    select @msg2 = 'Error 50'
		set @err = 50
        set @result = 50
        goto write_admresults
	END
	
	--Process Tax Records
	INSERT #arinptax (	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,
		amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	trx_state,
		mark_flag)
	SELECT	trx_ctrl_num,	trx_type,	t.sequence_id,	t.tax_type_code,	
		t.amt_taxable,	t.amt_gross,	t.amt_tax,	t.amt_final_tax,	2,		 
		0
	FROM #post_orders o, ord_list_tax t (nolock)
	where o.order_no = t.order_no and o.ext = t.order_ext 
	  and (@AR_INCL_NON_TAX = 'Y' or amt_final_tax <> 0)						-- mls 12/22/00 SCR 23738
	
	IF ( @@error != 0 )
	BEGIN
	  exec adm_post_ar_cancel_tax @msg2 out

	    select @msg = ''
	    select @msg2 = 'Error 60'
		set @err = 60
        set @result = 60
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
		org_id			varchar(30)
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
		org_id			varchar(30)
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
	   exec adm_post_ar_cancel_tax @msg2 out

	    select @msg = ''
	    select @msg2 = 'Error 70'
		set @err = 70
        set @result = 70
        goto write_admresults
	 END

	if @trx_type =  2031  
	BEGIN
	  EXEC @result = arinvedt_sp 1 
	
	  IF @result !=  0
	  BEGIN
	    exec adm_post_ar_cancel_tax @msg2 out

	    select @msg = ''
	    select @msg2 = 'Error 80'
		set @err = 80
        set @result = 80
        goto write_admresults
	  END

	  DELETE from #ewerror 								
	  where err_code = 20001  	
 	  DELETE from #ewerror where err_code = 20097  	-- mls 4/21/06 SCR 35623
  	  DELETE from #ewerror where err_code = 20070  		-- mls 4/21/06 SCR 35623
	
	  IF (select count(*) from #ewerror) > 0
	  begin
	    exec adm_post_ar_cancel_tax @msg2 out
	    select @msg = ''
	    select @msg2 = 'Error 90'
	    set @err = 90

        insert #adm_results (
         module_id, 	err_code, 	info1, 		info2 ,
           infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
          source_ctrl_num ,	extra, order_no, order_ext, ewerror_ind)
	    select 
         module_id, 	err_code, 	info1, 		info2 ,
           infoint, 		infofloat , 	flag1 , 	e.trx_ctrl_num , 	sequence_id , 
           source_ctrl_num ,	extra , o.order_no, o.ext, 1
        from #ewerror e
        left outer join #orders o on o.trx_ctrl_num = e.trx_ctrl_num

        goto ret_process
 	 END
	END
	ELSE 
	BEGIN
	  EXEC @result = arcmedt_sp 1 

	  IF @result !=  0
	  BEGIN
	    exec adm_post_ar_cancel_tax @msg2 out
	    select @msg = ''
	    select @msg2 = 'Error 80'
	    set @err = 80
        set @result = 80
        goto write_admresults
	  END

	  DELETE from #ewerror 								
	  where err_code = 20201   	
 	  DELETE from #ewerror where err_code = 20097  	-- mls 4/21/06 SCR 35623
  	  DELETE from #ewerror where err_code = 20070  		-- mls 4/21/06 SCR 35623

	  IF (select count(*) from #ewerror) > 0
	  begin
	    exec adm_post_ar_cancel_tax @msg2 out
	    select @msg = ''
	    select @msg2 = 'Error 90'
	    set @err = 90

        insert #adm_results (
         module_id, 	err_code, 	info1, 		info2 ,
           infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
          source_ctrl_num ,	extra, order_no, order_ext, ewerror_ind)
	    select 
         module_id, 	err_code, 	info1, 		info2 ,
           infoint, 		infofloat , 	flag1 , 	e.trx_ctrl_num , 	sequence_id , 
          source_ctrl_num ,	extra , o.order_no, o.ext, 1
        from #ewerror e
        left outer join #orders o on o.trx_ctrl_num = e.trx_ctrl_num
        goto ret_process
	  END
	END
end


BEGIN TRAN
if exists (select 1 from #post_orders)		
BEGIN

	EXEC @result = arinsav_sp @user_id, @new_batch_code OUTPUT

	IF @result !=  0
	BEGIN
	  ROLLBACK TRAN
	    exec adm_post_ar_cancel_tax @msg2 out
	    select @msg = ''
	    select @msg2 = 'Error 95'
	    set @err = 95
        set @result = 95
        goto write_admresults
	END

END 

update l
set status = 'T',posted_dt = getdate(), posted_who_nm = @user
from #post_orders p, orders_all o, load_master_all l
where p.order_no = o.order_no and p.ext = o.ext
and o.status <> 'T' and
l.load_no = o.load_no


update 	o								-- mls 7/16/03 SCR 31491
set status = 'T',
  date_transfered = dateadd(day, (CASE @aging WHEN 'R' THEN 
    datediff(day, '01/01/1900', o.date_shipped) + 693596
  ELSE
    datediff(day, '01/01/1900', o.invoice_date) + 693596
  END) - 693596, '01/01/1900'),
  process_ctrl_num  = '',
  invoice_no = -1	
FROM orders_all o, load_master_all l 
WHERE l.process_ctrl_num = @process_ctrl_num and l.load_no = o.load_no and
o.status in ('S','W') and	isnull(eprocurement_ind,0) = 1

update o
 set batch_code = convert(varchar(16),@new_batch_code), status = 'T',
	date_transfered = dateadd(day, p.date_applied - 693596, '01/01/1900')	-- skk 06/09/00 22637
from #post_orders p, orders_all o
where p.order_no = o.order_no and p.ext = o.ext and o.status <> 'T'


update l
set status = 'T',posted_dt = getdate(), posted_who_nm = @user
from #consolidated_post_orders p, orders_all o, load_master_all l
where p.order_no = o.order_no and p.ext = o.ext
and o.status <> 'T' and
l.load_no = o.load_no

update o
	set status = 'T', process_ctrl_num = '',
	    date_transfered = dateadd(day, (CASE @aging WHEN 'R' THEN 
	 				 	datediff(day, '01/01/1900', o.date_shipped) + 693596
    					  ELSE
						datediff(day, '01/01/1900', o.invoice_date) + 693596
  					  END) - 693596, '01/01/1900')
from #consolidated_post_orders p, orders_all o
where p.order_no = o.order_no and p.ext = o.ext and o.status <> 'T'
COMMIT TRAN


if @trx_type = 2032 -- credit memos
  exec icv_fs_post_cradj @user, @process_ctrl_num , @err OUT
else
  select @err = 1

if @err <> 1
begin
  select @msg = 'post Credit Adjustment'
  select @msg2 = 'Error returned from posting credit adjustment'
  set @result = @err
end
else
begin
  select @msg = 'OK'
  select @msg2 = ''
  set @err = 1
  set @result = 1
end

write_admresults:
  insert #adm_results (
    module_id, 	err_code, 	info1, 		info2 ,
    infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
    source_ctrl_num ,	extra, order_no, order_ext, ewerror_ind)
  select 
    18000, 	@result, 	@msg , 	@msg2,
    0, 		0 , 	'' , 	'',	'',
    @trx_ctrl_num , '', 	@ord, 	@ext, 0


ret_process:
if @in_cursor = 1
begin
    close orders_cursor
    deallocate orders_cursor
end

    select @err, 0, 	module_id, 	err_code, 	info1, 	
      case when ewerror_ind = 0 then '' else info2 end ,
      infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
      source_ctrl_num ,	extra, 		order_no, 	order_ext,
	  a.refer_to, a.field_desc, 
      case when ewerror_ind = 1 then a.err_desc else info2 end err_desc
    from #adm_results e
    left outer join aredterr a on a.e_code = e.err_code and e.ewerror_ind = 1

return @err


GO
GRANT EXECUTE ON  [dbo].[fs_post_ar_group] TO [public]
GO
