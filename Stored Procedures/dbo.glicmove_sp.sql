SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

		
CREATE PROCEDURE	[dbo].[glicmove_sp] 
			@org_company_code	varchar(8),
			@rec_company_code	varchar(8),
			@debug			smallint = 0
AS

BEGIN

	DECLARE	@rows	int,
		@err	int

	INSERT 	glictrxd
	       (journal_ctrl_num,	
		sequence_id,	
		account_code,
		posted_flag,		
		date_posted,	
		balance, 
		document_1,		
		description,
		rec_company_code,
		company_id,
		document_2,
		reference_code,
		nat_balance,
		nat_cur_code,
		rate,
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
		org_id)
	SELECT	d.journal_ctrl_num,	
		d.sequence_id,	
		d.account_code,
		d.posted_flag,		
		d.date_posted,	
		d.balance, 
		d.document_1,		
		d.description,
		d.rec_company_code,
		d.company_id,
		d.document_2,
		d.reference_code,
		d.nat_balance,
		d.nat_cur_code,
		d.rate,
		d.trx_type,
		d.offset_flag,
		d.seg1_code,
		d.seg2_code,
		d.seg3_code,
		d.seg4_code,
		d.seq_ref_id,
		d.balance_oper,
		d.rate_oper,
		d.rate_type_home,
		d.rate_type_oper,
		d.org_id
	FROM	#gldtrdet t, gltrxdet d
	WHERE	t.rec_company_code = @rec_company_code
	AND	d.journal_ctrl_num = t.journal_ctrl_num
	AND	d.sequence_id = t.sequence_id

	SELECT	@rows = @@ROWCOUNT, @err = @@error
	IF ( @err != 0 )
		RETURN	1039

	DELETE	gltrxdet
	FROM	#gldtrdet t, gltrxdet d
	WHERE	t.rec_company_code = @rec_company_code
	AND	d.journal_ctrl_num = t.journal_ctrl_num
	AND	d.sequence_id = t.sequence_id

	IF ( @@error != 0 OR @rows != @@ROWCOUNT )
		RETURN 1039
		
	DELETE	#gldtrdet
	WHERE	rec_company_code = @rec_company_code

	IF ( @@error != 0 OR @rows != @@ROWCOUNT )
		RETURN 1039

	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[glicmove_sp] TO [public]
GO
