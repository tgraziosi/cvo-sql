SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



create procedure [dbo].[adm_ep_ins_xfr]
@proc_po_no		varchar(20), --			REQUIRED
@from_loc		varchar(10), --			REQUIRED
@to_loc			varchar(10), --			REQUIRED
@req_ship_date	datetime = NULL, --		default getdate()
@sch_ship_date	datetime = NULL, --		default getdate()
@date_entered	datetime = NULL, --		default getdate()
@who_entered	varchar(20) = NULL, --	default	user_name()
@attention		varchar(15) = NULL, --	default NULL
@phone			varchar(20) = NULL, --	default NULL
@routing		varchar(20) = NULL, --	default NULL (apshipv.ship_via_code)
@special_instr	varchar(255) = NULL, --	default NULL
@freight		decimal(20,8) = 0,	 --	default 0
@freight_type	varchar(10) = NULL,	 --	default NULL (freight_type.kys)
@note			varchar(255) = NULL	 --	default NULL
as

declare @xfer_no int, @x_to_loc varchar(10), @x_from_loc varchar(10)

if @proc_po_no is null return -10
if @from_loc is NULL return -20
if @to_loc is NULL return -30

if not exists (select 1 from locations_all (nolock)
  where location = @from_loc and void = 'N')  return -21

if not exists (select 1 from locations_all (nolock)
  where location = @to_loc and void = 'N')  return -31

if @req_ship_date is NULL  set @req_ship_date = getdate()
if @sch_ship_date is NULL  set @sch_ship_date = getdate()
if @date_entered is NULL   set @date_entered = getdate()
if @who_entered is NULL    set @who_entered = suser_name()

select @xfer_no = xfer_no,
@x_to_loc = to_loc,
@x_from_loc = from_loc
from xfers_all (nolock)
where proc_po_no = @proc_po_no

if isnull(@xfer_no,'') != ''
begin
  if @to_loc != @x_to_loc  return -100
  if @from_loc != @x_from_loc return -100

  return 100
end
else
begin
  begin tran

  update next_xfer_no
  set last_no = last_no + 1

  select @xfer_no = last_no from next_xfer_no

  insert xfers_all (xfer_no,from_loc,to_loc,req_ship_date,sch_ship_date,date_shipped,date_entered,
    req_no,who_entered,status,attention,phone,routing,special_instr,fob,freight,printed,
    label_no,no_cartons,who_shipped,date_printed,who_picked,to_loc_name,to_loc_addr1,
    to_loc_addr2,to_loc_addr3,to_loc_addr4,to_loc_addr5,no_pallets,shipper_no,shipper_name,
    shipper_addr1,shipper_addr2,shipper_city,shipper_state,shipper_zip,cust_code,
    freight_type,note,rec_no,who_recvd,date_recvd,pick_ctrl_num, proc_po_no)
  select @xfer_no,@from_loc,@to_loc,@req_ship_date,@sch_ship_date,NULL,@date_entered,
    NULL,@who_entered,'N',@attention,@phone,@routing,@special_instr,NULL,@freight,'N',
    0,0,NULL,NULL,NULL,name,addr1,
    addr2,addr3,addr4,addr5,0,NULL,NULL,
    NULL,NULL,NULL,NULL,NULL,NULL,
    @freight_type,@note,0,NULL,NULL,'', @proc_po_no
  from locations_all (nolock)
  where location = @to_loc

  if @@error <> 0
  begin 
    rollback tran
    return -101
  end

  commit tran
end

return 1
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_xfr] TO [public]
GO
