SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--select * from gltrx
CREATE VIEW [dbo].[CVO_GL_tX_Detail_vw]
AS
select
b.journal_ctrl_num, b.journal_type, b.journal_description, a.sequence_id,
b.date_entered,
--convert(varchar,dateadd(d,b.date_entered-711858,'1/1/1950'),101) AS DateEntered,
b.date_applied,
--convert(varchar,dateadd(d,b.DATE_APPLIED-711858,'1/1/1950'),101) AS DateApplied,
b.date_posted,
-- convert(varchar,dateadd(d,isnull(b.DATE_posted,711858)-711858,'1/1/1950'),101) AS DatePosted,
a.seg1_code as NaturalAccount,
a.account_code,
a.balance, 
a.document_1,
a.document_2
from gltrxdet a,
gltrx b
where 1=1
--where seg1_code in ('4000','4500','4600','4999')
and a.journal_ctrl_num = b.journal_ctrl_num
--and b.DATE_APPLIED between @JDateFrom and @JDateTo
GO
GRANT CONTROL ON  [dbo].[CVO_GL_tX_Detail_vw] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_GL_tX_Detail_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_GL_tX_Detail_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_GL_tX_Detail_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_GL_tX_Detail_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_GL_tX_Detail_vw] TO [public]
GO
