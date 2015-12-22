SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                



















































































































































































































































































  



					  

























































 

































































































































































































































































































CREATE PROC [dbo].[ibpost_gl_sp]
 
	@process_ctrl_num	nvarchar(16),
	@trial_flag	integer=1,
	@debug_level	integer=0

AS


-- #include "STANDARD DECLARES.INC"





































DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(1000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @version			VARCHAR(128)
DECLARE @len				INTEGER
DECLARE @i				INTEGER

-- end "STANDARD DECLARES.INC"


DECLARE @ibio_exists		INTEGER
DECLARE @iblink_exists		INTEGER
DECLARE @iberror_exists		INTEGER
DECLARE @ibhdr_exists		INTEGER
DECLARE @ibdet_exists		INTEGER
DECLARE @gltrx_exists		INTEGER
DECLARE @gltrxdet_exists	INTEGER
DECLARE @ewerror_exists		INTEGER
DECLARE @userid			INTEGER
DECLARE @username		NVARCHAR(30)
DECLARE @id			UNIQUEIDENTIFIER
DECLARE @sql			NVARCHAR(3200)
DECLARE @sequence_id		INTEGER
DECLARE @precision_gl		INTEGER
DECLARE @home_currency		NVARCHAR(8)
DECLARE @rate_type_home		NVARCHAR(8)
DECLARE @rate_type_oper		NVARCHAR(8)
DECLARE @branch_code_segment 	INTEGER
DECLARE @branch_code_offset	INTEGER
DECLARE @branch_code_length	INTEGER
DECLARE @trx_ctrl_num		NVARCHAR(16)
DECLARE @module_id 		SMALLINT
DECLARE @val_mode 		INTEGER
DECLARE @journal_type 		NVARCHAR(8)
DECLARE @controlling_journal_ctrl_num 	NVARCHAR(30)				
DECLARE @detail_journal_ctrl_num	NVARCHAR(16)
DECLARE @journal_ctrl_num 	NVARCHAR(16)
DECLARE @journal_description 	NVARCHAR(30)
DECLARE @date_entered 		INTEGER
DECLARE @date_applied 		INTEGER
DECLARE @reccuring_flag 	SMALLINT
DECLARE @repeatng_flag 		SMALLINT
DECLARE @reversing_flag 	SMALLINT
DECLARE @source_batch_code 	NVARCHAR(16)
DECLARE @type_flag 		SMALLINT
DECLARE @company_code 		NVARCHAR(8)
DECLARE @document_1 		NVARCHAR(16)
DECLARE @trx_type 		SMALLINT
DECLARE @hdr_trx_type 		SMALLINT
DECLARE @hold_flag 		SMALLINT
DECLARE @oper_currency		NVARCHAR(8)
DECLARE @rec_company_code 	NVARCHAR(8)
DECLARE @account_code 		NVARCHAR(32)
DECLARE @description 		NVARCHAR(40)
DECLARE @document_2 		NVARCHAR(16)
DECLARE @reference_code 	NVARCHAR(32)
DECLARE @balance 		FLOAT
DECLARE @nat_balance 		FLOAT
DECLARE @balance_oper 		FLOAT
DECLARE @nat_cur_code 		NVARCHAR(8)
DECLARE @rate 			FLOAT
DECLARE @rate_oper 		FLOAT
DECLARE @seq_ref_id 		INTEGER
DECLARE @init_mode		INTEGER
DECLARE @interface_mode		INTEGER
DECLARE @max_controlling_sequence_id	INTEGER
DECLARE @max_detail_sequence_id		INTEGER
DECLARE @tax_type_code		NVARCHAR(8)
DECLARE @controlling_org_id	NVARCHAR(30)
DECLARE @detail_org_id		NVARCHAR(30)
DECLARE @org_id			NVARCHAR(30)
DECLARE @mask			NVARCHAR(16)
DECLARE @next_number		INTEGER
DECLARE @new_bcn		NVARCHAR(16)
DECLARE @curdate		INTEGER
DECLARE @curtime		INTEGER
DECLARE @batch_type		INTEGER
DECLARE @external_flag		SMALLINT
DECLARE @dummy_counter		INTEGER
DECLARE @tax_exists		int



DECLARE @amount 		float,   
	@external int,  
	@recipient_code	nvarchar(30)   


DECLARE @external_post	int 

SELECT @external_post = 0 
SELECT  @dummy_counter =0

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 146, 5 ) + " -- ENTRY: "	



	SELECT 	@return_value = 0, @iberror_exists = 0, @ibhdr_exists = 0, @ibdet_exists = 0, 
		@gltrx_exists = 0, @gltrxdet_exists = 0,  @ewerror_exists =0

	




	IF NOT EXISTS (SELECT 1 FROM ibifc_all WHERE process_ctrl_num = @process_ctrl_num AND state_flag IN (0,-1, -4,-5))
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 160, 5 ) + " -- EXIT: "
		RETURN 0
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 164, 5 ) + " -- MSG: " + 'Getting User ID'

	EXEC @ret = ibget_userid_sp @userid OUTPUT, @username OUTPUT
	
	IF @ret <> 0 
	BEGIN
		RETURN -130
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 173, 5 ) + " -- MSG: " + 'Creating Temporal Tables'

	

CREATE TABLE [#ibtax]
(	
	[flag]			integer,
	[timestamp]			timestamp NOT NULL,
	[id]				uniqueidentifier NOT NULL,
	[sequence_id]			integer NOT NULL,
	[tax_type_code]			nvarchar(8) NOT NULL,
	[amt_gross]			decimal(20,8) NOT NULL,
	[amt_taxable]			decimal(20,8) NOT NULL,
	[amt_tax]			decimal(20,8) NOT NULL,
	[create_date]			datetime  NOT NULL,
	[create_username]		nvarchar(256) NOT NULL,
	[last_change_date]		datetime  NOT NULL,
	[last_change_username]		nvarchar(256) NOT NULL,
	[last_change_userid]			integer,
	[nat_cur_code]			nvarchar(8) NOT NULL,	
	[balance_oper]			decimal(20,8) NOT NULL,
	[rate_oper]			decimal(20,8) NOT NULL,
	[oper_currency]			nvarchar(8) NOT NULL,	
	[rate_type_oper]		nvarchar(8) NOT NULL,	
	[balance_home]			decimal(20,8) NOT NULL,
	[rate_home]			decimal(20,8) NOT NULL,
	[home_currency]			nvarchar(8) NOT NULL,	
	[rate_type_home]		nvarchar(8) NOT NULL	
	)

	

CREATE TABLE #ibio
(	DocumentReferenceID		integer,
	id				uniqueidentifier,
	state_flag			integer,
	date_entered			datetime,
	date_applied			datetime,
	trx_type			integer  NULL,
	controlling_org_id		nvarchar(30)  NULL,
	detail_org_id			nvarchar(30)  NULL,
	amount			decimal(20,8)   NULL,	
	currency_code			nvarchar(16)   NULL,
	tax_code			nvarchar(8),
	recipient_code		nvarchar(32),
	originator_code		nvarchar(32),
	tax_payable_code		nvarchar(32),
	tax_expense_code		nvarchar(32),
	link1				nvarchar(1024)  NULL,
	link2				nvarchar(1024)  NULL,
	link3				nvarchar(1024)  NULL,
	username			nvarchar(256),
	reference_code		nvarchar(32),
	external_flag		smallint,
	source_document		nvarchar(16) NULL,
	source_line		int,
	rate_type_home NVARCHAR(8), 
	rate_type_oper NVARCHAR(8) 
	)

	

CREATE TABLE [#iberror]
(	[id]				uniqueidentifier,
	[error_code]			integer,
	[info1]				nvarchar(30),
	[info2]				nvarchar(30),
	[infoint]			integer,
	[infodecimal]			decimal(20,8),
	[link1]				nvarchar(1024),
	[link2]				nvarchar(1024),
	[link3]				nvarchar(1024)
	)

	

CREATE TABLE [#ibhdr]
(	[flag]			 integer,
	[controlling_journal_ctrl_num]	 nvarchar(30),
	[detail_journal_ctrl_num]	nvarchar(16),
	[timestamp]			timestamp NOT NULL,
	[id]				uniqueidentifier NOT NULL,
	[trx_ctrl_num]			nvarchar(16) NOT NULL,
	[date_entered]			datetime,
	[date_applied]			datetime,
	[trx_type]			integer NOT NULL,
	[controlling_org_id]		nvarchar(30) NOT NULL,
	[detail_org_id]			nvarchar(30) NOT NULL,
	[amount]			decimal(20,8),		
	[currency_code]			nvarchar(16) NOT NULL,
	[tax_code]			nvarchar(8) NOT NULL,
	[doc_description]		nvarchar(40) NOT NULL,
	[create_date]			datetime,
	[create_username]		nvarchar(256) NOT NULL,
	[last_change_date]		datetime,
	[last_change_username]		nvarchar(256) NOT NULL,
	[org_sequence_id]			integer,
	[external_flag]			smallint,
	[source_document]		nvarchar(16) NULL,
	[source_line]		int,
	rate_type_home NVARCHAR(8), 
	rate_type_oper NVARCHAR(8),
	sequence_order_ib	integer
	)



	

CREATE TABLE [#ibdet]
(	[flag]			integer,
	[timestamp]			timestamp NOT NULL,
	[id]				uniqueidentifier NOT NULL,
	[sequence_id]			integer NOT NULL,
	[org_id]			nvarchar(30) NOT NULL,
	[amount]			decimal(20,8) NOT NULL,
	[currency_code]			nvarchar(16) NOT NULL,
	[doc_description]		nvarchar(40) NOT NULL,
	[account_code]			nvarchar(32) NOT NULL,
	[reconciled_flag]		integer NOT NULL,
	[create_date]			datetime,
	[create_username]		nvarchar(256) NOT NULL,
	[last_change_date]		datetime,
	[last_change_username]		nvarchar(256) NOT NULL,
	[reference_code]		nvarchar(32) NOT NULL,
	[balance_oper]			decimal(20,8) NOT NULL,
	[rate_oper]			decimal(20,8) NOT NULL,
	[oper_currency]			nvarchar(8) NOT NULL,	
	[rate_type_oper]		nvarchar(8) NOT NULL,	
	[balance_home]			decimal(20,8) NOT NULL,
	[rate_home]			decimal(20,8) NOT NULL,
	[home_currency]			nvarchar(8) NOT NULL,	
	[rate_type_home]		nvarchar(8) NOT NULL,
	[state_flag]			integer
	)



	


CREATE TABLE [#iblink]
(
	[timestamp]			timestamp NOT NULL,
	[id]				uniqueidentifier NOT NULL,
	[sequence_id]			integer NOT NULL,
	[trx_type]			integer NOT NULL,	
	[source_trx_ctrl_num]		nvarchar(16) ,
	[source_sequence_id]		integer ,	
	[source_url]			nvarchar(1024),
	[source_urn]			nvarchar(256),
	[source_id]			integer ,		
	[source_po_no]			nvarchar(16),
	[source_order_no]		integer,	
	[source_ext]			integer,	
	[source_line]			integer,	
	[trx_ctrl_num]			nvarchar(30),
	[org_id]			nvarchar(30),
	[create_date]			datetime NOT NULL,
	[create_username]		nvarchar(256) NOT NULL,
	[last_change_date]		datetime,
	[last_change_username]		nvarchar(256) NOT NULL,	

	)




	
	























































































































































































































































































































































































































































                       









































CREATE TABLE #gltrx
(
	mark_flag			smallint NOT NULL,
	next_seq_id			int NOT NULL,
	trx_state			smallint NOT NULL,
	journal_type          		varchar(8) NOT NULL,
	journal_ctrl_num      		nvarchar(30) NOT NULL, 
	journal_description   		varchar(30) NOT NULL, 
	date_entered          		int NOT NULL,
	date_applied          		int NOT NULL,
	recurring_flag			smallint NOT NULL,
	repeating_flag			smallint NOT NULL,
	reversing_flag			smallint NOT NULL,
	hold_flag             		smallint NOT NULL,
	posted_flag           		smallint NOT NULL,
	date_posted           		int NOT NULL,
	source_batch_code		varchar(16) NOT NULL, 
	process_group_num		varchar(16) NOT NULL,
	batch_code             		varchar(16) NOT NULL, 
	type_flag			smallint NOT NULL,	
							
							
							
							
							
	intercompany_flag		smallint NOT NULL,	
	company_code			varchar(8) NOT NULL, 
	app_id				smallint NOT NULL,	


	home_cur_code		varchar(8) NOT NULL,		
	document_1		varchar(16) NOT NULL,	


	trx_type		smallint NOT NULL,		
	user_id			smallint NOT NULL,
	source_company_code	varchar(8) NOT NULL,
        oper_cur_code           varchar(8),         
	org_id			varchar(30) NULL,
	interbranch_flag	smallint
)

CREATE UNIQUE INDEX #gltrx_ind_0
	 ON #gltrx ( journal_ctrl_num )


	CREATE UNIQUE INDEX gltrx_temp1_ind	ON #gltrx(journal_ctrl_num)	
	
	








































































































CREATE TABLE #gltrxdet
(
	mark_flag		smallint NOT NULL,
	trx_state		smallint NOT NULL,
        journal_ctrl_num	varchar(30) NOT NULL,
	sequence_id		int NOT NULL,
	rec_company_code	varchar(8) NOT NULL,	
	company_id		smallint NOT NULL,
        account_code		varchar(32) NOT NULL,	
	description		varchar(40) NOT NULL,
        document_1		varchar(30) NOT NULL, 	
        document_2		varchar(30) NOT NULL, 	
	reference_code		varchar(32) NOT NULL,	
        balance			float NOT NULL,		
	nat_balance		float NOT NULL,		
	nat_cur_code		varchar(8) NOT NULL,	
	rate			float NOT NULL,		
        posted_flag             smallint NOT NULL,
        date_posted		int NOT NULL,
	trx_type		smallint NOT NULL,
	offset_flag		smallint NOT NULL,	





	seg1_code		varchar(32) NOT NULL,
	seg2_code		varchar(32) NOT NULL,
	seg3_code		varchar(32) NOT NULL,
	seg4_code		varchar(32) NOT NULL,
	seq_ref_id		int NOT NULL,		
        balance_oper            float NULL,
        rate_oper               float NULL,
        rate_type_home          varchar(8) NULL,
	rate_type_oper          varchar(8) NULL,
	org_id			varchar(30) NULL
                                                
)

CREATE UNIQUE INDEX #gltrxdet_ind_0
	ON #gltrxdet ( journal_ctrl_num, sequence_id )

CREATE INDEX #gltrxdet_ind_1
	ON #gltrxdet ( journal_ctrl_num, account_code )

	CREATE UNIQUE INDEX  gltrxdet_temp1_ind ON #gltrxdet(journal_ctrl_num, sequence_id)
	
	






























































































CREATE TABLE #trxerror
(
	journal_ctrl_num  	varchar(30) NOT NULL, 
	sequence_id		int NOT NULL,
	error_code	  	int NOT NULL
)

CREATE UNIQUE CLUSTERED INDEX	#trxerror_ind_0
ON				#trxerror (	journal_ctrl_num, 
						sequence_id, 
						error_code )


	CREATE UNIQUE INDEX trxerror_temp1_ind	ON #trxerror(journal_ctrl_num, sequence_id, error_code)
	
	































































































CREATE TABLE #batches
(
	date_applied		int	NOT NULL,
	source_batch_code	varchar(16)	NOT NULL,
	org_id				varchar(30)
)

CREATE UNIQUE CLUSTERED INDEX	#batches_ind_0
ON				#batches (	date_applied, 
						source_batch_code,
						org_id )


	CREATE UNIQUE INDEX batches_temp1_ind	ON #batches(date_applied, source_batch_code)
	
	




CREATE TABLE	#offsets (
	journal_ctrl_num	varchar(30)	NOT NULL,
	sequence_id		int	NOT NULL,
	company_code		varchar(8)	NOT NULL,
	company_id		smallint	NOT NULL,
	org_ic_acct  		varchar(32)	NOT NULL,
	org_seg1_code		varchar(32)	NOT NULL,
	org_seg2_code		varchar(32)	NOT NULL,
	org_seg3_code		varchar(32)	NOT NULL,
	org_seg4_code		varchar(32)	NOT NULL,
	org_org_id		    varchar(30) NOT NULL,
	rec_ic_acct  		varchar(32)	NOT NULL,
	rec_seg1_code		varchar(32)	NOT NULL,
	rec_seg2_code		varchar(32)	NOT NULL,
	rec_seg3_code		varchar(32)	NOT NULL,
	rec_seg4_code		varchar(32)	NOT NULL,
	rec_org_id		    varchar(30) NOT NULL )

CREATE UNIQUE CLUSTERED INDEX	#offsets_ind_0
	ON #offsets ( journal_ctrl_num, sequence_id )

	CREATE UNIQUE INDEX  offsets_temp1_ind	 ON #offsets(journal_ctrl_num, sequence_id)
	
	



CREATE TABLE	#offset_accts (
		account_code	varchar(32)	NOT NULL,
		org_code	varchar(8)	NOT NULL,
		rec_code	varchar(8)	NOT NULL,
		sequence_id	int 	NOT NULL)
CREATE UNIQUE CLUSTERED INDEX	#offset_accts_ind_0
	ON #offset_accts( rec_code, account_code, org_code )


	CREATE UNIQUE INDEX offsets_temp1_ind	ON #offset_accts(rec_code, account_code, org_code)
	
	






































































































CREATE TABLE	#pcontrol
(
	process_ctrl_num	varchar(16)	NOT NULL,
	process_parent_app	smallint	NOT NULL,		
	process_parent_company	varchar(8)	NOT NULL,	
	process_description	varchar(40)	NOT NULL,
	process_user_id		smallint	NOT NULL,		
	process_server_id	int	NOT NULL,		       	
	process_host_id		varchar(8)	NOT NULL,	
	process_kpid		int	NOT NULL,			
	process_start_date	datetime	NOT NULL,
	process_end_date	datetime NULL,
	process_state		smallint	NOT NULL
	
)

CREATE UNIQUE CLUSTERED INDEX	#pcontrol_ind_0
ON				#pcontrol ( process_ctrl_num ) 


	CREATE UNIQUE INDEX pcontrol_temp1_ind	ON #pcontrol(process_ctrl_num)
	
	
CREATE TABLE [#ibnumber]
(
	[id]				uniqueidentifier NOT NULL,
	[trx_type]			integer NOT NULL,
	[trx_ctrl_num]			nvarchar(16) NOT NULL
)


	
	IF EXISTS (SELECT 1 FROM CVO..ibifc_all WHERE process_ctrl_num = @process_ctrl_num and state_flag = -1)
	BEGIN
		SELECT @external_post = 1
		
CREATE TABLE  #rates (   from_currency   varchar(8),
			to_currency     varchar(8),
			rate_type       varchar(8),
			date_applied    int,
			rate            float)

	END
	ELSE
	BEGIN
		
CREATE TABLE  #rates_w_journal (   from_currency   varchar(8),  
   to_currency     varchar(8),  
   rate_type       varchar(8),  
   date_applied    int,  
   rate            float,
   journal_ctrl_num varchar(16),
   source_line	    int) 

	END

	
CREATE TABLE #gltrxedt1 (
	journal_ctrl_num	varchar(30), 
	sequence_id		int,
	journal_description	varchar(30),
	journal_type 		varchar(8),
	date_entered 		int,
	date_applied		int,
	batch_code		varchar(16),
	hold_flag		smallint,
	home_cur_code		varchar(8),
	intercompany_flag	smallint,
	company_code		varchar(8) NULL,
	source_batch_code	varchar(16),
	type_flag		smallint,
	user_id			smallint,
        source_company_code     varchar(8),
	account_code		varchar(32),
	account_description	varchar(40),	
	rec_company_code	varchar(8),
	nat_cur_code		varchar(8),
	document_1		varchar(16), 
	description		varchar(40),
	reference_code		varchar(32),
	balance			float,
	nat_balance		float,
	trx_type		smallint,
	offset_flag		smallint,
	seq_ref_id		int,
	temp_flag		smallint,
        spid                    smallint,
        oper_cur_code      	varchar(8)      NULL,
        balance_oper            float           NULL,
	db_name			varchar(128),
	controlling_org_id 	varchar(30) NULL, 
	detail_org_id 		varchar(30) NULL, 
	interbranch_flag int NULL
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
	trx_ctrl_num char(30),
	sequence_id int,
	source_ctrl_num char(30),
	extra int
)



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 220, 5 ) + " -- MSG: " + 'Getting GLCO Defaults'

	SELECT @home_currency = '', @rate_type_home = '', @branch_code_offset = 0, @branch_code_length = 0, @precision_gl = 2
	
	SELECT @precision_gl = curr_precision
	FROM glco, glcurr_vw
	WHERE glco.home_currency = glcurr_vw.currency_code
	
	SELECT 	@home_currency = home_currency, 	@rate_type_home = rate_type_home, 	@branch_code_offset = ib_offset, 
		@branch_code_length = ib_length, 	@branch_code_segment = ib_segment, 	@company_code = company_code, 
		@oper_currency = oper_currency, 	@rate_type_oper = rate_type_oper
	FROM glco


	SELECT @branch_code_offset = @branch_code_offset + (start_col - 1)
	FROM glaccdef
	WHERE	acct_level = @branch_code_segment


	
	
	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 243, 5 ) + " -- MSG: " + 'Cleaning temporal tables: #gltrx,#gltrxdet and #gltrxedt1'


	TRUNCATE TABLE #gltrx
	TRUNCATE TABLE #gltrxdet
	TRUNCATE TABLE #gltrxedt1
		
	
	
	
	
		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 255, 5 ) + " -- MSG: " + 'Inserting in #gltrx'

	INSERT  #gltrx(
		journal_type,           journal_ctrl_num,       journal_description,    
		date_entered,           date_applied,           recurring_flag,
		repeating_flag,         reversing_flag,         hold_flag,              
		posted_flag,            date_posted,            source_batch_code,
		batch_code,             type_flag,              intercompany_flag,
		company_code,           app_id,                 home_cur_code,
		document_1,             trx_type,               user_id,
		source_company_code,    process_group_num,      trx_state,
		next_seq_id,            mark_flag,
		oper_cur_code,		org_id, 		interbranch_flag)
	SELECT  journal_type,           journal_ctrl_num,       journal_description,   
		date_entered,           date_applied,           recurring_flag,
		repeating_flag,         reversing_flag,         hold_flag,
		posted_flag,            date_posted,            source_batch_code,
		batch_code,             type_flag,             intercompany_flag,
		company_code,           app_id,                 home_cur_code,
		document_1,             trx_type,               user_id,
		source_company_code,    process_group_num,      0,
		0,            		0, 
		oper_cur_code, 		org_id, 		interbranch_flag
	FROM gltrx 
	WHERE process_group_num = @process_ctrl_num 
				AND posted_flag = -1  
				AND interbranch_flag = 1


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 284, 5 ) + " -- MSG: " + 'Inserting in #gltrxdet'

	INSERT  #gltrxdet (	journal_ctrl_num,	sequence_id,	rec_company_code,
				company_id, 		account_code,	description,
				document_1,		document_2,	reference_code,
				balance,		nat_balance,	balance_oper,
				nat_cur_code,		rate, 		rate_oper,
				rate_type_home,		rate_type_oper,	posted_flag,    
				date_posted,trx_type,	offset_flag,    seg1_code,	
				seg2_code,      	seg3_code,      seg4_code,
				seq_ref_id,		trx_state,	mark_flag,
				org_id )
	SELECT d.journal_ctrl_num,	sequence_id,	rec_company_code,
				company_id, 		account_code,	description,
				d.document_1,		document_2,	reference_code,
				balance,		nat_balance,	balance_oper,
				nat_cur_code,		rate, 		rate_oper,
				d.rate_type_home,		d.rate_type_oper,	d.posted_flag,    
				d.date_posted,		d.trx_type,	offset_flag,    seg1_code,	
				seg2_code,      	seg3_code,      seg4_code,
				seq_ref_id,		0, 		0,
				d.org_id 
	FROM gltrxdet d
				INNER JOIN #gltrx h
				ON h.journal_ctrl_num=  d.journal_ctrl_num

	
	DELETE #ewerror
	WHERE err_code = 6500

	

	





	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 322, 5 ) + " -- MSG: " + 'Populate #ibio from ibifc'	

	IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION SELECT @transaction_started = 1 SELECT 'PS_TRACE'='BEGIN transaction: ' + 'LOADIBIO' END

	INSERT INTO #ibio (	DocumentReferenceID, 	id, 	state_flag, 	date_entered, 	date_applied, 
					trx_type, 		controlling_org_id, 	detail_org_id, 	amount, 
					currency_code, 		tax_code, 		recipient_code,
					originator_code,	tax_payable_code, 	tax_expense_code, 
					link1, 			link2, 			link3, 
					username,		reference_code, 	external_flag,
					source_document,	source_line  
					, rate_type_home, rate_type_oper)  
	SELECT 		0, 			NEWID(), f.state_flag, 	dateadd(day,  g.date_entered - 693596, '01/01/1900'   ) , 	dateadd(day,  g.date_applied - 693596, '01/01/1900'   ), 
					g.trx_type, 		g.org_id, 		d.org_id,  	d.nat_balance, 
					d.nat_cur_code, 	'', 			d.account_code,
					d.account_code,		d.account_code, 	d.account_code,  
					f.link1, 		d.sequence_id, 		f.link3, 
					f.username, 		d.reference_code,	0,
					d.document_2,		d.sequence_id 
					, d.rate_type_home, d.rate_type_oper
	FROM ibifc_all  f
		INNER JOIN #gltrx g
				ON f.link1 = g.journal_ctrl_num
				AND g.interbranch_flag = 1
		INNER JOIN #gltrxdet d
				ON g.journal_ctrl_num = d.journal_ctrl_num
				AND g.org_id<> d.org_id 
	WHERE f.process_ctrl_num = @process_ctrl_num
		       	AND f.state_flag IN ( 0, -4)
			AND g.journal_ctrl_num NOT IN (SELECT journal_ctrl_num FROM #trxerror UNION SELECT trx_ctrl_num FROM #ewerror)


	
	TRUNCATE TABLE #trxerror
	TRUNCATE TABLE #ewerror


	UPDATE ibifc_all 
	SET state_flag = -2
	WHERE process_ctrl_num = @process_ctrl_num
	AND state_flag IN ( 0, -4)		


	IF @transaction_started = 1 BEGIN COMMIT TRANSACTION SELECT @transaction_started = 0 SELECT 'PS_TRACE'='COMMIT transaction: ' + 'LOADIBIO' END

	

	















	



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 389, 5 ) + " -- MSG: " + 'Prepare #ibio for recipient_code and originator_code update'	

	UPDATE #ibio SET state_flag  = 1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 393, 5 ) + " -- MSG: " + 'Update recipient_code and originator_code'

	UPDATE #ibio
	SET recipient_code  = d.recipient_code,
	    originator_code = d.originator_code,
	    state_flag = 0
	FROM OrganizationOrganizationDef d, #ibio i
	WHERE	d.controlling_org_id = i.controlling_org_id
	AND d.detail_org_id = i.detail_org_id
	AND i.recipient_code LIKE d.account_mask

	

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 407, 5 ) + " -- MSG: " + 'Register errors encountered recipient_code and  originator_code  update'

	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	SELECT id, 10040, recipient_code, originator_code, 0, 0.0, '',link2,''
	FROM #ibio d
	WHERE d.state_flag = 1


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 415, 5 ) + " -- MSG: " + 'Update tax accounts for transactios that have a tax'

	UPDATE #ibio
	SET tax_expense_code  = recipient_code,
	    tax_payable_code = originator_code
	FROM #ibio WHERE  (DATALENGTH(ISNULL(RTRIM(LTRIM(tax_code)),0))<>0) 

	



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 426, 5 ) + " -- MSG: " + 'Insert Apply masks to rows in table #ibio'	

	UPDATE #ibio 
        SET originator_code = SUBSTRING(d.originator_code,0,@branch_code_offset) +
			   RTRIM(LTRIM(o.branch_account_number)) +    SUBSTRING(d.originator_code, @branch_code_offset + @branch_code_length, 32)
	FROM #ibio d, Organization_all o
	WHERE d.controlling_org_id = o.organization_id 
	

	UPDATE #ibio 
        SET recipient_code = SUBSTRING(d.recipient_code,0,@branch_code_offset) +
			   RTRIM(LTRIM(o.branch_account_number)) +	SUBSTRING(d.recipient_code, @branch_code_offset + @branch_code_length, 32)
	FROM #ibio d, Organization_all o
	WHERE d.detail_org_id = o.organization_id 
	
	UPDATE #ibio 
	SET tax_expense_code = SUBSTRING(d.tax_expense_code,0,@branch_code_offset) +
				   RTRIM(LTRIM(o.branch_account_number)) +    SUBSTRING(d.tax_expense_code, @branch_code_offset + @branch_code_length, 32),
	tax_payable_code = SUBSTRING(d.tax_payable_code,0,@branch_code_offset) +
				   RTRIM(LTRIM(o.branch_account_number)) +	SUBSTRING(d.tax_payable_code, @branch_code_offset + @branch_code_length, 32)		     
	FROM #ibio d, Organization_all o
	WHERE d.detail_org_id = o.organization_id AND (DATALENGTH(ISNULL(RTRIM(LTRIM(d.tax_code)),0))<>0) 
	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 450, 5 ) + " -- MSG: " + 'Insert into #ibio external transactions'

	IF @external_post = 1
	BEGIN
		INSERT INTO #ibio (	DocumentReferenceID, 	id, 	state_flag, 	date_entered, 	date_applied, 
					trx_type, 		controlling_org_id, 	detail_org_id, 	amount, 
					currency_code, 		tax_code, 		recipient_code,
					originator_code,	tax_payable_code, 	tax_expense_code, 
					link1, 			link2, 			link3, 
					username,		reference_code,		external_flag,
					source_document,	source_line 		
					, rate_type_home, rate_type_oper)
		SELECT 		0, 			id , 	0, 		f.date_entered,  f.date_applied, 
					f.trx_type, 		f.controlling_org_id, 	f.detail_org_id,  f.amount * -1, 
					f.currency_code, 	f.tax_code, 		f.recipient_code,
					f.originator_code,	f.tax_payable_code, 	f.tax_expense_code,  
					f.link1, 		f.link2, 		f.link3, 
					f.username, 		f.reference_code,	1,
					'e4se',			1 			
					, @rate_type_home, @rate_type_oper		
		FROM ibifc_all  f
		WHERE process_ctrl_num = @process_ctrl_num
		AND state_flag IN ( -1, -5 )
	
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 474, 5 ) + " -- MSG: " + 'Lock rows in ibifc for external transactions'
	
		UPDATE ibifc_all 
		SET state_flag = -3
		WHERE process_ctrl_num = @process_ctrl_num
		AND state_flag IN ( -1, -5)
	
	END 

	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 485, 5 ) + " -- MSG: " + 'Populate tax information into #ibio'

	UPDATE 	#ibio
	SET 	tax_code = oot.tax_code
	FROM    #ibio hdr, OrganizationOrganizationTrx oot
	WHERE 	hdr.controlling_org_id 	= oot.controlling_org_id
	AND 	hdr.detail_org_id 	= oot.detail_org_id
	AND 	hdr.trx_type 		= oot.trx_type

	





	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 502, 5 ) + " -- MSG: " + 'Executing ibvalidate_sp'

	EXEC ibvalidate_sp @debug_level

	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 508, 5 ) + " -- MSG: " + 'Mark Transactions After Validate'
	

	IF @trial_flag = 1
	BEGIN
		UPDATE #ibio
		SET state_flag = -1
		FROM #ibio i
			INNER JOIN #iberror e
			 ON  i.id=e.id
	END
	ELSE
	BEGIN

		


		DELETE #iberror
		FROM #iberror ib, ibedterr edt
		WHERE 	ib.error_code = edt.code
		AND 	edt.level = 2
	
		UPDATE #ibio
			SET state_flag = -1
		FROM #ibio i
			INNER JOIN #iberror e
			 ON  i.id=e.id
	END


	
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 540, 5 ) + " -- MSG: " + 'Mark All Child journals'
	
	
	UPDATE #ibio
	SET state_flag = -1
	FROM #ibio 
	WHERE link1 IN (SELECT link1 FROM #ibio WHERE state_flag = -1)
	AND external_flag = 0

		
	
	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 553, 5 ) + " -- MSG: " + 'Insert into #ewerror for #ibio records with errors'

	INSERT INTO #ewerror (  module_id, 	err_code,  	info1,  	info2, 
				 infoint,  	infofloat,  	flag1,  	trx_ctrl_num,  
				 sequence_id,  	source_ctrl_num, 	extra )  
	SELECT  DISTINCT 6000,  		error_code,  	info1,  	info2,  
				infoint,  	infodecimal,  		0,  	CASE WHEN b.external_flag = 0 THEN  b.link1 ELSE substring(convert(varchar,b.link3)+'-'+convert(varchar,b.trx_type),1,16) END,  
				CASE WHEN external_flag = 0 THEN e.link2 ELSE -1 END ,  	' ', 	 1
	FROM #iberror e
		INNER JOIN  #ibio b
			ON e.id = b.id	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 565, 5 ) + " -- MSG: " + 'UPDATE ibifc to mark records with errors-INTERNAL Transactions'

	UPDATE ibifc_all
	SET	state_flag = -4
	FROM ibifc_all i
		INNER JOIN #ibio h
			ON i.link1 = h.link1
			AND i.state_flag=-2
		INNER JOIN #iberror e
			ON h.id = e.id
		INNER JOIN ibedterr edt
			ON e.error_code = edt.code
			AND edt.level = 3

  
	



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 584, 5 ) + " -- MSG: " + 'Create #ibhdr'

	INSERT INTO #ibhdr (	flag,		detail_journal_ctrl_num, 	timestamp, 	id, 
					trx_ctrl_num, 	date_entered, 			date_applied, 	trx_type,
					controlling_org_id, 		detail_org_id, 	amount, 	currency_code, 
					tax_code, 			doc_description, 		create_date, 
					create_username, 		last_change_date, 		last_change_username,
					external_flag,			source_document,	source_line
					, rate_type_home, rate_type_oper)
	SELECT 			0, 		substring(link1,1,16), 				NULL, 		id, 			
					substring(link1,1,16),    	date_entered, 		date_applied, trx_type, 			
					controlling_org_id, 		detail_org_id, 	amount , 	currency_code, 
					tax_code, 			'Inter-Organization transaction', GETDATE(), 
					username, 			GETDATE(), 			username,
					external_flag,			source_document,	source_line 
					, i.rate_type_home, i.rate_type_oper
	FROM #ibio i WHERE state_flag <> -1
	

	







	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 611, 5 ) + " -- MSG: " + 'Assign trx_ctrl_num'

	INSERT INTO #ibnumber (id, trx_type, trx_ctrl_num)
	SELECT id, trx_type, ''
	FROM #ibhdr
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 617, 5 ) + " -- MSG: " + 'EXEC ibassign_control_numbers_sp'

	EXEC @ret = ibassign_control_numbers_sp @debug_level

	IF @ret <> 0 BEGIN
		SELECT @return_value = -200
		GOTO ibpost_sp_error_exit
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 626, 5 ) + " -- MSG: " + 'UPDATE #ibhdr, setting flag'

	UPDATE #ibhdr SET flag = 1

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 630, 5 ) + " -- MSG: " + 'UPDATE #ibhdr with trx_ctrl_num'

	UPDATE #ibhdr 
	SET trx_ctrl_num = n.trx_ctrl_num, flag = 0
	FROM #ibhdr h, #ibnumber n
	WHERE h.id = n.id
	AND  (DATALENGTH(ISNULL(RTRIM(LTRIM(n.trx_ctrl_num)),0))<>0) 

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 638, 5 ) + " -- MSG: " + 'Record errors from generating trx_ctrl_num'

	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	SELECT id, 10030, '', '', 0, 0.0, '','',''
	FROM #ibhdr
	WHERE flag = 1
		

	




	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 651, 5 ) + " -- MSG: " + 'Create tables for tax handling'

	
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
create index #TLI_1 on #TxLineInput( control_number, reference_number)

	
CREATE TABLE #TxInfo
(
	control_number		varchar(16),
	sequence_id		int,
	tax_type_code		varchar(8),
	amt_taxable			float,
	amt_gross			float,
	amt_tax				float,
	amt_final_tax		float,
	currency_code		varchar(8),
	tax_included_flag	smallint

)
create index #TI_1 on #TxInfo( control_number, sequence_id)

	
CREATE TABLE #TxLineTax
(
	control_number		varchar(16),
	reference_number	int,
	tax_amount			float,
	tax_included_flag	smallint
)

	
	CREATE TABLE #txdetail
	(
		control_number	varchar(16),
		reference_number	int,
		tax_type_code		varchar(8),
		amt_taxable		float
	)


	CREATE TABLE #txinfo_id
	(
		id_col			numeric identity,
		control_number	varchar(16),
		sequence_id		int,
		tax_type_code		varchar(8),
		currency_code		varchar(8)
	)


	CREATE TABLE #TXInfo_min_id (control_number varchar(16),min_id_col numeric)


	CREATE TABLE	#TxTLD
	(
		control_number	varchar(16),
		tax_type_code		varchar(8),
		tax_code		varchar(8),
		currency_code		varchar(8),
		tax_included_flag	smallint,
		base_id		int,
		amt_taxable		float,		
		amt_gross		float		
	)


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 658, 5 ) + " -- MSG: " + 'Populate tax information into #TxLineInput'	

	INSERT INTO #TxLineInput (control_number, reference_number, tax_code,	quantity,	extended_price,   discount_amount,
                              	tax_type,       currency_code)
	SELECT 			hdr.trx_ctrl_num, 	0, 		hdr.tax_code,                  1,  	ABS(hdr.amount), 
				0.0,             0, hdr.currency_code
	FROM 	#ibhdr hdr 
	WHERE	tax_code != ''

	SELECT @tax_exists = @@ROWCOUNT
	
	
	
	CREATE TABLE #txconnhdrinput 
	(
		doccode	varchar(16),
		doctype	smallint,
		trx_type smallint,
		companycode 	varchar(25),
		docdate 	datetime,
		exemptionno 	varchar(20),
		salespersoncode varchar(20),
		discount 	float,		
		purchaseorderno varchar(20),
		customercode 	varchar(20),
		customerusagetype varchar(20) ,
		detaillevel 	varchar(20) ,
		referencecode 	varchar(20) ,
		oriaddressline1	varchar(40),
		oriaddressline2	varchar(40),
		oriaddressline3	varchar(40),
		oricity	varchar(40),
		oriregion	varchar(40),
		oripostalcode	varchar(40),
		oricountry	varchar(40),
		destaddressline1 varchar(40),
		destaddressline2 varchar(40),
		destaddressline3 varchar(40),
		destcity	varchar(40),
		destregion	varchar(40),
		destpostalcode	varchar(40),
		destcountry	varchar(40),
		currCode varchar(8),
		currRate decimal(20,8),
		currRateDate datetime null,
		locCode varchar(20) null,
		paymentDt datetime null,
		taxOverrideReason varchar(100) null,
		taxOverrideAmt decimal(20,8) null,
		taxOverrideDate datetime null,
		taxOverrideType int null,
		commitInd int null		
	)

	CREATE INDEX TCHI_1 on #txconnhdrinput( doctype, doccode)
	CREATE INDEX TCHI_2 on #txconnhdrinput( doccode)

	
	CREATE TABLE #txconnlineinput 
	(
		doccode varchar(16),
		no	varchar(20),
		oriaddressline1	varchar(40),
		oriaddressline2	varchar(40),
		oriaddressline3	varchar(40),
		oricity	varchar(40),
		oriregion	varchar(40),
		oripostalcode	varchar(40),
		oricountry	varchar(40),
		destaddressline1	varchar(40),
		destaddressline2	varchar(40),
		destaddressline3	varchar(40),
		destcity	varchar(40),
		destregion	varchar(40),
		destpostalcode	varchar(40),
		destcountry	varchar(40),
		qty	float,		
		amount	float,		
		discounted	smallint, 
		exemptionno	varchar(20),
		itemcode	varchar(40) ,
		ref1	varchar(20) ,
		ref2	varchar(20) ,
		revacct	varchar(20) ,
		taxcode	varchar(8),
		customerUsageType varchar(20) null,
		description varchar(255) null,
		taxIncluded int null,
		taxOverrideReason varchar(100) null,
		taxOverrideTaxAmount decimal(20,8) null,
		taxOverrideTaxDate datetime null,
		taxOverrideType int null
	)

	create index TCLI_1 on #txconnlineinput( doccode, no)




	insert #txconnhdrinput
	(doccode, doctype, trx_type, companycode, docdate, exemptionno, salespersoncode,
	discount, purchaseorderno, customercode, customerusagetype, detaillevel,
	referencecode, oriaddressline1, oriaddressline2, oriaddressline3,
	oricity, oriregion, oripostalcode, oricountry, destaddressline1,
	destaddressline2, destaddressline3, destcity, destregion, destpostalcode,
	destcountry)
	select trx_ctrl_num, 0, trx_type, '', getdate(), '', '',
	0, '', '', '', 3,
	'', '', '', '',
	'', '', '', '', '',
	'', '', '', '', '',
	''
	from #ibhdr

	
	
	



	IF  @tax_exists != 0
	BEGIN
 		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 698, 5 ) + " -- MSG: " + 'Calculate tax TXCalculateTax_SP'	
	
		EXEC TXCalculateTax_SP
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 702, 5 ) + " -- MSG: " + 'Load tax information into #ibtax'
	
		INSERT INTO #ibtax (flag, timestamp, id, sequence_id, tax_type_code, amt_gross, amt_taxable, amt_tax, create_date, create_username, last_change_date,last_change_username, last_change_userid, nat_cur_code, balance_oper, rate_oper, oper_currency, rate_type_oper, balance_home, rate_home, home_currency, rate_type_home)
		SELECT 			0, NULL,  h.id, i.sequence_id, i.tax_type_code, (i.amt_gross * SIGN(h.amount)), (i.amt_taxable * SIGN(h.amount)), (i.amt_tax * SIGN(h.amount)), GETDATE(), @username, GETDATE(),@username,  @userid, i.currency_code, 0.0, 0.0, @oper_currency, h.rate_type_oper , 0.0, 0.0, @home_currency, h.rate_type_home 
		FROM #TxInfo i, #ibhdr h
		WHERE i.control_number = h.trx_ctrl_num

		
		DELETE #ibtax WHERE amt_tax = 0.0

		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 712, 5 ) + " -- MSG: " + 'Load rate table for tax home conversion'
	
		
		IF @external_post > 0		
		BEGIN
			DELETE #rates

			INSERT INTO #rates (from_currency, to_currency, rate_type, date_applied, rate)
			SELECT DISTINCT d.nat_cur_code, home_currency, d.rate_type_home, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, 0.0
			FROM #ibhdr h, #ibtax d
			WHERE h.id = d.id
	
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 724, 5 ) + " -- MSG: " + 'EXEC mcrates_sp for tax home conversion '
	
			EXEC @ret = CVO_Control..mcrates_sp
	
			IF @ret <> 0 
			BEGIN
				SELECT @return_value = -210
				GOTO ibpost_sp_error_exit
			END
			
		END
		ELSE
		BEGIN

			DELETE #rates_w_journal	

			INSERT INTO #rates_w_journal (from_currency, to_currency, rate_type, date_applied, rate, journal_ctrl_num, source_line)  
			SELECT DISTINCT d.nat_cur_code, home_currency, d.rate_type_home, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, g.rate, 
			h.detail_journal_ctrl_num, g.sequence_id
			FROM #ibhdr h, #ibtax d, #gltrxdet g 
			WHERE h.id = d.id  
			AND h.detail_journal_ctrl_num = g.journal_ctrl_num -- Rev 4.1
	
		END
	
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 749, 5 ) + " -- MSG: " + 'Set flag to 1 for tax HOME conversion'		
			
		UPDATE #ibtax SET flag = 1
				
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 753, 5 ) + " -- MSG: " + 'Apply currency rates to details 1 for tax home conversion '		
			
		
		IF @external_post > 0		
		BEGIN
			
			UPDATE #ibtax 
			SET 	rate_home = r.rate, 
				balance_home = CASE WHEN r.rate < 0.0 THEN  amt_tax / ABS(r.rate) ELSE  amt_tax * ABS(r.rate) END, 
				flag = 0, 
				rate_type_home = r.rate_type	
			FROM #ibtax d, #rates r, #ibhdr h
			WHERE d.nat_cur_code = r.from_currency
			AND DATEDIFF(DD,'1/1/80', h.date_applied)+722815 = r.date_applied
			AND d.id = h.id
	
		END
		ELSE
		BEGIN
			UPDATE #ibtax 
			SET 	rate_home = r.rate, 
				balance_home = CASE WHEN r.rate < 0.0 THEN  amt_tax / ABS(r.rate) ELSE  amt_tax * ABS(r.rate) END,	
				flag = 0, 
				rate_type_home = r.rate_type			
			FROM #ibtax d, #rates_w_journal r, #ibhdr h  
			WHERE d.nat_cur_code = r.from_currency  
			AND DATEDIFF(DD,'1/1/80', h.date_applied)+722815 = r.date_applied  
			AND d.id = h.id  
			AND h.detail_journal_ctrl_num = r.journal_ctrl_num
			AND r.source_line = h.source_line			-- Rev 4.1
		END
		
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 786, 5 ) + " -- MSG: " + 'Register errors encountered during tax currency translation'	
			
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		SELECT d.id, 10020, d.nat_cur_code, d.home_currency, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, 0.0, '','',''
		FROM #ibtax d, #ibhdr h
		WHERE d.flag = 1
		AND d.id = h.id
	

		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 795, 5 ) + " -- MSG: " + 'Load rate table for tax Oper conversion'		
		
		IF @external_post > 0				
		BEGIN		
			DELETE #rates

			INSERT INTO #rates (from_currency, to_currency, rate_type, date_applied, rate)
			SELECT DISTINCT d.nat_cur_code, oper_currency, d.rate_type_oper, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, 0.0
			FROM #ibhdr h, #ibtax d
			WHERE h.id = d.id
	
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 806, 5 ) + " -- MSG: " + 'EXEC mcrates_sp for tax oper conversion'
			
			EXEC @ret = CVO_Control..mcrates_sp
	
			IF @ret <> 0 
			BEGIN
				SELECT @return_value = -210
				GOTO ibpost_sp_error_exit
			END
		END
		ELSE
		BEGIN
			DELETE #rates_w_journal
		
			INSERT INTO #rates_w_journal (from_currency, to_currency, rate_type, date_applied, rate, journal_ctrl_num, source_line)  
			SELECT DISTINCT d.nat_cur_code, oper_currency, d.rate_type_oper, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, g.rate_oper, h.detail_journal_ctrl_num, g.sequence_id
			FROM #ibhdr h, #ibtax d, #gltrxdet g  
			WHERE h.id = d.id  
			AND h.detail_journal_ctrl_num = g.journal_ctrl_num -- Rev 4.1
	
		END		
			
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 828, 5 ) + " -- MSG: " + 'Set flag to 1 for tax oper conversion'
			
		UPDATE #ibtax SET flag = 1
	
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 832, 5 ) + " -- MSG: " + 'Apply currency rates to details 1 for tax oper conversion'		
			
		
		IF @external_post > 0				
		BEGIN
			
			 UPDATE #ibtax 
			 SET 	rate_oper = r.rate, 
				balance_oper = CASE WHEN r.rate < 0.0 THEN  amt_tax / ABS(r.rate) ELSE  amt_tax * ABS(r.rate) END, 
				flag = 0, 
				rate_type_oper = r.rate_type	
			 FROM #ibtax d, #rates r, #ibhdr h
			 WHERE d.nat_cur_code = r.from_currency
			 	AND DATEDIFF(DD,'1/1/80', h.date_applied)+722815 = r.date_applied
				AND d.id = h.id
	
		END
		ELSE
		BEGIN
			UPDATE #ibtax 
			SET 	rate_oper = r.rate, 
				balance_oper = CASE WHEN r.rate < 0.0 THEN  amt_tax / ABS(r.rate) ELSE  amt_tax * ABS(r.rate) END,
				flag = 0,
				rate_type_oper = r.rate_type	
			FROM #ibtax d, #rates_w_journal r, #ibhdr h
			 WHERE d.nat_cur_code = r.from_currency
			       AND DATEDIFF(DD,'1/1/80', h.date_applied)+722815 = r.date_applied
			       AND d.id = h.id
			       AND h.detail_journal_ctrl_num = r.journal_ctrl_num	
			       AND r.source_line = h.source_line	-- Rev 4.1
			
		END
	
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 865, 5 ) + " -- MSG: " + 'Register errors encountered during currency translation'		
			
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		SELECT d.id, 10020, d.nat_cur_code, d.oper_currency, DATEDIFF (DD,'1/1/80', h.date_applied)+722815, 0.0, '','',''
		FROM #ibtax d, #ibhdr h
		WHERE d.flag = 1
		AND d.id = h.id
	
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 873, 5 ) + " -- MSG: " + 'Flag records in #ibhdr where an error has occurred'		
			
		UPDATE #ibhdr SET flag = 0
				
		UPDATE #ibhdr 
		SET flag = 1
		FROM #ibhdr i, #iberror e
		WHERE i.id = e.id
				
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 882, 5 ) + " -- MSG: " + 'Flag records in #ibtax where an error has occurred'		
			
		UPDATE #ibtax SET flag = 0
			
		UPDATE #ibtax 
		SET flag = 1
		FROM #ibtax i, #iberror e
		WHERE i.id = e.id
				
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 891, 5 ) + " -- MSG: " + 'Calculate Tax for the lines'	
	
		SELECT t.id, ROUND( SUM(t.amt_tax), @precision_gl) amt_tax 
		INTO #ibtaxtemp  
		FROM #ibtax t 
		GROUP BY (t.id) 
	
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 898, 5 ) + " -- MSG: " + 'Take the account codes from artrxtype '
	
		
		SELECT 		t.id, 			t.tax_type_code, 	
			CASE WHEN i.external_flag = 0 	THEN 
					CASE WHEN t.amt_tax >= 0 THEN
						dbo.IBAcctMask_fn(a.gl_internal_tax_account, i.detail_org_id)
					ELSE
						dbo.IBAcctMask_fn(a.sales_tax_acct_code, i.detail_org_id)
					END					  	
				ELSE 
					CASE WHEN t.amt_tax >= 0 THEN
						dbo.IBAcctMask_fn(a.gl_internal_tax_account, dbo.IBOrgbyAcct_fn(i.recipient_code)) 
					ELSE
						dbo.IBAcctMask_fn(a.sales_tax_acct_code, dbo.IBOrgbyAcct_fn(i.recipient_code)) 
					END		
				END as account_code, 
				ROUND( t.amt_tax, @precision_gl) amt_tax , 		CONVERT(int,2) as sequence_id, 
				CONVERT(int,0) state_flag, i.external_flag external_flag
		INTO #ibtaxtdetail
		FROM #ibtax t
			INNER JOIN #ibio i
					 ON t.id = i.id
			INNER JOIN artxtype a
					ON t.tax_type_code = a.tax_type_code
		ORDER BY t.id
			
		CREATE CLUSTERED INDEX ibtaxtdetail_temp_1	 		ON #ibtaxtdetail (id)
	
	
		INSERT INTO  #ibtaxtdetail	(id, tax_type_code, account_code,
						amt_tax, sequence_id, state_flag, external_flag)
		SELECT 		t.id, 			t.tax_type_code, 	
			CASE WHEN i.external_flag = 0 	THEN 
					CASE WHEN ( t.amt_tax  * -1 ) >= 0 THEN
	
						dbo.IBAcctMask_fn(a.gl_internal_tax_account,i.controlling_org_id )
					ELSE
						dbo.IBAcctMask_fn(a.sales_tax_acct_code,i.controlling_org_id )
					END					  	
				ELSE 
					CASE WHEN (t.amt_tax *-1) >= 0 THEN
						dbo.IBAcctMask_fn(a.gl_internal_tax_account, dbo.IBOrgbyAcct_fn(i.recipient_code)) 
					ELSE
						dbo.IBAcctMask_fn(a.sales_tax_acct_code, dbo.IBOrgbyAcct_fn(i.recipient_code)) 
					END		
				END, 
				ROUND( t.amt_tax, @precision_gl) * -1 , 		CONVERT(int,2) , 
				CONVERT(int,0), i.external_flag
		FROM #ibtax t
			INNER JOIN #ibio i
				 ON t.id = i.id
			INNER JOIN artxtype a
				ON t.tax_type_code = a.tax_type_code
		ORDER BY t.id
	
		
		
		SELECT @sequence_id =2
		
		UPDATE #ibtaxtdetail 
		SET sequence_id = @sequence_id,
		    @sequence_id = CASE WHEN id <> @id THEN 3 ELSE  @sequence_id +1 END,
		    @id = id
		WHERE external_flag = 0
		
		SELECT @sequence_id =4
		
		UPDATE #ibtaxtdetail 
		SET sequence_id = @sequence_id,
		    @sequence_id = CASE WHEN id <> @id THEN 5 ELSE  @sequence_id +1 END,
		    @id = id
		WHERE external_flag = 1
		
		



		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 976, 5 ) + " -- MSG: " + 'Create #ibdet Tax 2'
		
		INSERT INTO #ibdet (	flag, 		timestamp, 	id, 		sequence_id, 	org_id, 
					amount, 	currency_code, 		doc_description, 	account_code, 
					reconciled_flag, 	create_date, 	create_username, 	last_change_date, 
					last_change_username, 	reference_code, balance_oper, 		rate_oper, 
					oper_currency, 		rate_type_oper, balance_home, 		rate_home, 
					home_currency, 		rate_type_home)
		SELECT 			0, 		NULL, 		i.id, 		t.sequence_id, 		 dbo.IBOrgbyAcct_fn(t.account_code)  , 
					t.amt_tax , 	currency_code, 	convert(varchar(40),'Inter-Organization GL Tax -' +tax_type_code), 	t.account_code,
					0, 			GETDATE(), 	@username, 		GETDATE(), 
					@username, 		reference_code, 0.0, 		0.0, 
					@oper_currency, 	i.rate_type_oper , 0.0, 	0.0, 		@home_currency, 
					i.rate_type_home 
		FROM #ibio i 
		 	INNER JOIN #ibtaxtdetail t
				ON i.id = t.id
			
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 994, 5 ) + " -- MSG: " + 'Update IB Hdr Amount'
		
		UPDATE #ibhdr
		SET amount = ABS(h.amount) + ABS(t.amt_tax)
		FROM #ibhdr h
		  	INNER JOIN #ibtaxtemp t
				ON h.id = t.id
	
		UPDATE #ibio
		SET amount = (ABS(h.amount) + ABS(t.amt_tax) ) * SIGN(h.amount)
		FROM   #ibio h
		  	INNER JOIN #ibtaxtemp t
				ON h.id = t.id 


	END 	
	






	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1017, 5 ) + " -- MSG: " + 'Insert Details for Interbanch transactions'
	
	
		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1021, 5 ) + " -- MSG: " + 'Create #ibdet 1'

	INSERT INTO #ibdet (	flag, 		timestamp, 	id, 		sequence_id, 	org_id, 
				amount, 	currency_code, 		doc_description, 	account_code, 
				reconciled_flag, 	create_date, 	create_username, 	last_change_date, 
				last_change_username, 	reference_code, balance_oper, 		rate_oper, 
				oper_currency, 		rate_type_oper, balance_home, 		rate_home, 
				home_currency, 		rate_type_home)
	SELECT 			0, 		NULL, 		id, 		1, 		CASE WHEN external_flag = 1 THEN dbo.IBOrgbyAcct_fn(recipient_code)  ELSE detail_org_id END, 
				amount * -1, 	currency_code, 	'Inter-Organization GL', 	recipient_code,
				0, 			GETDATE(), 	@username, 		GETDATE(), 
				@username, 		reference_code, 0.0, 		0.0, 
				@oper_currency, 	#ibio.rate_type_oper , 0.0, 	0.0, 		@home_currency, 
				#ibio.rate_type_home 
	FROM #ibio 
			
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1038, 5 ) + " -- MSG: " + 'Create #ibdet 2'	
		
	INSERT INTO #ibdet (	flag, 		timestamp, 	id, 		sequence_id, 	org_id, 
				amount, 	currency_code, 		doc_description, 	account_code, 
				reconciled_flag, 	create_date, 	create_username, 	last_change_date, 
				last_change_username, 	reference_code, balance_oper, 		rate_oper, 
				oper_currency, 		rate_type_oper, balance_home, 		rate_home, 
				home_currency, 		rate_type_home)
	SELECT 			0, 		NULL, 		id, 		2, 		CASE WHEN external_flag = 1 THEN dbo.IBOrgbyAcct_fn(originator_code)  ELSE  controlling_org_id END, 
				amount, 	currency_code, 	'Inter-Organization GL', 	originator_code,
				0, 			GETDATE(), 	@username, 		GETDATE(), 
				@username, 		reference_code, 0.0, 		0.0, 
				@oper_currency, 	#ibio.rate_type_oper , 0.0, 	0.0, 		@home_currency, 
				#ibio.rate_type_home 
	FROM #ibio
		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1055, 5 ) + " -- MSG: " + 'External  Transactions -- Create #ibdet 3'
	

	IF @external_post > 0				
	BEGIN
			
		INSERT INTO #ibdet (	flag, 		timestamp, 	id, 		sequence_id, 	org_id, 
					amount, 	currency_code, 		doc_description, 	account_code, 
					reconciled_flag, 	create_date, 	create_username, 	last_change_date, 
					last_change_username, 	reference_code, balance_oper, 		rate_oper, 
					oper_currency, 		rate_type_oper, balance_home, 		rate_home, 
					home_currency, 		rate_type_home)
		SELECT 			0, 		NULL, 		id, 		3, 		dbo.IBOrgbyAcct_fn(tax_expense_code), 
					amount * -1, 	currency_code, 	'Inter-Organization GL', 	tax_expense_code,
					0, 			GETDATE(), 	@username, 		GETDATE(), 
					@username, 		reference_code, 0.0, 		0.0, 
					@oper_currency, 	rate_type_oper , 0.0, 	0.0, 		@home_currency, 
					rate_type_home 
		FROM #ibio 
		WHERE external_flag = 1 -- 2005 Just External transactions
				
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1076, 5 ) + " -- MSG: " + 'Create #ibdet 4'	
			
		INSERT INTO #ibdet (	flag, 		timestamp, 	id, 		sequence_id, 	org_id, 
					amount, 	currency_code, 		doc_description, 	account_code, 
					reconciled_flag, 	create_date, 	create_username, 	last_change_date, 
					last_change_username, 	reference_code, balance_oper, 		rate_oper, 
					oper_currency, 		rate_type_oper, balance_home, 		rate_home, 
					home_currency, 		rate_type_home)
		SELECT 			0, 		NULL, 		id, 		4, 		dbo.IBOrgbyAcct_fn(tax_payable_code), 
					amount, 	currency_code, 	'Inter-Organization GL', 	tax_payable_code,
					0, 			GETDATE(), 	@username, 		GETDATE(), 
					@username, 		reference_code, 0.0, 		0.0, 
					@oper_currency, 	rate_type_oper , 0.0, 	0.0, 		@home_currency, 
					rate_type_home 
		FROM #ibio
			WHERE external_flag = 1 -- 2005 Just External transactions

	END 
	
		
	IF @tax_exists != 0
	BEGIN
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1099, 5 ) + " -- MSG: " + 'EXEC ibvalidateptax_sp'
			
		EXEC ibvalidateptax_sp @debug_level
		
		INSERT INTO #ewerror (  module_id, 	err_code,  	info1,  	info2, 
					 infoint,  	infofloat,  	flag1,  	trx_ctrl_num,  
					 sequence_id,  	source_ctrl_num, 	extra )  
		SELECT DISTINCT 	6000,  		error_code,  	info1,  	info2,  
					infoint,  	infodecimal,  		0,  	CASE WHEN b.external_flag = 0 THEN  b.link1 ELSE substring(convert(varchar,b.link3)+'-'+convert(varchar,b.trx_type),1,16) END,  
						CASE WHEN external_flag = 0 THEN e.link2 ELSE -1 END,  	' ', 	 1
		FROM #iberror e
				INNER JOIN  #ibio b
						ON e.id = b.id	
		WHERE e.error_code IN (213,222,280)
				
		DROP TABLE #ibtaxtemp
		DROP TABLE #ibtaxtdetail

	END --jgt aqui		

	











	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1131, 5 ) + " -- MSG: " + 'Load rate table for home conversion'
		
	
	IF @external_post > 0				
	BEGIN
		DELETE #rates
	
		INSERT INTO #rates (from_currency, to_currency, rate_type, date_applied, rate)
		SELECT DISTINCT d.currency_code, home_currency, h.rate_type_home, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, 0.0
		FROM #ibhdr h, #ibdet d
		WHERE h.id = d.id
			
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1143, 5 ) + " -- MSG: " + 'EXEC mcrates_sp for home conversion'	
			
		EXEC @ret = CVO_Control..mcrates_sp
		 
		IF @ret <> 0 
		BEGIN
			SELECT @return_value = -210
			GOTO ibpost_sp_error_exit

	END
	END
	ELSE
	BEGIN

		DELETE #rates_w_journal
		
		INSERT INTO #rates_w_journal(from_currency, to_currency, rate_type, date_applied, rate, journal_ctrl_num, source_line)  
		SELECT DISTINCT d.currency_code, home_currency, d.rate_type_home, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, g.rate, h.detail_journal_ctrl_num, g.sequence_id
		FROM #ibhdr h, #ibdet d, #gltrxdet g  
		WHERE h.id = d.id  
		AND h.detail_journal_ctrl_num = g.journal_ctrl_num	-- Rev 4.1
		
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1167, 5 ) + " -- MSG: " + 'Set flag to 1 for HOME conversion'
	
	UPDATE #ibdet SET flag = 1
		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1171, 5 ) + " -- MSG: " + 'Apply currency rates to details 1 for home conversion'		
	
	
	IF @external_post > 0				
	BEGIN
		UPDATE #ibdet 
		SET 	rate_home = r.rate, 
			balance_home = CASE WHEN r.rate < 0.0 THEN  d.amount / ABS(r.rate) ELSE  d.amount * ABS(r.rate) END,
			flag = 0, 
			rate_type_home = r.rate_type	
		FROM #ibdet d, #rates r, #ibhdr h
		WHERE d.currency_code = r.from_currency
		       AND DATEDIFF(DD,'1/1/80', h.date_applied)+722815 = r.date_applied
		       AND d.id = h.id

	END
	ELSE
	BEGIN
		UPDATE #ibdet 
		SET 	rate_home = r.rate, 
			balance_home = CASE WHEN r.rate < 0.0 THEN  d.amount / ABS(r.rate) ELSE  d.amount * ABS(r.rate) END,
			flag = 0, 
			rate_type_home = r.rate_type	
		FROM #ibdet d, #rates_w_journal r, #ibhdr h  
		WHERE d.currency_code = r.from_currency  
        	AND DATEDIFF(DD,'1/1/80', h.date_applied)+722815 = r.date_applied  
        	AND d.id = h.id  
		AND h.detail_journal_ctrl_num = r.journal_ctrl_num
		AND r.source_line = h.source_line	-- Rev 4.1
	END
        

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1203, 5 ) + " -- MSG: " + 'Register errors encountered during currency translation'	
	
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	SELECT d.id, 10020, d.currency_code, d.home_currency, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, 0.0, '','',''
	FROM #ibdet d, #ibhdr h
	WHERE d.flag = 1
	AND d.id = h.id
		

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1212, 5 ) + " -- MSG: " + 'Load rate table for oper conversion'	

	
	IF @external_post > 0				
	BEGIN
		DELETE #rates

		INSERT INTO #rates (from_currency, to_currency, rate_type, date_applied, rate)
		  SELECT DISTINCT d.currency_code, oper_currency, d.rate_type_oper, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, 0.0
		     FROM #ibhdr h, #ibdet d
		  WHERE h.id = d.id
		
		EXEC @ret = CVO_Control..mcrates_sp
		 
		IF @ret <> 0 BEGIN
			SELECT @return_value = -210
			GOTO ibpost_sp_error_exit
		END
	END
	ELSE
	BEGIN
		DELETE #rates_w_journal

		INSERT INTO #rates_w_journal (from_currency, to_currency, rate_type, date_applied, rate, journal_ctrl_num, source_line)  
		SELECT DISTINCT d.currency_code, oper_currency, d.rate_type_oper, DATEDIFF(DD,'1/1/80', h.date_applied)+722815, g.rate_oper, h.detail_journal_ctrl_num ,g.sequence_id
		FROM #ibhdr h, #ibdet d, #gltrxdet g  
		WHERE h.id = d.id  
		AND h.detail_journal_ctrl_num = g.journal_ctrl_num	  -- Rev 4.1
		
	END	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1243, 5 ) + " -- MSG: " + 'Set flag to 1 for oper conversion'
	
	UPDATE #ibdet SET flag = 1
		
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1247, 5 ) + " -- MSG: " + 'Apply currency rates to details 1 for oper conversion'	
	
	
	IF @external_post > 0				
	BEGIN		
		UPDATE #ibdet 
		SET 	rate_oper = r.rate, 
			balance_oper = CASE WHEN r.rate < 0.0 THEN  d.amount / ABS(r.rate) ELSE  d.amount * ABS(r.rate) END,
			flag = 0, 
			rate_type_oper = r.rate_type	
		FROM #ibdet d, #rates r, #ibhdr h
		WHERE d.currency_code = r.from_currency
		       AND DATEDIFF(DD,'1/1/80', h.date_applied)+722815 = r.date_applied
		       AND d.id = h.id

	END
	ELSE
	BEGIN
		UPDATE #ibdet 
		SET 	rate_oper = r.rate, 
			balance_oper = CASE WHEN r.rate < 0.0 THEN  d.amount / ABS(r.rate) ELSE  d.amount * ABS(r.rate) END,
			flag = 0, 
			rate_type_oper = r.rate_type	
		FROM #ibdet d, #rates_w_journal r, #ibhdr h  
		WHERE d.currency_code = r.from_currency  
		        AND DATEDIFF(DD,'1/1/80', h.date_applied)+722815 = r.date_applied  
		        AND d.id = h.id  
		        AND h.detail_journal_ctrl_num = r.journal_ctrl_num
			AND r.source_line = h.source_line	-- Rev 4.1
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1278, 5 ) + " -- MSG: " + 'Register errors encountered during currency translation'	
	
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	SELECT d.id, 10020, d.currency_code, d.oper_currency, DATEDIFF (DD,'1/1/80', h.date_applied)+722815, 0.0, '','',''
	FROM #ibdet d, #ibhdr h
	WHERE d.flag = 1
	AND d.id = h.id
		
	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1289, 5 ) + " -- MSG: " + 'Loop to create GL Headers'

	SELECT 	@trx_ctrl_num = '',
		@init_mode = 0,
		@module_id = 6000,
		@val_mode = 2,
		@reccuring_flag = 0,
		@repeatng_flag = 0,
		@reversing_flag = 0,
		@source_batch_code = '',
		@type_flag = 0,
		@journal_description = 'Interbranch transaction',
		@hold_flag = 0,
		@interface_mode = 2

	SELECT	@journal_type = ib_journal_type
	FROM glco

	
	IF ( @external_post > 0 )
	BEGIN 
		WHILE (1=1)		
		BEGIN
			SET ROWCOUNT 1
			SELECT 		@id = id,
					@date_entered = DATEDIFF(DD,'1/1/80',date_entered)+722815,
					@date_applied = DATEDIFF(DD,'1/1/80',date_applied)+722815,
					@document_1 = trx_ctrl_num,
					@trx_type = trx_type,
					@controlling_org_id = controlling_org_id,
					@detail_org_id = detail_org_id,
					@journal_description = detail_journal_ctrl_num,
					@journal_ctrl_num = detail_journal_ctrl_num,
					@trx_ctrl_num = trx_ctrl_num,
					@external_flag = external_flag
			FROM  #ibhdr
			WHERE  trx_ctrl_num > @trx_ctrl_num
			AND flag = 0
			ORDER BY trx_ctrl_num	

			SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

			SET ROWCOUNT 0
			IF @rowcount = 0 
			BEGIN 
				BREAK
			END


			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1338, 5 ) + " -- MSG: " + 'Override the trx_type to 111 (Staandard Journal Entry ) for external transactions '
			
			SELECT @controlling_journal_ctrl_num = ''
					
			SELECT @journal_description =  SUBSTRING ('IO Trx From : Trx Type ' + CONVERT(varchar, @trx_type),1,30)
			SELECT  @trx_type = 111

			


			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1348, 5 ) + " -- MSG: " + 'Generate a new journal_ctrl_num for external transactions'

			EXEC @ret = gltrxcrh_sp @process_ctrl_num,
								   @init_mode,
								   @module_id,
								   @val_mode, 
								   @journal_type,
								   @controlling_journal_ctrl_num OUTPUT, 
								   @journal_description,
								   @date_entered,
								   @date_applied,            
								   @reccuring_flag,
								   @repeatng_flag,
								   @reversing_flag,
								   @source_batch_code,
								   @type_flag, 
								   @company_code,
								   @company_code, 
								   @home_currency,
								   @document_1,
								   @trx_type,
								   @userid,
								   @hold_flag,
								   @oper_currency,
								   @debug_level,
					   @controlling_org_id,
					   2
				
			IF @ret <> 0 
			BEGIN
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				SELECT hd.id, @ret, @controlling_journal_ctrl_num, @trx_ctrl_num, 0, 0.0, '','',''
				FROM #ibhdr hd
				WHERE hd.id = @trx_ctrl_num

				CONTINUE
			END

			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1386, 5 ) + " -- MSG: " + 'Record controlling journal_ctrl_num in ibhdr'
			
			UPDATE #ibhdr
		        SET controlling_journal_ctrl_num = @controlling_journal_ctrl_num
			WHERE id = @id
			
			

 
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1395, 5 ) + " -- MSG: " + 'Create GL transactions details.'
			SELECT @seq_ref_id = 0
			WHILE (1=1)
			BEGIN
		
				SET ROWCOUNT 1
				SELECT @seq_ref_id = sequence_id,
								@account_code = account_code,
								@description = doc_description,
								@document_1 = @trx_ctrl_num,
								@document_2 = @controlling_journal_ctrl_num,
								@reference_code = reference_code,
								@balance = balance_home,
								@nat_balance = amount,
								@nat_cur_code = currency_code,
								@rate = rate_home,
								@trx_type = @trx_type,		
								@seq_ref_id = sequence_id,	
								@rate_oper = rate_oper,
								@balance_oper = balance_oper,
								@rate_type_home = rate_type_home,
								@rate_type_oper = rate_type_oper,
								@org_id = org_id
				FROM #ibdet
				WHERE id = @id
				AND sequence_id > @seq_ref_id
				AND flag = 0
				ORDER BY id, sequence_id

				SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
			
				SET ROWCOUNT 0
				IF @rowcount = 0 
				BEGIN
					BREAK
				END

			        EXEC @ret = gltrxcrd_sp @module_id,   
					                                       @interface_mode,
					                                       @controlling_journal_ctrl_num,
					                                       @seq_ref_id,          
					                                       @company_code,  
					                                       @account_code, 
					                                       @description,   
					                                       @document_1,
					                                       @document_2,
					                                       @reference_code,
					                                       @balance,          
					                                       @nat_balance,    
					                                       @nat_cur_code,     
					                                       @rate,    
					                                       @trx_type,
					                                       @seq_ref_id,
					                                       @balance_oper,
					                                       @rate_oper,
					                                       @rate_type_home,
					                                       @rate_type_oper,
					                                       @debug_level,
									       @org_id
						
				IF @ret <> 0 
				BEGIN
					INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
					SELECT @id, @ret, @controlling_journal_ctrl_num, @trx_ctrl_num, @sequence_id, 0.0, '','',''
					CONTINUE
				END
			END

		END	
	END
	ELSE
	BEGIN
		create table #ib_journal_hdr (journal_ctrl_num_x nvarchar(30) NOT NULL, ident int IDENTITY, id_x uniqueidentifier NOT NULL )
		CREATE INDEX #ib_journal_hdr_ind_1 ON #ib_journal_hdr ( journal_ctrl_num_x )
		CREATE INDEX #ib_journal_hdr_ind_2 ON #ib_journal_hdr ( id_x )

		INSERT INTO #ib_journal_hdr ( journal_ctrl_num_x, id_x) SELECT detail_journal_ctrl_num, id
		FROM  #ibhdr
		WHERE flag = 0
		ORDER BY trx_ctrl_num	

		UPDATE #ibhdr
		SET controlling_journal_ctrl_num = detail_journal_ctrl_num + '-'+ cast(#ib_journal_hdr.ident as varchar(10)), 
			sequence_order_ib = #ib_journal_hdr.ident
		FROM #ibhdr, #ib_journal_hdr
		WHERE #ibhdr.id = #ib_journal_hdr.id_x

		INSERT  #gltrx(
					journal_type,           journal_ctrl_num,       journal_description,  
					date_entered,           date_applied,           recurring_flag,
					repeating_flag,         reversing_flag,         hold_flag,              
					posted_flag,            date_posted,            source_batch_code,
					batch_code,             type_flag,              intercompany_flag,
					company_code,           app_id,                 home_cur_code,
					document_1,             trx_type,               user_id,
					source_company_code,    process_group_num,      trx_state,
					next_seq_id,            mark_flag,
					oper_cur_code,		org_id, 		interbranch_flag)
		SELECT @journal_type,         controlling_journal_ctrl_num,       SUBSTRING('IO Trx From :' + detail_journal_ctrl_num,1,30),   
					DATEDIFF(DD,'1/1/80',date_entered)+722815 date_entered,          DATEDIFF(DD,'1/1/80',date_applied)+722815 date_applied,          @reccuring_flag,
					@repeatng_flag,        @reversing_flag,        @hold_flag,
					@init_mode,             0,                      @source_batch_code,
					' ',                    @type_flag,             0,
					@company_code,          @module_id,             @home_currency,
					trx_ctrl_num document_1,            trx_type,              @userid,
					@company_code,   	@process_ctrl_num,      0,
					1,                      0, 
					@oper_currency,		controlling_org_id, 		2
		FROM  #ibhdr
		WHERE flag = 0
		ORDER BY trx_ctrl_num	

		DROP TABLE #ib_journal_hdr

		DECLARE @company_id smallint
		SELECT	@company_id = company_id 
		FROM	glcomp_vw
		WHERE	company_code = @company_code

		INSERT #gltrxdet ( journal_ctrl_num, sequence_id, rec_company_code, company_id , account_code, 
			description, document_1, document_2, reference_code, balance, 
			nat_balance, balance_oper, nat_cur_code, rate, rate_oper,
			rate_type_home, rate_type_oper, posted_flag, date_posted, trx_type, 
			offset_flag, seg1_code, seg2_code, seg3_code, seg4_code,
			seq_ref_id, trx_state, mark_flag, org_id )
		SELECT h.controlling_journal_ctrl_num, d.sequence_id, @company_code, @company_id, d.account_code,
		d.doc_description, h.trx_ctrl_num, h.controlling_journal_ctrl_num, d.reference_code, d.balance_home balance,
		d.amount nat_balance, d.balance_oper, d.currency_code, d.rate_home, d.rate_oper,
		d.rate_type_home, d.rate_type_oper, 0, 0, h.trx_type,
		0, c.seg1_code,  ISNULL( c.seg2_code, ' ' ), ISNULL( c.seg3_code, ' ' ), ISNULL( c.seg4_code, ' ' ),
		d.sequence_id, 0, 0, d.org_id
		FROM #ibdet d, #ibhdr h, glchart c
		WHERE  h.id = d.id
		AND d.flag = 0
		AND c.account_code = d.account_code
		ORDER BY d.id, d.sequence_id
		
		declare @ib_org_id varchar(30)
		SELECT @ib_org_id = (SELECT max(organization_id) FROM Organization WHERE outline_num = '1')

		UPDATE #gltrxdet SET org_id = @ib_org_id
		WHERE org_id is null
		
		
		EXEC glcalcrate_sp
		IF EXISTS (select 1 from #gltrxdet where mark_flag = 1)
			INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
			SELECT h.id, 3022, g.journal_ctrl_num, h.trx_ctrl_num, g.sequence_id, 0.0, '','',''
			FROM #ibhdr h, #gltrxdet g
			WHERE h.controlling_journal_ctrl_num = g.journal_ctrl_num
		

		
		EXEC glacsum_grp_sp @module_id
		
	END 
	
	



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1556, 5 ) + " -- MSG: " + 'INSERT iblink sequence_id 0 entries'

	INSERT INTO #iblink (timestamp, id, sequence_id, trx_type, source_trx_ctrl_num, source_sequence_id, source_url, source_urn, source_id, source_po_no, source_order_no, source_ext, source_line, trx_ctrl_num, org_id, create_date, create_username, last_change_date, last_change_username)
	SELECT NULL, h.id, 0, h.trx_type, h.source_document	, h.source_line	, '', '', 0, '', 0, 0, 0, h.trx_ctrl_num, '', GETDATE(), @username, GETDATE(), @username
	FROM #ibhdr h
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1562, 5 ) + " -- MSG: " + 'INSERT iblink gl link entries - controlling'

	INSERT INTO #iblink (timestamp, id, sequence_id, trx_type, source_trx_ctrl_num, source_sequence_id, source_url, source_urn, source_id, source_po_no, source_order_no, source_ext, source_line, trx_ctrl_num, org_id, create_date, create_username, last_change_date, last_change_username)
	SELECT NULL, h.id, 2, h.trx_type, h.source_document	, h.source_line	, '', '', 0, '', 0, 0, 0, g.journal_ctrl_num, h.controlling_org_id, GETDATE(), @username, GETDATE(), @username
	FROM #ibhdr h, #gltrx g
	WHERE h.trx_ctrl_num = g.document_1
	AND h.controlling_journal_ctrl_num = g.journal_ctrl_num
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1570, 5 ) + " -- MSG: " + 'INSERT iblink gl link entries - detail'

	INSERT INTO #iblink (timestamp, id, sequence_id, trx_type, source_trx_ctrl_num, source_sequence_id , source_url, source_urn, source_id, source_po_no, source_order_no, source_ext, source_line, trx_ctrl_num, org_id, create_date, create_username, last_change_date, last_change_username)
	SELECT NULL, h.id, 3, h.trx_type, h.source_document	, h.source_line	, '', '', 0, '', 0, 0, 0, CASE WHEN h.external_flag =1 THEN g.journal_ctrl_num ELSE h.detail_journal_ctrl_num END, h.detail_org_id, GETDATE(), @username, GETDATE(), @username
	FROM #ibhdr h, #gltrx g
	WHERE h.trx_ctrl_num = g.document_1

	    
	
	
	







	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1588, 5 ) + " -- MSG: " + 'Validate GL Transactions'

	EXEC @ret = gltrxval_sp @company_code,
						   @company_code,
						   NULL,
						   NULL,
						   @debug_level
 
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1596, 5 ) + " -- MSG: " + 'Move errors to #iberror after gltrxval_sp'

	
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	SELECT g.id, t.error_code, t.journal_ctrl_num, g.trx_ctrl_num, t.sequence_id, 0.0, '','',''
	FROM #gltrx h, #trxerror t, #ibhdr g
	WHERE h.journal_ctrl_num = t.journal_ctrl_num
	AND g.controlling_journal_ctrl_num =h.journal_ctrl_num	         
	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1606, 5 ) + " -- MSG: " + 'LOAD details for gledtval_sp'






	INSERT INTO [#gltrxedt1] (journal_ctrl_num,  sequence_id,         journal_description,  
                              journal_type,      date_entered,        date_applied,  
                              batch_code,        hold_flag,           home_cur_code,  
                              intercompany_flag, company_code,        source_batch_code,  
                              type_flag,         user_id,             source_company_code,  
                              account_code,      account_description, rec_company_code,  
                              nat_cur_code,      document_1,          description,  
                              reference_code,    balance,             nat_balance,  
                              trx_type,          offset_flag,         seq_ref_id,  
                              temp_flag,         spid,                oper_cur_code,  
                              balance_oper,      db_name,		controlling_org_id,	
				detail_org_id, interbranch_flag)  					
	SELECT h.journal_ctrl_num,  d.sequence_id,     h.journal_description,
                   h.journal_type,      h.date_entered,    h.date_applied,
                   h.batch_code,        h.hold_flag,       h.home_cur_code,  
                   h.intercompany_flag, h.company_code,    h.source_batch_code,
                   h.type_flag,         h.user_id,         h.source_company_code,
                   d.account_code,      '',                d.rec_company_code,  
                   d.nat_cur_code,      d.document_1,      d.description,  
                   d.reference_code,    d.balance,         d.nat_balance, 
                   d.trx_type,          d.offset_flag,     d.seq_ref_id,  
                   1,                   @@SPID,            h.oper_cur_code,  
                   d.balance_oper,      'CVO',	h.org_id,	d.org_id,	h.interbranch_flag			
        FROM [#gltrx] h
        	INNER JOIN [#gltrxdet] d
                            ON h.[journal_ctrl_num] = d.[journal_ctrl_num]  
	WHERE (h.[posted_flag] = 0 OR h.[posted_flag] = -1) 
	AND 	h.[hold_flag] = 0 


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1643, 5 ) + " -- MSG: " + 'LOAD headers for gledtval_sp'
	
	INSERT INTO [#gltrxedt1] (journal_ctrl_num,  sequence_id,         journal_description,  
                              journal_type,      date_entered,        date_applied,  
                              batch_code,        hold_flag,           home_cur_code,  
                              intercompany_flag, company_code,        source_batch_code,  
                              type_flag,         user_id,             source_company_code,  
                              account_code,      account_description, rec_company_code,  
                              nat_cur_code,      document_1,          description,  
                              reference_code,    balance,             nat_balance,  
                              trx_type,          offset_flag,         seq_ref_id,  
                              temp_flag,         spid,                oper_cur_code,  
                              balance_oper,      db_name,		controlling_org_id,	
				detail_org_id, interbranch_flag)					
	SELECT journal_ctrl_num,  -1,           journal_description,  					
                   journal_type,      date_entered, date_applied, 
                   batch_code,        hold_flag,    home_cur_code,  
                   intercompany_flag, company_code, source_batch_code,  
                   type_flag,         user_id,      source_company_code,  
                   '',                '',           '',  
                   '',                '',           '',  
                   '',                0.0,          0.0,  
                   trx_type,          0,            0,  
                   0,                 @@SPID,       oper_cur_code,  
                   0.0,               '',		org_id,  
			org_id,		interbranch_flag					
	FROM 	[#gltrx]
	WHERE ([posted_flag] = 0 OR [posted_flag] = -1)
	AND 	[hold_flag] = 0 


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1674, 5 ) + " -- MSG: " + 'EXECuting gledtval_sp'
	
	EXEC gledtval_sp @process_mode = 1,
                              @debug_level = @debug_level

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1679, 5 ) + " -- MSG: " + 'Executing  glvedb_sp CVO, CVO'

	EXEC  glvedb_sp 'CVO', 'CVO', 0, 0, 0

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1684, 5 ) + " -- MSG: " + 'Move errors to #iberror after gledtval_sp'
	
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	SELECT i.id, t.err_code, t.trx_ctrl_num, h.journal_ctrl_num, t.sequence_id, t.infofloat, '','',''
	FROM #gltrx h, #ewerror t, #ibhdr i
	WHERE h.journal_ctrl_num = t.trx_ctrl_num
	AND i.controlling_journal_ctrl_num =h.journal_ctrl_num


	






	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1700, 5 ) + " -- MSG: " + 'UPDATE ibifc to mark records with errors-EXTERNAL Transactions (ibedterr)'

	
	UPDATE ibifc_all
	SET	state_flag = -5
	FROM ibifc_all i
		INNER JOIN #iberror e
			ON i.id = e.id
			AND i.state_flag=-3
		INNER JOIN ibedterr edt
			ON e.error_code = edt.code
			AND edt.level = 3

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1713, 5 ) + " -- MSG: " + 'glerrdef  error for EXTERNAL Transactions'	
	
	UPDATE ibifc_all
	SET	state_flag = -5
	FROM ibifc_all i
		INNER JOIN #iberror e
			ON i.id = e.id
			AND i.state_flag=-3
		INNER JOIN glerrdef edt
			ON e.error_code = edt.e_code
			AND edt.e_level = 3
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1725, 5 ) + " -- MSG: " + 'UPDATE ibifc to mark records with errors-INTERNAL Transactions (ibedterr)'

	
	UPDATE ibifc_all
		SET	state_flag = -4
	FROM ibifc_all i
		INNER JOIN #ibhdr h
			ON i.link1 = h.detail_journal_ctrl_num
		INNER JOIN #iberror e
			ON h.id = e.id
			AND i.state_flag=-2
		INNER JOIN ibedterr edt
			ON e.error_code = edt.code
			AND edt.level = 3

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1740, 5 ) + " -- MSG: " + 'glerrdef  error for INTERNAL Transactions'	
	
	UPDATE ibifc_all
	SET	state_flag = -4
	FROM ibifc_all i
		INNER JOIN #ibhdr h
			ON i.link1 = h.detail_journal_ctrl_num
		INNER JOIN #iberror e
			ON h.id = e.id
			AND i.state_flag=-2
		
		INNER JOIN glerrdef edt
					ON e.error_code = edt.e_code
					AND edt.e_level = 3	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1755, 5 ) + " -- MSG: " + 'Delete Trasactions with errors from the Temporal tables'
	
	DELETE #iberror
	FROM #iberror e
	INNER JOIN glerrdef edt
		ON e.error_code = edt.e_code
		AND edt.e_level <> 3

	DELETE #iberror
	FROM #iberror e
	INNER JOIN ibedterr edt
		ON e.error_code = edt.code
		AND edt.level <>  3

	DELETE #gltrx
	    FROM #gltrx s, #iberror e, #ibhdr i
	 WHERE i.id = e.id
	  AND i.controlling_journal_ctrl_num =s.journal_ctrl_num

	DELETE #gltrxdet
	    FROM #gltrxdet s, #iberror e, #ibhdr i
		 WHERE i.id = e.id
		  AND i.controlling_journal_ctrl_num =s.journal_ctrl_num

	DELETE #ibhdr
	    FROM #ibhdr s, #iberror e
	 WHERE s.id = e.id

	DELETE #ibdet
	    FROM #ibdet s, #iberror e
	 WHERE s.id = e.id

	DELETE #ibtax
	    FROM #ibtax s, #iberror e
	 WHERE s.id = e.id

	DELETE #iblink
	    FROM #iblink s, #iberror e
	 WHERE s.id = e.id
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1795, 5 ) + " -- MSG: " + 'Update state flags in #gltrx and #gltrxdet so the transaction will get saved'

	UPDATE #gltrx SET trx_state = 2
	UPDATE #gltrxdet SET trx_state = 2
	 
	
	



	IF @trial_flag = 1 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1807, 5 ) + " -- MSG: " + 'RESET data in ibifc that has been processed'
	
		UPDATE ibifc_all
		SET state_flag = CASE WHEN state_flag = -2 THEN 0 ELSE -1 END 
		WHERE process_ctrl_num = @process_ctrl_num
		AND state_flag IN (-2, -3)
		 
		SELECT @return_value = 0
		
		


		GOTO ibpost_sp_error_exit
	END

	


























































































































	IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION SELECT @transaction_started = 1 SELECT 'PS_TRACE'='BEGIN transaction: ' + 'CREATEGL' END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1947, 5 ) + " -- MSG: " + 'EXECing gltrxsav_sp'	


	
	
	

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 1954, 5 ) + " -- MSG: " + 'update the sequence id for the inter-org rows'
























































	

	
	CREATE TABLE #gltrxdet_ordered_jrnl 
	(	journal_ctrl_num	varchar(30) NOT NULL,

		sequence_id		int NOT NULL,
		old_sequence_id		int NOT NULL,
		detail_journal_ctrl_num varchar(32) NOT NULL,
		external_flag int,
		sequence_order_ib	integer		
	)
	CREATE CLUSTERED INDEX temp_gltrxdet_ordered_0 on #gltrxdet_ordered_jrnl (journal_ctrl_num ASC, sequence_order_ib ASC, old_sequence_id ASC)

	INSERT #gltrxdet_ordered_jrnl (journal_ctrl_num,sequence_id,old_sequence_id, detail_journal_ctrl_num, 
		external_flag, sequence_order_ib)
	SELECT d.journal_ctrl_num, d.sequence_id, d.sequence_id, isnull(i.detail_journal_ctrl_num,d.journal_ctrl_num), 
		i.external_flag, isnull(i.sequence_order_ib, 0)
	FROM #gltrxdet d left outer join #ibhdr i on (i.controlling_journal_ctrl_num 	= d.journal_ctrl_num)
	
	SELECT  MAX(sequence_id) sequence_id, i.journal_ctrl_num
	INTO 	#sequence_ids
	FROM 	#gltrx i, #gltrxdet_ordered_jrnl d
	WHERE  	i.journal_ctrl_num = d.journal_ctrl_num
	AND 	i.posted_flag = -1
	GROUP BY i.journal_ctrl_num

	declare @changed_flag varchar(30)
	set @sequence_id = 0

	UPDATE TEMP
	SET 	TEMP.sequence_id = @sequence_id,
		@sequence_id = (case @changed_flag when TEMP.detail_journal_ctrl_num then @sequence_id + 1 else 1 end )
		, @changed_flag = TEMP.detail_journal_ctrl_num
	FROM 	#gltrxdet_ordered_jrnl TEMP, #sequence_ids s
	WHERE 	TEMP.external_flag = 0

	UPDATE TEMP
	SET 	TEMP.sequence_id = TEMP.sequence_id + s.sequence_id
	FROM 	#gltrxdet_ordered_jrnl TEMP, #sequence_ids s
	WHERE 	s.journal_ctrl_num = TEMP.detail_journal_ctrl_num
	AND 	s.journal_ctrl_num != TEMP.journal_ctrl_num
	AND  	TEMP.external_flag = 0

	DROP TABLE #sequence_ids


	UPDATE DET
		SET DET.sequence_id = TEMP.sequence_id
	FROM #gltrxdet DET
		INNER JOIN #gltrxdet_ordered_jrnl TEMP ON DET.journal_ctrl_num = TEMP.journal_ctrl_num AND DET.sequence_id = TEMP.old_sequence_id

	DROP TABLE #gltrxdet_ordered_jrnl

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 2066, 5 ) + " -- MSG: " + 'Insert the new details to the original journal '
		
	INSERT  gltrxdet (
		journal_ctrl_num,		sequence_id,		rec_company_code,		company_id,	
		account_code,		description,		document_1,		document_2,		reference_code,
		balance,		nat_balance,		nat_cur_code,		rate,		posted_flag,
		date_posted,		trx_type,		offset_flag,		seg1_code,
		seg2_code,		seg3_code,		seg4_code,		seq_ref_id, 
		balance_oper,		rate_oper,		rate_type_home,		rate_type_oper,	org_id
		)
	SELECT  
		i.detail_journal_ctrl_num,		d.sequence_id,		d.rec_company_code,		d.company_id,
		d.account_code,		d.description,	d.document_1,		i.detail_journal_ctrl_num,	d.reference_code,
		ROUND( d.balance, @precision_gl ), 	ROUND( d.nat_balance, c.curr_precision ),		d.nat_cur_code,		d.rate,		d.posted_flag,
		d.date_posted,		d.trx_type,	d.offset_flag,		d.seg1_code,
		d.seg2_code,		d.seg3_code,	d.seg4_code,		-1,												
		ROUND( d.balance_oper, @precision_gl ),	d.rate_oper,		d.rate_type_home,		d.rate_type_oper,	d.org_id
	FROM    #gltrxdet d, #gltrx h, glcurr_vw c, #ibhdr i
	WHERE   h.trx_state = 2
	AND     h.journal_ctrl_num 		= d.journal_ctrl_num
	AND     d.nat_cur_code 			= c.currency_code
	AND 	i.controlling_journal_ctrl_num 	= d.journal_ctrl_num
	AND 	i.external_flag 		= 0
		

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 2091, 5 ) + " -- MSG: " + 'Delete the journals for internal transactions because now owe have just one journal'

	DELETE #gltrx
	FROM #gltrx d , #ibhdr i
	WHERE  	i.controlling_journal_ctrl_num = d.journal_ctrl_num
	AND 	i.external_flag = 0
	

	DELETE #gltrxdet
	FROM #gltrxdet d , #ibhdr i
	WHERE  	i.controlling_journal_ctrl_num =d.journal_ctrl_num
	AND 	i.external_flag = 0
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 2104, 5 ) + " -- MSG: " + 'Save the journals JUST for external transactions'		

	IF @external_post > 0				
	BEGIN	
		EXEC @ret = gltrxsav_sp @process_ctrl_num = @process_ctrl_num,
		                                       @org_company = @company_code,
		                                       @debug = @debug_level,
		                                       @interface_flag = 1, 
		                                       @userid = @userid
		
		IF @ret <> 0 
		BEGIN
			IF @transaction_started = 1 BEGIN ROLLBACK TRANSACTION SELECT @transaction_started = 0 SELECT 'PS_TRACE'='ROLLBACK transaction: ' + 'CREATEGL' END
			SELECT @return_value = -230
			GOTO ibpost_sp_error_exit
		END

		UPDATE gltrx
			SET posted_flag =-1
		WHERE interbranch_flag = 2
			AND posted_flag = 0

	END 


	


	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 2132, 5 ) + " -- MSG: " + 'Save Inter-Organization information in the final tables'
	
	INSERT INTO ibhdr (timestamp, id, trx_ctrl_num, date_entered, date_applied, trx_type, controlling_org_id, detail_org_id, amount, currency_code, tax_code, doc_description, create_date, create_username, last_change_date, last_change_username)
	  SELECT NULL, id, trx_ctrl_num, date_entered, date_applied, trx_type, controlling_org_id, detail_org_id, amount, currency_code, tax_code, doc_description, create_date, create_username, last_change_date, last_change_username
	     FROM #ibhdr
	
	INSERT INTO ibdet (timestamp, id, sequence_id, org_id, amount, currency_code, doc_description, account_code, reconciled_flag, create_date, create_username, last_change_date, last_change_username, reference_code, balance_oper, rate_oper, oper_currency, rate_type_oper, balance_home, rate_home, home_currency, rate_type_home, dispute_flag)
	  SELECT NULL, id, sequence_id, org_id, amount, currency_code, doc_description, account_code, reconciled_flag, create_date, create_username, last_change_date, last_change_username, reference_code, balance_oper, rate_oper, oper_currency, rate_type_oper, balance_home, rate_home, home_currency, rate_type_home, 0
	    FROM #ibdet
	
	INSERT INTO ibtax(timestamp, id, sequence_id, tax_type_code, amt_gross, amt_taxable, amt_tax, create_date, create_username, last_change_date, last_change_username, nat_cur_code, balance_oper, rate_oper, oper_currency, rate_type_oper, balance_home, rate_home, home_currency, rate_type_home)
	  SELECT NULL, id, sequence_id, tax_type_code, amt_gross, amt_taxable, amt_tax, create_date, create_username, last_change_date, last_change_username, nat_cur_code, balance_oper, rate_oper, oper_currency, rate_type_oper, balance_home, rate_home, home_currency, rate_type_home
	     FROM #ibtax
	
	INSERT INTO iblink (timestamp, id, sequence_id, trx_type, source_trx_ctrl_num, source_sequence_id, source_url, source_urn, source_id, source_po_no, source_order_no, source_ext, source_line, trx_ctrl_num, org_id, create_date, create_username, last_change_date, last_change_username)
	  SELECT NULL, id, sequence_id, trx_type, source_trx_ctrl_num, source_sequence_id, source_url, source_urn, source_id, source_po_no, source_order_no, source_ext, source_line, trx_ctrl_num, org_id, create_date, create_username, last_change_date, last_change_username
	      FROM #iblink
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 2150, 5 ) + " -- MSG: " + 'DELETE data from ibifc that has been processed'	
	
	DELETE ibifc_all
	WHERE process_ctrl_num = @process_ctrl_num
	AND state_flag IN (-2,-3)
		 
	

















	IF @transaction_started = 1 BEGIN COMMIT TRANSACTION SELECT @transaction_started = 0 SELECT 'PS_TRACE'='COMMIT transaction: ' + 'CREATEGL' END







SELECT @return_value = 0





ibpost_sp_error_exit:
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 2189, 5 ) + " -- MSG: " + ' ibpost_sp_error_exit: Drop temp tables'



	DROP TABLE #ibtax
	DROP TABLE #ibio
	INSERT INTO iberror (   [id], 	[error_code],	[info1]	,
				[info2],	[infoint],	[infodecimal],
				[link1], 	[link2],	[link3], 
			        [process_ctrl_num])
	SELECT     [id], 	[error_code],	[info1]	,
				[info2],	[infoint],	[infodecimal],
				[link1], 	[link2],	[link3], 
			        @process_ctrl_num
	FROM #iberror

	DROP TABLE #iberror 
	DROP TABLE #ibhdr 
	DROP TABLE #ibdet 
	DROP TABLE #iblink
	DROP TABLE [#gltrx] 
	DROP TABLE [#gltrxdet] 
	DROP TABLE #ewerror



DROP TABLE #trxerror
DROP TABLE #batches
DROP TABLE #offsets
DROP TABLE #offset_accts
DROP TABLE #pcontrol
DROP TABLE #ibnumber
DROP TABLE #TxLineInput
DROP TABLE  #TxInfo
DROP TABLE  #TxLineTax
DROP TABLE  #txdetail
DROP TABLE  #txinfo_id
DROP TABLE  #TXInfo_min_id
DROP TABLE  #TxTLD
DROP TABLE #gltrxedt1












IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ibpost_gl.cpp" + ", line " + STR( 2241, 5 ) + " -- EXIT: "	

RETURN @return_value


GO
GRANT EXECUTE ON  [dbo].[ibpost_gl_sp] TO [public]
GO
