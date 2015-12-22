SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE VIEW [dbo].[CVO_ap_daily_activity_vw] 
AS

-- vouchers
select 
d.account_code,
g.account_description,
v.vendor_code,
m.address_name,
v.doc_ctrl_num,
'I' IOrC,
case
	when d.balance_oper < 0 then 0
	else round(d.balance_oper,2)
end debit,
case
	when d.balance_oper > 0 then 0
	else round(d.balance_oper,2)*-1
end credit,
h.date_applied,
h.journal_ctrl_num
from gltrx_all h(nolock) 
join gltrxdet d(nolock)  on  h.journal_ctrl_num = d.journal_ctrl_num
join glchart g (nolock) on d.account_code = g.account_code
left join apvohdr_all v (nolock) on d.document_2 = v.trx_ctrl_num  
left join apmaster_all m on v.vendor_code =  m.vendor_code and v.pay_to_code = m.pay_to_code 
where h.journal_type = 'AP'
and h.trx_type in (4091)

union

--debit memo
select 
d.account_code,
g.account_description,
v.vendor_code,
m.address_name,
v.doc_ctrl_num,
'C' IOrC,
case
	when d.balance_oper < 0 then 0
	else round(d.balance_oper,2)
end debit,
case
	when d.balance_oper > 0 then 0
	else round(d.balance_oper,2)*-1
end credit,
h.date_applied,
h.journal_ctrl_num
from gltrx_all h(nolock) 
join gltrxdet d(nolock)  on  h.journal_ctrl_num = d.journal_ctrl_num
join glchart g (nolock) on d.account_code = g.account_code
left join apdmhdr_all v (nolock) on d.document_2 = v.trx_ctrl_num  
left join apmaster_all m on v.vendor_code =  m.vendor_code and v.pay_to_code = m.pay_to_code 
where h.journal_type = 'AP'
and h.trx_type in (4092, 4161, 4162) 


GO
GRANT REFERENCES ON  [dbo].[CVO_ap_daily_activity_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_ap_daily_activity_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ap_daily_activity_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ap_daily_activity_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ap_daily_activity_vw] TO [public]
GO
