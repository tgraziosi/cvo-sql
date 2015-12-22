SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_cost_insert] @part varchar(30), @loc varchar(10),
	@qty decimal(20,8),@tran_code char(1), @tran_no int, @tran_ext int, @tran_line int,
	@account varchar(10), @tran_date datetime, @tran_age datetime, @unitcost decimal(20,8) OUT,
	@direct decimal(20,8) OUT, @overhead decimal(20,8) OUT, @labor decimal(20,8) OUT, @utility decimal(20,8) OUT,
        @a_avg_cost decimal(20,8), @a_direct decimal(20,8), @a_overhead decimal(20,8), @a_utility decimal(20,8),
        @a_labor decimal(20,8), 
        @s_std_cost decimal(20,8), @s_direct decimal(20,8), @s_overhead decimal(20,8), @s_utility decimal(20,8),
        @s_labor decimal(20,8), @stat char(1), @typ char(1), @use_ac char(1),
        @COGS int = 0, @l_qty decimal(20,8) = 0, 
        @n_unitcost decimal(20,8) = 0  OUT, @n_direct decimal(20,8) = 0  OUT, @n_overhead decimal(20,8) = 0  OUT, 
        @n_utility decimal(20,8) = 0  OUT, @n_labor decimal(20,8) = 0  OUT
AS
BEGIN

set nocount on

if @qty=0 return 1

declare @f_qty decimal(20,8), @f_row_id int, @apply_qty decimal(20,8), @fc_qty decimal(20,8), @nl_qty decimal(20,8),@cg_qty decimal(20,8)
create table #new_layers (tran_date datetime, quantity decimal(20,8),org_cost decimal(20,8),
  act_mtrl_cost decimal(20,8), act_dir_cost decimal(20,8), act_ovhd_cost decimal(20,8), act_util_cost decimal(20,8), act_labor_cost decimal(20,8),
  tot_mtrl_cost decimal(20,8), tot_dir_cost decimal(20,8), tot_ovhd_cost decimal(20,8), tot_util_cost decimal(20,8), tot_labor_cost decimal(20,8),
  apply_qty decimal(20,8), cogs_qty decimal(20,8), row_id int identity(1,1))
create index newl_a1 on #new_layers (row_id)

declare @convfactor decimal(20,8), @maxseq int, @wtnum int, @newseq int, @minseq int, @lastseq int,
    @XFER_COST_LAYER int
declare @prod_date datetime 								-- mls 7/28/99 SCR 70 20187
declare @dir int, @prod_type char (1)									-- mls 10/14/99
declare @sum_wavg decimal(20,8), @in_stock decimal(20,8), @prod_qty decimal(20,8)	-- mls 5/3/00 SCR 22567
declare @cl_tran_code char(1)
declare @balance decimal(20,8)
declare @retval int, @l_typ char(1),
 @d_unitcost decimal(20,8), @d_direct decimal(20,8), @d_overhead decimal(20,8), @d_utility decimal(20,8), @d_labor decimal(20,8),
 @x_unitcost decimal(20,8), @x_direct decimal(20,8), @x_overhead decimal(20,8), @x_utility decimal(20,8), @x_labor decimal(20,8),
 @i_unitcost decimal(20,8), @i_direct decimal(20,8), @i_overhead decimal(20,8), @i_utility decimal(20,8), @i_labor decimal(20,8)
 
select @i_unitcost = 0, @i_direct = 0, @i_overhead = 0, @i_utility = 0, @i_labor = 0
select @l_typ = @typ
select @wtnum=charindex(@typ,'123456789')
if @wtnum > 0 select @l_typ='W'

set @XFER_COST_LAYER = 0
if exists (select 1 from config (nolock) where upper(flag) = 'XFER_COST_LAYER' and upper(value_str) like 'Y%')
  set @XFER_COST_LAYER = 1

select @prod_qty = @qty	,								-- mls 5/4/00 SCR 22567
  @cl_tran_code = @tran_code

if @tran_code = 'K'
  select @cl_tran_code = 'S'

if @stat = 'R' 
begin
  select @unitcost = -@s_std_cost * @qty, @direct = -@s_direct * @qty, @overhead = -@s_overhead * @qty, 
    @utility = -@s_utility * @qty, @labor = -@s_labor * @qty

  return 1
end

select @d_unitcost = @unitcost / @qty, @d_direct = @direct / @qty, @d_overhead = @overhead / @qty, 
  @d_utility = @utility / @qty, @d_labor = @labor / @qty

if @l_typ in ('E','F','L','A') or @account = 'QC'						 -- mls 1/31/03 SCR 29278	
begin
    set @newseq = NULL
    if @l_typ in ('F','L') and @tran_code = 'X'
    begin
      insert #new_layers (tran_date,quantity, org_cost,
	act_mtrl_cost, act_dir_cost, act_ovhd_cost, act_util_cost, act_labor_cost,
	tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost,apply_qty, cogs_qty)
      select tran_age, quantity,org_cost, 0,0,0,0,0,
        case when isnull(tot_mtrl_cost,0) = 0 or inv_cost_bal = 0 then unit_cost else tot_mtrl_cost / inv_cost_bal end,
        case when isnull(tot_dir_cost,0) = 0 or inv_cost_bal = 0 then direct_dolrs else tot_dir_cost / inv_cost_bal end,
        case when isnull(tot_ovhd_cost,0) = 0 or inv_cost_bal = 0 then ovhd_dolrs else tot_ovhd_cost / inv_cost_bal end,
        case when isnull(tot_util_cost,0) = 0 or inv_cost_bal = 0 then util_dolrs else tot_util_cost / inv_cost_bal end,
        case when isnull(tot_labor_cost,0) = 0 or inv_cost_bal = 0 then labor else tot_labor_cost / inv_cost_bal end,
        0,0
      from inv_cost_history
      where tran_code = @tran_code and tran_no = @tran_no and tran_ext = @tran_ext and location != @loc
        and tran_line = @tran_line --and ins_del_flag = -1
      order by ins_del_flag, tran_age, audit
    end

  if @COGS != 0 and @account != 'QC'
  begin
    select @maxseq = 1 + isnull((select max(sequence)
      from inv_costing 
      where part_no=@part and location=@loc and account=@account),0)
    if @@error > 0 return 0

    if @l_typ = 'E'
    begin
      insert into inv_costing (part_no,location,lot_ser, sequence,tran_code,tran_no,
        tran_ext, tran_line, account,tran_date,tran_age,unit_cost,quantity,balance,
        direct_dolrs,ovhd_dolrs, labor,util_dolrs, org_cost) 
      select @part, @loc, lot_ser, @maxseq + row_id, @cl_tran_code, @tran_no, @tran_ext, 
      @tran_line, @account, @tran_date, @tran_age,  abs(@n_unitcost), qty , qty,
        abs(@n_direct), abs(@n_overhead), 0, abs(@n_utility), abs(@n_unitcost)
      from #cost_lots
      where cl_upd_ind is null
      order by lot_ser
      if @@error > 0 return 0
    end
    else
    begin
      insert into inv_costing (part_no,location,sequence,tran_code,tran_no,tran_ext, tran_line,
        account,tran_date,tran_age,unit_cost,quantity,balance,direct_dolrs,ovhd_dolrs,
        labor,util_dolrs, org_cost) 
      select @part, @loc, @maxseq, @cl_tran_code, @tran_no, @tran_ext, @tran_line,
        @account, @tran_date, @tran_age, abs(@n_unitcost), @qty , @qty,
        abs(@n_direct), abs(@n_overhead), 0, abs(@n_utility), abs(@n_unitcost)
      if @@error > 0 return 0
    end
    exec @retval=fs_cost_delete @part, @loc, 0, @cl_tran_code, @tran_no, 
      @tran_ext, @tran_line, @account, @tran_date, @tran_age, 
      @x_unitcost OUT, @x_direct OUT, @x_overhead OUT, @x_labor OUT, @x_utility OUT,
      @a_avg_cost, @a_direct, @a_overhead, @a_utility, @a_labor,
      @s_std_cost, @s_direct, @s_overhead, @s_utility, @s_labor,	
      @stat, @typ, @use_ac
  
    if @retval=0
    begin
      rollback tran
      raiserror 83221 'Costing Error... Try Re-Saving!'
      return -1
    end

    select @i_unitcost = @n_unitcost * @qty, @i_direct = @n_direct * @qty,
      @i_overhead = @n_overhead * @qty, @i_utility = @n_utility * @qty, @i_labor = @n_labor * @qty

    select @qty = @l_qty - @qty
    select @unitcost = @unitcost * @qty, @direct = @direct * @qty, @overhead = @overhead * @qty, @utility = @utility * @qty,
      @labor = @labor * @qty
    select @unitcost = @unitcost / @l_qty, @direct = @direct / @l_qty, @overhead = @overhead / @l_qty, @utility = @utility / @l_qty,
      @labor = @labor / @l_qty

  end --@COGS != 0 and @account != 'QC'

    if @l_typ in ('F','L') and @tran_code = 'X'
    begin
      select @fc_qty = case when @COGS != 0 then @l_qty - @qty else 0 end
      select @f_qty = @qty 
      select @f_row_id = isnull((select min(row_id) from #new_layers where quantity > 0),0)
      While @f_row_id != 0
      begin
        select @apply_qty = quantity,
          @nl_qty = quantity,
          @cg_qty = 0
        from #new_layers
        where row_id = @f_row_id

        if @fc_qty != 0
        begin
          select @apply_qty = case when @apply_qty > @fc_qty then @apply_qty - @fc_qty else 0 end,
            @cg_qty = case when @nl_qty > @fc_qty then @fc_qty else @nl_qty end
          set @fc_qty = case when @nl_qty > @fc_qty then 0 else @fc_qty - @nl_qty end
        end

        if @fc_qty = 0
        begin
          select @apply_qty = case when @apply_qty > @f_qty then @f_qty else @apply_qty end
          select @f_qty = @f_qty - @apply_qty
        end

        update #new_layers
        set apply_qty = @apply_qty + @cg_qty,
          act_mtrl_cost = tot_mtrl_cost * (@apply_qty + @cg_qty),
          act_dir_cost = tot_dir_cost * (@apply_qty + @cg_qty),
          act_ovhd_cost = tot_ovhd_cost * (@apply_qty + @cg_qty),
          act_util_cost = tot_util_cost * (@apply_qty + @cg_qty),
          act_labor_cost = tot_labor_cost * (@apply_qty + @cg_qty),
          tot_mtrl_cost = tot_mtrl_cost * (@apply_qty ),
          tot_dir_cost = tot_dir_cost * (@apply_qty ), 
          tot_ovhd_cost = tot_ovhd_cost * (@apply_qty ),
          tot_util_cost = tot_util_cost * (@apply_qty ),
          tot_labor_cost = tot_labor_cost * (@apply_qty ),
          cogs_qty = @cg_qty
        where row_id = @f_row_id

        if @f_qty = 0 and @fc_qty = 0
          select @f_row_id = 0
        else
          select @f_row_id = isnull((select min(row_id) from #new_layers where quantity > 0 and row_id > @f_row_id),0)
      end

      if @f_qty > 0
      begin
        select @d_unitcost = (@unitcost) / @qty, @d_direct = (@direct) / @qty,
          @d_overhead = (@overhead) / @qty, @d_utility = (@utility) / @qty, @d_labor = (@labor) / @qty
        insert #new_layers (tran_date, quantity, org_cost,
  	  act_mtrl_cost, act_dir_cost, act_ovhd_cost, act_util_cost, act_labor_cost,
	  tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost,apply_qty, cogs_qty)
        select @tran_date, @f_qty,@d_unitcost, 
          (@d_unitcost * @f_qty), (@d_direct * @f_qty), (@d_overhead * @f_qty), (@d_utility * @f_qty), (@d_labor * @f_qty),
          (@d_unitcost * @f_qty), (@d_direct * @f_qty), (@d_overhead * @f_qty), (@d_utility * @f_qty), (@d_labor * @f_qty), @f_qty,0
      end

      select @n_unitcost = sum(act_mtrl_cost), @n_direct = sum(act_dir_cost), @n_overhead = sum(act_ovhd_cost),
        @n_utility = sum(act_util_cost), @n_labor = sum(act_labor_cost)
      from #new_layers where apply_qty != 0
    end
    else
    begin
      if @qty != 0
        insert #new_layers (tran_date, quantity, org_cost,
  	  act_mtrl_cost, act_dir_cost, act_ovhd_cost, act_util_cost, act_labor_cost,
	  tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost,apply_qty, cogs_qty)
        select @tran_date, @qty, @unitcost/@qty, @unitcost, @direct, @overhead, @utility, @labor,
	  @unitcost, @direct, @overhead, @utility, @labor, @qty, 0
    end

  if @qty != 0
  begin
    select @maxseq = 1 + isnull((select max(sequence)
      from inv_costing 
      where part_no=@part and location=@loc and account=@account),0)
    if @@error > 0 return 0

    select @d_unitcost = (@unitcost) / @qty, @d_direct = (@direct) / @qty,
      @d_overhead = (@overhead) / @qty, @d_utility = (@utility) / @qty, @d_labor = (@labor) / @qty

    if @l_typ = 'E' 
    begin
      update #cost_lots
      set tot_mtrl_cost = isnull(tot_mtrl_cost,convert(decimal(20,8),@d_unitcost * qty )) , 
        tot_dir_cost = isnull(tot_dir_cost, convert(decimal(20,8),@d_direct * qty )) ,
        tot_ovhd_cost = isnull(tot_ovhd_cost, convert(decimal(20,8),@d_overhead *qty )), 
        tot_util_cost = isnull(tot_util_cost, convert(decimal(20,8),@d_utility * qty )),
        tot_labor_cost = isnull(tot_labor_cost,convert(decimal(20,8),@d_labor * qty ))
      where cl_upd_ind is null
      
      select @unitcost = sum(tot_mtrl_cost),
        @direct = sum(tot_dir_cost),
        @overhead = sum(tot_ovhd_cost),
        @utility = sum(tot_util_cost),
        @labor = sum(tot_labor_cost)
      from #cost_lots
      where cl_upd_ind is null

      select @d_unitcost = (@unitcost) / @qty, @d_direct = (@direct) / @qty,
        @d_overhead = (@overhead) / @qty, @d_utility = (@utility) / @qty, @d_labor = (@labor) / @qty

      insert into inv_costing (part_no,location,lot_ser,sequence,tran_code,tran_no,tran_ext, tran_line,
        account,tran_date,tran_age,unit_cost,quantity,balance,direct_dolrs,ovhd_dolrs,
        labor,util_dolrs, org_cost,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost) 
      select @part, @loc, lot_ser, @maxseq + row_id, @cl_tran_code, @tran_no, @tran_ext, 
        @tran_line, @account, @tran_date, @tran_age,  (tot_mtrl_cost / qty), qty , qty,
        (tot_dir_cost / qty), (tot_ovhd_cost / qty), (tot_labor_cost / qty), (tot_util_cost / qty), 
        (tot_mtrl_cost / qty),
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost
      from #cost_lots
      where cl_upd_ind is null
      order by lot_ser
      if @@error > 0 return 0

      select @i_unitcost = @unitcost, @i_direct = @direct, @i_overhead = @overhead, @i_utility = @utility, @i_labor = @labor	-- mls 1/25/06 SCR 36086

    end
    else
    begin
    select @minseq = isnull((select min(sequence)
      from inv_costing 
      where part_no=@part and location=@loc and account=@account),NULL)
    if @@error > 0 return 0

    set @lastseq = 1

    update #new_layers
    set apply_qty = apply_qty - cogs_qty, cogs_qty = 0

    select @f_row_id = isnull((select min(row_id) from #new_layers where (apply_qty ) != 0),0)
    While @f_row_id != 0
    begin

    set @newseq = NULL
    if @l_typ in ('F','L') and @XFER_COST_LAYER = 1
    begin
		if @minseq is not null
		begin
			select @newseq = max(sequence)
			from inv_costing
			where part_no = @part
			and location = @loc
			and account = @account
			and tran_date = 
			(select min(ic.tran_date) from inv_costing ic
			join #new_layers nl on nl.row_id = @f_row_id
			where ic.part_no = @part
			and ic.location = @loc
			and ic.account = @account
			and ic.tran_date > nl.tran_date)
		end
	end
	if @newseq is null
    begin
        set @newseq = @maxseq
        set @maxseq = @maxseq + 1
    end
	else
	begin
        if @newseq = isnull(@minseq,-1) and @lastseq < isnull(@minseq,-1)
        begin
          set @newseq = @lastseq
          set @lastseq = @lastseq + 1
        end
        else
        begin
		update inv_costing
		set sequence = sequence + 1
		where part_no = @part
		and location = @loc
		and account = @account
		and sequence >= @newseq		
        end

	end

      insert into inv_costing (part_no,location,sequence,tran_code,tran_no,tran_ext, tran_line,
        account,tran_date,tran_age,unit_cost,quantity,balance,direct_dolrs,ovhd_dolrs,
        labor,util_dolrs, org_cost, tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost) 
      select @part, @loc, @newseq, @cl_tran_code, @tran_no, @tran_ext, @tran_line,
        @account, case when @XFER_COST_LAYER = 1 then tran_date else @tran_date end, @tran_age, 
        tot_mtrl_cost/apply_qty, apply_qty, apply_qty, tot_dir_cost/apply_qty, tot_ovhd_cost/apply_qty, tot_labor_cost/apply_qty, tot_util_cost/apply_qty,
        org_cost, tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost
      from #new_layers
      where row_id = @f_row_id and (apply_qty - cogs_qty) != 0

      if @@error > 0 return 0

      select @i_unitcost = @i_unitcost + tot_mtrl_cost, @i_direct = @i_direct + tot_dir_cost, @i_overhead = @i_overhead + tot_ovhd_cost,
        @i_utility = @i_utility + tot_util_cost, @i_labor = @i_labor + tot_labor_cost
      from #new_layers
      where row_id = @f_row_id and apply_qty > cogs_qty

      select @f_row_id = isnull((select min(row_id) from #new_layers where row_id > @f_row_id and (apply_qty) > 0),0)
    end
    END
  end

  if @l_typ = 'A' and @account != 'QC' and @newseq is not null								-- mls 1/31/03 SCR 29278
  begin
    exec fs_cost_accum @part, @loc, @cl_tran_code, @tran_no, @tran_ext, @tran_line, @newseq, @account, @tran_date		
  end												-- mls 7/14/00 SCR 23527 end
end -- @l_typ in ('F','L','A') or @account = 'QC'	

if @l_qty = 0  select @l_qty = @qty

if (@l_typ in ('W','S')) and @account != 'QC'								-- mls 1/31/03 SCR 29278
begin
  if @l_typ = 'S' 
  begin
    select @wtnum=1, @d_unitcost=@s_std_cost, @d_direct=@s_direct, @d_overhead=@s_overhead,
      @d_labor = @s_labor, @d_utility=@s_utility,
      @unitcost = @s_std_cost* @l_qty, @direct = @s_direct* @l_qty, @overhead = @s_overhead* @l_qty, @utility = @s_utility* @l_qty,
      @labor = @s_labor* @l_qty
  end

  if @l_typ = 'W'  								-- mls 5/3/00 SCR 22567 start
  begin
    select @in_stock = isnull((select in_stock + hold_ord + hold_xfr
      from inventory where part_no = @part and location = @loc),0),
      @sum_wavg = 0

    if @in_stock > 0
      select @sum_wavg = isnull((select sum(balance) 
      from inv_costing where part_no = @part and location = @loc and account = @account),0)

    if (@in_stock <= 0) or (@sum_wavg <= 0)
    begin
      delete inv_costing 
      where part_no=@part and location=@loc and account=@account
    end  	

    select @d_unitcost = @unitcost / @qty, @d_direct = @direct / @qty,
      @d_overhead = @overhead / @qty, @d_utility = @utility / @qty, @d_labor = @labor / @qty
	
    if exists (select 1 from inv_costing 
      where part_no=@part and location=@loc and tran_code=@cl_tran_code and
        tran_no=@tran_no and tran_ext=@tran_ext and tran_line=@tran_line and account=@account) 
    begin
      update inv_costing 
      set unit_cost=@d_unitcost ,
        direct_dolrs=@d_direct,
        ovhd_dolrs=@d_overhead,
        labor=@d_labor,
        util_dolrs=@d_utility,
        balance=@qty,									-- mls 5/2/00 SCR 22565
        quantity=@qty,
        tot_mtrl_cost = @unitcost, tot_dir_cost = @direct, tot_ovhd_cost = @overhead,
        tot_util_cost = @utility, tot_labor_cost = @labor
      from inv_costing 
      where part_no=@part and location=@loc and account=@account and
        tran_code=@cl_tran_code and tran_no=@tran_no and tran_ext=@tran_ext and  tran_line=@tran_line

      if @@error > 0 return 0
    end 
    else 
    begin	
      delete inv_costing 
      where part_no=@part and location=@loc and  account=@account and sequence >= @wtnum

      if @@error > 0 return 0
  
      update inv_costing 
      set	sequence=(sequence + 1) 
      where part_no=@part and location=@loc and account=@account

      if @@error > 0 return 0

      insert into inv_costing (part_no,location,sequence,tran_code,tran_no,tran_ext,tran_line,
        account, tran_date,tran_age,unit_cost,quantity,balance,direct_dolrs,ovhd_dolrs,
        labor,util_dolrs, org_cost,tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost)  
      values (@part, @loc, 1, @cl_tran_code, @tran_no, @tran_ext, @tran_line, @account, @tran_date,
        @tran_age, (@d_unitcost), @qty , @qty,  (@d_direct),  (@d_overhead),
         (@d_labor),  (@d_utility), (@d_unitcost),
         (@unitcost), (@direct),  (@overhead),  (@utility), (@labor))

      if @@error > 0 return 0
    end 
  end
  select @i_unitcost = @unitcost, @i_direct = @direct, @i_overhead = @overhead, @i_utility = @utility, @i_labor = @labor
end 
select @unitcost = @i_unitcost, @direct = @i_direct, @overhead = @i_overhead, @utility = @i_utility,
  @labor = @i_labor
 
if @tran_code='P' 									
begin
  select @d_unitcost = @unitcost / @l_qty, @d_direct = @direct / @l_qty,
    @d_overhead = @overhead / @l_qty, @d_utility = @utility / @l_qty, @d_labor = @labor / @l_qty

  select @dir = direction					-- mls 10/14/99
  from   prod_list 
  where   prod_no=@tran_no and  prod_ext=@tran_ext and line_no=@tran_line

  select @prod_type = prod_type
  from produce_all (nolock)   
  where prod_no = @tran_no and prod_ext = @tran_ext
end 

if @tran_code='S' 
begin
  update   ord_list 
  set  
 cost = (@unitcost * conv_factor / @l_qty), direct_dolrs = (@direct * conv_factor / @l_qty),
    ovhd_dolrs = (@overhead * conv_factor / @l_qty),labor = (@labor * conv_factor / @l_qty), 
    util_dolrs = (@utility * conv_factor / @l_qty)
  where   order_no = @tran_no and  order_ext = @tran_ext and  line_no = @tran_line and part_no=@part

  if @@error > 0 return 0
end

if @tran_code='K' 
begin
  update   ord_list_kit 
    set cost = (@unitcost * conv_factor / @l_qty), direct_dolrs = (@direct * conv_factor / @l_qty),
    ovhd_dolrs = (@overhead * conv_factor / @l_qty),labor = (@labor * conv_factor / @l_qty), 
    util_dolrs = (@utility * conv_factor / @l_qty)
  where   order_no = @tran_no and  order_ext = @tran_ext and line_no = @tran_line and part_no=@part

  if @@error > 0 return 0
end
 
if @tran_code='X' 
begin

  update   xfer_list 
  set   cost = (@unitcost * conv_factor / @l_qty), direct_dolrs = (@direct * conv_factor / @l_qty),
    ovhd_dolrs = (@overhead * conv_factor / @l_qty),labor = (@labor * conv_factor / @l_qty), 
    util_dolrs = (@utility * conv_factor / @l_qty)
  where   xfer_no = @tran_no and  line_no = @tran_line and part_no=@part

  if @@error > 0 return 0
end

if @tran_code='I' 
begin
  update   issues_all 
  set   avg_cost = @unitcost / @l_qty, direct_dolrs = @direct / @l_qty,
    ovhd_dolrs = @overhead / @l_qty,labor = @labor / @l_qty, util_dolrs = @utility / @l_qty
  where issue_no = @tran_no   							-- mls 1/18/01 SCR 20398

  if @@error > 0 return 0
end

return 1
END
GO
GRANT EXECUTE ON  [dbo].[fs_cost_insert] TO [public]
GO
