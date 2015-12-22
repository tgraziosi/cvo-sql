SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ar_MostOverdue_vw]
AS
	SELECT	ar.timestamp,		ar.customer_code,		
			ar.customer_name,	ar.doc_ctrl_num, 
			date_due = DATEADD (dd, ar.date_due  - 693596, '1900-01-01')
		FROM ar_ALLInvoices_vw ar WHERE ar.past_due_status = 'YES'
GO
GRANT SELECT ON  [dbo].[ar_MostOverdue_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_MostOverdue_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_MostOverdue_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_MostOverdue_vw] TO [public]
GO
