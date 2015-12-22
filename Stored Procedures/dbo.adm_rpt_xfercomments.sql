SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_xfercomments] @table varchar(255) as
begin
set nocount on
exec ('
select d.xfer_no, n.note_no, n.note
from (SELECT distinct t.x_xfer_no
from ' + @table + ' t) as d(xfer_no)
join notes n on n.code = d.xfer_no and n.code_type = ''X'' and n.form = ''Y''
order by d.xfer_no, n.note_no')
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_xfercomments] TO [public]
GO
