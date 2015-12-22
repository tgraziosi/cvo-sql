CREATE TABLE [dbo].[ibdispcd]
(
[timestamp] [timestamp] NULL,
[dispute_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (160) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ibdispcd_i1] ON [dbo].[ibdispcd] ([dispute_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ibdispcd] TO [public]
GO
GRANT SELECT ON  [dbo].[ibdispcd] TO [public]
GO
GRANT INSERT ON  [dbo].[ibdispcd] TO [public]
GO
GRANT DELETE ON  [dbo].[ibdispcd] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibdispcd] TO [public]
GO
