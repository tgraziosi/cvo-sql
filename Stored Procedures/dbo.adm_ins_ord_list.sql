SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_ins_ord_list] @mode int, @ord_no int, @ext int , @row_id int = 0
as

-- @mode
-- 1 = regular order
-- 2 = blanket ext

declare  @rc int, @line_no int,
  @part_sort varchar(255), @lrow int, @ordered decimal(20,8),
  @part_no varchar(30), @part_type char(1), @location varchar(10),
  @conv_factor decimal(20,8), @rel_row_id int, @cust_po varchar(40), @status char(1),
  @price decimal(20,8)

if @mode = 1
begin
select @line_no = 0
select @part_sort = isnull((select min(part_sort) from #ins_ord_list_rel where list_ind = 1),NULL)
while @part_sort is not null
begin
select @lrow = isnull((select min(row_id) from #ins_ord_list_rel where list_ind = 1 and part_sort = @part_sort ),NULL)
while @lrow is not null
begin
  select @ordered = isnull((select sum(ordered) from #ins_ord_list_rel where part_sort = @part_sort),0)    
  select @part_type = part_type,
    @location = location,
    @conv_factor = conv_factor,
    @part_no = part_no ,
    @rel_row_id = rel_row_id,
    @price = price 
  from #ins_ord_list_rel where list_ind = 1 and part_sort = @part_sort and row_id = @lrow

  if @@error <> 0 return -8
 
  if @ordered != 0
  begin
    select @line_no = @line_no + 1
    if @part_type not in ('M','J','E','X')
    begin
      insert ord_list (
      order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,
      price_type,note,status,cost,who_entered,sales_comm,temp_price,temp_type,cr_ordered,
      cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,
      lb_tracking,labor,direct_dolrs,ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,
      qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,
      curr_price,oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,
      reference_code,contract,agreement_id,ship_to,service_agreement_flag,inv_available_flag,
      create_po_flag,load_group_no,return_code,user_count, cust_po)
      select 
      @ord_no, @ext, @line_no, t.location, t.part_no, t.description, getdate(), @ordered, 0, 
	case when o.curr_factor >= 0 then (t.price * o.curr_factor) else (t.price / abs(curr_factor)) end,
      'Y', t.note, o.status, 
      case when isnull(i.inv_cost_method,'S') = 'S' then isnull(i.std_cost,0) else i.avg_cost end, host_name(), 0, t.price, 'Y', 0,
      0, t.discount, t.uom, t.conv_factor, 'N', NULL, NULL, 0, isnull(i.cubic_feet,0), 'N',
      isnull(i.lb_tracking,'N'), 0, 
      case when isnull(i.inv_cost_method,'S') = 'S' then isnull(i.std_direct_dolrs,0) else i.avg_direct_dolrs end,
      case when isnull(i.inv_cost_method,'S') = 'S' then isnull(i.std_ovhd_dolrs,0) else i.avg_ovhd_dolrs end,
      case when isnull(i.inv_cost_method,'S') = 'S' then isnull(i.std_util_dolrs,0) else i.avg_util_dolrs end,
      isnull(i.taxable,1), isnull(i.weight_ea,0), 'N', NULL, 
      0, 0, case when isnull(i.status,'M') = 'V' then 'V' when isnull(i.status,'M') = 'C' then 'C' else t.part_type end, 
      t.orig_part_no, t.back_ord_flag, t.gl_rev_acct, 0, t.tax_code,
      t.price, 
      case when o.oper_factor >= 0 then (t.price * o.oper_factor) else (t.price / abs(oper_factor)) end,
      @line_no, 0, 0, 0, 
      isnull(t.reference_code,''), NULL, NULL, NULL, 'N', 'Y', 
      case when case when isnull(i.status,'M') = 'V' then 'V' when isnull(i.status,'M') = 'C' then 'C' else t.part_type end = 'C' then 0
        else isnull(t.create_po_ind,0) end, 0, NULL, 0, t.cust_po
    from #ins_ord_list_rel t, inventory i (nolock), orders_all o (nolock)
    where t.part_no = i.part_no and t.location = i.location and o.order_no = @ord_no and o.ext = @ext
    and t.list_ind = 1 and t.part_sort = @part_sort and t.row_id = @lrow 

    if @@rowcount = 0
    begin
      return -8
    end      

    if exists (select 1 from inv_master where part_no = @part_no and status = 'C') 
    begin
      insert ord_list_kit (
        order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,
        cr_ordered,cr_shipped,uom,conv_factor,cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,
        qty_per,qc_flag,qc_no,description)
      select @ord_no, @ext, @line_no, @location, w.part_no, 'P', @ordered, 0, o.status, m.lb_tracking,
        0, 0, w.uom, @conv_factor, 0, 0, 0, 0, 0, NULL,
        w.qty, 'N', 0, m.description
      from what_part w
      join orders_all o (nolock) on o.order_no = @ord_no and o.ext = @ext
      left outer join inv_master m (nolock) on w.part_no = m.part_no
      where w.active < 'C' and (w.location = 'ALL' or w.location = @location) and w.asm_no = @part_no
     
      if @@error <> 0 return -8
    end
  end
  else
  begin
      insert ord_list (
      order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,
      price_type,note,status,cost,who_entered,sales_comm,temp_price,temp_type,cr_ordered,
      cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,
      lb_tracking,labor,direct_dolrs,ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,
      qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,
      curr_price,oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,
      reference_code,contract,agreement_id,ship_to,service_agreement_flag,inv_available_flag,
      create_po_flag,load_group_no,return_code,user_count, cust_po)
      select 
      @ord_no, @ext, @line_no, t.location, t.part_no, t.description, getdate(), @ordered, 0, 
	case when o.curr_factor >= 0 then (t.price * o.curr_factor) else (t.price / abs(curr_factor)) end,
      'Y', t.note, o.status, 0, host_name(), 0, 0, NULL, 0,
      0, t.discount, t.uom, t.conv_factor, 'N', NULL, NULL, 0, 0, 'N','N', 0, 0,0,0,1,0, 'N', NULL, 
      0, 0, t.part_type, 
      t.orig_part_no, t.back_ord_flag, t.gl_rev_acct, 0, t.tax_code,
      t.price, 
      case when o.oper_factor >= 0 then (t.price * o.oper_factor) else (t.price / abs(oper_factor)) end,
      @line_no, 0, 0, 0, 
      isnull(t.reference_code,''), NULL, NULL, NULL, 'N', 'Y', 
      isnull(t.create_po_ind,0), 0, NULL, 0, t.cust_po
    from #ins_ord_list_rel t,  orders_all o (nolock)
    where o.order_no = @ord_no and o.ext = @ext 
    and t.list_ind = 1 and t.part_sort = @part_sort and t.row_id = @lrow 

    if @@rowcount = 0
    begin
      return -8
    end      
  end

  select @price = case when o.curr_factor >= 0 then (@price * o.curr_factor) 
     else (@price / abs(curr_factor)) end
    from orders_all o (nolock)
    where o.order_no = @ord_no and o.ext = @ext 

  update releases
  set int_order_no = @ord_no,
    int_ord_line = @line_no
  where row_id = @rel_row_id

  update l
  set unit_cost = @price,
    curr_cost = case when p.curr_factor >= 0 then (@price * p.curr_factor) 
     else (@price / abs(p.curr_factor)) end,
    oper_cost = case when p.oper_factor >= 0 then (@price * p.oper_factor) 
     else (@price / abs(p.oper_factor)) end
  from releases r 
  join pur_list l on l.po_no = r.po_no and l.line = r.po_line
  join purchase p on p.po_no = l.po_no
  where r.row_id = @rel_row_id

  end -- ordered != 0

select @lrow = isnull((select min(row_id) from #ins_ord_list_rel where list_ind = 1 and part_sort = @part_sort and row_id > @lrow),NULL)
end
select @part_sort = isnull((select min(part_sort) from #ins_ord_list_rel where list_ind = 1 and part_sort > @part_sort),NULL)
end
end

if @mode = 2
begin
  select @part_sort = part_sort ,
    @ordered = ordered,
    @cust_po = cust_po
  from #ins_ord_list_rel 
  where rel_row_id = @row_id

  if @@error <> 0 or @@rowcount = 0 return -8
 
  if @ordered != 0
  begin
    select @part_no = part_no
    from #ins_ord_list_rel where part_sort = @part_sort and list_ind = 1

    select @status = status
    from orders where order_no = @ord_no and ext = @ext

    select @line_no = line_no, @part_type = part_type
    from ord_list
    where order_no = @ord_no and order_ext = 0 and part_no = @part_no

    if @@rowcount = 0  return -10


      insert ord_list (
      order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,
      price_type,note,status,cost,who_entered,sales_comm,temp_price,temp_type,cr_ordered,
      cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,
      lb_tracking,labor,direct_dolrs,ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,
      qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,
      curr_price,oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,
      reference_code,contract,agreement_id,ship_to,service_agreement_flag,inv_available_flag,
      create_po_flag,load_group_no,return_code,user_count, cust_po)
      select 
      order_no,@ext,line_no,location,part_no,description,getdate(),@ordered,0,price,
      price_type,note,@status,cost,host_name(),sales_comm,temp_price,temp_type,cr_ordered,
      cr_shipped,discount,uom,conv_factor,'N',NULL,NULL,std_cost,cubic_feet,'N',
      lb_tracking,labor,direct_dolrs,ovhd_dolrs,util_dolrs,taxable,weight_ea,'N',reason_code,
      0,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,
      curr_price,oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,
      reference_code,contract,agreement_id,ship_to,service_agreement_flag,inv_available_flag,
      create_po_flag,load_group_no,return_code,user_count, @cust_po
      from ord_list
      where order_no = @ord_no and order_ext = 0 and line_no = @line_no

    if @@rowcount = 0
    begin
      return -8
    end      

    update releases
    set int_order_no = @ord_no,
      int_ord_line = @line_no
    where row_id = @row_id
  end -- ordered != 0
end

return 1
GO
GRANT EXECUTE ON  [dbo].[adm_ins_ord_list] TO [public]
GO
