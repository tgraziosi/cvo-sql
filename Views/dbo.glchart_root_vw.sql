SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO






                                                




CREATE VIEW [dbo].[glchart_root_vw]  AS
	
SELECT 	coa.account_code, 
	coa.account_description,
	coa.account_type,
	coa.new_flag,
	coa.seg1_code,
	coa.seg2_code,
	coa.seg3_code,
	coa.seg4_code,
	coa.consol_detail_flag,
	coa.consol_type,
	coa.active_date,
	coa.inactive_date,
	coa.inactive_flag,
	coa.currency_code,
	coa.revaluate_flag,
	coa.rate_type_home,
	coa.rate_type_oper 

	FROM glco c,glchart coa, Organization_all o
	WHERE 
	CASE  ib_segment 
		WHEN 1 THEN substring (seg1_code,ib_offset,ib_length)
		WHEN 2 THEN substring (seg2_code,ib_offset,ib_length)
		WHEN 3 THEN substring (seg3_code,ib_offset,ib_length)
		WHEN 4 THEN substring (seg4_code,ib_offset,ib_length)
	END = o.branch_account_number 
		 AND ib_flag=1
	AND o.outline_num = '1'

UNION 

SELECT 	coa.account_code, 
	coa.account_description,
	coa.account_type,
	coa.new_flag,
	coa.seg1_code,
	coa.seg2_code,
	coa.seg3_code,
	coa.seg4_code,
	coa.consol_detail_flag,
	coa.consol_type,
	coa.active_date,
	coa.inactive_date,
	coa.inactive_flag,
	coa.currency_code,
	coa.revaluate_flag,
	coa.rate_type_home,
	coa.rate_type_oper 

	FROM glco c,glchart coa
	WHERE ib_flag = 0


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glchart_root_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glchart_root_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glchart_root_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glchart_root_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchart_root_vw] TO [public]
GO
