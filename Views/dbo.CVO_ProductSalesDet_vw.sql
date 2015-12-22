SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[CVO_ProductSalesDet_vw]
AS
SELECT 
  	X.CUSTOMER_CODE,
  	ar.addr_sort1 as cust_type,
	ar.customer_name,
	substring(x.territory_code,1,2) as region,
	x.territory_code as territory,
	x.salesperson_code as salesperson,
	INVCRM =  CASE X.TRX_TYPE
  		WHEN 2032 THEN 'Credit'
  		ELSE 'Invoice'
  	END,
	ARTRXCDT.DOC_CTRL_NUM,
	ARTRXCDT.TRX_CTRL_NUM,
	x.order_ctrl_num,
	case x.order_ctrl_num 
		when null then ' ' when '' then ' '
		else
		isnull( (select top 1 promo_id from cvo_orders_all (nolock) 
		   where substring(x.order_ctrl_num,1,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
	end as promo_id,
	case x.order_ctrl_num
		when null then ' ' when '' then ' '
		else
		isnull( (select top 1 promo_level from cvo_orders_all (nolock) 
		   where left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
	end as promo_level,
	case x.order_ctrl_num
		when null then ' ' when '' then ' '
		else
		isnull( (select top 1 user_category from orders (nolock) 
		   where left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
		end as order_type,
	case x.order_ctrl_num 
		when null then ar.country_code 
		when '' then ar.country_code
		else
		isnull( (select top 1 ship_to_country_cd from orders (nolock) 
		   where substring(x.order_ctrl_num,1,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
	end as country_code,
	case x.order_ctrl_num 
		when null then ar.state 
		when '' then ar.state
		else
		isnull( (select top 1 ship_to_state from orders (nolock) 
		   where substring(x.order_ctrl_num,1,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
	end as state_code,
		
	x.date_applied,
	SEQUENCE_ID,  
	artrxcdt.LOCATION_CODE, 
	ITEM_CODE,     
	LINE_DESC,     
	case item_code
	 when null then ' ' when '' then ' '
	 else
	 isnull ( (select top 1 category from inv_master (nolock) where part_no = item_code),' ')
	end as Product_group,
	case item_code
	 when null then ' ' when '' then ' '
	 else
	 isnull ( (select top 1 type_code from inv_master (nolock) where part_no = item_code),' ')
	end as Product_type,
	case item_code
	 when null then ' ' when '' then ' '
	 else
	 isnull ( (select top 1 field_2 from inv_master_add (nolock) where part_no = item_code),' ')
	end as Product_Style,
	case item_code
	 when null then ' ' when '' then ' '
	 else
	 isnull ( (select top 1 category_2 from inv_master_add (nolock) where part_no = item_code),' ')
	end as Product_gender,

	QTY_ORDERED,   
	QTY_SHIPPED,   
	QTY_RETURNED,        
	UNIT_CODE,     
	case x.order_ctrl_num 
		when null then 0 when '' then 0
		else
		isnull( (select top 1 list_price from cvo_ord_list (nolock) 
		   where substring(x.order_ctrl_num,1,charindex('-',x.order_ctrl_num)-1) = order_no
			and sequence_id = line_no),0 ) 
	end as list_price,
	CASE x.trx_type WHEN 2032 THEN UNIT_PRICE * -1 ELSE unit_price END AS UNIT_PRICE, 
	case item_code
	 when null then 0 when '' then 0
	 else
	 isnull ( (select top 1 price_a from part_price (nolock) where part_no = item_code),0)
	end as Current_list_price,
   
	ARTRXCDT.TAX_CODE,       
	GL_REV_ACCT,
	DISCOUNT_AMT,   
	DISC_PRC_FLAG = CASE DISC_PRC_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,         
	CASE x.trx_type WHEN 2032 THEN EXTENDED_PRICE * -1 ELSE extended_price END AS EXTENDED_PRICE,
	X.NAT_CUR_CODE,
	convert(varchar,dateadd(d,x.date_applied-711858,'1/1/1950'),101) as DateApplied
FROM         
	ARTRXCDT AS ARTRXCDT (nolock) INNER JOIN
	ARTRX AS x (nolock) ON ARTRXCDT.TRX_CTRL_NUM = X.TRX_CTRL_NUM inner join
	arcust ar (nolock) on ar.customer_code = x.customer_code
	
WHERE     
	(X.TRX_TYPE IN (2031, 2032))
AND x.DOC_DESC NOT LIKE '%CONVERTED%'
AND x.doc_desc NOT LIKE '%NONSALES%'
AND x.doc_ctrl_num NOT LIKE 'CB%'
AND x.doc_ctrl_num NOT LIKE 'FIN%'
and x.void_flag = 0
and x.posted_flag = 1
	
union

-- gather unposted transaction detail
select 
  	X.CUSTOMER_CODE,
 	ar.addr_sort1 as cust_type,
	ar.customer_name,
	substring(x.territory_code,1,2) as region,
	x.territory_code as territory,
	x.salesperson_code as salesperson,
	INVCRM =  CASE X.TRX_TYPE
  		WHEN 2032 THEN 'Credit'
  		ELSE 'Invoice'
  	END,
	ARTRXCDT.DOC_CTRL_NUM,
	ARTRXCDT.TRX_CTRL_NUM,
	x.order_ctrl_num,
	case x.order_ctrl_num 
		when null then ' ' when '' then ' '
		else
		isnull( (select top 1 promo_id from cvo_orders_all (nolock) 
		   where left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
	end as promo_id,
	case x.order_ctrl_num
		when null then ' ' when '' then ' '
		else
		isnull( (select top 1 promo_level from cvo_orders_all (nolock) 
		   where left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
	end as promo_level,
	case x.order_ctrl_num
		when null then ' ' when '' then ' '
		else
		isnull( (select top 1 user_category from orders (nolock) 
		   where left(x.order_ctrl_num,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
		end as order_type,
	case x.order_ctrl_num 
		when null then ar.country_code 
		when '' then ar.country_code
		else
		isnull( (select top 1 ship_to_country_cd from orders (nolock) 
		   where substring(x.order_ctrl_num,1,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
	end as country_code,
	case x.order_ctrl_num 
		when null then ar.state 
		when '' then ar.state
		else
		isnull( (select top 1 ship_to_state from orders (nolock) 
		   where substring(x.order_ctrl_num,1,charindex('-',x.order_ctrl_num)-1) = order_no),' ' ) 
	end as state_code,
	x.date_applied,
	SEQUENCE_ID,  
	ARTRXCDT.LOCATION_CODE, 
	ITEM_CODE,     
	LINE_DESC,     
	case item_code
	 when null then ' ' when '' then ' '
	 else
	 isnull ( (select top 1 category from inv_master (nolock) where part_no = item_code),' ')
	end as Product_group,
	case item_code
	 when null then ' ' when '' then ' '
	 else
	 isnull ( (select top 1 type_code from inv_master (nolock) where part_no = item_code),' ')
	end as Product_type,
	case item_code
	 when null then ' ' when '' then ' '
	 else
	 isnull ( (select top 1 field_2 from inv_master_add (nolock) where part_no = item_code),' ')
	end as Product_Style,
	case item_code
	 when null then ' ' when '' then ' '
	 else
	 isnull ( (select top 1 category_2 from inv_master_add (nolock) where part_no = item_code),' ')
	end as Product_gender,

	QTY_ORDERED,   
	QTY_SHIPPED,   
	QTY_RETURNED,        
	UNIT_CODE,     
	case x.order_ctrl_num 
		when null then 0 when '' then 0
		else
		isnull( (select top 1 list_price from cvo_ord_list (nolock) 
		   where substring(x.order_ctrl_num,1,charindex('-',x.order_ctrl_num)-1) = order_no
			and sequence_id = line_no),0 ) 
	end as list_price,
	CASE x.trx_type WHEN 2032 THEN UNIT_PRICE * -1 ELSE unit_price END AS UNIT_PRICE,    
	case item_code
	 when null then 0 when '' then 0
	 else
	 isnull ( (select top 1 price_a from part_price (nolock) where part_no = item_code),0)
	end as Current_list_price,
	ARTRXCDT.TAX_CODE,       
	GL_REV_ACCT,
	DISCOUNT_AMT,   
	DISC_PRC_FLAG = CASE DISC_PRC_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,         

	CASE x.trx_type WHEN 2032 THEN EXTENDED_PRICE * -1 ELSE extended_price END AS EXTENDED_PRICE,
	X.NAT_CUR_CODE,
	convert(varchar,dateadd(d,x.date_applied-711858,'1/1/1950'),101) as DateApplied
from          
	arinpcdt ARTRXCDT (nolock) inner join
	arinpchg_all X (nolock) on ARTRXCDT.TRX_CTRL_NUM = X.TRX_CTRL_NUM inner join
	arcust ar (nolock) on ar.customer_code = x.customer_code

where      
	(X.TRX_TYPE IN (2031, 2032))
AND x.DOC_DESC NOT LIKE '%CONVERTED%'
AND x.doc_desc NOT LIKE '%NONSALES%'
AND x.doc_ctrl_num NOT LIKE 'CB%'
AND x.doc_ctrl_num NOT LIKE 'FIN%'

GO
GRANT SELECT ON  [dbo].[CVO_ProductSalesDet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ProductSalesDet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ProductSalesDet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ProductSalesDet_vw] TO [public]
GO
