SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[scm_pb_set_dw_transfer_rcv_sp]
@typ char(1), @no integer, @from_loc varchar(10), @to_loc varchar(10)
, @req_ship_date datetime, @sch_ship_date datetime, @date_shipped datetime
, @date_entered datetime, @req_no varchar(20), @who_entered varchar(20)
, @status char(1), @attention varchar(15), @phone varchar(20)
, @routing varchar(20), @si varchar(255), @fob varchar(10)
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
, @date_recvd datetime, @c_status char(1), @from_organization_id varchar(30)
, @to_organization_id varchar(30), @proc_po_no varchar(20)
, @i_eprocurement_interface integer, @back_ord_flag integer
, @orig_xfer_no integer, @orig_xfer_ext integer, @timestamp varchar(20)
 AS
BEGIN
set nocount on
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
  rollback tran
  RAISERROR 832115 'You cannot insert a new transfer from the transfer receive screen'
  RETURN 
end
if @typ = 'U'
begin
update xfers_to set
xfers_to.from_loc= @from_loc, xfers_to.to_loc= @to_loc
, xfers_to.req_ship_date= @req_ship_date
, xfers_to.sch_ship_date= @sch_ship_date
, xfers_to.date_shipped= @date_shipped
, xfers_to.date_entered= @date_entered, xfers_to.req_no= @req_no
, xfers_to.who_entered= @who_entered, xfers_to.status= @status
, xfers_to.attention= @attention, xfers_to.phone= @phone
, xfers_to.routing= @routing, xfers_to.special_instr= @si
, xfers_to.fob= @fob, xfers_to.freight= @freight
, xfers_to.printed= @printed, xfers_to.label_no= @label_no
, xfers_to.no_cartons= @no_cartons, xfers_to.who_shipped= @who_shipped
, xfers_to.date_printed= @date_printed, xfers_to.who_picked= @who_picked
, xfers_to.to_loc_name= @to_loc_name
, xfers_to.to_loc_addr1= @to_loc_addr1
, xfers_to.to_loc_addr2= @to_loc_addr2, xfers_to.note= @note
, xfers_to.rec_no= @rec_no, xfers_to.freight_type= @freight_type
, xfers_to.no_pallets= @xfers_no_pallets
, xfers_to.to_loc_addr3= @to_loc_addr3
, xfers_to.to_loc_addr4= @to_loc_addr4
, xfers_to.to_loc_addr5= @to_loc_addr5, xfers_to.who_recvd= @who_recvd
, xfers_to.date_recvd= @date_recvd
from xfers_all xfers_to
join xfers_to x (nolock) on x.xfer_no = xfers_to.xfer_no
where xfers_to.xfer_no= @no
 and xfers_to.timestamp= @ts
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
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_transfer_rcv_sp] TO [public]
GO
