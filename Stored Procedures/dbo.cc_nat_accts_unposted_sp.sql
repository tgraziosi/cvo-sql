SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC	[dbo].[cc_nat_accts_unposted_sp]

AS


	DECLARE	@chg_flag	int,
				@pyt_flag	int


 


	SELECT @chg_flag = count(customer_code)
	FROM arinpchg
	WHERE hold_flag = 0
 
 
	SELECT @pyt_flag = count(customer_code)
	FROM arinppyt
	WHERE hold_flag = 0

	SELECT	@chg_flag + @pyt_flag

GO
GRANT EXECUTE ON  [dbo].[cc_nat_accts_unposted_sp] TO [public]
GO
