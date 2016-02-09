CREATE TABLE [dbo].[cvo_cust_designation_codes_distinct]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_reqd] [smallint] NULL,
[start_date] [datetime] NULL,
[end_date] [datetime] NULL,
[primary_flag] [int] NULL
) ON [PRIMARY]
GO
