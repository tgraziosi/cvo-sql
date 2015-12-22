SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

























CREATE PROCEDURE [dbo].[nbpostrep_sp] 	@min_net_ctrl_num varchar(16), @max_ctrl_num varchar(16), @module_id int


as

CREATE TABLE  #nbcretrx_1 
	( 
			net_ctrl_num varchar(16), 
			source_trx_num varchar(16), 
			source_doc_num varchar(16), 
			trx_ctrl_num  varchar(16), 
			doc_ctrl_num varchar(16), 
			trx_type	varchar(30), 
			amt_net float,
			currency_symbol varchar(3)
	 ) 
CREATE TABLE  #nbdebtrx_1 
	( 
			net_ctrl_num varchar(16), 
			source_trx_num varchar(16), 
			source_doc_num varchar(16), 
			trx_ctrl_num  varchar(16), 
			doc_ctrl_num varchar(16), 
			trx_type	varchar(30), 
			amt_net float, 
			currency_symbol varchar(3)
	 ) 




CREATE TABLE #trx_type 
( 
	trx_type smallint, 
	trx_type_desc varchar(30) 
) 

INSERT #trx_type 
( 
	trx_type, 
	trx_type_desc 
) 

SELECT 
	trx_type, 
	trx_type_desc 
FROM aptrxtyp 

INSERT #trx_type 
( 
	trx_type, 
	trx_type_desc 
) 

SELECT 
	trx_type, 
	trx_type_desc 
FROM artrxtyp 


		INSERT   #nbnethdr  
			 ( 
			net_ctrl_num, 
			vendor_code, 
			currency_code, 
			date_entered, 
			customer_code, 
			payment_flag, 
			amt_payment, 
			user_name, 
			module_id,
			currency_symbol 
			 ) 
			SELECT 
			a.net_ctrl_num, 
			a.vendor_code, 
			a.currency_code, 
			a.date_entered, 
			a.customer_code, 
			a.payment_flag, 
			a.amt_payment, 
			sm.user_name, 
			a.module_id,
			b.symbol
			FROM nbtrx a, smusers_vw sm, glcurr_vw b
			WHERE  a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
			 AND sm.user_id = a.user_id 
			AND module_id = @module_id 		-- DJPB 
			AND a.currency_code = b.currency_code			
			

	    INSERT  #nbnetdeb  
			 ( 
			net_ctrl_num, 
			trx_ctrl_num, 
			doc_ctrl_num, 
			trx_type, 
			amt_net, 
			amt_payment, 
			amt_committed, 
			date_applied,
			currency_symbol
			 ) 
			SELECT 
			a.net_ctrl_num, 
			a.trx_ctrl_num, 
			a.doc_ctrl_num, 
			c.trx_type_desc, 
			a.amt_net, 
			a.amt_payment, 
			a.amt_committed, 
			a.date_applied,
			b.currency_symbol 
			FROM nbtrxdeb a,   #nbnethdr   b, #trx_type c 
			WHERE a.net_ctrl_num = b.net_ctrl_num 
			AND   a.trx_type = c.trx_type 

		
	    INSERT  #nbnetcre 
			 ( 
			net_ctrl_num, 
			trx_ctrl_num, 
			doc_ctrl_num, 
			trx_type, 
			amt_net, 
			amt_payment, 
			amt_committed, 
			date_applied,
			currency_symbol
			 ) 
			SELECT 
			a.net_ctrl_num, 
			a.trx_ctrl_num, 
			a.doc_ctrl_num, 
			c.trx_type_desc, 
			a.amt_net, 
			a.amt_payment, 
			a.amt_committed, 
			a.date_applied,
			b.currency_symbol 
			FROM nbtrxcre a,  #nbnethdr   b, 
			#trx_type c 
			WHERE a.net_ctrl_num = b.net_ctrl_num 
			AND   a.trx_type = c.trx_type 



INSERT   #nbdebtrx  
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxdeb a, nbtrxrel b, artrx c, #trx_type d
Where a.trx_ctrl_num = c.source_trx_ctrl_num
And c.trx_ctrl_num = b.trx_ctrl_num
And d.trx_type = c.trx_type
--And a.trx_type = 2031
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num 

INSERT  #nbdebtrx  
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxdeb a, nbtrxrel b, apvohdr c, #trx_type d
Where a.trx_ctrl_num = c.vend_order_num
And c.trx_ctrl_num = b.trx_ctrl_num
And d.trx_type = 4091
--And a.trx_type = 2031
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num 

INSERT  #nbdebtrx
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 	
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxdeb a, nbtrxrel b, apdmhdr c, #trx_type d
Where a.trx_ctrl_num = c.vend_order_num
And c.trx_ctrl_num = b.trx_ctrl_num
And d.trx_type = 4092
--And a.trx_type = 2031
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num 

INSERT  #nbdebtrx
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxdeb a, nbtrxrel b, appyhdr c, #trx_type d
Where a.doc_ctrl_num = c.doc_ctrl_num
And c.trx_ctrl_num = b.trx_ctrl_num
And d.trx_type = 4111
--And a.trx_type = 2031
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num 







-- Get generated ar documents
INSERT  #nbcretrx  
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxcre a, nbtrxrel b, artrx c, #trx_type d
Where a.trx_ctrl_num = c.source_trx_ctrl_num
And c.trx_ctrl_num = b.trx_ctrl_num
--And d.trx_type = a.trx_type
And d.trx_type = c.trx_type		-- Dpardo
and c.trx_type != 2031			-- Filter out invoices created to kill cash and credit
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num 

-- Get generated vouchers
INSERT  #nbcretrx  
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxcre a, nbtrxrel b, apvohdr c, #trx_type d
Where a.trx_ctrl_num = c.vend_order_num
And c.trx_ctrl_num = b.trx_ctrl_num
And d.trx_type = 4091
--And a.trx_type = 2031
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num 

-- Get generated debit memos
INSERT  #nbcretrx  
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 	
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxcre a, nbtrxrel b, apdmhdr c, #trx_type d
Where a.trx_ctrl_num = c.vend_order_num
And c.trx_ctrl_num = b.trx_ctrl_num
And d.trx_type = 4092
--And a.trx_type = 2031
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num 

-- Get generated payments
INSERT  #nbcretrx  
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxcre a, nbtrxrel b, appyhdr c, #trx_type d
Where a.doc_ctrl_num = c.doc_ctrl_num
And c.trx_ctrl_num = b.trx_ctrl_num
And d.trx_type = 4111
--And a.trx_type = 2031
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num 



INSERT  #nbcretrx  
 ( 
	net_ctrl_num, 
	source_trx_num, 
	source_doc_num, 
	trx_ctrl_num, 
	doc_ctrl_num, 
	trx_type, 
	amt_net,
	currency_symbol
 ) 
Select 
	a.net_ctrl_num,
	a.trx_ctrl_num,
	a.doc_ctrl_num,
	c.trx_ctrl_num,
	c.doc_ctrl_num,
	d.trx_type_desc,
	c.amt_net,
	''
From nbtrxcre a, nbtrxrel b, artrx c, #trx_type d
Where a.doc_ctrl_num = c.doc_ctrl_num
And c.trx_ctrl_num = b.trx_ctrl_num
And d.trx_type =4111
--And a.trx_type = 2031
And a.net_ctrl_num between @min_net_ctrl_num and @max_ctrl_num
order by a.net_ctrl_num




INSERT #nbdebtrxdt 
select distinct
b.net_ctrl_num,
b.doc_ctrl_num,
a.apply_to_num,
d.doc_ctrl_num,
e.trx_type_desc,
a.amt_applied,
''
from appydet a,  #nbdebtrx b, appyhdr c, apvohdr d, #trx_type e
where a.trx_ctrl_num = c.trx_ctrl_num
and b.doc_ctrl_num = c.doc_ctrl_num
and d.trx_ctrl_num = a.apply_to_num
And e.trx_type =4091



INSERT #nbcretrxdt 
select 
b.net_ctrl_num,
b.trx_ctrl_num,
a.apply_to_num,
d.doc_ctrl_num,
e.trx_type_desc,
a.amt_applied,
''
from appydet a,  #nbcretrx b, appyhdr c, apvohdr d, #trx_type e
where a.trx_ctrl_num = c.trx_ctrl_num
and b.doc_ctrl_num = c.doc_ctrl_num
and d.trx_ctrl_num = a.apply_to_num
And e.trx_type =4091

INSERT #nbcretrxdt
select 
b.net_ctrl_num,
b.trx_ctrl_num,
 a.apply_to_num,
d.doc_ctrl_num,
e.trx_type_desc,
a.amt_applied,
''
from artrxpdt a,  #nbcretrx b, appyhdr c, artrx d, #trx_type e
where a.trx_ctrl_num = c.trx_ctrl_num
and b.doc_ctrl_num = c.doc_ctrl_num
and d.trx_ctrl_num = a.apply_to_num
And e.trx_type =2031

INSERT #nbdebtrxdt
select 
b.net_ctrl_num,
b.trx_ctrl_num,
 a.apply_to_num,
d.doc_ctrl_num,
e.trx_type_desc,
a.amt_applied,
''
from artrxpdt a,  #nbdebtrx b, artrx c, artrx d, #trx_type e
where b.doc_ctrl_num = c.doc_ctrl_num 
and a.trx_ctrl_num = c.trx_ctrl_num
and a.apply_to_num =  d.doc_ctrl_num 
and c.trx_type = 2111
and d.trx_type = 2031
And e.trx_type =2031

INSERT #nbcretrxdt
select 
b.net_ctrl_num,
b.trx_ctrl_num,
d.trx_ctrl_num,
 a.apply_to_num,
e.trx_type_desc,
a.amt_applied,
''
from artrxpdt a,  #nbcretrx b, artrx c, artrx d, #trx_type e
where b.doc_ctrl_num = c.doc_ctrl_num 
and a.trx_ctrl_num = c.trx_ctrl_num
and a.apply_to_num =  d.doc_ctrl_num 
and c.trx_type = 2111
and d.trx_type = 2031
And e.trx_type =2031

INSERT #nbdebtrxdt
select 
b.net_ctrl_num,
b.trx_ctrl_num,
 d.trx_ctrl_num,
 d.doc_ctrl_num,
e.trx_type_desc,
a.amt_net,
''
from apvohdr a,  #nbcretrx b, apvohdr d, #trx_type e
where  a.trx_ctrl_num = b.trx_ctrl_num
and a.apply_to_num =  d.trx_ctrl_num 
And e.trx_type =4091
and  a.apply_to_num <> a.trx_ctrl_num

INSERT #nbdebtrxdt
select 
b.net_ctrl_num,
b.trx_ctrl_num,
 d.trx_ctrl_num,
 d.doc_ctrl_num,
e.trx_type_desc,
a.amt_net,
''
from apvohdr a,  #nbdebtrx b, apvohdr d, #trx_type e
where  a.trx_ctrl_num = b.trx_ctrl_num
and a.apply_to_num =  d.trx_ctrl_num 
And e.trx_type =4091
and  a.apply_to_num <> a.trx_ctrl_num













insert #nbdebtrx_1
Select min( net_ctrl_num),     min(source_trx_num),   min(source_doc_num),  min( trx_ctrl_num),     doc_ctrl_num,     trx_type,  sum(amt_net ), currency_symbol from  #nbdebtrx group by  doc_ctrl_num,     trx_type, currency_symbol

insert  #nbcretrx_1
Select min( net_ctrl_num),    min( source_trx_num),  min( source_doc_num), min(  trx_ctrl_num),     doc_ctrl_num,     trx_type, sum( amt_net), currency_symbol from  #nbcretrx group by  doc_ctrl_num,     trx_type, currency_symbol

truncate table  #nbcretrx
truncate table  #nbdebtrx

insert  #nbdebtrx
select * from #nbdebtrx_1
insert  #nbcretrx
select * from  #nbcretrx_1

insert #nbpaygen
select net_ctrl_num, trx_ctrl_num from nbtrxlog where step = '2.6' and substep in(5,34)

          

UPDATE #nbcretrxdt
	set currency_symbol = #nbnethdr.currency_symbol
FROM #nbnethdr
WHERE #nbcretrxdt.net_ctrl_num = #nbnethdr.net_ctrl_num

UPDATE #nbdebtrxdt
	set currency_symbol = #nbnethdr.currency_symbol
FROM #nbnethdr
WHERE #nbdebtrxdt.net_ctrl_num = #nbnethdr.net_ctrl_num

UPDATE #nbcretrx
	set currency_symbol = #nbnethdr.currency_symbol
FROM #nbnethdr
WHERE #nbcretrx.net_ctrl_num = #nbnethdr.net_ctrl_num

UPDATE #nbcretrx
	set currency_symbol = #nbnethdr.currency_symbol
FROM #nbnethdr
WHERE #nbcretrx.net_ctrl_num = #nbnethdr.net_ctrl_num

UPDATE #nbdebtrx
	set currency_symbol = #nbnethdr.currency_symbol
FROM #nbnethdr
WHERE #nbdebtrx.net_ctrl_num = #nbnethdr.net_ctrl_num

UPDATE #nbnetdeb
	set currency_symbol = #nbnethdr.currency_symbol
FROM #nbnethdr
WHERE #nbnetdeb.net_ctrl_num = #nbnethdr.net_ctrl_num


drop table  #trx_type
drop table  #nbcretrx_1
drop table  #nbdebtrx_1
return 
GO
GRANT EXECUTE ON  [dbo].[nbpostrep_sp] TO [public]
GO
