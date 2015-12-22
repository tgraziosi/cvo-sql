SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  --cvo_daily_drill_promo '1/18/2012','BrendeDa','BrendeDa'      
 --cvo_daily_drill '1/18/2012','BrendeDa','BrendeDa'      
CREATE procedure [dbo].[cvo_daily_drill_promoH] @d int, @FTerr nvarchar(25), @tTerr nvarchar(25)                             
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
                                      
                                            
set @monday='1/1/'+convert(varchar, @d)--YEAR(getdate()))--DATEADD(day,1,@monday)                                            
set @friday='12/31/'+convert(varchar, @d)--getdate()           
          
          
          
          
          
selecT t7.sales_mgr_code,t6.address_name,t6.salesperson_code,t2.order_no,t2.ext,t2.cust_code,t2.ship_to,t2.date_entered,t5.promo_id,t2.user_category        
,SUM(t3.ordered) FROM orders_all t2(nolock)          
--inner join orders_all t2 (nolock) on t1.order_no=t2.order_no and t1.ext=t2.ext          
inner join ord_list t3 (nolock) on t2.order_no=t3.order_no and t2.ext=t3.order_ext        
inner join inv_master t4 (nolock) on t3.part_no=t4.part_no        
inner join cvo_orders_all t5 (nolock) on t5.order_no=t2.order_no and t5.ext=t2.ext       
inner join armaster_all t6 (nolock) on t6.customer_code=t2.cust_code  
inner join arsalesp t7 (nolock) on t7.salesperson_code=t6.salesperson_code
where t2.date_entered between @monday and @friday          
and t2.salesperson between @Fterr and @tterr                                             
and t4.type_code in ('SUN','FRAME')        
--and t2.user_category like 'ST%'       
and t2.ext=0       
and type='I'      
and t5.promo_id is not null  and t5.promo_id<>''      
group by t2.order_no,t2.ext,t2.cust_code,t2.ship_to,t2.date_entered,t5.promo_id,t2.user_category,  
t6.address_name,t6.salesperson_code,t7.sales_mgr_code 
GO
