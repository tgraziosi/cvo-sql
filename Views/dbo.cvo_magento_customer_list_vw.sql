SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM dbo.cvo_magento_customer_list_vw AS mclv

CREATE VIEW [dbo].[cvo_magento_customer_list_vw]
AS 

-- RXExpress accounts
SELECT ar.customer_code, ar.ship_to_code, ar.address_name, ccdc.code AS designation, 'rxe' AS List_name
	FROM dbo.cvo_cust_designation_codes AS ccdc (NOLOCK)
	JOIN armaster ar (NOLOCK) ON ar.customer_code = ccdc.customer_code
	WHERE ccdc.code LIKE '%rx%' AND ccdc.primary_flag = 1 AND GETDATE() BETWEEN ISNULL(start_date,GETDATE()) AND ISNULL(end_date, GETDATE())
UNION ALL
	SELECT ar.customer_code, ar.ship_to_code, ar.address_name, 'key', 'key' AS List_name
	FROM armaster ar (NOLOCK)
	WHERE ar.addr_sort1 IN ('BCBG RETAILER','Corporate','Key Account', 'Intl Retailer')




GO

GRANT REFERENCES ON  [dbo].[cvo_magento_customer_list_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_magento_customer_list_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_magento_customer_list_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_magento_customer_list_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_magento_customer_list_vw] TO [public]
GO
