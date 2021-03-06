SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[CVO_InvRegDet_vw]
AS
SELECT 
  	ARTRX.CUSTOMER_CODE,
  	INVCRM =  CASE ARTRX.TRX_TYPE
  		WHEN 2032 THEN 'Credit'
  		ELSE 'Invoice'
  	END,
	ARTRXCDT.DOC_CTRL_NUM,
	ARTRXCDT.TRX_CTRL_NUM,
	ARTRXCDT.ORG_ID,
	SEQUENCE_ID,  
	LOCATION_CODE, 
	ITEM_CODE,     
	LINE_DESC,     
	QTY_ORDERED,   
	QTY_SHIPPED,   
	UNIT_CODE,     
	CASE artrx.trx_type WHEN 2032 THEN UNIT_PRICE * -1 ELSE unit_price END AS UNIT_PRICE,    
	QTY_RETURNED,        
	ARTRXCDT.TAX_CODE,       
	GL_REV_ACCT,
	DISCOUNT_AMT,   
	DISC_PRC_FLAG = CASE DISC_PRC_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,         
	CASE artrx.trx_type WHEN 2032 THEN EXTENDED_PRICE * -1 ELSE extended_price END AS EXTENDED_PRICE,
	ARTRX.NAT_CUR_CODE
FROM         
	ARTRXCDT AS ARTRXCDT INNER JOIN
	ARTRX AS ARTRX ON ARTRXCDT.TRX_CTRL_NUM = ARTRX.TRX_CTRL_NUM
WHERE     
	(ARTRX.TRX_TYPE IN (2021, 2031, 2032))
	
union

-- gather unposted transaction detail
select 
  	ARTRX.CUSTOMER_CODE,
  	INVCRM =  CASE ARTRX.TRX_TYPE
  		WHEN 2032 THEN 'Credit'
  		ELSE 'Invoice'
  	END,
	ARTRXCDT.DOC_CTRL_NUM,
	ARTRXCDT.TRX_CTRL_NUM,
	ARTRXCDT.ORG_ID,
	SEQUENCE_ID,  
	ARTRXCDT.LOCATION_CODE, 
	ITEM_CODE,     
	LINE_DESC,     
	QTY_ORDERED,   
	QTY_SHIPPED,   
	UNIT_CODE,     
	CASE artrx.trx_type WHEN 2032 THEN UNIT_PRICE * -1 ELSE unit_price END AS UNIT_PRICE,    
	QTY_RETURNED,        
	ARTRXCDT.TAX_CODE,       
	GL_REV_ACCT,
	DISCOUNT_AMT,   
	DISC_PRC_FLAG = CASE DISC_PRC_FLAG
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
	END,         
	CASE artrx.trx_type WHEN 2032 THEN EXTENDED_PRICE * -1 ELSE extended_price END AS EXTENDED_PRICE,
	ARTRX.NAT_CUR_CODE
from          
	arinpcdt ARTRXCDT (nolock) 
	join arinpchg_all ARTRX (nolock) on ARTRXCDT.TRX_CTRL_NUM = ARTRX.TRX_CTRL_NUM
where      
	(ARTRX.TRX_TYPE IN (2021, 2031, 2032))
		
GO
GRANT REFERENCES ON  [dbo].[CVO_InvRegDet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_InvRegDet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_InvRegDet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_InvRegDet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_InvRegDet_vw] TO [public]
GO
