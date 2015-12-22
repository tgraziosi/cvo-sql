CREATE TABLE [dbo].[icv_temp]
(
[spid] [int] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt1_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_payment] [float] NOT NULL,
[prompt4_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_code] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[icv_temp] TO [public]
GO
GRANT SELECT ON  [dbo].[icv_temp] TO [public]
GO
GRANT INSERT ON  [dbo].[icv_temp] TO [public]
GO
GRANT DELETE ON  [dbo].[icv_temp] TO [public]
GO
GRANT UPDATE ON  [dbo].[icv_temp] TO [public]
GO
