SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



-- Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_compare_schedule_inventory]
	(
	@sched_id	INT,
        @first_call	INT,
	@sched_location varchar(10),
        @apply_changes  INT = 0
	)
AS
BEGIN

DECLARE @err_ind		INT,
	@sched_item_id		INT
SET NOCOUNT ON

select @err_ind = 0

if @first_call = -1
begin
  insert #inventory_detail (location, part_no, status, uom, list_amt, produce_amt, sales_amt, recv_amt, xfer_amt)   
  select distinct il.location, il.part_no, im.status, im.uom,
    il.in_stock + il.issued_mtd,
    ip.produced_mtd - ip.usage_mtd,
    s.sales_qty_mtd,
    r.recv_mtd,
    x.xfer_mtd
  from inv_list il
  join #sched_locations sl on sl.location = il.location
  join inv_master im on im.part_no = il.part_no
  join inv_produce ip on ip.part_no = il.part_no and ip.location = il.location
  join inv_sales s on s.part_no = il.part_no and s.location = il.location
  join inv_recv r on r.part_no = il.part_no and r.location = il.location
  join inv_xfer x on x.part_no = il.part_no and x.location = il.location
  where il.status <= 'Q' and isnull(il.void,'') = 'N'

  update i
  set produce_amt = d.produce_amt
  from #inventory_detail i
  join (select d_part_no, d_location, min(d_produced_mtd - d_usage_mtd)
    from #process_detail where d_produced_mtd is not null
    group by d_part_no, d_location) as d(part_no, location,produce_amt)
  on d.part_no = i.part_no and d.location = i.location

  update i
  set produce_amt = d.produce_amt
  from #inventory_detail i
  join (select h_part_no, h_location, min(h_produced_mtd - h_usage_mtd)
    from #process_detail where h_produced_mtd is not null
    group by h_part_no, h_location) as d(part_no, location,produce_amt)
  on d.part_no = i.part_no and d.location = i.location

  update i
  set sales_amt = od.sales_qty_mtd
  from #inventory_detail i, 
   (select part_no, location, min(sales_qty_mtd) 
    from #order_detail where sales_qty_mtd is not null group by part_no, location) as od(part_no, location, sales_qty_mtd)
  where i.part_no = od.part_no and i.location = od.location

  update i
  set recv_amt = r.recv_amt
  from #inventory_detail i
  join (select part_no, location, min(recv_mtd)
    from #purchase_detail where recv_mtd is not null group by part_no, location) as r(part_no,location,recv_amt)
  on r.part_no = i.part_no and r.location = i.location

  update i
  set recv_amt = r.recv_amt
  from #inventory_detail i
  join (select part_no, location, min(recv_mtd)
    from #replenishment_detail where recv_mtd is not null group by part_no, location) as r(part_no,location,recv_amt)
  on r.part_no = i.part_no and r.location = i.location

  update i
  set xfer_amt = x.xfer_amt
  from #inventory_detail i
  join (select part_no, from_loc, min(from_xfer_mtd)
    from #transfer_detail where from_xfer_mtd is not null group by part_no, from_loc) as x(part_no,location,xfer_amt)
  on x.part_no = i.part_no and x.location = i.location

  update i
  set xfer_amt = x.xfer_amt
  from #inventory_detail i
  join (select part_no, to_loc, min(to_xfer_mtd)
    from #transfer_detail where to_xfer_mtd is not null group by part_no, to_loc) as x(part_no,location,xfer_amt)
  on x.part_no = i.part_no and x.location = i.location
   
return @err_ind
end

-- Check for dropped 'inventory'
if @first_call = 1
begin
  if @apply_changes = 1 
  begin
    DECLARE scheditem CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
    SELECT distinct sched_item_id 
    FROM sched_item SI
    WHERE SI.sched_id = @sched_id AND SI.source_flag = 'I'
    AND	NOT EXISTS (SELECT 1 FROM #inventory_detail I
      WHERE I.location = SI.location AND I.part_no = SI.part_no)

    OPEN scheditem
    FETCH NEXT FROM scheditem into @sched_item_id

    While @@FETCH_STATUS = 0
    begin									-- mls #22 end
      exec adm_set_sched_item 'D',NULL,@sched_item_id
      if @@error <> 0  select @err_ind = @err_ind + 1

      FETCH NEXT FROM scheditem into @sched_item_id
    end
    CLOSE scheditem
    DEALLOCATE scheditem
  end

  if @err_ind != 0 or @apply_changes = 0
  begin
    INSERT #result(object_flag,status_flag,location,sched_item_id,part_no,message)
    SELECT 'I','O',SI.location,SI.sched_item_id,SI.part_no,'Deleted inventory  (' + SI.location + '/' + SI.part_no + ')'
    FROM	sched_item SI
    WHERE	SI.sched_id = @sched_id AND SI.source_flag = 'I'
    AND	NOT EXISTS (	SELECT	1 FROM	#inventory_detail I
	WHERE	I.location = SI.location AND I.part_no = SI.part_no)
  end

-- Check for changed 'inventory' levels
  select @err_ind = 0
  if @apply_changes = 1
  begin
    UPDATE  sched_item
    SET  done_datetime = getdate(),
      uom_qty = (case when I.status = 'C' or I.status = 'V' then 0 else
        I.list_amt + I.produce_amt - I.sales_amt + I.recv_amt + I.xfer_amt end)         
    FROM sched_item SI, #inventory_detail I 
    where I.location = SI.location and I.part_no = SI.part_no AND 
      (case when I.status = 'C' or I.status = 'V' then 0 else
        I.list_amt + I.produce_amt - I.sales_amt + I.recv_amt + I.xfer_amt end) != SI.uom_qty 
      AND SI.sched_id = @sched_id AND SI.source_flag = 'I'
    if @@error <> 0  select @err_ind = @err_ind + 1
  end

  if @apply_changes = 0 or @err_ind != 0
  begin
    INSERT #result(object_flag,status_flag,location,sched_item_id,part_no,message)
    SELECT 'I','C',SI.location,SI.sched_item_id,SI.part_no,'Changed inventory levels (' + SI.location + '/' + SI.part_no + ')'
    FROM sched_item SI, #inventory_detail I 
    where I.location = SI.location and I.part_no = SI.part_no 
      AND (case when I.status = 'C' or I.status = 'V' then 0 else
        I.list_amt + I.produce_amt - I.sales_amt + I.recv_amt + I.xfer_amt end) != SI.uom_qty 
      AND SI.sched_id = @sched_id AND SI.source_flag = 'I'
  end
end -- first_call = 1


-- Check for new 'inventory' appearances
select @err_ind = 0
if @apply_changes = 1
begin
  INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
  SELECT  @sched_id, I.location, I.part_no,  getdate(),  
    (case when I.status = 'C' or I.status = 'V' then 0 else
       I.list_amt + I.produce_amt - I.sales_amt + I.recv_amt + I.xfer_amt end), I.uom, 'I'   
  FROM  #inventory_detail I
  WHERE   I.location = @sched_location
    AND NOT EXISTS (SELECT 1 FROM sched_item SI
      WHERE SI.sched_id = @sched_id AND SI.location = I.location
        AND SI.source_flag = 'I' AND SI.part_no = I.part_no )
   if @@error <> 0  select @err_ind = @err_ind + 1
END

IF @apply_changes = 0 or @err_ind != 0
begin
  INSERT  #result(object_flag,status_flag,location,part_no,message)
  SELECT  'I','N',IL.location,IL.part_no,'New inventory '+IL.location+'/'+IL.part_no
  FROM  #inventory_detail IL 
  WHERE IL.location = @sched_location 
    AND NOT EXISTS (  SELECT  1 FROM  sched_item SI
      WHERE  SI.sched_id = @sched_id AND  SI.location = IL.location
        AND  SI.source_flag = 'I' AND  SI.part_no = IL.part_no )
end

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_compare_schedule_inventory] TO [public]
GO
