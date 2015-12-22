SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amtrxdpr_vwNextRow_sp] 
( 
	@company_id                     smCompanyID, 
	@trx_ctrl_num                   smControlNumber 
) 
AS 

DECLARE 
	@MSKtrx_ctrl_num        smControlNumber

SELECT 	@MSKtrx_ctrl_num 	= MIN(trx_ctrl_num) 
FROM 	amtrxdpr_vw 
WHERE 	company_id 			= @company_id 
AND 	trx_ctrl_num 		> @trx_ctrl_num 

SELECT 
    timestamp,
    company_id,
    trx_ctrl_num,      
    co_trx_id,
    trx_type,          
    last_modified_date 	= CONVERT(char(8), last_modified_date, 112), 
    modified_by,
    apply_date 			= CONVERT(char(8), apply_date, 112), 
    posting_flag,
    date_posted 		= CONVERT(char(8), date_posted, 112), 
    trx_description,   
    doc_reference,
    process_id,
    from_code,
    to_code,
    from_book,
    to_book,
    group_code,
	from_org_id,					
	to_org_id				 		
FROM    amtrxdpr_vw 
WHERE   company_id 		= @company_id 
AND     trx_ctrl_num 	= @MSKtrx_ctrl_num 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amtrxdpr_vwNextRow_sp] TO [public]
GO
