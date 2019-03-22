SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_chg_cc_to_check_sp] @pytrx VARCHAR(50)
AS
BEGIN

    IF EXISTS (SELECT 1 FROM arinppyt WHERE trx_ctrl_num = @pytrx)
        UPDATE a
        SET payment_code = 'CHECK',
            prompt1_inp = '',
            prompt2_inp = '',
            prompt3_inp = '',
            prompt4_inp = '',
            hold_flag = 0,
            a.posted_flag = 0
        -- select * 
        FROM arinppyt a
            JOIN
            (
                SELECT aa.trx_ctrl_num
                FROM dbo.arinppyt_all AS aa
                WHERE 1 = 1
                      AND aa.payment_code <> ''
                      AND aa.trx_ctrl_num = @pytrx
            ) AS t
                ON a.trx_ctrl_num = t.trx_ctrl_num;
        SELECT CAST(@@ROWCOUNT AS VARCHAR(10)) + ' record(s) updated'
END;

GRANT EXECUTE ON dbo.cvo_chg_cc_to_check_sp TO PUBLIC;

GO
GRANT EXECUTE ON  [dbo].[cvo_chg_cc_to_check_sp] TO [public]
GO
