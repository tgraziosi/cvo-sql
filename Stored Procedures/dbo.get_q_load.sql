SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_load] @strsort varchar(255), @sort char(1) AS

set rowcount 100
declare @x int

if (@strsort is null) 
 begin
  select @strsort = '%'
 end
	
if @sort='L' begin
 if @strsort = '%' select @strsort = '0'
 select @x=convert(int,@strsort)
 
 select distinct h.load_no,d.order_no,d.ext,d.ship_to_name, d.ship_to_add_1, d.ship_to_city, d.ship_to_state, d.ship_to_zip
  from orders_all d ( NOLOCK ), load_master h ( NOLOCK ), load_list l ( NOLOCK )
  where (l.load_no = h.load_no) and
	(l.order_no=d.order_no) and
	(l.order_ext=d.ext) and
        (h.load_no >= @x)
 order by h.load_no
end 	
	
if @sort='O' begin
 if @strsort = '%' select @strsort = '0'
 select @x=convert(int,@strsort)
 
 select distinct h.load_no,d.order_no,d.ext,d.ship_to_name, d.ship_to_add_1, d.ship_to_city, d.ship_to_state, d.ship_to_zip
  from orders_all d ( NOLOCK ), load_master h ( NOLOCK ), load_list l ( NOLOCK )
  where (l.load_no = h.load_no) and
	(l.order_no=d.order_no) and
	(l.order_ext=d.ext) and
        (d.order_no >= @x)
  order by d.order_no
end 	
	
if @sort='S' begin
 if charindex( '%', @strsort ) <= 0 
  begin 
   select @strsort = RTrim(@strsort) + '%'
  end
 select distinct h.load_no,d.order_no,d.ext,d.ship_to_name, d.ship_to_add_1, d.ship_to_city, d.ship_to_state, d.ship_to_zip
  from orders_all d ( NOLOCK ), load_master h ( NOLOCK ), load_list l ( NOLOCK )
  where (l.load_no = h.load_no) and
	(l.order_no=d.order_no) and
	(l.order_ext=d.ext) and
        (d.ship_to_name like @strsort)
  order by d.ship_to_name
end		






























GO
GRANT EXECUTE ON  [dbo].[get_q_load] TO [public]
GO
