SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE  [dbo].[adm_post_ar] 
  @err int OUT,			@post_description varchar(255) = NULL,			@num_to_post int = 0,
  @type char(1) = 'I',		@user varchar(30) = NULL,				@location varchar(10) = NULL,
  @org_id varchar(30) = NULL,   @end_date datetime = NULL,				@cust_code varchar(8) = NULL,
  @process_ctrl_num varchar(16) = NULL,
  @online_call int = 0
AS
BEGIN
set nocount on

declare 
  @post_filter varchar(1000),
  @gl_method int, 		@psql_glpost_mth varchar(1), 		@arpost_batch_size int,
  @process_user_id int, 	@company_code varchar(8),		@ret_code int,
  @cca_installed varchar(8), 	@post_id int, 				@post_date datetime,
  @cust_key varchar(10),	@ll_orig_no int,			@ll_orig_ext int,
  @icv_credit varchar(10), 	@icv_type varchar(10), 			@icv_cust_dflts char(1), 
  @processor int,		@consolidate_flag int, 
  @order_no	int,		@order_ext	int,			@payment_code varchar(8),
  @blanket char(1), 		@ord_type char(1), 			@cca_amt decimal(20,8), 
  @batch varchar(16),		@ls_icv_stat varchar(10), 		@icv_val_code varchar(10), 
  @err_msg varchar(255), 	@eprocurement_ind int, 			@post_ar_error int,
  @post_batch_id int, 		@ar_incl_non_tax char(1), 		@printed char(1),
  @home_currency varchar(8), 	@oper_currency varchar(8), 		@company_id int ,
  @num_posted int, 		@num_in_batch int, 			@ord_status char(1), 
  @cursor_rows int, 		@last_order int,			@trx_type smallint,
  @process_status char(1),	@nat_cur_code varchar(8),		@tot_invoice decimal(20,8),
  @date_shipped datetime,	@curr_date int,				@msg varchar(32),
  @val_apply_dt char(1),	@period_end_date int,			@allow_prior_posting char(1), 
  @allow_future_posting char(1),@allow_range_posting char(1),		@apply_date_range int,
  @msg2 varchar(32),		@gl_start_dt int,			@gl_end_dt int,
  @trx_ctrl_num varchar(16),	@tcn_mask varchar(16),
  @first_tcn int,			@result int,
  @tax_rc int

-----------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE #ewerror(
  module_id 	smallint,		err_code  	int,			info1 		char(32),
  info2 	char(255),		infoint 	int,			infofloat 	float,
  flag1		smallint,		trx_ctrl_num 	char(16),		sequence_id 	int,
  source_ctrl_num char(16),		extra 		int			)

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
  amt_rem_tax     float,		date_recurring  int,			location_code   varchar(10),
  process_group_num varchar(16) NULL, 	source_trx_ctrl_num varchar(16) NULL,   source_trx_type smallint NULL,	
  amt_discount_taken float NULL,	amt_write_off_given float NULL,		nat_cur_code    varchar(8),
  rate_type_home  varchar(8),  		rate_type_oper  varchar(8),  		rate_home       float, 
  rate_oper       float, 		temp_flag	smallint NULL, 		org_id		varchar(30) NULL, 
  interbranch_flag int NULL, 		temp_flag2 	smallint NULL		)

CREATE TABLE #arterm (
  date_doc	 int,			terms_code	varchar(8),		date_due	int,
  date_discount	 int			)

--Create temp processing Tables
CREATE TABLE #arinpchg(
  trx_ctrl_num	   varchar(16),		doc_ctrl_num	varchar(16),		doc_desc	    varchar(40),
  apply_to_num	   varchar(16),		apply_trx_type	smallint,		order_ctrl_num	    varchar(16),
  batch_code	   varchar(16),		trx_type	smallint,		date_entered	    int,
  date_applied	   int,			date_doc	int,			date_shipped	    int,
  date_required	   int,			date_due	int,			date_aging	    int,
  customer_code	   varchar(8),		ship_to_code	varchar(8),		salesperson_code    varchar(8),
  territory_code   varchar(8),		comment_code	varchar(8),		fob_code	    varchar(8),
  freight_code	   varchar(8),		terms_code	varchar(8),		fin_chg_code	    varchar(8),
  price_code	   varchar(8),		dest_zone_code	varchar(8),		posting_code	    varchar(8),
  recurring_flag   smallint,		recurring_code	varchar(8),		tax_code	    varchar(8),
  cust_po_num	   varchar(20),		total_weight	float,			amt_gross	    float,
  amt_freight	   float,		amt_tax		float,			amt_tax_included    float,
  amt_discount	   float,		amt_net		float,			amt_paid	    float,
  amt_due	   float,		amt_cost	float,			amt_profit	    float,
  next_serial_id   smallint,		printed_flag	smallint,		posted_flag	    smallint,
  hold_flag	   smallint,		hold_desc	varchar(40),		user_id		    smallint,
  customer_addr1   varchar(40),		customer_addr2	varchar(40),		customer_addr3	    varchar(40),
  customer_addr4   varchar(40),		customer_addr5	varchar(40),		customer_addr6	    varchar(40),
  ship_to_addr1	   varchar(40),		ship_to_addr2	varchar(40),		ship_to_addr3	    varchar(40),
  ship_to_addr4	   varchar(40),		ship_to_addr5	varchar(40),		ship_to_addr6	    varchar(40),
  attention_name   varchar(40),		attention_phone	varchar(30),		amt_rem_rev	    float,
  amt_rem_tax	   float,		date_recurring	int,			location_code	    varchar(10),
  process_group_num  varchar(16),	trx_state	smallint NULL,		mark_flag	    smallint	 NULL,
  amt_discount_taken float NULL,	amt_write_off_given float NULL,		source_trx_ctrl_num varchar(16) NULL,
  source_trx_type   smallint NULL,	nat_cur_code	varchar(8),		rate_type_home	    varchar(8),	
  rate_type_oper    varchar(8),		rate_home	float,			rate_oper	    float,	
  edit_list_flag    smallint,		ddid 		varchar(32) NULL,	org_id 		    varchar(30) NULL,
  customer_city varchar(40), customer_state varchar(40), customer_postal_code varchar(15), customer_country_code varchar(3),
  ship_to_city varchar(40), ship_to_state varchar(40), ship_to_postal_code varchar(15), ship_to_country_code varchar(3),
  writeoff_code varchar(8) NULL)

CREATE UNIQUE INDEX #arinpchg_ind_0 	ON #arinpchg ( trx_ctrl_num, trx_type )
CREATE INDEX #arinpchg_ind_1 		ON #arinpchg ( batch_code)

CREATE TABLE #arinpage(
  trx_ctrl_num	varchar(16),		sequence_id	int,			doc_ctrl_num	varchar(16),
  apply_to_num	varchar(16),		apply_trx_type	smallint,		trx_type	smallint,
  date_applied	int,			date_due	int,			date_aging	int,
  customer_code	varchar(8),		salesperson_code varchar(8),		territory_code	varchar(8),
  price_code	varchar(8),		amt_due		float,			trx_state	smallint NULL,
  mark_flag	smallint NULL		)

CREATE UNIQUE INDEX arinpage_ind_0 	ON #arinpage ( trx_ctrl_num, trx_type, sequence_id )

CREATE TABLE #arinptax (
  trx_ctrl_num	varchar(16),		trx_type	smallint,		sequence_id	int,
  tax_type_code	varchar(8),		amt_taxable	float,			amt_gross	float,
  amt_tax	float,			amt_final_tax	float,			trx_state 	smallint NULL,
  mark_flag 	smallint NULL		)

CREATE UNIQUE INDEX arinptax_ind_0 	ON #arinptax ( trx_ctrl_num, trx_type, sequence_id )

CREATE TABLE #arinpcom (
  trx_ctrl_num	   varchar(16),		trx_type	smallint,		sequence_id	int,
  salesperson_code varchar(8),		amt_commission	float,			percent_flag	smallint,
  exclusive_flag   smallint,		split_flag	smallint, 		trx_state 	smallint NULL,
  mark_flag 	   smallint NULL	)

CREATE UNIQUE INDEX arinpcom_ind_0 	ON #arinpcom ( trx_ctrl_num, trx_type, sequence_id )

CREATE TABLE #arinptmp (
  timestamp 	timestamp,		trx_ctrl_num	varchar(16),		doc_ctrl_num	varchar(16),	
  trx_desc	varchar(40),		date_doc	int,        		customer_code	varchar(8),
  payment_code	varchar(8),     	amt_payment	float,			prompt1_inp	varchar(30),
  prompt2_inp	varchar(30),		prompt3_inp	varchar(30),		prompt4_inp	varchar(30),
  amt_disc_taken	float,		cash_acct_code	varchar(32)		)

create table #arinpcdt (
  trx_ctrl_num	 varchar(16),		doc_ctrl_num	varchar(16),		sequence_id	int,
  trx_type	 smallint,		location_code	varchar(10),		item_code	varchar(30),
  bulk_flag	 smallint,		date_entered	int,			line_desc	varchar(60),
  qty_ordered	 float,			qty_shipped	float,			unit_code	varchar(8),
  unit_price	 float,			unit_cost	float,			weight	 	float,
  serial_id	 int,			tax_code	varchar(8),		gl_rev_acct	varchar(32),
  disc_prc_flag	 smallint,		discount_amt	float,			commission_flag	smallint,
  rma_num	 varchar(16),		return_code	varchar(8),		qty_returned	float,
  qty_prev_returned float,		new_gl_rev_acct	varchar(32),		iv_post_flag	smallint,
  oe_orig_flag	 smallint,		discount_prc	float,			extended_price	float,	
  calc_tax	float,			reference_code	varchar(32) NULL,	trx_state	smallint NULL,
  mark_flag	smallint NULL,		cust_po 	VARCHAR(20) NULL,	org_id		varchar(30) NULL)

CREATE UNIQUE INDEX arinpcdt_ind_0 ON #arinpcdt ( trx_ctrl_num, trx_type, sequence_id )

create table #t1 (
tax_type_code 	varchar(8) NOT NULL,	tax_amt		decimal(20,8) NOT NULL,	row_id 		int identity(1,1) 
)

CREATE TABLE #post_orders (
  order_no 	  int,			ext 		int,			tmp_ctrl_num	varchar(16),
  trx_ctrl_num	  varchar(16),		doc_ctrl_num	varchar(16),		doc_desc	varchar(40),
  apply_to_num	  varchar(16),		apply_trx_type	smallint,		order_ctrl_num	varchar(16),
  batch_code	  varchar(16),		trx_type	smallint,		date_entered	int,
  date_applied	  int,			date_doc	int,			date_shipped	int,
  date_required	  int,			date_due	int,			date_aging	int,
  customer_code	  varchar(8),		ship_to_code	varchar(8),		salesperson_code varchar(8),
  territory_code  varchar(8),		comment_code	varchar(8),		fob_code	varchar(8),
  freight_code	  varchar(8),		terms_code	varchar(8),		fin_chg_code	varchar(8),
  price_code	  varchar(8),		dest_zone_code	varchar(8),		posting_code	varchar(8),
  recurring_flag  smallint,		recurring_code	varchar(8),		tax_code	varchar(8),
  cust_po_num	  varchar(20),		total_weight	float,			amt_gross	float,
  amt_freight	  float,		amt_tax		float,			amt_tax_included float,
  amt_discount	  float,		amt_net		float,			amt_paid	float,
  amt_due	  float,		amt_cost	float,			amt_profit	float,
  next_serial_id  smallint,		printed_flag	smallint,		posted_flag	smallint,
  hold_flag	  smallint,		hold_desc	varchar(40),		user_id		smallint,
  customer_addr1  varchar(40),		customer_addr2	varchar(40),		customer_addr3	varchar(40),
  customer_addr4  varchar(40),		customer_addr5	varchar(40),		customer_addr6	varchar(40),
  ship_to_addr1	  varchar(40),		ship_to_addr2	varchar(40),		ship_to_addr3	varchar(40),
  ship_to_addr4	  varchar(40),		ship_to_addr5	varchar(40),		ship_to_addr6	varchar(40),
  attention_name  varchar(40),		attention_phone	varchar(30),		amt_rem_rev	float,
  amt_rem_tax	  float,		date_recurring	int,			location_code	varchar(10),
  process_group_num varchar(16),	trx_state	smallint NULL,		mark_flag	smallint	 NULL,
  amt_discount_taken float NULL,	amt_write_off_given float NULL,		source_trx_ctrl_num varchar(16) NULL,
  source_trx_type smallint NULL,	nat_cur_code	varchar(8),		rate_type_home	varchar(8),	
  rate_type_oper  varchar(8),		rate_home	float,			rate_oper	float,	
  edit_list_flag  smallint,		nat_precision	int ,			home_override_flag smallint,
  oper_override_flag smallint,		cr_invoice_no 	int,			line_item_cnt int,
  organization_id varchar(30),		
  customer_city varchar(40), customer_state varchar(40), customer_postal_code varchar(15), customer_country_code varchar(3),
  ship_to_city varchar(40), ship_to_state varchar(40), ship_to_postal_code varchar(15), ship_to_country_code varchar(3),
  writeoff_code varchar(8) NULL,
  row_id 	  	int identity(0,1)	)

CREATE INDEX post_orders1 		on #post_orders (order_no, ext)
CREATE INDEX post_orders2 		on #post_orders (trx_ctrl_num)
CREATE INDEX post_orders4 		on #post_orders (terms_code, date_doc)
CREATE INDEX post_orders5 		on #post_orders (nat_cur_code)
CREATE INDEX post_orders6 		on #post_orders (row_id)

CREATE TABLE #arvalcdt (
  trx_ctrl_num	  varchar(16),		doc_ctrl_num	varchar(16),		sequence_id 	  int,
  trx_type	  smallint,		location_code	varchar(10),		item_code	  varchar(30),
  bulk_flag	  smallint,		date_entered	int,			line_desc	  varchar(60),
  qty_ordered	  float,		qty_shipped	float,			unit_code	  varchar(8),
  unit_price	  float,		unit_cost	float,			extended_price	  float,
  weight	  float,		serial_id	int,			tax_code	  varchar(8),
  gl_rev_acct	  varchar(32),		disc_prc_flag	smallint,		discount_amt	  float,
  discount_prc	  float,		commission_flag	smallint,		rma_num		  varchar(16),
  return_code	  varchar(8),		qty_returned	float,			qty_prev_returned float,
  new_gl_rev_acct varchar(32),		iv_post_flag	smallint,		oe_orig_flag	  smallint,	
  calc_tax	  float,		reference_code	varchar(32) NULL,	temp_flag	  smallint NULL,
  org_id	  varchar(30) NULL,	temp_flag2	int NULL		
)

CREATE TABLE #arvalage (
  trx_ctrl_num	varchar(16),		sequence_id	 int,			doc_ctrl_num	varchar(16),
  apply_to_num	varchar(16),		apply_trx_type	 smallint,		trx_type	smallint,
  date_applied	int,			date_due	 int,			date_aging	int,
  customer_code	varchar(8),		salesperson_code varchar(8),		territory_code	varchar(8),
  price_code	varchar(8),		amt_due		 float,			temp_flag	smallint NULL
)

CREATE TABLE #arvaltax (
  trx_ctrl_num	varchar(16),		trx_type       	smallint,		sequence_id     int,
  tax_type_code	varchar(8),		amt_taxable     float,			amt_gross       float,
  amt_tax 	float,			amt_final_tax   float,			temp_flag	smallint NULL
)

CREATE TABLE #arvaltmp (
  trx_ctrl_num	 varchar(16),		doc_ctrl_num	varchar(16), 		date_doc	int,
  customer_code	 varchar(8),		payment_code	varchar(8),		amt_payment	float,
  amt_disc_taken float,			cash_acct_code	varchar(32),		temp_flag	smallint NULL
)

CREATE TABLE #arvalrev (
  trx_ctrl_num	varchar(16),		sequence_id	int,			rev_acct_code	varchar(32),
  apply_amt	float,			trx_type	smallint,     		reference_code  varchar(32) NULL,
  temp_flag 	smallint,		org_id		varchar(30) NULL	
)

CREATE TABLE #arinbat (
  date_applied	 int, 			process_group_num varchar(16),		trx_type	smallint,
  batch_ctrl_num char(16) NULL,		flag		  smallint,		org_id		varchar(30) NULL)

CREATE TABLE #arbatsum (
  batch_ctrl_num char(16) NOT NULL,	actual_number 	int NOT NULL,		actual_total 	float NOT NULL
)

CREATE TABLE #arbatnum(
  date_applied	int,			process_group_num varchar(16),		trx_type	  smallint,
  flag		smallint,		batch_ctrl_num	  char(16) NULL,	batch_description char(30) NULL,
  company_code  char(8) NULL,		seq		  numeric identity, 	org_id varchar (30) NULL)

CREATE TABLE #aritemp (
  code 		varchar(8),		code2 varchar(8),			mark_flag	smallint,
  amt_home 	float,			amt_oper float				)

create table #orders (
  order_no int,				ext int,					trx_ctrl_num varchar(16),
  trx_type int)
create index to_1 on #orders (order_no, ext)
create index to_2 on #orders (trx_type, trx_ctrl_num)

-----------------------------------------------------------------------------------------------------------------------------------
set @process_status = 'R'

set @post_filter = ''
if @user is not null		select @post_filter = @post_filter + ' User: '  	+ @user
if @location is not null 	select @post_filter = @post_filter + ' Location: '  	+ @location
if @end_date is not null 	select @post_filter = @post_filter + ' Date: '  	+ convert(varchar,@end_date,102)
if @cust_code is not null 	select @post_filter = @post_filter + ' Customer: '  	+ @cust_code
if isnull(@num_to_post,0) != 0 	select @post_filter = @post_filter + ' Number of Orders: '  + convert(varchar,@num_to_post)

insert adm_post_history 
	 (post_type, 	post_description,			post_filter, 	batch_cnt)
  values ( 'AR', 	ltrim(isnull(@post_description,'')),	@post_filter, 	0)
select @post_id = @@identity
 
set @psql_glpost_mth = 'I'
if exists (select 1 from config(nolock) where flag = 'PSQL_GLPOST_MTH' and value_str = 'D')
begin
  set @psql_glpost_mth = 'D'
  SELECT @gl_method = indirect_flag FROM glco (nolock)
end 

select @arpost_batch_size = convert(int,isnull((select value_str from config (nolock) where flag = 'ARPOST_BATCH_SIZE'),'40'))
select @cca_installed = isnull((select upper(value_str) from config (nolock) where flag = 'CCA'),'N')
select @val_apply_dt = isnull((select value_str from config(nolock) where upper(flag) = 'PLT_VAL_APPLY_DT' ),'1')
select @gl_start_dt = min(period_start_date) from glprd (nolock)
select @gl_end_dt = max(period_end_date) from glprd (nolock)

if @val_apply_dt = '1'
begin
  SELECT @period_end_date = isnull((select CASE WHEN ISNUMERIC(value_str)=1 THEN CAST(value_str AS INT) ELSE 0 END 
    FROM config (NOLOCK) WHERE upper(flag) = 'DIST_PLT_END_DATE' ),0)

  SELECT @allow_prior_posting = isnull((select LEFT(value_str, 1) from config (NOLOCK) where upper(flag) = 'PLT_PRIOR_POST'),'N')
  SELECT @allow_future_posting = isnull((select LEFT(value_str, 1) from config(NOLOCK) where upper(flag) = 'PLT_FUTURE_POST'),'N')
  SELECT @allow_range_posting = isnull((select LEFT(value_str, 1) from config (NOLOCK)where upper(flag) = 'PLT_RANGE_POST'),'N')
  SELECT @apply_date_range = isnull((select case when ISNUMERIC(value_str)=1 THEN CAST(value_str as integer) else 0 end
     from config(NOLOCK) where upper(flag) = 'PLT_APPLY_DT_RANGE'),0)
end

select @num_posted = 0, @num_in_batch = 0, @batch = isnull(@process_ctrl_num,''), @last_order = 0


if @process_user_id is NULL
begin
  SELECT @process_user_id  = user_id,
    @user = user_name
  FROM  glusers_vw (nolock) 
  WHERE lower(user_name) = lower(@user)

  IF @process_user_id is NULL  
    Select @process_user_id  = 1, @user = 'sa'
END

set @post_batch_id = 0
while (@num_posted < @num_to_post) or @num_to_post = 0 or @process_ctrl_num is not NULL
begin
    truncate table #orders

    DECLARE update_order_cursor CURSOR LOCAL FORWARD_ONLY STATIC FOR
    SELECT
	o.order_no, 			o.ext, 								upper(o.blanket), 
	o.type,				(o.gross_sales - o.total_discount + o.total_tax + o.freight),	o.cust_code, 		
	o.orig_no, 			o.orig_ext,							isnull(o.eprocurement_ind,0), 
	isnull(o.consolidate_flag,0), 	o.status,							o.curr_key,
	o.total_invoice,		o.date_shipped, oi.trx_ctrl_num
    FROM orders_all o
    left outer join orders_invoice oi on oi.order_no = o.order_no and oi.order_ext = o.ext
    WHERE (@process_ctrl_num is NULL         				and o.type = @type 
        and (o.status = @process_status and isnull(load_no,0) = 0) 	and o.order_no > @last_order
        and (o.location = isnull(@location,o.location))			and (o.date_shipped <= isnull(@end_date,o.date_shipped))
        and (o.cust_code = isnull(@cust_code,o.cust_code))		and (o.process_ctrl_num = '' or o.status = 'R')
	and (o.organization_id = isnull(@org_id,o.organization_id)))
      or  (@process_ctrl_num is NOT NULL 				and o.status in ('R','S','W')
	and o.process_ctrl_num = isnull(@process_ctrl_num,'') 		and isnull(o.load_no,0) = 0)
    order by o.order_no

  SET ROWCOUNT @num_to_post
  OPEN update_order_cursor 
  set rowcount 0

  set @cursor_rows = @@cursor_rows

  if @cursor_rows != 0 and @post_batch_id = 0
  begin
    select @post_date = getdate()
    insert adm_post_hist_batch (post_id, process_ctrl_num, start_time, end_time, num_processed,ret_code)
    select @post_id, @batch, @post_date, NULL,0,0
    set @post_batch_id = @@identity
  end

  if @cursor_rows != 0 and @batch = ''
  begin
    exec @ret_code = adm_next_batch 'ADM AR Transactions', @user OUT, 18000, 0, @process_user_id OUT, @company_code OUT,
      @batch OUT

    select @batch = isnull(@batch,'')

    update adm_post_hist_batch
     set num_processed = -1, ret_code = @ret_code, process_ctrl_num = @batch
    where post_batch_id = @post_batch_id

    if @batch = ''
    begin
      update adm_post_hist_batch
       set end_time = @post_date
      where post_batch_id = @post_batch_id

      update adm_post_history
      set end_time = getdate()
      where post_id = @post_id    

      CLOSE update_order_cursor
      DEALLOCATE update_order_cursor 
      select @err = -1
      return -1
    end
  end

  WHILE @cursor_rows != 0
  BEGIN
    FETCH NEXT FROM update_order_cursor INTO @order_no, @order_ext, @blanket, @ord_type, @cca_amt, @cust_key, @ll_orig_no, @ll_orig_ext,
      @eprocurement_ind, @consolidate_flag, @ord_status, @nat_cur_code, @tot_invoice, @date_shipped,
      @trx_ctrl_num

    if @@FETCH_STATUS <> 0
      BREAK

    select @last_order = @order_no
    set @trx_type = CASE @ord_type WHEN 'I' THEN 2031 ELSE 2032 END

    if not exists (select 1 from ord_list (nolock) where order_no = @order_no and order_ext = @order_ext and 
       case @ord_type when 'I' then shipped else cr_shipped end != 0)
    begin 
      insert adm_post_hist_batch_errors (
        post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
        infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
        source_ctrl_num ,	extra, 		order_no, 	order_ext)
      select 
        @post_batch_id, 	18000, 	0, 	
        case when @ord_type = 'I' then 'Order has nothing shipped' else
	  'Credit has nothing returned' end , 	'but is in ready/posting status',
        0, 		0 , 	'' , 	'',	'',
        '' , '', 	@order_no, 	@order_ext

      CONTINUE
    end

    if @tot_invoice < 0
    begin
      insert adm_post_hist_batch_errors (
        post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
        infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
        source_ctrl_num ,	extra, 		order_no, 	order_ext)
      select 
        @post_batch_id, 	18000, 	0, 	'Invoice Total is less than 0' , 	'',
        0, 		0 , 	'' , 	'',	'',
        '' , '', 	@order_no, 	@order_ext

      CONTINUE
    end

    SELECT @curr_date = datediff(day,'01/01/1900',@date_shipped) + 693596
    if @curr_date < @gl_start_dt
    begin
      select @msg = 'Date Shipped ' + convert(varchar(10),@date_shipped,101) + ' invalid.'
      select @msg2 = 'It is in not in a valid gl period' 

      insert adm_post_hist_batch_errors (
        post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
        infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
        source_ctrl_num ,	extra, 		order_no, 	order_ext)
      select 
        @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
        0, 		0 , 	'' , 	'',	'',
        '' , '', 	@order_no, 	@order_ext

     CONTINUE
    end

    if @curr_date > @gl_end_dt
    begin
      select @msg = 'Date Shipped ' + convert(varchar(10),@date_shipped,101) + ' invalid.'
      select @msg2 = 'It is in not in a valid gl period' 

      insert adm_post_hist_batch_errors (
        post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
        infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
        source_ctrl_num ,	extra, 		order_no, 	order_ext)
      select 
        @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
        0, 		0 , 	'' , 	'',	'',
        '' , '', 	@order_no, 	@order_ext

     CONTINUE
    end

    if @val_apply_dt = '1'
    begin
      if @allow_range_posting = 'Y'
      begin
        if ABS(DATEDIFF(DAY, getdate(), @date_shipped)) > @apply_date_range
        begin 
          select @msg = 'Date Shipped ' + convert(varchar(10),@date_shipped,101) + ' invalid.'
          select @msg2 = 'It is in not in the valid date range' 

          insert adm_post_hist_batch_errors (
            post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
            infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
            source_ctrl_num ,	extra, 		order_no, 	order_ext)
          select 
            @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
            0, 		0 , 	'' , 	'',	'',
            '' , '', 	@order_no, 	@order_ext

          CONTINUE
        end
      end
      else
      begin
        if @allow_future_posting = 'N'
        begin
          if @curr_date > @period_end_date				-- mls 8/19/03 SCR 31660 start
          begin
            select @msg = 'Date Shipped ' + convert(varchar(10),@date_shipped,101) + ' invalid.'
          select @msg2 = 'It is in a future period'

            insert adm_post_hist_batch_errors (
              post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
              infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
              source_ctrl_num ,	extra, 		order_no, 	order_ext)
            select 
              @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
              0, 		0 , 	'' , 	'',	'',
              '' , '', 	@order_no, 	@order_ext

            CONTINUE
          end
        end
		
        if @allow_prior_posting = 'N'
        begin
          if @curr_date < (select period_start_date from glprd (nolock) where period_end_date = @period_end_date)
          begin
            select @msg = 'Date Shipped ' + convert(varchar(10),@date_shipped,101) + ' invalid.'
            select @msg2 = 'It is in a prior period.'

            insert adm_post_hist_batch_errors (
              post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
              infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
              source_ctrl_num ,	extra, 		order_no, 	order_ext)
            select 
              @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
              0, 		0 , 	'' , 	'',	'',
              '' , '', 	@order_no, 	@order_ext

            CONTINUE
          end 		
        end								
      end
    end

    exec @tax_rc = fs_calculate_oetax_wrap @ord = @order_no, @ext = @order_ext,
      @batch_call = 1

    if @tax_rc <> 1
    begin
      insert adm_post_hist_batch_errors (
        post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
        infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
        source_ctrl_num ,	extra, 		order_no, 	order_ext)
      select 
        @post_batch_id, 	18000, 	@tax_rc, 	'Tax not calculated successfully' , 	
        @err_msg,			0, 		0 , 	0,	'' , 	0,
        '' , '', 	@order_no, 	@order_ext

      CONTINUE
    end

    exec @ret_code = fs_updordtots @order_no,@order_ext
    if @ret_code != 1
    begin
      insert adm_post_hist_batch_errors (
        post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
        infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
        source_ctrl_num ,	extra, 		order_no, 	order_ext)
      select 
        @post_batch_id, 	18000, 	@ret_code, 	'Update Order Totals failed' , 	
        @err_msg,			0, 		0 , 	0,	'' , 	0,
        '' , '', 	@order_no, 	@order_ext

      CONTINUE
    end

    begin tran

    UPDATE orders_all
    SET printed = 'S', status = 'S', process_ctrl_num = @batch
    WHERE order_no = @order_no    AND ext = @order_ext and (status != 'S' or process_ctrl_num != @batch)

    IF @@error <> 0   
    BEGIN
      rollback tran
      CONTINUE
    END

    if @consolidate_flag = 0 and
      not exists (select 1 from orders_invoice (nolock) where order_no = @order_no and order_ext = @order_ext and isnull(doc_ctrl_num,'') != '')
    begin
      rollback tran
      CONTINUE
    END

    if @blanket = 'Y'
    begin
      exec @ret_code = fs_calculate_oetax_wrap @order_no,0, 0, 1
      if @ret_code < 1
      begin
        rollback tran
        CONTINUE
      end

      exec @ret_code = fs_updordtots @order_no,0
      if @ret_code != 1
      begin
        rollback tran
        CONTINUE
      end
    end

    if @cca_installed = 'Y'
    begin
      exec @ret_code = adm_post_process_cca @order_no, @order_ext, @ord_type,
        @cca_amt, @cust_key, @ll_orig_no, @ll_orig_ext, @ls_icv_stat OUT, @icv_val_code OUT, 
        @icv_credit OUT, @icv_type OUT, @icv_cust_dflts OUT, @processor OUT, 
        @nat_cur_code OUT, @err_msg OUT

      if @ret_code < 1
      begin
        rollback tran
        CONTINUE
      end
    end

    commit tran

    if isnull(@consolidate_flag,0) = 0
    begin
      if isnull(@trx_ctrl_num,'') = ''
      BEGIN
        EXEC @result = adm_arnewnum_sp @trx_type, 1, @first_tcn OUT, @tcn_mask OUTPUT
        IF ( @result != 0 )
        BEGIN
          select @msg2 = 'Could not generate trx control number.'
          select @msg = ''

          insert adm_post_hist_batch_errors (
            post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
            infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
            source_ctrl_num ,	extra, 		order_no, 	order_ext)
          select 
            @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
            0, 		0 , 	'' , 	'',	'',
            '' , '', 	@order_no, 	@order_ext

          CONTINUE
        END

        select @trx_ctrl_num = dbo.adm_fmtctlnm_fn(@first_tcn, @tcn_mask)

        update orders_invoice set trx_ctrl_num = @trx_ctrl_num
        where order_no = @order_no and order_ext = @order_ext
      END
      else
      begin
        -- if tax record exists, remove it
        exec @tax_rc = adm_post_ar_cancel_tax @msg2 OUT, @trx_ctrl_num, @trx_type
        if @tax_rc < 1
        begin
          select @msg = ''

          insert adm_post_hist_batch_errors (
            post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
            infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
            source_ctrl_num ,	extra, 		order_no, 	order_ext)
          select 
            @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
            0, 		0 , 	'' , 	@trx_ctrl_num,	'',
            '' , '', 	@order_no, 	@order_ext

          CONTINUE
        end      
      end

      if isnull(@trx_ctrl_num,'') = ''
      BEGIN
        select @msg2 = 'Could not generate masked trx control number.'
        select @msg = ''

        insert adm_post_hist_batch_errors (
          post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
          infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
          source_ctrl_num ,	extra, 		order_no, 	order_ext)
        select 
          @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
          0, 		0 , 	'' , 	'',	'',
          '' , '', 	@order_no, 	@order_ext

        CONTINUE
      END

      exec @tax_rc = fs_calculate_oetax_wrap @ord = @order_no, @ext = @order_ext,
        @debug = 0, @batch_call = 1,  @doctype = 1, @trx_ctrl_num = @trx_ctrl_num, 
        @err_msg = @err_msg OUT

      if @tax_rc <> 1
      begin
        insert adm_post_hist_batch_errors (
          post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
          infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
          source_ctrl_num ,	extra, 		order_no, 	order_ext)
        select 
          @post_batch_id, 	18000, 	90, 	'Tax not calculated successfully' , 	
          @err_msg,			0, 		0 , 	0,	@trx_ctrl_num , 	0,
          '' , '', 	@order_no, 	@order_ext

        CONTINUE
      end

      insert #orders (order_no, ext, trx_ctrl_num, trx_type)
      select	@order_no,  @order_ext, @trx_ctrl_num, @trx_type

      IF ( @@error != 0 )
      BEGIN
        select @msg = 'Could not insert on #orders table'
        exec @tax_rc = adm_post_ar_cancel_tax @msg2 out, @trx_ctrl_num, @trx_type

        insert adm_post_hist_batch_errors (
          post_batch_id, 	module_id, 	err_code, 	info1, 		info2 ,
          infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
          source_ctrl_num ,	extra, 		order_no, 	order_ext)
        select 
          @post_batch_id, 	18000, 	0, 	@msg , 	@msg2,
          0, 		0 , 	'' , 	'',	'',
          '' , '', 	@order_no, 	@order_ext

        CONTINUE
      END     
    end -- consolidate = 0

    if @eprocurement_ind = 1
    begin
      update orders_all								-- mls 7/16/03 SCR 31491
      set status = 'T',
        date_transfered = dateadd(day, (datediff(day, '01/01/1900', date_shipped) + 693596) - 693596, '01/01/1900'),
        process_ctrl_num  = '',
        invoice_no = -1	
      WHERE order_no = @order_no    AND ext = @order_ext

      delete from #orders where order_no = @order_no and ext = @order_ext
      CONTINUE
    end
 
    if @consolidate_flag = 1
    begin
      update orders_all								-- mls 3/24/03 SCR 30877
      set status = 'T',
      date_transfered = dateadd(day, (datediff(day, '01/01/1900', date_shipped) + 693596) - 693596, '01/01/1900'),
      process_ctrl_num  = ''	
      WHERE order_no = @order_no    AND ext = @order_ext

      CONTINUE
    end

    select @num_in_batch = @num_in_batch + 1
    select @num_posted = @num_posted + 1

    if (((@num_posted >= @num_to_post) and @num_to_post != 0) 
      or (@num_in_batch >= @arpost_batch_size)) and @process_ctrl_num is NULL
      BREAK
  END
  CLOSE update_order_cursor 
  DEALLOCATE update_order_cursor 

  if @num_in_batch != 0 and 
    (@cursor_rows = 0 or @num_in_batch >= @arpost_batch_size or @process_ctrl_num is not NULL
    or ((@num_posted >= @num_to_post) and @num_to_post != 0))
  begin 			
      EXECUTE    adm_post_ar_work  @process_user_id, @user, @post_batch_id, @batch, @trx_type,
        @ar_incl_non_tax OUT, @printed OUT, @home_currency OUT, @oper_currency OUT,
        @company_id OUT, @post_ar_error OUT, @num_in_batch OUT

      update adm_post_hist_batch
      set end_time = getdate(),
        ret_code = @post_ar_error,
        num_processed = @num_in_batch
      where post_batch_id = @post_batch_id

      update adm_post_history
      set batch_cnt = batch_cnt + 1
      where post_id = @post_id

      exec fs_close_batch @batch, 0

      select @post_batch_id = 0
      select @err = @post_ar_error
      if @post_ar_error = 1 and @psql_glpost_mth = 'D'
      begin
        exec @ret_code = adm_process_gl @user,@gl_method,'',0,0,@err out
      end

      exec @tax_rc = adm_post_ar_cancel_tax @msg2 out

      update orders_all
      set process_ctrl_num = ''
      where process_ctrl_num = @batch and status = 'S'

      set @batch = ''
      set @num_in_batch = 0
  end

  if @process_ctrl_num is NOT NULL
  begin
    update orders_all
    set process_ctrl_num = ''
    where process_ctrl_num = @process_ctrl_num and status = 'S'

    BREAK
  end

  if @cursor_rows = 0
  begin
    if @process_status = 'S'
      BREAK

    set @process_status = 'S'
    set @last_order = 0
  end
end

if @post_batch_id != 0
begin
  update adm_post_hist_batch
  set end_time = getdate(),
    ret_code = 0,
    num_processed = 0
  where post_batch_id = @post_batch_id
end

update adm_post_history
  set end_time = getdate()
where post_id = @post_id

if exists (select 1 from adm_post_history (nolock) where post_type = 'AR' and datediff(dd,getdate(),start_time) < -7)
begin
  delete e
  from adm_post_history h, adm_post_hist_batch b, adm_post_hist_batch_errors e
  where h.post_id = b.post_id and b.post_batch_id = e.post_batch_id
    and datediff(dd,getdate(),h.start_time) < -7

  delete b
  from adm_post_history h, adm_post_hist_batch b
  where h.post_id = b.post_id and datediff(dd,getdate(),h.start_time) < -7

  delete h
  from adm_post_history h
  where datediff(dd,getdate(),h.start_time) < -7
end

select @err = 1

if @online_call = 1
begin
  if exists (select 1 from adm_post_hist_batch_errors e (nolock)
    join adm_post_hist_batch b on b.post_batch_id = e.post_batch_id
    where post_id = @post_id)
    select @err, e.post_batch_id, 	module_id, 	err_code, 	info1, 	
      case when module_id = 18000 then '' else info2 end ,
      infoint, 		infofloat , 	flag1 , 	trx_ctrl_num , 	sequence_id , 
      source_ctrl_num ,	extra, 		order_no, 	order_ext,
	  a.refer_to, a.field_desc, case when module_id = 18000 then info2 else a.err_desc end err_desc
    from adm_post_hist_batch_errors e
    join adm_post_hist_batch b on b.post_batch_id = e.post_batch_id
    left outer join aredterr a on a.e_code = e.err_code and e.module_id != 18000
    where b.post_id = @post_id
  else
    select @err, 0, 0, 0, 'OK', '', 0, 0, 0, '', 0, '', 0, 0, 0, '', '', ''
end

return @err


END
GO
GRANT EXECUTE ON  [dbo].[adm_post_ar] TO [public]
GO
