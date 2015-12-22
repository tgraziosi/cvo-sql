SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 09/09/2011 -- Added style

CREATE PROCEDURE [dbo].[fs_sch_avail] @batch_id varchar(20)
  AS 



declare @this_morning  datetime,
  @end_date    datetime
declare  @buyer      varchar(10),
  @location    varchar(10),
  @vendor_no    varchar(12),
  @part_no    varchar(30),
  @category    varchar(10),
  @part_type    varchar(10),
  @org_id varchar(30)
declare  @po_flag    char(1),
  @qc_flag    char(1),
  @xfer_flag    char(1),
  @return_flag  char(1),
  @wo_flag    char(1),
  @wo_qc_flag    char(1),
  @stock_flag    char(1),

  @min_flag char(1),
  @style varchar(40) -- v1.0

--******************************************************************************
--* Construct a date value equal to today with no time incremented
--******************************************************************************
select @this_morning = convert(char(8),getdate(),1) + ' 00:00:00'

--******************************************************************************
--* Obtain the user's selection criteria for which supply sources to include
--*  in the calculation
--******************************************************************************
SELECT  @buyer      = IsNull(buyer, '%'),
  @location    = IsNull(location, '%'),
  @vendor_no    = IsNull(vendor_no, '%'),
  @part_no    = IsNull(part_no, '%'),
  @category    = IsNull(category, '%'),
  @part_type    = IsNull(part_type, '%'),
  @end_date    = time_fence_end_date,
  @po_flag    = supply_po_flag,
  @qc_flag    = supply_qc_flag,
  @xfer_flag    = supply_xfer_flag,
  @return_flag  = supply_return_flag,
  @wo_flag    = supply_wo_flag,
  @wo_qc_flag    = supply_wo_qc_flag,
  @stock_flag    = supply_stock_flag,
  @min_flag = demand_min_flag,
  @org_id = isnull(organization_id,'%'),
  @style = style -- v1.0
FROM  resource_batch (nolock)
WHERE  batch_id = @batch_id


if @org_id != '%' select @location = '%'

--******************************************************************************
--* Set the time fence end date to the last minute of that day
--******************************************************************************
select @end_date = convert(char(8), @end_date, 1) + ' 23:59:59'


--******************************************************************************
--* Get selected inventory items
--******************************************************************************
INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
  location, source, status, commit_ed, source_no, pqty, p_used, type,
  vendor, uom, parent, buyer, prod_no, location2,
  min_stock, max_stock)
SELECT  @batch_id, 0, l.part_no, l.min_stock,
--  case when @min_flag = 'X' then l.max_stock else l.min_stock end,	-- mls 11/29/04 SCR 33703
  convert(char(8),getdate(),1 )+' 00:00:00',     	-- demand date is immediate
  l.location, 'T',              		 	-- set source to 'M' for Minimum
  'T', 0, '0',               				-- source_no is 0 for all minimum entries
  1, 0, l.status, m.vendor, m.uom, '', m.buyer, 0, l.location,
  isnull(l.min_stock,0), isnull(l.max_stock,0)				-- mls 12/10/04 SCR 33703
FROM  inv_list l (nolock)
JOIN  inv_master m (nolock) on m.part_no = l.part_no
JOIN locations loc (nolock) on loc.location = l.location
JOIN  inv_master_add iad (nolock) on m.part_no = iad.part_no -- v1.0
WHERE l.status  <= 'Q' and        			-- exclude non-qty bearing
  (isnull(m.obsolete,0) != 1 and isnull(m.void,'N') != 'V') and			-- mls 3/11/02 SCR 28499
  ((l.location  like @location)) and
  ((l.part_no  like @part_no)) and
  ((m.buyer  like @buyer) or  (m.buyer is NULL and @buyer = '%')) and
  ((m.vendor  like @vendor_no) or (m.vendor is NULL and @vendor_no = '%')) and
  ((m.category  like @category) or (m.category is NULL and @category = '%')) and
  ((m.type_code  like @part_type) or (m.type_code is NULL and @part_type = '%')) and
  ((iad.field_2  like @style) or (iad.field_2 is NULL and @style = '%')) and -- v1.0
  ((loc.organization_id like @org_id)) and
  l.location not like 'DROP%' 

--******************************************************************************
--* Get supply from open purchase orders
--******************************************************************************
if @po_flag = 'Y'
begin
  --**************************************************************************
  --* Inventory items - Set the resource type equal to the inventory status code
  --*  of the item on order: 'P' Purchase, 'M' Make, 'C' Custom Kit, etc.
  --**************************************************************************
  INSERT   #resource_avail(batch_id, part_no, qty, avail_date, commit_ed,
    source, location, source_no, temp_qty, type, status)
  SELECT  @batch_id, r.part_no, ((r.quantity - r.received) * r.conv_factor),
    IsNull(confirm_date, due_date),          		-- it's possible for confirm_date to be null
    0, 'R', r.location, po_no, 0, t.type, 'N'
  FROM   releases r (nolock), #resource_demand t (nolock)          	-- skk 03/20/01 SCR 26115
  WHERE  r.status  > 'N' and          			-- open PO release lines
    r.part_type  = 'P' and          			-- inventory items
    IsNull(r.confirm_date, r.due_date) <= @end_date and    -- items within time fence
    t.part_no = r.part_no and t.location = r.location and t.source = 'T'
end -- if @po_flag = 'Y'


--******************************************************************************
--* Get supply for items already received but in Q/C hold
--******************************************************************************
if @qc_flag = 'Y'
begin
  INSERT   #resource_avail(batch_id, part_no, qty, avail_date, commit_ed,
    source, location, source_no, temp_qty, type, status)
  SELECT @batch_id, r.part_no, (r.quantity * r.conv_factor),
    r.recv_date,              				-- use receive date for avail date
    0, 'Q',                				-- set source to 'Q' for Q/C
    r.location, convert(varchar(10), receipt_no), 0, 'P',    -- resource type is Purchase item
    'N'
  FROM receipts_all r (nolock), #resource_demand t (nolock)        		-- skk 03/20/01 SCR 26115
  WHERE r.qc_flag= 'Y' and          			-- receipts in Q/C
    r.part_type!= 'M' and          			-- don't pick up misc items
    r.recv_date <= @end_date and        		-- items within time fence
    t.part_no = r.part_no and t.location = r.location and t.source = 'T'
end -- if @qc_flag = 'Y'


--******************************************************************************
--* Get supply from transfer orders
--******************************************************************************
if @xfer_flag = 'Y'
begin
  INSERT   #resource_avail (batch_id, part_no, qty, avail_date, commit_ed,
    source, location, source_no, temp_qty, type, status)
  SELECT @batch_id, xl.part_no, (xl.ordered * xl.conv_factor), x.sch_ship_date,
    0,  'X',              				-- set source to 'X' for xfer order
    x.to_loc,              				-- a xfer is supply for the "to" location
    x.xfer_no,              				-- the source number is the xfer order number
    0, t.type, 'N'
  FROM xfers_all x (nolock), xfer_list xl (nolock), #resource_demand t (nolock)    	-- skk 03/20/01 SCR 26115
  WHERE x.xfer_no= xl.xfer_no and
    x.status>= 'N' and         	 			-- open transfer orders
    x.status<= 'R' and          			-- shipped but not yet received at to_loc
    x.sch_ship_date <= @end_date and
    t.part_no = xl.part_no and t.location = xl.to_loc and t.source = 'T'    
end -- if @xfer_flag = 'Y'


--******************************************************************************
--* Get supply from customer credit returns
--******************************************************************************
if @return_flag = 'Y'
begin
  --**************************************************************************
  --* Pick up item supply from credit return lines for all items except Custom Kit 
  --*  parents.  We do a SELECT DISTINCT from the orders tables in case an item
  --* appears on more than one line on an order - we only want to have one record in
  --* #resource_avail.
  --**************************************************************************
  INSERT   #resource_avail (batch_id, part_no, qty, avail_date, commit_ed,
    source, location, source_no, temp_qty, type, status)
  SELECT 
    @batch_id, ol.part_no, SUM(cr_ordered * conv_factor), o.sch_ship_date, 0,
    'C',                					-- set source to 'C' for customer return
    ol.location, convert(varchar(20), o.order_no),        	-- the source number is the credit return number
    0, t.type, 'N'
  FROM  orders_all o (nolock), ord_list ol (nolock), #resource_demand t (nolock)        	-- skk 03/20/01 SCR 26115
  WHERE  o.order_no  = ol.order_no and
    o.ext    = ol.order_ext and
    ol.part_type  != 'C' and          				-- do not pick up Custom Kit parents
    o.status  = 'N' and          				-- only credit orders with status New
    o.type    = 'C' and          				-- don't include invoice orders
    o.sch_ship_date  <= @end_date and        			-- scheduled ship date within the time fence
    ol.cr_ordered  > 0 and
    t.part_no = ol.part_no and t.location = ol.location and t.source = 'T'
  group by ol.part_no, o.sch_ship_date, ol.location, o.order_no, t.type

  --**************************************************************************
  --* When the customer returns a Custom Kit, we get components back so pick up
  --* that supply.  This information comes from ord_list_kit instead of ord_list.
  --**************************************************************************
  INSERT   #resource_avail (batch_id, part_no, qty, avail_date, commit_ed,
    source, location, source_no, temp_qty, type, status)
  SELECT DISTINCT
    @batch_id, olk.part_no, SUM(cr_ordered * conv_factor * qty_per), 
    o.sch_ship_date, 0, 'C',        				-- set source to 'C' for customer return
    olk.location, convert(varchar(20), o.order_no),        	-- the source number is the credit return number
    0, t.type, 'N'
  FROM  orders_all o (nolock), ord_list_kit olk (nolock), #resource_demand t (nolock)      	-- skk 03/20/01 SCR 26115
  WHERE  o.order_no  = olk.order_no and
    o.ext    = olk.order_ext and
    o.status  = 'N' and        -- only credit orders with status New
    o.type    = 'C' and        -- don't include invoice orders
    o.sch_ship_date  <= @end_date and        -- scheduled ship date within the time fence
    (olk.cr_ordered * olk.qty_per) > 0 and
    t.part_no = olk.part_no and t.location = olk.location and t.source = 'T'
  group by olk.part_no, o.sch_ship_date, olk.location, o.order_no, t.type
end -- if @return_flag = 'Y'

--******************************************************************************
--* Get supply from open work orders
--******************************************************************************
if @wo_flag = 'Y'
begin
  INSERT   #resource_avail (batch_id, part_no, qty, avail_date, commit_ed,
    source, location, source_no, temp_qty, type, status)
  SELECT  @batch_id, l.part_no, 
    case when p.prod_type = 'R' then ((l.plan_qty - l.used_qty) * l.conv_factor) -- mls 2/11/05 SCR 34251
      else (l.plan_qty * l.conv_factor) end , 
    p.prod_date,
    0, 'W',                					-- set source to 'W' for work order
    l.location, l.prod_no, 0, t.type, 'N'
  FROM  produce_all p (nolock), #resource_demand t (nolock),		-- mls 3/11/02 SCR 28499
    prod_list l (nolock)
  WHERE  l.prod_no = p.prod_no and l.prod_ext = p.prod_ext and
    l.direction > 0 and
    l.status  between 'N' and 'Q' and  
    p.prod_date  <= @end_date and					-- mls 2/25/03 SCR 30688
    l.part_no = t.part_no and l.location = t.location and t.source = 'T'		-- mls 3/11/02 SCR 28499
end -- if @wo_flag = 'Y'

--******************************************************************************
--* Get supply from completed work orders in Q/C hold
--******************************************************************************
if @wo_qc_flag = 'Y'
begin
  INSERT   #resource_avail (batch_id, part_no, qty, avail_date, commit_ed,
    source, location, source_no, temp_qty, type, status)
  SELECT  @batch_id, l.part_no, (l.used_qty * l.conv_factor),
    p.prod_date, 0, 'W',                			-- set source to 'W' for work order
    l.location, l.prod_no, 0, t.status, 'N'
  FROM  produce_all p (nolock), #resource_demand t (nolock),		-- mls 3/11/02 SCR 28499
    prod_list l (nolock)
  WHERE  l.prod_no = p.prod_no and l.prod_ext = p.prod_ext and
    l.direction > 0 and
    l.status  = 'R' and          				-- Complete: Q/C Hold
--    p.prod_date  <= @end_date and					-- mls 2/25/03 SCR 30688
    l.part_no = t.part_no and l.location = t.location and t.source = 'T'		-- mls 3/11/02 SCR 28499
end -- @wo_qc_flag = 'Y'


--******************************************************************************
--* Get supply from on-hand stock
--******************************************************************************
if @stock_flag = 'Y'
begin
  INSERT   #resource_avail (batch_id, part_no, qty, avail_date, commit_ed,
    source, location, source_no, temp_qty, type, status)
  SELECT  @batch_id, i.part_no, i.in_stock, getdate(), 0, 'I', i.location,
    '0', 0, i.status, 'N'
  FROM  inventory i (nolock), #resource_demand t (nolock)
  WHERE  i.part_no = t.part_no and i.location = t.location and t.source = 'T' and
    i.in_stock   > 0 
end -- if @stock_flag = 'Y'


--******************************************************************************
--* Clear any entries with zero or negative quantities.
--*  Negative on-hand balances will be picked up as demand later.
--******************************************************************************
DELETE  #resource_avail
WHERE qty    <= 0
GO
GRANT EXECUTE ON  [dbo].[fs_sch_avail] TO [public]
GO
