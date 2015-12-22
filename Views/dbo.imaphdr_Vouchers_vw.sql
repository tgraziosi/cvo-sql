SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imaphdr_Vouchers_vw] 
    AS 
    SELECT * 
            FROM [CVO_Control]..[imaphdr]
            WHERE [trx_type] = 4091
GO
GRANT REFERENCES ON  [dbo].[imaphdr_Vouchers_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imaphdr_Vouchers_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imaphdr_Vouchers_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imaphdr_Vouchers_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imaphdr_Vouchers_vw] TO [public]
GO
