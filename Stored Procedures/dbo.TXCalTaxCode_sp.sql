SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[TXCalTaxCode_sp] @ti_row int, @ti_tax_code varchar(8), @ti_control_number varchar(16),
@debug int = 0
as
declare @tc_row int,
  @tc_tax_included smallint,
  @tax_type_cnt int, 
  @tax_type varchar(8), 
  @ttr_row int,
  @tot_extended decimal(20,8),
  @rc int

select @tc_tax_included = tc.tax_included_flag, @tax_type_cnt = 1
from artax tc where tc.tax_code = @ti_tax_code

if @@rowcount = 0
begin
  return -1
end

select @tot_extended = 
  case when action_flag = 0 then extended_price - amt_discount else freight end
from #TXLineInput_ex
where row_id = @ti_row

select @tc_row = isnull((select row_id from #TXtaxcode where tax_code = @ti_tax_code
and control_number = @ti_control_number and ti_row = @ti_row
),0)
if @tc_row = 0
begin
insert #TXtaxcode (ti_row, tax_code, amt_tax, tax_included_flag, tax_type_cnt, control_number, tot_extended_amt)
select @ti_row, @ti_tax_code, 0.0, @tc_tax_included, @tax_type_cnt, @ti_control_number, @tot_extended

select @tc_row = @@identity
end
else
begin
  update #TXtaxcode
  set tot_extended_amt = tot_extended_amt + @tot_extended
  where row_id = @tc_row
end

if @tax_type_cnt > 0
begin
  insert #TXtaxtyperec (tc_row, tax_code, seq_id, base_id, cur_amt, old_tax, tax_type)
  select @tc_row, tax_code, sequence_id, base_id, 0.0, 0.0, tax_type_code
  from artaxdet 
  where tax_code = @ti_tax_code
  and not exists (select 1 from #TXtaxtyperec ttr  where ttr.tc_row = @tc_row)
  order by sequence_id

  if @@rowcount > 0
  begin
    insert #TXtaxtype (ttr_row, tax_type, ext_amt, amt_gross, amt_taxable, amt_tax,
      amt_final_tax, amt_tax_included, save_flag, tax_rate, prc_flag, prc_type,
      cents_code_flag, cents_code, cents_cnt, tax_based_type, tax_included_flag,
      modify_base_prc, base_range_flag, base_range_type, base_taxed_type,
      min_base_amt, max_base_amt, tax_range_flag, tax_range_type, min_tax_amt,
      max_tax_amt, recoverable_flag)
    select ttr.row_id, tt.tax_type_code, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, tt.amt_tax, 
      tt.prc_flag, tt.prc_type, tt.cents_code_flag, tt.cents_code, 0, tt.tax_based_type, 
      tt.tax_included_flag, tt.modify_base_prc, tt.base_range_flag, tt.base_range_type, 
      tt.base_taxed_type, tt.min_base_amt, tt.max_base_amt, tt.tax_range_flag, 
      tt.tax_range_type, tt.min_tax_amt, tt.max_tax_amt, tt.recoverable_flag
    FROM #TXtaxtyperec ttr
    join artxtype tt on tt.tax_type_code = ttr.tax_type
    where ttr.tc_row = @tc_row
  end
end

update #TXLineInput_ex set calc_tax = 0 where row_id = @ti_row

if @tc_tax_included = 1 
begin
  exec @rc = TXCalTaxIncluded_sp @tc_row, @ti_row, @ti_tax_code, @debug
  return @rc
end

select @rc = 1

DECLARE c_taxtyperec CURSOR STATIC READ_ONLY FORWARD_ONLY FOR
select row_id, tax_type
from #TXtaxtyperec
where tax_code = @ti_tax_code and tc_row = @tc_row
order by seq_id

OPEN c_taxtyperec
IF @@cursor_rows > 0
BEGIN -- Begin 1
  FETCH c_taxtyperec INTO @ttr_row, @tax_type

  WHILE (@@fetch_status = 0) and @rc > 0
  BEGIN -- begin 2
    exec @rc = TXCalTaxType_sp @tc_row, @ttr_row, @ti_row, @tax_type, @debug
 
    if @rc > 0
      FETCH c_taxtyperec INTO @ttr_row, @tax_type
  END
END

close c_taxtyperec
deallocate c_taxtyperec

return @rc
GO
GRANT EXECUTE ON  [dbo].[TXCalTaxCode_sp] TO [public]
GO
