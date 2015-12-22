SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APPYNumberBankGenerated_sp]
					@debug_level  smallint = 0
AS
   DECLARE 
	@payment_code varchar(8),
	@doc_num_mask varchar(16),
	@next_numb    int,
	@first_num int,
	@last_num int,
	@doc_ctrl_num varchar(16),
	@first_doc_ctrl_num varchar(16),
	@last_doc_ctrl_num varchar(16),
	@previous_payment_code varchar(8),
	@total int,
	@error_flag   smallint



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appynbg.cpp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appynbg.cpp" + ", line " + STR( 63, 5 ) + " -- MSG: " + "count number of bank generated payments"

SELECT a.payment_code, numb = count(*)
INTO #bankgen_temp
FROM #appypyt_work a, appymeth b
WHERE a.payment_code = b.payment_code
AND a.payment_type = 1
AND b.payment_type = 3
GROUP BY a.payment_code

IF @@rowcount = 0
   BEGIN
	 DROP TABLE #bankgen_temp
	 RETURN 0
   END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appynbg.cpp" + ", line " + STR( 83, 5 ) + " -- MSG: " + "Check if Bank Generated Payment number already in use"

SELECT @previous_payment_code=''
WHILE (1=1)
BEGIN

	SELECT @payment_code = min(payment_code)
	FROM #bankgen_temp
	WHERE payment_code > @previous_payment_code

	IF @@rowcount = 0 BREAK

	IF @payment_code is null BREAK

	SELECT @total = numb
	FROM #bankgen_temp
	WHERE payment_code = @payment_code


	SELECT @previous_payment_code = @payment_code
	SELECT 	@first_num = next_doc_num,
		@doc_num_mask = doc_num_mask
	FROM	appymeth
	WHERE	payment_code = @payment_code

	SELECT @last_num = @first_num + @total - 1;
	EXEC fmtctlnm_sp @first_num, @doc_num_mask, @first_doc_ctrl_num OUTPUT, @error_flag OUTPUT
	EXEC fmtctlnm_sp @last_num, @doc_num_mask, @last_doc_ctrl_num OUTPUT, @error_flag OUTPUT

	IF EXISTS(SELECT * FROM apchecks_vw
		WHERE doc_ctrl_num BETWEEN @first_doc_ctrl_num AND @last_doc_ctrl_num  and payment_code = @payment_code)
	BEGIN
		DROP TABLE #bankgen_temp
		RETURN -1
	END
	IF EXISTS(SELECT * FROM apinppyt
        	WHERE trx_type IN (4111)
		AND doc_ctrl_num BETWEEN @first_doc_ctrl_num AND @last_doc_ctrl_num and payment_code = @payment_code)
	BEGIN
		DROP TABLE #bankgen_temp
		RETURN -1
	END

END 





BEGIN TRAN updappymeth

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appynbg.cpp" + ", line " + STR( 134, 5 ) + " -- MSG: " + "Update appymeth with next document number"

UPDATE appymeth
SET next_doc_num = appymeth.next_doc_num + b.numb
FROM appymeth, #bankgen_temp b
WHERE appymeth.payment_code = b.payment_code

IF (@@error <> 0)
	BEGIN
	    ROLLBACK TRAN updappymeth
		RETURN -1
	END

UPDATE #bankgen_temp
SET numb = a.next_doc_num - #bankgen_temp.numb
FROM appymeth a, #bankgen_temp
WHERE a.payment_code = #bankgen_temp.payment_code

IF (@@error <> 0)
	BEGIN
	    ROLLBACK TRAN updappymeth
		RETURN -1
	END


COMMIT TRAN updappymeth


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appynbg.cpp" + ", line " + STR( 162, 5 ) + " -- MSG: " + "assign bank generated numbers"

WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
	  SELECT @payment_code = payment_code,
	         @next_numb = numb
	  FROM #bankgen_temp

	  IF @@rowcount = 0 BREAK

	  SET ROWCOUNT 0

	  SELECT @doc_num_mask = doc_num_mask
	  FROM appymeth
	  WHERE payment_code = @payment_code
	  

	   EXEC fmtctlnm_sp @next_numb, @doc_num_mask, @doc_ctrl_num OUTPUT, @error_flag OUTPUT
		 
		 WHILE(1=1)
		    BEGIN
			   
			   SET ROWCOUNT 1

			   UPDATE #appypyt_work
			   SET doc_ctrl_num = @doc_ctrl_num
			   WHERE payment_code = @payment_code
			   AND doc_ctrl_num = ""
			   AND payment_type = 1

			   IF @@rowcount = 0 OR @@error != 0 BREAK

			   
			   SET ROWCOUNT 0

			   SELECT @next_numb = @next_numb + 1
		
			   EXEC fmtctlnm_sp @next_numb, @doc_num_mask, @doc_ctrl_num OUTPUT, @error_flag OUTPUT
			END
		 
		 IF @@error != 0
		    BEGIN
			   SET ROWCOUNT 0
			   RETURN -1
			END
		 		 
		 SET ROWCOUNT 0

		 DELETE #bankgen_temp 
		 WHERE payment_code = @payment_code
   END

SET ROWCOUNT 0

DROP TABLE #bankgen_temp

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appynbg.cpp" + ", line " + STR( 219, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYNumberBankGenerated_sp] TO [public]
GO
