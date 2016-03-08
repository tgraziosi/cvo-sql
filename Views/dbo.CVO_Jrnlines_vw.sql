
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO






-- updated 3/12/2013 - tag - add posted date
-- select journal_type, app_id, trx_type, * from gltrx where journal_type = 'ap' 
-- select * from cvo_jrnlines_vw where journal_type = 'ap' and journal_ctrl_num = 'jrnl00082149'
-- SELECT * FROM apvodet WHERE trx_ctrl_num = 'vo031046'
-- select * From apvohdr
-- select * From apmaster

CREATE VIEW [dbo].[CVO_Jrnlines_vw] AS
 SELECT 
  	t1.journal_ctrl_num,
	t2.journal_type,					-- CVO
  	t2.date_applied,
  	t2.date_posted, -- 3/12/13 - tag
  	t1.sequence_id,
  	CAST(t1.account_code AS VARCHAR(36)) AS account_code, 
  	-- 021814 - tag - add vendor name and vendor code for AP entries
  	-- 033114 - tag - add customer name for AR entries
  	CASE WHEN t2.trx_type BETWEEN 4011 AND 4099 -- ap voucher/debit entries
        THEN ISNULL((SELECT TOP 1 ap.address_name FROM apmaster ap
        INNER JOIN apvohdr vo  ON vo.vendor_code = ap.vendor_code
         WHERE vo.trx_ctrl_num = t1.document_2),'')
         WHEN t2.trx_type BETWEEN 2002 AND 2162
            THEN ISNULL((SELECT TOP 1 ar.customer_name FROM arcust ar
                WHERE ar.customer_code = t1.document_1),'')
        ELSE '' END AS address_name,
    CASE WHEN t2.trx_type BETWEEN 4011 AND 4099 -- ap voucher/debit entries
        THEN ISNULL((SELECT TOP 1 vendor_code FROM apvohdr WHERE trx_ctrl_num = t1.document_2),'')
        ELSE '' END AS vendor_code,
    CASE WHEN t2.trx_type BETWEEN 4011 AND 4099
        THEN (SELECT TOP 1 date_doc FROM apvohdr WHERE trx_ctrl_num = t1.document_2) 
        END AS date_doc, -- 032414
  	CASE WHEN CHARINDEX('/',t1.description) > 0 THEN -- 03/2016 - longer ap description
		LEFT(t1.description,(CHARINDEX('/',t1.description))) + ISNULL(b.line_desc,'')
		ELSE t1.description END AS [description],
	t1.document_1,
	t1.document_2,
	t1.nat_cur_code, 
  	t1.nat_balance,
	t1.reference_code,
  	t1.rate_type_home,
	t1.rate,
	t2.home_cur_code,
  	t1.balance,
	t1.rate_type_oper,
	t1.rate_oper,
	t2.oper_cur_code,
	t1.balance_oper,
	posted_flag = CASE t1.posted_flag 
		WHEN 0 THEN 'No'
		WHEN 1 THEN 'Yes'
	END,
 	x_date_applied=t2.date_applied,
 	x_sequence_id=t1.sequence_id,
 	x_nat_balance=t1.nat_balance,
	x_rate=t1.rate,
 	x_balance=t1.balance,
	x_rate_oper=t1.rate_oper,
	x_balance_oper=t1.balance_oper
FROM 
  	gltrxdet t1 INNER JOIN gltrx t2 ON t1.journal_ctrl_num = t2.journal_ctrl_num
	LEFT JOIN apvodet b(nolock)
	ON t1.document_2 = b.trx_ctrl_num
	AND t1.seq_ref_id = b.sequence_id
	

GO

GRANT REFERENCES ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_Jrnlines_vw] TO [public]
GO
