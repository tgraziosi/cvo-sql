SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE view [dbo].[cvo_issues] as
select
issue_no,
i.part_no,
location_from,
location_to,
avg_cost,
who_entered,
code,
issue_date,
i.note,
qty,
inventory,
direction,
lb_tracking,
direct_dolrs,
ovhd_dolrs,
util_dolrs,
labor,
reason_code,
qc_no,
status,
journal_ctrl_num,
reference_code,
project1,
project2,
project3,
serial_flag,
oper_avg_cost,
oper_direct_dolrs,
oper_ovhd_dolrs,
oper_util_dolrs,
mtrl_reference_cd_expense,
direct_reference_cd_expense,
ovhd_reference_cd_expense,
util_reference_cd_expense,
mtrl_account_expense,
direct_account_expense,
ovhd_account_expense,
util_account_expense,
user_def_fld1,
user_def_fld2,
user_def_fld3,
user_def_fld4,
user_def_fld5,
user_def_fld6,
user_def_fld7,
user_def_fld8,
user_def_fld9,
user_def_fld10,
user_def_fld11,
user_def_fld12,
ref_issue_no,
i.organization_id,
ISNULL(t.bin_no,'')bin_no
from issues_all i (nolock)
join locations l (nolock) on i.location_from = l.location
left join tdc_log t (nolock) on t.tran_no = i.issue_no and t.tran_ext=0
--left join tdc_log t (nolock) on i.issue_no = t.tran_no



GO
