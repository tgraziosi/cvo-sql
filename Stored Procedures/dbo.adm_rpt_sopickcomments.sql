SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_sopickcomments] @table varchar(255) as
begin
set nocount on

exec ('
select o.order_no, n.note_no, n.line_no, n.note
from (SELECT distinct t.o_order_no
from ' + @table + ' t) as o(order_no)
join notes n on n.code = convert(varchar(10),o.order_no) and n.code_type = ''O'' and n.pick = ''Y''
order by o.order_no, n.note_no')

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_sopickcomments] TO [public]
GO
