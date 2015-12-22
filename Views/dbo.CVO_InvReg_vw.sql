SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO







--select * from cvo_invreg_vw where customer_code = '010656'

CREATE VIEW [dbo].[CVO_InvReg_vw]
AS
-- invoices
-- v1.1 - TAG - 3/9/2012 - Update from logic
-- v1.2 - TAG - 031612 - added salesperson, territory and order type
-- v1.3 - tag - 5/7/2012 - use orders_invoice table to get back to orders table
-- v1.4 - tag - 6/7/2012 - add ship-to_state
--- tag - 10/24/2012 - fixup ship_to_state
-- v1.5 - tag - 041015 - show ship-to country

SELECT	
	M.ADDRESS_NAME,
	X.CUSTOMER_CODE,
	IsNull(m.state,'') as [State],
	IsNull(m.Country_code,'') as Country,
-- 10/24/2012
	[ship_to_state] = case when isnull(o.ship_to_state,'') = '' then ar.state else o.ship_to_state end,
	--isnull(o.ship_to_state, ar.state) 
		--(select top 1 ship_to_state from orders o (nolock) inner join orders_invoice oi (nolock) 
		--on o.order_no = oi.order_no and o.ext = oi.order_ext 
		--where oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	--as [ship_to_state],
	[ship_to_country_cd] = case when isnull(o.ship_to_country_cd,'') = '' then ar.country_code else
		o.ship_to_country_cd end,
	--	isnull(o.ship_to_country_cd, ar.country_code)
		--(select top 1 ship_to_country_cd from orders o (nolock) inner join orders_invoice oi (nolock) 
		--on o.order_no = oi.order_no and o.ext = oi.order_ext 
		--where oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	-- as [ship_to_country_cd],
--	isnull(o.ship_to_state,'') as [ship_to_state],
--	 ((select top 1 ship_to_state from orders (nolock) where 
--		left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = orders.order_no))) as [Ship_To_State],
	INVCRM =  'Invoice',
	X.DOC_CTRL_NUM,
	X.TRX_CTRL_NUM,
	X.ORG_ID,
	PAST_DUE_STATUS=CASE CONVERT(INT,SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))* SIGN(1 - X.PAID_FLAG))
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,
	SETTLED_STATUS= CASE X.PAID_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,
	HOLD_FLAG='NO',
	POSTED_FLAG='YES',
	X.NAT_CUR_CODE,
	X.amt_gross,
	x.amt_discount,
	X.AMT_NET - X.amt_freight - X.amt_tax  as AMT_NET,
	X.amt_freight,
	X.amt_tax,
	--X.AMT_NET,
	X.AMT_PAID_TO_DATE,
	UNPAID_BALANCE = X.AMT_NET - X.AMT_PAID_TO_DATE,
	AMT_PAST_DUE = (X.AMT_NET - X.AMT_PAID_TO_DATE)*(SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))* SIGN(1 - X.PAID_FLAG)),
	RECURRING_FLAG = '',
	X.DATE_DOC,
	X.DATE_APPLIED,
	X.DATE_DUE,
	X.DATE_SHIPPED,
	LAST_PAYMENT_DATE=X.DATE_PAID,
	X.CUST_PO_NUM,
	X.ORDER_CTRL_NUM,
	X.GL_TRX_ID,
-- 3/16/12 - tag - add salesperson and territory
	x.salesperson_code,
	x.territory_code,
-- 5/7/2012
--    case 
--	 when x.order_ctrl_num<>''
--	 then (select top 1 user_category from orders_all (nolock) where 
--		left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = orders_all.order_no)
--	 else ''
--    end order_type
--	isnull(o.user_category,'') as order_type
-- 10/24/2012
	isnull(o.user_category,
		(select top 1 user_category from orders o (nolock), orders_invoice oi (nolock) where
		o.order_no = oi.order_no and o.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as order_type
-- 5/7/2012
	,isnull(co.promo_id,
		(select top 1 promo_id from cvo_orders_all co (nolock), orders_invoice oi (nolock) where
		co.order_no = oi.order_no and co.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as promo_id
FROM         
	ARTRX AS X (nolock) 
	INNER JOIN ARMASTER AS M (nolock) ON X.CUSTOMER_CODE = M.CUSTOMER_CODE
	inner join armaster as ar (nolock) on x.customer_code = ar.customer_code		
			and x.ship_to_code = ar.ship_To_code
	left outer join orders_invoice oi (nolock) on x.trx_ctrl_num = oi.trx_ctrl_num
	left outer join orders o (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext
	left outer join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
WHERE     
	(M.ADDRESS_TYPE = 0) 
--AND (X.DOC_CTRL_NUM = X.APPLY_TO_NUM) 
--AND (X.TRX_TYPE = X.APPLY_TRX_TYPE) 
/** v1.1 starts **/
--AND (X.TRX_TYPE IN (2021, 2031))
--AND X.void_flag = 0
--AND X.doc_desc NOT LIKE '%NONSALES%'
and x.trx_type in ('2031')
AND x.DOC_DESC NOT LIKE 'CONVERTED%'
AND x.doc_desc NOT LIKE '%NONSALES%'
AND x.doc_ctrl_num NOT LIKE 'CB%'
AND x.doc_ctrl_num NOT LIKE 'FIN%'
and x.void_flag = 0
and x.posted_flag = 1
-- end v1.1 


UNION 

-- credits

SELECT 
	M.ADDRESS_NAME,	 
	M.CUSTOMER_CODE,	
	IsNull(m.state,'') as [State],
	IsNull(m.Country_code,'') as Country,
	[ship_to_state] = case when isnull(o.ship_to_state,'') = '' then ar.state else o.ship_to_state end,
	--	isnull(o.ship_to_state, ar.state)
		--(select top 1 ship_to_state from orders o (nolock), orders_invoice oi (nolock) where
		--o.order_no = oi.order_no and o.ext = oi.order_ext and 
		--oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	-- as [ship_to_state],
	[ship_to_country_cd] = case when isnull(o.ship_to_country_cd,'') = '' then ar.country_code else o.ship_to_country_cd end,
	-- isnull(o.ship_to_country_cd, ar.country_code)
		--(select top 1 ship_to_country_cd from orders o (nolock) inner join orders_invoice oi (nolock) 
		--on o.order_no = oi.order_no and o.ext = oi.order_ext 
		--where oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	-- as [ship_to_country_cd],
--	isnull(o.ship_to_state,'') as [ship_to_state],
--	 ((select top 1 ship_to_state from orders (nolock) where 
--		left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = orders.order_no))) as [Ship_To_State],
	INVCRM = 'Credit',
	X.DOC_CTRL_NUM,
	X.TRX_CTRL_NUM,
	X.ORG_ID,	
	PAST_DUE_STATUS = '',
	SETTLED_STATUS = '',		
	HOLD_FLAG = 'NO',		
	POSTED_FLAG = CASE X.POSTED_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,		
	X.NAT_CUR_CODE,
	-- tag - 032213
	case when x.recurring_flag = 1 then X.amt_gross * -1 else 0 end as amt_gross,
	x.amt_discount *-1 as amt_discount,
	case when x.recurring_flag = 1  then (X.AMT_NET - X.amt_freight - X.amt_tax) *-1 else 0 end as AMT_NET,
	case when x.recurring_flag in (1,3,4) then X.amt_freight * -1 else 0 end as amt_freight,
	case when x.recurring_flag in (1,2,4) then X.amt_tax * -1 else 0 end as amt_tax,
	-- X.AMT_NET * -1 as amt_net,
	X.AMT_PAID_TO_DATE,
	case when x.recurring_flag = 1 then (x.amt_net - x.amt_paid_to_date) * -1
		 when x.recurring_flag = 2 then (x.amt_tax - x.amt_paid_to_date) * -1
		 when x.recurring_flag = 3 then (x.amt_freight - x.amt_paid_to_date) * -1
		 when x.recurring_flag = 4 then (x.amt_Tax + x.amt_freight - x.amt_paid_to_date) * -1 
		 else 0 end as unpaid_balance,
--	UNPAID_BALANCE = (X.AMT_NET - X.AMT_PAID_TO_DATE)  * -1,
	case when x.recurring_flag = 1 then (x.amt_net - x.amt_paid_to_date) * -1 *
		 SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))* SIGN(1 - X.PAID_FLAG)
		 when x.recurring_flag = 2 then (x.amt_tax - x.amt_paid_to_date) * -1 *
		 SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))* SIGN(1 - X.PAID_FLAG)
		 when x.recurring_flag = 3 then (x.amt_freight - x.amt_paid_to_date) * -1 *
		 SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))* SIGN(1 - X.PAID_FLAG)
		 when x.recurring_flag = 4 then (x.amt_Tax + x.amt_freight - x.amt_paid_to_date) * -1 *
		 SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))* SIGN(1 - X.PAID_FLAG)
		 else 0 end as amt_past_due,
--	AMT_PAST_DUE =(X.AMT_NET - X.AMT_PAID_TO_DATE)*(SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))* SIGN(1 - X.PAID_FLAG)) * -1,
	RECURRING_FLAG = T3.CM_DESCR,						  
	X.DATE_DOC, 		
	X.DATE_APPLIED,
	X.DATE_DUE,
	X.DATE_SHIPPED,
	LAST_PAYMENT_DATE=X.DATE_PAID,	
	X.CUST_PO_NUM,
	X.ORDER_CTRL_NUM,
	X.GL_TRX_ID,
-- 3/16/12 - tag - add salesperson and territory
	x.salesperson_code,
	x.territory_code,
-- 5/7/2012
--    case 
--	 when x.order_ctrl_num<>''
--	 then (select top 1 user_category from orders_all (nolock) where 
--		left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = orders_all.order_no)
--	 else ''
--    end order_type
-- 10/24/2012
	isnull(o.user_category,
		(select top 1 user_category from orders o (nolock), orders_invoice oi (nolock) where
		o.order_no = oi.order_no and o.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as order_type
--	isnull(o.user_category,'') as order_type
-- 5/7/2012
	,isnull(co.promo_id,
		(select top 1 promo_id from cvo_orders_all co (nolock), orders_invoice oi (nolock) where
		co.order_no = oi.order_no and co.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as promo_id

FROM         
	ARTRX AS X (nolock) INNER JOIN
	ARMASTER AS M (nolock) ON X.CUSTOMER_CODE = M.CUSTOMER_CODE 
	left outer join armaster ar (nolock) on ar.customer_code = x.customer_code and ar.ship_to_code = x.ship_to_code
	left join ARCMTYPE AS T3 (nolock)  ON X.RECURRING_FLAG = T3.CM_TYPE
	left outer join orders_invoice oi (nolock) on x.trx_ctrl_num = oi.trx_ctrl_num
	left outer join orders o (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext
	left outer join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext

WHERE    
	(M.ADDRESS_TYPE = 0) 
AND	(X.TRX_TYPE IN (2032)) 
AND (X.POSTED_FLAG = 1)
AND X.void_flag = 0
AND X.doc_desc NOT LIKE '%NONSALES%'
-- v1.1
AND x.DOC_DESC NOT LIKE 'CONVERTED%'
AND x.doc_desc NOT LIKE '%NONSALES%'
AND x.doc_ctrl_num NOT LIKE 'CB%'
AND x.doc_ctrl_num NOT LIKE 'FIN%'
--v1.1

union

-- unposted invoices
select 
	M.ADDRESS_NAME,
	X.CUSTOMER_CODE,
	IsNull(m.state,'') as [State],
	IsNull(m.Country_code,'') as Country,
	isnull(o.ship_to_state,
		(select top 1 ship_to_state from orders o (nolock), orders_invoice oi (nolock) where
		o.order_no = oi.order_no and o.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as [ship_to_state],
	isnull(o.ship_to_country_cd,
		(select top 1 ship_to_country_cd from orders o (nolock) inner join orders_invoice oi (nolock) 
		on o.order_no = oi.order_no and o.ext = oi.order_ext 
		where oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as [ship_to_country_cd],
--	isnull(o.ship_to_state,''),
--	 ((select top 1 ship_to_state from orders (nolock) where 
--		left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = orders.order_no))) as [Ship_To_State],
	INVCRM =  'Invoice',
	X.DOC_CTRL_NUM,
	X.TRX_CTRL_NUM,
	X.ORG_ID,
	PAST_DUE_STATUS=CASE CONVERT(INT,SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE)))
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,
	SETTLED_STATUS = 'NO',
	HOLD_FLAG= case
		when X.hold_flag = 1 then 'YES'
		else 'NO'
		end,
	POSTED_FLAG = 'NO',
	X.NAT_CUR_CODE,
	X.amt_gross,
	x.amt_discount,
	X.AMT_NET - X.amt_freight - X.amt_tax  as AMT_NET,
	X.amt_freight,
	X.amt_tax,
	--X.AMT_NET,
	0 as AMT_PAID_TO_DATE,	--X.AMT_PAID_TO_DATE,
	UNPAID_BALANCE = X.amt_due,	--X.AMT_NET - X.AMT_PAID_TO_DATE,
	AMT_PAST_DUE = (X.AMT_NET - 0)*(SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))),
	RECURRING_FLAG = '',
	X.DATE_DOC,
	X.DATE_APPLIED,
	X.DATE_DUE,
	X.DATE_SHIPPED,
	LAST_PAYMENT_DATE= 0,	-- X.DATE_PAID,
	X.CUST_PO_NUM,
	X.ORDER_CTRL_NUM,
	'' as GL_TRX_ID,	--X.GL_TRX_ID,
-- 3/16/12 - tag - add salesperson and territory
	x.salesperson_code,
	x.territory_code,
-- 5/7/2012
--    case 
--	 when x.order_ctrl_num<>''
--	 then (select top 1 user_category from orders_all (nolock) where 
--		left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = orders_all.order_no)
--	 else ''
--    end order_type
-- 10/24/2012
	isnull(o.user_category,
		(select top 1 user_category from orders o (nolock), orders_invoice oi (nolock) where
		o.order_no = oi.order_no and o.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as order_type
--	isnull(o.user_category,'') as order_type
-- 5/7/2012
	,isnull(co.promo_id,
		(select top 1 promo_id from cvo_orders_all co (nolock), orders_invoice oi (nolock) where
		co.order_no = oi.order_no and co.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as promo_id

FROM         
	arinpchg_all X (nolock)   
	JOIN ARMASTER M (nolock) ON X.CUSTOMER_CODE = M.CUSTOMER_CODE
	left outer join orders_invoice oi (nolock) on x.trx_ctrl_num = oi.trx_ctrl_num
	left outer join orders o (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext
	left outer join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext

WHERE     
	(M.ADDRESS_TYPE = 0) 
--AND (X.DOC_CTRL_NUM = X.APPLY_TO_NUM) 
--AND (X.TRX_TYPE = X.APPLY_TRX_TYPE) 
	AND (X.TRX_TYPE IN (2021, 2031))
	AND X.doc_desc NOT LIKE '%NONSALES%'

union

SELECT 
	M.ADDRESS_NAME,	 
	M.CUSTOMER_CODE,	
	IsNull(m.state,'') as [State],
	IsNull(m.Country_code,'') as Country,
	isnull(o.ship_to_state,
		(select top 1 ship_to_state from orders o (nolock), orders_invoice oi (nolock) where
		o.order_no = oi.order_no and o.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as [ship_to_state],
	isnull(o.ship_to_country_cd,
		(select top 1 ship_to_country_cd from orders o (nolock) inner join orders_invoice oi (nolock) 
		on o.order_no = oi.order_no and o.ext = oi.order_ext 
		where oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as [ship_to_country_cd],
--	isnull(o.ship_to_state,''),
--	 ((select top 1 ship_to_state from orders (nolock) where 
--		left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = orders.order_no))) as [Ship_To_State],
	INVCRM = 'Credit',
	X.DOC_CTRL_NUM,
	X.TRX_CTRL_NUM,
	X.ORG_ID,	
	PAST_DUE_STATUS = '',
	SETTLED_STATUS = '',		
		HOLD_FLAG= case
		when X.hold_flag = 1 then 'YES'
		else 'NO'
		end,		
	POSTED_FLAG = CASE X.POSTED_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,		
	X.NAT_CUR_CODE,
	case when x.recurring_flag < 2 then X.amt_gross * -1 else 0 end as amt_gross,
	x.amt_discount *-1 as amt_discount,
		-- tag - 032213
	case when x.recurring_flag < 2 then (X.AMT_NET - X.amt_freight - X.amt_tax) *-1 else 0 end as AMT_NET,
	X.amt_freight * -1 as amt_freight,
	X.amt_tax * -1 as amt_tax,
	--X.AMT_NET * -1 as amt_net,
	0 as AMT_PAID_TO_DATE,
	UNPAID_BALANCE = (X.AMT_NET - 0)  * -1,
	AMT_PAST_DUE =(X.AMT_NET - 0)*(SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))) * -1,
	RECURRING_FLAG = T3.CM_DESCR,						  
	X.DATE_DOC, 		
	X.DATE_APPLIED,
	X.DATE_DUE,
	X.DATE_SHIPPED,
	LAST_PAYMENT_DATE=0,	
	X.CUST_PO_NUM,
	X.ORDER_CTRL_NUM,
	'' as GL_TRX_ID,
-- 3/16/12 - tag - add salesperson and territory
	x.salesperson_code,
	x.territory_code,
-- 5/7/2012
--    case 
--	 when x.order_ctrl_num<>''
--	 then (select top 1 user_category from orders_all (nolock) where 
--		left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = orders_all.order_no)
--	 else ''
--    end order_type
-- 10/24/2012
	isnull(o.user_category,
		(select top 1 user_category from orders o (nolock), orders_invoice oi (nolock) where
		o.order_no = oi.order_no and o.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as order_type
--	isnull(o.user_category,'') as order_type
-- 5/7/2012
	,isnull(co.promo_id,
		(select top 1 promo_id from cvo_orders_all co (nolock), orders_invoice oi (nolock) where
		co.order_no = oi.order_no and co.ext = oi.order_ext and 
		oi.doc_ctrl_num = left(x.doc_ctrl_num,10)))
	as promo_id

FROM         
	arinpchg_all X (nolock) 
	join ARMASTER M (nolock) ON X.CUSTOMER_CODE = M.CUSTOMER_CODE 
	left join  ARCMTYPE T3 (nolock) ON X.RECURRING_FLAG = T3.CM_TYPE
	left outer join orders_invoice oi (nolock) on x.trx_ctrl_num = oi.trx_ctrl_num
	left outer join orders o (nolock) on oi.order_no = o.order_no and oi.order_ext = o.ext
	left outer join cvo_orders_all co (nolock) on co.order_no = o.order_no and co.ext = o.ext
	
WHERE    
	(M.ADDRESS_TYPE = 0) 
AND	(X.TRX_TYPE IN (2032)) 
AND (X.POSTED_FLAG = 0)
AND X.doc_desc NOT LIKE '%NONSALES%'








GO
GRANT REFERENCES ON  [dbo].[CVO_InvReg_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_InvReg_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_InvReg_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_InvReg_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_InvReg_vw] TO [public]
GO
