SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[apstlaoa_sp]  @vendor_code varchar(12), @currency_code varchar(8)
AS

DELETE #avail_onacct
FROM #avail_onacct a, #apvpay3450 p
WHERE a.vendor_code = p.vendor_code



INSERT #avail_onacct
(
  vendor_code,  doc_ctrl_num, pa_type, amt_on_acct, in_use, org_id
)
SELECT
  t.vendor_code, doc_ctrl_num, case when payment_type = 1 then "CASH" else "OADM" end,amt_on_acct, 0, org_id
FROM appyhdr t, #apvpay3450 p
WHERE t.vendor_code = p.vendor_code
AND payment_type in (1,3)
AND void_flag = 0
AND amt_on_acct > 0
AND currency_code = @currency_code




DELETE #avail_onacct
FROM #avail_onacct a, apinppyt p
WHERE p.payment_type in ( 2, 4 )
AND   a.doc_ctrl_num = p.doc_ctrl_num



DELETE #avail_onacct
FROM #avail_onacct a, #apinppyt3450 c
WHERE a.doc_ctrl_num = c.doc_ctrl_num

INSERT #avail_onacct
SELECT vendor_code, doc_ctrl_num, case when payment_type = 1 then "CASH" else "OADM" end,amt_on_acct, 1, org_id
FROM #apinppyt3450


RETURN
GO
GRANT EXECUTE ON  [dbo].[apstlaoa_sp] TO [public]
GO
