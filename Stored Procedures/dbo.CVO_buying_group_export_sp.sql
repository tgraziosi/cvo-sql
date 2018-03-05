SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/**************************************************************************************  
  
      Created 2011 and Protected as Unpublished Work         
     Under the U.S. Copyright Act of 1976              
   Copyright (c) 2011 Epicor Software Corporation, 2011      
      All Rights Reserved        
                    
CREATED BY:    Bruce Bishop  
CREATED ON:   20111129  
PURPOSE:    Generate Buying Group Export Files  
LAST UPDATE:   20120113  
  
  
EXEC CVO_buying_group_export_sp  'INVOICE_DATE BETWEEN ''08/26/2014'' AND ''09/25/2014'''
  
**************************************************************************************/  
  
CREATE PROCEDURE [dbo].[CVO_buying_group_export_sp] (@WHERECLAUSE VARCHAR(1024))  
-- tag 092612 - handle invoice numbers more than 12 characters long  
-- v1.1 CT 13/02/13 - Display Credit Return Fee amount in field #19
-- v1.2 CT 21/03/13 - Logic change for Credit Return Fees
-- v1.3 CT 16/03/13 - When applying credit fee, subtract from line's total and tot_due values
-- tag 053013 - various updates, exclude 100% discount items
-- v1.4 - tg - 031814 - updates for debit promo activity
AS  
DECLARE   
@SQL  VARCHAR(1000),  
@FILENAME  VARCHAR(200),  
@BCPCOMMAND VARCHAR(2000),  
@date_from varchar(10),  
@date_to varchar(10),  
@FILENAME_sub VARCHAR(100),  
@file_from varchar(10),  
@file_to varchar(10),  
@jul_from int,  
@jul_to  int,
-- START v1.2
@doc_ctrl_num	VARCHAR(16),  
@line_value		DECIMAL(20,8), 
@id				INT,
@fee			DECIMAL(20,8), 
-- END v1.2
-- START v1.3
@total			DECIMAL(20,8),
@tot_due		DECIMAL(20,8)
-- END v1.3

--declare @whereclause varchar(1000)
--set @whereclause = ''

-- create temp tables  
create table #buy  
(  
ID              int identity(1,1),  
customer  varchar(8),  
account_num  varchar(8),  
child   varchar(12),  
member_name  varchar(30),  
issue   varchar(3),  
  
discount  varchar(4),  
type   varchar(1),  
invoice   varchar(12),  
split   varchar(3),  
invoice_date varchar(8),  
  
terms   varchar(3),  
bill_mon  varchar(2),  
bill_year  varchar(4),  
merch   varchar(13),  
non_merch  varchar(13),  
  
freight   varchar(11),  
tax    varchar(11),  
misc   varchar(13),  
non_disc  varchar(13),  
total   varchar(13),  
  
mer_disc  varchar(13),  
tot_due   varchar(13),  
inv_seq   varchar(2),  
terms_code  varchar(8)  
)  
  
create index idx_customer on  #buy (customer) with fillfactor = 80  
create index idx_invoice on  #buy (invoice) with fillfactor = 80  
create index idx_id on #buy(ID)
  
create table #buy_out  
(  
ID              int,  
customer  varchar(8),	 -- 1-8
account_num  varchar(8), -- 9-16
child   varchar(12),	 -- 17-28
member_name  varchar(30), -- 29-58
issue   varchar(3),		-- 59-61
  
discount  varchar(4),	 -- 62-65
type   varchar(1),		 -- 66
invoice   varchar(12),		-- 67-78
split   varchar(3),		 -- 79-81
invoice_date varchar(8),  -- 82-89
  
terms   varchar(3),		 -- 90-92
bill_mon  varchar(2),	 -- 93-94 
bill_year  varchar(4),   -- 95-98
merch   varchar(12),	 -- 99-110
non_merch  varchar(12),  -- 111-122
  
freight   varchar(10),  -- 123-132
tax    varchar(10),		-- 133-142
misc   varchar(12),		-- 143-154,
non_disc  varchar(12),  -- 155-166
total   varchar(12),	-- 167-178
  
mer_disc  varchar(12),  -- 179-190
tot_due   varchar(12),  -- 191-202
inv_seq   varchar(2),   -- 203-204
terms_code  varchar(8)  
)  
 

create index idx_customer on  #buy_out (customer) with fillfactor = 80  
create index idx_invoice on  #buy_out (invoice) with fillfactor = 80  
create index idx_id on #buy_out (ID)
  
create table #customer  
(  
ID              int identity(1,1),  
customer  varchar(8)  
)  
create index idx_customer on  #customer (customer) with fillfactor = 80  
  
  
  
create table #invoice  
(  
ID              int identity(1,1),  
mcount   int,  
customer  varchar(8),  
child   varchar(12),   
invoice   varchar(12),  
type   varchar(1)  
)  
create index idx_customer on  #invoice (customer) with fillfactor = 80  
create index idx_invoice on  #invoice (invoice) with fillfactor = 80  
 
--=======================================================================  
 IF (CHARINDEX ('Between',@WHERECLAUSE) = 0 )  
  BEGIN  
   --TEMPORARY FOR NOW  
   SELECT  @date_from = convert(varchar(10), dateadd(m,-1, getdate()),101),  
   @date_to = convert(varchar(10), getdate(),101)  
  END   
 ELSE  
  BEGIN  
   SELECT  @date_from = substring(@WHERECLAUSE,charindex('BETWEEN ',@WHERECLAUSE)+9,10), --charindex('AND',@WHERECLAUSE)-1),  
   @date_to = substring(@WHERECLAUSE,charindex('AND ',@WHERECLAUSE)+5,10)     --, charindex('ORDER BY',@WHERECLAUSE)-1)  
  END   
    
set @jul_from = datediff(dd, '1/1/1753', @date_from) + 639906   
set @jul_to = datediff(dd, '1/1/1753', @date_to) + 639906   
    
set @file_from =   
--convert(varchar(4),datepart(yy, @date_from))+ convert(varchar(2),datepart(mm, @date_from))+convert(varchar(2),datepart(dd, @date_from))  
replace (convert(varchar(12), dateadd(dd, @jul_from - 639906, '1/1/1753'),102),'.','')    
set @file_to =   
--convert(varchar(4),datepart(yy, @date_to))+ convert(varchar(2),datepart(mm, @date_to))+convert(varchar(2),datepart(dd, @date_to))  
replace (convert(varchar(12), dateadd(dd, @jul_to - 639906, '1/1/1753'),102),'.','')   
  
  
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
Declare   
@sequence_num   smallint,  
@fin_sequence_id  int,   
@fin_max_sequence_id int,  
@customer    varchar(8),  
@child     varchar(12),  
@invoice    varchar(12),  
@type     varchar(1),  
@pcount     int,  
@mer_disc    varchar(12),  
@max_count    int,  
@inv_sequence_id  int,   
@inv_max_sequence_id int,  
@invoice_date   varchar(8),  
@invoice_date_part  varchar(12),  
@customer_code   varchar(12),  
@terms_code    varchar(8),  
@date_doc    int,  
@date_due    int  
  
  
/*  
-- eg 1 --  
select * from artrx_all where trx_ctrl_num = 'IVTRX0088382'  
select * from artrx_all where order_ctrl_num like '12517'  
select * from orders_invoice where order_no = 12517  
select * from orders where order_no = 12517 and ext = 0  
select * from ord_list where order_no = 12517 and order_ext = 0  
select * from Cvo_ord_list where order_no = 12517 and order_ext = 0  
select * from CVO_disc_percent where order_no = 12517 and order_ext = 0  
select * from arnarel where child = '036252'  
select * from arcust where customer_code = '000500'  
select * from CVO_BGLog_source_vw where doc_ctrl_num = 'INV0088382'  
  
-- eg 2 --   
select * from artrx_all where trx_ctrl_num = 'CMTRX0029334'  
select * from orders where order_no = 24060 and ext = 0  
select * from ord_list where order_no = 24060 and order_ext = 0  
select * from Cvo_ord_list where order_no = 12517 and order_ext = 0  
select * from CVO_disc_percent where order_no = 12517 and order_ext = 0  
select * from arnarel where child = '036252'  
select * from arcust where customer_code = '000500'  
  
exec CVO_buying_group_export_sp ''  
  
select * from CVO_BGLog_source_vw   
where doc_ctrl_num in ('inv0486251')
  
*/  
  
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
 
  
insert into #buy  -- Invoices
select   
left(v.parent,8) customer,   
left(rtrim(ltrim(isnull(c.ftp,''))),8) account_num,  
left(rtrim(ltrim(v.cust_code)),12) child,  
left(c.customer_name,30) member_name,  
'000' as issue,  
case when v.disc_perc >=0 then
	right(replace(convert(varchar(20),convert(money,round(v.disc_perc*100,2))),'.',''),4)
	else 0 end as discount,  
case  
 when left(v.type,1) = 'I' then 'D'  
 else left(v.type,1)  
end   
as type,  
-- 092612 tag  
case when datalength(v.doc_ctrl_num)>12 then -- installment invoices too long 092612  
 replace(v.doc_ctrl_num,'INV','')   
 ELSE V.DOC_CTRL_NUM END as invoice,  
'000' as split,  
right(v.inv_date,4) + left(v.inv_date,2) + convert(char(2),substring(v.inv_date,4,2)) as invoice_date,  
v.trm as terms,  
right(v.due_year_month,2)  
as bill_mon,  
left(v.due_year_month,4)  
as bill_year,  
case   
 -- when v.disc_perc = 0 then '0.00'
 when v.disc_perc <= 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_disc)),2)))   -- net
 else convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2)))    -- list
 -- else '0.00'   
end as merch,  
 case   
 when v.disc_perc = 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2)))    
else '0.00' 
end as non_merch,  
-- end as non_merch,  
convert(varchar(11),convert(money,round(sum((v.freight)),2)))  as freight,   
convert(varchar(11),convert(money,round(sum((v.tax)),2))) as tax,  
'000000000000' as misc,  
'000000000000' as non_disc,   
convert(varchar(13),convert(money, round(sum(v.mer_tot),2)+round(sum(v.freight),2) + round(sum(v.tax),2) )) as total,
convert(varchar(13),convert(money,round(sum((v.mer_disc)),2))) as mer_disc,
convert(varchar(13),convert(money,round(sum((v.inv_due)),2))) as tot_due,  
convert(varchar(2),0) as inv_seq,  
'' as terms_code  
from CVO_BGLog_source_vw v (nolock)  
join arcust b (nolock)on v.parent = b.customer_code  
join arcust c (nolock)on v.cust_code = c.customer_code  
where  left(v.type,1) = 'I'  
and xinv_date between  @jul_from and @jul_to   
and b.addr_sort1 = 'Buying Group'  
and v.disc_perc <> 1 -- 053013 - don't include 100% discount items
group by  
v.parent,  
c.ftp,  
v.cust_code,  
c.customer_name,  
v.disc_perc,  
v.doc_ctrl_num,  
v.inv_date,  
v.due_year_month,  
v.trm,  
v.type  
order by v.parent,v.cust_code, v.doc_ctrl_num, v.disc_perc  
  

insert into #buy  -- Credits
select   
left(v.parent,8) customer,   
left(rtrim(ltrim(isnull(c.ftp,''))),8) account_num,  
left(rtrim(ltrim(v.cust_code)),12) child,  
left(c.customer_name,30) member_name,  
'000' as issue,  
case when v.disc_perc >=0 then
	right(replace(convert(varchar(20),convert(money,round(v.disc_perc*100,2))),'.',''),4)
	else 0 end as discount,  
-- right(replace(convert(varchar(20),convert(money,round(v.disc_perc*100,2))),'.',''),4) as discount,  
case  
 when left(v.type,1) = 'I' then 'D'  
 else left(v.type,1)  
end   
as type,  
-- 092612 tag  
case when datalength(v.doc_ctrl_num)>12 then -- installment invoices too long 092612  
 replace(v.doc_ctrl_num,'INV','')   
 ELSE V.DOC_CTRL_NUM END as invoice,  
'000' as split,  
right(v.inv_date,4) + left(v.inv_date,2) + convert(char(2),substring(v.inv_date,4,2)) as invoice_date,  
v.trm as terms,  
right(v.due_year_month,2)  
as bill_mon,  
left(v.due_year_month,4)  
as bill_year,  
case 
 -- when v.disc_perc = 0 then '0.00'
 when v.disc_perc <= 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_disc)),2)))   
 -- when v.disc_perc <> 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2)))    
 else convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2)))    
 -- else '0.00'   
end as merch, 
 case   
 when v.disc_perc = 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2)))    
else '0.00' 
end as non_merch,   
--'0.00' as non_merch,
--case   
-- when v.disc_perc < 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_disc)),2)))   
-- when v.disc_perc = 0 then convert(varchar(13),convert(money,round(abs(sum(v.mer_tot)),2)))    
-- else '0.00'  
--end as non_merch,  
convert(varchar(11),convert(money,round(abs(sum(v.freight)),2)))  as freight,   
convert(varchar(11),convert(money,round(abs(sum(v.tax)),2))) as tax,  
'000000000000' as misc,
-- START v1.2  
'000000000000' as non_disc,
-- START v1.1
--'000000000000' as non_disc,  
--CASE SUM(ISNULL(v.ndd,0)) WHEN 0 THEN '000000000000' ELSE convert(varchar(11),convert(money,round(abs(sum(v.ndd)),2))) END as non_disc,    
-- END v1.1
-- END v1.2
convert(varchar(13),convert(money, round(abs(sum(v.mer_tot)),2)+round(Abs(sum(v.freight)),2) + round(abs(sum(v.tax)),2) )) as total,  
convert(varchar(13),convert(money,round(abs(sum(v.mer_disc)),2))) as mer_disc,  
convert(varchar(13),convert(money,round(abs(sum(v.inv_due)),2))) as tot_due,  
convert(varchar(2),0) as inv_seq,  
'' as terms_code  
from CVO_BGLog_source_vw v (nolock)  
join arcust b (nolock)on v.parent = b.customer_code  
join arcust c (nolock)on v.cust_code = c.customer_code  
where left(v.type,1) = 'C'  
and xinv_date between  @jul_from and @jul_to   
and b.addr_sort1 = 'Buying Group'  
and v.disc_perc <> 1 -- 053013 - don't include 100% discount items
group by  
v.parent,  
c.ftp,  
v.cust_code,  
c.customer_name,  
v.disc_perc,  
v.doc_ctrl_num,  
v.inv_date,  
v.due_year_month,  
v.trm,  
v.type
order by v.parent,v.cust_code, v.doc_ctrl_num, v.disc_perc 

--=================================================================================================  
-- remove 100% discounts  
delete
--select *  
from #buy  
where round(freight,2) = 0  
and round(tax,2) = 0  
and round(tot_due,2) = 0  
and round(mer_disc,2) = 0
and round(misc,2) = 0
and round(non_disc,2) = 0
and round(merch,2) = 0
and round(non_merch,2) = 0    
and round(total,2) = 0

-- tag - 071013
update #buy set merch = '0.00' where discount = 0 and merch <> '0.00' and non_merch <> '0.00'

/*
-- START v1.2
-- Loop through #bg_log table and apply credit return fees for any matching credits
SET @doc_ctrl_num = ''

WHILE 1=1
BEGIN

	SELECT TOP 1
		@doc_ctrl_num = invoice,
		@line_value = mer_disc,
		@id = id,
		-- START v1.3
		@total = CAST(total AS DECIMAL(20,8)),
		@tot_due = CAST(tot_due AS DECIMAL(20,8))
		-- END v1.3
	FROM
		#buy
	WHERE
		[type] = 'C'
		AND invoice > @doc_ctrl_num
	ORDER BY
		invoice ASC,
		mer_disc DESC

	IF @@ROWCOUNT = 0
		BREAK

	-- Check if there is a fee line for this credit
	SET @fee = NULL

	SELECT 
		@fee = fee
	FROM
		dbo.cvo_credit_return_fee_lines_vw (NOLOCK)
	WHERE
		doc_ctrl_num = @doc_ctrl_num

	-- Check if fee is less than or equal to line_value
	IF ISNULL(@fee,0) <> 0
	BEGIN
		
		IF @fee <= @line_value
		BEGIN

			-- START v1.3
			SET @total = @total - @fee
			SET @tot_due = @tot_due - @fee
			-- END v1.3

			UPDATE
				#buy
			SET
				non_disc = CAST(CAST(ROUND(@fee,2) AS DECIMAL (20,2)) AS VARCHAR(13)),
				-- START v1.3
				total = CONVERT(VARCHAR(13),CONVERT(MONEY,ROUND(@total,2))),
				tot_due = CONVERT(VARCHAR(13),CONVERT(MONEY,ROUND(@tot_due,2)))
				-- END v1.3
			WHERE
				id = @id
		END

	END
END
-- END v1.2
*/ 
 

-- update results  
update #buy  
set #buy.terms_code = c.terms_code  
from #buy   
join orders_invoice i (nolock) on #buy.invoice = i.doc_ctrl_num  
join orders_all o (nolock) on i.order_no = o.order_no and i.order_ext = o.ext  
join arcust c (nolock) on o.cust_code = c.customer_code   
where #buy.terms_code <> c.terms_code
  
update #buy  
set #buy.terms_code = h.terms_code  
from #buy    
join artrx_all h (nolock) on h.doc_ctrl_num = #buy.invoice   
where #buy.terms_code = ''  
  
 -- select * from #buy
--=========================================================================================  
-- recalculate due dates --- why?????????????????  only do for doc's that don't already have one
-- fill in the blanks in case due date missing

create table #id_duedate
(invoice varchar(12),
new_due_date int,
bill_year varchar(4),
bill_mon varchar(2))

declare @bill_year varchar(4), @bill_mon varchar(2)

select   @invoice = min(invoice) from #buy where (bill_year = '' or bill_mon = '')
			and #buy.terms_code not like 'INS%'  

                      
WHILE (@invoice is not null)
Begin  

	select @invoice
	
    select  top 1
    @customer_code = child,  
    @terms_code = case when type = 'c' then 'NET30' else terms_code end,  
    @invoice_date = invoice_date,  
    @invoice_date_part = substring(@invoice_date,5,2) + '/' + right(@invoice_date,2) + '/' + left(@invoice_date,4),     @date_doc = datediff(dd, '1/1/1753', @invoice_date_part) + 639906  
    from #buy (nolock)  
    where invoice = @invoice    
 
  
    exec CVO_CalcDueDate_sp  @customer_code, @date_doc, @date_due  OUTPUT, @terms_code  
  
	select @bill_year = convert(varchar(4),datepart(yy,convert(varchar(12), dateadd(dd, @date_due - 639906, '1/1/1753'),101)))

	SELECT @BILL_MON = 	
	 case when datepart(dd,convert(varchar(12), dateadd(dd, @date_due - 639906, '1/1/1753'),101)) <= '25'  
     then right('000'+ convert(varchar(2),datepart(mm,convert(varchar(12), dateadd(dd, @date_due - 639906, '1/1/1753'),101))),2)  
     else right('000' + convert(varchar(2),convert(int,datepart(mm,convert(varchar(12), dateadd(dd, @date_due - 639906, '1/1/1753'),101)))+ 1), 2)  
    end  -- month
    
	insert into #id_duedate values ( @invoice, @date_due, @bill_year, @bill_mon)
	            
    select @invoice = min(invoice) from #buy where invoice > @invoice
    and (bill_year = '' or bill_mon = '') and #buy.terms_code not like 'INS%'  

   End -- while loop  
    
   update #buy   
    set   
    #buy.bill_year = due.bill_year,
    #buy.bill_mon =   due.bill_mon
    from #id_duedate due
    inner join #buy on due.invoice = #buy.invoice 
    and #buy.terms_code not like 'INS%'  
	and ( #buy.bill_year <> due.bill_year or #buy.bill_mon <>   due.bill_mon )
	    
    drop table #id_duedate
    
--=========================================================================================  
-- update row id for same invoice  
    
   If exists (  
   select count(ID) from #BUY   
   group by customer, child, invoice, type  
   having count(ID) > 1  
   )  
   begin  
  
   truncate table #invoice  
  
   insert into #invoice     
   select count(ID) as mcount, customer, child, invoice, type   
   from #BUY   
   group by customer, child, invoice, type  
   having count(ID) > 1  
  
            select   
            @fin_sequence_id = '',   
            @fin_max_sequence_id = ''  
  
            select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID)   
            from #invoice (nolock)  
                      
            WHILE (@fin_sequence_id <= @fin_max_sequence_id )    
            Begin  
              
   select   
   @customer = customer, @child = child, @invoice = invoice, @type = type  
   from #invoice (nolock)   
   where ID = @fin_sequence_id  
     
  
   select @inv_sequence_id ='',  
   @inv_max_sequence_id ='',  
   @max_count = 0  
  
   select @inv_sequence_id = min(ID), @inv_max_sequence_id = max(ID)   
   from #buy   
   where invoice = @invoice  
   and customer = @customer  
   and child = @child  
   and type = @type  
                 
   WHILE (@inv_sequence_id <= @inv_max_sequence_id )    
            Begin   
        
   set @max_count = @max_count + 1  
        
   update #BUY  
   set inv_seq = convert(varchar(2), @max_count)  
   where ID = @inv_sequence_id  
     
   set @inv_sequence_id = @inv_sequence_id + 1  
   end -- invoice while  
  
     
   set @fin_sequence_id = @fin_sequence_id + 1  
     
   End -- while loop  
    
     
   end -- having count(ID) > 1  
  
  
--=========================================================================================  
-- update row id for INSTALMENTS  
    
   If exists (  
   select count(ID) from #BUY   
   where terms_code like 'INS%'  
   group by customer, child, invoice, type  
   )  
   begin  
  
   truncate table #invoice  
  
   insert into #invoice     
   select count(ID) as mcount, customer, child, invoice, type   
   from #BUY   
   where terms_code like 'INS%'  
   group by customer, child, invoice, type  
     
            select   
            @fin_sequence_id = '',   
            @fin_max_sequence_id = ''  
  
            select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID)   
            from #invoice (nolock)           
                      
            WHILE (@fin_sequence_id <= @fin_max_sequence_id )    
            Begin  
            set @invoice = ''  
            set @child = ''  
              
            select @invoice = invoice, @child = child  
            from #invoice (nolock)  
            where ID = @fin_sequence_id  
              
            update #Buy  
            set   
			-- tag 092514 - fix for installment with no -01 ...
			split = case when charindex('-',@invoice) > 0 then
			right('000'+ substring(@invoice,charindex('-',@invoice)+1,len(@invoice)-charindex('-',@invoice)),3)  
			else '001' end
   where invoice = @invoice  
   and child = @child  
     
   set @fin_sequence_id = @fin_sequence_id + 1  
     
   End -- while loop  
      
   end -- having count(ID) > 1  
  
--=========================================================================================  
  
-- return data to explorer view  
--/*  
  
SELECT    
customer,   
account_num,   
child,          
member_name,                      
issue,   
discount,   
type,   
invoice,        
split,   
invoice_date,   
terms,   
bill_mon,   
bill_year,   
merch,          
non_merch,      
freight,      
tax,          
misc,           
non_disc,       
total,          
mer_disc,       
tot_due,        
inv_seq  
,terms_code  --testing remove this  
from #buy  
  
--*/  
--=========================================================================================  
-- prep and pad fields for export  
  
update #buy  
set   
merch = convert(varchar(12),left(convert(varchar(14),convert(money,merch)*100),len(convert(varchar(14),convert(money,merch)*100))-3)),  
non_merch = convert(varchar(12),left(convert(varchar(14),convert(money,non_merch)*100),len(convert(varchar(14),convert(money,non_merch)*100))-3)),  
tax = convert(varchar(10),left(convert(varchar(12),convert(money,tax)*100),len(convert(varchar(14),convert(money,tax)*100))-3)),  
freight = convert(varchar(10),left(convert(varchar(12),convert(money,freight)*100),len(convert(varchar(14),convert(money,freight)*100))-3)),  
total = convert(varchar(12),left(convert(varchar(14),convert(money,total)*100),len(convert(varchar(14),convert(money,total)*100))-3)),  
mer_disc = convert(varchar(12),left(convert(varchar(14),convert(money,mer_disc)*100),len(convert(varchar(14),convert(money,mer_disc)*100))-3)),  
tot_due = convert(varchar(12),left(convert(varchar(14),convert(money,tot_due)*100),len(convert(varchar(14),convert(money,tot_due)*100))-3))  
  
update #BUY  
set   
customer =  left(customer + '        ',8),  
account_num =  right('000000000'+ account_num,8),  
child = left(child + '            ',12),  
member_name = left(member_name + '                              ' ,30),  
issue = right('000'+ issue,3),  
discount = right('0000' + discount,4),  
invoice = left(invoice + '            ',12),  
split = right ('000' + split,3),  
terms = right ( '000' + terms ,3),  
merch = right( '000000000000' + merch, 12),  
non_merch = right( '000000000000' + non_merch, 12),  
tax = right( '0000000000' + tax, 10),  
freight = right( '0000000000' + freight, 10),  
total = right('000000000000' + total,12),   
mer_disc = right('000000000000' + mer_disc, 12),   
tot_due = right('000000000000' + tot_due, 12),   
inv_seq = right('000' + inv_seq, 2),  
bill_mon = right('00' + bill_mon, 2),
-- START v1.2
non_disc = CASE non_disc WHEN '000000000000' THEN '000000000000' ELSE RIGHT( '0000000000' + REPLACE(non_disc,'.',''), 12) END 
--non_disc = right( '0000000000' + REPLACE(non_disc,'.',''), 10)  -- v1.1 
-- END v1.2
   
--=========================================================================================  
/*  
*/  
  
--=======================================================================================  
-- select trans for export  
select @pcount = 0  
select @pcount = count(ID) from #buy  
  
if @pcount > 0 begin -- records to export   
-- #customer  
insert into #customer  
select distinct customer from #buy (nolock)  
  
        select   
        @fin_sequence_id = '',   
        @fin_max_sequence_id = '',  
        @customer = ''  
          
        --EXPORT DATA FILE  
 CREATE TABLE ##EXP1_TEMP  
 (  
  ID INT,  
  LINE VARCHAR(265)  
 )  
  
        select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID)   
        from #customer (nolock)  
              
       set @pcount = 0         
       WHILE (@fin_sequence_id <= @fin_max_sequence_id )    
       Begin  
   truncate table #buy_out  
   select @customer = customer   
   from #customer  
   where ID = @fin_sequence_id  
  
   Insert into #buy_out  
   select * from #buy  
   where #buy.customer = @customer  
  
  
  
truncate TABLE ##EXP1_TEMP  
  
INSERT INTO ##EXP1_TEMP  
(  
LINE  
)  
select   
customer +   
account_num +  
child +          
member_name +                      
issue +   
discount +   
type +   
invoice +        
split +   
invoice_date +   
terms +   
bill_mon +   
bill_year +   
merch +          
non_merch +      
freight +      
tax +          
misc +           
non_disc +       
total +          
mer_disc +       
tot_due +        
inv_seq  
from #buy_out  
order by invoice, inv_seq  
  
  
 


 
--/*  
  
SET NOCOUNT ON  
set @FILENAME_sub = ltrim(rtrim(@customer)) + '_' + @file_from + '_' + @file_to + '.txt'  
--SET @FILENAME = 'C:\Epicor_BGData\Detail\' + @FILENAME_sub  
SET @FILENAME = '\\cvo-fs-01\Public_Data\Accounts Receivable\Buying Groups\Epicor_BGData\' + @FILENAME_sub  
--SET @FILENAME = '\\172.20.10.5\Public_Data\Accounts Receivable\Buying Groups\Epicor_BGData\' + @FILENAME_sub  
SET @BCPCOMMAND = 'BCP "SELECT LINE FROM CVO..##EXP1_TEMP" QUERYOUT "'  
-- SET @BCPCOMMAND = @BCPCOMMAND + @FILENAME + '" -U sa -P sa12345  -c'  
SET @BCPCOMMAND = @BCPCOMMAND + @FILENAME + '" -T   -c'  
EXEC MASTER..XP_CMDSHELL @BCPCOMMAND  
  
--*/  
  

set @fin_sequence_id = @fin_sequence_id + 1  
  
end -- while loop  
  
drop table ##EXP1_TEMP  
  
end -- records to export   
  
--=======================================================================================  
  
drop table #buy  
drop table #buy_out  
drop table #customer 
-- drop table #bg_log -- v1.2 
  
--=============================================================================  
  
exec CVO_buying_group_export_two_sp @WHERECLAUSE  
  
--=============================================================================  
  
  
--select * from #invoice  
--select * from #buy  
  
  
--drop table ##exp1_temp  



GO
GRANT EXECUTE ON  [dbo].[CVO_buying_group_export_sp] TO [public]
GO
