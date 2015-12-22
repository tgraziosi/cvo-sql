SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_fs_create_temps] AS
Begin
Declare @obj varchar(40)
	CREATE TABLE #TxLineInput (	control_number		varchar(16),reference_number	int,
	   	tax_code			varchar(8),	quantity			FLOAT,	exted_price		float,
      		discount_amount		float,	tax_type			smallint,	currency_code		varchar(8) )
	
	CREATE TABLE #TxInfo (	control_number		varchar(16),	sequence_id		int,
		tax_type_code		varchar(8),	amt_taxable			float,	amt_gross			float,
		amt_tax				float,	amt_final_tax		float,	currency_code		varchar(8),
	 	tax_included_flag	smallint )
	
	CREATE TABLE #TxLineTax (	control_number		varchar(16),	reference_number	int,
			tax_amount			float,	tax_included_flag	smallint )
	
	CREATE TABLE #txdetail ( control_number	varchar(16), reference_number	int,
		 tax_type_code		varchar(8),	amt_taxable		float	) 

	CREATE TABLE #txinfo_id ( id_col numeric identity, control_number	varchar(16), 
		 sequence_id		int,	tax_type_code		varchar(8),	currency_code		varchar(8)	)

	CREATE TABLE #TXInfo_min_id (control_number varchar(16),min_id_col numeric) 

	CREATE TABLE	#TxTLD ( control_number	varchar(16), tax_type_code		varchar(8),
		tax_code		varchar(8),	currency_code		varchar(8),	tax_included_flag	smallint,
		base_id		int, amt_taxable		float, amt_gross		float		)

/* Credit Checking temp tables */
	CREATE TABLE #arcrchk (  customer_code	varchar(8), check_credit_limit	smallint,
		 credit_limit	float, limit_by_home	smallint) 

	CREATE UNIQUE INDEX #arcrchk_ind_0 ON #arcrchk (customer_code)

/* Error Processing Temps */

	CREATE TABLE #ewerror(    module_id smallint,	err_code  int,	info1 char(32),
		info2 char(32),	infoint int,	infofloat float,	flag1 smallint,	trx_ctrl_num char(16),
		sequence_id int,	source_ctrl_num char(16),	extra int)

	CREATE TABLE #arvalchg(	trx_ctrl_num    varchar(16),	doc_ctrl_num    varchar(16),	doc_desc	varchar(40),
		apply_to_num    varchar(16),	apply_trx_type  smallint,	order_ctrl_num  varchar(16),	batch_code      varchar(16),
		trx_type        smallint,	date_entered    int,	date_applied    int,	date_doc        int,	date_shipped    int,
		date_required   int,	date_due        int,	date_aging      int,	customer_code   varchar(8),	ship_to_code    varchar(8),
		salesperson_code        varchar(8),territory_code  varchar(8),comment_code    varchar(8),fob_code        varchar(8),
		freight_code    varchar(8),	terms_code      varchar(8),	fin_chg_code    varchar(8),	price_code      varchar(8),
		dest_zone_code  varchar(8),	posting_code    varchar(8),	recurring_flag  smallint,	recurring_code  varchar(8),
		tax_code        varchar(8),	cust_po_num     varchar(20),	total_weight    float,	amt_gross       float,
		amt_freight     float,	amt_tax float,	amt_tax_included	float,	amt_discount    float,	amt_net float,
		amt_paid        float,	amt_due float,	amt_cost        float,	amt_profit      float,	next_serial_id  smallint,
		printed_flag    smallint,	posted_flag     smallint,	hold_flag       smallint,	hold_desc	varchar(40),
		user_id smallint,	customer_addr1	varchar(40),	customer_addr2	varchar(40),	customer_addr3	varchar(40),
		customer_addr4	varchar(40),	customer_addr5	varchar(40),	customer_addr6	varchar(40),	ship_to_addr1	varchar(40),
		ship_to_addr2	varchar(40),	ship_to_addr3	varchar(40),	ship_to_addr4	varchar(40),	ship_to_addr5	varchar(40),
		ship_to_addr6	varchar(40),	attention_name	varchar(40),	attention_phone	varchar(30),	amt_rem_rev     float,
		amt_rem_tax     float,	date_recurring  int,	location_code   varchar(8),	process_group_num       varchar(16) NULL,
		source_trx_ctrl_num     varchar(16) NULL,	source_trx_type smallint NULL,	amt_discount_taken      float NULL,
		amt_write_off_given     float NULL,	nat_cur_code    varchar(8),     	rate_type_home  varchar(8),
		rate_type_oper  varchar(8),	rate_home       float, 	rate_oper       float, temp_flag	smallint	NULL)

/* GL Processing Tables */
	CREATE TABLE #gltrx (mark_flag	smallint NOT NULL, next_seq_id	int NOT NULL, trx_state	smallint NOT NULL,
		journal_type	varchar(8) NOT NULL, journal_ctrl_num	varchar(16) NOT NULL, journal_description	varchar(40) NOT NULL,
		date_entered	int NOT NULL,	date_applied	int NOT NULL,	recurring_flag	smallint NOT NULL,	repeating_flag	smallint NOT NULL,
		reversing_flag	smallint NOT NULL, hold_flag smallint NOT NULL,	posted_flag		smallint NOT NULL,
		date_posted		int NOT NULL,	source_batch_code		varchar(16) NOT NULL,	process_group_num		varchar(16) NOT NULL,
		batch_code 	varchar(16) NOT NULL, type_flag	smallint NOT NULL,	intercompany_flag	smallint NOT NULL,	company_code	varchar(8) NOT NULL,
		app_id	smallint NOT NULL,	home_cur_code	varchar(8) NOT NULL,	document_1	varchar(16) NOT NULL,	trx_type	smallint NOT NULL,
		user_id	smallint NOT NULL,	source_company_code	varchar(8) NOT NULL,   oper_cur_code  varchar(8))

	CREATE UNIQUE INDEX #gltrx_ind_0 ON #gltrx ( journal_ctrl_num )

	CREATE TABLE #gltrxdet (mark_flag smallint NOT NULL, trx_state	smallint NOT NULL, journal_ctrl_num	varchar(16) NOT NULL,
		sequence_id int NOT NULL,	rec_company_code	varchar(8) NOT NULL,	company_id smallint NOT NULL, account_code varchar(32) NOT NULL,
		description	varchar(40) NOT NULL, document_1	varchar(16) NOT NULL, document_2	varchar(16) NOT NULL,
		reference_code	varchar(32) NOT NULL, balance	float NOT NULL, nat_balance float NOT NULL, nat_cur_code	varchar(8) NOT NULL,
		rate	float NOT NULL, posted_flag smallint NOT NULL, date_posted int NOT NULL, trx_type smallint NOT NULL,
		offset_flag smallint NOT NULL, seg1_code	varchar(32) NOT NULL, seg2_code	varchar(32) NOT NULL, seg3_code	varchar(32) NOT NULL,
		seg4_code	varchar(32) NOT NULL, seq_ref_id		int NOT NULL, balance_oper  float NULL, rate_oper  float NULL,
   		rate_type_home varchar(8) NULL,	rate_type_oper varchar(8) NULL)

	CREATE UNIQUE INDEX #gltrxdet_ind_0	ON #gltrxdet ( journal_ctrl_num, sequence_id )

	CREATE INDEX #gltrxdet_ind_1	ON #gltrxdet ( journal_ctrl_num, account_code )

	CREATE TABLE #trxerror (journal_ctrl_num  	varchar(16),	sequence_id		int,	error_code	  	int)
	
	CREATE UNIQUE INDEX	#trxerror_ind_0 ON #trxerror ( journal_ctrl_num, sequence_id, error_code )
		
	CREATE TABLE	#offset_accts ( account_code	varchar(32)	NOT NULL, org_code	varchar(8)	NOT NULL, rec_code	varchar(8)	NOT NULL,
		sequence_id	int 	NOT NULL)

	CREATE UNIQUE CLUSTERED INDEX	#offset_accts_ind_0 ON #offset_accts( rec_code, account_code, org_code )

	CREATE TABLE	#offsets ( journal_ctrl_num	varchar(16)	NOT NULL, sequence_id int	NOT NULL, company_code		varchar(8)	NOT NULL,
		company_id		smallint	NOT NULL, org_ic_acct  varchar(32)	NOT NULL, org_seg1_code		varchar(32)	NOT NULL, org_seg2_code		varchar(32)	NOT NULL,
		org_seg3_code		varchar(32)	NOT NULL, org_seg4_code		varchar(32)	NOT NULL, rec_ic_acct  		varchar(32)	NOT NULL,
		rec_seg1_code		varchar(32)	NOT NULL, rec_seg2_code		varchar(32)	NOT NULL, rec_seg3_code		varchar(32)	NOT NULL,
		rec_seg4_code		varchar(32)	NOT NULL )
		--if

	CREATE UNIQUE CLUSTERED INDEX	#offsets_ind_0	ON #offsets ( journal_ctrl_num, sequence_id )
		
	CREATE TABLE #batches ( date_applied		int	NOT NULL, source_batch_code	varchar(16)	NOT NULL)

	CREATE UNIQUE CLUSTERED INDEX	#batches_ind_0 ON	#batches (	date_applied, source_batch_code )
		
	CREATE TABLE #gltrxjcn( journal_ctrl_num varchar(16) )
		
	CREATE TABLE #gldtrdet ( journal_ctrl_num	varchar(16)	NOT NULL, sequence_id		int	NOT NULL, account_code varchar(32)	NOT NULL,
	          	balance float	NOT NULL, nat_balance float	NOT NULL, nat_cur_code varchar(8)	NOT NULL,
	       	rec_company_code	varchar(8)	NOT NULL, mark_flag smallint NOT NULL, balance_oper float   NOT NULL)

	CREATE UNIQUE CLUSTERED INDEX	#gldtrdet_ind_0 ON #gldtrdet ( journal_ctrl_num, sequence_id )

	CREATE INDEX	#gldtrdet_ind_1 ON #gldtrdet ( account_code )

	CREATE TABLE	#drcr ( account_code	varchar(32)	NOT NULL, balance_type	smallint	NOT NULL, currency_code	varchar(8)	NOT NULL,
		home_debit	float	NOT NULL, home_credit	float	NOT NULL, nat_debit	float	NOT NULL, nat_credit	float	NOT NULL,
		bal_fwd_flag	smallint	NOT NULL, seg1_code	varchar(32)	NOT NULL, seg2_code	varchar(32)	NOT NULL, seg3_code	varchar(32)	NOT NULL,
		seg4_code	varchar(32)	NOT NULL, account_type	smallint	NOT NULL, initialized     tinyint NOT NULL, oper_debit float NOT NULL,
      		oper_credit  float NOT NULL )
	
	CREATE UNIQUE INDEX #drcr_ind_0 ON #drcr ( account_code, currency_code, balance_type )
		
	CREATE TABLE	#summary ( summary_code		varchar(32)	NOT NULL, summary_type		tinyint	NOT NULL,
		account_code		varchar(32)	NOT NULL )
		
	CREATE UNIQUE CLUSTERED INDEX	#summary_ind_0 ON	#summary ( account_code, summary_code, summary_type )
		
	CREATE TABLE	#sumhdr ( summary_code		varchar(32)	NOT NULL, summary_type		tinyint	NOT NULL,
		bal_fwd_flag		smallint	NOT NULL, balance_type		smallint	NOT NULL, seg1_code		varchar(32)	NOT NULL,
		seg2_code		varchar(32)	NOT NULL, seg3_code		varchar(32)	NOT NULL, seg4_code		varchar(32)	NOT NULL,
		account_type		smallint 	NOT NULL )

	CREATE UNIQUE CLUSTERED	INDEX	#sumhdr_ind_0 ON #sumhdr ( summary_code, summary_type )
		
	CREATE TABLE #gldtrx (	journal_ctrl_num varchar(16)	NOT NULL, date_applied int	NOT NULL,
		recurring_flag			smallint	NOT NULL, repeating_flag			smallint	NOT NULL,
		reversing_flag			smallint	NOT NULL, mark_flag           		smallint	NOT NULL )

	CREATE UNIQUE CLUSTERED INDEX	#gldtrx_ind_0 ON #gldtrx ( journal_ctrl_num )
		

	CREATE INDEX	#gldtrx_ind_1 ON		#gldtrx ( mark_flag )
		
	CREATE TABLE	#acct  (	account_code	varchar(32) NOT NULL, balance_type	smallint NOT NULL )

	CREATE UNIQUE INDEX	#acct_ind_0 ON	#acct ( account_code, balance_type )

	CREATE TABLE	#updglbal (	account_code		varchar(32)	NOT NULL, currency_code		varchar(8)	NOT NULL,
			balance_date		int	NOT NULL, balance_until		int	NOT NULL, balance_type		smallint	NOT NULL,
			current_balance		float	NOT NULL, home_current_balance	float	NOT NULL, bal_fwd_flag		smallint	NOT NULL,
			seg1_code		varchar(32)	NOT NULL, seg2_code		varchar(32)	NOT NULL, seg3_code		varchar(32)	NOT NULL,
			seg4_code		varchar(32)	NOT NULL, account_type  smallint    NOT NULL, current_balance_oper float NOT NULL)
		
	CREATE UNIQUE INDEX #updglbal_ind_0 ON #updglbal (	account_code, currency_code, balance_date, balance_type )
		
	CREATE TABLE #hold ( journal_ctrl_num  	varchar(16)	NOT NULL, e_code	int	NOT NULL, logged smallint	NOT NULL)
		
	CREATE UNIQUE INDEX	#hold_ind_0 ON	#hold ( journal_ctrl_num, e_code )

Select @obj='##employee%'

If not exists (select * from tempdb.dbo.sysobjects where type = 'U' and name like @obj)
	Begin	
		CREATE TABLE ##employee( emp_id	integer
			CONSTRAINT p1_constraint PRIMARY KEY NONCLUSTERED,
			fname 		CHAR(20) NOT NULL,
			minitial	CHAR(1) NULL,
			lname		VARCHAR(30) NOT NULL,
			job_id 		SMALLINT NOT NULL DEFAULT 1)
	End

End

GO
GRANT EXECUTE ON  [dbo].[tdc_fs_create_temps] TO [public]
GO
