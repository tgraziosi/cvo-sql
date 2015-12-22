SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imeglt_vw] AS 

SELECT 	journal_type,
	journal_ctrl_num,
	journal_description,
	date_entered,
	date_applied
	recurring_flag,
	repeating_flag,
	reversing_flag,
	type_flag,
	intercompany_flag,
	company_code,
	home_cur_code,
	oper_cur_code,
	document_1,
	processed_flag = 
		CASE processed_flag
			WHEN 0 then 'Unprocessed'
			WHEN 1 then 'Processed (Final)'
			WHEN 2 then 'Error'
		END,
	date_processed,
    org_id,
    	CASE ISNULL(interbranch_flag,0)
			WHEN 0 then 'No'
			WHEN 1 then 'Yes'
		END interbranch_flag
  FROM [CVO_Control]..imglhdr


                                             
GO
GRANT REFERENCES ON  [dbo].[imeglt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imeglt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imeglt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imeglt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imeglt_vw] TO [public]
GO
