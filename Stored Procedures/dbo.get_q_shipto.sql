SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_shipto] @cust varchar(30), @sort char(1), @cust_code varchar(10), @void char(1),
  @secured_mode int = 0  AS


declare @stat int

set @secured_mode = isnull(@secured_mode,0)

select @stat=case when @void='%' then 3 else 1 end

set rowcount 100

if @secured_mode = 0
begin
if @sort='1'
begin
select customer_code, ship_to_code, ship_to_name, addr2, city, state, postal_code, status_type 
from adm_shipto_all ( NOLOCK ) 
where ship_to_code >= @cust and
customer_code like @cust_code and status_type <= @stat
order by ship_to_code, customer_code
end
if @sort='2'
begin
select customer_code, ship_to_code, ship_to_name, addr2, city, state, postal_code, status_type 
from adm_shipto_all ( NOLOCK ) 
where ship_to_name >= @cust and
customer_code like @cust_code and status_type <= @stat
order by ship_to_name, ship_to_code, customer_code
end
end
else
begin
if @sort='1'
begin
select customer_code, ship_to_code, ship_to_name, addr2, city, state, postal_code, status_type 
from adm_shipto ( NOLOCK ) 
where ship_to_code >= @cust and
customer_code like @cust_code and status_type <= @stat
order by ship_to_code, customer_code
end
if @sort='2'
begin
select customer_code, ship_to_code, ship_to_name, addr2, city, state, postal_code, status_type 
from adm_shipto ( NOLOCK ) 
where ship_to_name >= @cust and
customer_code like @cust_code and status_type <= @stat
order by ship_to_name, ship_to_code, customer_code
end
end

GO
GRANT EXECUTE ON  [dbo].[get_q_shipto] TO [public]
GO
