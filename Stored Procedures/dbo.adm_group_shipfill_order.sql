SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_group_shipfill_order] @batch_name varchar(32), @percent_fill_s decimal(20,8) OUT,
@percent_fill_e decimal(20,8) OUT
as
BEGIN
DECLARE @sort_order_by varchar(500), @group_cmd varchar(2000),@group_sel varchar(2000), 
  @group_where varchar(2000) 

declare @start_s varchar(40), @stop_s varchar(40),
  @start_i int, @stop_i int,
  @start_t datetime, @stop_t datetime,
  @start_d decimal(20,8), @stop_d decimal(20,8),
  @part_i int, @part_s varchar(30), @part_e varchar(30),
  @loc_i int, @loc_s varchar(10), @loc_e varchar(10), 
  @org_i int, @org_s varchar(10), @org_e varchar(10), 
  @data_type char(1), @adm_cust_all_ind int, @sort_percent int

declare @sel_name varchar(50), @group_ind int, @sort_order int, 
  @sort_desc_ind int, @sel_ind int,
  @start varchar(255), @stop varchar(255), @batch_found int,
  @insert_cmd varchar(1000),@update_cmd varchar(1000),
  @where varchar(1000), @adm_cust_all_where varchar(1000),
  @sort_cnt int, @grp_cnt int,
  @order_where varchar(2000), @where2 varchar(1000), 
  @sort_col varchar(500),
  @sort_grp varchar(2000), @sort_grp_select varchar(2000),
  @sort_grp_where varchar(2000), @sel_col varchar(100),
  @sort_grp_order_by varchar(2000),
  @group_order_by varchar(2000),
  @group_label varchar(2000),
  @sort_ind int

create table #temp_batch (group_no int,order_no int, ext int, cust_code varchar(8), 
  ship_to varchar(8) null, so_priority_code char(1), salesperson varchar(8), 
  ship_to_region varchar(8), addr_sort1 varchar(40), addr_sort2 varchar(40), 
  addr_sort3 varchar(40), date_entered datetime, req_ship_date datetime,
  sch_ship_date datetime, percent_fillable decimal(20,8), curr_key varchar(8),
  back_ord_flag char(1), location varchar(10), route_code varchar(10), 
  route_no int, backorders_only int, checked int, status char(1), organization_id varchar(30))

create index #temp_batch1 on #temp_batch(checked)

select @batch_found = 0, @start_d = 0, @stop_d = 100
select @sort_cnt = 0, @grp_cnt = 0, @sort_percent = 0
select @org_i = -1

select @insert_cmd = 'insert #temp_batch' +
  ' select 0, o.order_no, o.ext, isnull(o.cust_code,''''), isnull(o.ship_to,''''), isnull(o.so_priority_code,''''),' +
  'isnull(o.salesperson,''''), isnull(o.ship_to_region,''''),' +
  ''''' addr_sort1,'''' addr_sort2,'''' addr_sort3,o.date_entered, o.req_ship_date, o.sch_ship_date, 0 percent_fillable, isnull(o.curr_key,''''), isnull(o.back_ord_flag,''''),' +
  'isnull(o.location,''''), '''' route_code, 0 route_no, case when o.ext > 0 then 1 else 0 end backorders_only, 0 checked, ' +
  ' o.status, isnull(o.organization_id,'''') from orders_shipping_vw o' +
  ' where (o.status between ''N'' and ''Q'') and o.type = ''I'' and o.load_no = 0 '

select @where = '', @order_where = '', @where2 = '',
  @adm_cust_all_where = '', @sort_order_by = '', @group_sel = '', @sort_grp_order_by = '',
  @group_cmd = '', @sort_grp = '', @sort_grp_select = '',
  @sort_grp_where = '', @group_where = '', @group_order_by = '',
  @group_label = ''

-- read selections made on the filter screen

DECLARE filterc CURSOR LOCAL FOR
SELECT lower(selection_name), group_ind, sort_order, sort_desc_ind, 
  selection_ind, start_value, stop_value, data_type, case when sort_order > 0 then 0 else 1 end 'sort_ind'
from adm_shipment_fill_filter
where batch_name = @batch_name 
order by sort_ind,sort_order, rcd_ord

OPEN filterc
FETCH NEXT FROM filterc INTO
  @sel_name, @group_ind, @sort_order, @sort_desc_ind, @sel_ind, @start, @stop, @data_type, @sort_ind

While @@FETCH_STATUS = 0
begin
  select @batch_found = 1, @adm_cust_all_ind = 0
  select @where = '', @sel_col = ''

  if @sel_name = 'customer code'
  begin
    select @sel_col = 'cust_code'
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 8 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 8 ) else substring(ltrim(@stop),1, 8 ) end
  end
  if @sel_name = 'ship to'
  begin
    select @sel_col = 'ship_to'
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 8 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 8 ) else substring(ltrim(@stop),1, 8 ) end
  end
  if @sel_name = 'order number'
  begin
    select @sel_col = 'order_no'
    select @start_i = case when IsNumeric(@start) = 1 then @start else 1 end
    select @stop_i = case when IsNumeric(@stop) = 1 then @stop else 1000000000 end
  end
  if @sel_name = 'sales order priority'
  begin
    select @sel_col = 'so_priority_code'
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 1 ) end
    select @stop_s = case when @stop = '<Last>' then char(255) else substring(ltrim(@stop),1, 1 ) end
  end
  if @sel_name = 'salesperson'
  begin
    select @sel_col = 'salesperson'
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 8 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 8 ) else substring(ltrim(@stop),1, 8 ) end
  end
  if @sel_name = 'territory code'
  begin
    select @sel_col = 'ship_to_region'
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 8 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 8 ) else substring(ltrim(@stop),1, 8 ) end
  end
  if @sel_name = 'customer sort code1'
  begin
    select @sel_col = 'addr_sort1'
    select @adm_cust_all_ind = 1
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 40 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 40 ) else substring(ltrim(@stop),1, 40 ) end
  end
  if @sel_name = 'customer sort code2'
  begin
    select @sel_col = 'addr_sort2'
    select @adm_cust_all_ind = 1
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 40 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 40 ) else substring(ltrim(@stop),1, 40 ) end
  end
  if @sel_name = 'customer sort code3'
  begin
    select @sel_col = 'addr_sort3'
    select @adm_cust_all_ind = 1
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 40 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 40 ) else substring(ltrim(@stop),1, 40 ) end
  end
  if @sel_name = 'order date'
  begin
    select @sel_col = 'date_entered'
    select @start_t = case when IsDate(@start) = 1 then @start else '01/01/1900' end
    select @stop_t = case when IsDate(@stop) = 1 then @stop else '12/31/2100' end
  end
  if @sel_name = 'delivery date'
  begin
    select @sel_col = 'req_ship_date'
    select @start_t = case when IsDate(@start) = 1 then @start else '01/01/1900' end
    select @stop_t = case when IsDate(@stop) = 1 then @stop else '12/31/2100' end
  end
  if @sel_name = 'sch ship date'
  begin
    select @sel_col = 'sch_ship_date'
    select @start_t = case when IsDate(@start) = 1 then @start else '01/01/1900' end
    select @stop_t = case when IsDate(@stop) = 1 then @stop else '12/31/2100' end
  end
  if @sel_name = 'percent fillable'
  begin
    select @sel_col = 'percent_fillable'
    select @start_d = case when IsNumeric(@start) = 1 then convert(decimal(20,8),@start) else 0 end
    select @stop_d = case when IsNumeric(@stop) = 1 then convert(decimal(20,8),@stop) else 100 end
    select @percent_fill_s = @start_d / 100, @percent_fill_e = @stop_d / 100
  end
  if @sel_name = 'currency code'
  begin
    select @sel_col = 'curr_key'
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 8 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 8 ) else substring(ltrim(@stop),1, 8 ) end
  end
  if @sel_name = 'back order flag'
  begin
    select @sel_col = 'back_ord_flag'
    select @start_s = case when @start = '<First>' then '0'  else substring(ltrim(@start),1, 1 ) end
    select @stop_s = case when @stop = '<Last>' then '2' else substring(ltrim(@stop),1, 1 ) end
  end
  if @sel_name = 'order organization'
  begin
    select @sel_col = 'organization_id'
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 10 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 10 ) else substring(ltrim(@stop),1, 10 ) end
  end
  if @sel_name = 'order location'
  begin
    select @sel_col = 'location'
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 10 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 10 ) else substring(ltrim(@stop),1, 10 ) end
  end
  if @sel_name = 'route code'
  begin
    select @sel_col = 'route_code'
    select @adm_cust_all_ind = 1
    select @start_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 10 ) end
    select @stop_s = case when @stop = '<Last>' then replicate(char(255), 10 ) else substring(ltrim(@stop),1, 10 ) end
  end
  if @sel_name = 'route number'
  begin
    select @sel_col = 'route_no'
    select @adm_cust_all_ind = 1
    select @start_i = case when IsNumeric(@start) = 1 then @start else 0 end
    select @stop_i = case when IsNumeric(@stop) = 1 then @stop else 1000000000 end
  end  
  if @sel_name = 'order status'
  begin
    select @sel_col = 'status'
    select @start_s = case when @start = '<First>' then 'N' else substring(ltrim(@start),1, 1 ) end
    select @stop_s = case when @stop = '<Last>' then 'Q' else substring(ltrim(@stop),1, 1 ) end
  end  
  if @sel_name = 'part number'
  begin
    select @sel_col = ''
    select @part_i = @sel_ind
    select @part_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 30 ) end
    select @part_e = case when @stop = '<Last>' then replicate(char(255), 30 ) else substring(ltrim(@stop),1, 30 ) end
  end
  if @sel_name = 'location'
  begin
    select @sel_col = ''
    select @loc_i = @sel_ind
    select @loc_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 10 ) end
    select @loc_e = case when @stop = '<Last>' then replicate(char(255), 10 ) else substring(ltrim(@stop),1, 10 ) end
  end
  if @sel_name = 'organization'
  begin
    select @sel_col = ''
    select @org_i = @sel_ind
    select @org_s = case when @start = '<First>' then '' else substring(ltrim(@start),1, 10 ) end
    select @org_e = case when @stop = '<Last>' then replicate(char(255), 10 ) else substring(ltrim(@stop),1, 10 ) end
  end

  if @sel_name = 'backorders only'
  begin
    select @sel_col = 'backorders_only'
  end

  if @sel_col != ''
  begin
    select @sort_col = ''
    -- if the selection is to be sorted by or grouped by - create the value for the sort column
    if @sort_order > 0 or @group_ind > 0
    begin
      if @data_type = 'C'
        select @sort_col = ' isnull(' + @sel_col + ','''')'
      if @data_type = 'I'
        select @sort_col = ' replicate(0,12-datalength(convert(varchar(11),' + 
        'isnull(' + @sel_col + ',0)))) + ' +
        'convert(varchar(10),isnull(' + @sel_col + ',0))' 
      if @data_type = 'T'
        select @sort_col = ' convert(varchar(10),isnull(' + @sel_col + 
          ',''1/1/1900''),102)'
       
      if @sel_col = 'percent_fillable'
        select @sort_col = 
          ' replicate(0,12-datalength(convert(varchar(11),floor(percent_fillable * 10)))) + ' +
          'convert(varchar(11),floor(percent_fillable * 10))'


      if @sel_col = 'order_no'
      begin
        select @sort_col = @sort_col + 
          '+ replicate(0,12-datalength(convert(varchar(11),ext))) + ' +
          'convert(varchar(10),ext)'
      end
    end

    -- if the selection is to be sorted by
    if @sort_order > 0
    begin
      select @sort_cnt = @sort_cnt + 1

      if @sort_cnt > 1  
      begin
        select @sort_order_by = @sort_order_by + ', '
        select @sort_grp_select = @sort_grp_select + ', '
        select @sort_grp_where = @sort_grp_where + ' and'
        select @sort_grp_order_by = @sort_grp_order_by + ', '
      end

      if @sel_col = 'percent_fillable'  select @sort_percent = @sort_cnt

--    sort cmd = order by 
      select @sort_order_by = @sort_order_by + @sel_col + 
        case when @sort_desc_ind = 1 then ' desc' else '' end

      if @sel_col = 'order_no'
        select @sort_order_by = @sort_order_by + ',ext' + case when @sort_desc_ind = 1 
          then ' desc' else '' end 

--    sort sel = select statement to populate group table

      select @sort_grp_select = @sort_grp_select + @sort_col

--    sort_grp_where = where statement to update batch from group with group #
      select @sort_grp_where = @sort_grp_where + '(' + @sort_col
      select @sort_grp_where = @sort_grp_where + '=val' + 
        replicate('0',case when @sort_cnt > 9 then 0 else 1 end) + 
        convert(varchar(2),@sort_cnt) + ')'
      select @sort_grp_order_by = @sort_grp_order_by + @sort_col +
        case when @sort_desc_ind = 1 then ' desc' else '' end
    end

    -- if the selection check box is unchecked, use the from and to data ranges 
    if @sel_ind = 0 and @sel_col != 'backorders_only'
    begin
      if @data_type = 'C'
      begin
        select @where = '(isnull(o.' + @sel_col + ','''') between ''' + @start_s + ''' and ''' + @stop_s + ''')'
      end
      if @data_type = 'I'
      begin
        select @where = '(isnull(o.' + @sel_col + ',0) between ' + convert(varchar(11), @start_i) + ' and ' + convert(varchar(11), @stop_i) + ')'
      end
      if @data_type = 'T'
      begin
        select @where = '(isnull(o.' + @sel_col + ',''1/1/1900'') between ''' + convert(varchar(10),@start_t,101) + 
          ''' and ''' + convert(varchar(10),@stop_t,101) + ''')'
      end
    end

    -- if the selection check box is checked for backorders only, only include ext > 1
    if @sel_ind = 1 and @sel_col = 'backorders_only'
    begin
      select @where = '(ext >= 1)'
    end

    if @where != '' and @adm_cust_all_ind = 0
      select @order_where = @order_where + ' and ' + @where

    if @where != '' and @adm_cust_all_ind = 1 
    begin
      if @adm_cust_all_where != '' select @where = ' and ' + @where
      select @adm_cust_all_where = @adm_cust_all_where + @where
    end

    -- if we are to group by the selection 
    if @group_ind > 0
    begin
      select @grp_cnt = @grp_cnt + 1

      if @grp_cnt > 1
      begin
        select @group_sel = @group_sel + ','
        select @group_where = @group_where + ' and'
        select @group_order_by = @group_order_by + ', '
        select @group_label = @group_label + ' + '
      end

--    group_sel =  select statement to populate group table

      if @sel_name = 'order status'
      begin
	select @group_where = @group_where + '(' +
          'case ' + @sort_col + 'when ''P'' then ''Picked'' when ''Q'' then ''Printed'' else ''New'' end'
        select @sel_col = 'status_text'
        select @sort_col = 'status_text'
        select @group_label = @group_label + ' ''(status '' +' 
      end
      if @sel_name = 'back order flag'
      begin
	select @group_where = @group_where + '(' +
          'case ' + @sort_col + 'when ''0'' then ''Allow Backorder'' when ''1'' then ''Ship Complete'' when ''2'' ' +
          ' then ''Allow Partial'' else ' + @sort_col + ' end'
        select @sel_col = 'bo_text'
        select @sort_col = 'bo_text'
        select @group_label = @group_label + ' ''('' +' 
      end
      if not (@sel_name in ('order status','back order flag'))
      begin
        select @group_where = @group_where + '(' + @sort_col
        select @group_label = @group_label + ' ''(' +
          @sel_name + ' '' + '
      end

      select @group_sel = @group_sel + @sort_col
      select @group_order_by = @group_order_by + @sort_col 

--    sort_grp_where = where statement to update batch from group with group #
      select @group_where = @group_where + '=val' + replicate('0',case when @grp_cnt < 10 then 1 else 0 end) + convert(varchar(2),@grp_cnt) + ')'
      if @sort_desc_ind = 1
        select @group_order_by = @group_order_by + ' desc'


      if @data_type = 'C'
        select @group_label = @group_label + ' isnull(' + @sel_col + ','''')'
      if @data_type = 'I'
        select @group_label = @group_label + 'convert(varchar(10),isnull(' + @sel_col + ',0))' 
      if @data_type = 'T'
        select @group_label = @group_label + ' convert(varchar(10),isnull(' + @sel_col + 
          ',''1/1/1900''),101)'
       
      if @sel_col = 'percent_fillable'
        select @group_label = @group_label +
          'convert(varchar(11),floor(percent_fillable * 10)*10)' + '+ ''%'''


      if @sel_col = 'order_no'
      begin
        select @group_label = @group_label + 
          '+ ''-'' + convert(varchar(10),ext)'
      end

      select @group_label = @group_label + '+ '') '''
    end
  end

  FETCH NEXT FROM filterc INTO
    @sel_name, @group_ind, @sort_order, @sort_desc_ind, @sel_ind, @start, @stop, @data_type, @sort_ind
end

close filterc
deallocate filterc

if @sort_cnt > 0 
begin
  select @sort_order_by = 'order by ' + @sort_order_by
  select @sort_grp = @sort_grp_select
  select @sort_grp_select = @sort_grp_select + replicate(',''''',20-@sort_cnt)
end
if @grp_cnt > 0 
begin
  select @group_cmd = @group_sel
  select @group_sel = @group_sel + replicate(',''''',20-@grp_cnt)
end

select @where = ''
select @where = ' and exists (select 1 from ord_list l (nolock) '
select @where = @where + 'where l.order_no = o.order_no and l.order_ext = o.ext'
select @where = @where + ' and l.location not like ''DROP%'''

if (@part_i = 0 or @loc_i = 0 or @org_i = 0)
begin
  if @part_i = 0   select @where = @where + ' and (l.part_no between ''' + @part_s + ''' and ''' + @part_e + ''')'
  if @loc_i = 0 select @where = @where + ' and (l.location between ''' + @loc_s + ''' and ''' + @loc_e + ''')'
  if @org_i = 0 select @where = @where + ' and (isnull(l.organization_id,'''') between ''' + @org_s + ''' and ''' + @org_e + ''')'
end 
select @where = @where + ')'

exec (@insert_cmd + @order_where + @where + @sort_order_by)

select @where = ''
if (@percent_fill_s > 0 or @percent_fill_e < 1) and (@part_i = 0 or @loc_i = 0 or @org_i =0)
begin
  if @part_i = 0   select @where = @where + ' and (s.part_no between ''' + @part_s + ''' and ''' + @part_e + ''')'
  if @loc_i = 0 select @where = @where + ' and (s.location between ''' + @loc_s + ''' and ''' + @loc_e + ''')'
  if @org_i = 0 select @where = @where + ' and (isnull(l.organization_id,'''') between ''' + @org_s + ''' and ''' + @org_e + ''')'
end

update #temp_batch
set addr_sort1 = isnull(a.addr_sort1,''), addr_sort2 = isnull(a.addr_sort2,''), 
addr_sort3 = isnull(a.addr_sort3,''),
route_code = isnull(a.route_code,''), route_no = isnull(a.route_no,0)
from adm_shipto_all a
where a.customer_code = #temp_batch.cust_code and a.ship_to_code = #temp_batch.ship_to

update #temp_batch
set addr_sort1 = isnull(a.addr_sort1,''), addr_sort2 = isnull(a.addr_sort2,''), 
addr_sort3 = isnull(a.addr_sort3,''),
route_code = isnull(a.route_code,''), route_no = isnull(a.route_no,0)
from adm_cust_all a
where a.customer_code = #temp_batch.cust_code and #temp_batch.ship_to = ''	-- mls 1/22/03 SCR 30558

if @adm_cust_all_where != ''
begin
  select @adm_cust_all_where = @adm_cust_all_where + ')'
  select @update_cmd = 'update #temp_batch set checked = -1 from adm_shipto_all s, #temp_batch o' + 
    ' where s.customer_code = o.cust_code and s.ship_to_code = o.ship_to and not ('

  exec (@update_cmd + @adm_cust_all_where)

  select @update_cmd = 'update #temp_batch set checked = -1 from adm_cust_all s, #temp_batch o' +
    ' where s.customer_code = o.cust_code and o.checked = 0 and not ('

  exec (@update_cmd + @adm_cust_all_where)
end

delete from #temp_batch where checked = -1
-- group the orders by the sort so that availability will be checked based on each break
-- in the selected sort. If the percent fillable is the first sort item, check
-- availablilty across all orders.

if @sort_cnt > 0 and @sort_percent != 1
begin
  select @insert_cmd = 'insert #group ' +
    '(val01,val02,val03,val04,val05,val06,val07,val08,val09,val10,val11,val12,' +
    'val13,val14,val15,val16,val17,val18,val19,val20) select '
  exec (@insert_cmd + @sort_grp_select + ' from #temp_batch group by ' + @sort_grp + ' order by ' + @sort_grp_order_by)

  select @update_cmd = 'update #temp_batch ' + 
    'set group_no = g.group_no ' +
    'from #group g where '

  exec (@update_cmd + @sort_grp_where)
end



select @insert_cmd = 'insert #batch ' +
  '(group_no,order_no, ext, cust_code, ship_to, so_priority_code, salesperson, ship_to_region, addr_sort1, addr_sort2, addr_sort3,' +
  'date_entered, req_ship_date, sch_ship_date, percent_fillable, curr_key, back_ord_flag, location, route_code,' +
  'route_no, backorders_only, status, organization_id) ' + 
  'select group_no,order_no, ext, cust_code, ship_to, so_priority_code, salesperson, ship_to_region, addr_sort1, addr_sort2, addr_sort3,' +
  'date_entered, req_ship_date, sch_ship_date, percent_fillable, curr_key, back_ord_flag, location, route_code,' +
  'route_no, backorders_only, status, organization_id from #temp_batch ' 

exec (@insert_cmd + @sort_order_by)

insert #command values ('group_cmd',@group_cmd)
insert #command values ('group_sel',@group_sel)
insert #command values ('group_where',@group_where)
insert #command values ('group_order_by',@group_order_by)
insert #command values ('sort_order_by',@sort_order_by)
insert #command values ('fillable_where',@where)
insert #command values ('group_label',@group_label)

return 1
END
GO
GRANT EXECUTE ON  [dbo].[adm_group_shipfill_order] TO [public]
GO
