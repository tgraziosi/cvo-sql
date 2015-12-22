SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apldoa_sp] 	@vendor_code varchar(12), 
							@nat_cur_code varchar(8), 
							@org_id varchar(30),
							@restrict_by_cur smallint
AS 

DECLARE @all_org varchar(50)
SELECT @all_org  = ''


IF (@org_id ='')
	SELECT @all_org  = ' AND 1=1'
else
	SELECT @all_org = ' AND org_id = ''' + @org_id + ''''


CREATE TABLE #amts( doc_ctrl_num varchar(16) NULL, 
		vendor_code varchar(12) NULL, 
		cash_acct_code varchar(32) NULL , 
		amount  float NULL )




EXEC('
INSERT #onacct
(trx_ctrl_num,
 doc_ctrl_num,
 date_doc,
 date_applied,
 payment_code,
 cash_acct_code,
 amt_on_acct,
 nat_cur_code,
 rate_home,
 rate_oper,
 rate_type_home,
 rate_type_oper )
SELECT trx_ctrl_num,
	   doc_ctrl_num,
	   date_doc,
	   date_applied,
	   payment_code,
	   cash_acct_code,
	   amt_on_acct,
	   currency_code,
	   rate_home,
	   rate_oper,
	   rate_type_home,
	   rate_type_oper
FROM appyhdr
WHERE vendor_code =  '''+ @vendor_code +'''
AND void_flag = 0
AND ((amt_on_acct) > (0.0) + 0.0000001)
AND payment_type IN (1,3)' + @all_org ) 





IF (@restrict_by_cur = 1)
   DELETE #onacct
   WHERE nat_cur_code != @nat_cur_code




EXEC('
DELETE #onacct
FROM #onacct a, apinppyt b
WHERE a.doc_ctrl_num = b.doc_ctrl_num
AND b.vendor_code = '''+ @vendor_code + '''
AND a.cash_acct_code = b.cash_acct_code
AND b.trx_type = 4112 ' + @all_org )









EXEC('
INSERT  #amts
SELECT  a.doc_ctrl_num, 
		a.vendor_code, 
		a.cash_acct_code, 
		amount = SUM(a.amt_payment - a.amt_on_acct)
FROM	apinppyt a, #onacct b
WHERE a.doc_ctrl_num = b.doc_ctrl_num
AND a.vendor_code = '''+ @vendor_code +''' 
AND a.cash_acct_code = b.cash_acct_code  ' + @all_org + 'GROUP BY a.doc_ctrl_num, a.vendor_code, a.cash_acct_code' )











UPDATE #onacct
SET amt_on_acct = amt_on_acct - b.amount
FROM #onacct, #amts b
WHERE #onacct.doc_ctrl_num = b.doc_ctrl_num
AND #onacct.cash_acct_code = b.cash_acct_code

DROP TABLE #amts





DELETE #onacct
WHERE ((amt_on_acct) <= (0.0) + 0.0000001)


GO
GRANT EXECUTE ON  [dbo].[apldoa_sp] TO [public]
GO
