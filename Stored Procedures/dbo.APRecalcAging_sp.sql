SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                










CREATE PROC [dbo].[APRecalcAging_sp]
AS
BEGIN




































DELETE 	aptrxage
FROM	aptrxage a
WHERE	a.trx_type = 4171
AND	a.apply_trx_type = 4111
AND	a.apply_to_num NOT IN (
	SELECT	b.trx_ctrl_num
	FROM	aptrxage b
	WHERE 	b.doc_ctrl_num = a.doc_ctrl_num
	AND	b.trx_type = 4111
	AND	b.apply_trx_type = 0 )
























































DELETE 	aptrxage
FROM	aptrxage a
WHERE	a.trx_type = 4181
AND	a.apply_trx_type = 4111
AND	a.apply_to_num NOT IN (
	SELECT	b.trx_ctrl_num
	FROM	aptrxage b
	WHERE 	b.doc_ctrl_num = a.doc_ctrl_num
	AND	b.trx_type = 4111
	AND	b.apply_trx_type = 0 )


CREATE TABLE #aptrxage
(
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	doc_ctrl_num		varchar(16),
	ref_id				int,
	apply_to_num		varchar(16),
	apply_trx_type		smallint,
	date_doc			int,
	date_applied		int,
	date_due			int,
	date_aging			int,
	vendor_code			varchar(12),
	pay_to_code			varchar(8),
	class_code			varchar(8),
	branch_code			varchar(8),
	amount				float,
	amt_paid_to_date	float,
	cash_acct_code		varchar(32),
	paid_flag			smallint,
	date_paid			int,
	nat_cur_code		varchar(8),
	rate_home			float,
	rate_oper			float,
	journal_ctrl_num	varchar(16),
	account_code		varchar(32)
)

SELECT trx_ctrl_num,trx_type,apply_to_num,apply_trx_type, doc_ctrl_num,COUNT(*) counter 
INTO 	#work
FROM 	aptrxage
WHERE 	trx_type = 4181
GROUP BY 
	doc_ctrl_num, trx_ctrl_num, apply_to_num, trx_type,apply_trx_type
HAVING count(*) > 1

INSERT	#aptrxage (
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	ref_id,
	apply_to_num,
	apply_trx_type,
	date_doc,
	date_applied,
	date_due,
	date_aging,
	vendor_code,
	pay_to_code,
	class_code,
	branch_code,
	amount,
	amt_paid_to_date,
	cash_acct_code,
	paid_flag,
	date_paid,
	nat_cur_code,
	rate_home,
	rate_oper,
	journal_ctrl_num,
	account_code)

SELECT DISTINCT
	a.trx_ctrl_num,
	a.trx_type,
	a.doc_ctrl_num,
	ref_id,
	a.apply_to_num,
	a.apply_trx_type,
	date_doc,
	date_applied,
	date_due,
	date_aging,
	vendor_code,
	pay_to_code,
	class_code,
	branch_code,
	amount,
	amt_paid_to_date,
	cash_acct_code,
	paid_flag,
	date_paid,
	nat_cur_code,
	rate_home,
	rate_oper,
	journal_ctrl_num,
	dbo.IBAcctMask_fn(account_code,a.org_id)
FROM	aptrxage a, #work b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num
AND	a.doc_ctrl_num=b.doc_ctrl_num
AND	a.apply_to_num=b.apply_to_num
AND	a.trx_type=b.trx_type
AND	a.apply_trx_type=b.apply_trx_type


DELETE 	aptrxage 
FROM	aptrxage a, #work b
WHERE	a.trx_ctrl_num = b.trx_ctrl_num
AND	a.doc_ctrl_num=b.doc_ctrl_num
AND	a.apply_to_num=b.apply_to_num
AND	a.trx_type=b.trx_type
AND	a.apply_trx_type=b.apply_trx_type

INSERT	aptrxage (
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	ref_id,
	apply_to_num,
	apply_trx_type,
	date_doc,
	date_applied,
	date_due,
	date_aging,
	vendor_code,
	pay_to_code,
	class_code,
	branch_code,
	amount,
	amt_paid_to_date,
	cash_acct_code,
	paid_flag,
	date_paid,
	nat_cur_code,
	rate_home,
	rate_oper,
	journal_ctrl_num,
	account_code)
SELECT
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	ref_id,
	apply_to_num,
	apply_trx_type,
	date_doc,
	date_applied,
	date_due,
	date_aging,
	vendor_code,
	pay_to_code,
	class_code,
	branch_code,
	amount,
	amt_paid_to_date,
	cash_acct_code,
	paid_flag,
	date_paid,
	nat_cur_code,
	rate_home,
	rate_oper,
	journal_ctrl_num,
	dbo.IBAcctMask_fn(account_code,org_id)
FROM 	#aptrxage





CREATE TABLE #aptrxage_vo
(
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	doc_ctrl_num		varchar(16),
	ref_id				int,
	apply_to_num		varchar(16),
	apply_trx_type		smallint,
	date_doc			int,
	date_applied		int,
	date_due			int,
	date_aging			int,
	vendor_code			varchar(12),
	pay_to_code			varchar(8),
	class_code			varchar(8),
	branch_code			varchar(8),
	amount				float,
	amt_paid_to_date	float,
	cash_acct_code		varchar(32),
	paid_flag			smallint,
	date_paid			int,
	nat_cur_code		varchar(8),
	rate_home			float,
	rate_oper			float,
	journal_ctrl_num	varchar(16),
	account_code		varchar(32),
	flag				smallint
)





INSERT #aptrxage_vo
(
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	ref_id,
	apply_to_num,
	apply_trx_type,
	date_doc,
	date_applied,
	date_due,
	date_aging,
	vendor_code,
	pay_to_code,
	class_code,
	branch_code,
	amount,
	amt_paid_to_date,
	cash_acct_code,
	paid_flag,
	date_paid,
	nat_cur_code,
	rate_home,
	rate_oper,
	journal_ctrl_num,
	account_code,
	flag
)
SELECT
	a.trx_ctrl_num,
	4091,
	a.doc_ctrl_num,
	1,
	a.trx_ctrl_num,
	0,
	a.date_doc,
	a.date_applied,
	a.date_due,
	a.date_aging,
	a.vendor_code,
	a.pay_to_code,
	a.class_code,
	a.branch_code,
	a.amt_net,
	0.0E0,
	"",
	0,
	0,
	a.currency_code,
	a.rate_home,
	a.rate_oper,
	a.journal_ctrl_num,
	dbo.IBAcctMask_fn(b.ap_acct_code,a.org_id),
	0
FROM apvohdr a, apaccts b
WHERE a.posting_code = b.posting_code
AND date_aging != 0





INSERT #aptrxage_vo
(
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	ref_id,
	apply_to_num,
	apply_trx_type,
	date_doc,
	date_applied,
	date_due,
	date_aging,
	vendor_code,
	pay_to_code,
	class_code,
	branch_code,
	amount,
	amt_paid_to_date,
	cash_acct_code,
	paid_flag,
	date_paid,
	nat_cur_code,
	rate_home,
	rate_oper,
	journal_ctrl_num,
	account_code,
	flag
)
SELECT
	a.trx_ctrl_num,
	4091,
	a.doc_ctrl_num,
	b.ref_id,
	a.trx_ctrl_num,
	0,
	a.date_doc,
	a.date_applied,
	b.date_due,
	b.date_aging,
	a.vendor_code,
	a.pay_to_code,
	a.class_code,
	a.branch_code,
	b.amount,
	0.0E0,
	"",
	0,
	0,
	a.currency_code,
	a.rate_home,
	a.rate_oper,
	a.journal_ctrl_num,
	dbo.IBAcctMask_fn(c.ap_acct_code,a.org_id),
	0
FROM apvohdr a, aptrxage b, apaccts c
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND b.trx_type = 4091
AND a.posting_code = c.posting_code
AND a.date_aging = 0

DELETE	aptrxage
WHERE	trx_type = 4091





WHILE (1=1)
  BEGIN

	SET ROWCOUNT 10000

	UPDATE #aptrxage_vo
	SET flag = 1

	SET ROWCOUNT 0

	INSERT aptrxage
	(
	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	ref_id,
	apply_to_num,
	apply_trx_type,
	date_doc,
	date_applied,
	date_due,
	date_aging,
	vendor_code,
	pay_to_code,
	class_code,
	branch_code,
	amount,
	amt_paid_to_date,
	cash_acct_code,
	paid_flag,
	date_paid,
	nat_cur_code,
	rate_home,
	rate_oper,
	journal_ctrl_num,
	account_code
	)
SELECT 	trx_ctrl_num,
	trx_type,
	doc_ctrl_num,
	ref_id,
	apply_to_num,
	apply_trx_type,
	date_doc,
	date_applied,
	date_due,
	date_aging,
	vendor_code,
	pay_to_code,
	class_code,
	branch_code,
	amount,
	0.0,
	cash_acct_code,
	paid_flag,
	date_paid,
	nat_cur_code,
	rate_home,
	rate_oper,
	journal_ctrl_num,
	dbo.IBAcctMask_fn(account_code,org_id)
FROM #aptrxage_vo
WHERE flag = 1

IF @@rowcount = 0 BREAK

DELETE #aptrxage_vo
WHERE flag = 1

CHECKPOINT

END 

DROP TABLE #aptrxage
DROP TABLE #aptrxage_vo
DROP TABLE #work

END 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[APRecalcAging_sp] TO [public]
GO
