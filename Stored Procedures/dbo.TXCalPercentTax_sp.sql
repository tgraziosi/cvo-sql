SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[TXCalPercentTax_sp] @tc_row int, @ttr_row int, @ti_row int, @tt_row int,
 @tt_tax_type varchar(8), @debug int = 0
as
declare @rc int,
  @ti_action_flag smallint,
  @ti_curr_precision int,
  @ti_extended_price decimal(20,8),
  @ti_amt_discount decimal(20,8),
  @ti_freight decimal(20,8),
  @ti_vat_prc decimal(20,8),
  @tt_tax_rate decimal(20,8),
  @tt_prc_flag smallint,
  @tt_prc_type int,
  @tt_cents_code_flag smallint,
  @tt_cents_code varchar(8),
  @tt_cents_cnt int,
  @tt_tax_based_type int,
  @tt_tax_included_flag smallint,
  @tt_modify_base_prc decimal(20,8),
  @tt_base_range_flag smallint,
  @tt_base_range_type int,
  @tt_base_taxed_type int,
  @tt_min_base_amt decimal(20,8),
  @tt_max_base_amt decimal(20,8),
  @tt_tax_range_flag smallint,
  @tt_tax_range_type int,
  @tt_min_tax_amt decimal(20,8),
  @tt_max_tax_amt decimal(20,8),
  @tt_amt_final_tax decimal(20,8),
  @tt_amt_taxable decimal(20,8),
  @ttr_cur_amt decimal(20,8),
  @base_amount decimal(20,8),
  @cent_base_amt decimal(20,8),
  @cent_tax_amt decimal(20,8),
  @prev_ttr_row int, 
  @prev_extended_price decimal(20,8)

select @ti_action_flag = action_flag, @ti_curr_precision = curr_precision,
@ti_extended_price = extended_price, @ti_amt_discount = amt_discount,
@ti_freight = freight, @ti_vat_prc = vat_prc
from #TXLineInput_ex where row_id = @ti_row

if @@rowcount = 0 return -1

select @tt_tax_rate = tax_rate, @tt_prc_flag = prc_flag, @tt_prc_type = prc_type,
@tt_cents_code_flag = cents_code_flag, @tt_cents_code = cents_code, 
@tt_tax_based_type = tax_based_type, @tt_tax_included_flag = tax_included_flag,
@tt_modify_base_prc = modify_base_prc, @tt_base_range_flag = base_range_flag,
@tt_base_range_type = base_range_type, @tt_base_taxed_type = base_taxed_type,
@tt_min_base_amt = min_base_amt, @tt_max_base_amt = max_base_amt, 
@tt_tax_range_flag = tax_range_flag, @tt_tax_range_type = tax_range_type,
@tt_min_tax_amt = min_tax_amt, @tt_max_tax_amt = max_tax_amt,
@tt_amt_final_tax = amt_final_tax, @tt_amt_taxable = amt_taxable
from #TXtaxtype where row_id = @tt_row

if @@rowcount = 0 return -1






if (@ti_action_flag = 1 and @tt_tax_based_type != 2) or
  (@tt_tax_based_type = 2 and @ti_action_flag != 1)
  return 1

update #TXtaxtyperec
set cur_amt = 0,
old_tax = 0
--old_tax = @tt_amt_final_tax
--old_tax = case when @tt_prc_type = 0 then @tt_amt_final_tax else old_tax end
where row_id = @ttr_row

if @@rowcount = 0 return -1

select @ttr_cur_amt = 0

if @debug > 0
begin
print 'cal_percent_tax - begin - #TXtaxtype table'
select * from #TXtaxtype where row_id = @tt_row
select * from #TXLineInput_ex where row_id = @ti_row
end

if @tt_prc_type = 0 -- base sales amt
begin
  if @tt_tax_based_type not in (0,2) return -1

  select @base_amount = 
    case when @tt_tax_based_type = 0 then @ti_extended_price - @ti_amt_discount
    else @ti_freight
    end

  select @ttr_cur_amt = round(@base_amount * (@tt_modify_base_prc / 100),@ti_curr_precision)

  if @ti_vat_prc != 0
    select @ttr_cur_amt = @ttr_cur_amt - (@ttr_cur_amt * (@ti_vat_prc / 100))
 
  update #TXtaxtyperec
  set cur_amt = @ttr_cur_amt
  where row_id = @ttr_row 

  if @tt_base_range_flag = 1
  begin
    exec @rc = TXBaseRangeCheck_sp @tt_row, @ttr_row, @ti_row, @ti_extended_price, @debug
    if @rc < 1 return @rc
  end  
  else
  begin
    select @tt_amt_taxable = @tt_amt_taxable + @ttr_cur_amt

    update #TXtaxtype
    set 
      amt_taxable = @tt_amt_taxable,
      amt_gross = amt_gross + @ti_extended_price
    from #TXtaxtype 
    where row_id = @tt_row 

    if @tt_cents_code_flag = 1
    begin
      exec @rc = TXCalCentsTax_sp @tt_row, @ttr_cur_amt, @ti_curr_precision, 	-- mls 5/15/03 SCR 31155 start
        @cent_tax_amt OUT, @debug
      if @rc < 1 return @rc
      
      update #TXLineInput_ex
      set calc_tax = calc_tax + @cent_tax_amt
      where row_id = @ti_row 								-- mls 5/15/03 SCR 31155 end

      exec @rc = TXCalCentsTax_sp @tt_row, @tt_amt_taxable, @ti_curr_precision, 	-- mls 5/15/03 SCR 31155
        @cent_tax_amt OUT, @debug
      if @rc < 1 return @rc
      
      update ttr					-- mls 11/25/02 SCR 30263
      set cur_amt = @cent_tax_amt							-- mls 5/15/03 SCR 31155
      from #TXtaxtyperec ttr
      where ttr.row_id = @ttr_row 
    end
    else
    begin
      if @debug > 0
      begin
        print 'updating calc tax'
        select ti.calc_tax, round(ttr.cur_amt * (@tt_tax_rate / 100), ti.curr_precision)
        from #TXLineInput_ex ti, #TXtaxtyperec ttr
        where ti.row_id = @ti_row and ttr.row_id = @ttr_row
      end

      update #TXLineInput_ex
      set calc_tax = calc_tax + round(@ttr_cur_amt * (@tt_tax_rate / 100), @ti_curr_precision)
      where row_id = @ti_row 

      update #TXtaxtyperec
      set cur_amt = @tt_amt_final_tax + round(@ttr_cur_amt * (@tt_tax_rate / 100), @ti_curr_precision)
      where row_id = @ttr_row 
    end
  end
end
else if (@tt_prc_type in (1,2)) -- previous tax types
begin
if @ti_row > 1 and @tt_row > 1 and @debug > 0							-- mls 9/19/03 SCR 31907
begin
select @ti_row ti_row, @tt_row tt_row, @ttr_row ttr_row, @tc_row tc_row
print 'taxinfo'
select row_id, reference_number, extended_price, calc_tax from #TXLineInput_ex
print 'taxtype'
select row_id, ttr_row, tax_type, amt_taxable, amt_tax, amt_final_tax from #TXtaxtype
print 'taxtyperec'
select row_id, tc_row, tax_code, seq_id, base_id, cur_amt, old_tax from #TXtaxtyperec
print 'taxcode'
select * from #TXtaxcode
end

  select @base_amount = ttr_prev.cur_amt - ttr_prev.old_tax, 
    @prev_ttr_row = ttr_prev.row_id
  from #TXtaxtyperec ttr_prev, #TXtaxtyperec ttr_curr
  where ttr_curr.row_id = @ttr_row and ttr_prev.seq_id = (ttr_curr.base_id) and
    ttr_prev.tc_row = ttr_curr.tc_row
  if @@rowcount = 0 return -1

  if @tt_prc_type = 2
  begin
    select @prev_extended_price = isnull((select case when tax_based_type = 1 then (amt_gross - @ti_amt_discount) else amt_taxable end
      from #TXtaxtype where ttr_row = @prev_ttr_row),@ti_extended_price - @ti_amt_discount)
    select @base_amount = @base_amount + @prev_extended_price
  end

  select @base_amount = round(@base_amount * (@tt_modify_base_prc / 100), @ti_curr_precision)

  select @ttr_cur_amt = round(@base_amount * (@tt_tax_rate / 100),@ti_curr_precision)
  select @tt_amt_taxable =  @base_amount

  update #TXtaxtype
  set amt_taxable = @tt_amt_taxable,
    amt_gross = amt_gross + @ti_extended_price
  where row_id = @tt_row

  update #TXLineInput_ex
  set calc_tax = calc_tax + @ttr_cur_amt
  where row_id = @ti_row 

  update #TXtaxtyperec
  set cur_amt = @tt_amt_final_tax + @ttr_cur_amt
  where row_id = @ttr_row 
end
else return -1

exec @rc = TXRangeCheck_sp @ttr_row, @ti_row, @tt_row, @debug

return @rc
GO
GRANT EXECUTE ON  [dbo].[TXCalPercentTax_sp] TO [public]
GO
