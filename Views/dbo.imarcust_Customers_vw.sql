SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE VIEW 
[dbo].[imarcust_Customers_vw] 
    AS 
    SELECT * 
            FROM [CVO_Control]..[imarcust]
            WHERE [address_type] = 0

GO
GRANT REFERENCES ON  [dbo].[imarcust_Customers_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imarcust_Customers_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imarcust_Customers_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imarcust_Customers_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imarcust_Customers_vw] TO [public]
GO
