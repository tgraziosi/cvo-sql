SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




-- Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_compare_schedule]
	(
	@sched_id	INT,
        @forecastonly   CHAR(1) = 'A', 
        @apply_changes  INT = 0
	)
AS
BEGIN

-- This procedure returns a result set identifying changes to the
-- core database which have not been reflected in the scheduling system
-- if the apply_changes is set to 0
-- if apply_changes is set to 1, this procedure will apply the changes to the scheduler tables
-- immediately
-- Following are all of the object flag/status flag combinations and
-- the columns which the user should expect to be filled:
--	'R' - Resource <-> Sched_Resource
--	'D' - Orders,Ord_List <-> Sched_Order
--	'P' - Produce <-> Sched_Process
--	'I' - Inventory <-> Sched_Item
--	'O' - Purchase,Releases <-> Sched_Item,Sched_Purchase
--	'N' - Resource_Demand <-> Sched_Item,Sched_Purchase
--      'F' - EFORECAST_FORECAST <-> Sched_Order

DECLARE	@order_usage_mode	CHAR(1),
        @pur_repl_flag          CHAR(1),
        @forecast_resync_flag   CHAR(1),
        @forecast_delete_past_flag CHAR(1),
        @forecast_horizon       INT,
        @forecast_min_date      DATETIME,
        @forecast_max_date      DATETIME,
	@xfer_demand_mode	char(1),		-- mls 4/26/02 SCR 28832
	@xfer_supply_mode	char(1)			-- mls 4/26/02 SCR 28832
DECLARE @drop_result            INT
DECLARE @sched_location		varchar(10)				-- mls #22
DECLARE @purchase_lead_flag	char(1)

DECLARE @err_ind		INT,
        @o_err_ind              INT,
	@order_priority_id	INT,
        @pr_err_ind		INT,
    	@sched_process_id	INT,
 	@sched_operation_id	INT,
	@prod_no		INT,
	@prod_ext		INT,
	@prod_line		INT,
 	@first_call		INT,
	@rc			INT

SET NOCOUNT ON

SELECT @drop_result = 0

-- Get the models order handling mode
SELECT	@order_usage_mode=SM.order_usage_mode,
	@purchase_lead_flag = SM.purchase_lead_flag,
        @forecast_resync_flag = SM.forecast_resync_flag,
        @forecast_delete_past_flag = SM.forecast_delete_past_flag,
        @forecast_horizon = SM.forecast_horizon,
        @xfer_demand_mode = transfer_demand_mode,	-- mls 4/26/02 SCR 28832
        @xfer_supply_mode = transfer_supply_mode	-- mls 4/26/02 SCR 28832
FROM	sched_model SM (nolock)
WHERE	SM.sched_id = @sched_id

-- Check to make sure model exists
IF @@rowcount <> 1
	BEGIN
	RaisError 69010 'Schedule model does not exist.'
	RETURN
	END

SELECT	@order_priority_id=OP.order_priority_id
FROM	order_priority OP
WHERE	OP.usage_flag = 'D'

IF @@rowcount <> 1
BEGIN
  RaisError 64049 'Unable to determine default order priority'
  RETURN
END

-----------------------------------------------------------------------------------------------------------------
-- This flag indicates whether inventory for purchases is being replenished via the scheduler.  If 'N', then 
-- we don't want to bring in new or changed records from the resource_demand_group table.  They are in the table
-- as suggested purchases by the inventory replenishment module.
-----------------------------------------------------------------------------------------------------------------
SELECT	@pur_repl_flag = LEFT(CG.value_str,1) FROM config CG (nolock)
WHERE		CG.flag = 'PUR_INV_REPL'

-- Create table to report differences (if it wasn't already created by the calling proc)
CREATE TABLE #result										-- mls 1/22/03 SCR 30559
	(
	object_flag		CHAR(1),
	status_flag		CHAR(1),
	location		VARCHAR(10)	NULL,
	resource_id		INT		NULL,
	sched_resource_id	INT		NULL,
	part_no			VARCHAR(30)	NULL,
	sched_order_id		INT		NULL,
	order_no		INT		NULL,
	order_ext		INT		NULL,
	order_line		INT		NULL,
	order_line_kit		INT		NULL,
	sched_process_id	INT		NULL,
	sched_operation_id	INT		NULL,
	prod_no			INT		NULL,
	prod_ext		INT		NULL,
	prod_line		INT		NULL,
	sched_item_id		INT		NULL,
	po_no			VARCHAR(16)	NULL,		-- mls 2/28/03 SCR 30781
	release_id		INT		NULL,
	sched_transfer_id	INT		NULL,
	xfer_no			INT		NULL,
	xfer_line		INT		NULL,
	resource_demand_id	INT		NULL,
        forecast_demand_date    DATETIME        NULL,
        forecast_qty            FLOAT           NULL,
        forecast_uom            VARCHAR(2)      NULL,
	message			VARCHAR(255)
	)

create index #r1 on #result(order_no,order_ext)
create index #r2 on #result(sched_process_id)
create index #r3 on #result(po_no)
create index #r4 on #result(xfer_no)
create index #r5 on #result(object_flag,status_flag)

CREATE TABLE #inv_forecast (
  inv_forecast_location        VARCHAR(10) NOT NULL,
  inv_forecast_part_no         VARCHAR(30) NOT NULL,
  inv_forecast_demand_date     DATETIME NOT NULL,
  inv_forecast_qty             FLOAT NOT NULL
)

CREATE TABLE #res_group (part_no varchar(30) NOT NULL)

create index #rg1 on #res_group(part_no)

create index #inf1 on #inv_forecast(inv_forecast_location, inv_forecast_part_no, inv_forecast_demand_date)

create table #sched_locations (location varchar(10))		-- mls 4/29/02 SCR 28832
create index #sl1 on #sched_locations(location)			-- mls 4/29/02 SCR 28832

-- mls 11/8/02 start
create table #order_detail( location varchar(10), demand_date datetime null,
  part_no varchar(30) NULL, uom_qty decimal(20,8), uom char(2) NULL,
  source_flag char(1), order_no int, order_ext int, line_no int,
  prod_no int NULL, prod_ext int null, order_line_kit int,
  status char(1) NULL, back_ord_flag char(1) NULL, part_type char(1),
  sales_qty_mtd decimal(20,8) NULL)

create index od1 on #order_detail(part_no,location,sales_qty_mtd)
create index od2 on #order_detail(order_no,order_ext,line_no,order_line_kit)
-- mls 11/8/02 end

-- mls 11/25/02 start
create table #process_detail (
  prod_no int, 
  prod_ext int, 
  h_part_no varchar(30) NULL, 
  h_location varchar(10) NULL,
  h_uom char(2) NULL,
  d_part_no  varchar(30) , 
  d_location  varchar(10) , 
  d_uom char(2) NULL, 
  qty decimal(20,8) , 
  void char(1) NULL, 
  status char(1) ,
  hold_flag char(1) , 
  qty_scheduled decimal(20,8) NULL, 
  qty_scheduled_orig decimal(20,8) NULL, 
  prod_type varchar(10) , 
  bom_rev varchar(10) NULL, 
  end_sch_date datetime NULL, 
  prod_date datetime , 
  line_no int , 
  p_pcs decimal(20,8) NULL, 
  direction int NULL, 
  plan_pcs decimal(20,8) , 
  pieces decimal(20,8) , 
  seq_no  varchar(4) , 
  scrap_pcs decimal(20,8) , 
  oper_status char(1) NULL, 
  plan_qty decimal(20,8) ,
  used_qty decimal(20,8) , 
  constrain char(1) NULL,
  pool_qty decimal(20,8) NULL, 
  part_type char(1) NULL, 
  active char(1) , 
  eff_date datetime NULL,
  p_qty decimal(20,8) NULL, 
  cost_pct decimal(20,8) NULL, 
  p_line int NULL, 
  im_status char(1) NULL, 
  im_type_code  varchar(10) NULL, 
  il_lead_time int NULL,
  h_usage_mtd decimal(20,8) NULL,
  h_produced_mtd decimal(20,8) NULL,
  d_usage_mtd decimal(20,8) NULL,
  d_produced_mtd decimal(20,8) NULL,
  d_status char(1) NULL,
  d_qc_no int NULL
)

create index #pd1 on #process_detail(prod_no, prod_ext, line_no)
create index #pd2 on #process_detail(prod_no, prod_ext, direction,seq_no)
create index #pd3 on #process_detail(h_location,prod_no, prod_ext)
create index #pd4 on #process_detail(h_location,h_part_no,h_produced_mtd,h_usage_mtd)
create index #pd5 on #process_detail(d_location,d_part_no,d_produced_mtd,d_usage_mtd)

create table #purchase_detail(
rcd_type char(1),
po_no varchar(16) ,					-- mls 2/28/03 SCR 30781
vendor_no varchar(12),
part_no varchar(30),
row_id int,
status char(1),
quantity decimal(20,8),
received decimal(20,8),
release_date datetime,
po_line int NULL,
location varchar(10),
confirmed char(1) NULL,
confirm_date datetime NULL,
due_date datetime NULL,
conv_factor decimal(20,8),
part_type varchar(10) NULL,
receipts_quantity decimal(20,8),
lead_time int NULL,
dock_to_stock int NULL,
unit_measure char(2) NULL,
uom char(2) NULL,
recv_mtd decimal(20,8) NULL
)

create table #replenishment_detail(
part_no varchar(30),
row_id int,
location varchar(10),
demand_date datetime,
qty decimal(20,8),
uom char(2),
recv_mtd decimal(20,8) NULL)

create index #rd1 on #replenishment_detail(location,row_id)
create index #rd2 on #replenishment_detail(row_id)
create index #rd3 on #replenishment_detail(location,part_no,recv_mtd)

create table #transfer_detail (
xfer_no int,
from_loc varchar(10),
to_loc varchar(10),
sch_ship_date datetime NULL,
req_ship_date datetime,
line_no int,
part_no varchar(30),
ordered decimal(20,8),
uom char(2) NULL,
from_xfer_mtd decimal(20,8) NULL,
to_xfer_mtd decimal(20,8) NULL)

create index #td1 on #transfer_detail(xfer_no,line_no)
create index #td2 on #transfer_detail(from_loc,part_no,from_xfer_mtd)
create index #td3 on #transfer_detail(to_loc,part_no,to_xfer_mtd)


create table #inventory_detail(
part_no varchar(30),
location varchar(10),
status char(1),
uom char(2),
list_amt decimal(20,8),
produce_amt decimal(20,8),
sales_amt decimal(20,8),
recv_amt decimal(20,8),
xfer_amt decimal(20,8))

create index id1 on #inventory_detail(location,part_no)

-- mls 11/25/02 end

insert #sched_locations								-- mls 4/29/02 SCR 28832
select location from sched_location SL (nolock) where SL.sched_id = @sched_id

if @forecast_resync_flag = 'Y'
BEGIN
  -- Select forecast from the inventory (smart) tables based on whether we are ignoring past-due forecast and the forecast horizon.
  IF @forecast_delete_past_flag = 'Y'
    SELECT @forecast_min_date = convert(varchar(2),month(getdate())) + '/01/' + 
      convert(varchar(4),year(getdate()))			-- mls 6/4/02 SCR 29031
  ELSE
    SELECT @forecast_min_date = '01-01-1970'

  IF @forecast_horizon > 0
    SELECT @forecast_max_date = dateadd(day,@forecast_horizon,getdate())
  ELSE
    SELECT @forecast_max_date = '01-01-2038'
END

IF @forecastonly = 'A'
BEGIN
  exec @rc = fs_compare_schedule_orders @sched_id, -1, @sched_location, @order_usage_mode, @order_priority_id,
    @apply_changes

  if @rc <> 0
  begin
    RaisError 99021108 'Error returned gathering order information'
    return
  end

  exec @rc = fs_compare_schedule_processes @sched_id,-1,@sched_location,@apply_changes

  if @rc <> 0
  begin
    RaisError 99021109 'Error returned gathering process information'
    return
  end

  exec fs_compare_schedule_xfers @sched_id,-1,@sched_location,@xfer_demand_mode,@xfer_supply_mode,
    @order_priority_id,@apply_changes

  if @rc <> 0
  begin
    RaisError 99021109 'Error returned gathering transfer information'
    return
  end

  exec fs_compare_schedule_purchases @sched_id,-1,@sched_location,@pur_repl_flag,@purchase_lead_flag,@apply_changes

  if @rc <> 0
  begin
    RaisError 99021109 'Error returned gathering purchase information'
    return
  end

  exec fs_compare_schedule_inventory @sched_id,-1,@sched_location,@apply_changes
 
  if @rc <> 0
  begin
    RaisError 99021109 'Error returned gathering inventory information'
    return
  end
end 

exec fs_compare_schedule_forecast @sched_id,-1,@sched_location,
   @forecast_resync_flag, @forecast_delete_past_flag, @forecast_horizon,
   @forecast_min_date, @forecast_max_date, @order_priority_id, @apply_changes

if @rc <> 0
begin
  RaisError 99021109 'Error returned gathering forecast information'
  return
end



insert #res_group
select distinct group_part_no from resource_group

select @first_call = 1

DECLARE schedloc CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
SELECT location
from sched_location SL (nolock) where SL.sched_id = @sched_id

OPEN schedloc
FETCH NEXT FROM schedloc into @sched_location

While @@FETCH_STATUS = 0
begin									-- mls #22 end

IF @forecastonly = 'A'
BEGIN
--
-- sched_resource
--
  select @err_ind = 0
  if @apply_changes = 1
  begin
    INSERT 	sched_resource(sched_id,location,resource_type_id,resource_id,calendar_id,source_flag)
    SELECT	@sched_id,@sched_location,R.resource_type_id,R.resource_id,R.calendar_id,'R'
    FROM	resource R 
    WHERE   R.location = @sched_location
    AND	NOT EXISTS (SELECT 1 FROM sched_resource SR (nolock)
      WHERE SR.sched_id = @sched_id and SR.source_flag = 'R' and SR.resource_id = R.resource_id)
    if @@error <> 1
      select @err_ind = @err_ind + 1

    if (@@version like '%7.0%')
    begin
      delete SOR
      FROM	sched_resource SR, sched_operation_resource SOR
      WHERE	SR.sched_id = @sched_id AND SR.source_flag = 'R' AND SR.resource_id IS NOT NULL
      AND	NOT EXISTS (SELECT 1 FROM resource R (nolock) WHERE SR.resource_id = R.resource_id)
      if @@error <> 1
        select @err_ind = @err_ind + 1
    end

    DELETE SR
    FROM	sched_resource SR
    WHERE	SR.sched_id = @sched_id AND SR.source_flag = 'R' AND SR.resource_id IS NOT NULL
    AND	NOT EXISTS (SELECT 1 FROM resource R (nolock) WHERE SR.resource_id = R.resource_id)
    if @@error <> 1
      select @err_ind = @err_ind + 1
  end

  if @apply_changes = 0 or @err_ind != 0
  begin
    -- Determine new resources
    INSERT	#result(object_flag,status_flag,location,resource_id,message)
    SELECT	'R','N',R.location,R.resource_id,'New schedule resource found ('+R.resource_code+') '+R.resource_name
    FROM	resource R 
    WHERE   R.location = @sched_location
    AND	NOT EXISTS (SELECT 1 FROM sched_resource SR (nolock)
      WHERE SR.sched_id = @sched_id and SR.source_flag = 'R' and SR.resource_id = R.resource_id)

    -- Determine deleted resources
    INSERT	#result(object_flag,status_flag,location,resource_id,sched_resource_id,message)
    SELECT	'R','O',SR.location,SR.resource_id,SR.sched_resource_id,'Old resource not longer available'
    FROM	sched_resource SR
    WHERE	SR.sched_id = @sched_id AND SR.source_flag = 'R' AND SR.resource_id IS NOT NULL
    AND	NOT EXISTS (SELECT 1 FROM resource R (nolock) WHERE SR.resource_id = R.resource_id)
  end

--
-- sched_orders
--
  exec fs_compare_schedule_orders @sched_id, @first_call, @sched_location, @order_usage_mode, @order_priority_id,
    @apply_changes

-- 
-- sched_process - changes to productions
--
  exec fs_compare_schedule_processes @sched_id,@first_call,@sched_location,@apply_changes

-- 
-- sched_item - changes to purchase
--
  exec fs_compare_schedule_purchases @sched_id,@first_call,@sched_location,@pur_repl_flag,@purchase_lead_flag,@apply_changes

-- 
-- sched_transfer - changes to transfers
--
  exec fs_compare_schedule_xfers @sched_id,@first_call,@sched_location,@xfer_demand_mode,@xfer_supply_mode,
    @order_priority_id,@apply_changes

-- 
-- sched_item - changes to inventory
--
  exec fs_compare_schedule_inventory @sched_id,@first_call,@sched_location,@apply_changes
end -- @forecastonly = 'A'

-- 
-- sched_item - changes to forecasts
--
  exec fs_compare_schedule_forecast @sched_id,@first_call,@sched_location,
     @forecast_resync_flag, @forecast_delete_past_flag, @forecast_horizon,
     @forecast_min_date, @forecast_max_date, @order_priority_id, @apply_changes

  select @first_call = 0
  FETCH NEXT FROM schedloc into @sched_location
end -- while @@fetchstatus = 0

CLOSE schedloc
Deallocate schedloc

-- =================================================
-- Report results
-- =================================================
SELECT	object_flag,
	status_flag,
	location,
	resource_id,
	sched_resource_id,
	part_no,
	sched_order_id,
	order_no,
	order_ext,
	order_line,
	order_line_kit,
	sched_process_id,
	sched_operation_id,
	prod_no,
	prod_ext,
	prod_line,
	sched_item_id,
	po_no,
	release_id,
	sched_transfer_id,
	xfer_no,
	xfer_line,
	resource_demand_id,
        forecast_demand_date,
        forecast_qty,
        forecast_uom,
	message,
	' ' note
FROM	#result


DROP TABLE #inv_forecast    
DROP TABLE #result							-- mls 1/22/03 SCR 30559

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_compare_schedule] TO [public]
GO
