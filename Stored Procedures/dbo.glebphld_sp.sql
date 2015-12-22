SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[glebphld_sp] 
		@to_date		int,
		@v_from_org_id          varchar(30),
		@v_to_org_id          varchar(30)
			

as
begin

	declare	@ap_from_date		int,
		@ar_from_date		int,
		@ap_days_before_purge	int,
		@ar_days_before_purge	int,
		@i_today		int
		

	
	
	exec appdate_sp	@i_today output


	

	select	@ap_days_before_purge = days_before_purge
	from	apco

	select	@ap_from_date = @i_today - @ap_days_before_purge

	

	select	@ar_days_before_purge = days_before_purge
	from	arco

	select	@ar_from_date = @i_today - @ar_days_before_purge


	
	
	insert	glebhoar
	select	trx_ctrl_num,
		doc_ctrl_num,
		sequence_id,
		ebas_key,
		tax_code,
		tax_type_code,
		date_doc,
		amt_tax,					
		date_applied,					
		amount,
		din,
		to_date,
		@i_today
	from	glebhold
	where	date_doc < @ap_from_date
	and	(
			ebas_key = 'G10' or
			ebas_key = 'G11' or
			ebas_key = 'G13' or
			ebas_key = 'G14' or
			ebas_key = 'G15' or
			ebas_key = 'G7' or
			ebas_key = 'W4'
		)


	delete
	from	glebhold
	where	date_doc < @ap_from_date
	and	(
			ebas_key = 'G10' or
			ebas_key = 'G11' or
			ebas_key = 'G13' or
			ebas_key = 'G14' or
			ebas_key = 'G15' or
			ebas_key = 'G7' or
			ebas_key = 'W4'
		)


	insert	glebhoar
	select	trx_ctrl_num,
		doc_ctrl_num,
		sequence_id,
		ebas_key,
		tax_code,
		tax_type_code,
		date_doc,
		amt_tax,					
		date_applied,					
		amount,
		din,
		to_date,
		@i_today
	from	glebhold
	where	date_doc < @ar_from_date
	and	(
			ebas_key = 'G1' or
			ebas_key = 'G2' or
			ebas_key = 'G3' or
			ebas_key = 'G4' or
			ebas_key = 'G18'		
		)

	delete
	from	glebhold
	where	date_doc < @ar_from_date
	and	(
			ebas_key = 'G1' or
			ebas_key = 'G2' or
			ebas_key = 'G3' or
			ebas_key = 'G4' or
			ebas_key = 'G18'
		)


	
	
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
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
        and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTFRAR' or
			glastxmp.aust_tax_type = 'GSTAR' or
			glastxmp.aust_tax_type = 'INPTAXAR' or
			glastxmp.aust_tax_type = 'EXPORT'
		)
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrxcdt.trx_ctrl_num = glebhold.trx_ctrl_num
			      and artrxcdt.sequence_id = glebhold.sequence_id
			      and 'G1 ' = substring(glebhold.ebas_key,1,3))
--	and	artrxcdt.trx_ctrl_num + convert(varchar(20),artrxcdt.sequence_id) + "G1 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by artrxcdt.trx_ctrl_num, artrxcdt.sequence_id

	  


	

         
	
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
	and	artax.tax_code = glastxmp.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTFRAR' or
			glastxmp.aust_tax_type = 'GSTAR' or
			glastxmp.aust_tax_type = 'INPTAXAR' or
			glastxmp.aust_tax_type = 'EXPORT'
		)
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrx.trx_ctrl_num = glebhold.trx_ctrl_num
			      and 1 = glebhold.sequence_id
			      and 'G1 ' = substring(glebhold.ebas_key,1,3))
--	and	artrx.trx_ctrl_num + convert(varchar(20), 1) + "G1 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)




	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G1 Total Revenue - Invoice & ATF Invoice lines using taxtypes mapping to ALL AR Australian Tax Types',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'GSTFRAR' or
				g.aust_tax_type = 'GSTAR' or
				g.aust_tax_type = 'INPTAXAR' or
				g.aust_tax_type = 'EXPORT'
			)
	WHERE 
		h.trx_type IN ( 2031, 2021)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ar_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G1 ' = substring(glebhold.ebas_key,1,3))




	
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
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrxcdt.trx_ctrl_num = glebhold.trx_ctrl_num
			      and artrxcdt.sequence_id = glebhold.sequence_id
			      and 'G2 ' = substring(glebhold.ebas_key,1,3))
--	and	artrxcdt.trx_ctrl_num + convert(varchar(20),artrxcdt.sequence_id) + "G2 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by artrxcdt.trx_ctrl_num, artrxcdt.sequence_id




	
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
	and	artrx.tax_code = artaxdet.tax_code
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'EXPORT'
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrx.trx_ctrl_num = glebhold.trx_ctrl_num
			      and 1 = glebhold.sequence_id
			      and 'G2 ' = substring(glebhold.ebas_key,1,3))
--	and	artrx.trx_ctrl_num + convert(varchar(20), 1) + "G2 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)






	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G2 Exports - Invoices using taxtypes mapping to EXPORT',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'EXPORT'
			)
	WHERE 
		h.trx_type IN ( 2031, 2021)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ar_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G2 ' = substring(glebhold.ebas_key,1,3))


	
	
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
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrxcdt.trx_ctrl_num = glebhold.trx_ctrl_num
			      and artrxcdt.sequence_id = glebhold.sequence_id
			      and 'G3 ' = substring(glebhold.ebas_key,1,3))
--	and	artrxcdt.trx_ctrl_num + convert(varchar(20),artrxcdt.sequence_id) + "G3 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by artrxcdt.trx_ctrl_num, artrxcdt.sequence_id



	
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
	and	artrx.trx_ctrl_num = artrxcdt.trx_ctrl_num
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artrx.tax_code = artaxdet.tax_code
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'GSTFRAR'
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrx.trx_ctrl_num = glebhold.trx_ctrl_num
			      and 1 = glebhold.sequence_id
			      and 'G3 ' = substring(glebhold.ebas_key,1,3))
--	and	artrx.trx_ctrl_num + convert(varchar(20), 1) + "G3 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)




	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G3 Other GST Free - Invoices using taxtypes mapping to GSTFRAR',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'GSTFRAR'
			)
	WHERE 
		h.trx_type IN ( 2031, 2021)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ar_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G3 ' = substring(glebhold.ebas_key,1,3))


	
	
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
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrxcdt.trx_ctrl_num = glebhold.trx_ctrl_num
			      and artrxcdt.sequence_id = glebhold.sequence_id
			      and 'G4 ' = substring(glebhold.ebas_key,1,3))
--	and	artrxcdt.trx_ctrl_num + convert(varchar(20),artrxcdt.sequence_id) + "G4 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by artrxcdt.trx_ctrl_num, artrxcdt.sequence_id


	
	
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
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrx.trx_ctrl_num = glebhold.trx_ctrl_num
			      and 1 = glebhold.sequence_id
			      and 'G4 ' = substring(glebhold.ebas_key,1,3))
--	and	artrx.trx_ctrl_num + convert(varchar(20), 1) + "G4 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)






	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G4 Input Taxed Sales & Other Supplies - Invoices using taxtypes mapping to INPTAXAR',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'INPTAXAR'
			)
	WHERE 
		h.trx_type IN ( 2031, 2021)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ar_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G4 ' = substring(glebhold.ebas_key,1,3))

	
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
	and     artrx.org_id between @v_from_org_id and @v_to_org_id   
	and	artrxcdt.tax_code = artaxdet.tax_code
	and	artaxdet.tax_code = artax.tax_code
	and	artax.tax_code = glastxmp.tax_code
	and	artxtype.tax_type_code = artaxdet.tax_type_code
	and	(
		glastxmp.aust_tax_type = 'GSTAR'
		)
	and	artrx.date_doc between @ar_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where artrxcdt.trx_ctrl_num = glebhold.trx_ctrl_num
			      and artrxcdt.sequence_id = glebhold.sequence_id
			      and 'G18' = substring(glebhold.ebas_key,1,3))
--	and	artrxcdt.trx_ctrl_num + convert(varchar(20),artrxcdt.sequence_id) + "G18 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by artrxcdt.trx_ctrl_num, artrxcdt.sequence_id




	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G18 Adjustments - Credit Memos lines using taxtypes mapping to GSTAR',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'GSTAR'
			)
	WHERE 
		h.trx_type IN ( 2032)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ar_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G18 ' = substring(glebhold.ebas_key,1,3))


	

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
			glastxmp.aust_tax_type = 'CAPACQ' OR
			glastxmp.aust_tax_type = 'GSTAPNDA' 			
		)
	and	apdmhdr.date_doc between @ap_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where apdmdet.trx_ctrl_num = glebhold.trx_ctrl_num
			      and apdmdet.sequence_id = glebhold.sequence_id
			      and 'G7 ' = substring(glebhold.ebas_key,1,3))
--	and	apdmdet.trx_ctrl_num + convert(varchar(20),apdmdet.sequence_id) + "G7" not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by apdmdet.trx_ctrl_num, apdmdet.sequence_id




	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G7 Adjustments - Debit Memo lines using taxtypes mapping to GSTAP, CAPACQ, GSTAPNDA',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'GSTAP' OR
				g.aust_tax_type = 'CAPACQ' OR
				g.aust_tax_type = 'GSTAPNDA'
			)
	WHERE 
		h.trx_type IN ( 4092)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ap_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G7 ' = substring(glebhold.ebas_key,1,3))



	
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
	and	aptaxdet.tax_code = aptax.tax_code
	and	aptax.tax_code = glastxmp.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'CAPACQ'
	and	apvohdr.date_doc between @ap_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where apvodet.trx_ctrl_num = glebhold.trx_ctrl_num
			      and apvodet.sequence_id = glebhold.sequence_id
			      and 'G10' = substring(glebhold.ebas_key,1,3))
--	and	apvodet.trx_ctrl_num + convert(varchar(20),apvodet.sequence_id) + "G10" not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by apvodet.trx_ctrl_num, apvodet.sequence_id



	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G10 Capital Acquisitions - Voucher lines using taxtypes mapping to CAPACQ',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'CAPACQ' 
			)
	WHERE 
		h.trx_type IN ( 4091)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ap_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G10 ' = substring(glebhold.ebas_key,1,3))
	
	
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
	and	aptaxdet.tax_code = aptax.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTFRAP' or
			glastxmp.aust_tax_type = 'GSTAP' or
			glastxmp.aust_tax_type = 'INPTAXAP' or
			glastxmp.aust_tax_type = 'PAYGWH'
		)
	and	apvohdr.date_doc between @ap_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where apvodet.trx_ctrl_num = glebhold.trx_ctrl_num
			      and apvodet.sequence_id = glebhold.sequence_id
			      and 'G11' = substring(glebhold.ebas_key,1,3))
--	and	apvodet.trx_ctrl_num + convert(varchar(20),apvodet.sequence_id) + "G11" not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by apvodet.trx_ctrl_num, apvodet.sequence_id




	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G11 Other Acquisitions - Voucher lines using taxtypes mapping to GSTAP, INPTAXAP, GSTFRAP, PAYGWH',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'GSTFRAP' or
				g.aust_tax_type = 'GSTAP' or
				g.aust_tax_type = 'INPTAXAP' or
				g.aust_tax_type = 'PAYGWH'
			)
	WHERE 
		h.trx_type IN ( 4091)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ap_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G11 ' = substring(glebhold.ebas_key,1,3))
	
	
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
	and	aptaxdet.tax_code = aptax.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   	
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	glastxmp.aust_tax_type = 'INPTAXAP'
	and	apvohdr.date_doc between @ap_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where apvodet.trx_ctrl_num = glebhold.trx_ctrl_num
			      and apvodet.sequence_id = glebhold.sequence_id
			      and 'G13' = substring(glebhold.ebas_key,1,3))
--	and	apvodet.trx_ctrl_num + convert(varchar(20),apvodet.sequence_id) + "G13" not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by apvodet.trx_ctrl_num, apvodet.sequence_id





	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G13 Input Taxed Sales - Voucher lines using taxtypes mapping to INPTAXAP',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
				g.aust_tax_type = 'INPTAXAP' 
				)
	WHERE 
		h.trx_type IN ( 4091)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ap_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G13 ' = substring(glebhold.ebas_key,1,3))
	
	
	
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
	and	aptaxdet.tax_code = aptax.tax_code
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   	
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTFRAP' or
			glastxmp.aust_tax_type = 'PAYGWH'
		)
	and	apvohdr.date_doc between @ap_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where apvodet.trx_ctrl_num = glebhold.trx_ctrl_num
			      and apvodet.sequence_id = glebhold.sequence_id
			      and 'G14' = substring(glebhold.ebas_key,1,3))
--	and	apvodet.trx_ctrl_num + convert(varchar(20),apvodet.sequence_id) + "G14" not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by apvodet.trx_ctrl_num, apvodet.sequence_id




	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G14 Acquisitions with no GST in the price - Voucher lines using taxtypes mapping to GSTFRAP, PAYGWH',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
					g.aust_tax_type = 'GSTFRAP' or
					g.aust_tax_type = 'PAYGWH'
				)
	WHERE 
		h.trx_type IN ( 4091)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ap_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G14 ' = substring(glebhold.ebas_key,1,3))
		
	
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
	and     apvohdr.org_id between @v_from_org_id and @v_to_org_id   
	and	apvodet.tax_code = aptaxdet.tax_code
	and	aptaxdet.tax_code = aptax.tax_code
	and	aptax.tax_code = glastxmp.tax_code
	and	aptxtype.tax_type_code = aptaxdet.tax_type_code
	and	(
			glastxmp.aust_tax_type = 'GSTAPNDA'
		)
	and	apvohdr.date_doc between @ap_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where apvodet.trx_ctrl_num = glebhold.trx_ctrl_num
			      and apvodet.sequence_id = glebhold.sequence_id
			      and 'G15' = substring(glebhold.ebas_key,1,3))
--	and	apvodet.trx_ctrl_num + convert(varchar(20),apvodet.sequence_id) + "G15" not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by apvodet.trx_ctrl_num, apvodet.sequence_id
		




	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'G15 Non-Income Tax Deductible Acquisitions - Vouchers using all taxtypes mapping to GSTAPNDA',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
					g.aust_tax_type = 'GSTAPNDA' 
				)
	WHERE 
		h.trx_type IN ( 4091)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ap_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'G15 ' = substring(glebhold.ebas_key,1,3))
		

	
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
	and	apvohdr.date_doc between @ap_from_date and @to_date
	and	not exists (select 1 from glebhold	--mod003
			    where apvodet.trx_ctrl_num = glebhold.trx_ctrl_num
			      and apvodet.sequence_id = glebhold.sequence_id
			      and 'W4 ' = substring(glebhold.ebas_key,1,3))
--	and	apvodet.trx_ctrl_num + convert(varchar(20),apvodet.sequence_id) + "W4 " not in (select trx_ctrl_num + convert(varchar(20),sequence_id) + substring(ebas_key,1,3) from glebhold)
--	order by apvodet.trx_ctrl_num, apvodet.sequence_id





	insert	glebhold
	select	h.trx_ctrl_num,
		l.source_trx_ctrl_num,
		l.source_sequence_id,
		'W4 PAYG Witholding Tax - Discounted amount on voucher lines using taxtypes mapping to PAYGWH',
		h.tax_code,
		t.tax_type_code,
		datediff( day, '01/01/1900', date_applied) + 693596,
		t.amt_tax,							
		datediff( day, '01/01/1900', date_applied) + 693596,						
		round(amt_taxable+amt_tax * (case when sign(t.rate_home) = 1.0 then t.rate_home else 1/(t.rate_home * -1.0) end),2),
		'',
		@to_date,
		h.controlling_org_id	
	 FROM ibhdr h
		INNER JOIN ibtax t
			ON h.id = t.id
		INNER JOIN iblink l
			ON h.id = l.id
			AND l.sequence_id =0
		INNER JOIN glastxmp g
			ON h.tax_code = h.tax_code
			AND (
					g.aust_tax_type = 'PAYGWH' 
				)
	WHERE 
		h.trx_type IN ( 4091)
		AND h.controlling_org_id between @v_from_org_id and @v_to_org_id  
		AND datediff( day, '01/01/1900', date_applied) + 693596 between @ap_from_date and @to_date
		AND NOT EXISTS (select 1 from glebhold	
			    where l.trx_ctrl_num = glebhold.trx_ctrl_num
			      and l.source_sequence_id = glebhold.sequence_id
			      and 'W4 ' = substring(glebhold.ebas_key,1,3))

end
GO
GRANT EXECUTE ON  [dbo].[glebphld_sp] TO [public]
GO
