SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_bg_cust_info_check_sp]
AS 
BEGIN
-- has parent/child but bg history is not active
SELECT na.parent,
       ar.customer_name BG_Name,
       na.child,
       archild.customer_name Child_Name,
       CASE archild.status_type WHEN 1 THEN 'Active'
                WHEN 2 THEN 'InActive'
                WHEN 3 THEN 'NoNewBus' END Customer_Status,
       'Parent/Child has no active BG history entry' Problem
FROM arnarel na (nolock)
    JOIN arcust ar (nolock)
        ON ar.customer_code = na.parent
    JOIN arcust archild (nolock)
        ON archild.customer_code = na.child
    LEFT OUTER JOIN dbo.cvo_buying_groups_hist AS bgh
        ON bgh.parent = na.parent
           AND bgh.child = na.child
WHERE ar.addr_sort1 = 'buying group'
      AND bgh.end_date_int IS NOT NULL
      AND bgh.parent IS NOT NULL
      AND NOT EXISTS
(
SELECT 1
FROM dbo.cvo_buying_groups_hist AS bgh2 (NOLOCK)
WHERE bgh2.child = na.child
      AND bgh2.end_date IS NULL
)

UNION all

-- bg history record is missing for active parent/child

SELECT na.parent,
       ar.customer_name BG_Name,
       na.child,
       archild.customer_name Child_Name,
       CASE archild.status_type WHEN 1 THEN 'Active'
                WHEN 2 THEN 'InActive'
                WHEN 3 THEN 'NoNewBus' END Customer_Status,
       'Parent/Child missing BG history entry' Problem
FROM arnarel na (nolock)
    JOIN arcust ar (nolock)
        ON ar.customer_code = na.parent
    JOIN arcust archild (nolock)
        ON archild.customer_code = na.child
    LEFT OUTER JOIN dbo.cvo_buying_groups_hist AS bgh
        ON bgh.parent = na.parent
           AND bgh.child = na.child
WHERE ar.addr_sort1 = 'buying group'
      AND bgh.end_date_int IS NULL
      AND bgh.parent IS NULL
      AND NOT EXISTS
(
SELECT 1
FROM dbo.cvo_buying_groups_hist AS bgh2 (nolock)
WHERE bgh2.child = na.child
      AND bgh2.end_date IS NULL
);
END

GRANT EXECUTE ON dbo.cvo_bg_cust_info_check_sp TO PUBLIC
GO
GRANT EXECUTE ON  [dbo].[cvo_bg_cust_info_check_sp] TO [public]
GO
