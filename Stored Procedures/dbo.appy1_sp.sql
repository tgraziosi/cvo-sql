SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                


/*
exec appy1_sp 'vendor_code like "%comopt"'
*/












CREATE proc [dbo].[appy1_sp] @WhereClause varchar(1024)="" as
DECLARE
	@CM_interfaced 		smallint,
	@Sub1			varchar(1024),
	@Sub2			varchar(1024),
	@Sub3			varchar(1024),
	@firstQuote 		smallint,
	@secondQuote		smallint,
	@fourthQuote		smallint,
	@payment_doc_no		varchar(16),
	@payment_doc_no1	varchar(16),
	@payment_doc_no2	varchar(16),
	@payment_ctrl_no	varchar(16),
	@payment_ctrl_no1	varchar(16),
	@payment_ctrl_no2	varchar(16),
	@payment_ctrl_no_criteria	varchar(255), 
	@payment_doc_no_criteria	varchar(255), 
	@where_payment_ctrl_no	varchar(255), 
	@where_payment_doc_no	varchar(255), 
	@OrderBy		varchar(255)

SELECT @payment_ctrl_no_criteria = NULL
SELECT @payment_doc_no_criteria = NULL
SELECT @where_payment_ctrl_no = NULL
SELECT @where_payment_doc_no = NULL


CREATE TABLE #apvend(
	vendor_code			varchar(12),		vendor_name			varchar(40),
	vendor_short_name	varchar(10),		addr1				varchar (40),
	addr2				varchar(40),		addr3				varchar(40),
	addr4				varchar(40),		addr5				varchar(40),
	addr6				varchar(40),		addr_sort1			varchar(40),
	addr_sort2			varchar(40),		addr_sort3			varchar(40),
	status_type			smallint NULL,		attention_name		varchar(40),
	attention_phone		varchar(30),		contact_name		varchar(40),
	contact_phone		varchar(30),		tlx_twx				varchar(30),
	phone_1				varchar(30),		phone_2				varchar(30),
	pay_to_code			varchar(8),			tax_code			varchar(8),
	terms_code			varchar(8),			fob_code			varchar(8),
	posting_code		varchar(8),			location_code		varchar(10),
	orig_zone_code		varchar(8),			customer_code		varchar(8),
	affiliated_vend_code varchar(12),		alt_vendor_code		varchar(12),
	comment_code		varchar(8),			vend_class_code		varchar(8),
	branch_code			varchar(8),			pay_to_hist_flag	smallint NULL,
	item_hist_flag		smallint NULL,		credit_limit_flag	smallint NULL,
	credit_limit		float NULL,			aging_limit_flag	smallint NULL,	
	aging_limit			smallint NULL,		restock_chg_flag	smallint NULL,
	restock_chg			float,				prc_flag			smallint NULL,
	vend_acct			varchar(20),		tax_id_num			varchar(20),
	flag_1099			smallint NULL,		exp_acct_code		varchar(32),
	amt_max_check		float NULL,			lead_time			smallint NULL,
	one_check_flag		smallint NULL,		dup_voucher_flag	smallint NULL,
	dup_amt_flag		smallint NULL,		code_1099			varchar(8),
	user_trx_type_code	varchar(8),			payment_code		varchar(8),
	address_type		smallint NULL,		limit_by_home		smallint NULL,
	rate_type_home		varchar(8),			rate_type_oper		varchar(8),
	nat_cur_code		varchar(8),			one_cur_vendor		smallint NULL,
	cash_acct_code		varchar(32),		city				varchar(40),
	state				varchar(40),		postal_code			varchar(15),
	country				varchar(40),		freight_code		varchar(10),
	note				varchar(255),		url					varchar(255),
	country_code		varchar(3),			ftp					varchar(255),
	attention_email		varchar(255),		contact_email		varchar(255),
	etransmit_ind		int NULL,			po_item_flag		int NULL, 
	vo_hold_flag		int NULL,			buying_cycle		int NULL, 
	proc_vend_flag		int NULL)

CREATE TABLE #appyhdr (
	trx_ctrl_num		varchar(16),		doc_ctrl_num		varchar(16),
	batch_code			varchar(16),		date_posted			int NULL,
	date_applied		int NULL,			date_doc			int NULL,
	date_entered		int NULL,			vendor_code			varchar(12),
	pay_to_code			varchar(8),			approval_code		varchar(8),	
	cash_acct_code		varchar(32),		payment_code		varchar(8),
	state_flag			smallint NULL,		void_flag			smallint NULL,
	amt_net				float NULL,			amt_discount		float NULL,
	amt_on_acct			float NULL,			payment_type		smallint NULL,
	doc_desc			varchar(40),		user_id				smallint NULL,
	journal_ctrl_num	varchar(16),		print_batch_num		int NULL,
	process_ctrl_num	varchar(16),		currency_code		varchar(8),
	rate_type_home		varchar(8),			rate_type_oper		varchar(8),
	rate_home			float NULL,			rate_oper			float NULL,
	payee_name			varchar(40),		settlement_ctrl_num varchar(16),
	org_id				varchar(30)
)

	insert into #apvend (
		vendor_code,		vendor_name,		vendor_short_name,		addr1,					addr2,				
		addr3,				addr4,				addr5,					addr6,					addr_sort1,
		addr_sort2,			addr_sort3,			status_type,			attention_name,			attention_phone,		
		contact_name,		contact_phone,		tlx_twx,				phone_1,				phone_2,
		pay_to_code,		tax_code,			terms_code,				fob_code,				posting_code,			
		location_code,		orig_zone_code,		customer_code,			affiliated_vend_code,	alt_vendor_code,
		comment_code,		vend_class_code,	branch_code,			pay_to_hist_flag,		item_hist_flag,		
		credit_limit_flag,	credit_limit,		aging_limit_flag,		aging_limit,			restock_chg_flag,
		restock_chg,		prc_flag,			vend_acct,				tax_id_num,				flag_1099,		
		exp_acct_code,		amt_max_check,		lead_time,				one_check_flag,			dup_voucher_flag,
		dup_amt_flag,		code_1099,			user_trx_type_code,		payment_code,			address_type,		
		limit_by_home,		rate_type_home,		rate_type_oper,			nat_cur_code,			one_cur_vendor,
		cash_acct_code,		city,				state,					postal_code,			country,		
		freight_code,		note,				url,					country_code,			ftp,
		attention_email,	contact_email,		etransmit_ind,			po_item_flag,			vo_hold_flag,			
		buying_cycle,		proc_vend_flag)
	select 
		vendor_code,		vendor_name,		vendor_short_name,		addr1,					addr2,				
		addr3,				addr4,				addr5,					addr6,					addr_sort1,
		addr_sort2,			addr_sort3,			status_type,			attention_name,			attention_phone,		
		contact_name,		contact_phone,		tlx_twx,				phone_1,				phone_2,
		pay_to_code,		tax_code,			terms_code,				fob_code,				posting_code,			
		location_code,		orig_zone_code,		customer_code,			affiliated_vend_code,	alt_vendor_code,
		comment_code,		vend_class_code,	branch_code,			pay_to_hist_flag,		item_hist_flag,		
		credit_limit_flag,	credit_limit,		aging_limit_flag,		aging_limit,			restock_chg_flag,
		restock_chg,		prc_flag,			vend_acct,				tax_id_num,				flag_1099,		
		exp_acct_code,		amt_max_check,		lead_time,				one_check_flag,			dup_voucher_flag,
		dup_amt_flag,		code_1099,			user_trx_type_code,		payment_code,			address_type,		
		limit_by_home,		rate_type_home,		rate_type_oper,			nat_cur_code,			one_cur_vendor,
		cash_acct_code,		city,				state,					postal_code,			country,		
		freight_code,		note,				url,					country_code,			ftp,
		attention_email,	contact_email,		etransmit_ind,			po_item_flag,			vo_hold_flag,			
		buying_cycle,		proc_vend_flag	from apvend

	insert into #appyhdr (
		trx_ctrl_num,		doc_ctrl_num,		batch_code,		date_posted,	date_applied,		
		date_doc,			date_entered,		vendor_code,	pay_to_code,	approval_code,	
		cash_acct_code,		payment_code,		state_flag,		void_flag,		amt_net,		
		amt_discount,		amt_on_acct,		payment_type,	doc_desc,		user_id,
		journal_ctrl_num,	print_batch_num,	process_ctrl_num,	currency_code,	rate_type_home,		
		rate_type_oper,		rate_home,			rate_oper,		payee_name,		settlement_ctrl_num, 
		org_id)	
	select 
		trx_ctrl_num,		doc_ctrl_num,		batch_code,		date_posted,		date_applied,		
		date_doc,			date_entered,		vendor_code,	pay_to_code,		approval_code,	
		cash_acct_code,		payment_code,		state_flag,		void_flag,			amt_net,		
		amt_discount,		amt_on_acct,		payment_type,	doc_desc,			user_id,
		journal_ctrl_num,	print_batch_num,	process_ctrl_num, currency_code,	rate_type_home,		
		rate_type_oper,		rate_home,			rate_oper,		payee_name,			settlement_ctrl_num, 
		org_id	from appyhdr
		
create table #Payments 
(
	org_id			varchar(30) NULL,	
	gl_trx_id		varchar(16),		
	vendor_name		varchar(40),		
	vendor_code		varchar(12),		
	pay_to_code		varchar(8),		
	settlement_ctrl_num  	varchar(16) NULL,	
	trx_ctrl_num		varchar(16),		
	doc_ctrl_num		varchar(16),		
	posted_flag		varchar(4),		
	hold_flag		varchar(4),      	
	printed_flag		varchar(4),     	
	approval_flag		varchar(4),    		
	void_flag		varchar(4),		
	cleared_flag		varchar(4) NULL,	
	nat_cur_code		varchar(8),    		
	cash_acct_code		varchar(32),		
	date_doc		int,			
	date_applied		int,			
	date_cleared		int NULL,
	rate  float, -- 033114 tag
	amt_payment_nat float,			
	amt_payment_home float,	-- 033114 tag	
	amt_on_acct		float,			
	amt_disc_taken		float,
	amt_1099		float, -- new field for 1099 reporting
	vend_class_code	varchar(8), -- vendor fields for 1099 and vendor class
	tax_id_num varchar(20),
	flag_1099 smallint,
	code_1099 varchar(8)	
	   		
)
create clustered index py_1 on #Payments (vendor_name,vendor_code,doc_ctrl_num)


-- select @OrderBy = " order by vendor_name,vendor_code,doc_ctrl_num"

select @OrderBy = " order by trx_ctrl_num desc,vendor_name,vendor_code"




if (charindex('trx_ctrl_num',@WhereClause) <> 0)
begin
if (charindex('trx_ctrl_num BETWEEN',@WhereClause) <> 0)
begin
	select @Sub1 = substring(@WhereClause, 
		charindex('trx_ctrl_num',@WhereClause),
		datalength(@WhereClause) - charindex('trx_ctrl_num',@WhereClause) + 1)
	select @firstQuote = charindex("'", @Sub1)
	select @Sub2 = substring (@Sub1, @firstQuote + 1, datalength(@Sub1) - @firstQuote)

	select @secondQuote = charindex("'", @Sub2)
	select @payment_ctrl_no1 = substring (@Sub2,1, @secondQuote -1)
	select @Sub3 = substring(@Sub2,
				datalength(@payment_ctrl_no1) + 8,
				datalength(@Sub2) - 8)
	select @fourthQuote = charindex("'", @Sub3)
	select @payment_ctrl_no2 = substring (@Sub3,1, @fourthQuote -1)
	select @payment_ctrl_no_criteria = "  BETWEEN " + "'"+ @payment_ctrl_no1 + "'"+
		" AND " + "'"+ @payment_ctrl_no2 + "'"
end
else
begin
	select @Sub1 = substring(@WhereClause, 
		charindex('trx_ctrl_num',@WhereClause),
		datalength(@WhereClause) - charindex('trx_ctrl_num',@WhereClause) + 1)
	select @firstQuote = charindex("'", @Sub1)
	select @Sub2 = substring (@Sub1, @firstQuote + 1, datalength(@Sub1) - @firstQuote)

	select @secondQuote = charindex("'", @Sub2)
	select @payment_ctrl_no = substring (@Sub2,1, @secondQuote -1)
	select @payment_ctrl_no_criteria = " like " + "'"+@payment_ctrl_no + "'"
end
end		


if (charindex('doc_ctrl_num',@WhereClause) <> 0)
begin
if (charindex('doc_ctrl_num BETWEEN',@WhereClause) <> 0)
begin
	select @Sub1 = substring(@WhereClause, 
		charindex('doc_ctrl_num',@WhereClause),
		datalength(@WhereClause) - charindex('doc_ctrl_num',@WhereClause) + 1)
	select @firstQuote = charindex("'", @Sub1)
	select @Sub2 = substring (@Sub1, @firstQuote + 1, datalength(@Sub1) - @firstQuote)

	select @secondQuote = charindex("'", @Sub2)
	select @payment_doc_no1 = substring (@Sub2,1, @secondQuote -1)
	select @Sub3 = substring(@Sub2,
				datalength(@payment_doc_no1) + 8,
				datalength(@Sub2) - 8)
	select @fourthQuote = charindex("'", @Sub3)
	select @payment_doc_no2 = substring (@Sub3,1, @fourthQuote -1)
	select @payment_doc_no_criteria = "  BETWEEN " + "'"+ @payment_doc_no1 + "'"+
			" AND " + "'"+ @payment_doc_no2 + "'"
end
else
begin
	select @Sub1 = substring(@WhereClause, 
		charindex('doc_ctrl_num',@WhereClause),
		datalength(@WhereClause) - charindex('doc_ctrl_num',@WhereClause) + 1)
	select @firstQuote = charindex("'", @Sub1)
	select @Sub2 = substring (@Sub1, @firstQuote + 1, datalength(@Sub1) - @firstQuote)

	select @secondQuote = charindex("'", @Sub2)
	select @payment_doc_no = substring (@Sub2,1, @secondQuote -1)
	select @payment_doc_no_criteria = "  like " + "'"+@payment_doc_no +"'"
end		
end










	
if @payment_ctrl_no_criteria is not null
begin
	select @where_payment_ctrl_no = "#appyhdr.trx_ctrl_num" + @where_payment_ctrl_no
	if @payment_doc_no_criteria is not null
		select @where_payment_doc_no = " AND #appyhdr.doc_ctrl_num" + 
                                               @where_payment_doc_no + " AND "
end
else
begin
	if @payment_doc_no_criteria is not null
		select @where_payment_doc_no = " #appyhdr.doc_ctrl_num" + 
						@where_payment_doc_no + " AND "
end	


exec("	insert into #Payments 
	(
		org_id,			
		gl_trx_id,		
		vendor_code,		
		vendor_name,		
		pay_to_code,		
		settlement_ctrl_num, 
		trx_ctrl_num,		
		doc_ctrl_num,		
		nat_cur_code,    	
		cash_acct_code,		
		date_doc,		
		date_applied,		
		date_cleared,		
		rate, -- 033114 tag
		amt_payment_nat, -- 033114 tag
		amt_payment_home,		
		amt_on_acct,		
		amt_disc_taken,    	
		posted_flag,		
		hold_flag,         	
		printed_flag,     	
		approval_flag,    	        
		void_flag,		
		cleared_flag,
		amt_1099,
		vend_class_code,
		tax_id_num,
		flag_1099,
		code_1099
		)
	select
		#appyhdr.org_id,			
		gl_trx_id=#appyhdr.journal_ctrl_num,		
						 
		#appyhdr.vendor_code,		
		#apvend.vendor_name,		
		#appyhdr.pay_to_code,		
		#appyhdr.settlement_ctrl_num,
		#appyhdr.trx_ctrl_num,		
		#appyhdr.doc_ctrl_num,		
		nat_cur_code=#appyhdr.currency_code,    	
						
		#appyhdr.cash_acct_code,		
		#appyhdr.date_doc,		
		#appyhdr.date_applied,		
		ISNULL(cminpdtl.date_cleared, 0),
		#appyhdr.rate_home, -- tag 033114
		#appyhdr.amt_net,		
		#appyhdr.amt_net*#appyhdr.rate_home, -- tag 033114		
		#appyhdr.amt_on_acct,		
		#appyhdr.amt_discount,   	
		posted_flag='Yes',		
		hold_flag='No',        		
		printed_flag='Yes',    		
		approval_flag='No',   		
		void_flag = case #appyhdr.void_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,				
		closed_flag = case ISNULL(cminpdtl.reconciled_flag,0)
			when 0 then 'No'
			when 1 then 'Yes'
		end,
		amt_1099 = (select sum(vd.amt_extended) from 
		apvodet vd, apvohdr vh, appydet pd
		where isnull(vd.code_1099,'')>''
		and pd.trx_ctrl_num = #appyhdr.trx_ctrl_num
		and pd.apply_to_num = vh.trx_ctrl_num
		and vd.trx_ctrl_num = vh.trx_ctrl_num
		),
		#apvend.vend_class_code,
		#apvend.tax_id_num,		
		#apvend.flag_1099,
		#apvend.code_1099

	from    
		#apvend #apvend, #appyhdr #appyhdr LEFT OUTER JOIN cminpdtl cminpdtl ON #appyhdr.trx_ctrl_num = cminpdtl.trx_ctrl_num
	where   "
	+ @where_payment_ctrl_no  
	+ @where_payment_doc_no + "
		#appyhdr.payment_type in (1,2,3,4)		
	and 	#appyhdr.vendor_code = #apvend.vendor_code ")
  	      
		






if @payment_ctrl_no_criteria is not null
begin
	select @where_payment_ctrl_no = "#appyhdr." + @where_payment_ctrl_no
	if @payment_doc_no_criteria is not null
		select @where_payment_doc_no = " AND apinppyt." + @where_payment_doc_no + 
					" AND "
end
else
begin
	if @payment_doc_no_criteria is not null
		select @where_payment_doc_no = " apinppyt." + @where_payment_doc_no + 
					" AND "
end	


	exec("insert into #Payments 
	(
		org_id,			
		gl_trx_id,		
		vendor_code,		
		vendor_name,		
		pay_to_code,		
		settlement_ctrl_num,
		trx_ctrl_num,		
		doc_ctrl_num,		
		nat_cur_code,    	
		cash_acct_code,		
		date_doc,		
		date_applied,		
		date_cleared,
		Rate, -- tag 033114,
		amt_payment_nat, -- tag 033114		
		amt_payment_home,		
		amt_on_acct,		
		amt_disc_taken,    	
		posted_flag,		
		hold_flag,         	
		printed_flag,     	
		approval_flag,    	
		void_flag,		
		cleared_flag, 
		amt_1099,
		vend_class_code,
		tax_id_num,
		flag_1099,
		code_1099
    )
	select 
		apinppyt.org_id,		
		'',				
		apinppyt.vendor_code,		
		#apvend.vendor_name,		
		apinppyt.pay_to_code,		
		apinppyt.settlement_ctrl_num,
		apinppyt.trx_ctrl_num,		
		apinppyt.doc_ctrl_num,		
		apinppyt.nat_cur_code,    	
		apinppyt.cash_acct_code,	
		apinppyt.date_doc,		
		apinppyt.date_applied,		
		date_cleared=0,			
		apinppyt.rate_home, -- 033114 tag
		apinppyt.amt_payment,		
		apinppyt.amt_payment*apinppyt.rate_home, -- tag 033114
		apinppyt.amt_on_acct,		
		apinppyt.amt_disc_taken,   	
		posted_flag = case apinppyt.posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,				
		hold_flag = case apinppyt.hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,        			
		printed_flag = case apinppyt.printed_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,     			
		approval_flag = case apinppyt.approval_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,   				
		void_flag='No',			
		distributed_flag='No',		
		amt_1099 = (select sum(vd.amt_extended) from 
		apvodet vd, apvohdr vh, apinppdt pd
		where isnull(vd.code_1099,'')>''
		and pd.trx_ctrl_num = apinppyt.trx_ctrl_num
		and pd.apply_to_num = vh.trx_ctrl_num
		and vd.trx_ctrl_num = vh.trx_ctrl_num
		),
		#apvend.vend_class_code,
		#apvend.tax_id_num,		
		#apvend.flag_1099,
		#apvend.code_1099
		
	from    
		apinppyt apinppyt, #apvend #apvend
	where "
	+ @where_payment_ctrl_no
	+ @where_payment_doc_no + "
		apinppyt.trx_type = 4111
	and 	apinppyt.vendor_code = #apvend.vendor_code ")





if @payment_doc_no_criteria is not null
	select @where_payment_doc_no = " apinppyt." + @where_payment_doc_no + " AND "



exec("insert into #Payments (
	org_id,			
	gl_trx_id,		
	vendor_code,		
	vendor_name,		
	pay_to_code,		
	settlement_ctrl_num,
	trx_ctrl_num,		
	doc_ctrl_num,		
	nat_cur_code,    	
	cash_acct_code,		
	date_doc,		
	date_applied,		
	date_cleared,		
	rate, -- tag 033114
	amt_payment_nat, -- tag 033114
	amt_payment_home,		
	amt_on_acct,		
	amt_disc_taken,    	
	posted_flag,		
	hold_flag,         	
	printed_flag,     	
	approval_flag,    	
	void_flag,		
	cleared_flag,
	amt_1099,
	vend_class_code,
	tax_id_num,
	flag_1099,
	code_1099
	)
select 
	apinpchg.org_id,	
	'',
	apinptmp.vendor_code,
	#apvend.vendor_name,
	apinpchg.pay_to_code,	
	'',
	'',			
	apinptmp.doc_ctrl_num,
	apinpchg.nat_cur_code,
	apinptmp.cash_acct_code,
	apinptmp.date_doc,
	apinptmp.date_applied,
	0,			
	apinpchg.rate_home, -- 033114 tag
	apinptmp.amt_payment,
	apinptmp.amt_payment*apinpchg.rate_home, -- 033114 tag
	amt_on_acct = apinptmp.amt_payment + apinptmp.amt_disc_taken - apinpchg.amt_paid,
	apinptmp.amt_disc_taken,
	'No',			
	hold_flag = case apinpchg.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
		end,		
	'Yes',			
	approval_flag = case apinptmp.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
		end,			
	'No',			
	'No',			
	amt_1099 = 0,
	#apvend.vend_class_code,
	#apvend.tax_id_num,		
	#apvend.flag_1099,
	#apvend.code_1099
	
from
	apinpchg, apinptmp, #apvend
where 	"
	+ @where_payment_doc_no + "
	apinpchg.trx_ctrl_num = apinptmp.trx_ctrl_num
and	apinptmp.payment_type = 1
and	apinpchg.vendor_code = #apvend.vendor_code")









	


	update  #Payments 
	set     date_applied = b.date_applied, 		
		void_flag='Yes'				
	from    #Payments a, appahdr b, cminpdtl c
	where 	a.doc_ctrl_num = b.doc_ctrl_num
	and     b.doc_ctrl_num = c.doc_ctrl_num
	and     c.trx_type = 4112

	



	update  #Payments 
	set     date_applied = b.date_applied, 		
		void_flag='Yes'				
	from    #Payments a, apinppyt b
	where 	a.vendor_code = b.vendor_code
	and     b.trx_type = 4112
	and     a.doc_ctrl_num = b.doc_ctrl_num









exec ("	select *, x_date_doc=date_doc, x_date_applied=date_applied, x_date_cleared=date_cleared, x_amt_payment=amt_payment_nat, x_amt_on_acct=amt_on_acct, x_amt_disc_taken=amt_disc_taken from #Payments" + @WhereClause + @OrderBy)

drop table #appyhdr
drop table #apvend

GO
GRANT EXECUTE ON  [dbo].[appy1_sp] TO [public]
GO
