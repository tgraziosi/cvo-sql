SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imarhdr_Invoices_vw] 
    AS 
    SELECT * 
            FROM [CVO_Control]..[imarhdr]
            WHERE [trx_type] = 2031

GO
GRANT REFERENCES ON  [dbo].[imarhdr_Invoices_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imarhdr_Invoices_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imarhdr_Invoices_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imarhdr_Invoices_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imarhdr_Invoices_vw] TO [public]
GO
