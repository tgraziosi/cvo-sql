CREATE TABLE [dbo].[cvo_magento_consolidate_order]
(
[order_no] [int] NOT NULL,
[magento_no] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [tinyint] NOT NULL CONSTRAINT [DF__cvo_magen__statu__7D7277CA] DEFAULT ('0'),
[tracking] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[magento_combined] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL CONSTRAINT [DF__cvo_magen__date___23870ACC] DEFAULT (NULL)
) ON [PRIMARY]
GO
