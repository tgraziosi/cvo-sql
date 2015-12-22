CREATE TABLE [dbo].[cvo_CR_parameters]
(
[username] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_paymeth] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_paymeth] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_CR_parameters] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_CR_parameters] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_CR_parameters] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_CR_parameters] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_CR_parameters] TO [public]
GO
