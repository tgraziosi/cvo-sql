CREATE TABLE [dbo].[cvo_artermsd_installment]
(
[timestamp] [timestamp] NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[installment_days] [smallint] NOT NULL,
[installment_prc] [float] NOT NULL,
[date_installment] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_artermsd_installment] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_artermsd_installment] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_artermsd_installment] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_artermsd_installment] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_artermsd_installment] TO [public]
GO
