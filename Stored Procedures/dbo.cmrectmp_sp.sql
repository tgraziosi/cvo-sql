SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE PROC [dbo].[cmrectmp_sp] 
		@account_code   char(32),       
		@statement_date int,
		@option         smallint,
		@begin_doc		varchar(16),
		@end_doc		varchar(16),
		@module_id		smallint			
AS
	DECLARE
		@amt_deposits	float,
		@amt_checks		float

IF (@option = 0)
	TRUNCATE TABLE #cmptmp

IF (@statement_date = 0) OR (@account_code = "")
	RETURN


IF (@option = 0)
  BEGIN

	UPDATE cminpdtl
	SET reconciled_flag = 0
	WHERE date_applied > @statement_date
	AND reconciled_flag = 1
	AND closed_flag=0
	AND cash_acct_code = @account_code
     
	INSERT #cmptmp(
			trx_type,            
			trx_ctrl_num,      
			doc_ctrl_num,    
			date_document,
			date_cleared,
			description,     
			cash_acct_code,
			amount_book,     
			reconciled_flag, 
			closed_flag,
			date_applied,
			cleared_type,
			app_code,
			org_id,
			form_sequence)
	SELECT  trx_type,            
			trx_ctrl_num,      
			doc_ctrl_num,    
			date_document,
			date_cleared,
			description,     
			cash_acct_code,
			amount_book,     
			reconciled_flag, 
			closed_flag,
			date_applied,
			cleared_type,
			"",
			org_id,
			""
	FROM            cminpdtl
	WHERE           cash_acct_code =  @account_code
	  AND           (void_flag != 1)
	  AND           (closed_flag != 1) 
	  AND           date_applied <= @statement_date


	UPDATE #cmptmp
	SET app_code = b.app_code
	FROM #cmptmp a, CVO_Control..smapp b
	WHERE (a.trx_type/1000)*1000 = b.app_id

   UPDATE #cmptmp
   SET form_sequence = app_code + doc_ctrl_num + convert(char,date_document) + trx_ctrl_num

	UPDATE #cmptmp
	SET date_cleared = @statement_date
	WHERE date_cleared = 0

END
ELSE 
	
		IF @option = 1
		   BEGIN
			  UPDATE #cmptmp
			  SET reconciled_flag = 1
		   END
ELSE
    
	    IF @option = 2
		   BEGIN
		      UPDATE #cmptmp
			  SET reconciled_flag = 1
			  WHERE (trx_type/1000)=(@module_id/1000)
			  AND doc_ctrl_num BETWEEN @begin_doc AND @end_doc
			END
ELSE
	
		IF @option = 3
		   BEGIN

				
				IF (@module_id = 0)
				   UPDATE #cmptmp
				   SET form_sequence = app_code + doc_ctrl_num + convert(char,date_cleared) + trx_ctrl_num
				ELSE IF (@module_id = 1)
				   UPDATE #cmptmp
				   SET form_sequence = convert(char,date_cleared) + app_code + doc_ctrl_num + trx_ctrl_num
				ELSE IF (@module_id = 2)
				   UPDATE #cmptmp
				   SET form_sequence = doc_ctrl_num + app_code + convert(char,date_cleared) + trx_ctrl_num
			END

SELECT @amt_deposits = SUM(amount_book * reconciled_flag)
FROM #cmptmp
WHERE cleared_type = 0

SELECT @amt_checks = SUM(amount_book * reconciled_flag)
FROM #cmptmp
WHERE cleared_type != 0

SELECT @amt_deposits, @amt_checks

RETURN
GO
GRANT EXECUTE ON  [dbo].[cmrectmp_sp] TO [public]
GO
