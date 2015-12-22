SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_cost_delete] @part varchar(30), @loc varchar(10), @qty decimal(20,8),
@tran_code char(1), @tran_no int, @tran_ext int, @tran_line int, @account varchar(10),
@tran_date datetime, @tran_age datetime, 
@unitcost decimal(20,8) OUTPUT, @direct decimal(20,8) OUTPUT, @overhead decimal(20,8) OUTPUT,
@labor decimal(20,8) OUTPUT, @utility decimal(20,8) OUTPUT,
@il_avg_cost decimal(20,8), @il_avg_dir_dolrs decimal(20,8),						-- mls 6/4/01 SCR 27031  start
@il_avg_ovhd_dolrs decimal(20,8), @il_avg_util_dolrs decimal(20,8), @il_avg_labor decimal(20,8),
@il_std_cost decimal(20,8), @il_std_dir_dolrs decimal(20,8),		 
@il_std_ovhd_dolrs decimal(20,8), @il_std_util_dolrs decimal(20,8), @il_std_labor decimal(20,8),
@m_status char(1), @typ char(1), @use_ac char(1)
AS
begin
--if @qty=0 return 1	--spham 10/5/99 cannot divide qty when qty = 0						-- mls 10/4/99
			-- the stored procedure is called with a zero when cogs = 2 and it was not running

declare @retval int, @jobno int, @convfactor decimal(20,8),
  @dir int, @prod_date datetime,										-- mls 10/15/99
  @qc_no int, @rcpt_no int,											-- mls 5/16/00 SCR 22881
  @cl_tran_code char(1)
declare @r_prod_no int, @r_prod_ext int, @fg_cost_ind int


declare 
@ol_cost decimal(20,8), @ol_direct decimal(20,8),						 
@ol_ovhd decimal(20,8), @ol_util decimal(20,8), @ol_labor decimal(20,8),		
@ic_unit_cost decimal(20,8), @ic_direct_dolrs decimal(20,8), @ic_ovhd_dolrs decimal(20,8),
@ic_labor decimal(20,8), @ic_util_dolrs decimal(20,8), @ic_tran_age datetime,
@ic_audit int, @ic_org_cost decimal(20,8),
@ol_srce char(1), @ol_part_type char(1), @ol_conv_factor decimal(20,8),
@l_typ char(1), @wtnum int,
@ic_tot_mtrl_cost decimal(20,8),@ic_tot_dir_cost decimal(20,8),@ic_tot_ovhd_cost decimal(20,8),
@ic_tot_util_cost decimal(20,8),@ic_tot_labor_cost decimal(20,8),
@cl_mtrl_cost decimal(20,8),@cl_dir_cost decimal(20,8),@cl_ovhd_cost decimal(20,8),
@cl_util_cost decimal(20,8),@cl_labor_cost decimal(20,8),

@ic_lot_ser varchar(255), @this_qty decimal(20,8),
@ic_tran_date datetime																		-- mls 10/22/07 SCR 38218

select @l_typ = @typ
select @wtnum=charindex(@typ,'123456789')
if @wtnum > 0 select @l_typ='W'

select @cl_tran_code = @tran_code

if @tran_code='S' 
begin
  select @ol_conv_factor=null, @ol_srce = 'O'
  select @ol_conv_factor=conv_factor,
    @ol_cost = cost, @ol_direct = direct_dolrs, @ol_ovhd = ovhd_dolrs, @ol_labor = labor, @ol_util = util_dolrs,
    @ol_part_type = part_type
  from ord_list 
  where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part

  if isnull(@ol_part_type,'') = 'J'
    select @m_status=NULL
end

if @tran_code = 'K'
begin
  select @ol_conv_factor=conv_factor, 
    @ol_cost = cost, @ol_direct = direct_dolrs, @ol_ovhd = ovhd_dolrs, @ol_labor = labor, @ol_util = util_dolrs,
    @ol_part_type = part_type, @ol_srce = 'K'
  from ord_list_kit
  where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part
  select @cl_tran_code = 'S'
end

if (@m_status is null) and @qty != 0
begin
  exec @retval=fs_cost_delete_misc @part, @loc, @qty, @tran_code, @tran_no, @tran_ext,
    @tran_line, @account, @tran_date, @tran_age, @unitcost OUT, @direct OUT, 					
    @overhead OUT, @labor OUT, @utility OUT									 
  return @retval
end

if @m_status = 'R' 
begin
  select @unitcost= -@il_std_cost * @qty, @direct = -@il_std_dir_dolrs * @qty,
    @overhead = -@il_std_ovhd_dolrs * @qty, @utility = -@il_std_util_dolrs * @qty,
    @labor = -@il_std_labor * @qty
  return 1
end -- typ = R

declare @maxseq int, @xlp int, @tqty decimal(20,8), @d1 datetime, @pull_qty decimal(20,8), 
  @uc decimal(20,8), @d decimal(20,8), @o decimal(20,8), @l decimal(20,8), @u decimal(20,8),
  @uca decimal(20,8), @da decimal(20,8), @oa decimal(20,8), @la decimal(20,8), @ua decimal(20,8),
  @d2 datetime													-- mls 4/13/00 SCR 22566

select @uc=0, @d=0, @o=0, @l=0, @u=0, @pull_qty=@qty 

IF (select sum(balance) 
  from inv_costing 
  where part_no=@part and location=@loc and account=@account and tran_no=@tran_no and tran_ext=@tran_ext and
    tran_line=@tran_line and tran_code=@cl_tran_code) = @pull_qty and @l_typ not in ('W','S')
  and @tran_code != 'P'										-- mls 4/5/04 SCR 32603  
begin
  delete inv_costing 
  where part_no=@part and location=@loc and account=@account and tran_no=@tran_no and tran_ext=@tran_ext and
    tran_code=@cl_tran_code and tran_line=@tran_line
 
  if @tran_code='S' 
  begin
    if (@ol_cost != 0 or @ol_direct != 0 or @ol_ovhd != 0 or @ol_labor != 0 or @ol_util != 0)
    begin
      update ord_list set cost=0, direct_dolrs=0, ovhd_dolrs=0, labor=0, util_dolrs=0
      where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part

      if @@error > 0 return 0
    end
  end
  if @tran_code = 'K'
  begin
    if (@ol_cost != 0 or @ol_direct != 0 or @ol_ovhd != 0 or @ol_labor != 0 or @ol_util != 0)
    begin
      update ord_list_kit set cost=0, direct_dolrs=0, ovhd_dolrs=0, labor=0, util_dolrs=0
      where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part 

      if @@error > 0 return 0
    end
  end
 
  if @tran_code='X' 
  begin
    update xfer_list set cost=0, direct_dolrs=0, ovhd_dolrs=0,labor=0,util_dolrs=0
    where xfer_no=@tran_no and line_no=@tran_line and part_no=@part  and
      (cost != 0 or direct_dolrs != 0 or ovhd_dolrs != 0 or labor != 0 or util_dolrs != 0)			-- mls 6/4/01

    if @@error > 0 return 0
  end -- tran_code = X

  if @tran_code='I' 
  begin
    update issues_all set avg_cost=0, direct_dolrs=0, ovhd_dolrs=0 ,labor=0,util_dolrs=0
    where issue_no=@tran_no and
      (avg_cost != 0 or direct_dolrs != 0 or ovhd_dolrs != 0 or labor != 0 or util_dolrs != 0)			-- mls 6/4/01

    if @@error > 0 return 0
  end -- tran_code = I

  return 1
end -- sum(balance) = pqty

select @unitcost=0, @direct=0, @overhead=0, @labor=0, @utility=0

if @pull_qty < 0 
begin
  select @d1=case when @tran_code = 'P' then @tran_date else getdate() end, 
    @pull_qty=(@pull_qty * -1), @d2 = getdate()							-- mls 4/13/00 SCR22566

  select @unitcost=@il_std_cost * @pull_qty, 
    @direct=@il_std_dir_dolrs * @pull_qty, @overhead=@il_std_ovhd_dolrs * @pull_qty,
    @labor=@il_std_labor * @pull_qty, @utility=@il_std_util_dolrs * @pull_qty	
 
  if @@error > 0 return 0

  exec @retval=fs_cost_insert @part, @loc, @pull_qty , @tran_code, @tran_no,
    @tran_ext, @tran_line, @account, @d1, @d2, 
    @unitcost, @direct, @overhead, @labor, @utility,
    @il_avg_cost, @il_avg_dir_dolrs,  @il_avg_ovhd_dolrs, @il_avg_util_dolrs, @il_avg_labor,
    @il_std_cost, @il_std_dir_dolrs,  @il_std_ovhd_dolrs, @il_std_util_dolrs, @il_std_labor,
    @m_status, @typ, @use_ac

  return @retval
end -- qty < 0

if @l_typ = 'W'
begin
  select @uc=-(@il_avg_cost * @pull_qty), @d=-(@il_avg_dir_dolrs * @pull_qty), 						-- mls 6/4/01 SCR 27031 start
    @o=-(@il_avg_ovhd_dolrs * @pull_qty), @l=-(@il_avg_labor * @pull_qty), @u=-(@il_avg_util_dolrs * @pull_qty)			-- mls 6/4/01 SCR 27031 end

  if @@error > 0 return 0

  select @pull_qty = (in_stock + hold_ord + hold_xfr) * -1
  from inventory 
  where part_no = @part and location = @loc

  if @pull_qty > 0
  begin
    delete inv_costing where part_no=@part and location=@loc and account=@account
  end
end -- typ = W 

if @l_typ='S' 
begin
  select @uc=-(@il_std_cost * @pull_qty), @d=-(@il_std_dir_dolrs * @pull_qty), 						-- mls 6/4/01 SCR 27031 start
    @o=-(@il_std_ovhd_dolrs * @pull_qty), @l=-(@il_std_labor * @pull_qty), @u=-(@il_std_util_dolrs * @pull_qty)			-- mls 6/4/01 SCR 27031 end

  if @@error > 0 return 0
end -- typ = S


if @l_typ not in ('W','S')
begin
  select @fg_cost_ind = 0
  if @tran_code = 'P' and @l_typ in ('L','F')
  begin
    select @r_prod_no = orig_prod_no,
      @r_prod_ext = orig_prod_ext,
      @fg_cost_ind = fg_cost_ind
    from produce_all (nolock) where prod_no = @tran_no and prod_ext = @tran_ext and qty < 0
      and fg_cost_ind = 1 and part_no = @part

    if @@rowcount = 0 or isnull(@r_prod_no,0) = 0 
      set @fg_cost_ind = 0
  end

  select @xlp = -1												-- mls 5/16/00 SCR 22881 start
  if @tran_code = 'I' 
  begin
    select @qc_no = isnull((select qc_no from issues_all (nolock)
      where issue_no = @tran_no and part_no = @part and location_from = @loc),0)

    if @qc_no > 0 
    begin
      select @rcpt_no = isnull((select tran_no from qc_results (nolock)
        where qc_no = @qc_no and status = 'S' and reject_qty = @pull_qty and tran_code = 'R'
        and part_no = @part and location = @loc),0)
      if @rcpt_no != 0
      begin
	if @l_typ in ('A','F')											-- mls 6/4/01 SCR 27031 start
        begin
          select @xlp=isnull((select min(sequence) from inv_costing where part_no=@part and
            location=@loc and account=@account and tran_no=@rcpt_no and tran_ext=0 and
            tran_code= 'R'),-1)          
        end
        else if @l_typ = 'L'  -- type = 'L'
        begin
          select @xlp=isnull((select max(sequence) from inv_costing where part_no=@part and
            location=@loc and account=@account and tran_no=@rcpt_no and tran_ext=0 and
            tran_code= 'R'),-1)
        end													-- mls 6/4/01 SCR 27031 end
        else
        begin
          select @xlp=isnull((select min(c.sequence) from inv_costing c
            join #cost_lots l on l.lot_ser = c.lot_ser and l.qty < l.cl_qty
            where part_no=@part and
            location=@loc and account=@account and tran_no=@rcpt_no and tran_ext=0 and
            tran_code= 'R'),-1)
        end													-- mls 6/4/01 SCR 27031 end
      end
    end
  end

  if @xlp = -1 and @pull_qty != 0
  begin 													-- mls 5/16/00 SCR 22881 end
    if @fg_cost_ind = 1
    begin
      select @xlp=isnull((select min(sequence) from inv_costing where part_no=@part and
        location=@loc and account=@account and tran_no=@r_prod_no and tran_ext=@r_prod_ext and
        tran_line=@tran_line and tran_code=@cl_tran_code),-1)
    end
    else if @l_typ in ('A','F')											-- mls 6/4/01 SCR 27031 start
    begin
      select @xlp=isnull((select min(sequence) from inv_costing where part_no=@part and
        location=@loc and account=@account and tran_no=@tran_no and tran_ext=@tran_ext and
        tran_line=@tran_line and tran_code=@cl_tran_code),-1)
    end
    else if @l_typ = 'L' -- type = 'L'
    begin
      select @xlp=isnull((select max(sequence) from inv_costing where part_no=@part and
        location=@loc and account=@account and tran_no=@tran_no and tran_ext=@tran_ext and
        tran_line=@tran_line and tran_code=@cl_tran_code),-1)
    end														-- mls 6/4/01 SCR 27031 end
    else
    begin
      select @xlp=isnull((select min(c.sequence) from inv_costing c
        join #cost_lots l on l.lot_ser = c.lot_ser and l.qty < l.cl_qty
        where part_no=@part and
        location=@loc and account=@account and tran_no=@tran_no and tran_line = @tran_line
        and tran_ext = @tran_ext and tran_code= @cl_tran_code),-1)
    end													-- mls 6/4/01 SCR 27031 end
  end
 
  if @xlp=-1 
  begin
    if @l_typ = 'E'
    begin
      select @xlp=isnull((select min(c.sequence) from inv_costing c
      join #cost_lots l on l.lot_ser = c.lot_ser and l.qty < l.cl_qty
      where part_no=@part and location=@loc and account=@account),0)
    end
    else if @l_typ in ('A','F') or @pull_qty = 0											-- mls 6/4/01 SCR 27031 start
    begin
      select @xlp=isnull((select min(sequence) from inv_costing where part_no=@part and
      location=@loc and account=@account),0)
    end
    else -- type = 'L'
    begin
      select @xlp=isnull((select max(sequence) from inv_costing where part_no=@part and
      location=@loc and account=@account),0)
    end														-- mls 6/4/01 SCR 27031 end
  end

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
      @ic_tot_mtrl_cost = isnull(tot_mtrl_cost,unit_cost * balance),
      @ic_tot_dir_cost = isnull(tot_dir_cost,direct_dolrs * balance),
      @ic_tot_ovhd_cost = isnull(tot_ovhd_cost,ovhd_dolrs * balance),
      @ic_tot_util_cost = isnull(tot_util_cost,util_dolrs * balance),
      @ic_tot_labor_cost = isnull(tot_labor_cost,labor * balance),
      @ic_lot_ser = lot_ser,
      @ic_tran_date = tran_date																		-- mls 10/22/07 SCR 38218
    from inv_costing 
    where part_no=@part and location=@loc and account=@account and @xlp=sequence

    if @l_typ = 'E'
      select @this_qty = cl_qty - qty
      from #cost_lots where lot_ser = @ic_lot_ser
    else
      select @this_qty = @pull_qty

    if @this_qty >= @tqty 
    begin
      if @l_typ in ('F','L','A','E')
      begin
        select @uc=@uc - isnull(@ic_tot_mtrl_cost,(@ic_unit_cost * @tqty)),
          @d=@d - isnull(@ic_tot_dir_cost,(@ic_direct_dolrs * @tqty)),
          @o=@o - isnull(@ic_tot_ovhd_cost,(@ic_ovhd_dolrs * @tqty)),
          @l=@l - isnull(@ic_tot_labor_cost,(@ic_labor * @tqty)),
          @u=@u - isnull(@ic_tot_util_cost,(@ic_util_dolrs * @tqty))
      end -- typ = F or L

      insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,
        tran_ext,tran_line,account,tran_date,tran_age,unit_cost,quantity,
        inv_cost_bal,direct_dolrs,ovhd_dolrs,labor,util_dolrs, audit, org_cost,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost,lot_ser)
      select @part,@loc,-1,@cl_tran_code,
        @tran_no,@tran_ext,@tran_line,@account,@tran_date,
	    @ic_tran_date,@ic_unit_cost,@tqty,															-- mls 10/22/07 SCR 38218
        @tqty,@ic_direct_dolrs,@ic_ovhd_dolrs,@ic_labor,@ic_util_dolrs,@ic_audit, @ic_org_cost,
        @ic_tot_mtrl_cost, @ic_tot_dir_cost, @ic_tot_ovhd_cost, @ic_tot_util_cost, @ic_tot_labor_cost,
        @ic_lot_ser
      if @@error > 0 return 0

      delete inv_costing 
      where part_no=@part and location=@loc and account=@account and @xlp=sequence

      if @@error > 0 return 0

      if @l_typ = 'E'
        update #cost_lots
        set cl_qty = cl_qty - @tqty,
        tot_mtrl_cost = isnull(tot_mtrl_cost,0) - isnull(@ic_tot_mtrl_cost,(@ic_unit_cost * @tqty)),
        tot_dir_cost = isnull(tot_dir_cost,0) - isnull(@ic_tot_dir_cost,(@ic_direct_dolrs * @tqty)),
        tot_ovhd_cost = isnull(tot_ovhd_cost,0) - isnull(@ic_tot_ovhd_cost,(@ic_ovhd_dolrs * @tqty)),
        tot_util_cost = isnull(tot_util_cost,0) - isnull(@ic_tot_util_cost,(@ic_util_dolrs * @tqty)),
        tot_labor_cost = isnull(tot_labor_cost,0) - isnull(@ic_tot_labor_cost,(@ic_labor * @tqty))
        where lot_ser = @ic_lot_ser

      select @pull_qty=@pull_qty-@tqty
    end -- pqty >= tqty
    else 
    begin
      select @cl_mtrl_cost = @ic_tot_mtrl_cost / @tqty,
        @cl_dir_cost = @ic_tot_dir_cost / @tqty,
        @cl_ovhd_cost = @ic_tot_ovhd_cost / @tqty,
        @cl_labor_cost = @ic_tot_labor_cost / @tqty,
        @cl_util_cost = @ic_tot_util_cost / @tqty

      select @cl_mtrl_cost = (@cl_mtrl_cost * @this_qty),
        @cl_dir_cost = (@cl_dir_cost * @this_qty),
        @cl_ovhd_cost = (@cl_ovhd_cost * @this_qty),
        @cl_labor_cost = (@cl_labor_cost * @this_qty),
        @cl_util_cost = (@cl_util_cost * @this_qty)

      select 
        @cl_mtrl_cost = case when @cl_mtrl_cost > @ic_tot_mtrl_cost then @ic_tot_mtrl_cost else @cl_mtrl_cost end,
        @cl_dir_cost = case when @cl_dir_cost > @ic_tot_dir_cost then @ic_tot_dir_cost else @cl_dir_cost end,
        @cl_ovhd_cost = case when @cl_ovhd_cost > @ic_tot_ovhd_cost then @ic_tot_ovhd_cost else @cl_ovhd_cost end,
        @cl_util_cost = case when @cl_util_cost > @ic_tot_util_cost then @ic_tot_util_cost else @cl_util_cost end,
        @cl_labor_cost = case when @cl_labor_cost > @ic_tot_labor_cost then @ic_tot_labor_cost else @cl_labor_cost end

      if @l_typ in ('F','L','A','E')
      begin
        select @uc=@uc - @cl_mtrl_cost,
          @d=@d - @cl_dir_cost,
          @o=@o - @cl_ovhd_cost,
          @l=@l - @cl_labor_cost,
          @u=@u - @cl_util_cost

        if @@error > 0 return 0
      end -- typ = F or L

      insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,
        tran_ext,tran_line,account,tran_date,tran_age,unit_cost,quantity,
        inv_cost_bal,direct_dolrs,ovhd_dolrs,labor,util_dolrs, audit, org_cost,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost, lot_ser)    
      select @part,@loc,-1,@cl_tran_code,
        @tran_no,@tran_ext,@tran_line,@account,@tran_date,
		@ic_tran_date,@ic_unit_cost,@this_qty ,														-- mls 10/22/07 SCR 38218
        @tqty,@ic_direct_dolrs,@ic_ovhd_dolrs,@ic_labor,@ic_util_dolrs,@ic_audit,@ic_org_cost,
        @ic_tot_mtrl_cost, @ic_tot_dir_cost, @ic_tot_ovhd_cost, @ic_tot_util_cost, @ic_tot_labor_cost,
        @ic_lot_ser

      if @@error > 0 return 0

      select @ic_tot_mtrl_cost = @ic_tot_mtrl_cost - @cl_mtrl_cost,
        @ic_tot_dir_cost = @ic_tot_dir_cost - @cl_dir_cost,
        @ic_tot_ovhd_cost = @ic_tot_ovhd_cost - @cl_ovhd_cost,
        @ic_tot_util_cost = @ic_tot_util_cost - @cl_util_cost,
        @ic_tot_labor_cost = @ic_tot_labor_cost - @cl_labor_cost

      update inv_costing 
      set balance=balance - @this_qty,
        tot_mtrl_cost =  @ic_tot_mtrl_cost ,
        tot_dir_cost = @ic_tot_dir_cost ,
        tot_ovhd_cost =  @ic_tot_ovhd_cost ,
        tot_util_cost =  @ic_tot_util_cost ,
        tot_labor_cost = @ic_tot_labor_cost 
      where part_no=@part and location=@loc and account=@account and @xlp=sequence

      if @@error > 0 return 0

      if @l_typ = 'E'
        update #cost_lots
        set cl_qty = qty,
        tot_mtrl_cost = isnull(tot_mtrl_cost,0) - @cl_mtrl_cost,
        tot_dir_cost = isnull(tot_dir_cost,0) - @cl_dir_cost,
        tot_ovhd_cost = isnull(tot_ovhd_cost,0) - @cl_ovhd_cost,
        tot_util_cost = isnull(tot_util_cost,0) - @cl_util_cost,
        tot_labor_cost = isnull(tot_labor_cost,0) - @cl_labor_cost
        where lot_ser = @ic_lot_ser

      select @pull_qty = @pull_qty - @this_qty
    end -- pqty < tqty

    if @pull_qty > 0
    begin
      select @xlp = -1
      if @qty != 0
      begin
        if @l_typ in ('A','F')											-- mls 6/4/01 SCR 27031 start
        begin
          select @xlp=isnull((select min(sequence) from inv_costing 
            where part_no=@part and location=@loc and account=@account and tran_no=@tran_no and 
            tran_ext=@tran_ext and tran_line=@tran_line and tran_code=@cl_tran_code),-1)
        end
        else if @l_typ = 'L' -- type = 'L'
        begin
          select @xlp=isnull((select max(sequence) from inv_costing 
            where part_no=@part and location=@loc and account=@account and tran_no=@tran_no and 
            tran_ext=@tran_ext and tran_line=@tran_line and tran_code=@cl_tran_code),-1)
        end													-- mls 6/4/01 SCR 27031 end
        else
        begin
          select @xlp=isnull((select min(c.sequence) from inv_costing c
            join #cost_lots l on l.lot_ser = c.lot_ser and l.qty < l.cl_qty
            where part_no=@part and
            location=@loc and account=@account and tran_no=@tran_no and tran_line = @tran_line
            and tran_ext = @tran_ext and tran_code= @cl_tran_code),-1)
        end													-- mls 6/4/01 SCR 27031 end
      end
 
      if @xlp=-1 
      begin
        if @l_typ = 'E'
        begin
          select @xlp=isnull((select min(c.sequence) from inv_costing c
          join #cost_lots l on l.lot_ser = c.lot_ser and l.qty < l.cl_qty
          where part_no=@part and location=@loc and account=@account),0)
        end
        else if @l_typ in ('A','F') or @qty = 0									-- mls 6/4/01 SCR 27031 start
        begin
          select @xlp=isnull((select min(sequence) from inv_costing where part_no=@part and
            location=@loc and account=@account),0)
        end
        else -- type = 'L'
        begin
          select @xlp=isnull((select max(sequence) from inv_costing where part_no=@part and
            location=@loc and account=@account),0)
        end													-- mls 6/4/01 SCR 27031 end
      end

      if @@error > 0 return 0
    end -- pqty > 0
    else
    begin
      select @xlp=0
    end -- pqty <= 0
  end -- while
end -- typ not W or S												-- mls 5/2/00 SCR 22567

if @pull_qty > 0 and @l_typ != 'S' 
begin		
  if @l_typ = 'E'
  begin
    select @il_avg_cost = -@uc / (@qty - @pull_qty),
    @il_avg_dir_dolrs = -@d / (@qty - @pull_qty),
    @il_avg_ovhd_dolrs = -@o / (@qty - @pull_qty),
    @il_avg_util_dolrs = -@u / (@qty - @pull_qty),
    @il_avg_labor = 0
  end
  else
  begin
    select @il_avg_cost = isnull(avg_cost,0),									-- mls 6/4/01 SCR 27031 start
    @il_avg_dir_dolrs = isnull(avg_direct_dolrs,0),
    @il_avg_ovhd_dolrs = isnull(avg_ovhd_dolrs,0),
    @il_avg_util_dolrs = isnull(avg_util_dolrs,0),
    @il_avg_labor = 0
    from inv_list 	
    where part_no=@part and location=@loc									 	-- mls 6/4/01 SCR 27031 end	
  end
  select @d1=getdate()

  if @use_ac = 'Y' and (@il_avg_cost != 0 or @il_avg_dir_dolrs != 0 or @il_avg_ovhd_dolrs != 0 or
    @il_avg_util_dolrs != 0 or @il_avg_labor != 0)
  begin
    select @unitcost=@il_avg_cost, @direct=@il_avg_dir_dolrs, @overhead=@il_avg_ovhd_dolrs, 			-- mls 6/4/01 SCR 27031 start
      @labor=@il_avg_labor, @utility=@il_avg_util_dolrs								-- mls 6/4/01 SCR 27031 end
  end-- use avg cost = Y
  else 
  begin
    -- Set all the cost to standard cost
    select @unitcost = @il_std_cost, @direct = @il_std_dir_dolrs,
      @overhead = @il_std_ovhd_dolrs, @utility = @il_std_util_dolrs, @labor = @il_std_labor
  end  -- use avg cost = N
 
  select @ic_tot_mtrl_cost = -@unitcost * @pull_qty, @ic_tot_dir_cost = -@direct * @pull_qty,
    @ic_tot_ovhd_cost = -@overhead * @pull_qty, @ic_tot_util_cost = -@utility * @pull_qty, 
    @ic_tot_labor_cost = -@labor * @pull_qty

  select @pull_qty=(@pull_qty * -1)
 
  if @l_typ != 'E'
  begin
    exec @retval=fs_cost_insert @part, @loc, @pull_qty , 'O', @tran_no,
      @tran_ext, @tran_line, @account, @d1, @d1, 
      @ic_tot_mtrl_cost, @ic_tot_dir_cost, @ic_tot_ovhd_cost, @ic_tot_labor_cost , @ic_tot_util_cost ,
      @il_avg_cost, @il_avg_dir_dolrs,  @il_avg_ovhd_dolrs, @il_avg_util_dolrs, @il_avg_labor,
      @il_std_cost, @il_std_dir_dolrs,  @il_std_ovhd_dolrs, @il_std_util_dolrs, @il_std_labor,
      @m_status, @typ, @use_ac
    if @retval !=1 return @retval

    select @pull_qty=(@pull_qty * -1)
  
    insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,tran_ext,
      tran_line, account,tran_date,tran_age,unit_cost,quantity,inv_cost_bal,direct_dolrs,
      ovhd_dolrs, labor,util_dolrs, audit, org_cost, 
      tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost)
    select @part, @loc, 1, 
      @cl_tran_code, @tran_no, @tran_ext, @tran_line, @account, @d1, @d1, 
      @unitcost, @pull_qty , 0, @direct, @overhead, @labor , @utility ,0, @unitcost,
      @ic_tot_mtrl_cost, @ic_tot_dir_cost, @ic_tot_ovhd_cost, @ic_tot_util_cost, @ic_tot_labor_cost

    if @@error > 0 return 0
  end
  else
  begin
    select @pull_qty=(@pull_qty * -1)

    insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,tran_ext,
      tran_line, account,tran_date,tran_age,unit_cost,quantity,inv_cost_bal,direct_dolrs,
      ovhd_dolrs, labor,util_dolrs, audit, org_cost, 
      tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost, lot_ser)
    select @part, @loc, -1, 
      @cl_tran_code, @tran_no, @tran_ext, @tran_line, @account, @d1, @d1, 
      @unitcost, cl_qty - qty , 0, @direct, @overhead, @labor , @utility ,0, @unitcost,
      (@unitcost * (cl_qty - qty)), (@direct * (cl_qty - qty)), 
      (@overhead * (cl_qty - qty)), (@utility * (cl_qty - qty)), (@labor * (cl_qty - qty)), lot_ser
    from #cost_lots
    where qty < cl_qty
    if @@error > 0 return 0
  end    


  if @l_typ in ('F','L','A','E')
  begin
    select @uc=@uc + @ic_tot_mtrl_cost, @d=@d + @ic_tot_dir_cost,
      @o=@o + @ic_tot_ovhd_cost, @l=@l + @ic_tot_labor_cost,
      @u=@u + @ic_tot_util_cost
  end
end -- pqty > 0 and typ != 'S'

select @convfactor=1
select @unitcost=@uc , @direct=@d , @overhead=@o , @labor=@l , @utility=@u 

if @tran_code='S' 
begin
  select @convfactor=@ol_conv_factor

  if @l_typ = 'S'									-- mls 3/14/02 SCR 28521 start
  begin
    select @uc=(@il_std_cost ), @d=(@il_std_dir_dolrs ), 						-- mls 6/4/01 SCR 27031 start
      @o=(@il_std_ovhd_dolrs ), @l=(@il_std_labor ), 
      @u=(@il_std_util_dolrs )		
  end
  else
  begin
    if @qty = 0
      select @uc = 0, @d = 0, @o = 0, @l = 0, @u = 0
    else
    begin
      select @uc = -@unitcost*@convfactor, @d = -@direct*@convfactor, 
        @o = -@overhead*@convfactor, @l = -@labor*@convfactor, @u = -@utility*@convfactor		-- mls 10/1/02 SCR 29830
      select @uc = @uc/@qty, @d = @d/@qty, 
        @o = @o/@qty, @l = @l/@qty, @u = @u/@qty
    end
  end										-- mls 3/14/02 SCR 28521 end

  if @uc != isnull(@ol_cost,-1*@uc) or @d != isnull(@ol_direct,-1*@d) or					-- mls 6/4/01
    @o != isnull(@ol_ovhd,-1*@o) or @l != isnull(@ol_labor,-1*@l) or 
    @u != isnull(@ol_util,-1*@u)
  begin
    update ord_list set cost=@uc , direct_dolrs=@d, ovhd_dolrs=@o,labor=@l,util_dolrs=@u
    where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part 

    if @@error > 0 return 0											-- mls 12/20/00 SCR 25339 end
  end 
end

if @tran_code='K' 
begin
  select @convfactor=@ol_conv_factor

  if @l_typ = 'S'									-- mls 3/14/02 SCR 28521 start
  begin
    select @uc=(@il_std_cost ), @d=(@il_std_dir_dolrs ), 						-- mls 6/4/01 SCR 27031 start
      @o=(@il_std_ovhd_dolrs ), @l=(@il_std_labor ), 
      @u=(@il_std_util_dolrs )		
  end
  else
  begin
    if @qty = 0
      select @uc = 0, @d = 0, @o = 0, @l = 0, @u = 0
    else
    begin
      select @uc = -@unitcost*@convfactor, @d = -@direct*@convfactor, 
        @o = -@overhead*@convfactor, @l = -@labor*@convfactor, @u = -@utility*@convfactor		-- mls 10/1/02 SCR 29830
      select @uc = @uc/@qty, @d = @d/@qty, 
        @o = @o/@qty, @l = @l/@qty, @u = @u/@qty
    end
  end										-- mls 3/14/02 SCR 28521 end

  if @uc != isnull(@ol_cost,-1*@uc) or @d != isnull(@ol_direct,-1*@d) or					-- mls 6/4/01
    @o != isnull(@ol_ovhd,-1*@o) or @l != isnull(@ol_labor,-1*@l) or 
    @u != isnull(@ol_util,-1*@u)
  begin
    update ord_list_kit set cost=@uc, direct_dolrs=@d, ovhd_dolrs=@o, labor=@l,util_dolrs=@u		-- mls 6/4/01
    where order_no=@tran_no and order_ext=@tran_ext and line_no=@tran_line and part_no=@part 

    if @@error > 0 return 0											-- mls 12/20/00 SCR 25339 end
  end 
end

if @tran_code='P' 
begin
  select  @dir = direction								-- mls 10/14/99
  from prod_list 
  where prod_no=@tran_no and prod_ext=@tran_ext and line_no=@tran_line

  if @l_typ = 'S'									-- mls 3/14/02 SCR 28521 start
  begin
    select @uc=(@il_std_cost ), @d=(@il_std_dir_dolrs ), 						-- mls 6/4/01 SCR 27031 start
      @o=(@il_std_ovhd_dolrs ), @l=(@il_std_labor ), 
      @u=(@il_std_util_dolrs )		
  end
  else
  begin
    if @qty = 0
      select @uc = 0, @d = 0, @o = 0, @l = 0, @u = 0
    else
      select @uc = @unitcost/@qty, @d = @direct/@qty, @o = @overhead/@qty, @l = @labor/@qty, @u = @utility/@qty		-- mls 10/1/02 SCR 29830
  end										-- mls 3/14/02 SCR 28521 end
















end

if @tran_code='X' 
begin
  select @convfactor=conv_factor ,
    @ol_cost = cost, @ol_direct = direct_dolrs, @ol_ovhd = ovhd_dolrs, @ol_labor = labor, @ol_util = util_dolrs	-- mls 6/4/01
  from xfer_list 
  where xfer_no=@tran_no and line_no=@tran_line

  if @l_typ = 'S'									-- mls 3/14/02 SCR 28521 start
  begin
    select @uc=(@il_std_cost*@convfactor), @d=(@il_std_dir_dolrs *@convfactor), 						-- mls 6/4/01 SCR 27031 start
      @o=(@il_std_ovhd_dolrs *@convfactor), @l=(@il_std_labor *@convfactor), 
      @u=(@il_std_util_dolrs*@convfactor )		
  end
  else
  begin
    if @qty = 0
      select @uc = 0, @d = 0, @o = 0, @l = 0, @u = 0
    else
    begin
      select @uc = -@unitcost*@convfactor, @d = -@direct*@convfactor, 
        @o = -@overhead*@convfactor, @l = -@labor*@convfactor, @u = -@utility*@convfactor		-- mls 10/1/02 SCR 29830
      select @uc = @uc/@qty, @d = @d/@qty, 
        @o = @o/@qty, @l = @l/@qty, @u = @u/@qty
    end
  end										-- mls 3/14/02 SCR 28521 end

  if @uc != isnull(@ol_cost,-1*@uc) or @d != isnull(@ol_direct,-1*@d) or					-- mls 6/4/01
    @o != isnull(@ol_ovhd,-1*@o) or @l != isnull(@ol_labor,-1*@l) or 
    @u != isnull(@ol_util,-1*@u)
  begin
    update xfer_list set cost= @uc , direct_dolrs=@d ,
      ovhd_dolrs=@o, labor=@l,
      util_dolrs=@u												-- mls 12/20/00 SCR 25339 end
    where xfer_no=@tran_no and line_no=@tran_line and part_no=@part
  end

  if @@error > 0 return 0
end

if @tran_code='I' 
begin
  select @ol_cost = avg_cost, @ol_direct = direct_dolrs, @ol_ovhd = ovhd_dolrs, @ol_labor = labor, 			-- mls 6/4/01
    @ol_util = util_dolrs	
  from issues_all where issue_no = @tran_no

  if @l_typ = 'S'									-- mls 3/14/02 SCR 28521 start
  begin
    select @uc=(@il_std_cost ), @d=(@il_std_dir_dolrs ), 						-- mls 6/4/01 SCR 27031 start
      @o=(@il_std_ovhd_dolrs ), @l=(@il_std_labor ), 
      @u=(@il_std_util_dolrs )		
  end
  else
  begin
    if @qty = 0
      select @uc = 0, @d = 0, @o = 0, @l = 0, @u = 0
    else
      select @uc = -@unitcost/@qty, @d = -@direct/@qty, @o = -@overhead/@qty, @l = -@labor/@qty, @u = -@utility/@qty		-- mls 10/1/02 SCR 29830
  end										-- mls 3/14/02 SCR 28521 end

  if @uc != isnull(@ol_cost,-1*@uc) or @d != isnull(@ol_direct,-1*@d) or					-- mls 6/4/01
    @o != isnull(@ol_ovhd,-1*@o) or @l != isnull(@ol_labor,-1*@l) or 
    @u != isnull(@ol_util,-1*@u)
  begin
    update issues_all set avg_cost=@uc , direct_dolrs=@d ,
      ovhd_dolrs=@o,labor=@l,util_dolrs=@u
    where issue_no=@tran_no 											-- mls 1/18/01 SCR 20398
  end

  if @@error > 0 return 0
end


return 1

end

GO
GRANT EXECUTE ON  [dbo].[fs_cost_delete] TO [public]
GO
