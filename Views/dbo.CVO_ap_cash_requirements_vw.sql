SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE view [dbo].[CVO_ap_cash_requirements_vw] 
as

select 
v.vendor_code,
m.address_name,
m.vend_class_code vend_type,
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
case 
	when v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  <= 6 then v.amt_net  - v.amt_paid_to_date 
	else 0
end cur_week,
case 
	when (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  > 6) 
	and (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  <= 13) 
	then v.amt_net - v.amt_paid_to_date 
	else 0
end two_weeks,
case 
	when (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  > 13) 
	and (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  <= 20) 
	then v.amt_net  - v.amt_paid_to_date 
	else 0
end three_weeks,
case 
	when (v.date_due - (datediff(dd, '1/1/1753', convert(datetime, getdate())) + 639906)  > 20) 
	then v.amt_net  - v.amt_paid_to_date 
	else 0
end beyond

from apvohdr_all v (nolock) 
join apmaster_all m on v.vendor_code =  m.vendor_code and v.pay_to_code = m.pay_to_code 
where v.paid_flag = 0



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
