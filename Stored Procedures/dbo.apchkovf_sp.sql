SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apchkovf_sp] @to_white_paper smallint, 
							 @lines_per_check smallint,
							 @debug_level smallint = 0


AS
	DECLARE @id numeric,
			@lines smallint,
			@trx_ctrl_num varchar(16),
			@apply_to_num varchar(16),
			@save_ctrl_num varchar(16),
			@count int



CREATE TABLE #overflows (trx_ctrl_num varchar(16), lines smallint)

INSERT #overflows (trx_ctrl_num,lines)
SELECT payment_num, SUM(lines)
FROM #apchkstb
GROUP BY payment_num
HAVING SUM(lines) > @lines_per_check


CREATE TABLE #lines( trx_ctrl_num varchar(16),
					 apply_to_num varchar(16),
					 lines smallint,
					 id numeric identity )


INSERT #lines (trx_ctrl_num,
			 apply_to_num,
			 lines)
SELECT a.payment_num,
	 a.voucher_num,
	 a.lines
FROM #apchkstb a, #overflows b
WHERE a.payment_num = b.trx_ctrl_num
ORDER BY a.payment_num, a.voucher_num, a.payment_type, a.description

DROP TABLE #overflows

CREATE TABLE #mark( trx_ctrl_num varchar(16),
					apply_to_num varchar(16))


SELECT @id = 1,
	 @save_ctrl_num = "",
	 @count = 0

WHILE (1=1)
BEGIN
	SELECT @trx_ctrl_num = NULL
	SELECT @trx_ctrl_num = trx_ctrl_num,
		 @apply_to_num = apply_to_num,
		 @lines = lines
	FROM #lines
	WHERE id = @id

	IF (@trx_ctrl_num IS NULL) BREAK

	IF (@trx_ctrl_num != @save_ctrl_num)
	 BEGIN
		 SELECT @save_ctrl_num = @trx_ctrl_num
		 SELECT @count = 0
	 END

	IF (@count <= @lines_per_check)
		BEGIN
			SELECT @count = @count + @lines
			IF @count > @lines_per_check
			 INSERT #mark (trx_ctrl_num,
							 apply_to_num)
			 VALUES (@trx_ctrl_num,
					 @apply_to_num)
		END

	SELECT @id = @id + 1
END

DROP TABLE #lines

UPDATE #apchkstb
SET overflow_flag = 1
FROM #apchkstb, #mark
WHERE #apchkstb.payment_num = #mark.trx_ctrl_num
AND #apchkstb.voucher_num >= #mark.apply_to_num

DROP TABLE #mark



		


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apchkovf.sp" + ", line " + STR( 129, 5 ) + " -- EXIT: "
GO
GRANT EXECUTE ON  [dbo].[apchkovf_sp] TO [public]
GO
