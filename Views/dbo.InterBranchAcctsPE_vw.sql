SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                
























                                              


CREATE  VIEW [dbo].[InterBranchAcctsPE_vw] AS

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
	--gc.account_code,
	o.organization_id org_id, 
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
		--gc.account_code,
		o.organization_id org_id,
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
		 AND account_code  IN (SELECT account_code FROM sm_accounts_access_vw)
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
		--account_code,
		' ',
		0 ,
		company_code
	FROM glchart gc, glco g
	WHERE ib_flag=0
	      AND account_code  IN (SELECT account_code FROM sm_accounts_access_vw)
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
		--account_code,
		' ',
		2 ,
		company_code
	FROM glchart gc, glco g
	WHERE ib_flag=1
	
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[InterBranchAcctsPE_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[InterBranchAcctsPE_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[InterBranchAcctsPE_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[InterBranchAcctsPE_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[InterBranchAcctsPE_vw] TO [public]
GO
