CREATE TABLE [dbo].[cvo_crm_lead_assoc]
(
[run_id] [int] NULL,
[lead_id] [int] NULL,
[sec_id] [int] NULL,
[isAddressValidated] [tinyint] NULL CONSTRAINT [DF__cvo_crm_l__isAdd__56DBC649] DEFAULT ((0)),
[isAccountMapped] [tinyint] NULL CONSTRAINT [DF__cvo_crm_l__isAcc__57CFEA82] DEFAULT ((0)),
[account_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
