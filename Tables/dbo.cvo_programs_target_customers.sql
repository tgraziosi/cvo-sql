CREATE TABLE [dbo].[cvo_programs_target_customers]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[Status] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Terr] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PROMO_level] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[address_name] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[postal_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tlx_twx] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[period] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Inv_cnt] [int] NULL,
[Inv_qty] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_programs_target_customers] ADD CONSTRAINT [PK__cvo_programs_tar__011CE42F] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
