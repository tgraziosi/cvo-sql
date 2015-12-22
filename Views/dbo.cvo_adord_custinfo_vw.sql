SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--select top 10 order_type, * from cvo_adord_custinfo_vw where territory = '20250' order_type like 'st%'

--select top 10 order_type, * from cvo_adord_custinfo_vw 


CREATE VIEW [dbo].[cvo_adord_custinfo_vw] AS 
SELECT 
 o.*, ar.addr1, ar.addr2, ar.addr3, ar.addr4, ar.addr5, ar.addr6, 
ar.city, ar.state, ar.postal_code, ar.country_code
, ISNULL((SELECT description FROM gl_country gl WHERE ar.country_code = gl.country_code),'') country_name,
ar.attention_name, ar.attention_phone, ar.contact_name, ar.contact_phone,
ar.tlx_twx fax,  ar.attention_email, ar.contact_email
FROM cvo_adord_vw o (NOLOCK)
INNER JOIN  armaster ar (NOLOCK) ON o.cust_code = ar.customer_code AND o.ship_to = ar.ship_to_code



GO
GRANT REFERENCES ON  [dbo].[cvo_adord_custinfo_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_adord_custinfo_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adord_custinfo_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adord_custinfo_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adord_custinfo_vw] TO [public]
GO
