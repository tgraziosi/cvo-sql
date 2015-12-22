SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_bolcomments] @table varchar(255) as
begin
set nocount on

exec ('
select o.bol_no, o.order_no, o.type, n.note_no, n.line_no, n.note
from (SELECT distinct t.b_bl_no, t.b_bl_src_no, t.b_bl_type
from ' + @table + ' t where t.b_bl_type = ''C'') as o(bol_no, order_no, type)
join notes n on n.code = convert(varchar(10),o.order_no) and n.code_type = ''O'' and n.bol = ''Y''
order by o.order_no, n.note_no')

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_bolcomments] TO [public]
GO
