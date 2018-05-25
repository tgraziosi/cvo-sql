CREATE TABLE [dbo].[cvo_crm_lead_enquiry]
(
[enq_id] [int] NOT NULL IDENTITY(1, 1),
[run_id] [int] NULL,
[lead_id] [int] NULL,
[sec_id] [int] NULL,
[prog_id] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_crm_lead_enquiry] ADD CONSTRAINT [PK__cvo_crm_lead_enq__5BA07B66] PRIMARY KEY CLUSTERED  ([enq_id]) ON [PRIMARY]
GO
