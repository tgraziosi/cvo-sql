SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[CMBTInsertTempTable_sp]			@process_ctrl_num   varchar(16),
                                			@batch_ctrl_num		varchar(16),
											@debug_level		smallint = 0
   
AS

DECLARE
    @result int,
	@acct_code_trans_from 	varchar(32),
	@acct_code_trans_to 	varchar(32),
	@acct_code_clr 			varchar(32),
   	@home_cur				varchar(8),
	@oper_cur				varchar(8),
	@rate_type_home			varchar(8),
	@rate_type_oper			varchar(8),
	@rate_home				float,
	@rate_oper				float

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'cmbtitt.cpp' + ', line ' + STR( 58, 5 ) + ' -- ENTRY: '


SELECT 
	@acct_code_clr 	= clearing_acct,
	@rate_type_home = rate_type_home,
	@rate_type_oper = rate_type_oper
FROM  cmco

SELECT @home_cur = home_currency,
	   @oper_cur = oper_currency
FROM glco


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'cmbtitt.cpp' + ', line ' + STR( 72, 5 ) + ' -- MSG: ' + 'Load #cminpbtr_work'
INSERT	#cminpbtr_work 
(
	trx_ctrl_num,
	trx_type,
	description,
	doc_ctrl_num,
	date_applied,
	date_document,
	date_entered,
	cash_acct_code_from,
	cash_acct_code_to,
	acct_code_trans_from,
	acct_code_trans_to,
	acct_code_clr,
	currency_code_from,
	currency_code_to,
	curr_code_trans_from,
	curr_code_trans_to,
	trx_type_cls_from,
	trx_type_cls_to,
 	amount_from,
 	amount_to,
 	bank_charge_amt_from,
 	bank_charge_amt_to,
	batch_code,
	user_id,
	auto_rec_flag,
	hold_flag,
	prc_gl_flag,
	posted_flag,
	rate_type_home,
	rate_type_oper,
	rate_home_from,
	rate_oper_from,
	rate_home_to,
	rate_oper_to,
	from_reference_code,
	from_expense_account_code,
	from_expense_reference_code,	 
	to_reference_code,
	to_expense_account_code,
	to_expense_reference_code,
	from_org_id,
	to_org_id
)
SELECT  	 
	trx_ctrl_num,
	7030,
	description,
	doc_ctrl_num,
	date_applied,
	date_document,
	date_entered,
	cash_acct_code_from,
	cash_acct_code_to,
	'',
	'',
	'',
	currency_code_from,
	currency_code_to,
	currency_code_from,
	currency_code_to,
	trx_type_cls_from,
	trx_type_cls_to,
 	amount_from,
 	amount_to,
 	bank_charge_amt_from,
 	bank_charge_amt_to,
	batch_code,
	user_id,
	0,
	hold_flag,
	prc_gl_flag,
	posted_flag,
	@rate_type_home,
	@rate_type_oper,
	0.0,
	0.0,
	0.0,
	0.0,
	from_reference_code,
	from_expense_account_code,
	from_expense_reference_code,	 
	to_reference_code,
	to_expense_account_code,
	to_expense_reference_code,
	from_org_id,
	to_org_id
	
FROM	cminpbtr
WHERE	batch_code = @batch_ctrl_num 

IF( @@error != 0 )
        RETURN -1


	UPDATE #cminpbtr_work 
	SET from_org_id = ISNULL((select organization_id from Organization where outline_num = '1'),'') 
	WHERE from_org_id IS NULL
        
        UPDATE #cminpbtr_work 
	SET to_org_id= ISNULL((select organization_id from Organization where outline_num = '1'),'') 
	WHERE to_org_id IS NULL


	    IF( @@error != 0 )
        	RETURN -1




UPDATE #cminpbtr_work
SET acct_code_trans_from  = b.from_expense_account_code
FROM #cminpbtr_work a,  cminpbtr b, cmtrxcls c
WHERE a.trx_ctrl_num = b.trx_ctrl_num 
AND a.trx_type_cls_from = c.trx_type_cls

UPDATE #cminpbtr_work
SET acct_code_trans_to  = b.to_expense_account_code
FROM #cminpbtr_work a,  cminpbtr b, cmtrxcls c
WHERE a.trx_ctrl_num = b.trx_ctrl_num 
AND a.trx_type_cls_to = c.trx_type_cls

UPDATE #cminpbtr_work 
SET acct_code_clr = @acct_code_clr
FROM #cminpbtr_work
WHERE currency_code_from != currency_code_to	

CREATE TABLE #rates (from_currency varchar(8),
		   to_currency varchar(8),
				   rate_type varchar(8),
				   date_applied int,
				   rate float)
IF @@error <> 0
   RETURN -1




INSERT #rates (
	from_currency,
	to_currency,
	rate_type,
	date_applied,
	rate)

SELECT DISTINCT 
	currency_code_from,
 	@home_cur,
	rate_type_home,
	date_applied,
	0.0E0
FROM 	#cminpbtr_work




INSERT #rates (
	from_currency,
	to_currency,
	rate_type,
	date_applied,
	rate)

SELECT DISTINCT 
	currency_code_from,
 	@oper_cur,
	rate_type_home,
	date_applied,
	0.0E0
FROM 	#cminpbtr_work




INSERT #rates (
	from_currency,
	to_currency,
	rate_type,
	date_applied,
	rate)

SELECT DISTINCT 
	currency_code_to,
 	@home_cur,
	rate_type_home,
	date_applied,
	0.0E0
FROM 	#cminpbtr_work




INSERT #rates (
	from_currency,
	to_currency,
	rate_type,
	date_applied,
	rate)

SELECT DISTINCT 
	currency_code_to,
 	@oper_cur,
	rate_type_home,
	date_applied,
	0.0E0
FROM 	#cminpbtr_work


EXEC CVO_Control..mcrates_sp




UPDATE #cminpbtr_work
SET rate_home_from = b.rate
FROM #cminpbtr_work a, #rates b
WHERE a.currency_code_from = b.from_currency
AND b.to_currency = @home_cur
AND a.date_applied = b.date_applied
AND a.rate_type_home = b.rate_type




UPDATE #cminpbtr_work
SET rate_oper_from = b.rate
FROM #cminpbtr_work a, #rates b
WHERE a.currency_code_from = b.from_currency
AND b.to_currency = @oper_cur
AND a.date_applied = b.date_applied
AND a.rate_type_oper = b.rate_type




UPDATE #cminpbtr_work
SET rate_home_to = b.rate
FROM #cminpbtr_work a, #rates b
WHERE a.currency_code_to = b.from_currency
AND b.to_currency = @home_cur
AND a.date_applied = b.date_applied
AND a.rate_type_home = b.rate_type




UPDATE #cminpbtr_work
SET rate_oper_to = b.rate
FROM #cminpbtr_work a, #rates b
WHERE a.currency_code_to = b.from_currency
AND b.to_currency = @oper_cur
AND a.date_applied = b.date_applied
AND a.rate_type_oper = b.rate_type

DROP TABLE #rates
	
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'cmbtitt.cpp' + ', line ' + STR( 331, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[CMBTInsertTempTable_sp] TO [public]
GO
