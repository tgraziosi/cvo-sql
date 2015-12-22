SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_compare_schedule_xfers]
  (
  	@sched_id 	INT,
        @first_call  	INT,
  	@sched_location 	varchar(10),
  	@xfer_demand_mode  	char(1),    -- mls 4/26/02 SCR 28832
  	@xfer_supply_mode  	char(1),      -- mls 4/26/02 SCR 28832
  	@order_priority_id  	INT,
        @apply_changes  INT = 0
  )
AS
BEGIN

DECLARE @err_ind    INT,
	@transfer_id INT,
 	@beg_location varchar(10),
 	@end_location varchar(10),
	@beg_datetime datetime,
	@end_datetime datetime,
	@part_no varchar(30),
	@qty decimal(20,8),
	@uom char(2),
	@transfer_line int,
	@sched_item_id int,
	@status_flag char(1),
	@rowcount INT,
	@xfer_line INT,
	@sched_order_id INT,
	@sched_transfer_id INT
	

SET NOCOUNT ON

if @first_call = -1
begin
  select @err_ind = 0

  insert #transfer_detail
  select distinct x.xfer_no, 
    case when x.status between 'N' and 'Q' then x.from_loc else '' end, 
    case when x.status between 'N' and 'R' then x.to_loc else '' end, x.sch_ship_date, x.req_ship_date,
    l.line_no, l.part_no, 
    case when x.status between 'N' and 'Q' then l.ordered else l.shipped end, l.uom, f.xfer_mtd, t.xfer_mtd
  from xfers_all x
  join xfer_list l on l.xfer_no = x.xfer_no
  join #sched_locations sl on 
    ((sl.location = x.from_loc and x.status between 'N' and 'Q') or 
     (sl.location = x.to_loc and x.status between 'N' and 'R'))
  left outer join inv_xfer f on f.part_no = l.part_no and f.location = x.from_loc
  left outer join inv_xfer t on t.part_no = l.part_no and t.location = x.to_loc
  where x.status between 'N' and 'R'

  if @@error <> 0  select @err_ind = @err_ind + 1

  return @err_ind
end

if @first_call = 1
begin
  select @err_ind = 0, @rowcount = 0
  -- Check for changes to transfer orders
  if @xfer_demand_mode = 'U'              -- mls 4/26/02 SCR 28832
  begin
    INSERT  #result(object_flag,status_flag,xfer_no,xfer_line,sched_order_id,message)
    SELECT  'X','1',XL.xfer_no,XL.line_no,SO.sched_order_id,'Transfer order changed (#'+CONVERT(VARCHAR(12),XL.xfer_no)+', '
      +CONVERT(VARCHAR(12),XL.line_no)+') '
    FROM  sched_order SO
    JOIN  #transfer_detail XL on XL.xfer_no = SO.order_no and XL.line_no = SO.order_line
    WHERE  SO.sched_id = @sched_id AND  SO.source_flag = 'T' 
      AND  (  SO.done_datetime <> XL.sch_ship_date OR  SO.location <> XL.from_loc OR  SO.part_no <> XL.part_no
      OR  SO.uom_qty <> XL.ordered OR  SO.uom <> XL.uom)
    select @rowcount = @@rowcount
  end
  -- Check for changes to transfer purchases
  if @xfer_supply_mode = 'U'              -- mls 4/26/02 SCR 28832
  begin
    INSERT  #result(object_flag,status_flag,xfer_no,xfer_line,sched_item_id,message)
    SELECT  'X','1',XL.xfer_no,XL.line_no,SI.sched_item_id,'Transfer purchase changed (#'+CONVERT(VARCHAR(12),XL.xfer_no)+', '+CONVERT(VARCHAR(12),XL.line_no)+') '
    FROM  sched_item SI
    JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id
    JOIN  #transfer_detail XL on XL.xfer_no = SP.xfer_no and XL.line_no = SP.xfer_line
    WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'T'
      AND  (  SI.done_datetime <> XL.req_ship_date OR  SI.location <> XL.to_loc OR  SI.part_no <> XL.part_no
      OR  SI.uom_qty <> XL.ordered OR  SI.uom <> XL.uom)
    select @rowcount = @rowcount + @@rowcount
  end

  -- Check for changes to internal transfers
  if @xfer_demand_mode = 'U' and @xfer_supply_mode = 'U'        -- mls 4/26/02 SCR 28832
  begin
    INSERT  #result(object_flag,status_flag,xfer_no,xfer_line,sched_transfer_id,message)
    SELECT  distinct 'X','0',XL.xfer_no,XL.line_no,ST.sched_transfer_id,'Transfer changed (#'+CONVERT(VARCHAR(12),XL.xfer_no)+', '+CONVERT(VARCHAR(12),XL.line_no)+') '
    FROM  sched_item SI
    JOIN  sched_transfer ST on ST.sched_transfer_id = SI.sched_transfer_id AND ST.sched_id = @sched_id
    JOIN  #transfer_detail XL on XL.xfer_no = ST.xfer_no and XL.line_no = ST.xfer_line
    WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'X' 
      AND  (  SI.done_datetime <> XL.req_ship_date OR  ST.move_datetime <> XL.sch_ship_date
      OR  SI.location <> XL.to_loc OR  ST.location <> XL.from_loc  OR  SI.part_no <> XL.part_no
      OR  SI.uom_qty <> XL.ordered OR  SI.uom <> XL.uom)

    INSERT  #result(object_flag,status_flag,xfer_no,xfer_line,sched_item_id,message)
    SELECT  'X','1',XL.xfer_no,XL.xfer_line,SI.sched_item_id,'Transfer purchase changed (#'+CONVERT(VARCHAR(12),XL.xfer_no)+', '+CONVERT(VARCHAR(12),XL.xfer_line)+') '
    FROM  sched_item SI
    JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id
    JOIN  #result XL on XL.xfer_no = SP.xfer_no and XL.xfer_line = SP.xfer_line and XL.object_flag = 'X' and XL.status_flag = '0'
    WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'T'
    select @rowcount = @rowcount + @@rowcount

    INSERT  #result(object_flag,status_flag,xfer_no,xfer_line,sched_order_id,message)
    SELECT  'X','1',XL.xfer_no,XL.xfer_line,SO.sched_order_id,'Transfer order changed (#'+CONVERT(VARCHAR(12),XL.xfer_no)+', '
      +CONVERT(VARCHAR(12),XL.xfer_line)+') '
    FROM  sched_order SO
    JOIN  #result XL on XL.xfer_no = SO.order_no and XL.xfer_line = SO.order_line and XL.object_flag = 'X' and XL.status_flag = '0'
    WHERE  SO.sched_id = @sched_id AND  SO.source_flag = 'T' 
  end

  insert #result(object_flag,status_flag,xfer_no,xfer_line,sched_transfer_id,message,sched_order_id, sched_item_id)
  SELECT  'X','C',xfer_no,xfer_line,max(isnull(sched_transfer_id,0)),
    min (message),
    max(isnull(sched_order_id,0)), max(isnull(sched_item_id,0))
    FROM #result
    where object_flag = 'X' and status_flag in ('0','1')
    group by xfer_no, xfer_line

  delete from #result
  where object_flag = 'X' and status_flag in ('0','1')
  
  -- Look for transfer orders which are no longer valid
  INSERT  #result(object_flag,status_flag,xfer_no, xfer_line,sched_order_id,message)
  SELECT  'X','1',SO.order_no, SO.order_line, SO.sched_order_id,
    case when @xfer_demand_mode = 'I' then 'Remove Transfer order (#' else 'Transfer order closed (#' end
    +CONVERT(VARCHAR(12),SO.order_no)+', '+CONVERT(VARCHAR(12),SO.order_line)+') '
  FROM  sched_order SO
  WHERE  SO.sched_id = @sched_id AND  SO.source_flag = 'T'  AND  (@xfer_demand_mode = 'I' or      
    NOT EXISTS (  SELECT  1 FROM #transfer_detail XL
    WHERE  XL.xfer_no = SO.order_no AND  XL.line_no = SO.order_line))
  select @rowcount = @rowcount + @@rowcount

  -- Look for transfer purchases which are no longer valid
  INSERT  #result(object_flag,status_flag,xfer_no, xfer_line,sched_item_id,message)
  SELECT  'X','1',SP.xfer_no, SP.xfer_line,SI.sched_item_id,
    case when @xfer_demand_mode = 'I' then 'Remove Transfer purchase (#' else 'Transfer purchase closed (#' end
    +CONVERT(VARCHAR(12),SP.xfer_no)+', '+CONVERT(VARCHAR(12),SP.xfer_line)+') '
  FROM  sched_item SI 
  JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id
  WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'T' AND  (@xfer_supply_mode = 'I' or 
    NOT EXISTS (  SELECT  1 FROM  #transfer_detail XL
    WHERE  XL.xfer_no = SP.xfer_no AND  XL.line_no = SP.xfer_line))
  select @rowcount = @rowcount + @@rowcount

  -- Look for internal transfers which are no longer valid
  INSERT  #result(object_flag,status_flag,xfer_no, xfer_line,sched_transfer_id,message)
  SELECT  'X','1',ST.xfer_no, ST.xfer_line, ST.sched_transfer_id,
    case when (@xfer_demand_mode = 'I' or @xfer_supply_mode = 'I')
    then 'Remove Transfer (#' else 'Transfer closed (#' end
    +CONVERT(VARCHAR(12),ST.xfer_no)+', '+CONVERT(VARCHAR(12),ST.xfer_line)+') '
  FROM  sched_item SI
  JOIN  sched_transfer ST on ST.sched_transfer_id = SI.sched_transfer_id and ST.sched_id = @sched_id
  WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'X' AND  (@xfer_demand_mode = 'I' or @xfer_supply_mode = 'I' or
    NOT EXISTS (  SELECT  1 FROM  #transfer_detail XL
    WHERE  XL.xfer_no = ST.xfer_no and XL.line_no = ST.xfer_line))
  select @rowcount = @rowcount + @@rowcount

  insert #result(object_flag,status_flag,sched_transfer_id,message,sched_order_id, sched_item_id)
  select 'X','O',max(isnull(sched_transfer_id,0)),min(message),
  max(isnull(sched_order_id,0)), 
  max(isnull(sched_item_id,0))
  from #result
  where object_flag = 'X' and status_flag = '1'
  group by xfer_no, xfer_line

  delete from #result
  where object_flag = 'X' and status_flag = '1'

  if @apply_changes = 1 and @rowcount != 0
  begin

    DECLARE schedtransfer CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
    SELECT distinct status_flag, xfer_no, xfer_line, sched_order_id, sched_item_id, sched_transfer_id
    from #result where object_flag = 'X' and status_flag in ('O','C')

    OPEN schedtransfer
    FETCH NEXT FROM schedtransfer into @status_flag, @transfer_id, @transfer_line, 
      @sched_order_id, @sched_item_id, @sched_transfer_id

    While @@FETCH_STATUS = 0
    begin									-- mls #22 end
      
      IF @sched_order_id != 0
      begin
        exec adm_set_sched_order 'DT',NULL,@sched_order_id  
        if @@error <> 0  select @err_ind = @err_ind + 1
      end
      
      IF @sched_item_id != 0
      begin
        exec adm_set_sched_item 'DT',NULL,@sched_item_id
        if @@error <> 0  select @err_ind = @err_ind + 1
      end
      
      IF @sched_transfer_id != 0
      begin
        exec adm_set_sched_item 'DU',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@sched_transfer_id
        if @@error <> 0  select @err_ind = @err_ind + 1
        if (@@version like '%7.0%')
        begin
          DELETE sched_transfer_item where sched_transfer_id = @sched_transfer_id
          if @@error <> 0  select @err_ind = @err_ind + 1
        end
        DELETE sched_transfer WHERE sched_transfer_id = @sched_transfer_id
        if @@error <> 0  select @err_ind = @err_ind + 1
      end

      if @status_flag = 'C'
      begin
        select @beg_location = from_loc, @end_location = to_loc, @beg_datetime = sch_ship_date,
          @end_datetime = req_ship_date, @part_no = part_no, @qty = ordered, @uom = uom
        from #transfer_detail
        where xfer_no = @transfer_id and line_no = @transfer_line

        
        IF EXISTS(SELECT 1 FROM #sched_locations SL WHERE SL.location = @beg_location)
        BEGIN -- BEGIN 13
          
          
          IF EXISTS(SELECT 1 FROM #sched_locations SL WHERE SL.location = @end_location)
          BEGIN -- BEGIN 14
            
            INSERT  sched_transfer(sched_id,location,move_datetime,source_flag,xfer_no,xfer_line)
            VALUES  (@sched_id,@beg_location,@beg_datetime,'R',@transfer_id,@transfer_line)
  
            
            SELECT  @sched_transfer_id=@@identity, @err_ind = @err_ind + case @@error when 0 then 0 else 1 end
  
            
            INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_transfer_id)
            VALUES  (@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'X',@sched_transfer_id)
            if @@error <> 0  select @err_ind = @err_ind + 1

            INSERT  sched_order (sched_id, location, done_datetime, part_no, uom_qty, uom, 
              order_priority_id, source_flag, order_no, order_line)
            VALUES  ( @sched_id,  @beg_location, @beg_datetime, @part_no, @qty, @uom,
              @order_priority_id,  'T', @transfer_id, @transfer_line)
            if @@error <> 0  select @err_ind = @err_ind + 1

            INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
            VALUES  (@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'T')
  
            SELECT  @sched_item_id=@@identity, @err_ind = @err_ind + case @@error when 0 then 0 else 1 end
  
            INSERT  sched_purchase(sched_item_id,xfer_no,xfer_line)
            VALUES(@sched_item_id,@transfer_id,@transfer_line)
            if @@error <> 0  select @err_ind = @err_ind + 1
          END -- END 14
          ELSE
          BEGIN -- BEGIN 15
            
            
            INSERT  sched_order (sched_id, location, done_datetime, part_no, uom_qty, uom, 
              order_priority_id, source_flag, order_no, order_line)
            VALUES  ( @sched_id,  @beg_location, @beg_datetime, @part_no, @qty, @uom,
              @order_priority_id,  'T', @transfer_id, @transfer_line)
            if @@error <> 0  select @err_ind = @err_ind + 1
          END -- END 15
        END -- END 13
        ELSE
        BEGIN -- BEGIN 16
          
          
          IF EXISTS(SELECT 1 FROM #sched_locations SL WHERE SL.location = @end_location)
          BEGIN -- BEGIN 17
            
            
            INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
            VALUES  (@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'T')
  
            
            SELECT  @sched_item_id=@@identity, @err_ind = @err_ind + case @@error when 0 then 0 else 1 end
  
            
            INSERT  sched_purchase(sched_item_id,xfer_no,xfer_line)
            VALUES(@sched_item_id,@transfer_id,@transfer_line)
            if @@error <> 0  select @err_ind = @err_ind + 1
          END -- END 17
        END -- END 16
      END -- END 10

      FETCH NEXT FROM schedtransfer into @status_flag, @transfer_id, @transfer_line, 
        @sched_order_id, @sched_item_id, @sched_transfer_id
    end

    CLOSE schedtransfer
    DEALLOCATE schedtransfer

    if @err_ind = 0
      delete #result where object_flag = 'X' and status_flag in ('O','C')
  end
END -- first_call = 1

-- Check for new 'xfers'
if (@xfer_supply_mode = 'U' or @xfer_demand_mode = 'U')
begin
  select @err_ind = 0
  INSERT  #result(object_flag,status_flag,xfer_no,message, location)
  SELECT  distinct 'X','N',X.xfer_no,'New transfer (#'+CONVERT(VARCHAR(12),X.xfer_no)+')', @sched_location
  FROM  #transfer_detail X
  WHERE ((X.to_loc = @sched_location and @xfer_supply_mode = 'U')    -- mls 4/26/02 SCR 28832
    OR  (X.from_loc = @sched_location and @xfer_demand_mode = 'U'))    -- mls 4/26/02 SCR 28832
  AND  NOT EXISTS (  SELECT  1 FROM  sched_transfer ST WHERE  ST.sched_id = @sched_id
  AND  ST.source_flag = 'R' AND  ST.xfer_no = X.xfer_no)
  AND  NOT EXISTS (  SELECT  1 FROM  sched_item SI
    JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.xfer_no = X.xfer_no
    WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'T')
  AND  NOT EXISTS (  SELECT  1
    FROM  sched_order SO WHERE  SO.sched_id = @sched_id AND  SO.source_flag = 'T' AND  SO.order_no = X.xfer_no )





  and not exists ( select 1
    from #result r where r.object_flag = 'X' and r.status_flag = 'N' and r.xfer_no = X.xfer_no)
  select @rowcount = @@rowcount

  -- Check for new 'xfer_list'
  INSERT  #result(object_flag,status_flag,xfer_no,xfer_line,message, location)
  SELECT  'X','A',XL.xfer_no,XL.line_no,'New line item on transfer (#'+CONVERT(VARCHAR(12),XL.xfer_no)+','+CONVERT(VARCHAR(12),XL.line_no)+')',
    @sched_location
  FROM  #transfer_detail XL 
  WHERE  ((XL.to_loc = @sched_location and @xfer_supply_mode = 'U')    -- mls 4/26/02 SCR 28832
    OR  (XL.from_loc = @sched_location and @xfer_demand_mode = 'U'))    -- mls 4/26/02 SCR 28832 
    AND  NOT EXISTS (  SELECT  1 FROM  sched_transfer ST
      WHERE  ST.sched_id = @sched_id AND  ST.source_flag = 'R' AND  ST.xfer_no = XL.xfer_no AND  ST.xfer_line = XL.line_no)
    AND  NOT EXISTS (  SELECT  1 FROM  sched_item SI
      JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.xfer_no = XL.xfer_no and SP.xfer_line = XL.line_no
      WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'T')
    AND  NOT EXISTS (  SELECT  1 FROM  sched_order SO
      WHERE  SO.sched_id = @sched_id AND  SO.source_flag = 'T' AND  SO.order_no = XL.xfer_no AND  SO.order_line = XL.line_no)
    AND  NOT EXISTS (  SELECT  1 FROM  #result R WHERE  R.xfer_no = XL.xfer_no and object_flag = 'X' and status_flag = 'N')





    and not exists ( select 1
      from #result r where r.object_flag = 'X' and r.status_flag = 'A' and r.xfer_no = XL.xfer_no and r.xfer_line = XL.line_no)
  select @rowcount = @rowcount + @@rowcount

  if @apply_changes = 1 and @rowcount != 0
  begin
    DECLARE schedtransfer CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
    SELECT distinct r.status_flag, r.xfer_no, r.xfer_line, x.from_loc, x.to_loc, x.sch_ship_date, x.req_ship_date
    from #result r
    join #transfer_detail x on x.xfer_no = r.xfer_no and isnull(r.xfer_line,x.line_no) = x.line_no
    where r.object_flag = 'X' and r.location = @sched_location and r.status_flag in ('A','N')

    OPEN schedtransfer
    FETCH NEXT FROM schedtransfer into @status_flag, @transfer_id, @transfer_line, 
      @beg_location, @end_location, @beg_datetime, @end_datetime

    While @@FETCH_STATUS = 0
    begin									-- mls #22 end

    DECLARE c_purchase CURSOR LOCAL FORWARD_ONLY STATIC FOR
    SELECT  XL.part_no, XL.ordered, XL.uom, XL.line_no
    FROM  #transfer_detail XL
    WHERE  XL.xfer_no = @transfer_id and isnull(@transfer_line,line_no) = line_no

      
      IF EXISTS(SELECT 1 FROM sched_location SL WHERE SL.sched_id = @sched_id AND SL.location = @beg_location)
      BEGIN -- BEGIN 3
        
        
        IF EXISTS(SELECT 1 FROM sched_location SL WHERE SL.sched_id = @sched_id AND SL.location = @end_location)
        BEGIN -- BEGIN 4
          
          INSERT  sched_transfer(sched_id,location,move_datetime,source_flag,xfer_no,xfer_line)
          SELECT  @sched_id,@beg_location,@beg_datetime,'R',@transfer_id,XL.line_no
          FROM  #transfer_detail XL
          WHERE  XL.xfer_no = @transfer_id and isnull(@transfer_line,line_no) = line_no
          if @@error <> 0  select @err_ind = @err_ind + 1

          

          INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_transfer_id)
          SELECT  @sched_id,@end_location,XL.part_no,@end_datetime,XL.ordered,XL.uom,'X',ST.sched_transfer_id
          FROM  sched_transfer ST
          JOIN  #transfer_detail XL on XL.xfer_no = ST.xfer_no and XL.line_no = ST.xfer_line
          WHERE  ST.sched_id = @sched_id AND ST.xfer_no = @transfer_id
            and isnull(@transfer_line,ST.xfer_line) = ST.xfer_line
          if @@error <> 0  select @err_ind = @err_ind + 1

          INSERT  sched_order (sched_id, location, done_datetime, part_no, uom_qty, uom, 
            order_priority_id, source_flag, order_no, order_line)
          SELECT  @sched_id, @beg_location, @beg_datetime,  XL.part_no, XL.ordered, 
            XL.uom, @order_priority_id,  'T', XL.xfer_no, XL.line_no
          FROM  #transfer_detail XL
          WHERE  XL.xfer_no = @transfer_id and isnull(@transfer_line,XL.line_no) = XL.line_no
          if @@error <> 0  select @err_ind = @err_ind + 1

          OPEN c_purchase
          FETCH c_purchase INTO @part_no,@qty,@uom,@xfer_line

          WHILE @@fetch_status = 0
          BEGIN -- BEGIN 8
            INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
            VALUES(@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'T')

            SELECT  @sched_item_id=@@identity, @err_ind = @err_ind + case @@error when 0 then 0 else 1 end

            INSERT  sched_purchase(sched_item_id,xfer_no,xfer_line)
            VALUES(@sched_item_id,@transfer_id,@xfer_line)
            if @@error <> 0  select @err_ind = @err_ind + 1

            FETCH c_purchase INTO @part_no,@qty,@uom,@xfer_line
          END 
          CLOSE c_purchase

        END -- END 4
        ELSE
        BEGIN -- BEGIN 5
          
          
          INSERT  sched_order (sched_id, location, done_datetime, part_no, uom_qty, uom, 
            order_priority_id, source_flag, order_no, order_line)
          SELECT  @sched_id, @beg_location, @beg_datetime,  XL.part_no, XL.ordered, 
            XL.uom, @order_priority_id,  'T', XL.xfer_no, XL.line_no
          FROM  #transfer_detail XL
          WHERE  XL.xfer_no = @transfer_id and isnull(@transfer_line,XL.line_no) = XL.line_no
          if @@error <> 0  select @err_ind = @err_ind + 1
        END -- END 5
      END -- END 3
      ELSE
      BEGIN -- BEGIN 6
        
        
        IF EXISTS(SELECT 1 FROM #sched_locations SL WHERE SL.location = @end_location)
        BEGIN -- BEGIN 7
          
          OPEN c_purchase

          
          FETCH c_purchase INTO @part_no,@qty,@uom,@xfer_line

          WHILE @@fetch_status = 0
          BEGIN -- BEGIN 8
            
            INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag)
            VALUES(@sched_id,@end_location,@part_no,@end_datetime,@qty,@uom,'T')

            
            SELECT  @sched_item_id=@@identity, @err_ind = @err_ind + case @@error when 0 then 0 else 1 end

            
            INSERT  sched_purchase(sched_item_id,xfer_no,xfer_line)
            VALUES(@sched_item_id,@transfer_id,@xfer_line)
            if @@error <> 0  select @err_ind = @err_ind + 1

            
            FETCH c_purchase INTO @part_no,@qty,@uom,@xfer_line
          END -- END 8
          CLOSE c_purchase
        END -- END 7
      END -- END 6

      DEALLOCATE c_purchase

      FETCH NEXT FROM schedtransfer into @status_flag, @transfer_id, @transfer_line,
      @beg_location, @end_location, @beg_datetime, @end_datetime

    end

    CLOSE schedtransfer
    DEALLOCATE schedtransfer

    delete from #result where object_flag = 'X' and location = @sched_location and status_flag in ('N','A')
  end -- @apply_changes = 1

  if @err_ind != 0
  begin
    INSERT  #result(object_flag,status_flag,xfer_no,message, location)
    SELECT  distinct 'X','N',X.xfer_no,'New transfer (#'+CONVERT(VARCHAR(12),X.xfer_no)+')', @sched_location
    FROM  #transfer_detail X
    WHERE ((X.to_loc = @sched_location and @xfer_supply_mode = 'U')    -- mls 4/26/02 SCR 28832
      OR  (X.from_loc = @sched_location and @xfer_demand_mode = 'U'))    -- mls 4/26/02 SCR 28832
    AND  NOT EXISTS (  SELECT  1 FROM  sched_transfer ST WHERE  ST.sched_id = @sched_id
    AND  ST.source_flag = 'R' AND  ST.xfer_no = X.xfer_no)
    AND  NOT EXISTS (  SELECT  1 FROM  sched_item SI
      JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.xfer_no = X.xfer_no
      WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'T')
    AND  NOT EXISTS (  SELECT  1
      FROM  sched_order SO WHERE  SO.sched_id = @sched_id AND  SO.source_flag = 'T' AND  SO.order_no = X.xfer_no )





    INSERT  #result(object_flag,status_flag,xfer_no,xfer_line,message, location)
    SELECT  'X','A',XL.xfer_no,XL.line_no,'New line item on transfer (#'+CONVERT(VARCHAR(12),XL.xfer_no)+','+CONVERT(VARCHAR(12),XL.line_no)+')',
      @sched_location
    FROM  #transfer_detail XL 
    WHERE  ((XL.to_loc = @sched_location and @xfer_supply_mode = 'U')    -- mls 4/26/02 SCR 28832
      OR  (XL.from_loc = @sched_location and @xfer_demand_mode = 'U'))    -- mls 4/26/02 SCR 28832 
      AND  NOT EXISTS (  SELECT  1 FROM  sched_transfer ST
        WHERE  ST.sched_id = @sched_id AND  ST.source_flag = 'R' AND  ST.xfer_no = XL.xfer_no AND  ST.xfer_line = XL.line_no)
      AND  NOT EXISTS (  SELECT  1 FROM  sched_item SI
        JOIN  sched_purchase SP on SP.sched_item_id = SI.sched_item_id and SP.xfer_no = XL.xfer_no and SP.xfer_line = XL.line_no
        WHERE  SI.sched_id = @sched_id AND  SI.source_flag = 'T')
      AND  NOT EXISTS (  SELECT  1 FROM  sched_order SO
        WHERE  SO.sched_id = @sched_id AND  SO.source_flag = 'T' AND  SO.order_no = XL.xfer_no AND  SO.order_line = XL.line_no)
      AND  NOT EXISTS (  SELECT  1 FROM  #result R WHERE  R.xfer_no = XL.xfer_no and object_flag = 'X' and status_flag IN ('N','A'))





  end
end


RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_compare_schedule_xfers] TO [public]
GO
