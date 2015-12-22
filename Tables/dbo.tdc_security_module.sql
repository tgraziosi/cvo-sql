CREATE TABLE [dbo].[tdc_security_module]
(
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Source] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Access] [int] NOT NULL CONSTRAINT [DF__tdc_secur__Acces__513A61C0] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_tdc_security_module] ON [dbo].[tdc_security_module] ([UserID], [module], [Source]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_security_module] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_security_module] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_security_module] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_security_module] TO [public]
GO
