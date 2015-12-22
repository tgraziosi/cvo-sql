SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_glchart_unsecured] as

SELECT 
	gc.timestamp,
	gc.account_code,
	gc.account_description,
	gc.account_type,
	gc.new_flag,
	gc.seg1_code,
	gc.seg2_code,
	gc.seg3_code,
	gc.seg4_code,
	gc.consol_detail_flag,
	gc.consol_type,
	gc.active_date,
	gc.inactive_date,
	gc.inactive_flag,
	gc.currency_code,
	gc.revaluate_flag,
	gc.rate_type_home, 
	gc.rate_type_oper,
	gc.organization_id org_id, 
	ib_flag,
	company_code
FROM glco c,glchart gc, Organization o
WHERE  1=2
	UNION ALL
	SELECT 
		gc.timestamp,
		gc.account_code,
		gc.account_description,
		gc.account_type,
		gc.new_flag,
		gc.seg1_code,
		gc.seg2_code,
		gc.seg3_code,
		gc.seg4_code,
		gc.consol_detail_flag,
		gc.consol_type,
		gc.active_date,
		gc.inactive_date,
		gc.inactive_flag,
		gc.currency_code,
		gc.revaluate_flag,
		gc.rate_type_home, 
		gc.rate_type_oper,
		gc.organization_id org_id,
		ib_flag,
		company_code
	FROM glco c,glchart gc, Organization o
	WHERE 
	CASE  ib_segment 
		WHEN 1 THEN substring (seg1_code,ib_offset,ib_length)
		WHEN 2 THEN substring (seg2_code,ib_offset,ib_length)
		WHEN 3 THEN substring (seg3_code,ib_offset,ib_length)
		WHEN 4 THEN substring (seg4_code,ib_offset,ib_length)
	END = o.branch_account_number 
		 AND ib_flag=1
	UNION ALL 
	SELECT 
		gc.timestamp,
		gc.account_code,
		gc.account_description,
		gc.account_type,
		gc.new_flag,
		gc.seg1_code,
		gc.seg2_code,
		gc.seg3_code,
		gc.seg4_code,
		gc.consol_detail_flag,
		gc.consol_type,
		gc.active_date,
		gc.inactive_date,
		gc.inactive_flag,
		gc.currency_code,
		gc.revaluate_flag,
		gc.rate_type_home, 
		gc.rate_type_oper,
		' ',
		0 ,
		company_code
	FROM glchart gc, glco g
	WHERE ib_flag=0
GO
GRANT REFERENCES ON  [dbo].[adm_glchart_unsecured] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_glchart_unsecured] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_glchart_unsecured] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_glchart_unsecured] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_glchart_unsecured] TO [public]
GO
