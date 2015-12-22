SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_i_shipto] @cust varchar(30), @sort char(1), @cust_code varchar(10), @void char(1), @username varchar(10)=''  AS

set rowcount 40
declare @cus_con varchar(10)

if @void is null select @void='null'
select @cus_con=' and ' + isnull((select constrain_by from sec_constraints where kys=@username and table_id='ship_to'),'adm_cust_all.customer_code=adm_cust_all.customer_code')

if @sort='1'
begin
exec('select cust_code, ship_to_no, name, address1, city, state, zip 
from ship_to 
where ship_to_no >=''+@cust+
'' and cust_code like ''+@cust_code+
'' and (void is NULL OR void like ''+@void+
'') order by ship_to_no, cust_code')
end
if @sort='2'
begin
exec('select cust_code, ship_to_no, name, address1, city, state, zip 
from ship_to 
where name >=''+@cust+
'' and cust_code like ''+@cust_code+
'' and (void is NULL OR void like ''+@void+
'') order by name')

end


GO
GRANT EXECUTE ON  [dbo].[get_i_shipto] TO [public]
GO
