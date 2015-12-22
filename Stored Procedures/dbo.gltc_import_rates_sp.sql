SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO








                                                


CREATE PROCEDURE [dbo].[gltc_import_rates_sp]
	@file_path	varchar(500),
	@from		varchar(3),
	@to			varchar(3)
AS
BEGIN

DECLARE 	@tax_auth_code varchar (8),
			@gl_internal_tax_account varchar (32),
			@gl_sales_tax_account varchar (32)

select @tax_auth_code = tax_auth_code, @gl_internal_tax_account = gl_internal_tax_account, 
		@gl_sales_tax_account = gl_sales_tax_account from gltcconfig

create table #import(info varchar(136))
create table #stateRates(stateCode varchar(2),
				stateCitySalesRate varchar (8))
CREATE TABLE #gltcrates ( 
		timestamp timestamp NOT NULL,
		tax_code varchar(8),
		external_tax_code varchar(13),
		stateCode varchar(2),
		zipCode varchar(5),
		geoCode varchar(2),
		stateCityName varchar(25),
		stateCitySalesRate varchar(7),
		cityTransitSalesRate varchar(7),
		countyName varchar(25),
		countyCode varchar(3),
		countySalesRate varchar(7),
		countyTransitSalesRate varchar(7),
		combinedSalesRate varchar(7),
		cityAdmin varchar(1),
		countyAdmin varchar(1)
	)
		
		EXEC(" BULK INSERT #import
				FROM '" + @file_path + "' WITH 
				(ROWTERMINATOR = '\n')" )

	
	------------insert into #gltcrates temp table------------------------
	
	insert into #gltcrates (tax_code, external_tax_code, stateCode, zipCode, geoCode, 
		stateCityName, stateCitySalesRate, cityTransitSalesRate, countyName, countyCode, 
		countySalesRate, countyTransitSalesRate, combinedSalesRate, cityAdmin, countyAdmin)
	select substring(info,3,7) as tax_code,
		substring(info,1,9) as external_tax_code,
		substring(info,1,2) as stateCode, substring(info,3,5) as zipCode, 
		substring(info,8,2) as geoCode, substring(info,10,25) as stateCityName,
		substring(info,36,7) as stateCitySalesRate, substring(info,43,7) as cityTransitSalesRate, 
		substring(info,64,25) as countyName, substring(info,134,3) as countyCode,
		substring(info,90,7) as countySalesRate, substring(info,97,7) as countyTransitSalesRate,  
		substring(info,118,7) as combinedSalesRate,
		substring(info,132,1) as cityAdmin, substring(info,133,1) as countyAdmin
	from #import where substring(info,8,2) != '00' and (substring(info,1,2) >=  @from and substring(info,1,2) <= @to)

	---------------------------------------------------------------------

	
	--------update rates into gltcrates table with the new rate info-----------
	update gltcrates set stateCitySalesRate = g.stateCitySalesRate, 
			cityTransitSalesRate = g.cityTransitSalesRate, countySalesRate = g.countySalesRate, 
			countyTransitSalesRate = g.countyTransitSalesRate, combinedSalesRate = g.combinedSalesRate, 
			cityAdmin = g.cityAdmin, countyAdmin = g.countyAdmin
	from #gltcrates g where gltcrates.tax_code = g.tax_code and g.zipCode != ''
	----------------------------------------------------------------------------
	-----insert new rates into gltcrates table with the new information---------
	insert into gltcrates (tax_code, external_tax_code, stateCode, zipCode, geoCode, 
		stateCityName, stateCitySalesRate, cityTransitSalesRate, countyName, countyCode, 
		countySalesRate, countyTransitSalesRate, combinedSalesRate, cityAdmin, countyAdmin)
	select tax_code , external_tax_code, stateCode, zipCode, geoCode, 
		stateCityName, stateCitySalesRate, cityTransitSalesRate, countyName, countyCode,
		countySalesRate, countyTransitSalesRate, combinedSalesRate, cityAdmin, countyAdmin
	from #gltcrates WITH (NOLOCK) 
		where NOT EXISTS(select tax_code from gltcrates where gltcrates.tax_code = #gltcrates.tax_code) and zipCode != ''
	----------------------------------------------------------------------------
	-----------update tax_code for unique tax_code registered-------------------
		update gltcrates SET gltcrates.tax_code = g.tax_code + + substring(g.stateCode,1,1)
			from #gltcrates g
			 where gltcrates.tax_code = g.tax_code 
				and	gltcrates.stateCode != g.stateCode 
	-----------------------------------------------------------------------------
	



 	---------- tax_type_code by state into temp_table-----------
	insert into #stateRates (stateCode, stateCitySalesRate)
	select stateCode, stateCitySalesRate 
		from #gltcrates 
			where zipCode = '' and stateCitySalesRate != '0.00000' 
	------------------------------------------------------------


	
	--------------insert new tax_code in artax table --------------------
	insert into artax (external_tax_code, tax_code,	tax_desc, 
				tax_included_flag, override_flag, module_flag, tax_connect_flag, imported_flag)
		select external_tax_code, tax_code, stateCode + '-' + stateCityName, 
				0, 0, 0, 0, 1  
	from gltcrates 
		where NOT EXISTS (select tax_code from artax where artax.tax_code = gltcrates.tax_code)
	--------------------------------------------------
	

	



	--------update tax_type_code into artxtype table with the new state rate info-----------
	update artxtype set amt_tax = cast(s.stateCitySalesRate as float) * 100
		FROM gltcrates g, #stateRates s  
				where g.zipCode != '' and g.stateCode = s.stateCode 
					and artxtype.tax_type_code = g.stateCode + g.zipCode and artxtype.amt_tax != cast(s.stateCitySalesRate as float)
	---------------------------------------------------------------------------------------

	--------insert tax_type_code into artxtype table with the state rate info-----------
	insert into artxtype (external_tax_type_code,
								tax_type_code, tax_type_desc, tax_auth_code,
								amt_tax, prc_flag, prc_type, cents_code_flag, 
								cents_code, tax_based_type, tax_included_flag, 
								modify_base_prc, base_range_flag, base_range_type,base_taxed_type,
								min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
								min_tax_amt, max_tax_amt, sales_tax_acct_code, 
								ap_tax_acct_code, ar_tax_code, vat_flag, 
								recoverable_flag, gl_internal_tax_account, tax_connect_flag)
			SELECT distinct g.stateCode + g.zipCode,										--external_tax_type_code,
							g.stateCode + g.zipCode, g.stateCode +  '-' + g.zipCode, @tax_auth_code, --tax_type_code, tax_type_desc, tax_auth_code,
							cast(s.stateCitySalesRate as float) * 100, 1,0,0,						--amt_tax, prc_flag, prc_type, cents_code_flag,
							'',0,0,															--cents_code, tax_based_type, tax_included_flag,
							100,0,0,0,														--modify_base_prc, base_range_flag, base_range_type, base_taxed_type,
							0,0,0,0,														--min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
							0,0,@gl_sales_tax_account,												--min_tax_amt, max_tax_amt, sales_tax_acct_code, 
							'','',0,														--ap_tax_acct_code, ar_tax_code, vat_flag,
							1,@gl_internal_tax_account,0												--ap_tax_acct_code, ar_tax_code, vat_flag,
			FROM gltcrates g, #stateRates s  
				where g.zipCode != '' and g.stateCode = s.stateCode 
				and NOT EXISTS (select tax_type_code from artxtype where artxtype.tax_type_code = g.stateCode + g.zipCode)
	-------------------------------------------------------------------------------------

	----------insert tax_type_code and tax_code relationship into artaxdet table----------
		insert into artaxdet (tax_code, sequence_id, tax_type_code,	base_id)
		select g.tax_code, 0, g.stateCode + g.zipCode, 0
		from gltcrates g, #stateRates s  
		where g.zipCode != '' and g.stateCode = s.stateCode 
			and (NOT EXISTS (select tax_type_code from artaxdet WHERE artaxdet.tax_type_code = (g.stateCode + g.zipCode)))
	--------------------------------------------------------------------------------------
	




	



	--------update tax_type_code into artxtype table with the new county rate info-----------
	update artxtype set amt_tax = cast(g.countySalesRate as float) * 100
		FROM gltcrates g 
				where g.countySalesRate != '0.00000' and g.zipCode != '' and g.countyAdmin = ''
					and artxtype.tax_type_code =  g.stateCode + g.countyCode and artxtype.amt_tax != cast(g.countySalesRate as float)
	---------------------------------------------------------------------------------------

	----------------------------tax_type_code by county-----------------------------------
	insert into artxtype (external_tax_type_code,
								tax_type_code, tax_type_desc, tax_auth_code,
								amt_tax, prc_flag, prc_type, cents_code_flag, 
								cents_code, tax_based_type, tax_included_flag, 
								modify_base_prc, base_range_flag, base_range_type,base_taxed_type,
								min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
								min_tax_amt, max_tax_amt, sales_tax_acct_code, 
								ap_tax_acct_code, ar_tax_code, vat_flag, 
								recoverable_flag, gl_internal_tax_account, tax_connect_flag)
			SELECT distinct g.stateCode + g.countyCode,										--external_tax_type_code,
							g.stateCode + g.countyCode, g.countyCode + '-' + g.countyName, @tax_auth_code, --tax_type_code, tax_type_desc, tax_auth_code,
							cast(g.countySalesRate as float) * 100, 1,0,0,						--amt_tax, prc_flag, prc_type, cents_code_flag,
							'',0,0,															--cents_code, tax_based_type, tax_included_flag,
							100,0,0,0,														--modify_base_prc, base_range_flag, base_range_type, base_taxed_type,
							0,0,0,0,														--min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
							0,0,@gl_sales_tax_account,												--min_tax_amt, max_tax_amt, sales_tax_acct_code, 
							'','',0,														--ap_tax_acct_code, ar_tax_code, vat_flag,
							1,@gl_internal_tax_account,0												--ap_tax_acct_code, ar_tax_code, vat_flag,
			FROM gltcrates g  
				where g.countySalesRate != '0.00000' and g.zipCode != '' and g.countyAdmin = ''
					and (NOT EXISTS (select tax_type_code from artxtype WHERE artxtype.tax_type_code = (g.stateCode + g.countyCode)))
	-------------------------------------------------------------------------------------

	----------insert tax_type_code and tax_code relationship into artaxdet table----------
		insert into artaxdet (tax_code, sequence_id, tax_type_code, base_id)
		select g.tax_code, 0, g.stateCode + g.countyCode, 0 
		from gltcrates g
			where g.countySalesRate != '0.00000' and g.zipCode != '' and g.countyAdmin = ''
				and (NOT EXISTS (select tax_type_code from artaxdet WHERE artaxdet.tax_type_code = (g.stateCode + g.countyCode)))
	--------------------------------------------------------------------------------------

	


	

	



	--------update tax_type_code into artxtype table with the new county rate info-----------
	update artxtype set amt_tax = cast(g.stateCitySalesRate as float)
		FROM gltcrates g 
				where g.stateCitySalesRate != '0.00000' and g.zipCode != '' and g.cityAdmin = ''
					and artxtype.tax_type_code = substring(g.stateCode,1,1) + g.zipCode + g.geoCode 
					and artxtype.amt_tax != cast(g.stateCitySalesRate as float) * 100
	---------------------------------------------------------------------------------------
	----------------------------tax_type_code by city-----------------------------------
	insert into artxtype (external_tax_type_code,
								tax_type_code, tax_type_desc, tax_auth_code,
								amt_tax, prc_flag, prc_type, cents_code_flag, 
								cents_code, tax_based_type, tax_included_flag, 
								modify_base_prc, base_range_flag, base_range_type,base_taxed_type,
								min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
								min_tax_amt, max_tax_amt, sales_tax_acct_code, 
								ap_tax_acct_code, ar_tax_code, vat_flag, 
								recoverable_flag, gl_internal_tax_account, tax_connect_flag)
			SELECT distinct g.stateCode + g.zipCode + g.geoCode,											--external_tax_type_code,
							substring(g.stateCode,1,1) + g.zipCode + g.geoCode, g.zipCode + '-' + g.stateCityName, @tax_auth_code, --tax_type_code, tax_type_desc, tax_auth_code,
							cast(g.stateCitySalesRate as float) * 100, 1,0,0,						--amt_tax, prc_flag, prc_type, cents_code_flag,
							'',0,0,															--cents_code, tax_based_type, tax_included_flag,
							100,0,0,0,														--modify_base_prc, base_range_flag, base_range_type, base_taxed_type,
							0,0,0,0,														--min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
							0,0,@gl_sales_tax_account,												--min_tax_amt, max_tax_amt, sales_tax_acct_code, 
							'','',0,														--ap_tax_acct_code, ar_tax_code, vat_flag,
							1,@gl_internal_tax_account,0												--ap_tax_acct_code, ar_tax_code, vat_flag,
			FROM gltcrates g  
				where g.stateCitySalesRate != '0.00000' and g.zipCode != '' and g.cityAdmin = ''
					and (NOT EXISTS (select tax_type_code from artxtype 
										WHERE artxtype.tax_type_code = (substring(g.stateCode,1,1) + g.zipCode + g.geoCode)))
	-------------------------------------------------------------------------------------
	----------insert tax_type_code and tax_code relationship into artaxdet table----------
		insert into artaxdet (tax_code, sequence_id, tax_type_code, base_id)
		select g.tax_code, 0, substring(g.stateCode,1,1) + g.zipCode + g.geoCode, 0 
		from gltcrates g 
			where g.stateCitySalesRate != '0.00000' and g.zipCode != '' and g.cityAdmin = ''
				and (NOT EXISTS (select tax_type_code from artaxdet 
									WHERE artaxdet.tax_type_code = (substring(g.stateCode,1,1) + g.zipCode + g.geoCode)))
	--------------------------------------------------------------------------------------
	




	


	--------update tax_type_code into artxtype table with the new county rate info-----------
	update artxtype set amt_tax = cast(g.cityTransitSalesRate as float)
		FROM gltcrates g 
				where  g.cityTransitSalesRate != '0.00000' and g.zipCode != '' and g.cityAdmin = ''
					and artxtype.tax_type_code = 'T' + g.zipCode + g.geoCode 
					and artxtype.amt_tax != cast(g.cityTransitSalesRate as float) * 100
	---------------------------------------------------------------------------------------
	----------------------------tax_type_code by city-----------------------------------
	insert into artxtype (external_tax_type_code,
								tax_type_code, tax_type_desc, tax_auth_code,
								amt_tax, prc_flag, prc_type, cents_code_flag, 
								cents_code, tax_based_type, tax_included_flag, 
								modify_base_prc, base_range_flag, base_range_type,base_taxed_type,
								min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
								min_tax_amt, max_tax_amt, sales_tax_acct_code, 
								ap_tax_acct_code, ar_tax_code, vat_flag, 
								recoverable_flag, gl_internal_tax_account, tax_connect_flag)
			SELECT distinct 'T' + g.stateCode + g.zipCode + g.geoCode + g.countyCode,											--external_tax_type_code,
							'T' + g.zipCode + g.geoCode, 'T-' +  g.zipCode + '-' + g.stateCityName, @tax_auth_code, --tax_type_code, tax_type_desc, tax_auth_code,
							cast(g.cityTransitSalesRate as float) * 100, 1,0,0,						--amt_tax, prc_flag, prc_type, cents_code_flag,
							'',0,0,															--cents_code, tax_based_type, tax_included_flag,
							100,0,0,0,														--modify_base_prc, base_range_flag, base_range_type, base_taxed_type,
							0,0,0,0,														--min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
							0,0,@gl_sales_tax_account,												--min_tax_amt, max_tax_amt, sales_tax_acct_code, 
							'','',0,														--ap_tax_acct_code, ar_tax_code, vat_flag,
							1,@gl_internal_tax_account,0												--ap_tax_acct_code, ar_tax_code, vat_flag,
			FROM gltcrates g  
				where  g.cityTransitSalesRate != '0.00000' and g.zipCode != '' and g.cityAdmin = ''
					and (NOT EXISTS (select tax_type_code from artxtype 
										WHERE artxtype.tax_type_code = ('T' + g.zipCode + g.geoCode)))
	-------------------------------------------------------------------------------------
	----------insert tax_type_code and tax_code relationship into artaxdet table----------
	insert into artaxdet (tax_code, sequence_id, tax_type_code, base_id)
		select g.tax_code, 0, g.zipCode + g.countyCode, 0 
		from gltcrates g 
			where g.cityTransitSalesRate != '0.00000' and g.zipCode != '' and g.cityAdmin = ''
				and (NOT EXISTS (select tax_type_code from artaxdet 
									WHERE artaxdet.tax_type_code = ('T' + g.zipCode + g.geoCode)))
	--------------------------------------------------------------------------------------
	





	



	--------update tax_type_code into artxtype table with the new county rate info-----------
	update artxtype set amt_tax = cast(g.countyTransitSalesRate as float)
		FROM gltcrates g 
				where g.countyTransitSalesRate != '0.00000' and g.zipCode != '' and g.countyAdmin = ''
					and artxtype.tax_type_code = 'C' + g.stateCode + g.countyCode
					and artxtype.amt_tax != cast(g.countyTransitSalesRate as float) * 100
	---------------------------------------------------------------------------------------
	----------------------------tax_type_code by city-----------------------------------
	insert into artxtype (external_tax_type_code,
								tax_type_code, tax_type_desc, tax_auth_code,
								amt_tax, prc_flag, prc_type, cents_code_flag, 
								cents_code, tax_based_type, tax_included_flag, 
								modify_base_prc, base_range_flag, base_range_type,base_taxed_type,
								min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
								min_tax_amt, max_tax_amt, sales_tax_acct_code, 
								ap_tax_acct_code, ar_tax_code, vat_flag, 
								recoverable_flag, gl_internal_tax_account, tax_connect_flag)
			SELECT distinct 'C' + g.stateCode + g.countyCode,												--external_tax_type_code,
							'C' + g.stateCode + g.countyCode,  'C-' + g.countyCode + '-' + g.countyName, @tax_auth_code, --tax_type_code, tax_type_desc, tax_auth_code,
							cast(g.countyTransitSalesRate as float) * 100, 1,0,0,						--amt_tax, prc_flag, prc_type, cents_code_flag,
							'',0,0,															--cents_code, tax_based_type, tax_included_flag,
							100,0,0,0,														--modify_base_prc, base_range_flag, base_range_type, base_taxed_type,
							0,0,0,0,														--min_base_amt, max_base_amt, tax_range_flag, tax_range_type,
							0,0,@gl_sales_tax_account,												--min_tax_amt, max_tax_amt, sales_tax_acct_code, 
							'','',0,														--ap_tax_acct_code, ar_tax_code, vat_flag,
							1,@gl_internal_tax_account,0												--ap_tax_acct_code, ar_tax_code, vat_flag,
			FROM gltcrates g  
				where g.countyTransitSalesRate != '0.00000' and g.zipCode != '' and g.countyAdmin = ''
					and (NOT EXISTS (select tax_type_code from artxtype 
										WHERE artxtype.tax_type_code = ('C' + g.stateCode + g.countyCode)))
	-------------------------------------------------------------------------------------
	----------insert tax_type_code and tax_code relationship into artaxdet table----------
		insert into artaxdet (tax_code, sequence_id, tax_type_code, base_id )
		select g.tax_code, 0, 'C' + g.stateCode + g.countyCode, 0
		from gltcrates g 
			where g.countyTransitSalesRate != '0.00000' and g.zipCode != '' and g.countyAdmin = ''
				and (NOT EXISTS (select tax_type_code from artaxdet 
									WHERE artaxdet.tax_type_code = ('C' + g.stateCode + g.countyCode)))
	--------------------------------------------------------------------------------------
	



END
                                              
GO
GRANT EXECUTE ON  [dbo].[gltc_import_rates_sp] TO [public]
GO
