SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_shiptono] 	
AS

set rowcount 100

select 	load_no, order_no, ext, cust_code, customer_name
from 	orders_all ( NOLOCK ), adm_cust_all ( NOLOCK )
where 	orders_all.cust_code = customer_code
and	status = 'T'
and 	invoice_no = 0
and 	consolidate_flag = 1
and 	void = 'N'
order by order_no


GO
GRANT EXECUTE ON  [dbo].[get_q_shiptono] TO [public]
GO
