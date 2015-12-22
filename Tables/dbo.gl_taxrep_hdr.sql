CREATE TABLE [dbo].[gl_taxrep_hdr]
(
[timestamp] [timestamp] NOT NULL,
[start_date] [int] NOT NULL,
[end_date] [int] NOT NULL,
[date_generated] [int] NOT NULL,
[generated_by] [smallint] NULL,
[report_cur] [smallint] NOT NULL,
[batch_lock] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_taxrep_hdr_0] ON [dbo].[gl_taxrep_hdr] ([start_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_taxrep_hdr] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_taxrep_hdr] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_taxrep_hdr] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_taxrep_hdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_taxrep_hdr] TO [public]
GO
