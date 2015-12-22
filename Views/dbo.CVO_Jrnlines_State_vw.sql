SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE VIEW [dbo].[CVO_Jrnlines_State_vw] AS
-- 6/12/2012 - tag - For sales tax reporting, include the order's ship-to-state where available.

-- select * from cvo_jrnlines_state_vw where date_applied between 735234 and 735264 and account_code like '2700%'
-- select * from cvo_jrnlines_STATE_vw where date_applied between 735234 and 735264 and account_code like '2700%'

SELECT distinct
  	gd.journal_ctrl_num,
	g.journal_type,					-- CVO
  	g.date_applied,
  	gd.sequence_id,
  	cast(gd.account_code as varchar(36)) as account_code, 
  	gd.description,
	gd.document_1,
	gd.document_2,
	gd.nat_cur_code, 
  	gd.nat_balance,
	gd.reference_code,
  	gd.rate_type_home,
	gd.rate,
	g.home_cur_code,
  	gd.balance,
	gd.rate_type_oper,
	gd.rate_oper,
	g.oper_cur_code,
	gd.balance_oper,
	posted_flag = case gd.posted_flag 
		when 0 then 'No'
		when 1 then 'Yes'
	end,
 	x_date_applied=g.date_applied,
 	x_sequence_id=gd.sequence_id,
 	x_nat_balance=gd.nat_balance,
	x_rate=gd.rate,
 	x_balance=gd.balance,
	x_rate_oper=gd.rate_oper,
	x_balance_oper=gd.balance_oper
,
 case when isnull(o.ship_to_state,'') <> '' then isnull(o.ship_to_state,'')
    when isnumeric(substring(x.doc_desc,4,7)) = 0 then 
        (SELECT TOP (1) STATE FROM ARMASTER 
        WHERE CUSTOMER_CODE = X.CUSTOMER_CODE 
        AND SHIP_TO_CODE = X.SHIP_TO_CODE)
    ELSE 
     isnull((select top (1) ship_to_state from orders (nolock) 
      where order_no = cast(substring(x.doc_desc,4,7) as int) and ext = 0 ),
      (select top (1) state from armaster where customer_code = x.customer_code and 
      ship_to_code = x.ship_to_code))
    END As Ship_State
    
    
FROM 
gltrxdet gd (nolock) 
inner join gltrx g (nolock) on gd.journal_ctrl_num = g.journal_ctrl_num
left join artrx x (nolock) on gd.document_2 = x.doc_ctrl_num 
	 and gd.journal_ctrl_num = x.gl_trx_id
left join orders_invoice oi (nolock) on oi.trx_ctrl_num = x.trx_ctrl_num
left join orders o (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
-- where gd.document_2 = 'crm0037941'


GO
GRANT SELECT ON  [dbo].[CVO_Jrnlines_State_vw] TO [public]
GO
