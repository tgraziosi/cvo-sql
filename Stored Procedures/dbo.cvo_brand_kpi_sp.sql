SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_brand_kpi_sp] 
@brand varchar(10), 
@rollingtomonth datetime,
@months int

-- exec cvo_brand_kpi_sp 'bcbg','10/31/2013', 1
-- 1 = one month by style within brand
-- 3 = 3 months by style within brand
-- 12 = 12 months rolling by brand

as 
begin
declare @ty datetime
declare @py datetime
select  @ty = (DATEADD(m, -@months, DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 0,0)) + 1)
-- select @py = (DATEADD(m, -24, DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 0,0)) + 1)
select  @rollingtomonth =      (DATEADD(dd, datediff(dd,0,@RollingToMonth) + 0,0))

--select @ty, dateadd(d,-1,@ty), @py, @rollingtomonth
--return

if @months = 12
begin
    
    IF(OBJECT_ID('tempdb.dbo.#rad_det') is not null)  drop table #rad_det

    SELECT  c.Brand, 
    c.year, c.x_month,
    sum(qnet_frames) as q_frames,
    sum(qnet_parts) as q_parts,
    sum(qsales - qreturns) as qnet,
    isnull((select sum(qsales - qreturns) 
        from cvo_rad_brand cc where cc.year = c.year - 1 
        and cc.x_month = c.x_month and cc.brand =c.brand),0) as qnet_ly,
    sum(netsales) anet,
    isnull((select sum(netsales) 
        from cvo_rad_brand cc where cc.year = c.year - 1 
        and cc.x_month = c.x_month and cc.brand =c.brand),0) as anet_ly,
    sum(isactivedoor) ActiveDoors,
    sum(isnew) NewAcct
    into #rad_det
    FROM  cvo_rad_brand c (nolock)
    WHERE  c.brand IN (@Brand) AND
     c.yyyymmdd between @ty and @rollingtomonth
     group by c.brand, c.year, c.x_month
    
    select brand, month, year, x_month, q_frames, q_parts, qnet, qnet_ly,
    cast((case when qnet_ly = 0 then 0 else (convert(float,qnet)/convert(float,qnet_ly))-1 end) as decimal(20,8)) as lyty_units,
    anet, anet_ly,
    cast((case when anet_ly = 0 then 0 else (anet/anet_ly) end) as decimal(20,8))-1 as lyty_sales,
    activedoors, newacct, @months months_reported
    from #rad_det
end -- 12 months data

if isnull(@months,0) in (1,3) 
begin

    SELECT  i.category as Brand, ia.field_2 as Model, c.*, @months months_reported
    FROM  cvo_sbm_details c (nolock)
    inner join inv_master i (nolock) on c.part_no = i.part_no
    inner join inv_master_add ia (nolock) on c.part_no = ia.part_no
    WHERE  i.category IN (@Brand) AND
     c.yyyymmdd >= (DATEADD(m, -@months, DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 0,0)) + 1)
       AND c.yyyymmdd < DATEADD(dd, datediff(dd, 0,@RollingToMonth) + 1,0)
    AND type_code IN ('Frame','Sun')

end -- 1 and 3 months

if isnull(@months,0) = 50
begin
    select Top 12 o.order_no, i.category Brand, ia.field_2 Style, sum(ol.ordered) order_qty,
    o.ship_to_name
     from ord_list ol (nolock) 
    inner join orders o (nolock) on ol.order_no = o.order_no and ol.order_ext = o.ext
    inner join inv_master i (nolock) on ol.part_no = i.part_no
    inner join inv_master_add ia (nolock) on ol.part_no = ia.part_no
    where o.who_entered <> 'backordr' and o.status = 't' and i.type_code in ('frame','sun')
    and right(o.user_category,2) not in ('rb','tb','pm')
    and i.category = @Brand
    group by  o.order_no, i.category, o.ship_to_name, ia.field_2
    having sum(ol.ordered) >= 50
end -- large order details

end -- end of procedure
GO
GRANT EXECUTE ON  [dbo].[cvo_brand_kpi_sp] TO [public]
GO
