SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[TXCalFlatTax_sp] @ttr_row int, @ti_row int, @tt_row int, @tt_tax_type varchar(8),
@debug int = 0
as

declare @ti_curr_precision int,
  @ti_extended_price decimal(20,8),
  @ti_qty decimal(20,8),
  @ti_unit_price decimal(20,8),
  @ti_action_flag smallint,
  @ti_amt_discount decimal(20,8),
  @ti_freight decimal(20,8),
  @ti_vat_prc decimal(20,8),
  @ttr_cur_amt decimal(20,8),
  @tt_tax_based_type int,
  @tt_prc_flag smallint,
  @tt_tax_rate decimal(20,8),
  @tt_modify_base_prc decimal(20,8),
  @rc int, 
  @based_on decimal(20,8),
  @tt_base_range_flag smallint,
  @tt_base_range_type int,
  @tt_min_base_amt decimal(20,8),
  @tt_max_base_amt decimal(20,8)

update #TXtaxtyperec
set cur_amt = 0
where row_id = @ttr_row

select @ttr_cur_amt = 0

select @ti_curr_precision = curr_precision,
@ti_extended_price = extended_price,
@ti_qty = qty,
@ti_unit_price = unit_price,
@ti_action_flag = action_flag,
@ti_amt_discount = amt_discount,
@ti_freight = freight,
@ti_vat_prc = vat_prc
from #TXLineInput_ex where row_id = @ti_row

select @tt_tax_based_type = tax_based_type,
  @tt_prc_flag = prc_flag,
  @tt_tax_rate = tax_rate,
  @tt_base_range_flag = base_range_flag,
  @tt_base_range_type = base_range_type,
  @tt_min_base_amt = min_base_amt,
  @tt_max_base_amt = max_base_amt,
  @tt_modify_base_prc = modify_base_prc
from #TXtaxtype 
where row_id = @tt_row

select @rc = 1

if (@ti_action_flag = 1 and @tt_tax_based_type != 2) or
  (@tt_tax_based_type = 2 and @ti_action_flag != 1)
  return 1

if @tt_tax_based_type in (0,2)	-- extend price or tax on freight
begin
  select @ttr_cur_amt = 
    case @tt_tax_based_type when 0 then @ti_extended_price - @ti_amt_discount
    else @ti_freight
    end

  select @ttr_cur_amt = round(@ttr_cur_amt * (@tt_modify_base_prc/100), @ti_curr_precision)

  if @ti_vat_prc != 0
    select @ttr_cur_amt = @ttr_cur_amt - (@ttr_cur_amt * (@ti_vat_prc/100))

  if @tt_base_range_flag = 1
  begin
    if @tt_base_range_type = 0	-- unit price
    begin
      if @ti_unit_price < @tt_min_base_amt or @ti_unit_price > @tt_max_base_amt
        select @ttr_cur_amt = 0
    end
    else if @tt_base_range_type = 1 -- extended price
    begin
      if @ttr_cur_amt < @tt_min_base_amt or @ttr_cur_amt > @tt_max_base_amt
        select @ttr_cur_amt = 0
    end
  end

  if @ttr_cur_amt != 0
    update #TXtaxtyperec
    set cur_amt = @tt_tax_rate
    where row_id = @ttr_row 

  update #TXtaxtype
  set amt_tax = amt_tax + case when @ttr_cur_amt != 0 then @tt_tax_rate else 0 end,
    amt_final_tax = amt_tax + case when @ttr_cur_amt != 0 then @tt_tax_rate else 0 end,
    amt_taxable = amt_taxable + @ttr_cur_amt,
    amt_gross = 
      case @tt_tax_based_type when 0 then @ti_extended_price - @ti_amt_discount
      else @ti_freight
      end
  from #TXtaxtype
  where row_id = @tt_row 
end
else if @tt_tax_based_type  = 1 -- qty
begin
  select @ttr_cur_amt = @ti_qty

  if @tt_base_range_flag = 1 
  begin
    if @tt_base_range_type = 0 -- unit price
    begin
      if @ti_unit_price < @tt_min_base_amt or @ti_unit_price > @tt_max_base_amt
        select @ttr_cur_amt = 0
    end
    else if @tt_base_range_type = 1 -- extended price
    begin
      select @based_on = @ti_extended_price - @ti_amt_discount
      if @based_on < @tt_min_base_amt or @based_on > @tt_max_base_amt
        select @ttr_cur_amt = 0
    end
  end

  if @ti_vat_prc != 0
    select @ttr_cur_amt = @ttr_cur_amt - (@ttr_cur_amt * (@ti_vat_prc/100))

  update #TXtaxtype
  set amt_tax = amt_tax + round(@tt_tax_rate * @ttr_cur_amt, @ti_curr_precision),
    amt_final_tax = amt_tax + round(@tt_tax_rate * @ttr_cur_amt, @ti_curr_precision),
    amt_taxable = amt_taxable + @ttr_cur_amt,
    amt_gross = amt_gross + @ti_extended_price
  from #TXtaxtype 
  where row_id = @tt_row 

  update #TXtaxtyperec
  set cur_amt = round(@tt_tax_rate * @ttr_cur_amt, @ti_curr_precision)
  where row_id = @ttr_row 

end
else return -1

return @rc
GO
GRANT EXECUTE ON  [dbo].[TXCalFlatTax_sp] TO [public]
GO
