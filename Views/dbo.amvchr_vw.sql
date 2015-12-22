SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amvchr_vw] 
AS 

SELECT 	DISTINCT
		amap.timestamp,
        amap.trx_ctrl_num, 
        hdr.doc_ctrl_num, 
        hdr.vendor_code,
		date_applied=DATEADD(dd, hdr.date_applied - 722815, "1/1/1980"),
        hdr.amt_net,
        hdr.org_id                       
FROM   	amapnew	amap,
		apvohdr hdr,
		apvodet det,
		amfac   fac
WHERE  	amap.trx_ctrl_num 	= hdr.trx_ctrl_num
AND		hdr.trx_ctrl_num 	= det.trx_ctrl_num
AND		det.gl_exp_acct 	LIKE RTRIM(fac.fac_mask)




GO
GRANT REFERENCES ON  [dbo].[amvchr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amvchr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amvchr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amvchr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amvchr_vw] TO [public]
GO
