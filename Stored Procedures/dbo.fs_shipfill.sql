SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_shipfill] @ord_date datetime, @loc varchar(10) AS 
BEGIN

declare @ord int, @ext int, @xlp int, @lin int, @old_ord int
declare @old_ext int, @old_lin int
declare @part varchar(30), @sch_ship_date datetime, @qty decimal(20,8)
declare @fetch_status int


create table #ship_stk 
  (location varchar(10), part_no varchar(30), stock_qty decimal(20,8), status char(1)) -- mls 3/19/01 SCR 26329
create index ship_stk_part on #ship_stk(part_no,stock_qty)

create table #ship_sort 
  (ord_no int, ord_ext int, line_no int, part_no varchar(30), 
   qty decimal(20,8) default(0), sch_ship_date datetime NULL, row_id int identity(1,1))
create index rowidindex ON #ship_sort(row_id)

CREATE TABLE #shipfill 
(location varchar (10) NOT NULL , order_no int NOT NULL , order_ext int NOT NULL ,
 part_no varchar (30) NOT NULL , filled varchar (1) NULL ,needed decimal(20, 8) NULL ,
 commit_ed decimal(20, 8) NULL , line_no int NULL , sch_ship_date datetime NULL ,
 cust_code varchar (10) NULL , priority char (1) NULL , picked char (1) NOT NULL,
 i_status char(1) NULL
)
create index #shipfill1 on #shipfill(filled,sch_ship_date, priority, order_no, order_ext, line_no, part_no)
create index #shipfill2 on #shipfill(order_no, order_ext, filled, line_no, part_no)
create index #shipfill3 on #shipfill(i_status)

delete shipfill where location = @loc
delete ship_fill_temp where location = @loc


INSERT #ship_stk 
(location, part_no, stock_qty, status)
select location, part_no, case when in_stock < 0 then 0 else in_stock end, status
FROM   inventory (nolock)
WHERE location = @loc and status < 'V' and status != 'R'

--UPDATE #ship_stk set stock_qty = 0 where stock_qty < 0


INSERT #shipfill 
(location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked, i_status )
SELECT l.location, o.order_no, o.ext, l.part_no, 
  case when isnull(i.status,'') = 'V' or create_po_flag = 1 then 'N' else 'A' end,	-- mls 6/7/07 SCR 37381
  l.ordered * l.conv_factor, 
  case when isnull(i.status,'') = 'V' then l.ordered * l.conv_factor else 0 end, 
  l.line_no, o.sch_ship_date, 'Z', 'N', i.status
FROM  ord_list l (nolock)
JOIN  orders_shipping_vw o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext 
left outer join inv_master i (nolock) on i.part_no = l.part_no
WHERE l.location=@loc  and l.ordered > 0 and l.part_type = 'P'
  and o.type = 'I' and (o.status = 'N' ) and (o.sch_ship_date <= @ord_date )


INSERT #shipfill 
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked, i_status )
SELECT l.location, o.order_no, o.ext, k.part_no, 
  case when isnull(i.status,'') = 'V' or create_po_flag = 1 then 'N' else 'A' end,	-- mls 6/7/07 SCR 37381
  (l.ordered * l.conv_factor * k.qty_per), 
  case when isnull(i.status,'') = 'V' then (l.ordered * l.conv_factor * k.qty_per) else 0 end, 
  l.line_no, o.sch_ship_date, 'Z', 'N', i.status
FROM ord_list_kit k (nolock)
Join ord_list l (nolock) on l.order_no = k.order_no and l.order_ext = k.order_ext and l.line_no = k.line_no
Join orders_shipping_vw o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
left outer join inv_master i (nolock) on i.part_no = k.part_no
WHERE l.location=@loc and l.ordered > 0 and l.part_type = 'C' and
  o.type = 'I' and (o.status = 'N' ) and (o.sch_ship_date <= @ord_date )


--UPDATE shipfill set filled = 'N', commit_ed = needed 
--FROM  shipfill s, #ship_stk i
--WHERE i.part_no = s.part_no and i.location = s.location and 
--  i.location = @loc and i.status = 'V' 


insert #ship_sort 
(ord_no, ord_ext, line_no, part_no) 
select order_no, order_ext, line_no, part_no
FROM #shipfill 
WHERE filled = 'A' 
ORDER BY sch_ship_date, priority, order_no, order_ext, line_no

--select @new_ord=@ord, @new_ext=@ext, @new_lin=@lin

DECLARE c_shipsort CURSOR LOCAL FOR
select ord_no, ord_ext, line_no, part_no, row_id
from #ship_sort
order by row_id

OPEN c_shipsort

FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp

select @fetch_status = @@FETCH_STATUS
While @fetch_status = 0 
begin
  UPDATE #shipfill 
  set commit_ed = case when (stock_qty >= needed) then needed else commit_ed end,
    filled = 
    case when (stock_qty < needed and stock_qty > 0) then 'P' 
      when (stock_qty >= needed) then 'C' end
  FROM   #ship_stk
  WHERE #ship_stk.part_no = #shipfill.part_no and #ship_stk.stock_qty > 0 and
    order_no = @ord and order_ext = @ext and line_no = @lin and 
    #shipfill.part_no=@part 
	
  UPDATE #ship_stk set stock_qty = 
    case when (stock_qty - commit_ed) < 0 then 0 else (stock_qty - commit_ed) end
  FROM   #shipfill 
  WHERE #ship_stk.part_no = #shipfill.part_no and #ship_stk.stock_qty > 0 and
    order_no = @ord and order_ext = @ext and line_no = @lin and 
    #shipfill.part_no=@part and #shipfill.filled = 'C' 
	
  select @old_ord = @ord, @old_ext = @ext, @old_lin = @lin

  FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp
  select @fetch_status = @@FETCH_STATUS

  if @fetch_status != 0
  begin
    select @ord = 0, @ext = 0
  end 

  
  if @fetch_status != 0 or (@ord != @old_ord OR @old_ext != @ext)
  BEGIN
    
    if exists( select 1 from #shipfill where order_no = @old_ord and order_ext = @old_ext and
      filled = 'P' ) 
    begin
      UPDATE #ship_stk set stock_qty = stock_qty + isnull((select sum(commit_ed) 
      FROM   #shipfill 
      WHERE #ship_stk.part_no = #shipfill.part_no  and
        order_no = @old_ord and order_ext = @old_ext),0)

      UPDATE #shipfill set commit_ed = 0, filled = 'Z' 
      WHERE order_no = @old_ord and order_ext = @old_ext 
    end
  END
end 

CLOSE c_shipsort
DEALLOCATE c_shipsort




delete #ship_sort
insert #ship_sort (ord_no, ord_ext, line_no, part_no) 
select order_no, order_ext, line_no, part_no
FROM #shipfill 
WHERE filled = 'Z'
ORDER BY sch_ship_date, priority, order_no, order_ext, line_no

DECLARE c_shipsort CURSOR LOCAL FOR
select ord_no, ord_ext, line_no, part_no, row_id
from #ship_sort
order by row_id

OPEN c_shipsort

FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp

While @@fetch_status = 0 
begin
	
--	UPDATE shipfill set filled = 'P' 
--		WHERE order_no = @ord and order_ext = @ext and
--		line_no = @lin
  UPDATE #shipfill 
  set commit_ed = case when (stock_qty < needed) then stock_qty else needed end, 
    filled = case when (stock_qty < needed) then 'P' else 'C' end
  FROM   #ship_stk
  WHERE order_no = @ord and order_ext = @ext and line_no = @lin and
    #shipfill.part_no=@part and
    #ship_stk.part_no = #shipfill.part_no and stock_qty > 0 

  UPDATE #ship_stk 
  set stock_qty = case when (stock_qty - commit_ed) < 0 then 0 else (stock_qty - commit_ed) end
  FROM   #shipfill 
  WHERE #ship_stk.part_no = #shipfill.part_no and stock_qty > 0 and
    order_no = @ord and order_ext = @ext and line_no = @lin and
    #shipfill.part_no=@part and commit_ed > 0

  FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp
end 

close c_shipsort
deallocate c_shipsort




delete #ship_sort
insert #ship_sort 
  (ord_no, ord_ext, line_no, part_no, qty, sch_ship_date) 
select order_no, order_ext, line_no, s.part_no, needed - commit_ed, sch_ship_date
FROM #shipfill s
WHERE s.i_status='K' and commit_ed < needed
ORDER BY sch_ship_date, priority, order_no, order_ext, line_no

DECLARE c_shipsort CURSOR LOCAL FOR
select ord_no, ord_ext, line_no, part_no, qty, sch_ship_date, row_id
from #ship_sort
order by row_id

OPEN c_shipsort

FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @qty, @sch_ship_date, @xlp

While @@fetch_status = 0 
begin
  UPDATE #shipfill 
  SET needed = commit_ed, filled='C'
  WHERE order_no = @ord and order_ext = @ext and line_no = @lin and part_no=@part

  DELETE #shipfill
  WHERE order_no = @ord and order_ext = @ext and line_no = @lin and part_no=@part and 
    needed <= 0
	
  
  INSERT #shipfill 
    ( location, order_no, order_ext, part_no, filled, needed, commit_ed,
      line_no, sch_ship_date, priority, picked, i_status )
  SELECT l.location, l.order_no, l.order_ext, k.part_no, 'K',
    case when fixed = 'N' then (@qty * l.conv_factor * k.qty)
      else k.qty end, 0, l.line_no, @sch_ship_date, 'Z', 'N', i.status
  FROM  ord_list l (nolock)
  JOIN what_part k (nolock) on k.asm_no = l.part_no 
  JOIN inv_master i (nolock) on i.part_no = k.part_no 
  WHERE l.order_no = @ord and l.order_ext = @ext and l.line_no = @lin and l.part_no = @part and
    l.location=@loc and l.ordered > 0 and
    k.active<='B' and (k.location='ALL' or k.location=@loc) and k.fixed in ('Y','N') and
    i.status < 'Q' 

  FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @qty, @sch_ship_date, @xlp
end

close c_shipsort
deallocate c_shipsort

delete #ship_sort

insert #ship_sort 
(ord_no, ord_ext, line_no, part_no) select order_no, order_ext, line_no, s.part_no
FROM #shipfill s
WHERE filled = 'K'
ORDER BY sch_ship_date, priority, order_no, order_ext, line_no

DECLARE c_shipsort CURSOR LOCAL FOR
select ord_no, ord_ext, line_no, part_no, row_id
from #ship_sort
order by row_id

OPEN c_shipsort

FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp

While @@fetch_status = 0 
begin
  UPDATE #shipfill 
  set commit_ed = case when (stock_qty < needed) then stock_qty else needed end,
    filled = case when (stock_qty < needed) then filled else 'C' end 
  FROM   #ship_stk
  WHERE order_no = @ord and order_ext = @ext and 
    line_no = @lin and #shipfill.part_no=@part and
    #ship_stk.part_no = #shipfill.part_no and stock_qty > 0

  UPDATE #ship_stk 
  set stock_qty = case when (stock_qty - commit_ed) < 0 then 0 else (stock_qty - commit_ed) end
  FROM   #shipfill 
  WHERE order_no = @ord and order_ext = @ext and 
    #shipfill.line_no = @lin and #shipfill.part_no=@part and
    #ship_stk.part_no = #shipfill.part_no and stock_qty > 0 and commit_ed > 0

  FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp
end 

close c_shipsort
deallocate c_shipsort


INSERT #shipfill 					 			-- mls 11/13/01 SCR 27907 start
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked )
SELECT l.location, o.order_no, o.ext, 
  l.part_no,  'A',l.ordered * l.conv_factor,   l.ordered * l.conv_factor,					
  l.line_no, o.sch_ship_date, 'Z', 'N'
FROM  ord_list l (nolock)
JOIN orders_shipping_vw o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
WHERE o.type = 'I' and o.status = 'N' and o.sch_ship_date <= @ord_date and 
  l.location=@loc and l.ordered > 0 and l.part_type = 'V'			-- mls 11/13/01 SCR 27907 end


INSERT #shipfill 					 			-- mls 10/30/01 SCR 27365 start
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked )
SELECT l.location, o.order_no, o.ext, 
  l.part_no,  'A',l.ordered * l.conv_factor,   l.ordered * l.conv_factor,					
  l.line_no, o.sch_ship_date, 'Z', 'N'
FROM  ord_list l (nolock)
JOIN orders_shipping_vw o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
WHERE o.type = 'I' and o.status = 'N' and o.sch_ship_date <= @ord_date and 
  l.location=@loc and l.ordered > 0 and l.part_type = 'M'			



INSERT #shipfill 
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked )
SELECT l.location, o.order_no, o.ext, 
  'Prod # ('+l.part_no+')', 'A',
  l.ordered * l.conv_factor,
  isnull((select sum(qty - qty_scheduled) from produce_all (nolock) where prod_no = convert(int,l.part_no) and status < 'R'),0) +
  (l.ordered * l.conv_factor),
  l.line_no, o.sch_ship_date, 'Z', 'N'
FROM  ord_list l (nolock)
JOIN orders_shipping_vw o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
WHERE o.type = 'I' and o.status = 'N' and o.sch_ship_date <= @ord_date and 
  l.location=@loc and l.ordered > 0 and l.part_type = 'J'			-- mls 10/30/01 SCR 27365 end

if not exists (select 1 from shipfill where location = @loc)
begin
  begin tran

  INSERT shipfill
  (location, order_no, order_ext, part_no, filled, needed, commit_ed, line_no, 
    sch_ship_date, cust_code, priority, picked)
  SELECT location, order_no, order_ext, part_no, filled, needed, commit_ed, line_no, 
    sch_ship_date, cust_code, priority, picked 
  FROM #shipfill

  
  INSERT ship_fill_temp (location , order_no, order_ext, percent_filled, quantity) -- mls 8/18/09 SCR 051723
  SELECT location, order_no, order_ext, sum(commit_ed) / sum(needed), sum(needed)
  FROM   #shipfill
  WHERE  needed > 0 
  GROUP BY location, order_no, order_ext
  having sum(commit_ed) / sum(needed) >= 0.0001
  ORDER BY location, order_no, order_ext

  commit tran
end

return
END
GO
GRANT EXECUTE ON  [dbo].[fs_shipfill] TO [public]
GO
