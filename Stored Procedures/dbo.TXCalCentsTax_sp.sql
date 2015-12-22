SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



create proc [dbo].[TXCalCentsTax_sp] @tt_row int, @base_amt decimal(20,8), @precision int, @tax_amt decimal(20,8) OUT,
@debug int = 0
as
declare @base_integer decimal(20,8), 
  @base_frac decimal(20,8), 
  @c_row int,
  @to_cent decimal(20,8), 
  @tax_cents decimal(20,8), 
  @tt_cents_code varchar(8)

select @base_frac = convert(decimal(20,8), @base_amt - floor(@base_amt))
select @base_integer = floor(@base_amt)

select @tax_amt = round (@base_integer * (tt.tax_rate / 100), @precision),
  @tt_cents_code = cents_code
from #TXtaxtype tt
where tt.row_id = @tt_row

if not exists (select 1 from #cents where cents_code = @tt_cents_code)
begin 
  insert #cents (cents_code, to_cent, tax_cents)
  select a.cents_code, to_cent, tax_cents
  from arcendet a, #TXtaxtype tt
  where a.cents_code = @tt_cents_code
  order by a.sequence_id
  if @@rowcount = 0 return -1
end

select @c_row = isnull((select min(row_id) from #cents where cents_code = @tt_cents_code),0)
while @c_row != 0
begin
  select @to_cent = convert(decimal(20,8), to_cent),
    @tax_cents = tax_cents
  from #cents
  where row_id = @c_row

if @debug > 0
begin
print 'in cents proc'
select @base_frac, @to_cent, @tax_cents
end

  if @base_frac > 0 and @base_frac <= @to_cent
  begin
    select @base_frac = @tax_cents,
      @c_row = 0
  end

  if @c_row != 0
    select @c_row = isnull((select min(row_id) from #cents
      where cents_code = @tt_cents_code and row_id > @c_row),0)
end

select @tax_amt = @tax_amt + @base_frac
return 1
GO
GRANT EXECUTE ON  [dbo].[TXCalCentsTax_sp] TO [public]
GO
