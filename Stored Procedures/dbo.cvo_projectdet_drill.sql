SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
                              
                              
CREATE procedure [dbo].[cvo_projectdet_drill] @d datetime, @FTerr nvarchar(25), @tTerr nvarchar(25)                     
AS                              
                              
SET QUOTED_IDENTIFIER OFF                              
--get current week                              
                              
declare @numbers table (n int)                                                                
declare @project nvarchar(25)                              
declare @project2 nvarchar(25)                              
declare @int nvarchar(5)                              
declare @qty nvarchar(25)                    
declare @tqty int                        
                                    
insert into @numbers(n)                                    
select 0 union all                                    
select 1 union all                                    
select 2 union all                                    
select 3 union all                                    
select 4 union all                                    
select 5 union all                                    
select 6 union all                                    
select -1 union all                                    
select -2 union all                                    
select -3 union all                                    
select -4 union all                                    
select -5 union all                                    
select -6                                    
                                    
                                          
declare @monday datetime, @friday datetime                                    
declare @territory nvarchar(25)                            
declare @territory2 nvarchar(25)                              
declare @territory3 nvarchar(15)                
                
    
IF @Fterr='Internal'    
BEGIN    
    
set @Fterr=(select MIN(Salesperson_code) from arsalesp)    
set @TTerr=(select MAX(Salesperson_code) from arsalesp)    
    
END    
ELSE    
BEGIN    
                              
set @FTerr=(                            
CASE                            
 WHEN @Fterr is null THEN (select MIN(Salesperson_code) from arsalesp)                            
 WHEN @Fterr = '' THEN (select MIN(Salesperson_code) from arsalesp)                            
 ELSE @Fterr                            
END)                            
                            
set @TTerr=(                            
CASE                            
 WHEN @Tterr is null THEN (select MAX(Salesperson_code) from arsalesp)                            
 WHEN @Tterr = '' THEN (select MAX(Salesperson_code) from arsalesp)                            
 ELSE @Tterr                            
END)     
    
END                           
                              
                                    
set @monday=(select min(d)                                    
from                                    
(                                    
 select dateadd(d, n, @d) as d, datepart(week, dateadd(d, n, @d)) as w                                    
 from @numbers                                    
) t                                    
where datepart(week, @d) = w)                                    
set @monday=DATEADD(day,1,@monday)                                    
set @friday=DATEADD(day,5,@monday)   
  
  
  
  
  
selecT t1.order_no,t1.ext,t1.promo_id,t1.promo_level,t2.cust_code,t2.ship_to,t2.date_entered
,SUM(t3.shipped) FROM cvo_orders_all t1(nolock)  
inner join orders_all t2 (nolock) on t1.order_no=t2.order_no and t1.ext=t2.ext  
inner join ord_list t3 (nolock) on t2.order_no=t3.order_no and t2.ext=t3.order_ext
inner join inv_master t4 (nolock) on t3.part_no=t4.part_no
where t1.promo_id is not null and t2.date_entered between @monday and @friday  
and t2.salesperson between @Fterr and @tterr                                     
and t1.promo_id<>'' and t1.ext=0  and t4.type_code in ('SUN','FRAME')
group by t1.order_no,t1.ext,t1.promo_id,t1.promo_level,t2.cust_code,t2.ship_to,t2.date_entered



GO
