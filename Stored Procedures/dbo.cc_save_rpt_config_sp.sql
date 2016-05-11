SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[cc_save_rpt_config_sp]	@config_name			varchar(65),
												@aging_type				smallint = 0,	
												@sequence				smallint = 0,
												@cbAllApplyTo			smallint = 1,
												@txtFromApplyTo		varchar(16) = '',
												@txtToApplyTo			varchar(16) = '',
												@cbAllCust				smallint = 1,
												@txtFromCust			varchar(8) = '',
												@txtToCust				varchar(8) = '',
												@cbAllName				smallint = 1,
												@txtFromName			varchar(40) = '',
												@txtToName				varchar(40) = '',
												@cbAllAcctCode			smallint = 1,
												@txtFromAcctCode		varchar(32) = '',
												@txtToAcctCode			varchar(32) = '',
												@cbAllNatAcct			smallint = 1,
												@txtFromNatAcct		varchar(32) = '',
												@txtToNatAcct			varchar(32) = '',
												@cbAllPriceCode		smallint = 1,
												@txtFromPrice			varchar(8) = '',
												@txtToPrice				varchar(8) = '',
												@cbAllPostingCode		smallint = 1,
												@txtFromPostingCode	varchar(8) = '',
												@txtToPostingCode		varchar(8) = '',
												@cbAllSalesCode		smallint = 1,
												@txtFromSales			varchar(8) = '',
												@txtToSales				varchar(8) = '',
												@cbAllTerr				smallint = 1,
												@txtFromTerr			varchar(8) = '',
												@txtToTerr				varchar(8) = '',
												@cbAllWorkload			smallint = 1,
												@txtFromWorkload		varchar(8) = '',
												@txtToWorkload			varchar(8) = '',
												@dtAsOfDate				varchar(12),
												@title					varchar(60) = '',		
												@order_by_currency	smallint = 0,
												@incl_future_trx		smallint = 0,
												@incl_trx_pif			smallint = 0,
												@age_on_date			smallint = 0,
												@prt_over_days			smallint = 0,
												@over_days				int = 0, 
												@prt_over_amt 			smallint = 0,
												@over_amt				float = 0, 
												@prt_ovr_cd_lim		smallint = 0,
												@prt_ovr_ag_lim		smallint = 0,
												@cond_req				smallint = 0,
												@print_name				smallint = 1,
												@print_contact			smallint = 1,
												@print_attention		smallint = 1,
												@print_address			smallint = 1,
												@print_status			smallint = 1,
												@reference_num			smallint = 0,
												@home_totals			smallint = 1,
												@apply_date_rate		smallint = 0,	
												@override_rate_type	varchar(9) = '',
												@relation_code			varchar(17) = 'STANDARD',	
												@print_to				smallint = 0,
											
												@balance_type			smallint = 0,	
												@days_type				smallint = 0,	
												@style					smallint = 0,	
												@territory_basis		smallint = 0,		
												@brackets			 smallint = 0,
												@exclude_on_acct		smallint = 0,											
												@include_comments		smallint = 0,
												@all_org_flag			smallint = 1,
												@from_org		varchar(30) = '',
												@to_org			varchar(30) = ''


AS

	IF (SELECT COUNT(*) FROM cc_report_configs WHERE config_name = @config_name AND aging_type = @aging_type ) > 0
		DELETE cc_report_configs WHERE config_name = @config_name
		AND aging_type = @aging_type

	
	INSERT cc_report_configs
	VALUES(	@config_name,
				@aging_type,
				@sequence,
				@cbAllApplyTo,
				@txtFromApplyTo,
				@txtToApplyTo,
				@cbAllCust,
				@txtFromCust,
				@txtToCust,
				@cbAllName,
				@txtFromName,
				@txtToName,
				@cbAllAcctCode,
				@txtFromAcctCode,
				@txtToAcctCode,
				@cbAllNatAcct,
				@txtFromNatAcct,
				@txtToNatAcct,
				@cbAllPriceCode,
				@txtFromPrice,
				@txtToPrice,
				@cbAllPostingCode,
				@txtFromPostingCode,
				@txtToPostingCode,
				@cbAllSalesCode,
				@txtFromSales,
				@txtToSales,
				@cbAllTerr,
				@txtFromTerr,
				@txtToTerr,
				@cbAllWorkload,
				@txtFromWorkload,
				@txtToWorkload,
				@dtAsOfDate,
				@title,
				@order_by_currency,
				@incl_future_trx,
				@incl_trx_pif,
				@age_on_date,
				@prt_over_days,
				@over_days,
				@prt_over_amt,
				@over_amt,
				@prt_ovr_cd_lim,
				@prt_ovr_ag_lim,
				@cond_req,
				@print_name,
				@print_contact,
				@print_attention,
				@print_address,
				@print_status,
				@reference_num,
				@home_totals,
				@apply_date_rate,
				@override_rate_type,
				@relation_code,
				@print_to,
							
				@balance_type,
				@days_type,	
				@style,	
				@territory_basis,
				@brackets,
				@exclude_on_acct,
				@include_comments,
				@all_org_flag,
				@from_org,
				@to_org )

GO
GRANT EXECUTE ON  [dbo].[cc_save_rpt_config_sp] TO [public]
GO