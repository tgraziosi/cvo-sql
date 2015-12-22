CREATE TABLE [dbo].[adm_shipment_fill_group]
(
[timestamp] [timestamp] NOT NULL,
[batch_no] [int] NOT NULL,
[group_no] [int] NOT NULL CONSTRAINT [DF__adm_shipm__group__11217359] DEFAULT ((0)),
[rcd_type] [int] NOT NULL CONSTRAINT [DF__adm_shipm__rcd_t__12159792] DEFAULT ((0)),
[val01] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val01__1309BBCB] DEFAULT (''),
[val02] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val02__13FDE004] DEFAULT (''),
[val03] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val03__14F2043D] DEFAULT (''),
[val04] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val04__15E62876] DEFAULT (''),
[val05] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val05__16DA4CAF] DEFAULT (''),
[val06] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val06__17CE70E8] DEFAULT (''),
[val07] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val07__18C29521] DEFAULT (''),
[val08] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val08__19B6B95A] DEFAULT (''),
[val09] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val09__1AAADD93] DEFAULT (''),
[val10] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val10__1B9F01CC] DEFAULT (''),
[val11] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val11__1C932605] DEFAULT (''),
[val12] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val12__1D874A3E] DEFAULT (''),
[val13] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val13__1E7B6E77] DEFAULT (''),
[val14] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val14__1F6F92B0] DEFAULT (''),
[val15] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val15__2063B6E9] DEFAULT (''),
[val16] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val16__2157DB22] DEFAULT (''),
[val17] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val17__224BFF5B] DEFAULT (''),
[val18] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val18__23402394] DEFAULT (''),
[val19] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val19__243447CD] DEFAULT (''),
[val20] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__val20__25286C06] DEFAULT (''),
[label] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_shipm__label__261C903F] DEFAULT ('')
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [adm_shipment_fg1] ON [dbo].[adm_shipment_fill_group] ([batch_no], [rcd_type], [group_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_shipment_fill_group] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_shipment_fill_group] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_shipment_fill_group] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_shipment_fill_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_shipment_fill_group] TO [public]
GO
