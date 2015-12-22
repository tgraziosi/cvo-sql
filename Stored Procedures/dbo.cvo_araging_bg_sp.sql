SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
exec cvo_araging_bg_sp 0
*/
CREATE procedure [dbo].[cvo_araging_bg_sp] @regen int 
as 

begin

   if @regen = 1 exec cvo_araging_ssrs_sp

set nocount on

if(object_id('tempdb.dbo.#araging') is not null) drop table #araging
if(object_id('tempdb.dbo.#araging_bg') is not null) drop table #araging_bg

select bg_code cust_code, 
    cast('BG' as varchar(40)) as [key],
    attn_email,
    sls,
    terr, 
    region, 
    name,
    cust_code as bg_code,
    name as bg_name,
    tms,
    avgdayslate,
    bal,
    fut, 
    cur,
    ar30,
    ar60,
    ar90,
    ar120,
    ar150,
    credit_limit,
    onorder,
    cast( 0 as datetime) lpmtdt,
    cast( 0 as float) amount, -- figure this out later
    ytdcreds,
    ytdsales,
    lyrsales,
    r12sales,
    hold,
    date_asof,
    date_type_string,
    date_type
into #araging
from ssrs_araging_temp where bg_code <> ''

-- select * From ssrs_araging_temp
--tempdb..sp_help #araging
--sp_help ssrs_araging_temp

insert into #araging
select * From ssrs_araging_temp where isnull(bg_code,'') = '' 

declare @last_bg varchar(8), @last_check varchar(16), @last_amt float, 
    @date_entered int, @hold varchar(5)

select @last_bg = min(cust_code) from #araging where [key] = 'BG'

while (@last_bg is not null)
begin
-- tag - last payment and date - simple version
        
    SELECT @date_entered = MAX( isnull(date_entered,0) ) 
	FROM artrx
	WHERE customer_code = @last_bg
	AND trx_type = 2111
	AND void_flag = 0
	AND payment_type <> 3	

    SELECT @last_check = isnull(doc_ctrl_num,''),
		   @last_amt = isnull(amt_net,0)
	FROM artrx
	WHERE customer_code = @last_bg
	AND trx_type = 2111
	AND void_flag = 0
	AND payment_type <> 3	
	AND	date_entered = @date_entered
	ORDER BY trx_ctrl_num DESC

    set @hold = ''
    select @hold = isnull(C.STATUS_CODE,'')
	FROM CC_CUST_STATUS_HIST C
	WHERE c.customer_code = @last_bg AND C.CLEAR_DATE IS NULL
    
	update #araging set #araging.lpmtdt = convert(varchar,dateadd(d,@date_entered-711858,'1/1/1950'),101)        ,#araging.hold = @hold 
	    ,#araging.amount = @last_amt
	    where #araging.cust_code = @last_bg
		
	select @last_bg = min(cust_code) from #araging
		    where cust_code > @last_bg and [key] = 'BG'
end

update #araging set 
    [key] = addr_sort1, -- 11/12/13
    attn_email = attention_email,
    sls = salesperson_code,
    terr = territory_code,
    region = dbo.calculate_region_fn(territory_code),
    tms = arcust.price_code,
    name = customer_name,
    credit_limit = arcust.credit_limit
from #araging inner join arcust on arcust.customer_code =#araging.cust_code
where #araging.[key] = 'BG'

--select * From arcust

select 
    cust_code, 
    min([key]) [key],
    isnull(max(attn_email),'') attn_email ,
    sls,
    terr, 
    region,
    name,
    --'' bg_code,
    --'' bg_name,
    tms,
    avg(avgdayslate) avgdayslate,
    sum(bal) bal,
    suM(fut) fut, 
    sum(cur) cur,
    sum(ar30) ar30,
    sum(ar60) ar60,
    sum(ar90) ar90,
    sum(ar120) ar120,
    sum(ar150) ar150,
    credit_limit,
    sum(onorder) onorder,
    max(lpmtdt) lpmtdt,
    max(amount) amount,
    sum(ytdcreds) ytdcreds,
    sum(ytdsales) ytdsales,
    sum(lyrsales) lyrsales,
    sum(r12sales) r12sales,
    hold,
    date_asof
into #araging_bg
from #araging
group by cust_code, 
name, 
--attn_email ,
sls,
terr, 
region,
name,
tms,
credit_limit,
hold,
date_asof


Select  *
, (AR30+AR60+AR90+AR120+AR150) AS TOTPD, Case 
When BAL < 1  Then 'LT1'
When (AR30+AR60+AR90+AR120+AR150) < 1 then 'LT1'
Else
'GT1'
End As CheckBal
,case
When [KEY] = 'Intl Retailer' And (AR90 >=1 OR AR120 >= 1 OR AR150 >= 1) Then 'I90'
Else
''
End As INTL90
,Case
When [key] <> 'Key Account' AND [key] <> 'Intl Retailer' And (AR60 >=1 OR AR90 >=1 OR AR120 >= 1 OR AR150 >= 1) Then 'NK60'
Else
''
End As NonKey60
,Case
When Hold = '' OR Hold is NULL Then ''
Else
'H'
End As IsHold
,Case
When BAL - Credit_Limit > 1000  and [key] <> 'Buying Group' Then 'OCL1K'
Else
''
End As OverCL
From #araging_bg

end


GO
GRANT EXECUTE ON  [dbo].[cvo_araging_bg_sp] TO [public]
GO
