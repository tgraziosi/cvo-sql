SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sales_cust] @sort char(1),@strsort varchar(30),@stat char(1),@bdate datetime,@edate datetime,@cnt int  AS

set rowcount @cnt

if @sort='%' 
   begin
	select customer_name,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from adm_cust_all,shippers
	where adm_cust_all.customer_code=shippers.cust_code AND
		date_shipped>=@bdate AND date_shipped <= @edate and
		(price * shipped <> 0)
	group by adm_cust_all.customer_name
	order by sum(price*shipped) Desc
   end       
 
if @sort='O' 
   begin
	select 'Total Sales',sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where date_shipped>=@bdate AND date_shipped <=@edate
   end        
 
if @sort='C' 
   begin
	select customer_name,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from adm_cust_all,shippers
	where adm_cust_all.customer_code=shippers.cust_code AND
		adm_cust_all.customer_code=@strsort AND
		date_shipped>=@bdate AND date_shipped <= @edate
	group by adm_cust_all.customer_name
	order by sum(price*shipped) Desc
   end         
 
if @sort='P' 
   begin
	select customer_name,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from adm_cust_all,shippers
	where shippers.cust_code=adm_cust_all.customer_code AND
		shippers.part_no=@strsort AND
		date_shipped>=@bdate AND date_shipped <= @edate
	group by adm_cust_all.customer_name
	order by sum(price*shipped) Desc
   end        
 
if @sort='A' 
   begin
	select customer_name,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from adm_cust_all,shippers
	where shippers.cust_code=adm_cust_all.customer_code AND
		shippers.category=@strsort AND
		date_shipped>=@bdate AND date_shipped <= @edate
	group by adm_cust_all.customer_name
	order by sum(price*shipped) Desc
   end         
 
if @sort='S' 
   begin
	select customer_name,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from adm_cust_all,shippers
	where shippers.cust_code=adm_cust_all.customer_code AND
		shippers.salesperson=@strsort AND
		date_shipped>=@bdate AND date_shipped <= @edate
	group by adm_cust_all.customer_name
	order by sum(price*shipped) Desc
   end     
 
if @sort='L' 
   begin
	select customer_name,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from adm_cust_all,shippers
	where adm_cust_all.customer_code=shippers.cust_code AND
		date_shipped>=@bdate AND date_shipped <= @edate and
		location=@strsort and (price * shipped <> 0)
	group by adm_cust_all.customer_name
	order by sum(price*shipped) Desc
	return
   end        
 
if @sort='T' 
   begin
	select customer_name,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from adm_cust_all,shippers
	where shippers.cust_code=adm_cust_all.customer_code AND
		shippers.ship_to_region=@strsort AND
		date_shipped>=@bdate AND date_shipped <= @edate
	group by adm_cust_all.customer_name
	order by sum(price*shipped) Desc
   end     



GO
GRANT EXECUTE ON  [dbo].[fs_sales_cust] TO [public]
GO
