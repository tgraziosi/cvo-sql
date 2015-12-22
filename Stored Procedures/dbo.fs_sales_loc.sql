SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sales_loc] @sort char(1),@strsort varchar(30),@stat char(1),
                                  @bdate datetime,@edate datetime,@cnt int  AS

if @cnt is null OR @cnt <= 0 begin
   SELECT @cnt = 10
end
set rowcount @cnt
 
if @sort='%' 
   begin
	select location,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where date_shipped>=@bdate AND date_shipped<@edate
	group by location
	order by sum(price*shipped) Desc
   end        
 
if @sort='O' 
   begin
	select 'Total Sales',sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where date_shipped>=@bdate AND date_shipped<@edate
   end        
 
if @sort='C' 
   begin
	select location,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where cust_code=@strsort AND
		date_shipped>=@bdate AND date_shipped<@edate
	group by location
	order by sum(price*shipped) Desc
   end         
 
if @sort='P' 
   begin
	select location,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where part_no=@strsort AND
		date_shipped>=@bdate AND date_shipped<@edate
	group by location
	order by sum(price*shipped) Desc
   end        
 
if @sort='A' 
   begin
	select location,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where category=@strsort AND
		date_shipped>=@bdate AND date_shipped<@edate
	group by location
	order by sum(price*shipped) Desc
   end         
 
if @sort='S' 
   begin
	select location,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where salesperson=@strsort AND
		date_shipped>=@bdate AND date_shipped<@edate
	group by location
	order by sum(price*shipped) Desc
   end         
 
if @sort='L' 
   begin
	select location,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where date_shipped>=@bdate AND date_shipped <= @edate and
		location=@strsort and (price * shipped <> 0)
	group by location
	order by sum(price*shipped) Desc
	return
   end        
 
if @sort='T' 
   begin

	select location,sum(price*shipped),
		((sum(price*shipped) - sum((cost + direct_dolrs + ovhd_dolrs + util_dolrs)*shipped))/sum(price*shipped))
	from shippers
	where shippers.ship_to_region=@strsort AND
		date_shipped>=@bdate AND date_shipped <= @edate
	group by location
	order by sum(price*shipped) Desc
   end     

GO
GRANT EXECUTE ON  [dbo].[fs_sales_loc] TO [public]
GO
