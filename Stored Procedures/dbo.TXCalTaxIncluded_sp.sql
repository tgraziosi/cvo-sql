SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[TXCalTaxIncluded_sp] @tc_row int, @ti_row int, @ti_tax_code varchar(8),
@debug int = 0
as
declare @ti_curr_precision int,
  @ti_extended_price decimal(20,8),
  @ti_qty decimal(20,8),
  @ti_unit_price decimal(20,8),
  @ti_action_flag smallint,
  @ti_amt_discount decimal(20,8),
  @ti_freight decimal(20,8),
  @amt_gross decimal(20,8),												-- mls 12/14/05 SCR 35861
  @tt_tax_based_type int,
  @tt_prc_flag smallint,
  @tt_tax_rate decimal(20,8),
  @tt_row int,
  @tt_amt_taxable decimal(20,8),
  @tt_amt_gross decimal(20,8),
  @tt_amt_tax decimal(20,8),
  @tt_amt_tax_included decimal(20,8),
  @ttr_row int, 
  @tax_type varchar(8),
  @rc int,
  @amt_taxable decimal(20,8),
  @tot_incl_pct decimal(20,8)

select @ti_curr_precision = curr_precision,
@ti_extended_price = extended_price,
@ti_qty = qty,
@ti_unit_price = unit_price,
@ti_action_flag = action_flag,
@ti_amt_discount = amt_discount,
@ti_freight = freight
from #TXLineInput_ex where row_id = @ti_row

select @rc = 1

DECLARE c_taxtyperec CURSOR STATIC READ_ONLY FORWARD_ONLY FOR
select row_id, tax_type
from #TXtaxtyperec
where tc_row = @tc_row
order by seq_id

OPEN c_taxtyperec
IF @@cursor_rows > 0
BEGIN -- Begin 1
  FETCH c_taxtyperec INTO @ttr_row, @tax_type

  WHILE (@@fetch_status = 0) and @rc > 0
  BEGIN -- begin 2
if @debug > 0
begin
print 'tax_included'
select @tt_row, @ttr_row, @ti_row, @tc_row
print 'TXtaxtype'
select * from #TXtaxtype
print '#TXtaxtyperec'
select * from #TXtaxtyperec
end
    select @tt_tax_based_type = tax_based_type,
      @tt_prc_flag = prc_flag,
      @tt_tax_rate = tax_rate,
      @tt_row = row_id,
      @tt_amt_taxable = amt_taxable,
      @tt_amt_gross = amt_gross,
      @tt_amt_tax = amt_tax,
      @tt_amt_tax_included = amt_tax_included
    from #TXtaxtype 
    where ttr_row = @ttr_row and tax_type = @tax_type
 
    if (@ti_action_flag = 1 and @tt_tax_based_type != 2) or
     (@tt_tax_based_type = 2 and @ti_action_flag != 1)
     goto next_record

    if @tt_tax_based_type = 0	-- extend price
    begin

      if @tt_prc_flag = 1
      begin
        select @tot_incl_pct = sum(tt.tax_rate)
        from #TXtaxtype tt, #TXtaxtyperec ttr
        where tt.ttr_row = ttr.row_id and ttr.tc_row = @tc_row
          and tt.tax_based_type = 0 and tt.prc_flag = 1
		  and ttr.tax_type = @tax_type
  
  	    select @amt_gross = round((@ti_extended_price - @ti_amt_discount),@ti_curr_precision)		-- mls 12/14/05 SCR 35861
        select @amt_taxable = round((@ti_extended_price - @ti_amt_discount) / (1.0 + (@tot_incl_pct/100)),@ti_curr_precision)
        select @tt_amt_tax_included = @tt_amt_tax_included + (@amt_gross - @amt_taxable)
        select @tt_amt_tax = @tt_amt_tax_included

        update #TXLineInput_ex
        set calc_tax = calc_tax + (@amt_gross - @amt_taxable) 						-- mls 01/13/07 SCR 37382
          		-- round(@amt_taxable * (@tt_tax_rate/100),@ti_curr_precision)
        where row_id = @ti_row 

	    select @amt_taxable = @amt_gross
        select @tt_amt_taxable = @tt_amt_taxable + @amt_taxable
      end
      else
      begin
  	    select @amt_gross = @ti_extended_price - @ti_amt_discount					-- mls 12/14/05 SCR 35861
        select @amt_taxable = @ti_extended_price - @ti_amt_discount
        select @tt_amt_taxable = @tt_amt_taxable + @amt_taxable
        select @tt_amt_tax = @tt_amt_tax_included
        if @amt_taxable != 0
        begin
          select @tt_amt_tax_included = @tt_amt_tax_included + @tt_tax_rate
          select @tt_amt_tax = @tt_amt_tax_included

          update #TXLineInput_ex
          set calc_tax = calc_tax + @tt_tax_rate
          where row_id = @ti_row
        end
      end
      select @tt_amt_gross = @tt_amt_gross + @amt_gross

      update #TXtaxtype
      set amt_final_tax = @tt_amt_tax_included,
        amt_gross = @tt_amt_gross,
        amt_taxable = @tt_amt_taxable,
        amt_tax = @tt_amt_tax,
        amt_tax_included = @tt_amt_tax_included
      where row_id = @tt_row
    end
    else if @tt_tax_based_type = 2 -- tax on freight
    begin
      select @amt_taxable = @ti_freight
      select @tt_amt_taxable = @tt_amt_taxable + @amt_taxable
      select @tt_amt_gross = @tt_amt_gross + @amt_taxable
      select @tt_amt_tax = @tt_amt_tax_included

      if @tt_prc_flag = 1
      begin
        select @tt_amt_tax_included = @tt_amt_taxable - 
          round(@tt_amt_taxable / (1.0 + (@tt_tax_rate/100)),@ti_curr_precision)
        select @tt_amt_tax = @tt_amt_tax_included

        update #TXLineInput_ex
        set calc_tax = calc_tax + (@amt_taxable - 
          round(@amt_taxable / (1.0 + (@tt_tax_rate/100)),@ti_curr_precision))
        where row_id = @ti_row 
      end
      else
      begin
        if @amt_taxable != 0
        begin
          update #TXLineInput_ex
          set calc_tax = calc_tax + @tt_amt_tax
          where row_id = @ti_row
        end
      end

      update #TXtaxtype
      set amt_final_tax = @tt_amt_tax_included,
       amt_taxable = @tt_amt_taxable,
       amt_gross = @tt_amt_gross,
       amt_tax = @tt_amt_tax,
       amt_tax_included = @tt_amt_tax_included
      where row_id = @tt_row
    end
    else if @tt_tax_based_type = 1 -- tax on qty
    begin
      select @amt_taxable = @ti_qty
      select @tt_amt_taxable = @tt_amt_taxable + @amt_taxable
      select @tt_amt_gross = @tt_amt_gross + (@ti_extended_price - @ti_amt_discount)
      select @tt_amt_tax_included = round(@tt_amt_taxable * @tt_tax_rate, @ti_curr_precision)
      select @tt_amt_tax = @tt_amt_tax_included

      update #TXLineInput_ex
      set calc_tax = calc_tax + round (@amt_taxable * @tt_tax_rate, @ti_curr_precision)
      where row_id = @ti_row

      update #TXtaxtype
      set amt_final_tax = @tt_amt_tax_included,
      amt_taxable = @tt_amt_taxable,
      amt_gross = @tt_amt_gross,
      amt_tax = @tt_amt_tax,
      amt_tax_included = @tt_amt_tax_included
      where row_id = @tt_row
    end

    next_record:
    if @rc > 0
      FETCH c_taxtyperec INTO @ttr_row, @tax_type
  END
END

close c_taxtyperec
deallocate c_taxtyperec

return @rc
GO
GRANT EXECUTE ON  [dbo].[TXCalTaxIncluded_sp] TO [public]
GO
