CREATE TABLE [dbo].[tdc_wow_buyer]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_buyers] [int] NULL CONSTRAINT [DF__tdc_wow_b__all_b__19B522AC] DEFAULT ((0)),
[buyer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_buyer_idx1] ON [dbo].[tdc_wow_buyer] ([userid], [buyer]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_buyer] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_buyer] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_buyer] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_buyer] TO [public]
GO
