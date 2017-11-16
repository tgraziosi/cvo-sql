SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_inv_val_sp]
as 

-- Author: TAG - 092013
-- create daily and monthly inventory value data
-- job runs nightly to exec this procedure
-- add weekly snapshot for POM inventory

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

begin

if (object_id('cvo_inv_val_snapshot') is not null) 
truncate table cvo_inv_val_snapshot

insert into cvo_inv_val_snapshot -- daily snapshot
select
location, category, type_code, part_no, description, in_stock, lbs_qty,
cvo_in_stock, ext_value, lbs_ext_value, cvo_ext_value, std_cost, std_ovhd_dolrs,
std_util_dolrs, pns_qty, pns_value, qc_qty, qc_value, int_qty, int_value, obs,
pom_date, bkordr_date, inv_acct_code, inv_ovhd_acct_code,
inv_util_acct_code, asofdate, valuation_group
from cvo_inv_value_vw

if datepart(day,getdate()) = 1
begin
    insert into cvo_inv_val_month -- month-end save for fin reporting
    select
    location, category, type_code, part_no, description, in_stock, lbs_qty,
    cvo_in_stock, ext_value, lbs_ext_value, cvo_ext_value, std_cost, std_ovhd_dolrs,
    std_util_dolrs, pns_qty, pns_value, qc_qty, qc_value, int_qty, int_value, obs,
    pom_date, bkordr_date, inv_acct_code, inv_ovhd_acct_code,
    inv_util_acct_code, dateadd(d,datediff(d,0,asofdate),-1) asofdate
	, valuation_group
    from cvo_inv_val_snapshot
end

if datepart(WEEKDAY,getdate()) = 1 -- Sunday
begin
insert into cvo_item_avail_POM_weekly -- weekly save for inventory planning
SELECT s.Brand ,
       s.ResType ,
       s.PartType ,
       s.Style ,
       s.part_no ,
       s.description ,
       s.location ,
       s.in_stock ,
       s.SOF ,
       s.Allocated ,
       s.Quarantine ,
       s.Non_alloc ,
       s.Replen_Qty_Not_SA ,
       s.qty_avl ,
       s.qty_hold ,
       s.ReplenQty ,
       s.Qty_Key ,
       s.tot_cost_ea ,
       s.tot_ext_cost ,
       s.po_on_order ,
       s.NextPOOnOrder ,
       s.NextPODueDate ,
       s.lead_time ,
       s.min_order ,
       s.min_stock ,
       s.max_stock ,
       s.order_multiple ,
       s.ReleaseDate ,
       s.POM_date ,
       s.Watch ,
       s.plc_status ,
       s.Gender ,
       s.Material ,
       s.vendor ,
       s.Color_desc ,
       s.ReserveQty ,
       s.QcQty ,
       s.QcQty2 ,
       s.future_ord_qty ,
       s.backorder,
	   GETDATE()
FROM   dbo.cvo_item_avail_vw AS s (nolock)
       JOIN inv_master_add ia ON ia.part_no = s.part_no
       JOIN inv_master i ON i.part_no = s.part_no
	WHERE ISNULL(s.POM_date,GETDATE()) < GETDATE()
	AND S.ResType IN ('frame','sun')
	AND 0 <> S.qty_avl + S.in_stock + S.ReserveQty
END

end

grant execute on cvo_inv_val_sp to public


GO
GRANT EXECUTE ON  [dbo].[cvo_inv_val_sp] TO [public]
GO
