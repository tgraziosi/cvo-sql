CREATE TABLE [dbo].[rpt_icverify]
(
[ERRCODE] [int] NOT NULL,
[HRESULT] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ADDITIONALINFO] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CUSTOMER] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PAYMENT_CODE] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DOCNUM] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DOC_DATE] [char] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AMT] [float] NOT NULL,
[NAME] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ACCOUNT] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[EXPIRATION] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AUTHORIZAT] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ERRORMESSAGE] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[USER_ID] [int] NOT NULL,
[USER_NAME] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[COMPANY_NAME] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TRX_CTRL_NUM] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MAYBE_MORE] [int] NOT NULL,
[CURRENCY_CODE] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SYMBOL] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_icverify] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_icverify] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_icverify] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_icverify] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_icverify] TO [public]
GO
