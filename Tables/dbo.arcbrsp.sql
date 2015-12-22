CREATE TABLE [dbo].[arcbrsp]
(
[cb_responsibility_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cb_resp_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [arcbrsp_ind_0] ON [dbo].[arcbrsp] ([cb_responsibility_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arcbrsp] TO [public]
GO
GRANT SELECT ON  [dbo].[arcbrsp] TO [public]
GO
GRANT INSERT ON  [dbo].[arcbrsp] TO [public]
GO
GRANT DELETE ON  [dbo].[arcbrsp] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcbrsp] TO [public]
GO
