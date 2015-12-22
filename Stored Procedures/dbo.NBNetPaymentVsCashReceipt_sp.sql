SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[NBNetPaymentVsCashReceipt_sp] 		@net_ctrl_num 		varchar(16), 
							@vend_susp_acct 	varchar(32),	
							@cust_susp_acct		varchar(32),
							@process_ctrl_num	varchar(16),
							@debug_level 		smallint
AS

	


	CREATE TABLE #gain_loss	(
	settlement_ctrl_num	varchar(16) NULL,	trx_ctrl_num	    varchar(16)	NULL,	sequence_id         int         NULL,   
	artrx_doc_ctrl_num	varchar(16) NULL,	cross_rate          float       NULL,	adj_home            float       NULL,
	adj_oper            	float       NULL,	rate_home_cur       float       NULL,	rate_oper_cur       float       NULL,
	rate_home_org       	float       NULL,	rate_oper_org       float       NULL    )
	CREATE INDEX argain_loss_ind_0	ON #gain_loss (settlement_ctrl_num,trx_ctrl_num,sequence_id)

	
CREATE TABLE #arinppyt4750
(
       timestamp            timestamp,
       trx_ctrl_num         varchar(16),
  doc_ctrl_num         varchar(16),
  trx_desc             varchar(40),
  batch_code           varchar(16),
       trx_type             smallint,
  non_ar_flag   smallint,
  non_ar_doc_num       varchar(16),
  gl_acct_code         varchar(32), 
  date_entered         int,
  date_applied         int,
  date_doc             int,
       customer_code        varchar(8),
  payment_code         varchar(8),
  payment_type         smallint, 
             
             
             
       amt_payment          float,
  amt_on_acct          float,
  prompt1_inp          varchar(30),
  prompt2_inp          varchar(30),
  prompt3_inp          varchar(30),
  prompt4_inp          varchar(30),
  deposit_num          varchar(16),
  bal_fwd_flag         smallint, 
             
  printed_flag         smallint,
  posted_flag          smallint,
  hold_flag            smallint,
  wr_off_flag          smallint, 
             
             
  on_acct_flag         smallint, 
             
             
  user_id              smallint, 
  max_wr_off           float,   
  days_past_due        int,   
  void_type            smallint,  
             
             
             
  cash_acct_code       varchar(32),
       origin_module_flag   smallint NULL, 


  process_group_num    varchar(16) NULL,
  source_trx_ctrl_num varchar(16) NULL,
  source_trx_type      smallint NULL,
  nat_cur_code         varchar(8),  
  rate_type_home       varchar(8),
  rate_type_oper       varchar(8),
  rate_home            float,
  rate_oper            float,        
  amt_discount    float NULL,   
  reference_code  varchar(32) NULL  ,
  settlement_ctrl_num varchar(16) NULL, 
  doc_amount	  float NULL,
  org_id          varchar(30)
)

	CREATE INDEX arinppyt_ind_0   		ON #arinppyt4750 (customer_code,trx_ctrl_num,trx_type)
	CREATE UNIQUE INDEX arinppyt_ind_1   	ON #arinppyt4750 (trx_ctrl_num,trx_type)

	
CREATE TABLE #arinppdt4750
(
	timestamp            timestamp,
	trx_ctrl_num         varchar(16),
	doc_ctrl_num         varchar(16),
	sequence_id          int,
	trx_type             smallint,
	apply_to_num         varchar(16),
	apply_trx_type       smallint,
	customer_code        varchar(8),
	date_aging           int,
	amt_applied          float,
	amt_disc_taken       float,
	wr_off_flag          smallint,
	amt_max_wr_off       float,
	void_flag            smallint,
	line_desc            varchar(40),
	sub_apply_num        varchar(16),
	sub_apply_type       smallint,
	amt_tot_chg          float,	      
	amt_paid_to_date     float,       
	terms_code           varchar(8),  
	posting_code         varchar(8),  
	date_doc             int,	      
	amt_inv              float,       
	gain_home            float,       
	gain_oper            float,
	inv_amt_applied      float,
	inv_amt_disc_taken   float,
	inv_amt_max_wr_off   float,        
	inv_cur_code		varchar(8),	
	writeoff_code	     varchar(8)	NULL DEFAULT "",	
	writeoff_amount	     float,		
	cross_rate	     float,		
	org_id		     varchar(30)
)

	CREATE UNIQUE CLUSTERED INDEX arinppdt_ind_0   ON #arinppdt4750 (trx_ctrl_num,trx_type,sequence_id)
	CREATE INDEX arinppdt_ind_1	ON #arinppdt4750 (apply_to_num,trx_type)


	CREATE TABLE #arinpstlhdr	(
	settlement_ctrl_num 	varchar(16) NOT NULL,	description	 varchar(40),		hold_flag 		smallint,
	posted_flag 		smallint,		date_entered	 int NOT NULL,		date_applied		int NOT NULL, 
	user_id 		smallint,		process_group_num varchar(16) NULL,	doc_count_expected	int,
	doc_count_entered 	int,			doc_sum_expected  float,		doc_sum_entered 	float,
	cr_total_home 		float,			cr_total_oper 	 float,			oa_cr_total_home 	float,
	oa_cr_total_oper 	float,			cm_total_home 	 float,			cm_total_oper 		float,
	inv_total_home		float,			inv_total_oper	 float,			disc_total_home 	float,
	disc_total_oper 	float,			wroff_total_home float,			wroff_total_oper	float,
	onacct_total_home 	float,			onacct_total_oper float,		gain_total_home 	float,
	gain_total_oper 	float,			loss_total_home  float,			loss_total_oper 	float,
	amt_on_acct		float,			inv_amt_nat	float,			amt_doc_nat		float,
	amt_dist_nat	 	float,			customer_code	varchar(8),		nat_cur_code		varchar(8),
	rate_type_home		varchar(8),		rate_home	float,			rate_type_oper		varchar(8),
	rate_oper		float,	 		settle_flag 	int,			org_id			varchar(30)NULL	)
	CREATE UNIQUE INDEX arsinpstlhdr_ind_0 ON #arinpstlhdr ( settlement_ctrl_num )


	

CREATE TABLE #apinppyt3450
(
	timestamp timestamp,
	trx_ctrl_num varchar(16),
	trx_type smallint,	
						
	doc_ctrl_num varchar(16), 
	trx_desc varchar(40),
	batch_code varchar(16),
	cash_acct_code varchar(32),
	date_entered int,
	date_applied int,
	date_doc int,
	vendor_code varchar(12),
	pay_to_code varchar(8),
	approval_code varchar(8),
	payment_code varchar(8),
	payment_type smallint, 
					 
					 
	amt_payment float, 
	amt_on_acct float,
	posted_flag smallint,
	printed_flag smallint, 
					 
					 
	hold_flag smallint,
	approval_flag smallint,
	gen_id int, 
	user_id smallint, 
	void_type smallint, 
					 
					 
	amt_disc_taken float,
	print_batch_num int, 
	company_code varchar(8), 
	process_group_num varchar(16) NULL,
	nat_cur_code			varchar(8) NULL,
	rate_type_home			varchar(8) NULL,
	rate_type_oper			varchar(8) NULL,
	rate_home				float NULL,
	rate_oper				float NULL,
	payee_name				varchar(40) NULL,
	settlement_ctrl_num	varchar(16) NULL,
	doc_amount				float	,
	org_id				varchar(30) NULL
)


	
CREATE TABLE #apinppdt3450
(
	timestamp			timestamp,
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	sequence_id			int,		
	apply_to_num		varchar(16),	
	apply_trx_type		smallint,	
	amt_applied			float,		
	amt_disc_taken		float,		
	line_desc			varchar(40),
	void_flag			smallint,
	payment_hold_flag	smallint,
	vendor_code			varchar(12),
	vo_amt_applied		float NULL,
	vo_amt_disc_taken	float NULL,
	gain_home			float NULL,
	gain_oper			float NULL,
	nat_cur_code		varchar(8) NULL,
	cross_rate			float NULL,
	org_id				varchar(30) NULL
)


	CREATE TABLE #apinpstl	(
	settlement_ctrl_num 	varchar (16) NOT NULL,		vendor_code 		varchar (12) NOT NULL ,
	pay_to_code 		varchar (8) NOT NULL ,		hold_flag 		smallint NOT NULL ,	
	date_entered 		int NOT NULL,			date_applied 		int NOT NULL ,
	user_id 		smallint NOT NULL,		batch_code 		varchar (16) NOT NULL ,
	process_group_num 	varchar (16) NOT NULL ,		state_flag 		smallint NOT NULL ,
	disc_total_home 	float NOT NULL ,		disc_total_oper 	float NOT NULL ,
	debit_memo_total_home 	float NOT NULL ,		debit_memo_total_oper 	float NOT NULL ,
	on_acct_pay_total_home 	float NOT NULL ,		on_acct_pay_total_oper 	float NOT NULL ,
	payments_total_home 	float NOT NULL ,		payments_total_oper 	float NOT NULL ,
	put_on_acct_total_home 	float NOT NULL ,		put_on_acct_total_oper 	float NOT NULL ,
	gain_total_home 	float NOT NULL ,		gain_total_oper 	float NOT NULL ,
	loss_total_home 	float NOT NULL ,		loss_total_oper 	float NOT NULL,
	description		varchar(40),			nat_cur_code 		varchar(12),
	doc_count_expected      int,				doc_count_entered       int,
	doc_sum_expected        float,				doc_sum_entered         float,
	vo_total_home    	float,				vo_total_oper    	float,
	rate_type_home    	varchar(8),			rate_home         	float,
	rate_type_oper    	varchar(8),			rate_oper         	float,
	vo_amt_nat	    	float,				amt_doc_nat	    	float,
	amt_dist_nat	    	float,				amt_on_acct	    	float,
	org_id			varchar(30)			)

	CREATE CLUSTERED INDEX apinpstl_01 ON #apinpstl (vendor_code,settlement_ctrl_num)

	

















CREATE TABLE #arinpchg
(
  link      varchar(16) NULL,
  trx_ctrl_num    varchar(16) NULL,
  doc_ctrl_num    varchar(16) NULL,
  doc_desc    varchar(40) NULL,
  apply_to_num    varchar(16) NULL,
  apply_trx_type  smallint NULL,
  order_ctrl_num  varchar(16) NULL,
  batch_code    varchar(16) NULL,
  trx_type    smallint NULL,
  date_entered    int NULL,
  date_applied    int NULL,
  date_doc    int NULL,
  date_shipped    int NULL,
  date_required   int NULL,
  date_due    int NULL,
  date_aging    int NULL,
  customer_code   varchar(8),
  ship_to_code    varchar(8) NULL,
  salesperson_code  varchar(8) NULL,
  territory_code  varchar(8) NULL,
  comment_code    varchar(8) NULL,
  fob_code    varchar(8) NULL,
  freight_code    varchar(8) NULL,
  terms_code    varchar(8) NULL,
  fin_chg_code    varchar(8) NULL,
  price_code    varchar(8) NULL,
  dest_zone_code  varchar(8) NULL,
  posting_code    varchar(8) NULL,
  recurring_flag  smallint NULL,
  recurring_code  varchar(8) NULL,
  tax_code    varchar(8) NULL,
  cust_po_num   varchar(20) NULL,
  total_weight    float NULL,
  amt_gross   float NULL,
  amt_freight   float NULL,
  amt_tax   float NULL,
  amt_tax_included  float NULL,
  amt_discount    float NULL,
  amt_net   float NULL,
  amt_paid    float NULL,
  amt_due   float NULL,
  amt_cost    float NULL,
  amt_profit    float NULL,
  next_serial_id  smallint NULL,
  printed_flag    smallint NULL,
  posted_flag   smallint NULL,
  hold_flag   smallint NULL,
  hold_desc   varchar(40) NULL,
  user_id   smallint NULL,
  customer_addr1  varchar(40) NULL,
  customer_addr2  varchar(40) NULL,
  customer_addr3  varchar(40) NULL,
  customer_addr4  varchar(40) NULL,
  customer_addr5  varchar(40) NULL,
  customer_addr6  varchar(40) NULL,
  ship_to_addr1   varchar(40) NULL,
  ship_to_addr2   varchar(40) NULL,
  ship_to_addr3   varchar(40) NULL,
  ship_to_addr4   varchar(40) NULL,
  ship_to_addr5   varchar(40) NULL,
  ship_to_addr6   varchar(40) NULL,
  attention_name  varchar(40) NULL,
  attention_phone varchar(30) NULL,
  amt_rem_rev   float NULL,
  amt_rem_tax   float NULL,
  date_recurring  int NULL,
  location_code   varchar(8) NULL,
  process_group_num varchar(16) NULL,
  trx_state   smallint NULL,
  mark_flag   smallint   NULL,
  amt_discount_taken  float NULL,
  amt_write_off_given float NULL, 
  source_trx_ctrl_num varchar(16) NULL,
  source_trx_type smallint NULL,
  nat_cur_code    varchar(8) NULL,  
  rate_type_home  varchar(8) NULL,  
  rate_type_oper  varchar(8) NULL,  
  rate_home   float NULL, 
  rate_oper   float NULL, 
  edit_list_flag  smallint NULL,
  ddid      varchar(32) NULL,
  writeoff_code	varchar(8)	NULL DEFAULT '',
  org_id	varchar(30)	NULL
)

CREATE INDEX #arinpchg_ind_0 
ON #arinpchg ( trx_ctrl_num, trx_type )
CREATE INDEX  #arinpchg_ind_1 
ON  #arinpchg (batch_code)

	
	















create table #arinpcdt 
(
	link			varchar(16) NULL,
	trx_ctrl_num	 	varchar(16) NULL,
	doc_ctrl_num	 	varchar(16) NULL,
	sequence_id	 	int NULL,
	trx_type	 	smallint NULL,
	location_code	 	varchar(8) NULL,
	item_code	 	varchar(30) NULL,
	bulk_flag	 	smallint NULL,
	date_entered	 	int NULL,
	line_desc	 	varchar(60) NULL,
	qty_ordered	 	float NULL,
	qty_shipped	 	float NULL,
	unit_code	 	varchar(8) NULL,
	unit_price	 	float,
	unit_cost	 	float NULL,
	weight	 		float NULL,
	serial_id	 	int NULL,
	tax_code	 	varchar(8) NULL,
	gl_rev_acct	 	varchar(32) NULL,
	disc_prc_flag	 	smallint NULL,
	discount_amt	 	float NULL,
	commission_flag	smallint NULL,
	rma_num		varchar(16) NULL,
	return_code	 	varchar(8) NULL,
	qty_returned	 	float NULL,
	qty_prev_returned	float NULL,
	new_gl_rev_acct	varchar(32) NULL,
	iv_post_flag	 	smallint NULL,
	oe_orig_flag	 	smallint NULL,
	discount_prc		float NULL,	
	extended_price	float NULL,	
	calc_tax		float NULL,
	reference_code	varchar(32)	NULL,
	trx_state		smallint	NULL,
	mark_flag		smallint	NULL,
	cust_po 		VARCHAR(20) NULL,	
	new_reference_code	varchar(32) NULL,
	org_id 			varchar(30) NULL
)

CREATE INDEX arinpcdt_ind_0 
	ON #arinpcdt ( trx_ctrl_num, trx_type, sequence_id )


	CREATE TABLE #arinptax	(
	trx_ctrl_num	varchar(16),	trx_type	smallint,	sequence_id	int,
	tax_type_code	varchar(8),	amt_taxable	float,		amt_gross	float,
	amt_tax		float,		amt_final_tax	float		)
	CREATE UNIQUE CLUSTERED INDEX arinptax_ind_0 ON #arinptax (trx_ctrl_num, trx_type, sequence_id)

	CREATE TABLE #arinpage	(
	trx_ctrl_num	varchar(16),	sequence_id	int,		doc_ctrl_num	varchar(16),
	apply_to_num	varchar(16),	apply_trx_type	smallint,	trx_type	smallint,
	date_applied	int,		date_due	int,		date_aging	int,
	customer_code	varchar(8),	salesperson_code varchar(8),	territory_code	varchar(8),
	price_code	varchar(8),	amt_due	float		)
	CREATE CLUSTERED INDEX arinpage_ind_0 ON #arinpage (apply_to_num,trx_type,date_aging)


	

















CREATE TABLE  #apinpchg  (
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	doc_ctrl_num		varchar(16),
	apply_to_num		varchar(16),
	user_trx_type_code	varchar(8),
	batch_code			varchar(16),
	po_ctrl_num			varchar(16),
	vend_order_num		varchar(20),
	ticket_num			varchar(20),
	date_applied		int,
	date_aging			int,
	date_due			int,
	date_doc			int,
	date_entered		int,
	date_received		int,
	date_required		int,
	date_recurring		int,
	date_discount		int,
	posting_code		varchar(8),
	vendor_code			varchar(12),
	pay_to_code			varchar(8),
	branch_code			varchar(8),
	class_code			varchar(8),
	approval_code		varchar(8),
	comment_code		varchar(8),
	fob_code			varchar(8),
	terms_code			varchar(8),
	tax_code			varchar(8),
	recurring_code		varchar(8),
	location_code		varchar(8),
	payment_code		varchar(8),
	times_accrued		smallint,
	accrual_flag		smallint,
	drop_ship_flag		smallint,
	posted_flag			smallint,
	hold_flag			smallint,
	add_cost_flag		smallint,
	approval_flag		smallint,
	recurring_flag		smallint,
	one_time_vend_flag	smallint,
	one_check_flag		smallint,
	amt_gross			float,
	amt_discount		float,
	amt_tax				float,
	amt_freight			float,
	amt_misc			float,
	amt_net				float,
	amt_paid			float,
	amt_due				float,
	amt_restock			float,
	amt_tax_included	float,
	frt_calc_tax		float,
	doc_desc			varchar(40),
	hold_desc			varchar(40),
	user_id				smallint,
	next_serial_id		smallint,
	pay_to_addr1		varchar(40),
	pay_to_addr2		varchar(40),
	pay_to_addr3		varchar(40),
	pay_to_addr4		varchar(40),
	pay_to_addr5		varchar(40),
	pay_to_addr6		varchar(40),
	attention_name		varchar(40),
	attention_phone		varchar(30),
	intercompany_flag	smallint,
	company_code		varchar(8),
	cms_flag			smallint,
	process_group_num   varchar(16),
	nat_cur_code 		varchar(8),	 
	rate_type_home 		varchar(8),	 
	rate_type_oper		varchar(8),	 
	rate_home 			float,		   
	rate_oper			float,		   
	trx_state        	smallint    NULL,
	mark_flag           smallint	 NULL,
	net_original_amt	float,
	org_id		varchar(30) NULL,
	tax_freight_no_recoverable float
	)


	CREATE UNIQUE CLUSTERED INDEX apinpchg_ind_0 ON #apinpchg ( trx_ctrl_num, trx_type )

	




















CREATE TABLE #apinpcdt   (
	trx_ctrl_num			varchar(16),
	trx_type            	smallint,
	sequence_id         	int,
	location_code       	varchar(8),
	item_code           	varchar(30),
	bulk_flag           	smallint,
	qty_ordered         	float,
	qty_received        	float,
	qty_returned        	float,
	qty_prev_returned   	float,
	approval_code			varchar(8),
	tax_code            	varchar(8),
	return_code         	varchar(8),
	code_1099           	varchar(8),
	po_ctrl_num         	varchar(16),
	unit_code           	varchar(8),
	unit_price          	float,
	amt_discount        	float,
	amt_freight         	float,
	amt_tax             	float,
	amt_misc            	float,
	amt_extended        	float,
	calc_tax            	float,
	date_entered        	int,
	gl_exp_acct         	varchar(32),
	new_gl_exp_acct     	varchar(32),
	rma_num             	varchar(20),
	line_desc           	varchar(60),
	serial_id           	int,
	company_id          	smallint,
	iv_post_flag        	smallint,
	po_orig_flag        	smallint,
	rec_company_code    	varchar(8),
	new_rec_company_code	varchar(8),
	reference_code			varchar(32),
	new_reference_code		varchar(32),
	trx_state        		smallint NULL,
	mark_flag           	smallint NULL,
	org_id		varchar(30) NULL,
	amt_nonrecoverable_tax	float,
	amt_tax_det		float

	)


	CREATE CLUSTERED INDEX apinpcdt_ind_0	ON #apinpcdt ( trx_ctrl_num, trx_type, sequence_id )

	CREATE TABLE #apinptax	(
	trx_ctrl_num	varchar(16),	trx_type	smallint,	sequence_id	int,
	tax_type_code	varchar(8),	amt_taxable	float,		amt_gross	float,
	amt_tax		float,		amt_final_tax	float	)
	CREATE CLUSTERED INDEX apinptax_ind_0 ON #apinptax ( trx_ctrl_num, trx_type, sequence_id )

	CREATE TABLE #apinpage	(
	trx_ctrl_num	varchar(16),	trx_type	smallint,	sequence_id	int,
	date_applied	int,		date_due	int,		date_aging	int,
	amt_due		float		)
	CREATE UNIQUE CLUSTERED INDEX apinpage_ind_0 ON #apinpage ( trx_ctrl_num, trx_type, date_aging )


	DECLARE	@customer_code		varchar(8),
		@ar_terms_code		varchar(8),		
		@ap_terms_code		varchar(8),
		@ap_posting_code	varchar(8),
		@ar_posting_code	varchar(8),
		@nat_cur_code		varchar(8),
		@rate_type_home		varchar(8),
		@rate_type_oper		varchar(8),
		@ar_payment_code	varchar(8),
		@ap_payment_code	varchar(8),
		@company_code		varchar(8),
		@branch_code		varchar(8),
		@class_code		varchar(8),
		@ship_to_code		varchar(8),
		@ar_comment_code	varchar(8),
		@ap_comment_code	varchar(8),
		@ar_fob_code		varchar(8),
		@ap_fob_code		varchar(8),
		@salesperson_code	varchar(8),
		@ar_location_code	varchar(8),
		@ap_location_code	varchar(8),
		@territory_code		varchar(8),
		@payment_code_work  varchar(8),
		@freight_code		varchar(8),
		@price_code		varchar(8),
		@dest_zone_code		varchar(8),
		@fin_chg_code		varchar(8),
		@vendor_code 		varchar(12),
		@inv_ctrl_num		varchar(16),
		@deb_trx_ctrl_num	varchar(16),
		@cre_trx_ctrl_num	varchar(16),
		@vou_ctrl_num		varchar(16),
		@doc_ctrl_num		varchar(16),
		@ded_doc_ctrl_num	varchar(16),
		@cre_doc_ctrl_num		varchar(16),
		@ar_settlement_ctrl_num	varchar(16),
		@ap_settlement_ctrl_num	varchar(16),
		@payment_ctrl_num	varchar(16),
		@net_doc_num		varchar(16),
		@settlement_ctrl_num	varchar(16),
		@cash_acct_code		varchar(32),
		@cash_account_work		varchar(32),
		@attention_phone	varchar(30),
		@attention_name		varchar(40),
		@cust_addr1		varchar(40),
		@cust_addr2		varchar(40),
		@cust_addr3		varchar(40),
		@cust_addr4		varchar(40),
		@cust_addr5		varchar(40),
		@cust_addr6		varchar(40),
		@deb_amt_committed 	float, 
		@cre_amt_committed	float,
		@amt_applied		float,
		@amt_committed		float,
		@deb_committed		float,
		@cre_committed		float,
		@rate_home		float,
		@rate_oper		float,
		@date_entered		int,
		@sequence_id		int,
		@trx_type		int,
		@num			int,
		@counter		int,
		@payment_type	int,
		@count_vouchers		int,
		@count_pay_dm		int,
		@company_id		smallint,
		@rows			smallint,
		@result			smallint,
		@user_trx_type_code	varchar(8),
		@ar_rate_type_home	varchar(8),
		@ar_rate_type_oper	varchar(8),
		@ap_rate_type_home	varchar(8),
		@ap_rate_type_oper	varchar(8),
		@ap_rate_home		float,
		@ap_rate_oper		float,
		@ar_rate_home		float,
		@ar_rate_oper		float,
		@approval_code        	varchar(8),
		@root_org_id		varchar(30)





SELECT @root_org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'')    
	

exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',0,''

SELECT	@customer_code 	= customer_code,
		@vendor_code 	= vendor_code,
		@nat_cur_code	= currency_code
FROM 	#nbnethdr_work
WHERE	net_ctrl_num 	= @net_ctrl_num

select @approval_code= default_aprv_code from apco
		
IF @approval_code IS NULL
	select @approval_code= '0'


SELECT	@deb_amt_committed = ISNULL(SUM(amt_committed),0.00)
FROM	#nbnetdeb_work
WHERE	net_ctrl_num 	= @net_ctrl_num
AND	trx_type	IN (4111,4092,4091)		
AND	amt_committed 	> 0.00
	
	


SELECT	@cre_amt_committed = ISNULL(SUM(amt_committed),0.00)
FROM	#nbnetcre_work
WHERE	net_ctrl_num 	= @net_ctrl_num
AND	trx_type 	IN (2111,2032)			
AND	amt_committed 	> 0.00


IF	@deb_amt_committed = 0.00 OR @cre_amt_committed = 0.00
BEGIN
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',1,''
	RETURN 0
END

IF	@deb_amt_committed > @cre_amt_committed 
	SELECT @deb_amt_committed = @cre_amt_committed
Else
	SELECT @cre_amt_committed = @deb_amt_committed

SELECT	@ap_terms_code		= ISNULL(terms_code,''),
	@ap_posting_code	= ISNULL(posting_code,''),
	@ap_payment_code	= ISNULL(payment_code,''),
	@cash_acct_code		= ISNULL(cash_acct_code,''),
	@branch_code		= ISNULL(branch_code,''),
	@class_code		= ISNULL(vend_class_code,''),
	@ap_comment_code	= ISNULL(comment_code,''), 
	@ap_fob_code		= ISNULL(fob_code,''),
	@ap_location_code 	= ISNULL(location_code,''),
	@attention_name		= ISNULL(attention_name,''),
	@attention_phone	= ISNULL(attention_phone,'')
FROM 	apvend
WHERE	vendor_code		= @vendor_code


SELECT	@ar_terms_code		= ISNULL(terms_code,''),
	@ar_posting_code	= ISNULL(posting_code,''),
	@ar_payment_code	= ISNULL(payment_code,''),
	@ship_to_code		= ISNULL(ship_to_code,''),	
	@salesperson_code	= ISNULL(salesperson_code,''),
	@territory_code		= ISNULL(territory_code,''),
	@ar_comment_code	= ISNULL(inv_comment_code,''),	
	@ar_fob_code		= ISNULL(fob_code,''),
	@freight_code		= ISNULL(freight_code,''),
	@price_code		= ISNULL(price_code,''),
	@dest_zone_code		= ISNULL(dest_zone_code,''),
	@cust_addr1		= ISNULL(addr1,''),	
	@cust_addr2		= ISNULL(addr2,''),
	@cust_addr3		= ISNULL(addr3,''),
	@cust_addr4		= ISNULL(addr4,''),
	@cust_addr5		= ISNULL(addr5,''),
	@cust_addr6		= ISNULL(addr6,''),
	@ar_location_code 	= ISNULL(location_code,''),
	@fin_chg_code		= ISNULL(fin_chg_code,'')
FROM 	arcust
WHERE	customer_code		= @customer_code

	
SELECT 	@company_code 	= company_code,
	@company_id	= company_id	
FROM	glco

EXEC	appdate_sp @date_entered OUTPUT

EXEC ARGetNextControl_SP 2015, @ar_settlement_ctrl_num OUTPUT, @num OUTPUT

EXEC apnewnum_sp 4116, @company_code, @ap_settlement_ctrl_num OUTPUT

IF @ap_settlement_ctrl_num IS NULL OR @ar_settlement_ctrl_num IS NULL
Begin
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',2,''
	RETURN 1
End


INSERT #arinpstlhdr
	(settlement_ctrl_num,	description,		hold_flag,		posted_flag,		date_entered,		
	date_applied,		user_id,		process_group_num,	doc_count_expected, 	doc_count_entered,	
	doc_sum_expected,	doc_sum_entered,	cr_total_home,		cr_total_oper,		oa_cr_total_home,	
	oa_cr_total_oper,	cm_total_home,		cm_total_oper,		inv_total_home,		inv_total_oper,		
	disc_total_home,	disc_total_oper,	wroff_total_home,	wroff_total_oper,	onacct_total_home,	
	onacct_total_oper,	gain_total_home,	gain_total_oper,	loss_total_home,	loss_total_oper,
	amt_on_acct,		inv_amt_nat,		amt_doc_nat,		amt_dist_nat,		customer_code,
	nat_cur_code,		rate_type_home,		rate_home,		rate_type_oper,		rate_oper,
	settle_flag,		org_id			)
values (
	@ar_settlement_ctrl_num,'Netting Settlement ' + @net_ctrl_num,	
							0,			-1,			@date_entered,
	@date_entered,		USER_ID(),		@process_ctrl_num,	0,			0,			
	0,			0,			0,			0,			0,
	0,		0,			0,			0,			0,
	0,			0,			0,			0,			0,
	0,			0,			0,			0,			0,
	0,			0,			0,			0,			@customer_code,
	@nat_cur_code,		'',			0,			'',			0,	
	0,			@root_org_id		)

IF @@error != 0
Begin
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',3,@ar_settlement_ctrl_num
	RETURN  -1
End
	
INSERT #apinpstl	(
	settlement_ctrl_num,	vendor_code,		pay_to_code,		hold_flag,	
	date_entered,		date_applied,		user_id,		batch_code,
	process_group_num,	state_flag,		disc_total_home,	disc_total_oper,
	debit_memo_total_home,	debit_memo_total_oper,	on_acct_pay_total_home,	on_acct_pay_total_oper,
	payments_total_home,	payments_total_oper,	put_on_acct_total_home,	put_on_acct_total_oper,
	gain_total_home,	gain_total_oper,	loss_total_home,	loss_total_oper,
	description,		nat_cur_code,		doc_count_expected,	doc_count_entered,	
	doc_sum_expected,	doc_sum_entered,	vo_total_home,		vo_total_oper,
	rate_type_home,		rate_home,		rate_type_oper,		rate_oper,
	vo_amt_nat,		amt_doc_nat,		amt_dist_nat,		amt_on_acct,
	org_id			)
values (
	@ap_settlement_ctrl_num,@vendor_code,		'',			0,
	@date_entered,		@date_entered,		USER_ID(),		'',
	@process_ctrl_num,	-1,			0,			0,			
	0.0,			0.0,			0.0,			0.0,
	0.0,			0.0,			0.0,			0.0,
	0.0,			0.0,			0.0,			0.0,
	'Netting Transaction',	@nat_cur_code,		0,			0,		
	0,			0,			0.00,			0.00,
	'',			0.00,			'',			0.00,
	0.00,			0.00,			0.00,			0.00,
	@root_org_id		)


IF @@error != 0
Begin
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',4,@ap_settlement_ctrl_num
	RETURN 	-1
End

SELECT	@count_vouchers = count(amt_committed)
FROM	#nbnetdeb_work
WHERE	net_ctrl_num 	= @net_ctrl_num
AND	trx_type	IN (4091)		
AND	amt_committed 	> 0.00

SELECT  @count_pay_dm = count(amt_committed)
FROM	#nbnetdeb_work
WHERE	net_ctrl_num 	= @net_ctrl_num
AND	trx_type	IN (4111,4092,4091)		
AND	amt_committed 	> 0.00

IF 	@count_vouchers =  @count_pay_dm
BEGIN
	SELECT 	@deb_trx_ctrl_num = MIN(trx_ctrl_num)
	FROM	#nbnetdeb_work
	WHERE	net_ctrl_num	= @net_ctrl_num
	AND	trx_type	IN (4091)
	AND	amt_committed	> 0.00

	SELECT @sequence_id = 1	

	While @deb_trx_ctrl_num is not null
	Begin
		SELECT 	@amt_committed 		= ISNULL(amt_committed,0.00),
			@ded_doc_ctrl_num	= doc_ctrl_num,
			@trx_type		= trx_type
		FROM	#nbnetdeb_work
		WHERE	trx_ctrl_num	= @deb_trx_ctrl_num
		AND	net_ctrl_num	= @net_ctrl_num

		SELECT 	@rate_type_home 	= ISNULL(rate_type_home,''),
			@rate_type_oper 	= ISNULL(rate_type_oper,''),
			@rate_home		= ISNULL(rate_home,0.00),
			@rate_oper		= ISNULL(rate_oper,0.00)
		FROM	apvohdr
		WHERE	trx_ctrl_num = @deb_trx_ctrl_num

		EXEC ARGetNextControl_SP 2000, @inv_ctrl_num OUTPUT, @num OUTPUT

		EXEC apnewnum_sp 4111, @company_code, @payment_ctrl_num OUTPUT

		EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT
				
		INSERT #arinpchg (
		trx_ctrl_num,	doc_ctrl_num,	doc_desc,	apply_to_num,	apply_trx_type,	order_ctrl_num,
		batch_code,	trx_type,	date_entered,	date_applied,	date_doc,	date_shipped,	
		date_required,	date_due,	date_aging,	customer_code,	ship_to_code,	salesperson_code,
		territory_code,	comment_code,	fob_code,	freight_code,	terms_code,	fin_chg_code,
		price_code,	dest_zone_code,	posting_code,	recurring_flag,	recurring_code,	tax_code,
		cust_po_num,	total_weight,	amt_gross,	amt_freight,	amt_tax,	amt_tax_included,
		amt_discount,	amt_net,	amt_paid,	amt_due,	amt_cost,	amt_profit,
		next_serial_id,	printed_flag,	posted_flag,	hold_flag,	hold_desc,	user_id,
		customer_addr1,	customer_addr2,	customer_addr3,	customer_addr4,	customer_addr5,	customer_addr6,
		ship_to_addr1,	ship_to_addr2,	ship_to_addr3,	ship_to_addr4,	ship_to_addr5,	ship_to_addr6,
		attention_name,	attention_phone,amt_rem_rev,	amt_rem_tax,	date_recurring,	location_code,
		process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, amt_write_off_given, nat_cur_code,	
		rate_type_home,	rate_type_oper,	rate_home,	rate_oper,	edit_list_flag,	ddid,
		writeoff_code,	org_id)
		VALUES (
		@inv_ctrl_num,	@net_doc_num,	'Netting Transaction','',	0,		'',	
		'',		2031,		@date_entered,	@date_entered,	@date_entered,	@date_entered,
		@date_entered,	@date_entered,	@date_entered,	@customer_code,	@ship_to_code,	@salesperson_code,
		@territory_code,@ar_comment_code,@ar_fob_code,	@freight_code,	@ar_terms_code,	@fin_chg_code,
		@price_code,	@dest_zone_code,@ar_posting_code,0,		'',		'NBTAX',
		'',		0.00,		@amt_committed,	0.00,		0.00,		0.00,
		0.00,		@amt_committed,	0.00,		@amt_committed,	0.00,		0.00,
		0,		1,		-1,		0,		'',		USER_ID(),
		@cust_addr1,	@cust_addr2,	@cust_addr3,	@cust_addr4,	@cust_addr5,	@cust_addr6,
		'',		'',		'',		'',		'',		'',
		'',		'',		0.00,		0.00,		0,		@ar_location_code,
		@process_ctrl_num,@deb_trx_ctrl_num, NULL,	0.00,		0.00,		@nat_cur_code,
		@rate_type_home,@rate_type_oper,@rate_home,@rate_oper,		0,		NULL,
		'',		@root_org_id)	

		INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,	trx_type	)
		VALUES 			(	@net_ctrl_num,@inv_ctrl_num,	2031		)

		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',5,@inv_ctrl_num

		INSERT	#arinpcdt (
		trx_ctrl_num,		doc_ctrl_num,	sequence_id,	trx_type,	location_code,	item_code,
		bulk_flag,		date_entered,	line_desc,	qty_ordered,	qty_shipped,	unit_code,
		unit_price,		unit_cost,	weight,		serial_id,	tax_code,	gl_rev_acct,
		disc_prc_flag,		discount_amt,	commission_flag,rma_num,	return_code,	qty_returned,
		qty_prev_returned,	new_gl_rev_acct,iv_post_flag,	oe_orig_flag,	discount_prc,	extended_price,
		calc_tax,		reference_code, new_reference_code, org_id	)
		VALUES (
		@inv_ctrl_num,		@net_doc_num,	1,		2031,		@ar_location_code,'',
		0,			@date_entered,	'',		1,		1,		'',	
		@amt_committed,		0.0,		0.0,		0,		'NBTAX',	@cust_susp_acct,
		0,			0.0,		0,		'',		'',		0,
		0.0,			'',		1,		0,		0.0,		@amt_committed,
		0.0,			'',		NULL,		@root_org_id	)

		INSERT 	#arinptax (
		trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
		amt_tax,	amt_final_tax			)
		VALUES (
		@inv_ctrl_num,	2031,		1,		'NBTAX',	@amt_committed,	@amt_committed,
		0.00,		0.00				)

		INSERT #arinpage(
		trx_ctrl_num,	sequence_id,	doc_ctrl_num,	apply_to_num,	apply_trx_type,		trx_type,
		date_applied,	date_due,	date_aging,	customer_code,	salesperson_code,	territory_code,	
		price_code,	amt_due	)
		VALUES 		(	
		@inv_ctrl_num,	1,		@net_doc_num,	'',		0,			2031,
		@date_entered,	@date_entered,	@date_entered,	@customer_code, @salesperson_code,	@territory_code,
		@price_code,	@amt_committed		)

		IF @@error != 0
		Begin
			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',6,@inv_ctrl_num
			RETURN -1
		End
		
		INSERT #arinppdt4750	(
		trx_ctrl_num,		doc_ctrl_num,		sequence_id,	trx_type,	apply_to_num,		
		apply_trx_type,		customer_code,		date_aging,	amt_applied,	amt_disc_taken,	
		wr_off_flag,		amt_max_wr_off,		void_flag,	line_desc,	sub_apply_num,	
		sub_apply_type,		amt_tot_chg,		amt_paid_to_date,terms_code,	posting_code,	
		date_doc,		amt_inv,		gain_home,	gain_oper,	inv_amt_applied,
		inv_amt_disc_taken,	inv_amt_max_wr_off,	inv_cur_code,	writeoff_code,	writeoff_amount,	
		cross_rate,		org_id		 	)
		VALUES 	( 
		@ar_settlement_ctrl_num,		@net_doc_num,		@sequence_id,	2111,		@net_doc_num,
		2031,			@customer_code,		@date_entered,	@amt_committed,	0,
		0,			0.0,			0,		@net_ctrl_num,	'',
		0,			@amt_committed,		@amt_committed,	@ar_terms_code,	@ar_posting_code,
		@date_entered,		@amt_committed,		0,		0,		@amt_committed,
		0.0,			0.0,			@nat_cur_code,	'',		0.0,
		1,			@root_org_id		)

		SELECT @deb_committed = @amt_committed

		SELECT 	@cre_trx_ctrl_num = MIN(trx_ctrl_num)
		FROM	#nbnetcre_work
		WHERE	net_ctrl_num	= @net_ctrl_num
		AND	trx_type	IN (2111,2032)
		AND	amt_committed	> 0.00
		
		While @cre_trx_ctrl_num is not null
		Begin
			SELECT 	@cre_committed 		= ISNULL(amt_committed,0.00),	
				@doc_ctrl_num 		= doc_ctrl_num,
				@trx_type		= trx_type
			FROM	#nbnetcre_work
			WHERE	trx_ctrl_num	= @cre_trx_ctrl_num
			AND	net_ctrl_num	= @net_ctrl_num
			
			IF @cre_committed < @deb_committed
				SELECT @amt_committed = @cre_committed
			ELSE
				SELECT @amt_committed = @deb_committed
			
			
			SELECT 	@user_trx_type_code 	= MAX(user_trx_type_code)
			FROM	apusrtyp
			WHERE	system_trx_type 	=  4091

			EXEC apnewnum_sp 4091, @company_code, @vou_ctrl_num OUTPUT

			EXEC ARGetNextControl_SP 2000, @inv_ctrl_num OUTPUT, @num OUTPUT

			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT

			INSERT #apinpchg (	
				trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
				po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
				date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
				posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
				comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
				payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
				add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
				amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
				amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
				user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
				pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
				cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
				rate_oper,	net_original_amt, org_id	)
			VALUES	(
				@vou_ctrl_num,	4091,		@net_doc_num,	@deb_trx_ctrl_num, @user_trx_type_code,	'',
				'',		@cre_trx_ctrl_num, '',		@date_entered,	@date_entered,		@date_entered,
				@date_entered,	@date_entered,	@date_entered,	@date_entered,	0,			0,
				@ap_posting_code,@vendor_code,	'',		@branch_code,	@class_code,		'',
				@ap_comment_code,@ap_fob_code,	@ap_terms_code,	'NBTAX',	'',			@ap_location_code,
				@ap_payment_code,0,		0,		0,		-1,			0,
				0,		0,		0,		0,		0,			@amt_committed,
				0.00,		0.00,		0.00,		0.00,		@amt_committed,		0.00,
				@amt_committed,	0.00,		0.00,		0.00,		'Netting Transaction',	'',
				USER_ID(),	0,		'',		'',		'',			'',
				'',		'',		@attention_name,@attention_phone,0,			@company_code,
				0,		@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,	@rate_home,
				@rate_oper,	@amt_committed,	@root_org_id	)

			INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,	trx_type	)
			VALUES 			(	@net_ctrl_num,@vou_ctrl_num,	4091		)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',8,@vou_ctrl_num

			INSERT #apinpcdt	(	
				trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
				qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
				return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
				amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
				gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
				iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
				org_id, 	amt_nonrecoverable_tax, 	amt_tax_det		)
			VALUES (
				@vou_ctrl_num,	4091,		1,		'',			'',		0,
				1,		1,		0,		0.0,			'',		'NBTAX',
				'',		'',		'',		'',			@amt_committed,	0.00,
				0.00,		0.00,		0.00,		@amt_committed,		0.00,		@date_entered,
				@vend_susp_acct,'',		'',		'Netting Transaction',	0,		@company_id,
				1,		0,		@company_code,	'',			'',		'',
				@root_org_id,	0.0,		0.0 	)

			INSERT #apinptax(
				trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
				amt_tax,	amt_final_tax		)
			VALUES (
				@vou_ctrl_num,	4091,		1,		'NBTAX',	@amt_committed,	@amt_committed,
				0.00,		0.00			)

			INSERT #apinpage(
				trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,
				date_aging,	amt_due )
			VALUES (
				@vou_ctrl_num,	4091,		1,		@date_entered,	@date_entered,
				@date_entered,	@amt_committed )

			IF @@error != 0
			Begin
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',9,@vou_ctrl_num
				RETURN -1
			End

			
			
			IF @trx_type = 2032
			Begin
				EXEC ARGetNextControl_SP 2011, @payment_ctrl_num OUTPUT,@num OUTPUT

				INSERT #arinppyt4750	(
					trx_ctrl_num,		doc_ctrl_num,		trx_desc,		batch_code,	trx_type,	
					non_ar_flag,		non_ar_doc_num,		gl_acct_code,		date_entered,	date_applied,	
					date_doc,		customer_code,		payment_code,		payment_type,	amt_payment,		
					amt_on_acct,		prompt1_inp,		prompt2_inp,		prompt3_inp,	prompt4_inp,	
					deposit_num,		bal_fwd_flag,		printed_flag,		posted_flag,	hold_flag,	
					wr_off_flag,		on_acct_flag,		user_id,		max_wr_off,	days_past_due,	
					void_type,		cash_acct_code,		origin_module_flag,	process_group_num, source_trx_ctrl_num,
					source_trx_type,	nat_cur_code,		rate_type_home,		rate_type_oper,	rate_home,
					rate_oper,		amt_discount,		reference_code,		settlement_ctrl_num,
					doc_amount,		org_id			)
				VALUES (
					@payment_ctrl_num,	@doc_ctrl_num,		'Netting Transacction',	'',		2111,
					0, 			'',			'',			@date_entered,	@date_entered,
					@date_entered,		@customer_code,		'',			4,		@amt_committed,
					0,			'',			'',			'',		'',
					'',			0,			1,			-1,		0,
					0,			0,			USER_ID(),		0.0,		0,
					0,			@cash_acct_code,	NULL,			@process_ctrl_num,NULL,
					NULL,			@nat_cur_code,		@rate_type_home,	@rate_type_oper,@rate_home,
					@rate_oper,		0.0,			'',			@ar_settlement_ctrl_num,
					@amt_committed,		@root_org_id		)
	
				INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,	trx_type	)
				VALUES 			(	@net_ctrl_num,@payment_ctrl_num,	2111		)
	
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',10,@payment_ctrl_num
				
			End
			Else
			Begin
				EXEC ARGetNextControl_SP 2011, @payment_ctrl_num OUTPUT,@num OUTPUT

				INSERT #arinppyt4750	(
					trx_ctrl_num,		doc_ctrl_num,		trx_desc,		batch_code,	trx_type,	
					non_ar_flag,		non_ar_doc_num,		gl_acct_code,		date_entered,	date_applied,	
					date_doc,		customer_code,		payment_code,		payment_type,	amt_payment,		
					amt_on_acct,		prompt1_inp,		prompt2_inp,		prompt3_inp,	prompt4_inp,	
					deposit_num,		bal_fwd_flag,		printed_flag,		posted_flag,	hold_flag,	
					wr_off_flag,		on_acct_flag,		user_id,		max_wr_off,	days_past_due,	
					void_type,		cash_acct_code,		origin_module_flag,	process_group_num, source_trx_ctrl_num,
					source_trx_type,	nat_cur_code,		rate_type_home,		rate_type_oper,	rate_home,
					rate_oper,		amt_discount,		reference_code,		settlement_ctrl_num,
					doc_amount,		org_id			)
				VALUES (
					@payment_ctrl_num,	@doc_ctrl_num,		'Netting Transacction',	'',		2111,
					0, 			'',			'',			@date_entered,	@date_entered,
					@date_entered,		@customer_code,		@ar_payment_code,	2,		@amt_committed, 
					0,			'',			'',			'',		'',
					'',			0,			1,			-1,		0,
					0,			0,			USER_ID(),		0.0,		0,
					0,			@cash_acct_code,	NULL,			@process_ctrl_num,NULL,
					NULL,			@nat_cur_code,		@rate_type_home,	@rate_type_oper,@rate_home,
					@rate_oper,		0.0,			'',			@ar_settlement_ctrl_num,
					@amt_committed,		@root_org_id		)
	
				INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,	trx_type	)
				VALUES 			(	@net_ctrl_num,@inv_ctrl_num,	2111		)
	
				exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',10,@inv_ctrl_num
			End
			
			UPDATE #nbnetcre_work
			SET amt_committed = amt_committed - @amt_committed
			WHERE	net_ctrl_num	= @net_ctrl_num
			AND	trx_type	IN (2111,2032)
			AND	amt_committed	> 0.00
			AND	trx_ctrl_num	= @cre_trx_ctrl_num

			IF @cre_committed >= @deb_committed
			Begin
				Select @cre_trx_ctrl_num = Null
			End
			ELSE
			BEGIN
				SELECT 	@cre_trx_ctrl_num = MIN(trx_ctrl_num)	
				FROM	#nbnetcre_work
				WHERE	net_ctrl_num 	= @net_ctrl_num
				AND	amt_committed	> 0.00
				AND	trx_type 	IN (2111,2032)	 
			END
		END  

		SELECT @sequence_id = @sequence_id + 1
		
		UPDATE #nbnetdeb_work
		SET amt_committed = amt_committed - @deb_committed
		WHERE	net_ctrl_num	= @net_ctrl_num
		AND	trx_type	IN (4111,4092,4091)
		AND	amt_committed	> 0.00
		AND	trx_ctrl_num	= @deb_trx_ctrl_num

		SELECT 	@deb_trx_ctrl_num = MIN(trx_ctrl_num)
		FROM	#nbnetdeb_work
		WHERE	net_ctrl_num	= @net_ctrl_num
		AND	trx_type	IN (4111,4092,4091)
		AND	amt_committed	> 0.00


	END  
END
ELSE
BEGIN

	SELECT 	@deb_trx_ctrl_num = MIN(trx_ctrl_num)
	FROM	#nbnetdeb_work
	WHERE	net_ctrl_num	= @net_ctrl_num
	AND	trx_type	IN (4111,4092,4091)
	AND	amt_committed	> 0.00

	SELECT @sequence_id = 1

	WHILE	@deb_amt_committed > 0
	BEGIN
		
		SELECT 	@amt_committed 		= ISNULL(amt_committed,0.00),	
			@doc_ctrl_num 	= doc_ctrl_num,
			@trx_type		= trx_type
		FROM	#nbnetdeb_work
		WHERE	trx_ctrl_num	= @deb_trx_ctrl_num
		AND	net_ctrl_num	= @net_ctrl_num

		IF @trx_type = 4111
		BEGIN
			SELECT 	@rate_type_home 	= ISNULL(rate_type_home,''),
				@rate_type_oper 	= ISNULL(rate_type_oper,''),
				@rate_home		= ISNULL(rate_home,0.00),
				@rate_oper		= ISNULL(rate_oper,0.00)
			FROM	appyhdr
			WHERE	trx_ctrl_num = @deb_trx_ctrl_num
			select @cash_account_work =@cash_acct_code, @payment_code_work =@ap_payment_code,@payment_type= 2
		END

		IF @trx_type = 4092
		BEGIN
			SELECT 	
				@rate_type_home 	= ISNULL(rate_type_home,''),
				@rate_type_oper 	= ISNULL(rate_type_oper,''),
				@rate_home		= ISNULL(rate_home,0.00),
				@rate_oper		= ISNULL(rate_oper,0.00)
			FROM	apdmhdr
			WHERE	trx_ctrl_num = @deb_trx_ctrl_num

			SELECT 	@rate_type_home 	= ISNULL(rate_type_home,''),
				@rate_type_oper 	= ISNULL(rate_type_oper,''),
				@rate_home		= ISNULL(rate_home,0.00),
				@rate_oper		= ISNULL(rate_oper,0.00)
			FROM	appyhdr
			WHERE	trx_ctrl_num = @deb_trx_ctrl_num

			select @cash_account_work ='', @payment_code_work ='DBMEMO',@payment_type= 3 
		END
	
		IF @trx_type = 4091
		BEGIN
			SELECT 	@rate_type_home 	= ISNULL(rate_type_home,''),
				@rate_type_oper 	= ISNULL(rate_type_oper,''),
				@rate_home		= ISNULL(rate_home,0.00),
				@rate_oper		= ISNULL(rate_oper,0.00)
			FROM	apvohdr
			WHERE	trx_ctrl_num = @deb_trx_ctrl_num
		END

		EXEC ARGetNextControl_SP 2000, @inv_ctrl_num OUTPUT, @num OUTPUT

		EXEC apnewnum_sp 4111, @company_code, @payment_ctrl_num OUTPUT

		EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT
				
		INSERT #arinpchg (
		trx_ctrl_num,	doc_ctrl_num,	doc_desc,	apply_to_num,	apply_trx_type,	order_ctrl_num,
		batch_code,	trx_type,	date_entered,	date_applied,	date_doc,	date_shipped,	
		date_required,	date_due,	date_aging,	customer_code,	ship_to_code,	salesperson_code,
		territory_code,	comment_code,	fob_code,	freight_code,	terms_code,	fin_chg_code,
		price_code,	dest_zone_code,	posting_code,	recurring_flag,	recurring_code,	tax_code,
		cust_po_num,	total_weight,	amt_gross,	amt_freight,	amt_tax,	amt_tax_included,
		amt_discount,	amt_net,	amt_paid,	amt_due,	amt_cost,	amt_profit,
		next_serial_id,	printed_flag,	posted_flag,	hold_flag,	hold_desc,	user_id,
		customer_addr1,	customer_addr2,	customer_addr3,	customer_addr4,	customer_addr5,	customer_addr6,
		ship_to_addr1,	ship_to_addr2,	ship_to_addr3,	ship_to_addr4,	ship_to_addr5,	ship_to_addr6,
		attention_name,	attention_phone,amt_rem_rev,	amt_rem_tax,	date_recurring,	location_code,
		process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, amt_write_off_given, nat_cur_code,	
		rate_type_home,	rate_type_oper,	rate_home,	rate_oper,	edit_list_flag,	ddid,
		writeoff_code,	org_id		)
		VALUES (
		@inv_ctrl_num,	@net_doc_num,	'Netting Transaction','',	0,		'',	
		'',		2031,		@date_entered,	@date_entered,	@date_entered,	@date_entered,
		@date_entered,	@date_entered,	@date_entered,	@customer_code,	@ship_to_code,	@salesperson_code,
		@territory_code,@ar_comment_code,@ar_fob_code,	@freight_code,	@ar_terms_code,	@fin_chg_code,
		@price_code,	@dest_zone_code,@ar_posting_code,0,		'',		'NBTAX',
		'',		0.00,		@amt_committed,	0.00,		0.00,		0.00,
		0.00,		@amt_committed,	0.00,		@amt_committed,	0.00,		0.00,
		0,		1,		-1,		0,		'',		USER_ID(),
		@cust_addr1,	@cust_addr2,	@cust_addr3,	@cust_addr4,	@cust_addr5,	@cust_addr6,
		'',		'',		'',		'',		'',		'',
		'',		'',		0.00,		0.00,		0,		@ar_location_code,
		@process_ctrl_num,@deb_trx_ctrl_num, NULL,	0.00,		0.00,		@nat_cur_code,
		@rate_type_home,@rate_type_oper,@rate_home,@rate_oper,		0,		NULL,
		'',		@root_org_id	)	

		INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,	trx_type	)
		VALUES 			(	@net_ctrl_num,@inv_ctrl_num,	2031		)

		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',5,@inv_ctrl_num

		INSERT	#arinpcdt (
		trx_ctrl_num,		doc_ctrl_num,	sequence_id,	trx_type,	location_code,	item_code,
		bulk_flag,		date_entered,	line_desc,	qty_ordered,	qty_shipped,	unit_code,
		unit_price,		unit_cost,	weight,		serial_id,	tax_code,	gl_rev_acct,
		disc_prc_flag,		discount_amt,	commission_flag,rma_num,	return_code,	qty_returned,
		qty_prev_returned,	new_gl_rev_acct,iv_post_flag,	oe_orig_flag,	discount_prc,	extended_price,
		calc_tax,		reference_code, new_reference_code, org_id	)
		VALUES (
		@inv_ctrl_num,		@net_doc_num,	1,		2031,		@ar_location_code,'',
		0,			@date_entered,	'',		1,		1,		'',	
		@amt_committed,		0.0,		0.0,		0,		'NBTAX',	@cust_susp_acct,
		0,			0.0,		0,		'',		'',		0,
		0.0,			'',		1,		0,		0.0,		@amt_committed,
		0.0,			'',		NULL,		@root_org_id	)

		INSERT 	#arinptax (
		trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
		amt_tax,	amt_final_tax			)
		VALUES (
		@inv_ctrl_num,	2031,		1,		'NBTAX',	@amt_committed,	@amt_committed,
		0.00,		0.00				)

		INSERT #arinpage(
		trx_ctrl_num,	sequence_id,	doc_ctrl_num,	apply_to_num,	apply_trx_type,		trx_type,
		date_applied,	date_due,	date_aging,	customer_code,	salesperson_code,	territory_code,	
		price_code,	amt_due	)
		VALUES 		(	
		@inv_ctrl_num,	1,		@net_doc_num,	'',		0,			2031,
		@date_entered,	@date_entered,	@date_entered,	@customer_code, @salesperson_code,	@territory_code,
		@price_code,	@amt_committed		)

		IF @@error != 0
		Begin
			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',6,@inv_ctrl_num
			RETURN -1
		End
		
		INSERT #arinppdt4750	(
		trx_ctrl_num,		doc_ctrl_num,		sequence_id,	trx_type,	apply_to_num,		
		apply_trx_type,		customer_code,		date_aging,	amt_applied,	amt_disc_taken,	
		wr_off_flag,		amt_max_wr_off,		void_flag,	line_desc,	sub_apply_num,	
		sub_apply_type,		amt_tot_chg,		amt_paid_to_date,terms_code,	posting_code,	
		date_doc,		amt_inv,		gain_home,	gain_oper,	inv_amt_applied,
		inv_amt_disc_taken,	inv_amt_max_wr_off,	inv_cur_code,	writeoff_code,	writeoff_amount,	
		cross_rate,		org_id		 	)
		VALUES 	( 
		@ar_settlement_ctrl_num,		@net_doc_num,		@sequence_id,	2111,		@net_doc_num,
		2031,			@customer_code,		@date_entered,	@amt_committed,	0,
		0,			0.0,			0,		@net_ctrl_num,	'',
		0,			@amt_committed,		@amt_committed,	@ar_terms_code,	@ar_posting_code,
		@date_entered,		@amt_committed,		0,		0,		@amt_committed,
		0.0,			0.0,			@nat_cur_code,	'',		0.0,
		1,			@root_org_id		)

		IF @trx_type = 4091
		BEGIN
			INSERT #apinppdt3450		(
					trx_ctrl_num,	trx_type,	sequence_id,	apply_to_num,	apply_trx_type,	
					amt_applied,    amt_disc_taken,	line_desc,	void_flag,	payment_hold_flag,	
					vendor_code,	vo_amt_applied,	vo_amt_disc_taken,gain_home,	gain_oper,	
					nat_cur_code,	cross_rate,	org_id		)
			VALUES 	( 
					@ap_settlement_ctrl_num,	4111,		@sequence_id,	@deb_trx_ctrl_num,	4091,
					@amt_committed,	0.0,		'Netting Transaction',0,	0,
					@vendor_code,	@amt_committed,	0.0,		0.0,		0.0,
					@nat_cur_code,	1,		@root_org_id	)
		END
		ELSE
		BEGIN
			EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT

			INSERT #apinppyt3450	(
				trx_ctrl_num, 	trx_type,	doc_ctrl_num,	trx_desc,	batch_code,	cash_acct_code,
				date_entered,	date_applied,	date_doc,	vendor_code,	pay_to_code,	approval_code,
				payment_code,	payment_type,	amt_payment,	amt_on_acct,	posted_flag,	printed_flag,
				hold_flag,	approval_flag,	gen_id,		user_id,	void_type, 	amt_disc_taken,
				print_batch_num,company_code,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,
				rate_home,	rate_oper,	payee_name,	settlement_ctrl_num,
				doc_amount,	org_id		)
			VALUES (
				@payment_ctrl_num,4111,		@doc_ctrl_num,'Netting Transacction ' + @net_ctrl_num,
												'',		@cash_account_work,
				@date_entered,	@date_entered,	@date_entered,	@vendor_code,	'',		@approval_code, 
				@payment_code_work,@payment_type, 		@amt_committed,	0.0,		-1,		2,
				0,		0,		0,		USER_ID(),	0,		0.0,
				0,		@company_code,	@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,
				@rate_home,	@rate_oper,	NULL,		@ap_settlement_ctrl_num,
				@amt_committed,	@root_org_id	)		
		
			INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,		trx_type	)
			VALUES 			(	@net_ctrl_num,@payment_ctrl_num,	4111		)

			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',7,@payment_ctrl_num
		END

		
		
		SELECT @sequence_id = @sequence_id + 1
		
		UPDATE #nbnetdeb_work
		SET amt_committed = amt_committed - @amt_committed
		WHERE	net_ctrl_num	= @net_ctrl_num
		AND	trx_type	IN (4111,4092,4091)
		AND	amt_committed	> 0.00
		AND	trx_ctrl_num	= @deb_trx_ctrl_num

		SELECT @deb_amt_committed = @deb_amt_committed - @amt_committed

		SELECT 	@deb_trx_ctrl_num = MIN(trx_ctrl_num)
		FROM	#nbnetdeb_work
		WHERE	net_ctrl_num	= @net_ctrl_num
		AND	trx_type	IN (4111,4092,4091)
		AND	amt_committed	> 0.00
		

	END	
	
	SELECT 	@cre_trx_ctrl_num = MIN(trx_ctrl_num)
	FROM	#nbnetcre_work
	WHERE	net_ctrl_num	= @net_ctrl_num
	AND	trx_type	IN (2111,2032)
	AND	amt_committed	> 0.00

	SELECT @sequence_id = 1

	WHILE 	@cre_amt_committed > 0
	BEGIN

		SELECT	@amt_committed 	= amt_committed, 
			@doc_ctrl_num = doc_ctrl_num,
			@trx_type 	= trx_type
		FROM	#nbnetcre_work
		WHERE	net_ctrl_num	= @net_ctrl_num
		AND	trx_ctrl_num	= @cre_trx_ctrl_num
		AND	amt_committed	> 0.00

		SELECT 	@rate_type_home 	= ISNULL(rate_type_home,''),
			@rate_type_oper 	= ISNULL(rate_type_oper,''),
			@rate_home		= ISNULL(rate_home,0.00),
			@rate_oper		= ISNULL(rate_oper,0.00)
		FROM	artrx
		WHERE	trx_ctrl_num	= @cre_trx_ctrl_num
		AND	trx_type	IN (2111,2032)

		SELECT 	@user_trx_type_code 	= MAX(user_trx_type_code)
		FROM	apusrtyp
		WHERE	system_trx_type 	=  4091

		EXEC apnewnum_sp 4091, @company_code, @vou_ctrl_num OUTPUT

		EXEC ARGetNextControl_SP 2000, @inv_ctrl_num OUTPUT, @num OUTPUT

		EXEC ARGetNextControl_SP 2130, @net_doc_num OUTPUT, @num OUTPUT

		INSERT #apinpchg (	
		trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
		po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
		date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
		posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
		comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
		payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
		add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
		amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
		amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
		user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
		pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
		cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
		rate_oper,	net_original_amt, org_id	)
		VALUES	(
		@vou_ctrl_num,	4091,		@net_doc_num,	'',		@user_trx_type_code,	'',
		'',		@cre_trx_ctrl_num, '',		@date_entered,	@date_entered,		@date_entered,
		@date_entered,	@date_entered,	@date_entered,	@date_entered,	0,			0,
		@ap_posting_code,@vendor_code,	'',		@branch_code,	@class_code,		'',
		@ap_comment_code,@ap_fob_code,	@ap_terms_code,	'NBTAX',	'',			@ap_location_code,
		@ap_payment_code,0,		0,		0,		-1,			0,
		0,		0,		0,		0,		0,			@amt_committed,
		0.00,		0.00,		0.00,		0.00,		@amt_committed,		0.00,
		@amt_committed,	0.00,		0.00,		0.00,		'Netting Transaction',	'',
		USER_ID(),	0,		'',		'',		'',			'',
		'',		'',		@attention_name,@attention_phone,0,			@company_code,
		0,		@process_ctrl_num,@nat_cur_code,@rate_type_home,@rate_type_oper,	@rate_home,
		@rate_oper,	@amt_committed,	@root_org_id	)

		INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,	trx_type	)
		VALUES 			(	@net_ctrl_num,@vou_ctrl_num,	4091		)

		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',8,@vou_ctrl_num

		INSERT #apinpcdt	(	
		trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
		qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
		return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
		amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
		gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
		iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
		org_id, 	amt_nonrecoverable_tax, 	amt_tax_det		)
		VALUES (
		@vou_ctrl_num,	4091,		1,		'',			'',		0,
		1,		1,		0,		0.0,			'',		'NBTAX',
		'',		'',		'',		'',			@amt_committed,	0.00,
		0.00,		0.00,		0.00,		@amt_committed,		0.00,		@date_entered,
		@vend_susp_acct,'',		'',		'Netting Transaction',	0,		@company_id,
		1,		0,		@company_code,	'',			'',		'',
		@root_org_id,	0.0,		0.0 	)

		INSERT #apinptax(
		trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
		amt_tax,	amt_final_tax		)
		VALUES (
		@vou_ctrl_num,	4091,		1,		'NBTAX',	@amt_committed,	@amt_committed,
		0.00,		0.00			)

		INSERT #apinpage(
		trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,
		date_aging,	amt_due )
		VALUES (
		@vou_ctrl_num,	4091,		1,		@date_entered,	@date_entered,
		@date_entered,	@amt_committed )

		IF @@error != 0
		Begin
			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',9,@vou_ctrl_num
			RETURN -1
		End

		INSERT #apinppdt3450		(
		trx_ctrl_num,	trx_type,	sequence_id,	apply_to_num,	apply_trx_type,	
		amt_applied,    amt_disc_taken,	line_desc,	void_flag,	payment_hold_flag,	
		vendor_code,	vo_amt_applied,	vo_amt_disc_taken,gain_home,	gain_oper,	
		nat_cur_code,	cross_rate,	org_id		)
		VALUES 	( 
		@ap_settlement_ctrl_num,	4111,		@sequence_id,	@vou_ctrl_num,	4091,
		@amt_committed,	0.0,		'Netting Transaction',0,	0,
		@vendor_code,	@amt_committed,	0.0,		0.0,		0.0,
		@nat_cur_code,	1,		@root_org_id	)



		IF @trx_type = 2032
		Begin
			EXEC ARGetNextControl_SP 2011, @payment_ctrl_num OUTPUT,@num OUTPUT

			INSERT #arinppyt4750	(
				trx_ctrl_num,		doc_ctrl_num,		trx_desc,		batch_code,	trx_type,	
				non_ar_flag,		non_ar_doc_num,		gl_acct_code,		date_entered,	date_applied,	
				date_doc,		customer_code,		payment_code,		payment_type,	amt_payment,		
				amt_on_acct,		prompt1_inp,		prompt2_inp,		prompt3_inp,	prompt4_inp,	
				deposit_num,		bal_fwd_flag,		printed_flag,		posted_flag,	hold_flag,	
				wr_off_flag,		on_acct_flag,		user_id,		max_wr_off,	days_past_due,	
				void_type,		cash_acct_code,		origin_module_flag,	process_group_num, source_trx_ctrl_num,
				source_trx_type,	nat_cur_code,		rate_type_home,		rate_type_oper,	rate_home,
				rate_oper,		amt_discount,		reference_code,		settlement_ctrl_num,
				doc_amount,		org_id			)
			VALUES (
				@payment_ctrl_num,	@doc_ctrl_num,		'Netting Transacction',	'',		2111,
				0, 			'',			'',			@date_entered,	@date_entered,
				@date_entered,		@customer_code,		'',			4,		@amt_committed,
				0,			'',			'',			'',		'',
				'',			0,			1,			-1,		0,
				0,			0,			USER_ID(),		0.0,		0,
				0,			@cash_acct_code,	NULL,			@process_ctrl_num,NULL,
				NULL,			@nat_cur_code,		@rate_type_home,	@rate_type_oper,@rate_home,
				@rate_oper,		0.0,			'',			@ar_settlement_ctrl_num,
				@amt_committed,		@root_org_id		)
	
			INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,	trx_type	)
			VALUES 			(	@net_ctrl_num,@payment_ctrl_num,	2111		)
	
			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',10,@payment_ctrl_num
			
		End
		Else
		Begin
			EXEC ARGetNextControl_SP 2011, @payment_ctrl_num OUTPUT,@num OUTPUT

			INSERT #arinppyt4750	(
				trx_ctrl_num,		doc_ctrl_num,		trx_desc,		batch_code,	trx_type,	
				non_ar_flag,		non_ar_doc_num,		gl_acct_code,		date_entered,	date_applied,	
				date_doc,		customer_code,		payment_code,		payment_type,	amt_payment,		
				amt_on_acct,		prompt1_inp,		prompt2_inp,		prompt3_inp,	prompt4_inp,	
				deposit_num,		bal_fwd_flag,		printed_flag,		posted_flag,	hold_flag,	
				wr_off_flag,		on_acct_flag,		user_id,		max_wr_off,	days_past_due,	
				void_type,		cash_acct_code,		origin_module_flag,	process_group_num, source_trx_ctrl_num,
				source_trx_type,	nat_cur_code,		rate_type_home,		rate_type_oper,	rate_home,
				rate_oper,		amt_discount,		reference_code,		settlement_ctrl_num,
				doc_amount,		org_id			)
			VALUES (
				@payment_ctrl_num,	@doc_ctrl_num,		'Netting Transacction',	'',		2111,
				0, 			'',			'',			@date_entered,	@date_entered,
				@date_entered,		@customer_code,		@ar_payment_code,	2,		@amt_committed,
				0,			'',			'',			'',		'',
				'',			0,			1,			-1,		0,
				0,			0,			USER_ID(),		0.0,		0,
				0,			@cash_acct_code,	NULL,			@process_ctrl_num,NULL,
				NULL,			@nat_cur_code,		@rate_type_home,	@rate_type_oper,@rate_home,
				@rate_oper,		0.0,			'',			@ar_settlement_ctrl_num,
				@amt_committed,		@root_org_id		)

			INSERT	#nbtrxrel 	(	net_ctrl_num, trx_ctrl_num,	trx_type	)
			VALUES 			(	@net_ctrl_num,@payment_ctrl_num,	2111		)
	
			exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',10,@payment_ctrl_num
		End


		SELECT @sequence_id = 	@sequence_id + 1

		
		UPDATE #nbnetcre_work
		SET amt_committed = amt_committed - @amt_committed
		WHERE	net_ctrl_num	= @net_ctrl_num
		AND	trx_type	IN (2111,2032)
		AND	amt_committed	> 0.00
		AND	trx_ctrl_num	= @cre_trx_ctrl_num

		SELECT @cre_amt_committed = @cre_amt_committed - @amt_committed
	
		SELECT 	@cre_trx_ctrl_num = MIN(trx_ctrl_num)	
		FROM	#nbnetcre_work
		WHERE	net_ctrl_num 	= @net_ctrl_num
		AND	amt_committed	> 0.00
		AND	trx_type 	IN (2111,2032)
	END 

END	

SELECT 	@amt_committed 	= SUM(amt_payment), @rows= COUNT(trx_ctrl_num)
FROM	#arinppyt4750

IF @amt_committed IS NULL
	SELECT  @amt_committed = 0
	
DECLARE arsett_cur CURSOR FOR SELECT settlement_ctrl_num FROM #arinpstlhdr 
OPEN arsett_cur

FETCH NEXT FROM arsett_cur INTO @settlement_ctrl_num

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT 	@amt_committed 	= SUM(amt_payment), @rows= COUNT(trx_ctrl_num)
	FROM	#arinppyt4750
	where settlement_ctrl_num = @settlement_ctrl_num

	IF @amt_committed IS NULL
		SELECT  @amt_committed = 0

	set rowcount  1

	SELECT	@ar_rate_type_home	= rate_type_home,                
		@ar_rate_type_oper = rate_type_oper,
		@ar_rate_home	= rate_home,
		@ar_rate_oper	= rate_oper
	FROM	#arinppyt4750 
	WHERE	settlement_ctrl_num	= @settlement_ctrl_num	
	
	set rowcount  0

	UPDATE	#arinpstlhdr
	SET	doc_count_entered 	= @rows,	
		doc_sum_entered		= @amt_committed,
		inv_total_home		= @amt_committed,
		inv_total_oper		= @amt_committed,
		cr_total_home  		= @amt_committed,
		cr_total_oper                 = @amt_committed,
		inv_amt_nat                   = @amt_committed,
		amt_doc_nat		= @amt_committed,
		rate_type_home	= @ar_rate_type_home ,
		rate_home    		= @ar_rate_home,
                rate_type_oper		= @ar_rate_type_oper,
		rate_oper		=@ar_rate_oper,
		settle_flag 		= 1
	WHERE	process_group_num 	= @process_ctrl_num
	AND	settlement_ctrl_num	= @settlement_ctrl_num
		


	EXEC @result = arstlprt_sp 	@settlement_ctrl_num

	IF @result != 0
	Begin
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',11,@settlement_ctrl_num
		RETURN	@result
	End

	FETCH NEXT FROM arsett_cur INTO @settlement_ctrl_num
END
  
CLOSE arsett_cur
DEALLOCATE arsett_cur



SELECT	@amt_committed 	= 0, @rows = 0

SELECT 	@amt_committed 	= SUM(amt_payment), @rows= COUNT(trx_ctrl_num)
FROM	#apinppyt3450

IF @amt_committed IS NULL
BEGIN
	DELETE from #apinpstl

	SELECT  @amt_committed = 0
END

SELECT @settlement_ctrl_num = ''

SELECT 	@counter = count(settlement_ctrl_num)
FROM	#apinpstl

DECLARE apsett_cur CURSOR FOR SELECT settlement_ctrl_num FROM #apinpstl
OPEN apsett_cur

FETCH NEXT FROM apsett_cur INTO @settlement_ctrl_num

WHILE @@FETCH_STATUS = 0
BEGIN

	EXEC @result = apstlprt_sp  @settlement_ctrl_num
	
	IF @result !=  0
	Begin
		exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',12,@settlement_ctrl_num
		RETURN	@result
	End	
		
	set rowcount  1

	SELECT	@ap_rate_type_home	= rate_type_home,                
			@ap_rate_type_oper = rate_type_oper,
			@ap_rate_home	= rate_home,
			@ap_rate_oper	= rate_oper
	FROM	#apinppyt3450 
	WHERE	settlement_ctrl_num	= @settlement_ctrl_num	

	
	set rowcount  0

	UPDATE	#apinpstl
	SET	payments_total_home	= @amt_committed,                 
		payments_total_oper	= @amt_committed,
		doc_count_entered	= @counter,
		vo_amt_nat 		= @amt_committed,
                       	amt_doc_nat		= @amt_committed,
		vo_total_home		= @amt_committed, 
		vo_total_oper		= @amt_committed,
		rate_type_home	= @ap_rate_type_home,
		rate_home		= @ap_rate_home,
		rate_type_oper		= @ap_rate_type_oper,
		rate_oper		= @ap_rate_oper       


	WHERE	process_group_num 	= @process_ctrl_num
	AND	settlement_ctrl_num	= @ap_settlement_ctrl_num
	
	FETCH NEXT FROM apsett_cur INTO @settlement_ctrl_num
END
  
CLOSE apsett_cur
DEALLOCATE apsett_cur


INSERT arinppyt(
	trx_ctrl_num, 	doc_ctrl_num, 	trx_desc,	batch_code, 	trx_type, 	non_ar_flag, 	non_ar_doc_num, 
	gl_acct_code, 	date_entered, 	date_applied, 	date_doc, 	customer_code, 	payment_code, 	payment_type,  
	amt_payment, 	amt_on_acct, 	prompt1_inp, 	prompt2_inp, 	prompt3_inp, 	prompt4_inp, 	deposit_num, 
	bal_fwd_flag,  	printed_flag, 	posted_flag, 	hold_flag, 	wr_off_flag,  	on_acct_flag,  	user_id,  
	max_wr_off,    	days_past_due,	void_type, 	cash_acct_code, origin_module_flag,process_group_num, source_trx_ctrl_num, 
	source_trx_type,nat_cur_code,	rate_type_home, rate_type_oper, rate_home, 	rate_oper, 	amt_discount, 
	reference_code,   settlement_ctrl_num, doc_amount, org_id  )
SELECT 	trx_ctrl_num, 	doc_ctrl_num, 	trx_desc, 	batch_code, 	trx_type, 	non_ar_flag, 	non_ar_doc_num, 
	gl_acct_code, 	date_entered, 	date_applied, 	date_doc, 	customer_code, 	payment_code, 	payment_type,  
	amt_payment, 	amt_on_acct, 	prompt1_inp, 	prompt2_inp, 	prompt3_inp, 	prompt4_inp, 	deposit_num, 
	bal_fwd_flag,  	printed_flag, 	posted_flag, 	hold_flag, 	wr_off_flag,  	on_acct_flag,  	user_id,  
	max_wr_off,    	days_past_due,  void_type, 	cash_acct_code, origin_module_flag,process_group_num, source_trx_ctrl_num, 
	source_trx_type,nat_cur_code,   rate_type_home, rate_type_oper, rate_home, 	rate_oper, 	amt_discount, 
	reference_code,	settlement_ctrl_num  , amt_payment, org_id
FROM	#arinppyt4750

INSERT arinppdt	(	
	trx_ctrl_num,	doc_ctrl_num,	sequence_id,	trx_type,	apply_to_num,	apply_trx_type,	customer_code,	
	date_aging,	amt_applied,	amt_disc_taken,	wr_off_flag,	amt_max_wr_off,	void_flag,	line_desc,	
	sub_apply_num,	sub_apply_type,	amt_tot_chg,	amt_paid_to_date,terms_code,	posting_code,	date_doc,	
	amt_inv,	gain_home,	gain_oper,	inv_amt_applied, inv_amt_disc_taken,inv_amt_max_wr_off,	inv_cur_code,	
	writeoff_code,	writeoff_amount, cross_rate,	org_id		)
SELECT 	trx_ctrl_num,	doc_ctrl_num,	sequence_id,	trx_type,	apply_to_num,	apply_trx_type,	customer_code,	
	date_aging,	amt_applied,	amt_disc_taken,	wr_off_flag,	amt_max_wr_off,	void_flag,	line_desc,	
	sub_apply_num,	sub_apply_type,	amt_tot_chg,	amt_paid_to_date,terms_code,	posting_code,	date_doc,	
	amt_inv,	gain_home,	gain_oper,	inv_amt_applied,inv_amt_disc_taken,inv_amt_max_wr_off,	inv_cur_code,	
	writeoff_code,	writeoff_amount, cross_rate,	org_id			
FROM	#arinppdt4750

INSERT arinpstlhdr( 
	settlement_ctrl_num, 	description,  	hold_flag,		posted_flag,		date_entered,	
	date_applied, 		user_id,	process_group_num, 	doc_count_expected,	doc_count_entered,   
	doc_sum_expected,   	doc_sum_entered,cr_total_home,   	cr_total_oper,   	oa_cr_total_home,
	oa_cr_total_oper,   	cm_total_home,	cm_total_oper,		inv_total_home,   	inv_total_oper,   
	disc_total_home,	disc_total_oper,wroff_total_home,   	wroff_total_oper,	onacct_total_home,   
	onacct_total_oper,   	gain_total_home,gain_total_oper,   	loss_total_home,   	loss_total_oper,
	amt_on_acct,		inv_amt_nat,	amt_doc_nat,		amt_dist_nat,		customer_code,
	nat_cur_code,		rate_type_home,	rate_home,		rate_type_oper,		rate_oper, 
	settle_flag,		org_id		)
SELECT 	settlement_ctrl_num, 	description,  	hold_flag,		posted_flag,		date_entered,	
	date_applied, 		user_id,	process_group_num, 	doc_count_expected,	doc_count_entered,   
	doc_sum_expected,   	doc_sum_entered,cr_total_home,   	cr_total_oper,   	oa_cr_total_home,
	oa_cr_total_oper,   	cm_total_home,	cm_total_oper,		inv_total_home,   	inv_total_oper,   
	disc_total_home,	disc_total_oper,wroff_total_home,   	wroff_total_oper,	onacct_total_home,   
	onacct_total_oper,   	gain_total_home,gain_total_oper,   	loss_total_home,   	loss_total_oper,
	amt_on_acct,		inv_amt_nat,	amt_doc_nat,		amt_dist_nat,		customer_code,
	nat_cur_code,		rate_type_home,	rate_home,		rate_type_oper,		rate_oper, 
	settle_flag,		org_id
FROM	#arinpstlhdr


INSERT arinpchg( 	
	trx_ctrl_num,	doc_ctrl_num,	doc_desc,	apply_to_num,	apply_trx_type,	order_ctrl_num,
	batch_code,	trx_type,	date_entered,	date_applied,	date_doc,	date_shipped,	
	date_required,	date_due,	date_aging,	customer_code,	ship_to_code,	salesperson_code,
	territory_code,	comment_code,	fob_code,	freight_code,	terms_code,	fin_chg_code,
	price_code,	dest_zone_code,	posting_code,	recurring_flag,	recurring_code,	tax_code,
	cust_po_num,	total_weight,	amt_gross,	amt_freight,	amt_tax,	amt_tax_included,
	amt_discount,	amt_net,	amt_paid,	amt_due,	amt_cost,	amt_profit,
	next_serial_id,	printed_flag,	posted_flag,	hold_flag,	hold_desc,	user_id,
	customer_addr1,	customer_addr2,	customer_addr3,	customer_addr4,	customer_addr5,	customer_addr6,
	ship_to_addr1,	ship_to_addr2,	ship_to_addr3,	ship_to_addr4,	ship_to_addr5,	ship_to_addr6,
	attention_name,	attention_phone,amt_rem_rev,	amt_rem_tax,	date_recurring,	location_code,
	process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, amt_write_off_given, nat_cur_code,	
	rate_type_home,	rate_type_oper,	rate_home,	rate_oper,	edit_list_flag,	ddid,
	writeoff_code,	org_id		)
SELECT 	trx_ctrl_num,	doc_ctrl_num,	doc_desc,	apply_to_num,	apply_trx_type,	order_ctrl_num,
	batch_code,	trx_type,	date_entered,	date_applied,	date_doc,	date_shipped,	
	date_required,	date_due,	date_aging,	customer_code,	ship_to_code,	salesperson_code,
	territory_code,	comment_code,	fob_code,	freight_code,	terms_code,	fin_chg_code,
	price_code,	dest_zone_code,	posting_code,	recurring_flag,	recurring_code,	tax_code,
	cust_po_num,	total_weight,	amt_gross,	amt_freight,	amt_tax,	amt_tax_included,
	amt_discount,	amt_net,	amt_paid,	amt_due,	amt_cost,	amt_profit,
	next_serial_id,	printed_flag,	posted_flag,	hold_flag,	hold_desc,	user_id,
	customer_addr1,	customer_addr2,	customer_addr3,	customer_addr4,	customer_addr5,	customer_addr6,
	ship_to_addr1,	ship_to_addr2,	ship_to_addr3,	ship_to_addr4,	ship_to_addr5,	ship_to_addr6,
	attention_name,	attention_phone,amt_rem_rev,	amt_rem_tax,	date_recurring,	location_code,
	process_group_num, source_trx_ctrl_num, source_trx_type, amt_discount_taken, amt_write_off_given, nat_cur_code,	
	rate_type_home,	rate_type_oper,	rate_home,	rate_oper,	edit_list_flag,	ddid,
	writeoff_code,	org_id
FROM 	#arinpchg


INSERT arinpcdt	( 		
	trx_ctrl_num,	doc_ctrl_num,	sequence_id,	trx_type,	location_code,	item_code,
	bulk_flag,	date_entered,	line_desc,	qty_ordered,	qty_shipped,	unit_code,
	unit_price,	unit_cost,	weight,		serial_id,	tax_code,	gl_rev_acct,
	disc_prc_flag,	discount_amt,	commission_flag,rma_num,	return_code,	qty_returned,
	qty_prev_returned,new_gl_rev_acct,iv_post_flag,	oe_orig_flag,	discount_prc,	extended_price,
	calc_tax,	reference_code, new_reference_code, org_id	)
SELECT	trx_ctrl_num,	doc_ctrl_num,	sequence_id,	trx_type,	location_code,	item_code,
	bulk_flag,	date_entered,	line_desc,	qty_ordered,	qty_shipped,	unit_code,
	unit_price,	unit_cost,	weight,		serial_id,	tax_code,	gl_rev_acct,
	disc_prc_flag,	discount_amt,	commission_flag,rma_num,	return_code,	qty_returned,
	qty_prev_returned,new_gl_rev_acct,iv_post_flag,	oe_orig_flag,	discount_prc,	extended_price,
	calc_tax,	reference_code, new_reference_code, org_id 	 
FROM 	#arinpcdt

INSERT arinptax(		
	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
	amt_tax,	amt_final_tax			)
SELECT 	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
	amt_tax,	amt_final_tax			
FROM	#arinptax

INSERT arinpage(
	trx_ctrl_num,	sequence_id,	doc_ctrl_num,	apply_to_num,	apply_trx_type,		trx_type,
	date_applied,	date_due,	date_aging,	customer_code,	salesperson_code,	territory_code,	
	price_code,	amt_due	)
SELECT	trx_ctrl_num,	sequence_id,	doc_ctrl_num,	apply_to_num,	apply_trx_type,		trx_type,
	date_applied,	date_due,	date_aging,	customer_code,	salesperson_code,	territory_code,	
	price_code,	amt_due
FROM	#arinpage



INSERT	apinpstl (
	settlement_ctrl_num,	vendor_code,		pay_to_code,		hold_flag,	
	date_entered,		date_applied,		user_id,		batch_code,
	process_group_num,	state_flag,		disc_total_home,	disc_total_oper,
	debit_memo_total_home,	debit_memo_total_oper,	on_acct_pay_total_home,	on_acct_pay_total_oper,
	payments_total_home,	payments_total_oper,	put_on_acct_total_home,	put_on_acct_total_oper,
	gain_total_home,	gain_total_oper,	loss_total_home,	loss_total_oper,
	description,		nat_cur_code,		doc_count_expected,	doc_count_entered,
	doc_sum_expected,	doc_sum_entered,	vo_total_home,		vo_total_oper,
	rate_type_home,		rate_home,		rate_type_oper,		rate_oper,
	vo_amt_nat,		amt_doc_nat,		amt_dist_nat,		amt_on_acct,
	org_id			)
SELECT	settlement_ctrl_num,	vendor_code,		pay_to_code,		hold_flag,	
	date_entered,		date_applied,		user_id,		batch_code,
	process_group_num,	state_flag,		disc_total_home,	disc_total_oper,
	debit_memo_total_home,	debit_memo_total_oper,	on_acct_pay_total_home,	on_acct_pay_total_oper,
	payments_total_home,	payments_total_oper,	put_on_acct_total_home,	put_on_acct_total_oper,
	gain_total_home,	gain_total_oper,	loss_total_home,	loss_total_oper,
	description,		nat_cur_code,		doc_count_expected,	doc_count_entered,
	doc_sum_expected,	doc_sum_entered,	vo_total_home,		vo_total_oper,
	rate_type_home,		rate_home,		rate_type_oper,		rate_oper,
	vo_amt_nat,		amt_doc_nat,		amt_dist_nat,		amt_on_acct,
	org_id	
FROM	#apinpstl

INSERT	apinppyt (			
	trx_ctrl_num, 	trx_type,	doc_ctrl_num,	trx_desc,	batch_code,	cash_acct_code,
	date_entered,	date_applied,	date_doc,	vendor_code,	pay_to_code,	approval_code,
	payment_code,	payment_type,	amt_payment,	amt_on_acct,	posted_flag,	printed_flag,
	hold_flag,	approval_flag,	gen_id,		user_id,	void_type, 	amt_disc_taken,
	print_batch_num,company_code,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,
	rate_home,	rate_oper,	payee_name,	settlement_ctrl_num, doc_amount, org_id	)
SELECT	trx_ctrl_num, 	trx_type,	doc_ctrl_num,	trx_desc,	batch_code,	cash_acct_code,
	date_entered,	date_applied,	date_doc,	vendor_code,	pay_to_code,	approval_code,
	payment_code,	payment_type,	amt_payment,	amt_on_acct,	posted_flag,	printed_flag,
	hold_flag,	approval_flag,	gen_id,		user_id,	void_type, 	amt_disc_taken,
	print_batch_num,company_code,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,
	rate_home,	rate_oper,	payee_name,	settlement_ctrl_num, 	amt_payment, org_id
FROM	#apinppyt3450

INSERT	apinppdt (			
	trx_ctrl_num,	trx_type,	sequence_id,	apply_to_num,	apply_trx_type,	
	amt_applied,    amt_disc_taken,	line_desc,	void_flag,	payment_hold_flag,	
	vendor_code,	vo_amt_applied,	vo_amt_disc_taken,gain_home,	gain_oper,	
	nat_cur_code,	cross_rate,	org_id		)
SELECT	trx_ctrl_num,	trx_type,	sequence_id,	apply_to_num,	apply_trx_type,	
	amt_applied,    amt_disc_taken,	line_desc,	void_flag,	payment_hold_flag,	
	vendor_code,	vo_amt_applied,	vo_amt_disc_taken,gain_home,	gain_oper,	
	nat_cur_code,	cross_rate,	org_id		
FROM	#apinppdt3450

INSERT	apinpchg (			
	trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
	po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
	date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
	posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
	comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
	payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
	add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
	amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
	amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
	user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
	pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
	cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
	rate_oper,	net_original_amt, org_id	)
SELECT	trx_ctrl_num,	trx_type,	doc_ctrl_num,	apply_to_num,	user_trx_type_code,	batch_code,
	po_ctrl_num,	vend_order_num,	ticket_num,	date_applied,	date_aging,		date_due,
	date_doc,	date_entered,	date_received,	date_required,	date_recurring,		date_discount,
	posting_code,	vendor_code,	pay_to_code,	branch_code,	class_code,		approval_code,
	comment_code,	fob_code,	terms_code,	tax_code,	recurring_code,		location_code,
	payment_code,	times_accrued,	accrual_flag,	drop_ship_flag,	posted_flag,		hold_flag,
	add_cost_flag,	approval_flag,	recurring_flag,	one_time_vend_flag,one_check_flag,	amt_gross,
	amt_discount,	amt_tax,	amt_freight,	amt_misc,	amt_net,		amt_paid,
	amt_due,	amt_restock,	amt_tax_included,frt_calc_tax,	doc_desc,		hold_desc,
	user_id,	next_serial_id,	pay_to_addr1,	pay_to_addr2,	pay_to_addr3,		pay_to_addr4,
	pay_to_addr5,	pay_to_addr6,	attention_name,	attention_phone,intercompany_flag,	company_code,
	cms_flag,	process_group_num,nat_cur_code,	rate_type_home,	rate_type_oper,		rate_home,
	rate_oper,	net_original_amt, org_id	
FROM	#apinpchg

INSERT	apinpcdt (	
	trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
	qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
	return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
	amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
	gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
	iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
	org_id, 	amt_nonrecoverable_tax, 	amt_tax_det		)
SELECT	trx_ctrl_num,	trx_type,	sequence_id,	location_code,		item_code,	bulk_flag,	
	qty_ordered,	qty_received,	qty_returned,	qty_prev_returned,	approval_code,	tax_code,
	return_code,	code_1099,	po_ctrl_num,	unit_code,		unit_price,	amt_discount,		
	amt_freight,	amt_tax,	amt_misc,	amt_extended,		calc_tax,	date_entered,
	gl_exp_acct,	new_gl_exp_acct,rma_num,	line_desc,		serial_id,	company_id,	
	iv_post_flag,	po_orig_flag,	rec_company_code,new_rec_company_code,	reference_code, new_reference_code,
	org_id, 	amt_nonrecoverable_tax, 	amt_tax_det
FROM	#apinpcdt


INSERT	apinptax (	
	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
	amt_tax,	amt_final_tax		)
SELECT	trx_ctrl_num,	trx_type,	sequence_id,	tax_type_code,	amt_taxable,	amt_gross,
	amt_tax,	amt_final_tax		
FROM	#apinptax


INSERT apinpage(
	trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,	date_aging,	amt_due )
SELECT 	trx_ctrl_num,	trx_type,	sequence_id,	date_applied,	date_due,	date_aging,	amt_due
FROM #apinpage




IF @@error != 0
Begin
	exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',13,''
	RETURN -1
End


DROP TABLE #gain_loss
DROP TABLE #arinppyt4750		
DROP TABLE #arinppdt4750
DROP TABLE #arinpstlhdr	
DROP TABLE #apinppyt3450  
DROP TABLE #apinppdt3450   
DROP TABLE #apinpstl	
DROP TABLE #arinpchg	
DROP TABLE #arinpcdt	
DROP TABLE #arinptax	
DROP TABLE #arinpage
DROP TABLE #apinpchg	
DROP TABLE #apinpcdt	
DROP TABLE #apinptax
DROP TABLE #apinpage

exec nbinsertnbtrxlog_sp @process_ctrl_num,@net_ctrl_num,'2.5',-1,''

RETURN    0  

GO
GRANT EXECUTE ON  [dbo].[NBNetPaymentVsCashReceipt_sp] TO [public]
GO
