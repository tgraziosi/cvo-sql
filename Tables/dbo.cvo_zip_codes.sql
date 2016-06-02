CREATE TABLE [dbo].[cvo_zip_codes]
(
[zipcode] [char] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[county] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [zp_idx] ON [dbo].[cvo_zip_codes] ([zipcode]) ON [PRIMARY]
GO
