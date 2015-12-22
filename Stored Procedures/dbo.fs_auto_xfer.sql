SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_auto_xfer] @fromloc varchar(10), @toloc varchar(10),
 @part varchar(30), @qty decimal(20,8), 
 @xpart varchar(30), @stat char(1), 
 @mode varchar(10), @who varchar(20) ,
 @combine int = 0
AS

declare @xno int, @found int, @cno int
declare @lno int
declare @temploc varchar(10)

if @qty < 0 begin
 select @temploc = @fromloc
 select @fromloc = @toloc
 select @toloc = @temploc
 select @qty = -1 * @qty
end

select @xno = 0, @found = 0
if @combine = 1
begin
  select @xno = isnull((select max(xfer_no) from xfers_all x
  where x.status = 'N' and x.to_loc = @toloc and x.from_loc = @fromloc
    and datediff(Hour,date_entered,getdate()) < 1 and who_entered = @who),0)
  if @xno > 0 select @found = 1

end

if @xno = 0
begin
  update next_xfer_no set last_no=last_no + 1
  select @xno = last_no from next_xfer_no
end 

if @found = 0
begin
INSERT xfers_all (
 xfer_no , from_loc , to_loc , 
 req_ship_date , sch_ship_date , date_shipped , 
 date_entered , req_no , who_entered , 
 status , attention , phone , 
 routing , special_instr , fob , 
 freight , printed , label_no , 
 no_cartons , who_shipped , date_printed , 
 who_picked , to_loc_name , to_loc_addr1 , 
 to_loc_addr2 , to_loc_addr3 , to_loc_addr4 , 
 to_loc_addr5 , no_pallets , shipper_no , 
 shipper_name , shipper_addr1 , shipper_addr2 , 
 shipper_city , shipper_state , shipper_zip , 
 cust_code , freight_type , note , 
 rec_no )
SELECT
 @xno , @fromloc , @toloc ,
 getdate() , getdate() , null ,
 getdate() , null , @who ,
 'N' , null , null ,
 null , null , null ,
 0 , 'N' , 0 ,
 0 , null , null ,
 null , l.name , l.addr1 	 ,
 l.addr2 , l.addr3 , l.addr4 ,
 l.addr5 , 0 , null ,
 null , null , null ,
 null , null , null ,
 null , null , null ,
 0
FROM locations_all l
WHERE l.location=@toloc
end

if @mode = 'BUILDPLAN' begin
 INSERT txferlist (
 xfer_no , from_loc , to_loc , 
 part_no , description , 
 time_entered , ordered , shipped , 
 status , who_entered , 

 uom , from_bin , lb_tracking )
 SELECT
 @xno , @fromloc , @toloc ,
 w.part_no , i.description ,
 getdate() , (@qty * qty) , 0 ,
 'N' , substring( @who + 'via Agent',1,20),							-- mls 8/8/00 
 i.uom , null , i.lb_tracking
 FROM what_part w, inv_master i
 WHERE w.asm_no=@part and w.part_no=i.part_no and
 w.active<'C' and i.status<'R' and w.part_no<>@xpart and 
	 ( w.location = @fromloc OR w.location = 'ALL' )
end

if @mode <> 'BUILDPLAN' begin
 INSERT txferlist (
 xfer_no , from_loc , to_loc , 
 part_no , description , 
 time_entered , ordered , shipped , 
 status , who_entered , 
 uom , from_bin , lb_tracking )
 SELECT
 @xno , @fromloc , @toloc ,
 @part , null ,
 getdate() , @qty , 0 ,
 'N' , substring( @who + 'via Agent',1,20),						-- mls 8/8/00
 'EA' , null , 'N'
end
UPDATE txferlist
 SET description=i.description, uom=i.uom, 
 from_bin=i.bin_no, lb_tracking=i.lb_tracking

 FROM inventory i
 WHERE txferlist.part_no=i.part_no and txferlist.from_loc=i.location

select @lno = isnull((select min( row_id ) from txferlist where xfer_no=@xno),0)
select @lno = @lno - 1
select @cno = isnull((select max(line_no) from xfer_list where xfer_no = @xno),0)

INSERT xfer_list (
 xfer_no , line_no , from_loc , 
 to_loc , part_no , description , 
 time_entered , ordered , shipped , 
 comment , status , cost , 
 who_entered , temp_cost , 
 uom , conv_factor , std_cost , 
 from_bin , to_bin , lot_ser , 
 date_expires , lb_tracking , labor , 
 display_line,										-- mls 12/16/03 SCR 31594
 direct_dolrs , ovhd_dolrs , util_dolrs )
SELECT
 @xno , @cno + (row_id - @lno) , from_loc ,
 to_loc , part_no , description ,
 time_entered , ordered , shipped ,
 null , status , 0 ,
 who_entered , 0 ,
 uom , 1.0 , 0 ,
 from_bin , 'IN TRANSIT' , null ,
 null , lb_tracking , 0 ,
 @cno + (row_id - @lno),									-- mls 12/16/03 SCR 31594
 0 , 0 , 0
FROM txferlist
WHERE xfer_no = @xno									-- skk 03/02/01 SCR 26115

delete txferlist where xfer_no = @xno


if @stat > 'N' begin
 exec fs_pick_stock 'T', @xno, 0, @who
end

update xfer_list set to_bin=bin_no from lot_bin_xfer
where xfer_list.xfer_no=@xno and
lot_bin_xfer.tran_no=xfer_list.xfer_no and
lot_bin_xfer.part_no=xfer_list.part_no

if @stat = 'S' begin
 update xfers_all set date_shipped=getdate(),
   date_recvd = getdate(),								-- mls 8/8/00 SCR 23877
   who_recvd = substring( @who + 'via Agent',1,20)					-- mls 8/8/00 SCR 23877
 where xfer_no=@xno

 update xfer_list set status='R' where xfer_no=@xno		
 update lot_bin_xfer set qty_received = uom_qty where tran_no = @xno			-- mls 7/13/06 SCR 36774

 update xfer_list set status='S' , qty_rcvd = shipped 
   where xfer_no=@xno
 update lot_bin_xfer set tran_code='S',
	to_bin = bin_no						 
 where tran_no=@xno
 update xfers_all set status='S' where xfer_no=@xno
end


GO
GRANT EXECUTE ON  [dbo].[fs_auto_xfer] TO [public]
GO
