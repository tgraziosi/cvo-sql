SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[fs_cost_delete_misc] @part varchar(30), @loc varchar(10), @qty decimal(20,8),
  @tran_code char(1), @tran_no int, @tran_ext int, @tran_line int, @account varchar(10),
  @tran_date datetime, @tran_age datetime, @unitcost decimal(20,8) OUTPUT,
  @direct decimal(20,8) OUTPUT, @overhead decimal(20,8) OUTPUT,
  @labor decimal(20,8) OUTPUT, @utility decimal(20,8) OUTPUT AS
begin


declare @maxseq int, @wtnum int, @xlp int, @tqty decimal(20,8),
  @d1 datetime, @pull_qty decimal(20,8), @uc decimal(20,8), @d decimal(20,8),
  @o decimal(20,8), @l decimal(20,8), @u decimal(20,8), @jobno int, @convfactor decimal(20,8)
declare @prod_ext int, @cl_tran_code char(1),										-- mls 3/27/01 SCR 20667
  @prod_qty decimal(20,8),
  @p_mtrl_cost decimal(20,8), @p_dir_cost  decimal(20,8), @p_ovhd_cost  decimal(20,8),
  @p_util_cost decimal(20,8), 
  @cl_mtrl_cost decimal(20,8), @cl_dir_cost  decimal(20,8), @cl_ovhd_cost  decimal(20,8),
  @cl_util_cost decimal(20,8), @cl_labor_cost decimal(20,8),
  @ic_unit_cost decimal(20,8), @ic_direct_dolrs  decimal(20,8), @ic_ovhd_dolrs  decimal(20,8),
  @ic_util_dolrs decimal(20,8), @ic_labor decimal(20,8),
  @ic_tot_mtrl_cost decimal(20,8), @ic_tot_dir_cost  decimal(20,8), @ic_tot_ovhd_cost decimal(20,8),
  @ic_tot_util_cost decimal(20,8), @ic_tot_labor_cost decimal(20,8),
  @ic_tran_age datetime, @ic_audit int, @ic_org_cost decimal(20,8)

select @cl_tran_code = case when @tran_code = 'K' then 'S' else @tran_code end

IF (select sum(balance) from inv_costing where part_no=@part and location=@loc and account=@account) = @qty
begin
  select @unitcost = 0, @direct = 0, @overhead = 0, @utility = 0, @labor = 0

  if @tran_code='P' 
  begin
    select 
      @uc=sum(isnull(tot_mtrl_cost,unit_cost * balance)), 
      @d=sum(isnull(tot_dir_cost,direct_dolrs * balance)), 
      @o=sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),
      @u=sum(isnull(tot_util_cost,util_dolrs * balance)), 
      @l=sum(isnull(tot_labor_cost,labor * balance)) 
    from inv_costing 
    where part_no=@part and location=@loc and account=@account

    insert prod_list_cost (prod_no, prod_ext, line_no, part_no, cost, direct_dolrs,
      ovhd_dolrs, labor, util_dolrs, tran_date, qty, status,
      tot_mtrl_cost,tot_dir_cost,tot_ovhd_cost,tot_util_cost,tot_labor_cost)
    select @tran_no, @tran_ext, @tran_line, @part, @uc  / @qty,
      @d  / @qty, @o  /@qty, @l  /@qty,
      @u  /@qty, @tran_age, @qty , 'N',					-- mls 9/12/00 SCR 24159
      @uc, @d, @o, @u, @l
    if @@error > 0 return 0
  end

  delete inv_costing from inv_costing 
  where part_no=@part and location=@loc and account=@account
  
  if @tran_code='S' 
  begin
    update ord_list 
    set cost=0, direct_dolrs=0, ovhd_dolrs=0, labor=0, util_dolrs=0
    where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and 
      part_no=@part

    if @@error > 0 return 0
  end

  if @tran_code='K' 
  begin
    update ord_list_kit 
    set cost=0, direct_dolrs=0, ovhd_dolrs=0, labor=0, util_dolrs=0
    where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and 
      part_no=@part

    if @@error > 0 return 0
  end
  
  if @tran_code='X' 
  begin
    update xfer_list 
    set cost=0, direct_dolrs=0, ovhd_dolrs=0,labor=0, util_dolrs=0
    where xfer_no=@tran_no and line_no=@tran_line and part_no=@part 
    if @@error > 0 return 0
  end
  if @tran_code='I'
  begin
    update issues_all 
    set avg_cost=0, direct_dolrs=0, ovhd_dolrs=0 ,labor=0,util_dolrs=0
    where issue_no=@tran_no 
    if @@error > 0 return 0
  end

  return 1
end


if (@tran_code='S') 
begin
  select @jobno=isnull((select convert(int,ord_list.part_no) 
    from ord_list 
    where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_type='J'),0)

  if @jobno > 0 
  begin
    -- SCR 20667 Begin Changes
    -- Modify the following three update statements so that job does not get marked complete
    -- unless entire job has been shipped
    select @prod_ext = isnull((select max(prod_ext) from prod_list      		-- mls 3/27/01 SCR 20667
      where prod_no = @jobno and status != 'S'),0)							-- mls 3/27/01 SCR 20667

    update prod_list 
    set status='S' 
    where prod_no=@jobno and status != 'S' and direction=-1 and plan_qty = used_qty

    update prod_list 
    set status='S' 
    where prod_no=@jobno and status != 'S' and direction=1 and plan_qty = used_qty

    update produce_all 
    set status='S' 
    where prod_no=@jobno and status != 'S' and qty = qty_scheduled + scrapped 
    -- SCR 20667 End changes
    -- mls 36760 7/6/06 - make unitcost negative because it is a credit to inventory
    select @unitcost = -tot_avg_cost,
      @direct = -tot_direct_dolrs,
      @overhead = -tot_ovhd_dolrs,
      @labor = -tot_labor,
      @utility = -tot_util_dolrs,
      @prod_qty = qty
    from produce_all
    where prod_no = @jobno and prod_ext = @prod_ext

    select @unitcost = isnull(@unitcost,0), @direct = isnull(@direct,0),
      @overhead = isnull(@overhead,0), @labor = isnull(@labor,0),
      @utility = isnull(@utility,0), @prod_qty = isnull(@prod_qty,1)

	-- mls 3/6/08 - start - fix cost on backordered orders to be cost of produced since last order shipped
	if @prod_ext = 0 and @tran_ext > 0
	begin

	select @p_mtrl_cost = unitcost, @p_dir_cost = direct,
	@p_ovhd_cost = ovhd, @p_util_cost = util
	from
	(select sum(shipped * cost), sum(shipped* direct_dolrs),
	sum(shipped * ovhd_dolrs), sum(shipped* util_dolrs)
	from ord_list where order_no = @tran_no and order_ext < @tran_ext
	and part_no = convert(varchar(10), @jobno)) as c(unitcost, direct,ovhd, util)

	select @unitcost = @unitcost + isnull(@p_mtrl_cost,0),
		@direct = @direct + isnull(@p_dir_cost,0),
		@overhead = @overhead + isnull(@p_ovhd_cost,0),
		@utility = @utility + isnull(@p_util_cost,0)
	end

    -- mls 36760 7/6/06 - make uc positive to update ord_list table
    select @uc = -(@unitcost / @qty),
      @d = -(@direct / @qty),
      @o = -(@overhead / @qty),
      @l = -(@labor / @qty),
      @u = -(@utility / @qty) 
	-- mls 3/6/08 - end

    update ord_list 
    set cost=@uc, direct_dolrs = @d, ovhd_dolrs = @o, labor = @l, util_dolrs = @u
    from ord_list
    where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and shipped != 0
    if @@error > 0 return 0

    return 1
  end
end

select @uc=0, @d=0, @o=0, @l=0, @u=0, @pull_qty=@qty 
select @xlp=isnull((select max(sequence) from inv_costing 
  where part_no=@part and location=@loc and account=@account),0)

while @xlp > 0 
begin
  update inv_costing 
  set balance=balance 
  where part_no=@part and location=@loc and account=@account and @xlp=sequence

  if @@error > 0 return 0

  select @tqty=balance,
      @ic_unit_cost = unit_cost,
      @ic_direct_dolrs = direct_dolrs,
      @ic_ovhd_dolrs = ovhd_dolrs,
      @ic_labor = labor,
      @ic_util_dolrs = util_dolrs,
      @ic_tran_age = tran_age,
      @ic_audit = audit,
      @ic_org_cost = org_cost,
      @ic_tot_mtrl_cost = tot_mtrl_cost,
      @ic_tot_dir_cost = tot_dir_cost,
      @ic_tot_ovhd_cost = tot_ovhd_cost,
      @ic_tot_util_cost = tot_util_cost,
      @ic_tot_labor_cost = tot_labor_cost
  from inv_costing 
  where part_no=@part and location=@loc and account=@account and @xlp=sequence

  if @pull_qty >= @tqty 
  begin
    select @uc=@uc + isnull(@ic_tot_mtrl_cost,(@ic_unit_cost * @tqty)),
      @d=@d + isnull(@ic_tot_dir_cost,(@ic_direct_dolrs * @tqty)),
      @o=@o + isnull(@ic_tot_ovhd_cost,(@ic_ovhd_dolrs * @tqty)),
      @l=@l + isnull(@ic_tot_labor_cost,(@ic_labor * @tqty)),
      @u=@u + isnull(@ic_tot_util_cost,(@ic_util_dolrs * @tqty))
    from inv_costing 
    where part_no=@part and location=@loc and account=@account and @xlp=sequence
    
    insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,
      tran_ext,tran_line,account,tran_date,tran_age,unit_cost,quantity,
      inv_cost_bal,direct_dolrs,ovhd_dolrs,labor,util_dolrs, audit, org_cost,
      tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost)
    select @part,@loc,-1,@cl_tran_code,
      @tran_no,@tran_ext,@tran_line,@account,@tran_date,@ic_tran_age,@ic_unit_cost,@tqty,
      @tqty,@ic_direct_dolrs,@ic_ovhd_dolrs,@ic_labor,@ic_util_dolrs,@ic_audit, @ic_org_cost,
      @ic_tot_mtrl_cost, @ic_tot_dir_cost, @ic_tot_ovhd_cost, @ic_tot_util_cost, @ic_tot_labor_cost

    if @@error > 0 return 0

    delete inv_costing 
    where part_no=@part and location=@loc and account=@account and @xlp=sequence  
    if @@error > 0 return 0

    select @pull_qty=@pull_qty-@tqty
  end
  else 
  begin
    select @cl_mtrl_cost = (@ic_unit_cost * @pull_qty),
      @cl_dir_cost = (@ic_direct_dolrs * @pull_qty),
      @cl_ovhd_cost = (@ic_ovhd_dolrs * @pull_qty),
      @cl_labor_cost = (@ic_labor * @pull_qty),
      @cl_util_cost = (@ic_util_dolrs * @pull_qty)

    select @uc=@uc + @cl_mtrl_cost,
      @d=@d + @cl_dir_cost,
      @o=@o + @cl_ovhd_cost,
      @l=@l + @cl_labor_cost,
      @u=@u + @cl_util_cost
    
    insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,
      tran_ext,tran_line,account,tran_date,tran_age,unit_cost,quantity,
      inv_cost_bal,direct_dolrs,ovhd_dolrs,labor,util_dolrs, audit, org_cost,
      tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost)    
    select @part,@loc,-1,@cl_tran_code,
      @tran_no,@tran_ext,@tran_line,@account,@tran_date,@ic_tran_age,@ic_unit_cost,@pull_qty ,
      @tqty,@ic_direct_dolrs,@ic_ovhd_dolrs,@ic_labor,@ic_util_dolrs,@ic_audit,@ic_org_cost,
      @ic_tot_mtrl_cost, @ic_tot_dir_cost, @ic_tot_ovhd_cost, @ic_tot_util_cost, @ic_tot_labor_cost

    if @@error > 0 return 0

    select @ic_tot_mtrl_cost = @ic_tot_mtrl_cost - @cl_mtrl_cost,
      @ic_tot_dir_cost = @ic_tot_dir_cost - @cl_dir_cost,
      @ic_tot_ovhd_cost = @ic_tot_ovhd_cost - @cl_ovhd_cost,
      @ic_tot_util_cost = @ic_tot_util_cost - @cl_util_cost,
      @ic_tot_labor_cost = @ic_tot_labor_cost - @cl_labor_cost

    update inv_costing 
    set balance=balance - @pull_qty,
      tot_mtrl_cost = case when @ic_tot_mtrl_cost < 0 then 0 else @ic_tot_mtrl_cost end,
      tot_dir_cost = case when @ic_tot_dir_cost < 0 then 0 else @ic_tot_dir_cost end,
      tot_ovhd_cost = case when @ic_tot_ovhd_cost < 0 then 0 else @ic_tot_ovhd_cost end,
      tot_util_cost = case when @ic_tot_util_cost < 0 then 0 else @ic_tot_util_cost end,
      tot_labor_cost = case when @ic_tot_labor_cost < 0 then 0 else @ic_tot_labor_cost end
    where part_no=@part and location=@loc and account=@account and @xlp=sequence


    if @@error > 0 return 0

    select @pull_qty=0
  end  

  if @pull_qty > 0
  begin   
    select @xlp=isnull((select max(sequence) from inv_costing where part_no=@part and
      location=@loc and account=@account and tran_no=@tran_no and tran_ext=@tran_ext and
      tran_line=@tran_line and tran_code=@cl_tran_code),-1)
   
    if @xlp=-1 
    begin
      select @xlp=isnull((select max(sequence) from inv_costing where part_no=@part and
      location=@loc and account=@account),0)
    end
    if @@error > 0 return 0
  end
  else
   select @xlp=0
end 

select @convfactor=1
select @unitcost=@uc , @direct=@d , @overhead=@o ,  @labor=@l , @utility=@u 

if @tran_code='S' 
begin
  select @convfactor=null 
  select @convfactor=conv_factor 
  from ord_list 
  where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part and location=@loc
  
  update ord_list set cost=@uc * conv_factor / @qty, direct_dolrs=@d * conv_factor / @qty,
    ovhd_dolrs=@o * conv_factor /@qty,labor=@l * conv_factor /@qty,util_dolrs=@u * conv_factor /@qty
  where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part 

  if @@error > 0 return 0
end
if @tran_code='K' 
begin
  select @convfactor=null 

  select @convfactor=conv_factor 
  from ord_list_kit 
  where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part and
    location=@loc
  
  update ord_list_kit set cost=@uc * conv_factor / @qty, direct_dolrs=@d * conv_factor / @qty,
    ovhd_dolrs=@o * conv_factor /@qty,labor=@l * conv_factor /@qty,util_dolrs=@u * conv_factor /@qty
  where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part 

  if @@error > 0 return 0
end














if @tran_code='X' 
begin
  select @convfactor=conv_factor 
  from xfer_list 
  where xfer_no=@tran_no and  line_no=@tran_line

  update xfer_list 
  set cost=@uc * conv_factor / @qty, direct_dolrs=@d * conv_factor / @qty,
    ovhd_dolrs=@o * conv_factor /@qty,labor=@l * conv_factor /@qty,
    util_dolrs=@u * conv_factor /@qty
  where xfer_no=@tran_no and line_no=@tran_line and part_no=@part
  if @@error > 0 return 0
end
if @tran_code='I' 
begin
  select @convfactor=1
  update issues_all 
  set avg_cost=@uc / @qty, direct_dolrs=@d / @qty, ovhd_dolrs=@o /@qty,labor=@l /@qty,util_dolrs=@u /@qty
  where issue_no=@tran_no 

  if @@error > 0 return 0
end

return 1
end

GO
GRANT EXECUTE ON  [dbo].[fs_cost_delete_misc] TO [public]
GO
