SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




-- Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_compare_schedule_orders]
	(
	@sched_id	INT,
        @first_call	INT,
	@sched_location	varchar(10),
        @order_usage_mode char(1),
        @order_priority_id INT,       
        @apply_changes  INT = 0
	)
AS
BEGIN

DECLARE @err_ind		INT,
        @o_err_ind              INT
	
SET NOCOUNT ON

create table #orders (order_no int, ext int, status char(1), back_ord_flag char(1) null,
sch_ship_date datetime null, type char(1) NULL)

create index o1 on #orders(type)
create index o2 on #orders(order_no, ext, status, back_ord_flag, sch_ship_date)

create table #sched_order (sched_order_id int)
create index so1 on #sched_order(sched_order_id)

if @first_call = -1
begin
  select @err_ind = 0

  insert #order_detail (location, demand_date, part_no, uom_qty, uom, source_flag,
    order_no, order_ext, line_no, prod_no, prod_ext, order_line_kit, status, back_ord_flag, part_type, sales_qty_mtd)
      SELECT OL.location,IsNull(O.sch_ship_date,O.req_ship_date),
        case when OL.part_type in ('P','M','C') then OL.part_no else NULL end,
          (OL.ordered - OL.shipped) * OL.conv_factor,IsNull(IM.uom,OL.uom),
        case when OL.part_type = 'J' then 'J' else 'C' end,
          OL.order_no,OL.order_ext,OL.line_no,
        case when OL.part_type = 'J' then CONVERT(int,OL.part_no) else NULL end,
        case when OL.part_type = 'J' then 0 else NULL end, 
        case when OL.part_type = 'C' then -1 else 0 end, O.status, O.back_ord_flag, OL.part_type,
        S.sales_qty_mtd
      FROM orders_all O
      JOIN ord_list OL on OL.order_no = O.order_no and OL.order_ext = O.ext 
        AND    (OL.status between 'N' and 'Q' OR (OL.status between 'R' and 'S' and O.back_ord_flag = '0' 
        and OL.back_ord_flag = '0')) AND OL.ordered > OL.shipped --and OL.location = O.location	-- mls 7/27/03 SCR 31636
        AND OL.part_type IN ('P','M','J','C') 
      LEFT OUTER JOIN inv_master IM on IM.part_no = OL.part_no
      LEFT OUTER JOIN inv_sales S on S.part_no = OL.part_no and S.location = OL.location
      JOIN #sched_locations SL on SL.location = OL.location 
      WHERE O.type = 'I' AND O.status between 'N' and 'S'
    UNION
      SELECT OLK.location, IsNull(O.sch_ship_date,O.req_ship_date),
        OLK.part_no, (OLK.ordered - OLK.shipped) * OLK.conv_factor * OLK.qty_per,	
        IM.uom, 'C', OLK.order_no, OLK.order_ext, OLK.line_no, NULL, NULL, OLK.row_id,
        O.status, O.back_ord_flag, OLK.part_type, S.sales_qty_mtd
      FROM  orders_all O
      join  ord_list OL on OL.order_no = O.order_no and OL.order_ext = O.ext --and OL.location = O.location
      join  ord_list_kit OLK on OLK.order_no = OL.order_no and OLK.order_ext = OL.order_ext
        and OLK.line_no = OL.line_no --and OLK.location = OL.location
        AND OLK.part_type = 'P' AND OLK.ordered > OLK.shipped
        AND (OLK.status between 'N' and 'Q' OR  (OLK.status between 'R' and 'S' and O.back_ord_flag = '0' 
        and OL.back_ord_flag = '0'))				-- mls 4/5/01 SCR 26567 end
      join inv_master IM on IM.part_no = OLK.part_no
      LEFT OUTER JOIN inv_sales S on S.part_no = OLK.part_no and S.location = OLK.location
      join #sched_locations SL on SL.location = OLK.location 
      WHERE O.type = 'I' AND O.status between 'N' and 'S'
      if @@error <> 0  select @err_ind = @err_ind + 1

  return @err_ind
end
--
-- sched_order - delete processed orders
--
if @first_call = 1
begin
  select @o_err_ind = 0
  if @apply_changes = 1
  begin
    Insert #sched_order 
    select sched_order_id
    FROM sched_order SO
    WHERE SO.sched_id = @sched_id AND SO.source_flag IN ('C','J') AND SO.order_line_kit IS NULL
    AND	(@order_usage_mode = 'I' or
      NOT EXISTS(SELECT	1 FROM	#order_detail OL
        where OL.order_no = SO.order_no and OL.order_ext = SO.order_ext and OL.line_no = SO.order_line
          and OL.order_line_kit < 1))
    if @@error <> 0 select @o_err_ind = @o_err_ind + 1

    Insert #sched_order 
    select sched_order_id
    FROM sched_order SO
    WHERE SO.sched_id = @sched_id AND SO.source_flag IN ('C','J') AND SO.order_line_kit IS NOT NULL
    AND (@order_usage_mode = 'I' or			
      NOT EXISTS(SELECT	1 FROM	#order_detail OL
        where OL.order_no = SO.order_no and OL.order_ext = SO.order_ext and OL.line_no = SO.order_line
          and OL.order_line_kit = SO.order_line_kit))
    if @@error <> 0 select @o_err_ind = @o_err_ind + 1

    if @o_err_ind = 0
    begin   
      if (@@version like '%7.0%')
      begin
        delete SOI
        from sched_order_item SOI, #sched_order SO
        where SOI.sched_order_id = SO.sched_order_id
        if @@error <> 0 select @o_err_ind = @o_err_ind + 1
      end
    end

    if @o_err_ind = 0
    begin
      Delete SO
      from sched_order SO, #sched_order t where SO.sched_order_id = t.sched_order_id
      if @@error <> 0 select @o_err_ind = @o_err_ind + 1
    end
  end
  if @apply_changes = 0 or @o_err_ind != 0
  begin
	-- Check for order that have been completed, closed or deleted
	INSERT	#result(object_flag,status_flag,location,part_no,sched_order_id,order_no,order_ext,order_line,message)
	SELECT	'D','O',SO.location,SO.part_no,SO.sched_order_id,SO.order_no,SO.order_ext,SO.order_line,
          case when @order_usage_mode = 'I' then 'Remove Order (#' else 'Completed order (#' end 
	  + CONVERT(VARCHAR(12),SO.order_no)+'-'+CONVERT(VARCHAR(12),SO.order_ext)+') for '+SO.part_no
	FROM	sched_order SO
	WHERE	SO.sched_id = @sched_id
	AND	SO.source_flag IN ('C','J')
	AND	SO.order_line_kit IS NULL
	AND 	(@order_usage_mode = 'I' or					-- mls 4/26/02 SCR 28832
          NOT EXISTS(SELECT 1 FROM #order_detail OL
            where OL.order_no = SO.order_no and OL.order_ext = SO.order_ext and OL.line_no = SO.order_line
              and OL.order_line_kit < 1))

	-- Check for kit orders that have been completed, closed or deleted
	INSERT	#result(object_flag,status_flag,location,part_no,sched_order_id,order_no,order_ext,order_line,order_line_kit,message)
	SELECT	'D','O',SO.location,SO.part_no,SO.sched_order_id,SO.order_no,SO.order_ext,SO.order_line,SO.order_line_kit,
          case when @order_usage_mode = 'I' then 'Remove Order (#' else 'Completed order (#' end 
	  +ltrim(str(SO.order_no))+'-'+ltrim(str(SO.order_ext))+', line '+ltrim(str(SO.order_line))+', kit item '+SO.part_no+')'
	FROM	sched_order SO
	WHERE	SO.sched_id = @sched_id
	AND	SO.source_flag IN ('C','J')
	AND	SO.order_line_kit IS NOT NULL
	AND 	(@order_usage_mode = 'I' or					-- mls 4/26/02 SCR 28832
          NOT EXISTS(SELECT 1 FROM #order_detail OL
            where OL.order_no = SO.order_no and OL.order_ext = SO.order_ext and OL.line_no = SO.order_line
              and OL.order_line_kit = SO.order_line_kit))
  end
end -- @first_call = 1

--
-- sched_orders
--
  -- If they did not want the customer orders, skip this section
  IF @order_usage_mode = 'U'
  BEGIN
    select @err_ind = 0
    if @apply_changes = 1
    begin
      update SO
      SET done_datetime	= OL.demand_date,
        part_no		= OL.part_no,
        uom_qty		= OL.uom_qty,
        uom		= OL.uom,
        location        = OL.location
      from sched_order SO
      join #order_detail OL on OL.order_no = SO.order_no and OL.order_ext = SO.order_ext
        and OL.line_no = SO.order_line and OL.location = @sched_location and OL.order_line_kit = 0
      where SO.sched_id = @sched_id 
	AND	SO.source_flag IN ('C','J')
	AND	SO.order_line_kit IS NULL
	AND	(	SO.done_datetime <> OL.demand_date
		OR	SO.part_no <> OL.part_no
		OR	SO.uom_qty <> OL.uom_qty
                OR      SO.location <> OL.location
		)
      if @@error <> 0  select @err_ind = @err_ind + 1

      update SO
      SET done_datetime	= OLK.demand_date,
        part_no		= OLK.part_no,
        uom_qty		= OLK.uom_qty,
        uom		= OLK.uom
      from sched_order SO
      join #order_detail OLK on OLK.order_no = SO.order_no and OLK.order_ext = SO.order_ext
        and OLK.line_no = SO.order_line and OLK.location = @sched_location and OLK.order_line_kit = SO.order_line_kit
      where SO.sched_id = @sched_id 
	AND	SO.source_flag IN ('C','J')
	AND	SO.order_line_kit IS not NULL
	AND	(	SO.done_datetime <> OLK.demand_date
		OR	SO.part_no <> OLK.part_no
		OR	SO.uom_qty <> OLK.uom_qty
		)
      if @@error <> 0  select @err_ind = @err_ind + 1

      INSERT sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,
        source_flag,order_no,order_ext,order_line, prod_no, prod_ext)
      SELECT @sched_id,OL.location,OL.demand_date,OL.part_no,OL.uom_qty,OL.uom,
        @order_priority_id,OL.source_flag, OL.order_no, OL.order_ext, OL.line_no, 
        OL.prod_no, OL.prod_ext
      FROM #order_detail OL
      WHERE OL.location = @sched_location and OL.order_line_kit = 0
	AND NOT EXISTS (SELECT 1 FROM sched_order SO
          WHERE SO.sched_id = @sched_id AND SO.source_flag IN ('C','J')
            AND SO.order_no = OL.order_no AND SO.order_ext = OL.order_ext
            AND SO.order_line = OL.line_no and SO.order_line_kit is NULL)
      if @@error <> 0  select @err_ind = @err_ind + 1

      INSERT sched_order(sched_id,location,done_datetime,part_no,uom_qty,uom,order_priority_id,
        source_flag,order_no,order_ext,order_line, order_line_kit)
      SELECT @sched_id, OLK.location, OLK.demand_date,OLK.part_no, OLK.uom_qty, OLK.uom,
        @order_priority_id, OLK.source_flag, OLK.order_no, OLK.order_ext, OLK.line_no,
       OLK.order_line_kit
      FROM #order_detail OLK
      WHERE OLK.location = @sched_location and OLK.order_line_kit > 0
        and NOT EXISTS (SELECT	1 FROM	sched_order SO 
          WHERE SO.sched_id = @sched_id AND SO.source_flag IN ('C','J')
            AND SO.order_no = OLK.order_no AND SO.order_ext = OLK.order_ext and SO.order_line = OLK.line_no
            AND SO.order_line_kit = OLK.order_line_kit )
      if @@error <> 0  select @err_ind = @err_ind + 1
    end

    if @apply_changes = 0 or @err_ind != 0
    begin
      -- Check for new 'orders'
      insert #orders
      select distinct o.order_no, o.order_ext, o.status, o.back_ord_flag, o.demand_date, 'A'
      from #order_detail o
      WHERE	o.location = @sched_location  

      INSERT #result(object_flag,status_flag,order_no,order_ext,message)
      SELECT distinct 'D','N',O.order_no,O.ext,'New order (#'+CONVERT(VARCHAR(12),O.order_no)+')'
      FROM	#orders O 
      WHERE	NOT EXISTS (	SELECT	1
				FROM	sched_order SO
				WHERE	SO.sched_id = @sched_id
				AND	SO.source_flag IN ('C','J')
				AND	SO.order_no = O.order_no
				AND	SO.order_ext = O.ext )


      INSERT #orders
      select distinct o.order_no, o.ext, o.status, o.back_ord_flag, o.sch_ship_date, 'B'
      from #orders o

      delete from #orders where type = 'A'

	-- Check for new 'ord_list'
	INSERT	#result(object_flag,status_flag,location,part_no,order_no,order_ext,order_line,message)
	SELECT	'D',
	case when OL.order_line_kit < 0 then 'D' else 'A' end,
        OL.location,OL.part_no,OL.order_no,OL.order_ext,OL.line_no,'New order (#'+CONVERT(VARCHAR(12),OL.order_no)+') line item ('+
        CASE OL.part_type WHEN 'J' THEN 'Job #'+OL.part_no ELSE RTrim(OL.part_no) END+')'
	FROM	#order_detail OL
	JOIN	#orders O on O.order_no = OL.order_no and O.ext = OL.order_ext
	WHERE	OL.location = @sched_location and OL.order_line_kit < 1
	AND	( OL.order_line_kit = 0
		OR	(	OL.order_line_kit < 0
			AND	EXISTS (SELECT	1
					FROM	#order_detail OLK
					WHERE	OLK.location = @sched_location
					AND	OLK.order_no = OL.order_no
					AND	OLK.order_ext = OL.order_ext
					AND	OLK.order_line_kit > 0
					AND	OLK.line_no = OL.line_no)))
	AND	NOT EXISTS (	SELECT	1
				FROM	sched_order SO
				WHERE	SO.sched_id = @sched_id
				AND	SO.source_flag IN ('C','J')
				AND	SO.order_no = OL.order_no
				AND	SO.order_ext = OL.order_ext
				AND	SO.order_line = OL.line_no )
        and NOT EXISTS (	SELECT	1
				FROM	#result R
				WHERE	R.order_no = OL.order_no
				AND	R.order_ext = OL.order_ext)				-- mls #22


	-- Check for new 'ord_list_kit'
	INSERT	#result(object_flag,status_flag,location,part_no,order_no,order_ext,order_line,order_line_kit,message)

	SELECT	'D','B',OLK.location,OLK.part_no,OLK.order_no,OLK.order_ext,OLK.line_no,OLK.order_line_kit,'New order line item (#'+ltrim(str(OLK.order_no))+', line '+ltrim(str(OLK.line_no))+', kit item '+RTrim(OLK.part_no)+')'
	FROM	#order_detail OLK
	join #orders O on OLK.order_no = O.order_no AND OLK.order_ext = O.ext 
	join #order_detail OL on OLK.order_no = OL.order_no and OLK.order_ext = OL.order_ext and OLK.line_no = OL.line_no
          and OL.order_line_kit < 1
	WHERE	OLK.location = @sched_location and OLK.order_line_kit > 0
	AND	NOT EXISTS (	SELECT	1
				FROM	sched_order SO
				WHERE	SO.sched_id = @sched_id
				AND	SO.source_flag IN ('C','J')
				AND	SO.order_no = OLK.order_no
				AND	SO.order_ext = OLK.order_ext
				AND	SO.order_line = OLK.line_no
				AND	SO.order_line_kit = OLK.order_line_kit )		-- MLS #22
	AND	NOT EXISTS (	SELECT	1
				FROM	#result R
				WHERE	R.order_no = O.order_no
				AND	R.order_ext = O.ext)					-- mls #22

	-- Check for changes to quantity or date
	INSERT	#result(object_flag,status_flag,location,part_no,sched_order_id,order_no,order_ext,order_line,message)
	SELECT	'D','C',SO.location,SO.part_no,SO.sched_order_id,SO.order_no,SO.order_ext,SO.order_line,'Updated order (#'+CONVERT(VARCHAR(12),OL.order_no)+')'
	FROM	sched_order SO
	JOIN	#orders O on O.order_no = SO.order_no and O.ext = SO.order_ext 
	JOIN	#order_detail OL on OL.order_no = SO.order_no and OL.order_ext = SO.order_ext and OL.line_no = SO.order_line 
          and OL.order_line_kit = 0
	WHERE	SO.sched_id = @sched_id
	AND	SO.source_flag IN ('C','J')
	AND	SO.order_line_kit IS NULL
	AND	(	SO.done_datetime <> O.sch_ship_date
		OR	SO.part_no <> OL.part_no
		OR	SO.uom_qty <> OL.uom_qty
                OR      SO.location <> OL.location
		)

	-- Check for kit changes to quantity or date
	INSERT	#result(object_flag,status_flag,location,part_no,sched_order_id,order_no,order_ext,order_line,order_line_kit,message)
	SELECT	'D','K',SO.location,SO.part_no,SO.sched_order_id,SO.order_no,SO.order_ext,SO.order_line,SO.order_line_kit,'Updated order (#'+ltrim(str(OLK.order_no))+'-'+ltrim(str(OLK.order_ext))+', line '+ltrim(str(OLK.line_no))+', kit item '+OLK.part_no+')'
	FROM	sched_order SO
	JOIN 	#orders O on O.order_no = SO.order_no and O.ext = SO.order_ext
	JOIN	#order_detail OLK on OLK.order_no = SO.order_no and OLK.order_ext = SO.order_ext
          and OLK.line_no = SO.order_line AND OLK.order_line_kit = SO.order_line_kit AND OLK.part_type = 'P'
	WHERE	SO.sched_id = @sched_id
	AND	SO.source_flag IN ('C','J')
	AND	SO.order_line_kit IS NOT NULL
	AND	(	SO.done_datetime <> O.sch_ship_date
		OR	SO.part_no <> OLK.part_no
		OR	SO.uom_qty <> OLK.uom_qty
		)
    end -- apply_changes = 0 or err_ind != 0
  END -- order_usage_mode = 'U'
	
RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_compare_schedule_orders] TO [public]
GO
