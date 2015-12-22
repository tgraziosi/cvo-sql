SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 11/10/2011 - Fix standard version - Search by cust code, cust name and ship name not working
-- v1.1 CT 07/01/2013 - Add search based on RA# (sort=R)
-- v1.2 CB 16/01/2015 - Fix issue with looping
CREATE PROCEDURE [dbo].[get_q_credit]	@strsort varchar(30), @sort char(1), @status char(1), 
										@ordno int, @otype char(1) = 'C', @secured_mode int = 0,
										@module varchar(10) = '', @sec_level int = 99 

AS


-- mls 2/25/00 SCR 22496 - totally rewritten to improve performance
set @secured_mode = isnull(@secured_mode,0)

set rowcount 0

declare @lastkey int
declare @minstat char(1)
declare @maxstat char(1)
declare @x int
declare @po varchar(20)
declare @ship varchar(40)
declare @invoice int
declare @custname varchar(40)
declare @custcode varchar(20)
declare @nextkey int
declare @counter int
declare @maxrowcount int

declare @sql varchar(4000)

create table #t1(
	order_no int,
	ext int,
	cust_code varchar(20) null,
	cust_name varchar(30) null,
	ship_to_name varchar(40) null,								
	cr_invoice_no int null,
	req_ship_date datetime null,
	invoice_no int null,
	status char(1) null)

declare @order_table varchar(50)
declare @cust_table varchar(50)

declare @ra_pad VARCHAR(20) -- v1.1

select @lastkey=@ordno
select @module = lower(isnull(@module,''))

if @status = 'A' 
begin
	select @minstat='A'
	select @maxstat='Z'
end

if @status = 'N' 
begin
	select @minstat='N'
	select @maxstat='Q'
end

if @status = 'S' 
begin
	select @minstat='R'
	select @maxstat='U'
end

select @order_table = case @secured_mode  when 1 then 'orders_entry_vw' when 2 then 'orders_shipping_vw' else 'orders' end
select @cust_table = case @secured_mode  when 1 then 'adm_cust' when 2 then 'adm_cust_all' else 'adm_cust_all' end

set rowcount 0
select @maxrowcount = 100

if @sort='I' 
BEGIN
	select @x = convert(int, isnull(@strsort,'0'))							

	set rowcount 100
	select @sql = 'select b.order_no, b.ext, b.cust_code, c.customer_name, b.ship_to_name, 
	 b.cr_invoice_no, b.req_ship_date, b.invoice_no, 
	 b.status, ' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + '
	from ' + @order_table + ' b (nolock), ' + @cust_table + ' c (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	select @sql = @sql + '
	where b.cust_code = c.customer_code 
	and b.type like ''' + @otype + ''' and b.invoice_no >= ' + convert(varchar,@x) 

	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + ' order by b.invoice_no '

	print @sql
	exec (@sql)
END	

if @sort='P' 
BEGIN									
	select @x = convert(int, isnull(@strsort,'0'))

	set rowcount 100

	select @sql = 'select b.order_no, b.ext, b.cust_code, c.customer_name, b.ship_to_name, 
	 b.cr_invoice_no, b.req_ship_date, b.invoice_no, 
	 b.status, ' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + '
	from ' + @order_table + ' b (nolock), ' + @cust_table + ' c (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	select @sql = @sql + '
	where b.cust_code = c.customer_code and b.cr_invoice_no >= ' + convert(varchar,@x) + '
	and b.type like ''' + @otype + ''''

	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '   order by b.cr_invoice_no ASC, b.order_no DESC, b.ext DESC'

	print @sql
	exec (@sql)

END											

if @sort='S' 
BEGIN
	if @lastkey != 0
	select @ship = (select min(ship_to_name) from orders (nolock) where order_no = @lastkey)
	else
	select @ship = isnull((@strsort + '%'),'%')  -- mls 3/24/09 SCR 051245 -- v1.0 Add %

	select @sql = '
	declare @counter int, @maxrowcount int, @ship varchar(40)

	select @maxrowcount = ' + convert(varchar,@maxrowcount) + '
	select @ship = ''' + isnull(@ship,'') + '''
	select @counter = -1
	create table #t1
	(order_no int,
	ext int,
	cust_code varchar(20) null,
	cust_name varchar(30) null,
	ship_to_name varchar(40) null,								
	cr_invoice_no int null,
	req_ship_date datetime null,
	invoice_no int null,
	status char(1) null)

	while (@counter <= @maxrowcount)
	BEGIN
	if @counter > 0
	begin
	insert into #t1
	select b.order_no, b.ext, b.cust_code, '''', @ship, b.cr_invoice_no, b.req_ship_date, b.invoice_no, b.status
	from ' + @order_table + ' b (nolock) , ' + @cust_table + ' c (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	select @sql = @sql + '
	where (b.ship_to_name= + @ship )    and b.cust_code = c.customer_code and b.type like ''' + @otype + ''''
	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '
	select @counter = @counter + @@rowcount
	end

	if @counter = -1 and @ship <> ''''
	begin
	insert into #t1
	select b.order_no, b.ext, b.cust_code, '''', @ship, b.cr_invoice_no, b.req_ship_date, b.invoice_no, b.status
	from ' + @order_table + ' b (nolock) , ' + @cust_table + ' c (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	-- v1.0 Add LIKE @ship instead of = @ship
	select @sql = @sql + '
	where (b.ship_to_name LIKE @ship)   and b.cust_code = c.customer_code and b.type like ''' + @otype + ''' and b.order_no >= ' + convert(varchar,@lastkey) 
	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '
	select @counter = @@rowcount
	end
	-- v1.2 Start
	IF (@counter = 0)
		BREAK
	-- v1.2 End
	if (@counter <= @maxrowcount)
	begin
	  select @ship = isnull((select min(ship_to_name) from ' + @order_table + ' b (nolock)  , ' + @cust_table + ' c (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	select @sql = @sql + '
	  where ship_to_name > @ship   and b.cust_code = c.customer_code and type like ''' + @otype + ''''
	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '
	  ),null)

	  if @counter = -1 select @counter = 1
	  if @ship is null
		select @counter=@maxrowcount + 1
	end
	END 

	set rowcount @maxrowcount
	select DISTINCT t.order_no, t.ext, t.cust_code, c.customer_name, t.ship_to_name, t.cr_invoice_no, t.req_ship_date, t.invoice_no, t.status, ' 
	 + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + '
	from ' + @cust_table + ' c (nolock), #t1 t 
	where t.cust_code = c.customer_code
	order by t.ship_to_name, t.order_no desc, t.ext desc'
	-- v1.0 Add distinct to final select above

	print @sql
	exec(@sql)
END	

if @sort='C' 
BEGIN
	if @lastkey != 0
	select @custcode = (select min(cust_code) from orders (nolock) where order_no = @lastkey and type like @otype)
	else
	select @custcode = isnull(@strsort,'')  -- mls 3/24/09 SCR 051245  

	select @sql = '
	declare @counter int, @maxrowcount int, @ship varchar(40)

	select @maxrowcount = ' + convert(varchar,@maxrowcount) + '
	select @ship = ''' + isnull(@custcode,'') + '''
	select @counter = -1
	create table #t1
	(order_no int,
	ext int,
	cust_code varchar(20) null,
	cust_name varchar(30) null,
	ship_to_name varchar(40) null,								
	cr_invoice_no int null,
	req_ship_date datetime null,
	invoice_no int null,
	status char(1) null)

	while (@counter <= @maxrowcount)
	BEGIN
	if @counter > 0
	begin
	insert into #t1
	select b.order_no, b.ext, b.cust_code, '''', b.ship_to_name, b.cr_invoice_no, b.req_ship_date, b.invoice_no, b.status
	from ' + @order_table + ' b (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	select @sql = @sql + '
	where (b.cust_code= + @ship ) and b.type like ''' + @otype + ''''
	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '
	select @counter = @counter + @@rowcount
	end

	if @counter = -1 and @ship <> ''''
	begin
	insert into #t1
	select b.order_no, b.ext, b.cust_code, '''', b.ship_to_name, b.cr_invoice_no, b.req_ship_date, b.invoice_no, b.status
	from ' + @order_table + ' b (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	select @sql = @sql + '
	where (b.cust_code= @ship) and b.type like ''' + @otype + ''' and b.order_no >= ' + convert(varchar,@lastkey) 
	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '

	select @counter = @@rowcount
	end
	-- v1.2 Start
	IF (@counter = 0)
		BREAK
	-- v1.2 End
	if (@counter <= @maxrowcount)
	begin
	  select @ship = isnull((select min(cust_code) from ' + @order_table + ' b (nolock)  , ' + @cust_table + ' c (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	select @sql = @sql + '
	  where cust_code > @ship   and b.cust_code = c.customer_code and type like ''' + @otype + ''''
	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '
	  ),null)

	  if @counter = -1 select @counter = 1
	  if @ship is null
		select @counter=@maxrowcount + 1
	end
	END 

	set rowcount @maxrowcount
	select t.order_no, t.ext, t.cust_code, c.customer_name, t.ship_to_name, t.cr_invoice_no, t.req_ship_date, t.invoice_no, t.status, ' 
	 + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + '
	from ' + @cust_table + ' c (nolock), #t1 t 
	where t.cust_code = c.customer_code
	order by t.cust_code, t.order_no desc, t.ext desc'

	print @sql
	exec(@sql)
END	

if @sort='U' 
begin
	  if @lastkey != 0
	  begin
		select @custcode = (select min(cust_code) from orders (nolock) where order_no = @lastkey)
		select @custname = (select min(customer_name) from adm_cust_all (nolock) where customer_code = @custcode)
	  end
	  else
		select @custcode = '', @custname = isnull(@strsort,'')  -- mls 3/24/09 SCR 051245  

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
	   cr_invoice_no int null,
	   req_ship_date datetime null,
	   invoice_no int null,
	   status char(1) null)'

	  select @sql = @sql + '
	  while  (@counter <= @maxrowcount) and @custname is not null
	  BEGIN
		if @counter > 0
		begin
		  if @custcode is not null
		  begin
			insert into #t1
			select b.order_no, b.ext, b.cust_code, @custname, b.ship_to_name, b.cr_invoice_no, b.req_ship_date, b.invoice_no, b.status
			from ' + @order_table + ' b (nolock) '

	  if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	  select @sql = @sql + '
			where (b.cust_code = @custcode)  and b.type like ''' + @otype + ''''
	  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 
	   
	  if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
		(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	  select @sql = @sql + '
			select @counter = @counter + @@rowcount

			select @custcode = isnull((select min(b.customer_code) 
			from ' + @cust_table + '  b (nolock)
			where b.customer_name = @custname and b.customer_code > @custcode),NULL)
		  end
		end

		if @counter = -1 and @custcode <> ''''
		begin
		insert into #t1
		select b.order_no, b.ext, b.cust_code, @custname, b.ship_to_name, b.cr_invoice_no, b.req_ship_date, b.invoice_no, b.status
		from ' + @order_table + ' b (nolock) '

	  if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	  select @sql = @sql + '
		where (cust_code = @custcode) and b.type like ''' + @otype + '''
		  and (b.order_no >= ' + convert(varchar,@lastkey) + ' )'

	  if @status != 'A'  select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + '''' 

	  if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
		(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	  select @sql = @sql + '
		select @counter = @@rowcount

		  select @custcode = isnull((select min(b.customer_code) 
		  from ' + @cust_table + ' b (nolock)
		  where b.customer_name = @custname and b.customer_code > @custcode),NULL)

		end
		-- v1.2 Start
		IF (@counter = 0)
			BREAK
		-- v1.2 End
		if (@counter <= @maxrowcount) and @custcode is NULL or @counter = -1
		begin


		  select @custname = (select min(customer_name) from ' + @cust_table + ' a (nolock) join  ' + @order_table + ' b (nolock) 
		on a.customer_code = b.cust_code where b.type like ''' + @otype + '''
		and ((customer_name > @custname) or (customer_name = @custname and @counter = -1)))
		  select @custcode = (select min(customer_code) from ' + @cust_table + ' (nolock) where customer_name = @custname)
		  if @counter = -1 select @counter = 1

		  if @custcode is NULL
			select @counter=@maxrowcount + 1
		end
	  END 

	  set rowcount @maxrowcount
	  select *, ' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	  + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	  + CHAR(39) + CHAR(39) + '
	  from #t1 t 
	  order by cust_name, order_no desc, ext desc'

	print @sql
	exec (@sql)

end	

if @sort='N' 
begin
	set rowcount 100
	select @x=convert(int, isnull(@strsort,'0')) 

	if (@lastkey > @x) 
	select @x=@lastkey

	select @sql = 'select b.order_no, b.ext, b.cust_code, c.customer_name, b.ship_to_name, 
	 b.cr_invoice_no, b.req_ship_date, b.invoice_no, 
	 b.status, ' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ',' + CHAR(39) + CHAR(39) + ','
	 + CHAR(39) + CHAR(39) + ' 
	from ' + @order_table + ' b (nolock), ' + @cust_table + ' c (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	select @sql = @sql + '
	where b.cust_code = c.customer_code 
	and b.type like ''' + @otype + '''
	and (b.order_no >= ' + convert(varchar,@x) + ') '

	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '     order by b.order_no,b.ext'

	print @sql
	exec (@sql)
end

-- START v1.1
if @sort='R' 
begin
	set rowcount 100

	-- If search contains a '-' remove it
	SET @strsort = REPLACE(@strsort,'-','')

	-- Replace wildcard of * with %
	SET @strsort = REPLACE(@strsort,'*','%')

	-- Format string
	IF CHARINDEX('%',@strsort,1) = 0 
	BEGIN
		IF LEN(@strsort) > 3
		BEGIN
			SET @ra_pad = Right(@strsort,(LEN(@strsort) - 3))
			WHILE LEN(@ra_pad) < 12
			BEGIN
				SET @ra_pad = '0' + @ra_pad
			END
	
			SET @strsort = Left(@strsort,3) + @ra_pad	
		END
	END

	if (@lastkey > @x) 
	select @x=@lastkey

	select @sql = 'select b.order_no, b.ext, b.cust_code, c.customer_name, b.ship_to_name, 
	 b.cr_invoice_no, b.req_ship_date, b.invoice_no, 
	 b.status, LEFT(a.ra1,3) + ''-'' + RIGHT(a.ra1,12), LEFT(a.ra2,3) + ''-'' + RIGHT(a.ra2,12),
	 LEFT(a.ra3,3) + ''-'' + RIGHT(a.ra3,12), LEFT(a.ra4,3) + ''-'' + RIGHT(a.ra4,12), LEFT(a.ra5,3) + ''-'' + RIGHT(a.ra5,12),
	 LEFT(a.ra6,3) + ''-'' + RIGHT(a.ra6,12), LEFT(a.ra7,3) + ''-'' + RIGHT(a.ra7,12), LEFT(a.ra8,3) + ''-'' + RIGHT(a.ra8,12)
	from ' + @order_table + ' b (nolock), ' + @cust_table + ' c (nolock), cvo_orders_all a (nolock)'

	if @module <> '' select @sql = @sql + ', locations_hdr_vw l (nolock)'

	
	select @sql = @sql + '
	where b.cust_code = c.customer_code 
	and b.order_no = a.order_no and b.ext = a.ext 
	and b.type like ''' + @otype + '''
	and (a.ra1 like ''' + @strsort + ''' or a.ra2 like ''' + @strsort + ''' or a.ra3 like ''' + @strsort + ''' or a.ra4 like ''' + @strsort + '''
	or a.ra5 like ''' + @strsort + ''' or a.ra6 like ''' + @strsort + ''' or a.ra7 like ''' + @strsort + ''' or a.ra8 like ''' + @strsort + ''') '
	
	if @status != 'A' select @sql = @sql + ' and b.status between ''' + @minstat + ''' and ''' + @maxstat + ''''

	if @module <> '' select @sql = @sql + ' and b.location = l.location and l.module = ''' + @module + ''' and 
	(' + convert(varchar,@sec_level) + ' > 0 or l.organization_id = ''' + dbo.sm_get_current_org_fn() + ''')'

	select @sql = @sql + '     order by b.order_no,b.ext'

	print @sql
	exec (@sql)
end
-- END v1.1
GO
GRANT EXECUTE ON  [dbo].[get_q_credit] TO [public]
GO
