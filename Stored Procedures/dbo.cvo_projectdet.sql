SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
--exec cvo_projectdet '1/18/2012','INTERNAL','INTERNAL'                                          
                                          
CREATE procedure [dbo].[cvo_projectdet] @d datetime, @FTerr nvarchar(25), @tTerr nvarchar(25)                                 
AS                                          
                                          
SET QUOTED_IDENTIFIER OFF                                          
--get current week                                          
                                          
declare @numbers table (n int)                                                
declare @sql nvarchar(4000)                                          
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
                                                
truncate table cvo_projecttable                                          
        
                                                      
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
                                          
                                        
set @TTerr=(                                        
CASE                                        
 WHEN @Tterr is null THEN @Fterr--(select 1)-- from arsalesp)                                        
 WHEN @Tterr = '' THEN @Fterr--(select 1)-- from arsalesp)                                        
 ELSE @Tterr                                        
END)                 

set @FTerr=(                                        
CASE                                        
 WHEN @Fterr is null THEN @TTerr--(select 1)-- from arsalesp)                                        
 WHEN @Fterr = '' THEN @TTerr--(select 1)-- from arsalesp)                                        
 ELSE @Fterr                                        
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
--select @monday                                       
--select @friday                                          
                                          
                                          
--                                          
--create table cvo_projects                                          
--(row int identity (1,1),                                          
--Project nvarchar(20),                                          
--ProjectLevel nvarchar(30))                                          
                            
insert into cvo_projects (project,ProjectLevel)                                          
select distinct promo_id,'' from cvo_promotions                 
where promo_end_date >= @d and promo_start_date >='1/1/'+convert(varchar,(YEAR(getdate())-1))                         
                          
                          
insert into cvo_projects (project,ProjectLevel)                                            
Select 'Total','Total'                                   
---cursor de tabla                                          
                                        
insert into cvo_projecttable (TER) values ('Project')                                        
                                        
set @int=0                                          
set @sql=''                                          
                            
DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR                                                                                      
select project from cvo_projects order by row asc                                          
--select distinct projectlevel from cvo_projects  order by projectlevel asc                                          
--select distinct (promo_id+'-'+Promo_level) from cvo_promotions                                          
--order by (promo_id+'-'+Promo_level) asc                                                                                         
                                          
OPEN table_cursor;                                        
                                                                                      
                                                                                      
                                         
FETCH NEXT FROM table_cursor                                                                                      
INTO @project;                                                                                      
                               
WHILE @@FETCH_STATUS = 0                                                                                      
BEGIN                                                   
                                          
set @int=@int+1                                          
set @project="'"+@project+"'"                                        
                                          
set @sql='update cvo_projecttable set P'+@int+'='+@project+' where row=1'                                        
                                        
--print @sql                                        
exec SP_EXECUTESQL @sql                                        
                                          
                                          
FETCH NEXT FROM table_cursor                                                                              
   INTO @project                                      
END                                                                              
                                                                              
CLOSE table_cursor;                             
DEALLOCATE table_cursor;                                                 
                                          
                                        
                         
--fin tabla                                          
                                          
                                          
                                          
set @int=0                                          
      
DECLARE terr2_cursor CURSOR LOCAL FAST_FORWARD FOR                                                                                      
select distinct t1.salesperson_code from armaster_all t1(nolock)    
join arsalesp t2 (nolock) on t1.salesperson_code=t2.salesperson_code                                        
where territory_code between @fterr and @tterr and t2.status_type=1                   
    
    
--union all      
--select 'BorelliM'      
--and salesperson_code=@slp --Admin                                                                         
                                                                                      
OPEN terr2_cursor;                                                                                      
                                      
                                                                                      
                                                                              
FETCH NEXT FROM terr2_cursor                                                                                      
INTO @territory;                                                                                      
                                                          
WHILE @@FETCH_STATUS = 0                                                                                      
BEGIN                                                   
                                          
                            
                            
set @territory3=(select top 1 SCODE from cvo_salespersonxref where salesperson_code=@territory)                            
                            
insert into cvo_projecttable (TER) values (@territory)                                           
                                          
                                          
                                          
 set @territory2="'"+@Territory+"'"                                
                                          
---second cursor                                          
                                          
set @project=''                                          
set @sql=''                                          
set @qty=0                                        
                                          
DECLARE pro_cursor CURSOR LOCAL FAST_FORWARD FOR                                                                                      
select Project from cvo_projects                           
order by row asc                          
--select distinct ProjectLevel from cvo_projects order by projectlevel asc                                          
                                                                                      
OPEN pro_cursor;                                                                                      
                                                    
                                        
set @int=0--change                                    
set @tqty=0                                     
                                                                                      
FETCH NEXT FROM pro_cursor                                                                                      
INTO @project;                                                                                      
                                                                                      
WHILE @@FETCH_STATUS = 0                                                                                      
BEGIN                                                   
                                       
set @qty=0                                          
                          
IF @project<>'Total'                          
BEGIN                                              
--set @territory2='SmithMo'                                        
set @qty=(                   
select count(distinct o1.order_no) from orders_all o1            (nolock)                            
join cvo_orders_all o2 on o2.order_no = o1.order_no and o1.ext=o2.ext                                        
where o1.date_entered between @monday and @friday                                         
and o1.salesperson=@territory                                          
and o2.promo_id=@project                                        
--and o2.promo_id+'-'+o2.promo_level=@project                                        
and o1.type='I' and o2.ext=0                                    
)                                    
                                    
set @qty=ISNULL(@qty,0)-ISNULL((                                        
select count(distinct o1.order_no) from orders_all o1            (nolock)                            
join cvo_orders_all o2 on o2.order_no = o1.order_no and o1.ext=o2.ext                      
where o1.date_entered between @monday and @friday                                         
and o1.salesperson=@territory                                          
and o2.promo_id=@project                                        
--and o2.promo_id+'-'+o2.promo_level=@project                                        
and o1.type='C' and o2.ext=0                                   
),0)                                    
        
        
IF @monday<='2012-01-12'                            
BEGIN        
                            
--begin history                            
set @qty=ISNULL(@qty,0)+(                                        
select count(distinct o1.order_no) from cvo_orders_all_hist o1 (nolock)                                       
where o1.date_entered between @monday and @friday                                         
and o1.salesperson=@territory3                                          
and o1.user_def_fld3=@project                                        
--and o2.promo_id+'-'+o2.promo_level=@project                                        
and o1.type='I' and o1.user_def_fld3 is not null                             
and o1.ext=0                    
)                                    
                                    
set @qty=ISNULL(@qty,0)+(                                        
select count(distinct o1.order_no) from cvo_orders_all_hist o1 (nolock)                                        
where o1.date_entered between @monday and @friday                                         
and o1.salesperson=@territory3                                         
and o1.user_def_fld3=@project                                        
--and o2.promo_id+'-'+o2.promo_level=@project                                        
and o1.type='C' and o1.user_def_fld3 is not null                             
and o1.ext=0)                              
END        
                          
set @tqty=ISNULL(@tqty,0)+@qty                          
                          
END                          
ELSE                          
BEGIN                          
 set @qty=ISNULL(@tqty,1000)                          
END                          
                      
set @int=@int+1                          
--end history                            
                            
                              
set @sql='update cvo_projecttable set P'+(@int)+'='+@qty+' where TER='+@territory2                                        
                                          
print @sql                                        
                                          
exec SP_EXECUTESQL @sql                                          
                                          
                                          
--update cvo_projecttable set            
FETCH NEXT FROM pro_cursor                                                                              
INTO @project                                                   
END                                                                              
                    
CLOSE pro_cursor;                                                                              
DEALLOCATE pro_cursor;               
                                                
                                                
                                          
                                          
                                          
--End second cursor                                          
--                                          
--                                          
--                                          
--                                          
--                                          
--                                          
--select * from cvo_projecttable                                          
                
                                          
FETCH NEXT FROM terr2_cursor                                                                              
   INTO @territory                                                  
END                                                                              
                                                                              
CLOSE terr2_cursor;                                                                              
DEALLOCATE terr2_cursor;                                                 
--         
----                                          
              
update cvo_projecttable set TEST=@d              
              
select * from cvo_projecttable   (nolock)                                     
                                       
truncate table cvo_projects                                          
truncate table cvo_projecttable                                          
--drop table cvo_projects                                          
----exec cvo_projectdet '7/15/2011' 
GO
GRANT EXECUTE ON  [dbo].[cvo_projectdet] TO [public]
GO
