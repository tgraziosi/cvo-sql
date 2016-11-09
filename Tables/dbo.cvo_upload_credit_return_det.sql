CREATE TABLE [dbo].[cvo_upload_credit_return_det]
(
[rec_id] [int] NOT NULL IDENTITY(1, 1),
[spid] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[kit_flag] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cvo_upload_credit_return_det_pk] ON [dbo].[cvo_upload_credit_return_det] ([rec_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_upload_credit_return_det_inx01] ON [dbo].[cvo_upload_credit_return_det] ([spid]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_upload_credit_return_det] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_upload_credit_return_det] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_upload_credit_return_det] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_upload_credit_return_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_upload_credit_return_det] TO [public]
GO
