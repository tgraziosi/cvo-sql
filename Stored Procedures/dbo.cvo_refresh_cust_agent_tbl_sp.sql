SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_refresh_cust_agent_tbl_sp]
AS
BEGIN

-- 8/13/2015 - tag - to support agent assignmnets in phone system.
-- exec cvo_refresh_cust_agent_tbl_sp

SET NOCOUNT ON

DECLARE @LAST_CUST VARCHAR(10), @LAST_USER VARCHAR(40), @last_phone VARCHAR(30), @QUEUE VARCHAR(20)

DECLARE @AGENTS TABLE
	(phone_num VARCHAR(30), queue_name VARCHAR(20), agent_id VARCHAR(40), customer_code VARCHAR(10) )

SELECT @LAST_CUST = '', @LAST_USER = ''
SELECT @LAST_CUST = MIN(CUSTOMER_CODE) FROM ARCUST WHERE CUSTOMER_CODE > @LAST_CUST AND ISNULL(contact_phone,'') <> ''
SELECT @last_phone = ISNULL(contact_phone,'') FROM arcust WHERE customer_code = @last_cust
SELECT  @LAST_USER = MIN([User_name]) 
	FROM CVO_TERRITORYXREF WHERE Salesperson_code IN ('SS','KA', 'CS') AND STATUS = 1
	AND [USER_NAME] > @LAST_USER
SELECT @QUEUE = MIN(Salesperson_code) FROM CVO_TERRITORYXREF WHERE USER_NAME = @LAST_USER


WHILE @LAST_CUST IS NOT NULL
BEGIN
	WHILE @LAST_USER IS NOT NULL
	BEGIN
		INSERT @AGENTS ( phone_num, queue_name, agent_id, customer_code )
			VALUES (@last_phone, @QUEUE, REPLACE(@last_user,'cvoptical\',''), @LAST_CUST)
		SELECT @LAST_CUST = MIN(CUSTOMER_CODE) FROM ARCUST WHERE CUSTOMER_CODE > @LAST_CUST AND ISNULL(contact_phone,'') <> ''
		SELECT @last_phone = ISNULL(contact_phone,'') FROM arcust WHERE customer_code = @last_cust
		SELECT @LAST_USER = MIN([User_name]) 
			FROM CVO_TERRITORYXREF WHERE Salesperson_code IN ('SS','KA', 'CS') AND STATUS = 1
			AND [USER_NAME] > @LAST_USER
		SELECT @QUEUE = MIN(Salesperson_code) FROM CVO_TERRITORYXREF WHERE USER_NAME = @LAST_USER


	END
	-- SELECT @LAST_CUST = MIN(CUSTOMER_CODE) FROM ARCUST WHERE CUSTOMER_CODE = @LAST_CUST
	SELECT @LAST_USER = MIN([User_name]) 
		FROM CVO_TERRITORYXREF WHERE Salesperson_code IN ('SS','KA', 'CS')  AND STATUS = 1
	SELECT @QUEUE = MIN(Salesperson_code) FROM CVO_TERRITORYXREF WHERE USER_NAME = @LAST_USER
END

-- SELECT COUNT(a.CUSTOMER_CODE) from @AGENTS a 

-- SELECT AGENT, COUNT(CUSTOMER_CODE) FROM @AGENTS GROUP BY AGENT

-- SELECT COUNT(customer_code) FROM arcust ar

IF ( OBJECT_ID('cvo.dbo.cvo_cust_agent_tbl') IS  null )
	CREATE TABLE dbo.cvo_cust_agent_tbl ( phone_num VARCHAR(30), QUEUE_NAME VARCHAR(20), 
		 agent_id VARCHAR(40) , CUSTOMER_CODE VARCHAR(10) )

-- drop TABLE dbo.cvo_cust_agent_tbl

TRUNCATE TABLE dbo.cvo_cust_agent_tbl
INSERT INTO dbo.cvo_cust_agent_tbl ( phone_num, QUEUE_NAME, agent_id, CUSTOMER_CODE )
VALUES ('7596','CSQ-CustomerCare','HKaufman','012345')
INSERT INTO dbo.cvo_cust_agent_tbl ( phone_num, QUEUE_NAME, agent_id, CUSTOMER_CODE )
VALUES ('7596','CSQ-KeyAccounts','HKaufman', '011111')
INSERT INTO dbo.cvo_cust_agent_tbl ( phone_num, QUEUE_NAME, agent_id, CUSTOMER_CODE )
VALUES ('7596','CSQ-SalesSupport','HKaufman', '011111')

INSERT INTO cvo_cust_agent_tbl( phone_num, QUEUE_NAME, agent_id, customer_code)
SELECT TOP 100 phone_num, CASE WHEN queue_name = 'KA' THEN 'CSQ-KeyAccounts' 
								WHEN queue_name = 'SS' THEN 'CSQ-SalesSupport'
								WHEN queue_name = 'CS' THEN 'CSQ-CustomerCare'
								ELSE 'CSQ-Unknown'
								END
								, agent_id 
								, CUSTOMER_CODE 
								FROM @AGENTS

-- SELECT * FROM dbo.cvo_cust_agent_tbl



-- SELECT agent, count(phone_num) FROM cvo_cust_agent_tbl group by agent

END
GO
GRANT EXECUTE ON  [dbo].[cvo_refresh_cust_agent_tbl_sp] TO [public]
GO
