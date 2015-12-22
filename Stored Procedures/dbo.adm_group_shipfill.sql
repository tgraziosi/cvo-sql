SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_group_shipfill] @batch_name varchar(32)  as
BEGIN

declare @batch_id int
declare @ord int, @ext int, @xlp int, @lin int, @old_ord int
declare @old_ext int, @old_lin int
declare @part varchar(30), @sch_ship_date datetime, @qty decimal(20,8)
declare @fetch_status int
declare @percent_fill_s decimal(20,8), @percent_fill_e decimal(20,8)
declare @rtn int
declare @group_cmd varchar(2000)
declare @detail_row_id int, @loc varchar(10), @o_row_id int
declare @group_sel varchar(2000)
declare @group_order_by varchar(2000)
declare @group_label varchar(2000)
declare @group int, @max_group int
declare @insert_cmd varchar(2000), @update_cmd varchar(500)

create table #command (command_name varchar(30), command_txt varchar(2000))

create table #batch (group_no int,order_no int, ext int, cust_code varchar(8), ship_to varchar(8) null, 
so_priority_code char(1), salesperson varchar(8), ship_to_region varchar(8), addr_sort1 varchar(40),
addr_sort2 varchar(40), addr_sort3 varchar(40), date_entered datetime, req_ship_date datetime,
sch_ship_date datetime, percent_fillable decimal(20,8), curr_key varchar(8), back_ord_flag char(1),
location varchar(10), route_code varchar(10), route_no int, backorders_only int, status char(1),
status_text varchar(10) default (''), bo_text varchar(20) default(''),
checked int default(0), row_id int identity(1,1), part_fillable decimal(20,8) default(0), organization_id varchar(30))
create index #batch_pk on #batch (order_no, ext)
create index #batch_row on #batch (row_id)

create table #group (min_row int default(0), val01 varchar(100), val02 varchar(100), val03 varchar(100), 
val04 varchar(100), val05 varchar(100), val06 varchar(100), val07 varchar(100), 
val08 varchar(100), val09 varchar(100), val10 varchar(100), val11 varchar(100), 
val12 varchar(100), val13 varchar(100), val14 varchar(100), val15 varchar(100), 
val16 varchar(100), val17 varchar(100), val18 varchar(100), val19 varchar(100), 
val20 varchar(100), group_no int identity(1,1), label varchar(255) default(''))


create table #ship_stk 
  (location varchar(10), part_no varchar(30), stock_qty decimal(20,8), status char(1)) -- mls 3/19/01 SCR 26329
create index ship_stk_part on #ship_stk(part_no,stock_qty)

create table #ship_sort 
  (ord_no int, ord_ext int, line_no int, part_no varchar(30), location varchar(10),
   qty decimal(20,8) default(0), o_row_id int, detail_row_id int, row_id int identity(1,1))
create index rowidindex ON #ship_sort(row_id)

CREATE TABLE #detail 
(location varchar (10) NOT NULL , order_no int NOT NULL , order_ext int NOT NULL ,
 part_no varchar (30) NOT NULL , filled varchar (1) NULL ,needed decimal(20, 8) NULL ,
 commit_ed decimal(20, 8) NULL , line_no int NULL , sch_ship_date datetime NULL ,
 cust_code varchar (10) NULL , priority char (1) NULL , picked char (1) NOT NULL,
 i_status char(1) NULL, o_row_id int, o_group int, row_id int identity(1,1), protect_line int,
)
create index #detail1 on #detail(o_group,filled,o_row_id,order_no,order_ext,line_no)
create index #detail2 on #detail(order_no, order_ext)
create index #detail3 on #detail(row_id)
create index #detail4 on #detail(i_status,o_group, o_row_id, order_no, order_ext, line_no)

select @batch_id = isnull((select min(batch_no) from adm_shipment_fill_filter where batch_name = @batch_name),0)

if @batch_id = 0
begin
select -1
return
end

delete adm_shipment_fill_detail where batch_no = @batch_id
delete adm_shipment_fill_group where batch_no = @batch_id
delete adm_shipment_fill_batch where batch_no = @batch_id


exec @rtn = adm_group_shipfill_order @batch_name, @percent_fill_s OUT, @percent_fill_e OUT

if @rtn < 1 
begin
select @rtn 
return
end


INSERT #detail 
(location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked, i_status , o_row_id, o_group, protect_line)
SELECT l.location, o.order_no, o.ext, l.part_no, 
  case when isnull(i.status,'') = 'V' then 'N' else 'A' end,
  l.ordered * l.conv_factor, 
  case when isnull(i.status,'') = 'V' then l.ordered * l.conv_factor else 0 end, 
  l.line_no, getdate(), 'Z', 'N', i.status, o.row_id, o.group_no, l.protect_line
FROM  ord_list_ship_vw l (nolock)
JOIN  #batch o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
left outer join inv_master i (nolock) on i.part_no = l.part_no
WHERE l.ordered > 0 and l.part_type = 'P'   and o.status = 'N' 


INSERT #detail 
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked, i_status, o_row_id, o_group , protect_line)
SELECT l.location, o.order_no, o.ext, k.part_no, 
  case when isnull(i.status,'') = 'V' then 'N' else 'A' end,
  (l.ordered * l.conv_factor * k.qty_per), 
  case when isnull(i.status,'') = 'V' then (l.ordered * l.conv_factor * k.qty_per) else 0 end, 
  l.line_no, getdate(), 'Z', 'N', i.status, o.row_id, o.group_no, l.protect_line
FROM ord_list_kit k (nolock)
Join ord_list_ship_vw l (nolock) on l.order_no = k.order_no and l.order_ext = k.order_ext and l.line_no = k.line_no 
Join #batch o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
left outer join inv_master i (nolock) on i.part_no = k.part_no
WHERE l.ordered > 0 and l.part_type = 'C'  and o.status = 'N'


INSERT #ship_stk 
(location, part_no, stock_qty, status)
select distinct i.location, i.part_no, case when i.in_stock < 0 then 0 else i.in_stock end, i.status
FROM   inventory_unsecured_vw i (nolock), #detail s 
where i.part_no = s.part_no and i.location = s.location

-- process availability by sort order selected in filter screen
select @max_group = isnull((select max(group_no) from #batch),0)
select @group = isnull((select min(group_no) from #batch),0)

while @group <= @max_group
begin
  
  insert #ship_sort 
  (ord_no, ord_ext, line_no, part_no, location, o_row_id,  detail_row_id) 
  select order_no, order_ext, line_no, part_no, location, o_row_id, row_id
  FROM #detail 
  WHERE filled = 'A' and o_group = @group
  ORDER BY o_row_id, order_no, order_ext, line_no

  --select @new_ord=@ord, @new_ext=@ext, @new_lin=@lin

  DECLARE c_shipsort CURSOR LOCAL FOR
  select ord_no, ord_ext, line_no, part_no, location, detail_row_id,  row_id 
  from #ship_sort
  order by row_id

  OPEN c_shipsort

  FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @loc, @detail_row_id, @xlp

  select @fetch_status = @@FETCH_STATUS
  While @fetch_status = 0 
  begin
    UPDATE #detail 
    set commit_ed = case when (stock_qty >= needed) then needed else commit_ed end,
      filled = case when (stock_qty < needed and stock_qty > 0) then 'P' 
        when (stock_qty >= needed) then 'C' end
    FROM   #ship_stk
    WHERE #ship_stk.part_no = @part and #ship_stk.location = @loc and #ship_stk.stock_qty > 0 and
      row_id = @detail_row_id 
	
    UPDATE #ship_stk set stock_qty = 
      case when (stock_qty - commit_ed) < 0 then 0 else (stock_qty - commit_ed) end
    FROM   #detail 
    WHERE #ship_stk.part_no = @part and #ship_stk.location = @loc and #ship_stk.stock_qty > 0 and
      #detail.row_id = @detail_row_id and #detail.filled = 'C' 
	
    select @old_ord = @ord, @old_ext = @ext

    FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @loc, @detail_row_id, @xlp
    select @fetch_status = @@FETCH_STATUS

    if @fetch_status != 0
    begin
      select @ord = 0, @ext = 0
    end 

    
    if @fetch_status != 0 or (@old_ord != @ord or @old_ext != @ext) 
    BEGIN
      
      if exists( select 1 from #detail where order_no = @old_ord and order_ext = @old_ext and
        filled = 'P' ) 
      begin
        UPDATE #ship_stk set stock_qty = stock_qty + isnull((select sum(commit_ed) 
        FROM   #detail 
        WHERE #ship_stk.part_no = #detail.part_no  and #ship_stk.location = #detail.location and
          order_no = @old_ord and order_ext = @old_ext),0)

        UPDATE #detail set commit_ed = 0, filled = 'Z' 
        WHERE order_no = @old_ord and order_ext = @old_ext 
      end
    END
  end 

  CLOSE c_shipsort
  DEALLOCATE c_shipsort

  
  
  
  delete #ship_sort
  insert #ship_sort (ord_no, ord_ext, line_no, part_no,location, o_row_id, detail_row_id) 
  select order_no, order_ext, line_no, part_no, location, o_row_id, row_id
  FROM #detail 
  WHERE filled = 'Z' and o_group = @group
  ORDER BY o_row_id, order_no, order_ext, line_no

  DECLARE c_shipsort CURSOR LOCAL FOR
  select ord_no, ord_ext, line_no, part_no, row_id, location, detail_row_id
  from #ship_sort
  order by row_id

  OPEN c_shipsort
  FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp, @loc, @detail_row_id

  While @@fetch_status = 0 
  begin
    UPDATE #detail 
    set commit_ed = case when (stock_qty < needed) then stock_qty else needed end, 
      filled = case when (stock_qty < needed) then 'P' else 'C' end
    FROM   #ship_stk
    WHERE row_id = @detail_row_id and
      #ship_stk.part_no = @part and #ship_stk.location = @loc and stock_qty > 0

    UPDATE #ship_stk 
    set stock_qty = case when (stock_qty - commit_ed) < 0 then 0 else (stock_qty - commit_ed) end
    FROM   #detail 
    WHERE #ship_stk.part_no = @part and #ship_stk.location = @loc and stock_qty > 0 and
      row_id = @detail_row_id and commit_ed > 0

    FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp, @loc, @detail_row_id
  end 

  close c_shipsort
  deallocate c_shipsort

  
  
  
  delete #ship_sort
  insert #ship_sort 
    (ord_no, ord_ext, line_no, part_no, qty, location, o_row_id, detail_row_id) 
  select order_no, order_ext, line_no, s.part_no, needed - commit_ed, location, o_row_id, row_id
  FROM #detail s
  WHERE s.i_status='K' and commit_ed < needed and s.o_group = @group
  ORDER BY o_row_id, order_no, order_ext, line_no

  DECLARE c_shipsort CURSOR LOCAL FOR
  select ord_no, ord_ext, line_no, part_no, qty, row_id, location, detail_row_id, o_row_id
  from #ship_sort
  order by row_id

  OPEN c_shipsort

  FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @qty, @xlp, @loc, @detail_row_id, @o_row_id

  While @@fetch_status = 0 
  begin
    UPDATE #detail 
    SET needed = commit_ed, filled='C'
    WHERE row_id = @detail_row_id

    DELETE #detail
    WHERE row_id = @detail_row_id and needed <= 0
	
    
    INSERT #detail 
      ( location, order_no, order_ext, part_no, filled, needed, commit_ed,
       line_no, sch_ship_date, priority, picked, i_status, o_row_id, o_group , protect_line)
    SELECT l.location, l.order_no, l.order_ext, k.part_no, 'K',
      case when fixed = 'N' then (@qty * l.conv_factor * k.qty)
        else k.qty end, 0, l.line_no, getdate(), 'Z', 'N', i.status, @o_row_id, @group, l.protect_line
    FROM  ord_list_ship_vw l (nolock)
    JOIN what_part k (nolock) on k.asm_no = l.part_no 
    JOIN inv_master i (nolock) on i.part_no = k.part_no 
    WHERE l.order_no = @ord and l.order_ext = @ext and l.line_no = @lin and l.part_no = @part and
      l.location = @loc and l.ordered > 0 and 
      k.active<='B' and (k.location='ALL' or k.location=l.location) and k.fixed in ('Y','N') and
      i.status < 'Q' 

    FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @qty, @xlp, @loc, @detail_row_id, @o_row_id
  end

  close c_shipsort
  deallocate c_shipsort

  delete #ship_sort

  insert #ship_sort (ord_no, ord_ext, line_no, part_no, location, o_row_id, detail_row_id) 
  select order_no, order_ext, line_no, s.part_no, s.location, s.o_row_id, s.row_id 
  FROM #detail s
  WHERE filled = 'K' and o_group = @group
  ORDER BY o_row_id, order_no, order_ext, line_no

  DECLARE c_shipsort CURSOR LOCAL FOR
  select ord_no, ord_ext, line_no, part_no, row_id, location, detail_row_id
  from #ship_sort
  order by row_id

  OPEN c_shipsort
  FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp, @loc, @detail_row_id

  While @@fetch_status = 0 
  begin
    UPDATE #detail 
    set commit_ed = case when (stock_qty < needed) then stock_qty else needed end,
      filled = case when (stock_qty < needed) then filled else 'C' end 
    FROM   #ship_stk
    WHERE row_id = @detail_row_id and
      #ship_stk.part_no = @part and #ship_stk.location = @loc and stock_qty > 0

    UPDATE #ship_stk 
    set stock_qty = case when (stock_qty - commit_ed) < 0 then 0 else (stock_qty - commit_ed) end
    FROM   #detail 
    WHERE row_id = @detail_row_id and
      #ship_stk.part_no = @part and #ship_stk.location = @loc and stock_qty > 0 and commit_ed > 0

    FETCH NEXT FROM c_shipsort into @ord, @ext, @lin, @part, @xlp, @loc, @detail_row_id
  end 

  close c_shipsort
  deallocate c_shipsort

  select @group = @group + 1
end  -- while @group <= @max_group


INSERT #detail 					 			-- mls 10/30/01 SCR 27365 start
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked, o_row_id, o_group, protect_line)
SELECT l.location, o.order_no, o.ext, 
  l.part_no,  'A',l.ordered * l.conv_factor,   l.ordered * l.conv_factor,					
  l.line_no, getdate(), 'Z', 'N', o.row_id, o.group_no, l.protect_line
FROM  ord_list_ship_vw l (nolock)
JOIN #batch o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
WHERE l.ordered > 0 and l.part_type = 'M' and o.status = 'N'



INSERT #detail 
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked, o_row_id, o_group, protect_line)
SELECT l.location, o.order_no, o.ext, 
  'Prod # ('+l.part_no+')', 'A',
  l.ordered * l.conv_factor,
  isnull((select sum(qty - qty_scheduled) from produce_all (nolock) where prod_no = convert(int,l.part_no) and status < 'R'),0) +
  (l.ordered * l.conv_factor),
  l.line_no, getdate(), 'Z', 'N', o.row_id, o.group_no, l.protect_line
FROM  ord_list_ship_vw l (nolock)
JOIN #batch o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
WHERE l.ordered > 0 and l.part_type = 'J' and o.status = 'N' 



INSERT #detail 
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked, o_row_id, o_group, protect_line)
SELECT l.location, o.order_no, o.ext, l.part_no, 'A',
  l.ordered * l.conv_factor, l.shipped * l.conv_factor,
  l.line_no, getdate(), 'Z', 'N', o.row_id, o.group_no, l.protect_line
FROM  ord_list_ship_vw l (nolock)
JOIN #batch o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
WHERE l.ordered > 0 and l.part_type in ('P','J','M') and o.status <> 'N' 

INSERT #detail 
( location, order_no, order_ext, part_no, filled, needed, commit_ed,
  line_no, sch_ship_date, priority, picked, i_status, o_row_id, o_group , protect_line)
SELECT l.location, o.order_no, o.ext, k.part_no, 'A', 
  (l.ordered * l.conv_factor * k.qty_per), 
  (l.shipped * l.conv_factor * k.qty_per), 
  l.line_no, getdate(), 'Z', 'N', i.status, o.row_id, o.group_no, l.protect_line
FROM ord_list_kit k (nolock)
Join ord_list_ship_vw l (nolock) on l.order_no = k.order_no and l.order_ext = k.order_ext and l.line_no = k.line_no 
Join #batch o (nolock) on o.order_no = l.order_no and o.ext = l.order_ext
left outer join inv_master i (nolock) on i.part_no = k.part_no
WHERE l.ordered > 0 and l.part_type = 'C'  and o.status <> 'N'

if not exists (select 1 from adm_shipment_fill_detail where batch_no = @batch_id )
begin
  begin tran

  update b
  set percent_fillable =
    isnull((select sum(case when protect_line = 0 then commit_ed else 0 end) / sum(needed)
    FROM   #detail s
    WHERE  s.order_no = b.order_no and s.order_ext = b.ext and s.needed > 0),0)
  from #batch b

  select @group_cmd = command_txt from #command where command_name = 'fillable_where'
  if @group_cmd != ''
  begin
    select @update_cmd = 'update b set part_fillable = ' +
      'isnull((select sum(commit_ed) / sum(needed) ' +
      'FROM   #detail s ' +
      'WHERE  s.order_no = b.order_no and s.order_ext = b.ext and o.needed > 0'

    exec (@update_cmd + @group_cmd + '),0) from #batch b')
  end

  if @percent_fill_s > 0 or @percent_fill_e < 1
  begin
    delete from #batch
    where percent_fillable not between @percent_fill_s and @percent_fill_e
  end

  update #batch
  set status_text = case when status = 'P' then 'Picked' when status = 'Q' then 'Printed' else 'New' end,
    bo_text = case back_ord_flag when 0 then 'Allow Backorder' when 1 then 'Ship Complete' when 2 then 'Allow Partial' else back_ord_flag end

  INSERT adm_shipment_fill_detail
  (batch_no, location, order_no, order_ext, part_no, filled, needed, commit_ed, line_no, 
    sch_ship_date, cust_code, priority, picked)
  SELECT @batch_id, d.location, d.order_no, d.order_ext, d.part_no, d.filled, d.needed, d.commit_ed, d.line_no, 
    d.sch_ship_date, d.cust_code, d.priority, d.picked 
  FROM #detail d, #batch b
  where d.o_row_id =  b.row_id

  select @group_sel = command_txt from #command where command_name = 'group_sel'
  if @group_sel = ''
  begin
    delete #group									-- mls 7/22/03 SCR 31606

    insert adm_shipment_fill_group (batch_no,label) values (@batch_id, 'ALL ORDERS')
    update #batch set group_no = 0 
  end
  else
  begin
    delete #group

    select @group_cmd = command_txt from #command where command_name = 'group_cmd'
    select @group_order_by = command_txt from #command where command_name = 'group_order_by'

    select @insert_cmd = 'insert #group ' +
    '(min_row,val01,val02,val03,val04,val05,val06,val07,val08,val09,val10,val11,val12,' +
    'val13,val14,val15,val16,val17,val18,val19,val20) select min(row_id), ' 

    exec (@insert_cmd + @group_sel + 
      ' from #batch group by ' + @group_cmd + ' order by ' + @group_order_by)

    select @group_cmd = command_txt from #command where command_name = 'group_where'

    select @update_cmd = 'update #batch set group_no = g.group_no from #group g where '
    exec (@update_cmd + @group_cmd)

    select @group_label = command_txt from #command where command_name = 'group_label'

    select @group_label = 'substring(' + @group_label + ',1,255)'
    select @update_cmd = 'update g set label = '
    exec (@update_cmd + @group_label + 'from #batch b, #group g where b.group_no = g.group_no and' +
      ' b.row_id = g.min_row')


    update #group 
    set label = substring(label,1,252) + '...'
    where substring(rtrim(label),datalength(rtrim(label)),1) != ')'

  end

  
  insert adm_shipment_fill_group
    (batch_no, group_no, val01,val02,val03,val04,val05,val06,val07,val08,val09,val10,val11,val12,
    val13,val14,val15,val16,val17,val18,val19,val20, label)
  select @batch_id, group_no, val01,val02,val03,val04,val05,val06,val07,val08,val09,val10,val11,val12,
    val13,val14,val15,val16,val17,val18,val19,val20, label
  from #group
  order by group_no

  select @group_cmd = command_txt from #command where command_name = 'sort_order_by'

  select @insert_cmd = 'insert adm_shipment_fill_batch ' +
    '(batch_no, group_no, order_no, ext, cust_code, ship_to, so_priority_code, salesperson, ship_to_region, addr_sort1, ' +
    'addr_sort2, addr_sort3, date_entered, req_ship_date, sch_ship_date, percent_fillable, curr_key, ' +
    'back_ord_flag, location, route_code, route_no, backorders_only, label)' +
    ' select ' + convert(varchar(10),@batch_id) + ',group_no, order_no, ext,' +
    'cust_code, ship_to, so_priority_code, salesperson, ship_to_region, addr_sort1, ' +
    'addr_sort2, addr_sort3, date_entered, req_ship_date, sch_ship_date, percent_fillable,' +
   'curr_key, back_ord_flag, location, route_code,' +
   'route_no, backorders_only'

  select @update_cmd = ', ''Order '' + convert(varchar(10),order_no) + ''-'' +' +
    'convert(varchar(10),ext) + '' '' + case b.status when ''P'' then ''Picked'' when ''Q'' then ''Printed'' else ''New'' end + ' +
    ''' (Ship to '' + cust_code + case when ship_to = '''' then '''' else ''-'' + ship_to end + ' +
    ''') ('' + convert(varchar(10),convert(int,round(percent_fillable * 100,0))) +' +
    '''% Fillable)'' from #batch b ' 

print @insert_cmd
print @update_cmd
print @group_cmd
  exec (@insert_cmd + @update_cmd + @group_cmd)
  commit tran

end

select @batch_id
return
END
GO
GRANT EXECUTE ON  [dbo].[adm_group_shipfill] TO [public]
GO
