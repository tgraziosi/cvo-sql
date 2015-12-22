SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[glebphda_sp] 
		@from_date		int,
		@to_date		int,
		@v_from_org_id          varchar(30),
		@v_to_org_id          varchar(30)
as
begin
	

	
	
	delete
	from	glebhold
	where	din = ''
	and	to_date > @to_date

	

	update	glebhold
	set	to_date = @to_date
	where	din = ''
		


	

	

	insert	glebhold
	select	artrxcdt.trx_ctrl_num,
		artrx.doc_ctrl_num,
		artrxcdt.sequence_id,
		'G1 Total Revenue - Invoice & ATF Invoice lines using taxtypes mapping to ALL AR Australian Tax Types',
		artrxcdt.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,							
		artrx.date_applied,						
		round((artrxcdt.extended_price + (case artxtype.tax_included_flag when 1 then 0 else artrxcdt.calc_tax end)) * (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		'',
		@to_date,
		artrx.org_id 
	from	artrx,
		artrxcdt,
		artaxdet,
		artax,
		artxtype,
		glastxmp
	where	artrxcdt.trx_ctrl_num = artrx.trx_ctrl_num
	and	(
		
			artrx.trx_type = 2031
		)
	and	artrxcdt.tax_code = artaxdet.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTFRAR' or
			glastxmp.aust_tax_type = 'GSTAR' or
			glastxmp.aust_tax_type = 'INPTAXAR' or
			glastxmp.aust_tax_type = 'EXPORT'
		)
	and	artrx.date_applied between @from_date and @to_date



	


	
	insert	glebhold
	select  artrx.trx_ctrl_num,
		artrx.doc_ctrl_num,
		1,
		'G1 Total Revenue - Invoices using taxtypes mapping to ALL AR Australian Tax Types',
		artrx.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,							
		artrx.date_applied,						
		round ((artrx.amt_gross + artrx.amt_tax)* (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		' ',
		@to_date,
		artrx.org_id 
	from 	artrx,
		artaxdet,
		artrxcdt,
		artax,
		artxtype,
		glastxmp
	where 	artrx.trx_type = 2021
	and	artrx.trx_ctrl_num = artrxcdt.trx_ctrl_num
	and	artrx.tax_code = artaxdet.tax_code
	and 	artaxdet.tax_code = artax.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTFRAR' or
			glastxmp.aust_tax_type = 'GSTAR' or
			glastxmp.aust_tax_type = 'INPTAXAR' or
			glastxmp.aust_tax_type = 'EXPORT'
		)
	and	artrx.date_applied between @from_date and @to_date



	
	insert	glebhold
	select	artrxcdt.trx_ctrl_num,
		artrx.doc_ctrl_num,
		artrxcdt.sequence_id,
		'G2 Exports - Invoice & ATF Invoice lines using taxtypes mapping to EXPORT',
		artrxcdt.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,						
		artrx.date_applied,					
		round((artrxcdt.extended_price + (case artxtype.tax_included_flag when 1 then 0 else artrxcdt.calc_tax end)) * (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		'',
		@to_date,
		artrx.org_id 
	from	artrx,
		artrxcdt,
		artaxdet,
		artax,
		artxtype,
		glastxmp
	where	artrxcdt.trx_ctrl_num = artrx.trx_ctrl_num
	and	(
		
			artrx.trx_type = 2031
		)
	and	artrxcdt.tax_code = artaxdet.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'EXPORT'
	and	artrx.date_applied between @from_date and @to_date




	
	insert	glebhold
	select	artrx.trx_ctrl_num,
		artrx.doc_ctrl_num,
		1,
		'G2 Exports - Invoices using taxtypes mapping to EXPORT',
		artrx.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,						
		artrx.date_applied,					
		round ((artrx.amt_gross + artrx.amt_tax)* (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		'',
		@to_date,
		artrx.org_id 
	from	artrx,
		artaxdet,
		artrxcdt,
		artax,
		artxtype,
		glastxmp
	where	artrx.trx_type = 2021
	and	artrx.trx_ctrl_num = artrxcdt.trx_ctrl_num
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artrx.tax_code = artaxdet.tax_code
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'EXPORT'
	and	artrx.date_applied between @from_date and @to_date


	
	
	insert	glebhold
	select	artrxcdt.trx_ctrl_num,
		artrx.doc_ctrl_num,
		artrxcdt.sequence_id,
		'G3 Other GST Free - Invoice & ATF Invoice lines using taxtypes mapping to GSTFRAR',
		artrxcdt.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,						
		artrx.date_applied,					
		round((artrxcdt.extended_price + (case artxtype.tax_included_flag when 1 then 0 else artrxcdt.calc_tax end)) * (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		'',
		@to_date,
		artrx.org_id 
	from	artrx,
		artrxcdt,
		artaxdet,
		artax,
		artxtype,
		glastxmp
	where	artrxcdt.trx_ctrl_num = artrx.trx_ctrl_num
	and	(
		
			artrx.trx_type = 2031
		)
	and	artrxcdt.tax_code = artaxdet.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'GSTFRAR'
	and	artrx.date_applied between @from_date and @to_date



	
	insert	glebhold
	select	artrx.trx_ctrl_num,
		artrx.doc_ctrl_num,
		1,
		'G3 Other GST Free - Invoices using taxtypes mapping to GSTFRAR',
		artrx.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,						
		artrx.date_applied,					
		round ((artrx.amt_gross + artrx.amt_tax)* (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		'',
		@to_date,
		artrx.org_id 
	from	artrx,
		artaxdet,
		artrxcdt,
		artax,
		artxtype,
		glastxmp
	where	artrx.trx_type = 2021
	and	artrx.tax_code = artaxdet.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artrx.trx_ctrl_num = artrxcdt.trx_ctrl_num
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'GSTFRAR'
	and	artrx.date_applied between @from_date and @to_date


	
	
	insert	glebhold
	select	artrxcdt.trx_ctrl_num,
		artrx.doc_ctrl_num,
		artrxcdt.sequence_id,
		'G4 Input Taxed Sales & Other Supplies - Invoice & ATF Invoice lines using taxtypes mapping to INPTAXAR',
		artrxcdt.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,					
		artrx.date_applied,				
		round((artrxcdt.extended_price + (case artxtype.tax_included_flag when 1 then 0 else artrxcdt.calc_tax end)) * (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		'',
		@to_date,
		artrx.org_id 
	from	artrx,
		artrxcdt,
		artaxdet,
		artax,
		artxtype,
		glastxmp
	where	artrxcdt.trx_ctrl_num = artrx.trx_ctrl_num
	and	(
		
			artrx.trx_type = 2031
		)
	and	artrxcdt.tax_code = artaxdet.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'INPTAXAR'
	and	artrx.date_applied between @from_date and @to_date


	
	
	insert	glebhold
	select	artrx.trx_ctrl_num,
		artrx.doc_ctrl_num,
		1,
		'G4 Input Taxed Sales & Other Supplies - Invoices using taxtypes mapping to INPTAXAR',
		artrx.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,					
		artrx.date_applied,				
		round ((artrx.amt_gross + artrx.amt_tax)* (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		'',
		@to_date,
		artrx.org_id 
	from	artrx,
		artaxdet,
		artrxcdt,
		artax,
		artxtype,
		glastxmp
	where	artrx.trx_type = 2021
	and	artrx.trx_ctrl_num = artrxcdt.trx_ctrl_num
	and	artrx.tax_code = artaxdet.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'INPTAXAR'
	and	artrx.date_applied between @from_date and @to_date



	
	insert	glebhold
	select	artrxcdt.trx_ctrl_num,
		artrx.doc_ctrl_num,
		artrxcdt.sequence_id,
		'G18 Adjustments - Credit Memos lines using taxtypes mapping to GSTAR',
		artrxcdt.tax_code,
		artaxdet.tax_type_code,
		artrx.date_doc,
		artrxcdt.calc_tax,					
		artrx.date_applied,				
		round((artrxcdt.extended_price + (case artxtype.tax_included_flag when 1 then 0 else artrxcdt.calc_tax end)) * (case when sign(artrx.rate_home) = 1.0 then artrx.rate_home else 1/(artrx.rate_home * -1.0) end),2),
		'',
		@to_date,
		artrx.org_id 
	from	artrx,
		artrxcdt,
		artaxdet,
		artax,
		artxtype,
		glastxmp
	where	artrxcdt.trx_ctrl_num = artrx.trx_ctrl_num
	and	artrx.trx_type = 2032
	and	artrxcdt.tax_code = artaxdet.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	(
		glastxmp.aust_tax_type = 'GSTAR'  
		)
	and	artrx.date_applied between @from_date and @to_date


	

	insert	glebhold
	select	apdmdet.trx_ctrl_num,
		apdmhdr.doc_ctrl_num,
		apdmdet.sequence_id,
		'G7 Adjustments - Debit Memo lines using taxtypes mapping to GSTAP, CAPACQ, GSTAPNDA',
		apdmdet.tax_code,
		aptaxdet.tax_type_code,
		apdmhdr.date_doc,
		apdmdet.calc_tax,				
		apdmhdr.date_applied,				
		round((apdmdet.amt_extended + (case aptxtype.tax_included_flag when 1 then 0 else apdmdet.calc_tax end) - apdmdet.amt_discount) * (case when sign(apdmhdr.rate_home) = 1.0 then apdmhdr.rate_home else 1/(apdmhdr.rate_home * -1.0) end),2),
		'',
		@to_date,
		apdmhdr.org_id 
	from	apdmhdr,
		apdmdet,
		aptaxdet,
		aptax,
		aptxtype,
		glastxmp
	where	apdmdet.trx_ctrl_num = apdmhdr.trx_ctrl_num
	and	apdmdet.tax_code = aptaxdet.tax_code
	and	aptaxdet.tax_code = aptax.tax_code
	and     apdmhdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTAP' or
			glastxmp.aust_tax_type = 'CAPACQ' or
			glastxmp.aust_tax_type = 'GSTAPNDA'

		)
	and	apdmhdr.date_applied between @from_date and @to_date	
	
	
	insert	glebhold
	select	apvodet.trx_ctrl_num,
		apvohdr.doc_ctrl_num,
		apvodet.sequence_id,
		'G10 Capital Acquisitions - Voucher lines using taxtypes mapping to CAPACQ',
		apvodet.tax_code,
		aptaxdet.tax_type_code,
		apvohdr.date_doc,
		apvodet.calc_tax,				
		apvohdr.date_applied,				
		round((apvodet.amt_extended + (case aptxtype.tax_included_flag when 1 then 0 else apvodet.calc_tax end) - apvodet.amt_discount) * (case when sign(apvohdr.rate_home) = 1.0 then apvohdr.rate_home else 1/(apvohdr.rate_home * -1.0) end),2),
		'',
		@to_date,
		apvohdr.org_id 
	from	apvohdr,
		apvodet,
		aptaxdet,
		aptax,
		aptxtype,
		glastxmp
	where	apvodet.trx_ctrl_num = apvohdr.trx_ctrl_num
	and	apvodet.tax_code = aptaxdet.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptaxdet.tax_code = aptax.tax_code
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'CAPACQ'
	and	apvohdr.date_applied between @from_date and @to_date


	
	
	insert	glebhold
	select	apvodet.trx_ctrl_num,
		apvohdr.doc_ctrl_num,
		apvodet.sequence_id,
		'G11 Other Acquisitions - Voucher lines using taxtypes mapping to GSTAP, INPTAXAP, GSTFRAP, PAYGWH',
		apvodet.tax_code,
		aptaxdet.tax_type_code,
		apvohdr.date_doc,
		apvodet.calc_tax,					
		apvohdr.date_applied,					
		round((apvodet.amt_extended + (case aptxtype.tax_included_flag when 1 then 0 else apvodet.calc_tax end) - (case aptaxdet.tax_type_code when 'PAYGWH' then 0 else apvodet.amt_discount end)) * (case when sign(apvohdr.rate_home) = 1.0 then apvohdr.rate_home else 1/(apvohdr.rate_home * -1.0) end),2),
		'',
		@to_date,
		apvohdr.org_id 
	from	apvohdr,
		apvodet,
		aptaxdet,
		aptax,
		aptxtype,
		glastxmp
	where	apvodet.trx_ctrl_num = apvohdr.trx_ctrl_num
	and	apvodet.tax_code = aptaxdet.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptaxdet.tax_code = aptax.tax_code
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTFRAP' or
			glastxmp.aust_tax_type = 'GSTAP' or
			glastxmp.aust_tax_type = 'INPTAXAP' or
			glastxmp.aust_tax_type = 'PAYGWH'
		)
	and	apvohdr.date_applied between @from_date and @to_date

	
	
	insert	glebhold
	select	apvodet.trx_ctrl_num,
		apvohdr.doc_ctrl_num,
		apvodet.sequence_id,
		'G13 Input Taxed Sales - Voucher lines using taxtypes mapping to INPTAXAP',
		apvodet.tax_code,
		aptaxdet.tax_type_code,
		apvohdr.date_doc,
		apvodet.calc_tax,					
		apvohdr.date_applied,					
		round((apvodet.amt_extended + (case aptxtype.tax_included_flag when 1 then 0 else apvodet.calc_tax end) - apvodet.amt_discount) * (case when sign(apvohdr.rate_home) = 1.0 then apvohdr.rate_home else 1/(apvohdr.rate_home * -1.0) end),2),
		'',
		@to_date,
		apvohdr.org_id 
	from	apvohdr,
		apvodet,
		aptaxdet,
		aptax,
		aptxtype,
		glastxmp
	where	apvodet.trx_ctrl_num = apvohdr.trx_ctrl_num
	and	apvodet.tax_code = aptaxdet.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptaxdet.tax_code = aptax.tax_code
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'INPTAXAP'
	and	apvohdr.date_applied between @from_date and @to_date
	
	
	insert	glebhold
	select	apvodet.trx_ctrl_num,
		apvohdr.doc_ctrl_num,
		apvodet.sequence_id,
		'G14 Acquisitions with no GST in the price - Voucher lines using taxtypes mapping to GSTFRAP, PAYGWH',
		apvodet.tax_code,
		aptaxdet.tax_type_code,
		apvohdr.date_doc,
		apvodet.calc_tax,					
		apvohdr.date_applied,					
		round((apvodet.amt_extended + (case aptxtype.tax_included_flag when 1 then 0 else apvodet.calc_tax end) - (case aptaxdet.tax_type_code when 'PAYGWH' then 0 else apvodet.amt_discount end)) * (case when sign(apvohdr.rate_home) = 1.0 then apvohdr.rate_home else 1/(apvohdr.rate_home * -1.0) end),2),
		'',
		@to_date,
		apvohdr.org_id 
	from	apvohdr,
		apvodet,
		aptaxdet,
		aptax,
		aptxtype,
		glastxmp
	where	apvodet.trx_ctrl_num = apvohdr.trx_ctrl_num
	and	apvodet.tax_code = aptaxdet.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptaxdet.tax_code = aptax.tax_code
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTFRAP' or
			glastxmp.aust_tax_type = 'PAYGWH'
		)
	and	apvohdr.date_applied between @from_date and @to_date
		
	
	insert	glebhold
	select	apvodet.trx_ctrl_num,
		apvohdr.doc_ctrl_num,
		apvodet.sequence_id,
		'G15 Non-Income Tax Deductible Acquisitions - Vouchers using all taxtypes mapping to GSTAPNDA',
		apvodet.tax_code,
		aptaxdet.tax_type_code,
		apvohdr.date_doc,
		apvodet.calc_tax,					
		apvohdr.date_applied,					
		round((apvodet.amt_extended + (case aptxtype.tax_included_flag when 1 then 0 else apvodet.calc_tax end) - (case aptaxdet.tax_type_code when 'PAYGWH' then 0 else apvodet.amt_discount end)) * (case when sign(apvohdr.rate_home) = 1.0 then apvohdr.rate_home else 1/(apvohdr.rate_home * -1.0) end),2),
		'',
		@to_date,
		apvohdr.org_id 
	from	apvohdr,
		apvodet,
		aptaxdet,
		aptax,
		aptxtype,
		glastxmp
	where	apvodet.trx_ctrl_num = apvohdr.trx_ctrl_num
	and	apvodet.tax_code = aptaxdet.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptaxdet.tax_code = aptax.tax_code
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTAPNDA'
		)
	and	apvohdr.date_applied between @from_date and @to_date


	
	insert	glebhold
	select	apvodet.trx_ctrl_num,
		apvohdr.doc_ctrl_num,
		apvodet.sequence_id,
		'W4 PAYG Witholding Tax - Discounted amount on voucher lines using taxtypes mapping to PAYGWH',
		apvodet.tax_code,
		aptaxdet.tax_type_code,
		apvohdr.date_doc,
		apvodet.calc_tax,					
		apvohdr.date_applied,					
		round((apvodet.amt_extended * 0.485) * (case when sign(apvohdr.rate_home) = 1.0 then apvohdr.rate_home else 1/(apvohdr.rate_home * -1.0) end),2),
		'',
		@to_date,
		apvohdr.org_id 
	from	apvohdr,
		apvodet,
		aptaxdet,
		aptax,
		aptxtype,
		glastxmp
	where	apvodet.trx_ctrl_num = apvohdr.trx_ctrl_num
	and	apvodet.tax_code = aptaxdet.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptaxdet.tax_code = aptax.tax_code
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'PAYGWH'
	and	apvohdr.date_applied between @from_date and @to_date


end
GO
GRANT EXECUTE ON  [dbo].[glebphda_sp] TO [public]
GO
