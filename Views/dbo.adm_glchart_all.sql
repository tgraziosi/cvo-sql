SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_glchart_all] as
SELECT 
	gc.timestamp,
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
	gc.rate_type_home, 
	gc.rate_type_oper,
	'' org_id,
	ib_flag,
	company_code
FROM glchart gc, glco

GO
GRANT REFERENCES ON  [dbo].[adm_glchart_all] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_glchart_all] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_glchart_all] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_glchart_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_glchart_all] TO [public]
GO
