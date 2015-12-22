SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amsusact_vw_ampa_vwChildAll_sp]
(
	@company_id                  	smCompanyID,
	@posting_code					smPostingCode
) as







 
SELECT timestamp, company_id, posting_code, account_type, account, account_type_name, display_order, income_account, updated_by
	, permission = case
		when 	account in ('')
			then 1
		when 	account in (select account_code from am_glchart_root_vw) 
			and 
			account in (select account_code from sm_accounts_access_vw) 
			then 1
			else 0
	end						
FROM	ampa_vw 
WHERE	company_id	= @company_id
AND	posting_code	= "____SUSP"
ORDER BY	company_id, posting_code, display_order

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amsusact_vw_ampa_vwChildAll_sp] TO [public]
GO
