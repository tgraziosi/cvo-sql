SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_invforecast] @range varchar(8000) = '0=0',
@order varchar(1000) = ' EFPROD.PART' 
as

BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

select @sql = ' SELECT  distinct
EFSESS.FOREDESC,  
EFSESS.SESSTIMESTAMP,  
EFSESS.SESSNOTE,  
EFLOC.LOCATION, 
EFPROD.PART,  
EFPROD.NAME,  
EFPROMO.PROMOTION,  
EFTIME.LABEL,  
EFFORE.FORECAST 
FROM  
EFORECAST_SESSION EFSESS (nolock),  
EFORECAST_TIME EFTIME (nolock),  
EFORECAST_FORECAST EFFORE (nolock),  
EFORECAST_LOCATION EFLOC (nolock),  
EFORECAST_PRODUCT EFPROD (nolock),  
EFORECAST_PROMO EFPROMO  (nolock),
locations l (nolock), region_vw r (nolock)
WHERE 
EFFORE.SESSIONID = EFSESS.SESSIONID AND  
   l.location = EFLOC.LOCATION and 
   l.organization_id = r.org_id and
EFFORE.LOCATIONID = EFLOC.LOCATIONID AND 
EFFORE.PRODUCTID = EFPROD.PRODUCTID AND 
EFFORE.PROMOID = EFPROMO.PROMOID AND 
EFFORE.TIMEID = EFTIME.TIMEID AND ' +
@range + ' 
ORDER BY ' + @order

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_invforecast] TO [public]
GO
