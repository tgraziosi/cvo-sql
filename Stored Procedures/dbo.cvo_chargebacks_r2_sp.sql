SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select dbo.adm_get_pltdate_f('03/25/2015')

-- EXEC CVO_CHARGEBACKS_r2_SP "cutoff date = 735682 and create_doc = 'N'"

 -- EXEC CVO_CHARGEBACKS_SP "cutoff date = 735682 and create_doc = 'N'"

CREATE PROCEDURE [dbo].[cvo_chargebacks_r2_sp] @where_clause varchar(255)
AS
--
-- v4.0	TM	04/16/2012 - Remove any lines where the discount comes out negative
-- v5.0 TM  05/19/2012 - Remove any customer that has a past due balance < 0
-- v6.0 TM  06/09/2012 - Do not pick up invoices already on chfarargebacks
-- v6.1 TG 07/27/2012 - fix where conditions - add isnull on promo id, and = cutoffdate to not pick up older invoices
-- v6.2.1 tg 09/2012  & 10/2012 - changes to fineline what chargebacks are made - include credit details
-- v6.3 tg - dont allow chargebacks on debit promo activity


DECLARE @cutoff_date	int,
		@Create_doc		varchar(1)

SET NOCOUNT ON


SELECT @cutoff_date = convert(int,substring(@where_clause,charindex('=',@where_clause)+1,7))
SELECT @Create_doc = IsNULL(UPPER(substring(@where_clause,charindex('%',@where_clause)+1,1)),'N')
--
--select @cutoff_date = 734801
--select @create_doc = 'Y'


DECLARE @Total_of_invoice decimal(20,8), @days_due int, @date_due int, 
		@id_no int, @customer_code varchar(8), @disc_cback float,
		@ErrFlag int, @terms_code varchar(10)

IF (select object_id('tempdb..#Temp')) IS NOT NULL DROP TABLE #Temp
IF (select object_id('tempdb..#Temp_inv')) IS NOT NULL DROP TABLE #Temp_inv
IF (select object_id('tempdb..#tmp_custbal')) IS NOT NULL DROP TABLE #tmp_custbal
IF (select object_id('tempdb..#tmP_custbal_open')) IS NOT NULL DROP TABLE #tmP_custbal_open
IF (select object_id('tempdb..#tmp_bgbal')) IS NOT NULL DROP TABLE #tmp_bgbal
IF (select object_id('tempdb..#tmp_bgbal_open')) IS NOT NULL DROP TABLE #tmp_bgbal_open
IF (select object_id('tempdb..#temp_pp')) IS NOT NULL DROP TABLE #temp_pp
IF (select object_id('tempdb..#temp_cr')) IS NOT NULL DROP TABLE #temp_cr
IF (select object_id('tempdb..#temp_cash')) IS NOT NULL DROP TABLE #temp_cash

CREATE TABLE #Temp        
   (id_no int IDENTITY(1,1),
	customer_code varchar(16),
	cust_name varchar(40),
    doc_ctrl_num varchar(16),   
	trx_ctrl_num varchar(16),     
	date_due int,
	shipped float,   
	invoice_unit float,     
	list_unit float,
    disc_given float,
	disc_pct float,
	disc_nochg float,  
	why varchar(3),
    order_ctrl_num varchar(16),
	part_no varchar(30),
	bg_code varchar(16),
	trx_type smallint
   )       

CREATE INDEX #temp_idx1 ON #temp (customer_code, doc_ctrl_num)
CREATE TABLE #Temp_inv
	(id_no int IDENTITY(1,1),
	customer_code varchar(16),
	cust_name varchar(40),
    doc_ctrl_num varchar(16),
	trx_ctrl_num varchar(16),        
	date_due int,
	shipped float,   
	invoice_unit float,     
	list_unit float,
    disc_given float,
	disc_pct float,
	disc_nochg float,  
	why varchar(3),
    order_ctrl_num varchar(16),
	part_no varchar(30),
	bg_code varchar(16),
	trx_type smallint
		)

IF (object_id('tempdb..#Tmp_bgbal') IS NOT NULL) DROP TABLE #Tmp_bgbal
create table #tmp_bgbal
(bg_code varchar(8),
 cust_code			varchar(8),
 shipto_code		varchar(8),
 doc_ctrl_no		varchar(16),
 open_amount		decimal(20,2),
--v6.2
 trx_type			smallint
)
CREATE INDEX #temp_idx1 ON #tmp_bgBal (cust_code, doc_ctrl_no)

 if(object_id('tempdb.dbo.#ar') is not null)      
  drop TABLE #ar      
     
 CREATE TABLE #ar      
 (      
  CUSTOMER_CODE  VARCHAR(8) NULL,      
  [key]   VARCHAR(40) NULL,      
  attn_email   varchar(50) NULL,   --v1.1      
  sls VARCHAR(8) NULL,      
  terr  VARCHAR(8) NULL,   
  region varchar(8) null,   
  NAME  VARCHAR(40) NULL,      
  BG_Code    varchar(8) NULL,      
  BG_Name    varchar(40) NULL,      
  tms   VARCHAR(8) NULL, 
  r12sales float null, -- 101613      
  AVGDAYSLATE   SMALLINT NULL,      
  BAL     FLOAT  NULL,      
  FUT     FLOAT  NULL,      
  CUR     FLOAT  NULL,      
  AR30    FLOAT  NULL,      
  AR60    FLOAT  NULL,      
  AR90    FLOAT  NULL,      
  AR120    FLOAT  NULL,      
  AR150    FLOAT  NULL,      
  CREDIT_LIMIT  FLOAT  NULL,      
  ONORDER    FLOAT  NULL,      
  LPMTDT    datetime   NULL, 
  amount float null,     
  YTDCREDS   FLOAT  NULL,      
  YTDSALES   FLOAT  NULL,      
  LYRSALES   FLOAT  NULL,      
  HOLD    VARCHAR(5) NULL,    
  date_asof varchar(20) null,
  date_type_string varchar (20) null,
  date_type int null
  )
    
 CREATE INDEX #ar_IDX ON #ar (customer_code)      
       

INSERT INTO #Temp 
(	customer_code ,
	cust_name ,
    doc_ctrl_num , 
	trx_ctrl_num,       
	date_due ,
	shipped ,   
	invoice_unit ,     
	list_unit ,
    disc_given ,
	disc_pct ,
	disc_nochg ,  
	why,
    order_ctrl_num ,
	part_no ,
	bg_code ,
	trx_type
	)       
-- invoices
SELECT ar.customer_code, ac.customer_name, ar.doc_ctrl_num, oi.trx_ctrl_num, ar.date_due, ol.shipped,
	   ol.curr_price as sell_price, cl.list_price as list_price,
	   (cl.list_price - ol.curr_price) * shipped as total_discount, 
		case when cl.list_price <> 0 then round((cl.list_price - ol.curr_price)/isnull(cl.list_price,1)*100,2)
			else 0 end as disc_pct,
		0 as disc_nochg, '', ar.order_ctrl_num, ol.part_no,
		 isnull((select top 1 parent from arnarel where ar.customer_code = child),'') as bg_code,
		ar.trx_type
  FROM orders_invoice oi
	left join orders_all oh (nolock) on oi.order_no = oh.order_no and oi.order_ext = oh.ext			--v2.0
	left join cvo_orders_all ch (nolock) on oi.order_no = ch.order_no and oi.order_ext = ch.ext		--v3.0
	left join ord_list ol (nolock) on oi.order_no = ol.order_no and oi.order_ext = ol.order_ext
	left join cvo_ord_list cl (nolock) on ol.order_no = cl.order_no and ol.order_ext = cl.order_ext and ol.line_no = cl.line_no
	left join inv_master iv (nolock) on ol.part_no = iv.part_no
	left join artrx ar (nolock) on oi.trx_ctrl_num = ar.trx_ctrl_num and ar.trx_type = 2031 and ar.paid_flag = 0
	left join arcust ac (nolock) on ar.customer_code = ac.customer_code
	left join cvo_armaster_all cm (nolock) on ar.customer_code = cm.customer_code and cm.address_type = 0
  WHERE ol.price <> cl.list_price
   AND shipped > 0
   AND oh.user_category NOT IN ('ST-CL')				--v2.0
   AND isnull(ch.promo_id,'') NOT IN ('QOP','EOR','EOS','EAG')	--v3.0 - v6.1 - tag - 072612
   AND ar.paid_flag = 0
   AND ar.doc_ctrl_num > ''
   AND iv.type_code in ('FRAME','SUN')
   AND IsNull(cm.cvo_chargebacks,1) = 1
   AND ar.date_due = @cutoff_date -- v6.1 - change from <= to =
   AND SUBSTRING(ar.doc_ctrl_num,1,2) NOT IN ('FC','CB')
   AND ar.doc_ctrl_num NOT IN (select SUBSTRING(line_desc,1,10) from artrxcdt where doc_ctrl_num like 'CB%')	--v6.0
   -- v6.3 - 031814 debit promos cant be charged back
   and not exists (select 1 from cvo_debit_promo_customer_det dd where
            dd.order_no = oi.order_no and dd.ext = oi.order_ext)
--v4.0
--select * from #temp WHERE (disc_given < 0 and trx_type = 2031) or (disc_given > 0 and trx_type = 2032)
DELETE #temp WHERE (disc_given < 0 and trx_type = 2031) or (disc_given > 0 and trx_type = 2032)

-- Test a buying group


--
-- GATHER DETAIL for buying groups
--
INSERT INTO #tmp_bgBal
-- Invoices
SELECT arn.parent, h.customer_code,h.ship_to_code,h.doc_ctrl_num,
	convert(decimal(20,2),h.amt_net - h.amt_paid_to_date) as Open_Amount, h.trx_type -- v6.2
  FROM armaster b (nolock), arcust c (nolock), artrxage a (nolock)
	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
	inner join arnarel arn (nolock) on h.customer_code = arn.child
 WHERE a.trx_type = 2031
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
--v6.2
--and a.date_due = @cutoff_date -- v6.1 - chage from <= to =
and a.date_due >= @cutoff_date -- v6.1 - chage from <= to =
--v6.2

UNION
-- OA Cash Receipts
select arn.parent, h.customer_code,h.ship_to_code,h.doc_ctrl_num,h.amt_on_acct * -1, a.trx_type
  from  armaster b (nolock), arcust c (nolock), artrxage a (nolock)	
	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
	inner join arnarel arn (nolock) on h.customer_code = arn.child
 where a.trx_type = 2111 and h.trx_type <> 2112
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and h.amt_on_acct > 0
UNION
-- OA Credit Memos
select arn.parent, h.customer_code,h.ship_to_code,h.doc_ctrl_num,ROUND((h.amt_on_acct * -1),2), a.trx_type
  from  armaster b (nolock), arcust c (nolock), artrxage a (nolock)	
	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
	inner join arnarel arn (nolock) on h.customer_code = arn.child
 where a.trx_type = 2161
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and ROUND(h.amt_on_acct,2) > 0
-- v6.3 - dont include debit memo activity
and not exists (select 1 from cvo_debit_promo_customer_det dd where
            dd.trx_ctrl_num = h.trx_ctrl_num)
order by h.customer_code, h.ship_to_code


--
IF (object_id('tempdb..#tmp_bgBal_Open') IS NOT NULL) DROP TABLE #tmp_bgBal_Open

CREATE TABLE #tmp_bgBal_Open
(bg_code varchar(8),
 open_amount		decimal(20,2)
)
--
-- SUMMARIZE TOTAL OPEN BY buying group
--
INSERT INTO #tmp_bgBal_Open
select bg_code, sum(open_amount)
  from #tmp_bgBal
group by bg_code
order by bg_code
--

-- select * FROM #tmp_bgBal_Open WHERE open_amount > 0
DELETE FROM #tmp_bgBal_Open WHERE open_amount > 0

-- select * from #temp where bg_code in (select bg_code from #tmp_bgBal_Open)

DELETE FROM #temp WHERE bg_code in (select bg_code from #tmp_bgBal_Open)

-------

-- Determine if a Customer has a net balance < $0 - for direct customers
--

IF (object_id('tempdb..#tmp_CustBal') IS NOT NULL) DROP TABLE #tmp_CustBal

CREATE TABLE #tmp_CustBal
(cust_code			varchar(8),
 shipto_code		varchar(8),
 doc_ctrl_no		varchar(16),
 open_amount		decimal(20,2),
--v6.2
 trx_type			smallint
)

CREATE INDEX #temp_idx1 ON #tmp_CustBal (cust_code, doc_ctrl_no)

--
-- GATHER DETAIL for Direct Customers
--
INSERT INTO #tmp_CustBal
-- Invoices
SELECT h.customer_code, h.ship_to_code,h.doc_ctrl_num,
	convert(decimal(20,2),h.amt_net - h.amt_paid_to_date) as Open_Amount, h.trx_type -- v6.2
  FROM armaster b (nolock), arcust c (nolock), artrxage a (nolock)	
	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
 WHERE a.trx_type = 2031
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and not exists (select * from arnarel (nolock) where h.customer_code = child)
--v6.2
--and a.date_due = @cutoff_date -- v6.1 - chage from <= to =
and a.date_due >= @cutoff_date -- v6.1 - chage from <= to =
--v6.2

UNION
-- OA Cash Receipts
select h.customer_code,h.ship_to_code,h.doc_ctrl_num,h.amt_on_acct * -1, a.trx_type
  from  armaster b (nolock), arcust c (nolock), artrxage a (nolock)	
	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
 where a.trx_type = 2111 and h.trx_type <> 2112
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and h.amt_on_acct > 0
and not exists (select * from arnarel (nolock) where h.customer_code = child)
UNION
-- OA Credit Memos
select h.customer_code,h.ship_to_code,h.doc_ctrl_num,ROUND((h.amt_on_acct * -1),2), a.trx_type
  from  armaster b (nolock), arcust c (nolock), artrxage a (nolock)	
	INNER JOIN artrx h (nolock) ON a.trx_ctrl_num = h.trx_ctrl_num
 where a.trx_type = 2161
and h.customer_code = c.customer_code
and h.customer_code = b.customer_code
and h.ship_to_code = b.ship_to_code 
and a.paid_flag = 0
and b.status_type = 1
and ROUND(h.amt_on_acct,2) > 0
and not exists (select * from arnarel (nolock) where h.customer_code = child)
order by h.customer_code, h.ship_to_code

--
IF (object_id('tempdb..#tmp_CustBal_Open') IS NOT NULL) DROP TABLE #tmp_CustBal_Open
CREATE TABLE #tmp_CustBal_Open
(cust_code			varchar(8),
 open_amount		decimal(20,2)
)
--
-- SUMMARIZE TOTAL OPEN BY CUSTOMER/SHIP TO
--
INSERT INTO #tmp_CustBal_Open
select cust_code, sum(open_amount)
  from #tmp_CustBal
group by cust_code
order by cust_code
--
DELETE FROM #tmp_CustBal_Open WHERE open_amount > 0

--select * from #temp where customer_code in (select cust_code from #tmp_custBal_Open)

DELETE FROM #temp WHERE customer_code in (select cust_code from #tmp_CustBal_Open)
--
--

-- v5.0 BEGIN


insert into #ar exec cvo_araging_sp ''

delete from #temp where customer_code in (select customer_code from #ar
	where (#ar.ar30 + #ar.ar60 +#ar.ar90 +#ar.ar120 +#ar.ar150) <=0 )

/*IF (object_id('tempdb..#past_due_bal') IS NOT NULL) DROP TABLE #past_due_bal

CREATE TABLE #past_due_bal (amount float, on_acct float, age_b1 float, age_b2 float, age_b3	float, age_b4 float,
					 		age_b5 float, age_b6 float, home_curr varchar(8), age_b0 float)

DECLARE @Net_past_due float

Select @customer_code = min(customer_code) from #temp

while (@customer_code is not null)
BEGIN
	
	-- select @customer_code, ' get summary aging'

	INSERT #past_due_bal EXEC cc_summary_aging_sp @customer_code, '4', 0, 'CVO', 'CVO'
	SELECT @Net_past_due = age_b2 + age_b3 + age_b4 + age_b5 + age_b6 FROM #past_due_bal
	IF @Net_past_due <= 0
	BEGIN
		DELETE FROM #temp WHERE customer_code = @customer_code		-- If Past Due < 0 Then remove
	--select 'DELETED '+@customer_code
	END
	DELETE #past_due_bal	-- Clear dat out
	select @customer_code = min(customer_code) from #temp 
		where customer_code > @customer_code
END 
*/

-- tag - dont use cursor

delete from #temp where customer_code in 
	(select customer_code from #temp group by customer_code having (sum(disc_given)<=0 ) )

-- select * from #temp
-- Credit details were loaded along with invoices.  Clear out any that are no longer open.

--delete from #temp where not exists 
--	(select * from #tmp_custbal t2 where customer_code = t2.cust_code
--	and #temp.doc_ctrl_num = t2.doc_ctrl_no and t2.trx_type = 2161)
--	and trx_type = 2032

declare @last_trx varchar(16)
declare @pp_amt float
declare @id smallint
declare @last_cust varchar(12)
declare @last_cust_cr varchar(12)
declare @credit_amt float
declare @disc float
DECLARE @NET_amt float

-- Reduce chgeback amount by amt paid on partially paid invoice
IF (select object_id('tempdb..#Temp_pp')) IS NOT NULL DROP TABLE #Temp_pp

CREATE TABLE #Temp_pp
		(id_no int IDENTITY(1,1),
		 customer_code varchar(16),
		 trx_ctrl_num varchar(16),
		 amt_paid_to_date float
		) 

insert into #temp_pp
select distinct t1.customer_code, t1.trx_ctrl_num, amt_paid_to_date  
from #temp t1, artrx ar (nolock) where t1.trx_ctrl_num = ar.trx_ctrl_num
and t1.trx_type = 2031 and ar.amt_paid_to_date <> 0
set @last_trx = ''
set @pp_amt = 0
delete #temp_inv 


select @last_trx = min(trx_ctrl_num) from #temp_pp

while @last_trx is not null
begin
	select @pp_amt = amt_paid_to_date from #temp_pp where  trx_ctrl_num = @last_trx
	delete #temp_inv 
	insert into #temp_inv 
	(	customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type
	) 
	select 
	customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type
	from #temp where trx_ctrl_num = @last_trx and why = ''
		order by doc_ctrl_num, disc_pct	
	delete from #temp where trx_ctrl_num = @last_trx and why = ''

	select @id = min(id_no) from #temp_inv
	
	while @pp_amt >= (select INVOICE_UNIT * SHIPPED from #temp_inv where id_no = @id) 
		and @id is not null
	 begin
		update #temp_inv set disc_nochg = disc_given where id_no = @id
		set @pp_amt = @pp_amt - (select INVOICE_UNIT * SHIPPED from #temp_inv where id_no = @id)
		select @id = min(id_no) from #temp_inv where id_no > @id
	 end
	insert into #temp
	( customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type
	)  select 
	customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , 
	case when disc_nochg <> 0 then 'PPI' else why end, order_ctrl_num , part_no , bg_code , trx_type
	from #temp_inv
	delete #temp_inv 

	select @last_trx = min(trx_ctrl_num) from #temp_pp where trx_ctrl_num >  @last_trx
END -- pp loop

-- Use up on account Cash according to discount %

IF (object_id('tempdb..#Temp_cash') IS NOT NULL) DROP TABLE #Temp_cash

CREATE TABLE #Temp_cash
		(id_no int IDENTITY(1,1),
		 customer_code varchar(16),
		 open_amount float
		) 

insert into #temp_cash
SELECT cust_code, sum(abs(open_amount)) open_amount
	 FROM #tmp_custbal where trx_type = 2111 group by cust_code order by cust_code
set @last_cust = ''
select @last_cust = min(customer_code) from #temp_cash 
delete #temp_inv 
set @credit_amt = 0

while @last_cust is not null
begin
	select @credit_amt = abs(sum(open_amount)) from #temp_cash where @last_cust = customer_code
	delete #temp_inv 
	insert into #temp_inv 
	(customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type	) 
	select 
	customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type
	from #temp where customer_code = @last_cust and why = ''
	order by doc_ctrl_num, disc_pct, invoice_unit	
	
	delete #temp where customer_code = @last_cust and why = ''

	select @id = min(id_no) from #temp_inv
		while @credit_amt >= (select INVOICE_UNIT * SHIPPED from #temp_inv where id_no = @id ) 
		and @id is not null
	 begin
		update #temp_inv set disc_nochg = disc_given where id_no = @id
		set @credit_amt = @credit_amt - 
						(select INVOICE_UNIT * SHIPPED from #temp_inv where id_no = @id)
		select @id = min(id_no) from #temp_inv where id_no > @id
	 end
	insert into #temp
	(customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type	)  
	select 
	customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , 
	case when disc_nochg <> 0 then 'OA$' else why end,
	order_ctrl_num , part_no , bg_code , trx_type
	from #temp_inv

	delete #temp_inv 

 select @last_cust = min(customer_code) from #temp_cash where customer_code > @last_cust
end -- loop for cash


-- Use up on account credits according to discount %

IF (select object_id('tempdb..#Temp_cr')) IS NOT NULL DROP TABLE #Temp_cr

CREATE TABLE #Temp_cr
		(id_no int IDENTITY(1,1),
		 customer_code varchar(16),
		 open_amount float
		) 

insert into #temp_cr
SELECT cust_code, sum(abs(open_amount)) 
	 FROM #tmp_custbal where trx_type = 2161
	 group by cust_code order by cust_code
set @last_cust = ''
select @last_cust = min(customer_code) from #temp_cr 
delete #temp_inv 
set @credit_amt = 0

while @last_cust is not null
begin
	select @credit_amt = sum(abs(open_amount)) from #temp_cr where @last_cust = customer_code
	delete #temp_inv 
	insert into #temp_inv 
	(customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type	) 
	select 
	customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type
	from #temp where customer_code = @last_cust and trx_type = 2031 and why = ''
		order by doc_ctrl_num, disc_pct, invoice_unit
	
	delete from #temp where customer_code = @last_cust and why = ''  

	select @id = min(id_no) from #temp_inv
		while @credit_amt >= (select INVOICE_UNIT * SHIPPED from #temp_inv where id_no = @id) 
		and @id is not null
	 begin
		update #temp_inv set disc_nochg = disc_given where id_no = @id
		set @credit_amt = @credit_amt - 
						(select INVOICE_UNIT * SHIPPED from #temp_inv 
						where id_no = @id)
		select @id = min(id_no) from #temp_inv where id_no > @id
	 end
	insert into #temp
	(customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , why, order_ctrl_num , part_no , bg_code , trx_type	)  
	select 
	customer_code , cust_name , doc_ctrl_num , trx_ctrl_num, date_due , shipped , invoice_unit ,     
	list_unit , disc_given , disc_pct , disc_nochg , 
	case when disc_nochg <> 0 then 'OAC' else why end,
	order_ctrl_num , part_no , bg_code , trx_type
	from #temp_inv
	delete #temp_inv 

 select @last_cust = min(customer_code) from #temp_cr where customer_code > @last_cust
end -- cm loop

 		
delete from #temp where customer_code in 
	(select customer_code from #temp where trx_type = 2031
		group by customer_code having (sum(disc_given-disc_nochg)<=0 ) )

-- done with selections

IF @Create_doc = 'Y'
BEGIN

	CREATE TABLE #TempSum
		(id_no int IDENTITY(1,1),
		 customer_code varchar(16),
		 disc_CBack float  
		)        
		
	INSERT INTO #TempSum (customer_code, disc_CBack)
	SELECT customer_code, SUM(disc_given-disc_nochg)
	  FROM #temp
	GROUP BY customer_code
	ORDER BY customer_code
	
	select @id_no = min(id_no) from #tempsum
	select @customer_code = customer_code, @disc_cback = disc_cback from #tempsum where id_no = @id_no

	while (@id_no is not null)
	BEGIN

	BEGIN TRANSACTION

      --Get the doc_ctrl_num      
      DECLARE @doc_ctrl_number_inv  varchar(10)      
      SELECT @doc_ctrl_number_inv =  SUBSTRING(mask,1,10-(SELECT LEN(next_num)       
		FROM ewnumber WHERE num_type = 3004)) + CAST(next_num as varchar(16)) FROM ewnumber WHERE num_type = 3004         

      --Get the next trx_ctrl_num      
      UPDATE ewnumber SET next_num = next_num + 1 WHERE num_type = 3004      

      --trx_ctrl_num   
      DECLARE @control_number_inv varchar(16), @num int     
      EXEC ARGetNextControl_SP 2000, @control_number_inv OUTPUT, @num OUTPUT       

	COMMIT TRANSACTION


	  SELECT @terms_code = terms_code
		FROM arcust
	   WHERE customer_code = @customer_code

	  EXEC dbo.CVO_CalcDueDate_sp @customer_code, @cutoff_date, @date_due OUTPUT, @terms_code

    ---------------------------------------------------------    
    -- Begin Creation Process
    ---------------------------------------------------------    

	CREATE TABLE #TempDet        
		(lne_id int IDENTITY(1,1),
		 customer_code varchar(16),
		 doc_ctrl_num varchar(16),        
	     order_ctrl_num varchar(16),
	     disc_given float
	    )        
           
	INSERT INTO #TempDet (customer_code, doc_ctrl_num, order_ctrl_num, disc_given)
	SELECT customer_code, doc_ctrl_num, order_ctrl_num, disc_given-disc_nochg
      FROM #Temp
	 WHERE customer_code = @customer_code

	SELECT @ErrFlag = 0

	BEGIN TRANSACTION
            
	   ---------------------------------------------------------    
          /*arinpchg_all*/    
       ---------------------------------------------------------    

     INSERT into arinpchg_all        
       SELECT   
       NULL as timestamp,        
       @control_number_inv as trx_ctrl_num,       
       @doc_ctrl_number_inv,  
       'ChargeBack Invoice' as doc_desc,  
       ' ' as apply_to_num,  
       0 as apply_trx_type,  
       ' ' as order_ctrl_num,       
       '' as batch_code,        
       2031 as trx_type,  
       @cutoff_date as date_entered,              
       @cutoff_date as date_applied,              
       @cutoff_date as date_doc,           
       @cutoff_date as date_shipped,             
       @cutoff_date as date_required,        
       @date_due as date_due,       
       @date_due as date_aging,        
       armaster.customer_code as customer_code,   
       ' ' as ship_to_code,  
       armaster.salesperson_code as salesperson_code,  
       armaster.territory_code,  
       '' as comment_code,  
       '' as fob_code,       
       '' freight_code,     
       armaster.terms_code as terms_code,      
       '' as fin_chg_code,  
       '' as price_code,          
       '' as dest_zone_code,  
       armaster.posting_code as Posting_Code,      
       0 as recurring_flag,        
       '' as recurring_code,  
       armaster.tax_code as tax_code,      
       '' as Customer_PO,        
       0 as total_weight,           
       @disc_cback as amt_gross,         
       0 as amt_freight,                       
       0 as amt_tax,              
       0 as amt_tax_included,         
       0 as amt_discount,                      
       @disc_cback as amt_net,          
       0 as amt_paid,      
       @disc_cback as amt_due,                 
       0 as amt_cost,       
       0 as amt_profit,         
	   1 as next_serial_id,        
       1 as printed_flag,       
       0 as posted_flag,        
       0 as hold_flag,        
       ' ' as hold_desc,       
       1 as user_id,      
       armaster.addr1,  
       armaster.addr2,  
       armaster.addr3,  
       armaster.addr4,  
       armaster.addr5,  
       armaster.addr6,  
       ' ',  
       ' ',  
       ' ',  
       ' ',  
       ' ',  
       ' ',  
       ' ',  
       ' ',
       0,      
       0,      
       0,      
       ' ',  
       ' ',  
       ' ',  
       NULL,  
       0,  
       0,  
       'USD' as nat_cur_code,        
       'BUY' as rate_type_home,        
       'BUY' as rate_type_oper,        
       1 as rate_home,        
       1 as rate_oper,        
       0,  
       NULL,  
       NULL,  
       NULL,  
       'CVO' as org_id,        
       armaster.country_code,  
       armaster.city,  
       armaster.state,  
       armaster.postal_code,  
       ' ',  
       ' ',  
       ' ',  
       ' '  
      FROM  arcust armaster  
      WHERE @customer_code = armaster.customer_code   

	IF @@error <> 0 
		SELECT @ErrFlag = 10
        
       ---------------------------------------------------------    
						/*arinpcdt*/    
       ---------------------------------------------------------   
  
       INSERT INTO arinpcdt    
           SELECT   
           NULL as timestamp,         
           @control_number_inv as trx_ctrl_num,        
           @doc_ctrl_number_inv,  
           TDet.lne_id as sequence_id,         
           2031 as trx_type,         
           ' ' as location_code,         
           ' ' as item_code,         
           0 as bulk_flag,         
           @cutoff_date as date_entered,  
           doc_ctrl_num + ' / ' + order_ctrl_num as line_desc,       
           1 as qty_ordered,        
           1 as qty_shipped,        
           ' ',  
           tdet.disc_given as unit_price,      
           0,  
           0,  
           0 as serial_id,         
           armaster.tax_code as tax_code,       
           '4920000000000',       
           0,  
           0 as amt_discount,         
           0,  
           '' as rma_num,         
           ' ',  
           0 as qty_returned,        
           0 as qty_prev_returned,         
           ' ',   
           0,
           0,      
           0,   
           tdet.disc_given as extended_price,  
           0 as calc_tax,         
           '' as reference_code,         
           '' as new_reference_code,         
           ' ',  
           'CVO' as org_id         
          FROM  arcust armaster, #TempDet tdet  
		 WHERE @customer_code = armaster.customer_code   
		   AND @customer_code = tdet.customer_code

	IF @@error <> 0 
		SELECT @ErrFlag = 20

       --------------------------------------------------------    
           /*arinpage*/    
       ---------------------------------------------------------    
  
     INSERT INTO arinpage  
       SELECT   
        NULL,         
        @control_number_inv as trx_ctrl_num,        
        1,         
        @doc_ctrl_number_inv,  
        ' ',  
        0,  
        2031 as trx_type,        
        @cutoff_date as date_applied,      
        @date_due as date_due,   
        @date_due as date_aging,  
		@customer_code,  
        armaster.salesperson_code,  
        armaster.territory_code,  
        armaster.price_code,  
        @disc_cback   
       FROM  arcust armaster  
       WHERE @customer_code = armaster.customer_code     
          
	IF @@error <> 0 
		SELECT @ErrFlag = 30

       --------------------------------------------------------    
           /*arinptax*/    
       ---------------------------------------------------------    
        
      INSERT INTO arinptax    
        SELECT    
          NULL as timestamp,          
          @control_number_inv as trx_ctrl_num,        
          2031 as trx_type,    
          1 as sequence_id,    
          armaster.tax_code as tax_type_code,       
          @disc_cback as amt_taxable,         
          @disc_cback as amt_gross,    
          0 as amt_tax,           
	      0 as amt_final_tax         
        FROM   arcust armaster  
       WHERE @customer_code = armaster.customer_code
 
	IF @@error <> 0 
		SELECT @ErrFlag = 40


	IF @ErrFlag = 0
		BEGIN
			COMMIT TRANSACTION
		END
	ELSE
		BEGIN
			ROLLBACK TRANSACTION
		END
  

	DROP TABLE #TempDet

	--FETCH NEXT from ap01 INTO @id_no, @customer_code, @disc_cback
	
	select @id_no = min(id_no) from #tempsum where id_no > @id_no
	select @customer_code = customer_code, @disc_cback = disc_cback from #tempsum where id_no = @id_no


end -- loop statement for creating cb invoices

--close ap01 
--deallocate ap01

DROP TABLE #TEMPSUM

end -- if

SELECT #temp.*, @cutoff_date as cutoff_date, @Create_doc as create_doc 
FROM #temp ORDER BY customer_code
-- , trx_ctrl_num


IF (select object_id('tempdb..#Temp')) IS NOT NULL DROP TABLE #Temp
IF (select object_id('tempdb..#Temp_inv')) IS NOT NULL DROP TABLE #Temp_inv
IF (select object_id('tempdb..#tmp_custbal')) IS NOT NULL DROP TABLE #tmp_custbal
IF (select object_id('tempdb..#tmP_custbal_open')) IS NOT NULL DROP TABLE #tmP_custbal_open
IF (select object_id('tempdb..#tmp_bgbal')) IS NOT NULL DROP TABLE #tmp_bgbal
IF (select object_id('tempdb..#tmp_bgbal_open')) IS NOT NULL DROP TABLE #tmp_bgbal_open
IF (select object_id('tempdb..#temp_pp')) IS NOT NULL DROP TABLE #temp_pp
IF (select object_id('tempdb..#temp_cr')) IS NOT NULL DROP TABLE #temp_cr
IF (select object_id('tempdb..#temp_cash')) IS NOT NULL DROP TABLE #temp_cash

GO
