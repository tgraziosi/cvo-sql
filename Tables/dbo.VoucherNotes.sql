CREATE TABLE [dbo].[VoucherNotes]
(
[DocumentReferenceID] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SequenceID] [int] NULL,
[Link] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShowLineMode] [int] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[VoucherNotes] TO [public]
GO
GRANT INSERT ON  [dbo].[VoucherNotes] TO [public]
GO
GRANT DELETE ON  [dbo].[VoucherNotes] TO [public]
GO
GRANT UPDATE ON  [dbo].[VoucherNotes] TO [public]
GO
