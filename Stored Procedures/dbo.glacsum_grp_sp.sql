SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[glacsum_grp_sp] (@module_id	  	int)
AS

IF NOT EXISTS (SELECT 1 FROM glacsum)
	GOTO EXIT_PROCEDURE

CREATE TABLE #gltrxdet_sort
(
	mark_flag		smallint	NOT NULL,
	trx_state		smallint	NOT NULL,
	journal_ctrl_num	varchar(30)	NOT NULL,
	sequence_id		int	NOT NULL,
	rec_company_code	varchar(8)	NOT NULL,
	company_id		smallint	NOT NULL,
	account_code		varchar(32)	NOT NULL,
	description		varchar(40)	NOT NULL,
	document_1		varchar(30)	NOT NULL,
	document_2		varchar(30)	NOT NULL,
	reference_code		varchar(32)	NOT NULL,
	balance			float	NOT NULL,
	nat_balance		float	NOT NULL,
	nat_cur_code		varchar(8)	NOT NULL,
	rate			float	NOT NULL,
	posted_flag		smallint	NOT NULL,
	date_posted		int	NOT NULL,
	trx_type		smallint	NOT NULL,
	offset_flag		smallint	NOT NULL,
	seg1_code		varchar(32)	NOT NULL,
	seg2_code		varchar(32)	NOT NULL,
	seg3_code		varchar(32)	NOT NULL,
	seg4_code		varchar(32)	NOT NULL,
	seq_ref_id		int	NOT NULL,
	balance_oper		float	NULL,
	rate_oper		float	NULL,               
	rate_type_home		varchar(8) 	NULL,    
	rate_type_oper		varchar(8) 	NULL,
	org_id			varchar(30)	NULL,
	status_grp INTEGER
)

CREATE INDEX #gltrxdet_sort_ind_0 ON #gltrxdet_sort ( journal_ctrl_num, sequence_id )
CREATE INDEX #gltrxdet_sort_ind_1 ON #gltrxdet_sort ( journal_ctrl_num, account_code )

CREATE TABLE	#gltrxdet_grp
(
	journal_ctrl_num	varchar(30)	NOT NULL,
	rec_company_code	varchar(8)	NOT NULL,
	account_code		varchar(32)	NOT NULL,
	description		varchar(40)	NOT NULL,
	document_1		varchar(30)	NOT NULL,
	document_2		varchar(30)	NOT NULL,
	reference_code		varchar(32)	NOT NULL,
	balance			float	NOT NULL,
	nat_balance		float	NOT NULL,
	nat_cur_code		varchar(8)	NOT NULL,
	rate			float	NOT NULL,
	trx_type		smallint	NOT NULL,
	balance_oper		float	NULL,
	rate_oper		float	NULL,               
	rate_type_home		varchar(8) 	NULL,    
	rate_type_oper		varchar(8) 	NULL
)

CREATE INDEX #gltrxdet_grp_ind_1 ON #gltrxdet_grp ( journal_ctrl_num, account_code )

INSERT INTO #gltrxdet_sort (
		mark_flag,			trx_state,				journal_ctrl_num,
		sequence_id,		rec_company_code,		company_id,
		account_code,		description,			document_1,
		document_2,			reference_code,			balance,
		nat_balance,		nat_cur_code,			rate,
		posted_flag,		date_posted,			trx_type,
		offset_flag,		seg1_code,				seg2_code,
		seg3_code,			seg4_code,				seq_ref_id,
		balance_oper,		rate_oper,				rate_type_home,
		rate_type_oper,		org_id,					status_grp)
SELECT 	mark_flag,			trx_state,				journal_ctrl_num,
		sequence_id,		rec_company_code,		company_id,
		DET.account_code,		description,			document_1,
		document_2,			reference_code,			balance,
		nat_balance,		nat_cur_code,			rate,
		posted_flag,		date_posted,			trx_type,
		offset_flag,		seg1_code,				seg2_code,
		seg3_code,			seg4_code,				seq_ref_id,
		balance_oper,		rate_oper,				rate_type_home,
		rate_type_oper,		org_id,					0
FROM #gltrxdet DET
	INNER JOIN glacsum CSUM ON DET.account_code = CSUM.account_code AND CSUM.app_id = @module_id
WHERE offset_flag = 0
ORDER BY
	journal_ctrl_num,		DET.account_code,			rec_company_code,
	reference_code,			nat_cur_code,			rate,
	rate_oper,				rate_type_home,			rate_type_oper,
	trx_type


INSERT INTO #gltrxdet_grp (
	journal_ctrl_num,		rec_company_code,		account_code,			
	description,			document_1,				document_2,				
	reference_code,			balance,				nat_balance,			
	nat_cur_code,			rate,					trx_type,				
	balance_oper,			rate_oper,				rate_type_home,			
	rate_type_oper)
SELECT 
	journal_ctrl_num,		rec_company_code,		DET.account_code,		
	' ',					' ',					' ',					
	reference_code,			SUM(balance),			SUM(nat_balance),		
	nat_cur_code,			rate,					trx_type,				
	SUM(balance_oper),		rate_oper,				rate_type_home,			
	rate_type_oper
FROM #gltrxdet_sort DET
	INNER JOIN glacsum CSUM ON DET.account_code = CSUM.account_code AND CSUM.app_id = @module_id
WHERE offset_flag = 0
GROUP BY 
	journal_ctrl_num,		DET.account_code,			rec_company_code,
	reference_code,			nat_cur_code,			rate,
	rate_oper,				rate_type_home,			rate_type_oper,
	trx_type









DECLARE @count INTEGER
DECLARE @journal_ctrl_num_flag	varchar(16)
DECLARE @account_code_flag		varchar(32)
DECLARE @rec_company_code_flag	varchar(8)
DECLARE @reference_code_flag		varchar(32)
DECLARE @nat_cur_code_flag		varchar(8)
DECLARE @rate_flag				float	
DECLARE @rate_oper_flag			float	
DECLARE @rate_type_home_flag		varchar(8)
DECLARE @rate_type_oper_flag		varchar(8)
DECLARE @trx_type_flag			smallint	

SET @count = 0

UPDATE #gltrxdet_sort
	SET journal_ctrl_num = journal_ctrl_num,
		account_code = account_code,
		rec_company_code = rec_company_code,
		reference_code = reference_code,
		nat_cur_code = nat_cur_code,
		rate = rate,
		rate_oper = rate_oper,
		rate_type_home = rate_type_home,
		rate_type_oper = rate_type_oper,
		trx_type = trx_type,
		status_grp = @count,
		@count = (CASE @journal_ctrl_num_flag WHEN journal_ctrl_num THEN  
					CASE @account_code_flag WHEN account_code THEN
						CASE @rec_company_code_flag WHEN rec_company_code THEN
							CASE @reference_code_flag WHEN reference_code THEN
								CASE @nat_cur_code_flag WHEN nat_cur_code THEN
									CASE @rate_flag WHEN rate THEN
										CASE @rate_oper_flag  WHEN rate_oper THEN
											CASE @rate_type_home_flag WHEN rate_type_home THEN
												CASE @rate_type_oper_flag WHEN rate_type_oper THEN
													CASE @trx_type_flag  WHEN trx_type THEN
														@count + 1
													ELSE 1 END
												ELSE 1 END
											ELSE 1 END
										ELSE 1 END
									ELSE 1 END
								ELSE 1 END
							ELSE 1 END
						ELSE 1 END
					ELSE 1 END
				  ELSE 1 END),
		@journal_ctrl_num_flag = journal_ctrl_num,
		@account_code_flag = account_code,
		@rec_company_code_flag = rec_company_code,
		@reference_code_flag = reference_code,
		@nat_cur_code_flag = nat_cur_code,
		@rate_flag = rate,
		@rate_oper_flag = rate_oper,
		@rate_type_home_flag = rate_type_home,
		@rate_type_oper_flag = rate_type_oper,
		@trx_type_flag = trx_type

DELETE #gltrxdet_sort WHERE status_grp > 1

UPDATE SORT
	SET SORT.journal_ctrl_num = GRP.journal_ctrl_num,		
		SORT.rec_company_code = GRP.rec_company_code,		
		SORT.account_code = GRP.account_code,			
		SORT.description = GRP.description,			
		SORT.document_1 = GRP.document_1,				
		SORT.document_2 = GRP.document_2,				
		SORT.reference_code = GRP.reference_code,			
		SORT.balance = GRP.balance,				
		SORT.nat_balance = GRP.nat_balance,			
		SORT.nat_cur_code = GRP.nat_cur_code,			
		SORT.rate = GRP.rate,					
		SORT.trx_type = GRP.trx_type,				
		SORT.balance_oper = GRP.balance_oper,			
		SORT.rate_oper = GRP.rate_oper,				
		SORT.rate_type_home = GRP.rate_type_home,			
		SORT.rate_type_oper = GRP.rate_type_oper
FROM #gltrxdet_sort SORT
	INNER JOIN #gltrxdet_grp GRP ON SORT.journal_ctrl_num = GRP.journal_ctrl_num AND SORT.account_code = GRP.account_code


DELETE DET
FROM #gltrxdet DET
	INNER JOIN glacsum CSUM ON DET.account_code = CSUM.account_code AND CSUM.app_id = @module_id


INSERT INTO #gltrxdet (
		mark_flag,			trx_state,				journal_ctrl_num,
		sequence_id,		rec_company_code,		company_id,
		account_code,		description,			document_1,
		document_2,			reference_code,			balance,
		nat_balance,		nat_cur_code,			rate,
		posted_flag,		date_posted,			trx_type,
		offset_flag,		seg1_code,				seg2_code,
		seg3_code,			seg4_code,				seq_ref_id,
		balance_oper,		rate_oper,				rate_type_home,
		rate_type_oper,		org_id)
SELECT 	mark_flag,			trx_state,				journal_ctrl_num,
		sequence_id,		rec_company_code,		company_id,
		account_code,		description,			document_1,
		document_2,			reference_code,			balance,
		nat_balance,		nat_cur_code,			rate,
		posted_flag,		date_posted,			trx_type,
		offset_flag,		seg1_code,				seg2_code,
		seg3_code,			seg4_code,				seq_ref_id,
		balance_oper,		rate_oper,				rate_type_home,
		rate_type_oper,		org_id
FROM #gltrxdet_sort

SET @count = 0
SET @journal_ctrl_num_flag = ''

UPDATE DET
	SET DET.journal_ctrl_num = DET.journal_ctrl_num,
		DET.sequence_id = @count,
		@count = (CASE @journal_ctrl_num_flag WHEN DET.journal_ctrl_num THEN @count + 1 ELSE 1 END),
		@journal_ctrl_num_flag = DET.journal_ctrl_num
FROM #gltrxdet DET
	INNER JOIN #gltrxdet_sort SORT ON DET.journal_ctrl_num = SORT.journal_ctrl_num AND DET.account_code = SORT.account_code

DROP TABLE #gltrxdet_sort
DROP TABLE #gltrxdet_grp



EXIT_PROCEDURE:
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glacsum_grp_sp] TO [public]
GO
