CREATE TABLE [dbo].[cvo_specialty_fit]
(
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_specia__void__31213305] DEFAULT ('N'),
[void_who] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_cvo_specialty_fit_cmi] ON [dbo].[cvo_specialty_fit] ([description], [kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_specialty_fit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_specialty_fit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_specialty_fit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_specialty_fit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_specialty_fit] TO [public]
GO
