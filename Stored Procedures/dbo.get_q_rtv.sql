SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_rtv]  @info varchar(30), @sort char(1), @rtvno int , @secured_mode int = 0
 AS

declare @x int

set @secured_mode = isnull(@secured_mode,0)

set rowcount 100
if @secured_mode = 0
begin
if @sort='D'
begin
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK )
   where    r.rtv_no=x.rtv_no and
            r.date_of_order >= @info AND r.rtv_no >= @rtvno
   order by r.date_of_order, x.part_no
end
if @sort='P'
begin
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK )
   where    r.rtv_no=x.rtv_no and
            x.part_no >= @info AND r.rtv_no >= @rtvno
   order by x.part_no, r.rtv_no
end
if @sort='V'
begin
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK )
   where    r.rtv_no=x.rtv_no and
            r.vendor_no >= @info AND r.rtv_no >= @rtvno
   order by r.vendor_no, r.rtv_no, x.part_no
end
if @sort='M'
begin
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK )
   where    r.rtv_no=x.rtv_no and
            r.ship_name >= @info AND r.rtv_no >= @rtvno
   order by r.ship_name, r.rtv_no, x.part_no
end
if @sort='N'
begin
   select  @x=convert(int,@info)
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK )
   where    r.rtv_no=x.rtv_no and
            r.rtv_no >= @x
   order by r.rtv_no
end
end
else
begin
if @sort='D'
begin
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK ), adm_vend v (nolock)
   where    r.rtv_no=x.rtv_no and v.vendor_code = r.vendor_no and
            r.date_of_order >= @info AND r.rtv_no >= @rtvno
   order by r.date_of_order, x.part_no
end
if @sort='P'
begin
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK ), adm_vend v (nolock)
   where    r.rtv_no=x.rtv_no and v.vendor_code = r.vendor_no and
            x.part_no >= @info AND r.rtv_no >= @rtvno
   order by x.part_no, r.rtv_no
end
if @sort='V'
begin
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK ), adm_vend v (nolock)
   where    r.rtv_no=x.rtv_no and v.vendor_code = r.vendor_no and
            r.vendor_no >= @info AND r.rtv_no >= @rtvno
   order by r.vendor_no, r.rtv_no, x.part_no
end
if @sort='M'
begin
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK ), adm_vend v (nolock)
   where    r.rtv_no=x.rtv_no and v.vendor_code = r.vendor_no and
            r.ship_name >= @info AND r.rtv_no >= @rtvno
   order by r.ship_name, r.rtv_no, x.part_no
end
if @sort='N'
begin
   select  @x=convert(int,@info)
   select   r.rtv_no, r.vendor_no, r.ship_name, x.part_no, x.location, 
            x.qty_ordered, x.unit_measure, r.date_of_order
   from     rtv r ( NOLOCK ), rtv_list x ( NOLOCK ), adm_vend v (nolock)
   where    r.rtv_no=x.rtv_no and v.vendor_code = r.vendor_no and
            r.rtv_no >= @x
   order by r.rtv_no
end
end
GO
GRANT EXECUTE ON  [dbo].[get_q_rtv] TO [public]
GO
