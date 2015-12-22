SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC	[dbo].[arinvrev_sp]	
			@posting_code	varchar(8),
			@cr_memo_flag	smallint
AS

DECLARE	
		@rev_acct	varchar(32)

SELECT	@rev_acct = NULL



IF	@cr_memo_flag = 1
BEGIN
	SELECT	@rev_acct = sales_ret_acct_code
	FROM	araccts
	WHERE	posting_code = @posting_code
END
ELSE
BEGIN
	SELECT	@rev_acct = rev_acct_code
	FROM	araccts
	WHERE	posting_code = @posting_code
END



IF	@rev_acct IS NULL
	SELECT	""
ELSE
	SELECT	@rev_acct



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arinvrev_sp] TO [public]
GO
