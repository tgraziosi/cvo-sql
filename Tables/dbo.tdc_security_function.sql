CREATE TABLE [dbo].[tdc_security_function]
(
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Source] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Function] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Access] [int] NULL CONSTRAINT [DF__tdc_secur__Acces__5416CE6B] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_security_function] ADD CONSTRAINT [PK_tdc_security_function] PRIMARY KEY NONCLUSTERED  ([UserID], [module], [Source], [Function]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_tdc_security_function] ON [dbo].[tdc_security_function] ([UserID], [module], [Source], [Function]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_security_function] ADD CONSTRAINT [Function_CON] FOREIGN KEY ([module], [Source], [Function]) REFERENCES [dbo].[tdc_module_functions] ([module], [Source], [Function])
GO
ALTER TABLE [dbo].[tdc_security_function] ADD CONSTRAINT [UserID_CON] FOREIGN KEY ([UserID]) REFERENCES [dbo].[tdc_sec] ([UserID])
GO
GRANT SELECT ON  [dbo].[tdc_security_function] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_security_function] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_security_function] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_security_function] TO [public]
GO
