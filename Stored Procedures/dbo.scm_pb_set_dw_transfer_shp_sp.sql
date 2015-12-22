SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[scm_pb_set_dw_transfer_shp_sp]
@typ char(1), @no integer, @from_loc varchar(10), @to_loc varchar(10)
, @req_ship_date datetime, @sch_ship_date datetime, @date_shipped datetime
, @date_entered datetime, @req_no varchar(20), @who_entered varchar(20)
, @status char(1), @attention varchar(15), @phone varchar(20)
, @c_routing varchar(20), @si varchar(255), @fob varchar(10)
, @freight decimal(20,8), @printed char(1), @label_no integer
, @no_cartons integer, @who_shipped varchar(20), @date_printed datetime
, @who_picked varchar(20), @to_loc_name varchar(40), @to_loc_addr1 varchar(40)
, @to_loc_addr2 varchar(40), @locations_name varchar(30)
, @locations_addr1 varchar(40), @locations_addr2 varchar(40), @note varchar(255)
, @rec_no integer, @freight_type varchar(10), @xfers_no_pallets integer
, @freight_type_description varchar(40), @arshipv_ship_via_name varchar(40)
, @locations_addr3 varchar(40), @locations_addr4 varchar(40)
, @locations_addr5 varchar(40), @to_loc_addr3 varchar(40)
, @to_loc_addr4 varchar(40), @to_loc_addr5 varchar(40), @who_recvd varchar(20)
, @date_recvd datetime, @c_status char(1), @c_tdc_status varchar(100)
, @dflt_recv_bin varchar(12), @from_organization_id varchar(30)
, @to_organization_id varchar(30), @auto_rcv_tfr integer
, @proc_po_no varchar(20), @i_eprocurement_interface integer
, @back_ord_flag integer, @orig_xfer_no integer, @orig_xfer_ext integer
, @timestamp varchar(20)
 AS
BEGIN
set nocount on
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
  rollback tran
  RAISERROR 832115 'You cannot insert a new transfer from the transfer ship screen'
  RETURN 
end
if @typ = 'U'
begin
update xfers_from set
xfers_from.from_loc= @from_loc, xfers_from.to_loc= @to_loc
, xfers_from.req_ship_date= @req_ship_date
, xfers_from.sch_ship_date= @sch_ship_date
, xfers_from.date_shipped= @date_shipped
, xfers_from.date_entered= @date_entered, xfers_from.req_no= @req_no
, xfers_from.who_entered= @who_entered, xfers_from.status= @status
, xfers_from.attention= @attention, xfers_from.phone= @phone
, xfers_from.routing= @c_routing, xfers_from.special_instr= @si
, xfers_from.fob= @fob, xfers_from.freight= @freight
, xfers_from.printed= @printed, xfers_from.label_no= @label_no
, xfers_from.no_cartons= @no_cartons
, xfers_from.who_shipped= @who_shipped
, xfers_from.date_printed= @date_printed
, xfers_from.who_picked= @who_picked
, xfers_from.to_loc_name= @to_loc_name
, xfers_from.to_loc_addr1= @to_loc_addr1
, xfers_from.to_loc_addr2= @to_loc_addr2, xfers_from.note= @note
, xfers_from.rec_no= @rec_no, xfers_from.freight_type= @freight_type
, xfers_from.no_pallets= @xfers_no_pallets
, xfers_from.to_loc_addr3= @to_loc_addr3
, xfers_from.to_loc_addr4= @to_loc_addr4
, xfers_from.to_loc_addr5= @to_loc_addr5
, xfers_from.who_recvd= @who_recvd, xfers_from.date_recvd= @date_recvd
, xfers_from.back_ord_flag= @back_ord_flag
from xfers_all xfers_from
join xfers_from x (nolock) on x.xfer_no = xfers_from.xfer_no
where xfers_from.xfer_no= @no
 and (xfers_from.timestamp= @ts or (xfers_from.status = 'Q' and @status = 'R'))
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end

end
if @typ = 'D'
begin
delete from xfers_all
where xfers_all.xfer_no= @no
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Error Deleting Row'
  RETURN 
end

end

return
end

GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_transfer_shp_sp] TO [public]
GO
