CREATE TABLE [dbo].[arsalesp_upd]
(
[Conf] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SALESPERSON_CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SALESPERSON_NAME] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHORT_NAME] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SALESPERSON_TYPE] [float] NULL,
[EMPLOYEE_CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[VENDOR_CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR3] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR4] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR5] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR6] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR_SORT1] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR_SORT2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ADDR_SORT3] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STATUS_TYPE] [float] NULL,
[DATE_HIRED] [datetime] NULL,
[DATE_TERMINATED] [float] NULL,
[PHONE_1] [float] NULL,
[PHONE_2] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PHONE_3] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TIME_ZONE_CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SOCIAL_SECURITY] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SALES_MGR_CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMMISSION_CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMMISSION_ACCT_CODE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PAID_THRU_TYPE] [float] NULL,
[USER_NAME] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DDID] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ESCALATED_COMMISSIONS] [float] NULL,
[COMMISSION] [float] NULL,
[DATE_OF_HIRE] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DRAW_AMOUNT] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[arsalesp_upd] TO [public]
GO
GRANT INSERT ON  [dbo].[arsalesp_upd] TO [public]
GO
GRANT DELETE ON  [dbo].[arsalesp_upd] TO [public]
GO
GRANT UPDATE ON  [dbo].[arsalesp_upd] TO [public]
GO
