SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
 exec cvo_customer_price_list_sp '013748','','bcbg,ch,izod,izx,cvo','001','03/03/2014','%','FRAME,SUN'
*/

CREATE procedure [dbo].[cvo_customer_price_list_sp]
( @customer_code varchar(8), 
    @ship_to_code varchar(8), 
    @collection varchar(1000), 
    @location varchar(10), 
    @asofdate datetime, 
    @part_no varchar(30),
    @type_code varchar(1000)
    )
as
begin

set nocount on

if(object_id('tempdb.dbo.#t') is not null)
drop table #t

CREATE TABLE #T
(
ID int IDENTITY,
customer_code varchar(8),
ship_to_code varchar(8),
address_name varchar(40),
collection varchar(30),
style varchar(20),
channel varchar(20),
part_no varchar(30),
price_a float,
comments varchar(60),
price float,
promo_rate float,
min_qty float,
customer_key varchar(10),
ship_to_no varchar(10),
ilevel int,
item varchar(30),
startdate datetime,
end_date datetime,
type varchar(3),
qloop int,
rate float,
curr_key varchar(3),
promo_dt datetime,
curr_ind int,
in_part varchar(30),
in_loc varchar(10),
pom_date datetime,
release_date datetime,
type_code varchar(10),
gender varchar(40)
)


-- set up tables for multi-value parameters

CREATE TABLE #TYPE_CODE (TYPE_CODE VARCHAR(10))

INSERT INTO #TYPE_CODE (type_code)
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@TYPE_CODE)

CREATE TABLE #collection ([collection] VARCHAR(30))

INSERT INTO #collection ([collection])
SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@collection)

--select * From #type_code

insert into #t (customer_code, ship_to_code, address_name, collection, style, channel, part_no, price_a, pom_date, release_date, type_code, gender)
select a.customer_code, a.ship_to_code, c.customer_name, i.category, i.style, i.channel, i.part_no, i.price_a, i.pom_date, i.release_date, i.type_code, i.gender
from armaster a 
inner join arcust c on c.customer_code = @customer_code
cross join 
(select min(ii.part_no) part_no, ii.category, ia.field_2 style, ii.type_code, ia.field_28 pom_date, ia.field_26 release_date, p.price_a, 
case when ia.field_32 in ('retail','hvc') then ia.field_32 else '' end as channel,
(select top 1 description from cvo_gender where kys=ia.category_2) gender
    from inv_master ii 
    inner join inv_master_add ia on ii.part_no = ia.part_no
    inner join part_price p on ii.part_no = p.part_no 
    INNER JOIN #type_code t on t.type_code = ii.type_code
    INNER JOIN #collection c on c.collection = ii.category
    where 1=1
    and ii.void = 'N'
    and @asofdate  <= isnull(ia.field_28, @asofdate)
    -- and ii.category like @collection
    -- and ii.type_code like @type_code
    and ii.part_no like @part_no
    group by ii.category, ia.field_2 , ii.type_code, ia.field_28 , ia.field_26, p.price_a, ia.field_32, ia.category_2 ) as i
where 1=1
and a.customer_code like @customer_code
and a.ship_to_code like @ship_to_code


--

declare @last_id int, @max_id int

if(object_id('tempdb.dbo.#tt') is not null)
drop table #tt

create table #tt
(
id int identity,
comments varchar(60),
price float,
promo_rate float,
min_qty float,
customer_key varchar(10),
ship_to_no varchar(10),
ilevel int,
item varchar(30),
startdate datetime,
end_date datetime,
type varchar(3),
qloop int,
rate float,
curr_key varchar(3),
promo_dt datetime,
curr_ind int,
in_part varchar(30),
in_loc varchar(10),
curr_mask varchar(255)
)
/*
 EXEC dbo.fs_show_price @cust = '011111',@shipto = '',@clevel = '1',@pn = 'BCGCOLINK5316',@loc = '001',@curr_key = 'USD',@curr_factor = 1,@svc_agr = 'N',@in_qty = 1,@conv_factor = 1,@mask = '''$ ''###,###,###,###.00;(''$ ''###,###,###,###.00)'  
*/ 

select @last_id = min(id) from #t

select @customer_code = customer_code, @ship_to_code = ship_to_code,
    @part_no = part_no from #t
where id = @last_id
       

while @last_id is not null
begin   
/*
 EXEC dbo.fs_show_price @cust = '011111',@shipto = '',@clevel = '1',@pn = 'BCGCOLINK5316',@loc = '001',@curr_key = 'USD',@curr_factor = 1,@svc_agr = 'N',@in_qty = 1,@conv_factor = 1,@mask = '''$ ''###,###,###,###.00;(''$ ''###,###,###,###.00)'  
*/
    insert into #tt 
    (comments, price, promo_rate, min_qty, customer_key, ship_to_no, ilevel, item, startdate,
    end_date, type, qloop, rate, curr_key, promo_dt, curr_ind, in_part, in_loc, curr_mask)
    EXEC dbo.fs_show_price 
    @cust = @customer_code, @shipto = @ship_to_code,
    @clevel = '1', @pn = @part_no, @loc = @location, @curr_key = 'USD', 
    @curr_factor = 1, @svc_agr = 'N', @in_qty = 1, @conv_factor = 1,
    @mask = '''$ ''###,###,###,###.00;(''$ ''###,###,###,###.00)'  
    
    -- select * from #tt
    delete from #tt where qloop = 99
    
    select @max_id = max(id) from #tt
    
    update #t set #t.comments = #tt.comments, 
    #t.price = #tt.price, 
    #t.promo_rate = #tt.promo_rate,
    #t.min_qty = #tt.min_qty, 
    #t.customer_key = #tt.customer_key, 
    #t.ship_to_no = #tt.ship_to_no, 
    #t.ilevel = #tt.ilevel, 
    #t.item = #tt.item, 
    #t.startdate = #tt.startdate, 
    #t.end_date = #tt.end_date,
    #t.type = #tt.type, 
    #t.rate = #tt.rate, 
    #t.curr_key = #tt.curr_key, 
    #t.promo_dt = #tt.promo_dt,
    #t.curr_ind = #tt.curr_ind, 
    #t.in_part = #tt.in_part, 
    #t.in_loc = #tt.in_loc
    
    from #tt cross join #t
    where #t.id = @last_id 
    and #tt.id = @max_id
    
    truncate table #tt
    
    select @last_id = min(id)
    from #t where id > @last_id
       
    select @customer_code = customer_code, @ship_to_code = ship_to_code,
    @part_no = part_no from #t where id = @last_id
    
end

select * , c.description brand_desc from #t
inner join category c on c.kys = #t.collection

end
GO
GRANT EXECUTE ON  [dbo].[cvo_customer_price_list_sp] TO [public]
GO
