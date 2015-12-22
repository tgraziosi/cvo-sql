SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_sched_resource_demand]
	(
	@resource_demand_id	INT,
	@sched_item_id		INT=NULL
	)
AS
BEGIN

create table #t1 (
  sched_order_id int NULL, location varchar(10) NULL, done_datetime datetime NULL,
  part_no varchar(30) NULL, description varchar(255) NULL, uom_qty decimal(20,8),
  uom char(2) NULL, order_priority_id int NULL, source_flag char(1) NULL,
  order_no int NULL, order_ext int NULL, order_line int NULL)

insert into #t1
exec fs_downstream_item @sched_item_id, NULL, 'O'

insert into resource_demand(
batch_id, group_no, part_no, qty, demand_date, ilevel, location, source, source_no, pqty, 
p_used, uom, parent, buyer)								-- mls 11/1/02 SCR 29652
select 'SCHEDULER', convert(varchar(20),@resource_demand_id), d.part_no, t.uom_qty, t.done_datetime, 0, t.location,
t.source_flag, 
convert(varchar(10),t.order_no) 
+ case when t.order_ext is null then '' else '-' end + convert(varchar(10),t.order_ext) 
+ case when t.order_line is null then '' else ',' end + convert(varchar(10),t.order_line), 
1, 1, t.uom, 'S' + convert(varchar(10),@sched_item_id), m.buyer				-- mls 11/1/02 SCR 29652
from #t1 t
join resource_demand_group d on d.group_no = convert(varchar(20),@resource_demand_id)	-- mls 6/9/05 SCR 34935
left outer join inv_master m on m.part_no = d.part_no					-- mls 11/1/02 SCR 29652

end
GO
GRANT EXECUTE ON  [dbo].[fs_sched_resource_demand] TO [public]
GO
