SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_hello_phone_vw] AS 

SELECT  DISTINCT phone_num ,
        agent.CUSTOMER_CODE ,
        QUEUE_NAME,
		ar.customer_name, 
		ar.city,
		ar.state,
		ar.contact_name
FROM    cvo_cust_agent_tbl  (NOLOCK) agent
		JOIN arcust ar ON ar.customer_code = agent.CUSTOMER_CODE
		WHERE 1=1
		AND NOT EXISTS (SELECT 1 FROM ARMASTER 
						  WHERE CONTACT_phone = agent.phone_num 
								AND agent.CUSTOMER_CODE = agent.customer_code)
UNION ALL
SELECT  DISTINCT contact_phone ,
        customer_code ,
        CASE WHEN SHIP_TO_CODE = '' THEN 'BILL-TO' ELSE 'SHIP-TO' END AS QUEUE_NAME,
		address_name,
		city,
		state,
		contact_name
FROM    armaster (NOLOCK)
WHERE   address_type <> 9
        AND status_type = 1
		AND ISNULL(contact_phone,'') > '0'
		;
GO
GRANT REFERENCES ON  [dbo].[cvo_hello_phone_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_hello_phone_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_hello_phone_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_hello_phone_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_hello_phone_vw] TO [public]
GO
