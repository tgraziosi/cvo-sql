CREATE TABLE [dbo].[eft_apms]
(
[timestamp] [timestamp] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bank_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bank_account_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[aba_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_type] [smallint] NOT NULL,
[user_varchar1] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_varchar2] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_varchar3] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_varchar4] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_smallint1] [smallint] NULL,
[user_smallint2] [smallint] NULL,
[user_smallint3] [smallint] NULL,
[user_smallint4] [smallint] NULL,
[user_int1] [int] NULL,
[user_int2] [int] NULL,
[user_int3] [int] NULL,
[user_int4] [int] NULL,
[user_float1] [float] NULL,
[user_float2] [float] NULL,
[user_float3] [float] NULL,
[user_float4] [float] NULL,
[bank_account_encrypted] [varbinary] (max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eft_apms_ind_0] ON [dbo].[eft_apms] ([vendor_code], [pay_to_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eft_apms] TO [public]
GO
GRANT SELECT ON  [dbo].[eft_apms] TO [public]
GO
GRANT INSERT ON  [dbo].[eft_apms] TO [public]
GO
GRANT DELETE ON  [dbo].[eft_apms] TO [public]
GO
GRANT UPDATE ON  [dbo].[eft_apms] TO [public]
GO
