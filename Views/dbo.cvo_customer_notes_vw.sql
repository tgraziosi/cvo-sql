SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_customer_notes_vw] 
AS 
SELECT ar.territory_code,
       ar.salesperson_code,
       ar.customer_code,
       ar.ship_to_code,
       CASE ar.status_type WHEN 1 THEN 'Active' WHEN 2 THEN 'Inactive' WHEN 3 THEN 'NoNewBusiness' ELSE 'Unknown' END Status,
       CASE ar.address_type WHEN 0 THEN 'Bill-to' WHEN 1 THEN 'Ship-to' WHEN 9 THEN 'Global' END AS Address_type,
       ar.address_name,
       ar.contact_name,
       ar.contact_phone,
       ar.contact_email,
       note,
       ar.special_instr
FROM armaster ar (NOLOCK)
WHERE ISNULL(ar.note, '') > ''
      OR ISNULL(ar.special_instr, '') > '';
GO
GRANT SELECT ON  [dbo].[cvo_customer_notes_vw] TO [public]
GO
