SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_brand_kpi_rolling12_sp] 
@brand varchar(10), 
@rollingtomonth datetime,
@months int

-- exec cvo_brand_kpi_rolling12_sp 'bcbg','10/31/2013', 12
-- 1 = one month by style within brand
-- 3 = 3 months by style within brand
-- 12 = 12 months rolling by brand

as 
begin
declare @ty datetime
declare @py datetime

select @months = 12

select  @ty = (DATEADD(m, -@months, DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 0,0)) + 1)
-- select @py = (DATEADD(m, -24, DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 0,0)) + 1)
select  @rollingtomonth =      (DATEADD(dd, datediff(dd,0,@RollingToMonth) + 0,0))

--select @ty, dateadd(d,-1,@ty), @py, @rollingtomonth
--return

--if @months = 12
--begin
    
    IF(OBJECT_ID('tempdb.dbo.#rad_det') is not null)  drop table #rad_det

    SELECT  c.Brand, 
    c.year, c.x_month,
    sum(qnet_frames) as q_frames,
    sum(qnet_parts) as q_parts,
    sum(qnet_cl) as qnet_cl,
    sum(qsales - qreturns) as qnet,
    isnull((select sum(qsales - qreturns) 
        from cvo_rad_brand cc where cc.year = c.year - 1 
        and cc.x_month = c.x_month and cc.brand = c.brand),0) as qnet_ly,
    sum(netsales) anet,
    sum(anet_cl) anet_cl,
    isnull((select sum(netsales) 
        from cvo_rad_brand cc where cc.year = c.year - 1 
        and cc.x_month = c.x_month and cc.brand = c.brand),0) as anet_ly,
    sum(isactivedoor) ActiveDoors,
    sum(isnew) NewAcct
    into #rad_det
    FROM  cvo_rad_brand c (nolock)
    WHERE  c.brand IN (@Brand) AND
     c.yyyymmdd between @ty and @rollingtomonth
     group by c.brand, c.year, c.x_month
    
    select brand, year, x_month, q_frames, q_parts, qnet_cl, qnet, qnet_ly,
    cast((case when qnet_ly = 0 then 0 else (convert(float,qnet)/convert(float,qnet_ly))-1 end) as decimal(20,8)) as lyty_units,
    anet, anet_cl, anet_ly,
    cast((case when anet_ly = 0 then 0 else (anet/anet_ly) end) as decimal(20,8))-1 as lyty_sales,
    activedoors, newacct, @months as months_reported
    from #rad_det

end -- end of procedure
GO
GRANT EXECUTE ON  [dbo].[cvo_brand_kpi_rolling12_sp] TO [public]
GO
