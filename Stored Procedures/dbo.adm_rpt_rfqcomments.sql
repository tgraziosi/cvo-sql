SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_rfqcomments] @table varchar(255) as
begin
set nocount on
exec ('
select d.po_no, n.note_no, n.note
from (SELECT distinct t.p_po_no
from ' + @table + ' t) as d(po_no)
join notes n on n.code = d.po_no and n.code_type = ''P'' and n.form = ''Y''
order by d.po_no, n.note_no')
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_rfqcomments] TO [public]
GO
