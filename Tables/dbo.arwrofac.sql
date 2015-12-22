CREATE TABLE [dbo].[arwrofac]
(
[writeoff_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[writeoff_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[writeoff_account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[writeoff_negative_amount] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arwrofac_ind_0] ON [dbo].[arwrofac] ([writeoff_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arwrofac] TO [public]
GO
GRANT SELECT ON  [dbo].[arwrofac] TO [public]
GO
GRANT INSERT ON  [dbo].[arwrofac] TO [public]
GO
GRANT DELETE ON  [dbo].[arwrofac] TO [public]
GO
GRANT UPDATE ON  [dbo].[arwrofac] TO [public]
GO
