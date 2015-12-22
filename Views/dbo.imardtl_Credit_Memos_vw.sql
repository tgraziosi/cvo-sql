SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imardtl_Credit_Memos_vw] 
    AS 
    SELECT d.* 
            FROM [CVO_Control]..[imardtl] d 
            LEFT OUTER JOIN [CVO_Control]..[imarhdr] h 
                    ON d.company_code = h.company_code
                            AND d.source_ctrl_num = h.source_ctrl_num
            WHERE (h.[trx_type] = 2032 OR h.[trx_type] IS NULL)
GO
GRANT REFERENCES ON  [dbo].[imardtl_Credit_Memos_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imardtl_Credit_Memos_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imardtl_Credit_Memos_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imardtl_Credit_Memos_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imardtl_Credit_Memos_vw] TO [public]
GO
