CREATE TABLE [dbo].[inv_master_add]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category_1] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_2] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_3] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_4] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_5] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[datetime_1] [datetime] NULL,
[datetime_2] [datetime] NULL,
[field_1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_7] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_8] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_9] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_10] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_11] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_12] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_13] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_14] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_15] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_16] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[long_descr] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_17] [decimal] (20, 8) NULL,
[field_18] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__78382C03] DEFAULT ('N'),
[field_19] [decimal] (20, 8) NULL,
[field_20] [decimal] (20, 8) NULL,
[field_21] [decimal] (20, 8) NULL,
[field_22] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__792C503C] DEFAULT ('N'),
[field_23] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_24] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_25] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_26] [datetime] NULL,
[field_27] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__7A207475] DEFAULT ('N'),
[field_28] [datetime] NULL,
[field_29] [datetime] NULL,
[field_30] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__7B1498AE] DEFAULT ('N'),
[field_31] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_32] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_33] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_34] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_35] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_36] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_37] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_38] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_39] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_40] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_18_a] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__466BC645] DEFAULT ('N'),
[field_18_b] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__475FEA7E] DEFAULT ('N'),
[field_18_c] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__48540EB7] DEFAULT ('N'),
[field_18_d] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__494832F0] DEFAULT ('N'),
[field_18_e] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__field__4A3C5729] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[inv_master_add_upd_trg]
ON [dbo].[inv_master_add] 
FOR UPDATE
as

SET NOCOUNT ON

/*
CREATE TABLE cvo_inv_master_audit (
field_name VARCHAR(30), 
field_from VARCHAR(60), 
field_to VARCHAR(60),
part_no VARCHAR(40), 
movement_flag SMALLINT, 
audit_date SMALLDATETIME, 
user_id VARCHAR(60),
id int identity(1,1)
)
go

grant all on cvo_inv_master_audit to public
go

CREATE UNIQUE CLUSTERED INDEX [inv_master_add_audit_ind_0] ON [dbo].[cvo_inv_master_audit]
(
	[id] ASC,
	[audit_date] ASC,
	[part_no] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

select * From cvo_inv_master_audit

*/

INSERT cvo_inv_master_audit (field_name, field_from, field_to, part_no, movement_flag, audit_date, user_id) 
SELECT 'Bridge Size', d.field_6, i.field_6, i.part_no, 2, getdate(), SUSER_SNAME() 
FROM inserted i INNER JOIN deleted d ON i.part_no = d.part_no
where ISNULL(d.field_6,'') <> ISNULL(i.field_6,'')

INSERT cvo_inv_master_audit (field_name, field_from, field_to, part_no, movement_flag, audit_date, user_id) 
SELECT 'Temple Size', d.field_8, i.field_8, i.part_no, 2, getdate(), SUSER_SNAME() 
FROM inserted i INNER JOIN deleted d ON i.part_no = d.part_no
where ISNULL(d.field_8,'') <> ISNULL(i.field_8,'')


INSERT cvo_inv_master_audit (field_name, field_from, field_to, part_no, movement_flag, audit_date, user_id) 
SELECT 'Eye Size', d.field_17, i.field_17, i.part_no, 2, getdate(), SUSER_SNAME() 
FROM inserted i INNER JOIN deleted d ON i.part_no = d.part_no
where ISNULL(d.field_17,0) <> ISNULL(I.field_17,0)

INSERT cvo_inv_master_audit (field_name, field_from, field_to, part_no, movement_flag, audit_date, user_id) 
SELECT 'Watch', d.category_1, i.category_1, i.part_no, 2, getdate(), SUSER_SNAME() 
FROM inserted i INNER JOIN deleted d ON i.part_no = d.part_no
where ISNULL(d.category_1,'N') <> ISNULL(i.category_1,'N')

INSERT cvo_inv_master_audit (field_name, field_from, field_to, part_no, movement_flag, audit_date, user_id) 
SELECT 'POM Date', d.field_28, i.field_28, i.part_no, 2, getdate(), SUSER_SNAME() 
FROM inserted i INNER JOIN deleted d ON i.part_no = d.part_no
where ISNULL(d.field_28,'1/1/1900') <> ISNULL(i.field_28,'1/1/1900')

INSERT cvo_inv_master_audit (field_name, field_from, field_to, part_no, movement_flag, audit_date, user_id) 
SELECT 'Rel Date', d.field_26, i.field_26, i.part_no, 2, getdate(), SUSER_SNAME() 
FROM inserted i INNER JOIN deleted d ON i.part_no = d.part_no
where ISNULL(d.field_26,'1/1/1900') <> ISNULL(i.field_26,'1/1/1900')

INSERT cvo_inv_master_audit (field_name, field_from, field_to, part_no, movement_flag, audit_date, user_id) 
SELECT 'Model', d.field_2, i.field_2, i.part_no, 2, getdate(), SUSER_SNAME() 
FROM inserted i INNER JOIN deleted d ON i.part_no = d.part_no
where ISNULL(d.field_2,'') <> ISNULL(i.field_2,'')
GO
CREATE NONCLUSTERED INDEX [invm_idx5_gender] ON [dbo].[inv_master_add] ([category_2]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invm_idx4_parttype] ON [dbo].[inv_master_add] ([category_3]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invm_idx1_case] ON [dbo].[inv_master_add] ([field_1]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invm_idx2_style] ON [dbo].[inv_master_add] ([field_2]) INCLUDE ([part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invm_idx3_pattern] ON [dbo].[inv_master_add] ([field_4]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [inv_master_add_idx] ON [dbo].[inv_master_add] ([part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_master_add] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_master_add] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_master_add] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_master_add] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_master_add] TO [public]
GO
