CREATE TABLE [dbo].[cvo_hs_prospects]
(
[hs_cust_id] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[business_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[territory] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zipcode] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_count] [int] NULL,
[location_type] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location_class] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[annual_retail_sale] [float] NULL,
[status] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lead_date] [datetime] NULL,
[lead_updated] [datetime] NULL,
[sc_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[addr2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
