SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO






-- updated 3/12/2013 - tag - add posted date
-- select journal_type, app_id, trx_type, * from gltrx where journal_type = 'ap' 
-- select top (100) * from cvo_jrnlines_bi_vw where natural_acct = '2165' and journal_type = 'ap'
-- SELECT * FROM apvodet WHERE trx_ctrl_num = 'vo031046'
-- select * From apvohdr
-- select * From apmaster

CREATE VIEW [dbo].[CVO_Jrnlines_bi_vw] AS
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
        THEN ISNULL(ap.address_name,'')
         WHEN t2.trx_type BETWEEN 2002 AND 2162
            THEN ISNULL(ar.customer_name,'')
        ELSE '' END AS address_name,
    CASE WHEN t2.trx_type BETWEEN 4011 AND 4099 -- ap voucher/debit entries
        THEN ISNULL(vohdr.vendor_code, '')
        ELSE '' END AS vendor_code,
    CASE WHEN t2.trx_type BETWEEN 4011 AND 4099
        THEN (vohdr.date_doc) 
		ELSE ''
        END AS date_doc, -- 032414
  	CASE WHEN CHARINDEX('/',t1.description) > 0 THEN -- 03/2016 - longer ap description
		LEFT(t1.description,(CHARINDEX('/',t1.description))) + ISNULL(vodet.line_desc,'')
		ELSE t1.description END AS [description],
	LTRIM(RTRIM(ISNULL(t1.document_1,''))) document_1,
	LTRIM(RTRIM(ISNULL(t1.document_2,''))) document_2,
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
		ELSE 'Unknown'
	END,
	c.seg1_code natural_acct,
 	x_date_applied=t2.date_applied,
 	x_sequence_id=t1.sequence_id,
 	x_nat_balance=t1.nat_balance,
	x_rate=t1.rate,
 	x_balance=t1.balance,
	x_rate_oper=t1.rate_oper,
	x_balance_oper=t1.balance_oper
FROM 
	glchart c (NOLOCK)
	JOIN 	dbo.gltrxdet t1 (NOLOCK) ON t1.account_code = c.account_code
	INNER JOIN dbo.gltrx t2 (NOLOCK) ON t1.journal_ctrl_num = t2.journal_ctrl_num
	LEFT JOIN dbo.apvodet vodet (nolock)
	ON t1.document_2 = vodet.trx_ctrl_num
	AND t1.seq_ref_id = vodet.sequence_id
	LEFT JOIN apvohdr (nolock) vohdr ON vohdr.trx_ctrl_num = t1.document_2
	LEFT JOIN apmaster ap (nolock) ON ap.vendor_code = vohdr.vendor_code
	LEFT JOIN arcust ar (NOLOCK) ON ar.customer_code = t1.document_1
	

	





GO
