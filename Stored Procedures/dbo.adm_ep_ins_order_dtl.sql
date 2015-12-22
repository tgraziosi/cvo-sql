SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE procedure [dbo].[adm_ep_ins_order_dtl] @cust_code varchar(10), @cust_po varchar(20),
@line_no int, @location varchar(10), @part_no varchar(30), @ordered decimal(20,8),
@uom char(2), @note varchar(255), @gl_rev_acct varchar(32), @reference_code varchar(32)
as

declare @ord_no int,  @ord_ext int, @rc int, @ol_line int, 
  @conv_factor decimal(20,8), @std_uom char(2),
  @kit_ins int,
  @inv_org_id varchar(30),							-- mls 3/24/05
  @masked_gl_rev_acct varchar(32)
declare @chk_sku_ind int
declare @part_type char(1)

select @ord_no = 0, @rc = 1, @ol_line = 0
select @inv_org_id = isnull((select value_str from config (nolock) where flag = 'INV_ORG_ID'),'')

if exists (select 1 from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
  and ext = 0 and (status = 'N' or status < 'L') and isnull(eprocurement_ind,0) = 1)
begin
  if isnull((select count(*) from orders_all (nolock) where cust_po = @cust_po and cust_code = @cust_code
    and ext = 0 and (status = 'N' or status < 'L') and isnull(eprocurement_ind,0) = 1), 0) != 1
  begin
    return -2
  end

  select @ord_no = order_no,  @ord_ext = 0
  from orders_all 
  where cust_po = @cust_po and cust_code = @cust_code and ext = 0 and (status = 'N' or status < 'L')
    and isnull(eprocurement_ind,0) = 1

  if @@rowcount = 0
  begin
    return -3
  end

  set @chk_sku_ind = 0
  set @part_type = 'P'
  while 1=1
  begin
    select @part_no = part_no, @location = location
    from inv_sales (nolock)
    where part_no = @part_no and location = @location

    if @@rowcount > 0 break

    if @chk_sku_ind > 0 
    begin
      set @part_type = 'M'
      break
    end

    set @chk_sku_ind = 1

    select @part_no = sku_no
    from vendor_sku (nolock)
    where vend_sku = @part_no and vendor_no = @cust_code

    if @@rowcount = 0
    begin
      set @part_type = 'M'
      break
    end
   end

  select @masked_gl_rev_acct = @gl_rev_acct
--  select @masked_gl_rev_acct = dbo.IBAcctMask_fn(@gl_rev_acct,@inv_org_id)

  if not exists (select 1 FROM adm_glchart_all (nolock) 			-- mls 3/24/05 
    WHERE inactive_flag = 0 AND account_code = @masked_gl_rev_acct)
  begin
    return -5
  end

  if exists (select 1 from glrefact (nolock) where @masked_gl_rev_acct like account_mask and reference_flag > 1)
  begin
    if not exists (select 1 from glratyp t (nolock), glref r (nolock)
      where t.reference_type = r.reference_type and @masked_gl_rev_acct like t.account_mask and
              r.status_flag = 0 and r.reference_code  = @reference_code)
      select @reference_code = NULL, @rc = 3
  end
  else
    select @reference_code = NULL, @rc = 2

  select @conv_factor = 1
  if @part_type != 'M'
  begin
    select @std_uom = uom from inv_master where part_no = @part_no
    if isnull(@std_uom,'!!') != isnull(@uom,'@@')
    begin
      if @uom is null or @std_uom is null
      begin
        return -6
      end

      select @conv_factor = isnull((select conv_factor
      from uom_table where item = @part_no and alt_uom = @uom and std_uom = @std_uom),NULL)

      if @conv_factor is null
        select @conv_factor = isnull((select conv_factor
        from uom_table where item = 'STD' and alt_uom = @uom and std_uom = @std_uom),NULL)

      if @conv_factor is null
      begin
        return -7
      end
    end
  end
  else
  begin
    if @uom is NULL
      return -6
  end 

  select @ol_line = isnull((select line_no from ord_list (nolock) 
    where order_no = @ord_no and order_ext = 0 and line_no = @line_no),0)
 
  if @ol_line > 0
  begin
    if @ordered = 0
    begin
      delete ord_list
      where order_no = @ord_no and order_ext = 0 and line_no = @line_no

      delete ord_list_kit
      where order_no = @ord_no and order_ext = 0 and line_no = @line_no
    end
    else
    begin
      select @kit_ins = 0
      if not exists (select 1 from ord_list where order_no = @ord_no and order_ext = 0
        and line_no = @line_no and part_no = @part_no and location = @location)
      begin
        delete ord_list_kit
        where order_no = @ord_no and order_ext = 0 and line_no = @line_no

        if exists (select 1 from inv_master where part_no = @part_no and status = 'C') and @part_type = 'P'
          select @kit_ins = 1
      end

      if @part_type = 'P'
      begin
        update o
        set location = i.location,
          part_type = case when i.status = 'V' then 'V' when i.status= 'C' then 'C' else 'P' end,
          part_no = i.part_no,
          o.description = i.description,
          ordered = @ordered,
          uom = @uom,
          conv_factor = @conv_factor,
          note = @note,
          gl_rev_acct = @masked_gl_rev_acct,
          reference_code = case when gl_rev_acct = @masked_gl_rev_acct then isnull(@reference_code,reference_code) else 
            isnull(@reference_code,'') end
        from ord_list o, inventory i (nolock)
        where o.order_no = @ord_no and o.order_ext = 0 and o.line_no = @line_no
          and i.part_no = @part_no and i.location = @location

        if @@rowcount = 0
        begin
          return -8
        end      
      end
      else
      begin
        update o
        set location = i.location,
          part_type = 'M',
          part_no = @part_no,
          o.description = @part_no,
          ordered = @ordered,
          uom = @uom,
          conv_factor = @conv_factor,
          note = @note,
          gl_rev_acct = @masked_gl_rev_acct,
          reference_code = case when gl_rev_acct = @masked_gl_rev_acct then isnull(@reference_code,reference_code) else 
            isnull(@reference_code,'') end
        from ord_list o, locations_all i (nolock) 
        where o.order_no = @ord_no and o.order_ext = 0 and o.line_no = @line_no
          and i.location = @location

        if @@rowcount = 0
        begin
          return -8
        end      
      end

      if @kit_ins = 1
      begin
        insert ord_list_kit (
          order_no,order_ext,line_no,location,part_no,part_type,ordered,shipped,status,lb_tracking,
          cr_ordered,cr_shipped,uom,conv_factor,cost,labor,direct_dolrs,ovhd_dolrs,util_dolrs,note,
          qty_per,qc_flag,qc_no,description)
        select @ord_no, 0, @line_no, @location, w.part_no, 'P', @ordered, 0, 'N', m.lb_tracking,
          0, 0, w.uom, 1, 0, 0, 0, 0, 0, NULL,
          w.qty, 'N', 0, m.description
        from what_part w
        left outer join inv_master m (nolock) on  w.part_no = m.part_no 
        where w.active < 'C' and (w.location = 'ALL' or w.location = @location) and w.asm_no = @part_no
      end
    end
  end
  else
  begin
    if @ordered != 0
    begin
    if @part_type = 'P'
    begin

    insert ord_list (
      order_no,order_ext,line_no,location,part_no,description,time_entered,ordered,shipped,price,
      price_type,note,status,cost,who_entered,sales_comm,temp_price,temp_type,cr_ordered,
      cr_shipped,discount,uom,conv_factor,void,void_who,void_date,std_cost,cubic_feet,printed,
      lb_tracking,labor,direct_dolrs,ovhd_dolrs,util_dolrs,taxable,weight_ea,qc_flag,reason_code,
      qc_no,rejected,part_type,orig_part_no,back_ord_flag,gl_rev_acct,total_tax,tax_code,
      curr_price,oper_price,display_line,std_direct_dolrs,std_ovhd_dolrs,std_util_dolrs,
      reference_code,contract,agreement_id,ship_to,service_agreement_flag,inv_available_flag,
      create_po_flag,load_group_no,return_code,user_count
    )
    select 
      @ord_no, 0, @line_no, i.location, i.part_no, i.description, getdate(), @ordered, 0, 0,
      'Y', @note, 'N', 
      case when i.inv_cost_method = 'S' then i.std_cost else i.avg_cost end, 'eprocurement', 0, 0, NULL, 0,
      0, 0, @uom, @conv_factor, 'N', NULL, NULL, 0, i.cubic_feet, 'N',
      i.lb_tracking, 0, case when i.inv_cost_method = 'S' then i.std_direct_dolrs else i.avg_direct_dolrs end,
      case when i.inv_cost_method = 'S' then i.std_ovhd_dolrs else i.avg_ovhd_dolrs end,
      case when i.inv_cost_method = 'S' then i.std_util_dolrs else i.avg_util_dolrs end,i.taxable, i.weight_ea, 'N', NULL, 
      0, 0, case when i.status = 'V' then 'V' when i.status = 'C' then 'C' else 'P' end, 
      i.part_no, 0, @masked_gl_rev_acct, 0, o.tax_id,
      0, 0, @line_no, 0, 0, 0, 
      isnull(@reference_code,''), NULL, NULL, NULL, 'N', 'Y', 
      0, 0, NULL, 0
    from inventory i (nolock), orders_all o (nolock)
    where i.part_no = @part_no and i.location = @location and o.order_no = @ord_no and o.ext = 0

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
      select @ord_no, 0, @line_no, @location, w.part_no, 'P', @ordered, 0, 'N', m.lb_tracking,
        0, 0, w.uom, 1, 0, 0, 0, 0, 0, NULL,
        w.qty, 'N', 0, m.description
      from what_part w
      left outer join inv_master m (nolock) on w.part_no = m.part_no
      where w.active < 'C' and (w.location = 'ALL' or w.location = @location) and w.asm_no = @part_no
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
      create_po_flag,load_group_no,return_code,user_count
    )
    select 
        @ord_no, 0, @line_no, i.location, @part_no, @part_no, getdate(), @ordered, 0, 0,
        'Y', @note, 'N', 
        0, 'eprocurement', 0, 0, NULL, 0,
        0, 0, @uom, @conv_factor, 'N', NULL, NULL, 0, 0, 'N',
        'N', 0, 0,
        0,
        0,1, 0, 'N', NULL, 
        0, 0, 'M', 
        @part_no, 0, @masked_gl_rev_acct, 0, o.tax_id,
        0, 0, @line_no, 0, 0, 0, 
        isnull(@reference_code,''), NULL, NULL, NULL, 'N', 'Y', 
        0, 0, NULL, 0
    from locations_all i (nolock), orders_all o (nolock)
    where i.location = @location and o.order_no = @ord_no and o.ext = 0

    if @@rowcount = 0
    begin
      return -8
    end      

    end
    end -- ordered != 0
  end
end
else
begin
  return -1
end

return @rc
GO
GRANT EXECUTE ON  [dbo].[adm_ep_ins_order_dtl] TO [public]
GO
