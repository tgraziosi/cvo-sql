SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ins_ord_rel] @ord_no int, @ext int out
as

declare  @rc int, @line_no int,
  @part_sort varchar(255), @lrow int, @ordered decimal(20,8),
  @part_no varchar(30), @part_type char(1), @location varchar(10),
  @conv_factor decimal(20,8), @rel_row_id int, @sch_ship_date datetime,
  @done int , @blanket_ext int

if not exists (select 1 from #ins_ord_list_rel where list_ind = 0)
  return 2

select @line_no = 0, @blanket_ext = 0
select @sch_ship_date = isnull((select min(sch_ship_date) from #ins_ord_list_rel),NULL)
while @sch_ship_date is not null
begin
set @done = 0


select @lrow = isnull((select min(row_id) from #ins_ord_list_rel where sch_ship_date = @sch_ship_date ),NULL)
while @lrow is not null
begin
  select 
    @rel_row_id = rel_row_id,
    @ordered = ordered
  from #ins_ord_list_rel where sch_ship_date = @sch_ship_date and row_id = @lrow

  if @@error <> 0 return -8
 
  if @ordered != 0
  begin
    if @done = 0
    begin
      exec @rc = adm_ins_order_hdr 2, @rel_row_id, @ord_no, @blanket_ext output

      if @rc < 1
      begin
        select @rc, 'Error creating blanket release record'
        return
      end
      set @done = 1
    end

    exec @rc = adm_ins_ord_list 2, @ord_no, @blanket_ext, @rel_row_id 
  end -- ordered != 0


select @lrow = isnull((select min(row_id) from #ins_ord_list_rel where sch_ship_date = @sch_ship_date and row_id > @lrow),NULL)
end
select @sch_ship_date = isnull((select min(sch_ship_date) from #ins_ord_list_rel where sch_ship_date > @sch_ship_date),NULL)
end

select @ext = @blanket_ext
return 1
GO
GRANT EXECUTE ON  [dbo].[adm_ins_ord_rel] TO [public]
GO
