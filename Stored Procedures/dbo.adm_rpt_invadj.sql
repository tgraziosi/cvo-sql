SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_invadj] @range varchar(8000) = ' 0=0',
@order varchar(1000) = ' issues.issue_no'

 as


BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

select @sql = ' SELECT distinct
issues.issue_no, 
issues.part_no, 
issues.location_from, 
issues.location_to, 
issues.avg_cost, 
issues.who_entered, 
case when isnull(issues.code,'''') = '''' and issues.inventory = ''Q'' then ''ADHOC QC'' else issues.code end, 
issues.issue_date, 
convert(varchar(80),issues.note), 
isnull(lot_serial_bin_issue.qty,issues.qty), 
issues.inventory, 
lot_serial_bin_issue.bin_no, 
lot_serial_bin_issue.lot_ser, 
isnull(lot_serial_bin_issue.direction,issues.direction), 
lot_serial_bin_issue.date_expires, 
inventory.description, 
issues.direct_dolrs, 
issues.ovhd_dolrs, 
issues.util_dolrs, 
issue_code.account
 FROM issues (nolock)
 join inventory (nolock) on issues.part_no = inventory.part_no and issues.location_from = inventory.location 
 left outer join issue_code (nolock) on issues.code = issue_code.code
 left outer join lot_serial_bin_issue (nolock) on issues.part_no = lot_serial_bin_issue.part_no and 
    issues.location_from = lot_serial_bin_issue.location and 
    issues.issue_no = lot_serial_bin_issue.tran_no 
 join locations l (nolock) on l.location = issues.location_from 
 join region_vw r (nolock) on l.organization_id = r.org_id 
 WHERE ' + @range + '
 ORDER BY ' + @order

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_invadj] TO [public]
GO
