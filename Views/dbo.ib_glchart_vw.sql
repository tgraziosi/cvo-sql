SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE  VIEW [dbo].[ib_glchart_vw] AS  
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
						CONVERT(varchar(30), 'CVO' ) org_id,			
						CONVERT (int, 0) ib_flag,
						CONVERT(varchar(8), 'CVO' ) company_code
					FROM    glchart gc 
GO
GRANT REFERENCES ON  [dbo].[ib_glchart_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ib_glchart_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ib_glchart_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ib_glchart_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ib_glchart_vw] TO [public]
GO
