SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[arstlaoa_sp]  @customer_code varchar(8), @currency_code varchar(8)
AS




CREATE TABLE #arvpay
(
   customer_code    varchar(8),
   customer_name            varchar(40),
   bal_fwd_flag             smallint,
   seq_id                   smallint
)

EXEC arvalpay_sp @customer_code

DELETE #avail_onacct
FROM #avail_onacct a, #arvpay p
WHERE a.customer_code = p.customer_code



INSERT #avail_onacct
(
  customer_code,  doc_ctrl_num, cr_type, amt_on_acct, in_use, org_id
)
SELECT
  t.customer_code, doc_ctrl_num, case when payment_type = 1 then "CASH" else "OACM" end,amt_on_acct, 0, t.org_id
FROM artrx t, #arvpay p
WHERE t.customer_code = p.customer_code
AND trx_type = 2111
AND payment_type in (1,3)
AND void_flag = 0
AND amt_on_acct > 0
AND nat_cur_code = @currency_code




DELETE #avail_onacct
FROM #avail_onacct a, arinppyt p
WHERE p.trx_type = 2111
AND p.payment_type in ( 2, 4 )
AND p.non_ar_flag = 0
AND   a.doc_ctrl_num = p.doc_ctrl_num
AND p.customer_code = @customer_code  			



DELETE #avail_onacct
FROM #avail_onacct a, #arinppyt4750 c
WHERE a.doc_ctrl_num = c.doc_ctrl_num
AND c.customer_code = @customer_code  			

INSERT #avail_onacct
SELECT   customer_code, doc_ctrl_num, case when payment_type = 1 then "CASH" else "OACM" end,amt_on_acct, 1, org_id
FROM #arinppyt4750

DROP TABLE #arvpay

RETURN
GO
GRANT EXECUTE ON  [dbo].[arstlaoa_sp] TO [public]
GO
