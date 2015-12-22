CREATE TABLE [dbo].[gl_taxrep_open_hdr_hst]
(
[timestamp] [timestamp] NOT NULL,
[report_date] [int] NOT NULL,
[start_date] [int] NOT NULL,
[end_date] [int] NOT NULL,
[date_generated] [int] NOT NULL,
[date_posted] [int] NOT NULL,
[generated_by] [smallint] NULL,
[report_cur] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_by] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_taxrep_open_hdr_hst_0] ON [dbo].[gl_taxrep_open_hdr_hst] ([start_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_taxrep_open_hdr_hst] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_taxrep_open_hdr_hst] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_taxrep_open_hdr_hst] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_taxrep_open_hdr_hst] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_taxrep_open_hdr_hst] TO [public]
GO
