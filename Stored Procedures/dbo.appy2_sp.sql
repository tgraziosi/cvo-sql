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













create proc [dbo].[appy2_sp] @WhereClause varchar(1024)="" as
DECLARE
	@CM_interfaced 		smallint,
	@Sub1			varchar(1024),
	@Sub2			varchar(1024),
	@firstQuote 		smallint,
	@secondQuote		smallint,
	@payment_doc_no		varchar(16),
	@payment_ctrl_no	varchar(16)

set quoted_identifier off

SELECT
	@payment_doc_no	= "%",
	@payment_ctrl_no = "%"



create table #PaymentDetails
(
	vendor_name		varchar(40),	
	vendor_code		varchar(12),	
	pyt_doc_no		varchar(16),	
	pyt_ctrl_no 		varchar(16),	
	org_id			varchar(30) NULL, 
	pyt_void_flag		varchar(4),	
	pyt_posted_flag		varchar(4),	
	pyt_hold_flag		varchar(4),	
	pyt_cleared_flag	varchar(4),	
	pyt_printed_flag	varchar(4),	
	pyt_approval_flag	varchar(4),	
	date_doc		int,		
	voucher_no		varchar(16),	 
	vo_posted_flag		varchar(4),	       
	vo_hold_flag		varchar(4),							
	vo_approval_flag 	varchar(4), 	
	nat_cur_code		varchar(8),    	
	payment_amt		float,		
	amt_disc_taken		float,		
	payment_desc		varchar(40)	
)






if (charindex('pyt_ctrl_no',@WhereClause) <> 0)
begin
	select @Sub1 = substring(@WhereClause, 
		charindex('pyt_ctrl_no',@WhereClause),
		datalength(@WhereClause) - charindex('pyt_ctrl_no',@WhereClause) + 1)
	select @firstQuote = charindex(CHAR(39), @Sub1)
	select @Sub2 = substring (@Sub1, @firstQuote + 1, datalength(@Sub1) - @firstQuote)

	select @secondQuote = charindex(CHAR(39), @Sub2)
	select @payment_ctrl_no = substring (@Sub2,1, @secondQuote -1)
end		

if (charindex('pyt_doc_no',@WhereClause) <> 0)
begin
	select @Sub1 = substring(@WhereClause, 
		charindex('pyt_doc_no',@WhereClause),
		datalength(@WhereClause) - charindex('pyt_doc_no',@WhereClause) + 1)
	select @firstQuote = charindex(CHAR(39), @Sub1)
	select @Sub2 = substring (@Sub1, @firstQuote + 1, datalength(@Sub1) - @firstQuote)

	select @secondQuote = charindex(CHAR(39), @Sub2)
	select @payment_doc_no = substring (@Sub2,1, @secondQuote -1)
end		











  insert #PaymentDetails
  (
	vendor_name,		 
	vendor_code, 		
	pyt_doc_no, 		 
	pyt_ctrl_no, 		
	org_id,			
	pyt_void_flag ,		
	pyt_posted_flag,	
	pyt_hold_flag ,		
	pyt_cleared_flag,	
	pyt_printed_flag,	
	pyt_approval_flag,	
	date_doc,		
	voucher_no,		 
	vo_posted_flag,		       
	vo_hold_flag,								
	vo_approval_flag,	
	nat_cur_code,		
	payment_amt,		
	amt_disc_taken,		
	payment_desc		
  )
  select 
	t2.vendor_name,		 
	t2.vendor_code, 	
	t3.doc_ctrl_num, 	 
	t1.trx_ctrl_num, 	
	t3.org_id,		
	pyt_void_flag = case t3.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	pyt_posted_flag = 'Yes',		
	pyt_hold_flag = 'No',			
	pyt_cleared_flag = case ISNULL(cminpdtl.closed_flag,0)
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	pyt_printed_flag = 'Yes',		
	pyt_approval_flag = 'No',		
	t3.date_doc,				
	voucher_no = t1.apply_to_num,		 
	vo_posted_flag = 'Yes',			       
	vo_hold_flag = 'No',									
	vo_approval_flag = 'No',		
	t3.currency_code,			
	payment_amt = t1.amt_applied,		
	t1.amt_disc_taken,			
	payment_desc=t1.line_desc		
	
  from 
	appydet t1(NOLOCK), apvend t2(NOLOCK), apvohdr t4(NOLOCK), appyhdr t3(NOLOCK) LEFT OUTER JOIN cminpdtl cminpdtl ON t3.trx_ctrl_num = cminpdtl.trx_ctrl_num
  where 
	t3.trx_ctrl_num 	like @payment_ctrl_no
and	t3.doc_ctrl_num 	like @payment_doc_no
and	t3.payment_type 	= 1
and 	t1.trx_ctrl_num		= t3.trx_ctrl_num
and 	t1.apply_to_num  	= t4.trx_ctrl_num
and	t2.vendor_code 		= t3.vendor_code
and 	t3.vendor_code 		= t4.vendor_code     









  insert #PaymentDetails
  (
	vendor_name,		 
	vendor_code, 		
	pyt_doc_no, 		 
	pyt_ctrl_no, 		
	org_id,			
	pyt_void_flag,		
	pyt_posted_flag,	
	pyt_hold_flag,		
	pyt_cleared_flag,	
	pyt_printed_flag,	
	pyt_approval_flag,	
	date_doc,		
	voucher_no,		 
	vo_posted_flag,		       
	vo_hold_flag,								
	vo_approval_flag,	
	nat_cur_code,		
	payment_amt,		
	amt_disc_taken,		
	payment_desc		
  )
  select 
	t2.vendor_name,		 
	t2.vendor_code, 	
	t3.doc_ctrl_num, 	     
	t3.trx_ctrl_num, 	
	t3.org_id,		
	pyt_void_flag='No',	
	pyt_posted_flag='No',	
	pyt_hold_flag=case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	pyt_cleared_flag='No',			
	pyt_printed_flag=case t3.printed_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	pyt_approval_flag=case t3.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	t3.date_doc,				
	voucher_no=t1.apply_to_num,		     
	vo_posted_flag='Yes',			
	vo_hold_flag='No',									
	vo_approval_flag = 'No',		
	t3.nat_cur_code,			
	payment_amt=t1.amt_applied,		
	t1.amt_disc_taken,			
	payment_desc=t1.line_desc		
	
  from 
	apinppdt t1(NOLOCK), apvend t2(NOLOCK), apinppyt t3(NOLOCK), apvohdr t4(NOLOCK)
where 
 	t3.trx_ctrl_num 	like @payment_ctrl_no 
and	t3.doc_ctrl_num 	like @payment_doc_no 
and 	t3.trx_type		= 4111
and	t3.payment_type		in (1,2)
and	t1.trx_ctrl_num		= t3.trx_ctrl_num
and 	t1.trx_type 		in (4111) 	
and	t1.vendor_code 		= t2.vendor_code
and 	t1.vendor_code 		= t3.vendor_code
and 	t1.apply_to_num 	= t4.trx_ctrl_num
and 	t1.vendor_code 		= t4.vendor_code 








  insert #PaymentDetails
  (
	vendor_name,		 
	vendor_code, 		
	pyt_doc_no, 		 
	pyt_ctrl_no, 		
	org_id,			
	pyt_void_flag,		
	pyt_posted_flag,	
	pyt_hold_flag,		
	pyt_cleared_flag,	
	pyt_printed_flag,	
	pyt_approval_flag,	
	date_doc,		
	voucher_no,		 
	vo_posted_flag,		       
	vo_hold_flag,								
	vo_approval_flag,							
	nat_cur_code,		
	payment_amt,		
	amt_disc_taken,		
	payment_desc		
  )
  select 
	t2.vendor_name,		 
	t2.vendor_code, 	
	t1.doc_ctrl_num, 	     
	'', 			
	t3.org_id,		
	pyt_void_flag='No',	
	pyt_posted_flag='No',	
	pyt_hold_flag='No',	
	pyt_cleared_flag='No',	
	pyt_printed_flag='Yes',	
	pyt_approval_flag=case t1.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	t1.date_doc,				
	voucher_no=t3.trx_ctrl_num,		
	vo_posted_flag='No',			
	vo_hold_flag=case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,											
	vo_approval_flag=case t3.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,											
	t3.nat_cur_code,			
						
	payment_amt=t1.amt_payment,		 
						
	t1.amt_disc_taken,			
						
	payment_desc=t1.trx_desc		

from
	apinptmp t1(NOLOCK), apvend t2(NOLOCK), apinpchg t3(NOLOCK)
where 
	t1.doc_ctrl_num 	like @payment_doc_no
and 	t1.trx_ctrl_num 	= t3.trx_ctrl_num
and	t3.vendor_code 		= t2.vendor_code
and	t3.trx_type 		in (4091)
and	t1.payment_type 	= 1







  insert #PaymentDetails
  (
	vendor_name,		 
	vendor_code, 		
	pyt_doc_no, 		 
	pyt_ctrl_no, 		
	org_id,			
	pyt_void_flag,		
	pyt_posted_flag,	
	pyt_hold_flag,		
	pyt_cleared_flag,	
	pyt_printed_flag,	
	pyt_approval_flag,	
	date_doc,		
	voucher_no,		 
	vo_posted_flag,		       
	vo_hold_flag,								
	vo_approval_flag,							
	nat_cur_code,		
	payment_amt,		
	amt_disc_taken,		
	payment_desc		
  )
  select 
	t2.vendor_name,		 
	t2.vendor_code, 	
	t1.doc_ctrl_num, 	     
	appyhdr.trx_ctrl_num, 	
	t3.org_id,		
	pyt_void_flag='No',	
	pyt_posted_flag='Yes',	
	pyt_hold_flag='No',	
	pyt_cleared_flag=case ISNULL(cminpdtl.closed_flag,0)
		when 0 then 'No'
		when 1 then 'Yes'
		end,	
	pyt_printed_flag='Yes',			
	pyt_approval_flag=case t1.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	t1.date_doc,				
	voucher_no=t3.trx_ctrl_num,	
						
	vo_posted_flag='No',			
	vo_hold_flag=case t3.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,											
	vo_approval_flag=case t3.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,											
	t3.nat_cur_code,			
						
	payment_amt=t1.amt_payment,		 
						
	t1.amt_disc_taken,			
						
	payment_desc=t1.trx_desc		

from
	apinptmp t1(NOLOCK), apvend t2(NOLOCK), apinpchg t3(NOLOCK), appyhdr(NOLOCK) LEFT OUTER JOIN cminpdtl(NOLOCK) ON appyhdr.doc_ctrl_num = cminpdtl.doc_ctrl_num
where 
	t1.doc_ctrl_num 	like @payment_doc_no
and 	t1.trx_ctrl_num 	= t3.trx_ctrl_num
and	t1.doc_ctrl_num		= appyhdr.doc_ctrl_num
and  	appyhdr.payment_type	= 1
and	t3.vendor_code 		= t2.vendor_code
and	t3.trx_type 		in (4091)
and	t1.payment_type 	= 2








exec ("select *, x_date_doc=date_doc, x_payment_amt=payment_amt, x_amt_disc_taken=amt_disc_taken from #PaymentDetails " + @WhereClause )



GO
GRANT EXECUTE ON  [dbo].[appy2_sp] TO [public]
GO
