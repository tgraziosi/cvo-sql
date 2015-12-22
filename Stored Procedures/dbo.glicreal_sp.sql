SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glicreal.SPv - e7.2.2 : 1.6.1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[glicreal_sp]
			@journal_ctrl_num	varchar(17),
			@company_code		varchar(8)
AS
DECLARE	@max_seq 	smallint,	
	@seq_id 	smallint, 
	@acct_code 	varchar(32), 
	@rec_code 	varchar(8),
	@org_acct 	varchar(32),
	@rec_acct 	varchar(32),
	@result 	smallint, 
	@new_seq 	smallint,	
	@org_seg1_code	varchar(32), 
	@org_seg2_code	varchar(32),
	@org_seg3_code	varchar(32),
	@org_seg4_code	varchar(32),
	@rec_seg1_code	varchar(32),
	@rec_seg2_code	varchar(32),
	@rec_seg3_code	varchar(32),
	@rec_seg4_code	varchar(32),
	@tran_started	tinyint

SET NOCOUNT ON

SELECT	@tran_started = 0


IF NOT EXISTS ( SELECT journal_ctrl_num 
		FROM	glreadet
		WHERE	journal_ctrl_num = @journal_ctrl_num
		AND	rec_company_code != @company_code )
BEGIN
	SELECT 0
	RETURN 0
END


SELECT	@max_seq = MAX( sequence_id )
FROM	glreadet
WHERE	journal_ctrl_num = @journal_ctrl_num


SELECT	@seq_id = 1, @result = 1, @new_seq = @max_seq + 1


IF ( @@trancount = 0 )
BEGIN
	BEGIN TRAN
	SELECT	@tran_started = 1
END


WHILE ( @seq_id <= @max_seq )
BEGIN 
	
	SELECT	@org_acct = NULL, @rec_acct = NULL

	SELECT	@acct_code = account_code,
		@rec_code = rec_company_code
	FROM	glreadet
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

	SET ROWCOUNT 0

	
	IF	@org_acct IS NULL OR @rec_acct IS NULL
	BEGIN
		SELECT	@result = 0
		BREAK
	END

	
	INSERT	glreadet (
		journal_ctrl_num,	sequence_id,	rec_company_code,
		account_code,		posted_flag,	date_posted,		
		balance,		document_1,	reference_code,		
		offset_flag,		seg1_code,	seg2_code,
		seg3_code,		seg4_code,	seq_ref_id )
	SELECT	@journal_ctrl_num,	@new_seq,	@company_code,
		@org_acct,		0,		0,			
		balance,		document_1,	"",			
		1,			@org_seg1_code,	@org_seg2_code,
		@org_seg3_code,		@org_seg4_code,	(@seq_id-1)
	FROM	glreadet
	WHERE	journal_ctrl_num = @journal_ctrl_num
	AND	sequence_id = @seq_id-1

	
	INSERT	glreadet (
		journal_ctrl_num,	sequence_id,	rec_company_code,
		account_code,		posted_flag,	date_posted,		
		balance,		document_1,	reference_code,		
		offset_flag,		seg1_code,	seg2_code,
		seg3_code,		seg4_code,	seq_ref_id )
	SELECT	@journal_ctrl_num,	@new_seq+1,	rec_company_code,
		@rec_acct,		0,		0,			
		-balance,		document_1,	"",			
		1,	 		@rec_seg1_code,	@rec_seg2_code,
		@rec_seg3_code,		@rec_seg4_code, (@seq_id-1)
	FROM	glreadet
	WHERE	journal_ctrl_num = @journal_ctrl_num
	AND	sequence_id = @seq_id-1

	
	SELECT	@new_seq = @new_seq + 2
END


IF	@result = 1
BEGIN
	IF ( @tran_started = 1 )
	BEGIN
		COMMIT TRAN
		SELECT	@tran_started = 0
	END

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
	
	UPDATE	glreall
	SET	hold_flag = 1
	WHERE	journal_ctrl_num = @journal_ctrl_num

	SELECT 1
	RETURN 1 
END



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glicreal_sp] TO [public]
GO
