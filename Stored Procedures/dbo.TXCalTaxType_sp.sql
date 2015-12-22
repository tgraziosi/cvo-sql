SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create proc [dbo].[TXCalTaxType_sp] @tc_row int, @ttr_row int, @ti_row int, @ttr_tax_type varchar(8),
  @debug int = 0
as
declare @tt_row int, @tt_prc_flag int
declare @rc int

select @tt_row = row_id, @tt_prc_flag = prc_flag
from #TXtaxtype 
where ttr_row = @ttr_row and tax_type = @ttr_tax_type

if @@Rowcount = 0 return -1

select @rc = 1

if @tt_prc_flag = 0
begin
  exec @rc = TXCalFlatTax_sp @ttr_row, @ti_row, @tt_row, @ttr_tax_type, @debug
  return @rc
end
else
begin
  exec @rc = TXCalPercentTax_sp @tc_row, @ttr_row, @ti_row, @tt_row, @ttr_tax_type, @debug
end

return @rc
GO
GRANT EXECUTE ON  [dbo].[TXCalTaxType_sp] TO [public]
GO
