SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_reset_mtd] @mode char(1) AS

declare @now datetime, @pltnow int

set @now = getdate()
set @pltnow = dbo.adm_get_pltdate_f (@now)

if @mode='Y' 
begin
  if not exists (select 1 from adm_inv_mtd_calendar where tran_type = '2' and beg_date = @pltnow )
  begin
    insert adm_inv_mtd_calendar (tran_type, beg_date, reset_date, year_month, fiscal_year, fiscal_start_mth, mtd_ind)
    select '2', @pltnow, @now, @pltnow, 0,0,0

    if @@error <> 0
    begin
      select -1,'Error Inserting YTD value'
      return
    end
  end
end

if not exists (select 1 from adm_inv_mtd_calendar where tran_type = '1' and beg_date = @pltnow)
begin
  insert adm_inv_mtd_calendar (tran_type, beg_date, reset_date, year_month, fiscal_year, fiscal_start_mth, mtd_ind)
  select '1', @pltnow, @now, @pltnow, 0,0,1

  if @@error <> 0
  begin
    select -1,'Error Inserting MTD value'
    return
  end 
end

select 1 , ''

GO
GRANT EXECUTE ON  [dbo].[fs_reset_mtd] TO [public]
GO
