SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_inv_val_sp]
as 

-- Author: TAG - 092013
-- create daily and monthly inventory value data
-- job runs nightly to exec this procedure

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

end

grant execute on cvo_inv_val_sp to public
GO
GRANT EXECUTE ON  [dbo].[cvo_inv_val_sp] TO [public]
GO
