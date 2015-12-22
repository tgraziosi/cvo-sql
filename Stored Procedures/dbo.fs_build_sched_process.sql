SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1999 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_build_sched_process]
	(
	@sched_id		INT = NULL,
	@prod_no		INT = NULL,
	@prod_ext		INT = NULL,
	@sched_process_id	INT = NULL,
        @qc_no                  INT = 0
	)
AS
BEGIN
set nocount on









DECLARE	@sched_operation_id	INT,
	@asm_type		CHAR(1),
	@operation_step		INT,
	@operation_type		CHAR(1),
	@line_no		INT,
	@p_line			INT,
	@seq_no			VARCHAR(4),
	@location		VARCHAR(10),
	@part_no		VARCHAR(30),
	@pool_qty		FLOAT,
	@uom_qty		FLOAT,
	@uom			CHAR(2),
	@source_flag		CHAR(1),
	@ave_flat_time		FLOAT,
	@ave_flat_qty		DECIMAL(20,8),

	@ave_unit_time		FLOAT,
	@p_qty			FLOAT,

	@process_unit		FLOAT,
	@process_unit_orig	FLOAT,	-- rev 1.
	@oper_status		CHAR(1),-- rev 1.
	@resource_type		VARCHAR(10),
	@status			CHAR(1),
	@part_type		CHAR(1),
	@hold_flag		CHAR(1),
	@part_type_pl 		CHAR(1),		
	@complete_qty		FLOAT,			
	@discard_qty		FLOAT,			
	@usage_qty		FLOAT,			

	@use_order		INT,

        @ave_flat_time_plan     FLOAT,
        @ave_unit_time_plan     FLOAT,
	@build_plan_resource VARCHAR(30),
 	@build_plan_flat_time FLOAT,
 	@build_plan_unit_time FLOAT,
        @build_plan_fixed_flag CHAR(1),
        @operation_resource_flat_time FLOAT,
	@operation_resource_unit_time FLOAT,
	@operation_previous_resource VARCHAR(30),
	@fixed                       VARCHAR(1),
	@active         CHAR(1),
	@eff_date       DATETIME,
	@next_seq       varchar(4),
        @lag_qty        FLOAT,      -- Rev 11
	@bom_rev	varchar(10),			-- mls 8/9/01 start
	@end_sch_date   datetime,
	@pstatus		char(1),
	@prod_date	datetime,			-- mls 8/9/01 end
        @asm_no         VARCHAR(30), -- Rev 11
	@p_asm_no	VARCHAR(30),			-- mls 8/10/01 
	@p_asm_line	int,
	@i_lead_time	INT				-- mls 8/10/01

CREATE TABLE #process
	(
	prod_no			INT,
	prod_ext		INT,
	sched_process_id	INT	NULL,
	process_unit		FLOAT,
	process_unit_orig	FLOAT,
	asm_no                  VARCHAR(30),  -- Rev 11
	location		VARCHAR(10),	-- mls 8/9/01 start
	prod_type		CHAR(1),
	hold_flag		CHAR(1),
	bom_rev			VARCHAR(10) NULL,
	end_sch_date		datetime NULL,
	prod_date		datetime,
	status			char(1),
	uom			char(2),	-- mls 8/9/01 end
        qc_no                   int NULL,
	PRIMARY KEY(prod_no,prod_ext)
	)

DECLARE @compare_schedule_ind INT		-- mls 11/25/02

select @compare_schedule_ind = 0
if @sched_process_id = -999
begin
  select @compare_schedule_ind = 1,
    @sched_process_id = NULL
end 
else if @prod_ext = -999
begin
  select @compare_schedule_ind = 1,
    @prod_ext = NULL
end


IF @sched_process_id IS NOT NULL
BEGIN
  
  SELECT @prod_no=SP.prod_no,
    @prod_ext=SP.prod_ext,
    @sched_id=SP.sched_id,
    @qc_no = case when @qc_no = 0 then isnull(SP.qc_no,0) else @qc_no end				-- mls 9/10/03 SCR 31868
  FROM sched_process SP
  WHERE SP.sched_process_id = @sched_process_id

  
  IF @@rowcount <> 1
  BEGIN
    RaisError 69110 'Schedule process does not exists'
    RETURN
  END

  

  set rowcount 1
  if @compare_schedule_ind = 1
  begin
    INSERT  #process(prod_no,prod_ext,asm_no,sched_process_id,
      process_unit, process_unit_orig, -- Rev 11
      location, prod_type, hold_flag, bom_rev, 
      end_sch_date, prod_date, status, uom, qc_no)		-- mls 8/9/01 start
    select distinct prod_no, prod_ext, 
      isnull(h_part_no,''), @sched_process_id, 				-- mls 6/12/02 SCR 29062
	case when status = 'R' then qty else qty_scheduled end,			-- mls 2/18/03 SCR 30719
        case when status = 'R' then qty else isnull(qty_scheduled_orig, qty_scheduled) end,			-- mls 2/18/03 SCR 30719
      h_location, prod_type, hold_flag, bom_rev, end_sch_date, 
      prod_date, status,    isnull(h_uom, 'EA'), d_qc_no				-- mls 4/16/02 SCR 28749
    FROM  #process_detail 
    WHERE  prod_no = @prod_no  AND  prod_ext = @prod_ext and d_qc_no = @qc_no						
  end
  else
  begin
    INSERT  #process(prod_no,prod_ext,asm_no,sched_process_id,
      process_unit, process_unit_orig, -- Rev 11
      location, prod_type, hold_flag, bom_rev, 
      end_sch_date, prod_date, status, uom, qc_no)		-- mls 8/9/01 start
    select distinct prod_no, prod_ext, 
      isnull(h_part_no,''), @sched_process_id, 				-- mls 6/12/02 SCR 29062
	case when status = 'R' then qty else qty_scheduled end,			-- mls 2/18/03 SCR 30719
        case when status = 'R' then qty else isnull(qty_scheduled_orig, qty_scheduled) end,			-- mls 2/18/03 SCR 30719
      h_location, prod_type, hold_flag, bom_rev, end_sch_date, 
      prod_date, status,    isnull(h_uom, 'EA'), d_qc_no				-- mls 4/16/02 SCR 28749
from
(  select
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
    d.p_qty, d.cost_pct, d.p_line, d.status, 
    isnull(case when h.prod_type = 'R' 
      then case when d.status = 'R' then d.qc_no else 0 end
      else case when h.status = 'R' then isnull((select max(qc_no) from prod_list f 
        where f.prod_no = h.prod_no and f.prod_ext = h.prod_ext),0) else 0 end
      end,0)
  from produce_all h
  join prod_list d on d.prod_no = h.prod_no and d.prod_ext = h.prod_ext
  WHERE h.prod_no = @prod_no  AND  h.prod_ext = @prod_ext and d.direction > 0 and isnull(d.qc_no,0) = @qc_no)
as pd (    prod_no, prod_ext, qty, void, status, hold_flag, h_part_no, qty_scheduled, h_location,
    qty_scheduled_orig, prod_type, bom_rev, end_sch_date, prod_date, h_uom,
    line_no, p_pcs, direction, plan_pcs, pieces, seq_no, scrap_pcs, oper_status, plan_qty,
    used_qty, constrain, d_part_no, d_location, pool_qty, part_type, d_uom, active, eff_date,
    p_qty, cost_pct, p_line, d_status, d_qc_no)
  end

  IF @@rowcount <> 1
  BEGIN
    set rowcount 0
    RaisError 69111 'Production does not exists'
    RETURN
  END									-- mls 8/9/01 end
  set rowcount 0
END

ELSE IF  @sched_id IS NOT NULL
BEGIN
  
  IF @prod_no IS NOT NULL
  BEGIN
    if @compare_schedule_ind = 1
    begin
      
      set rowcount 1
      INSERT  #process(prod_no,prod_ext,process_unit,process_unit_orig,asm_no, -- Rev 11
        location, prod_type, hold_flag, bom_rev, end_sch_date, prod_date, status, uom, qc_no)	-- mls 8/9/01 
      SELECT distinct P.prod_no,P.prod_ext,
	case when P.status = 'R' then P.qty else P.qty_scheduled end,			-- mls 2/18/03 SCR 30719
        case when P.status = 'R' then P.qty else isnull(qty_scheduled_orig, qty_scheduled) end,			-- mls 2/18/03 SCR 30719
        isnull(P.h_part_no,''),  -- Rev 11	-- mls 6/12/02 SCR 29062
        P.h_location, P.prod_type, P.hold_flag, P.bom_rev, P.end_sch_date, P.prod_date, P.status, -- mls 8/9/01
        isnull(P.h_uom,'EA'), P.d_qc_no							-- mls 4/16/02 SCR 28749
      FROM  #process_detail P
      WHERE  P.prod_no = @prod_no  AND  P.prod_ext = @prod_ext and P.d_qc_no = @qc_no 
      set rowcount 0
    end
    else
    begin
      

      INSERT  #process(prod_no,prod_ext,process_unit,process_unit_orig,asm_no, -- Rev 11
        location, prod_type, hold_flag, bom_rev, end_sch_date, prod_date, status, uom, qc_no)	-- mls 8/9/01 
    select distinct prod_no, prod_ext, 
	case when status = 'R' then qty else qty_scheduled end,			-- mls 2/18/03 SCR 30719
        case when status = 'R' then qty else isnull(qty_scheduled_orig, qty_scheduled) end,			-- mls 2/18/03 SCR 30719
      isnull(h_part_no,''), h_location, prod_type, hold_flag, bom_rev, end_sch_date, 
      prod_date, status,    isnull(h_uom, 'EA'), d_qc_no				-- mls 4/16/02 SCR 28749
from
(  select
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
    d.p_qty, d.cost_pct, d.p_line, d.status, 
    isnull(case when h.prod_type = 'R' 
      then case when d.status = 'R' then d.qc_no else 0 end
      else case when h.status = 'R' then isnull((select max(qc_no) from prod_list f 
        where f.prod_no = h.prod_no and f.prod_ext = h.prod_ext),0) else 0 end
      end,0)
  from produce_all h
  join prod_list d on d.prod_no = h.prod_no and d.prod_ext = h.prod_ext
  WHERE  h.prod_no = @prod_no  AND  h.prod_ext = @prod_ext and h.part_no = d.part_no and isnull(d.qc_no,0) = @qc_no)
as pd (    prod_no, prod_ext, qty, void, status, hold_flag, h_part_no, qty_scheduled, h_location,
    qty_scheduled_orig, prod_type, bom_rev, end_sch_date, prod_date, h_uom,
    line_no, p_pcs, direction, plan_pcs, pieces, seq_no, scrap_pcs, oper_status, plan_qty,
    used_qty, constrain, d_part_no, d_location, pool_qty, part_type, d_uom, active, eff_date,
    p_qty, cost_pct, p_line, d_status, d_qc_no)
    end
  END
  ELSE
  BEGIN
    
    INSERT  #process(prod_no,prod_ext,process_unit,process_unit_orig,asm_no, -- Rev 11
      location, prod_type, hold_flag, bom_rev, end_sch_date, prod_date, status, uom, qc_no)	-- mls 8/9/01 
    select distinct prod_no, prod_ext, 
	case when status = 'R' then qty else qty_scheduled end,			-- mls 2/18/03 SCR 30719
        case when status = 'R' then qty else isnull(qty_scheduled_orig, qty_scheduled) end,			-- mls 2/18/03 SCR 30719
      isnull(h_part_no,''), h_location, prod_type, hold_flag, bom_rev, end_sch_date, 
      prod_date, status,    isnull(h_uom, 'EA'), d_qc_no				-- mls 4/16/02 SCR 28749
from
(  select
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
    d.p_qty, d.cost_pct, d.p_line, d.status, 
    isnull(case when h.prod_type = 'R' 
      then case when d.status = 'R' then d.qc_no else 0 end
      else case when h.status = 'R' then isnull((select max(qc_no) from prod_list f 
        where f.prod_no = h.prod_no and f.prod_ext = h.prod_ext),0) else 0 end
      end,0)
  from produce_all h
  join prod_list d on d.prod_no = h.prod_no and d.prod_ext = h.prod_ext
  join sched_location sl on sl.location = h.location and sl.sched_id = @sched_id
  WHERE  h.status in ('N','P','Q','R') and h.void = 'N' and d.direction > 0)
as pd (    prod_no, prod_ext, qty, void, status, hold_flag, h_part_no, qty_scheduled, h_location,
    qty_scheduled_orig, prod_type, bom_rev, end_sch_date, prod_date, h_uom,
    line_no, p_pcs, direction, plan_pcs, pieces, seq_no, scrap_pcs, oper_status, plan_qty,
    used_qty, constrain, d_part_no, d_location, pool_qty, part_type, d_uom, active, eff_date,
    p_qty, cost_pct, p_line, d_status, d_qc_no)
  END
END

ELSE
BEGIN
  RaisError 69112 'There is not enough information to propagate production'
  RETURN
END

CREATE TABLE #plan
  (
  line_id		INT		NULL,
  cell_id		INT		NULL,
  seq_no		VARCHAR(4),
  part_no		VARCHAR(30),
  usage_qty	FLOAT,			
  ave_pool_qty	FLOAT,
  ave_flat_qty	FLOAT,
  ave_unit_qty    FLOAT,
  uom		CHAR(2),
  part_type	CHAR(1),
  active    	CHAR(1) NULL,
  eff_date    	DATETIME NULL
  )



CREATE TABLE #operation_resources
  (
   resource_id VARCHAR(30),
   fixed_flag  CHAR(1),
   build_plan_flat_time FLOAT,
   build_plan_unit_time  FLOAT
  )
create index #or1 on #operation_resources(resource_id, fixed_flag)

DECLARE c_operation_resources CURSOR FOR
  SELECT   OPRES.resource_id,
    OPRES.fixed_flag,
    OPRES.build_plan_flat_time,
    OPRES.build_plan_unit_time
  FROM  #operation_resources OPRES
  ORDER BY OPRES.resource_id, OPRES.fixed_flag


DECLARE c_process CURSOR LOCAL FOR
  SELECT  prod_no, prod_ext,
    sched_process_id,
    process_unit,
    process_unit_orig,
    prod_type,					-- mls 8/9/01 start
    hold_flag,
    location,
    bom_rev,
    end_sch_date,
    prod_date,
    uom,
    status,
    asm_no,  -- Rev 11				-- mls 8/9/01 end
    qc_no
  FROM  #process
  order by prod_no, prod_ext


OPEN c_process

FETCH c_process into @prod_no, @prod_ext,
  @sched_process_id,
  @process_unit,
  @process_unit_orig,
  @asm_type,
  @hold_flag,
  @location ,
  @bom_rev,
  @end_sch_date,
  @prod_date,
  @uom,
  @pstatus,
  @asm_no,
  @qc_no

WHILE @@FETCH_STATUS = 0
BEGIN -- 1
  
  SELECT @source_flag = case when isnull(@hold_flag,'N') = 'Y' then 'H' 
    when @pstatus = 'R' then 'Q' else 'R' end					-- mls 2/20/03 SCR 30719
  select @p_asm_line = 0

  
  IF @sched_process_id IS NULL
  BEGIN
    
    INSERT  sched_process(sched_id,process_unit,process_unit_orig,source_flag,prod_no,prod_ext, qc_no)
    VALUES (@sched_id,@process_unit,@process_unit_orig,@source_flag,@prod_no,@prod_ext, @qc_no)
    
    SELECT  @sched_process_id = @@identity
  END
  ELSE
  BEGIN
    
    UPDATE  sched_process
    SET  process_unit = @process_unit,
      process_unit_orig = @process_unit_orig,
      source_flag = @source_flag
    FROM  sched_process SP
    WHERE  SP.sched_process_id = @sched_process_id

    
    declare @spid int
    select @spid = @sched_process_id
    exec adm_set_sched_item 'D1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,@spid
    DELETE  sched_process_product WHERE  sched_process_id = @spid
    exec adm_set_sched_operation 'D1',NULL,@spid
  END

  
  if @compare_schedule_ind = 1
  begin
    INSERT  sched_process_product(sched_process_id,location,part_no,bom_rev,uom_qty,uom,usage_flag,cost_pct)
    SELECT  @sched_process_id,  	
      PL.d_location,			
      PL.d_part_no,			
      @bom_rev,         			-- mls 8/9/01
      case when PL.status = 'R' 										-- mls 2/20/03
        then case @process_unit when 0 then 0 else PL.used_qty / @process_unit end
       when PL.prod_type = 'R' and PL.d_part_no != @asm_no 
        then case when PL.plan_qty - PL.used_qty <= 0 or PL.plan_qty = 0 then 0 else PL.p_qty * ( (PL.plan_qty - PL.used_qty) / PL.plan_qty) end
        else  PL.p_qty end ,  			-- rev 1.
      IsNull(PL.d_uom,''),		
      CASE				
      WHEN PL.d_location = @location AND PL.d_part_no = @asm_no				-- mls 8/9/01
      THEN 'P'
      ELSE 'B'
      END,
      PL.cost_pct			
    FROM  #process_detail PL (nolock)
    WHERE  PL.prod_no = @prod_no  AND  PL.prod_ext = @prod_ext  AND  PL.direction = 1 and PL.d_qc_no = @qc_no
  end
  else
  begin
    INSERT  sched_process_product(sched_process_id,location,part_no,bom_rev,uom_qty,uom,usage_flag,cost_pct)
    SELECT  @sched_process_id,  	
      PL.location,			
      PL.part_no,			
      @bom_rev,         			-- mls 8/9/01
      case when PL.status = 'R' 										-- mls 2/20/03
        then case @process_unit when 0 then 0 else PL.used_qty / @process_unit end
       when P.prod_type = 'R' and PL.part_no != @asm_no 
        then case when PL.plan_qty - PL.used_qty <= 0 or PL.plan_qty = 0 then 0 else PL.p_qty * ( (PL.plan_qty - PL.used_qty) / PL.plan_qty) end
        else  PL.p_qty end ,  			-- rev 1.
      IsNull(PL.uom,''),		
      CASE				
      WHEN PL.location = @location AND PL.part_no = @asm_no				-- mls 8/9/01
      THEN 'P'
      ELSE 'B'
      END,
      PL.cost_pct			
    FROM  prod_list PL (nolock)
    join produce_all P (nolock) on P.prod_no = PL.prod_no and P.prod_ext = PL.prod_ext
    WHERE  PL.prod_no = @prod_no  AND  PL.prod_ext = @prod_ext  AND  PL.direction = 1 and PL.qc_no = @qc_no
  end

  
  IF @asm_type <> 'J' and @pstatus != 'V'
  BEGIN
    INSERT  sched_item(sched_id,location,part_no,done_datetime,uom_qty,uom,source_flag,sched_process_id)
    SELECT  @sched_id,				
      @location,				 -- mls 8/9/01
      @asm_no,				 -- mls 8/9/01
      IsNull(@end_sch_date,@prod_date),	
      @process_unit_orig,								   -- mls 8/9/01
						-- rev 1
      @uom,				
      'M',				
      @sched_process_id			
  END

   
  SELECT  @operation_step = 0,
    @operation_type = 'M',
    @ave_flat_time = 0.0,
    
    @ave_unit_time = 0.0
    

  
if @compare_schedule_ind = 1
begin
  DECLARE c_prod_list CURSOR STATIC LOCAL FOR
    SELECT PL.line_no,
    PL.p_line,
    PL.seq_no,
    PL.d_location,
    PL.d_part_no,
    case when IsNull(PL.pool_qty,1.0) < 0 then 0 else IsNull(PL.pool_qty,1.0) end,
    PL.plan_qty,
    PL.d_uom,
    PL.plan_pcs,
    CASE PL.oper_status WHEN 'X' Then 'X' When 'S' Then 'X' Else 'U' END,  -- rev 1
    case when (PL.im_status = 'R' and PL.p_qty = 0) or PL.qty_scheduled = 0 then 0 else PL.plan_qty / PL.qty_scheduled end, -- #13 -- MLS 3/26/04 SCR 32607
    PL.part_type,   
    PL.pieces,  
    PL.scrap_pcs,  
    CASE PL.plan_qty WHEN 0.0 THEN 0.0 ELSE PL.used_qty / PL.plan_qty END,
    PL.active,
    PL.eff_date,
    @asm_no,
    im_status,
    im_type_code,
    il_lead_time,
    case when PL.part_type = 'X' then 'M'
      when PL.part_type = 'C' then 'C'
      when isnull(im_type_code,'') = '#IGNORE' then 'X'
      when isnull(im_status,'') = 'R' then 'R'
      else 'P'
    end  -- part_type   
    FROM  #process_detail PL
    WHERE  PL.prod_no=@prod_no  AND  PL.prod_ext=@prod_ext 
      AND  (  PL.constrain = 'N' OR  PL.constrain IS NULL OR  (PL.seq_no != '****' or prod_type = 'R'))
      AND  PL.direction = -1 
    order by PL.p_line, PL.seq_no, PL.line_no					-- mls 1/24/02 SCR 24251
end
else
begin
  DECLARE c_prod_list CURSOR STATIC LOCAL FOR
    SELECT PL.line_no,
    PL.p_line,
    PL.seq_no,
    PL.location,
    PL.part_no,
    case when IsNull(PL.pool_qty,1.0) < 0 then 0 else IsNull(PL.pool_qty,1.0) end,
    PL.plan_qty,
    PL.uom,
    PL.plan_pcs,
    CASE PL.oper_status WHEN 'X' Then 'X' When 'S' Then 'X' Else 'U' END,  -- rev 1
    case when (IM.status = 'R' and PL.p_qty = 0) or @process_unit = 0 then 0 else PL.plan_qty / @process_unit end, -- #13 -- mls 3/26/04 SCR 32607
    PL.part_type,   
    PL.pieces,  
    PL.scrap_pcs,  
    CASE PL.plan_qty WHEN 0.0 THEN 0.0 ELSE PL.used_qty / PL.plan_qty END,
    PL.active,
    PL.eff_date,
    @asm_no,
    IM.status,
    IM.type_code,
    IL.lead_time,
    case when PL.part_type = 'X' then 'M'
      when PL.part_type = 'C' then 'C'
      when isnull(IM.type_code,'') = '#IGNORE' then 'X'
      when isnull(IM.status,'') = 'R' then 'R'
      else 'P'
    end  -- part_type   
    FROM  prod_list PL
    left outer join inv_master IM on IM.part_no = PL.part_no 
    left outer join inv_list IL on IL.part_no = PL.part_no and IL.location = PL.location
    WHERE  PL.prod_no=@prod_no  AND  PL.prod_ext=@prod_ext 
      AND  (  PL.constrain = 'N' OR  PL.constrain IS NULL OR  PL.seq_no <> '****' or @asm_type = 'R')
      AND  PL.direction = -1 
    order by PL.p_line, PL.seq_no, PL.line_no					-- mls 1/24/02 SCR 24251
end


  OPEN c_prod_list

  FETCH c_prod_list into
    @line_no,
      @p_line,
      @seq_no,
      @location,
      @part_no,
      @pool_qty,
      @uom_qty,
      @uom,
      @ave_flat_qty,
      @oper_status,
      @p_qty,
      @part_type_pl,
      @complete_qty,
      @discard_qty,
      @usage_qty,
      @active,
      @eff_date ,
      @p_asm_no,
      @status,
      @resource_type,
      @i_lead_time,   
      @part_type

  WHILE @@FETCH_STATUS = 0
  BEGIN --2
    if @p_line != @p_asm_line and @p_line > 0
    begin
      if @asm_type = 'R'
        select @p_asm_no = @asm_no
      else
      begin
        if @compare_schedule_ind = 1
          select @p_asm_no = isnull((select min(d_part_no) from #process_detail
            where prod_no = @prod_no and prod_ext = @prod_ext and line_no = @p_line 
              and d_qc_no = @qc_no and constrain = 'C'),@asm_no)
        else
          select @p_asm_no = isnull((select min(part_no) from prod_list (nolock)
            where prod_no = @prod_no and prod_ext = @prod_ext and line_no = @p_line and constrain = 'C'),@asm_no)
      end

      select @p_asm_line = @p_line
    end

    
    IF @status is not NULL OR @part_type_pl = 'X' 
    BEGIN --3 
      
      
      

      IF (@part_type = 'R')
      BEGIN
        IF EXISTS(SELECT 1 FROM resource_group WHERE group_part_no = @part_no)
        BEGIN
          SELECT @part_no = resource_part_no FROM resource_group
          WHERE group_part_no = @part_no AND 
            use_order = (SELECT MIN(use_order) FROM resource_group WHERE group_part_no = @part_no)
        END
      END
      

      SELECT @ave_flat_time_plan = 0.0
      SELECT @ave_unit_time_plan = 0.0

      
      
      IF @part_type = 'R' AND @operation_type = 'M'
      
      
      BEGIN
        IF @p_qty = 0.0    
        BEGIN
          SELECT @ave_flat_time_plan = @uom_qty
          SELECT @fixed = 'Y'
        END
        ELSE
        BEGIN
          SELECT @ave_unit_time_plan = @p_qty   -- Rev 10
          SELECT @fixed = 'N'
        END
        -- Save the resoures for this operation.
        INSERT #operation_resources
          (resource_id, fixed_flag, build_plan_flat_time, build_plan_unit_time)
        VALUES
        (
        @part_no,
        @fixed,
        @ave_flat_time_plan,
        @ave_unit_time_plan
        )
      END
      
      ELSE
      BEGIN
        SELECT @ave_unit_time_plan = @p_qty
      END

      
      INSERT #plan(line_id,cell_id,seq_no,part_no,usage_qty,ave_pool_qty, 
        ave_flat_qty,ave_unit_qty,uom,part_type,active,eff_date)
      VALUES (@line_no,@p_line,@seq_no,@part_no,@usage_qty,@pool_qty,@ave_flat_time_plan,@ave_unit_time_plan,
        IsNull(@uom,''),@part_type,@active,@eff_date)

      
      IF @pool_qty <= 0.0
        SELECT  @pool_qty = 1.0

      
      IF @status = 'Q'
      BEGIN
        
        SELECT  @operation_type = 'O',
          @ave_flat_time = 24.0 * isnull(@i_lead_time,0),
          @ave_unit_time = 0.0,
          @lag_qty = 0.0
      END

      
      IF @asm_type <> 'M' AND ((@ave_flat_qty > 0.0 AND @part_type = 'R') OR @status = 'Q')
      BEGIN
        
        SELECT  @operation_step=@operation_step+1
        IF @status <> 'Q'
        BEGIN
          
          OPEN c_operation_resources
  
          SELECT @operation_resource_flat_time = 0.0
          SELECT @operation_resource_unit_time = 0.0
          SELECT @ave_unit_time = 0.0  -- Operation unit run-time
          SELECT @ave_flat_time = 0.0  -- Operation flat run-time
 
          FETCH c_operation_resources into @build_plan_resource,@build_plan_fixed_flag,@build_plan_flat_time,@build_plan_unit_time
          SELECT @operation_previous_resource = @build_plan_resource

          WHILE @@fetch_status = 0
          BEGIN
            IF @build_plan_resource = @operation_previous_resource
            BEGIN
              IF @build_plan_fixed_flag = 'N'
              BEGIN
                IF @build_plan_unit_time > @operation_resource_unit_time
                  SELECT @operation_resource_unit_time = @build_plan_unit_time
              END
              ELSE
              BEGIN
                IF @build_plan_flat_time > @operation_resource_flat_time
                  SELECT @operation_resource_flat_time = @build_plan_flat_time
              END
            END
            ELSE
            BEGIN
              IF @operation_resource_unit_time = 0.0
              BEGIN
                IF @operation_resource_flat_time > @ave_flat_time
                  SELECT @ave_flat_time = @operation_resource_flat_time                  
              END
  
              SELECT @operation_resource_flat_time = 0.0
              SELECT @operation_resource_unit_time = 0.0
  
              IF @build_plan_fixed_flag = 'N'
                SELECT @operation_resource_unit_time = @build_plan_unit_time
              ELSE
                SELECT @operation_resource_flat_time = @build_plan_flat_time
            END
            -- For each non-fixed fetched, track the largest unit time.
            IF @build_plan_fixed_flag = 'N'
            BEGIN
              IF @build_plan_unit_time > @ave_unit_time
                SELECT @ave_unit_time = @build_plan_unit_time
            END

            SELECT @operation_previous_resource = @build_plan_resource
            FETCH c_operation_resources into @build_plan_resource,@build_plan_fixed_flag,@build_plan_flat_time,@build_plan_unit_time
          END  -- end of while loop

          IF @operation_resource_unit_time = 0.0
          BEGIN
            IF @operation_resource_flat_time > @ave_flat_time
             SELECT @ave_flat_time = @operation_resource_flat_time                  
          END
                 
          CLOSE c_operation_resources
          DELETE #operation_resources

          SELECT @lag_qty = NULL
  
          
          SELECT @lag_qty = WP.lag_qty
          FROM what_part WP
          WHERE WP.seq_no = @next_seq AND WP.asm_no = @p_asm_no AND WP.part_no = @part_no

          -- If did not find it in WP then maybe WP has the resource group identifier.
          IF @lag_qty IS NULL
          BEGIN
            SELECT @lag_qty = WP.lag_qty
            FROM what_part WP
            WHERE WP.seq_no = @next_seq AND WP.asm_no = @p_asm_no
            AND WP.part_no = (SELECT RG.group_part_no FROM resource_group RG WHERE RG.resource_part_no = @part_no)
          END
        END -- end of "if @status <> 'Q'"
        
        
        INSERT  sched_operation(sched_process_id,operation_step,location,ave_flat_qty,
          ave_flat_time, ave_unit_qty,ave_wait_qty, ave_unit_time, operation_type,complete_qty,discard_qty,operation_status)  -- rev 1
        VALUES  (@sched_process_id,@operation_step,@location,@ave_flat_qty,@ave_flat_time,
          0.0, IsNull(@lag_qty,0.0),@ave_unit_time, @operation_type,@complete_qty,@discard_qty,@oper_status)

        
        SELECT  @sched_operation_id=@@identity

        
        
        INSERT  sched_operation_plan(sched_operation_id,line_no,line_id,cell_id,seq_no,part_no,
          usage_qty,ave_pool_qty,ave_flat_qty,ave_unit_qty, uom,status,active,eff_date)  
        SELECT  @sched_operation_id,P.line_id,P.line_id,P.cell_id,P.seq_no,P.part_no,P.usage_qty,
          P.ave_pool_qty,P.ave_flat_qty,P.ave_unit_qty,P.uom, P.part_type,P.active,P.eff_date  
        FROM  #plan P

        
        DELETE  #plan

        
        SELECT  @operation_type = 'M'
      END
    END

    
  FETCH c_prod_list into
    @line_no,
      @p_line,
      @seq_no,
      @location,
      @part_no,
      @pool_qty,
      @uom_qty,
      @uom,
      @ave_flat_qty,
      @oper_status,
      @p_qty,
      @part_type_pl,
      @complete_qty,
      @discard_qty,
      @usage_qty,
      @active,
      @eff_date ,
      @p_asm_no,
      @status,
      @resource_type,
      @i_lead_time,
      @part_type
  END -- end of WHILE @@FETCH_STATUS = 0

  CLOSE c_prod_list
deallocate c_prod_list
  
  IF EXISTS(SELECT * FROM #plan)
  BEGIN
    

    
    SELECT  @operation_step=@operation_step+1
      
    
    OPEN c_operation_resources
  
    SELECT @operation_resource_flat_time = 0.0
    SELECT @operation_resource_unit_time = 0.0
    SELECT @ave_unit_time = 0.0  -- Operation unit run-time
    SELECT @ave_flat_time = 0.0  -- Operation flat run-time
 
    FETCH c_operation_resources into @build_plan_resource,@build_plan_fixed_flag,@build_plan_flat_time,@build_plan_unit_time
    SELECT @operation_previous_resource = @build_plan_resource

    WHILE @@fetch_status = 0
    BEGIN
      IF @build_plan_resource = @operation_previous_resource
      BEGIN
        IF @build_plan_fixed_flag = 'N'
        BEGIN
          IF @build_plan_unit_time > @operation_resource_unit_time
            SELECT @operation_resource_unit_time = @build_plan_unit_time
        END
        ELSE
        BEGIN
          IF @build_plan_flat_time > @operation_resource_flat_time
          SELECT @operation_resource_flat_time = @build_plan_flat_time
        END
      END
      ELSE
      BEGIN
        IF @operation_resource_unit_time = 0.0
        BEGIN
          IF @operation_resource_flat_time > @ave_flat_time
            SELECT @ave_flat_time = @operation_resource_flat_time                  
        END
  
        SELECT @operation_resource_flat_time = 0.0
        SELECT @operation_resource_unit_time = 0.0
 
        IF @build_plan_fixed_flag = 'N'
          SELECT @operation_resource_unit_time = @build_plan_unit_time
        ELSE
          SELECT @operation_resource_flat_time = @build_plan_flat_time
      END
      -- For each non-fixed fetched, track the largest unit time.
      IF @build_plan_fixed_flag = 'N'
      BEGIN
        IF @build_plan_unit_time > @ave_unit_time
          SELECT @ave_unit_time = @build_plan_unit_time
      END

      SELECT @operation_previous_resource = @build_plan_resource
      FETCH c_operation_resources into @build_plan_resource,@build_plan_fixed_flag,@build_plan_flat_time,@build_plan_unit_time
    END  -- end of while @@fetch_status loop

    IF @operation_resource_unit_time = 0.0
    BEGIN
      IF @operation_resource_flat_time > @ave_flat_time
        SELECT @ave_flat_time = @operation_resource_flat_time                  
    END
                 
    CLOSE c_operation_resources
    DELETE #operation_resources  

    
    SELECT @lag_qty = NULL

    SELECT @lag_qty = WP.lag_qty
    FROM what_part WP
    WHERE WP.seq_no = @next_seq AND WP.asm_no = @asm_no AND WP.part_no = @part_no

    -- If did not find it in WP then maybe WP has the resource group identifier.
    IF @lag_qty IS NULL
    BEGIN
      SELECT @lag_qty = WP.lag_qty
      FROM what_part WP
      WHERE WP.seq_no = @next_seq AND WP.asm_no = @asm_no AND
        WP.part_no = (SELECT RG.group_part_no FROM resource_group RG WHERE RG.resource_part_no = @part_no)
    END

    
    
    INSERT  sched_operation(sched_process_id,operation_step,location,ave_flat_qty,ave_unit_qty,ave_wait_qty,ave_flat_time,
      ave_unit_time, operation_type,complete_qty,discard_qty)
    VALUES  (@sched_process_id,@operation_step,@location,@ave_flat_qty,0.0,IsNull(@lag_qty,0.0),@ave_flat_time, @ave_unit_time,
      @operation_type,@complete_qty,@discard_qty)

    
    SELECT  @sched_operation_id=@@identity

    
    
    INSERT  sched_operation_plan(sched_operation_id,line_no,line_id,cell_id,seq_no,part_no,
      usage_qty,ave_pool_qty,ave_flat_qty,ave_unit_qty,uom,status,active,eff_date)  
    SELECT  @sched_operation_id,P.line_id,P.line_id,P.cell_id,P.seq_no,P.part_no,P.usage_qty,
      P.ave_pool_qty,P.ave_flat_qty,P.ave_unit_qty,P.uom,P.part_type,P.active,P.eff_date  
    FROM  #plan P

    
    DELETE  #plan
  END -- end of IF EXISTS(SELECT * FROM #plan)

  
  exec fs_calculate_opn_completion @sched_id, @prod_no, @prod_ext, @compare_schedule_ind, @qc_no
  

  FETCH c_process into @prod_no, @prod_ext,
    @sched_process_id,
    @process_unit,
    @process_unit_orig,
    @asm_type,
    @hold_flag,
    @location ,
    @bom_rev,
    @end_sch_date,
    @prod_date,
    @uom,
    @pstatus,
    @asm_no,
    @qc_no
END

CLOSE c_process
DEALLOCATE c_process


DROP TABLE #plan
DROP TABLE #process
DEALLOCATE c_operation_resources
DROP TABLE #operation_resources

RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_build_sched_process] TO [public]
GO
