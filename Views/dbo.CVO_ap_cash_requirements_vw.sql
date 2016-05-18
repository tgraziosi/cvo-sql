SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



-- SELECT * FROM dbo.CVO_ap_cash_requirements_vw AS cacrv

CREATE VIEW [dbo].[CVO_ap_cash_requirements_vw] 
AS

SELECT 
v.vendor_code,
m.address_name,
m.vend_class_code vend_type,
v.payment_code,
v.doc_ctrl_num,
'I' IOrC,
v.currency_code,
v.rate_home rate_oper,
-- round(v.amt_net - v.amt_paid_to_date,2) amt_due_cur,
v.date_applied,
v.date_due,
v.amt_discount * v.rate_home discount,
/* - 071613 - report all amounts in natural currency
case 
	when v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  <= 6 then v.amt_net * v.rate_home - v.amt_paid_to_date * v.rate_home
	else 0
end cur_week,
case 
	when (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  > 6) 
	and (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  <= 13) 
	then v.amt_net * v.rate_home - v.amt_paid_to_date * v.rate_home
	else 0
end two_weeks,
case 
	when (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  > 13) 
	and (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  <= 20) 
	then v.amt_net * v.rate_home - v.amt_paid_to_date * v.rate_home
	else 0
end three_weeks,
case 
	when (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  > 20) 
	then v.amt_net * v.rate_home - v.amt_paid_to_date * v.rate_home
	else 0
end beyond
*/
CASE 
	WHEN v.date_due - (DATEDIFF(dd, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906)  <= 6 THEN v.amt_net  - v.amt_paid_to_date 
	ELSE 0
END cur_week,
CASE 
	WHEN (v.date_due - (DATEDIFF(dd, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906)  > 6) 
	AND (v.date_due - (DATEDIFF(dd, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906)  <= 13) 
	THEN v.amt_net - v.amt_paid_to_date 
	ELSE 0
END two_weeks,
CASE 
	WHEN (v.date_due - (DATEDIFF(dd, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906)  > 13) 
	AND (v.date_due - (DATEDIFF(dd, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906)  <= 20) 
	THEN v.amt_net  - v.amt_paid_to_date 
	ELSE 0
END three_weeks,
CASE 
	WHEN (v.date_due - (DATEDIFF(dd, '1/1/1753', CONVERT(DATETIME, GETDATE())) + 639906)  > 20) 
	THEN v.amt_net  - v.amt_paid_to_date 
	ELSE 0
END beyond

FROM apvohdr_all v (NOLOCK) 
JOIN apmaster_all m ON v.vendor_code =  m.vendor_code AND v.pay_to_code = m.pay_to_code 
WHERE v.paid_flag = 0




GO
GRANT REFERENCES ON  [dbo].[CVO_ap_cash_requirements_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_ap_cash_requirements_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ap_cash_requirements_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ap_cash_requirements_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ap_cash_requirements_vw] TO [public]
GO
