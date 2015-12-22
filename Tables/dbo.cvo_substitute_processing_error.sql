CREATE TABLE [dbo].[cvo_substitute_processing_error]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[spid] [int] NOT NULL,
[order_no] [int] NOT NULL,
[ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[reason] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_substitute_processing_error_pk] ON [dbo].[cvo_substitute_processing_error] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_substitute_processing_error_inx01] ON [dbo].[cvo_substitute_processing_error] ([spid]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_substitute_processing_error] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_substitute_processing_error] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_substitute_processing_error] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_substitute_processing_error] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_substitute_processing_error] TO [public]
GO
