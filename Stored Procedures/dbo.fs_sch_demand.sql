SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_demand] @batch_id varchar(20)
  AS 

set nocount on



--******************************************************************************
--*                    Codes used for the source of demand
--* 'N'egative  = Negative On-Hand stock
--* 'C'ustomer  = Sales Order demand
--* 'M'inimums  = Inventory Minimum demand
--* 'X'fer    = Transfer Order demand
--* 'W'ork order= Work Order component demand
--* 'F'orecast  = Forecast demand
--* 'V'endor Ret= Return to Vendor order demand
--******************************************************************************

declare @lev int, @cnt int
declare @minord decimal(20,8)

declare @end_date  datetime
declare  @pn    varchar(30),
  @buyer    varchar(10),
  @location  varchar(10),
  @vendor_no  varchar(12),
  @part_no  varchar(30),
  @category  varchar(10),
  @part_type  varchar(10)
declare  @neg_flag  char(1),
  @min_flag  char(1),
  @so_flag  char(1),
  @so_hold_flag  char(1),
  @fcst_flag  char(1),
  @xfer_flag  char(1),
  @wo_flag  char(1),
  @rtv_flag  char(1),
  @stock_flag  char(1),
  @cust_code varchar(10),
  @in_order char(1),
  @ex_order char(1),

  @eproc_ind int
--******************************************************************************
--* Obtain the user's selection criteria for which demand sources to include
--*  in the calculation
--******************************************************************************
select @eproc_ind = 0

if exists (select 1 from config (nolock) where flag = 'PUR_EPROCUREMENT' and upper(value_str) like 'Y%') -- mls 9/8/03 SCR 31491
  select @eproc_ind = 1

SELECT  @buyer    = IsNull(buyer, '%'),
  @location  = IsNull(location, '%'),
  @vendor_no  = IsNull(vendor_no, '%'),
  @part_no  = IsNull(part_no, '%'),
  @category  = IsNull(category, '%'),
  @part_type  = IsNull(part_type, '%'),
  @end_date  = time_fence_end_date,
  @neg_flag  = demand_neg_flag,
  @min_flag  = demand_min_flag,
  @so_flag  = demand_so_flag,
  @so_hold_flag  = demand_so_hold_flag,
  @fcst_flag  = demand_fcast_flag,
  @xfer_flag  = demand_xfer_flag,
  @wo_flag  = demand_wo_flag,
  @rtv_flag  = demand_rtv_flag,
  @stock_flag  = demand_stock_flag,
  @cust_code = case when isnull(cust_code,'') = '' then '%' else cust_code end,
  @in_order = case when @eproc_ind = 1 then isnull(demand_so_internal_flag,'Y') else 'Y' end,
  @ex_order = case when @eproc_ind = 1 then isnull(demand_so_external_flag,'Y') else 'Y' end
FROM  resource_batch (nolock)
WHERE  batch_id   = @batch_id

--******************************************************************************
--* Set the time fence end date to the last minute of that day
--******************************************************************************
select @end_date = convert(char(8), @end_date, 1) + ' 23:59:59'

--******************************************************************************
--* Get selected inventory items
--******************************************************************************
if not exists (select 1 from #resource_demand where source = 'T')
begin
  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2,
    min_stock , max_stock )
  SELECT  @batch_id, 0, l.part_no, l.min_stock,
--  case when @min_flag = 'X' then l.max_stock else l.min_stock end,	-- mls 11/29/04 SCR 33703
    convert(char(8),getdate(),1 )+' 00:00:00', 		-- demand date is immediate
    l.location, 'T',     					-- set source to 'M' for Minimum
    'T', 0, '0',     					-- source_no is 0 for all minimum entries
    1, 0, l.status, m.vendor, m.uom, '', m.buyer, 0, l.location,
  isnull(l.min_stock,0), 
case when @min_flag = 'X' then isnull(l.max_stock,0) else isnull(l.min_stock,0) end				-- mls 12/10/04 SCR 33703
  FROM  inv_list l (nolock)
  JOIN  inv_master m (nolock) on m.part_no = l.part_no
  WHERE l.status  <= 'Q' and        -- exclude non-qty bearing
  (isnull(m.obsolete,0) != 1 and isnull(m.void,'N') != 'V') and			-- mls 3/11/02 SCR 28499
    ((l.location  like @location) or (l.location is NULL and @location = '%')) and
    ((l.part_no  like @part_no) or (l.part_no is NULL and @part_no = '%')) and
    ((m.buyer  like @buyer) or  (m.buyer is NULL and @buyer = '%')) and
    ((m.vendor  like @vendor_no) or (m.vendor is NULL and @vendor_no = '%')) and
    ((m.category  like @category) or (m.category is NULL and @category = '%')) and
    ((m.type_code  like @part_type) or (m.type_code is NULL and @part_type = '%')) and
    l.location not like 'DROP%'
end

--******************************************************************************
--* Get demand from negative stock
--******************************************************************************
if @neg_flag = 'Y'
begin
  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2)
  SELECT  @batch_id, 0, t.part_no, (i.in_stock * -1),  	-- negative supply is positive demand
    convert(char(8),getdate(),1 )+' 00:00:00', 		-- demand date is immediate
    t.location, 'N',     					-- set source to 'N' for Negative
    'N', 0, '0',     					-- source_no is 0 for all negative entries
    1, 0, t.type, t.vendor, t.uom, '', t.buyer, 0, t.location
  FROM #resource_demand t (nolock), inventory i (nolock)
  where i.part_no = t.part_no and i.location = t.location
    and i.in_stock < 0 and t.source = 'T'
  order by t.location, t.part_no
end -- @neg_flag = 'Y'


--******************************************************************************
--*  Get demand for minimum stock
--******************************************************************************
if @min_flag in ( 'Y','X')
begin
  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2, min_stock, max_stock)
  SELECT  @batch_id, 0, part_no, qty,
    convert(char(8),getdate(),1 )+' 00:00:00', 		-- demand date is immediate
    location, 'M',     					-- set source to 'M' for Minimum
    'N', 0, '0',     					-- source_no is 0 for all minimum entries
    1, 0, type, vendor, uom, '', buyer, 0, location2, min_stock, max_stock
  FROM #resource_demand (nolock)
  where source = 'T' and qty > 0
  order by batch_id, ilevel, location, part_no, source, source_no, demand_date, status, parent
end -- if @min_flag = 'Y'

--******************************************************************************
--*  Get Demand from customer orders
--******************************************************************************
if @so_flag = 'Y'
begin
  --******************************************************************************
  --* Pick up item demand from order lines for all items except Custom Kit parents. 
  --* We do a SELECT DISTINCT from the orders tables in case an item appears on
  --* more than one line in an order - we only want to have one record in
  --* resource_demand.
  --******************************************************************************
  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2)
  SELECT
    @batch_id, 0, ol.part_no, SUM((ordered - shipped) * conv_factor),			-- mls 3/15/02 SCR 28532 
    sch_ship_date, ol.location, '1',              					-- mls 3/25/02 SCR 28514
    'N', 0,
    (convert(varchar(20), o.order_no) + '-' + convert(varchar(20), o.ext)),  -- source number is the Sales Order number
    1,                      				-- skk 04/06/01 SCR 26622
    0, t.type, t.vendor, t.uom, '', t.buyer, 0, ol.location
  FROM  orders_all o (nolock), ord_list ol (nolock), #resource_demand t (nolock)
  WHERE  o.order_no = ol.order_no and o.ext = ol.order_ext 
    and o.cust_code like @cust_code								-- mls 9/12/03 SCR 31491
    and (@in_order = 'Y' or isnull(eprocurement_ind,0) = 0)
    and (@ex_order = 'Y' or isnull(eprocurement_ind,0) = 1)
    and ol.part_type  != 'C' and        -- do not pick up Custom Kit parents
    ((o.status  between 'N' and 'R') or			-- mls 3/15/02 SCR 28532    -- always orders with status New
    (o.status  in ('A','B','C','H') and
    @so_hold_flag = 'Y')) and        -- maybe orders with hold status
    o.type    = 'I' and        -- don't include credit returns
    o.sch_ship_date  <= @end_date and      -- scheduled ship date within the time fence
    ol.ordered  > 0 and (ol.ordered - ol.shipped) > 0 and				-- mls 3/15/02 SCR 28532 
    t.part_no = ol.part_no and t.location = ol.location and t.source = 'T'
  group by ol.part_no, sch_ship_date, ol.location, o.order_no, o.ext, t.type,
    t.vendor, t.uom, t.buyer

  --******************************************************************************
  --* Pick up demand for component items of Custom Kits.
  --*  This information comes from ord_list_kit instead of ord_list.
  --******************************************************************************
  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2)
  SELECT 
    @batch_id, 0, olk.part_no, SUM((ordered - shipped) * conv_factor * qty_per),	-- mls 3/15/02 SCR 28532 
    o.sch_ship_date, olk.location, '2',              					-- mls 3/25/02 SCR 28514
    'N', 0,
    (convert(varchar(20), o.order_no) + '-' + convert(varchar(20), o.ext)),  -- source number is the Sales Order number
    1,                        				-- skk 04/06/01 SCR 26622
    0, t.type, t.vendor, t.uom, '', t.buyer, 0, olk.location
  FROM  orders_all o (nolock), ord_list_kit olk (nolock), #resource_demand t (nolock)    	-- skk 03/20/01 SCR 26115
  WHERE  o.order_no  = olk.order_no and
    o.ext    = olk.order_ext 
    and o.cust_code like @cust_code								-- mls 9/12/03 SCR 31491
    and (@in_order = 'Y' or isnull(eprocurement_ind,0) = 0)
    and (@ex_order = 'Y' or isnull(eprocurement_ind,0) = 1)
    and ((o.status  between 'N' and 'R') or				-- mls 3/15/02 SCR 28532 
    (o.status  in ('A','B','C','H') and
    @so_hold_flag  = 'Y')) and        -- maybe orders with hold status
    o.type    = 'I' and        -- don't include credit returns
    o.sch_ship_date <= @end_date and
    (olk.ordered * olk.qty_per) > 0 and (olk.ordered - olk.shipped) > 0 and		-- mls 3/15/02 SCR 28532 
    t.part_no = olk.part_no and t.location = olk.location and t.source = 'T'
  group by olk.part_no, o.sch_ship_date, olk.location, o.order_no, o.ext, t.type,
    t.vendor, t.uom, t.buyer

  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,			-- mls 3/25/02 SCR 28514 start
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2)
  SELECT
    @batch_id, 0, part_no, SUM(qty), demand_date,
    location, 'C', 'N', 0, source_no, 1, 0, type,
    vendor, uom, '', buyer, 0, location2
  FROM #resource_demand t
  where t.source in ('1','2')
  group by part_no, demand_date, location, source_no, type, vendor, uom, buyer, location2

  delete from #resource_demand where source in ('1','2')				-- mls 3/25/02 SCR 28514 end
end -- if @so_flag = 'Y'

--******************************************************************************
--* Get demand from transfer orders
--******************************************************************************
if @xfer_flag = 'Y'
begin
  --******************************************************************************
  --* skk 2/23/01
  --* Do a SELECT DISTINCT because a transfer order can contain the same part
  --* number on more than one line.  Do the initial INSERT with 0 qty and then
  --* update the qty to get the sum for all rows with the same part number.
  --******************************************************************************
  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2)
  SELECT DISTINCT             					-- skk 2/23/01
    @batch_id, 0, xl.part_no, sum(xl.ordered * xl.conv_factor),
    x.sch_ship_date,          					-- demand date is scheduled ship date
    xl.from_loc,            					-- a xfer is demand for the "from" location
    'X',              						-- set source to 'X' for Xfer order
    'N', 0, x.xfer_no,           	 			-- source_no is the xfer order number
    1, 0, t.type, t.vendor, t.uom, '', t.buyer, 0, xl.from_loc
  FROM  xfers_all x (nolock), xfer_list xl (nolock), #resource_demand t (nolock)	-- skk 03/20/01 SCR 26115
  WHERE  x.xfer_no  = xl.xfer_no and
    x.status  = 'N' and        					-- only new transfer orders not yet shipped
    x.sch_ship_date <= @end_date and
    t.part_no = xl.part_no and t.location = xl.from_loc and t.source = 'T'
  group by xl.part_no, x.sch_ship_date, xl.from_loc, x.xfer_no,  t.type,
    t.vendor, t.uom, t.buyer
end -- if @xfer_flag = 'Y'

--******************************************************************************
--* Get demand from open work orders
--******************************************************************************
if @wo_flag = 'Y'
begin
  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2)
  SELECT  
    @batch_id, 0, pl.part_no, sum(((pl.plan_qty - pl.used_qty) * pl.conv_factor)),	-- mls 3/25/02 SCR 28514
    p.prod_date, pl.location, 'W',              -- set source to 'W' for work order
    'N', 0, p.prod_no, 1, 0, t.type, t.vendor, t.uom, '', t.buyer,
    0, pl.location
  FROM  produce_all p (nolock), prod_list pl (nolock), 
    #resource_demand t (nolock)						      -- mls 3/1/02 SCR 28456
  WHERE  p.prod_no  = pl.prod_no and
    p.prod_ext  = pl.prod_ext and
    t.part_no = pl.part_no and t.location = pl.location and t.source = 'T' and -- mls 3/1/02 SCR 28456
    (p.status  >= 'N' and p.status <= 'Q') and    -- New, Picked, or Printed
    p.prod_date  <= @end_date and
    pl.part_type   in ('M', 'P') and      -- Make, or Purchase	-- mls 5/29/02 SCR 29001
    pl.seq_no  > ''          -- exclude parent items
  group by pl.part_no, p.prod_date, pl.location, p.prod_no, t.type, t.vendor, t.uom, t.buyer -- mls 3/25/02 SCR 28514
end -- if @wo_flag = 'Y'

--******************************************************************************
--* Get demand from Return to Vendor orders
--******************************************************************************
if @rtv_flag = 'Y'
begin
  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2)
  SELECT  @batch_id, 0, rl.part_no, sum(rl.qty_ordered * rl.conv_factor),
    r.date_order_due, rl.location, 'V',           -- set source to 'V' for RTV
    'N', 0, r.rtv_no, 1, 0, t.type, t.vendor, t.uom, '',
    t.buyer, 0, rl.location
  FROM  rtv_all r (nolock), rtv_list rl (nolock), #resource_demand t (nolock)
  WHERE  r.rtv_no  = rl.rtv_no and
    r.status  = 'N' and        -- New, not shipped yet
    r.date_order_due <= @end_date and
    t.part_no = rl.part_no and t.location = rl.location and t.source = 'T'
  group by rl.part_no, r.date_order_due, rl.location, r.rtv_no, t.type, t.vendor, t.uom, t.buyer
end -- if @rtv_flag = 'Y'

--******************************************************************************
--* Get forecasted demand - do this in a seperate procedure because there is too
--* much code to include inline here
--******************************************************************************
if @fcst_flag = 'Y'
begin
  EXEC fs_sch_demand_forecast @batch_id, @buyer, @location, @vendor_no,
    @part_no, @category, @part_type, @end_date
end -- if @fcst_flag = 'Y'

--******************************************************************************
--* Clear any zero or negative entries
--******************************************************************************
--delete from #resource_demand where source = 'T'

DELETE  #resource_demand WHERE qty <= 0 and source != 'T'

GO
GRANT EXECUTE ON  [dbo].[fs_sch_demand] TO [public]
GO
