SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[TXBaseRangeCheck_sp] @tt_row int, @ttr_row int, @ti_row int, @ti_extended_price decimal(20,8),
@debug int = 0
as

if @debug > 0
  print 'entering TXBaseRangeCheck_sp'

declare @tt_tax_based_type int, 
@tt_base_taxed_type int,
@tt_cents_code_flag smallint, 
@tt_base_range_type int,
@tt_min_base_amt decimal(20,8), 
@tt_max_base_amt decimal(20,8), 
@tt_amt_taxable decimal(20,8), 
@tt_tax_rate decimal(20,8), 
@tt_modify_base_prc decimal(20,8), 
@tt_ext_amt decimal(20,8),
@ti_freight decimal(20,8), 
@ti_qty decimal(20,8), 
@ti_unit_price decimal(20,8), 
@ti_amt_discount decimal(20,8),
@ttr_cur_amt decimal(20,8),
@ti_curr_precision int,
@baseamt decimal(20,8), 
@qty decimal(20,8),
@rc int,
@ti_control_number varchar(20),
@tt_total_inv decimal(20,8), 
@tt_prev_amt_taxed decimal(20,8), 
@tt_tax_type varchar(20)



select @tt_tax_based_type = tax_based_type ,
@tt_min_base_amt = min_base_amt,
@tt_max_base_amt = max_base_amt,
@tt_base_taxed_type = base_taxed_type,
@tt_cents_code_flag = cents_code_flag,
@tt_base_range_type = base_range_type,
@tt_tax_rate = tax_rate,
@tt_modify_base_prc = modify_base_prc,
@tt_amt_taxable = amt_taxable,
@tt_ext_amt = ext_amt,
@tt_tax_type = tax_type
from #TXtaxtype
where row_id = @tt_row
if @@rowcount = 0 return -1

select @ti_curr_precision = curr_precision,
@ti_freight = freight, @ti_qty = qty, @ti_unit_price = unit_price,
@ti_amt_discount = amt_discount,
@ti_control_number = control_number
from #TXLineInput_ex
where row_id = @ti_row
if @@rowcount = 0 return -1

select @tt_total_inv = sum(extended_price)
from #TXLineInput_ex
where control_number = @ti_control_number

select @tt_prev_amt_taxed = sum(tt.amt_taxable)
from #TXLineInput_ex ti
join #TXtaxcode tc on tc.ti_row = ti.row_id
join #TXtaxtyperec ttr on ttr.tc_row = tc.row_id
join #TXtaxtype tt on tt.ttr_row = ttr.row_id
where ti.control_number = @ti_control_number
and tt.tax_type = @tt_tax_type and tt.row_id <> @tt_row


select @ttr_cur_amt = cur_amt
from #TXtaxtyperec 
where row_id = @ttr_row

if @tt_tax_based_type = 2 -- tax on freight
begin
  select @baseamt = @ttr_cur_amt
  
  if (@baseamt < @tt_min_base_amt) or (@baseamt > @tt_max_base_amt)
    select @baseamt = 0
 
  update #TXtaxtype
  set amt_gross = amt_gross + @ti_freight
  from #TXtaxtype 
  where row_id = @tt_row 
  
  if @baseamt > 0
  begin
    if @tt_base_taxed_type = 1	-- portion based
      select @baseamt = @baseamt - @tt_min_base_amt
    
    update #TXtaxtype
    set amt_taxable = amt_taxable + @baseamt
    where row_id = @tt_row

    if @tt_cents_code_flag = 1
    begin
      exec @rc = TXCalCentsTax_sp @tt_row, @baseamt, @ti_curr_precision, @ttr_cur_amt OUT, @debug
      if @rc < 1 return @rc

      update #TXtaxtyperec
      set cur_amt = @ttr_cur_amt
      where row_id = @ttr_row
    end
    else
      update #TXtaxtyperec
      set cur_amt = round(@baseamt * (@tt_tax_rate/100),@ti_curr_precision)
      where row_id = @ttr_row 
  end
  else     
    update #TXtaxtyperec
    set cur_amt = 0
    where row_id = @ttr_row

  return 1
end 
if @tt_base_range_type = 0
begin
  update #TXtaxtype
  set amt_gross = amt_gross + @ti_extended_price
  where row_id = @tt_row

  select @baseamt = @ti_unit_price, @qty = @ti_qty

  select @baseamt = @baseamt * (@tt_modify_base_prc / 100)

  if @tt_base_taxed_type = 1 -- portion base
  begin
    if @baseamt < @tt_min_base_amt
      select @baseamt = 0
    else
    begin
      if @baseamt > @tt_max_base_amt
        select @baseamt = @tt_max_base_amt

      select @baseamt = (@baseamt - @tt_min_base_amt) * @qty
    end      
  end
  else
  begin
    if @baseamt < @tt_min_base_amt or @baseamt > @tt_max_base_amt
      select @baseamt = 0
  end

  select @baseamt = round(@baseamt, @ti_curr_precision)

  select @tt_amt_taxable = @tt_amt_taxable + @baseamt
  update #TXtaxtype
  set amt_taxable = @tt_amt_taxable
  where row_id = @tt_row

  if @tt_cents_code_flag = 1
  begin
    exec @rc = TXCalCentsTax_sp @tt_row, @tt_amt_taxable, @ti_curr_precision, @ttr_cur_amt OUT, @debug
    if @rc < 1 return @rc

    update #TXtaxtyperec
    set cur_amt = @ttr_cur_amt
    where row_id = @ttr_row   
  end
  else
  begin
    update #TXtaxtyperec
    set cur_amt = round (@tt_amt_taxable * (@tt_tax_rate / 100), @ti_curr_precision)
    where row_id = @ttr_row 

    update #TXLineInput_ex
    set calc_tax = calc_tax + round (@baseamt * (@tt_tax_rate / 100), @ti_curr_precision)
    where row_id = @ti_row
  end
end
else if @tt_base_range_type = 1 -- base extended price
begin
  update #TXtaxtype
  set amt_gross = amt_gross + @ti_extended_price
  where row_id = @tt_row
 
  select @baseamt = round ((@ti_extended_price - @ti_amt_discount) *
    (@tt_modify_base_prc / 100),@ti_curr_precision)

  if @tt_base_taxed_type = 1 -- portion base
  begin
    if @baseamt < @tt_min_base_amt
      select @baseamt = 0
    else
    begin
      if @baseamt > @tt_max_base_amt
        select @baseamt = @tt_max_base_amt

      select @baseamt = @baseamt - @tt_min_base_amt
    end
  end
  begin
    if @baseamt < @tt_min_base_amt or @baseamt > @tt_max_base_amt
      select @baseamt = 0
  end

  select @tt_amt_taxable = @tt_amt_taxable + @baseamt

  update #TXtaxtype
  set amt_taxable = @tt_amt_taxable
  where row_id = @tt_row

  if @tt_cents_code_flag = 1
  begin
    exec @rc = TXCalCentsTax_sp @tt_row, @baseamt, @ti_curr_precision, @ttr_cur_amt OUT, @debug
    if @rc < 1 return @rc

    update #TXtaxtyperec
    set cur_amt = @ttr_cur_amt
    where row_id = @ttr_row
  end
  else
  begin
    update #TXtaxtyperec
    set cur_amt = round (@tt_amt_taxable * (@tt_tax_rate / 100),@ti_curr_precision)
    where row_id = @ttr_row 

    update #TXLineInput_ex
    set calc_tax = round( @baseamt * (@tt_tax_rate / 100), @ti_curr_precision)
    where row_id = @ti_row 
  end
end
else if @tt_base_range_type = 2 -- total invoice
begin
  select @tt_ext_amt = @tt_ext_amt + @ti_extended_price

  update #TXtaxtype
  set ext_amt = @tt_ext_amt,
    amt_gross = amt_gross + @ti_extended_price
  where row_id = @tt_row

  select @baseamt = @tt_total_inv

  select @baseamt = round ( @baseamt * (@tt_modify_base_prc / 100), @ti_curr_precision)

  if @tt_base_taxed_type = 1	-- portion base
  begin
    if @baseamt < @tt_min_base_amt
      select @baseamt = 0
    else
    begin
      if @baseamt > @tt_max_base_amt
        select @baseamt = @tt_max_base_amt
      
      select @baseamt = @baseamt - @tt_min_base_amt
      select @baseamt = @baseamt - isnull(@tt_prev_amt_taxed,0)

	  if @baseamt < 0 
		set @baseamt = 0
	
	  if @baseamt > @ti_extended_price
		select @baseamt = @ti_extended_price
    end
  end
  else
  begin
    if @baseamt < @tt_min_base_amt or @baseamt > @tt_max_base_amt
      select @baseamt = 0
   else
      select @baseamt = @ti_extended_price
  end

  if @debug > 0
  begin
    print '#TXtaxtype'
    select * from #TXtaxtype
    print '@baseamt'
    select @baseamt
  end

  update #TXtaxtype
  set amt_taxable = @baseamt
  where row_id = @tt_row

  if @tt_cents_code_flag = 1
  begin
    exec @rc = TXCalCentsTax_sp @tt_row, @baseamt, @ti_curr_precision, @ttr_cur_amt OUT, @debug
    if @rc < 1 return @rc

    update #TXtaxtyperec
    set cur_amt = @ttr_cur_amt
    where row_id = @ttr_row
  end
  else
  begin
    update #TXtaxtyperec
    set cur_amt = round (@baseamt * (@tt_tax_rate / 100),@ti_curr_precision)
    from #TXtaxtyperec 
    where row_id = @ttr_row

    update #TXLineInput_ex
    set calc_tax = calc_tax + round (@baseamt * (@tt_tax_rate / 100), @ti_curr_precision)
    where row_id = @ti_row
  end
end
else  return -1

return 1
GO
GRANT EXECUTE ON  [dbo].[TXBaseRangeCheck_sp] TO [public]
GO
