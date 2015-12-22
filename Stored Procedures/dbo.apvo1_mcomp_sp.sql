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














create proc [dbo].[apvo1_mcomp_sp] @WhereClause varchar(1024)="" as   
declare
	@sub1			varchar(1024),
	@sub2			varchar(1024),
	@sub3			varchar(1024),
	@firstQuote 		smallint,
	@secondQuote		smallint,
	@doc_ctrl_no		varchar(16),
	@trx_ctrl_no		varchar(16),
	@date_applied		varchar(40),
	@local_where		varchar(255),   
	@OrderBy		varchar(255),
	@db_name 		varchar(128),
	@company_name 		varchar(30),
	@comp 			smallint,
	@indx1 			int,
	@indx2 			int,
	@length 		int,
	@aux			varchar(1024)

create table #Vouchers 
( 
	company_name	varchar(30),
	address_name	varchar(40),				 
	vendor_code	varchar(12),
	pay_to_code	varchar(8),					
	voucher_no	varchar(16), 	
	org_id		varchar(30) NULL,
	approval_flag	varchar(4) NULL,													
	hold_flag	varchar(4) NULL,					
	posted_flag	varchar(4) ,					
	nat_cur_code	varchar(8),				
	amt_net		float, 					
	amt_paid	float,	
	amt_open	float, 
	date_doc	int, 					
	date_applied	int,				
	date_due	int,					
	date_discount	int,				
	invoice_no	varchar(16), 	
	po_ctrl_num	varchar(16), 				
 	gl_trx_id	varchar(16) NULL,
 	batch_code  varchar(16) NULL			
)
create clustered index vch_1 on #Vouchers (address_name,vendor_code,voucher_no)


select @OrderBy = " order by company_name"






SELECT @comp = 0
SELECT @indx1 = CHARINDEX('company_name', @WhereClause)
IF(@indx1 > 0 )
BEGIN
	SELECT @comp = 1
	SELECT @sub1 = SUBSTRING(@WhereClause, 1, @indx1 - 1)
	
	SELECT @indx2 = CHARINDEX('AND', @WhereClause, @indx1)
	
	IF( @indx2 > 0)
		BEGIN
			SELECT @sub2 = SUBSTRING(@WhereClause, @indx1, @indx2 - @indx1)
			SELECT @sub3 = SUBSTRING(@WhereClause, @indx1 + LEN(@sub2) + 5, LEN(@WhereClause)-(LEN(@sub2) + 5))
			SELECT @WhereClause = @sub1 + @sub3
		END
	ELSE
		BEGIN
			SELECT @sub2 = SUBSTRING(@WhereClause, @indx1, LEN(@WhereClause))
			SELECT @WhereClause = SUBSTRING(@sub1, 1, @indx1 - 5)
		END

	IF(CHARINDEX('like',@sub2,1) > 0)
	BEGIN
		SELECT @sub3 = SUBSTRING(@sub2, 18, LEN(@sub2))
	END
	ELSE
	BEGIN
		SELECT @sub3 = SUBSTRING(@sub2, 16, LEN(@sub2))		
	END
END
IF(LEN(@WhereClause) < 6)
BEGIN
	SELECT @WhereClause = ''
END

SELECT @db_name = min(db_name) 
FROM CVO_Control..smcomp












SELECT @local_where = NULL

if (charindex('trx_ctrl_num',@WhereClause) <> 0)
begin
	select @sub1 = substring(@WhereClause, 
		charindex('trx_ctrl_num',@WhereClause),
		datalength(@WhereClause) - charindex('trx_ctrl_num',@WhereClause) + 1)
	select @firstQuote = charindex("'", @sub1)
	select @sub2 = substring (@sub1, @firstQuote + 1, datalength(@sub1) - @firstQuote)

	select @secondQuote = charindex("'", @sub2)
	select @trx_ctrl_no = substring (@sub2,1, @secondQuote -1)
	select @local_where = ' trx_ctrl_num like ' +  @trx_ctrl_no
end		

if (charindex('doc_ctrl_num',@WhereClause) <> 0)
begin
	select @sub1 = substring(@WhereClause, 
		charindex('doc_ctrl_num',@WhereClause),
		datalength(@WhereClause) - charindex('doc_ctrl_num',@WhereClause) + 1)
	select @firstQuote = charindex("'", @sub1)
	select @sub2 = substring (@sub1, @firstQuote + 1, datalength(@sub1) - @firstQuote)

	select @secondQuote = charindex("'", @sub2)
	select @doc_ctrl_no = substring (@sub2,1, @secondQuote -1) 

	if @local_where is NULL 
		select @local_where = ' doc_ctrl_num like ' +  @doc_ctrl_no

	else
		select @local_where = @local_where + ' and doc_ctrl_num like ' +  @doc_ctrl_no
   	
	
end




WHILE (@db_name != '' 
	AND EXISTS( SELECT 1 from CVO_Control..smcomp c INNER JOIN CVO_Control..sminst i ON c.company_id = i.company_id		
			WHERE app_id = 4000 AND c.db_name = @db_name ))
BEGIN


	SELECT @sub3 = REPLACE (@sub3,char(39),'')

	


	SELECT @company_name = company_name
	FROM   CVO_Control..smcomp
	WHERE db_name = @db_name
	AND    company_name like RTRIM(LTRIM(@sub3))


	SELECT  @company_name = isnull(@company_name,'')

	


	IF((HAS_DBACCESS ( @db_name) = 1) AND (  (@company_name != '') OR (@comp = 0) ))
	BEGIN

		IF(@company_name = '')
		BEGIN
			SELECT @company_name = company_name
			FROM   CVO_Control..smcomp
			WHERE db_name = @db_name
		END

	if @local_where is not null
		select @local_where = @local_where + " and "	

	 exec ("USE " + @db_name + " insert	#Vouchers(
		company_name,
		address_name,				 
		vendor_code,	
		pay_to_code,			
		voucher_no, 	
		org_id,
		approval_flag,													
		hold_flag,					
		posted_flag	,					
		nat_cur_code,				
		amt_net	, 					
		amt_paid,	
		amt_open, 
		date_doc, 					
		date_applied,				
		date_due,					
		date_discount,				
		invoice_no, 	
		po_ctrl_num, 				
	 	gl_trx_id,
	 	batch_code) 		
	 select 
		company_name='" + @company_name + "',
		t2.address_name,				 
		t2.vendor_code,					
		t1.pay_to_code,		
		voucher_no=t1.trx_ctrl_num, 	
		t1.org_id,
		approval_flag='No',													
		hold_flag='No',					
		posted_flag='Yes',					
		nat_cur_code=t1.currency_code,				
		t1.amt_net, 					
		amt_paid=t1.amt_paid_to_date,	
		amt_open=t1.amt_net - t1.amt_paid_to_date, 
		t1.date_doc, 					
		t1.date_applied,				
		t1.date_due,					
		t1.date_discount,				
		invoice_no=t1.doc_ctrl_num, 	
		t1.po_ctrl_num, 				
	 	gl_trx_id=t1.journal_ctrl_num,
	 	t1.batch_code  		
	
	 from 
		apvohdr t1, apmaster t2 
	 where "
	  +	@local_where
	  +	" t1.vendor_code = t2.vendor_code
	      and t2.address_type = 0"
	)
	 
	
	


	 exec ("USE " + @db_name + " insert	#Vouchers(
		company_name,
		address_name,				 
		vendor_code,		
		pay_to_code,			
		voucher_no, 	
		org_id,
		approval_flag,													
		hold_flag,					
		posted_flag	,					
		nat_cur_code,				
		amt_net	, 					
		amt_paid,	
		amt_open, 
		date_doc, 					
		date_applied,				
		date_due,					
		date_discount,				
		invoice_no, 	
		po_ctrl_num, 				
	 	gl_trx_id,
	 	batch_code) 	
	 select 
		company_name='" + @company_name + "',
		t2.address_name,				 
		t2.vendor_code,		
		t1.pay_to_code,			
		voucher_no=t1.trx_ctrl_num, 	
		t1.org_id,
		approval_flag = case t1.approval_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,													
		hold_flag = case t1.hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,					
		posted_flag='No',					
		t1.nat_cur_code,				
		t1.amt_net, 					
		amt_paid=t1.amt_paid,			
		amt_open=t1.amt_net - t1.amt_paid, 
		t1.date_doc, 					
		t1.date_applied,				
		t1.date_due,					
		t1.date_discount,				
		invoice_no=t1.doc_ctrl_num, 	
		t1.po_ctrl_num, 				
	 	gl_trx_id='',
	 	t1.batch_code					
		
	 from 
		apinpchg t1, apmaster t2
	 where  "
	  +	@local_where
	  +	" t1.vendor_code = t2.vendor_code 
		and t2.address_type = 0
		and t1.trx_type in (4091) "	
	)

	END

	 SELECT @db_name = min(db_name) 
	 FROM CVO_Control..smcomp
	 WHERE db_name > @db_name

	SELECT @company_name = ''
	
END




exec (" select *, x_amt_net=amt_net, x_amt_paid=amt_paid, x_amt_open=amt_open, x_date_doc=date_doc, x_date_applied=date_applied, x_date_due=date_due, x_date_discount=date_discount from #Vouchers " + @WhereClause + @OrderBy)

 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apvo1_mcomp_sp] TO [public]
GO
