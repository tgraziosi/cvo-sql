SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**************************************************************************************

		    Created 2011 and Protected as Unpublished Work       
			  Under the U.S. Copyright Act of 1976            
		 Copyright (c) 2011 Epicor Software Corporation, 2011    
				  All Rights Reserved      
Created by:             Tine Graziosi - 1/14/14
                
CREATED BY: 			Bruce Bishop
CREATED ON:			20111129
PURPOSE:				Generate Customer Export Files
LAST UPDATE:			20120207



EXEC [CVO_CustLog_Export_det_sp] '11/26/2013', '12/25/2013','032137'


-- Rev 1 BNM 9/11/2012 updated to resolve issue 728, installment invoice details on export

**************************************************************************************/

CREATE PROCEDURE [dbo].[CVO_CustLog_Export_det_sp] 
( 
@date_from datetime,
@date_to datetime,
@customer varchar(8)
 )
  
AS

DECLARE 
@SQL		VARCHAR(1000),
@FILENAME 	VARCHAR(200),
@BCPCOMMAND VARCHAR(2000),
--@date_from	varchar(10),
--@date_to	varchar(10),
@FILENAME_sub VARCHAR(100),
@file_from	varchar(10),
@file_to	varchar(10),
@jul_from	int,
@jul_to		int


-- create temp tables
create table #cust_h
(
ID              int identity(1,1),
record_type		varchar(1),
customer		varchar(8),
account_num		varchar(10),
invoice			varchar(12),
order_num		varchar(8),
po_num			varchar(8),
invoice_date	varchar(8),
ship_to_name	varchar(36),
ship_to_address	varchar(36),
ship_to_address2	varchar(36),
ship_to_city	varchar(20),
ship_to_state	varchar(2),
ship_to_zip		varchar(10),
ship_to_phone	varchar(15),
ship_via_desc	varchar(20),
terms_desc		varchar(20),
sub_total		varchar(12),
freight			varchar(12),
tax				varchar(12),
total			varchar(12)
)

create table #cust_d
(
ID              int identity(1,1),
record_type		varchar(1),
account_num		varchar(10),
invoice			varchar(12),
line_num		varchar(3),
item_no			varchar(16),
item_desc1		varchar(36),
item_desc2		varchar(36),
item_desc3		varchar(36),
qty_shipped		varchar(20),
disc_unit		varchar(20),
list_unit		varchar(20)
)

create table #cust_out
(
ID              int identity(1,1),
record_type		varchar(1),
account_num		varchar(10),
invoice			varchar(12),
order_num		varchar(8),
po_num			varchar(8),
invoice_date	varchar(8),
ship_to_name	varchar(36),
ship_to_address	varchar(36),
ship_to_address2	varchar(36),
ship_to_city	varchar(20),
ship_to_state	varchar(2),
ship_to_zip		varchar(10),
ship_to_phone	varchar(15),
ship_via_desc	varchar(20),
terms_desc		varchar(20),
sub_total		varchar(12),
freight			varchar(12),
tax				varchar(12),
total			varchar(12)
)

create index idx_customer on  #cust_out (account_num) with fillfactor = 80
create index idx_invoice on  #cust_out (invoice) with fillfactor = 80


create table #customer
(
ID              int identity(1,1),
customer		varchar(10)
)
create index idx_customer on  #customer (customer) with fillfactor = 80

set @jul_from = datediff(dd, '1/1/1753', @date_from) + 639906	
set @jul_to = datediff(dd, '1/1/1753', @date_to) + 639906	
		
set @file_from = 
replace (convert(varchar(12), dateadd(dd, @jul_from - 639906, '1/1/1753'),102),'.','')		
set @file_to = 
replace (convert(varchar(12), dateadd(dd, @jul_to - 639906, '1/1/1753'),102),'.','')	

--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Declare 
@sequence_num			smallint,
@fin_sequence_id		int, 
@fin_max_sequence_id	int,
-- @customer				varchar(10),
@child					varchar(12),
@invoice				varchar(12),
@type					varchar(1),
@pcount					int,
@mer_disc				varchar(12),
@max_count				int,
@inv_sequence_id		int, 
@inv_max_sequence_id	int,
@ship_to_address2		varchar(36),
@ship_to_city			varchar(20),
@ship_to_state			varchar(2),
@ship_to_zip			varchar(10)



/*

select * from CVO_CustLog_source_vw
EXEC CVO_CustLog_Export_two_sp "customer in ('032137','015773') and invoice_date between '03/26/2012' and '04/25/2012'"
select * from CVO_CustLog_source_vw where doc_ctrl_num = 'INV0116436'

*/



-- 1 --	HEADER RECORD
-- 09/11/2012 BNM - resolve issue 728, extract non-installment headers first
insert into #cust_h
select 
'H', --	record_type		
left(case when v.parent = '' then c.customer_code else v.parent end,8)	customer, 
left(rtrim(ltrim(isnull(c.customer_code,''))),10)as account_num,
-- 092612 tag
case when datalength(v.doc_ctrl_num)>12 then -- installment invoices too long 092612
	replace(v.doc_ctrl_num,'INV','') 
	ELSE V.DOC_CTRL_NUM END as invoice,
convert(varchar(8),isnull(o.order_no,'')) as order_num,
convert(varchar(8),isnull(o.cust_po,'')) as po_num,
left(v.inv_date,2) +'/'+ convert(varchar(2),substring(v.inv_date,4,2))+ '/'+ right(v.inv_date,2)  as invoice_date,
left(isnull(o.ship_to_name,b.customer_name),36) as ship_to_name,
left(isnull(o.ship_to_add_1,''), 36) as ship_to_address,
left(isnull(o.ship_to_add_2,''), 36) as ship_to_address2,
left(isnull(o.ship_to_city,''), 20) as ship_to_city,
left(isnull(o.ship_to_state,''), 2) as ship_to_state,
left(isnull(replace(o.ship_to_zip,'-',''),''), 10) as ship_to_zip,
left(isnull(o.phone,''), 15) as ship_to_phone,
left(isnull(s.ship_via_name ,''),20) as ship_via_desc,
left(isnull(a.terms_desc,''),20) as terms_desc,
convert(varchar(12),convert(money,round(sum((v.mer_disc)),2)))as 	sub_total,
convert(varchar(12),convert(money,round(sum((v.freight)),2)))as freight,
convert(varchar(12),convert(money,round(sum((v.tax)),2))) as tax,
convert(varchar(12),convert(money,round(sum((v.inv_due)),2)))as total
from CVO_CustLog_source_vw v (nolock)
join arcust b (nolock)on v.parent = b.customer_code
join arcust c (nolock)on v.cust_code = c.customer_code
left join orders_invoice i (nolock) on v.doc_ctrl_num = i.doc_ctrl_num
left join orders_all o (nolock) on i.order_no = o.order_no  and i.order_ext = o.ext
left join arshipv s (nolock) on o.routing = s.ship_via_code
left join arterms a (nolock) on o.terms = a.terms_code
where xinv_date between  @jul_from and @jul_to   and c.customer_code = @customer
-- and b.addr_sort1 = 'Buying Group'
and charindex('-',v.doc_ctrl_num) <= 0	-- 09/11/2012 BNM - resolve issue 728, installment invoice details on export
group by
v.parent,
c.customer_code,
v.doc_ctrl_num,
o.order_no,
o.cust_po,
o.ship_to_name,
b.customer_name,
o.ship_to_add_1,
o.ship_to_add_2,
o.ship_to_city,
o.ship_to_state,
o.ship_to_zip,
o.phone,
s.ship_via_name,
a.terms_desc,
v.inv_date,
v.type
order by  v.doc_ctrl_num

-- 1a -- HEADER RECORD	(installments)
-- 09/11/2012 BNM - resolve issue 728, extract installment headers 
insert into #cust_h
select 
'H', --	record_type		
left(case when v.parent = '' then c.customer_code else v.parent end,8)	customer, 
left(rtrim(ltrim(isnull(c.customer_code,''))),10)as account_num,
left(i.doc_ctrl_num,12)	as invoice,		-- 09/11/2012 BNM - resolve issue 728, use original document number
convert(varchar(8),isnull(o.order_no,'')) as order_num,
convert(varchar(8),isnull(o.cust_po,'')) as po_num,
left(v.inv_date,2) +'/'+ convert(varchar(2),substring(v.inv_date,4,2))+ '/'+ right(v.inv_date,2)  as invoice_date,
left(isnull(o.ship_to_name,b.customer_name),36) as ship_to_name,
left(isnull(o.ship_to_add_1,''), 36) as ship_to_address,
left(isnull(o.ship_to_add_2,''), 36) as ship_to_address2,
left(isnull(o.ship_to_city,''), 20) as ship_to_city,
left(isnull(o.ship_to_state,''), 2) as ship_to_state,
left(isnull(replace(o.ship_to_zip,'-',''),''), 10) as ship_to_zip,
left(isnull(o.phone,''), 15) as ship_to_phone,
left(isnull(s.ship_via_name ,''),20) as ship_via_desc,
left(isnull(a.terms_desc,''),20) as terms_desc,
convert(varchar(12),convert(money,round(sum((v.mer_disc)),2)))as 	sub_total,
convert(varchar(12),convert(money,round(sum((v.freight)),2)))as freight,
convert(varchar(12),convert(money,round(sum((v.tax)),2))) as tax,
convert(varchar(12),convert(money,round(sum((v.inv_due)),2)))as total
from CVO_CustLog_source_vw v (nolock)
join arcust b (nolock)on v.parent = b.customer_code
join arcust c (nolock)on v.cust_code = c.customer_code
left join orders_invoice i (nolock) on i.doc_ctrl_num = left(v.doc_ctrl_num,charindex('-',v.doc_ctrl_num)-1)
left join orders_all o (nolock) on i.order_no = o.order_no  and i.order_ext = o.ext
left join arshipv s (nolock) on o.routing = s.ship_via_code
left join arterms a (nolock) on o.terms = a.terms_code
where xinv_date between  @jul_from and @jul_to   and c.customer_code = @customer
-- and b.addr_sort1 = 'Buying Group'
and charindex('-',v.doc_ctrl_num) > 0	-- 09/11/2012 BNM - resolve issue 728, installment invoice details on export
and a.terms_code like 'INS%'
group by
v.parent,
c.customer_code,
i.doc_ctrl_num,		-- 09/11/2012 BNM - resolve issue 728, use original document number
o.order_no,
o.cust_po,
o.ship_to_name,
b.customer_name,
o.ship_to_add_1,
o.ship_to_add_2,
o.ship_to_city,
o.ship_to_state,
o.ship_to_zip,
o.phone,
s.ship_via_name,
a.terms_desc,
v.inv_date,
v.type
order by  i.doc_ctrl_num		-- 09/11/2012 BNM - resolve issue 728, use original document number

create index idx_customer on  #cust_h (account_num) with fillfactor = 80
create index idx_invoice on  #cust_h (invoice) with fillfactor = 80

update #cust_h
set ship_to_name = left(m.address_name,36),
ship_to_address = left(m.addr1,36),
ship_to_address2 = left(m.addr2,36),
ship_to_city = left(m.city,20),
ship_to_state = left(m.state,2),
ship_to_zip = left(replace(m.postal_code, '-', ''),10),
ship_to_phone = left(m.contact_phone,15),
terms_desc = left(t.terms_desc,20)
from armaster_all m (nolock)
join artrx_all h (nolock) on m.customer_code = h.customer_code and m.ship_to_code = h.ship_to_code
join arterms t(nolock) on h.terms_code = t.terms_code
where invoice = h.doc_ctrl_num
and ship_to_address = ''


-- 2a -- DETAIL RECORD FROM ORDERS	-- 09/11/2012 BNM - resolve issue 728, load non-installment invoice detail first

insert into #cust_d
select 
'D' as record_type,		
h.account_num as account_num,
h.invoice as invoice,
left(convert(varchar(3),isnull(d.line_no,'')),3) as line_num,
left(isnull(d.part_no,''),16) as item_no,
left(isnull(d.description,''),16) as item_desc1,
'' as item_desc2,
'' as item_desc3,
case 
	when o.type = 'C' then left(convert(varchar(20),isnull(convert(int,d.cr_shipped)*-1,'')),20) 
	else left(convert(varchar(20),isnull(convert(int,d.shipped),'')),20)
end	as qty_shipped,
--case 
--	when o.type = 'C' then left(convert(varchar(20),isnull(convert(money,d.price)*-1,'')),20)
--	else left(convert(varchar(20),isnull(convert(money,d.price),'')),20) 
--end as disc_unit,
case when o.type = 'C' then 
	left(convert(varchar(20),isnull(convert(money,(curr_price - (curr_price * (d.discount / 100))))*-1,'')),20)
	else left(convert(varchar(20),isnull(convert(money,(curr_price - (curr_price * (d.discount / 100)))),'')),20) 
end as disc_unit,
case 
	when o.type = 'c' and d.discount < 0 then 
	 left(convert(varchar(20),isnull(convert(money,(curr_price - (curr_price * (d.discount / 100))))*-1,'')),20)
	when o.type = 'i' and d.discount < 0 then
	 left(convert(varchar(20),isnull(convert(money,(curr_price - (curr_price * (d.discount / 100)))),'')),20)
	when o.type = 'C' and d.discount >= 0 then left(convert(varchar(20),isnull(convert(money,c.list_price)*-1,'')),20) 
	else left(convert(varchar(20),isnull(convert(money,c.list_price),'')),20) 
end as list_unit
from #cust_h h (nolock)
join orders_invoice i (nolock) on h.invoice = i.doc_ctrl_num -- ltrim(rtrim(h.invoice)) = ltrim(rtrim(i.doc_ctrl_num))
join orders_all o (nolock) on i.order_no = o.order_no and i.order_ext = o.ext
join ord_list d (nolock) on i.order_no = d.order_no and i.order_ext = d.order_ext
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no
where d.shipped > 0 or d.cr_shipped > 0
and charindex('-',invoice) <= 0
and o.terms not like 'INS%'



-- 2b -- DETAIL RECORD FROM ORDERS	-- 09/11/2012 BNM - resolve issue 728, load installment invoice detail next
insert into #cust_d
select 
'D' as record_type,		
h.account_num as account_num,
h.invoice as invoice,
left(convert(varchar(3),isnull(d.line_no,'')),3) as line_num,
left(isnull(d.part_no,''),16) as item_no,
left(isnull(d.description,''),16) as item_desc1,
'' as item_desc2,
'' as item_desc3,
case 
	when o.type = 'C' then left(convert(varchar(20),isnull(convert(int,d.cr_shipped)*-1,'')),20) 
	else left(convert(varchar(20),isnull(convert(int,d.shipped),'')),20)
end	as qty_shipped,
case when o.type = 'C' then 
	left(convert(varchar(20),isnull(convert(money,(curr_price - (curr_price * (d.discount / 100))))*-1,'')),20)
	else left(convert(varchar(20),isnull(convert(money,(curr_price - (curr_price * (d.discount / 100)))),'')),20) 
end as disc_unit,
case 
	when o.type = 'c' and d.discount < 0 then 
	 left(convert(varchar(20),isnull(convert(money,(curr_price - (curr_price * (d.discount / 100))))*-1,'')),20)
	when o.type = 'i' and d.discount < 0 then
	 left(convert(varchar(20),isnull(convert(money,(curr_price - (curr_price * (d.discount / 100)))),'')),20)
	when o.type = 'C' and d.discount >= 0 then left(convert(varchar(20),isnull(convert(money,c.list_price)*-1,'')),20) 
	else left(convert(varchar(20),isnull(convert(money,c.list_price),'')),20) 
end as list_unit
from #cust_h h (nolock)
join orders_invoice i (nolock)
	on i.doc_ctrl_num = ltrim(rtrim(h.invoice))
--  on ltrim(rtrim(left(h.invoice,charindex('-',h.invoice)-1))) = ltrim(rtrim(i.doc_ctrl_num))
join orders_all o (nolock) on i.order_no = o.order_no and i.order_ext = o.ext
join ord_list d (nolock) on i.order_no = d.order_no and i.order_ext = d.order_ext
join Cvo_ord_list c (nolock) on  d.order_no =c.order_no and d.order_ext = c.order_ext and d.line_no = c.line_no
where h.invoice not in (select invoice from #cust_d (nolock))
and (d.shipped > 0 or d.cr_shipped > 0)
-- and charindex('-',invoice) > 0
and o.terms like 'INS%'


-- 2 -- DETAIL RECORD FROM AR DOCUMENTS	-- 09/11/2012 BNM - resolve issue 728, load non-installment invoice detail
insert into #cust_d
select 
'D' as record_type,		
h.account_num as account_num,
h.invoice as invoice,
left(convert(varchar(3),isnull(d.sequence_id,'')),3) as line_num,
left(isnull(d.item_code,''),16) as item_no,
left(isnull(d.line_desc,''),16) as item_desc1,
'' as item_desc2,
'' as item_desc3,
case 
	when i.trx_type = 2032 then left(convert(varchar(20),isnull(convert(int,d.qty_returned)*-1,'')),20) 
	else left(convert(varchar(20),isnull(convert(int,d.qty_shipped),'')),20)
end	as qty_shipped,
case 
	when i.trx_type = 2032 then left(convert(varchar(20),isnull(convert(money,d.unit_price - d.discount_amt)*-1,'')),20) 
	else left(convert(varchar(20),isnull(convert(money,d.unit_price - d.discount_amt),'')),20) 
end as  disc_unit,
case 
	when i.trx_type = 2032 then left(convert(varchar(20),isnull(convert(money,d.unit_price)*-1,'')),20)
	else left(convert(varchar(20),isnull(convert(money,d.unit_price),'')),20) 
end as list_unit
from #cust_h h (nolock)
join artrx_all i (nolock) on  h.invoice = i.doc_ctrl_num -- ltrim(rtrim(h.invoice)) = ltrim(rtrim(i.doc_ctrl_num))
join artrxcdt d (nolock) on i.trx_ctrl_num = d.trx_ctrl_num
where h.invoice not in (select invoice from #cust_d (nolock))
and i.trx_type in (2031,2032)
and i.terms_code not like 'INS%'	-- 09/11/2012 BNM - resolve issue 728, non-installment invoice detail

--=========================================================================================
-- prep and pad fields for export

-- remove address line

create index idx_customer on  #cust_d (account_num) with fillfactor = 80
create index idx_invoice on  #cust_d (invoice) with fillfactor = 80



update #cust_h set ship_to_address2 = '                                     '
where left(ship_to_address2, charindex(',',ship_to_address2)-1) = ship_to_city
and substring(ship_to_address2, charindex(',',ship_to_address2)+2,2) = ship_to_state
and replace(right(ship_to_address2, len(ltrim(rtrim(ship_to_address2))) -( charindex(',',ship_to_address2)+ 4)),'-','') = ship_to_zip
and charindex(',',ship_to_address2) > 0

update #cust_h
set 
customer =  left(customer + '        ',8),
account_num	=  left(account_num + '          ',10),
invoice	=  left(invoice + '             ',12),
order_num = left(order_num +'        ',8), -- varchar(8),
po_num = left(po_num +'        ',8), -- varchar(8),
ship_to_name = left(ship_to_name +'                                     ',36), --	varchar(36),
ship_to_address = left( ship_to_address +'                                     ',36),	--varchar(36),
ship_to_address2 = left( ship_to_address2 +'                                     ',36),	--varchar(36),
ship_to_city = left(ship_to_city +'                                     ',20),	--	varchar(20),
ship_to_state = left(ship_to_state+'  ',2), -- 	varchar(2),
ship_to_zip= left(ship_to_zip+'           ',10), --		varchar(10),
ship_to_phone = left(ship_to_phone+'                 ',15), --	varchar(15),
ship_via_desc = left(ship_via_desc+'                     ',20), --	varchar(20),
terms_desc = left(terms_desc+'                      ',20), --		varchar(20),
sub_total = right('             '+sub_total,10), --	varchar(12),
freight = right('              '+freight,10), --			varchar(12),
tax = right('             '+tax,10), --				varchar(12),
total = right('             '+total,10) --			varchar(12)

update #cust_d
set 
account_num	=  left(account_num + '          ',10),
invoice	= left(invoice+'            ',12), --		varchar(12),
line_num = right('000'+ line_num, 3),--		varchar(3),
item_no	= left(item_no+'                  ',16), --		varchar(16),
item_desc1 = left(item_desc1+'                                        ',36), -- 		varchar(36),
item_desc2 = left(item_desc2+'                                        ',36), -- 		varchar(36),
item_desc3 = left(item_desc3+'                                        ',36), -- 		varchar(36),
qty_shipped = right('0000000000'+qty_shipped,6),--	varchar(10),
disc_unit = right('          '+ disc_unit,10), -- varchar(10),
list_unit = right('          '+	list_unit,10) -- varchar(10)

--*/

--=========================================================================================
/*
*/
--=======================================================================================
CREATE TABLE ##EXP2_TEMP
(
	ID INT,
	LINE VARCHAR(350)
)

-- select trans for export
select @pcount = 0
select @pcount = count(ID) from #cust_h (nolock)
--=======================================================================================================
-- there are records to export

if @pcount > 0 begin -- records to export 
-- #customer
insert into #customer
select distinct customer from #cust_h (nolock)

        select 
        @fin_sequence_id = '', 
        @fin_max_sequence_id = '',
        @customer = ''

        select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID) 
        from #customer (nolock)
            
       set @pcount = 0
--================================================================       
       WHILE (@fin_sequence_id <= @fin_max_sequence_id )  
       Begin -- buyer group loop
			truncate table #cust_out
			
			-- per buyer group
			select @customer = customer 
			from #customer (nolock)
			where ID = @fin_sequence_id
			
			truncate table #cust_out

			Insert into #cust_out
			select   
			record_type,
			account_num,
			invoice,
			order_num,
			po_num,
			invoice_date,
			ship_to_name,
			ship_to_address,
			ship_to_address2,
			ship_to_city,
			ship_to_state,
			ship_to_zip,
			ship_to_phone,
			ship_via_desc,
			terms_desc,
			sub_total,
			freight,
			tax,
			total
			from #cust_h (nolock)
			where #cust_h.customer = @customer
			order by invoice

			-- clear output file
			truncate table ##EXP2_TEMP
			
			-- per invoice loop
			select @inv_sequence_id = '',
			@inv_max_sequence_id = ''



       select @inv_sequence_id = min(ID), @inv_max_sequence_id = max(ID) 
        from #cust_out (nolock)
--================================================================
-- gather invoices


       WHILE (@inv_sequence_id <= @inv_max_sequence_id)  
       Begin -- per invoice loop
			select @invoice = ''
				
			select @invoice = invoice 
			from #cust_out (nolock)
			where ID = @inv_sequence_id	
			
-- EXPORT DATA FILE
-- header
INSERT INTO ##EXP2_TEMP
(
LINE
)
select 
record_type +
account_num +
invoice +
order_num +
po_num +
invoice_date +
ship_to_name + 
ship_to_address +
ship_to_address2 +
ship_to_city +
ship_to_state +
ship_to_zip +
ship_to_phone +
ship_via_desc +
terms_desc +
sub_total +
freight +
tax +
total			
from #cust_out 
where ID = @inv_sequence_id	

-- detail
INSERT INTO ##EXP2_TEMP
(
LINE
)
select
record_type +
account_num +
invoice +
line_num +
item_no +
item_desc1 +
item_desc2 +
item_desc3 +
qty_shipped +
disc_unit +
list_unit
from #cust_d (nolock)
where invoice = @invoice
order by line_num
		
		
		select @inv_sequence_id = @inv_sequence_id + 1
		
		end -- per invoice loop
--/*

SET NOCOUNT ON
set @FILENAME_sub = ltrim(rtrim(@customer)) + '_' + @file_from + '_' + @file_to + '_detail.txt'

--SET @FILENAME = 'C:\Epicor_BGData\Detail\' + @FILENAME_sub
SET @FILENAME = '\\cvo-fs-01\Public_Data\Accounts Receivable\Buying Groups\Epicor_BGData\' + @FILENAME_sub
SET @BCPCOMMAND = 'BCP "SELECT LINE FROM CVO..##EXP2_TEMP" QUERYOUT "'
-- SET @BCPCOMMAND = @BCPCOMMAND + @FILENAME + '" -U sa -P sa12345  -c'
SET @BCPCOMMAND = @BCPCOMMAND + @FILENAME + '" -T   -c'
EXEC MASTER..XP_CMDSHELL @BCPCOMMAND

--*/

set @fin_sequence_id = @fin_sequence_id + 1

end -- buyer group loop

--=======================================================================================================

end -- records to export 

--=======================================================================================================

-- select * from #cust_h order by order_num
-- select * from #cust_d
-- select * from #customer

drop table ##EXP2_TEMP
drop table #cust_h
drop table #cust_d
drop table #cust_out
drop table #customer

GO
GRANT EXECUTE ON  [dbo].[CVO_CustLog_Export_det_sp] TO [public]
GO
