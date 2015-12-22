SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CT 08/11/12 - New fields autopack and autoship
-- v1.2 CB 07/08/2013 - Isssue #1202 - Transfer email moved to transfer ship confirm

CREATE PROCEDURE [dbo].[scm_pb_set_dw_transfer_sp]  
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
, @from_organization_id varchar(30), @to_organization_id varchar(30)  
, @proc_po_no varchar(20), @i_eprocurement_interface integer  
, @back_ord_flag integer, @orig_xfer_no integer, @orig_xfer_ext integer
, @timestamp varchar(20)
, @autopack SMALLINT, @autoship SMALLINT -- v1.1  

 AS  
BEGIN  
set nocount on  
DECLARE @ts timestamp  
exec adm_varchar_to_ts_sp @timestamp, @ts output  
if @typ = 'I'  
begin  
Insert into xfers_all (xfers.xfer_no, xfers.from_loc, xfers.to_loc, xfers.req_ship_date  
, xfers.sch_ship_date, xfers.date_shipped, xfers.date_entered, xfers.req_no  
, xfers.who_entered, xfers.status, xfers.attention, xfers.phone, xfers.routing  
, xfers.special_instr, xfers.fob, xfers.freight, xfers.printed, xfers.label_no  
, xfers.no_cartons, xfers.who_shipped, xfers.date_printed, xfers.who_picked  
, xfers.to_loc_name, xfers.to_loc_addr1, xfers.to_loc_addr2, xfers.note  
, xfers.rec_no, xfers.freight_type, xfers.no_pallets, xfers.to_loc_addr3  
, xfers.to_loc_addr4, xfers.to_loc_addr5, xfers.who_recvd, xfers.date_recvd  
, xfers.from_organization_id, xfers.to_organization_id, xfers.back_ord_flag  
, xfers.autopack, xfers.autoship)  -- v1.1
values (@no, @from_loc, @to_loc, @req_ship_date, @sch_ship_date, @date_shipped  
, @date_entered, @req_no, @who_entered, @status, @attention, @phone, @c_routing  
, @si, @fob, @freight, @printed, @label_no, @no_cartons, @who_shipped  
, @date_printed, @who_picked, @to_loc_name, @to_loc_addr1, @to_loc_addr2, @note  
, @rec_no, @freight_type, @xfers_no_pallets, @to_loc_addr3, @to_loc_addr4  
, @to_loc_addr5, @who_recvd, @date_recvd, @from_organization_id  
, @to_organization_id, @back_ord_flag 
, @autopack, @autoship -- v1.1 
)  
end  
if @typ = 'U'  
begin

-- Unallocate first
EXEC cvo_plw_xfer_unallocate_sp @no, @who_entered -- v1.1
  
update xfers set  
xfers.from_loc= @from_loc, xfers.to_loc= @to_loc  
, xfers.req_ship_date= @req_ship_date, xfers.sch_ship_date= @sch_ship_date  
, xfers.date_shipped= @date_shipped, xfers.date_entered= @date_entered  
, xfers.req_no= @req_no, xfers.who_entered= @who_entered, xfers.status= @status  
, xfers.attention= @attention, xfers.phone= @phone, xfers.routing= @c_routing  
, xfers.special_instr= @si, xfers.fob= @fob, xfers.freight= @freight  
, xfers.printed= @printed, xfers.label_no= @label_no  
, xfers.no_cartons= @no_cartons, xfers.who_shipped= @who_shipped  
, xfers.date_printed= @date_printed, xfers.who_picked= @who_picked  
, xfers.to_loc_name= @to_loc_name, xfers.to_loc_addr1= @to_loc_addr1  
, xfers.to_loc_addr2= @to_loc_addr2, xfers.note= @note, xfers.rec_no= @rec_no  
, xfers.freight_type= @freight_type, xfers.no_pallets= @xfers_no_pallets  
, xfers.to_loc_addr3= @to_loc_addr3, xfers.to_loc_addr4= @to_loc_addr4  
, xfers.to_loc_addr5= @to_loc_addr5, xfers.who_recvd= @who_recvd  
, xfers.date_recvd= @date_recvd  
, xfers.from_organization_id= @from_organization_id  
, xfers.to_organization_id= @to_organization_id  
, xfers.back_ord_flag= @back_ord_flag 
, xfers.autopack = @autopack	-- v1.1
, xfers.autoship = @autoship	-- v1.1 
from xfers_all xfers  
join xfers x (nolock) on x.xfer_no = xfers.xfer_no  
where xfers.xfer_no= @no  
 and xfers.timestamp= @ts  
if @@rowcount = 0  
begin  
  rollback tran  
  RAISERROR 832115 'Row changed between retrieve and update'  
  RETURN   
end  
  
end  
if @typ = 'D'  
begin 

-- Unallocate first
EXEC cvo_plw_xfer_unallocate_sp @no, @who_entered -- v1.1
 
delete from xfers_all  
where xfers_all.xfer_no= @no  
if @@rowcount = 0  
begin  
  rollback tran  
  RAISERROR 832115 'Error Deleting Row'  
  RETURN   
end  
  
end  

--BEGIN SED009 -- Transfer Orders - Product Shipping to & From a Sales Rep
--JVM 09/21/2010
--xfer was created and saved from Sales Rep to CVO
-- v1.2 Start
--	IF (@typ = 'I' OR @typ = 'U') 
--		EXEC CVO_send_xfer_notification_sp @no, 2
-- v1.2 End
--END   SED009 -- Transfer Orders - Product Shipping to & From a Sales Rep
  
return  
end  
  
GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_transfer_sp] TO [public]
GO
