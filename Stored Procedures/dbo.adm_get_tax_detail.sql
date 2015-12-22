SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[adm_get_tax_detail] @ord varchar(16), @ext int, @err int,
  @online_call int = 1,  @err_msg varchar(255) = '' output
AS
BEGIN
set nocount on

declare @tax_conn_ind int
set @tax_conn_ind = 0

update tldo
set amtBase = amtBase * case when t.amtTotal < 0 then -1 else 1 end,
amtTax = tldo.amtTax * case when t.amtTotal < 0 then -1 else 1 end,
taxable = tldo.taxable * case when t.amtTotal < 0 then -1 else 1 end
from #TXTaxLineDetOutput tldo, #TXTaxOutput t,
#txconnhdrinput thi
where tldo.control_number = t.control_number
and thi.doccode = t.control_number and thi.trx_type in (2032,4092)

update tlo
set amtTax = tlo.amtTax * case when t.amtTotal < 0 then -1 else 1 end,
taxable = tlo.taxable * case when t.amtTotal < 0 then -1 else 1 end
from #TXTaxLineOutput tlo, #TXTaxOutput t,
#txconnhdrinput thi
where tlo.control_number = t.control_number
and thi.doccode = t.control_number and thi.trx_type in (2032,4092)

update t
set amtTax = t.amtTax * case when t.amtTotal < 0 then -1 else 1 end,
amtTotal = t.amtTotal * case when t.amtTotal < 0 then -1 else 1 end
from #TXTaxOutput t, #txconnhdrinput thi
where thi.doccode = t.control_number and thi.trx_type in (2032,4092)

if @online_call = 1 
begin

if exists (select 1 from #TXTaxLineDetOutput where jurisCode > '-1' and reference_number > 0)
  set @tax_conn_ind = 1

select @ord, @ext, @err, 3, control_number, reference_number, '',
  t_index, d_index, amtBase, 0.0, 
  case when exception = 1 then nonTaxable else 0 end, amtTax,			-- mls 3/24/08
  taxRate, taxable, '', '', 0,
  exception, jurisCode, jurisName,jurisType, 
  case when exception = 0 then nonTaxable else 0 end, taxType
from #TXTaxLineDetOutput
where reference_number > -1
and (reference_number > 0 or (reference_number = 0 and (amtTax != 0 or taxable != 0)))
UNION
select @ord, @ext, @err, 2, control_number, reference_number, itemcode,
  t_index, 0, 0.0, amtDisc, amtExemption, amtTax,
  taxRate, taxable, TLO.taxCode, taxability, taxDetailCnt,
  0, '0', '', '0', 0, 0
from #TXTaxLineOutput TLO
join #txconnlineinput TLI on TLI.doccode = TLO.control_number and TLI.no = TLO.reference_number
and (TLO.reference_number > 0 or (TLO.reference_number = 0 and (TLO.amtTax != 0 or TLO.taxable != 0)))

UNION
select @ord, @ext, @err, 1, control_number, 0, '',
  0, 0, amtTotal, amtDisc, amtExemption, amtTax,
  0, 0, '', '', 0,
  0, '0', '', '0', 0, 0
from #TXTaxOutput
UNION
select @ord, @ext, t_index, 0, control_number, 0, '',
  0, 0, 0, 0, 0, 0,
  0, 0, '', '', 0,
  0, '0', isnull(jurisName,'Error: ' + convert(varchar,t_index)), '0', 0, @tax_conn_ind
from #TXTaxLineDetOutput
where reference_number = -1
UNION
select @ord, @ext, @err, 0, @ord, 0, '',
  1, 0, 0, 0, 0, 0,
  0, 0, '', '', 0,
  0, '0', 
case @err 
when -101 then 'Cannot have both tax connect tax codes and internal tax codes on the same order.'
when -112 then '#txconnhdrinput record is missing.'
when - 20 then 'Tax company code not defined for organization.'
when -81 then 'Total tax on shipped qty cannot be less than 0.'
when -82 then 'Total tax on ordered qty cannot be less than 0.'
when 1 then 'Tax calculated successfully.'
else 'Error: ' + convert(varchar,@err) end, '0', 0, @tax_conn_ind
where not exists (select 1 from #TXTaxLineDetOutput
  where reference_number = -1)
end
else
begin
if not exists (select 1 from #TXTaxLineDetOutput
  where reference_number = -1) 
select @err_msg = case @err 
when -101 then 'Cannot have both tax connect tax codes and internal tax codes on the same order.'
when -112 then '#txconnhdrinput record is missing.'
when - 20 then 'Tax company code not defined for organization.'
when -81 then 'Total tax on shipped qty cannot be less than 0.'
when -82 then 'Total tax on ordered qty cannot be less than 0.'
else 'Error: ' + convert(varchar,@err) end
else
select @err_msg = isnull((select top 1
isnull(jurisName,'Error: ' + convert(varchar,t_index))
from #TXTaxLineDetOutput
where reference_number = -1),'')
end
end
GO
GRANT EXECUTE ON  [dbo].[adm_get_tax_detail] TO [public]
GO
