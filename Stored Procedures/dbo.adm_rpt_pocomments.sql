SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_pocomments] @table varchar(255) as
begin
set nocount on
declare @n_len int

create table #temp_notes (po_no varchar(16), line_no int, note_no int, note text)

exec ('
insert #temp_notes (po_no, line_no, note_no, note)
select d.po_no, n.line_no, n.note_no, n.note
from (SELECT distinct t.p_po_no
from ' + @table + ' t) as d(po_no)
join notes n on n.code = d.po_no and n.code_type = ''P'' and n.form = ''Y''
order by d.po_no, n.line_no, n.note_no')

select @n_len = max(datalength(convert(varchar(10),note_no))) from #temp_notes
select @n_len = 10 * @n_len

update #temp_notes
set note_no = (line_no * @n_len) + note_no

select po_no, note_no, note
from #temp_notes
order by po_no, note_no
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_pocomments] TO [public]
GO
