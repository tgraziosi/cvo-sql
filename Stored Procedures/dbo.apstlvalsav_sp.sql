SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[apstlvalsav_sp] @debug_level smallint = 0
AS



IF EXISTS (
	SELECT trx_ctrl_num
	FROM	#apinppyt3450
	WHERE	((amt_payment) <= (0.0) + 0.0000001))
	
SELECT 1


ELSE IF EXISTS (
	SELECT 	trx_ctrl_num
	FROM	#apinppyt3450
	WHERE	(ABS((amt_payment)-(amt_on_acct)) < 0.0000001)
	AND	payment_type in (2,3))
	
SELECT 2


ELSE IF EXISTS (
	SELECT 	trx_ctrl_num
	FROM	#apinppyt3450
	WHERE	((amt_on_acct) < (0.0) - 0.0000001))
	
SELECT 3

ELSE
	SELECT 0

GO
GRANT EXECUTE ON  [dbo].[apstlvalsav_sp] TO [public]
GO
