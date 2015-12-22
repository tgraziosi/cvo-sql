SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_unpick_order] @order_no int, @order_ext int, @load_no int = 0, @who varchar(30),
  @online_call int = 0
as
BEGIN
  create table #t (order_no int, order_ext int, line_no int, shipped decimal(20,8), status char(1), printed char(1), printed_dt datetime, upd_ind int)
  create index t1_1 on #t(upd_ind, order_no, order_ext, line_no)

  set @load_no = isnull(@load_no,0)
  if @load_no > 0
  begin
    insert #t
    select ol.order_no, ol.order_ext, ol.line_no, ol.shipped, ol.status, ol.printed, ol.printed_dt, 
      case when ol.protect_line = 0 and ol.location not like 'DROP%' and ol.create_po_flag = 0 then 1 else 0 end
    from ord_list_ship_vw ol, load_master l, orders_all o
    where o.load_no = l.load_no and l.load_no = @load_no 
      and ol.order_no = o.order_no and ol.order_ext = o.ext and ol.status between 'P' and 'Q'
  end
  else
  begin
    insert #t
    select order_no, order_ext, line_no, shipped, status, printed, printed_dt, 
      case when ol.protect_line = 0 and ol.location not like 'DROP%' and ol.create_po_flag = 0 then 1 else 0 end
    from ord_list_ship_vw ol
    where ol.order_no = @order_no and ol.order_ext = @order_ext and ol.status between 'P' and 'Q'
  end

  delete lbs
  from lot_bin_ship lbs, #t t
  where lbs.tran_no = t.order_no and lbs.tran_ext = t.order_ext and lbs.line_no = t.line_no and t.upd_ind = 1
  
  update olk
  set shipped = 0
  from ord_list_kit olk, #t t
  where olk.order_no = t.order_no and olk.order_ext = t.order_ext and olk.line_no = t.line_no and t.upd_ind = 1

  update ol
  set printed = 'N', unpicked_dt =  case when t.shipped > 0 or t.printed > 'N' or ol.picked_dt is not null then getdate() else unpicked_dt end,
    printed_dt = NULL,
    picked_dt = NULL,
    who_unpicked_id = case when t.shipped > 0 or t.printed > 'N' or ol.picked_dt is not null then @who else who_unpicked_id end,
    who_picked_id = NULL,
    shipped = 0
  from ord_list_ship_vw ol, #t t
  where ol.order_no = t.order_no and ol.order_ext = t.order_ext and ol.line_no = t.line_no and t.upd_ind = 1

  if not exists (select 1 from #t ol where upd_ind = 0 and (printed = 'Q' or printed_dt is not null))
  begin
    if exists (select 1 from #t ol where upd_ind = 0 and shipped > 0)
    begin
      if @load_no > 0
        update load_master
        set status = 'P' where load_no = @load_no
      else
        update orders_all
        set status = 'P', printed = 'P'
        where order_no = @order_no and ext = @order_ext and status = 'Q'
    end
    else
    begin
      if @load_no > 0
        update load_master
        set status = 'N' where load_no = @load_no
      else
        update orders_all
        set status = 'N', printed = 'N'
        where order_no = @order_no and ext = @order_ext and status between 'P' and 'Q'
    end
  end

  if @online_call = 1
    select 1
end
GO
GRANT EXECUTE ON  [dbo].[adm_unpick_order] TO [public]
GO
