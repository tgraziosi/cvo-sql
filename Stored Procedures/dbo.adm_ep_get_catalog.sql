SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[adm_ep_get_catalog] @vendor VARCHAR(12) = '', @catalog VARCHAR(80) = '', @cust_code varchar(10) = ''
as
declare @rc int, @location varchar(10)
declare @eproc_735 int

if @vendor = '' and @catalog = ''
  set @eproc_735 = 1
else
  set @eproc_735 = 0

select @rc = 1

create table #catalog ( location varchar(10),
part_no varchar(30), upc_code varchar(20) NULL, sku_no varchar(30) NULL, description varchar(255) NULL,
vendor varchar(12) NULL, category varchar(10) NULL, uom char(2) NULL, rate decimal(20,8) NULL,
curr_key varchar(10) NULL, cost decimal(20,8) NULL, price decimal(20,8) NULL)

create index #c1 on #catalog(part_no, location)

create table #quotes (location varchar(10), part_no varchar(30), quote_order int, ilevel int, type char(1), rate decimal(20,8), curr_key varchar(10),
amt decimal(20,8) NULL)

create index #q1 on #quotes(ilevel)
create index #q2 on #quotes(quote_order)
create index #q3 on #quotes(part_no,quote_order)
create index #q4 on #quotes(location,part_no,quote_order)


select @location = isnull((select location_code from adm_cust_all where customer_code = @cust_code),'')

-- 736 or above eprocurement
if @eproc_735 = 0
begin
insert #catalog
select 
  l.location,
  i.part_no,
  i.upc_code,
  i.sku_no,
  i.description,
  i.vendor,
  i.category,
  i.uom,
  pr.price_a,
  pr.curr_key,
  (l.std_cost + l.std_direct_dolrs + l.std_ovhd_dolrs + l.std_util_dolrs),  
  0
from inv_master i (nolock) 
join glco g (nolock) on 1 = 1
left outer join inv_list l (nolock) on l.part_no = i.part_no 
left outer join 
(select pr.part_no, p.location, p.curr_key, pr.price_a
 from part_price_vw pr (nolock)
 join (select p.part_no, p.location, case p.org_level when 0 then '' when 1 then l.organization_id else p.location end, p.curr_key, p.org_level
       from locations l (nolock)
       join (select p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key, max(p.org_level)
             from part_price_vw p (nolock)
             join inv_list i (nolock) on i.part_no = p.part_no
             join glco g (nolock) on g.home_currency = p.curr_key
             join locations l (nolock) on (l.organization_id = p.loc_org_id and p.org_level = 1 and l.location = i.location) or (l.location = i.location and p.org_level != 1) 
             where p.part_no = i.part_no and p.active_ind = 1
             group by p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key)
             as p(part_no, location, curr_key, org_level) on l.location = p.location)
       as p(part_no, location, loc_org_id, curr_key, org_level) on p.part_no = pr.part_no and p.loc_org_id = pr.loc_org_id and p.org_level = pr.org_level and pr.active_ind = 1)
  as pr(part_no, location, curr_key, price_a) on pr.part_no = i.part_no and pr.location = l.location
where isnull(i.eprocurement_flag,0) = 1 and i.status != 'R'

if charindex('<item',@cust_code) > 0
	set @cust_code = ''

if isnull(@cust_code,'') != ''
begin
  insert #quotes
  select '', item, 0, ilevel, type, rate, curr_key,
  case when type = 'P' then rate else NULL end
  from c_quote c
  where customer_key = @cust_code and ship_to_no = 'ALL'
  and c.date_expires = 
      (select min(c1.date_expires) from c_quote c1
      where customer_key = @cust_code and ship_to_no = 'ALL' and c1.item = c.item and c1.ilevel = c.ilevel
        and c1.type = c.type and getdate() between c1.start_date and dateadd(day,1,c1.date_expires))

  insert #quotes
  select '', i.part_no, 1, 0, q.type, q.rate, q.curr_key,
  case when q.type = 'P' then q.rate else NULL end
  from #quotes q, inv_master i
  where q.ilevel = 1 and q.part_no = i.category

  delete from #quotes where ilevel = 1

  insert #quotes
  select '', part_no, 1 + isnull(charindex(type,'P+C-L'),6), 0, type, rate, curr_key, amt
  from #quotes q
  where q.ilevel = 0 and
  q.quote_order = (select min(q1.quote_order)
  from #quotes q1 where q1.part_no = q.part_no )

  delete from #quotes where quote_order < 2

  insert #quotes
  select '', part_no, 0, 0, type, rate, curr_key, amt
  from #quotes q
  where q.quote_order = (select min(q1.quote_order)
  from #quotes q1 where q1.part_no = q.part_no )

  delete from #quotes where quote_order > 0

  insert #quotes
  select l.location, q.part_no, q.quote_order, q.ilevel, q.type, q.rate, q.curr_key, q.amt
  from #quotes q
  join inv_list l on l.part_no = q.part_no

  delete from #quotes where location = ''

  update q
  set amt = i.cost * ((100 + q.rate)/100)
  from #quotes q, #catalog i
  where q.part_no = i.part_no and q.location = i.location and q.type = '+' 

  update q
  set amt = i.cost + q.rate
  from #quotes q, #catalog i
  where q.part_no = i.part_no and q.location = i.location and q.type = 'C' 

  update q
  set amt = pr.price_a - q.rate
  from #quotes q
  join #catalog i on q.part_no = i.part_no and q.location = i.location
  join (select pr.part_no, p.location, p.curr_key, pr.price_a
 from part_price_vw pr (nolock)
 join (select p.part_no, p.location, case p.org_level when 0 then '' when 1 then l.organization_id else p.location end, p.curr_key, p.org_level
       from locations l (nolock)
       join (select p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key, max(p.org_level)
             from part_price_vw p (nolock)
             join inv_list i (nolock) on i.part_no = p.part_no
             join locations l (nolock) on (l.organization_id = p.loc_org_id and p.org_level = 1 and l.location = i.location) or (l.location = i.location and p.org_level != 1) 
             where p.part_no = i.part_no and p.active_ind = 1
             group by p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key)
             as p(part_no, location, curr_key, org_level) on l.location = p.location)
       as p(part_no, location, loc_org_id, curr_key, org_level) on p.part_no = pr.part_no and p.loc_org_id = pr.loc_org_id and p.org_level = pr.org_level and pr.active_ind = 1
		and pr.curr_key = p.curr_key)
  as pr(part_no, location, curr_key, price_a) on pr.part_no = i.part_no and pr.location = i.location and pr.curr_key = q.curr_key
  where q.type = 'L' 

  update q
  set amt = pr.price_a + ((100 - q.rate)/100)
  from #quotes q
  join #catalog i on q.part_no = i.part_no and q.location = i.location
  join (select pr.part_no, p.location, p.curr_key, pr.price_a
 from part_price_vw pr (nolock)
 join (select p.part_no, p.location, case p.org_level when 0 then '' when 1 then l.organization_id else p.location end, p.curr_key, p.org_level
       from locations l (nolock)
       join (select p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key, max(p.org_level)
             from part_price_vw p (nolock)
             join inv_list i (nolock) on i.part_no = p.part_no
             join locations l (nolock) on (l.organization_id = p.loc_org_id and p.org_level = 1 and l.location = i.location) or (l.location = i.location and p.org_level != 1) 
             where p.part_no = i.part_no and p.active_ind = 1
             group by p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key)
             as p(part_no, location, curr_key, org_level) on l.location = p.location)
       as p(part_no, location, loc_org_id, curr_key, org_level) on p.part_no = pr.part_no and p.loc_org_id = pr.loc_org_id and p.org_level = pr.org_level and pr.active_ind = 1
		and pr.curr_key = p.curr_key)
  as pr(part_no, location, curr_key, price_a) on pr.part_no = i.part_no and pr.location = i.location and pr.curr_key = q.curr_key
  where q.type = '-' 

  update i
  set rate = q.amt,
  curr_key = q.curr_key
  from #catalog i, #quotes q
  where i.part_no = q.part_no  and q.location = i.location
end

INSERT INTO #catalog (part_no, description, category)
VALUES (@catalog, 'Catalog where the items will be inserted' , 'CATAINT')

INSERT INTO #catalog (part_no, description, category)
VALUES (@vendor, 'Vendor where the items will be inserted' , 'SUPPINT')

select distinct
i.part_no,
i.upc_code,
i.sku_no,
i.description,
i.vendor,
i.category,
i.uom,
i.location,
isnull(i.rate,0) as rate,
isnull(i.curr_key,'') as curr_key,
isnull(i.cost,0) as cost
from #catalog i

end
else
begin
-- 735 eprocurement
select @location = isnull((select location_code from adm_cust_all where customer_code = @cust_code),'')

insert #catalog
select 
'',
i.part_no,
i.upc_code,
i.sku_no,
i.description,
i.vendor,
i.category,
i.uom,
pr.price_a,
NULL,
(l.std_cost + l.std_direct_dolrs + l.std_ovhd_dolrs + l.std_util_dolrs),
0
from inv_master i (nolock) 
join glco g (nolock) on 1 = 1
left outer join inv_list l (nolock) on l.part_no = i.part_no and l.location = @location
left outer join 
(select pr.part_no, p.location, p.curr_key, pr.price_a
 from part_price_vw pr (nolock)
 join (select p.part_no, p.location, case p.org_level when 0 then '' when 1 then l.organization_id else p.location end, p.curr_key, p.org_level
       from locations l (nolock)
       join (select p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key, max(p.org_level)
             from part_price_vw p (nolock)
             join inv_list i (nolock) on i.part_no = p.part_no
             join glco g (nolock) on g.home_currency = p.curr_key
             join locations l (nolock) on (l.organization_id = p.loc_org_id and p.org_level = 1 and l.location = i.location) or (l.location = i.location and p.org_level != 1) 
             where p.part_no = i.part_no and p.active_ind = 1
             group by p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key)
             as p(part_no, location, curr_key, org_level) on l.location = p.location)
       as p(part_no, location, loc_org_id, curr_key, org_level) on p.part_no = pr.part_no and p.loc_org_id = pr.loc_org_id and p.org_level = pr.org_level and pr.active_ind = 1)
  as pr(part_no, location, curr_key, price_a) on pr.part_no = i.part_no and pr.location = l.location
where isnull(i.eprocurement_flag,0) = 1 and i.status != 'R'

insert #quotes
select '',item, 0, ilevel, type, rate, curr_key,
case when type = 'P' then rate else NULL end
from c_quote c
where customer_key = @cust_code and ship_to_no = 'ALL'
and c.date_expires = 
      (select min(c1.date_expires) from c_quote c1
      where customer_key = @cust_code and ship_to_no = 'ALL' and c1.item = c.item and c1.ilevel = c.ilevel
        and c1.type = c.type and getdate() between c1.start_date and dateadd(day,1,c1.date_expires))

insert #quotes
select '',i.part_no, 1, 0, q.type, q.rate, q.curr_key,
case when q.type = 'P' then q.rate else NULL end
from #quotes q, inv_master i
where q.ilevel = 1 and q.part_no = i.category

delete from #quotes where ilevel = 1

insert #quotes
select '',part_no, 1 + isnull(charindex(type,'P+C-L'),6), 0, type, rate, curr_key, amt
from #quotes q
where q.ilevel = 0 and
q.quote_order = (select min(q1.quote_order)
from #quotes q1 where q1.part_no = q.part_no )

delete from #quotes where quote_order < 2

insert #quotes
select '',part_no, 0, 0, type, rate, curr_key, amt
from #quotes q
where q.quote_order = (select min(q1.quote_order)
from #quotes q1 where q1.part_no = q.part_no )

delete from #quotes where quote_order > 0

update q
set amt = i.cost * ((100 + q.rate)/100)
from #quotes q, #catalog i
where q.part_no = i.part_no and q.type = '+' 

update q
set amt = i.cost + q.rate
from #quotes q, #catalog i
where q.part_no = i.part_no and q.type = 'C' 

update q
set amt = pr.price_a - q.rate
from #quotes q
  join #catalog i on q.part_no = i.part_no 
  join (select pr.part_no, p.location, p.curr_key, pr.price_a
 from part_price_vw pr (nolock)
 join (select p.part_no, p.location, case p.org_level when 0 then '' when 1 then l.organization_id else p.location end, p.curr_key, p.org_level
       from locations l (nolock)
       join (select p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key, max(p.org_level)
             from part_price_vw p (nolock)
             join inv_list i (nolock) on i.part_no = p.part_no
             join locations l (nolock) on (l.organization_id = p.loc_org_id and p.org_level = 1 and l.location = i.location) or (l.location = i.location and p.org_level != 1) 
             where p.part_no = i.part_no and p.active_ind = 1
             group by p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key)
             as p(part_no, location, curr_key, org_level) on l.location = p.location)
       as p(part_no, location, loc_org_id, curr_key, org_level) on p.part_no = pr.part_no and p.loc_org_id = pr.loc_org_id and p.org_level = pr.org_level and pr.active_ind = 1
		and pr.curr_key = p.curr_key)
  as pr(part_no, location, curr_key, price_a) on pr.part_no = i.part_no and pr.location = @location and pr.curr_key = q.curr_key
where q.type = 'L' 

update q
set amt = pr.price_a + ((100 - q.rate)/100)
from #quotes q
  join #catalog i on q.part_no = i.part_no 
  join (select pr.part_no, p.location, p.curr_key, pr.price_a
 from part_price_vw pr (nolock)
 join (select p.part_no, p.location, case p.org_level when 0 then '' when 1 then l.organization_id else p.location end, p.curr_key, p.org_level
       from locations l (nolock)
       join (select p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key, max(p.org_level)
             from part_price_vw p (nolock)
             join inv_list i (nolock) on i.part_no = p.part_no
             join locations l (nolock) on (l.organization_id = p.loc_org_id and p.org_level = 1 and l.location = i.location) or (l.location = i.location and p.org_level != 1) 
             where p.part_no = i.part_no and p.active_ind = 1
             group by p.part_no, case p.org_level when 0 then i.location when 1 then l.location when 2 then p.loc_org_id end, p.curr_key)
             as p(part_no, location, curr_key, org_level) on l.location = p.location)
       as p(part_no, location, loc_org_id, curr_key, org_level) on p.part_no = pr.part_no and p.loc_org_id = pr.loc_org_id and p.org_level = pr.org_level and pr.active_ind = 1
		and pr.curr_key = p.curr_key)
  as pr(part_no, location, curr_key, price_a) on pr.part_no = i.part_no and pr.location = @location and pr.curr_key = q.curr_key
where q.type = '-' 

update i
set rate = q.amt,
curr_key = q.curr_key
from #catalog i, #quotes q
where i.part_no = q.part_no 


select
i.part_no,
i.upc_code,
i.sku_no,
i.description,
i.vendor,
i.category,
i.uom,
isnull(i.rate,0) as rate,
isnull(i.curr_key,'') as curr_key
from #catalog i
end


return @rc

GO
GRANT EXECUTE ON  [dbo].[adm_ep_get_catalog] TO [public]
GO
