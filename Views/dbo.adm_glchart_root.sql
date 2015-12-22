SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_glchart_root] as
SELECT 
	account_code,
	account_description,
	account_type,
	new_flag,
	seg1_code,
	seg2_code,
	seg3_code,
	seg4_code,
	consol_detail_flag,
	consol_type,
	active_date,
	inactive_date,
	inactive_flag,
	currency_code,
	revaluate_flag,
	rate_type_home, 
	rate_type_oper
	FROM glchart_root_vw (nolock)
	WHERE inactive_flag = 0 and account_code in (SELECT account_code FROM sm_accounts_access_co_vw)
GO
GRANT REFERENCES ON  [dbo].[adm_glchart_root] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_glchart_root] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_glchart_root] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_glchart_root] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_glchart_root] TO [public]
GO
