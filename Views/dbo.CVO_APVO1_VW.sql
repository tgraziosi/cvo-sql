SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM CVO_APVO1_VW WHERE nat_cur_code <> 'usd'

CREATE VIEW [dbo].[CVO_APVO1_VW]
AS
SELECT 
	T2.ADDRESS_NAME AS  ADDRESS_NAME
	, T2.VENDOR_CODE AS  VENDOR_CODE
	, T1.PAY_TO_CODE AS  PAY_TO_CODE
	-- tag - 070813
	, t2.vend_class_code as Vendor_type
	, T1.TRX_CTRL_NUM AS   VOUCHER_NO
	, 'NO' AS  APPROVAL_FLAG
	, 'NO' AS  HOLD_FLAG
	, 'YES' AS  POSTED_FLAG
	, T1.CURRENCY_CODE AS  NAT_CUR_CODE
	, T1.AMT_NET AS   AMT_NET
	, T1.AMT_PAID_TO_DATE AS  AMT_PAID
	, round(T1.AMT_NET - T1.AMT_PAID_TO_DATE,2) AS   AMT_OPEN

	, round(t1.rate_home*t1.amt_net,2) as Amt_Net_USD
    , round(t1.rate_home*t1.amt_paid_to_date,2) as AMt_paid_USD
    , round(t1.rate_home*(t1.amt_net - t1.amt_paid_to_date),2) as amt_open_USD
    
	, T1.DATE_DOC AS   DATE_DOC
	, T1.DATE_APPLIED AS  DATE_APPLIED
	, T1.DATE_DUE AS  DATE_DUE
	, T1.DATE_DISCOUNT AS  DATE_DISCOUNT
	-- ADD CHECK NUMBER
	, (SELECT TOP 1 a.DOC_CTRL_NUM FROM APTRXAGE a
	    WHERE a.APPLY_TO_NUM = T1.TRX_CTRL_NUM
	    and a.trx_type = 4111 and a.apply_trx_type = 4091
		AND NOT EXISTS (SELECT 1 FROM aptrxage aa WHERE aa.apply_to_num = t1.trx_ctrl_num AND aa.doc_ctrl_num = a.doc_ctrl_num
		AND aa.trx_type IN (4113,4114))) AS PAYMENT_NUM
	   --SELECT DOC_CTRL_NUM, APPLY_TO_NUM, * FROM APTRXAGE WHERE TRX_TYPE = 4111
	   --SELECT TRX_CTRL_NUM, DOC_CTRL_NUM FROM APVOHDR
	   
	, T1.DOC_CTRL_NUM AS   INVOICE_NO
	, T1.PO_CTRL_NUM AS   PO_CTRL_NUM
	, T1.JOURNAL_CTRL_NUM AS  GL_TRX_ID
	, EW.USER_NAME AS  USER_NAME
	, t3.item_code as item_code
	, t3.qty_ordered as ordered
	, t3.qty_received as received
	, t3.amt_extended as amt_extended
	, t3.gl_exp_acct as gl_account
	, t3.line_desc as line_desc
	, T1.AMT_NET AS   X_AMT_NET
	, T1.AMT_PAID_TO_DATE AS  X_AMT_PAID
	, T1.AMT_NET - T1.AMT_PAID_TO_DATE AS   X_AMT_OPEN
	, T1.DATE_DOC AS   X_DATE_DOC
	, T1.DATE_APPLIED AS  X_DATE_APPLIED
	, T1.DATE_DUE AS  X_DATE_DUE
	, T1.DATE_DISCOUNT AS  X_DATE_DISCOUNT 	
	
	--select * 	
FROM 
	APVOHDR T1 
	inner join apvodet t3 on t3.trx_ctrl_num = t1.trx_ctrl_num
	inner join apmaster t2 on t2.vendor_code = t1.vendor_code
	inner join EWUSERS_VW ew on ew.user_id = t1.user_id
WHERE	T2.ADDRESS_TYPE = 0 

UNION

SELECT 
	T2.ADDRESS_NAME				 
	,T2.VENDOR_CODE
	,T1.PAY_TO_CODE		
	, t2.vend_class_code as Vendor_type
	,T1.TRX_CTRL_NUM	
	,APPROVAL_FLAG = CASE T1.APPROVAL_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END													
	,HOLD_FLAG = CASE T1.HOLD_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END					
	,POSTED_FLAG='NO'					
	,T1.NAT_CUR_CODE				
	,T1.AMT_NET 					
	,T1.AMT_PAID			
	,T1.AMT_NET - T1.AMT_PAID 
	
	, round(t1.rate_home*t1.amt_net,2) as Amt_Net_USD
    , round(t1.rate_home*t1.amt_paid,2) as AMt_paid_USD
    , round(t1.rate_home*(t1.amt_net - t1.amt_paid),2) as amt_open_USD

	,T1.DATE_DOC 					
	,T1.DATE_APPLIED				
	,T1.DATE_DUE					
	,T1.DATE_DISCOUNT
	-- 070813	
	,'' AS PAYMENT_NUM			
	,T1.DOC_CTRL_NUM 	
	,T1.PO_CTRL_NUM				
	,''
	,EW.USER_NAME
	, t3.item_code as item_code
	, t3.qty_ordered as ordered
	, t3.qty_received as received
	, t3.amt_extended as amt_extended
	, t3.gl_exp_acct as gl_account
	, t3.line_desc as line_desc
	, T1.AMT_NET AS   X_AMT_NET
	, T1.AMT_PAID AS  X_AMT_PAID
	, T1.AMT_NET - T1.AMT_PAID AS   X_AMT_OPEN
	, T1.DATE_DOC AS   X_DATE_DOC
	, T1.DATE_APPLIED AS  X_DATE_APPLIED
	, T1.DATE_DUE AS  X_DATE_DUE
	, T1.DATE_DISCOUNT AS  X_DATE_DISCOUNT
FROM 
	APINPCHG T1, apinpcdt t3,
	APMASTER T2, 
	EWUSERS_VW EW
WHERE	T1.VENDOR_CODE = T2.VENDOR_CODE 
AND		T2.ADDRESS_TYPE = 0
AND		T1.TRX_TYPE IN (4091) 
AND		T1.USER_ID = EW.USER_ID 
AND t1.trx_ctrl_num = t3.trx_ctrl_num



GO
GRANT REFERENCES ON  [dbo].[CVO_APVO1_VW] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_APVO1_VW] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_APVO1_VW] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_APVO1_VW] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_APVO1_VW] TO [public]
GO
