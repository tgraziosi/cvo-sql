SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_consolidate_order_list]
@order_no_from		int,
@order_no_to		int,
@cust_code_from		varchar (10),
@cust_code_to		varchar (10),
@ship_to_from		varchar (10),
@ship_to_to		varchar (10),
@date_shipped_from	datetime,
@date_shipped_to	datetime,
@user_code_from		varchar (8),
@user_code_to		varchar (8)

AS

set rowcount 100

if @order_no_from = 0
begin
	SELECT 	@order_no_from = MIN (order_no)
	FROM	orders_entry_vw
	WHERE	status = 'T'	and invoice_no = 0	and consolidate_flag = 1
end

if @order_no_to = 0
begin
	SELECT 	@order_no_to = MAX (order_no)
	FROM	orders_entry_vw
	WHERE	status = 'T'	and invoice_no = 0	and consolidate_flag = 1
end

if @cust_code_from = ''
begin
	SELECT 	@cust_code_from = MIN (customer_code)
	FROM	adm_cust
end

if @cust_code_to = ''
begin
	SELECT 	@cust_code_to = MAX (customer_code)
	FROM	adm_cust
end

if @date_shipped_to = '1900-01-01 00:00:00.000'
begin
	SELECT 	@date_shipped_to = MAX (date_shipped)
	FROM	orders_entry_vw
	WHERE	status = 'T'	and invoice_no = 0	and consolidate_flag = 1
end

if @user_code_from = ''
begin
	SELECT 	@user_code_from = MIN (user_stat_code)
	FROM	so_usrstat
end

if @user_code_to = ''
begin
	SELECT 	@user_code_to = MAX (user_stat_code)
	FROM	so_usrstat
end


DELETE cons_inv

INSERT cons_inv (order_ext, order_no, ext, cust_code, customer_name, date_shipped, ship_to, user_code, total_amt_order, consolidate_flag)
SELECT convert(varchar (10),order_no) + convert(varchar (5),ext)as order_ext, order_no, ext,cust_code, customer_name, date_shipped, ship_to, user_code, total_amt_order, 0
from orders_entry_vw (NOLOCK), adm_cust (NOLOCK)
where cust_code = customer_code
and status = 'T'
and invoice_no = 0
and consolidate_flag = 1
and order_no between @order_no_from and @order_no_to
and date_shipped between @date_shipped_from and @date_shipped_to
and user_code between @user_code_from and @user_code_to
and ((cust_code > @cust_code_from and cust_code < @cust_code_to)
or (cust_code = @cust_code_from and ship_to >= @ship_to_from and @cust_code_from != @cust_code_to)
or (cust_code = @cust_code_to and ship_to <= @ship_to_to and @cust_code_from != @cust_code_to)
or (cust_code = @cust_code_from and ship_to between @ship_to_from and @ship_to_to and @cust_code_from = @cust_code_to)) 
order by order_no

GO
GRANT EXECUTE ON  [dbo].[get_consolidate_order_list] TO [public]
GO
