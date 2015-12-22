SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[get_q_match] @info varchar(30), @sort char(1), @matchno int, @secured_mode int = 0
AS
declare @x int

set @secured_mode = isnull(@secured_mode,0)

set rowcount 100
if @secured_mode = 0
begin
if @sort='C'
begin
select @x = convert(int,@info)
select match_ctrl_int, vendor_code, vendor_invoice_no
from adm_pomchchg (nolock)
where match_ctrl_int >= @x
order by match_ctrl_int
end
if @sort='N'
begin
select match_ctrl_int, vendor_code, vendor_invoice_no
from adm_pomchchg (nolock)
where vendor_invoice_no > @info or (vendor_invoice_no = @info and match_ctrl_int >= @matchno)
order by vendor_invoice_no, match_ctrl_int
end
if @sort='O'
begin
select match_ctrl_int, vendor_code, vendor_invoice_no
from adm_pomchchg (nolock)
where vendor_code > @info or (vendor_code = @info and match_ctrl_int >= @matchno)
order by vendor_code, match_ctrl_int
end
end
else
begin
if @sort='C'
begin
select @x = convert(int,@info)
select match_ctrl_int, adm_pomchchg.vendor_code, vendor_invoice_no
from adm_pomchchg (nolock), adm_vend (nolock)
where match_ctrl_int >= @x
  and adm_pomchchg.vendor_code = adm_vend.vendor_code
order by match_ctrl_int
end
if @sort='N'
begin
select match_ctrl_int, adm_pomchchg.vendor_code, vendor_invoice_no
from adm_pomchchg (nolock), adm_vend (nolock)
where (vendor_invoice_no > @info or (vendor_invoice_no = @info and match_ctrl_int >= @matchno))
  and adm_pomchchg.vendor_code = adm_vend.vendor_code
order by vendor_invoice_no, match_ctrl_int
end
if @sort='O'
begin
select match_ctrl_int, adm_pomchchg.vendor_code, vendor_invoice_no
from adm_pomchchg (nolock), adm_vend (nolock)
where (adm_pomchchg.vendor_code > @info or (adm_pomchchg.vendor_code = @info and match_ctrl_int >= @matchno))
  and adm_pomchchg.vendor_code = adm_vend.vendor_code
order by adm_pomchchg.vendor_code, match_ctrl_int
end
end

GO
GRANT EXECUTE ON  [dbo].[get_q_match] TO [public]
GO
