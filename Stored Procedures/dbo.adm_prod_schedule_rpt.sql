SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_prod_schedule_rpt] @startdt varchar(30), @enddt varchar(30),
  @loc varchar(10), @part varchar(30), @startst char(1), @endst char(1) AS
BEGIN
declare @date1 datetime, @date2 datetime, @start varchar(30), @end varchar(30)
declare @date_format varchar(30)
select @date_format = isnull((select upper(value_str) from config (nolock)
  where upper(flag) = 'RPT_DATE_FORMAT'),'MM/DD/YYYY')	

if @date_format like 'DD/MM/YY%'	
begin
  select @startdt = substring(@startdt,4,2) + '/' + substring(@startdt,1,2) + '/' + 
    substring(@startdt,7,4)
  select @enddt = substring(@enddt,4,2) + '/' + substring(@enddt,1,2) + '/' + substring(@enddt,7,4)
end								

select @date1 = case IsDate(@startdt) when 1 then convert(datetime,@startdt) else '1/1/1753' end, 
  @date2 = case IsDate(@enddt) when 1 then convert(datetime,@enddt) else '12/31/9999' end    
select @date2 = dateadd(hour,23,@date2)					
select @date2 = dateadd(minute,59,@date2)
select @date2 = dateadd(second,59,@date2)					

SELECT  
p.location,  
p.status,  
rtrim(convert(varchar(12), p.prod_no)) + '-' + rtrim(convert(varchar(4), p.prod_ext)) prod_no,  
p.part_no  + ' ' +  i.description item_no ,  
p.uom,  
p.sch_date,  
p.qty_scheduled_orig,  
p.prod_date,  
p.qty,  
p.end_sch_date,  
p.shift,  
p.staging_area  
FROM produce_all p
left outer join inv_master i (nolock) on ( p.part_no = i.part_no ) 
WHERE  ( p.prod_date between @date1 and @date2) AND  
( p.status between @startst AND @endst) AND  
( p.location like @loc) AND  
( p.part_no like @part)

end
GO
GRANT EXECUTE ON  [dbo].[adm_prod_schedule_rpt] TO [public]
GO
