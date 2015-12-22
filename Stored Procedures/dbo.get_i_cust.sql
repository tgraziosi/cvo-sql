SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[get_i_cust] @strsort varchar(30), @sort char(1), @void char(1), @lastkey varchar(30), @username varchar(10)=''  AS

set rowcount 40
declare @cus_con varchar(255), @cust varchar(10) 
if @lastkey > '' select @cust=@lastkey else select @cust=''
if @void is null select @void='null'
select @cus_con=' and ' + isnull((select constrain_by from sec_constraints where kys=@username and table_id='adm_cust_all'),'adm_cust_all.customer_code=adm_cust_all.customer_code')

if @sort='C'   
begin
exec('select customer_code, customer_name, address_1, city, state,
	 phone_1
  from   adm_cust_all 
  where    customer_code>=''+@cust+
	'' AND city >=''+@strsort+
	'' and (void is NULL OR void like ''+@void+
	'') order by city, customer_name')
end
if @sort='K'   
begin
exec('select customer_code, customer_name, address_1, city, state,
	 phone_1
  from   adm_cust_all 
  where  customer_code>=''+@cust+
	'' and (void is NULL OR void like ''+@void+
	'') order by customer_code')
end
if @sort='N'   
begin

exec('select customer_code, customer_name, address_1, city, state,
	 phone_1
  from   adm_cust_all 
  where  customer_code>=''+@cust+
	'' AND customer_name >=''+@strsort+
	'' and (void is NULL OR void like ''+@void+
	'') order by customer_name, customer_code')
end
if @sort='P'   
begin
exec('select customer_code, customer_name, address_1, city, state,
	 phone_1
  from   adm_cust_all 
  where    customer_code>=''+@cust+
	'' AND phone_1 >=''+@strsort+

	'' and (void is NULL OR void like ''+@void+
	'') order by phone_1')
end
if @sort='S'   
begin

exec('select customer_code, customer_name, address_1, city, state,
	 phone_1
  from   adm_cust_all 
  where    customer_code>=''+@cust+
	'' AND salespersn_ky >=''+@strsort+
	'' and (void is NULL OR void like ''+@void+
	'') order by salespersn_ky, customer_name')
end
if @sort='T'   
begin
exec('select customer_code, customer_name, address_1, city, state,
	 phone_1
  from   adm_cust_all 
  where    customer_code>=''+@cust+
	'' AND territory_ky >=''+@strsort+
	'' and (void is NULL OR void like ''+@void+
	'') order by territory_ky, customer_name')
end

GO
GRANT EXECUTE ON  [dbo].[get_i_cust] TO [public]
GO
