SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_apaging_sp] @asofdate datetime, @aging_option int
as
begin
-- Author - TAG - 7/17/2013
-- AP Aging - date options4
-- Usage: Exec cvo_apaging_sp '07/17/2013',4

--declare @asofdate datetime
--select @asofdate = getdate()
--declare @aging_option int
--select @aging_option = 1 -- 1=aging date, 2=due date, 3 = doc date, 4 = apply date

declare @jasofdate int
select @jasofdate = dbo.adm_get_pltdate_f(@asofdate)

declare @ab1 int, @ab2 int, @ab3 int, @ab4 int, @ab5 int

SELECT 
@ab1 = age_bracket1, 
@ab2 = age_bracket2, 
@ab3 = age_bracket3, 
@ab4 = age_bracket4, 
@ab5 = age_bracket5 FROM apco

IF(OBJECT_ID('tempdb.dbo.#rpt_apaging') is not null)  drop table #rpt_apaging

create table #rpt_apaging 
( trx_type    	smallint, 
trx_ctrl_num   varchar(16), 
doc_ctrl_num   varchar(16), 
cash_acct_code varchar(32), 
apply_to_num   varchar(16), 
apply_trx_type smallint, 
branch_code   	varchar(8), 
class_code   	varchar(8), 
date_doc   	datetime NULL, 
date_due   	datetime NULL, 
date_aging   	datetime NULL, 
date_applied	datetime NULL, 
amount   		float, 
vendor_code  	varchar(12), 
nat_cur_code	varchar(8), 
rate_type		varchar(8), 
rate_home		float, 
rate_oper		float, 
vendor_name	varchar(40), 
contact_name	varchar(40), 
contact_phone	varchar(40), 
attention_name	varchar(40), 
attention_phone	varchar(30), 
addr1		varchar(40), 
addr2		varchar(40), 
addr3		varchar(40), 
addr4		varchar(40), 
addr5		varchar(40), 
addr6		varchar(40), 
status_desc	varchar(40), 
groupby0		varchar(40), 
groupby1		varchar(40), 
groupby2		varchar(40), 
groupby3		varchar(40), 
groupby4		datetime NULL, 
bracket		smallint, 
trx_type_code	varchar(8), 
status_type	smallint, 
symbol		varchar(8), 
curr_precision 	smallint, 
groupby1_desc	varchar(40), 
sort_date		int, 
num_currencies	smallint, 
days_aged		int NULL, 
ref_id			int, 
org_id			varchar(30) NULL, 
region_id		varchar(30) NULL,
terms_code      varchar(12) null )

IF(OBJECT_ID('tempdb.dbo.#pif') is not null)  drop table #pif
CREATE TABLE #pif (apply_to_num varchar(16))

INSERT #pif (apply_to_num) 
SELECT a.apply_to_num FROM aptrxage a, apvend b, region_vw r 
WHERE a.vendor_code = b.vendor_code 
AND a.org_id = r.org_id  
and
((@aging_option = 1 and a.date_aging <= @jasofdate) or
--(@aging_option = 2 and a.date_due <= @jasofdate) or
(@aging_option = 2 and a.date_aging <= @jasofdate) or
(@aging_option = 3 and a.date_doc <= @jasofdate) or
(@aging_option = 4 and a.date_applied <= @jasofdate))
GROUP BY apply_to_num  
HAVING ABS(SUM(amount)) > 0.000001


delete #pif from aptrxage a 
where #pif.apply_to_num = a.apply_to_num 
and a.apply_trx_type = 0 and  a.apply_to_num <> a.trx_ctrl_num 
and a.date_paid <= @jasofdate and a.paid_flag = 1 


INSERT #rpt_apaging (trx_type, trx_ctrl_num, doc_ctrl_num, cash_acct_code, apply_to_num, apply_trx_type, branch_code, class_code, date_doc, date_due, date_aging, date_applied, amount, vendor_code, nat_cur_code, rate_type, rate_home, rate_oper, vendor_name, contact_name, contact_phone, attention_name, attention_phone, addr1, addr2, addr3, addr4, addr5, addr6, status_desc, groupby0, groupby1, groupby2, groupby3, groupby4, bracket, trx_type_code, status_type, symbol, curr_precision, groupby1_desc, sort_date, num_currencies, days_aged,	ref_id,	org_id,	region_id, terms_code)
 SELECT DISTINCT 
a.trx_type, 
a.trx_ctrl_num, 
a.doc_ctrl_num, 
a.cash_acct_code, 
a.apply_to_num, 
a.apply_trx_type, 
a.branch_code, 
a.class_code, 
case when a.date_doc < 657072 then NULL 
     else dateadd(dd,a.date_doc-657072,'1/1/1800') end,
case when a.date_due < 657072 then NULL 
     else dateadd(dd,a.date_due-657072,'1/1/1800') end, 
case when a.date_aging < 657072 then NULL 
     else dateadd(dd,a.date_aging-657072,'1/1/1800') end, 
case when a.date_applied < 657072 then NULL 
     else dateadd(dd,a.date_applied-657072,'1/1/1800') end,
-- amount in home currency 
a.amount*a.rate_home as amount, 
a.vendor_code, 
a.nat_cur_code,
'' rate_type, 
a.rate_home, 
a.rate_oper, 
b.vendor_name, 
b.contact_name, 
b.contact_phone, 
b.attention_name, 
b.attention_phone, 
b.addr1, 
b.addr2, 
b.addr3, 
b.addr4, 
b.addr5, 
b.addr6, 
'' status_desc, 
'' groupby0, 
a.class_code groupby1, 
a.vendor_code groupby2,
a.nat_cur_code groupby3, 
null groupby4, 
0 bracket, 
d.trx_type_code, 
b.status_type, 
e.symbol, 
e.curr_precision, 
'' groupby1_desc,
case when @aging_option = 1 then isnull(a.date_aging,@jasofdate) 
     when @aging_option = 2 then isnull(a.date_due,@jasofdate)
     when @aging_option = 3 then isnull(a.date_doc,@jasofdate)
     when @aging_option = 4 then isnull(a.date_applied, @jasofdate) end, -- sort date
1, NULL, a.ref_id, a.org_id,  '', '' terms_code	 
FROM #pif c inner join aptrxage a on c.apply_to_num = a.apply_to_num
inner join apvend b on a.vendor_code = b.vendor_code
inner join glcurr_vw e on e.currency_code = a.nat_cur_code
inner join aptrxtyp d on d.trx_type = a.trx_type
inner join region_vw r on r.org_id = a.org_id
WHERE  1=1
and
(@aging_option = 1 and a.date_aging <= @jasofdate) or
--(@aging_option = 2 and a.date_due <= @jasofdate) or
(@aging_option = 2 and a.date_aging <= @jasofdate) or
(@aging_option = 3 and a.date_doc <= @jasofdate) or
(@aging_option = 4 and a.date_applied <= @jasofdate)



UPDATE #rpt_apaging SET region_id = b.region_id  
FROM #rpt_apaging a inner join IBDirectChilds b  
on a.org_id = b.child_org_id 

IF(OBJECT_ID('tempdb.dbo.#pif') is not null)  drop table #pif

if @aging_option = 1 -- Aging Date
 begin
    UPDATE #rpt_apaging 
    SET bracket = CASE
    WHEN -a.date_aging+@jasofdate <=0 or a.date_aging is null then 0  
    -- WHEN -a.date_aging+@jasofdate <= 30 THEN 1  
    when -a.date_aging+@jasofdate between 1 and @ab1 then 1
    WHEN -a.date_aging+@jasofdate BETWEEN @ab1+ 1 AND @ab2 THEN 2  
    WHEN -a.date_aging+@jasofdate BETWEEN @ab2+ 1 AND @ab3 THEN 3  
    WHEN -a.date_aging+@jasofdate BETWEEN @ab3+ 1 AND @ab4 THEN 4  
    WHEN -a.date_aging+@jasofdate BETWEEN @ab4+ 1 AND @ab5 THEN 5  
    WHEN -a.date_aging+@jasofdate > @ab5 THEN 6  END,  
    days_aged = -a.date_aging+@jasofdate 
    FROM #rpt_apaging b inner join aptrxage a
    on a.trx_ctrl_num = b.trx_ctrl_num  AND a.ref_id = b.ref_id 
END
if @aging_option = 2 -- Due Date
 Begin
    UPDATE #rpt_apaging 
    SET bracket = CASE
    WHEN -a.date_due+@jasofdate <=0 or a.date_due is null then 0  
    -- WHEN -a.date_due+@jasofdate <= 30 THEN 1  
    when -a.date_due+@jasofdate between 1 and @ab1 then 1
    WHEN -a.date_due+@jasofdate BETWEEN @ab1+ 1 AND @ab2 THEN 2  
    WHEN -a.date_due+@jasofdate BETWEEN @ab2+ 1 AND @ab3 THEN 3  
    WHEN -a.date_due+@jasofdate BETWEEN @ab3+ 1 AND @ab4 THEN 4  
    WHEN -a.date_due+@jasofdate BETWEEN @ab4+ 1 AND @ab5 THEN 5  
    WHEN -a.date_due+@jasofdate > @ab5 THEN 6  END,  
    days_aged = -a.date_due+@jasofdate 
 FROM #rpt_apaging b inner join aptrxage a
    on a.trx_ctrl_num = b.trx_ctrl_num  AND a.ref_id = b.ref_id 
 END
if @aging_option = 3 -- Doc Date
 Begin
    UPDATE #rpt_apaging 
    SET bracket = CASE
    WHEN -a.date_doc+@jasofdate <=0 or a.date_due is null then 0  
    -- WHEN -a.date_due+@jasofdate <= 30 THEN 1  
    when -a.date_doc+@jasofdate between 1 and @ab1 then 1
    WHEN -a.date_doc+@jasofdate BETWEEN @ab1+ 1 AND @ab2 THEN 2  
    WHEN -a.date_doc+@jasofdate BETWEEN @ab2+ 1 AND @ab3 THEN 3  
    WHEN -a.date_doc+@jasofdate BETWEEN @ab3+ 1 AND @ab4 THEN 4  
    WHEN -a.date_doc+@jasofdate BETWEEN @ab4+ 1 AND @ab5 THEN 5  
    WHEN -a.date_doc+@jasofdate > @ab5 THEN 6  END,  
    days_aged = -a.date_doc+@jasofdate 
 FROM #rpt_apaging b inner join aptrxage a
    on a.trx_ctrl_num = b.trx_ctrl_num  AND a.ref_id = b.ref_id 
 END
 if @aging_option = 4 -- Apply Date
 Begin
    UPDATE #rpt_apaging 
    SET bracket = CASE
    WHEN -a.date_applied+@jasofdate <=0 or a.date_due is null then 0  
    -- WHEN -a.date_due+@jasofdate <= 30 THEN 1  
    when -a.date_applied+@jasofdate between 1 and @ab1 then 1
    WHEN -a.date_applied+@jasofdate BETWEEN @ab1+ 1 AND @ab2 THEN 2  
    WHEN -a.date_applied+@jasofdate BETWEEN @ab2+ 1 AND @ab3 THEN 3  
    WHEN -a.date_applied+@jasofdate BETWEEN @ab3+ 1 AND @ab4 THEN 4  
    WHEN -a.date_applied+@jasofdate BETWEEN @ab4+ 1 AND @ab5 THEN 5  
    WHEN -a.date_applied+@jasofdate > @ab5 THEN 6  END,  
    days_aged = -a.date_applied+@jasofdate 
 FROM #rpt_apaging b inner join aptrxage a
    on a.trx_ctrl_num = b.trx_ctrl_num  AND a.ref_id = b.ref_id 
 END
  

UPDATE #rpt_apaging SET groupby1_desc = b.description  
FROM #rpt_apaging a inner join apclass b  
on a.class_code = b.class_code

update a set a.terms_code = vo.terms_code
From #rpt_apaging a inner join apvohdr_all vo
on a.trx_ctrl_num = vo.trx_ctrl_num

IF(OBJECT_ID('tempdb.dbo.#ctemp') is not null)  drop table #ctemp
CREATE TABLE #ctemp (vendor_code varchar(12), num smallint) 

INSERT #ctemp (vendor_code,num) 
SELECT vendor_code, COUNT(DISTINCT nat_cur_code) 
FROM #rpt_apaging 
GROUP BY vendor_code 

UPDATE #rpt_apaging SET num_currencies = b.num 
FROM #rpt_apaging a inner join #ctemp b 
on a.vendor_code = b.vendor_code AND b.num > 1

IF(OBJECT_ID('tempdb.dbo.#ctemp') is not null)  drop table #ctemp

SELECT r.date_applied, 
r.apply_to_num, 
r.nat_cur_code, 
r.contact_name, 
r.contact_phone, 
r.addr2, 
r.addr3, 
r.addr4, 
r.addr5, 
r.addr6, 
r.attention_name, 
r.attention_phone, 
r.addr1, 
r.doc_ctrl_num, 
r.date_due, 
r.date_aging, 
r.amount, 
r.date_doc, 
r.trx_ctrl_num, 
r.bracket, 
r.trx_type_code, 
r.vendor_code, 
r.symbol, 
r.curr_precision, 
r.groupby2, 
r.trx_type, 
r.groupby3, 
r.groupby1, 
r.groupby1_desc, 
r.rate_home, 
r.rate_oper, 
r.sort_date, 
r.num_currencies, 
r.days_aged, 
isnull(datediff(day,r.date_doc,r.date_due),0) as days_term,
r.groupby4, 
r.groupby0, 
r.status_type, 
r.org_id, 
r.region_id,
r.terms_code 
FROM     #rpt_apaging r
ORDER BY r.groupby0, r.groupby1, r.groupby2, r.groupby3

end


GO
GRANT EXECUTE ON  [dbo].[cvo_apaging_sp] TO [public]
GO
