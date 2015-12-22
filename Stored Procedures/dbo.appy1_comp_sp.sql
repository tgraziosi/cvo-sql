SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                




create proc [dbo].[appy1_comp_sp] @WhereClause varchar(1024)="", @comp_name varchar(30)="" as
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



create table #Payments 
(
	company_name		varchar(30),
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
	amt_payment		float,			
	amt_on_acct		float,			
	amt_disc_taken		float    		
)
create clustered index py_1 on #Payments (vendor_name,vendor_code,doc_ctrl_num)


select @OrderBy = " order by vendor_name,vendor_code,doc_ctrl_num"





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
	select @where_payment_ctrl_no = "appyhdr.trx_ctrl_num" + @where_payment_ctrl_no
	if @payment_doc_no_criteria is not null
		select @where_payment_doc_no = " AND appyhdr.doc_ctrl_num" + 
                                               @where_payment_doc_no + " AND "
end
else
begin
	if @payment_doc_no_criteria is not null
		select @where_payment_doc_no = " appyhdr.doc_ctrl_num" + 
						@where_payment_doc_no + " AND "
end	


exec("insert into #Payments 
	(
		company_name,
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
		amt_payment,		
		amt_on_acct,		
		amt_disc_taken,    	
		posted_flag,		
		hold_flag,         	
		printed_flag,     	
		approval_flag,    	        
		void_flag,		
		cleared_flag		
    )
	select
		company_name = '" + @comp_name + "',
		appyhdr.org_id,			
		gl_trx_id=appyhdr.journal_ctrl_num,		
						 
		appyhdr.vendor_code,		
		apvend.vendor_name,		
		appyhdr.pay_to_code,		
		appyhdr.settlement_ctrl_num,
		appyhdr.trx_ctrl_num,		
		appyhdr.doc_ctrl_num,		
		nat_cur_code=appyhdr.currency_code,    	
						
		appyhdr.cash_acct_code,		
		appyhdr.date_doc,		
		appyhdr.date_applied,		
		ISNULL(cminpdtl.date_cleared, 0),		
		appyhdr.amt_net,		
		appyhdr.amt_on_acct,		
		appyhdr.amt_discount,   	
		posted_flag='Yes',		
		hold_flag='No',        		
		printed_flag='Yes',    		
		approval_flag='No',   		
		void_flag = case appyhdr.void_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,				
		closed_flag = case ISNULL(cminpdtl.reconciled_flag,0)
			when 0 then 'No'
			when 1 then 'Yes'
		end				

	from    
		apvend apvend, 
		appyhdr appyhdr LEFT OUTER JOIN cminpdtl cminpdtl ON (appyhdr.trx_ctrl_num = cminpdtl.trx_ctrl_num)
	where   "
	+ @where_payment_ctrl_no  
	+ @where_payment_doc_no + "
		appyhdr.payment_type in (1,2,3,4)		
	and 	appyhdr.vendor_code = apvend.vendor_code ")
  	      
		






if @payment_ctrl_no_criteria is not null
begin
	select @where_payment_ctrl_no = "appyhdr." + @where_payment_ctrl_no
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
		company_name,
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
		amt_payment,		
		amt_on_acct,		
		amt_disc_taken,    	
		posted_flag,		
		hold_flag,         	
		printed_flag,     	
		approval_flag,    	
		void_flag,		
		cleared_flag		
    )
	select 
		company_name = '" + @comp_name + "',
		apinppyt.org_id,		
		'',				
		apinppyt.vendor_code,		
		apvend.vendor_name,		
		apinppyt.pay_to_code,		
		apinppyt.settlement_ctrl_num,
		apinppyt.trx_ctrl_num,		
		apinppyt.doc_ctrl_num,		
		apinppyt.nat_cur_code,    	
		apinppyt.cash_acct_code,	
		apinppyt.date_doc,		
		apinppyt.date_applied,		
		date_cleared=0,			
		apinppyt.amt_payment,		
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
		distributed_flag='No'		

	from    
		apinppyt apinppyt, apvend apvend
	where "
	+ @where_payment_ctrl_no
	+ @where_payment_doc_no + "
		apinppyt.trx_type = 4111
	and 	apinppyt.vendor_code = apvend.vendor_code ")





if @payment_doc_no_criteria is not null
	select @where_payment_doc_no = " apinppyt." + @where_payment_doc_no + " AND "



exec("insert into #Payments (
	company_name,
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
	amt_payment,		
	amt_on_acct,		
	amt_disc_taken,    	
	posted_flag,		
	hold_flag,         	
	printed_flag,     	
	approval_flag,    	
	void_flag,		
	cleared_flag		
)
select 
	company_name = '" + @comp_name + "',
	apinpchg.org_id,	
	'',
	apinptmp.vendor_code,
	apvend.vendor_name,
	apinpchg.pay_to_code,	
	'',
	'',			
	apinptmp.doc_ctrl_num,
	apinpchg.nat_cur_code,
	apinptmp.cash_acct_code,
	apinptmp.date_doc,
	apinptmp.date_applied,
	0,			
	apinptmp.amt_payment,
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
	'No'			
from
	apinpchg, apinptmp, apvend
where 	"
	+ @where_payment_doc_no + "
	apinpchg.trx_ctrl_num = apinptmp.trx_ctrl_num
and	apinptmp.payment_type = 1
and	apinpchg.vendor_code = apvend.vendor_code")









	


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









exec ("	select *, x_date_doc=date_doc, x_date_applied=date_applied, x_date_cleared=date_cleared, x_amt_payment=amt_payment, x_amt_on_acct=amt_on_acct, x_amt_disc_taken=amt_disc_taken from #Payments" + @WhereClause + @OrderBy)


GO
GRANT EXECUTE ON  [dbo].[appy1_comp_sp] TO [public]
GO
