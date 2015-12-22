SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[scm_pb_set_dw_rpt_new_scost_sp]
@typ char(1), @timestamp varchar(20), @kys integer, @part_no varchar(30), @cost_level varchar(4)
, @new_type char(1), @new_amt decimal(20,8), @new_direction integer
, @eff_date datetime, @who_entered varchar(20), @date_entered datetime
, @reason varchar(20), @status char(1), @real_note varchar(255), @row_id integer
, @inventory_description varchar(255), @inventory_location varchar(10)
, @inventory_avg_cost decimal(20,8)
, @inventory_avg_direct_dolrs decimal(20,8)
, @inventory_avg_ovhd_dolrs decimal(20,8)
, @inventory_avg_util_dolrs decimal(20,8), @inventory_std_cost decimal(20,8)
, @inventory_std_direct_dolrs decimal(20,8)
, @inventory_std_ovhd_dolrs decimal(20,8)
, @inventory_std_util_dolrs decimal(20,8), @inventory_category varchar(10)
, @new_cost_location varchar(10), @c_level1 char(1), @c_level2 char(1)
, @c_level3 char(1), @c_level4 char(1), @org_name varchar(255)
 AS
BEGIN
set nocount on
DECLARE @ts timestamp
exec adm_varchar_to_ts_sp @timestamp, @ts output
if @typ = 'I'
begin
rollback tran 
raiserror 99001 'You cannot create a new update cost record through this window'
return
end
if @typ = 'U'
begin
update new_cost set
new_cost.cost_level= @cost_level, new_cost.new_type= @new_type
, new_cost.new_amt= @new_amt, new_cost.eff_date= @eff_date
, new_cost.who_entered= @who_entered, new_cost.date_entered= @date_entered
, new_cost.status= @status
where kys = @kys and timestamp = @ts
if @@rowcount = 0
begin
  rollback tran
  RAISERROR 832115 'Row changed between retrieve and update'
  RETURN 
end
end
if @typ = 'D'
begin
rollback tran 
raiserror 99001 'You cannot delete an update cost record through this window'
return
end
end
GO
GRANT EXECUTE ON  [dbo].[scm_pb_set_dw_rpt_new_scost_sp] TO [public]
GO
