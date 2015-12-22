SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_ord] @strsort varchar(20), @sort varchar(1), 
@status varchar(1), @otype varchar(5), @ordno int = 0,
@maxrowcount int = 20,
@ordext int = 0	, @secured_mode int = 0
												-- mls 1/7/04 SCR 31961
AS

declare @sql varchar(4000),
@order_table varchar(30),
@cust_table varchar(30)


set @secured_mode = isnull(@secured_mode,0)

set rowcount 0

declare @lastkey int
declare @minstat char(1)
declare @maxstat char(1)
declare @minfilter char(1)
declare @maxfilter char(1)
declare @x int
declare @po varchar(20)
declare @ship varchar(40)
declare @invoice int
declare @custname varchar(40)
declare @custcode varchar(20)
declare @nextkey int, @nextext int
declare @counter int

create table #t1
 (order_no int,
  ext int,
  cust_code varchar(20) null,
  cust_name varchar(40) null,
  ship_to_name varchar(40) null,
  cust_po varchar(20) null,
  req_ship_date datetime null,
  invoice_no int null,
  status char(1) null,
  ship_to_city varchar(40) null,
  ship_to_state varchar(40) null)

--create index #tc on #t1(sortfield)

select @lastkey=@ordno

if @status = 'A' begin 
select @minstat='A'
select @maxstat='U'
select @minfilter = ''
select @maxfilter = ''
end
if @status = 'B' begin 
select @minstat='A'
select @maxstat='U'
select @minfilter = 'L'
select @maxfilter = 'Q'
end
if @status = 'H' begin 
select @minstat='A'
select @maxstat='H'
select @minfilter = ''
select @maxfilter = ''
end
if @status = 'K' begin 
select @minstat='A'
select @maxstat='Q'
select @minfilter = ''
select @maxfilter = ''
end
if @status = 'N' begin 
select @minstat='L'
select @maxstat='Q'
select @minfilter = ''
select @maxfilter = ''
end
if @status = 'Q' begin 
select @minstat='L'
select @maxstat='U'
select @minfilter = ''
select @maxfilter = ''
end
if @status = 'S' begin 

select @minstat='R'
select @maxstat='U'
select @minfilter = ''
select @maxfilter = ''
end
if @status = 'V' begin 
select @minstat='V'
select @maxstat='V'
select @minfilter = ''
select @maxfilter = ''
end

if @status = '1'					-- mls 2/13/03 SCR 30690
begin
select @minstat = 'T', @maxstat = 'T', @minfilter = '', @maxfilter = ''
end 

if @otype is NULL
begin
  select @otype = ''
end

select @order_table = case @secured_mode  when 1 then 'orders_entry_vw' when 2 then 'orders_shipping_vw' else 'orders_all' end
select @cust_table = case @secured_mode  when 1 then 'adm_cust' when 2 then 'adm_cust_all' else 'adm_cust_all' end

if @otype= 'PS' -- post shipments search
begin
  select @otype = 'SS'
  select @order_table = 'orders_posting_vw'
  if @status = 'S' select @maxstat = 'S'
end 

	
if @sort='I' 
BEGIN
  select @x = convert(int,@strsort)							-- mls 4/13/00 SCR 22700 start

  set rowcount @maxrowcount
  select @sql = 'select b.order_no, b.ext, b.cust_code, c.customer_name, b.ship_to_name, 
    b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state, ' + convert(varchar,@maxrowcount) 
  select @sql = @sql + ' from ' + @order_table + ' b (nolock), ' + @cust_table + ' c (nolock)' 
  select @sql = @sql + ' where b.cust_code = c.customer_code and b.type = ''I'''  
  select @sql = @sql + ' and b.invoice_no >= ' + convert(varchar,@x) 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  select @sql = @sql + ' and ((b.invoice_no = ' + convert(varchar,@x ) 
  select @sql = @sql + ' and (order_no > ' + convert(varchar,@lastkey) + ' or (order_no = ' + convert(varchar,@lastkey) + ' and ext >= ' 
  select @sql = @sql + convert(varchar,@ordext) + '))) or (b.invoice_no > ' + convert(varchar,@x) + '))' 
  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  select @sql = @sql + ' order by b.invoice_no, b.order_no	, b.ext	'

  print @sql
  exec (@sql)
END	

	
if @sort='P' 
BEGIN
  select @po = @strsort									-- mls 4/13/00 SCR 22700 start
  select @po = isnull(@po,'')

  set rowcount @maxrowcount
  select @sql = 'select order_no, ext, cust_code, customer_name, ship_to_name, cust_po,
	req_ship_date, invoice_no, status, ship_to_city, ship_to_state, ' + convert(varchar,@maxrowcount) + '
	from
	(select b.order_no, b.ext, b.cust_code, c.customer_name, b.ship_to_name, 
    b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state ' 
  select @sql = @sql + ' from ' + @order_table + ' b (nolock), ' + @cust_table + ' c (nolock)' 
  select @sql = @sql + ' where b.cust_code = c.customer_code and b.type = ''I'''  
  if @po != '' select @sql = @sql + ' and isnull(b.cust_po,'''') >= ''' + @po + ''''
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'
  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  select @sql = @sql + ' and ((b.cust_po = ''' + @po + '''' 
  select @sql = @sql + ' and (order_no > ' + convert(varchar,@lastkey) + ' or (order_no = ' + convert(varchar,@lastkey) + ' and ext >= ' 
  select @sql = @sql + convert(varchar,@ordext) + '))) or (b.cust_po > ''' + @po + '''))' 
  select @sql = @sql + ' union
	select b.order_no, b.ext, b.cust_code, c.customer_name, b.ship_to_name, 
    l.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state ' 
  select @sql = @sql + ' from ' + @order_table + ' b (nolock), ' + @cust_table + ' c (nolock)' 
  select @sql = @sql + ', ord_list l (nolock) '
  select @sql = @sql + ' where b.cust_code = c.customer_code and b.type = ''I'''  
  select @sql = @sql + ' and b.order_no = l.order_no and b.ext = l.order_ext'
  if @po != '' select @sql = @sql + ' and l.cust_po >= ''' + @po + ''''
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'
  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  select @sql = @sql + ' and ((l.cust_po = ''' + @po + '''' 
  select @sql = @sql + ' and (b.order_no > ' + convert(varchar,@lastkey) + ' or (b.order_no = ' + convert(varchar,@lastkey) + ' and b.ext >= ' 
  select @sql = @sql + convert(varchar,@ordext) + '))) or (l.cust_po > ''' + @po + '''))' 
  select @sql = @sql + ') as t (order_no, ext, cust_code, customer_name, ship_to_name, cust_po,
	    req_ship_date, invoice_no, status, ship_to_city, ship_to_state)'
  select @sql = @sql + ' order by cust_po, order_no	, ext'

  print @sql
  exec (@sql)
	-- mls 1/12/04 SCR 31961
END	

	
if @sort='S' 
BEGIN
  if @lastkey != 0
    select @strsort = (select min(ship_to_name) from orders_all (nolock) where order_no = @lastkey and ext = @ordext)


  select @sql = ' declare @counter int, @maxrowcount int, @ship varchar(40)
  set @maxrowcount = ' + convert(varchar,@maxrowcount) + '
  set @ship = ''' + isnull(@strsort,'') + '''
  set @counter = -1
  create table #t1
   (order_no int,
    ext int,
    cust_code varchar(20) null,
    cust_name varchar(40) null,
    ship_to_name varchar(40) null,
    cust_po varchar(20) null,
    req_ship_date datetime null,
    invoice_no int null,
    status char(1) null,
    ship_to_city varchar(40) null,
    ship_to_state varchar(40) null)' 

  select @sql = @sql + '
  while  (@counter <= @maxrowcount)
  BEGIN
    if @counter > 0
    begin
    insert into #t1
    select b.order_no, b.ext, b.cust_code, '''', @ship, b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state
    from ' + @order_table + ' b (nolock) , ' + @cust_table + ' c (nolock)
    where (b.ship_to_name= @ship)  and b.cust_code = c.customer_code
      and b.type = ''I'''

  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'

  select @sql = @sql + '
    order by b.order_no desc, b.ext desc
      select @counter = @counter + @@rowcount
    end

    if @counter = -1 and @ship <> ''''
    begin
    insert into #t1
    select b.order_no, b.ext, b.cust_code, '''', @ship, b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state
    from ' + @order_table + ' b (nolock)  , ' + @cust_table + ' c (nolock)
    where (b.ship_to_name= @ship)   and b.cust_code = c.customer_code
      and b.type = ''I'' and (b.order_no < ' + convert(varchar,@lastkey) + ' or (b.order_no = ' + convert(varchar,@lastkey) + ' and 
      b.ext <= ' + convert(varchar,@ordext) + '))'

  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'

  select @sql = @sql + '
    order by b.order_no desc, b.ext desc
    select @counter = @@rowcount
    if @counter = 0 and ' + convert(varchar,@lastkey) + ' = 0 set @counter = -1
    end
    if (@counter <= @maxrowcount)
    begin
if @counter = -1
      select @ship = isnull((select min(ship_to_name) from orders_all b (nolock) , ' + @cust_table + ' c (nolock)
      where ((b.ship_to_name >= @ship))  and b.cust_code = c.customer_code
      and b.type = ''I'''
  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'

  select @sql = @sql + '
	),null)
else
      select @ship = isnull((select min(ship_to_name) from orders_all b (nolock) , ' + @cust_table + ' c (nolock)
      where ((b.ship_to_name > @ship) )  and b.cust_code = c.customer_code
      and b.type = ''I'''
  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'

  select @sql = @sql + '
	),null)

      if @counter = -1 select @counter = 1
      if @ship is NULL
        select @counter=@maxrowcount + 1
    end
  END 

  set rowcount @maxrowcount
  select t.order_no, t.ext, t.cust_code, c.customer_name, t.ship_to_name, t.cust_po, t.req_ship_date, t.invoice_no, t.status, t.ship_to_city, t.ship_to_state,
    @maxrowcount
  from ' + @cust_table + ' c (nolock), #t1 t where t.cust_code = c.customer_code
  order by t.ship_to_name, t.order_no desc, t.ext desc'

print @sql
exec (@sql)
END	


	
if @sort='C' 
BEGIN
  
  if @lastkey != 0
    select @strsort = (select min(cust_code) from orders_all (nolock) 
      where order_no = @lastkey and ext = @ordext and type = 'I')			-- mls 1/12/04 SCR 31961

  select @sql = ' declare @counter int, @maxrowcount int, @custcode varchar(20)
  set @maxrowcount = ' + convert(varchar,@maxrowcount) + '
  set @custcode = ''' + isnull(@strsort,'') + '''
  set @counter = -1
  create table #t1
   (order_no int,
    ext int,
    cust_code varchar(20) null,
    cust_name varchar(40) null,
    ship_to_name varchar(40) null,
    cust_po varchar(20) null,
    req_ship_date datetime null,
    invoice_no int null,
    status char(1) null,
    ship_to_city varchar(40) null,
    ship_to_state varchar(40) null)' 

  select @sql = @sql + '
  while  (@counter <= @maxrowcount)
  BEGIN
    if @counter > 0
    begin
    insert into #t1
    select b.order_no, b.ext, b.cust_code, '''', ship_to_name, b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state
    from ' + @order_table + ' b (nolock) 
    where (b.cust_code = @custcode)  
      and b.type = ''I'''

  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'

  select @sql = @sql + '
    order by b.order_no desc, b.ext desc
      select @counter = @counter + @@rowcount
    end

    if @counter = -1 and @custcode <> ''''
    begin
    insert into #t1
    select b.order_no, b.ext, b.cust_code, '''', ship_to_name, b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state
    from ' + @order_table + ' b (nolock) 
    where (cust_code = @custcode) 
      and b.type = ''I'' and (b.order_no < ' + convert(varchar,@lastkey) + ' or (b.order_no = ' + convert(varchar,@lastkey) + ' and 
      b.ext <= ' + convert(varchar,@ordext) + '))'

  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'

  select @sql = @sql + '
    order by b.order_no desc, b.ext desc
    select @counter = @@rowcount
    if @counter = 0 and ' + convert(varchar,@lastkey) + ' = 0 set @counter = -1
    end
    if (@counter <= @maxrowcount)
    begin
      if @counter = -1
begin
      select @custcode = isnull((select min(cust_code) from orders_all b (nolock) , ' + @cust_table + ' c (nolock)
        where (cust_code >= @custcode ) and b.cust_code = c.customer_code
      and b.type = ''I'''
  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'
  select @sql = @sql + '
	),null)
end
      else
begin      select @custcode = isnull((select min(cust_code) from orders_all b (nolock) , ' + @cust_table + ' c (nolock)
        where (cust_code > @custcode ) and b.cust_code = c.customer_code
      and b.type = ''I'''
  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'

  select @sql = @sql + '
	),null)
end
      if @counter = -1 select @counter = 1
      if @custcode is NULL
        select @counter=@maxrowcount + 1
    end
  END 

  set rowcount @maxrowcount
  select t.order_no, t.ext, t.cust_code, c.customer_name, t.ship_to_name, t.cust_po, t.req_ship_date, t.invoice_no, t.status, t.ship_to_city, t.ship_to_state,
    @maxrowcount
  from #t1 t
  left outer join ' + @cust_table + ' c (nolock) on t.cust_code = c.customer_code
  order by t.cust_code, t.order_no desc, t.ext desc'

print @sql
exec (@sql)
END	



if @sort='U' 
begin
  
  if @lastkey != 0
  begin
    select @custcode = (select min(cust_code) from orders_all (nolock) where order_no = @lastkey)
    select @custname = (select customer_name from adm_cust_all (nolock) where customer_code = @custcode)
  end
  else
    select @custname = @strsort

  select @sql = ' declare @counter int, @maxrowcount int, @custcode varchar(20), @custname varchar(40)
  set @maxrowcount = ' + convert(varchar,@maxrowcount) + '
  set @custcode = ''' + isnull(@custcode,'') + '''
  set @custname = ''' + isnull(@custname,'') + '''
  set @counter = -1
  create table #t1
   (order_no int,
    ext int,
    cust_code varchar(20) null,
    cust_name varchar(40) null,
    ship_to_name varchar(40) null,
    cust_po varchar(20) null,
    req_ship_date datetime null,
    invoice_no int null,
    status char(1) null,
    ship_to_city varchar(40) null,
    ship_to_state varchar(40) null)' 

  select @sql = @sql + '
  while  (@counter <= @maxrowcount) and @custname is not null
  BEGIN
    if @counter > 0
    begin
      if @custcode is not null
      begin
        insert into #t1
        select b.order_no, b.ext, b.cust_code, @custname, ship_to_name, b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state
        from ' + @order_table + ' b (nolock) 
        where (b.cust_code = @custcode)  
        and b.type = ''I'''

  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'
   
  select @sql = @sql + '
        order by b.order_no desc, b.ext desc

        select @counter = @counter + @@rowcount

        select @custcode = isnull((select min(b.customer_code) 
        from ' + @cust_table + '  b (nolock)
        where b.customer_name = @custname and b.customer_code > @custcode),NULL)
      end
    end

    if @counter = -1 and @custname <> ''''
    begin
    insert into #t1
    select b.order_no, b.ext, b.cust_code, @custname, ship_to_name, b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state
    from ' + @order_table + ' b (nolock) 
    where (cust_code = @custcode) 
      and b.type = ''I'' and (b.order_no < ' + convert(varchar,@lastkey) + ' or (b.order_no = ' + convert(varchar,@lastkey) + ' and 
      b.ext <= ' + convert(varchar,@ordext) + '))'

  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'

  select @sql = @sql + '
    order by b.order_no desc, b.ext desc
    select @counter = @@rowcount
    if @counter = 0 and ' + convert(varchar,@lastkey) + ' = 0 set @counter = -1

      select @custcode = isnull((select min(b.customer_code) 
      from ' + @cust_table + ' b (nolock)
      where b.customer_name = @custname and b.customer_code > @custcode),NULL)

    end
    if (@counter <= @maxrowcount) and @custcode is NULL or @counter = -1
    begin
if @counter = -1 
      select @custname = (select min(customer_name) from ' + @cust_table + ' a (nolock) 
join orders_all b on b.cust_code = a.customer_code
	where ((customer_name >= @custname) ))
else
      select @custname = (select min(a.customer_name) from ' + @cust_table + ' a (nolock) 
join orders_all b on b.cust_code = a.customer_code
	where ((a.customer_name > @custname) ))

      select @custcode = (select min(customer_code) from ' + @cust_table + ' (nolock) where customer_name = @custname)
      if @counter = -1 select @counter = 1

      if @custcode is NULL
        select @counter=@maxrowcount + 1
    end
  END 

  set rowcount @maxrowcount
  select *, @maxrowcount
  from #t1 t 
  order by cust_name, order_no desc, ext desc'

print @sql
exec (@sql)

end	

if @sort='N' 
begin
  select @x=convert(int,@strsort) 
  if (@lastkey > @x) select @x=@lastkey

  set rowcount @maxrowcount
  select @sql = 'select b.order_no, b.ext, b.cust_code, c.customer_name, b.ship_to_name, 
    b.cust_po, b.req_ship_date, b.invoice_no, b.status, b.ship_to_city, b.ship_to_state, ' + convert(varchar,@maxrowcount) 
  select @sql = @sql + ' from ' + @order_table + ' b (nolock), ' + @cust_table + ' c (nolock)' 
  select @sql = @sql + ' where b.cust_code = c.customer_code and b.type = ''I'''  
  if @otype = 'SS' select @sql = @sql + ' and (b.load_no = 0 and b.status <> ''M'')' 
  select @sql = @sql + ' and ((order_no = ' + convert(varchar,@x) + ' and ext >= ' 
  select @sql = @sql + convert(varchar,@ordext) + ') or (b.order_no > ' + convert(varchar,@x) + '))' 
  if @status = '1' select @sql = @sql + ' and b.invoice_no = 0 and b.consolidate_flag = 1'
  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
  if @status  = 'B'  select @sql = @sql + ' and b.status not between ''' + @minfilter + ''' and ''' + @maxfilter + '''' 
  select @sql = @sql + ' order by b.order_no	, b.ext	'

  exec (@sql)

end 
GO
GRANT EXECUTE ON  [dbo].[get_q_ord] TO [public]
GO
