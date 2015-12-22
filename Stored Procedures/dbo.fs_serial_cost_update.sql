SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_serial_cost_update] @part varchar(30), @loc varchar(10), @qty decimal(20,8),
	@tran_code char(1), @tran_no int, @tran_ext int, @tran_line int, @account varchar(10),
	@tran_date datetime, @tran_age datetime, @delta_qty decimal(20,8), @rcpt_unitcost decimal(20,8),
        @a_avg_cost decimal(20,8), @a_dir_cost decimal(20,8), @a_ovhd_cost decimal(20,8), @a_util_cost decimal(20,8),
        @a_labor decimal(20,8),
        @s_std_cost decimal(20,8), @s_dir_cost decimal(20,8), @s_ovhd_cost decimal(20,8), @s_util_cost decimal(20,8),
        @s_labor decimal(20,8),
        @m_status char(1), @use_ac char(1), @typ char(1),
        @neg_cost decimal(20,8), @neg_direct_dolrs decimal(20,8), @neg_ovhd_dolrs decimal(20,8),
        @neg_labor decimal(20,8), @neg_util_dolrs decimal(20,8), 
        @cogs_qty decimal(20,8) OUTPUT,
        @unitcost decimal(20,8) OUTPUT,
	@direct decimal(20,8) OUTPUT, @overhead decimal(20,8) OUTPUT,
	@labor decimal(20,8) OUTPUT, @utility decimal(20,8) OUTPUT , @l_typ char(1),
        @lot_ser varchar(255) = ''
AS
begin	-- start procedure



declare 
@old_qty decimal(20,8),
  @retval int,
  @seq int, @qty_bal decimal(20,8),
  @hist_tran_date datetime, @hist_tran_age datetime, @hist_unit_cost decimal(20,8),
  @hist_qty decimal(20,8), @hist_direct decimal(20,8), @hist_ovhd decimal(20,8),
  @hist_labor decimal(20,8), @hist_util decimal(20,8), @hist_acct varchar(10),
  @hist_bal decimal(20,8),
  @audit int,
  @hold_seq int, @test_tran_date datetime, @test_seq int,
  @maxseq int, @counter int,
  @move_qty decimal(20,8), @move_seq_to_use int,
  @l_unitcost decimal(20,8), @l_direct decimal(20,8), @l_overhead decimal(20,8), @l_utility decimal(20,8),
  @l_org_cost decimal(20,8), @l_tran_age datetime,

  
  @temp_dir decimal(20,8), @temp_oh decimal(20,8), @temp_utl decimal(20,8),		-- mls 9/18/00 23804
  @total_stock_qty decimal(20,8),
  @po_line int,								-- mls #16
  @dummycost decimal(20,8),
  @new_audit int,									-- mls 5/17/00 SCR 22897
  @mls_m_cost decimal(20,8), @mls_qty decimal(20,8),				-- mls 12/20/00 SCR 25339
  @mls_d_cost decimal(20,8), @mls_u_cost decimal(20,8), @mls_o_cost decimal(20,8), -- mls 12/20/00 SCR 25339
  @mls_l_cost decimal(20,8),
  @layers_above int						-- mls 6/6/01 SCR 27048

declare @rcpt_cost decimal(20,8)						-- mls 2/24/05 SCR 34297
declare 
  @f_unitcost decimal(20,8), @f_direct decimal(20,8), @f_overhead decimal(20,8), @f_utility decimal(20,8),
  @a_tran_id int, @tot_neg_bal decimal(20,8), @neg_bal decimal(20,8), @negaudit int,
  @cost_bal decimal(20,8), @move_cost decimal(20,8),
  @qty_used decimal(20,8), @inv_qty decimal(20,8), @orig_unitcost decimal(20,8),
  @temp decimal(20,8)





































--if @qty=0 return 1							-- mls
-- qty can be zero if you are adjusting the receipt to zero




if (@l_typ != 'E') return 0

if exists (select 1 from inv_costing where part_no = @part and location = @loc
  and account = @account and  balance < 0)
  return 0


select @old_qty = @qty - @delta_qty,
  @f_unitcost = 0, @f_direct = 0, @f_overhead = 0, @f_utility = 0,
  @tot_neg_bal = 0, @cogs_qty = 0, @orig_unitcost = @unitcost

select @rcpt_cost = case when @qty = 0 then 0 else @rcpt_unitcost / @qty end	-- mls 2/24/05 SCR 34297




select @seq = isnull(sequence,0), @qty_bal = balance,  @audit = audit, @cost_bal = balance * unit_cost
from inv_costing 
where part_no=@part and location=@loc and account=@account and tran_no=@tran_no and tran_ext=@tran_ext and
  tran_line=@tran_line and tran_code=@tran_code and lot_ser = @lot_ser and
  sequence = (select max(sequence) 							-- mls 3/26/02 SCR 28570
    from inv_costing where part_no=@part and location=@loc and account=@account and 
    tran_no=@tran_no and tran_ext=@tran_ext and tran_line=@tran_line and tran_code=@tran_code and lot_ser = @lot_ser )


--check if the row is gone
if @@rowcount = 0
  select @seq = 0

if @seq=0 
begin        -- check cost history
  select @qty_bal = 0, @hist_tran_date = tran_date, @hist_tran_age = tran_age,
    @hist_unit_cost = unit_cost, @hist_qty  = quantity, @hist_direct  = direct_dolrs,
    @hist_ovhd  = ovhd_dolrs, @hist_labor  = labor, @hist_util  = util_dolrs, @hist_acct  = account,
    @audit   = audit
  from inv_cost_history (nolock)
  where part_no=@part and location=@loc and account=@account and tran_no=@tran_no
    and tran_ext=@tran_ext and tran_line=@tran_line and tran_code=@tran_code 
    and ins_del_flag = 1 and lot_ser = @lot_ser
    -- bring only one of the rows back from history, if there are multiple rows
    and audit = (select max(audit) from inv_cost_history 
    where part_no=@part and location=@loc and account=@account and tran_no=@tran_no
      and tran_ext=@tran_ext and tran_line=@tran_line and tran_code=@tran_code 
      and lot_ser = @lot_ser
      and ins_del_flag = 1)									-- mls 9/25/00

  -- check the row count instead of the history qty.  It could be that the receipt was altered to
  -- a quantity of zero causing it to be written to the history table.  In that case, the hist qty
  -- would be zero.

  if @@rowcount = 0 return 0	-- couldn't find the quantity in the history table  --mls
  -- this is the historical row.... need to update this in the inv_costing table,
  -- and delete it from the inv_cost_history (scenario 3)

  -- added this section of code.  If this record is in history, bring it to the costing table
  -- with a zero quantity balance so it can be modified the same as if it was already on the
  -- table.
  -- NOTE:  May need to check if quantity changes since you may not need to do this if it is 
  -- only a price change. - mls

  -- mls start
  delete inv_cost_history 
  from inv_cost_history 
  where part_no=@part and location=@loc and account=@account and tran_no=@tran_no and tran_ext=@tran_ext and
    tran_code=@tran_code and tran_line=@tran_line and audit = @audit and lot_ser = @lot_ser

  if @@error > 0 return 0

  -- need to figure out the sequence number for this historical row as it goes back into
  -- the costing layers
  select @maxseq = isnull((select max(sequence) from inv_costing where part_no = @part and
    location = @loc and account = @account),0)

  select @counter = 1, @hold_seq=0

  while (@counter <= @maxseq) 
  begin
    select @test_tran_date = isnull((select 
      case when balance < 0 then '1/1/1900' else tran_date end from inv_costing			-- mls 5/11/00 SCR 22872 start
    where part_no=@part and location=@loc and account=@account and sequence=@counter),NULL)
	
    if @test_tran_date is not NULL 
    begin
      select @test_seq = @counter
      if @test_tran_date = '1/1/1900'
        select @hold_seq = @test_seq
      else
        if DATEDIFF(ss, @hist_tran_date, @test_tran_date) <= 0 
          select @hold_seq = @test_seq  	-- this number changes each time and should be the last unchanged row
                                        -- The historical row will be inserted back into the layers in the next position
        else 
          break
    end
  
    select @counter = @counter+1
  end	-- end while loop

  -- begin to increase the sequence number for the rows to follow the inserted row
  -- need to start at the bottom of the stack to avoid problems with duplicate rows
  select @counter = @maxseq
  while (@counter > @hold_seq) 
  begin
    update inv_costing set sequence=(sequence + 1) 
    where part_no=@part and location=@loc and account=@account and sequence = @counter

    select @counter=@counter-1
  end		
	
  select @seq = (@hold_seq + 1)
  insert inv_costing (part_no,location,sequence,tran_code,tran_no,tran_ext, tran_line, account,
    tran_date,tran_age,unit_cost,quantity,balance,direct_dolrs,ovhd_dolrs, labor,util_dolrs, org_cost,
    tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost, lot_ser) 
  select @part, @loc, @seq, @tran_code, @tran_no, @tran_ext, @tran_line,@hist_acct,
    @hist_tran_date, @hist_tran_age, abs(@rcpt_cost), @old_qty,0,0,0,0,0, @rcpt_cost,	-- mls 2/24/05 SCR 34297
    0, 0, 0, 0, 0, @lot_ser

  select @new_audit = @@IDENTITY							-- mls 5/17/00 SCR 22897 start

  update inv_cost_history
  set audit = @new_audit
  where part_no = @part and location = @loc and audit = @audit			

  -- bring the record into inv_costing with the current unitcost not the old unitcost
  if @@error > 0 return 0											
	
  select @audit = @new_audit							-- mls 5/17/00 SCR 22897 end
end -- @seq = 0	-- check cost history





-- receipt should be on inv_costing or inv_cost_history but not both.  If it was on history, it is move to inv_costing
-- and deleted from history.  Therefore, it should be on one or the other but not both.


select @move_qty = 0, @temp_dir = 0, @temp_oh = 0, @temp_utl = 0


-- @delta_qty is positive if quantity is increased
-- @delta_qty is negative if quantity is decreased
-- if it is going to be negative, there may be a problem if the amount is less than the current balance
select @move_qty = @delta_qty
select @move_cost = @unitcost

if @delta_qty != 0 or @qty_bal != 0
begin
  -- check for negative rows for this part, accumulate the negative balances and delete them
  select @total_stock_qty = sum(balance)
  from inv_costing 
  where part_no=@part and location=@loc and account = @account

  -- using up the cost layer either by taking its cost or taking all of its balance
  
  --(scenarios 2a, 2b)
  -- also need to check if the row is @qty_bal is negative.... if so, there will be a problem
  if @move_cost != 0 or @move_qty != 0
  begin
    -- select the row next in the sequence, if possible
    select @maxseq = isNull((Select max(sequence) 
    from inv_costing where part_no=@part and location=@loc and account=@account), 0)

    select @move_seq_to_use= @seq, @layers_above = 0

    -- the original row has already been deleted, so the maximum number is reduced by 1
    while ((@move_qty != 0 or @move_cost != 0 or @temp_dir != 0 or @temp_oh != 0 or @temp_utl != 0)   -- mls 9/18/00 23804
      AND (@move_seq_to_use <= @maxseq))  
    begin -- mls 5/11/00 SCR 22872
      -- loop through while there is still a quantity to redistribute and there are still sequence numbers
      select @audit = 0
      if (@move_seq_to_use > 0) and @layers_above = 0										-- mls 6/6/01 SCR 27048
      begin
        select @qty_bal = balance , @audit = audit, 
          @l_unitcost = unit_cost, @l_direct = direct_dolrs, @l_overhead = ovhd_dolrs, @l_utility = util_dolrs,
          @l_org_cost = org_cost, @l_tran_age = tran_age,
          @mls_m_cost = isnull(tot_mtrl_cost,(balance * unit_cost)),
          @mls_d_cost = isnull(tot_dir_cost,(balance * direct_dolrs)),
          @mls_o_cost = isnull(tot_ovhd_cost,(balance * ovhd_dolrs)),
          @mls_u_cost = isnull(tot_util_cost,(balance * util_dolrs)),
          @mls_l_cost = isnull(tot_labor_cost,(balance * labor))
        from inv_costing 
        where part_no=@part and location=@loc and account=@account and sequence = @move_seq_to_use
        if @@rowcount = 0
          select @qty_bal = 0, @audit = 0, @cost_bal = 0, @move_seq_to_use = @move_seq_to_use -1
      end
      else
      begin
        if @layers_above = 0
          select @move_seq_to_use = @move_seq_to_use+1
        select @layers_above = 1	

        if @move_seq_to_use = @seq
          select @move_seq_to_use = @move_seq_to_use + 1

        select @qty_bal = balance , @audit = audit, 
          @l_unitcost = unit_cost, @l_direct = direct_dolrs, @l_overhead = ovhd_dolrs, @l_utility = util_dolrs,
          @l_org_cost = org_cost, @l_tran_age = tran_age,
          @mls_m_cost = isnull(tot_mtrl_cost,(balance * unit_cost)),
          @mls_d_cost = isnull(tot_dir_cost,(balance * direct_dolrs)),
          @mls_o_cost = isnull(tot_ovhd_cost,(balance * ovhd_dolrs)),
          @mls_u_cost = isnull(tot_util_cost,(balance * util_dolrs)),
          @mls_l_cost = isnull(tot_labor_cost,(balance * labor))
        from inv_costing 
        where part_no=@part and location=@loc and account=@account and sequence = @move_seq_to_use

        if @@rowcount = 0
          select @qty_bal = 0, @audit = 0, @cost_bal = 0
      end

      if @audit != 0
      begin
        if @move_seq_to_use = @seq
        begin
          insert into inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,	-- mls 9/25/00 start
            tran_ext,tran_line,account,tran_date,tran_age,unit_cost,quantity,
            inv_cost_bal,direct_dolrs,ovhd_dolrs,labor,util_dolrs, audit, org_cost,
            tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost)
          select @part, @loc ,-1, 'R',
            @tran_no,@tran_ext,@tran_line,@account,@tran_date,@l_tran_age,@l_unitcost,abs(@delta_qty),
            @qty_bal,@l_direct,@l_overhead,0,@l_utility,@audit, @l_org_cost,
            @mls_m_cost, @mls_d_cost, @mls_o_cost, @mls_u_cost, @mls_l_cost
        end -- @move_seq_to_use = @seq

        if @qty_bal + @move_qty < 0  
          return 0

        select @mls_qty = case when @qty_bal + @move_qty > 0 then @qty_bal + @move_qty else 0 end

        if @mls_qty = 0
        begin
          select @f_unitcost = @f_unitcost - @mls_m_cost, 
            @f_direct = @f_direct - @mls_d_cost,
            @f_overhead = @f_overhead - @mls_o_cost,
            @f_utility = @f_utility - @mls_u_cost,
            @move_qty = @move_qty + @qty_bal

          select
            @move_cost = @move_cost + @mls_m_cost,
            @temp_dir = @temp_dir + @mls_d_cost,
            @temp_oh = @temp_oh + @mls_o_cost, 
            @temp_utl = @temp_utl + @mls_u_cost

          delete inv_costing 
            where audit = @audit
        end
        else
        begin
          if @move_seq_to_use = @seq and @delta_qty = 0
          begin
            select @cogs_qty = case when @qty_bal <= @qty then @qty - @qty_bal else @qty end
            select @temp = @unitcost * @qty_bal 
            select @move_cost = @temp / @qty
          end

          select @f_unitcost = @f_unitcost + case when (@mls_m_cost + @move_cost) < 0 then - @mls_m_cost else @move_cost end,
            @f_direct = @f_direct + case when (@mls_d_cost + @temp_dir) < 0 then  -@mls_d_cost else @temp_dir end,
            @f_overhead = @f_overhead + case when (@mls_o_cost + @temp_oh) < 0 then -@mls_o_cost else @temp_oh end,
            @f_utility = @f_utility + case when (@mls_u_cost + @temp_utl) < 0 then -@mls_u_cost else @temp_utl end

          select @cost_bal = @mls_m_cost
          select @mls_m_cost = case when @mls_m_cost + @move_cost < 0 then 0 else (@mls_m_cost + @move_cost) end,
            @mls_d_cost = case when @mls_d_cost + @temp_dir < 0 then 0 else (@mls_d_cost + @temp_dir) end,
            @mls_o_cost = case when @mls_o_cost + @temp_oh < 0 then 0 else (@mls_o_cost + @temp_oh) end,           
            @mls_u_cost = case when @mls_u_cost + @temp_utl < 0 then 0 else (@mls_u_cost  + @temp_utl) end

          select
            @move_qty = 0,
            @move_cost = case when @cost_bal + @move_cost < 0 then @move_cost + @cost_bal else 0 end,
            @temp_dir = 0,
            @temp_oh = 0,
            @temp_utl = 0

          select @l_unitcost = @mls_m_cost / @mls_qty,        
            @l_direct = @mls_d_cost / @mls_qty,
            @l_overhead = @mls_o_cost / @mls_qty,
            @l_utility = @mls_u_cost / @mls_qty                        -- mls 12/6/00 SCR 25339 end

          update inv_costing 
          set unit_cost = @l_unitcost,                        -- mls 12/6/00 SCR 25339
            direct_dolrs = @l_direct,
            ovhd_dolrs = @l_overhead,
            util_dolrs = @l_utility,
            balance= @mls_qty,                                -- mls 12/6/00 SCR 25339
            quantity = case when @move_seq_to_use = @seq then @qty else quantity end,
            org_cost = case when @move_seq_to_use = @seq then @rcpt_cost else org_cost end,	-- mls 2/24/05 SCR 34297
            tot_mtrl_cost = @mls_m_cost,
            tot_dir_cost = @mls_d_cost,
            tot_ovhd_cost = @mls_o_cost,
            tot_util_cost = @mls_u_cost,
            tot_labor_cost = @mls_l_cost
          where audit = @audit

        end

        if @move_seq_to_use = @seq
        begin
          --if this were a zero quantity, zero balance row, delete it from history too
          delete inv_cost_history 
          where part_no=@part and location=@loc and account=@account and tran_no=@tran_no 
            and tran_ext=@tran_ext and tran_code=@tran_code and tran_line=@tran_line and quantity=0
            and inv_cost_bal=0 and audit <> @audit
        end
      end
      select @move_seq_to_use = @move_seq_to_use + case when @layers_above = 0 then -1 else 1 end
    end -- end while loop

    if @delta_qty = 0 and @move_cost != 0
    begin
      select @move_cost = 0
    end

    if (@move_qty < 0) or @move_cost != 0
    begin -- there are no more rows but still quantity left, so add a negative row
--      if @move_cost != 0 and @move_qty = 0						-- mls 2/26/04
--        select @f_unitcost = @f_unitcost + @move_cost

      if @move_qty < 0
      begin
        return 0
      end 
    end
  end -- end the remainder problem
end -- if (@move_cost < 0 AND abs(@move_cost) > @cost_bal) or (@delta_qty < 0 and abs(@delta_qty) > @qty_bal)
if @qty_bal = 0 and @delta_qty = 0
begin
  delete inv_costing
  where audit = @audit
end
if @delta_qty != 0
begin
  select @unitcost = @f_unitcost,
    @direct = @f_direct,
    @overhead = @f_overhead,
    @utility = @f_utility,
    @cogs_qty = @move_qty - @tot_neg_bal,
    @inv_qty = @delta_qty
end
else
begin
  select @inv_qty = @qty - @cogs_qty
  select @unitcost = @f_unitcost,
    @direct = @f_direct ,
    @overhead = @f_overhead,
    @utility = @f_utility
end




























return 1
end -- end procedure
GO
GRANT EXECUTE ON  [dbo].[fs_serial_cost_update] TO [public]
GO
