SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                






























CREATE PROCEDURE [dbo].[glicacct_sp]
	@journal_ctrl_num	varchar(17),
	@company_code		varchar(8), 
	@return_row		smallint = 1
AS
DECLARE	
	@max_seq   	int,	
	@seq_id 	int,     
	@acct_code 	varchar(32),	
	@rec_code 	varchar(8),
	@org_acct  	varchar(32), 
	@rec_acct 	varchar(32),
	@result 	smallint,	
	@ret 		smallint,
	@new_seq 	int,
	@comp_id 	smallint,    
	@rec_comp_id 	smallint,
	@org_seg1_code	varchar(32),
	@org_seg2_code	varchar(32),
	@org_seg3_code	varchar(32),
	@org_seg4_code	varchar(32),
	@rec_seg1_code	varchar(32),
	@rec_seg2_code	varchar(32),
	@rec_seg3_code	varchar(32),
	@rec_seg4_code	varchar(32),
	@tran_started	tinyint,
	@orig_org_id		varchar(30),
	@rec_org_id		varchar(30),
	@rec_db_name		varchar(128),
	@SQL 			varchar(500),
	@account_format_mask	varchar(35)
	

SET NOCOUNT ON




CREATE TABLE #masked_account
 ( account_code varchar(32),
   account_format_mask varchar(35))

SELECT	@tran_started = 0




IF NOT EXISTS ( SELECT  journal_ctrl_num 
		FROM	gltrxdet
		WHERE	journal_ctrl_num = @journal_ctrl_num
		AND	rec_company_code != @company_code )
BEGIN
	IF 	@return_row = 1
		SELECT 0

	RETURN 0
END




SELECT	@max_seq = MAX( sequence_id )
FROM	gltrxdet
WHERE	journal_ctrl_num = @journal_ctrl_num




SELECT	@comp_id = company_id
FROM	glcomp_vw
WHERE	company_code = @company_code




SELECT	@seq_id = 1, @result = 1, @new_seq = @max_seq + 1, 	@orig_org_id='',@rec_org_id =''




IF ( @@trancount = 0 )
BEGIN
	BEGIN TRAN
	SELECT	@tran_started = 1
END



SELECT @orig_org_id = org_id
FROM   gltrx
WHERE journal_ctrl_num = @journal_ctrl_num 





WHILE  ( @seq_id <= @max_seq )
BEGIN 
	


	SELECT	@org_acct = NULL, @rec_acct = NULL

	SELECT	@acct_code = account_code,
		@rec_code = rec_company_code,
		@rec_org_id= org_id
	FROM	gltrxdet
	WHERE	journal_ctrl_num = @journal_ctrl_num
	AND	sequence_id = @seq_id

	


	SELECT	@seq_id = @seq_id + 1

	


	IF	@rec_code = @company_code
		CONTINUE

	


	SET ROWCOUNT 1

	SELECT	@org_acct = org_ic_acct,
		@rec_acct = rec_ic_acct,
		@org_seg1_code = org_seg1_code,
		@org_seg2_code = org_seg2_code,
		@org_seg3_code = org_seg3_code,
		@org_seg4_code = org_seg4_code,
		@rec_seg1_code = rec_seg1_code,
		@rec_seg2_code = rec_seg2_code,
		@rec_seg3_code = rec_seg3_code,
		@rec_seg4_code = rec_seg4_code
	FROM 	glcocodt_vw 
	WHERE	org_code = @company_code
	AND 	rec_code = @rec_code 
	AND 	@acct_code LIKE account_mask
	ORDER	BY sequence_id

	SET ROWCOUNT 0

	


	IF	@org_acct IS NULL OR @rec_acct IS NULL
	BEGIN
		SELECT	@result = 0
		BREAK
	END

	


	SELECT	@rec_comp_id = company_id
	FROM	glcomp_vw
	WHERE	company_code = @rec_code

	SELECT @rec_db_name=db_name FROM glcomp_vw WHERE company_id = @rec_comp_id

	


	TRUNCATE TABLE #masked_account
	SELECT @SQL ='INSERT INTO #masked_account (account_code, account_format_mask) SELECT  '+@rec_db_name + '.dbo.IBAcctMask_fn(''' +  @rec_acct +''' ,''' + @rec_org_id +''')  , account_format_mask FROM '+@rec_db_name + '..glco'
	EXEC (@SQL)

	SELECT @rec_acct = account_code ,
	      @account_format_mask = account_format_mask
	FROM #masked_account

	EXEC @ret = glprsact_sp	@rec_acct, 
					@account_format_mask,
					@rec_seg1_code OUTPUT,
					@rec_seg2_code OUTPUT,                  
					@rec_seg3_code OUTPUT,                  
					@rec_seg4_code OUTPUT

	
	



	INSERT	gltrxdet (
		journal_ctrl_num,	
		sequence_id,	
		rec_company_code,
		company_id,		
		account_code,	
		description,
		document_1,		
		document_2,	
		reference_code,
		balance,		
		nat_balance,	
		nat_cur_code,
		rate,			
		posted_flag,	
		date_posted,
		trx_type,		
		offset_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		seq_ref_id,
		balance_oper,
		rate_oper,
		rate_type_home,
		rate_type_oper,
		org_id )
	SELECT	@journal_ctrl_num,	
		@new_seq,	
		@company_code,
		@comp_id,		
		dbo.IBAcctMask_fn( @org_acct,@orig_org_id),	
		description, 
		document_1,
		document_2,
		'',
		balance,		
		nat_balance,	
		nat_cur_code,
		rate,			
		0, 0,
		trx_type, 
		1,
		@org_seg1_code,
		@org_seg2_code,
		@org_seg3_code,
		@org_seg4_code,
		( @seq_id-1 ),
		balance_oper,
		rate_oper,
		rate_type_home,
		rate_type_oper,
		@orig_org_id 
	FROM	gltrxdet
	WHERE	journal_ctrl_num = @journal_ctrl_num
	AND	sequence_id = @seq_id-1

	


	INSERT	gltrxdet (
		journal_ctrl_num,	
		sequence_id,	
		rec_company_code,
		company_id,		
		account_code,	
		description,
		document_1,		
		document_2,	
		reference_code,
		balance,		
		nat_balance,	
		nat_cur_code,
		rate,			
		posted_flag,	
		date_posted,
		trx_type,		
		offset_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		seq_ref_id,
		balance_oper,
		rate_oper,
		rate_type_home,
		rate_type_oper,
		org_id )
	SELECT	@journal_ctrl_num,	
		@new_seq+1,	
		rec_company_code,
		@rec_comp_id,		
		@rec_acct,	
		description, 
		document_1, 
		document_2,
		'',
		-balance,		
		-nat_balance,	
		nat_cur_code,
		rate,			
		0, 0,
		trx_type,		
		1,
 		@rec_seg1_code,
		@rec_seg2_code,
		@rec_seg3_code,
		@rec_seg4_code,
		( @seq_id-1 ),
		-balance_oper,
		rate_oper,
		rate_type_home,
		rate_type_oper,
		@rec_org_id 
	FROM	gltrxdet
	WHERE	journal_ctrl_num = @journal_ctrl_num
	AND	sequence_id = @seq_id-1

	


	SELECT	@new_seq = @new_seq + 2
END




DROP TABLE #masked_account




IF	@result = 1
BEGIN
	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRAN
		SELECT	@tran_started = 0
	END

	IF 	@return_row = 1
		SELECT 0

	RETURN 0  
END
ELSE
BEGIN
	IF ( @tran_started = 1 )
	BEGIN
		ROLLBACK TRAN
		SELECT	@tran_started = 0
	END
	


	UPDATE	gltrx
	SET	hold_flag = 1
	WHERE	journal_ctrl_num = @journal_ctrl_num

	IF 	@return_row = 1
		SELECT  1

	RETURN  1  
END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glicacct_sp] TO [public]
GO
