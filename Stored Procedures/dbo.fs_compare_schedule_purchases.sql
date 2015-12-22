SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_compare_schedule_purchases]
	(
	@sched_id	INT,
        @first_call	INT,
	@sched_location varchar(10),
        @pur_repl_flag          CHAR(1),
	@purchase_lead_flag CHAR(1),
        @apply_changes  INT = 0
	)
AS
BEGIN

CREATE TABLE #po_result
	(
	status_flag		CHAR(1),
	location		VARCHAR(10)	NULL,
	part_no			VARCHAR(30)	NULL,
	sched_item_id		INT		NULL,
	po_no			VARCHAR(16)	NULL,		-- mls 2/28/03 SCR 30781
	release_id		INT		NULL,
	done_datetime		datetime	NULL,
	qty			decimal(20,8) 	NULL,
	part_type		char(1)		NULL,
	po_line			INT		NULL,
	uom			char(2)		NULL,
	vendor			varchar(12)	NULL,
	lead_time		INT		NULL,
	dock_to_stock		INT		NULL,
	message			VARCHAR(255)
	)

DECLARE @err_ind		INT,
	@po_no			varchar(16),			-- mls 2/28/03 SCR 30781
	@vendor_no		varchar(12),
	@location		varchar(10),
	@done_datetime		datetime,
	@lead_time		INT,
	@part_type		char(1),
	@dock_to_stock		INT,
	@part_no		varchar(30),
	@lead_datetime		datetime,
	@qty			decimal(20,8),
	@sched_item_id		INT,
	@po_line		INT,
	@release_id		INT,
	@uom			char(2),
        @rowcount		INT,
     	@resource_demand_id	INT
        
SET NOCOUNT ON


if @first_call = -1
begin
  select @err_ind = 0

  insert #purchase_detail
  select 'P',p.po_no, p.vendor_no, r.part_no, r.row_id, r.status, r.quantity, r.received, r.release_date,
    r.po_line, r.location, r.confirmed, r.confirm_date, r.due_date, r.conv_factor, r.part_type, 
    IsNull((SELECT SUM(rcpt.quantity) FROM receipts_all rcpt WHERE rcpt.po_no = r.po_no AND rcpt.part_no = r.part_no
      AND rcpt.release_date = r.release_date  AND rcpt.qc_flag = 'Y' 
      and rcpt.po_line = case when isnull(r.po_line,0)=0 then rcpt.po_line else r.po_line end),0.0),
    i.lead_time, i.dock_to_stock, pl.unit_measure, m.uom, ir.recv_mtd
  from purchase_all p
  join releases r on r.po_no = p.po_no AND r.part_type IN ('P','M') AND (r.status = 'O'
    or (r.status = 'C' and exists (select 1 from receipts_all t where t.po_no = r.po_no and t.po_line = r.po_line 
  and t.release_date = r.release_date and t.qc_flag = 'Y')))				-- mls 3/16/04 SCR 32538
											-- mls 8/25/03 SCR 31790
  JOIN #sched_locations SL on SL.location = r.location
  left outer join pur_list pl on pl.po_no = p.po_no and pl.line = r.po_line and pl.part_no = r.part_no
  left outer join inv_list i on i.part_no = r.part_no and i.location = r.location
  left outer join inv_master m on m.part_no = r.part_no
  left outer join inv_recv ir on ir.part_no = r.part_no and ir.location = r.location
  UNION
  SELECT 'R','','',RD.part_no,RD.row_id, '',RD.qty,0,RD.demand_date,
    0,RD.location,'',getdate(),getdate(),1,'',
    0,0,0,'EA',RD.uom, ir.recv_mtd
  FROM	resource_demand_group RD
  JOIN #sched_locations SL on SL.location = RD.location 
  left outer join inv_recv ir on ir.part_no = RD.part_no and ir.location = RD.location
  WHERE	RD.batch_id = 'SCHEDULER'  

  if @@error <> 0  select @err_ind = 1

  create index #pd1 on #purchase_detail(rcd_type)
  create index #pd2 on #purchase_detail(po_no,part_no,row_id)
  create index #pd3 on #purchase_detail(location,po_no)
  create index #pd4 on #purchase_detail(location,part_no,recv_mtd)

  insert #replenishment_detail
  select part_no, row_id, location, release_date, quantity, uom, recv_mtd
  from #purchase_detail
  where rcd_type = 'R'
  if @@error <> 0  select @err_ind = 1

  delete from #purchase_detail where rcd_type = 'R'
  if @@error <> 0  select @err_ind = 1

return @err_ind
end

if @first_call = 1
begin

--
-- Check for purchase order releases that have been completed or deleted
-- ---------------------------------------------------------------------------------------------------------------
  select @err_ind = 0
  INSERT #result(object_flag,status_flag,sched_item_id,message)
  SELECT  'O','O',SI.sched_item_id,'Closed release ('+RTrim(SI.part_no)+') on purchase order #'+SP.po_no
  FROM  sched_item SI 
  JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id
  WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'O'
    AND NOT EXISTS (  SELECT  1 FROM  #purchase_detail PR
      WHERE  PR.part_no = SI.part_no AND  PR.po_no = SP.po_no AND  PR.row_id = SP.release_id
      AND PR.location = SI.location										-- mls 4/5/04 SCR 32607
      AND PR.quantity > (PR.received - PR.receipts_quantity))
  select @rowcount = @@rowcount

  IF @pur_repl_flag = 'Y' 
  BEGIN
    INSERT  #result(object_flag,status_flag,sched_item_id,message)
    SELECT  'O','O',SI.sched_item_id,'Purchase request received ('+RTrim(SI.part_no)+')'
    FROM  sched_purchase SP
    JOIN  sched_item SI on SI.sched_item_id = SP.sched_item_id and SI.source_flag = 'R' and SI.sched_id = @sched_id     
    WHERE  NOT EXISTS (SELECT  1 FROM  #replenishment_detail RD WHERE  RD.row_id = SP.resource_demand_id)
    select @rowcount = @rowcount + @@rowcount
  END

  if @apply_changes = 1 and @rowcount != 0
  begin
    DECLARE schedpurchase CURSOR LOCAL FORWARD_ONLY STATIC FOR		
    SELECT DISTINCT sched_item_id
    FROM #result
    WHERE object_flag = 'O' and status_flag = 'O' 

    OPEN schedpurchase
    FETCH NEXT FROM schedpurchase into @sched_item_id

    While @@FETCH_STATUS = 0
    begin
      exec adm_set_sched_item 'D',NULL,@sched_item_id  
      if @@error <> 0  select @err_ind = @err_ind + 1

      FETCH NEXT FROM schedpurchase into @sched_item_id
    end
    CLOSE schedpurchase
    DEALLOCATE schedpurchase

    delete #result where object_flag = 'O' and status_flag = 'O'
  end

  if @err_ind != 0
  begin
    INSERT #result(object_flag,status_flag,sched_item_id,message)
    SELECT  'O','O',SI.sched_item_id,'Closed release ('+RTrim(SI.part_no)+') on purchase order #'+SP.po_no
    FROM  sched_item SI 
    JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id
    WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'O'
      AND NOT EXISTS (  SELECT  1 FROM  #purchase_detail PR
        WHERE  PR.part_no = SI.part_no AND  PR.po_no = SP.po_no AND  PR.row_id = SP.release_id
        AND PR.location = SI.location										-- mls 4/5/04 SCR 32607
        AND PR.quantity > (PR.received - PR.receipts_quantity))

    IF @pur_repl_flag = 'Y' 
    BEGIN
      INSERT  #result(object_flag,status_flag,sched_item_id,message)
      SELECT  'O','O',SI.sched_item_id,'Purchase request received ('+RTrim(SI.part_no)+')'
      FROM  sched_purchase SP
      JOIN  sched_item SI on SI.sched_item_id = SP.sched_item_id and SI.source_flag = 'R' and SI.sched_id = @sched_id     
      WHERE  NOT EXISTS (SELECT  1 FROM  #replenishment_detail RD WHERE  RD.row_id = SP.resource_demand_id)
    END
  end

--
-- Check for changed releases
-- ---------------------------------------------------------------------------------------------------------------
  select @err_ind = 0
  if @apply_changes = 1
  begin
    INSERT #po_result(status_flag,sched_item_id,po_no,part_no,release_id,location,done_datetime,
      qty, part_type, po_line, uom, vendor, lead_time, dock_to_stock, message)
    SELECT 'C',SI.sched_item_id,PR.po_no,PR.part_no,PR.row_id,
      PR.location, CASE PR.confirmed WHEN 'Y' THEN PR.confirm_date ELSE PR.due_date END,
      ( PR.quantity - CASE WHEN PR.received > PR.quantity THEN PR.quantity ELSE PR.received END
            + PR.receipts_quantity) * PR.conv_factor, PR.part_type, PR.po_line, SI.uom,
      PR.vendor_no,
      case when PR.part_type = 'M' then 0 else isnull(PR.lead_time,0) end,
      case when PR.part_type = 'M' then 0 else isnull(PR.dock_to_stock,0) end,
      'Change on release ('+RTrim(PR.part_no)+') on purchase order #'+PR.po_no
    FROM	sched_item SI
    JOIN	sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.po_no is NOT NULL
    JOIN	#purchase_detail PR on PR.po_no = SP.po_no and PR.part_no = SI.part_no and PR.row_id = SP.release_id 
    WHERE	SI.sched_id = @sched_id AND SI.source_flag = 'O'
    AND ((PR.confirmed = 'N' AND SI.done_datetime != (DateAdd(d, isnull(PR.dock_to_stock,0), PR.due_date)))		-- rev 8
      OR (PR.confirmed = 'Y' AND SI.done_datetime != (DateAdd(d, isnull(PR.dock_to_stock,0), PR.confirm_date)))	-- rev 8
      OR SI.uom_qty != (PR.quantity - CASE WHEN PR.received > PR.quantity THEN PR.quantity ELSE PR.received END
        + PR.receipts_quantity) * PR.conv_factor
      OR SP.vendor_key != PR.vendor_no )

    if @@rowcount != 0
    begin
      DECLARE schedpurchase CURSOR LOCAL FORWARD_ONLY STATIC FOR		
      SELECT DISTINCT sched_item_id, po_no, part_no, release_id, location, done_datetime,
        qty, part_type, po_line, uom, vendor, lead_time, dock_to_stock
      FROM #po_result
      WHERE status_flag = 'C' 

      OPEN schedpurchase
      FETCH NEXT FROM schedpurchase into @sched_item_id, @po_no, @part_no, @release_id,
        @location, @done_datetime, @qty, @part_type, @po_line, @uom, @vendor_no,
        @lead_time, @dock_to_stock

      While @@FETCH_STATUS = 0
      begin
        SELECT @done_datetime = DateAdd (d,(1 * isnull(@dock_to_stock,0)), @done_datetime)
        SELECT @lead_datetime = DateAdd (d,(-1 * isnull(@dock_to_stock,0)),@done_datetime)
        IF @purchase_lead_flag = 'S'
        BEGIN
          -- rev 4:  add dock_to_stock to @done_datetime, 
          --     subtract lead_time and d_to_s to get lead_timedate
          SELECT @lead_datetime = DateAdd (d,(-1 * @lead_time),@done_datetime)
        END              -- #12 end

        UPDATE  sched_item
        SET  done_datetime =  @done_datetime,
          uom_qty =   @qty
        WHERE  sched_item_id = @sched_item_id AND  ((done_datetime <> @done_datetime)OR  (uom_qty <> @qty))
        if @@error <> 0  select @err_ind = @err_ind + 1

        UPDATE  SP
        SET  vendor_key = @vendor_no,
          lead_datetime = @lead_datetime
        FROM  sched_item SI, sched_purchase SP
        WHERE  SI.sched_item_id = @sched_item_id  and  SP.sched_item_id = SI.sched_item_id
          AND  (SP.vendor_key <> @vendor_no or SP.lead_datetime <> @lead_datetime)
        if @@error <> 0  select @err_ind = @err_ind + 1

        FETCH NEXT FROM schedpurchase into @sched_item_id, @po_no, @part_no, @release_id,
          @location, @done_datetime, @qty, @part_type, @po_line, @uom, @vendor_no,
          @lead_time, @dock_to_stock
      end
      CLOSE schedpurchase
      DEALLOCATE schedpurchase

      delete from #po_result where status_flag = 'C'
    end -- rowcount != 0
  end -- @apply_changes = 1

  if @err_ind != 0 or @apply_changes != 1
  begin
    INSERT #result(object_flag,status_flag,sched_item_id,po_no,part_no,release_id,message)
    SELECT 'O','C',SI.sched_item_id,PR.po_no,PR.part_no,PR.row_id,'Change on release ('+RTrim(PR.part_no)+
      ') on purchase order #'+PR.po_no
    FROM sched_item SI
    JOIN sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.po_no is NOT NULL
    JOIN #purchase_detail PR on PR.po_no = SP.po_no and PR.part_no = SI.part_no and PR.row_id = SP.release_id 
    WHERE SI.sched_id = @sched_id AND SI.source_flag = 'O'
    AND ((PR.confirmed = 'N' AND SI.done_datetime != (DateAdd(d, isnull(PR.dock_to_stock,0), PR.due_date)))		-- rev 8
      OR (PR.confirmed = 'Y' AND SI.done_datetime != (DateAdd(d, isnull(PR.dock_to_stock,0), PR.confirm_date)))	-- rev 8
      OR SI.uom_qty != (PR.quantity - CASE WHEN PR.received > PR.quantity THEN PR.quantity ELSE PR.received END
        + PR.receipts_quantity) * PR.conv_factor
      OR SP.vendor_key != PR.vendor_no )
  end
end -- first call

--
-- Check for new purchases
-- ---------------------------------------------------------------------------------------------------------------
select @err_ind = 0

INSERT	#result(object_flag,status_flag,po_no,message,location)
SELECT	DISTINCT 'O','N',PR.po_no,'New purchase order #'+PR.po_no, @sched_location
FROM	#purchase_detail PR 
WHERE	PR.location = @sched_location and PR.quantity > (PR.received - PR.receipts_quantity)
AND	NOT EXISTS (	SELECT	1
			FROM	sched_item SI 
			JOIN	sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.po_no = PR.po_no
			WHERE	SI.sched_id = @sched_id
			AND	SI.source_flag = 'O')

if @apply_changes = 1 and @@rowcount != 0
begin
  DECLARE schedpurchase CURSOR LOCAL FORWARD_ONLY STATIC FOR		
  SELECT DISTINCT po_no
  FROM	#result
  WHERE	location = @sched_location AND object_flag = 'O' and status_flag = 'N'

  OPEN schedpurchase
  FETCH NEXT FROM schedpurchase into @po_no

  While @@FETCH_STATUS = 0
  begin
    DECLARE schedrel CURSOR LOCAL FOR          							-- mls 1/28/03 SCR 30579
    SELECT  PR.location, PR.part_no, CASE PR.confirmed WHEN 'Y' THEN PR.confirm_date ELSE PR.due_date END,
      ( PR.quantity - CASE  WHEN PR.received > PR.quantity THEN PR.quantity ELSE PR.received END
        + PR.receipts_quantity) * PR.conv_factor,
      PR.part_type, PR.po_line,          -- mls 5/15/01 SCR 6603
      case when PR.part_type = 'M' then PR.unit_measure else PR.uom end, PR.row_id,
      case when PR.part_type = 'M' then 0 else PR.lead_time end, 
      case when PR.part_type = 'M' then 0 else PR.dock_to_stock end,
      vendor_no
    FROM  #purchase_detail PR
    WHERE PR.location = @sched_location and PR.po_no = @po_no and PR.quantity > (PR.received - PR.receipts_quantity)

    OPEN schedrel
    FETCH NEXT FROM schedrel into @location, @part_no, @done_datetime, @qty, @part_type, @po_line, @uom, @release_id,
      @lead_time, @dock_to_stock, @vendor_no

    While @@FETCH_STATUS = 0
    begin                  
      -- Compute the lead_datetime to so that when confirmed receipt dates change,
      -- we will have a way to know that something changed.
      SELECT @lead_datetime = @done_datetime

      if @part_type != 'M'
        SELECT @lead_datetime = NULL
      SELECT @done_datetime = DateAdd (d,(1 * isnull(@dock_to_stock,0)), @done_datetime)
      SELECT @lead_datetime = DateAdd (d,(-1 * isnull(@dock_to_stock,0)),@done_datetime)
      IF @purchase_lead_flag = 'S'
      BEGIN
          select @lead_time = IsNull(@lead_time, 0)
        -- rev 4:  add dock_to_stock to @done_datetime, 
        --     subtract lead_time and d_to_s to get lead_timedate
        SELECT @lead_datetime = DateAdd (d,(-1 * @lead_time),@done_datetime)
      END              -- #12 end
      
      INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
      VALUES(@sched_id,@location,@part_no,@done_datetime,@qty,IsNull(@uom,''),'O')
      SELECT  @sched_item_id=@@identity, @err_ind = @err_ind + case when @@error <> 0 then 1 else 0 end

      
      INSERT  sched_purchase(sched_item_id,lead_datetime,vendor_key,po_no,release_id)  
      VALUES(@sched_item_id,@lead_datetime,@vendor_no,@po_no,@release_id)
      if @@error <> 0  select @err_ind = @err_ind + 1

      
      FETCH NEXT FROM schedrel into @location, @part_no, @done_datetime, @qty, @part_type, @po_line, @uom, @release_id,
        @lead_time, @dock_to_stock, @vendor_no
    END -- fetch status = 0

    CLOSE schedrel
    deallocate schedrel									-- mls 1/28/03 SCR 30579

    FETCH NEXT FROM schedpurchase into @po_no
  END

  CLOSE schedpurchase

  DEALLOCATE schedpurchase

  delete from #result where location = @sched_location and object_flag = 'O' and status_flag = 'N'
end

if @err_ind != 0
begin
  INSERT #result(object_flag,status_flag,po_no,message,location)
  SELECT DISTINCT 'O','N',PR.po_no,'New purchase order #'+PR.po_no, @sched_location
  FROM	#purchase_detail PR 
  WHERE	PR.location = @sched_location and PR.quantity > (PR.received - PR.receipts_quantity)
  AND	NOT EXISTS (	SELECT	1
			FROM	sched_item SI 
			JOIN	sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.po_no = PR.po_no
			WHERE	SI.sched_id = @sched_id
			AND	SI.source_flag = 'O')
end

--
-- Check for new releases
-- ---------------------------------------------------------------------------------------------------------------
select @err_ind = 0
INSERT	#result(object_flag,status_flag,po_no,part_no,release_id,message, location)
SELECT	'O','A',PR.po_no,PR.part_no,PR.row_id,'New release ('+RTrim(PR.part_no)+') on purchase order #'+PR.po_no, @sched_location
FROM	#purchase_detail PR 
WHERE PR.location = @sched_location AND PR.quantity > (PR.received - PR.receipts_quantity)
AND NOT EXISTS (SELECT 1 FROM sched_item SI
  JOIN sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.release_id = PR.row_id and SP.po_no = PR.po_no
  WHERE	SI.sched_id = @sched_id AND SI.source_flag = 'O' AND SI.part_no = PR.part_no
      AND PR.location = SI.location)										-- mls 4/5/04 SCR 32607
AND NOT EXISTS (SELECT 1 FROM	#result R WHERE	R.po_no = PR.po_no and R.object_flag = 'O' and R.status_flag = 'N')

if @apply_changes = 1 and @@rowcount != 0
begin
  DECLARE schedpurchase CURSOR LOCAL FORWARD_ONLY STATIC FOR		
  SELECT DISTINCT po_no, part_no, release_id
  FROM	#result
  WHERE	location = @sched_location AND object_flag = 'O' and status_flag = 'A'

  OPEN schedpurchase
  FETCH NEXT FROM schedpurchase into @po_no, @part_no, @release_id

  While @@FETCH_STATUS = 0
  begin
    SELECT @done_datetime = CASE PR.confirmed WHEN 'Y' THEN PR.confirm_date ELSE PR.due_date END,
      @qty = ( PR.quantity - CASE  WHEN PR.received > PR.quantity THEN PR.quantity ELSE PR.received END
        + PR.receipts_quantity) * PR.conv_factor,
      @part_type = PR.part_type, @po_line = PR.po_line,        -- mls 5/15/01 SCR 6603
      @uom = case when PR.part_type = 'M' then PR.unit_measure else PR.uom end,
      @lead_time = case when @part_type = 'M' then 0 else PR.lead_time end,
      @dock_to_stock = case when @part_type = 'M' then 0 else PR.dock_to_stock end,
      @vendor_no = PR.vendor_no
    FROM  #purchase_detail PR
    WHERE  PR.po_no = @po_no and PR.part_no = @part_no AND PR.row_id = @release_id
    AND  PR.quantity > (PR.received - PR.receipts_quantity)
    select @rowcount = @@rowcount, @err_ind = @err_ind + case when @@error <> 0 then 1 else 0 end

    if @rowcount <> 0
    begin
      SELECT @lead_datetime = @done_datetime
      if @part_type != 'M'
        SELECT @lead_datetime = NULL
      SELECT @done_datetime = DateAdd (d,(1 * isnull(@dock_to_stock,0)), @done_datetime)
      SELECT @lead_datetime = DateAdd (d,(-1 * isnull(@dock_to_stock,0)),@done_datetime)
      IF @purchase_lead_flag = 'S'
      BEGIN
        select @lead_time = IsNull(@lead_time, 0)
        -- rev 4:  add dock_to_stock to @done_datetime, 
        --     subtract lead_time and d_to_s to get lead_timedate
        SELECT @lead_datetime = DateAdd (d,(-1 * @lead_time),@done_datetime)
      END              -- #12 end
      INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
      VALUES(@sched_id,@sched_location,@part_no,@done_datetime,@qty,IsNull(@uom,''),'O')

      SELECT  @rowcount=@@rowcount,
        @sched_item_id=@@identity, @err_ind = @err_ind + case @@error when 0 then 0 else 1 end
      
      IF @rowcount > 0    
      begin
        INSERT  sched_purchase(sched_item_id,vendor_key,po_no,release_id,lead_datetime)
        SELECT  @sched_item_id, @vendor_no, @po_no, @release_id, @lead_datetime
        if @@error <> 0  select @err_ind = @err_ind + 1
      end -- @@rowcount > 0
    end -- @@rowcount <> 0
    FETCH NEXT FROM schedpurchase into @po_no, @part_no, @release_id
  end
  CLOSE schedpurchase
  DEALLOCATE schedpurchase

  delete from #result where location = @sched_location and object_flag = 'O' and status_flag = 'A'
end

if @err_ind != 0
begin
  INSERT #result(object_flag,status_flag,po_no,part_no,release_id,message, location)
  SELECT 'O','A',PR.po_no,PR.part_no,PR.row_id,'New release ('+RTrim(PR.part_no)+') on purchase order #'+PR.po_no, @sched_location
  FROM	#purchase_detail PR 
  WHERE PR.location = @sched_location AND PR.quantity > (PR.received - PR.receipts_quantity)
  AND NOT EXISTS (SELECT 1 FROM sched_item SI
    JOIN sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.release_id = PR.row_id and SP.po_no = PR.po_no
    WHERE SI.sched_id = @sched_id AND SI.source_flag = 'O' AND SI.part_no = PR.part_no
      AND PR.location = SI.location)										-- mls 4/5/04 SCR 32607
  AND NOT EXISTS (SELECT 1 FROM	#result R WHERE	R.po_no = PR.po_no )
end

--
-- Check for release in inventory replenishment
-- ---------------------------------------------------------------------------------------------------------------
select @err_ind = 0
INSERT	#result(object_flag,status_flag,resource_demand_id,message,location)
SELECT	'O','R',RD.row_id,'Release in Inv Replenishment found for ('+RTrim(RD.part_no)+')', RD.location
FROM	#replenishment_detail RD
WHERE	RD.location = @sched_location
  AND NOT EXISTS (SELECT 1 FROM	sched_purchase SP
    JOIN sched_item SI on SI.sched_item_id = SP.sched_item_id and SI.source_flag = 'R' and SI.sched_id = @sched_id
    WHERE SP.resource_demand_id = RD.row_id)

if @apply_changes = 1 and @@rowcount != 0
begin
  DECLARE schedpurchase CURSOR LOCAL FORWARD_ONLY STATIC FOR		
  SELECT DISTINCT resource_demand_id
  FROM #result
  WHERE location = @sched_location and object_flag = 'O' and status_flag = 'R' 

  OPEN schedpurchase
  FETCH NEXT FROM schedpurchase into @resource_demand_id

  While @@FETCH_STATUS = 0
  begin
    INSERT sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
    SELECT @sched_id, RD.location, RD.part_no, RD.demand_date, RD.qty, RD.uom, 'R'
    FROM #replenishment_detail RD							-- mls 1/22/03 SCR 30559
    WHERE RD.row_id = @resource_demand_id 
    SELECT @sched_item_id=@@identity, @err_ind = @err_ind + case @@error when 0 then 0 else 1 end
					
    INSERT sched_purchase(sched_item_id,resource_demand_id)
    VALUES (@sched_item_id,@resource_demand_id)
    if @@error <> 0  select @err_ind = @err_ind + 1

    FETCH NEXT FROM schedpurchase into @resource_demand_id
  end
  CLOSE schedpurchase
  DEALLOCATE schedpurchase

  delete #result where location = @sched_location and object_flag = 'O' and status_flag = 'R'
end

if @err_ind != 0
begin
  INSERT #result(object_flag,status_flag,resource_demand_id,message,location)
  SELECT 'O','R',RD.row_id,'Release in Inv Replenishment found for ('+RTrim(RD.part_no)+')', RD.location
  FROM	#replenishment_detail RD
  WHERE	RD.location = @sched_location
  AND NOT EXISTS (SELECT 1 FROM	sched_purchase SP
    JOIN sched_item SI on SI.sched_item_id = SP.sched_item_id and SI.source_flag = 'R' and SI.sched_id = @sched_id
    WHERE SP.resource_demand_id = RD.row_id)
end

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_compare_schedule_purchases] TO [public]
GO
