CREATE TABLE [dbo].[cvo_cust_designation_codes]
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
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[CustDesig_del_trg]
on [dbo].[cvo_cust_designation_codes]
FOR DELETE
AS
BEGIN
SET NOCOUNT ON;
-- DELETE
INSERT cvo_cust_designation_codes_audit (Item, customer_code, code, audit_date, user_id) 
	SELECT 'DEL' as Item, D.customer_code, D.code, getdate(), SUSER_SNAME()
from deleted D

END


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[CustDesig_ins_trg]
on [dbo].[cvo_cust_designation_codes]
FOR INSERT
AS


/*
CREATE TABLE cvo_cust_designation_codes_audit (
Item varchar (30),
customer_code varchar (8),
code varchar (30),
Audit_Date smalldatetime,
User_ID varchar (60) )

GRANT Delete, Insert, References, Select, Update, View Definition ON cvo_cust_designation_codes_audit TO PUBLIC

*/
-- ADD
INSERT cvo_cust_designation_codes_audit (Item, customer_code, code, audit_date, user_id) 
	SELECT 'ADD' as Item, customer_code, code, getdate(), SUSER_SNAME()
from inserted 

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[CustDesig_upd_trg]
on [dbo].[cvo_cust_designation_codes]
FOR UPDATE
AS

-- UPDATES
-- End Date Update
INSERT cvo_cust_designation_codes_audit (Item, customer_code, code, audit_date, user_id, ColumnChange, ColumnDataFrom, ColumnDataTo) 
	SELECT 'UPD' as Item, i.customer_code, i.code, getdate(), SUSER_SNAME(), 'EndDate', d.end_date,  i.end_date
	 from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.code = d.code
where d.end_date <> i.end_date

-- Start Date Update
INSERT cvo_cust_designation_codes_audit (Item, customer_code, code, audit_date, user_id, ColumnChange, ColumnDataFrom, ColumnDataTo) 
	SELECT 'UPD' as Item, i.customer_code, i.code, getdate(), SUSER_SNAME(), 'StartDate', d.start_date, i.start_date
	 from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.code = d.code
where d.start_date <> i.start_date

-- Primary Flag Update
INSERT cvo_cust_designation_codes_audit (Item, customer_code, code, audit_date, user_id, ColumnChange, ColumnDataFrom, ColumnDataTo) 
	SELECT 'UPD' as Item, i.customer_code, i.code, getdate(), SUSER_SNAME(), 'PrimaryFlag', d.primary_flag, i.primary_flag
	 from inserted i INNER JOIN deleted d ON i.customer_code = d.customer_code AND i.code = d.code
where d.primary_flag <> i.primary_flag

GO
CREATE NONCLUSTERED INDEX [missing_index_311_310_cvo_cust_designation_codes] ON [dbo].[cvo_cust_designation_codes] ([customer_code], [date_reqd], [start_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_cust_designation_codes] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cust_designation_codes] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cust_designation_codes] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cust_designation_codes] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cust_designation_codes] TO [public]
GO
