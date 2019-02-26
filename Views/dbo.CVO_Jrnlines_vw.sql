SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO






-- updated 3/12/2013 - tag - add posted date
-- select journal_type, app_id, trx_type, * from gltrx where journal_type = 'ap' 
-- select top (100) * from cvo_jrnlines_vw where natural_acct = '7910' and date_applied between dbo.adm_get_pltdate_f('6/1/2018') AND dbo.adm_get_pltdate_f('6/30/2018')
-- SELECT * FROM apvodet WHERE trx_ctrl_num = 'vo031046'
-- select * From apvohdr
-- select * From apmaster

CREATE VIEW [dbo].[CVO_Jrnlines_vw] AS
 SELECT distinct
  	gldet.journal_ctrl_num,
	gl.journal_type,					-- CVO
  	gl.date_applied,
  	gl.date_posted, -- 3/12/13 - tag
  	gldet.sequence_id,
	CAST(gldet.account_code AS VARCHAR(36)) AS account_code, 
  	-- 021814 - tag - add vendor name and vendor code for AP entries
  	-- 033114 - tag - add customer name for AR entries
  	CASE WHEN gl.trx_type BETWEEN 4011 AND 4099 -- ap voucher/debit entries
        THEN ISNULL(ap.address_name,'')
         WHEN gl.trx_type BETWEEN 2002 AND 2162
            THEN ISNULL(ar.customer_name,'')
        ELSE '' END AS address_name,
    CASE WHEN gl.trx_type BETWEEN 4011 AND 4099 -- ap voucher/debit entries
        THEN ISNULL(vohdr.vendor_code, '')
        ELSE '' END AS vendor_code,
    CASE WHEN gl.trx_type BETWEEN 4011 AND 4099
        THEN (vohdr.date_doc) 
		ELSE ''
        END AS date_doc, -- 032414
  	CASE WHEN CHARINDEX('/',gldet.description) > 0 THEN -- 03/2016 - longer ap description
		LEFT(gldet.description,(CHARINDEX('/',gldet.description))) + ISNULL(vodet.line_desc,'')
		ELSE gldet.description END AS [description],
	LTRIM(RTRIM(ISNULL(gldet.document_1,''))) document_1,
	LTRIM(RTRIM(ISNULL(gldet.document_2,''))) document_2,
	gldet.nat_cur_code, 
  	gldet.nat_balance,
	CASE WHEN gl.trx_type = 2151 THEN (SELECT TOP (1) x.apply_to_num FROM artrxage x (nolock) 
                                        WHERE x.doc_ctrl_num = gldet.document_2 AND x.amount = gldet.balance AND gldet.document_1 = x.customer_code
                                        ORDER BY x.apply_to_num) 
                                        ELSE gldet.reference_code END reference_code,
  	gldet.rate_type_home,
	gldet.rate,
	gl.home_cur_code,
  	gldet.balance,
	gldet.rate_type_oper,
	gldet.rate_oper,
	gl.oper_cur_code,
	gldet.balance_oper,
	posted_flag = CASE gldet.posted_flag 
		WHEN 0 THEN 'No'
		WHEN 1 THEN 'Yes'
		ELSE 'Unknown'
	END,
	c.seg1_code natural_acct,
    gl.trx_type,
 	x_date_applied=gl.date_applied,
 	x_sequence_id=gldet.sequence_id,
 	x_nat_balance=gldet.nat_balance,
	x_rate=gldet.rate,
 	x_balance=gldet.balance,
	x_rate_oper=gldet.rate_oper,
	x_balance_oper=gldet.balance_oper
FROM 
	glchart c (NOLOCK)
	JOIN 	dbo.gltrxdet gldet (NOLOCK) ON gldet.account_code = c.account_code
	INNER JOIN dbo.gltrx gl (NOLOCK) ON gldet.journal_ctrl_num = gl.journal_ctrl_num
	LEFT JOIN dbo.apvodet vodet (NOLOCK)
	ON gldet.document_2 = vodet.trx_ctrl_num
	AND gldet.seq_ref_id = vodet.sequence_id
	LEFT JOIN apvohdr (NOLOCK) vohdr ON vohdr.trx_ctrl_num = gldet.document_2
	LEFT JOIN apmaster ap (NOLOCK) ON ap.vendor_code = vohdr.vendor_code AND ap.address_type = 0
	LEFT JOIN arcust ar (NOLOCK) ON ar.customer_code = gldet.document_1



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
