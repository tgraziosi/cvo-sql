SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_find_inv_loc_org_sp] @part_no varchar(30), @location varchar(10), @mode varchar(10),
  @curr_key varchar(10), @ls_no_drop varchar(10), @status char(1), @org_id varchar(30) AS
BEGIN		
  set nocount on
  declare @loc2 varchar(10)

  if lower(@mode) = 'next'
  begin
    select @loc2 = isnull((SELECT MIN( location )
		 FROM inv_list l (nolock)
         join inv_master m (nolock) on m.part_no = l.part_no and m.status <= @status
		WHERE l.part_no = @part_no and l.location > @location  and  l.location not like @ls_no_drop  
          and l.location in (select location from locations_all (nolock) 
          where isnull(organization_id,'') = @org_id)),'')

	if @loc2 = '' set @mode = 'last'
  end 

  if lower(@mode) = 'prev'
  begin
    select @loc2 = isnull((SELECT MAX( location )
		 FROM inv_list l (nolock)
         join inv_master m (nolock) on m.part_no = l.part_no and m.status <= @status
		WHERE l.part_no = @part_no and l.location < @location  and  l.location not like @ls_no_drop  
          and l.location in (select location from locations_all (nolock) 
          where isnull(organization_id,'') = @org_id)),'')

	if @loc2 = '' set @mode = 'first'
  end

	if lower(@mode) = 'first'
      select @loc2 = isnull((SELECT MIN( location )
		 FROM inv_list l (nolock)
         join inv_master m (nolock) on m.part_no = l.part_no and m.status <= @status
		WHERE l.part_no = @part_no and  l.location not like @ls_no_drop  
          and l.location in (select location from locations_all (nolock) 
          where isnull(organization_id,'') = @org_id)),'')

	if lower(@mode) = 'last'
      select @loc2 = isnull((SELECT Max( location )
		 FROM inv_list l (nolock)
         join inv_master m (nolock) on m.part_no = l.part_no and m.status <= @status
		WHERE l.part_no = @part_no and  l.location not like @ls_no_drop  
          and l.location in (select location from locations_all (nolock) 
          where isnull(organization_id,'') = @org_id)),'')

	if lower(@mode) = 'get_void'
      select @loc2 = isnull((SELECT MIN( location )
		 FROM inv_list l (nolock)
         join inv_master m (nolock) on m.part_no = l.part_no and m.status <= @status
		WHERE l.part_no = @part_no and l.location = @location and l.location not like @ls_no_drop  
          and l.location in (select location from locations_all (nolock) 
          where isnull(organization_id,'') = @org_id)),'')

	if lower(@mode) = 'get'
      select @loc2 = isnull((SELECT MIN( location )
		 FROM inv_list l (nolock)
         join inv_master m (nolock) on m.part_no = l.part_no and m.status <= @status
		WHERE l.part_no = @part_no and l.location = @location and l.location not like @ls_no_drop  
          and l.location in (select location from locations_all (nolock) 
          where isnull(organization_id,'') = @org_id)),'')

	SELECT m.part_no, i.location, m.description, m.status, m.uom, m.lb_tracking, m.taxable, 
		m.cubic_feet, m.weight_ea, case isnull(i.acct_code,'') when '' then m.account else i.acct_code end account, 
        m.type_code, m.qc_flag, m.category, m.cfg_flag, m.allow_fractions,
		m.tax_code, m.min_profit_perc, m.tolerance_cd,
		pp.price_a, pp.price_b, pp.price_c, pp.price_d, pp.price_e, pp.price_f,
		i.cost, i.avg_cost, i.last_cost, i.std_cost,
		i.avg_direct_dolrs, i.avg_ovhd_dolrs, i.avg_util_dolrs, i.labor,
		i.std_direct_dolrs, i.std_ovhd_dolrs, i.std_util_dolrs, 
		i.min_order, i.min_stock, case isnull(i.note,'') when '' then m.note else i.note end note, i.bin_no, 
		i.eoq, i.hold_qty, i.hold_ord,
		i.hold_mfg, i.hold_rcv, i.hold_xfr, i.in_stock, i.serial_flag, i.inv_cost_method, 
		i.po_uom, i.organization_id,
		ppv.price_a o_price_a, ppv.price_b o_price_b, ppv.price_c o_price_c, ppv.price_d o_price_d, 
        ppv.price_e o_price_e, ppv.price_f o_price_f
	FROM inv_master m ( NOLOCK )
	left outer join part_price pp (nolock) on pp.part_no = m.part_no and pp.curr_key = @curr_key
	left outer join inventory i (nolock) on i.part_no = m.part_no and i.location = @loc2
	left outer join (SELECT  ppv.part_no, ppv.curr_key, price_a, price_b, price_c, price_d, price_e, price_f
		FROM	part_price_vw ppv ( NOLOCK )
		join (SELECT  part_no, curr_key, max(org_level)
			FROM	part_price_vw pp ( NOLOCK )
			WHERE (org_level = 0 or (org_level = 1 and loc_org_id = @org_id) or 
			(org_level = 2 and loc_org_id = @org_id))
			group by part_no, curr_key)
			as mp (part_no, curr_key, org_level) on ppv.part_no = mp.part_no and ppv.curr_key = mp.curr_key
			and ppv.org_level = mp.org_level)
		as ppv (part_no, curr_key,price_a, price_b, price_c, price_d, price_e, price_f) 
		on ppv.part_no = m.part_no and ppv.curr_key = @curr_key
	WHERE m.part_no = @part_no
END
GO
GRANT EXECUTE ON  [dbo].[adm_find_inv_loc_org_sp] TO [public]
GO
