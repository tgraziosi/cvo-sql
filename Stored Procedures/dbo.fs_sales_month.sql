SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sales_month] @sort char(1),@strsort varchar(30),@stat char(1),
                                    @bdate datetime,@edate datetime,@cnt int  AS

if @cnt is null OR @cnt <= 0 begin
   SELECT @cnt = 10
end
set rowcount @cnt
 
if @sort='%' begin
select substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2),
sum(price*shipped),
((sum(price*shipped) - sum(cost*shipped))/sum(price*shipped))
from shippers
where date_shipped>=@bdate AND date_shipped<@edate
group by substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2)
end        
 
if @sort='O' begin
select 'Total Sales'  ,sum(price*shipped),
((sum(price*shipped) - sum(cost*shipped))/sum(price*shipped))
from shippers
where date_shipped>=@bdate AND date_shipped<@edate
end        
 
if @sort='C' begin
select substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2),
sum(price*shipped),
((sum(price*shipped) - sum(cost*shipped))/sum(price*shipped))
from shippers
where date_shipped>=@bdate AND date_shipped<@edate
AND cust_code=@strsort
group by substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2)
end     
 
if @sort='P' begin
select substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2),
sum(price*shipped),
((sum(price*shipped) - sum(cost*shipped))/sum(price*shipped))
from shippers
where date_shipped>=@bdate AND date_shipped<@edate
AND part_no=@strsort
group by substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2)
end     
 
if @sort='A' begin
select substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2),
sum(price*shipped),
((sum(price*shipped) - sum(cost*shipped))/sum(price*shipped))
from shippers
where date_shipped>=@bdate AND date_shipped<@edate
AND category=@strsort
group by substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2)
end     
 
if @sort='S' begin
select substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2),
sum(price*shipped),
((sum(price*shipped) - sum(cost*shipped))/sum(price*shipped))
from shippers
where date_shipped>=@bdate AND date_shipped<@edate
AND salesperson=@strsort
group by substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2)
end         
 
if @sort='L' begin
select substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2),
sum(price*shipped),
((sum(price*shipped) - sum(cost*shipped))/sum(price*shipped))
from shippers
where date_shipped>=@bdate AND date_shipped <= @edate and
location=@strsort and (price * shipped <> 0)
group by substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2)
order by sum(price*shipped) Desc
return
end        
 
if @sort='T' begin
select substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2),
sum(price*shipped),
((sum(price*shipped) - sum(cost*shipped))/sum(price*shipped))
from shippers
where shippers.ship_to_region=@strsort AND
date_shipped>=@bdate AND date_shipped <= @edate
group by substring(datename(month,date_shipped),1,3)+char(39)+substring(str(datepart(year,date_shipped),4),3,2)
order by sum(price*shipped) Desc
end     

GO
GRANT EXECUTE ON  [dbo].[fs_sales_month] TO [public]
GO
