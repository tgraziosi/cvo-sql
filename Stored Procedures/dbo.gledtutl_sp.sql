SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[gledtutl_sp] 
AS

DECLARE @min_sequence_id int

SELECT	@min_sequence_id = MIN(ic.sequence_id)
FROM	#gltrxedt1 ed, glcocodt_vw ic
WHERE	ed.offset_flag = 0
AND	ed.sequence_id > -1
AND	ed.rec_company_code <> ed.company_code
AND 	ed.company_code = ic.org_code
AND 	ed.rec_company_code = ic.rec_code
AND	ed.account_code LIKE ic.account_mask

SELECT	ed.journal_ctrl_num journal_ctrl_num,
	ed.sequence_id trx_id,
	ic.sequence_id mask_id
INTO	#mask_id
FROM	#gltrxedt1 ed, glcocodt_vw ic
WHERE	ed.offset_flag = 0
AND	ed.sequence_id > -1
AND	ed.rec_company_code <> ed.company_code
AND	ed.company_code = ic.org_code
AND	ed.rec_company_code = ic.rec_code
AND	ed.account_code LIKE ic.account_mask
AND	ic.sequence_id = @min_sequence_id
GROUP BY	ed.account_code, ed.journal_ctrl_num, 
		ed.sequence_id, ic.sequence_id

UPDATE	#gltrxedt1
SET	temp_flag = mask_id
FROM	#mask_id m, #gltrxedt1 ed
WHERE	m.journal_ctrl_num = ed.journal_ctrl_num
AND	m.trx_id = ed.sequence_id

DROP TABLE #mask_id

RETURN 
GO
GRANT EXECUTE ON  [dbo].[gledtutl_sp] TO [public]
GO
