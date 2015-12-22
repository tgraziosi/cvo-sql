SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_i_ord] @strsort varchar(20), @sort varchar(1), @status varchar(1), @ordno int ,  @username varchar(10)='' AS




set rowcount 0
declare @maxrowcount int
declare @lastkey int
declare @minstat char(1)
declare @maxstat char(1)
declare @x int
declare @po varchar(20)
declare @ship varchar(40)
declare @xship varchar(40)
declare @invoice int
declare @custname varchar(40)
declare @custcode varchar(20)

declare @nextkey int
declare @counter int
declare @ord_con varchar(255) 
declare @strnum varchar(20) 

create table #t1

 (order_no int,
  ext int,
  cust_code varchar(20) null,
  cust_name varchar(30) null,
  ship_to_name varchar(30) null,
  cust_po varchar(20) null,
  req_ship_date datetime null,

  invoice_no int null,
  status char(1) null,
  ship_to_city varchar(40) null,
  ship_to_state varchar(40) null)

if @ordno is null select @ordno=0
select @lastkey=@ordno
select @maxrowcount=40

if @status = 'A' begin 
select @minstat='A'
select @maxstat='Z'
end
if @status = 'H' begin 
select @minstat='A'
select @maxstat='M'
end
if @status = 'K' begin 
select @minstat='A'
select @maxstat='Q'
end

if @status = 'N' begin 
select @minstat='N'
select @maxstat='Q'
end
if @status = 'Q' begin 
select @minstat='N'
select @maxstat='U'
end
if @status = 'S' begin 

select @minstat='R'
select @maxstat='U'

end
if @status = 'V' begin 
select @minstat='V'

select @maxstat='V'
end


select @ord_con=' and ' + isnull((select constrain_by from sec_constraints where kys=@username and table_id='orders_all'),'orders_all.order_no=orders_all.order_no')

	
if @sort='I' BEGIN
  
  select @counter = 1
  if convert(int,isnull(@strsort,'0'))=0 select @strsort='1'
  select @x=convert(int,@strsort) 
  
  if @lastkey = 0
    begin
      select @invoice = isnull((select min(invoice_no) from orders_all where orders_all.status >= @minstat and orders_all.status <= @maxstat 
          and type = 'I' and invoice_no >= @x),0)
    end
  else
    begin
     select @invoice = min(invoice_no) from orders_all where order_no = @lastkey
    end
  

  while  (@counter < @maxrowcount) AND (@invoice != 0)
    BEGIN
      select @strnum=convert(varchar(20),@invoice)	
      exec ('insert into #t1
        select order_no, ext, cust_code, '', ship_to_name, cust_po, req_ship_date, invoice_no, status, ship_to_city, ship_to_state
	          from orders_all where orders_all.invoice_no ='+@strnum+@ord_con) 

        select @counter = count(*) from #t1
        if (@counter < @maxrowcount)
          begin
            select @invoice = isnull((select min(invoice_no) from orders_all where 

              invoice_no > @invoice and orders_all.status >= @minstat and orders_all.status <= @maxstat and type = 'I'),0)
	    if @invoice = 0

              select @counter=@maxrowcount	
	end
    END 
  set rowcount 40
  select t.order_no, t.ext, t.cust_code, c.customer_name, t.ship_to_name, t.cust_po, t.req_ship_date, t.invoice_no, t.status, t.ship_to_city, t.ship_to_state
  from adm_cust_all c, #t1 t where t.cust_code = c.customer_code
  order by t.invoice_no, t.order_no, t.ext
END	
	
if @sort='P' BEGIN
  
  select @counter = 0
  if @strsort='' select @strsort=null
  if @lastkey = 0
    begin
	if @strsort is null 
		select @po=null
	else
		select @po = (select min(cust_po) from orders_all where
	          orders_all.status >= @minstat and orders_all.status <= @maxstat 
	          and type = 'I' and (cust_po >= @strsort))
    end
  else
    begin
      select @po = (select min(cust_po) from orders_all where order_no = @lastkey )
    end
  
  while (@counter < @maxrowcount)

    BEGIN 
      set rowcount 40
      select @strnum=convert(varchar(20),@lastkey)	
      if @po is not null
        exec ('insert into #t1
        select order_no, ext, cust_code, '', ship_to_name, cust_po, req_ship_date, invoice_no, status, ship_to_city, ship_to_state
          from orders_all 
		where cust_po=''+@po+'' and status>=''+@minstat+'' and status<=''+
		@maxstat+'' and type = ''I'' and order_no>='+ @strnum + @ord_con+' order by order_no')
      else	
        exec ('insert into #t1
        select order_no, ext, cust_code, '', ship_to_name, cust_po, req_ship_date, invoice_no, status, ship_to_city, ship_to_state
          from orders_all 
		where cust_po=NULL and status>=''+@minstat+'' and status<=''+
		@maxstat+'' and type = ''I'' and order_no>='+ @strnum + @ord_con+' order by order_no')
      select @lastkey=0	
      if @po is null select @po=''	

      select @counter = count(*) from #t1
      if (@counter < @maxrowcount) 
        begin

          select @po = (select min(cust_po) from orders_all where (cust_po > @po)
            and status >= @minstat and status <= @maxstat and type = 'I')
          if @po is null
            select @counter = @maxrowcount
	end 
    END 

  select t.order_no, t.ext, t.cust_code, c.customer_name, t.ship_to_name, t.cust_po, t.req_ship_date, t.invoice_no, t.status, t.ship_to_city, t.ship_to_state
  from adm_cust_all c, #t1 t where t.cust_code = c.customer_code
  order by t.cust_po, t.order_no, t.ext
END	




if @sort='S' BEGIN

  
  if @lastkey = 0

    begin
      select @ship = min(ship_to_name) from orders_all where

          orders_all.status >= @minstat and orders_all.status <= @maxstat 
          and type = 'I' and ship_to_name >= @strsort

      select @xship=@ship	
      exec fs_fix_quoted_id @xship OUTPUT
      select @nextkey=0
      select @counter = 1

    end
  else
    begin
      select @ship = ship_to_name from orders_all where order_no = @lastkey
      select @xship=@ship	
      exec fs_fix_quoted_id @xship OUTPUT
      select @strnum=convert(varchar(20),@lastkey)	
      exec ('insert into #t1 select orders_all.order_no, orders_all.ext, orders_all.cust_code, '',
	orders_all.ship_to_name, orders_all.cust_po, orders_all.req_ship_date, orders_all.invoice_no, orders_all.status, orders_all.ship_to_city, orders_all.ship_to_state
	from orders_all orders_all,  orders_all o where o.ship_to_name='+@xship+
	' and orders_all.order_no=o.order_no and orders_all.ext=o.ext and o.status>=''+@minstat+
	'' and o.type = ''I'' and o.status<=''+@maxstat+'' and orders_all.order_no<='+@strnum+@ord_con+
	' order by orders_all.order_no desc, orders_all.ext desc')
      select @counter = count(*) from #t1
      if (@counter < @maxrowcount)
        begin
          select @ship = isnull((select min(ship_to_name) from orders_all where 

            ship_to_name > @ship and type = 'I' and orders_all.status >= @minstat and orders_all.status <= @maxstat),null)
          if @ship is not null
	  begin
	   select @xship=@ship	
	   exec fs_fix_quoted_id @xship OUTPUT
           select @nextkey=0
	  end 
          else
            select @counter=@maxrowcount	
        end

    end

  

  while  (@counter < @maxrowcount)

    BEGIN

      select @strnum=convert(varchar(20),@nextkey)
      exec ('insert into #t1 select orders_all.order_no, orders_all.ext, orders_all.cust_code, '',
	orders_all.ship_to_name, orders_all.cust_po, orders_all.req_ship_date, orders_all.invoice_no, orders_all.status, orders_all.ship_to_city, orders_all.ship_to_state
	from orders_all orders_all, orders_all o where o.ship_to_name='+@xship+
	' and orders_all.order_no=o.order_no and orders_all.ext=o.ext and o.status>=''+@minstat+
	'' and o.type = ''I'' and o.status<=''+@maxstat+'' and orders_all.order_no >'+@strnum+@ord_con+
	' order by orders_all.order_no desc, orders_all.ext desc')
        select @counter = count(*) from #t1
        if (@counter < @maxrowcount)
          begin
            select @ship = isnull((select min(ship_to_name) from orders_all where 

              ship_to_name > @ship and type = 'I' and orders_all.status >= @minstat and orders_all.status <= @maxstat),null)
	    if @ship is not null
	      begin	
	      select @xship=@ship	
	      exec fs_fix_quoted_id @xship OUTPUT
              select @nextkey=0
	    end	
	    else

              select @counter=@maxrowcount	
	end
    END 

  set rowcount 40
  select t.order_no, t.ext, t.cust_code, c.customer_name, t.ship_to_name, t.cust_po, t.req_ship_date, t.invoice_no, t.status, t.ship_to_city, t.ship_to_state


  from adm_cust_all c, #t1 t where t.cust_code = c.customer_code
  order by t.ship_to_name, t.order_no desc, t.ext desc
END	



	

if @sort='C' BEGIN
  
  if @lastkey = 0

    begin

      select @custcode = isnull((select min(cust_code) from orders_all where
          orders_all.status >= @minstat and orders_all.status <= @maxstat 

          and type = 'I' and (cust_code >= @strsort)),'')
      select @nextkey = 0

      select @counter = 1

    end
  else
    begin

      select @custcode = (select min(cust_code) from orders_all where order_no = @lastkey and type = 'I')
      select @strnum=convert(varchar(20),@lastkey)	
      exec ('insert into #t1
        select orders_all.order_no, orders_all.ext, orders_all.cust_code, '', orders_all.ship_to_name, orders_all.cust_po, orders_all.req_ship_date, orders_all.invoice_no, orders_all.status, orders_all.ship_to_city, orders_all.ship_to_state

          from orders_all , orders_all a where a.cust_code =''+ @custcode+
	  '' and orders_all.order_no = a.order_no and orders_all.ext=a.ext and a.status >=''+@minstat+
	  '' and a.status <=''+@maxstat+
	  '' and orders_all.order_no <='+@strnum+' and a.type = ''I'''+@ord_con)

      select @counter = count(*) from #t1
      if (@counter < @maxrowcount)


        begin

          select @custcode = (select min(cust_code) from orders_all where cust_code > @custcode

            and status >= @minstat and status <= @maxstat and type = 'I')

          if @custcode is not null

            select @nextkey = 0
          else

            select @counter = @maxrowcount

      end 
    end
  
  while (@counter < @maxrowcount)

    BEGIN

      select @strnum=convert(varchar(20),@nextkey)	
      exec ('insert into #t1
        select orders_all.order_no, orders_all.ext, orders_all.cust_code, '', orders_all.ship_to_name, orders_all.cust_po, orders_all.req_ship_date, orders_all.invoice_no, orders_all.status, orders_all.ship_to_city, orders_all.ship_to_state
          from orders_all a, orders_all  where a.cust_code =''+@custcode+'' and orders_all.order_no = a.order_no and

	  orders_all.ext=a.ext and a.status >=''+@minstat+'' and a.status <=''+@maxstat+'' and orders_all.order_no >'+@strnum+
	  ' and a.type = ''I'''+@ord_con)

      select @counter = count(*) from #t1
      if (@counter < @maxrowcount)

        begin
          select @custcode = (select min(cust_code) from orders_all where cust_code > @custcode
            and status >= @minstat and status <= @maxstat and type = 'I')
          if @custcode is not null

            select @nextkey = 0
          else

            select @counter = @maxrowcount

      end 

    END 
  set rowcount 40
  select t.order_no, t.ext, t.cust_code, c.customer_name, t.ship_to_name, t.cust_po, t.req_ship_date, t.invoice_no, t.status, t.ship_to_city, t.ship_to_state
  from adm_cust_all c, #t1 t where t.cust_code = c.customer_code
  order by t.cust_code, t.order_no desc, t.ext desc
END	






if @sort='U' begin

  
  if @lastkey = 0

    begin

      select @custname = (select min(customer_name) from adm_cust_all where customer_name >= @strsort)
      select @custcode = (select min(customer_code) from adm_cust_all where customer_name = @custname)
      select @nextkey = 0

      select @counter = 1
    end


  else

    begin
      select @custcode = (select min(cust_code) from orders_all where order_no = @lastkey)

      select @custname = (select min(customer_name) from adm_cust_all where customer_code = @custcode)
      select @strnum=convert(varchar(20),@lastkey)
      select @xship=@custname
      exec fs_fix_quoted_id @xship OUTPUT
      exec ('insert into #t1

        select orders_all.order_no, orders_all.ext, orders_all.cust_code,'+@xship+', orders_all.ship_to_name, orders_all.cust_po, orders_all.req_ship_date, orders_all.invoice_no, orders_all.status, orders_all.ship_to_city, orders_all.ship_to_state
          from orders_all a, orders_all  where a.cust_code =''+@custcode+
	  '' and a.type = ''I'' and orders_all.order_no = a.order_no and orders_all.ext=a.ext and a.status >=''+@minstat+
	  '' and a.status <=''+@maxstat+
	  '' and orders_all.order_no <='+@strnum+@ord_con)

      select @counter = count(*) from #t1
      select @nextkey = @lastkey
      select @lastkey = -1
    end

  

  if (@counter < @maxrowcount)
    BEGIN
      if (@lastkey <> -1)

        begin
          
	  set rowcount 40	

	  select @strnum=convert(varchar(20),@nextkey)
	  select @xship=@custname
	  exec fs_fix_quoted_id @xship OUTPUT
	  exec ('insert into #t1

	     select orders_all.order_no, orders_all.ext, orders_all.cust_code,'+@xship+', orders_all.ship_to_name, orders_all.cust_po, orders_all.req_ship_date, orders_all.invoice_no, orders_all.status, orders_all.ship_to_city, orders_all.ship_to_state
              from orders_all a, orders_all

		where a.cust_code =''+@custcode+
		'' and a.type = ''I'' and orders_all.order_no = a.order_no and orders_all.ext=a.ext and a.status >=''+@minstat+
		'' and a.status <=''+@maxstat+
		'' and orders_all.order_no >'+@strnum+@ord_con+
		' order by orders_all.order_no')

          select @counter = count(*) from #t1

        end
      while (@counter < @maxrowcount and @custname is not null)


        begin

          
          select @custcode = (select min(b.customer_code) from adm_cust_all a, adm_cust_all b

            where (a.customer_name = @custname) and (b.customer_code = a.customer_code and b.customer_code > @custcode))

	  select @strnum=convert(varchar(20),@nextkey)
          select @xship=@custname
          exec fs_fix_quoted_id @xship OUTPUT
          exec ('insert into #t1

	    select orders_all.order_no, orders_all.ext, orders_all.cust_code,'+@xship+', orders_all.ship_to_name, orders_all.cust_po, orders_all.req_ship_date, orders_all.invoice_no, orders_all.status, orders_all.ship_to_city, orders_all.ship_to_state
              from orders_all a, orders_all where a.cust_code =''+@custcode+
	      '' and a.type = ''I'' and orders_all.order_no = a.order_no and orders_all.ext=a.ext and a.status >=''+@minstat+
	      '' and a.status <=''+@maxstat+'''+@ord_con)

          select @counter = count(*) from #t1
          if (@counter < @maxrowcount)

            if ((select min(b.customer_code) from adm_cust_all a, adm_cust_all b

              where (a.customer_name = @custname) and (b.customer_code = a.customer_code and b.customer_code > @custcode)) is null)

                begin

                

                  select @custname = (select min(customer_name) from adm_cust_all where customer_name > @custname)
                  select @custcode = (select min(customer_code) from adm_cust_all where customer_name = @custname)
		  select @strnum=convert(varchar(20),@nextkey)
                  select @xship=@custname
                  exec fs_fix_quoted_id @xship OUTPUT
                  exec ('insert into #t1

		    select orders_all.order_no, orders_all.ext, orders_all.cust_code,'+@xship+', orders_all.ship_to_name, orders_all.cust_po, orders_all.req_ship_date, orders_all.invoice_no, orders_all.status, orders_all.ship_to_city, orders_all.ship_to_state
                      from orders_all a, orders_all where a.cust_code =''+@custcode+
		      '' and a.type = ''I'' and orders_all.order_no = a.order_no and orders_all.ext=a.ext and a.status >=''+@minstat+

		      '' and a.status <=''+@maxstat+'''+@ord_con)

		  select @counter = count(*) from #t1

                end 
        end 

    END 
  set rowcount 40
  select * from #t1

  order by cust_name, order_no desc, ext desc

end	




if @sort='N' begin
	set rowcount 40
	select @x=convert(int,@strsort) 
	if (@lastkey > @x) select @x=@lastkey
        select @strnum=convert(varchar(20),@x)	
	exec ('select orders_all.order_no, orders_all.ext, orders_all.cust_code, adm_cust_all.customer_name, 

		ship_to_name, cust_po, req_ship_date, invoice_no, orders_all.status, ship_to_city, ship_to_state
		from orders_all,adm_cust_all

		where orders_all.cust_code = adm_cust_all.customer_code and
		orders_all.type = ''I''  and
		orders_all.status >=''+ @minstat+
		'' and orders_all.status <=''+@maxstat+
		'' and orders_all.order_no >='+@strnum+@ord_con+
		' order by orders_all.order_no,orders_all.ext')


end 


GO
GRANT EXECUTE ON  [dbo].[get_i_ord] TO [public]
GO
