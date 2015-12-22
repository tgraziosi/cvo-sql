SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_create_backorder_xfer] @xfer int AS
declare @ext int, @xlp int, @orig_xfer int, @new_xfer int
declare @qty decimal(20,8)


if isnull((select back_ord_flag from xfers_all where xfer_no=@xfer),0) != '0'
BEGIN
	return 1
END


if NOT exists (select 1 from xfer_list where xfer_no=@xfer and shipped < ordered and isnull(back_ord_flag,0) = 0 )
begin
  return 1
end

select @orig_xfer = isnull(orig_xfer_no, 0),
  @ext = isnull(orig_xfer_ext,0)
from xfers_all where xfer_no = @xfer

if @orig_xfer = 0
  select @orig_xfer = @xfer, @ext = 1
else
  select @ext = @ext + 1



update next_xfer_no set last_no = last_no + 1

select @new_xfer = last_no from next_xfer_no


if exists (select 1 from xfers_all where orig_xfer_no = @orig_xfer and orig_xfer_ext = @ext) return 1
if exists (select 1 from xfers_all where xfer_no = @new_xfer) return 1


INSERT xfers_all (
    xfer_no,from_loc,to_loc,req_ship_date,sch_ship_date,date_shipped,date_entered,req_no,who_entered,
    status,attention,phone,routing,special_instr,fob,freight,printed,label_no,no_cartons,who_shipped,
    date_printed,who_picked,to_loc_name,to_loc_addr1,to_loc_addr2,to_loc_addr3,to_loc_addr4,to_loc_addr5,
    no_pallets,shipper_no,shipper_name,shipper_addr1,shipper_addr2,shipper_city,shipper_state,shipper_zip,
    cust_code,freight_type,note,rec_no,who_recvd,date_recvd,pick_ctrl_num,proc_po_no,from_organization_id,
    to_organization_id,back_ord_flag,orig_xfer_no,orig_xfer_ext)
select
    @new_xfer,from_loc,to_loc,req_ship_date,sch_ship_date,NULL,getdate(),req_no,'BACKORDR',
    'N',attention,phone,routing,special_instr,fob,0,'N',0,0,NULL,
    NULL,NULL,to_loc_name,to_loc_addr1,to_loc_addr2,to_loc_addr3,to_loc_addr4,to_loc_addr5,
    0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    cust_code,freight_type,note,rec_no,NULL,NULL,'',proc_po_no,from_organization_id,
    to_organization_id,back_ord_flag,@orig_xfer,@ext
FROM xfers_all
WHERE xfer_no=@xfer

if @@error != 0
begin
	return @@error
end


SELECT @xlp=isnull((select min(line_no) from xfer_list where xfer_no=@xfer and shipped < ordered and
		isnull(back_ord_flag,0) = 0),0)
while @xlp > 0
BEGIN

	
	SELECT @qty=(ordered - shipped)
	FROM xfer_list
	WHERE xfer_no=@xfer and line_no=@xlp

	INSERT xfer_list(
      xfer_no,line_no,from_loc,to_loc,part_no,description,time_entered,ordered,shipped,comment,
      status,cost,com_flag,who_entered,temp_cost,uom,conv_factor,std_cost,from_bin,to_bin,lot_ser,
      date_expires,lb_tracking,labor,direct_dolrs,ovhd_dolrs,util_dolrs,display_line,qty_rcvd,
      reference_code,adj_code,amt_variance,back_ord_flag)
    SELECT
      @new_xfer,line_no,from_loc,to_loc,part_no,description,getdate(),@qty,0,comment,
      'N',cost,com_flag,who_entered,temp_cost,uom,conv_factor,std_cost,from_bin,'IN TRANSIT','N/A',
      getdate(),lb_tracking,labor,direct_dolrs,ovhd_dolrs,util_dolrs,display_line,NULL,
      reference_code,adj_code,0,back_ord_flag
	FROM xfer_list
	WHERE xfer_no=@xfer and line_no=@xlp
	if @@error != 0
		begin
		return @@error
		end

    SELECT @xlp=isnull((select min(line_no) from xfer_list where xfer_no=@xfer and shipped < ordered
		and line_no > @xlp and isnull(back_ord_flag,0) = 0),0)
END 


IF (select count(*) from xfer_list where xfer_no=@new_xfer ) = 0
	BEGIN
		DELETE xfers_all WHERE xfer_no=@new_xfer
		if @@error != 0
			begin
			return @@error
			end
	END

if @ext = 1 
begin
  update xfers_all
    set orig_xfer_no = xfer_no,
      orig_xfer_ext = 0 
  where xfer_no = @xfer
end

return 1
GO
GRANT EXECUTE ON  [dbo].[fs_create_backorder_xfer] TO [public]
GO
