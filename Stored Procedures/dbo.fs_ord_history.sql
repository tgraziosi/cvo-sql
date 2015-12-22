SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_ord_history] @cust varchar(10), @shipto varchar(10), @org_id varchar(30) = '', @module varchar(10) = '',
  @sec_level int = 99 AS
BEGIN

declare @chkdate datetime
declare @x integer
declare @part varchar(30), @custname varchar(40)
declare @hdays integer,    @chardays varchar(40)
select @chardays = value_str from config where flag='OE_HISTORY_DAYS'
if @chardays is null begin
   select @chardays = '365'
end
select @hdays = Abs( convert( integer, @chardays ) )
if @hdays = 0 begin
   select @hdays = 365
end
select @hdays = -1 * @hdays
select @shipto = LTrim( @shipto )
if @shipto = '' begin
   select @shipto = null
end

select @chkdate = DateAdd( day, @hdays, getdate() )

select @custname = customer_name
from   adm_cust_all
where  customer_code = @cust

CREATE TABLE #history (
   customer_key    varchar(10)      ,  ship_to_no    varchar(10) NULL,
   customer_name   varchar(40) NULL ,  part_no       varchar(30),
   cust_part       varchar(30) NULL ,  uom           char(2) NULL,
   ordered         decimal(20,8)    ,  shipped       decimal(20,8),
   price           decimal(20,8)    ,  date_shipped  datetime NULL,
   order_no        integer          ,  order_ext     integer,
   line_no         integer          ,  new_qty       decimal(20,8) ,
   description     varchar(255) NULL,  location      varchar(10),
   conv_factor     decimal(20,8)    ,  price_type    char(1) NULL,
   new_price_type  char(1) NULL     ,  new_price     decimal(20,8) NULL,
   part_type       char(1),								-- mls 7/25/00 SCR 23475
   row_id        integer Identity(1,1) )

create index h1 on #history(row_id)

INSERT #history
SELECT cust_code,      ship_to_no,        @custname,
       part_no,        null,              null,
       ordered,        shipped,           price,
       date_shipped,   order_no,          order_ext,
       line_no,        0,                 null,
       location,       conv_factor,       price_type,
       case when part_type = 'M' then 'X' else NULL end,				-- mls 7/25/00 SCR 23475 start
       case when part_type = 'M' then price else NULL end,
       part_type									-- mls 7/25/00 SCR 23475 end
FROM   shippers
WHERE  (cust_code = @cust and date_shipped >= @chkdate) and
       ( (@shipto > '' and ship_to_no = @shipto) or
         (@shipto is null and (isnull(ship_to_no,'') ='') ) ) and
       (ordered+shipped) > 0 and
	part_type not in ('A','E','J','X')						-- mls 7/26/00 SCR 23475
       and (@org_id = '' or location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id, @sec_level)))
ORDER BY date_shipped DESC

select @x = isnull((select min(row_id) from #history),0)
while @x > 0 
begin
   select @part = part_no
   from #history
   where row_id = @x

   delete #history
   where  part_no = @part and row_id > @x

   select @x = isnull((select min(row_id) from #history where row_id > @x),0)
end

update #history
set    uom=o.uom, description=o.description
from   ord_list o
where  #history.order_no=o.order_no and #history.order_ext=o.order_ext and
       #history.line_no=o.line_no

update #history
set    cust_part=x.cust_part
from   cust_xref x
where  #history.customer_key=x.customer_key and #history.part_no=x.part_no

select 
   customer_key    , ship_to_no      ,
   customer_name   , new_qty         , 
   location        , part_no         ,
   cust_part       , description     , uom           ,
   ordered         , shipped         ,
   price           , date_shipped    ,
   order_no        , order_ext       ,
   line_no         , conv_factor     ,
   price_type      , new_price_type  ,
   new_price,
   part_type										-- mls 7/25/00 SCR 23475
from #history
order by date_shipped DESC, part_no
END


GO
GRANT EXECUTE ON  [dbo].[fs_ord_history] TO [public]
GO
