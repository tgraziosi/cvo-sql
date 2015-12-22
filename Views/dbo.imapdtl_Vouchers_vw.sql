SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imapdtl_Vouchers_vw] 
    AS 
    SELECT d.* 
            FROM [CVO_Control]..[imapdtl] d 
            LEFT OUTER JOIN [CVO_Control]..[imaphdr] h 
                    ON d.company_code = h.company_code
                            AND d.source_trx_ctrl_num = h.source_trx_ctrl_num
            WHERE (h.[trx_type] = 4091 OR h.[trx_type] IS NULL)
GO
GRANT REFERENCES ON  [dbo].[imapdtl_Vouchers_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imapdtl_Vouchers_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imapdtl_Vouchers_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imapdtl_Vouchers_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imapdtl_Vouchers_vw] TO [public]
GO
