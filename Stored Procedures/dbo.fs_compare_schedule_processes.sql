SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_compare_schedule_processes]
	(
	@sched_id	INT,
        @first_call	INT,
	@sched_location varchar(10),
        @apply_changes  INT = 0
	)
AS
BEGIN
SET NOCOUNT ON

DECLARE @pr_err_ind		INT,
    	@sched_process_id	INT,
 	@sched_operation_id	INT,
	@prod_no		INT,
	@prod_ext		INT,
	@prod_line		INT,
        @qc_no			INT

-- 
-- sched_process - changes to productions
--
-- get current open processes
--
if @first_call = -1
begin
  select @pr_err_ind = 0

  insert #process_detail (
    prod_no, prod_ext, qty, void, status, hold_flag, h_part_no, qty_scheduled, h_location,
    qty_scheduled_orig, prod_type, bom_rev, end_sch_date, prod_date, h_uom,
    line_no, p_pcs, direction, plan_pcs, pieces, seq_no, scrap_pcs, oper_status, plan_qty,
    used_qty, constrain, d_part_no, d_location, pool_qty, part_type, d_uom, active, eff_date,
    p_qty, cost_pct, p_line, im_status, im_type_code, il_lead_time, h_usage_mtd, h_produced_mtd,
    d_usage_mtd, d_produced_mtd, d_status, d_qc_no)
  select 
    h.prod_no, h.prod_ext, 
    case when h.prod_type = 'R' and d.status = 'R' and d.qc_no != 0 then d.used_qty else h.qty end,
    h.void, 
    case when h.prod_type = 'R' and d.status = 'R' and d.qc_no != 0 then 'R' else h.status end, 
    h.hold_flag, 
    case when h.prod_type = 'R' and d.status = 'R' and d.qc_no != 0 then d.part_no else h.part_no end, 
    case when h.prod_type = 'R' then
      case when d.status = 'R' and d.qc_no != 0 then d.used_qty else h.qty_scheduled - h.qty end
      else 
       case when h.status = 'R' then h.qty else h.qty_scheduled end end,
    h.location,
    case when h.prod_type = 'R' then
      case when d.status = 'R' and d.qc_no != 0 then d.used_qty else h.qty_scheduled_orig - h.qty end
      else 
        case when h.status = 'R' then h.qty else h.qty_scheduled_orig end end,
    h.prod_type, h.bom_rev, h.end_sch_date, h.prod_date, h.uom,
    d.line_no, d.p_pcs, d.direction, d.plan_pcs, d.pieces, d.seq_no, d.scrap_pcs, d.oper_status, d.plan_qty,
    d.used_qty, d.constrain, d.part_no, d.location, d.pool_qty, d.part_type, d.uom, d.active, d.eff_date,
    d.p_qty, d.cost_pct, d.p_line, im.status, im.type_code, il.lead_time, iph.usage_mtd, iph.produced_mtd,
    ipd.usage_mtd, ipd.produced_mtd, d.status, 
    isnull(case when h.prod_type = 'R' 
      then case when d.status = 'R' then d.qc_no else 0 end
      else case when h.status = 'R' then isnull((select max(qc_no) from prod_list f 
        where f.prod_no = h.prod_no and f.prod_ext = h.prod_ext),0) else 0 end
      end,0)
  from produce_all h
  join prod_list d on d.prod_no = h.prod_no and d.prod_ext = h.prod_ext
  JOIN #sched_locations SL on SL.location = h.location
  left outer join inv_master im on im.part_no = d.part_no
  left outer join inv_list il on il.part_no = d.part_no and il.location = d.location
  left outer join inv_produce ipd on ipd.part_no = d.part_no and ipd.location = d.location
  left outer join inv_produce iph on iph.part_no = h.part_no and iph.location = h.location
  where h.void = 'N' and h.status between 'N' and 'R'
   and ((h.prod_type != 'R' and (h.status < 'R' or (h.status = 'R' and h.qty != 0)))
      or (h.prod_type = 'R' and (d.status < 'R' or (d.status = 'R' and  d.used_qty != 0 and d.direction > 0))))
  if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1

  return @pr_err_ind
end
-- check for changes 
if @first_call = 1
begin
  exec fs_compare_schedule_process_chg @sched_id

  select @pr_err_ind = 0
  if @apply_changes = 1 and exists (select 1 FROM #result where object_flag = 'P' and status_flag = 'O')
  begin
    if (@@version like '%7.0%') and @pr_err_ind = 0 
     and exists (select 1 from #result where object_flag = 'P' and status_flag = 'O')
    begin
      delete SPP
      from sched_process_product SPP, #result SP where SPP.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
      delete SOP
      from sched_operation_plan SOP, sched_operation SO, #result SP where SOP.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
      delete SOR
      from sched_operation_resource SOR, sched_operation SO, #result SP where SOR.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
      delete SOI
      from sched_operation_item SOI, sched_operation SO, #result SP where SOI.sched_operation_id = SO.sched_operation_id
      and SO.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
      delete SO
      from sched_operation SO, #result SP where SO.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1

      delete SOI 
      from sched_order_item SOI, sched_item SI, #result SP where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
      delete SOI 
      from sched_operation_item SOI, sched_item SI, #result SP where SOI.sched_item_id = SI.sched_item_id
      and SI.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
      delete STI 
      from sched_transfer_item STI, sched_item SI, #result SP where STI.sched_item_id = SI.sched_item_id
      and SI.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
      delete PU
      from sched_purchase PU, sched_item SI, #result SP where PU.sched_item_id = SI.sched_item_id
      and SI.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
    end

    if @pr_err_ind = 0 and exists (select 1 from #result)
    begin
      delete SI
      from sched_item SI, #result SP where SI.sched_process_id = SP.sched_process_id
        and SP.object_flag = 'P' and SP.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
    end

    if @pr_err_ind = 0 and exists (select 1 from #result)
    begin
      delete SP
      from sched_process SP, #result t where SP.sched_process_id = t.sched_process_id  
        and t.object_flag = 'P' and t.status_flag = 'O'
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
    end
  end

  if @apply_changes = 1 
  begin
    if @pr_err_ind = 0 and exists (select 1 from #result where object_flag = 'P' and status_flag = 'C')
    begin
      DECLARE schedprocess CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
      SELECT distinct sched_process_id 
      from #result where object_flag = 'P' and status_flag = 'C'

      OPEN schedprocess
      FETCH NEXT FROM schedprocess into @sched_process_id

      While @@FETCH_STATUS = 0
      begin									-- mls #22 end
        exec fs_build_sched_process NULL,NULL,-999,@sched_process_id
        if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1

        FETCH NEXT FROM schedprocess into @sched_process_id
      end
      CLOSE schedprocess
      DEALLOCATE schedprocess
    end

    if @pr_err_ind = 0 and exists (select 1 from #result where object_flag = 'P' and status_flag = 'P')
    begin
      DECLARE schedprocess1 CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
      SELECT distinct sched_operation_id, prod_no, prod_ext, prod_line , isnull(xfer_no,0)
      from #result where object_flag = 'P' and status_flag = 'P'

      OPEN schedprocess1
      FETCH NEXT FROM schedprocess1 into @sched_operation_id, @prod_no, @prod_ext, @prod_line, @qc_no

      While @@FETCH_STATUS = 0
      begin									-- mls #22 end
		UPDATE	sched_operation
		SET	complete_qty = PL.pieces,
			discard_qty = PL.scrap_pcs,
			operation_status = CASE PL.oper_status 
			WHEN 'X' THEN 'X'    
			WHEN 'S' THEN 'X' 
			ELSE SO.operation_status 
			END
		FROM	sched_operation SO,
			#process_detail PL
		WHERE	SO.sched_operation_id = @sched_operation_id
		AND	PL.prod_no = @prod_no
		AND	PL.prod_ext = @prod_ext
		AND	PL.line_no = @prod_line
                AND     PL.d_qc_no = @qc_no
                if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1

		UPDATE	sched_operation_plan
		SET	usage_qty =  CASE PL.plan_qty
                        WHEN 0.0 THEN 0.0
                        ELSE PL.used_qty / PL.plan_qty
			END 
		FROM	sched_operation_plan SOP,
			#process_detail PL
		WHERE	SOP.sched_operation_id = @sched_operation_id
		AND	SOP.line_no = @prod_line
		AND	PL.prod_no = @prod_no
		AND	PL.prod_ext = @prod_ext
                AND     PL.d_qc_no = @qc_no
		AND	PL.line_no = @prod_line
                if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1

		
		exec fs_calculate_opn_completion @sched_id, @prod_no, @prod_ext,1, @qc_no	-- mls 9/10/03 SCR 31868
                if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1
	
        FETCH NEXT FROM schedprocess1 into @sched_operation_id, @prod_no, @prod_ext, @prod_line, @qc_no
      end
      CLOSE schedprocess1
      DEALLOCATE schedprocess1
    end

    delete from #result where object_flag = 'P'
    if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1  
  end

  if @pr_err_ind != 0
  begin
    exec fs_compare_schedule_process_chg @sched_id
  end
end -- first call = 1

select @pr_err_ind = 0

-- Check for new 'produce'
INSERT	#result(object_flag,status_flag,prod_no,prod_ext,xfer_no, message, location)
SELECT	distinct 'P','N',P.prod_no,P.prod_ext,P.d_qc_no, 'Released process found #'+Convert(VARCHAR(12),P.prod_no), P.h_location
FROM	#process_detail P
WHERE	P.h_location = @sched_location
  AND NOT EXISTS (	SELECT	1
			FROM	sched_process SP
			WHERE	SP.sched_id = @sched_id
			AND	SP.source_flag IN ('R','H','U','Q')			-- mls 2/20/03 SCR 30719
											-- mls 6/13/01 SCR 27066
			AND	SP.prod_no = P.prod_no
			AND	SP.prod_ext = P.prod_ext
                        AND     isnull(SP.qc_no,0) = P.d_qc_no)

if @apply_changes = 1 and @@rowcount != 0
begin
    DECLARE schedprocess CURSOR LOCAL FORWARD_ONLY STATIC FOR			-- mls #22 start
    SELECT distinct prod_no, prod_ext , xfer_no
    from #result where object_flag = 'P' and status_flag = 'N' and location = @sched_location

    OPEN schedprocess
    FETCH NEXT FROM schedprocess into @prod_no, @prod_ext, @qc_no

    While @@FETCH_STATUS = 0
    begin									-- mls #22 end
      exec fs_build_sched_process @sched_id,@prod_no,@prod_ext,-999, @qc_no
      if @@error <> 0  select @pr_err_ind = @pr_err_ind + 1

      FETCH NEXT FROM schedprocess into @prod_no, @prod_ext, @qc_no
    end
    CLOSE schedprocess
    DEALLOCATE schedprocess

    delete #result where object_flag = 'P' and status_flag = 'N' and location = @sched_location
end

if @pr_err_ind != 0
begin
  INSERT	#result(object_flag,status_flag,prod_no,prod_ext,xfer_no, message, location)
  SELECT	'P','N',P.prod_no,P.prod_ext, P.d_qc_no, 'Released process found #'+Convert(VARCHAR(12),P.prod_no), P.h_location
  FROM	#process_detail P
  WHERE	P.h_location = @sched_location
    AND NOT EXISTS (	SELECT	1
			FROM	sched_process SP
			WHERE	SP.sched_id = @sched_id
			AND	SP.source_flag IN ('R','H','U','Q')				-- mls 2/20/03 SCR 30719
												-- mls 6/13/01 SCR 27066
			AND	SP.prod_no = P.prod_no
			AND	SP.prod_ext = P.prod_ext
                        AND     isnull(SP.qc_no,0) = P.d_qc_no)
end

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_compare_schedule_processes] TO [public]
GO
