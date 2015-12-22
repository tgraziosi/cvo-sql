SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[TXRangeCheck_sp] @ttr_row int, @ti_row int, @tt_row int, @debug int = 0
as
declare @qty decimal(20,8),
  @unit_price decimal(20,8),
  @ti_calc_tax decimal(20,8),
  @tt_tax_range_type int,
  @tt_tax_range_flag smallint,
  @tt_min_tax_amt decimal(20,8),
  @tt_max_tax_amt decimal(20,8),
  @tt_amt_tax decimal(20,8)

select @tt_tax_range_flag = tax_range_flag,
@tt_tax_range_type = tax_range_type,
@tt_min_tax_amt = min_tax_amt,
@tt_max_tax_amt = max_tax_amt,
@tt_amt_tax = amt_tax
from #TXtaxtype 
where row_id = @tt_row

if @@rowcount = 0 return -1

if @tt_tax_range_flag = 0
begin
  update tt
  set amt_tax = ttr.cur_amt,
    amt_final_tax = ttr.cur_amt
  from #TXtaxtype tt, #TXtaxtyperec ttr
  where tt.row_id = @tt_row and ttr.row_id = @ttr_row
end
else
begin
  select @qty = qty, @unit_price = unit_price,
    @ti_calc_tax = calc_tax
  from #TXLineInput_ex 
  where row_id = @ti_row

  if @@rowcount = 0 return -1

  if @qty > 0
  begin
    if @tt_tax_range_type = 1 -- per line item
    begin
      if @ti_calc_tax < @tt_min_tax_amt    
        select @tt_amt_tax = @tt_amt_tax + @tt_min_tax_amt
      else if @ti_calc_tax > @tt_max_tax_amt
        select @tt_amt_tax = @tt_amt_tax + @tt_max_tax_amt
      else
        select @tt_amt_tax = @tt_amt_tax + @ti_calc_tax

      update #TXtaxtype
      set amt_final_tax = @tt_amt_tax,
        amt_tax = @tt_amt_tax
      where row_id = @tt_row
    end
    else
    begin
      update #TXtaxtyperec
      set cur_amt = 
        case when cur_amt < @tt_min_tax_amt then @tt_min_tax_amt
          when cur_amt > @tt_max_tax_amt then @tt_max_tax_amt
          else cur_amt end
      where row_id = @ttr_row

      update tt
      set amt_tax = ttr.cur_amt,
      amt_final_tax = ttr.cur_amt
      from #TXtaxtype tt, #TXtaxtyperec ttr
      where tt.row_id = @tt_row and ttr.row_id = @ttr_row
    end
  end
end

return 1
GO
GRANT EXECUTE ON  [dbo].[TXRangeCheck_sp] TO [public]
GO
