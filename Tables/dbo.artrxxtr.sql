CREATE TABLE [dbo].[artrxxtr]
(
[timestamp] [timestamp] NULL,
[rec_set] [smallint] NOT NULL,
[amt_due] [float] NOT NULL,
[amt_paid] [float] NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attention_phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxxtr__custom__15C3CAE0] DEFAULT (''),
[customer_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxxtr__custom__16B7EF19] DEFAULT (''),
[customer_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxxtr__custom__17AC1352] DEFAULT (''),
[customer_postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxxtr__custom__18A0378B] DEFAULT (''),
[ship_to_country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxxtr__ship_t__19945BC4] DEFAULT (''),
[ship_to_city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxxtr__ship_t__1A887FFD] DEFAULT (''),
[ship_to_state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxxtr__ship_t__1B7CA436] DEFAULT (''),
[ship_to_postal_code] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxxtr__ship_t__1C70C86F] DEFAULT ('')
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [artrxxtr_ind_0] ON [dbo].[artrxxtr] ([trx_type], [trx_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artrxxtr] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxxtr] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxxtr] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxxtr] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxxtr] TO [public]
GO
