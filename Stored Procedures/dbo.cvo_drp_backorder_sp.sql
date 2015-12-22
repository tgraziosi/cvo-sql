SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure [dbo].[cvo_drp_backorder_sp] as 
begin

IF (SELECT OBJECT_ID('tempdb..#t')) IS NOT NULL 
BEGIN  
DROP TABLE #t  
END

select d.collection, d.style, d.type_code, d.part_no, d.status_description, d.release_date, 
d.pom_date, datediff(dd,getdate(),isnull(d.pom_date,getdate()))/7 wks_til_pom,
d.lead_time, d.location, isnull(ia.field_32,'') spec_fit,
d.on_hand, d.e4_wu, isnull(d.backorder,0) backorder, 
case when d.avend > 0 then 0 else d.avend end avend
, case when d.av4end > 0 then 0 else d.av4end end av4end
, case when d.av8end > 0 then 0 else d.av8end end av8end
, case when d.av12end > 0 then 0 else d.av12end end av12end
, case when d.av16end > 0 then 0 else d.av16end end av16end
, case when d.av20end > 0 then 0 else d.av20end end av20end
, case when d.av24end > 0 then 0 else d.av24end end av24end
into #t
From dpr_report d (nolock) inner join inv_master_add ia on ia.part_no = d.part_no
where 1=1
and (isnull (backorder,0) > 0
or avend < 0 or av4end < 0 or av8end < 0 or av12end < 0 or av16end < 0 or av20end < 0 or av24end < 0)
and location = '001'
and (pom_date is null or pom_date >= getdate())
and type_code in ('Frame/Sun')
and isnull(ia.field_32,'') not in ('costco','retail','hvc')

update #t set av4end = 0 where wks_til_pom <4 and pom_date is not null
update #t set av8end = 0 where wks_til_pom < 8 and pom_date is not null
update #t set av12end = 0 where wks_til_pom < 12 and pom_date is not null
update #t set av16end = 0 where wks_til_pom < 16 and pom_date is not null
update #t set av20end = 0 where wks_til_pom < 20 and pom_date is not null
update #t set av24end = 0 where wks_til_pom < 24 and pom_date is not null

select * from #t
order by collection, style, part_no

end
GO
GRANT EXECUTE ON  [dbo].[cvo_drp_backorder_sp] TO [public]
GO
