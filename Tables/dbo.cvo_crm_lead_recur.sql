CREATE TABLE [dbo].[cvo_crm_lead_recur]
(
[recur_id] [int] NOT NULL IDENTITY(1, 1),
[run_id] [int] NULL,
[lead_id] [int] NULL,
[sec_id] [int] NULL,
[recur_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_lead_recur] ADD CONSTRAINT [PK__cvo_crm_lead_rec__59B832F4] PRIMARY KEY CLUSTERED  ([recur_id]) ON [PRIMARY]
GO
