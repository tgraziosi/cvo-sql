SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_customer_types_vw]
AS
SELECT	cust_type addr_sort1
FROM	cvo_customer_types (NOLOCK)
GO
GRANT REFERENCES ON  [dbo].[cvo_customer_types_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_customer_types_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_customer_types_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_customer_types_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_customer_types_vw] TO [public]
GO
