SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_recv] @strsort varchar(30), @sort char(1), @loc varchar(10), @rno int  AS

set rowcount 100
declare @no int
declare @dt datetime
        
if @sort='R' begin
select @no=convert(int,@strsort)
select r.receipt_no, r.part_no, r.sku_no, r.po_no, 
r.recv_date, r.location
from receipts r
where   (r.receipt_no >= @no) and r.location like @loc
order by r.receipt_no
end       
    
      
if @sort='O' begin
select r.receipt_no, r.part_no, r.sku_no, r.po_no, 
r.recv_date, r.location 
from receipts r ( NOLOCK )
where  ( (r.po_no > @strsort) OR (r.po_no = @strsort and r.receipt_no >= @rno) )
        and r.location like @loc           
order by r.po_no
end     
   
if @sort='P' begin
select r.receipt_no, r.part_no, r.sku_no, r.po_no, 
r.recv_date, r.location 
from receipts r ( NOLOCK )
where  ( (r.part_no > @strsort) OR (r.part_no = @strsort and r.receipt_no >= @rno) ) 
        and r.location like @loc
order by r.part_no
end     
   
if @sort='S' begin
select r.receipt_no, r.part_no, r.sku_no, r.po_no, 
r.recv_date, r.location 
from receipts r ( NOLOCK )
where  ( (r.sku_no > @strsort) OR (r.sku_no = @strsort and r.receipt_no >= @rno) )           
        and r.location like @loc
order by r.sku_no
end     

if @sort='D' begin
select @dt=convert(datetime,@strsort)
select r.receipt_no, r.part_no, r.sku_no, r.po_no, 

r.recv_date, r.location 
from receipts r ( NOLOCK )
where   (r.recv_date >= @dt)  and r.location like @loc
order by r.recv_date
end     

GO
GRANT EXECUTE ON  [dbo].[get_q_recv] TO [public]
GO
