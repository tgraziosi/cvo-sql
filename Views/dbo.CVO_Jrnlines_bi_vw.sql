SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- updated 3/12/2013 - tag - add posted date
-- select journal_type, app_id, trx_type, * from gltrx where journal_type = 'ap' 
-- select top (1000) * from cvo_jrnlines_bi_vw where account_code = '1400000000000'
-- SELECT * FROM apvodet WHERE trx_ctrl_num = 'vo031046'
-- select * From apvohdr
-- select * From apmaster

CREATE VIEW [dbo].[CVO_Jrnlines_bi_vw]
AS
SELECT t1.journal_ctrl_num,
       t2.journal_type, -- CVO
       t2.date_applied,
       t2.date_posted,  -- 3/12/13 - tag
       t1.sequence_id,
       CAST(t1.account_code AS VARCHAR(36)) AS account_code,
                        -- 021814 - tag - add vendor name and vendor code for AP entries
                        -- 033114 - tag - add customer name for AR entries
       CASE WHEN t2.trx_type
                 BETWEEN 4011 AND 4099 -- ap voucher/debit entries
       THEN     ISNULL(
                (
                SELECT TOP 1
                       ap.address_name
                FROM apmaster ap (NOLOCK)
                    INNER JOIN apvohdr vo (NOLOCK)
                        ON vo.vendor_code = ap.vendor_code
                WHERE vo.trx_ctrl_num =        LTRIM(RTRIM(ISNULL(t1.document_2, '')))
                ),
                ''
                      )
       WHEN t2.trx_type
            BETWEEN 2002 AND 2162 THEN ISNULL(
                                       (
                                       SELECT TOP 1
                                              ar.customer_name
                                       FROM arcust ar
                                           (NOLOCK)
                                       WHERE ar.customer_code = LTRIM(RTRIM(ISNULL(t1.document_1, ''))) 
                                       ),
                                       ''
                                             ) ELSE ''
       END AS address_name,
       CASE WHEN t2.trx_type
                 BETWEEN 4011 AND 4099 -- ap voucher/debit entries
       THEN     ISNULL(
                (
                SELECT TOP 1
                       vendor_code
                FROM apvohdr
                    (NOLOCK)
                WHERE trx_ctrl_num =        LTRIM(RTRIM(ISNULL(t1.document_2, '')))
                ),
                ''
                      ) ELSE ''
       END AS vendor_code,
       CASE WHEN t2.trx_type
                 BETWEEN 4011 AND 4099 THEN
            (
            SELECT TOP 1
                   date_doc
            FROM apvohdr
                (NOLOCK)
            WHERE trx_ctrl_num =        LTRIM(RTRIM(ISNULL(t1.document_2, '')))
            )
       END AS date_doc, -- 032414
       CASE WHEN CHARINDEX('/', t1.description) > 0 THEN -- 03/2016 - longer ap description
                LEFT(t1.description, (CHARINDEX('/', t1.description))) + ISNULL(b.line_desc, '') ELSE t1.description
       END AS description,
       LTRIM(RTRIM(ISNULL(t1.document_1, ''))) document_1,
       LTRIM(RTRIM(ISNULL(t1.document_2, ''))) document_2,
       t1.nat_cur_code,
       SUM(t1.nat_balance) nat_balance,
       t1.reference_code,
       t1.rate_type_home,
       t1.rate,
       t2.home_cur_code,
       SUM(t1.balance) balance,
       t1.rate_type_oper,
       t1.rate_oper,
       t2.oper_cur_code,
       SUM(t1.balance_oper) blanace_oper,
       posted_flag = CASE t1.posted_flag WHEN 0 THEN 'No' WHEN 1 THEN 'Yes' END
FROM gltrxdet t1 (nolock)
    INNER JOIN gltrx t2 (nolock)
        ON t1.journal_ctrl_num = t2.journal_ctrl_num
    LEFT JOIN apvodet b
    (NOLOCK)
        ON t1.document_2 = b.trx_ctrl_num
           AND t1.seq_ref_id = b.sequence_id
GROUP BY CAST(t1.account_code AS VARCHAR(36)),
         
         CASE WHEN CHARINDEX('/', t1.description) > 0 THEN -- 03/2016 - longer ap description
                  LEFT(t1.description, (CHARINDEX('/', t1.description))) + ISNULL(b.line_desc, '') ELSE t1.description
         END,
         LTRIM(RTRIM(ISNULL(t1.document_1, ''))),
         LTRIM(RTRIM(ISNULL(t1.document_2, ''))),
         CASE t1.posted_flag WHEN 0 THEN 'No' WHEN 1 THEN 'Yes' END,
         t1.journal_ctrl_num,
         t2.journal_type,
		 t2.trx_type,
         t2.date_applied,
         t2.date_posted,
         t1.sequence_id,
         t1.nat_cur_code,
         t1.reference_code,
         t1.rate_type_home,
         t1.rate,
         t2.home_cur_code,
         t1.rate_type_oper,
         t1.rate_oper,
         t2.oper_cur_code;




GO
