SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





-- updated 3/12/2013 - tag - add posted date
-- select journal_type, app_id, trx_type, * from gltrx where journal_type = 'ap' 
-- select * from cvo_jrnlines_vw where journal_type = 'ap' 
-- select * From apvohdr
-- select * From apmaster

CREATE VIEW [dbo].[CVO_Jrnlines_vw] AS
 SELECT 
  	t1.journal_ctrl_num,
	t2.journal_type,					-- CVO
  	t2.date_applied,
  	t2.date_posted, -- 3/12/13 - tag
  	t1.sequence_id,
  	cast(t1.account_code as varchar(36)) as account_code, 
  	-- 021814 - tag - add vendor name and vendor code for AP entries
  	-- 033114 - tag - add customer name for AR entries
  	case when t2.trx_type between 4011 and 4099 -- ap voucher/debit entries
        then isnull((select top 1 ap.address_name from apmaster ap
        inner join apvohdr vo  on vo.vendor_code = ap.vendor_code
         where vo.trx_ctrl_num = t1.document_2),'')
         when t2.trx_type between 2002 and 2162
            then isnull((select top 1 ar.customer_name from arcust ar
                where ar.customer_code = t1.document_1),'')
        else '' end as address_name,
    case when t2.trx_type between 4011 and 4099 -- ap voucher/debit entries
        then isnull((select top 1 vendor_code from apvohdr where trx_ctrl_num = t1.document_2),'')
        else '' end as vendor_code,
    case when t2.trx_type between 4011 and 4099
        then (select top 1 date_doc from apvohdr where trx_ctrl_num = t1.document_2) 
        end as date_doc, -- 032414
  	t1.description,
	t1.document_1,
	t1.document_2,
	t1.nat_cur_code, 
  	t1.nat_balance,
	t1.reference_code,
  	t1.rate_type_home,
	t1.rate,
	t2.home_cur_code,
  	t1.balance,
	t1.rate_type_oper,
	t1.rate_oper,
	t2.oper_cur_code,
	t1.balance_oper,
	posted_flag = case t1.posted_flag 
		when 0 then 'No'
		when 1 then 'Yes'
	end,
 	x_date_applied=t2.date_applied,
 	x_sequence_id=t1.sequence_id,
 	x_nat_balance=t1.nat_balance,
	x_rate=t1.rate,
 	x_balance=t1.balance,
	x_rate_oper=t1.rate_oper,
	x_balance_oper=t1.balance_oper
FROM 
  	gltrxdet t1 inner join gltrx t2 on t1.journal_ctrl_num = t2.journal_ctrl_num




GO
GRANT REFERENCES ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
