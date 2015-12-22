SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE PROCEDURE [dbo].[fs_check_schedule_status]
	(
	@sched_id       INT
	)
AS
BEGIN

DECLARE @rowcount       	INT ,
	@sched_order_id		INT,
	@done_datetime		DATETIME,
        @purchase_lead_flag     CHAR(1),
        @tolerance_days_late    INT,
        @tolerance_days_early   INT,
        @item_id                INT,
        @lead_date      	DATETIME,
        @lead_days              INT,
	@dock_to_stock_days     INT,
        @projected_receipt_date DATETIME,
	@confirmed_receipt_date DATETIME,
	@new_status             CHAR(1),
	@sched_process_id	INT,
	@prev_sched_process_id	INT,
	@demand_datetime	DATETIME,
	@prod_completion_date	DATETIME,
	@sched_order_item	INT,
	@prev_item_id	INT,
	@status_flag		CHAR(1),
	@status_flag_num_string CHAR(1),
        @level_count            INT

DECLARE @uom_qty              FLOAT,
        @order_id_pulling    INT,
        @uom_qty_pulled         FLOAT,
        @item_id_pulled     INT,
        @process_id_pulled  INT,
        @source_flag_pulled      CHAR(1),
        @work_datetime_pulled    DATETIME,
        @prev_order_id INT,
        @prev_order_uom_qty           FLOAT,
        @uom_tot_qty_pulled     FLOAT,
        @uom_inv_qty_pulled     FLOAT,
        @order_action_flag      CHAR(1),
        @replenishment_level   	INT,
        @order_action_datetime  DATETIME,
        @lower_level_action_datetime DATETIME,
        @lower_level_action_flag     CHAR(1),
        @replenishment_table_ctr       INT,
        @next_replenishment_level      INT

DECLARE @new_order_id INT,
 	@order_id INT,
	@orig_order_id INT,
        @SP_order_id INT

----------------------------------------------------------------------------------------------------------------------
-- Starting at orders in the scenario, work through the sched_order_item and sched_operation_item tables to get all the 
-- related supply records for the orders.  Pass along the initial early, late or on time status for the final process
-- before shipping the order.  This will be used to calculate possibly early and possibly on_time status.
----------------------------------------------------------------------------------------------------------------------

SELECT @purchase_lead_flag = SM.purchase_lead_flag,
  @tolerance_days_late = SM.tolerance_days_late,
  @tolerance_days_early = SM.tolerance_days_early
FROM	sched_model SM (nolock)
WHERE	SM.sched_id = @sched_id

create table #temp (sched_item_id int, sched_order_id int, done_datetime datetime, flag int, 
sched_process_id int NULL, si_done_datetime datetime, type char(1),prev_status char(1), prev_sched_process_id int NULL,
part_no varchar(30), location varchar(10))
create index t1 on #temp (flag)
create index t2 on #temp (sched_item_id)
create index t3 on #temp (sched_process_id)

declare @level int, @flag int
select @level = 0

insert #temp
select soi.sched_item_id, so.sched_order_id, so.done_datetime, @level, 
  si.sched_process_id, si.done_datetime, si.source_flag,
  case when datediff(d,so.done_datetime,si.done_datetime) > 0 then 'L'
    when datediff(d,so.done_datetime,si.done_datetime) < -3 then 'E'
    when datediff(d,so.done_datetime,si.done_datetime) < -1 and
       datepart(dw,si.done_datetime) > 5 then '0'		-- mls 2/23/05 SCR 34305
    when datediff(d,so.done_datetime,si.done_datetime) < -1 then 'E' 
    else 'O' end , NULL,	-- mls 2/23/05 SCR 34305
  si.part_no, si.location
from sched_order_item soi, sched_order so, sched_item si
where si.sched_item_id = soi.sched_item_id and soi.sched_order_id = so.sched_order_id and so.sched_id = @sched_id

select @flag = @@rowcount
while @flag > 0
begin
  insert #temp
  select si.sched_item_id, t.sched_order_id, t.done_datetime, (@level + 1), 
    si.sched_process_id, si.done_datetime, si.source_flag, t.prev_status, t.sched_process_id,
    si.part_no, si.location
  from #temp t
  join sched_process sp on sp.sched_process_id = t.sched_process_id
  join sched_operation so on so.sched_process_id = sp.sched_process_id
  join sched_operation_item soi on soi.sched_operation_id = so.sched_operation_id
  join sched_item si on si.sched_item_id = soi.sched_item_id
  where t.flag = @level and t.sched_process_id is not null

  select @flag = @@rowcount
  select @level = @level + 1
end

------------------------------------------------------------------------------------------------------
--
-- Codes and meaning from worst to least-worst.
--   L Late
--   M Late Receipt Confirmed
--   E Early
--   F Early Receipt Confirmed
--   S Surplus
--   O On-Time
--   NULL No status determined
--
-- Early, late, and on-time mean that the purchase is actually being used to support a scheduled production,
-- but the receipt date is either later than or earlier than the production required.
-- Early Receipt and late receipt mean that the confirmed date of the purchase is different 
-- from what we expected based on lead-time (but this is not currently adversely affecting 
-- any scheduled productions). 
-- Surplus means that the purchase exists but is not currently allocated to meet any demand in 
-- this scenario.
------------------------------------------------------------------------------------------------------


-- Declare cursor to look for situations where purchases were used to meet demand but were later or earlier
-- than required.  Since a single sched_item record can be "pulled" by multiple sched_order_item records, need to 
-- allow for doing comparisons to find the "worst" order.
update PU
set PU.status_flag =
  case 
  when convert(int,substring(min_lvl_order,38,20)) < 0 then 'L'      	-- po_date < order_date
  when datediff(d,h.done_datetime,getdate()) > @tolerance_days_late then 'K'
  else
    case
    when convert(int,substring(min_lvl_order,38,20)) > 0 then 		-- po_date > order_date
      case 
      when substring(min_op_order,1,1) = '1' then 'D'			-- po is early but process is late set to possibly early
      else 'E' 							-- else set to early
      end 
    else 
      case 
      when substring(min_op_order,1,1) = '1' then 'N' 		-- po is on time but process is late
      else 	
        case 
        when datediff(d,h.lead_datetime,h.done_datetime) > @tolerance_days_late then 'M' -- release date < po_date by more than tolerance late 
        when datediff(d,h.lead_datetime,h.done_datetime) < (@tolerance_days_early * -1) then 'F' -- release date > po_date by more than tolerance early
        else 'O' 							-- else set to on time
        end
      end
    end
  end,
  PU.sched_order_id = 
  case 
    when convert(int,substring(min_lvl_order,38,20)) < 0 		-- late
      then convert(int,substring(min_lvl_order,23,15)) 
    when convert(int,substring(min_lvl_order,38,20)) > 0 then 		-- early
      case 
        when substring(min_op_order,1,1) = '1' 				-- process is late but PO is early
          then convert(int,substring(min_op_order,23,15)) 		-- set to processes minimum sched_order_id
        else convert(int,substring(min_lvl_order,23,15)) 		-- else set to POs minimum sched_order_id
      end 
    else 
      case 
        when substring(min_op_order,1,1) = '1' 				-- process is late but PO is on time
          then convert(int,substring(min_op_order,23,15)) 		-- set to processes minimum sched_order_id
        else convert(int,substring(min_lvl_order,23,15)) 		-- else set to POs minimum sched_order_id
      end 
  end
from sched_purchase PU
left outer join 
  (select t.sched_item_id, 
     min(case when charindex(prev_status,'LKOE') = 0 then '9' else convert(char(1),charindex(prev_status,'LKOE')) end+
       case when DATEDIFF (d,t.si_done_datetime,t.done_datetime) < 0 then 'b' else 'c' end +
       convert(char(20),10000000000 + (DATEDIFF (d,t.si_done_datetime,t.done_datetime))) + 
       convert(char(15),right(replicate('0',15)+convert(varchar(15),t.sched_order_id),15))+
       convert(char(20),DATEDIFF (d,t.si_done_datetime,t.done_datetime))),
     min(case when prev_sched_process_id is null then '9' else 
       case when charindex(prev_status,'LKOE') = 0 then '9' else convert(char(1),charindex(prev_status,'LKOE')) end end +
       case when DATEDIFF (d,t.si_done_datetime,t.done_datetime) < 0 then 'b' else 'c' end +
       convert(char(20),10000000000 + (DATEDIFF (d,t.si_done_datetime,t.done_datetime))) + 
       convert(char(15),right(replicate('0',15)+convert(varchar(15),t.sched_order_id),15))+
       convert(char(20),DATEDIFF (d,t.si_done_datetime,t.done_datetime))),
     dateadd(d, case when isnull(@purchase_lead_flag,'X') = 'S' then isnull(IL.lead_time + IL.dock_to_stock,0) else 0 end, sp.lead_datetime),
     t.si_done_datetime
   from #temp t
   join sched_purchase sp on sp.sched_item_id = t.sched_item_id
   left outer join inv_list IL on IL.part_no = t.part_no and IL.location = t.location
   group by t.sched_item_id, sp.lead_datetime, IL.lead_time, IL.dock_to_stock, t.si_done_datetime) 
  as h(sched_item_id, min_lvl_order, min_op_order, lead_datetime, done_datetime) on h.sched_item_id = PU.sched_item_id
where (
  PU.status_flag != 
    case when h.sched_item_id is null then 'S' 
      else
        case when convert(int,substring(min_lvl_order,38,20)) < 0 then 'L' 
          when datediff(d,h.done_datetime,getdate()) > @tolerance_days_late then 'K'
          else
            case
            when convert(int,substring(min_lvl_order,38,20)) > 0 
              then case when left(min_op_order,1) = '1' then 'D' else 'E' end 
            else 
              case when left(min_op_order,1) = '1' then 'N' 
                else 
                  case when datediff(d,h.lead_datetime,h.done_datetime) > @tolerance_days_late then 'M'
                    when datediff(d,h.lead_datetime,h.done_datetime) < (@tolerance_days_early * -1) then 'F' 
                    else 'O' end
              end
           end
        end 
    end
  or 
  isnull(PU.sched_order_id,-1) != case when convert(int,substring(min_lvl_order,38,20)) < 0 
    then convert(int,substring(min_lvl_order,23,15)) 
    when convert(int,substring(min_lvl_order,38,20)) > 0 
      then case when substring(min_op_order,1,1) = '1' 
        then convert(int,substring(min_op_order,23,15)) else convert(int,substring(min_lvl_order,23,15)) end 
    else case when substring(min_op_order,1,1) = '1' 
      then convert(int,substring(min_op_order,23,15)) else convert(int,substring(min_lvl_order,23,15)) end 
  end)

update PU
set PU.status_flag = case when h.sched_process_id is null then 'S' else
  case when convert(int,substring(min_lvl_order,38,20)) < 0 then 'L' 
    when convert(int,substring(min_lvl_order,38,20)) > 3 or
     (convert(int,substring(min_lvl_order,38,20)) > 1 and
       not (datepart(dw,h.done_datetime) > 5))		-- mls 2/23/05 SCR 34305
	then 				-- mls 2/23/05 SCR 34305
    case when substring(min_lvl_order,37,1) = 'L' then 'D' else 'E' end 
    else case when substring(min_lvl_order,37,1) = 'L' then 'N' else 'O' end end end,
  PU.sched_order_id =  convert(int,substring(min_lvl_order,22,15))
from sched_process PU
left outer join (select t.sched_process_id, 
   min(case when DATEDIFF (d,t.si_done_datetime,t.done_datetime) < 0 then 'b' else 'c' end +
     convert(char(20),10000000000 + (DATEDIFF (d,t.si_done_datetime,t.done_datetime))) + 
     convert(char(15),right(replicate('0',15)+convert(varchar(15),t.sched_order_id),15))+
     prev_status +
     convert(char(20),DATEDIFF (d,t.si_done_datetime,t.done_datetime))),
   t.si_done_datetime
  from #temp t, sched_process sp
  where t.sched_process_id = sp.sched_process_id and t.sched_process_id is not null
  group by t.sched_process_id,t.si_done_datetime) as h(sched_process_id, min_lvl_order,done_datetime) on h.sched_process_id = PU.sched_process_id
where  (PU.status_flag != case when h.sched_process_id is null then 'S' else
case when convert(int,substring(min_lvl_order,38,20)) < 0 then 'L' 
    when convert(int,substring(min_lvl_order,38,20)) > 3 or
     (convert(int,substring(min_lvl_order,38,20)) > 1 and
       not (datepart(dw,h.done_datetime) > 5)) then	-- mls 2/23/05 SCR 34305
  case when substring(min_lvl_order,37,1) = 'L' then 'D' else 'E' end 
  else case when substring(min_lvl_order,37,1) = 'L' then 'N' else 'O' end end end
or isnull(PU.sched_order_id,-1) != isnull(convert(int,substring(min_lvl_order,22,15)),-1))



UPDATE	sched_model
SET	check_datetime = getdate()
FROM	sched_model SM
WHERE	SM.sched_id = @sched_id

RETURN
END


GO
GRANT EXECUTE ON  [dbo].[fs_check_schedule_status] TO [public]
GO
