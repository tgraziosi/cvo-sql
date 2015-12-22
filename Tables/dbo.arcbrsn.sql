CREATE TABLE [dbo].[arcbrsn]
(
[cb_reason_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arcbrsn_ind_0] ON [dbo].[arcbrsn] ([cb_reason_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcbrsn] TO [public]
GO
GRANT SELECT ON  [dbo].[arcbrsn] TO [public]
GO
GRANT INSERT ON  [dbo].[arcbrsn] TO [public]
GO
GRANT DELETE ON  [dbo].[arcbrsn] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcbrsn] TO [public]
GO
