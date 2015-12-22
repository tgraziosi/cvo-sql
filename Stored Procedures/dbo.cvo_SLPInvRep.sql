SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec cvo_SLPInvRep '03/01/2012','03/29/2012'    
    
CREATE procedure [dbo].[cvo_SLPInvRep] @fd datetime, @td datetime                    
AS                    
                    
set @fd=ISNULL(@fd,'01/01/2012')                    
set @td=ISNULL(@td,'02/02/2012')                    
                    
                    
declare @fd2 datetime, @td2 datetime                    
                    
set @fd2=@fd                    
set @td2=@td                    
                    
                    
--set @fd=(select datediff(dd, '1/1/1753', @fd) + 639906)                    
--set @td=(select datediff(dd, '1/1/1753', @td) + 639906)                    
                    
create table #cvo_slpinvrep                    
(row int identity (0,1),                    
SalesPerson varchar(15),                    
Orders int,                    
Shipped float,                    
Bo float,                    
Invoiced float,                    
Discount float,                    
Comm float,                    
fdate datetime,                    
tdate datetime,        
manager nvarchar(15))     
  
create table #order_no  
(order_no nvarchar(20))                 
                    
declare @slp varchar(15)                    
declare @orders int                    
declare @qty float                    
declare @boqty float                    
declare @inv float                    
declare @dic float                    
declare @comm float                    
declare @manager nvarchar(15)        
---                    
--set @slp=205                    
---                    
                    
DECLARE slp_cursor CURSOR FOR                                                  
select salesperson_code from arsalesp                                                  
where salesperson_code >='A%'        
and status_type<>2      
              
                
                                                  
OPEN slp_cursor;                                                  
                                                  
                                                  
                                                  
FETCH NEXT FROM slp_cursor                                                  
INTO @slp;                                                  
                                                  
WHILE @@FETCH_STATUS = 0                                                  
BEGIN                                                  
                    
  
insert into #order_no (order_no)  
select order_no from orders_all where salesperson=@slp and date_shipped between @fd and @td                
and type='I' and ext=0 and status='T'  
                    
set @manager=(select top 1 sales_mgr_code from arsalesp where salesperson_code=@slp)        
                    
set @orders = (select count(*) from orders_all where salesperson=@slp and date_shipped between @fd and @td                
and type='I' and ext=0 and status='T')                

--set @orders = ISNULL(@orders,0)+(select count(*) from                 
--cvo_orders_all_hist where salesperson=@slp and date_entered between @fd and @td and type='I')                
                
--set @qty=(select ISNULL(SUM(qty_shipped),0) from artrxcdt t1 (nolock)  
--inner join artrx t2 on t2.trx_ctrl_num=t1.trx_ctrl_num  
--where t2.order_ctrl_num in (select order_no+'-0' from #order_no))  
  
  
--  
--(select SUM(shipped) from ord_list t1 (nolock)                
--join orders_all t2 (nolock) on t1.order_no=t2.order_no and t1.order_ext=t2.ext                
--where t2.salesperson=@slp and t2.date_shipped between @fd and @td and t2.type='I' and t2.status='T'  
--and ext=0)                
--                
--set @qty=ISNULL(@qty,0)-ISNULL((select SUM(shipped) from ord_list t1 (nolock)                
--join orders_all t2 (nolock) on t1.order_no=t2.order_no and t1.order_ext=t2.ext                
--where t2.salesperson=@slp and t2.date_shipped between @fd and @td and t2.type='C' and t2.status='T'),0)                
--Add History          
          
--set @qty=ISNULL(@qty,0)+(select SUM(shipped) from cvo_ord_list_hist t1 (nolock)                
--join cvo_orders_all_hist t2 (nolock) on t1.order_no=t2.order_no                
--where t2.salesperson=@slp and t2.date_shipped between @fd and @td and t2.type='I' and t2.status='T')                
--                
--set @qty=ISNULL(@qty,0)-ISNULL((select SUM(shipped) from cvo_ord_list_hist t1 (nolock)                
--join cvo_orders_all_hist t2 (nolock) on t1.order_no=t2.order_no                
--where t2.salesperson=@slp and t2.date_shipped between @fd and @td and t2.type='C' and t2.status='T'),0)                
          
          
--End History                
                
--set @qty=(select SUM(qty_shipped) from ord_list t1 (nolock)                
--join orders_all t2 (nolock) on t1.order_no=t2.order_no                
--where t2.salesperson=@slp and t2.date_entered between @fd and @td and type='I')        
                
--set @boqty=(select ISNULL(SUM(qty_ordered - qty_shipped),0) from artrxcdt t1 (nolock)  
--inner join artrx t2 on t2.trx_ctrl_num=t1.trx_ctrl_num  
--where t2.order_ctrl_num in (select order_no+'-0' from #order_no))  
  
--ISNULL((select sum(ordered) from ord_list t1 (nolock)                
--join orders_all t2 (nolock) on t1.order_no=t2.order_no and t1.order_ext=t2.ext                
--where t2.salesperson=@slp and t2.date_shipped between @fd and @td and type='I'                
--and t1.order_ext<>0 and t2.status<>'T'  
--and t2.ext=0),0)                
--                
--set @inv=(select ISNULL(SUM(extended_price),0) from artrxcdt t1 (nolock)  
--inner join artrx t2 on t2.trx_ctrl_num=t1.trx_ctrl_num  
--where t2.order_ctrl_num in (select order_no+'-0' from #order_no))  
  
select @qty=ISNULL(SUM(qty_shipped),0),@boqty=ISNULL(SUM(qty_ordered - qty_shipped),0),  
@inv=ISNULL(SUM(extended_price),0) from artrxcdt t1 (nolock)  
inner join artrx t2 on t2.trx_ctrl_num=t1.trx_ctrl_num  
where t2.order_ctrl_num in (select order_no+'-0' from #order_no)

select @qty=@QTY+ISNULL(SUM(qty_shipped),0),@boqty=@boqty+ISNULL(SUM(qty_ordered - qty_shipped),0),  
@inv=@inv+ISNULL(SUM(extended_price),0) from arinpcdt t1 (nolock)  
inner join arinpchg t2 on t2.trx_ctrl_num=t1.trx_ctrl_num  
where t2.order_ctrl_num in (select order_no+'-0' from #order_no)

    
  
--(select sum(total_invoice) from orders_all (nolock)                 
--where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='I'  
--and ext=0)                
--set @inv=ISNULL(@inv,0)-ISNULL((select sum(total_invoice) from orders_all (nolock)                 
--where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='C'  
--and ext=0),0)                
                
set @inv=round(@inv,0)                
                
set @dic=(select sum(discount) from orders_all (nolock)                 
where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='I'  
and ext=0)                
set @dic=ISNULL(@dic,0)-ISNULL((select sum(discount) from orders_all (nolock)                 
where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='C'  
and ext=0),0)                
                
set @comm=(select sum(sales_comm) from orders_all (nolock)                 
where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='I'  
and ext=0)                
set @comm=ISNULL(@comm,0)-ISNULL((select sum(sales_comm) from orders_all (nolock)                 
where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='C'  
and ext=0),0)                
          
          
--ad history          
--          
--set @boqty=ISNULL((select sum(ordered) from ord_list t1 (nolock)                
--join orders_all t2 (nolock) on t1.order_no=t2.order_no                
--where t2.salesperson=@slp and t2.date_shipped between @fd and @td and type='I'                
--and t1.order_ext<>0 and t2.status<>'T'),0)                
--                
--set @inv=ISNULL(@inv,0)+(select sum(total_invoice) from cvo_orders_all_hist (nolock)                 
--where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='I')                
--          
--set @inv=ISNULL(@inv,0)-ISNULL((select sum(total_invoice) from cvo_orders_all_hist (nolock)      
--where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='C'),0)                
--                
--set @inv=round(@inv,0)                
--                
--set @dic=ISNULL(@dic,0)+(select sum(discount) from cvo_orders_all_hist (nolock)                 
--where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='I')                
--set @dic=ISNULL(@dic,0)-ISNULL((select sum(discount) from cvo_orders_all_hist (nolock)                 
--where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='C'),0)                
--                
--set @comm=ISNULL(@comm,0)+(select sum(sales_comm) from cvo_orders_all_hist (nolock)                 
--where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='I')                
--set @comm=ISNULL(@comm,0)-ISNULL((select sum(sales_comm) from cvo_orders_all_hist (nolock)                 
--where salesperson=@slp and date_shipped between @fd and @td and status='T' and type='C'),0)                
--          
--          
--end add history   
  
  
truncate table #order_no  
               
insert into #cvo_slpinvrep (SalesPerson,Orders,Shipped,Bo,Invoiced,                    
       Discount,Comm,fdate,tdate,manager)                    
VALUES                    
       (@SLP,@orders,@qty,@boqty,@inv,                    
       @dic,@comm,@fd2,@td2,@manager)                    
                    
                    
                    
  FETCH NEXT FROM slp_cursor                        
   INTO @slp                                                  
END       
                                        
CLOSE slp_cursor;                                                  
DEALLOCATE slp_cursor;                    
                    
                    
                    
select * from #cvo_slpinvrep                              
                    
drop table #cvo_slpinvrep                    
              drop table #order_no      
                    
--exec cvo_SLPInvRep null, null
GO
GRANT EXECUTE ON  [dbo].[cvo_SLPInvRep] TO [public]
GO
