SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


-- Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_compare_schedule_process_chg]
	(
	@sched_id	INT
	)
AS
BEGIN

SET NOCOUNT ON

-- 
-- sched_process - changes to productions
--
-- check for changes 

INSERT	#result(object_flag,status_flag,sched_process_id,prod_no,prod_ext,xfer_no,message)
SELECT	distinct 'P', 'O', SP.sched_process_id,SP.prod_no,SP.prod_ext, isnull(SP.qc_no,0),
  'Released process closed #'+Convert(VARCHAR(12),SP.prod_no)
FROM	sched_process SP
WHERE   SP.sched_id = @sched_id
  AND SP.source_flag in ('H','R','U','Q')						-- mls 2/20/03 SCR 30719
  AND not exists (select 1 from #process_detail p where p.prod_no = SP.prod_no and p.prod_ext = SP.prod_ext 
  and p.d_qc_no = isnull(SP.qc_no,0) )

INSERT	#result(object_flag,status_flag,sched_process_id,prod_no,prod_ext,xfer_no,message)
SELECT	distinct 'P', 'C', SP.sched_process_id,SP.prod_no,SP.prod_ext, isnull(SP.qc_no,0), 
'Released process changed #'+Convert(VARCHAR(12),SP.prod_no)
FROM	sched_process SP
JOIN	#process_detail P on P.prod_no = SP.prod_no and P.prod_ext = SP.prod_ext and P.d_qc_no = isnull(SP.qc_no,0)
WHERE	SP.sched_id = @sched_id
AND	((SP.source_flag != 'U' and						-- mls 6/13/01 SCR 27066
  SP.source_flag != CASE WHEN P.hold_flag = 'Y' THEN 'H' WHEN P.status = 'R' THEN 'Q' ELSE 'R' END)	-- mls 2/20/03 SCR 30719

	or (P.prod_type != 'J' and SP.process_unit * isnull((select sum(SPP.uom_qty) from sched_process_product SPP
  	  WHERE	SPP.sched_process_id = SP.sched_process_id
	  AND	SPP.usage_flag = 'P' and P.h_part_no = SPP.part_no),-1) != P.qty_scheduled)

        or (P.prod_type = 'R' and P.direction > 0 and P.h_part_no != P.d_part_no and
          (case when (P.plan_qty -P.used_qty) < 0 then 0 else (P.plan_qty -P.used_qty) end != (SP.process_unit * isnull((select sum(SPP.uom_qty) from sched_process_product SPP
           where SPP.sched_process_id = SP.sched_process_id 
           AND SPP.usage_flag = 'B' and SPP.part_no = P.d_part_no),0))))

        or (P.status = 'R' and P.direction > 0 and P.h_part_no != P.d_part_no and
          (P.used_qty != (SP.process_unit * isnull((select max(SPP.uom_qty) from sched_process_product SPP
           where SPP.sched_process_id = SP.sched_process_id 
           AND SPP.usage_flag = 'B' and SPP.part_no = P.d_part_no),0))))					-- mls 2/20/03 SCR 30719

	OR	EXISTS(	SELECT	distinct 1
			FROM	sched_process_product SPP
			WHERE	SPP.sched_process_id = SP.sched_process_id
			AND	SPP.usage_flag = 'P'
			AND	P.h_part_no != SPP.part_no)

	OR	((	SELECT	count(*)			-- Make sure nothing has been deleted	-- mls 4/3/03 SCR 30719
			FROM	sched_operation_plan SOP
			JOIN	sched_operation SO on SO.sched_operation_id = SOP.sched_operation_id 
				and SO.sched_process_id = SP.sched_process_id
			WHERE  NOT EXISTS(	SELECT	1
					FROM	#process_detail PL
					WHERE	PL.prod_no = SP.prod_no
					AND	PL.prod_ext = SP.prod_ext AND PL.d_qc_no = isnull(SP.qc_no,0)
					AND	PL.line_no = SOP.line_no)) > 0 and P.status != 'R')	-- mls 6/13/01
	OR	EXISTS(	SELECT	distinct 1			-- Make sure nothing has been added
			FROM	#process_detail PL1
			WHERE	PL1.prod_no = SP.prod_no
			AND	PL1.prod_ext = SP.prod_ext AND PL1.d_qc_no = isnull(SP.qc_no,0)
			AND	PL1.direction = -1
			AND	(	isnull(PL1.constrain,'N') = 'N'
				OR	PL1.seq_no <> '****')
			AND NOT EXISTS(	SELECT	1
					FROM	sched_operation SO1,
					sched_operation_plan SOP1 
					where SOP1.sched_operation_id = SO1.sched_operation_id AND SOP1.line_no = PL1.line_no
					and	SO1.sched_process_id = SP.sched_process_id))		-- mls 6/13/01
	OR	(EXISTS(	SELECT	distinct 1			-- Make sure nothing has been changed
			FROM	sched_operation_plan SOP2
			JOIN	sched_operation SO2 on SO2.sched_operation_id = SOP2.sched_operation_id 
and SO2.sched_process_id = SP.sched_process_id
			JOIN	#process_detail PL2 on PL2.prod_no = SP.prod_no and 
PL2.prod_ext = SP.prod_ext and PL2.line_no = SOP2.line_no AND PL2.d_qc_no = isnull(SP.qc_no,0)
			WHERE	(	PL2.seq_no <> SOP2.seq_no

				OR	((PL2.d_part_no <> SOP2.part_no) AND
					PL2.d_part_no NOT IN (select part_no from #res_group))

				OR	PL2.d_location <> SO2.location
				OR	(	PL2.pool_qty <> SOP2.ave_pool_qty
					AND	PL2.part_type = 'R')

				-- to fulfill new business rule regarding operation completions
				OR	((PL2.p_pcs > 0) AND 
					  NOT(((PL2.pieces = SO2.complete_qty) OR 
					 ((P.qty = SO2.complete_qty) AND (P.qty > PL2.pieces))) ) )

				OR	PL2.d_uom <> SOP2.uom
				OR      PL2.active <> SOP2.active
				OR      PL2.eff_date <> SOP2.eff_date
				OR   
					((PL2.direction = 1 and PL2.p_qty <> SOP2.ave_unit_qty) or
					(PL2.direction = -1 and 
					 ((PL2.plan_qty != SOP2.ave_flat_qty and SOP2.ave_unit_qty = 0) or		-- mls 5/24/02 SCR 28976
                                         (PL2.plan_qty / case when P.qty_scheduled = 0 then 1 else P.qty_scheduled end != SOP2.ave_unit_qty and SOP2.ave_flat_qty = 0)))) -- #24
				OR      PL2.pool_qty <> SOP2.ave_pool_qty  -- Rev 10
				)
			) and P.status != 'R')
	)

-- Check for progress in 'prod_list'
INSERT	#result(object_flag,status_flag,sched_process_id,sched_operation_id,prod_no,prod_ext,prod_line,xfer_no,message)
SELECT	distinct 'P','P',SO.sched_process_id,SO.sched_operation_id,PL.prod_no,PL.prod_ext,PL.line_no,isnull(SP.qc_no,0),
'Released process progress #'+Convert(VARCHAR(12),PL.prod_no)
FROM	sched_process SP
JOIN	sched_operation SO on SO.sched_process_id = SP.sched_process_id AND SO.operation_status <> 'X'
and not exists (select 1 from #result R where R.sched_process_id = SP.sched_process_id)
JOIN	sched_operation_plan SOP on SOP.sched_operation_id = SO.sched_operation_id
JOIN	#process_detail PL on PL.prod_no = SP.prod_no and PL.prod_ext = SP.prod_ext and PL.line_no = SOP.line_no
  and PL.d_qc_no = isnull(SP.qc_no,0)
WHERE	SP.sched_id = @sched_id
AND	SP.source_flag = 'R'
AND	(	(	PL.plan_pcs > 0.0
		AND	(	NOT(((PL.pieces = SO.complete_qty) OR ((PL.qty = SO.complete_qty) AND 
				   (PL.qty > PL.pieces)))) -- rev 3
			OR	PL.scrap_pcs <> SO.discard_qty
			OR	PL.oper_status = 'X'
			OR      PL.oper_status = 'S'
			)
		)
	OR	(	
			SOP.usage_qty != CASE PL.plan_qty WHEN 0.0 THEN 0.0 ELSE PL.used_qty / PL.plan_qty END
		)
	)

INSERT	#result(object_flag,status_flag,sched_process_id,sched_operation_id,prod_no,prod_ext,prod_line,xfer_no,message)
SELECT	distinct 'P','P',SP.sched_process_id,null,PL.prod_no,PL.prod_ext,PL.line_no,isnull(SP.qc_no,0),
  'Released process item progress #'+Convert(VARCHAR(12),PL.prod_no)
from #process_detail PL
join sched_process SP (nolock) on SP.prod_no = PL.prod_no and SP.prod_ext = PL.prod_ext
  and SP.sched_id = @sched_id and SP.source_flag = 'R' and isnull(SP.qc_no,0) = PL.d_qc_no
join sched_operation SO (nolock) on SO.sched_process_id = SP.sched_process_id and SO.complete_qty != 0
join sched_operation_plan SOP (nolock) on SOP.sched_operation_id = SO.sched_operation_id 
  and SOP.line_no = (select max(line_no) from sched_operation_plan SOP1 
    where SOP1.sched_operation_id = SO.sched_operation_id)
join #process_detail PL1 (nolock) on PL1.prod_no = PL.prod_no and PL1.prod_ext = PL.prod_ext 
  and PL1.line_no = SOP.line_no and PL1.p_pcs > 0 and PL1.d_qc_no = PL.d_qc_no
where PL.direction > 0 and PL.plan_pcs > 0 and PL.pieces > 0 and PL.seq_no = ''
and (PL.pieces * PL1.p_pcs) != SO.complete_qty
AND NOT EXISTS(	SELECT	1
		FROM	#result R
		WHERE	R.sched_process_id = SP.sched_process_id)


RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_compare_schedule_process_chg] TO [public]
GO
