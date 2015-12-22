SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



--  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[fs_build_process_plan]
  (
  @asm_no  VARCHAR(30),
  @location VARCHAR(10) = NULL,
  @sched_id INT = NULL,
  @asm_qty FLOAT = 0.0,
  @sched_process_id INT = NULL OUT,
  @read_AsNeeded int = 0						-- mls 7/28/04 SCR 33323
  )
AS
BEGIN

DECLARE  @asm_type  CHAR(1),  
  @operation_step  INT,
  @operation_type  CHAR(1),
  @ave_flat_time  FLOAT,
  @ave_unit_time  FLOAT,
  @part_id  INT,
  @seq_no    VARCHAR(4),
  @part_no  VARCHAR(30),
  @uom_qty  DECIMAL(20,8),
  @uom    CHAR(2),
  @fixed    CHAR(1),
  @cell_flag  CHAR(1),
  @status    CHAR(1),
  @part_type  CHAR(1),
  @resource_type  VARCHAR(10),
  @ave_pool_qty  FLOAT,
  @ave_flat_qty  FLOAT,
  @ave_unit_qty  FLOAT,
  @ave_plan_qty  FLOAT,
  @ave_wait_qty  FLOAT,
  @line_id  INT,
  @cell_id  INT,
  @build_plan_resource VARCHAR(30),
  @build_plan_flat_time FLOAT,
  @build_plan_unit_time FLOAT,
  @build_plan_fixed_flag CHAR(1),
  @operation_resource_flat_time FLOAT,
  @operation_resource_unit_time FLOAT,
  @operation_previous_resource VARCHAR(30),
  @active     CHAR(1),
  @eff_date   DATETIME,
  @bom_rev    VARCHAR(10),
  @im_status  char(1)


DECLARE @yield_pct  FLOAT,
  @adm_qty_adj_yield  FLOAT

declare @test_resource_type   char (1),
  @test_resource     char(30),
  @resource_new_code   char(30),
  @test_step     int,
  @alphabet varchar(26)


declare @ret_mult int, @clvl int 


select @ret_mult = charindex('%',@asm_no),
   @alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


if @sched_id is not null and @ret_mult != 0
begin
  RaisError 63010 'You cannot use wildcarded part when sched_id is also used'
  return
end

if @ret_mult = 0
begin
  select @read_AsNeeded = 0						-- mls 7/28/04 SCR 33323		
  SELECT @yield_pct = IM.yield_pct,  -- rev 1--add yield percent
    @asm_type = IM.status
  FROM  dbo.inv_master IM (NOLOCK)
  WHERE  IM.part_no = @asm_no

  IF @@rowcount <> 1
  BEGIN
    IF @sched_id IS NOT NULL  
      SELECT  @sched_process_id = NULL
    ELSE
      RaisError 63019 'Item does not exist in inventory master'
    RETURN
  END

  
  IF NOT EXISTS(SELECT 1 FROM dbo.what_part WP (nolock) WHERE WP.asm_no = @asm_no)
  BEGIN
    IF @sched_id IS NOT NULL
      SELECT  @sched_process_id = NULL
    ELSE
      RaisError 62319 'Item does not have a build plan'
    RETURN
  END

  
  IF @asm_type = 'V'
  BEGIN
    IF @sched_id IS NOT NULL
      SELECT  @sched_process_id = NULL
    ELSE
      RaisError 63018 'Item is non-quantity bearing and has no build plan'
    RETURN
  END
end -- ret_mult = 0

CREATE TABLE #part (
  part_id    INT IDENTITY,
  asm_no    varchar(30),
  asm_revision varchar(10) NULL,
  asm_uom char(2),
  asm_ind  int,
  asm_status char(1),
  operation_step  int,
  seq_no    VARCHAR(4),
  part_no    VARCHAR(30),
  cost_pct float,
  ave_pool_qty  FLOAT,
  uom_qty    FLOAT,
  uom    CHAR(2),
  fixed    CHAR(1),
  ave_plan_qty  FLOAT,
  ave_wait_qty  FLOAT,
  ave_flat_qty    FLOAT,
  ave_unit_qty    FLOAT,
  ave_flat_time   FLOAT,
  ave_unit_time  FLOAT,
  status    CHAR(1),
  type_code  VARCHAR(10),
  cell_flag  CHAR(1),
  cell_id    INT NULL default(0),
  active      CHAR(1) NULL,     
  eff_date    DATETIME NULL, 
  part_type  char(1),
  operation_type char(1),
  oper_ind int,
  cell_lvl int default(0),
  cell_order varchar(255) default(''),
  sort_order varchar(3000) default('')
)

create index part2 on #part (part_id)
create index part3 on #part (oper_ind,asm_no,operation_step, ave_plan_qty, ave_wait_qty,operation_type)
create index part4 on #part (asm_no, oper_ind, seq_no)
create index part5 on #part (asm_ind)
create index part6 on #part (asm_no, operation_step, part_id)
create index part7 on #part (cell_lvl,cell_flag)
create index part8 on #part (part_type,operation_type)
create index part9 on #part (asm_no, operation_step, part_type)

create table #part_order (
  asm_no varchar(30),
  operation_step int,
  part_id int,
  seq_no varchar(4) null,
  sort_order varchar(3000) null,
  oper_seq varchar(2) NULL,
  line_cnt int NULL,
  line_seq int NULL,
  row_id int identity(1,1))

create index #poa on #part_order(asm_no, operation_step,row_id)
create Index #pob on #part_order(part_id,seq_no)

CREATE TABLE #operation (
  asm_no varchar(30),
  operation_step  INT,
  location  VARCHAR(10)  NULL,
  ave_flat_qty  FLOAT,
  ave_unit_qty  FLOAT,
  ave_wait_qty  FLOAT,
  ave_flat_time  FLOAT,
  ave_unit_time  FLOAT,
  operation_type  CHAR(1)
  )
create index operation1 on #operation(asm_no,operation_step)


CREATE TABLE #plan (
  line_id    INT    IDENTITY,
  asm_no    VARCHAR(30),
  part_id    int,
  cell_id    INT    NULL,
  operation_step  INT    NULL,
  seq_no    VARCHAR(4),
  part_no    VARCHAR(30),
  ave_pool_qty  FLOAT,
  ave_flat_qty  FLOAT,
  ave_unit_qty  FLOAT,
  uom    CHAR(2),
  part_type  CHAR(1),
  active      CHAR(1) NULL,    
  eff_date    DATETIME NULL,   
  operation_type char(1),
  fixed_flag char(1)
  )
create index plan1 on #plan(part_id,line_id)
create index plan2 on #plan(cell_id)


if @read_AsNeeded = 0							-- mls 7/28/04 SCR 33323
begin
INSERT  #part  (
  asm_no,
  asm_ind,
  asm_uom,
  asm_revision,
  asm_status,
  operation_step,
  seq_no,      
  part_no,    
  cost_pct,
  ave_pool_qty,    
  uom_qty,    
  uom,      
  fixed,      
  ave_plan_qty,    
  ave_wait_qty,    
  ave_flat_qty,     
  ave_unit_qty,      
  ave_flat_time,      
  ave_unit_time,      
  status,      
  type_code,    
  cell_flag,    
  active,      
  eff_date,     
  part_type,
  operation_type,
  oper_ind ,
  sort_order)
SELECT  
  WP.asm_no,
  case when ASM.status <> 'M' then 1 else 0 end, 
  ASM.uom,
  isnull((select max(revision) from inv_revisions IR (nolock)
    where IR.part_no = WP.asm_no),NULL),
  ASM.status,
  1,
  WP.seq_no,    
  WP.part_no,    
  WP.cost_pct,
  case when IsNull(WP.pool_qty,1.0) < 0 then 0 else IsNull(WP.pool_qty,1.0) end ,
  WP.qty,      
  WP.uom,      
  WP.fixed,    
  IsNull(WP.plan_pcs,0.0),
  IsNull(WP.lag_qty,0.0),  
  case when WP.fixed = 'Y' then WP.qty else 0 end,
  case when WP.fixed = 'Y' then 0 else WP.qty end,
  case when IM.status = 'Q' then isnull(IL.lead_time,0) * 24 else 0 end,
  0,
  IM.status,    
  IM.type_code,    
  case WP.active when 'M' then 'N' else WP.constrain end,  
  WP.active,      
  WP.eff_date,     
  case when WP.constrain = 'Y' then 'C'
    when IM.type_code = '#IGNORE' then 'X'
    when IM.status = 'R' then 'R'
    else 'P' end  part_type,
  case when IM.status = 'Q' then 'O' else 'M' end,
  case when ASM.status != 'M' and WP.active != 'M' and ((IsNull(WP.plan_pcs,0.0) > 0
    and WP.constrain != 'Y' and IM.type_code != '#IGNORE' and
      IM.status = 'R') or IM.status = 'Q') 
    then 1 else 0 end,
  WP.seq_no + replicate(' ',5-datalength(WP.seq_no)) + '.'
FROM dbo.what_part WP (NOLOCK)
join dbo.inv_master IM (NOLOCK) ON IM.part_no = WP.part_no and isnull(IM.void,'N') = 'N'
left outer join dbo.inv_list IL (NOLOCK) on IL.part_no = WP.part_no and IL.location = @location
join inv_master ASM (NOLOCK) ON ASM.part_no = WP.asm_no and ASM.status != 'V'
WHERE WP.asm_no like @asm_no AND WP.active IN ('A','B','U','M')
AND  WP.location IN (@location,'ALL')
ORDER BY WP.asm_no, WP.seq_no
end

select @clvl = 0
while @clvl < 11
begin
  INSERT  #part(
    asm_no,
    asm_ind,
    asm_uom,
    asm_revision,
    asm_status,
    operation_step,
    cost_pct,
    active,
    seq_no,
    part_no,
    ave_pool_qty,
    uom_qty,
    uom,
    fixed,
    ave_plan_qty,
    ave_wait_qty,
    ave_flat_qty,     
    ave_unit_qty,      
    ave_flat_time,
    ave_unit_time,
    status,
    type_code,
    cell_flag,
    cell_id,
    part_type,
    operation_type,
    oper_ind,
    cell_lvl,
    cell_order, sort_order)
  SELECT  
    p.asm_no,
    p.asm_ind,
    p.asm_uom,
    p.asm_revision,
    p.asm_status,
    p.operation_step,
    WP.cost_pct,
    WP.active,
    WP.seq_no,      
    WP.part_no,      
    IsNull(WP.pool_qty,1.0),  
    CASE WP.fixed WHEN 'Y' THEN WP.qty ELSE WP.qty * p.uom_qty END,
    WP.uom,        
    CASE p.fixed WHEN 'Y' THEN 'Y' ELSE WP.fixed END,
    IsNull(WP.plan_pcs,0.0),  
    IsNull(WP.lag_qty,0.0),    
    case when WP.fixed = 'Y' then WP.qty 						-- mls 3/3/03 SCR 30784 start
      when p.fixed = 'Y' then 
        WP.qty * p.uom_qty else 0 end ave_flat_qty,
    case when WP.fixed = 'Y' then 0
      when p.fixed = 'Y' then 0 else WP.qty * p.uom_qty end ave_unit_qty,		-- mls 3/3/03 SCR 30784 end
    isnull(IL.lead_time,0) * 24,
    0,
    IM.status,      
    IM.type_code,      
    WP.constrain,      
    p.part_id,      
    case when WP.constrain = 'Y' then 'C'
      when IM.type_code = '#IGNORE' then 'X'  
      when IM.status = 'R' then 'R'
      else 'P' end,
    case when IM.status = 'Q' or WP.active = 'M' then 'O' else 'M' end,
  case when ASM.status != 'M' and WP.active != 'M' and ((IsNull(WP.plan_pcs,0.0) > 0
    and WP.constrain != 'Y' and IM.type_code != '#IGNORE' and
      IM.status = 'R') or IM.status = 'Q') 
    then 1 else 0 end,
    @clvl + 1,
    cell_order + right(replicate('0',10) + convert(varchar(10),p.part_id),10),
    sort_order + WP.seq_no + replicate(' ',5-datalength(WP.seq_no)) + '.'
    FROM  dbo.what_part WP (NOLOCK)
    join #part p on p.part_no = WP.asm_no and p.cell_flag = 'Y' and p.cell_lvl = @clvl
    join dbo.inv_master IM (NOLOCK) ON IM.part_no = WP.part_no and isnull(IM.void,'N') = 'N'
join inv_master ASM (NOLOCK) ON ASM.part_no = WP.asm_no and ASM.status != 'V'
    left outer join dbo.inv_list IL (NOLOCK) on IL.part_no = WP.part_no and IL.location = @location
    WHERE  WP.active IN ('A','B','U') AND WP.location IN (@location,'ALL')
    ORDER BY WP.asm_no, WP.seq_no

if @@rowcount = 0 select @clvl = 11
  select @clvl = @clvl + 1
end

update p
set operation_step =
  isnull((select count(*) from #part w2
    where w2.asm_no = p.asm_no and w2.sort_order < p.sort_order and oper_ind = 1),0) + 1
from #part p
where asm_ind = 1

update p
set oper_ind = case when p.sort_order = 
  (select max(p2.sort_order) from #part p2 
   where p2.asm_no = p.asm_no and p2.operation_step = p.operation_step) then 1 else 0 end
from #part p

INSERT  #operation(asm_no, operation_step,location,ave_flat_qty,ave_unit_qty,ave_wait_qty,
  ave_flat_time,ave_unit_time,operation_type)
select asm_no, operation_step,@location,0,ave_plan_qty,ave_wait_qty,
  max(isnull(a1,0)),max(isnull(a2,0)),operation_type
from #part p1
left outer join (select p2.asm_no, p2.operation_step, p2.part_no,
  case max(p2.ave_unit_qty) when 0 then max(p2.ave_flat_qty) else 0 end 'a1', max(p2.ave_unit_qty) 'a2'
  from #part p2
  where p2.part_type = 'R' and p2.operation_type = 'M'
  group by asm_no, operation_step, part_no) as t1(a,o,r,a1,a2)
  on p1.asm_no = t1.a and p1.operation_step = t1.o
where p1.oper_ind = 1
group by p1.asm_no, p1.operation_step, p1.ave_plan_qty, p1.ave_wait_qty,p1.operation_type

insert #part_order (asm_no, operation_step, part_id, sort_order)
select distinct p.asm_no, p.operation_step, p.part_id, p.sort_order
from #part p
join inv_master m on m.part_no = p.asm_no and m.status = 'H'
join #part p1 on p1.asm_no = p.asm_no and p1.part_type = 'C'
where p.part_type != 'C' 
order by p.asm_no, p.sort_order

    update p
    set oper_seq = 
      case when operation_step < 10 then '0' + convert(char(1),operation_step)
        when operation_step < 100 then convert(char(2),operation_step)
        else substring(@alphabet,(floor((operation_step - 100)/10) +1),1) + 
          convert(varchar(1),operation_step - (floor((operation_step)/10) * 10)) end,
      line_cnt = isnull((select count(*) from #part_order p1 where p1.asm_no = p.asm_no and p1.operation_step = p.operation_step ),0),
      line_seq = isnull((select count(*) from #part_order p1 where p1.asm_no = p.asm_no and p1.row_id <= p.row_id and p1.operation_step = p.operation_step ),0)
    from #part_order p

    update p
    set line_seq = 
      case when line_cnt < 10 then line_seq * 10
        when floor(100/(line_cnt+1)) > 0 then line_seq * floor(100/(line_cnt+1))
        else line_seq end
    from #part_order p

    update p
    set seq_no = oper_seq + 
      case when line_seq < 10 then '0' + convert(char(1),line_seq)
        when line_seq < 100 then convert(char(2),line_seq)
        else substring(@alphabet,(floor((line_seq - 100)/10) +1),1) + 
          convert(varchar(1),line_seq - (floor((line_seq)/10) * 10)) end
    from #part_order p

if @ret_mult = 0
begin
  IF NOT EXISTS(SELECT 1 FROM #operation)
  BEGIN
    IF @sched_id IS NULL
      RaisError 62318 'Build plan is invalid for this location'
    ELSE
      SELECT  @sched_process_id = NULL

    RETURN
  END

  if @sched_id is not null
  begin
    select @bom_rev = isnull((select max(revision) 
      from inv_revisions IR where IR.part_no = @asm_no),NULL)

    INSERT #plan (asm_no, seq_no, part_id, part_no, ave_pool_qty,
      ave_flat_qty, ave_unit_qty, uom, part_type, cell_id, active,
      eff_date, operation_type, fixed_flag, operation_step)
    select asm_no, seq_no, part_id, part_no, ave_pool_qty, ave_flat_qty,
      ave_unit_qty, uom, part_type, cell_id, active, eff_date, operation_type,
      fixed, operation_step
    from #part
    order by  sort_order

    update p
    set cell_id = p1.line_id
    from #plan p, #plan p1
    where p.cell_id = p1.part_id and p.cell_id > 0

  
    select @adm_qty_adj_yield = @asm_qty
    select @yield_pct = IsNull(@yield_pct, 0.00)
    if @yield_pct <> 0.00
    begin
      select @adm_qty_adj_yield = ((100/@yield_pct) * @asm_qty)  -- apply yield percent
      select @adm_qty_adj_yield = CEILING(@adm_qty_adj_yield)      -- round up
    end
    

    INSERT  dbo.sched_process(sched_id,process_unit,process_unit_orig,source_flag)  
    VALUES  (@sched_id,@adm_qty_adj_yield,@asm_qty,'P')    -- rev 1:  add process_unit_orig

    SELECT  @sched_process_id=@@identity
    
    INSERT  dbo.sched_process_product(sched_process_id,location,part_no,uom_qty,uom,
      usage_flag,cost_pct,bom_rev)
    SELECT  @sched_process_id,@location,P.part_no,P.uom_qty,P.uom,'B', P.cost_pct,@bom_rev
    FROM  #part P, dbo.inv_master IM
    WHERE  IM.part_no = P.part_no and P.active = 'M'

    INSERT  dbo.sched_process_product(sched_process_id,location,part_no,uom_qty,uom,
      usage_flag,cost_pct,bom_rev)
    SELECT  @sched_process_id,@location,IM.part_no,P.uom_qty,P.uom,'B',
      P.cost_pct,@bom_rev
    FROM  #part P, dbo.inv_master IM
    WHERE  IM.part_no = P.part_no and P.active = 'M'
    SELECT  @sched_process_id,@location,IM.part_no,1.0,IM.uom,'P',
      100.0-IsNull((SELECT SUM(P.cost_pct) FROM #part P where P.asm_no = IM.part_no
      and P.active = 'M'),0.0), @bom_rev
    FROM  dbo.inv_master IM (NOLOCK)
    WHERE  IM.part_no = @asm_no 

    
    INSERT  dbo.sched_operation (
      sched_process_id,
      operation_step,
      location,
      ave_flat_qty,
      ave_unit_qty,
      ave_wait_qty,
      ave_flat_time,
      ave_unit_time,
      operation_type,
      operation_status )
    SELECT  @sched_process_id,  
      O.operation_step,  
      O.location,    
      O.ave_flat_qty,    
      O.ave_unit_qty,    
      O.ave_wait_qty,    
      O.ave_flat_time,  
      O.ave_unit_time,  
      O.operation_type,  
      'U'      
    FROM  #operation O

    DECLARE c_resource_test CURSOR FOR
    select   P.part_type, P.part_no, P.operation_step
    FROM  #plan P,
      dbo.sched_operation SO
    WHERE  SO.sched_process_id = @sched_process_id
    AND  P.operation_step = SO.operation_step

    open c_resource_test
    fetch c_resource_test into @test_resource_type, @test_resource, @test_step

    while @@fetch_status = 0 
    begin
      if (@test_resource_type = 'R') 
      begin    --if it is a resource
        if exists(select group_part_no from resource_group where group_part_no = 
          @test_resource) 
        begin
          select @resource_new_code = resource_part_no from resource_group
          where group_part_no = @test_resource and 
            use_order = (select min(use_order) from resource_group where
            group_part_no = @test_resource)

          if (@resource_new_code != @test_resource) 
          begin
            update #plan
            set part_no = @resource_new_code
            where operation_step = @test_step AND part_no = @test_resource
          end
        end
      end
      fetch c_resource_test into @test_resource_type, @test_resource, @test_step
    END -- end of while loop

    CLOSE c_resource_test
    DEALLOCATE c_resource_test
    

    INSERT  dbo.sched_operation_plan (
      sched_operation_id,
      line_id,
      cell_id,
      seq_no,
      part_no,
      ave_pool_qty,    
      ave_flat_qty,
      ave_unit_qty,
      uom,
      status)
    SELECT  SO.sched_operation_id,  
      P.line_id,    
      P.cell_id,    
      isnull(o.seq_no,P.seq_no),
      --case when P.part_type = 'C' then '****' else isnull(o.seq_no,P.seq_no) end,
      P.part_no,    
      P.ave_pool_qty,    
      P.ave_flat_qty,    
      P.ave_unit_qty,    
      P.uom,      
      P.part_type    
    FROM  #plan P
    join  dbo.sched_operation SO on P.operation_step = SO.operation_step and SO.sched_process_id = @sched_process_id
    left outer join #part_order o on o.part_id = P.part_id
  end
  else
  begin
    CREATE TABLE #product (
	location	VARCHAR(10)	NULL,
	part_no		VARCHAR(30),
	uom_qty		FLOAT,
	uom		CHAR(2),
	usage_flag	CHAR(1),
	cost_pct	FLOAT,
	bom_rev VARCHAR(10) NULL
	)

    INSERT	#product(location,part_no,uom_qty,uom,usage_flag,cost_pct,bom_rev)
    SELECT	distinct @location,WP.part_no,WP.uom_qty,WP.uom,'B',WP.cost_pct,WP.asm_revision
    FROM	#part WP (NOLOCK)
    WHERE	WP.active = 'M'

    INSERT	#product(location,part_no,uom_qty,uom,usage_flag,cost_pct,bom_rev)
    SELECT	distinct @location,IM.asm_no,1.0,IM.asm_uom,'P',100.0-IsNull((SELECT SUM(P.cost_pct) 
    FROM #part P where P.active = 'M'),0.0),asm_revision
    FROM	#part IM (NOLOCK)

    SELECT  P.location,P.part_no,P.uom_qty,P.uom,P.usage_flag,P.cost_pct,bom_rev
    FROM  #product P

    SELECT  O.operation_step,
      O.location,
      O.ave_flat_qty,
      O.ave_unit_qty,
      O.ave_wait_qty,
      O.ave_flat_time,
      O.ave_unit_time,
      O.operation_type
    FROM  #operation O


    SELECT  P.part_id,
      P.cell_id,
      P.operation_step,
      isnull(o.seq_no,P.seq_no),
      -- case when P.part_type = 'C' then '****' else isnull(o.seq_no,P.seq_no) end,
      P.part_no,
      P.ave_pool_qty,   
      P.ave_flat_qty,
      P.ave_unit_qty,
      P.uom,
      P.part_type,
      P.active,
      P.eff_date
    FROM  #part P
    left outer join #part_order o on o.part_id = P.part_id
    WHERE P.active != 'M'
    order by  P.sort_order
  end
end
IF @sched_id IS NULL and @ret_mult > 0
BEGIN
  select 
    M.asm_no, M.asm_uom, M.asm_revision,
    @location,M.part_no,M.uom_qty,M.uom,
    M.cost_pct,
    O.operation_step,
    O.ave_flat_qty,
    O.ave_unit_qty,
    O.ave_wait_qty,
    O.ave_flat_time,
    O.ave_unit_time,
    O.operation_type,
    M.part_id,
    M.cell_id,
    isnull(p.seq_no,M.seq_no),
    -- case when M.part_type = 'C' then '****' else isnull(p.seq_no,M.seq_no) end,
    M.ave_pool_qty,    
    M.ave_flat_qty,
    M.ave_unit_qty,
    M.part_type,
    M.active,
    M.eff_date
  from #part M
join #operation O on O.asm_no = M.asm_no and O.operation_step = M.operation_step
left outer join #part_order p on p.part_id = M.part_id
order by M.asm_no,M.sort_order 
END

DROP TABLE #plan
DROP TABLE #operation
drop table #part_order
RETURN
END

GO
GRANT EXECUTE ON  [dbo].[fs_build_process_plan] TO [public]
GO
