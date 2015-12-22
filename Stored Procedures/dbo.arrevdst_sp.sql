SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arrevdst_sp]	@PostingCode char(8), @TrxType smallint,
	@TrxCtrlNum char(16), @ApplyDate int, @org_id varchar(30)
AS

DECLARE @seq_id smallint,
        @rev_acct_code varchar(32),
        @result smallint,
	@count int
        












SELECT	@rev_acct_code = dbo.IBAcctMask_fn(rev_acct_code, @org_id)
FROM	araccts
WHERE	posting_code = @PostingCode




EXEC @result = arglvc_sp @rev_acct_code, @ApplyDate, 1
IF ( @result > 0 ) 
      SELECT @rev_acct_code = ""




SELECT @count = COUNT (*) 
FROM InterBranchAccts 
WHERE account_code = @rev_acct_code 
AND org_id = @org_id




select @result = @count
IF ( @result = 0 ) 
 SELECT @rev_acct_code = ""




INSERT	#arinprev(
	trx_ctrl_num,	sequence_id,	rev_acct_code,	apply_amt,
	trx_type, org_id
	)
VALUES ( @TrxCtrlNum, 0, @rev_acct_code, 0, @TrxType, @org_id )



SELECT	@seq_id = 1
SET	ROWCOUNT 1

WHILE	( 1 = 1 )
BEGIN
	UPDATE	#arinprev
	SET	sequence_id = @seq_id
	WHERE	sequence_id = 0

	IF ( @@ROWCOUNT = 0 )
		BREAK

	SELECT	@seq_id = @seq_id + 1
END

SET	ROWCOUNT 0

GO
GRANT EXECUTE ON  [dbo].[arrevdst_sp] TO [public]
GO
