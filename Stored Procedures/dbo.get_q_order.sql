SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_order] 	@sort char(1), 
				@void char(1) 
AS

set rowcount 100

if @sort='O'
begin
	select 	order_no, cust_code, customer_name, void
	from 	orders_all ( NOLOCK ), adm_cust_all ( NOLOCK )
	where 	cust_code = customer_code
	and 	status = 'T'
	and 	invoice_no = 0
	and 	consolidate_flag = 1
	and 	(void is NULL OR void like @void) 
	order by order_no
end

if @sort='C'
begin
	select 	order_no, cust_code, customer_name, void
	from 	orders_all ( NOLOCK ), adm_cust_all ( NOLOCK )
	where 	cust_code = customer_code
	and 	status = 'T'
	and 	invoice_no = 0
	and 	consolidate_flag = 1
	and 	(void is NULL OR void like @void) 
	order by cust_code
end

GO
GRANT EXECUTE ON  [dbo].[get_q_order] TO [public]
GO
