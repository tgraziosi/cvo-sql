SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[cc_load_rpt_config_sp] 	@config_name varchar(65),
												@aging_type smallint = 0

AS

	SELECT 	aging_type,
				sequence,
				cbAllApplyTo,
				txtFromApplyTo,
				txtToApplyTo,
				cbAllCust,
				txtFromCust,
				txtToCust,
				cbAllName,
				txtFromName,
				txtToName,
				cbAllAcctCode,
				txtFromAcctCode,
				txtToAcctCode,
				cbAllNatAcct,
				txtFromNatAcct,
				txtToNatAcct,
				cbAllPriceCode,
				txtFromPrice,
				txtToPrice,
				cbAllPostingCode,
				txtFromPostingCode,
				txtToPostingCode,
				cbAllSalesCode,
				txtFromSales,
				txtToSales,
				cbAllTerr,
				txtFromTerr,
				txtToTerr,
				cbAllWorkload,
				txtFromWorkload,
				txtToWorkload,
				dtAsOfDate,
				title,
				order_by_currency,
				incl_future_trx,
				incl_trx_pif,
				age_on_date,
				prt_over_days,
				over_days,
				prt_over_amt,
				over_amt,
				prt_ovr_cd_lim,
				prt_ovr_ag_lim,
				cond_req,
				print_name,
				print_contact,
				print_attention,
				print_address,
				print_status,
				reference_num,
				home_totals,
				apply_date_rate,
				override_rate_type,
				relation_code,
				print_to,
							
				balance_type,
				days_type,	
				style,	
				territory_basis,
				brackets,
				exclude_on_acct,
				include_comments,
				all_org_flag,
				from_org,
				to_org
	FROM	cc_report_configs 
	WHERE	config_name = @config_name
	AND	aging_type = @aging_type


GO
GRANT EXECUTE ON  [dbo].[cc_load_rpt_config_sp] TO [public]
GO
