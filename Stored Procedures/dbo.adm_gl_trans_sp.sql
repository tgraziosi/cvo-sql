SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_gl_trans_sp]
 	@trans_id int,           --Trans Type
        @user_id varchar(10) AS  --ADM User id  

--2010 --Invoice Processing
--2011 --Shipment Processing
--2030 --Credit Memo Processing
--2031 --CR Shipment Processing

--4010 --Voucher Processing
--4011 --Receipts Batch
--4030 --Debit Memo Processing
--4031 --DB Memo Receipt??

--5010 --Inventory Adjustment Processing
--5020 --Transfer Procession
--5030 --WIP Feeds
--5040 --Production Close




BEGIN

DECLARE @error varchar(255)

--Create Temp Table's used In Processing

CREATE TABLE #gltrx
(
	mark_flag			smallint NOT NULL,
	next_seq_id			int NOT NULL,
	trx_state			smallint NOT NULL,
	journal_type          		varchar(8) NOT NULL,
	journal_ctrl_num      		varchar(16) NOT NULL, 
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
        oper_cur_code           varchar(8)         
)

CREATE UNIQUE INDEX #gltrx_ind_0
	 ON #gltrx ( journal_ctrl_num )


--Create detail Temp Table
CREATE TABLE #gltrxdet
(
	mark_flag		smallint NOT NULL,
	trx_state		smallint NOT NULL,
        journal_ctrl_num	varchar(16) NOT NULL,
	sequence_id		int NOT NULL,
	rec_company_code	varchar(8) NOT NULL,	
	company_id		smallint NOT NULL,
        account_code		varchar(32) NOT NULL,	
	description		varchar(40) NOT NULL,
        document_1		varchar(16) NOT NULL, 	
        document_2		varchar(16) NOT NULL, 	
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
	rate_type_oper          varchar(8) NULL
                                                
)

CREATE UNIQUE INDEX #gltrxdet_ind_0
	ON #gltrxdet ( journal_ctrl_num, sequence_id )

CREATE INDEX #gltrxdet_ind_1
	ON #gltrxdet ( journal_ctrl_num, account_code )

--TRXERROR TABLE

CREATE TABLE #trxerror
(
	journal_ctrl_num  	varchar(16), 
	sequence_id		int,
	error_code	  	int
)

CREATE UNIQUE INDEX	#trxerror_ind_0
ON			#trxerror (	journal_ctrl_num, 
					sequence_id, 
					error_code )



CREATE TABLE	#offset_accts (
		account_code	varchar(32)	NOT NULL,
		org_code	varchar(8)	NOT NULL,
		rec_code	varchar(8)	NOT NULL,
		sequence_id	int 	NOT NULL)
CREATE UNIQUE CLUSTERED INDEX	#offset_accts_ind_0
	ON #offset_accts( rec_code, account_code, org_code )


CREATE TABLE	#offsets (
	journal_ctrl_num	varchar(16)	NOT NULL,
	sequence_id		int	NOT NULL,
	company_code		varchar(8)	NOT NULL,
	company_id		smallint	NOT NULL,
	org_ic_acct  		varchar(32)	NOT NULL,
	org_seg1_code		varchar(32)	NOT NULL,
	org_seg2_code		varchar(32)	NOT NULL,
	org_seg3_code		varchar(32)	NOT NULL,
	org_seg4_code		varchar(32)	NOT NULL,
	org_org_id		varchar(30)	NOT NULL,
	rec_ic_acct  		varchar(32)	NOT NULL,
	rec_seg1_code		varchar(32)	NOT NULL,
	rec_seg2_code		varchar(32)	NOT NULL,
	rec_seg3_code		varchar(32)	NOT NULL,
	rec_seg4_code		varchar(32)	NOT NULL,
	rec_org_id		varchar(30)	NOT NULL )

CREATE UNIQUE CLUSTERED INDEX	#offsets_ind_0
	ON #offsets ( journal_ctrl_num, sequence_id )


CREATE TABLE #batches
(

	date_applied		int	NOT NULL,
	source_batch_code	varchar(16)	NOT NULL
)

CREATE UNIQUE CLUSTERED INDEX	#batches_ind_0
ON				#batches (	date_applied, 
						source_batch_code )

--Processing Call Appropiate SP for each feed type


if @trans_id = 5010
   exec fs_post_gl @user_id

if @trans_id = 5020
   exec fs_post_xfer @user_id

if @trans_id = 4011 or @trans_id = 2011
   exec adm_process_gl @user_id

--select * from #trxerror
--select * from #gltrx
--select * from #gltrxdet


end
GO
GRANT EXECUTE ON  [dbo].[adm_gl_trans_sp] TO [public]
GO
