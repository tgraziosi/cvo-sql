
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- SELECT * FROM cvo_loc_bin_vw

CREATE VIEW 
[dbo].[cvo_loc_bin_vw]
AS

SELECT TOP 1000 location ,
       bin_no ,
       description ,
       usage_type_code ,
       size_group_code ,
       cost_group_code ,
       group_code ,
       group_code_id ,
       seq_no ,
       sort_method ,
       status ,
       reference ,
       last_modified_date ,
       modified_by ,
       bm_udef_a ,
       bm_udef_b ,
       bm_udef_c ,
       bm_udef_d ,
       bm_udef_e ,
       maximum_level
	   
	    FROM tdc_bin_master
		WHERE((LOCATION = '001' AND BIN_NO = 'RR REFURB') OR location IN ('999','008'))
		AND group_code NOT IN ( 'pickarea','highbay','overflow','rdock')
		AND status = 'a'
/*UNION ALL 
SELECT TOP 1000 location ,
       bin_no ,
       description ,
       usage_type_code ,
       size_group_code ,
       cost_group_code ,
       group_code ,
       group_code_id ,
       seq_no ,
       sort_method ,
       status ,
       reference ,
       last_modified_date ,
       modified_by ,
       bm_udef_a ,
       bm_udef_b ,
       bm_udef_c ,
       bm_udef_d ,
       bm_udef_e ,
       maximum_level
	   
	    FROM tdc_bin_master
		WHERE status='A' AND location in ('001','008')
		AND group_code NOT IN ( 'pickarea','highbay','overflow','rdock')
		AND bin_no NOT LIKE 'f13%'
		AND bin_no NOT LIKE 'p04%'

*/



GO

GRANT REFERENCES ON  [dbo].[cvo_loc_bin_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_loc_bin_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_loc_bin_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_loc_bin_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_loc_bin_vw] TO [public]
GO
